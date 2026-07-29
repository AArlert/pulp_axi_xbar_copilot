// tb/functional_coverage.sv — M2 functional coverage (covergroup) collector
// (design-prompt functional_coverage.md §1/§2). `include-d from tb_pkg.sv
// BEFORE scoreboard_refmodel.sv (the scoreboard stores this class's
// stall_class_e in its own bookkeeping records).
//
// ## What this file is and is NOT
//
// Every bin below records only "did this situation ever occur" — NONE of them
// takes part in any pass/fail verdict (functional_coverage.md §0 hard rule).
// The verdicts stay where they already are: the scoreboard's routing / payload
// / response-route / ordering checks (scoreboard_refmodel.md) and the SVA under
// tb/sva/ (sva_bind.md). Nothing here reads a bus signal or re-decodes an
// address: every sample argument is handed over by the scoreboard at the
// instant its own judgement for that transaction lands (functional_coverage.md
// C1.1 single-source-of-truth, C1.2 sampling instant), so a bin can never
// disagree with the judgement it accompanies.
//
// ## Bin design provenance (expectations trace to doc/spec.md only)
//
//   cg_addr_reconfig          spec §3.4      (M2-CFG01)
//   cg_stall                  spec §5.2      (M2-OR01 / M2-OR02)
//   cg_tx_limit               spec §2.1 MaxMstTrans row + §5.4.1 (M2-TL01/TL02)
//   cg_w_order                spec §5.5      (M2-WO01)
//   cg_atop                   spec §6.3      (M2-AT01)
//   cg_atop_read_interaction  spec §6.5 + §5.2.5 (M2-AT01)
//
// The numeric ceilings come from the pinned baseline Cfg in xbar_types_pkg
// (whose sole parameter-definition source is vendor/axi/src/axi_pkg.sv,
// CLAUDE.md §6); the effective per-bucket ceiling formula
// 2**ceil(log2(MaxMstTrans))-1 is spec §5.4.1 (BUG-0016 / REV-007), NOT a value
// read out of the RTL or a waveform.
//
// ## The one master-port grouping that is deliberately not a covergroup here
//
// functional_coverage.md §2's cg_tx_limit paragraph describes a master-port
// counterpart (per master port × per observable prefixed ID × per direction
// in-flight, non-decisional, bins incl. == MaxSlvTrans) and then says
// "本处先登记 slave 侧". This file lands the slave-side coverpoint. The
// master-side one is NOT duplicated here on purpose: the scoreboard observes
// master-port *requests* only (mstport_monitor is request-side; responses are
// judged from the slave-side round trip), so a covergroup fed from
// scoreboard-visible events could only approximate a master-port in-flight
// count by decrementing at the slave-side B/rlast — an over-count that would
// falsely record "reached MaxSlvTrans". The exact master-port count already
// exists, master-port-local and cycle-exact, in tb/sva/axi_xbar_txlimit_sva.sv
// (its cnt_slv_w/cnt_slv_r covers at lines 256-258 / 267-269 record exactly
// "reached / exceeded MaxSlvTrans" per (full id, direction) per master port —
// sva_bind.md C3.4). Adding a less accurate second observation path would
// violate C1.1's single-source-of-truth rule for no coverage gain.

