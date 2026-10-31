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


task body;
  req = txn::type_id::create("req");
  start_item(req);
  assert(!req.randomize() with {hwrite == 1;}) `uvm_fatal("", "");
  finish_item(req);
endtask


interface axi_if (input logic aclk);
  // read address channel
  logic [31:0] ARADDR;
  logic [7:0]  ARLEN;
  logic [2:0]  ARSIZE;
  logic [1:0]  ARBURST;
  logic [3:0]  ARID;
  logic        ARVALID, ARREADY;

  // write address channel
  logic [31:0] AWADDR;
  logic [7:0]  AWLEN;
  logic [2:0]  AWSIZE;
  logic [1:0]  AWBURST;
  logic [3:0]  AWID;
  logic        AWVALID, AWREADY;

  // write data channel
  logic [31:0] WDATA;
  logic [3:0]  WSTRB;
  logic        WLAST, WVALID, WREADY;

  // read data channel
  logic [31:0] RDATA;
  logic [1:0]  RRESP;
  logic [3:0]  RID;
  logic RVALID, RREADY, RLAST;

  // write resp channel
  logic [1:0]  BRESP;
  logic [3:0]  BID;
  logic        BVALID, BREADY;

endinterface

sel, write, en, ready, slverror
prot 3, strob 4
paddr
pwdata
prdata

idle
non seq
seq
busy

single
incr without len
wrap4
incr4
wrap8
incr8
wrap16
incr16



enum bit [1:0] {
  okay = 2'b00,
  exokay = 2'b01,
  slverror = 2'b10,
  decerror = 2'b11
  } axi_resp_t;

enum bit [1:0] {
  fixed = 2'b00,
  incr = 2'b01,
  wrap = 2'b10
  } axi_burst_t;

class axi_item extends uvm_sequence_item;
  `uvm_object_utils(axi_item)

  rand bit [31:0] AXADDR;
  rand bit        write;
  rand bit [7:0]  AXLEN;
  rand bit [2:0]  AXSIZE;
  rand bit [3:0]  AXID;
  rand axi_burst_t  AXBURST;
  rand bit [31:0] WDATA [];
  rand bit [3:0]  WSTRB [];

  bit [3:0] XID;
  axi_resp_t XRESP [$];
  bit [31:0] RDATA [$];

  constraint len_cons {
    (AXBURST == fixed) -> AXLEN inside {[0:15]};
    (AXBURST == incr)  -> AXLEN inside {[0:255]};
    (AXBURST == wrap)  -> AXLEN inside {1, 3, 7, 15};
    }

  constraint bounday_4kb {
    (AXBURST == incr) -> AXADDR[11:0]+(AXLEN+1)<<AXSIZE <= 4096;
    }

  constraint valid_burst {
    AXBURST != 2'b11;
    }
  constraint burst_len {
    WDATA.size() == write ? (AXLEN+1) : 0;
    WSTRB.size() == write ? (AXLEN+1) : 0;
    }

  function new(string n = "axi_item");
    super.new(n);
  endfunction
endclass

in top module,
my_if mif;
uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.env.agent.*", "vif", mif);


