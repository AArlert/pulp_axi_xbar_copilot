// tb/seq_lib.sv — M1 UVM env: M1-01 happy-path routing smoke sequences
// (testplan.md M1-01, design-prompt uvm_env.md C4.1). `include-d from
// tb_pkg.sv.
//
// slvport_basic_seq: per-slv-port sequence issuing NUM_ITER write bursts
// and NUM_ITER read bursts, cycling the target master port across the
// whole map so a single run covers multiple master ports (testplan M1-01
// "目标覆盖多个 master 端口"). Every address is built from
// xbar_types_pkg::ADDR_MAP so it always hits a rule (uvm_env.md C2.4 —
// M1-01 stays on the happy path, no decode error / default port).
//
// m1_01_smoke_vseq: virtual sequence forking one slvport_basic_seq per
// slave port onto the virtual sequencer's per-port sub-sequencers, so
// traffic from different slave ports is concurrent (exercising the
// crossbar's cross-port arbitration, not just serial single-port
// transactions).

class slvport_basic_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_basic_seq)

  int unsigned slv_port_idx;
  int unsigned num_iter = 4;

  function new(string name = "slvport_basic_seq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned k = 0; k < num_iter; k++) begin
      int unsigned  tgt_mst;
      xbar_types_pkg::addr_t waddr, raddr;
      axi_seq_item  witem, ritem;

      tgt_mst = (slv_port_idx + k) % xbar_types_pkg::NO_MST_PORTS;
      waddr = xbar_types_pkg::addr_t'(tgt_mst) * xbar_types_pkg::REGION_SIZE
              + xbar_types_pkg::addr_t'(k) * 32'd128;
      raddr = xbar_types_pkg::addr_t'(tgt_mst) * xbar_types_pkg::REGION_SIZE
              + 32'h0001_0000 + xbar_types_pkg::addr_t'(k) * 32'd128;

      witem = axi_seq_item::type_id::create(
          $sformatf("witem_%0d_%0d", slv_port_idx, k));
      start_item(witem);
      witem.is_write = 1'b1;
      witem.addr     = waddr;
      witem.len      = axi_pkg::len_t'($urandom_range(0, 7));
      witem.id       = xbar_types_pkg::id_slv_t'($urandom_range(0, 31));
      witem.wdata.delete();
      witem.wstrb.delete();
      for (int unsigned b = 0; b <= witem.len; b++) begin
        xbar_types_pkg::data_t d;
        d = {$urandom(), $urandom()};
        witem.wdata.push_back(d);
        witem.wstrb.push_back('1);
      end
      finish_item(witem);

      ritem = axi_seq_item::type_id::create(
          $sformatf("ritem_%0d_%0d", slv_port_idx, k));
      start_item(ritem);
      ritem.is_write = 1'b0;
      ritem.addr     = raddr;
      ritem.len      = axi_pkg::len_t'($urandom_range(0, 7));
      ritem.id       = xbar_types_pkg::id_slv_t'($urandom_range(0, 31));
      finish_item(ritem);
    end
  endtask
endclass

class m1_01_smoke_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m1_01_smoke_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)

  function new(string name = "m1_01_smoke_vseq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork
        begin
          slvport_basic_seq s;
          s = slvport_basic_seq::type_id::create($sformatf("slv_seq_%0d", ii));
          s.slv_port_idx = ii;
          s.start(p_sequencer.slv_sqr[ii]);
        end
      join_none
    end
    wait fork;
  endtask
endclass

// ----------------------------------------------------------------------------
// M1-02 — ID-prefix response-routing smoke (testplan.md M1-02, uvm_env.md
// C4.2). Deliberately reuses the *same* low-order slave-side ID across
// multiple slave ports in the same round, each port targeting a *different*
// master port, so the crossbar must rely on the ID-prefix high
// $clog2(NoSlvPorts) bits (spec §5.1.2/§5.1.3) to route each B/R back to its
// true source slave port. Distinct target regions per port also give the
// read-data check a payload-level cross-check (a misroute would surface as
// both a source-port miss and a data mismatch).
//
// Stall-avoidance (spec §5.2.1 / uvm_env.md C4.2 note): the same-low-ID
// collisions here are *across different slave ports*, never two outstanding
// same-ID/same-direction/different-target requests on one slave port — the
// slvport driver is single-outstanding-per-port, so the §5.2 false-conflict
// stall condition is structurally never created. Within a round a port issues
// write then read serially (same ID, opposite directions, serialized), which
// is also outside the §5.2.1 (same-direction) stall trigger.
// ----------------------------------------------------------------------------
class m1_02_id_prefix_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(m1_02_id_prefix_seq)

  int unsigned slv_port_idx;
  int unsigned num_rounds = 8;

  function new(string name = "m1_02_id_prefix_seq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned k = 0; k < num_rounds; k++) begin
      int unsigned  tgt_mst;
      xbar_types_pkg::id_slv_t shared_id;
      xbar_types_pkg::addr_t waddr, raddr;
      axi_seq_item  witem, ritem;

      // Same low-order slave-side ID for every port this round (cross-port
      // collision), distinct target master port per port (spec §5.1.2/§5.1.3).
      shared_id = xbar_types_pkg::id_slv_t'(k);
      tgt_mst   = (slv_port_idx + k) % xbar_types_pkg::NO_MST_PORTS;
      waddr = xbar_types_pkg::addr_t'(tgt_mst) * xbar_types_pkg::REGION_SIZE
              + xbar_types_pkg::addr_t'(k) * 32'd128;
      raddr = xbar_types_pkg::addr_t'(tgt_mst) * xbar_types_pkg::REGION_SIZE
              + 32'h0001_0000 + xbar_types_pkg::addr_t'(k) * 32'd128;

      witem = axi_seq_item::type_id::create(
          $sformatf("witem_%0d_%0d", slv_port_idx, k));
      start_item(witem);
      witem.is_write = 1'b1;
      witem.addr     = waddr;
      witem.len      = axi_pkg::len_t'($urandom_range(0, 7));
      witem.id       = shared_id;
      witem.wdata.delete();
      witem.wstrb.delete();
      for (int unsigned b = 0; b <= witem.len; b++) begin
        xbar_types_pkg::data_t d;
        d = {$urandom(), $urandom()};
        witem.wdata.push_back(d);
        witem.wstrb.push_back('1);
      end
      finish_item(witem);

      ritem = axi_seq_item::type_id::create(
          $sformatf("ritem_%0d_%0d", slv_port_idx, k));
      start_item(ritem);
      ritem.is_write = 1'b0;
      ritem.addr     = raddr;
      ritem.len      = axi_pkg::len_t'($urandom_range(0, 7));
      ritem.id       = shared_id;
      finish_item(ritem);
    end
  endtask
endclass

class m1_02_id_prefix_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m1_02_id_prefix_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)

  function new(string name = "m1_02_id_prefix_vseq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork
        begin
          m1_02_id_prefix_seq s;
          s = m1_02_id_prefix_seq::type_id::create(
              $sformatf("m1_02_seq_%0d", ii));
          s.slv_port_idx = ii;
          s.start(p_sequencer.slv_sqr[ii]);
        end
      join_none
    end
    wait fork;
  endtask
endclass
