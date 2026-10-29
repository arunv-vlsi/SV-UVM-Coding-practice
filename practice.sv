class ahb_d extends uvm_driver#(txn);
  `uvm_component_utils(ahb_d)

  virtual mif vif;

  function new(string n = "ahb_d", uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual mif)::get(this, "", "vif", vif)) `uvm_fatal("", "");
  endfunction

  task init_signals;
    @(vif.cb);
    vif.cb.hwrite <= 1'b0;
    // set all the ahb signals to 0
  endtask

  task drv_dut;
    @(vif.cb);
    vif.cb.hsel <= 1'b1;

  endtask

  task run_phase(uvm_phase phase);
    init_signals;

    forever begin
      seq_item_port.get_next_port(req);
      drv_dut;
      seq_item_port.item_done(resp);
    end
  endtask
endclass


task run_phase(uvm_phase phase);
  init_signals;
  forever begin
    // setup phase
    vif.cb.sel <= 1'b1;
    vif.cb.pwrite <= req.pwrite;
    // all signals
    vif.cb.pen <= 1'b0;

    // access phase
    vif.cb.pen <= 1'b1;

    do @(vif.cb);
    while(!(vif.cb.psel && vif.cb.pen && vif.cb.pready));

    resp.prdata <= vif.cb.prdata;

    vif.cb.psel <= 1'b0;
    vif.cb.pen <= 1'b0;
  end
endtask



class