in driver or monitor
virtual my_if vif;
if(!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif)) `uvm_fatal("driver or monitor", "vif not set for driver or monitor");

argument of set method: first is where it is being set, second argument where this database will be visible, third argument is name by which we access the value, 4th argument is static interface which is passed.

argument of get method: first is same where we are getting, second is not required for get method, third is name to access virtual interface, last is virtual interface handle to get pointer to static interface.

I will check these 3 things:
first I will check the set path because if its wrong driver will not have visibility of set vif.
second I will check the name passed in set method
I will check the type of interface mentioned in set and get method and handle types created because if thats wrong then also the get method will fail
I will check the name mentioned in the set and get method. The name mismatch will also return null pointer.


set method is used to set interface to be used by driver and monitor. run_test will start build phase where we get the virtual interface so if the set command is run after run_test then the get method will fail for drivers and monitors. Thats why the set method should be called before run_test.

the driver will get the interface set with null as context because it has higher precedence then this used inside test class.

I will not use 5 different sets. I will create config object and declare these things as properties of config object. Then I will set and get config object to avoid repeated set and get call as well as make the testbench cleaner and more reusable.



rand and randc both make the variable eligble for randomization but the difference lies in distribution of subsequent randomization. All the possible values will have equeal probability no matter how many times a rand variable is randomized. randc on the other hand is cyclic meaning with each randomization the solver will try to pick the unused state. I will use rand for address and data. randc I will use for operations type in a test where I want to trigger all types of operations one after another.

class txn extends uvm_sequence_item;
  `uvm_object_utils(txn)

  rand bit [31:0] addr;
  rand bit [7:0] len;
  rand bit write;

  constraint addr_align {
    addr[1:0] == 2'b00;
    }

  constraint len_c {
    len inside {[1:16]};
    }

  constraint addr_dist {
    addr dist {['x0000:'x0FFF]:=70;
               ['x1000:'xFFFF]:=30;}
    }

  constraint boundary_4kb {
    addr[11:0] + len*4 <= 4096;
    }
  function new(string n = "txn");
    super.new(n);
  endfunction
endclass

I did not use assert or if condition on tx.randomize() so when the solver is failing its failing silently. 
  I will use assert(tx.randomize()) `uvm_fatal("solver", "failure");


// I will not see cyclic behaviour because random values are tracked per object. A new objection everytime will reset that tracker and will not show cyclic behaviour.
// I can create child class of transaction class and define a constraint with same name but with len == 1
// Or I can create a child class and use factory overriding to override parent
// class handle. If it was a soft constraint then I could override it with
// a inline constraint. soft constraint do not lead to conflict and solver
// failure they are used for default values.
// I will check the coverage and how many times each bins are being hit. That
// will show me if the dist is working. I will define 2 separate bins for 70
// and 30 range.
//
//

sequence will do start_item which will put a request with sequencer. Driver will call get_next_item which ask for a packet from sequencer. Sequencer will then send grant to sequence which will call finish_item after randomization and send the packet. driver will get the packet via sequencer and then it will drive it on dut. After driving is done then it will call item done which will unblock sequence's finish_item. This is one complete transactions.

task run_phase(uvm_phase phase);
  @(vif.cb.resetn); //wait for reset

  forever begin
    seq_item_port.get_next_item(req);
    drv_dut;
    seq_item_port.item_done();
  end
endtask
if item done is missed then sequence will remain blocked. If the item done is called before driving transaction to dut then the handle might point to new transaction and the current transaction might get corrupted. They should be called in this order.

  The macro is `uvm_do(req) which will create req packet, call start_item, randomize req and then do finish_item. Its harder to debug macro based code so better to write these steps manually like
req = txn::type_id::create("req");
start_item(req);
assert(req.randomize()) `uvm_fatal("", "");
finish_item(req);
I will chose manually steps everytime but in cases where the test is simple and transaction randomization is easy then I will use `uvm_do();




get_next_item is blocking and try_next_item is non blocking. get_next_item will block the driver until a packet arrives. try_next_item is used to drive idle cycles. If there is no packet then drive idle cycle otherwise drive the packet. get method gets the packet and handles item done internally.

there are 2 ways to send response back to sequence: first is using item_done(req); which will update object in finish_item. or driver can call put_response(rsp); and sequence can call get_response(rsp) to get response. I dont know what happens if sequence never reads them.


task reset_task;
  @(negedge vif.resetn);
endtask

task packet_task;
  forever begin
    seq_item_port.get_next_item(req);
    drv_dut;
    seq_item_port.item_done();
  end
endtask

task run_phase(uvm_phase phase);

  forever begin
    @(posedge vif.resetn);
    fork
      reset_task;
      packet_task;
    join_any
    disable fork;
  end
endtask

  suggest me model answer and keywords I missed which I should use in my answers.



normal TLM ports do not support one to many connections so I will use tlm analysis port. I will connect them in env.
agent.mon.ap.connect(scb.aip);
agent.mon.ap.connect(coverage_collector.aip);

in monitor,
uvm_analysis_port#(txn) ap;

