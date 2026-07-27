// M1+ UVM env compile list (CLAUDE.md §6 flist 布局). Compile order matters:
// xbar_types_pkg.sv (plain package: Cfg/typedefs/addr-map/predict fn) must
// precede axi_if.sv (interfaces reference those typedefs), which must
// precede tb_pkg.sv (UVM classes hold virtual handles to those interfaces).
// `include-d class files (axi_txn.sv, slvport_agent.sv, mstport_agent.sv,
// scoreboard_refmodel.sv, xbar_env.sv, seq_lib.sv, test_lib.sv, sva_bind.sv)
// are pulled in textually and must NOT be listed separately here.
+incdir+../tb
../tb/xbar_types_pkg.sv
../tb/axi_if.sv
../tb/tb_pkg.sv
../tb/sva/axi_chan_sva.sv
../tb/tb_top.sv
