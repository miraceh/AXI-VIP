`ifndef TVIP_AXI_IF_SV
`define TVIP_AXI_IF_SV
interface tvip_axi_if (
  input var aclk,
  input var areset_n
);
  import  tvip_axi_types_pkg::*;

  //  Write Address Channel
  logic                 awvalid;
  logic                 awready;
  tvip_axi_id           awid;
  tvip_axi_address      awaddr;
  tvip_axi_burst_length awlen;
  tvip_axi_burst_size   awsize;
  tvip_axi_burst_type   awburst;
  tvip_axi_write_cache  awcache;
  tvip_axi_protection   awprot;
  tvip_axi_qos          awqos;
  //  Write Data Channel
  logic                 wvalid;
  logic                 wready;
  tvip_axi_data         wdata;
  tvip_axi_strobe       wstrb;
  logic                 wlast;
  //  Write Response Channel
  logic                 bvalid;
  logic                 bready;
  tvip_axi_id           bid;
  tvip_axi_response     bresp;
  //  Read Address Channel
  logic                 arvalid;
  logic                 arready;
  tvip_axi_id           arid;
  tvip_axi_address      araddr;
  tvip_axi_burst_length arlen;
  tvip_axi_burst_size   arsize;
  tvip_axi_burst_type   arburst;
  tvip_axi_read_cache   arcache;
  tvip_axi_protection   arprot;
  tvip_axi_qos          arqos;
  //  Read Data Channel
  logic                 rvalid;
  logic                 rready;
  tvip_axi_id           rid;
  tvip_axi_data         rdata;
  tvip_axi_response     rresp;
  logic                 rlast;

  clocking master_cb @(posedge aclk, negedge areset_n);
    output  awvalid;
    input   awready;
    output  awid;
    output  awaddr;
    output  awlen;
    output  awsize;
    output  awburst;
    output  awprot;
    output  awcache;
    output  awqos;
    output  wvalid;
    input   wready;
    output  wdata;
    output  wstrb;
    output  wlast;
    input   bvalid;
    output  bready;
    input   bid;
    input   bresp;
    output  arvalid;
    input   arready;
    output  arid;
    output  araddr;
    output  arlen;
    output  arsize;
    output  arburst;
    output  arcache;
    output  arprot;
    output  arqos;
    input   rvalid;
    output  rready;
    input   rid;
    input   rdata;
    input   rresp;
    input   rlast;
  endclocking

  clocking slave_cb @(posedge aclk, negedge areset_n);
    input   awvalid;
    output  awready;
    input   awid;
    input   awaddr;
    input   awlen;
    input   awsize;
    input   awburst;
    input   awcache;
    input   awprot;
    input   awqos;
    input   wvalid;
    output  wready;
    input   wdata;
    input   wstrb;
    input   wlast;
    output  bvalid;
    input   bready;
    output  bid;
    output  bresp;
    input   arvalid;
    output  arready;
    input   arid;
    input   araddr;
    input   arlen;
    input   arsize;
    input   arburst;
    input   arcache;
    input   arprot;
    input   arqos;
    output  rvalid;
    input   rready;
    output  rid;
    output  rdata;
    output  rresp;
    output  rlast;
  endclocking

  clocking monitor_cb @(posedge aclk);
    input areset_n;
    input awvalid;
    input awready;
    input awid;
    input awaddr;
    input awlen;
    input awsize;
    input awburst;
    input awcache;
    input awprot;
    input awqos;
    input wvalid;
    input wready;
    input wdata;
    input wstrb;
    input wlast;
    input bvalid;
    input bready;
    input bid;
    input bresp;
    input arvalid;
    input arready;
    input arid;
    input araddr;
    input arlen;
    input arsize;
    input arburst;
    input arcache;
    input arprot;
    input arqos;
    input rvalid;
    input rready;
    input rid;
    input rdata;
    input rresp;
    input rlast;
  endclocking

  event at_master_cb_edge;
  event at_slave_cb_edge;
  event at_monitor_cb_edge;

  always @(master_cb) begin
    ->at_master_cb_edge;
  end

  always @(slave_cb) begin
    ->at_slave_cb_edge;
  end

  always @(monitor_cb) begin
    ->at_monitor_cb_edge;
  end

// Handshake Properties
ap_wvalid_hold:
assert property (@(posedge aclk) disable iff (!areset_n)
  wvalid && !wready |=> wvalid s_until_with wready
);

ap_wready_eventually:
assert property (@(posedge aclk) disable iff (!areset_n)
  wvalid |=> s_eventually(wready)
);

cp_w_handshake:
cover property (@(posedge aclk) disable iff (!areset_n)
  wvalid && wready
);

ap_bvalid_hold:
assert property (@(posedge aclk) disable iff (!areset_n)
  bvalid && !bready |=> bvalid s_until_with bready
);

// Backpressure Stability Properties
ap_wdata_stable:
assert property (@(posedge aclk) disable iff (!areset_n)
  wvalid && !wready |=> $stable({wdata, wstrb, wlast})
);

ap_aw_stable:
assert property (@(posedge aclk) disable iff (!areset_n)
  awvalid && !awready |=> $stable({awid, awaddr, awlen})
);

ap_bid_stable:
assert property (@(posedge aclk) disable iff (!areset_n)
  bvalid && !bready |=> $stable(bid)
);

cp_w_backpressure_multi:
cover property (@(posedge aclk) disable iff (!areset_n)
  (wvalid && !wready)[*2:$] ##1 wready
);


// Burst Properties
ap_burst_4kb_boundary:
assert property (@(posedge aclk) disable iff (!areset_n)
  awvalid && awready && awburst == 2'b01 |->
    ({1'b0, awaddr[11:0]} +
     (({1'b0, awlen} + 1'b1) << awsize)) <= 13'd4096
);

ap_wrap_len_legal:
assert property (@(posedge aclk) disable iff (!areset_n)
  awvalid && awburst == 2'b10 |->
    awlen inside {1, 3, 7, 15}
);

ap_awburst_legal:
assert property (@(posedge aclk) disable iff (!areset_n)
  awvalid |-> awburst != 2'b11
);

ap_wrap_addr_aligned:
assert property (@(posedge aclk) disable iff (!areset_n)
  awvalid && awburst == 2'b10 |-> (awaddr % (1 << awsize)) == 0
);

ap_fixed_len_legal:
assert property (@(posedge aclk) disable iff (!areset_n)
  awvalid && awburst == 2'b00 |->
    awlen <= 15
);

// reset behaviors
ap_valid_low_during_reset:
assert property (@(posedge aclk)
  !areset_n |-> !awvalid && !wvalid && !arvalid
);

ap_response_valid_low_during_reset:
assert property (@(posedge aclk)
  !areset_n |-> !bvalid && !rvalid
);

cp_reset_recovery:
cover property (@(posedge aclk)
  $rose(areset_n) ##[1:$] (awvalid && awready)
);

// X-Value Properties
ap_bresp_no_x:
assert property (@(posedge aclk) disable iff (!areset_n)
  bvalid |-> !$isunknown({bid, bresp})
);

ap_rresp_no_x:
assert property (@(posedge aclk) disable iff (!areset_n)
  rvalid |-> !$isunknown({rid, rdata, rresp, rlast})
);

endinterface
`endif
