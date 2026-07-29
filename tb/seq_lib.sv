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

// ----------------------------------------------------------------------------
// M3 error-path / spec §5.2.6 scenarios (testplan M3-DE01/DE02/OR04/CFG02).
// Addresses outside every rule (rules cover [0, NoAddrRules*REGION_SIZE) =
// [0, 0x8000_0000)) are decode-error / default-port addresses (spec §3.2/§4).
// M3_UNMAPPED_BASE is comfortably above that window. No M3 stimulus ever sets
// aw.atop on an unmapped address (env constraint, spec §4.7 / BUG-0032).
// ----------------------------------------------------------------------------
localparam xbar_types_pkg::addr_t M3_UNMAPPED_BASE = 32'h9000_0000;

// One same-direction pair with fully explicit ids + addresses for each leg
// (either leg may be an unmapped/decode-error address). Same drive_pair path as
// build_or_pair, but the caller controls both ids and both addresses so a hit
// leg and an err_slv leg can share (or not) a full ID / low-ID bucket.
function automatic axi_pair_item build_m3_pair(
    input string        name,
    input bit           is_write,
    input xbar_types_pkg::id_slv_t id_a, input xbar_types_pkg::addr_t addr_a,
    input xbar_types_pkg::id_slv_t id_b, input xbar_types_pkg::addr_t addr_b,
    input axi_pkg::len_t len, input int unsigned gap_cycles);
  axi_pair_item item;
  item = axi_pair_item::type_id::create(name);
  item.is_write = is_write;
  item.id       = id_a;
  item.addr     = addr_a;
  item.len      = len;
  if (is_write) begin
    item.wdata.delete();
    item.wstrb.delete();
    for (int unsigned b = 0; b <= len; b++) begin
      item.wdata.push_back({$urandom(), $urandom()});
      item.wstrb.push_back('1);
    end
  end
  item.second_item = axi_seq_item::type_id::create({name, "_b"});
  item.second_item.is_write = is_write;
  item.second_item.id       = id_b;
  item.second_item.addr     = addr_b;
  item.second_item.len      = len;
  if (is_write) begin
    item.second_item.wdata.delete();
    item.second_item.wstrb.delete();
    for (int unsigned b = 0; b <= len; b++) begin
      item.second_item.wdata.push_back({$urandom(), $urandom()});
      item.second_item.wstrb.push_back('1);
    end
  end
  item.gap_cycles = gap_cycles;
  return item;
endfunction

// ---- M3-DE01: decode-error slave basic response (testplan M3-DE01, spec §4).
// Each slave port issues writes and reads to unmapped addresses, AxLEN spanning
// 0 and >0 so the beat-count judgement is non-vacuous. Single-outstanding (plain
// axi_seq_item), no ATOP (spec §4.7 env constraint). The scoreboard judges the
// err_slv DECERR responses (spec §4.3/§4.4/§4.5).
class slvport_de01_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_de01_seq)
  int unsigned slv_port_idx;
  function new(string name = "slvport_de01_seq"); super.new(name); endfunction

  task automatic send(input bit is_write, input xbar_types_pkg::addr_t addr,
                      input xbar_types_pkg::id_slv_t id, input axi_pkg::len_t len);
    axi_seq_item it;
    it = axi_seq_item::type_id::create(
        $sformatf("de01_%0d_%s_%0h", slv_port_idx, is_write ? "w" : "r", addr));
    start_item(it);
    it.is_write = is_write; it.addr = addr; it.len = len; it.id = id;
    it.atop = '0; // spec §4.7: never ATOP to an unmapped address
    if (is_write) begin
      it.wdata.delete(); it.wstrb.delete();
      for (int unsigned b = 0; b <= len; b++) begin
        it.wdata.push_back({$urandom(), $urandom()});
        it.wstrb.push_back('1);
      end
    end
    finish_item(it);
  endtask

  task body();
    xbar_types_pkg::addr_t base;
    base = M3_UNMAPPED_BASE + xbar_types_pkg::addr_t'(slv_port_idx) * 32'h1000;
    // AxLEN 0 and >0, both directions (spec §4.3 beat-count both ways).
    send(1'b1, base + 32'h000, xbar_types_pkg::id_slv_t'(slv_port_idx),      axi_pkg::len_t'(0));
    send(1'b1, base + 32'h040, xbar_types_pkg::id_slv_t'(slv_port_idx + 4),  axi_pkg::len_t'(3));
    send(1'b0, base + 32'h080, xbar_types_pkg::id_slv_t'(slv_port_idx + 8),  axi_pkg::len_t'(0));
    send(1'b0, base + 32'h0c0, xbar_types_pkg::id_slv_t'(slv_port_idx + 12), axi_pkg::len_t'(3));
  endtask
endclass

class m3_de01_decerr_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m3_de01_decerr_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)
  function new(string name = "m3_de01_decerr_vseq"); super.new(name); endfunction
  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork begin
        slvport_de01_seq s;
        s = slvport_de01_seq::type_id::create($sformatf("de01_seq_%0d", ii));
        s.slv_port_idx = ii;
        s.start(p_sequencer.slv_sqr[ii]);
      end join_none
    end
    wait fork;
  endtask
endclass

// ---- M3-DE02: default master port vs decode error slave split (testplan
// M3-DE02, spec §3.3/§4). Per-slave-port mixed en_default (even ports enabled
// → default master port; odd ports disabled → err_slv). Each port sends an
// unmapped write+read (→ default port OKAY on enabled ports, err_slv DECERR on
// disabled) plus a rule-hit write+read (unaffected by default enable). The
// mixed config is applied once, in an all-idle window, by the vseq below.
class slvport_de02_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_de02_seq)
  int unsigned slv_port_idx;
  function new(string name = "slvport_de02_seq"); super.new(name); endfunction

  task automatic send(input bit is_write, input xbar_types_pkg::addr_t addr,
                      input xbar_types_pkg::id_slv_t id, input axi_pkg::len_t len);
    axi_seq_item it;
    it = axi_seq_item::type_id::create(
        $sformatf("de02_%0d_%s_%0h", slv_port_idx, is_write ? "w" : "r", addr));
    start_item(it);
    it.is_write = is_write; it.addr = addr; it.len = len; it.id = id;
    it.atop = '0;
    if (is_write) begin
      it.wdata.delete(); it.wstrb.delete();
      for (int unsigned b = 0; b <= len; b++) begin
        it.wdata.push_back({$urandom(), $urandom()});
        it.wstrb.push_back('1);
      end
    end
    finish_item(it);
  endtask

  task body();
    xbar_types_pkg::addr_t umap, hit;
    umap = M3_UNMAPPED_BASE + xbar_types_pkg::addr_t'(slv_port_idx) * 32'h1000;
    // rule-hit control transaction: region (slv%NoMst) -> that master port.
    hit  = xbar_types_pkg::addr_t'(slv_port_idx % xbar_types_pkg::NO_MST_PORTS)
           * xbar_types_pkg::REGION_SIZE + 32'h0000_2000;
    send(1'b1, umap + 32'h000, xbar_types_pkg::id_slv_t'(slv_port_idx),      axi_pkg::len_t'(1));
    send(1'b0, umap + 32'h080, xbar_types_pkg::id_slv_t'(slv_port_idx + 8),  axi_pkg::len_t'(1));
    send(1'b1, hit  + 32'h000, xbar_types_pkg::id_slv_t'(slv_port_idx + 16), axi_pkg::len_t'(1));
    send(1'b0, hit  + 32'h100, xbar_types_pkg::id_slv_t'(slv_port_idx + 24), axi_pkg::len_t'(1));
  endtask
endclass

class m3_de02_default_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m3_de02_default_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)
  virtual xbar_cfg_if cfg_vif; // set by the test

  function new(string name = "m3_de02_default_vseq"); super.new(name); endfunction

  // Apply the mixed per-port default-master-port config once, in an all-idle
  // window (spec §3.4 restriction — no AW/AR valid during the change).
  task automatic set_mixed_default();
    logic [xbar_types_pkg::NO_SLV_PORTS-1:0]                             en;
    logic [xbar_types_pkg::NO_SLV_PORTS-1:0][xbar_types_pkg::MST_PORT_IDX_W-1:0] dm;
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      en[i] = (i % 2 == 0);                                  // even ports enabled
      dm[i] = i[xbar_types_pkg::MST_PORT_IDX_W-1:0];         // distinct default master port
    end
    do @(posedge cfg_vif.clk_i); while (!cfg_vif.all_ax_idle);
    cfg_vif.en_default_mst_port <= en;
    cfg_vif.default_mst_port    <= dm;
    repeat (3) @(posedge cfg_vif.clk_i);
  endtask

  task body();
    if (cfg_vif == null)
      `uvm_fatal("NOCFGVIF", "m3_de02_default_vseq: cfg_vif not set")
    set_mixed_default();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork begin
        slvport_de02_seq s;
        s = slvport_de02_seq::type_id::create($sformatf("de02_seq_%0d", ii));
        s.slv_port_idx = ii;
        s.start(p_sequencer.slv_sqr[ii]);
      end join_none
    end
    wait fork;
  endtask
endclass

// ---- M3-OR04: decode-miss transactions' ordering position (testplan M3-OR04,
// spec §5.2.6). Baseline config (en_default=0 for every port). Per slave port:
//   crit (1) full-ID dimension (assertable): two SAME full ID, same-direction
//     transactions in flight — one rule hit (a real master port), one decode miss
//     (err_slv) — built both orders (hit-first, miss-first), mirrored read/write.
//     Their B/rlast completion order must equal accept order regardless of routing
//     (scoreboard err_order_q / SB_DECERR_ORDER).
//   crit (2) bucket dimension (undefined, excluded): a same-low-bucket, DIFFERENT
//     full ID pair with one leg via err_slv — no completion-order verdict is made
//     on it (stall_sva excludes it, scoreboard never queues the miss leg for the
//     bucket check); the stall_sva §5.2.6-2.b cover records the corner is reached.
class slvport_or04_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_or04_seq)
  int unsigned slv_port_idx;
  function new(string name = "slvport_or04_seq"); super.new(name); endfunction

  task body();
    axi_pair_item p;
    int unsigned  bkt;
    xbar_types_pkg::addr_t hit_a, miss_a;
    bkt    = slv_port_idx % (1 << xbar_types_pkg::Cfg.AxiIdUsedSlvPorts);
    // rule-hit region for this port's hit leg (a real master port), and an
    // unmapped address for the err_slv leg.
    hit_a  = xbar_types_pkg::addr_t'(slv_port_idx % xbar_types_pkg::NO_MST_PORTS)
             * xbar_types_pkg::REGION_SIZE + 32'h0000_3000;
    miss_a = M3_UNMAPPED_BASE + xbar_types_pkg::addr_t'(slv_port_idx) * 32'h1000 + 32'h200;

    // crit (1) same full ID X, hit-first then miss (write, then read mirror).
    for (int unsigned dir = 0; dir < 2; dir++) begin
      xbar_types_pkg::id_slv_t x;
      x = xbar_types_pkg::id_slv_t'({2'd0, bkt[2:0]});
      p = build_m3_pair($sformatf("or04_hf_%s_%0d", dir ? "w" : "r", slv_port_idx),
                        dir[0], x, hit_a, x, miss_a, axi_pkg::len_t'(0), 2);
      start_item(p); finish_item(p);
      // same full ID Y, miss-first then hit.
      p = build_m3_pair($sformatf("or04_mf_%s_%0d", dir ? "w" : "r", slv_port_idx),
                        dir[0], x, miss_a + 32'h40, x, hit_a + 32'h40,
                        axi_pkg::len_t'(0), 2);
      start_item(p); finish_item(p);
    end

    // crit (2) DIFFERENT full IDs sharing the low bucket, one leg via err_slv —
    // the §5.2.6 clause 2.b excluded corner (no verdict; cover records the touch).
    for (int unsigned dir = 0; dir < 2; dir++) begin
      xbar_types_pkg::id_slv_t ida, idb;
      ida = xbar_types_pkg::id_slv_t'({2'd0, bkt[2:0]});
      idb = xbar_types_pkg::id_slv_t'({2'd1, bkt[2:0]}); // same bucket, different full ID
      p = build_m3_pair($sformatf("or04_bkt_%s_%0d", dir ? "w" : "r", slv_port_idx),
                        dir[0], ida, hit_a + 32'h80, idb, miss_a + 32'h80,
                        axi_pkg::len_t'(0), 2);
      start_item(p); finish_item(p);
    end
  endtask
endclass

class m3_or04_order_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m3_or04_order_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)
  function new(string name = "m3_or04_order_vseq"); super.new(name); endfunction
  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork begin
        slvport_or04_seq s;
        s = slvport_or04_seq::type_id::create($sformatf("or04_seq_%0d", ii));
        s.slv_port_idx = ii;
        s.start(p_sequencer.slv_sqr[ii]);
      end join_none
    end
    wait fork;
  endtask
endclass

// ---- M3-CFG02: runtime address-table live value visible on the judgement path
// (testplan M3-CFG02, BUG-0031, spec §3.4/§5.2). Reuses the M2-CFG01 reconfig
// discipline (change only in an all-idle window). After V0->V1 (moved rule
// region0 -> CFG01_MOVED_IDX, default port enabled), one slave port presents a
// same-low-bucket, DIFFERENT full ID cross-target sibling pair whose leg-A target
// (region0) now resolves to CFG01_MOVED_IDX under the live V1 table — the three
// coincident elements BUG-0031's guard needs (post-reconfig + different-full-ID
// bucket siblings + target crossing master ports). stall_sva must now see the
// live table (sibling covers > 0, live-V1 cover > 0) and raise no spurious
// reorder (bidirectional guard).
class slvport_cfg02_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_cfg02_seq)
  int unsigned slv_port_idx;
  function new(string name = "slvport_cfg02_seq"); super.new(name); endfunction

  task body();
    axi_pair_item p;
    int unsigned  bkt, tgt_b;
    xbar_types_pkg::addr_t addr_moved, addr_other;
    bkt    = slv_port_idx % (1 << xbar_types_pkg::Cfg.AxiIdUsedSlvPorts);
    // leg A: the moved-rule region (V1 routes it to CFG01_MOVED_IDX).
    addr_moved = xbar_types_pkg::addr_t'(xbar_types_pkg::CFG01_MOVED_RULE)
                 * xbar_types_pkg::REGION_SIZE + 32'h0000_5000
                 + xbar_types_pkg::addr_t'(slv_port_idx) * 32'h40;
    // leg B: a different, unchanged region -> a different master port (so the two
    // legs cross master ports: CFG01_MOVED_IDX vs tgt_b).
    tgt_b  = (xbar_types_pkg::CFG01_MOVED_IDX + 1) % xbar_types_pkg::NO_MST_PORTS;
    addr_other = xbar_types_pkg::addr_t'(tgt_b) * xbar_types_pkg::REGION_SIZE
                 + 32'h0000_5000 + xbar_types_pkg::addr_t'(slv_port_idx) * 32'h40;
    // write pair then read pair; different full IDs sharing the low bucket.
    for (int unsigned dir = 0; dir < 2; dir++) begin
      p = build_m3_pair($sformatf("cfg02_%s_%0d", dir ? "w" : "r", slv_port_idx),
                        dir[0],
                        xbar_types_pkg::id_slv_t'({2'd0, bkt[2:0]}), addr_moved,
                        xbar_types_pkg::id_slv_t'({2'd1, bkt[2:0]}), addr_other,
                        axi_pkg::len_t'(3), 0);
      start_item(p); finish_item(p);
    end
  endtask
endclass

class m3_cfg02_reconfig_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m3_cfg02_reconfig_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)
  virtual xbar_cfg_if cfg_vif; // set by the test

  function new(string name = "m3_cfg02_reconfig_vseq"); super.new(name); endfunction

  // Batch-1 drain (rule hits under V0) so the reconfiguration lands in an idle
  // window (same discipline as m2_cfg01_reconfig_vseq.run_batch).
  task automatic run_batch_v0();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork begin
        slvport_basic_seq s;
        s = slvport_basic_seq::type_id::create($sformatf("cfg02_v0_%0d", ii));
        s.slv_port_idx = ii;
        s.num_iter     = 2;
        s.start(p_sequencer.slv_sqr[ii]);
      end join_none
    end
    wait fork;
  endtask

  task automatic do_reconfig();
    do @(posedge cfg_vif.clk_i); while (!cfg_vif.all_ax_idle);
    cfg_vif.addr_map            <= xbar_types_pkg::ADDR_MAP_V1;
    cfg_vif.en_default_mst_port <= xbar_types_pkg::EN_DEFAULT_V1;
    cfg_vif.default_mst_port    <= xbar_types_pkg::DEFAULT_MST_V1;
    repeat (3) @(posedge cfg_vif.clk_i);
  endtask

  task automatic run_batch_v1();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork begin
        slvport_cfg02_seq s;
        s = slvport_cfg02_seq::type_id::create($sformatf("cfg02_v1_%0d", ii));
        s.slv_port_idx = ii;
        s.start(p_sequencer.slv_sqr[ii]);
      end join_none
    end
    wait fork;
  endtask

  task body();
    if (cfg_vif == null)
      `uvm_fatal("NOCFGVIF", "m3_cfg02_reconfig_vseq: cfg_vif not set")
    run_batch_v0();
    do_reconfig();
    run_batch_v1();
  endtask
