# Feature matrix

feature → deliverable → testplan scenarios. Delivery/verification are computed live by the scripts, never stored. Every feature maps to ≥1 existing scenario id (ghost references fail docs-check).

| id | milestone | feature | module | scenes |
| --- | --- | --- | --- | --- |
| F-M0-01 | M0 | 仿真基建：vendored DUT + 依赖库在 VCS-2018 下编译/弹性/运行 | (infra) | M0-01 |
| F-M1-01 | M1 | UVM env 骨架：tb_top 单 axi_xbar + 6 slave/8 master 接口 + master/slave agent + env 编译弹起并跑通 baseline smoke | tb_top+uvm_env | M1-01 |
| F-M1-02 | M1 | 地址路由参考模型记分板：地址译码（SPEC-3.1/3.2）+ 目标 master 端口 idx 路由 + 数据完整性（SPEC-1）判决 | scoreboard_refmodel | M1-01 |
| F-M1-03 | M1 | ID 前缀响应路由参考模型：master 端口侧 ID 前缀（SPEC-5.1）与响应回送源 slave 端口正确性 | scoreboard_refmodel | M1-02 |
| F-M1-04 | M1 | 协议/时序 SVA bind 挂接：tb/sva 经 bind 挂到 DUT 每 slave/master 端口，smoke 期间 AXI4 协议基线 passive 零告警 | sva_bind | M1-01, M1-02 |
| F-M2-01 | M2 | 运行时地址表/default port 重配置：仅在全部 slave 端口 AW/AR 均空闲的窗口更改，随后事务按新表路由（SPEC-3.1/3.3/3.4） | uvm_env+scoreboard_refmodel | M2-CFG01 |
| F-M2-02 | M2 | 同 ID（低 `AxiIdUsedSlvPorts` 位）同向跨 master 端口保序 stall：第二笔在第一笔完成前不被接受（SPEC-5.2.1/5.2.2） | uvm_env+scoreboard_refmodel | M2-OR01 |
| F-M2-03 | M2 | 同 ID 同向同目标 master 端口 / 同 ID 异向：不受 §5.2 stall 约束（SPEC-5.2.4） | uvm_env+scoreboard_refmodel | M2-OR02 |
| F-M2-04 | M2 | 事务数上限：每 slave 端口（MaxMstTrans）、每 master 端口每 ID（MaxSlvTrans）在飞事务达上限即暂停接受（SPEC-5.4） | uvm_env+scoreboard_refmodel | M2-TL01, M2-TL02 |
| F-M2-05 | M2 | W 通道次序：≥2 个 slave 端口并发写同一 master 端口时，W burst 按 AW 接受序、不与他源交织（SPEC-5.5.1/5.5.2） | uvm_env+scoreboard_refmodel | M2-WO01 |
| F-M2-06 | M2 | ATOP 原子读：B 与 R 两通道成对返回 + 环境侧 ID 唯一性约束（SPEC-6.3/6.4） | uvm_env+scoreboard_refmodel | M2-AT01 |
| F-M2-07 | M2 | 协议/时序 SVA M2 激活集（design-prompt sva_bind.md C3.1-C3.5）：配置稳定性(C3.1) / 保序 stall(C3.2) / W 次序(C3.3，cover-only、不新增独立断言) / 事务上限(C3.4) / ATOP 成对+ID 唯一(C3.5)，各配一条非判决性 cover property 佐证非空转 | sva_bind | M2-CFG01, M2-OR01, M2-OR02, M2-TL01, M2-TL02, M2-WO01, M2-AT01 |
| F-M2-08 | M2 | functional + assert 功能覆盖采集基建：六类覆盖口径（SPEC-0 行4）中 functional（covergroup）与 assert（cover property）两维度在 M2 场景落地 | functional_coverage | M2-CFG01, M2-OR01, M2-OR02, M2-TL01, M2-TL02, M2-WO01, M2-AT01 |
