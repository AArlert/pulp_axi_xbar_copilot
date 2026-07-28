// tb/scoreboard_refmodel.sv — M1 UVM env: address-routing / ID-prefix /
// data-integrity reference model + scoreboard (design-prompt
// scoreboard_refmodel.md). `include-d from tb_pkg.sv. Every expected value
// below traces to doc/spec.md as cited; nothing here reads vendor/ RTL
// internals — only the two shared, spec-derived functions in
// xbar_types_pkg (decode_mst_port §3.1/§3.2, predict_beat_data, itself
// built on axi_pkg::beat_addr — AXI4 baseline math, spec §1).
//
// M1-01 active judgement paths (scoreboard_refmodel.md §7):
//   - request-side routing + ID-prefix (§3, §5.1): matches each slv-side
//     request against the mst-side request the crossbar produced for it,
//     keyed by the *expected* master-side ID (source-port-prefixed,
//     spec §5.1.1) — any DUT deviation from the prefix formula manifests
//     as a lookup miss.
//   - response payload / resp code (§1, C4.2): judged entirely from the
//     slv-port round trip (predict_beat_data for reads, RESP_OKAY check for
//     both directions) — deliberately does not need to cross-reference the
//     mst-side responder's internal state.
// Decode-error (§4, C2 in the design prompt) and stall/ordering (§5.2/§5.4,
// C5) remain documented-but-unexercised stubs here — M1-01 sends no
// unmapped address and never has two outstanding requests on one slv port
// (uvm_env.md C2.4 / this scoreboard's own single-pending-record-per-id
// invariant), so those branches are simply never hit; M2/M3 activate them
// (per the design prompt's own note in scoreboard_refmodel.md §7).