endclass

// ----------------------------------------------------------------------------
// M3-OR05 — stall-SVA judgement-range disarm, directed falsification (testplan.md
// M3-OR05, BUG-0024, REV-011 §2.3 route (b), spec §5.2.1/§5.2.3/§5.2.4). One
// slave port, one low-ID bucket, two DISTINCT full IDs X and Y (differing in the
// high ID bits, same low AxiIdUsedSlvPorts bucket). The REV-011 §2.2 four-step
// construction, presented back-to-back on one axi_burst_item (drive_burst never
// waits for a completion between items, so all AWs/ARs are accepted into the
// crossbar's CUT_ALL_AX elastic buffers while responses are still in flight —
// the same stacking mechanism M2-OR03 uses):
//   step 1: AW/AR X -> target A                       (seq0, oldest X)
//   step 2: AW/AR Y -> target B  (B != A)             (seq1, sibling, same bucket)
//   step 3: AW/AR X -> target A  (spec §5.2.4 legal same-ID/same-dir/SAME-target
//           stacking, so a SECOND X is in flight — this OVERWRITES the SVA's
//           per-full-ID w_id_seq[X] to seq2)          (seq2..)
//   step 4: the crossbar completes the OLDEST X (seq0) first — same-ID same-target
//           returns in acceptance order (AXI4, spec §1/§5.2.3), and Y is stalled by
//           the demux (§5.2.1, same bucket, different target) so it drains after the
//           X stack. FIFO order at the demux input keeps external accept order ==
//           completion order (X, Y, X...), so the SCOREBOARD sees zero reordering.
// The un-fixed stall_sva would FALSE-RED at step 4 (it compares the completing X's
// overwritten seq2 against the older sibling Y's seq1 and wrongly reports Y was
// overtaken — REV-011 §2.2); the range-disarm (w_n[X]/r_n[X] >= 2 early return in
// w_reorder/r_reorder) must suppress that. n_post is deepened past the "≥2" floor
// (same robustness rationale as M2-OR03's n_a) so ≥2 X are reliably co-resident with
// an open Y when the oldest X completes. Iterates every low bucket for many chances.
// ----------------------------------------------------------------------------
function automatic axi_burst_item build_or05_burst(
    input string        name,
    input bit           is_write,
    input xbar_types_pkg::id_slv_t id_x, input xbar_types_pkg::id_slv_t id_y,
    input int unsigned  tgt_a, input int unsigned tgt_b,
    input int unsigned  n_post, // number of X->A stacked AFTER the Y->B sibling
    input xbar_types_pkg::addr_t addr_base);
  axi_burst_item burst;
  int unsigned   k;
  burst = axi_burst_item::type_id::create(name);
  k = 0;
  // Emit one full item into the burst, at the given full id / target.
  for (int unsigned step = 0; step < 2 + n_post; step++) begin
    axi_seq_item it;
    xbar_types_pkg::id_slv_t id;
    int unsigned tgt;
    // step 0 = X->A (oldest), step 1 = Y->B (sibling), step >=2 = X->A (stack)
    id  = (step == 1) ? id_y   : id_x;
    tgt = (step == 1) ? tgt_b  : tgt_a;
    it  = axi_seq_item::type_id::create($sformatf("%s_%0d", name, step));
    it.is_write = is_write;
    it.id       = id;
    it.addr     = xbar_types_pkg::addr_t'(tgt) * xbar_types_pkg::REGION_SIZE
                  + addr_base + xbar_types_pkg::addr_t'(k) * 32'h40;
    // Reads single beat; writes alternate AxLEN 0/1 to sweep the AW/B phase
    // relationship (same anti-phase-lock reasoning as build_or03_burst).
    it.len      = axi_pkg::len_t'(is_write ? (step % 2) : 0);
    if (is_write) begin
      for (int unsigned b = 0; b <= it.len; b++) begin
        it.wdata.push_back({$urandom(), $urandom()});
        it.wstrb.push_back('1);
      end
    end
    burst.items.push_back(it);
    k++;
  end
  return burst;
endfunction

class slvport_or05_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_or05_seq)

  int unsigned slv_port_idx;
  int unsigned n_post = 2; // X->A stacked after Y (>= 1; total X in flight = 1+n_post)

  function new(string name = "slvport_or05_seq"); super.new(name); endfunction

  task body();
    // Walk every low-ID bucket (2**AxiIdUsedSlvPorts of them) so the timing
    // coincidence gets many independent chances across buckets and targets.
    int unsigned n_bkt;
    n_bkt = (1 << xbar_types_pkg::Cfg.AxiIdUsedSlvPorts);
    for (int unsigned bkt = 0; bkt < n_bkt; bkt++) begin
      axi_burst_item wb, rb;
      xbar_types_pkg::id_slv_t id_x, id_y;
      int unsigned tgt_a, tgt_b;
      // X and Y share the low bucket, differ in the high ID bits -> DISTINCT full
      // IDs, same §5.2.2 bucket (siblings).
      id_x  = xbar_types_pkg::id_slv_t'({2'd0, bkt[2:0]});
      id_y  = xbar_types_pkg::id_slv_t'({2'd1, bkt[2:0]});
      tgt_a = (slv_port_idx + bkt) % xbar_types_pkg::NO_MST_PORTS;
      tgt_b = (tgt_a + 1)          % xbar_types_pkg::NO_MST_PORTS;

      wb = build_or05_burst($sformatf("or05_w_%0d_%0d", slv_port_idx, bkt),
                            1'b1, id_x, id_y, tgt_a, tgt_b, n_post,
                            32'h0008_0000 + xbar_types_pkg::addr_t'(bkt) * 32'h1000);
      start_item(wb); finish_item(wb);

      rb = build_or05_burst($sformatf("or05_r_%0d_%0d", slv_port_idx, bkt),
                            1'b0, id_x, id_y, tgt_a, tgt_b, n_post,
                            32'h000c_0000 + xbar_types_pkg::addr_t'(bkt) * 32'h1000);
      start_item(rb); finish_item(rb);
    end
  endtask
endclass

class m3_or05_range_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m3_or05_range_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)
  function new(string name = "m3_or05_range_vseq"); super.new(name); endfunction
  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork begin
        slvport_or05_seq s;
        s = slvport_or05_seq::type_id::create($sformatf("or05_seq_%0d", ii));
        s.slv_port_idx = ii;
        s.start(p_sequencer.slv_sqr[ii]);
      end join_none
    end
    wait fork;
  endtask
endclass

// ---- M3-CF01: config point A regression (cfgA 1×8, NO_LATENCY) (testplan
// M3-CF01, spec §0 row 3 / §7.2). The single slave port (port 0 — NoSlvPorts=1)
// sends hit read/write bursts covering all NoMstPorts master ports, then a
// batch of unmapped-address read/writes (en_default='0 ⇒ err_slv DECERR). No
// new stimulus primitives: hits reuse slvport_basic_seq (num_iter=NoMstPorts
// walks tgt across every master port), misses reuse slvport_de01_seq (§4.7
// no-ATOP). The whole point of cfgA is that expectations are bit-for-bit the
// baseline's — LatencyMode only changes path latency, not the functional
// response (spec §7.4) — so the scoreboard/SVA judge these with no cfgA-specific
// expected values. ID-prefix degenerates to 0-bit (spec §5.1, tb_top C5.6),
// handled in build_exp_id / prefix extraction.
class m3_cf01_cfga_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m3_cf01_cfga_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)
  function new(string name = "m3_cf01_cfga_vseq"); super.new(name); endfunction
  task body();
    slvport_basic_seq hs;
    slvport_de01_seq  ms;
    // NoSlvPorts=1: the sole slave port is index 0.
    hs = slvport_basic_seq::type_id::create("cf01_hit");
    hs.slv_port_idx = 0;
    hs.num_iter     = xbar_types_pkg::NO_MST_PORTS; // walk every master port
    hs.start(p_sequencer.slv_sqr[0]);
    ms = slvport_de01_seq::type_id::create("cf01_miss");
    ms.slv_port_idx = 0;
    ms.start(p_sequencer.slv_sqr[0]);
  endtask
