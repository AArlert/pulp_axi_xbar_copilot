// tb/slvport_agent.sv — M1 UVM env: agent attached to one crossbar *slave*
// port (TB plays the external AXI master, uvm_env.md §2 "master agent").
// `include-d from tb_pkg.sv.
//
// slvport_driver: consumes axi_seq_item from the sequencer, drives AW/W or
// AR on the port, blocks for the matching B/R completion before item_done()
// (single-outstanding-per-port by construction — sidesteps the baseline
// false-conflict stall entirely, spec §5.2.1/§5.2.2/§0 row 2, since a stall
// only arises with *two* simultaneously outstanding requests on one port).
//
// slvport_monitor: purely passive (Monitor modport), reconstructs both the
// request ("input observation", spec §5.1 source-index) and the full
// request+response round trip, and publishes both to the scoreboard.
// Non-interleaved-per-port assumption matches slvport_driver's behavior
// above, so a single pending-record per direction is sufficient.

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
      axi_seq_item item;
      seq_item_port.get_next_item(item);
      if (item.is_write) drive_write(item);
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
    vif.aw_atop   <= '0; // M1-01 issues no ATOP (uvm_env.md C2.4 note)
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

    do @(posedge vif.clk_i); while (!(vif.b_valid && vif.b_ready));
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

    do @(posedge vif.clk_i);
    while (!(vif.r_valid && vif.r_ready && vif.r_last));
  endtask
endclass

class slvport_monitor extends uvm_monitor;
  `uvm_component_utils(slvport_monitor)

  virtual slvport_if vif;
  int unsigned        port_idx;
  uvm_analysis_port #(axi_req_obs)  req_ap;
  uvm_analysis_port #(axi_resp_obs) resp_ap;

  // write-collection state
  local bit                    w_busy;
  local xbar_types_pkg::id_slv_t w_id;
  local xbar_types_pkg::addr_t   w_addr;
  local axi_pkg::len_t           w_len;
  local axi_pkg::size_t          w_size;
  local axi_pkg::burst_t         w_burst;
  local xbar_types_pkg::data_t   w_data_q[$];
  local xbar_types_pkg::strb_t   w_strb_q[$];

  // read-collection state
  local bit                    r_busy;
  local xbar_types_pkg::id_slv_t r_id;
  local xbar_types_pkg::addr_t   r_addr;
  local axi_pkg::len_t           r_len;
  local axi_pkg::size_t          r_size;
  local axi_pkg::burst_t         r_burst;
  local xbar_types_pkg::data_t   r_data_q[$];
  local axi_pkg::resp_t          r_resp_q[$];

  function new(string name, uvm_component parent);
    super.new(name, parent);
    req_ap  = new("req_ap", this);
    resp_ap = new("resp_ap", this);
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
    r_busy = 1'b0;
    forever begin
      @(posedge vif.clk_i);
      if (!vif.rst_ni) continue;

      if (vif.aw_valid && vif.aw_ready) begin
        w_id    = vif.aw_id;
        w_addr  = vif.aw_addr;
        w_len   = vif.aw_len;
        w_size  = vif.aw_size;
        w_burst = vif.aw_burst;
        w_data_q.delete();
        w_strb_q.delete();
        w_busy = 1'b1;
      end
      if (w_busy && vif.w_valid && vif.w_ready) begin
        w_data_q.push_back(vif.w_data);
        w_strb_q.push_back(vif.w_strb);
        if (vif.w_last) begin
          axi_req_obs ro = axi_req_obs::type_id::create("slv_wreq_obs");
          ro.port_idx = port_idx;
          ro.is_write = 1'b1;
          ro.id       = {{(xbar_types_pkg::ID_W_MST-xbar_types_pkg::ID_W_SLV){1'b0}}, w_id};
          ro.addr     = w_addr;
          ro.len      = w_len;
          ro.size     = w_size;
          ro.burst    = w_burst;
          ro.wdata    = w_data_q;
          ro.wstrb    = w_strb_q;
          req_ap.write(ro);
          w_busy = 1'b0;
        end
      end

      if (vif.ar_valid && vif.ar_ready) begin
        axi_req_obs ro = axi_req_obs::type_id::create("slv_rreq_obs");
        ro.port_idx = port_idx;
        ro.is_write = 1'b0;
        ro.id       = {{(xbar_types_pkg::ID_W_MST-xbar_types_pkg::ID_W_SLV){1'b0}}, vif.ar_id};
        ro.addr     = vif.ar_addr;
        ro.len      = vif.ar_len;
        ro.size     = vif.ar_size;
        ro.burst    = vif.ar_burst;
        req_ap.write(ro);

        r_id    = vif.ar_id;
        r_addr  = vif.ar_addr;
        r_len   = vif.ar_len;
        r_size  = vif.ar_size;
        r_burst = vif.ar_burst;
        r_data_q.delete();
        r_resp_q.delete();
        r_busy = 1'b1;
      end

      if (vif.b_valid && vif.b_ready) begin
        axi_resp_obs bo = axi_resp_obs::type_id::create("slv_wresp_obs");
        bo.port_idx = port_idx;
        bo.is_write = 1'b1;
        bo.id       = vif.b_id;
        bo.resp.push_back(vif.b_resp);
        resp_ap.write(bo);
      end

      if (r_busy && vif.r_valid && vif.r_ready) begin
        r_data_q.push_back(vif.r_data);
        r_resp_q.push_back(vif.r_resp);
        if (vif.r_last) begin
          axi_resp_obs ro = axi_resp_obs::type_id::create("slv_rresp_obs");
          ro.port_idx = port_idx;
          ro.is_write = 1'b0;
          ro.id       = r_id;
          ro.addr     = r_addr;
          ro.len      = r_len;
          ro.size     = r_size;
          ro.burst    = r_burst;
          ro.rdata    = r_data_q;
          ro.resp     = r_resp_q;
          resp_ap.write(ro);
          r_busy = 1'b0;
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
