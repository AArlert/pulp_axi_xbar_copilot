// tb/slvport_agent.sv — M1 UVM env: agent attached to one crossbar *slave*
// port (TB plays the external AXI master, uvm_env.md §2 "master agent").
// `include-d from tb_pkg.sv.
//
// slvport_driver: consumes axi_seq_item from the sequencer, drives AW/W or
// AR on the port, blocks for the matching B/R completion before item_done()
// (single-outstanding-per-port for every M1-style item — sidesteps the
// baseline false-conflict stall entirely, spec §5.2.1/§5.2.2/§0 row 2, since
// a stall only arises with *two* simultaneously outstanding requests on one
// port). M2-OR01/OR02 (uvm_env.md C5.2) deliberately break that invariant
// for one controlled pair at a time via the axi_pair_item/drive_pair() path
// below — see that task's own header comment.
//
// slvport_monitor: purely passive (Monitor modport), reconstructs both the
// request ("input observation", spec §5.1 source-index) and the full
// request+response round trip, and publishes both to the scoreboard. AW/W
// and AR/R tracking is FIFO-queue-based (not a single overwritten slot) so
// it stays correct when a port legitimately has more than one same-
// direction request outstanding (M2-OR02(a)) — see the aw_pending_q/
// ar_pending_q comments below.