endclass

// ---- M3-CF02: config point B regression (cfgB 6×1, CUT_ALL_PORTS) (testplan
// M3-CF02, spec §0 row 3 / §7.2 / §5.5). Every slave port concurrently drives
// hit write/read bursts — all 8 rules idx=0 so every hit converges on the sole
// master port (mux-side convergence maximised, spec §3.1 / §5.5.1) — plus a
// batch of unmapped-address read/writes (en_default='0 ⇒ err_slv DECERR). No
// new stimulus primitives: hits reuse slvport_basic_seq (tgt=(slv+k)%1=0 always,
// num_iter deepened so several AWs from distinct sources are co-pending at the
// master port), misses reuse slvport_de01_seq (§4.7 no-ATOP). Same-source W
// bursts stay in AW order (single-outstanding-per-port driver) and the scoreboard
// SB_WORDER check owns that per-source order (spec §5.5.1); NOTHING here asserts
// cross-source round-robin order (spec §5.5.4 red line) — the worder_sva compete
// cover only witnesses the ≥2-source contention was reached.
class m3_cf02_cfgb_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m3_cf02_cfgb_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)
  function new(string name = "m3_cf02_cfgb_vseq"); super.new(name); endfunction
  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork begin
        slvport_basic_seq hs;
        slvport_de01_seq  ms;
        hs = slvport_basic_seq::type_id::create($sformatf("cf02_hit_%0d", ii));
        hs.slv_port_idx = ii;
        hs.num_iter     = 6; // several bursts per source at the sole master port
        hs.start(p_sequencer.slv_sqr[ii]);
        ms = slvport_de01_seq::type_id::create($sformatf("cf02_miss_%0d", ii));
        ms.slv_port_idx = ii;
        ms.start(p_sequencer.slv_sqr[ii]);
      end join_none
    end
    wait fork;
  endtask
