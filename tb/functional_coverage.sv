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

  // ---- module->class instrumentation bridge handle (functional_coverage.md §4)
  // Three of the M3 covergroups below (cg_default_port_tracked, cg_live_addr_map,
  // and cg_miss_order's same_bucket_diff_full_id_with_err_slv bin) must sample the
  // EXACT folded fact signals the BUG-0025/BUG-0031 cover properties in
  // tb/sva/axi_xbar_stall_sva.sv already compute — not a second, independently
  // maintained copy of the default-port / live-table / err-bucket decision logic
  // (the user's single-fact-source rule). Those facts live in a module (6 stall-SVA
  // instances), so the module reaches this single collector through this static
  // handle (assigned in new(); there is exactly one fcov instance, created once by
  // the scoreboard) and calls the sample_* wrappers below with the already-folded
  // always_comb/wire value as the argument — "接一根线到 sample 调用". The handle is
  // the only plumbing; no fact is recomputed here.
  static xbar_functional_coverage m_probe = null;

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

  // Decode destination of one AW/AR (spec §3.2/§3.3/§4.2), classified by the
  // scoreboard at the SAME decode_mst_port() call its routing reference model
  // uses (single source of truth) — never a second decode. cg_decode_error bin.
  typedef enum bit [1:0] {
    DR_HIT_RULE     = 2'd0, // matched an address rule → a mapped master port
    DR_MISS_DEFAULT = 2'd1, // matched no rule, routed to the default master port
    DR_MISS_ERR_SLV = 2'd2  // matched no rule, no default → err_slv (DECERR)
  } decode_route_e;

  // Which spec §5.2.6 miss-ordering留痕 situation this sample records. The two
  // arms come from two fact sources on purpose (see cg_miss_order): COEXIST from
  // the scoreboard's err_order_q, ERRBUCKET from the stall-SVA err-bucket fold.
  typedef enum bit {
    MO_COEXIST   = 1'b0, // §5.2.6 clause 2.a: same FULL id hit+miss both in flight
    MO_ERRBUCKET = 1'b1  // §5.2.6 clause 2.b: same low bucket, diff full id, one err
  } miss_order_e;

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
      bins cfgE     = {5}; // 6x8 FallThrough=1    (M4-FT01)
    }
  endgroup

  // ---- cg_fallthrough (non-decisional, testplan M4-FT01, spec §2.1/§7.3.1)
  // Whether a slave port's AW and its (first) W beat were EVER accepted on
  // the same sampled edge (fed by slvport_monitor's own external valid/
  // ready observation — never a second decode of DUT-internal state). Same
  // "entered-only" convention as cg_default_port_tracked/cg_xbucket_total
  // above: sampled only when the situation is observed, so samples=0 means
  // "never witnessed this run" and is expected/structural for every config
  // point except cfgE (FallThrough=1'b1). SPEC-7.4.3 red line: this bin
  // draws no verdict — pass/fail never depends on whether it fires.
  covergroup cg_fallthrough with function sample(bit same_cycle_aw_w);
    option.per_instance = 1;
    cp_same_cycle: coverpoint same_cycle_aw_w {
      bins hit = {1'b1};
    }
  endgroup

  // ==== M3 covergroups (functional_coverage.md §4 "M3 覆盖点清单") ============
  // Sampling instant / hook obey §1 C1.1/C1.2. §4's opening scopes decisional-
  // adjacency: every §4 group is 非判决留痕 EXCEPT cg_decode_error /
  // cg_decerr_shape — those two record a situation that IS separately verdicted
  // by the scoreboard's SB_ROUTE / SB_DECERR_* checks (spec §4.3/§4.4); the
  // covergroup itself still renders NO pass/fail (functional_coverage.md §0 hard
  // rule holds for all groups here), it only proves those verdicts were exercised
  // on more than the trivial single-beat / single-destination shape.

  // ---- cg_decode_error (spec §3.2/§3.3/§4.2, M3-DE01/DE02) ---------------
  // The reference model's decode destination for this AW/AR, crossed with source
  // slave port × direction. Classified by the scoreboard at write_slv_req from the
  // very decode_mst_port() result its routing model already computed (rule-only
  // re-call with default off distinguishes HIT_RULE from MISS_DEFAULT — the same
  // single-source function, not a re-derived decoder).
  covergroup cg_decode_error with function sample(decode_route_e route,
                                                  bit is_write,
                                                  int unsigned src_port);
    option.per_instance = 1;
    cp_route: coverpoint route {
      bins hit_rule          = {DR_HIT_RULE};
      bins miss_default_port = {DR_MISS_DEFAULT};
      bins miss_err_slv      = {DR_MISS_ERR_SLV};
    }
    cp_src_port: coverpoint src_port {
      bins port[] = {[0:xbar_types_pkg::NO_SLV_PORTS-1]};
    }
    cp_dir: coverpoint is_write {
      bins write = {1'b1};
      bins read  = {1'b0};
    }
    x_route_src_dir: cross cp_route, cp_src_port, cp_dir;
  endgroup

  // ---- cg_decerr_shape (spec §4.3, M3-DE01) -----------------------------
  // For a decode-error (err_slv) transaction: was its burst a single beat
  // (AxLEN==0) or multi-beat (AxLEN>0), crossed with direction — proof that
  // §4.3's beat-count judgement (reads return AxLEN+1 DECERR beats, writes a
  // single B) is not verified only on the trivial single-beat burst. AxLEN is
  // taken from the same ro.len the SB_DECERR_RBEATS check uses.
  covergroup cg_decerr_shape with function sample(bit len_gt0, bit is_write);
    option.per_instance = 1;
    cp_len: coverpoint len_gt0 {
      bins len_eq_0 = {1'b0};
      bins len_gt_0 = {1'b1};
    }
    cp_dir: coverpoint is_write {
      bins write = {1'b1};
      bins read  = {1'b0};
    }
    x_len_dir: cross cp_len, cp_dir;
  endgroup

  // ---- cg_miss_order (non-decisional, spec §5.2.6 clause 2.a/2.b, M3-OR04) --
  // Two 留痕 bins from two fact sources (never one judgement computed twice):
  //   same_full_id_hit_miss_coexist       — the scoreboard's err_order_q holds a
  //     hit(is_err=0) AND a miss(is_err=1) owed response for ONE full id at once
  //     (clause 2.a, the assertable dimension SB_DECERR_ORDER verdicts). Without
  //     this cover, "the coexistence was really reached" and "the ordering check
  //     ran vacuously" look identical in the report.
  //   same_bucket_diff_full_id_with_err_slv — the stall-SVA's aw_err_bucket_now /
  //     ar_err_bucket_now fold (the c_bug25_errbucket cover source): a same low
  //     bucket, DIFFERENT full id, one-leg-via-err_slv corner was reached (clause
  //     2.b, the deliberately EXCLUDED dimension). Named by clause 2.b precisely
  //     so "excluded on purpose" and "forgot to write" stop looking the same.
  covergroup cg_miss_order with function sample(miss_order_e situ);
    option.per_instance = 1;
    cp_miss: coverpoint situ {
      bins same_full_id_hit_miss_coexist         = {MO_COEXIST};
      bins same_bucket_diff_full_id_with_err_slv = {MO_ERRBUCKET};
    }
  endgroup

  // ---- cg_default_port_tracked (non-decisional, BUG-0025 clause-1 guard) ---
  // Did a default-master-port-routed transaction ENTER axi_xbar_stall_sva's in-
  // flight tracking table? Sampled (value always "entered") only when that
  // module's own aw_via_default / ar_via_default fold fires at an accepted AW/AR
  // — the exact c_bug25_default cover source. Structurally 0 before the BUG-0025
  // fix (default traffic was dropped from tracking); >0 once M3-DE02 enables a
  // default port and sends unmapped-address traffic. spec §3.3/§5.2.6 clause 1.
  covergroup cg_default_port_tracked with function sample(bit entered);
    option.per_instance = 1;
    cp_entered: coverpoint entered {
      bins entered = {1'b1};
    }
  endgroup

  // ---- cg_xbucket_total (non-decisional, testplan M3-TL01, BUG-0010
  // regression_guard, spec §5.4.1) ------------------------------------------
  // spec §5.4.1: each slave port counts in-flight transactions per (low
  // AxiIdUsedSlvPorts-bit ID bucket x direction) independently. This bin
  // records whether, at some accepted AW/AR, the SUM of that one slave
  // port's per-bucket in-flight counts (same direction) exceeded the
  // documented MaxMstTrans ceiling WHILE >=2 distinct buckets were
  // simultaneously non-empty — the flat/aggregate reading M3-TL01 exists to
  // exercise. Fed by the scoreboard's own or_open_q bookkeeping (the exact
  // per-(port,bucket,direction) table cg_tx_limit already reads), summed
  // across buckets — no second decode, no RTL-derived threshold (CLAUDE.md
  // input boundary): the ceiling compared against is Cfg.MaxMstTrans from
  // xbar_types_pkg, the pinned parameter-definition file. Sampled only when
  // the condition holds (same "entered"-only convention as
  // cg_default_port_tracked above).
  covergroup cg_xbucket_total with function sample(bit combined_over_limit_multibucket);
    option.per_instance = 1;
    cp_combined: coverpoint combined_over_limit_multibucket {
      bins hit = {1'b1};
    }
  endgroup

  // ---- cg_live_addr_map (non-decisional, BUG-0031 positive witness) -------
  // The target master port the STALL-SVA computed for a transaction hitting the
  // moved-rule region after reconfiguration — sampled from that module's aw_tgt /
  // ar_tgt fold at an accepted moved-region hit (the c_bug31_livev1 fact source).
  // new_version_idx (CFG01_MOVED_IDX) is reachable ONLY if the decode path used
  // the runtime (V1) table; the compile-time V0 table routes this region to idx 0
  // (old_version_idx). spec §3.4; M3-CFG02.
  covergroup cg_live_addr_map with function sample(int unsigned tgt);
    option.per_instance = 1;
    cp_live_tgt: coverpoint tgt {
      bins old_version_idx = {0};
      bins new_version_idx = {xbar_types_pkg::CFG01_MOVED_IDX};
    }
  endgroup

  int unsigned n_addr_reconfig;
  int unsigned n_stall;
  int unsigned n_tx_limit;
  int unsigned n_w_order;
  int unsigned n_atop;
  int unsigned n_atop_read;
  int unsigned n_cfg_point;
  int unsigned n_decode_error;
  int unsigned n_decerr_shape;
  int unsigned n_miss_order;
  int unsigned n_default_port;
  int unsigned n_live_addr;
  int unsigned n_xbucket_total;
  int unsigned n_fallthrough;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg_addr_reconfig         = new();
    cg_stall                 = new();
    cg_tx_limit              = new();
    cg_w_order               = new();
    cg_atop                  = new();
    cg_atop_read_interaction = new();
    cg_cfg_point             = new();
    cg_decode_error          = new();
    cg_decerr_shape          = new();
    cg_miss_order            = new();
    cg_default_port_tracked  = new();
    cg_live_addr_map         = new();
    cg_xbucket_total         = new();
    cg_fallthrough           = new();
    // Publish this single instance for the stall-SVA instrumentation bridge
    // (see m_probe's declaration). One scoreboard builds one fcov, so the last
    // (only) assignment is the live collector.
    m_probe = this;
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

  // ---- M3 sample wrappers (functional_coverage.md §4) --------------------
  // cg_decode_error / cg_decerr_shape / cg_miss_order(COEXIST) are driven by the
  // scoreboard (scoreboard_refmodel.sv). cg_miss_order(ERRBUCKET),
  // cg_default_port_tracked, cg_live_addr_map are driven by the stall-SVA
  // instrumentation bridge through m_probe (tb/sva/axi_xbar_stall_sva.sv), each
  // fed an already-folded fact — this file re-derives nothing.
  function void sample_decode_error(decode_route_e route, bit is_write,
                                    int unsigned src_port);
    cg_decode_error.sample(route, is_write, src_port);
    n_decode_error++;
  endfunction

  function void sample_decerr_shape(bit len_gt0, bit is_write);
    cg_decerr_shape.sample(len_gt0, is_write);
    n_decerr_shape++;
  endfunction

  function void sample_miss_order(miss_order_e situ);
    cg_miss_order.sample(situ);
    n_miss_order++;
  endfunction

  function void sample_default_port_tracked(bit entered);
    cg_default_port_tracked.sample(entered);
    n_default_port++;
  endfunction

  function void sample_live_addr_map(int unsigned tgt);
    cg_live_addr_map.sample(tgt);
    n_live_addr++;
  endfunction

  // Driven directly by the scoreboard (scoreboard_refmodel.sv
  // write_slv_req_accept), which owns the or_open_q per-(port,bucket,
  // direction) table this bin sums — testplan M3-TL01 / BUG-0010
  // regression_guard, spec §5.4.1.
  function void sample_xbucket_total(bit combined_over_limit_multibucket);
    cg_xbucket_total.sample(combined_over_limit_multibucket);
    n_xbucket_total++;
  endfunction

  // Driven directly by slvport_monitor's own external aw_valid&&aw_ready&&
  // w_valid&&w_ready fold — testplan M4-FT01, spec §2.1/§7.3.1. Non-
  // decisional (see cg_fallthrough header above).
  function void sample_fallthrough(bit same_cycle_aw_w);
    cg_fallthrough.sample(same_cycle_aw_w);
    n_fallthrough++;
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
      $sformatf("cg_decode_error: samples=%0d inst_cov=%0.2f%% | cg_decerr_shape: samples=%0d inst_cov=%0.2f%% | cg_miss_order: samples=%0d inst_cov=%0.2f%% | cg_default_port_tracked: samples=%0d inst_cov=%0.2f%% | cg_live_addr_map: samples=%0d inst_cov=%0.2f%% | cg_xbucket_total: samples=%0d inst_cov=%0.2f%%",
                 n_decode_error, cg_decode_error.get_inst_coverage(),
                 n_decerr_shape, cg_decerr_shape.get_inst_coverage(),
                 n_miss_order,   cg_miss_order.get_inst_coverage(),
                 n_default_port, cg_default_port_tracked.get_inst_coverage(),
                 n_live_addr,    cg_live_addr_map.get_inst_coverage(),
                 n_xbucket_total, cg_xbucket_total.get_inst_coverage()),
      UVM_LOW)
    `uvm_info("FCOV_SUMMARY",
      $sformatf("cg_fallthrough samples=%0d inst_cov=%0.2f%%",
                 n_fallthrough, cg_fallthrough.get_inst_coverage()),
      UVM_LOW)
    `uvm_info("FCOV_SUMMARY",
      $sformatf("cg_decode_error coverpoints: cp_route=%0.2f%% cp_src_port=%0.2f%% cp_dir=%0.2f%% x_route_src_dir=%0.2f%% | cg_decerr_shape cp_len=%0.2f%% cp_dir=%0.2f%% x_len_dir=%0.2f%% | cg_miss_order cp_miss=%0.2f%% | cg_default_port_tracked cp_entered=%0.2f%% | cg_live_addr_map cp_live_tgt=%0.2f%%",
                 cg_decode_error.cp_route.get_inst_coverage(),
                 cg_decode_error.cp_src_port.get_inst_coverage(),
                 cg_decode_error.cp_dir.get_inst_coverage(),
                 cg_decode_error.x_route_src_dir.get_inst_coverage(),
                 cg_decerr_shape.cp_len.get_inst_coverage(),
                 cg_decerr_shape.cp_dir.get_inst_coverage(),
                 cg_decerr_shape.x_len_dir.get_inst_coverage(),
                 cg_miss_order.cp_miss.get_inst_coverage(),
                 cg_default_port_tracked.cp_entered.get_inst_coverage(),
                 cg_live_addr_map.cp_live_tgt.get_inst_coverage()),
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
