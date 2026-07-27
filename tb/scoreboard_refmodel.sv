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

  // Keyed by the *expected* master-side id — unique per outstanding
  // transaction since (a) ID prefixing makes different slv ports' ID
  // spaces disjoint (spec §5.1.4) and (b) this env never has two
  // outstanding requests on the same slv port at once (single pending
  // record per source id is always sufficient).
  local pend_rec_t pending_by_id[bit [xbar_types_pkg::ID_W_MST-1:0]];

  int unsigned route_match_cnt;
  int unsigned route_mismatch_cnt;
  int unsigned resp_match_cnt;
  int unsigned resp_mismatch_cnt;

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
    pending_by_id[exp_id] = rec;
  endfunction

  // ---- request-side, mst-port stream: check the expectation (§3.1/§3.2,
  // §5.1.1, C4.1/C4.3) -----------------------------------------------------
  virtual function void write_mst_req(axi_req_obs ro);
    pend_rec_t rec;
    bit found;
    bit [xbar_types_pkg::ID_W_MST-1:0] key;
    key = ro.id[xbar_types_pkg::ID_W_MST-1:0];
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
      $sformatf("route: match=%0d mismatch=%0d | resp: match=%0d mismatch=%0d | pending(unmatched at end)=%0d",
                 route_match_cnt, route_mismatch_cnt, resp_match_cnt,
                 resp_mismatch_cnt, pending_by_id.num()),
      UVM_LOW)
    if (pending_by_id.num() != 0) begin
      `uvm_error("SB_DANGLING",
        $sformatf("%0d slv-side request(s) never observed a matching mst-side request — routing incomplete at end of test",
                   pending_by_id.num()))
    end
  endfunction
endclass