`uvm_analysis_imp_decl(_slv_req)
`uvm_analysis_imp_decl(_mst_req)
`uvm_analysis_imp_decl(_resp)

class xbar_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(xbar_scoreboard)

  uvm_analysis_imp_slv_req #(axi_req_obs, xbar_scoreboard)  slv_req_imp;
  uvm_analysis_imp_mst_req #(axi_req_obs, xbar_scoreboard)  mst_req_imp;
  uvm_analysis_imp_resp    #(axi_resp_obs, xbar_scoreboard) resp_imp;

  typedef struct {
    int unsigned            exp_mst_port;
    bit                     is_write;
    xbar_types_pkg::addr_t  addr;
    axi_pkg::len_t          len;
    axi_pkg::size_t         size;
    axi_pkg::burst_t        burst;
    axi_pkg::atop_t         atop; // spec §6.1 pass-through expectation
    xbar_types_pkg::data_t  wdata[$];
    xbar_types_pkg::strb_t  wstrb[$];
    // Functional coverage only (functional_coverage.md §2 cg_addr_reconfig,
    // spec §3.4): was this transaction's own accept instant after the first
    // runtime address-table/default-port change? Recorded at accept, sampled
    // when this record's routing judgement lands. Never a judgement input.
    bit                     post_change;
  } pend_rec_t;

  // Keyed by {direction, expected master-side id}. A *FIFO queue* per key (not
  // a single slot): read and write are independent AXI channels so the
  // direction bit keeps a same-id write and read apart, and different slv
  // ports' ID spaces are disjoint (spec §5.1.4). Most scenarios keep at most
  // one outstanding request per (dir, full-id) key — the queue is then depth 1
  // and behaves exactly like the old single slot. But M2-TL01/TL02
  // (uvm_env.md C5.3) deliberately keep SEVERAL same-full-id requests
  // outstanding at once to the SAME target master port (legal AXI: same-ID
  // same-target transactions preserve order, spec §5.2.4), which the DUT
  // completes strictly in acceptance order — so pushing at slv-side accept and
  // popping the front at each mst-side observation pairs them correctly.
  local pend_rec_t pending_by_id[bit [xbar_types_pkg::ID_W_MST:0]][$];

  // {direction, mst-side id} key builder for pending_by_id.
  local function bit [xbar_types_pkg::ID_W_MST:0] pend_key(
      input bit is_write, input bit [xbar_types_pkg::ID_W_MST-1:0] mst_id);
    return {is_write, mst_id};
  endfunction

  // ---- C3.2 source-port response-routing (spec §5.1.2/§5.1.3) -----------
  // Independent of the payload/resp-code judgement in write_resp: every B/R
  // observed at slv port p must trace to a request p *itself* issued with
  // that (direction, slv-side id). A response landing on a port that has no
  // matching outstanding request is a cross-port misdelivery — the ID-prefix
  // high $clog2(NoSlvPorts) bits routed the response to the wrong source
  // slave port. Works for writes too (B carries no payload, so the read-data
  // check cannot catch a write-B misroute). Count-based because the same
  // (port,dir,slv-id) recurs across the test; per *exact* (port,dir,slv-id)
  // key the live count is always 0/1 (M2-OR01/OR02's two-outstanding
  // constructions use two different slv-ids per pair — see pending_by_id's
  // comment above for why).
  local int unsigned resp_expect[int unsigned];
  int unsigned resp_route_match_cnt;
  int unsigned resp_route_mismatch_cnt;

  int unsigned route_match_cnt;
  int unsigned route_mismatch_cnt;
  int unsigned resp_match_cnt;
  int unsigned resp_mismatch_cnt;

  // key = {port, direction, slv-side id}; slv id is 5 bits (< 32), dir 1 bit.
  local function int unsigned resp_key(input int unsigned port,
                                       input bit is_write,
                                       input xbar_types_pkg::id_slv_t sid);
    return (port << 6) | (int'(is_write) << 5) | int'(sid);
  endfunction

  // ---- C5.1/C5.2 same-ID (low AxiIdUsedSlvPorts bits) cross-port stall /
  // non-stall (spec §5.2.1/§5.2.2/§5.2.3/§5.2.4) — TB-side cross-check
  // independent of sva_bind.md C3.2's cycle-accurate SVA (same spec clause,
  // different observation path). "Open" = AW/AR accepted, matching B/rlast
  // not yet observed, keyed by (source slv port, low-id-bucket, direction)
  // — a *queue* (not a single slot) because M2-OR01/OR02 legitimately keep
  // two same-bucket/direction records open at once (the driver-side
  // rationale for slvport_agent.sv's aw_pending_q/ar_pending_q
  // generalization applies here too).
  //
  // Judgement-gate note (BUG-0013, OPEN, pending rev arbitration): checking
  // spec §5.2.1's literal external-boundary reading at *accept* time ("a
  // different-target request must not be accepted while an older one is
  // still open") fails deterministically on this repo's pinned baseline
  // (`LatencyMode=CUT_ALL_AX`, spec §7.2) — `make run TEST=m2_or01_stall_test
  // SEED=1` shows the crossbar's `SpillAw`/`SpillAr` elastic buffering (ahead
  // of the core per-ID decision logic) lets a second request be externally
  // accepted before that decision logic evaluates it against the first.
  // Crucially, completion *order* (B/rlast) was still exactly preserved in
  // that same repro, satisfying the AXI-ordering purpose spec §5.2.3 states
  // for this mechanism. Until rev arbitrates, this check's PASS/FAIL gate is
  // therefore the reading-independent §5.2.3 property below (checked at
  // *completion* time, using accept_time as the ordering key): a completing
  // B/rlast must not overtake an older, still-open, same-bucket/direction,
  // different-target request. See BUG-0013 ## fix / ## regression_guard and
  // tb/sva/axi_xbar_stall_sva.sv's matching note.
  typedef struct {
    int unsigned              mst_port;
    xbar_types_pkg::id_slv_t  slv_id;
    time                      accept_time;
    // Functional coverage only (functional_coverage.md §2 cg_stall, spec
    // §5.2): this request's situation w.r.t. §5.2.1 at its own accept
    // instant, classified once here and sampled when the completion-time
    // judgement below lands. Never a judgement input.
    xbar_functional_coverage::stall_class_e stall_cls;
  } or_open_rec_t;
  local or_open_rec_t or_open_q[int unsigned][$];
  int unsigned         or_stall_violation_cnt;

  // key = {port, direction, low AxiIdUsedSlvPorts-bit id bucket}.
  local function int unsigned or_key(input int unsigned port,
                                     input bit is_write,
                                     input int unsigned bucket);
    return (port << 8) | (int'(is_write) << 7) | bucket;
  endfunction

  local function int unsigned id_bucket(input xbar_types_pkg::id_slv_t sid);
    return int'(sid) & ((1 << xbar_types_pkg::Cfg.AxiIdUsedSlvPorts) - 1);
  endfunction

  // ---- C5.4/C5.5(b) same-source W-burst order (spec §5.5.1, M2-WO01) ------
  // For each source slave port S targeting master port P, S's write bursts
  // must complete at P in the order S's own AWs were accepted (W burst stays
  // in order with its AW — spec §5.5.1). Keyed strictly per (source port,
  // target master port): this check NEVER compares one source against another
  // and NEVER asserts any cross-source service order — that would be the
  // round-robin arbitration occurrence, an implementation detail explicitly
  // out of bounds (spec §5.5.4 / C6.2, REV-006 §4.3 hard red line). The
  // ordering key is accept_time (the AW handshake instant recorded slave-side
  // — reusable infra, scoreboard_refmodel.md C5.5(a)); the expected order is
  // therefore the *slave-side* AW-accept order, a TB-driven ground truth
  // (each slvport driver issues one W burst per AW in order), against which
  // the master-side completion order is judged. accept_time is strictly
  // monotonic per source (one AW accepted per handshake), so within one
  // (source, target) queue the "oldest still-open" entry is unambiguous.
  typedef struct {
    xbar_types_pkg::id_mst_t mst_id;
    time                     accept_time;
  } worder_rec_t;
  local worder_rec_t worder_pend[int unsigned][$];
  int unsigned       worder_match_cnt;
  int unsigned       worder_mismatch_cnt;

  // key = {source slv port, target mst port}; both < NoSlvPorts/NoMstPorts.
  local function int unsigned worder_key(input int unsigned src_port,
                                         input int unsigned tgt_port);
    return (src_port << 8) | tgt_port;
  endfunction

  // ---- C6.3 ATOP atomic-load pair tracking (spec §6.3, M2-AT01) ----------
  // One record per in-flight atomic load, keyed by (source slv port, full
  // slv-side id) — unambiguous because the env guarantees the ATOP's ID
  // differs from every in-flight ID on its port (spec §6.4, uvm_env.md
  // C2.4/C5.5; SVA C3.5 property 2 watches that discipline independently).
  // The record clears only once *both* the B and the R(last) with that ID
  // returned to the source port; anything still open at end of test is a
  // §6.3 violation (reported in report_phase — "both must eventually
  // appear", with no B-vs-R order or latency asserted, spec §7.4).
  typedef struct {
    bit b_seen;
    bit r_seen;
    // Functional coverage only (functional_coverage.md §2
    // cg_atop_read_interaction, spec §6.5 + §5.2.5): was a normal read with
    // the same low-ID bucket in flight on this port when the atomic load was
    // issued? Recorded at accept, sampled when the pair completes. Explicitly
    // non-decisional — spec §6.5 declares the resulting cross-direction stall
    // normal design behaviour.
    bit collide_read;
  } atop_pend_t;
  local atop_pend_t atop_pend[int unsigned];
  int unsigned      atop_pair_cnt;

  // key = {port, full slv-side id}; slv id is 5 bits.
  local function int unsigned atop_key(input int unsigned port,
                                       input xbar_types_pkg::id_slv_t sid);
    return (port << 5) | int'(sid);
  endfunction

  // ---- C1.5 address-table version tracking (spec §3.1/§3.4, M2-CFG01) -----
  // The address table / default-port config is runtime-variable (spec §3.4).
  // The reference model must decode each transaction against the table version
  // in effect at *that transaction's own AW/AR handshake completion instant*
  // (scoreboard_refmodel.md C1.5) — not a compile-time constant. This env
  // observes the live cfg_if signal (the same physical bus tb_top drives to
  // the DUT and to the C3.1 SVA — single source of truth, no second snapshot)
  // and records a timestamped history of its value; write_slv_req below looks
  // up the version whose effective time is the latest <= the transaction's
  // accept_time. For every non-reconfiguring scenario the history holds only
  // the baseline entry, so the decode result is identical to the old
  // constant-table path (no M1/other-M2 regression).
  virtual xbar_cfg_if cfg_vif;
  typedef struct {
    xbar_types_pkg::rule_t [xbar_types_pkg::NO_ADDR_RULES-1:0] addr_map;
    logic [xbar_types_pkg::NO_SLV_PORTS-1:0]                    en_def;
    logic [xbar_types_pkg::NO_SLV_PORTS-1:0]
          [xbar_types_pkg::MST_PORT_IDX_W-1:0]                  def_port;
    time                                                        eff_time;
  } cfg_snap_t;
  local cfg_snap_t cfg_hist[$];

  // Latest table version whose effective time <= t (cfg_hist is time-ordered
  // by construction). Defensive fallback to the compile-time baseline if the
  // history is somehow empty (should never happen — the baseline is recorded
  // at reset deassert, before any traffic).
  local function cfg_snap_t version_at(time t);
    cfg_snap_t r;
    bit        found;
    found = 1'b0;
    foreach (cfg_hist[i]) begin
      if (cfg_hist[i].eff_time <= t) begin
        r     = cfg_hist[i];
        found = 1'b1;
      end
    end
    if (!found) begin
      r.addr_map = xbar_types_pkg::ADDR_MAP;
      r.en_def   = '0;
      r.def_port = '0;
      r.eff_time = 0;
    end
    return r;
  endfunction

  // ---- M2 functional coverage collector (functional_coverage.md C1.1) -----
  // Owned by the scoreboard so every sample can be taken at the exact instant
  // this scoreboard's own judgement for that transaction lands (C1.2), from
  // the very objects/state the judgement used — no second decode path, no bus
  // re-parsing. Coverage never feeds back into any check.
  xbar_functional_coverage fcov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    slv_req_imp = new("slv_req_imp", this);
    mst_req_imp = new("mst_req_imp", this);
    resp_imp    = new("resp_imp", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual xbar_cfg_if)::get(this, "", "cfg_vif", cfg_vif))
      `uvm_fatal("NOCFGVIF", "xbar_scoreboard: cfg_vif not set")
    fcov = xbar_functional_coverage::type_id::create("fcov", this);
  endfunction

  // Live-observe the config bus and append a timestamped snapshot whenever it
  // changes (spec §3.4 runtime variability). The baseline value in effect from
  // time 0 is recorded first (eff_time 0); each subsequent change is stamped at
  // its actual $time. M2-CFG01 produces exactly one extra entry.
  virtual task run_phase(uvm_phase phase);
    cfg_snap_t s, last;
    @(posedge cfg_vif.clk_i);
    while (cfg_vif.rst_ni !== 1'b1) @(posedge cfg_vif.clk_i);
    s.addr_map = cfg_vif.addr_map;
    s.en_def   = cfg_vif.en_default_mst_port;
    s.def_port = cfg_vif.default_mst_port;
    s.eff_time = 0;
    cfg_hist.push_back(s);
    last = s;
    forever begin
      @(posedge cfg_vif.clk_i);
      if (cfg_vif.addr_map            !== last.addr_map
          || cfg_vif.en_default_mst_port !== last.en_def
          || cfg_vif.default_mst_port    !== last.def_port) begin
        s.addr_map = cfg_vif.addr_map;
        s.en_def   = cfg_vif.en_default_mst_port;
        s.def_port = cfg_vif.default_mst_port;
        s.eff_time = $time;
        cfg_hist.push_back(s);
        last = s;
      end
    end
  endtask

  local function bit [xbar_types_pkg::ID_W_MST-1:0] build_exp_id(
      input int unsigned slv_port, input xbar_types_pkg::id_slv_t slv_id);
    return {slv_port[$clog2(xbar_types_pkg::NO_SLV_PORTS)-1:0], slv_id};
  endfunction

  // ---- request-side, slv-port stream: build the expectation (§3.1/§3.2,
  // §5.1.1) --------------------------------------------------------------
  virtual function void write_slv_req(axi_req_obs ro);
    pend_rec_t rec;
    bit [xbar_types_pkg::ID_W_MST-1:0] exp_id;
    int unsigned exp_port;
    bit hit;

    // C1.5 (spec §3.4): decode against the table version in effect at this
    // transaction's own AW/AR handshake instant (ro.accept_time), not a
    // compile-time constant — so batch-1 and batch-2 of M2-CFG01 each route
    // by their own live table (§3.1/§3.2 rule move, §3.3 default port).
    begin
      cfg_snap_t snap;
      snap = version_at(ro.accept_time);
      hit  = xbar_types_pkg::decode_mst_port(ro.addr, snap.addr_map,
               snap.en_def[ro.port_idx], snap.def_port[ro.port_idx], exp_port);
    end
    if (!hit) begin
      `uvm_error("SB_DECODE",
        $sformatf("slv port %0d addr 'h%0h matched no rule and no enabled default master port at accept_time %0t — stimulus must not send a decode-error address (spec §3.2/§3.3/§4)",
                   ro.port_idx, ro.addr, ro.accept_time))
      return;
    end

    // Coverage bookkeeping (cg_addr_reconfig, spec §3.4): entry 0 of cfg_hist
    // is the baseline table recorded at reset release, so "a later entry is
    // already in effect at this accept instant" is exactly "this transaction
    // belongs to a post-change batch".
    rec.post_change = 1'b0;
    foreach (cfg_hist[i])
      if (i > 0 && cfg_hist[i].eff_time <= ro.accept_time) rec.post_change = 1'b1;

    rec.exp_mst_port = exp_port;
    rec.is_write      = ro.is_write;
    rec.addr          = ro.addr;
    rec.len           = ro.len;
    rec.size          = ro.size;
    rec.burst         = ro.burst;
    rec.atop          = ro.atop;
    if (ro.is_write) begin
      rec.wdata = ro.wdata;
      rec.wstrb = ro.wstrb;
    end
    exp_id = build_exp_id(ro.port_idx, ro.id[xbar_types_pkg::ID_W_SLV-1:0]);
    pending_by_id[pend_key(ro.is_write, exp_id)].push_back(rec);

    // C3.2: record that source port ro.port_idx now expects a response for
    // this (direction, slv-side id) back on its own port (spec §5.1.2/§5.1.3).
    resp_expect[resp_key(ro.port_idx, ro.is_write,
                         ro.id[xbar_types_pkg::ID_W_SLV-1:0])]++;

    // ---- C6.3 (spec §6.3, M2-AT01): an atomic load owes its source port
    // *two* responses — the B (already registered by the write-direction
    // resp_expect above) and an R burst with the same ID (registered here on
    // the read direction so the C3.2 route check accepts it and report_phase
    // catches an R that never comes). A dedicated pair record additionally
    // ties the two halves together.
    if (ro.is_write && ro.atop[axi_pkg::ATOP_R_RESP]) begin
      int unsigned ak;
      int unsigned rd_k;
      bit          collide;
      ak = atop_key(ro.port_idx, ro.id[xbar_types_pkg::ID_W_SLV-1:0]);
      if (atop_pend.exists(ak))
        `uvm_error("SB_ATOP_OVERLAP",
          $sformatf("slv port %0d issued atomic load id 'h%0h while a previous atomic load with the same id is still awaiting B/R — env violated its own spec §6.4 ID-uniqueness discipline (TB_BUG suspect first)",
                     ro.port_idx, ro.id))
      // Coverage bookkeeping (cg_atop_read_interaction, spec §6.5 + §5.2.5):
      // a normal READ still open on this port in the same low-ID bucket is the
      // situation in which the atomic load's shadow-AR can produce a
      // cross-direction false-conflict stall. Observation only.
      rd_k = or_key(ro.port_idx, 1'b0,
                    id_bucket(ro.id[xbar_types_pkg::ID_W_SLV-1:0]));
      collide = or_open_q.exists(rd_k) && or_open_q[rd_k].size() != 0;
      atop_pend[ak] = '{b_seen: 1'b0, r_seen: 1'b0, collide_read: collide};
      resp_expect[resp_key(ro.port_idx, 1'b0,
                           ro.id[xbar_types_pkg::ID_W_SLV-1:0])]++;
    end

    // ---- C5.1/C5.2/C5.5: register this AW/AR's accept as a new open
    // record (BUG-0013: the violation check itself runs at *completion*
    // time in write_resp below, not here — see that block's comment).
    begin
      int unsigned bucket;
      int unsigned k;
      int unsigned k_opp;
      xbar_functional_coverage::stall_class_e cls;
      bucket = id_bucket(ro.id[xbar_types_pkg::ID_W_SLV-1:0]);
      k     = or_key(ro.port_idx, ro.is_write,  bucket);
      k_opp = or_key(ro.port_idx, !ro.is_write, bucket);
      // Coverage classification (cg_stall, spec §5.2) — read off the very
      // open-record table the §5.2.3 completion check uses, so bin and verdict
      // can never disagree. Priority: a same-direction different-target
      // sibling is §5.2.1's precondition even if an opposite-direction one
      // also happens to be open.
      cls = xbar_functional_coverage::SC_NONE;
      if (or_open_q.exists(k) && or_open_q[k].size() != 0) begin
        cls = xbar_functional_coverage::SC_SAME_TGT; // §5.2.4
        foreach (or_open_q[k][idx])
          if (or_open_q[k][idx].mst_port != exp_port)
            cls = xbar_functional_coverage::SC_STALLED; // §5.2.1
      end else if (or_open_q.exists(k_opp) && or_open_q[k_opp].size() != 0) begin
        cls = xbar_functional_coverage::SC_DIFF_DIR; // §5.2.1 direction scope
      end
      or_open_q[k].push_back('{exp_port, ro.id[xbar_types_pkg::ID_W_SLV-1:0],
                                ro.accept_time, cls});
      // cg_tx_limit (spec §2.1 MaxMstTrans row / §5.4.1): the in-flight count
      // of this (slave port, bucket, direction) group right after this
      // observed accept. Sampled here — not at completion — because an
      // in-flight count only exists at the accept instant; the event is the
      // monitor's observed AW/AR handshake (what actually happened, C1.2's
      // intent), never a driver-side intent.
      fcov.sample_tx_limit(or_open_q[k].size());
    end

    // ---- C5.4/C5.5(b) (spec §5.5.1): register this write's expected master-
    // side completion slot, ordered by slave-side AW accept_time within its
    // (source port, target master port) group. Writes only — reads have no W
    // channel (the atop shadow-R is registered read-side but never a W burst).
    if (ro.is_write) begin
      int unsigned wk;
      wk = worder_key(ro.port_idx, exp_port);
      worder_pend[wk].push_back('{exp_id, ro.accept_time});
    end
  endfunction

  // ---- request-side, mst-port stream: check the expectation (§3.1/§3.2,
  // §5.1.1, C4.1/C4.3) -----------------------------------------------------
  virtual function void write_mst_req(axi_req_obs ro);
    pend_rec_t rec;
    bit found;
    bit [xbar_types_pkg::ID_W_MST:0] key;
    key = pend_key(ro.is_write, ro.id[xbar_types_pkg::ID_W_MST-1:0]);
    found = pending_by_id.exists(key) && pending_by_id[key].size() != 0;
    if (!found) begin
      route_mismatch_cnt++;
      `uvm_error("SB_NOPEND",
        $sformatf("mst port %0d observed id 'h%0h with no matching pending record (spec §5.1.1 prefix formula violated, or unexpected transaction)",
                   ro.port_idx, ro.id))
      return;
    end
    rec = pending_by_id[key].pop_front(); // FIFO: oldest same-key request first
    if (pending_by_id[key].size() == 0) pending_by_id.delete(key);

    if (ro.is_write != rec.is_write || ro.port_idx != rec.exp_mst_port
        || ro.addr != rec.addr || ro.len != rec.len || ro.size != rec.size
        || ro.burst != rec.burst || ro.atop != rec.atop) begin
      route_mismatch_cnt++;
      `uvm_error("SB_ROUTE",
        $sformatf("routing/attr mismatch id 'h%0h: got port=%0d write=%0d addr='h%0h len=%0d atop='h%0h — expected port=%0d write=%0d addr='h%0h len=%0d atop='h%0h (spec §3.1/§3.2/§1/§6.1)",
                   ro.id, ro.port_idx, ro.is_write, ro.addr, ro.len, ro.atop,
                   rec.exp_mst_port, rec.is_write, rec.addr, rec.len, rec.atop))
      return;
    end
    if (ro.is_write) begin
      if (ro.wdata.size() != rec.wdata.size()) begin
        route_mismatch_cnt++;
        `uvm_error("SB_WDATA_LEN",
          $sformatf("id 'h%0h write beat count mismatch: got %0d expected %0d (spec §1)",
                     ro.id, ro.wdata.size(), rec.wdata.size()))
        return;
      end
      foreach (ro.wdata[k]) begin
        if (ro.wdata[k] !== rec.wdata[k] || ro.wstrb[k] !== rec.wstrb[k]) begin
          route_mismatch_cnt++;
          `uvm_error("SB_WDATA",
            $sformatf("id 'h%0h write beat %0d payload mismatch: got data='h%0h strb='h%0h expected data='h%0h strb='h%0h (spec §1 payload pass-through)",
                       ro.id, k, ro.wdata[k], ro.wstrb[k], rec.wdata[k], rec.wstrb[k]))
          return;
        end
      end

      // ---- C5.4/C5.5(b) (spec §5.5.1): this write burst just completed at
      // master port ro.port_idx. Its source slave port is the ID-prefix high
      // $clog2(NoSlvPorts) bits (spec §5.1.1). Verify no *older-accepted*
      // (smaller accept_time) write from the SAME source to the SAME target is
      // still outstanding — that would mean this burst overtook it, violating
      // "W burst stays in order with its AW" (spec §5.5.1). The comparison is
      // strictly within one (source, target) queue: it never looks at another
      // source's traffic, so it asserts nothing about cross-source service
      // order (spec §5.5.4 / C6.2 red line).
      begin
        int unsigned src_port;
        int unsigned wk;
        src_port = ro.id[xbar_types_pkg::ID_W_MST-1:xbar_types_pkg::ID_W_SLV];
        wk = worder_key(src_port, ro.port_idx);
        if (worder_pend.exists(wk)) begin
          int unsigned this_idx;
          bit          this_found;
          this_found = 1'b0;
          // Match the OLDEST still-open entry with this id (break on first).
          // When several same-source writes share one full id (M2-TL01 fills a
          // bucket via a few full ids, each used more than once), they complete
          // in acceptance order (same-id in-order, spec §5.2.4), so the front-
          // most is the one completing now; matching the newest instead would
          // falsely see older same-id entries as "overtaken". For distinct ids
          // (M2-WO01) there is exactly one match, so this is unchanged.
          foreach (worder_pend[wk][idx]) begin
            if (worder_pend[wk][idx].mst_id == ro.id) begin
              this_idx   = idx;
              this_found = 1'b1;
              break;
            end
          end
          if (this_found) begin
            bit reordered;
            // cg_w_order (spec §5.5, M2-WO01): at the instant this burst's
            // §5.5.1 order judgement lands, do >= 2 distinct SOURCE slave
            // ports have write bursts open towards this master port? Counted
            // from worder_pend (keys are {src, tgt}) before this entry is
            // removed. This records the cross-source convergence situation
            // itself; it asserts nothing about arbitration order (spec §5.5.4
            // red line). The cycle-exact "at W burst START" counterpart lives
            // in tb/sva/axi_xbar_worder_sva.sv's compete_start cover — the
            // scoreboard only observes a master-side write burst at its
            // w_last, so this is the burst-scoped image of the same situation.
            begin
              int unsigned n_src;
              n_src = 0;
              foreach (worder_pend[wk_i])
                if ((wk_i & 32'hff) == ro.port_idx
                    && worder_pend[wk_i].size() != 0) n_src++;
              fcov.sample_w_order(n_src >= 2);
            end
            reordered = 1'b0;
            foreach (worder_pend[wk][idx]) begin
              if (idx != this_idx
                  && worder_pend[wk][idx].accept_time
                       < worder_pend[wk][this_idx].accept_time) begin
                reordered = 1'b1;
                worder_mismatch_cnt++;
                `uvm_error("SB_WORDER",
                  $sformatf("src slv port %0d -> mst port %0d: write id 'h%0h (AW accepted @%0t) completed ahead of older still-open write id 'h%0h (AW accepted @%0t) from the SAME source — W burst did not stay in its own AW order (spec §5.5.1)",
                             src_port, ro.port_idx, ro.id,
                             worder_pend[wk][this_idx].accept_time,
                             worder_pend[wk][idx].mst_id,
                             worder_pend[wk][idx].accept_time))
              end
            end
            if (!reordered) worder_match_cnt++;
            worder_pend[wk].delete(this_idx);
            if (worder_pend[wk].size() == 0) worder_pend.delete(wk);
          end
        end
      end
    end

    // ---- functional coverage at the routing-judgement instant (this
    // transaction matched its expectation: port/attrs/payload all agree).
    // Source slave port = the master-side ID prefix (spec §5.1.1).
    begin
      int unsigned src_port;
      src_port = ro.id[xbar_types_pkg::ID_W_MST-1:xbar_types_pkg::ID_W_SLV];
      fcov.sample_addr_reconfig(rec.post_change, src_port); // spec §3.4
      if (ro.is_write && ro.atop != '0)                     // spec §6.3/§6.1
        fcov.sample_atop(src_port, ro.atop[axi_pkg::ATOP_R_RESP]);
    end
    route_match_cnt++;
  endfunction

  // ---- response-side (slv port round trip only): payload/resp-code
  // judgement (§1, C4.2) --------------------------------------------------
  virtual function void write_resp(axi_resp_obs ro);
    // C3.2 source-port response-routing check (spec §5.1.2/§5.1.3): this B/R
    // landed on slv port ro.port_idx — verify that port actually has an
    // outstanding request with this (direction, slv-side id). A miss means
    // the response was routed back to the wrong source port (ID-prefix
    // high-bit routing error) or is otherwise spurious. Runs independently of
    // the payload/resp-code judgement below (which continues regardless).
    begin
      int unsigned rk;
      rk = resp_key(ro.port_idx, ro.is_write, ro.id);
      if (!resp_expect.exists(rk) || resp_expect[rk] == 0) begin
        resp_route_mismatch_cnt++;
        `uvm_error("SB_RESP_ROUTE",
          $sformatf("slv port %0d observed a %s response id 'h%0h it never issued — cross-port misdelivery: response id-prefix routed to the wrong source slave port (spec §5.1.2/§5.1.3)",
                     ro.port_idx, ro.is_write ? "B(write)" : "R(read)", ro.id))
      end else begin
        resp_expect[rk]--;
        resp_route_match_cnt++;
      end
    end

    // ---- C6.3 (spec §6.3): mark this port+id's atomic-load pair half. Safe
    // to key on (port, id) alone: while the pair is open no other in-flight
    // transaction on this port may carry the same ID (spec §6.4 env
    // discipline), so a B/R with this ID can only belong to the atomic load.
    begin
      int unsigned ak;
      atop_pend_t  ap;
      ak = atop_key(ro.port_idx, ro.id);
      if (atop_pend.exists(ak)) begin
        ap = atop_pend[ak];
        if (ro.is_write) ap.b_seen = 1'b1;
        else             ap.r_seen = 1'b1;
        if (ap.b_seen && ap.r_seen) begin
          // cg_atop_read_interaction (spec §6.5 + §5.2.5): the §6.3 pair
          // judgement for this atomic load has just landed — record the
          // situation captured at its issue. Observation only.
          fcov.sample_atop_read_interaction(ap.collide_read);
          atop_pend.delete(ak);
          atop_pair_cnt++;
        end else begin
          atop_pend[ak] = ap;
        end
      end
    end

    // ---- C5.1/C5.3 (spec §5.2.1/§5.2.3, BUG-0013 anchor): this B/rlast is
    // completing now — if an *older* (earlier accept_time), still-open,
    // same-bucket/direction record with a *different* target exists, this
    // completion overtook it, i.e. a cross-master-port response reordering
    // (the exact thing spec §5.2.3 says the stall mechanism exists to
    // prevent). Checked here (at completion) rather than at accept time —
    // BUG-0013 — because this reading is independent of how quickly the
    // DUT's own elastic pipelining (`LatencyMode=CUT_ALL_AX`, spec §7.2)
    // externally accepts a same-bucket request relative to an older one.
    begin
      int unsigned bucket;
      int unsigned k;
      bucket = id_bucket(ro.id);
      k = or_key(ro.port_idx, ro.is_write, bucket);
      if (or_open_q.exists(k)) begin
        int unsigned this_idx;
        bit          this_found;
        this_found = 1'b0;
        foreach (or_open_q[k][idx]) begin
          if (or_open_q[k][idx].slv_id == ro.id) begin
            this_idx   = idx;
            this_found = 1'b1;
          end
        end
        if (this_found) begin
          foreach (or_open_q[k][idx]) begin
            if (idx != this_idx
                && or_open_q[k][idx].accept_time < or_open_q[k][this_idx].accept_time
                && or_open_q[k][idx].mst_port != or_open_q[k][this_idx].mst_port) begin
              or_stall_violation_cnt++;
              `uvm_error("SB_OR_REORDER",
                $sformatf("slv port %0d id-bucket 'h%0h dir=%s: id 'h%0h (accepted @%0t, mst %0d) completed ahead of older still-open id 'h%0h (accepted @%0t, mst %0d) — spec §5.2.1/§5.2.3 response reordering",
                           ro.port_idx, bucket, ro.is_write ? "W" : "R",
                           ro.id, or_open_q[k][this_idx].accept_time,
                           or_open_q[k][this_idx].mst_port,
                           or_open_q[k][idx].slv_id, or_open_q[k][idx].accept_time,
                           or_open_q[k][idx].mst_port))
            end
          end
          // cg_stall (spec §5.2): the §5.2.3 ordering judgement for this
          // transaction has just landed — sample the situation classified at
          // its own accept instant, crossed with its direction.
          fcov.sample_stall(or_open_q[k][this_idx].stall_cls, ro.is_write);
          or_open_q[k].delete(this_idx);
        end
        if (or_open_q[k].size() == 0) or_open_q.delete(k);
      end
    end

    if (ro.is_write) begin
      if (ro.resp[0] !== axi_pkg::RESP_OKAY) begin
        resp_mismatch_cnt++;
        `uvm_error("SB_BRESP",
          $sformatf("slv port %0d id 'h%0h B resp != OKAY ('b%0b) — happy-path smoke expects OKAY (testplan M1-01)",
                     ro.port_idx, ro.id, ro.resp[0]))
        return;
      end
      resp_match_cnt++;
      return;
    end
    // read: per-beat data must equal the shared deterministic predictor
    if (ro.rdata.size() != int'(ro.len) + 1) begin
      resp_mismatch_cnt++;
      `uvm_error("SB_RBEATS",
        $sformatf("slv port %0d id 'h%0h R beat count %0d != AxLEN+1 (%0d) (spec §1)",
                   ro.port_idx, ro.id, ro.rdata.size(), int'(ro.len) + 1))
      return;
    end
    foreach (ro.rdata[k]) begin
      xbar_types_pkg::data_t exp_data;
      exp_data = xbar_types_pkg::predict_beat_data(ro.addr, ro.size, ro.len,
                                                     ro.burst, k);
      if (ro.rdata[k] !== exp_data || ro.resp[k] !== axi_pkg::RESP_OKAY) begin
        resp_mismatch_cnt++;
        `uvm_error("SB_RDATA",
          $sformatf("slv port %0d id 'h%0h R beat %0d mismatch: got data='h%0h resp='b%0b expected data='h%0h resp=OKAY (spec §1/C4.2)",
                     ro.port_idx, ro.id, k, ro.rdata[k], ro.resp[k], exp_data))
        return;
      end
    end
    resp_match_cnt++;
  endfunction

  virtual function void report_phase(uvm_phase phase);
    int unsigned or_open_total;
    int unsigned worder_open_total;
    int unsigned pending_total;
    super.report_phase(phase);
    or_open_total = 0;
    foreach (or_open_q[k]) or_open_total += or_open_q[k].size();
    worder_open_total = 0;
    foreach (worder_pend[k]) worder_open_total += worder_pend[k].size();
    pending_total = 0;
    foreach (pending_by_id[k]) pending_total += pending_by_id[k].size();
    `uvm_info("SB_SUMMARY",
      $sformatf("route: match=%0d mismatch=%0d | resp: match=%0d mismatch=%0d | resp-route(C3.2): match=%0d mismatch=%0d | pending(unmatched at end)=%0d | stall(C5.1/C5.2): violations=%0d open(unmatched at end)=%0d | atop(C6.3): pairs=%0d open(unpaired at end)=%0d | worder(C5.4): match=%0d mismatch=%0d open(unmatched at end)=%0d",
                 route_match_cnt, route_mismatch_cnt, resp_match_cnt,
                 resp_mismatch_cnt, resp_route_match_cnt,
                 resp_route_mismatch_cnt, pending_total,
                 or_stall_violation_cnt, or_open_total, atop_pair_cnt,
                 atop_pend.num(), worder_match_cnt, worder_mismatch_cnt,
                 worder_open_total),
      UVM_LOW)
    if (pending_total != 0) begin
      `uvm_error("SB_DANGLING",
        $sformatf("%0d slv-side request(s) never observed a matching mst-side request — routing incomplete at end of test",
                   pending_total))
    end
    // C3.2: any source port still expecting a response never received back
    // on its own port means a B/R was dropped or misrouted (spec §5.1.2).
    foreach (resp_expect[k]) begin
      if (resp_expect[k] != 0) begin
        `uvm_error("SB_RESP_DANGLING",
          $sformatf("source port %0d still expects %0d %s response(s) never observed on its own port — response routing incomplete/misrouted (spec §5.1.2/§5.1.3)",
                     (k >> 6), resp_expect[k],
                     ((k >> 5) & 1) ? "B(write)" : "R(read)"))
      end
    end
    // C6.3 (spec §6.3): every atomic load must have returned *both* its B
    // and its R by end of test — an open pair record means one (or both)
    // halves never appeared.
    foreach (atop_pend[k]) begin
      `uvm_error("SB_ATOP_DANGLING",
        $sformatf("slv port %0d atomic load id 'h%0h never completed its response pair (B seen=%0d, R seen=%0d) — spec §6.3 requires both B and R to return",
                   (k >> 5), (k & 'h1f), atop_pend[k].b_seen,
                   atop_pend[k].r_seen))
    end
    // C5.1: any still-open stall-tracking record at end of test means a B/
    // rlast never arrived for a request this check thought was accepted.
    if (or_open_total != 0) begin
      `uvm_error("SB_OR_DANGLING",
        $sformatf("%0d C5.1/C5.2 stall-tracking record(s) never observed a matching B/rlast — incomplete at end of test",
                   or_open_total))
    end
    // C5.4 (spec §5.5.1): any still-open W-order record means a write's burst
    // never completed at its target master port — routing/pairing incomplete.
    if (worder_open_total != 0) begin
      `uvm_error("SB_WORDER_DANGLING",
        $sformatf("%0d C5.4 W-order record(s) never observed a completing master-side write burst — incomplete at end of test",
                   worder_open_total))
    end
  endfunction
endclass