class xbar_functional_coverage extends uvm_component;
  `uvm_component_utils(xbar_functional_coverage)

  // Classification of one AW/AR against spec §5.2.1, computed by the
  // scoreboard at the observed accept instant and carried to the sampling
  // instant. SC_STALLED records that §5.2.1's *precondition* held (an older,
  // still-open, same-bucket, same-direction record with a different target
  // master port) — it does NOT claim the acceptance handshake was deferred:
  // per spec §5.2.1's accept-boundary note (BUG-0013 / REV-006) that is not a
  // lockable external behaviour, and this is a coverage bin, not a verdict.
  typedef enum bit [1:0] {
    SC_NONE     = 2'd0, // no same-bucket sibling open on this port
    SC_STALLED  = 2'd1, // §5.2.1 precondition: same dir, different target
    SC_SAME_TGT = 2'd2, // §5.2.4: same dir, same target
    SC_DIFF_DIR = 2'd3  // §5.2.1 "same direction" scope boundary: opposite dir
  } stall_class_e;

  // ---- cg_addr_reconfig (spec §3.4, M2-CFG01) ---------------------------
  // Which address-table version was live at this transaction's own AW/AR
  // accept instant, crossed with its source slave port.
  covergroup cg_addr_reconfig with function sample(bit is_post,
                                                    int unsigned src_port);
    option.per_instance = 1;
    cp_table_version: coverpoint is_post {
      bins pre_change  = {1'b0};
      bins post_change = {1'b1};
    }
    cp_src_port: coverpoint src_port {
      bins port[] = {[0:xbar_types_pkg::NO_SLV_PORTS-1]};
    }
    x_version_src: cross cp_table_version, cp_src_port;
  endgroup

  // ---- cg_stall (spec §5.2, M2-OR01/OR02) -------------------------------
  covergroup cg_stall with function sample(stall_class_e cls, bit is_write);
    option.per_instance = 1;
    cp_stall_state: coverpoint cls {
      bins stalled                    = {SC_STALLED};
      bins not_stalled_same_target    = {SC_SAME_TGT};
      bins not_stalled_diff_direction = {SC_DIFF_DIR};
      // SC_NONE intentionally has no bin: "no sibling at all" is not one of
      // the three §5.2 situations this coverpoint tracks.
    }
    cp_dir: coverpoint is_write {
      bins write = {1'b1};
      bins read  = {1'b0};
    }
    x_state_dir: cross cp_stall_state, cp_dir;
  endgroup

  // ---- cg_tx_limit (spec §2.1 MaxMstTrans row + §5.4.1, M2-TL01/TL02) ----
  // In-flight count of the (slave port, low-AxiIdUsedSlvPorts-bit ID bucket,
  // direction) group this transaction belongs to, taken at its accept — every
  // intermediate value up to the group's peak is therefore sampled. Bins run
  // 1..effective ceiling, with the two mandated stops: == MaxMstTrans (the
  // documented value, baseline 10) and == the effective ceiling
  // 2**ceil(log2(MaxMstTrans))-1 (baseline 15, spec §5.4.1) — the bin layout
  // must be able to record counts ABOVE the literal MaxMstTrans, which
  // BUG-0016/REV-007 established as normal (counter-width rounding), not a
  // violation.
  covergroup cg_tx_limit with function sample(int unsigned inflight);
    option.per_instance = 1;
    cp_inflight: coverpoint inflight {
      bins below_max[]          = {[1:xbar_types_pkg::MAX_MST_TRANS-1]};
      bins at_max_mst_trans     = {xbar_types_pkg::MAX_MST_TRANS};
      bins above_max[]          = {[xbar_types_pkg::MAX_MST_TRANS+1:
                                    xbar_types_pkg::MAX_MST_TRANS_EFF-1]};
      bins at_effective_ceiling = {xbar_types_pkg::MAX_MST_TRANS_EFF};
    }
  endgroup

  // ---- cg_w_order (spec §5.5, M2-WO01) ----------------------------------
  // Whether >= 2 distinct source slave ports had write bursts open towards
  // this master port around this burst (see sample_w_order's caller comment in
  // the scoreboard for the exact instant).
  covergroup cg_w_order with function sample(bit multi_source);
    option.per_instance = 1;
    cp_w_contention: coverpoint multi_source {
      bins single_source          = {1'b0};
      bins multi_source_contended = {1'b1};
    }
  endgroup

  // ---- cg_atop (spec §6.3, M2-AT01) -------------------------------------
  covergroup cg_atop with function sample(int unsigned src_port, bit r_resp);
    option.per_instance = 1;
    cp_atop_src_port: coverpoint src_port {
      bins port[] = {[0:xbar_types_pkg::NO_SLV_PORTS-1]};
    }
    cp_atop_r_resp: coverpoint r_resp {
      bins read_resp_required = {1'b1};
      bins no_read_resp       = {1'b0};
    }
    x_src_rresp: cross cp_atop_src_port, cp_atop_r_resp;
  endgroup

  // ---- cg_atop_read_interaction (observational, spec §6.5 + §5.2.5) ------
  // Whether a normal read with the SAME low-ID bucket was in flight on the
  // same slave port when the atomic load was issued. Purely a record of the
  // situation: spec §6.5 states the resulting cross-direction stall is normal
  // design behaviour affecting only performance, so no checker anywhere may
  // draw a verdict from this bin's hit/miss.
  covergroup cg_atop_read_interaction with function sample(bit colliding);
    option.per_instance = 1;
    cp_atop_read_collision: coverpoint colliding {
      bins none                   = {1'b0};
      bins colliding_read_present = {1'b1};
    }
  endgroup

  // ---- cg_cfg_point (spec §0 row 3, functional_coverage.md §4, M3-CF01~CF04)
  // Records WHICH config point this run actually elaborated — one bin per
  // registered config point, so "哪些配置点真的跑过" becomes a coverage-database
  // fact rather than a regression-list claim. The value is the compile-time
  // xbar_types_pkg::CFG_POINT_ID (elaborated by the TEST-name-selected build in
  // sim/Makefile, C5.1), sampled once at start_of_simulation. This covergroup is
  // NON-DECISIONAL like every other bin in this file — it draws no verdict, it
  // only lets signoff confirm each config point in the regression was really
  // exercised (not silently re-running one config, the BUG-0022/0028 hazard).
  covergroup cg_cfg_point with function sample(int unsigned point_id);
    option.per_instance = 1;
    cp_config_point: coverpoint point_id {
      bins baseline = {0}; // 6x8 CUT_ALL_AX (M1/M2 + M3 baseline scenarios)
      bins cfgA     = {1}; // 1x8 NO_LATENCY       (M3-CF01)
      bins cfgB     = {2}; // 6x1 CUT_ALL_PORTS    (M3-CF02)
      bins cfgC     = {3}; // 4x4 UniqueIds        (M3-CF03)
      bins cfgD     = {4}; // 4x4 sparse Conn/ATOPs=0 (M3-CF04)
    }
  endgroup

  int unsigned n_addr_reconfig;
  int unsigned n_stall;
  int unsigned n_tx_limit;
  int unsigned n_w_order;
  int unsigned n_atop;
  int unsigned n_atop_read;
  int unsigned n_cfg_point;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_addr_reconfig         = new();
    cg_stall                 = new();
    cg_tx_limit              = new();
    cg_w_order               = new();
    cg_atop                  = new();
    cg_atop_read_interaction = new();
    cg_cfg_point             = new();
  endfunction

  // Sample the elaborated config point once (its value is a compile-time
  // constant, so one sample fully covers this run's bin — spec §0 row 3).
  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    cg_cfg_point.sample(xbar_types_pkg::CFG_POINT_ID);
    n_cfg_point++;
  endfunction

  function void sample_addr_reconfig(bit is_post, int unsigned src_port);
    cg_addr_reconfig.sample(is_post, src_port);
    n_addr_reconfig++;
  endfunction

  function void sample_stall(stall_class_e cls, bit is_write);
    cg_stall.sample(cls, is_write);
    n_stall++;
  endfunction

  function void sample_tx_limit(int unsigned inflight);
    cg_tx_limit.sample(inflight);
    n_tx_limit++;
  endfunction

  function void sample_w_order(bit multi_source);
    cg_w_order.sample(multi_source);
    n_w_order++;
  endfunction

  function void sample_atop(int unsigned src_port, bit r_resp);
    cg_atop.sample(src_port, r_resp);
    n_atop++;
  endfunction

  function void sample_atop_read_interaction(bit colliding);
    cg_atop_read_interaction.sample(colliding);
    n_atop_read++;
  endfunction

  // Per-run, log-visible coverage evidence: sample count + instance coverage
  // for every covergroup (the "非空转" proof functional_coverage.md §4 asks
  // for). A zero sample count means the scenario never produced that kind of
  // transaction at all; a non-zero count with < 100% means some bins of that
  // group were not hit by this test — both are reported to orch as coverage
  // holes with an attribution (workflow/dispatch/coverage_hole.md), never
  // "fixed" by widening the stimulus on the spot.
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("FCOV_SUMMARY",
      $sformatf("cg_addr_reconfig: samples=%0d inst_cov=%0.2f%% | cg_stall: samples=%0d inst_cov=%0.2f%% | cg_tx_limit: samples=%0d inst_cov=%0.2f%% | cg_w_order: samples=%0d inst_cov=%0.2f%% | cg_atop: samples=%0d inst_cov=%0.2f%% | cg_atop_read_interaction: samples=%0d inst_cov=%0.2f%%",
                 n_addr_reconfig, cg_addr_reconfig.get_inst_coverage(),
                 n_stall,         cg_stall.get_inst_coverage(),
                 n_tx_limit,      cg_tx_limit.get_inst_coverage(),
                 n_w_order,       cg_w_order.get_inst_coverage(),
                 n_atop,          cg_atop.get_inst_coverage(),
                 n_atop_read,     cg_atop_read_interaction.get_inst_coverage()),
      UVM_LOW)
    `uvm_info("FCOV_SUMMARY",
      $sformatf("cg_cfg_point: samples=%0d inst_cov=%0.2f%% point_id=%0d config=%s",
                 n_cfg_point, cg_cfg_point.get_inst_coverage(),
                 xbar_types_pkg::CFG_POINT_ID, xbar_types_pkg::CFG_NAME),
      UVM_LOW)
    `uvm_info("FCOV_SUMMARY",
      $sformatf("cg_stall coverpoints: cp_stall_state=%0.2f%% cp_dir=%0.2f%% x_state_dir=%0.2f%% | cg_tx_limit cp_inflight=%0.2f%% | cg_addr_reconfig cp_table_version=%0.2f%% cp_src_port=%0.2f%% x_version_src=%0.2f%% | cg_w_order cp_w_contention=%0.2f%% | cg_atop cp_src=%0.2f%% cp_r_resp=%0.2f%% x_src_rresp=%0.2f%% | cg_atop_read_interaction cp=%0.2f%%",
                 cg_stall.cp_stall_state.get_inst_coverage(),
                 cg_stall.cp_dir.get_inst_coverage(),
                 cg_stall.x_state_dir.get_inst_coverage(),
                 cg_tx_limit.cp_inflight.get_inst_coverage(),
                 cg_addr_reconfig.cp_table_version.get_inst_coverage(),
                 cg_addr_reconfig.cp_src_port.get_inst_coverage(),
                 cg_addr_reconfig.x_version_src.get_inst_coverage(),
                 cg_w_order.cp_w_contention.get_inst_coverage(),
                 cg_atop.cp_atop_src_port.get_inst_coverage(),
                 cg_atop.cp_atop_r_resp.get_inst_coverage(),
                 cg_atop.x_src_rresp.get_inst_coverage(),
                 cg_atop_read_interaction.cp_atop_read_collision.get_inst_coverage()),
      UVM_LOW)
  endfunction
endclass