class slvport_driver extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(slvport_driver)

  virtual slvport_if vif;
  int unsigned        port_idx;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual slvport_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "slvport_driver: virtual interface not set")
    if (!uvm_config_db#(int)::get(this, "", "port_idx", port_idx))
      `uvm_fatal("NOPIDX", "slvport_driver: port_idx not set")
  endfunction

  task automatic drive_idle();
    vif.aw_valid <= 1'b0;
    vif.w_valid  <= 1'b0;
    vif.ar_valid <= 1'b0;
    vif.b_ready  <= 1'b1; // no backpressure modelled on the response side
    vif.r_ready  <= 1'b1;
  endtask

  virtual task run_phase(uvm_phase phase);
    drive_idle();
    wait (vif.rst_ni === 1'b1);
    // `wait` unblocks the instant rst_ni changes (mid-cycle, not
    // clock-synchronous); align to the next full clock edge before driving
    // anything so the reset-release cycle itself stays idle (spec §2.3/§1,
    // sva_bind.md C2.2 — the "release cycle" the SVA checks is the next
    // *sampled* clock edge, not this raw signal-change instant).
    @(posedge vif.clk_i);
    forever begin
      axi_seq_item   item;
      axi_pair_item  pair;
      axi_burst_item burst;
      seq_item_port.get_next_item(item);
      if ($cast(burst, item)) drive_burst(burst);
      else if ($cast(pair, item)) drive_pair(pair);
      else if (item.is_write && item.fallthrough_probe) drive_write_ft(item);
      else if (item.is_write) drive_write(item);
      else drive_read(item);
      seq_item_port.item_done();
    end
  endtask

  task automatic drive_write(axi_seq_item item);
    vif.aw_id     <= item.id;
    vif.aw_addr   <= item.addr;
    vif.aw_len    <= item.len;
    vif.aw_size   <= item.size;
    vif.aw_burst  <= item.burst;
    vif.aw_lock   <= 1'b0;
    vif.aw_cache  <= '0;
    vif.aw_prot   <= '0;
    vif.aw_qos    <= '0;
    vif.aw_region <= '0;
    vif.aw_atop   <= item.atop; // '0 for ordinary writes; ATOP_ATOMICLOAD for M2-AT01 (spec §6.1, uvm_env.md C2.4/C5.5)
    vif.aw_user   <= '0;
    vif.aw_valid  <= 1'b1;
    do @(posedge vif.clk_i); while (!vif.aw_ready);
    vif.aw_valid <= 1'b0;

    for (int unsigned k = 0; k <= item.len; k++) begin
      vif.w_data  <= item.wdata[k];
      vif.w_strb  <= item.wstrb[k];
      vif.w_last  <= (k == item.len);
      vif.w_user  <= '0;
      vif.w_valid <= 1'b1;
      do @(posedge vif.clk_i); while (!vif.w_ready);
    end
    vif.w_valid <= 1'b0;

    // Completion: an ordinary write completes on its B; an atomic load
    // (aw.atop[ATOP_R_RESP]) completes only once *both* B and its R(last)
    // have returned (spec §6.3) — tracked in one combined poll (not
    // B-then-R sequentially) because their relative arrival order is
    // unconstrained (delay-insensitive, spec §7.4 / sva_bind.md C3.5).
    // Both matches are ID-qualified so a concurrent read leg's R (mixed
    // drive_pair, M2-AT01 overlap) is never miscounted as ours.
    begin
      bit got_b, got_r;
      got_b = 1'b0;
      got_r = !item.atop[axi_pkg::ATOP_R_RESP];
      do begin
        @(posedge vif.clk_i);
        if (vif.b_valid && vif.b_ready && (vif.b_id == item.id))
          got_b = 1'b1;
        if (vif.r_valid && vif.r_ready && vif.r_last && (vif.r_id == item.id))
          got_r = 1'b1;
      end while (!(got_b && got_r));
    end
  endtask

  // ---- M4-FT01 fall-through probe primitive (testplan M4-FT01, spec §2.1/
  // §7.3.1). Presents AW and the burst's FIRST W beat with valid asserted
  // CONCURRENTLY from the first cycle — never waiting out the AW handshake
  // before raising w_valid the way drive_write() above does. That serial
  // presentation structurally can never let aw_valid and w_valid both be
  // high on an accept cycle (w_valid is only ever raised after aw_valid has
  // already been deasserted); this task is the only way stimulus can even
  // offer the DUT the opportunity to accept an AW and its matching first W
  // beat on the SAME cycle (spec §2.1: FallThrough lets the AW routing
  // decision "fall through" onto the W channel). Whether the DUT actually
  // takes that opportunity is a non-decisional, delay-insensitive runtime
  // observation (SPEC-7.4.3 red line: this task asserts nothing about the
  // outcome, it only creates the opportunity) — see functional_coverage.sv
  // cg_fallthrough / slvport_monitor's sample call below. Any beats after
  // the first are driven exactly as drive_write()'s W loop; the completion
  // wait is copied verbatim from drive_write() (no ATOP on probe items).
  task automatic drive_write_ft(axi_seq_item item);
    vif.aw_id     <= item.id;
    vif.aw_addr   <= item.addr;
    vif.aw_len    <= item.len;
    vif.aw_size   <= item.size;
    vif.aw_burst  <= item.burst;
    vif.aw_lock   <= 1'b0;
    vif.aw_cache  <= '0;
    vif.aw_prot   <= '0;
    vif.aw_qos    <= '0;
    vif.aw_region <= '0;
    vif.aw_atop   <= item.atop; // '0 — fall-through probe items never carry ATOP
    vif.aw_user   <= '0;
    vif.aw_valid  <= 1'b1;

    vif.w_data  <= item.wdata[0];
    vif.w_strb  <= item.wstrb[0];
    vif.w_last  <= (item.len == 0);
    vif.w_user  <= '0;
    vif.w_valid <= 1'b1;

    fork
      begin
        do @(posedge vif.clk_i); while (!vif.aw_ready);
        vif.aw_valid <= 1'b0;
      end
      begin
        do @(posedge vif.clk_i); while (!vif.w_ready);
      end
    join

    for (int unsigned k = 1; k <= item.len; k++) begin
      vif.w_data  <= item.wdata[k];
      vif.w_strb  <= item.wstrb[k];
      vif.w_last  <= (k == item.len);
      vif.w_user  <= '0;
      vif.w_valid <= 1'b1;
      do @(posedge vif.clk_i); while (!vif.w_ready);
    end
    vif.w_valid <= 1'b0;

    begin
      bit got_b, got_r;
      got_b = 1'b0;
      got_r = !item.atop[axi_pkg::ATOP_R_RESP];
      do begin
        @(posedge vif.clk_i);
        if (vif.b_valid && vif.b_ready && (vif.b_id == item.id))
          got_b = 1'b1;
        if (vif.r_valid && vif.r_ready && vif.r_last && (vif.r_id == item.id))
          got_r = 1'b1;
      end while (!(got_b && got_r));
    end
  endtask

  task automatic drive_read(axi_seq_item item);
    vif.ar_id     <= item.id;
    vif.ar_addr   <= item.addr;
    vif.ar_len    <= item.len;
    vif.ar_size   <= item.size;
    vif.ar_burst  <= item.burst;
    vif.ar_lock   <= 1'b0;
    vif.ar_cache  <= '0;
    vif.ar_prot   <= '0;
    vif.ar_qos    <= '0;
    vif.ar_region <= '0;
    vif.ar_user   <= '0;
    vif.ar_valid  <= 1'b1;
    do @(posedge vif.clk_i); while (!vif.ar_ready);
    vif.ar_valid <= 1'b0;

    // ID-qualified: with an atomic load's R possibly in flight on the same
    // port (M2-AT01 mixed pair, spec §6.3), an unqualified r_last wait could
    // unblock on the ATOP's R instead of this read's own.
    do @(posedge vif.clk_i);
    while (!(vif.r_valid && vif.r_ready && vif.r_last
             && (vif.r_id == item.id)));
  endtask

  // ---- M2-OR01/OR02 same-ID cross-port ordering primitive (uvm_env.md
  // C5.2). The four helper tasks below decompose a single burst into its
  // AW/AR-accept phase and its W/B(or R)-completion phase so drive_pair()
  // can present sub-transaction B's AW/AR while sub-transaction A's B/R is
  // still outstanding — deliberately *not* reusing drive_write()/
  // drive_read() above for the same-direction pair legs (those two remain
  // untouched, still driving every non-pair item exactly as before).
  task automatic drive_aw(axi_seq_item item);
    vif.aw_id     <= item.id;
    vif.aw_addr   <= item.addr;
    vif.aw_len    <= item.len;
    vif.aw_size   <= item.size;
    vif.aw_burst  <= item.burst;
    vif.aw_lock   <= 1'b0;
    vif.aw_cache  <= '0;
    vif.aw_prot   <= '0;
    vif.aw_qos    <= '0;
    vif.aw_region <= '0;
    vif.aw_atop   <= item.atop; // pair legs leave this '0 (build_or_pair)
    vif.aw_user   <= '0;
    vif.aw_valid  <= 1'b1;
    do @(posedge vif.clk_i); while (!vif.aw_ready);
    vif.aw_valid <= 1'b0;
  endtask

  task automatic drive_w_burst(axi_seq_item item);
    for (int unsigned k = 0; k <= item.len; k++) begin
      vif.w_data  <= item.wdata[k];
      vif.w_strb  <= item.wstrb[k];
      vif.w_last  <= (k == item.len);
      vif.w_user  <= '0;
      vif.w_valid <= 1'b1;
      do @(posedge vif.clk_i); while (!vif.w_ready);
    end
    vif.w_valid <= 1'b0;
  endtask

  task automatic drive_ar(axi_seq_item item);
    vif.ar_id     <= item.id;
    vif.ar_addr   <= item.addr;
    vif.ar_len    <= item.len;
    vif.ar_size   <= item.size;
    vif.ar_burst  <= item.burst;
    vif.ar_lock   <= 1'b0;
    vif.ar_cache  <= '0;
    vif.ar_prot   <= '0;
    vif.ar_qos    <= '0;
    vif.ar_region <= '0;
    vif.ar_user   <= '0;
    vif.ar_valid  <= 1'b1;
    do @(posedge vif.clk_i); while (!vif.ar_ready);
    vif.ar_valid <= 1'b0;
  endtask

  // Drives one txn pair on this one slave port. AW/AR channel presentation
  // of B always starts only after A's own AW/AR handshake completed — one
  // physical address channel cannot carry two payloads at once. Same-
  // direction legs additionally need a background event counter (spawned
  // *before* presenting A) rather than a linear post-hoc poll: A's own B/R
  // can complete *during* the blocking wait for B's AW/AR to be accepted
  // (that overlap is the whole point of the stall/non-stall construction),
  // so a poll started only after that wait returns could miss an edge that
  // already came and went.
  task automatic drive_pair(axi_pair_item item);
    int unsigned b_seen;
    int unsigned r_seen;
    b_seen = 0;
    r_seen = 0;
    fork
      forever begin
        @(posedge vif.clk_i);
        if (vif.b_valid && vif.b_ready) b_seen++;
      end
      forever begin
        @(posedge vif.clk_i);
        if (vif.r_valid && vif.r_ready && vif.r_last) r_seen++;
      end
    join_none

    if (item.is_write && item.second_item.is_write) begin
      drive_aw(item);
      fork
        drive_w_burst(item);
        begin
          repeat (item.gap_cycles) @(posedge vif.clk_i);
          drive_aw(item.second_item);
        end
      join
      drive_w_burst(item.second_item);
      wait (b_seen >= 2);
    end else if (!item.is_write && !item.second_item.is_write) begin
      drive_ar(item);
      repeat (item.gap_cycles) @(posedge vif.clk_i);
      drive_ar(item.second_item);
      wait (r_seen >= 2);
    end else begin
      // Mixed direction (M2-OR02(b), spec §5.2.1 "same direction" scope
      // boundary): AW/W/B and AR/R are independent channels, so there is no
      // ordering interaction to construct — drive both legs concurrently,
      // reusing the ordinary single-item tasks unchanged.
      fork
        if (item.is_write) drive_write(item); else drive_read(item);
        begin
          repeat (item.gap_cycles) @(posedge vif.clk_i);
          if (item.second_item.is_write) drive_write(item.second_item);
          else drive_read(item.second_item);
        end
      join
    end

    disable fork; // reap the still-running b_seen/r_seen counters above
  endtask

  // ---- M2-TL01/TL02 sustained-pressure primitive (uvm_env.md C5.3). Presents
  // every sub-transaction's AW(+W burst) or AR back-to-back on this one slave
  // port WITHOUT waiting for any completion in between, then blocks until all
  // completions have returned. When the DUT's per-(bucket|id) in-flight ceiling
  // (spec §5.4) is reached the crossbar naturally back-pressures the next AW/AR
  // handshake (aw_ready/ar_ready held low ahead of the core decision logic) —
  // drive_aw/drive_ar simply wait there while the background counter keeps
  // tallying completions, so a slot freed by a returning B/R lets the stalled
  // handshake proceed (no deadlock as long as the responder eventually
  // responds; a genuinely stuck DUT surfaces as the tb_top watchdog, not a
  // silent pass). Every sub-item is the SAME direction (the sequence builds it
  // that way), so one completion channel tallies the whole burst; this port
  // runs exactly one burst at a time, so no unrelated B/R is miscounted.
  // M4-EB01 response-side backpressure hold (testplan M4-EB01, spec
  // §4.3/§7.4.5): cycles this port's b_ready is held LOW before release. Pure
  // stimulus timing — long enough that the internal err_slv B-fifo fills and
  // its input w_ready/aw_ready are driven low (the structural motive), then
  // released so every decode-error write's single B(DECERR) drains. The value
  // is NOT a judgement anchor: nothing asserts which cycle aw_ready drops or
  // the b_fifo fills (spec §7.4.5 red line).
  localparam int unsigned BP_B_HOLD_CYC = 50;

  task automatic drive_burst(axi_burst_item item);
    int unsigned done_cnt;
    int unsigned total;
    bit          is_w;
    total    = item.items.size();
    done_cnt = 0;
    is_w     = (total > 0) ? item.items[0].is_write : 1'b1;
    // M4-EB01: drop b_ready so the port's internal err_slv B-response fifo fills
    // (its consumer, b_ready, is now starved) — see axi_burst_item.b_backpressure.
    if (item.b_backpressure) vif.b_ready <= 1'b0;
    fork
      forever begin
        @(posedge vif.clk_i);
        if (is_w) begin
          if (vif.b_valid && vif.b_ready) done_cnt++;
        end else begin
          if (vif.r_valid && vif.r_ready && vif.r_last) done_cnt++;
        end
      end
      // M4-EB01: bounded b_ready hold, then release. Runs concurrently with the
      // presentation below so the AW/W loops (which stall while the fifos are
      // full) can make progress once b_ready lets the B(DECERR)s drain.
      if (item.b_backpressure) begin
        repeat (BP_B_HOLD_CYC) @(posedge vif.clk_i);
        vif.b_ready <= 1'b1;
      end
    join_none
    if (item.b_backpressure && is_w) begin
      // M4-EB01: present all AWs decoupled from (running ahead of) their W
      // bursts. With b_ready held low the err_slv b_fifo fills after two
      // collected writes → its w_ready drops (W stalls), and the AWs still
      // piling in fill its w_fifo → its input aw_ready drops too — the input-
      // side backpressure this scenario targets. AW-before-W order per item is
      // still enforced by the DUT (the demux gates each W burst on its own AW's
      // routing, and err_slv raises w_ready only once the matching AW is in its
      // w_fifo), so the slv monitor's FIFO AW/W pairing never sees a W with no
      // AW (no MON_WNOAW).
      fork
        foreach (item.items[i]) drive_aw(item.items[i]);
        foreach (item.items[i]) drive_w_burst(item.items[i]);
      join
    end else begin
      foreach (item.items[i]) begin
        axi_seq_item sub;
        sub = item.items[i];
        if (sub.is_write) begin
          drive_aw(sub);
          drive_w_burst(sub);
        end else begin
          drive_ar(sub);
        end
      end
    end
    wait (done_cnt >= total);
    disable fork; // reap the background completion counter (+ b_ready hold)
  endtask
endclass

class slvport_monitor extends uvm_monitor;
  `uvm_component_utils(slvport_monitor)

  virtual slvport_if vif;
  int unsigned        port_idx;
  uvm_analysis_port #(axi_req_obs)  req_ap;
  // BUG-0018: a second, payload-free request-observation port fired at the TRUE
  // AW/AR handshake instant (not at w_last like req_ap does for writes). It
  // carries no wdata/wstrb — its sole purpose is to let the scoreboard anchor
  // its accept-instant coverage-input registrations (or_open_q + cg_stall
  // classification, cg_tx_limit in-flight, cg_w_order worder_pend) to the
  // moment the AW/AR is accepted, instead of several cycles late at w_last. It
  // is NOT a second judgement path: the full payload-carrying observation is
  // still published on req_ap at w_last unchanged, and every verdict continues
  // to feed off req_ap/resp_ap. See scoreboard write_slv_req_accept.
  uvm_analysis_port #(axi_req_obs)  req_accept_ap;
  uvm_analysis_port #(axi_resp_obs) resp_ap;

  // write-collection state. AW-accepted records queue up in aw_pending_q
  // (FIFO, mirrors mstport_monitor.sv's aw_q pattern) rather than a single
  // overwritten slot: M2-OR02(a) (spec §5.2.4, uvm_env.md C5.2) legitimately
  // accepts a second same-port AW before the first burst's B has completed,
  // so a single-slot "capture AW / collect until w_last" scheme would
  // corrupt an in-progress collection the moment the second AW is accepted
  // (the same class of bug BUG-0009 fixed on the master-port side). W bursts
  // themselves are never interleaved (AXI4), so only the *head* of the
  // queue is ever the "currently collecting" record.
  typedef struct {
    xbar_types_pkg::id_slv_t id;
    xbar_types_pkg::addr_t   addr;
    axi_pkg::len_t           len;
    axi_pkg::size_t          size;
    axi_pkg::burst_t         burst;
    axi_pkg::atop_t          atop; // spec §6.1 — '0 for ordinary writes
    time                     accept_time; // scoreboard_refmodel.md C5.5(a)
  } aw_rec_t;
  local aw_rec_t                 aw_pending_q[$];
  local bit                      w_busy;
  local aw_rec_t                 w_cur;
  local xbar_types_pkg::data_t   w_data_q[$];
  local xbar_types_pkg::strb_t   w_strb_q[$];

  // read-collection state — same FIFO rationale as the write side above,
  // for the read-direction leg of the same M2-OR02(a) construction.
  typedef struct {
    xbar_types_pkg::id_slv_t id;
    xbar_types_pkg::addr_t   addr;
    axi_pkg::len_t           len;
    axi_pkg::size_t          size;
    axi_pkg::burst_t         burst;
  } ar_rec_t;
  local ar_rec_t                 ar_pending_q[$];
  // BUG-0034 / REV-015: R bursts of DIFFERENT full IDs may legitimately
  // beat-interleave on one shared slave-port R channel — spec §5.1.4/§5.5.3
  // (different-full-ID responses are round-robin merged and MAY interleave;
  // upstream axi_mux.md frames it as a performance feature), and §5.5.4
  // forbids a checker from asserting any particular grant order. The earlier
  // single r_busy/r_cur slot assumed "R never interleaves": once a burst
  // started it blindly absorbed every following beat until r_last, misattribut-
  // ing an interleaved other-id beat into the wrong burst (the MON_RNOAR /
  // SB_RBEATS / SB_ATOP_DANGLING false-report cascade). Reconstruct one
  // in-progress R burst PER r_id concurrently, keyed by the slave-side id, so
  // each beat is paired/appended/closed against its own transaction. Same-full-
  // id R beats are never interleaved with each other (AXI4 §5.2.3), so at most
  // one open burst exists per id at any instant. This does NOT assert that
  // interleaving must/mustn't happen (§5.5.4 red line) — it only reconstructs
  // correctly whether or not it does.
  local bit                    r_busy_by_id [xbar_types_pkg::id_slv_t];
  local ar_rec_t               r_cur_by_id  [xbar_types_pkg::id_slv_t];
  local xbar_types_pkg::data_t r_data_qq    [xbar_types_pkg::id_slv_t][$];
  local axi_pkg::resp_t        r_resp_qq    [xbar_types_pkg::id_slv_t][$];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_ap        = new("req_ap", this);
    req_accept_ap = new("req_accept_ap", this);
    resp_ap       = new("resp_ap", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual slvport_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "slvport_monitor: virtual interface not set")
    if (!uvm_config_db#(int)::get(this, "", "port_idx", port_idx))
      `uvm_fatal("NOPIDX", "slvport_monitor: port_idx not set")
  endfunction

  virtual task run_phase(uvm_phase phase);
    w_busy = 1'b0;
    forever begin
      @(posedge vif.clk_i);
      if (!vif.rst_ni) continue;

      // M4-FT01 non-decisional fall-through witness (testplan M4-FT01, spec
      // §2.1/§7.3.1): AW and the (first) W beat accepted on the SAME sampled
      // edge, observed purely from this slave port's own external valid/
      // ready pair — no DUT-internal signal read (CLAUDE.md input boundary).
      // Only meaningfully non-zero under FallThrough=1'b1 configs (cfgE);
      // structurally near-impossible under FallThrough=1'b0 baselines since
      // there the AW/W channels have no combinational tie (spec §2.1). Never
      // feeds any judgement (functional_coverage.sv cg_fallthrough, SPEC-
      // 7.4.3 red line: this is a cover, not an assert).
      if (vif.aw_valid && vif.aw_ready && vif.w_valid && vif.w_ready
          && xbar_functional_coverage::m_probe != null)
        xbar_functional_coverage::m_probe.sample_fallthrough(1'b1);

      // M4-EB01 non-decisional err_slv-backpressure witness (testplan M4-EB01,
      // spec §4.3/§7.4.5): this slave port's AW (or W) was offered but not
      // ready-accepted on this sampled edge — the external image of the port's
      // internal err_slv B-fifo filling (b_ready starved) and back-pressuring
      // its input aw_ready/w_ready. In the M4-EB01 run decode-error writes are
      // the only traffic, so a held AW/W here can only be that path (proving
      // 背压非空转); other configs may also hold these for mux-side reasons —
      // an entered-only bin, same convention as cg_fallthrough/cg_aw_retry.
      // Purely external valid/ready (CLAUDE.md input boundary); draws no verdict
      // (spec §7.4.5 red line — neither the b_fifo depth nor the exact cycle
      // aw_ready drops is ever asserted).
      if (xbar_functional_coverage::m_probe != null) begin
        if (vif.aw_valid && !vif.aw_ready)
          xbar_functional_coverage::m_probe.sample_errbp(
            xbar_functional_coverage::EB_AW_HELD);
        if (vif.w_valid && !vif.w_ready)
          xbar_functional_coverage::m_probe.sample_errbp(
            xbar_functional_coverage::EB_W_HELD);
      end

      if (vif.aw_valid && vif.aw_ready) begin
        aw_rec_t a;
        a.id          = vif.aw_id;
        a.addr        = vif.aw_addr;
        a.len         = vif.aw_len;
        a.size        = vif.aw_size;
        a.burst       = vif.aw_burst;
        a.atop        = vif.aw_atop;
        a.accept_time = $time;
        aw_pending_q.push_back(a);
        // BUG-0018: publish the payload-free AW-accept event NOW so the
        // scoreboard registers this write's open record / classifies its
        // §5.2 stall situation / counts it in-flight at the real AW handshake
        // instant. The full wdata/wstrb-carrying observation still goes out on
        // req_ap at w_last below (unchanged) — this event never carries a
        // judgement, only the accept-instant coverage inputs.
        begin
          axi_req_obs ae = axi_req_obs::type_id::create("slv_wreq_accept");
          ae.port_idx    = port_idx;
          ae.is_write    = 1'b1;
          ae.id          = {{(xbar_types_pkg::ID_W_MST-xbar_types_pkg::ID_W_SLV){1'b0}}, vif.aw_id};
          ae.addr        = vif.aw_addr;
          ae.len         = vif.aw_len;
          ae.size        = vif.aw_size;
          ae.burst       = vif.aw_burst;
          ae.atop        = vif.aw_atop;
          ae.accept_time = $time;
          req_accept_ap.write(ae);
        end
        // Atomic load (spec §6.3): this AW also owes the port an R burst
        // (never preceded by any AR of its own — demux.md-derived spec §6.5
        // background). Queue a read-side pending record built from the AW's
        // own attributes so the R burst pairs up and carries addr/len for
        // the payload judgement, instead of tripping MON_RNOAR below.
        if (vif.aw_atop[axi_pkg::ATOP_R_RESP]) begin
          ar_rec_t ra;
          ra.id    = vif.aw_id;
          ra.addr  = vif.aw_addr;
          ra.len   = vif.aw_len;
          ra.size  = vif.aw_size;
          ra.burst = vif.aw_burst;
          ar_pending_q.push_back(ra);
        end
      end
      if (vif.w_valid && vif.w_ready) begin
        if (!w_busy) begin
          if (aw_pending_q.size() == 0)
            `uvm_error("MON_WNOAW",
              "slv monitor saw a W beat with no accepted AW queued (AW/W pairing violated at slave port)")
          else
            w_cur = aw_pending_q.pop_front();
          w_data_q.delete();
          w_strb_q.delete();
          w_busy = 1'b1;
        end
        w_data_q.push_back(vif.w_data);
        w_strb_q.push_back(vif.w_strb);
        if (vif.w_last) begin
          axi_req_obs ro = axi_req_obs::type_id::create("slv_wreq_obs");
          ro.port_idx    = port_idx;
          ro.is_write    = 1'b1;
          ro.id          = {{(xbar_types_pkg::ID_W_MST-xbar_types_pkg::ID_W_SLV){1'b0}}, w_cur.id};
          ro.addr        = w_cur.addr;
          ro.len         = w_cur.len;
          ro.size        = w_cur.size;
          ro.burst       = w_cur.burst;
          ro.wdata       = w_data_q;
          ro.wstrb       = w_strb_q;
          ro.atop        = w_cur.atop;
          ro.accept_time = w_cur.accept_time;
          req_ap.write(ro);
          w_busy = 1'b0;
        end
      end

      if (vif.ar_valid && vif.ar_ready) begin
        ar_rec_t a;
        axi_req_obs ro = axi_req_obs::type_id::create("slv_rreq_obs");
        ro.port_idx    = port_idx;
        ro.is_write    = 1'b0;
        ro.id          = {{(xbar_types_pkg::ID_W_MST-xbar_types_pkg::ID_W_SLV){1'b0}}, vif.ar_id};
        ro.addr        = vif.ar_addr;
        ro.len         = vif.ar_len;
        ro.size        = vif.ar_size;
        ro.burst       = vif.ar_burst;
        ro.accept_time = $time;
        req_ap.write(ro);
        // BUG-0018: read direction — AR handshake IS the accept instant, so
        // this coincides with req_ap above. Published on the accept port too so
        // the scoreboard's or_open_q/cg_stall/cg_tx_limit registration for BOTH
        // directions runs from the one place (write_slv_req_accept); read timing
        // is byte-for-byte what it was when that registration lived in
        // write_slv_req (which also ran at this AR-accept for reads).
        begin
          axi_req_obs ae = axi_req_obs::type_id::create("slv_rreq_accept");
          ae.port_idx    = port_idx;
          ae.is_write    = 1'b0;
          ae.id          = {{(xbar_types_pkg::ID_W_MST-xbar_types_pkg::ID_W_SLV){1'b0}}, vif.ar_id};
          ae.addr        = vif.ar_addr;
          ae.len         = vif.ar_len;
          ae.size        = vif.ar_size;
          ae.burst       = vif.ar_burst;
          ae.accept_time = $time;
          req_accept_ap.write(ae);
        end

        a.id    = vif.ar_id;
        a.addr  = vif.ar_addr;
        a.len   = vif.ar_len;
        a.size  = vif.ar_size;
        a.burst = vif.ar_burst;
        ar_pending_q.push_back(a);
      end

      if (vif.b_valid && vif.b_ready) begin
        axi_resp_obs bo = axi_resp_obs::type_id::create("slv_wresp_obs");
        bo.port_idx      = port_idx;
        bo.is_write      = 1'b1;
        bo.id            = vif.b_id;
        bo.resp.push_back(vif.b_resp);
        bo.complete_time = $time;
        resp_ap.write(bo);
      end

      if (vif.r_valid && vif.r_ready) begin
        xbar_types_pkg::id_slv_t rid;
        rid = vif.r_id;
        if (!(r_busy_by_id.exists(rid) && r_busy_by_id[rid])) begin
          // Start of an R burst for THIS r_id. Pair it with the oldest pending
          // read record of the same ID (a normal read's AR, or an atomic
          // load's AW-registered shadow-read record queued above, spec
          // §6.3/§6.5) — AXI4: R.id identifies the transaction (spec §1), and
          // same-ID responses return in acceptance order (spec §5.2.3), so the
          // first same-ID match is the right one. Keying the whole burst by
          // r_id means a concurrently-interleaving burst of a DIFFERENT full ID
          // (legal, spec §5.1.4) can never be misattributed into this one.
          int r_match_idx;
          r_match_idx = -1;
          foreach (ar_pending_q[qi]) begin
            if (ar_pending_q[qi].id == rid) begin
              r_match_idx = qi;
              break;
            end
          end
          if (r_match_idx < 0)
            `uvm_error("MON_RNOAR",
              "slv monitor saw an R beat with no matching accepted AR/atomic-load AW queued (AR/R pairing violated at slave port)")
          else begin
            r_cur_by_id[rid] = ar_pending_q[r_match_idx];
            ar_pending_q.delete(r_match_idx);
          end
          r_data_qq[rid].delete();
          r_resp_qq[rid].delete();
          r_busy_by_id[rid] = 1'b1;
        end
        r_data_qq[rid].push_back(vif.r_data);
        r_resp_qq[rid].push_back(vif.r_resp);
        if (vif.r_last) begin
          axi_resp_obs ro = axi_resp_obs::type_id::create("slv_rresp_obs");
          ro.port_idx      = port_idx;
          ro.is_write      = 1'b0;
          ro.id            = r_cur_by_id[rid].id;
          ro.addr          = r_cur_by_id[rid].addr;
          ro.len           = r_cur_by_id[rid].len;
          ro.size          = r_cur_by_id[rid].size;
          ro.burst         = r_cur_by_id[rid].burst;
          ro.rdata         = r_data_qq[rid];
          ro.resp          = r_resp_qq[rid];
          ro.complete_time = $time;
          resp_ap.write(ro);
          r_busy_by_id[rid] = 1'b0;
          r_data_qq.delete(rid);
          r_resp_qq.delete(rid);
          r_cur_by_id.delete(rid);
        end
      end
    end
  endtask
endclass

typedef uvm_sequencer #(axi_seq_item) slvport_sequencer;

class slvport_agent extends uvm_agent;
  `uvm_component_utils(slvport_agent)

  slvport_driver    driver;
  slvport_monitor   monitor;
  slvport_sequencer sequencer;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    driver    = slvport_driver::type_id::create("driver", this);
    monitor   = slvport_monitor::type_id::create("monitor", this);
    sequencer = slvport_sequencer::type_id::create("sequencer", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass
