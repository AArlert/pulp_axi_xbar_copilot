# Feature matrix

feature → deliverable → testplan scenarios. Delivery/verification are computed live by the scripts, never stored. Every feature maps to ≥1 existing scenario id (ghost references fail docs-check).

| id | milestone | feature | module | scenes |
| --- | --- | --- | --- | --- |
| F-M0-01 | M0 | 仿真基建：vendored DUT + 依赖库在 VCS-2018 下编译/弹性/运行 | (infra) | M0-01 |
| F-M1-01 | M1 | UVM env 骨架：tb_top 单 axi_xbar + 6 slave/8 master 接口 + master/slave agent + env 编译弹起并跑通 baseline smoke | tb_top+uvm_env | M1-01 |
| F-M1-02 | M1 | 地址路由参考模型记分板：地址译码（SPEC-3.1/3.2）+ 目标 master 端口 idx 路由 + 数据完整性（SPEC-1）判决 | scoreboard_refmodel | M1-01 |
| F-M1-03 | M1 | ID 前缀响应路由参考模型：master 端口侧 ID 前缀（SPEC-5.1）与响应回送源 slave 端口正确性 | scoreboard_refmodel | M1-02 |
| F-M1-04 | M1 | 协议/时序 SVA bind 挂接：tb/sva 经 bind 挂到 DUT 每 slave/master 端口，smoke 期间 AXI4 协议基线 passive 零告警 | sva_bind | M1-01, M1-02 |
