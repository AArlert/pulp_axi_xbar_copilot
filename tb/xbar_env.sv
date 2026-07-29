// tb/xbar_env.sv — M1 UVM env: top-level env + virtual sequencer
// (design-prompt uvm_env.md §0/§1). `include-d from tb_pkg.sv.

class xbar_vseqr extends uvm_sequencer #(uvm_sequence_item);
  `uvm_component_utils(xbar_vseqr)

  slvport_sequencer slv_sqr[xbar_types_pkg::NO_SLV_PORTS];

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

class xbar_env extends uvm_env;
  `uvm_component_utils(xbar_env)

  slvport_agent   slv_agent[xbar_types_pkg::NO_SLV_PORTS];
  mstport_agent   mst_agent[xbar_types_pkg::NO_MST_PORTS];
  xbar_scoreboard sb;
  xbar_vseqr      vseqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++)
      slv_agent[i] =
          slvport_agent::type_id::create($sformatf("slv_agent[%0d]", i), this);
    for (int unsigned j = 0; j < xbar_types_pkg::NO_MST_PORTS; j++)
      mst_agent[j] =
          mstport_agent::type_id::create($sformatf("mst_agent[%0d]", j), this);
    sb    = xbar_scoreboard::type_id::create("sb", this);
    vseqr = xbar_vseqr::type_id::create("vseqr", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      slv_agent[i].monitor.req_ap.connect(sb.slv_req_imp);
      // BUG-0018: accept-instant request stream → the scoreboard handler that
      // owns the accept-anchored coverage-input registrations (or_open_q /
      // cg_stall / cg_tx_limit / worder_pend). Coexists with req_ap above.
      slv_agent[i].monitor.req_accept_ap.connect(sb.slv_req_accept_imp);
      slv_agent[i].monitor.resp_ap.connect(sb.resp_imp);
      vseqr.slv_sqr[i] = slv_agent[i].sequencer;
    end
    for (int unsigned j = 0; j < xbar_types_pkg::NO_MST_PORTS; j++) begin
      mst_agent[j].monitor.req_ap.connect(sb.mst_req_imp);
    end
  endfunction
endclass
