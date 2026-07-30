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

// ---------------------------------------------------------------------------
// Transaction flow — one write burst, driver → scoreboard verdict.
// (Reads are the same shape; for reads AR-accept == accept, so req_accept_ap
// and req_ap coincide and the two request-side handlers below fire together.)
//
//   seq_lib.sv seq  ── axi_seq_item(is_write=1) ──▶ slvport_sequencer
//                                                        │
//                                     slvport_driver.drive_write (slvport_agent.sv)
//                                       drives AW / W-burst onto the DUT slave port
//                                                        │
//                    ┌───────────── slvport_monitor observes the slave port ──────────┐
//                    │                                                                 │
//        at AW handshake accept                                        at W-last (whole W burst seen)
//        req_accept_ap ─▶ write_slv_req_accept                         req_ap ─▶ write_slv_req
//          · or_open_q open-record + cg_stall class (§5.2.1/.2/.4)       · decode target master port at the
//          · cg_tx_limit in-flight sample (§2.1/§5.4.1)                    live table version (§3.1/§3.2/§3.4)
//          · worder_pend registration for writes (§5.5.1)                · push pending_by_id keyed by the
//        [BUG-0018: this stream exists so §5.2 / worder /                  EXPECTED mst-side prefixed id (§5.1.1)
//         tx_limit anchor at the real AW-accept instant, not             · decode-miss → resp_expect + err_order_q
//         the late w_last that req_ap carries for writes]                  only (err_slv DECERR path, §4)
//                    │                                                                 │
//                    │                          crossbar routes the request           │
//                    ▼                                                                 │
//        mstport_monitor observes the DESTINATION master port                          │
//        req_ap ─▶ write_mst_req                                                        │
//          · pop pending_by_id (FIFO) → SB_ROUTE: right master port, right              │
//            prefixed id? a lookup miss = misroute / prefix-formula break (§5.1.1)      │
//          · SB_WORDER: each source's W bursts complete in that source's AW order (§5.5.1)
//                                                                                       │
//        mstport_responder answers B ──▶ slvport_monitor observes B on the source port  │
//        resp_ap ─▶ write_resp  (the five-in-one response verdict) ◀────────────────────┘
//          · SB_RESP_ROUTE: B/R came back to the true source slave port (§5.1.2/§5.1.3)
//          · SB_OR_REORDER: same-bucket completion order not reordered (§5.2.3, BUG-0013/0027)
//          · SB_DECERR_ORDER: same-full-id OKAY/DECERR complete in accept order (§5.2.6-2.a)
//          · decerr resp-code / beat-count / ERR_RDATA (§4.3/§4.4/§4.5, ERR_RDATA from pinned spec §4.4)
//          · atop B+R pairing (§6.3) — one owed pair retired per atomic load
// ---------------------------------------------------------------------------

`uvm_analysis_imp_decl(_slv_req)
`uvm_analysis_imp_decl(_slv_req_accept)
`uvm_analysis_imp_decl(_mst_req)
`uvm_analysis_imp_decl(_resp)