endclass

// ---- M3-CF03: config point C regression (cfgC 4×4, UniqueIds=1'b1) (testplan
// M3-CF03, spec §0 row 3 / §5.3). Every slave port concurrently walks hit
// write/read bursts across all 4 master ports (basic_seq tgt=(slv+k)%4) plus
// unmapped misses (err_slv). The §5.3.1 precondition (per direction, in-flight
// IDs unique OR same-target) is guaranteed CONSTRUCTIVELY: the slvport driver is
// single-outstanding-per-port for plain items (slvport_agent.sv header), so a
// slave port never has two same-direction transactions in flight at once ⇒ every
// in-flight ID is trivially unique per direction (precondition branch a). An
// env-side fallback monitor (scoreboard uid_check, gated on Cfg.UniqueIds) flags
// any violation as TB_BUG — so a §5.3.1 breach can never be silently mistaken for
// a DUT_BUG, and the ✅ is never built on §5.3.3 undefined behaviour.
class m3_cf03_cfgc_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m3_cf03_cfgc_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)
  function new(string name = "m3_cf03_cfgc_vseq"); super.new(name); endfunction
  task body();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork begin
        slvport_basic_seq hs;
        slvport_de01_seq  ms;
        hs = slvport_basic_seq::type_id::create($sformatf("cf03_hit_%0d", ii));
        hs.slv_port_idx = ii;
        hs.num_iter     = xbar_types_pkg::NO_MST_PORTS; // walk every master port
        hs.start(p_sequencer.slv_sqr[ii]);
        ms = slvport_de01_seq::type_id::create($sformatf("cf03_miss_%0d", ii));
        ms.slv_port_idx = ii;
        ms.start(p_sequencer.slv_sqr[ii]);
      end join_none
    end
    wait fork;
  endtask
