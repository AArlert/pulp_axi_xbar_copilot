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

// ----------------------------------------------------------------------------
// M2-OR01/OR02 — same-ID cross-port ordering: stall trigger (testplan.md
// M2-OR01) and non-stall counter-examples (testplan.md M2-OR02). Both
// scenarios share the one construction primitive (uvm_env.md C5.2:
// "同一套原语覆盖两个场景，不重复开发") — build_or_pair() below builds one
// axi_pair_item independently controlling the four dimensions: (a) shared
// low-Cfg.AxiIdUsedSlvPorts-bit ID bucket, (b) direction of each leg, (c)
// each leg's target master port, (d) the gap between presenting the two
// AW/AR handshakes.
//
// (a) note: the two legs use *different* full slv-side IDs (upper, unused
// ID bits 0 vs 1) that happen to share the low AxiIdUsedSlvPorts=3 bits —
// the bucket the DUT itself compares (spec §5.2.2). This keeps every pair
// collision-free in the pre-existing, per-*full*-ID M1 routing-check maps
// (scoreboard_refmodel.md pending_by_id/resp_expect key off the full
// 5-bit slv-side id, not just its low 3 bits), while still landing both
// legs in the one bucket spec §5.2 cares about.
// ----------------------------------------------------------------------------
function automatic axi_pair_item build_or_pair(
    input string        name,
    input bit           dir_a, input bit dir_b,
    input int unsigned  tgt_a, input int unsigned tgt_b,
    input int unsigned  bucket, input xbar_types_pkg::addr_t addr_ofs,
    input int unsigned  gap_cycles);
  axi_pair_item item;
  item = axi_pair_item::type_id::create(name);
  item.is_write = dir_a;
  item.id       = xbar_types_pkg::id_slv_t'({2'd0, bucket[2:0]});
  item.addr     = xbar_types_pkg::addr_t'(tgt_a) * xbar_types_pkg::REGION_SIZE
                  + addr_ofs;
  item.len      = axi_pkg::len_t'(3);
  if (dir_a) begin
    item.wdata.delete();
    item.wstrb.delete();
    for (int unsigned b = 0; b <= item.len; b++) begin
      item.wdata.push_back({$urandom(), $urandom()});
      item.wstrb.push_back('1);
    end
  end

  item.second_item = axi_seq_item::type_id::create({name, "_b"});
  item.second_item.is_write = dir_b;
  item.second_item.id       = xbar_types_pkg::id_slv_t'({2'd1, bucket[2:0]});
  item.second_item.addr     = xbar_types_pkg::addr_t'(tgt_b) * xbar_types_pkg::REGION_SIZE
                               + addr_ofs + 32'h0000_4000;
  item.second_item.len      = axi_pkg::len_t'(3);
  if (dir_b) begin
    item.second_item.wdata.delete();
    item.second_item.wstrb.delete();
    for (int unsigned b = 0; b <= item.second_item.len; b++) begin
      item.second_item.wdata.push_back({$urandom(), $urandom()});
      item.second_item.wstrb.push_back('1);
    end
  end
  item.gap_cycles = gap_cycles;
  return item;
endfunction

// M2-OR01 (testplan.md): same bucket, same direction, *different* target —
// must stall (spec §5.2.1/§5.2.2). One write-write pair (back-to-back, gap
// 0) and one read-read pair (deliberately separated, gap 5) per slv port,
// exercising uvm_env.md C5.2 dimension (d) both ways.
class slvport_or01_stall_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_or01_stall_seq)

  int unsigned slv_port_idx;

  function new(string name = "slvport_or01_stall_seq");
    super.new(name);
  endfunction

  task body();
    axi_pair_item p;
    int unsigned  tgt_a, tgt_b;
    tgt_a = slv_port_idx % xbar_types_pkg::NO_MST_PORTS;
    tgt_b = (slv_port_idx + 1) % xbar_types_pkg::NO_MST_PORTS;

    p = build_or_pair($sformatf("or01_ww_%0d", slv_port_idx),
                       1'b1, 1'b1, tgt_a, tgt_b, slv_port_idx, 32'h0000, 0);
    start_item(p);
    finish_item(p);

    p = build_or_pair($sformatf("or01_rr_%0d", slv_port_idx),
                       1'b0, 1'b0, tgt_a, tgt_b, slv_port_idx, 32'h0100, 5);
    start_item(p);
    finish_item(p);
  endtask
endclass

class m2_or01_stall_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m2_or01_stall_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)

  function new(string name = "m2_or01_stall_vseq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork
        begin
          slvport_or01_stall_seq s;
          s = slvport_or01_stall_seq::type_id::create(
              $sformatf("or01_seq_%0d", ii));
          s.slv_port_idx = ii;
          s.start(p_sequencer.slv_sqr[ii]);
        end
      join_none
    end
    wait fork;
  endtask
endclass

// M2-OR02 (testplan.md): non-stall counter-examples — (a) same bucket,
// same direction, *same* target (spec §5.2.4) and (b) same bucket,
// *opposite* direction (spec §5.2.1 "same direction" scope boundary).
class slvport_or02_nonstall_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_or02_nonstall_seq)

  int unsigned slv_port_idx;

  function new(string name = "slvport_or02_nonstall_seq");
    super.new(name);
  endfunction

  task body();
    axi_pair_item p;
    int unsigned  tgt_same, tgt_other;
    tgt_same  = slv_port_idx % xbar_types_pkg::NO_MST_PORTS;
    tgt_other = (slv_port_idx + 1) % xbar_types_pkg::NO_MST_PORTS;

    // (a) same target, same direction — spec §5.2.4.
    p = build_or_pair($sformatf("or02a_ww_%0d", slv_port_idx),
                       1'b1, 1'b1, tgt_same, tgt_same, slv_port_idx, 32'h0200, 0);
    start_item(p);
    finish_item(p);
    p = build_or_pair($sformatf("or02a_rr_%0d", slv_port_idx),
                       1'b0, 1'b0, tgt_same, tgt_same, slv_port_idx, 32'h0300, 3);
    start_item(p);
    finish_item(p);

    // (b) opposite direction — target choice is irrelevant to spec §5.2.1's
    // "same direction" scope, kept distinct for a stronger cross-check.
    p = build_or_pair($sformatf("or02b_wr_%0d", slv_port_idx),
                       1'b1, 1'b0, tgt_same, tgt_other, slv_port_idx, 32'h0400, 0);
    start_item(p);
    finish_item(p);
    p = build_or_pair($sformatf("or02b_rw_%0d", slv_port_idx),
                       1'b0, 1'b1, tgt_other, tgt_same, slv_port_idx, 32'h0500, 4);
    start_item(p);
    finish_item(p);
  endtask
endclass

class m2_or02_nonstall_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m2_or02_nonstall_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)

  function new(string name = "m2_or02_nonstall_vseq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork
        begin
          slvport_or02_nonstall_seq s;
          s = slvport_or02_nonstall_seq::type_id::create(
              $sformatf("or02_seq_%0d", ii));
          s.slv_port_idx = ii;
          s.start(p_sequencer.slv_sqr[ii]);
        end
      join_none
    end
    wait fork;
  endtask
endclass

// ----------------------------------------------------------------------------
// M2-AT01 — ATOP atomic read (testplan.md M2-AT01, uvm_env.md C5.5, spec
// §6.3/§6.4). Encoding from vendor/axi/src/axi_pkg.sv (the DV parameter-
// definition source): an atomic load is aw.atop[5:4]=ATOP_ATOMICLOAD, with
// aw.atop[ATOP_R_RESP] (= bit 5) set — the transaction owes its port both a
// B and an R (spec §6.3).
//
// Phase A: each port issues two standalone atomic loads (different target
// master ports). The blocking driver keeps them single-outstanding, so the
// §6.4 ID-uniqueness constraint holds trivially; the scoreboard/SVA judge
// the B+R pair.
//
// Phase B: one mixed pair per port — a normal read leg in flight, then the
// atomic load presented while it is (best-effort; no cycle count is relied
// on). This exercises the §6.4 guarantee against a *non-empty* in-flight
// set (SVA C3.5 property-2 premise, covered non-vacuously). Constructive
// choices: (a) both legs target the *same* master port, so the single
// responder serializes the two R bursts (no R interleave at the source
// port); (b) the two legs use different full IDs *and* different low-
// AxiIdUsedSlvPorts buckets, staying structurally clear of the §6.5/
// BUG-0012 shadow-AR cross-direction stall — that (non-judgemental)
// same-bucket overlap observation belongs to the functional-coverage card
// (BUG-0012 ## regression_guard), not this one.
// ----------------------------------------------------------------------------
class slvport_at01_atop_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_at01_atop_seq)

  int unsigned slv_port_idx;

  // ATOP[5:4]=ATOMICLOAD, ATOP[3]=LITTLE_END, ATOP[2:0]=ADD (axi_pkg.sv).
  localparam axi_pkg::atop_t ATOP_LOAD_ADD =
      {axi_pkg::ATOP_ATOMICLOAD, axi_pkg::ATOP_LITTLE_END, axi_pkg::ATOP_ADD};

  function new(string name = "slvport_at01_atop_seq");
    super.new(name);
  endfunction

  task body();
    // ---- Phase A: standalone atomic loads (spec §6.3 core criterion) ----
    for (int unsigned k = 0; k < 2; k++) begin
      int unsigned tgt;
      axi_seq_item item;
      tgt  = (slv_port_idx + k) % xbar_types_pkg::NO_MST_PORTS;
      item = axi_seq_item::type_id::create(
          $sformatf("at01a_%0d_%0d", slv_port_idx, k));
      start_item(item);
      item.is_write = 1'b1;
      item.atop     = ATOP_LOAD_ADD;
      item.addr     = xbar_types_pkg::addr_t'(tgt) * xbar_types_pkg::REGION_SIZE
                      + 32'h0000_0600
                      + xbar_types_pkg::addr_t'(slv_port_idx) * 32'h40
                      + xbar_types_pkg::addr_t'(k) * 32'h10;
      item.len      = axi_pkg::len_t'(0); // single full-width beat
      item.id       = xbar_types_pkg::id_slv_t'(slv_port_idx * 2 + k);
      item.wdata.delete();
      item.wstrb.delete();
      item.wdata.push_back({$urandom(), $urandom()});
      item.wstrb.push_back('1);
      finish_item(item);
    end

    // ---- Phase B: atomic load overlapping an in-flight normal read
    // (spec §6.4 exercised non-vacuously) ---------------------------------
    begin
      axi_pair_item p;
      int unsigned  tgt;
      tgt = slv_port_idx % xbar_types_pkg::NO_MST_PORTS;

      p = axi_pair_item::type_id::create(
          $sformatf("at01b_%0d", slv_port_idx));
      // leg A: normal read, low-ID bucket = slv_port_idx[2:0]
      p.is_write = 1'b0;
      p.id       = xbar_types_pkg::id_slv_t'({2'd0, slv_port_idx[2:0]});
      p.addr     = xbar_types_pkg::addr_t'(tgt) * xbar_types_pkg::REGION_SIZE
                   + 32'h0000_0700
                   + xbar_types_pkg::addr_t'(slv_port_idx) * 32'h40;
      p.len      = axi_pkg::len_t'(3);
      // leg B: atomic load, different full ID and different low bucket
      // ((x+3)%8 != x%8), same target master port — see class header.
      p.second_item = axi_seq_item::type_id::create(
          $sformatf("at01b_%0d_b", slv_port_idx));
      p.second_item.is_write = 1'b1;
      p.second_item.atop     = ATOP_LOAD_ADD;
      p.second_item.id       = xbar_types_pkg::id_slv_t'(
          {2'd0, 3'((slv_port_idx + 3) % 8)});
      p.second_item.addr     = xbar_types_pkg::addr_t'(tgt)
                               * xbar_types_pkg::REGION_SIZE
                               + 32'h0000_0800
                               + xbar_types_pkg::addr_t'(slv_port_idx) * 32'h40;
      p.second_item.len      = axi_pkg::len_t'(0);
      p.second_item.wdata.delete();
      p.second_item.wstrb.delete();
      p.second_item.wdata.push_back({$urandom(), $urandom()});
      p.second_item.wstrb.push_back('1);
      p.gap_cycles = 1;
      start_item(p);
      finish_item(p);
    end
  endtask
endclass

class m2_at01_atop_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m2_at01_atop_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)

  function new(string name = "m2_at01_atop_vseq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork
        begin
          slvport_at01_atop_seq s;
          s = slvport_at01_atop_seq::type_id::create(
              $sformatf("at01_seq_%0d", ii));
          s.slv_port_idx = ii;
          s.start(p_sequencer.slv_sqr[ii]);
        end
      join_none
    end
    wait fork;
  endtask
endclass

// ----------------------------------------------------------------------------
// M2-WO01 — W channel order under multi-source convergence (testplan.md
// M2-WO01, uvm_env.md C5.4, spec §5.5.1/§5.5.2). Every slave port drives a
// stream of write bursts at ONE common master port (WO01_TGT_MST) so their
// AWs interleave/converge there far more tightly than M1-02's incidental
// overlap. Each pair is pipelined by drive_pair (leg A's W burst overlaps
// leg B's AW), so several AWs from one source stack up at the master port;
// with all sources doing this concurrently the master port genuinely sees
// ≥2 different-source AWs pending at W-burst starts (the sva_bind.md C3.3
// cover condition, axi_xbar_worder_sva.sv).
//
// The two legs of every pair use *different* full slave-side IDs spanning
// *different* low-AxiIdUsedSlvPorts buckets, so the master-side same-source
// completion order is a genuine spec §5.5.1 property (W follows AW
// regardless of ID) rather than a spec §5.2 same-ID-bucket consequence.
//
// Judgement is the scoreboard's per-(source,target) SB_WORDER check (each
// source's own bursts complete in that source's AW-accept order) — this
// sequence asserts NOTHING about cross-source order (spec §5.5.4 / REV-006
// §4.3 red line), it only provides the convergence.
// ----------------------------------------------------------------------------
function automatic axi_pair_item build_wo01_pair(
    input string        name,
    input int unsigned  tgt, input int unsigned pair_idx,
    input int unsigned  gap_cycles);
  axi_pair_item item;
  item = axi_pair_item::type_id::create(name);
  item.is_write = 1'b1;
  item.id       = xbar_types_pkg::id_slv_t'(2*pair_idx);
  item.addr     = xbar_types_pkg::addr_t'(tgt) * xbar_types_pkg::REGION_SIZE
                  + 32'h0000_0800 + xbar_types_pkg::addr_t'(pair_idx) * 32'h80;
  item.len      = axi_pkg::len_t'(3);
  item.wdata.delete();
  item.wstrb.delete();
  for (int unsigned b = 0; b <= item.len; b++) begin
    item.wdata.push_back({$urandom(), $urandom()});
    item.wstrb.push_back('1);
  end

  item.second_item = axi_seq_item::type_id::create({name, "_b"});
  item.second_item.is_write = 1'b1;
  item.second_item.id       = xbar_types_pkg::id_slv_t'(2*pair_idx + 1);
  item.second_item.addr     = xbar_types_pkg::addr_t'(tgt) * xbar_types_pkg::REGION_SIZE
                              + 32'h0000_0c00 + xbar_types_pkg::addr_t'(pair_idx) * 32'h80;
  item.second_item.len      = axi_pkg::len_t'(3);
  item.second_item.wdata.delete();
  item.second_item.wstrb.delete();
  for (int unsigned b = 0; b <= item.second_item.len; b++) begin
    item.second_item.wdata.push_back({$urandom(), $urandom()});
    item.second_item.wstrb.push_back('1);
  end
  item.gap_cycles = gap_cycles;
  return item;
endfunction

class slvport_wo01_conv_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_wo01_conv_seq)

  int unsigned slv_port_idx;
  int unsigned tgt_mst   = 0;  // common convergence target (set by the vseq)
  int unsigned num_pairs = 4;  // 8 writes/source, IDs 0..7 (distinct buckets)

  function new(string name = "slvport_wo01_conv_seq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned p = 0; p < num_pairs; p++) begin
      axi_pair_item item;
      item = build_wo01_pair($sformatf("wo01_%0d_%0d", slv_port_idx, p),
                              tgt_mst, p, slv_port_idx % 3);
      start_item(item);
      finish_item(item);
    end
  endtask
endclass

class m2_wo01_worder_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m2_wo01_worder_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)

  function new(string name = "m2_wo01_worder_vseq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork
        begin
          slvport_wo01_conv_seq s;
          s = slvport_wo01_conv_seq::type_id::create(
              $sformatf("wo01_seq_%0d", ii));
          s.slv_port_idx = ii;
          s.tgt_mst      = 0; // all sources converge on master port 0
          s.start(p_sequencer.slv_sqr[ii]);
        end
      join_none
    end
    wait fork;
  endtask
endclass

// ----------------------------------------------------------------------------
// M2-TL01 — MaxMstTrans transaction-number ceiling (testplan.md M2-TL01,
// uvm_env.md C5.3, scoreboard_refmodel.md C5.3, sva_bind.md C3.4; spec
// §5.4.1/§5.4.3, §7.4.5). Each slave port back-to-back fires n>MaxMstTrans
// same-direction requests at ONE target master port, all in ONE low-
// AxiIdUsedSlvPorts-bit bucket, so the demux's per-(bucket,direction) counter
// (spec §5.4.1) is pushed to its ceiling. A single bucket spans only
// 2**(ID_W_SLV-AxiIdUsedSlvPorts)=4 full ids, and one full id may itself hold
// at most MaxSlvTrans=6 at the master port, so filling the bucket to
// MaxMstTrans=10 REQUIRES spreading across the bucket's sibling ids — the
// helper cycles the 4 of them (≤3 each, well under MaxSlvTrans). Single target
// throughout keeps this strictly a counting scenario, never a §5.2 cross-
// target stall (uvm_env.md C5.3). The judgement (master-port in-flight never
// exceeds MaxMstTrans, and reaches it non-vacuously) lives in
// axi_xbar_txlimit_sva; the responder holds its B/R (resp_hold, set by the
// test) so the count is genuinely stressed rather than draining away ("空转").
// ----------------------------------------------------------------------------
function automatic axi_burst_item build_txlimit_burst(
    input string        name,
    input bit           is_write,
    input int unsigned  tgt_mst,
    input int unsigned  n,
    input xbar_types_pkg::addr_t addr_base,
    input bit           spread_bucket,      // 1=cycle bucket siblings (TL01);
    input int unsigned  bucket_or_id);      // 0=single full id (TL02)
  axi_burst_item burst;
  burst = axi_burst_item::type_id::create(name);
  for (int unsigned k = 0; k < n; k++) begin
    axi_seq_item it;
    logic [1:0]  hi;
    it  = axi_seq_item::type_id::create($sformatf("%s_%0d", name, k));
    hi  = k[1:0];
    it.is_write = is_write;
    // TL01: {rotating upper-2 bits, fixed bucket} — same bucket, up-to-4
    // distinct full ids. TL02: one fixed full id for every sub-transaction.
    it.id = spread_bucket
              ? xbar_types_pkg::id_slv_t'({hi, bucket_or_id[2:0]})
              : xbar_types_pkg::id_slv_t'(bucket_or_id[4:0]);
    it.addr = xbar_types_pkg::addr_t'(tgt_mst) * xbar_types_pkg::REGION_SIZE
              + addr_base + xbar_types_pkg::addr_t'(k) * 32'h40;
    it.len  = axi_pkg::len_t'(0); // single full-width beat — fast to fill
    if (is_write) begin
      it.wdata.push_back({$urandom(), $urandom()});
      it.wstrb.push_back('1);
    end
    burst.items.push_back(it);
  end
  return burst;
endfunction

class slvport_tl01_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_tl01_seq)

  int unsigned slv_port_idx;
  int unsigned num_tx = 12; // > MaxMstTrans=10, so the ceiling is genuinely hit

  function new(string name = "slvport_tl01_seq");
    super.new(name);
  endfunction

  task body();
    axi_burst_item wb, rb;
    int unsigned    tgt;
    tgt = slv_port_idx % xbar_types_pkg::NO_MST_PORTS;
    // write-direction fill, then (serialised) read-direction fill — one bucket
    // (0) throughout; each direction fills its own demux counter (spec §5.4.1).
    wb = build_txlimit_burst($sformatf("tl01_w_%0d", slv_port_idx),
                              1'b1, tgt, num_tx, 32'h0000_1000, 1'b1, 0);
    start_item(wb);
    finish_item(wb);
    rb = build_txlimit_burst($sformatf("tl01_r_%0d", slv_port_idx),
                              1'b0, tgt, num_tx, 32'h0002_0000, 1'b1, 0);
    start_item(rb);
    finish_item(rb);
  endtask
endclass

class m2_tl01_txlimit_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m2_tl01_txlimit_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)

  function new(string name = "m2_tl01_txlimit_vseq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork
        begin
          slvport_tl01_seq s;
          s = slvport_tl01_seq::type_id::create($sformatf("tl01_seq_%0d", ii));
          s.slv_port_idx = ii;
          s.start(p_sequencer.slv_sqr[ii]);
        end
      join_none
    end
    wait fork;
  endtask
endclass

// ----------------------------------------------------------------------------
// M2-TL02 — MaxSlvTrans observable-upper-bound monitor (testplan.md M2-TL02,
// uvm_env.md C5.3, scoreboard_refmodel.md C5.3, sva_bind.md C3.4; spec §5.4.2/
// §5.4.3, BUG-0011 SPEC_CHANGED / REV-005). Each slave port back-to-back fires
// n same-full-(prefix-after-)id, same-direction requests at ONE target master
// port (legal to stack per spec §5.2.4). Only the weakened observable-upper-
// bound is judged — master-port in-flight per (full id, direction) ≤
// MaxSlvTrans=6 (axi_xbar_txlimit_sva); NO mechanism-level "which Nth beat is
// refused, when" is asserted (the card's / REV-005's hard red line, spec
// §5.4.3 upstream-confirmation item). n slightly over MaxSlvTrans exercises
// the cap non-vacuously.
// ----------------------------------------------------------------------------
class slvport_tl02_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_tl02_seq)

  int unsigned slv_port_idx;
  int unsigned num_tx = 8; // > MaxSlvTrans=6

  function new(string name = "slvport_tl02_seq");
    super.new(name);
  endfunction

  task body();
    axi_burst_item wb, rb;
    int unsigned    tgt;
    xbar_types_pkg::id_slv_t sid;
    tgt = slv_port_idx % xbar_types_pkg::NO_MST_PORTS;
    sid = xbar_types_pkg::id_slv_t'(0); // one fixed full slv-side id
    wb = build_txlimit_burst($sformatf("tl02_w_%0d", slv_port_idx),
                              1'b1, tgt, num_tx, 32'h0004_0000, 1'b0, int'(sid));
    start_item(wb);
    finish_item(wb);
    rb = build_txlimit_burst($sformatf("tl02_r_%0d", slv_port_idx),
                              1'b0, tgt, num_tx, 32'h0006_0000, 1'b0, int'(sid));
    start_item(rb);
    finish_item(rb);
  endtask
endclass

class m2_tl02_slvtrans_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m2_tl02_slvtrans_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)

  function new(string name = "m2_tl02_slvtrans_vseq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork
        begin
          slvport_tl02_seq s;
          s = slvport_tl02_seq::type_id::create($sformatf("tl02_seq_%0d", ii));
          s.slv_port_idx = ii;
          s.start(p_sequencer.slv_sqr[ii]);
        end
      join_none
    end
    wait fork;
  endtask
endclass

// ----------------------------------------------------------------------------
// M2-OR03 — BUG-0023/BUG-0024 joint regression guard (testplan.md M2-OR03,
// spec §5.2.1/§5.2.3/§5.2.4, §7.4.5). One slave port, ONE full slave-side id
// X per iteration:
//   (1) n_a same-direction requests at master port A, presented back-to-back
//       (drive_burst never waits for a completion in between), so they stack
//       up legally in flight — spec §5.2.4 exempts same-id/same-direction/
//       SAME-target requests from the §5.2 stall. n_a is deliberately well
//       past "≥2" (testplan's floor) so the in-flight count also runs into the
//       DUT's own per-(bucket,direction) ceiling (spec §5.4.1, effective 15):
//       once there, each further AW/AR acceptance is paced by a returning
//       B/rlast, which is the interleaving BUG-0023's ## regression_guard
//       names as the way to reach its same-edge corner.
//   (2) n_b requests with the SAME full id X at master port B (B != A),
//       presented while that stack is still in flight — per spec §5.2.1 these
//       may not be forwarded until every earlier same-id request on A has
//       completed, so their acceptance/forwarding is released exactly around
//       the last A completion (BUG-0023's same-edge "AW accept + B complete on
//       one full id" chance, and BUG-0024's "≥2 same-target in flight while a
//       different-target same-id request waits" corner).
// The responder is left at its default zero hold (testplan: "对 A 上堆积事务
// 的应答不额外背压"), so the release above happens under natural run
// conditions; nothing here asserts any cycle count (spec §7.4.5). Write and
// read mirrors are built by the same helper, and the iteration walks several
// full ids so the timing coincidence gets many independent chances.
// ----------------------------------------------------------------------------
function automatic axi_burst_item build_or03_burst(
    input string        name,
    input bit           is_write,
    input xbar_types_pkg::id_slv_t id_full,
    input int unsigned  tgt_a, input int unsigned tgt_b,
    input int unsigned  n_a,   input int unsigned n_b,
    input xbar_types_pkg::addr_t addr_base);
  axi_burst_item burst;
  burst = axi_burst_item::type_id::create(name);
  for (int unsigned k = 0; k < n_a + n_b; k++) begin
    axi_seq_item it;
    int unsigned tgt;
    tgt = (k < n_a) ? tgt_a : tgt_b;
    it  = axi_seq_item::type_id::create($sformatf("%s_%0d", name, k));
    it.is_write = is_write;
    it.id       = id_full;                 // ONE full id for the whole group
    it.addr     = xbar_types_pkg::addr_t'(tgt) * xbar_types_pkg::REGION_SIZE
                  + addr_base + xbar_types_pkg::addr_t'(k) * 32'h40;
    // Reads: single beat — an AR per cycle is what drives the in-flight count
    // to the ceiling. Writes: alternate AxLEN 0/1, i.e. 2 and 3 cycles per
    // request. A uniform write stream is phase-locked against the returning B
    // stream (AW handshakes land on one parity, B handshakes on the other), so
    // the same-edge accept+complete BUG-0023 needs never occurs; alternating
    // the length sweeps that phase instead of adding response backpressure,
    // which this scenario is not allowed to add. Measured: uniform AxLEN=0
    // gives 0 write-side collisions, alternating gives 192.
    it.len      = axi_pkg::len_t'(is_write ? (k % 2) : 0);
    if (is_write) begin
      for (int unsigned b = 0; b <= it.len; b++) begin
        it.wdata.push_back({$urandom(), $urandom()});
        it.wstrb.push_back('1);
      end
    end
    burst.items.push_back(it);
  end
  return burst;
endfunction

class slvport_or03_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_or03_seq)

  int unsigned slv_port_idx;
  int unsigned num_ids = 4;  // distinct full ids iterated, one group each
  int unsigned n_a     = 14; // same-target stack (>= 2, testplan floor)
  int unsigned n_b     = 4;  // different-target requests behind the stall

  function new(string name = "slvport_or03_seq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned it = 0; it < num_ids; it++) begin
      axi_burst_item wb, rb;
      xbar_types_pkg::id_slv_t id_full;
      int unsigned tgt_a, tgt_b;
      // Full id = {2-bit iteration index, this port's own 3-bit bucket}: one
      // full id per group, four distinct ones per port, and groups are
      // serialised (start_item blocks to completion) so no two of them are
      // ever in flight together.
      id_full = xbar_types_pkg::id_slv_t'({it[1:0], slv_port_idx[2:0]});
      tgt_a   = (slv_port_idx + it) % xbar_types_pkg::NO_MST_PORTS;
      tgt_b   = (tgt_a + 1) % xbar_types_pkg::NO_MST_PORTS;

      wb = build_or03_burst($sformatf("or03_w_%0d_%0d", slv_port_idx, it),
                             1'b1, id_full, tgt_a, tgt_b, n_a, n_b,
                             32'h0008_0000 + xbar_types_pkg::addr_t'(it) * 32'h1000);
      start_item(wb);
      finish_item(wb);

      rb = build_or03_burst($sformatf("or03_r_%0d_%0d", slv_port_idx, it),
                             1'b0, id_full, tgt_a, tgt_b, n_a, n_b,
                             32'h000c_0000 + xbar_types_pkg::addr_t'(it) * 32'h1000);
      start_item(rb);
      finish_item(rb);
    end
  endtask
endclass

class m2_or03_guard_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m2_or03_guard_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)

  function new(string name = "m2_or03_guard_vseq");
    super.new(name);
  endfunction

  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork
        begin
          slvport_or03_seq s;
          s = slvport_or03_seq::type_id::create($sformatf("or03_seq_%0d", ii));
          s.slv_port_idx = ii;
          s.start(p_sequencer.slv_sqr[ii]);
        end
      join_none
    end
    wait fork;
  endtask
endclass

// ----------------------------------------------------------------------------
// M2-CFG01 — address-table / default-port runtime reconfiguration (testplan.md
// M2-CFG01, uvm_env.md C5.1, spec §3.1/§3.2/§3.3/§3.4). Every leg is single-
// outstanding-per-port (the blocking driver serialises each item to its own
// B/R), so batch 1 fully drains before the reconfiguration and batch 2 fully
// follows it — and the same-ID cross-port stall machinery (C3.2/scoreboard
// C5.1) is never triggered here (no two same-bucket requests outstanding on
// one port). The scoreboard decodes each item against the table version live
// at its own AW/AR accept instant (scoreboard_refmodel C1.5), so no address
// choice needs the sequence itself to "know" the routing — it only has to keep
// each batch off a decode-error address for its own live table:
//   batch 1 (baseline V0, default disabled): all rule hits;
//   batch 2 (V1): region-CFG01_MOVED_RULE (moved rule → a different master
//   port than V0 gave for the SAME address, §3.1/§3.2), an unmapped address
//   (routed to the newly enabled default master port, §3.3), and an unchanged
//   region (still routes the same, cross-check the move was surgical).
// ----------------------------------------------------------------------------
class slvport_cfg01_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_cfg01_seq)

  int unsigned slv_port_idx;
  bit          phase_v1; // 0 = batch 1 (V0), 1 = batch 2 (V1)

  function new(string name = "slvport_cfg01_seq");
    super.new(name);
  endfunction

  task automatic send(input bit is_write, input xbar_types_pkg::addr_t addr,
                      input xbar_types_pkg::id_slv_t id, input axi_pkg::len_t len);
    axi_seq_item it;
    it = axi_seq_item::type_id::create(
        $sformatf("cfg01_%0d_%s_%0h", slv_port_idx, is_write ? "w" : "r", addr));
    start_item(it);
    it.is_write = is_write;
    it.addr     = addr;
    it.len      = len;
    it.id       = id;
    if (is_write) begin
      it.wdata.delete();
      it.wstrb.delete();
      for (int unsigned b = 0; b <= len; b++) begin
        it.wdata.push_back({$urandom(), $urandom()});
        it.wstrb.push_back('1);
      end
    end
    finish_item(it);
  endtask

  task body();
    if (!phase_v1) begin
      // batch 1 — baseline table V0 (all rule hits, default port disabled)
      send(1'b1, 32'h0000_2000,
           xbar_types_pkg::id_slv_t'(slv_port_idx),      axi_pkg::len_t'(1)); // region0 -> mst0
      send(1'b0, 32'h3000_1000,
           xbar_types_pkg::id_slv_t'(slv_port_idx + 8),  axi_pkg::len_t'(3)); // region3 -> mst3
    end else begin
      // batch 2 — reconfigured table V1
      send(1'b1, 32'h0000_2000,
           xbar_types_pkg::id_slv_t'(slv_port_idx),      axi_pkg::len_t'(1)); // region0 -> mst5 (moved rule, §3.1/§3.2)
      send(1'b0, 32'h9000_0000 + xbar_types_pkg::addr_t'(slv_port_idx) * 32'h100,
           xbar_types_pkg::id_slv_t'(slv_port_idx + 8),  axi_pkg::len_t'(3)); // unmapped -> default mst = port (§3.3)
      send(1'b1, 32'h3000_1000,
           xbar_types_pkg::id_slv_t'(slv_port_idx + 16), axi_pkg::len_t'(1)); // region3 -> mst3 (unchanged)
    end
  endtask
endclass

class m2_cfg01_reconfig_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m2_cfg01_reconfig_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)

  virtual xbar_cfg_if cfg_vif; // set by the test (config_db handle)

  function new(string name = "m2_cfg01_reconfig_vseq");
    super.new(name);
  endfunction

  task automatic run_batch(input bit phase_v1);
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork
        begin
          slvport_cfg01_seq s;
          s = slvport_cfg01_seq::type_id::create(
              $sformatf("cfg01_seq_%0d_%0d", phase_v1, ii));
          s.slv_port_idx = ii;
          s.phase_v1     = phase_v1;
          s.start(p_sequencer.slv_sqr[ii]);
        end
      join_none
    end
    wait fork;
  endtask

  // Apply the single runtime reconfiguration (spec §3.4). Only inside an
  // all-ports-AW/AR-idle window (uvm_env.md C5.1): batch 1 fully drained leaves
  // every port idle, and we still gate on the live all_ax_idle before driving
  // so the change provably never overlaps any port's AW/AR valid — the C3.1 SVA
  // watches that independently. A few settle cycles keep batch 2's first AW/AR
  // off the change cycle.
  task automatic do_reconfig();
    do @(posedge cfg_vif.clk_i); while (!cfg_vif.all_ax_idle);
    cfg_vif.addr_map            <= xbar_types_pkg::ADDR_MAP_V1;
    cfg_vif.en_default_mst_port <= xbar_types_pkg::EN_DEFAULT_V1;
    cfg_vif.default_mst_port    <= xbar_types_pkg::DEFAULT_MST_V1;
    repeat (3) @(posedge cfg_vif.clk_i);
  endtask

  task body();
    if (cfg_vif == null)
      `uvm_fatal("NOCFGVIF", "m2_cfg01_reconfig_vseq: cfg_vif not set")
    run_batch(1'b0); // batch 1 — routed by V0
    do_reconfig();   // one runtime reconfiguration in the idle window
    run_batch(1'b1); // batch 2 — routed by V1
  endtask
endclass