class xbar_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(xbar_scoreboard)

  uvm_analysis_imp_slv_req #(axi_req_obs, xbar_scoreboard)  slv_req_imp;
  // BUG-0018: accept-instant request stream (payload-free, fired at the real
  // AW/AR handshake) — owns only the accept-anchored coverage-input
  // registrations, see write_slv_req_accept below.
  uvm_analysis_imp_slv_req_accept #(axi_req_obs, xbar_scoreboard) slv_req_accept_imp;
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

  // ---- cfgC UniqueIds precondition fallback monitor (M3-CF03, spec §5.3.1) --
  // ONLY armed when Cfg.UniqueIds is set (cfgC). Tracks, per (slave port,
  // direction, FULL slv-side id), the count of currently in-flight transactions
  // and their common target master port. spec §5.3.1's precondition holds iff
  // every such group targets ONE master port (or the id is unique in flight, the
  // count==0 branch). A new same-key accept whose target differs from an already
  // in-flight one BREAKS the precondition — and since §5.3.3 makes the DUT
  // undefined then, this must be reported as a TB_BUG (env violated its own
  // constructive guarantee), never pre-judged a DUT_BUG. Decode-miss legs carry
  // a sentinel target (NO_MST_PORTS) so same-id misses stay consistent. Under the
  // single-outstanding-per-port cfgC env the count is always 0/1, so this can
  // never fire — it is a falsifiable safety net, not a routine check.
  local int unsigned uid_cnt[int unsigned];
  local int unsigned uid_tgt[int unsigned];
  int unsigned uid_violation_cnt;
  local function int unsigned uid_key(input int unsigned port, input bit is_write,
                                      input xbar_types_pkg::id_slv_t full_id);
    return (port << (xbar_types_pkg::ID_W_SLV + 1))
           | (int'(is_write) << xbar_types_pkg::ID_W_SLV) | int'(full_id);
  endfunction

  // ---- decode-error / same-full-ID completion-order bookkeeping (spec §4,
  // §5.2.6 clause 2.a; M3-DE01/DE02/OR04). Per (source port, direction, full
  // slv-side id) FIFO of "is this owed response a decode-error (err_slv) one?"
  // bits, pushed in AW/AR-accept order at write_slv_req and popped at each
  // completion in write_resp. Two uses:
  //   (a) spec §4: decides whether write_resp expects a normal (OKAY) response or
  //       a decode-error one (single B(DECERR) for writes; AxLEN+1 beats of the
  //       spec §4.4 err data, all DECERR, for reads);
  //   (b) spec §5.2.6 clause 2.a (assertable, the BUG-0025 full-ID dimension):
  //       two same-FULL-ID same-direction transactions — regardless of whether one
  //       is routed to a master port and the other to err_slv — must complete in
  //       accept order; the FIFO front (accept order) must therefore match the
  //       err-class actually observed at completion (SB_DECERR_ORDER otherwise).
  // A decode-miss transaction is NOT pushed to pending_by_id (it never reaches an
  // external master port — err_slv is internal, spec §4.1) nor to or_open_q (spec
  // §5.2.6 clause 2.b excludes the low-bucket dimension from any verdict).
  local bit err_order_q[int unsigned][$];
  // spec §4.4 (corrected per REV-014 / BUG-0033): each decode-error read beat
  // carries err_slv default RespData = 64'hCA11AB1EBADCAB1E, taken as r.data by
  // zero-extend/truncate to AxiDataWidth. Baseline AxiDataWidth=64 => the full
  // 64-bit value. Traces to pinned spec SPEC-4.4 — NOT read from RTL.
  localparam xbar_types_pkg::data_t ERR_RDATA =
    xbar_types_pkg::data_t'(64'hCA11AB1EBADCAB1E);
  int unsigned decerr_resp_cnt;
  int unsigned decerr_order_violation_cnt;

  // cg_miss_order same_full_id_hit_miss_coexist (functional_coverage.md §4, spec
  // §5.2.6 clause 2.a): reuse the err_order_q we already maintain — after a push,
  // does this (port,dir,FULL slv-id) key now owe BOTH a hit (is_err=0) and a miss
  // (is_err=1) response at once? That IS "同一完整 ID 命中笔+未命中笔并存" reached.
  // Pure read of already-computed state; no new tracking structure.
  local function bit err_order_coexist(input int unsigned rk);
    bit has_hit, has_miss;
    if (!err_order_q.exists(rk)) return 1'b0;
    foreach (err_order_q[rk][i])
      if (err_order_q[rk][i]) has_miss = 1'b1; else has_hit = 1'b1;
    return has_hit && has_miss;
  endfunction

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
    slv_req_imp        = new("slv_req_imp", this);
    slv_req_accept_imp = new("slv_req_accept_imp", this);
    mst_req_imp        = new("mst_req_imp", this);
    resp_imp           = new("resp_imp", this);
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
    // master-side id = {source-port prefix, slv-side id} (spec §5.1.1). Prefix
    // width = $clog2(NoSlvPorts); NoSlvPorts=1 (cfgA) ⇒ 0-bit prefix ⇒ id ==
    // slv_id (tb_top.md C5.6 / scoreboard_refmodel.md C5.7 — express as "no
    // prefix field", NOT a width-0 part-select which is illegal in SV). The
    // shift form is legal for both cases (0-bit prefix ⇒ shift by 0 ⇒ slv_id).
    return (xbar_types_pkg::id_mst_t'(slv_port) << xbar_types_pkg::ID_W_SLV)
           | slv_id;
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
      bit rule_hit;
      int unsigned rule_port;
      snap = version_at(ro.accept_time);
      hit  = xbar_types_pkg::decode_mst_port(ro.addr, snap.addr_map,
               snap.en_def[ro.port_idx], snap.def_port[ro.port_idx], exp_port);
      // cg_decode_error (functional_coverage.md §4, spec §3.2/§3.3/§4.2):
      // classify this transaction's decode destination at the reference model's
      // decode instant. HIT_RULE vs MISS_DEFAULT is told apart by re-calling the
      // SAME single-source decode function with the default master port forced off
      // (rule-only) — not a second, hand-written decoder. A hit that no longer
      // hits with default disabled was routed via the default master port.
      if (!hit)
        fcov.sample_decode_error(xbar_functional_coverage::DR_MISS_ERR_SLV,
                                 ro.is_write, ro.port_idx);
      else begin
        rule_hit = xbar_types_pkg::decode_mst_port(ro.addr, snap.addr_map,
                     1'b0, '0, rule_port);
        fcov.sample_decode_error(rule_hit ? xbar_functional_coverage::DR_HIT_RULE
                                          : xbar_functional_coverage::DR_MISS_DEFAULT,
                                 ro.is_write, ro.port_idx);
      end
    end
    if (!hit) begin
      // spec §4 decode error: unmapped address with no enabled default master
      // port → routed to this slave port's internal err_slv, which answers with
      // RESP_DECERR (M3-DE01/DE02). The transaction never reaches an external
      // master port, so it is registered ONLY for the response-side judgement:
      //   - resp_expect: the DECERR B/R comes back on this same source port (spec
      //     §4.5/§5.1 response routing);
      //   - err_order_q: marks this owed response is_err=1 so write_resp expects a
      //     decode-error response and can order-check it (spec §5.2.6 clause 2.a).
      // NOT pushed to pending_by_id (no master-side observation) or or_open_q (spec
      // §5.2.6 clause 2.b: the low-bucket dimension of a decode-miss transaction is
      // undefined and must not be judged).
      // Env constraint (BUG-0032, spec §4.7): no ATOP is ever sent to an unmapped
      // address; a stray one here is an env-side violation, flagged (not judged).
      if (ro.is_write && ro.atop != '0)
        `uvm_error("SB_ATOP_DECODE",
          $sformatf("slv port %0d sent an ATOP (atop='h%0h) to unmapped address 'h%0h — env violated the BUG-0032 / spec §4.7 no-ATOP-to-decode-error constraint (TB_BUG)",
                     ro.port_idx, ro.atop, ro.addr))
      resp_expect[resp_key(ro.port_idx, ro.is_write,
                           ro.id[xbar_types_pkg::ID_W_SLV-1:0])]++;
      err_order_q[resp_key(ro.port_idx, ro.is_write,
                           ro.id[xbar_types_pkg::ID_W_SLV-1:0])].push_back(1'b1);
      // cg_decerr_shape (functional_coverage.md §4, spec §4.3): record the
      // err_slv transaction's burst-length band (AxLEN==0 vs >0) × direction, so
      // §4.3's beat-count判据 is shown exercised beyond the trivial single-beat
      // burst. Same AxLEN datum (ro.len) the SB_DECERR_RBEATS check consumes.
      fcov.sample_decerr_shape(ro.len != 0, ro.is_write);
      // cg_miss_order same_full_id_hit_miss_coexist: this miss just joined the
      // (port,dir,full-id) err_order_q — if a hit is also owed on the same key,
      // the clause-2.a coexistence corner is reached (see err_order_coexist).
      if (err_order_coexist(resp_key(ro.port_idx, ro.is_write,
                                     ro.id[xbar_types_pkg::ID_W_SLV-1:0])))
        fcov.sample_miss_order(xbar_functional_coverage::MO_COEXIST);
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
    // spec §5.2.6 clause 2.a full-ID ordering: this hit's owed response is a
    // normal (is_err=0) one, queued in accept order (see err_order_q comment).
    err_order_q[resp_key(ro.port_idx, ro.is_write,
                         ro.id[xbar_types_pkg::ID_W_SLV-1:0])].push_back(1'b0);
    // cg_miss_order same_full_id_hit_miss_coexist (mirror of the miss-branch
    // check): this hit joining the key while a miss is already owed for the same
    // full id is the same clause-2.a coexistence corner, seen from the other side.
    if (err_order_coexist(resp_key(ro.port_idx, ro.is_write,
                                   ro.id[xbar_types_pkg::ID_W_SLV-1:0])))
      fcov.sample_miss_order(xbar_functional_coverage::MO_COEXIST);

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
      // The atomic load's R half is likewise a normal (is_err=0) owed response;
      // its B half was already queued by the write-direction push above.
      err_order_q[resp_key(ro.port_idx, 1'b0,
                           ro.id[xbar_types_pkg::ID_W_SLV-1:0])].push_back(1'b0);
    end
    // BUG-0018: the accept-instant registrations that used to live here — the
    // C5.1/C5.2 or_open_q open-record + cg_stall classification, the
    // cg_tx_limit in-flight sample, and the C5.4 worder_pend push — now run in
    // write_slv_req_accept below, off the payload-free AW/AR-accept stream, so
    // for writes they anchor to the true AW handshake instant instead of this
    // w_last-time observation (req_ap fires this handler at w_last for writes).
    // Nothing accept-anchored remains in this handler.
  endfunction

  // ---- request-side, slv-port ACCEPT stream (BUG-0018) -------------------
  // Fired at the true AW/AR handshake instant on the monitor's payload-free
  // req_accept_ap (for writes that is several cycles ahead of req_ap's w_last-
  // time observation that drives write_slv_req above; for reads AR-accept ==
  // accept, so this coincides with write_slv_req and read behaviour is
  // unchanged). This handler owns EXACTLY the coverage-input registrations that
  // must be anchored to the accept instant rather than to w_last:
  //   - the C5.1/C5.2 or_open_q open-record and its cg_stall classification
  //     (spec §5.2.1/§5.2.2/§5.2.4),
  //   - the cg_tx_limit in-flight sample (spec §2.1 MaxMstTrans / §5.4.1),
  //   - the C5.4/C5.5(b) worder_pend registration for writes (spec §5.5.1),
  //     feeding cg_w_order's cross-source contention count at completion time.
  // It introduces NO new verdict and touches NO judgement anchor: the §5.2.3
  // completion-order check (BUG-0013), accept_time, or_key, err_order_q and the
  // routing/payload judgement all stay in write_slv_req/write_resp untouched.
  // The accept_time carried here is the same real AW/AR handshake instant the
  // monitor stamped (slvport_agent.sv), so the ordering key is identical to
  // what write_slv_req recorded before. A decode-miss transaction is excluded
  // here exactly as write_slv_req excludes it (spec §5.2.6 clause 2.b — a
  // decode-miss low-bucket record must never enter or_open_q/worder).
  virtual function void write_slv_req_accept(axi_req_obs ro);
    bit hit;
    int unsigned exp_port;
    cfg_snap_t snap;
    // C1.5 (spec §3.4): decode against the table version live at this
    // transaction's own accept instant — same lookup write_slv_req performs,
    // so both handlers agree on the target master port for the same txn.
    snap = version_at(ro.accept_time);
    hit  = xbar_types_pkg::decode_mst_port(ro.addr, snap.addr_map,
             snap.en_def[ro.port_idx], snap.def_port[ro.port_idx], exp_port);

    // ---- cfgC §5.3.1 precondition fallback monitor (M3-CF03) — armed only under
    // Cfg.UniqueIds. Runs BEFORE the decode-miss early return so misses (sentinel
    // target) are tracked too. A same (port,dir,full-id) group already in flight
    // toward a DIFFERENT target is a §5.3.1 breach ⇒ TB_BUG (env's own guarantee).
    if (xbar_types_pkg::Cfg.UniqueIds) begin
      int unsigned uk;
      int unsigned tgt;
      uk  = uid_key(ro.port_idx, ro.is_write, ro.id[xbar_types_pkg::ID_W_SLV-1:0]);
      tgt = hit ? exp_port : xbar_types_pkg::NO_MST_PORTS; // sentinel for err_slv
      if (uid_cnt.exists(uk) && uid_cnt[uk] != 0 && uid_tgt[uk] != tgt) begin
        uid_violation_cnt++;
        `uvm_error("SB_UNIQUEIDS",
          $sformatf("slv port %0d %s full-id 'h%0h accepted toward target %0d while %0d in-flight same-id/dir transaction(s) target %0d — env broke the spec §5.3.1 UniqueIds precondition (TB_BUG; §5.3.3 makes the DUT undefined here, so this is NOT a DUT_BUG)",
                     ro.port_idx, ro.is_write ? "AW" : "AR",
                     ro.id[xbar_types_pkg::ID_W_SLV-1:0], tgt, uid_cnt[uk], uid_tgt[uk]))
      end
      if (!uid_cnt.exists(uk) || uid_cnt[uk] == 0) uid_tgt[uk] = tgt;
      uid_cnt[uk]++;
    end

    if (!hit) return; // §5.2.6 clause 2.b: decode-miss never enters or_open_q/worder

    // ---- C5.1/C5.2/C5.5: register this AW/AR's accept as a new open
    // record (BUG-0013: the violation check itself runs at *completion*
    // time in write_resp, not here — see that block's comment).
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
      // observed accept. Sampled here — at the accept instant — because an
      // in-flight count only exists then; the event is the monitor's observed
      // AW/AR handshake (what actually happened, C1.2's intent), never a
      // driver-side intent. (BUG-0018: for writes this is the AW handshake,
      // no longer the late w_last, so the write-direction count is no longer
      // undercounted.)
      fcov.sample_tx_limit(or_open_q[k].size());

      // ---- testplan M3-TL01 / BUG-0010 regression_guard (spec §5.4.1) ----
      // Combined in-flight across ALL low-AxiIdUsedSlvPorts-bit buckets for
      // THIS (slave port, direction) — the demux's own per-bucket counters
      // (or_open_q, the exact table cg_tx_limit reads above) summed, never a
      // second decode. Non-decisional witness only (functional_coverage.md
      // §0): fires when the SUM exceeds the documented Cfg.MaxMstTrans ceiling
      // while >=2 distinct buckets are simultaneously non-empty — precisely
      // the aggregate-vs-flat reading the card constructs. Cfg.MaxMstTrans is
      // read from xbar_types_pkg (the pinned parameter-definition file), not
      // any RTL-observed value.
      begin
        int unsigned n_bkt;
        int unsigned combined_total;
        int unsigned nonzero_buckets;
        n_bkt           = 1 << xbar_types_pkg::Cfg.AxiIdUsedSlvPorts;
        combined_total  = 0;
        nonzero_buckets = 0;
        for (int unsigned bk = 0; bk < n_bkt; bk++) begin
          int unsigned kb;
          int unsigned sz;
          kb = or_key(ro.port_idx, ro.is_write, bk);
          sz = or_open_q.exists(kb) ? or_open_q[kb].size() : 0;
          combined_total += sz;
          if (sz != 0) nonzero_buckets++;
        end
        if (combined_total > xbar_types_pkg::Cfg.MaxMstTrans && nonzero_buckets >= 2)
          fcov.sample_xbucket_total(1'b1);
      end
    end

    // ---- C5.4/C5.5(b) (spec §5.5.1): register this write's expected master-
    // side completion slot, ordered by slave-side AW accept_time within its
    // (source port, target master port) group. Writes only — reads have no W
    // channel (the atop shadow-R is registered read-side but never a W burst).
    if (ro.is_write) begin
      int unsigned wk;
      bit [xbar_types_pkg::ID_W_MST-1:0] exp_id;
      exp_id = build_exp_id(ro.port_idx, ro.id[xbar_types_pkg::ID_W_SLV-1:0]);
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
        // source slave port = ID-prefix high bits (spec §5.1.1); shift not a
        // part-select so NoSlvPorts=1's 0-bit prefix stays legal (⇒ src=0,
        // the sole slave port — scoreboard_refmodel.md C5.7).
        src_port = ro.id >> xbar_types_pkg::ID_W_SLV;
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
      // source slave port = ID-prefix high bits (spec §5.1.1); shift keeps
      // NoSlvPorts=1's 0-bit prefix legal (scoreboard_refmodel.md C5.7).
      src_port = ro.id >> xbar_types_pkg::ID_W_SLV;
      fcov.sample_addr_reconfig(rec.post_change, src_port); // spec §3.4
      if (ro.is_write && ro.atop != '0)                     // spec §6.3/§6.1
        fcov.sample_atop(src_port, ro.atop[axi_pkg::ATOP_R_RESP]);
    end
    route_match_cnt++;
  endfunction

  // ---- response-side (slv port round trip only): payload/resp-code
  // judgement (§1, C4.2) --------------------------------------------------
  virtual function void write_resp(axi_resp_obs ro);
    bit observed_err;    // this completion is a decode-error (all beats DECERR)
    bit expected_is_err; // accept-order-expected err class for this (port,dir,id)

    // cfgC §5.3.1 monitor (M3-CF03): this B/rlast retires one in-flight
    // (port,dir,full-id) transaction — mirror the accept-time increment so the
    // in-flight group count stays exact. Armed only under Cfg.UniqueIds.
    if (xbar_types_pkg::Cfg.UniqueIds) begin
      int unsigned uk;
      uk = uid_key(ro.port_idx, ro.is_write, ro.id);
      if (uid_cnt.exists(uk) && uid_cnt[uk] != 0) uid_cnt[uk]--;
    end
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

    // ---- decode-error class + spec §5.2.6 clause 2.a same-full-ID completion-
    // order check (M3-DE01/DE02/OR04). `observed_err` is what actually came back
    // (all err_slv beats are DECERR); `expected_is_err` is the accept-order front
    // of err_order_q for this (port,dir,full-id). For two same-full-ID same-
    // direction transactions (one via a master port → OKAY, one via err_slv →
    // DECERR) the two must complete in accept order (spec §5.2.6 clause 2.a); a
    // swapped completion pops the wrong err-class expectation and is flagged here.
    // This is the assertable BUG-0025 full-ID dimension (falsifiable: a reversed
    // completion order or a corrupted queue front turns it red).
    observed_err = (ro.resp.size() > 0) && (ro.resp[0] === axi_pkg::RESP_DECERR);
    begin
      int unsigned rk;
      rk = resp_key(ro.port_idx, ro.is_write, ro.id);
      if (err_order_q.exists(rk) && err_order_q[rk].size() != 0)
        expected_is_err = err_order_q[rk].pop_front();
      else
        expected_is_err = observed_err; // no queued expectation (already flagged above)
      if (expected_is_err != observed_err) begin
        decerr_order_violation_cnt++;
        `uvm_error("SB_DECERR_ORDER",
          $sformatf("slv port %0d %s id 'h%0h completed as %s but accept order expected %s — same-full-ID responses out of order (spec §5.2.6 clause 2.a / §4)",
                     ro.port_idx, ro.is_write ? "B(write)" : "R(read)", ro.id,
                     observed_err ? "DECERR" : "OKAY",
                     expected_is_err ? "DECERR" : "OKAY"))
      end
      if (err_order_q.exists(rk) && err_order_q[rk].size() == 0) err_order_q.delete(rk);
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
    // spec §5.2.6 clause 2.b: a decode-miss (err_slv) completion is excluded from
    // the low-bucket ordering verdict (it was never pushed to or_open_q). Skip the
    // whole block for it — never attribute a hit sibling's or_open record to it.
    if (!observed_err)
    begin
      int unsigned bucket;
      int unsigned k;
      bucket = id_bucket(ro.id);
      k = or_key(ro.port_idx, ro.is_write, bucket);
      if (or_open_q.exists(k)) begin
        int unsigned this_idx;
        bit          this_found;
        this_found = 1'b0;
        // Attribution rule (BUG-0027): when several records share the FULL
        // slv-side id, this completing B/rlast belongs to the OLDEST of them
        // — same-id/same-direction responses return in acceptance order
        // (AXI4 same-id in-order, spec §1/§5.2.3), which the queue holds in
        // push (accept) order, so the first match is the right one. Picking
        // the last match instead attributed every completion of a same-full-id
        // group to its newest, different-target member and reported the legal
        // spec §5.2.4 stack as a §5.2.3 reordering (336 false SB_OR_REORDER in
        // `make run TEST=m2_or03_guard_test SEED=1`, BUG-0027). Ordering
        // *within* one full id is not judged here at all (B carries only
        // id+resp, so the boundary cannot tell two same-id writes apart); it
        // is judged by the master-side FIFO route check (SB_ROUTE — a
        // forwarding order swap surfaces there) and, for reads, by the
        // per-address data check (SB_RDATA).
        foreach (or_open_q[k][idx]) begin
          if (or_open_q[k][idx].slv_id == ro.id) begin
            this_idx   = idx;
            this_found = 1'b1;
            break;
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

    // ---- spec §4 decode-error response judgement (M3-DE01/DE02). The err_slv
    // absorbs the whole transaction and answers DECERR with the proper beat count
    // (spec §4.3): a WRITE gets a single B(DECERR); a READ gets AxLEN+1 R beats,
    // each carrying the spec §4.4 err data, all DECERR, RLAST on the last (the
    // slv monitor only builds this resp_obs at r_last). Expected values trace to
    // spec §4.3/§4.4 only — never read from RTL.
    if (observed_err) begin
      if (ro.is_write) begin
        if (ro.resp.size() != 1 || ro.resp[0] !== axi_pkg::RESP_DECERR) begin
          resp_mismatch_cnt++;
          `uvm_error("SB_DECERR_BRESP",
            $sformatf("slv port %0d id 'h%0h decode-error write expected a single B(DECERR): got %0d beat(s), resp[0]='b%0b (spec §4.3)",
                       ro.port_idx, ro.id, ro.resp.size(), ro.resp[0]))
          return;
        end
      end else begin
        if (ro.rdata.size() != int'(ro.len) + 1) begin
          resp_mismatch_cnt++;
          `uvm_error("SB_DECERR_RBEATS",
            $sformatf("slv port %0d id 'h%0h decode-error read beat count %0d != AxLEN+1 (%0d) (spec §4.3)",
                       ro.port_idx, ro.id, ro.rdata.size(), int'(ro.len) + 1))
          return;
        end
        foreach (ro.rdata[k]) begin
          if (ro.rdata[k] !== ERR_RDATA || ro.resp[k] !== axi_pkg::RESP_DECERR) begin
            resp_mismatch_cnt++;
            `uvm_error("SB_DECERR_RDATA",
              $sformatf("slv port %0d id 'h%0h decode-error R beat %0d: got data='h%0h resp='b%0b expected data='h%0h resp=DECERR (spec §4.3/§4.4)",
                         ro.port_idx, ro.id, k, ro.rdata[k], ro.resp[k], ERR_RDATA))
            return;
          end
        end
      end
      decerr_resp_cnt++;
      resp_match_cnt++;
      return;
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
      $sformatf("route: match=%0d mismatch=%0d | resp: match=%0d mismatch=%0d | resp-route(C3.2): match=%0d mismatch=%0d | pending(unmatched at end)=%0d | stall(C5.1/C5.2): violations=%0d open(unmatched at end)=%0d | atop(C6.3): pairs=%0d open(unpaired at end)=%0d | worder(C5.4): match=%0d mismatch=%0d open(unmatched at end)=%0d | decerr(§4): resp=%0d order_violations=%0d",
                 route_match_cnt, route_mismatch_cnt, resp_match_cnt,
                 resp_mismatch_cnt, resp_route_match_cnt,
                 resp_route_mismatch_cnt, pending_total,
                 or_stall_violation_cnt, or_open_total, atop_pair_cnt,
                 atop_pend.num(), worder_match_cnt, worder_mismatch_cnt,
                 worder_open_total, decerr_resp_cnt, decerr_order_violation_cnt),
      UVM_LOW)
    // cfgC §5.3.1 fallback monitor (M3-CF03): report the breach count so the
    // evidence self-documents the env-side guard actually ran (0 = precondition
    // held for the whole run). Only meaningful when armed (Cfg.UniqueIds).
    if (xbar_types_pkg::Cfg.UniqueIds)
      `uvm_info("SB_UNIQUEIDS_SUMMARY",
        $sformatf("cfgC §5.3.1 UniqueIds precondition monitor: violations=%0d (0 = env held the constructive guarantee for the whole run)",
                   uid_violation_cnt), UVM_LOW)
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
