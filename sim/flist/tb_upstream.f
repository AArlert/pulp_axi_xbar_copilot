// M0 sanity：上游自带 tb（vendor/axi/test/，v0.39.9）。pkg 先于 tb 编译；
// include 路径由 dut.f 的 +incdir+ 提供（同一次 vcs 调用全局生效）。
../vendor/axi/test/tb_axi_xbar_pkg.sv
../vendor/axi/test/tb_axi_xbar.sv
