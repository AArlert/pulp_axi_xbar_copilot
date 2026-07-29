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

  // ---- runtime-reconfiguration config bus (C4.2, spec §2.3/§3.4) --------
  // Holds addr_map / en_default_mst_port / default_mst_port as runtime-drivable
  // signals wired straight to the DUT below. Initialised once to the baseline
  // (V0) at time 0 here; M2-CFG01's env later overrides it in an all-idle
  // window (m2_cfg01_reconfig_vseq). Every other test leaves it at baseline,
  // so their behaviour is unchanged from the previous hard-wired constants.
  xbar_cfg_if cfg_if (.clk_i(clk), .rst_ni(rst_n));

  initial begin
    cfg_if.addr_map            = xbar_types_pkg::ADDR_MAP;
    cfg_if.en_default_mst_port = '0;
    cfg_if.default_mst_port    = '0;
  end

  // ---- config-point self-report (design-prompt tb_top.md C5.3) ----------
  // Prints the full elaborated config (all 13 Cfg fields + ATOPs + Connectivity
  // + the address table) at time 0 so every evidence log self-identifies which
  // config point it exercised — signoff need not reverse-engineer it (spec
  // §2.1/§2.2/§0 row 3). Tag [CFG_REPORT] is grep-able by scripts/humans.
  initial begin
    $display("[CFG_REPORT] config_point=%s", xbar_types_pkg::CFG_NAME);
    $display("[CFG_REPORT] Cfg NoSlvPorts=%0d NoMstPorts=%0d MaxMstTrans=%0d MaxSlvTrans=%0d FallThrough=%0b",
             Cfg.NoSlvPorts, Cfg.NoMstPorts, Cfg.MaxMstTrans, Cfg.MaxSlvTrans, Cfg.FallThrough);
    $display("[CFG_REPORT] Cfg LatencyMode=10'b%010b PipelineStages=%0d AxiIdWidthSlvPorts=%0d AxiIdUsedSlvPorts=%0d UniqueIds=%0b",
             Cfg.LatencyMode, Cfg.PipelineStages, Cfg.AxiIdWidthSlvPorts,
             Cfg.AxiIdUsedSlvPorts, Cfg.UniqueIds);
    $display("[CFG_REPORT] Cfg AxiAddrWidth=%0d AxiDataWidth=%0d NoAddrRules=%0d ATOPs=%0b Connectivity=0x%0h",
             Cfg.AxiAddrWidth, Cfg.AxiDataWidth, Cfg.NoAddrRules,
             xbar_types_pkg::ATOPS, xbar_types_pkg::CONNECTIVITY);
    $display("[CFG_REPORT] derived ID_W_SLV=%0d ID_W_MST=%0d PREFIX_W=%0d",
             xbar_types_pkg::ID_W_SLV, xbar_types_pkg::ID_W_MST,
             xbar_types_pkg::PREFIX_W);
    for (int unsigned r = 0; r < xbar_types_pkg::NO_ADDR_RULES; r++)
      $display("[CFG_REPORT] rule[%0d] idx=%0d start=0x%08h end=0x%08h",
               r, xbar_types_pkg::ADDR_MAP[r].idx,
               xbar_types_pkg::ADDR_MAP[r].start_addr,
               xbar_types_pkg::ADDR_MAP[r].end_addr);
  end

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

  // ---- all-ports-silent window (C4.2 / uvm_env.md C5.1, spec §3.4) -------
  // High on a cycle where NO slave port drives AW or AR valid — the window the
  // env waits for before applying the one runtime reconfiguration (so the
  // change never overlaps any port's AW/AR valid). TB-internal sync aid only.
  always_comb begin
    logic idle;
    idle = 1'b1;
    for (int unsigned s = 0; s < xbar_types_pkg::NO_SLV_PORTS; s++)
      if (slv_req[s].aw_valid || slv_req[s].ar_valid) idle = 1'b0;
    cfg_if.all_ax_idle = idle;
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
    .addr_map_i            (cfg_if.addr_map),
    .en_default_mst_port_i (cfg_if.en_default_mst_port),
    .default_mst_port_i    (cfg_if.default_mst_port)
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

  // Config bus handle for the scoreboard's version tracker (C1.5) and the
  // M2-CFG01 reconfiguration test/vseq (C5.1).
  initial begin
    uvm_config_db#(virtual xbar_cfg_if)::set(null, "*", "cfg_vif", cfg_if);
  end

  initial begin
    run_test();
  end

endmodule
