// tb/tb_top.sv — M1 UVM env static top (design-prompt tb_top.md).
// Instantiates a single axi_xbar DUT with struct request/response array
// ports (no axi_xbar_intf wrapper — spec §0 row 1, C1.1), clk/rst, one
// slvport_if per crossbar slave port, one mstport_if per crossbar master
// port, the SVA bind attachment (tb/sva_bind.sv, C4.1), and the UVM
// config_db wiring feeding virtual interface handles + port indices to
// xbar_env's agents. No DUT behavior is asserted here — this file is
// purely structural per the design prompt's own scope statement.

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "axi/assign.svh"
import xbar_types_pkg::*;
import xbar_tb_pkg::*;

module tb_top;

  // ---- clock / reset (design-prompt tb_top.md C3.1) --------------------
  logic clk;
  logic rst_n;

  initial clk = 1'b0;
  always #5 clk = ~clk; // 10ns period, 100 MHz

  // Release on the *negedge* (mid low-phase), not exactly at a posedge:
  // deasserting exactly at a posedge races every posedge-triggered process
  // sampling rst_ni in the same delta (DUT registers and the SVA reset
  // checker alike may then disagree about which edge is "first out of
  // reset" — this is a testbench clocking issue, not a DUT question).
  initial begin
    rst_n = 1'b0;
    repeat (10) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
  end

  // Hang-detection watchdog only (delay-insensitive per spec §7.4 / C3.2 —
  // not a functional/cycle-accurate judgement, purely a generous ceiling
  // so a stuck simulation does not run forever).
  initial begin
    #200000;
    `uvm_fatal("WATCHDOG",
      "tb_top watchdog: simulation exceeded 200000ns without natural completion")
  end

  // ---- per-port interfaces (C2.1/C2.2) ----------------------------------
  slvport_if slv_if [xbar_types_pkg::NO_SLV_PORTS] (.clk_i(clk), .rst_ni(rst_n));
  mstport_if mst_if [xbar_types_pkg::NO_MST_PORTS] (.clk_i(clk), .rst_ni(rst_n));

  xbar_types_pkg::slv_req_t  [xbar_types_pkg::NO_SLV_PORTS-1:0] slv_req;
  xbar_types_pkg::slv_resp_t [xbar_types_pkg::NO_SLV_PORTS-1:0] slv_resp;
  xbar_types_pkg::mst_req_t  [xbar_types_pkg::NO_MST_PORTS-1:0] mst_req;
  xbar_types_pkg::mst_resp_t [xbar_types_pkg::NO_MST_PORTS-1:0] mst_resp;

  for (genvar i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin : gen_slv_conn
    `AXI_ASSIGN_TO_REQ(slv_req[i], slv_if[i])
    `AXI_ASSIGN_FROM_RESP(slv_if[i], slv_resp[i])
  end
  for (genvar j = 0; j < xbar_types_pkg::NO_MST_PORTS; j++) begin : gen_mst_conn
    `AXI_ASSIGN_FROM_REQ(mst_if[j], mst_req[j])
    `AXI_ASSIGN_TO_RESP(mst_resp[j], mst_if[j])
  end

  // ---- DUT instance (C1.1-C1.4, C2.3, C2.4, C2.5) -----------------------
  axi_xbar #(
    .Cfg          (xbar_types_pkg::Cfg),
    .ATOPs        (xbar_types_pkg::ATOPS),
    .Connectivity (xbar_types_pkg::CONNECTIVITY),
    .slv_aw_chan_t(xbar_types_pkg::slv_aw_chan_t),
    .mst_aw_chan_t(xbar_types_pkg::mst_aw_chan_t),
    .w_chan_t     (xbar_types_pkg::w_chan_t),
    .slv_b_chan_t (xbar_types_pkg::slv_b_chan_t),
    .mst_b_chan_t (xbar_types_pkg::mst_b_chan_t),
    .slv_ar_chan_t(xbar_types_pkg::slv_ar_chan_t),
    .mst_ar_chan_t(xbar_types_pkg::mst_ar_chan_t),
    .slv_r_chan_t (xbar_types_pkg::slv_r_chan_t),
    .mst_r_chan_t (xbar_types_pkg::mst_r_chan_t),
    .slv_req_t    (xbar_types_pkg::slv_req_t),
    .slv_resp_t   (xbar_types_pkg::slv_resp_t),
    .mst_req_t    (xbar_types_pkg::mst_req_t),
    .mst_resp_t   (xbar_types_pkg::mst_resp_t),
    .rule_t       (xbar_types_pkg::rule_t)
  ) i_xbar_dut (
    .clk_i                (clk),
    .rst_ni                (rst_n),
    .test_i                (1'b0),
    .slv_ports_req_i       (slv_req),
    .slv_ports_resp_o      (slv_resp),
    .mst_ports_req_o       (mst_req),
    .mst_ports_resp_i      (mst_resp),
    .addr_map_i            (xbar_types_pkg::ADDR_MAP),
    .en_default_mst_port_i ('0),
    .default_mst_port_i    ('0)
  );

  // ---- SVA bind attachment (C4.1) ---------------------------------------
  `include "sva_bind.sv"

  // ---- UVM config_db wiring: vif + port_idx per agent instance ----------
  for (genvar i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin : cfg_slv
    initial begin
      uvm_config_db#(virtual slvport_if)::set(
          null, $sformatf("uvm_test_top.env.slv_agent[%0d]*", i), "vif", slv_if[i]);
      uvm_config_db#(int)::set(
          null, $sformatf("uvm_test_top.env.slv_agent[%0d]*", i), "port_idx", i);
    end
  end
  for (genvar j = 0; j < xbar_types_pkg::NO_MST_PORTS; j++) begin : cfg_mst
    initial begin
      uvm_config_db#(virtual mstport_if)::set(
          null, $sformatf("uvm_test_top.env.mst_agent[%0d]*", j), "vif", mst_if[j]);
      uvm_config_db#(int)::set(
          null, $sformatf("uvm_test_top.env.mst_agent[%0d]*", j), "port_idx", j);
    end
  end

  initial begin
    run_test();
  end

endmodule
