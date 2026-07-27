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
    xbar_types_pkg::data_t  wdata[$];
    xbar_types_pkg::strb_t  wstrb[$];
  } pend_rec_t;

  // Keyed by {direction, expected master-side id} — unique per outstanding
  // transaction since (a) ID prefixing makes different slv ports' ID spaces
  // disjoint (spec §5.1.4), (b) read and write are independent AXI channels
  // so the direction bit keeps a same-id write and read from aliasing (M1-02
  // deliberately reuses one slv-side id for both a write and a read on the
  // same port), and (c) this env never has two outstanding same-direction
  // requests on one slv port at once (single pending record per key suffices).
  local pend_rec_t pending_by_id[bit [xbar_types_pkg::ID_W_MST:0]];

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
  // (port,dir,slv-id) recurs across the test; the slvport driver is
  // single-outstanding-per-port-per-direction, so any live count is 0/1.
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

  function new(string name, uvm_component parent);
    super.new(name, parent);
    slv_req_imp = new("slv_req_imp", this);
    mst_req_imp = new("mst_req_imp", this);
    resp_imp    = new("resp_imp", this);
  endfunction

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

    hit = xbar_types_pkg::decode_mst_port(ro.addr, exp_port);
    if (!hit) begin
      `uvm_error("SB_DECODE",
        $sformatf("slv port %0d addr 'h%0h matched no address-map rule — M1-01 must only send mapped addresses (spec §3.2, uvm_env.md C2.4)",
                   ro.port_idx, ro.addr))
      return;
    end

    rec.exp_mst_port = exp_port;
    rec.is_write      = ro.is_write;
    rec.addr          = ro.addr;
    rec.len           = ro.len;
    rec.size          = ro.size;
    rec.burst         = ro.burst;
    if (ro.is_write) begin
      rec.wdata = ro.wdata;
      rec.wstrb = ro.wstrb;
    end
    exp_id = build_exp_id(ro.port_idx, ro.id[xbar_types_pkg::ID_W_SLV-1:0]);
    pending_by_id[pend_key(ro.is_write, exp_id)] = rec;

    // C3.2: record that source port ro.port_idx now expects a response for
    // this (direction, slv-side id) back on its own port (spec §5.1.2/§5.1.3).
    resp_expect[resp_key(ro.port_idx, ro.is_write,
                         ro.id[xbar_types_pkg::ID_W_SLV-1:0])]++;
  endfunction

  // ---- request-side, mst-port stream: check the expectation (§3.1/§3.2,
  // §5.1.1, C4.1/C4.3) -----------------------------------------------------
  virtual function void write_mst_req(axi_req_obs ro);
    pend_rec_t rec;
    bit found;
    bit [xbar_types_pkg::ID_W_MST:0] key;
    key = pend_key(ro.is_write, ro.id[xbar_types_pkg::ID_W_MST-1:0]);
    found = pending_by_id.exists(key);
    if (!found) begin
      route_mismatch_cnt++;
      `uvm_error("SB_NOPEND",
        $sformatf("mst port %0d observed id 'h%0h with no matching pending record (spec §5.1.1 prefix formula violated, or unexpected transaction)",
                   ro.port_idx, ro.id))
      return;
    end
    rec = pending_by_id[key];
    pending_by_id.delete(key);

    if (ro.is_write != rec.is_write || ro.port_idx != rec.exp_mst_port
        || ro.addr != rec.addr || ro.len != rec.len || ro.size != rec.size
        || ro.burst != rec.burst) begin
      route_mismatch_cnt++;
      `uvm_error("SB_ROUTE",
        $sformatf("routing/attr mismatch id 'h%0h: got port=%0d write=%0d addr='h%0h len=%0d — expected port=%0d write=%0d addr='h%0h len=%0d (spec §3.1/§3.2/§1)",
                   ro.id, ro.port_idx, ro.is_write, ro.addr, ro.len,
                   rec.exp_mst_port, rec.is_write, rec.addr, rec.len))
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
    super.report_phase(phase);
    `uvm_info("SB_SUMMARY",
      $sformatf("route: match=%0d mismatch=%0d | resp: match=%0d mismatch=%0d | resp-route(C3.2): match=%0d mismatch=%0d | pending(unmatched at end)=%0d",
                 route_match_cnt, route_mismatch_cnt, resp_match_cnt,
                 resp_mismatch_cnt, resp_route_match_cnt,
                 resp_route_mismatch_cnt, pending_by_id.num()),
      UVM_LOW)
    if (pending_by_id.num() != 0) begin
      `uvm_error("SB_DANGLING",
        $sformatf("%0d slv-side request(s) never observed a matching mst-side request — routing incomplete at end of test",
                   pending_by_id.num()))
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
  endfunction
endclass
