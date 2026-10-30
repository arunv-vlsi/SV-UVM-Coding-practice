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



class ahb_driver extends uvm_driver#(txn);
  `uvm_component_utils(ahb_driver)

  virtual mif vif;

  function new(string n = "ahb_driver", uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual mif)::get(this, "", "vif", vif)) `uvm_fatal("", "");
  endfunction

  task drv_addr;
    @(vif.cb);
    for (int i = 0; i < req.len; i++) begin
      
    end
  endtask

  task run_phase(uvm_phase phase);
    @(vif.cb.resetn); // wait for reset

    forever begin
      seq_item_port.get_next_item(req);
      fork
        drv_addr;
        drv_data;
      join_any
      seq_item_port.item_done();
    end
  endtask
endclass


`uvm_analysis_imp_decl(_master)
`uvm_analysis_imp_decl(_slave)
class mysb extends uvm_scoreboard;
  `uvm_component_utils(mysb)

  uvm_analysis_imp_master#(txn) mip;
  uvm_analysis_imp_slave#(txn) sip;

  covergroup name with function sample(txn t);
    adddr_cp : coverpoint t.addr {bins a = 'h100;}
  endgroup

  function new(string n = "mysb", uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mip = new("mip", this);
    sip = new("sip", this);
  endfunction

  function void check_phase(uvm_phase phase);
  endfunction

  function void report_phase(uvm_phase phase);
  endfunction
  function void write_master(txn t);
  endfunction

  function void write_slave(txn t);
  endfunction
endclass

class txn extends uvm_sequence_item;
  `uvm_object_utils(txn)

  rand bit [31:0] addr;
  rand bit [31:0] data [];

  constraint addr_c{
    addr inside {['h100:'h200]};
    }
  constraint data_c {
    data.size() inside {'d10, 'd20, 'd30};
    }

  function new(string n = "txn", uvm_component p);
    super.new(n, p);
  endfunction

  function string convert2string();
    return $sformatf("", );
  endfunction
endclass


class axi_txn extends uvm_sequence_item;
  `uvm_object_utils(axi_txn)

  // read
  // write
  // read data
  // write response
  // write data
  //
  rand bit [31:0] ARADDR;
  rand bit [7:0] ARLEN;
  rand bit [3:0] ARBURST;


  function new(string n = "axi_txn");
    super.new(n);
  endfunction
endclass

class ahb_rd_wr_seq extends uvm_sequence#(txn);
  `uvm_object_utils(ahb_rd_wr_seq)

  function new(string n = "ahb_rd_wr_seq");
    super.new(n);
  endfunction

  task body;
    req = txn::type_id::create("req");
    start_item(req);
    assert(!req.randomize() with {hwrite == 1'b1;}) `uvm_fatal("", "");
    finish_item(req);

    req = txn::type_id::create("req");
    start_item(req);
    assert(!req.randomize() with {hwrite == 1'b0;}) `uvm_fatal("", "");
    finish_item(req);
  endtask
endclass


interface axi_if (input logic aclk);
  // read
  logic ARVALID, ARREADY;
  logic [3:0] ARID;
  logic [31:0] ARADDR;
  logic [6:0] ARSIZE;
  logic [7:0] ARLEN;
  logic [1:0] ARBURST;

  // write
  logic AWVALID, AWREADY;
  logic [3:0] AWID;
  logic [31:0] AWADDR;
  logic [2:0] AWSIZE;
  logic [7:0] AWLEN;
  logic [1:0] AWBURST;

  // write data
  logic [31:0] WDATA;
  logic [3:0] WSTRB;
  logic WVALID, WREADY, WLAST;

  // read data
  logic [31:0] RDATA;
  logic [3:0] RID;
  logic [1:0] RRESP;
  logic RVALID, RREADY, RLAST;

  // write resp
  logic BVALID, BREADY;
  logic [1:0] BRESP;
  logic [3:0] BID;
endinterface


class axi_txn extends uvm_sequence_item;
  `uvm_object_utils(axi_txn)

  // read address channel
  rand bit [31:0] ARADDR;
  rand bit [3:0]  ARID;
  rand bit [7:0]  ARLEN;
  rand bit [2:0]  ARSIZE;
  rand bit [1:0]  ARBURST;

  // write address channel
  rand bit [31:0] AWADDR;
  rand bit [3:0]  AWID;
  rand bit [7:0]  AWLEN;
  rand bit [2:0]  AWSIZE;
  rand bit [1:0]  AWBURST;

  // read data channel
  bit [31:0] RDATA;
  bit [1:0] RRESP;
  bit RLAST;

  // write data channel
  rand bit [31:0] WDATA;
  rand bit [3:0]  WSTRB;

  // write response channel
  bit [1:0] BRESP;

  function new(string n = "axi_txn");
    super.new(n);
  endfunction
endclass



class axi_rd_seq extends uvm_sequence#(axi_item);
  `uvm_object_utils(axi_rd_seq)

  function new(string n = "axi_rd_seq");
    super.new(n);
  endfunction

  task body;
    req = axi_item::type_id::create("req");
    start_item(req);
    assert(!req.randomize() with {write == 1}) `uvm_fatal("", "");
    finish_item(req);
  endtask
endclass

software
transaction
data link
physical

hsize
3 bit


1kb
haddr[31:10] == haddr+size*len >> 10;

incr
0 255
wrap 
1, 2, 4, 8, 16
fixed

setup phase


enum bit [2:0] {
  byte1 = 3'b000,
  byte2 = 3'b001,
  byte4 = 3'b010,
  byte8 = 3'b011,
  byte16 = 3'b100,
  byte32 = 3'b101,
  byte64 = 3'b110,
  byte128 = 3'b111
  } axi_size_t;

enum bit [1:0] {
  fixed = 2'b00,
  incr = 2'b01,
  wrap = 2'b10
  } axi_burst_t

enum bit [1:0] {
  okay = 2'b00,
  exokay = 2'b01,
  slverror = 2'b10,
  decerror = 2'b11
  }  axi_resp_t

class axi_item extends uvm_sequence_item;
  `uvm_object_utils(axi_item)

  rand bit [31:0] AXADDR;
  rand bit write;
  rand bit [7:0] AXLEN;
  rand axi_size_t AXSIZE;
  rand axi_burst_t AXBURST;
  rand bit [3:0] AXID
  rand bit [31:0] WDATA [];
  rand bit [3:0] WSTRB [];
  bit axi_resp_t XRESP [$];
  bit [31:0] RDATA [$];
  bit [3:0] XID;

  constraint len_cons {
    (AXBURST == fixed) -> (int'(AXLEN)+1) inside {1, 2, 4, 8, 16};
    (AXBURST == incr)  -> int'(AXLEN) inside {[0:255]};
    (AXBURST == wrap)  -> (int'(AXLEN)+1) inside {[1:16]};
    }

  constraint write_data_cons {
    WDATA.size() == (write == 1) ? (AXLEN+1) : 0;
    WSTRB.size() == (write == 1) ? (AXLEN+1) : 0;
    }

  constraint boundary_4kb {
    (AXBURST == incr) -> (AXADDR[11:0] + (int'(AXLEN)*int'(1'b1<<AXSIZE)))<= 'd4096;
    }

  function new(string n = "axi_item");
    super.new(n);
  endfunction

  function string convert2string();
    return $sformatf("", );
  endfunction
endclass