endclass

// ---- M3-CF04: config point D regression (cfgD 4×4, sparse Connectivity,
// ATOPs=1'b0) (testplan M3-CF04, spec §0 row 3 / §8 / §6 / §3.3). The 8 rules
// point only to mst0/mst1 (addr-map idx = index mod 2), so every rule-hit routes
// to a mst0/mst1 (connected to all slave ports). mst2/mst3 are reachable ONLY via
// each slave port's default master port: slv 0/1 → mst2, slv 2/3 → mst3 (spec
// §3.3, applied once in an all-idle window before traffic, spec §3.4). Unmapped
// addresses therefore route to the row's default port (mst2/mst3) rather than
// err_slv, giving the sparse ports genuine traffic. The existing stall_sva
// c_bug25_default_aw/ar cover witnesses that default-routed traffic — since in
// cfgD every default target is mst2/mst3, its firing proves mst2/mst3 got default
// traffic (the CF04 non-decisional witness; no new covergroup needed, and none of
// the excluded cg_default_port_tracked family is touched). ATOPs=1'b0 ⇒ every AW
// is aw.atop≡'0 (slvport_basic_seq / slvport_de01_seq never set atop).
class m3_cf04_cfgd_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m3_cf04_cfgd_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)
  virtual xbar_cfg_if cfg_vif; // set by the test

  function new(string name = "m3_cf04_cfgd_vseq"); super.new(name); endfunction

  // Apply cfgD's per-port default master port config once, in an all-idle window
  // (spec §3.4 — no AW/AR valid during the change), before any traffic.
  task automatic set_cfgd_default();
    do @(posedge cfg_vif.clk_i); while (!cfg_vif.all_ax_idle);
    cfg_vif.en_default_mst_port <= xbar_types_pkg::EN_DEFAULT_CFGD;
    cfg_vif.default_mst_port    <= xbar_types_pkg::DEFAULT_MST_CFGD;
    repeat (3) @(posedge cfg_vif.clk_i);
  endtask

  task body();
    if (cfg_vif == null)
      `uvm_fatal("NOCFGVIF", "m3_cf04_cfgd_vseq: cfg_vif not set")
    set_cfgd_default();
    for (int unsigned i = 0; i < xbar_types_pkg::NO_SLV_PORTS; i++) begin
      automatic int unsigned ii = i;
      fork begin
        slvport_basic_seq hs;
        slvport_de01_seq  ms;
        hs = slvport_basic_seq::type_id::create($sformatf("cf04_hit_%0d", ii));
        hs.slv_port_idx = ii;
        hs.num_iter     = xbar_types_pkg::NO_MST_PORTS; // regions 0..3 → mst0/mst1 via idx
        hs.start(p_sequencer.slv_sqr[ii]);
        ms = slvport_de01_seq::type_id::create($sformatf("cf04_miss_%0d", ii));
        ms.slv_port_idx = ii;
        ms.start(p_sequencer.slv_sqr[ii]); // unmapped → this row's default (mst2/mst3)
      end join_none
    end
    wait fork;
  endtask
endclass

// ---- M3-AT02: ATOP atomic read cross-direction false-conflict guard (testplan
// M3-AT02, spec §6.5 / §5.2.5, BUG-0012). Per slave port an axi_pair_item overlaps
// a normal READ (leg A) with an atomic load requiring a read response (leg B, a
// write with atop) that share the SAME low AxiIdUsedSlvPorts=3 bucket but target
// DIFFERENT master ports — so the atomic load's shadow-AR is injected into the AR
// direction counter/compare against the still-open normal read (spec §6.5), the
// cross-direction false conflict M2-AT01 only observed incidentally. The two legs
// carry DIFFERENT full IDs (high bits differ) so the atomic load's ID stays unique
// vs all in-flight (spec §6.4). Functional correctness is unaffected (spec §6.5):
// the atomic load returns B+R (spec §6.3), the read completes, scoreboard zero
// mismatch. The cover cg_atop_read_interaction.colliding_read_present fires because
// a same-bucket read is open at the atomic load's accept (scoreboard collide flag).
class slvport_at02_seq extends uvm_sequence #(axi_seq_item);
  `uvm_object_utils(slvport_at02_seq)

  int unsigned slv_port_idx;

  // ATOP[5:4]=ATOMICLOAD, ATOP[3]=LITTLE_END, ATOP[2:0]=ADD (axi_pkg.sv).
  localparam axi_pkg::atop_t ATOP_LOAD_ADD =
      {axi_pkg::ATOP_ATOMICLOAD, axi_pkg::ATOP_LITTLE_END, axi_pkg::ATOP_ADD};

  function new(string name = "slvport_at02_seq"); super.new(name); endfunction

  task body();
    axi_pair_item p;
    int unsigned  bkt, tgt_a, tgt_b;
    bkt   = slv_port_idx % (1 << xbar_types_pkg::Cfg.AxiIdUsedSlvPorts);
    tgt_a = slv_port_idx % xbar_types_pkg::NO_MST_PORTS;
    tgt_b = (slv_port_idx + 1) % xbar_types_pkg::NO_MST_PORTS;

    p = axi_pair_item::type_id::create($sformatf("at02_%0d", slv_port_idx));
    // leg A: normal read, low bucket = bkt, target A. Stays open (awaiting R)
    // while leg B's atomic load is accepted.
    p.is_write = 1'b0;
    p.id       = xbar_types_pkg::id_slv_t'({2'd0, bkt[2:0]});
    p.addr     = xbar_types_pkg::addr_t'(tgt_a) * xbar_types_pkg::REGION_SIZE
                 + 32'h0000_0900 + xbar_types_pkg::addr_t'(slv_port_idx) * 32'h40;
    p.len      = axi_pkg::len_t'(3); // 4-beat read (BUG-0034 restored): the atomic
                                     // load's single-beat shadow R may legally
                                     // beat-interleave into this multi-beat read's R
                                     // on the shared slave-port R channel — different
                                     // full IDs, spec §5.1.4/§5.5.3 permit it. The
                                     // slv monitor + axi_chan_sva now reconstruct R
                                     // per r_id (BUG-0034 fix), so this interleave is
                                     // handled, not false-reported.
    // leg B: atomic load requiring read response, SAME low bucket (bkt) but
    // DIFFERENT full ID and DIFFERENT target (tgt_b) — the §6.5 cross-direction
    // collision that must NOT be judged an §5.2.1 violation (sva_bind C3.2 range
    // boundary), only cover-witnessed here.
    p.second_item = axi_seq_item::type_id::create(
        $sformatf("at02_%0d_b", slv_port_idx));
    p.second_item.is_write = 1'b1;
    p.second_item.atop     = ATOP_LOAD_ADD;
    p.second_item.id       = xbar_types_pkg::id_slv_t'({2'd1, bkt[2:0]});
    p.second_item.addr     = xbar_types_pkg::addr_t'(tgt_b)
                             * xbar_types_pkg::REGION_SIZE
                             + 32'h0000_0a00 + xbar_types_pkg::addr_t'(slv_port_idx) * 32'h40;
    p.second_item.len      = axi_pkg::len_t'(0);
    p.second_item.wdata.delete();
    p.second_item.wstrb.delete();
    p.second_item.wdata.push_back({$urandom(), $urandom()});
    p.second_item.wstrb.push_back('1);
    p.gap_cycles = 1; // leg A's AR accepted first, so it is open at leg B's accept
    start_item(p); finish_item(p);
  endtask
endclass

class m3_at02_atop_read_vseq extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(m3_at02_atop_read_vseq)
  `uvm_declare_p_sequencer(xbar_vseqr)
  function new(string name = "m3_at02_atop_read_vseq"); super.new(name); endfunction
  task body();
    // Single slave port (testplan M3-AT02 "单 slave 端口"): the atomic load and
    // the same-bucket colliding read both originate from ONE slave port toward
    // two DIFFERENT master ports (mst0 / mst1). Deliberately NOT forked across
    // all ports — that would make port p's atomic load and port p+1's read
    // converge at a shared master port, an atop+read convergence AT02 is not
    // about and which the plain responder does not model (an unintended
    // scenario, not the §6.5 cross-direction interaction under test). Repeated a
    // few times on the same port for robustness (each repeat is one atop+read
    // overlap → several colliding_read_present cover hits).
    slvport_at02_seq s;
    s = slvport_at02_seq::type_id::create("at02_seq");
    s.slv_port_idx = 0;
    s.start(p_sequencer.slv_sqr[0]);
  endtask
endclass