in scb,
`uvm_analysis_imp_decl(_mon1)  // outside class
uvm_analysis_imp_mon1#(txn) aip;

in coverage collector
`uvm_analysis_imp_decl(_from_mon1)  // outside class
uvm_analysis_imp_from_mon1#(txn) aip;


analysis port is for connection between two components like driver and sequencer, analysis implementation is where we need multiple connection (write method is implemented here), when both are initiator then we use analysis fifo.


`uvm_anaylsis_imp_decl(_wp)
`uvm_analysis_imp_decl(_rp)
class myscb extends uvm_scoreboard;
  `uvm_component_utils(myscb)

  uvm_analysis_imp_wp#(w_txn) aiwp;
  uvm_analysis_imp_rp#(r_txn) airp;

  bit [31:0] mem_model [bit [31:0]];

  function new(string n = "myscb", uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    aiwp = new("aiwp", this);
    airp = new("airp", this);
  endfunction

  function void write_wp(w_txn t);
    mem_model[t.addr] = t.data;
  endfunction

  function void write_rp(r_txn t);
    if (t.rdata != mem_model[t.addr])
      `uvm_error("scb", "data mismatch");
  endfunction

  function void report_phase(uvm_phase phase);
    // print memory model
  endfunction

  function void check_phase(uvm_phase phase);
  endfunction
endclass

revise
best debug
introduction

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

  task drv_data;
    forever begin
      @(vif.cb);
    end
  endtask

  task drv_addr;
    @(vif.cb);
    vif.cb.hwrite <= req.hwrite;
    vif.cb.haddr <=  req.haddr;
  endtask

  task run_phase(uvm_phase phase);
    wait(vif.resetn === 1'b1);

    fork
      drv_data;
    join_none

    forever begin
      seq_item_port.get_next_item(req);
      drv_addr;
      seq_item_port.item_done();
    end
  endtask
endclass



// sel write, mlock, ready resp
// trans 2
// burst and size 3
// prot is 4 in ahb

enum bit [2:0] {single, incr, wrap4, incr4, wrap8, incr8,
  wrap16, incr16} hburst_t;

rand bit hwrite, mlock;
rand hburst_t hburst, 
rand bit [2:0] hsize;
rand bit [3:0] hprot
rand bit [31:0] haddr, hdata;

bit [31:0] hrdata;
bit resp;


class apb_mon extends uvm_monitor;
  `uvm_component_utils(apb_mon)

  virtual mif vif;

  uvm_analysis_port#(txn) ap;

  function new(string n = "apb_mon", uvm_component p);
    super.new(n, p);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual mif)::get(this, "", "vif", vif)) `uvm_fatal("", "");
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    wait(vif.resetn === 1'b1);

    forever begin
      do @(vif.cb);
      while(!(vif.cb.sel && vif.cb.pen && vif.cb.pready));
      txn req = txn::type_id::create("req");
      req.paddr = vif.cb.paddr;
      req.pwdata = vif.cb.pwdata;
      req.pwrite = vif.cb.pwrite;
      ap.write(req);
    end
  endtask
endclass

task body;
  req = txn::type_id::create("req");
  start_item(req);
  assert(req.randomize() with {write == 1;}) else `uvm_fatal("", "");
  finish_item(req);
endtask

interface axi_if (input logic aclk);
  // read address channel
  logic [31:0] ARADDR;
  logic [7:0]  ARLEN;
  logic [1:0]  ARBURST;
  logic [2:0]  ARSIZE;
  logic [3:0]  ARID;
  logic ARVALID, ARREADY;

  // write address channel
  logic [31:0] AWADDR;
  logic [7:0]  AWLEN;
  logic [1:0]  AWBURST;
  logic [2:0]  AWSIZE;
  logic [3:0]  AWID;
  logic AWVALID, AWREADY;

  // write data channel
  logic [31:0] WDATA;
  logic WLAST, WREADY, WVALID;
  logic [3:0] WSTRB;

  // read data channel
  logic [31:0] RDATA;
  logic [1:0] RRESP;
  logic RID;
  logic RLAST, RREADY, RVALID;

  // write response channel
  logic [1:0] BRESP;
  logic [3:0] BID;
  logic BVALID, BREADY;
endinterface

