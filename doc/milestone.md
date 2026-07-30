# Milestones

版本号 0.M.P，M 即里程碑号。出口条件由 `make check MILESTONE=<n>` 机器核验（全场景 ✅ · regress 摘要入证据 · bugs 终态或未到期 ACCEPTED · **KILL 覆盖**）加 rev 签核记录 `doc/evidence/v0.M.*/signoff-M<n>.md`，二者缺一不可。

> **KILL 覆盖（不变量 5）自 M3 起生效。** 
> - M0/M1/M2 在旧 rubric 下已合法签核，按「冻结记录不回改」裁决**不回填** KILL 行，故其条件 4 恒红——已知记账缺口，非实质缺口。
> - M2 的击杀自证取证位置：`doc/evidence/v0.2.5/signoff-M2.md` rubric #5（BUG-0027 缺陷放回，见 336 条红后复原）。裁决记于 log [0.3.6]。

## M0 — 基建 + sanity + spec v0 ✅

Exit criteria:

- [x] 仿真基建可跑：flist 分层（vendor/dut/tb_upstream）、`sim/Makefile` 入口、VCS-MX O-2018 跑通上游 tb sanity
- [x] `doc/spec.md` v0 由 arch 从许可来源蒸馏，经 rev 评审后 sha256 钉死
- [x] 签核：`doc/evidence/v0.0.2/signoff-M0.md`

## M1 — UVM env + smoke ✅

Exit criteria:

- [x] `tb_top` + UVM env（多 master/slave agent + 地址路由参考模型记分板）可跑
- [x] smoke 场景 ✅，证据入库
- [x] 附带评估 vendor v0.39.9 → v0.39.10 升级（结论记于评审记录）
- [x] 签核：`doc/evidence/v0.1.2/signoff-M1.md`

## M2 — 功能场景 + SVA + 功能覆盖 ✅

Exit criteria:

- [x] 八条功能场景全 ✅，`make regress` 11/11 独立重跑
- [x] 协议/时序 SVA 挂接并非空转（每 assert 配同触发前提的 cover）
- [x] 功能覆盖 covergroup 落地，非空转自证
- [x] 签核：`doc/evidence/v0.2.5/signoff-M2.md`（rubric #7 首次实战）

## M3 — 多配置回归 + 错误路径 ✅

Exit criteria:

- [x] 11 条场景全 ✅（DE01/DE02/OR04/CFG02/OR05/AT02/CF01~04/TL01）
- [x] 多配置维以**声明式覆盖子集**实现（4 配置点 + 基线，每维度每取值至少出现一次），**不做 constrained-random**——配置维全是 elaboration 期 localparam，且 `run: compile` 产物名固定 `simv`，随机化会让"配置 X 通过"与"基线又跑一遍"在日志上同形（裁决见 log [0.3.3]）
- [x] 四条 `ACCEPTED@M3` 债务逐条了结：BUG-0018 / BUG-0024 / BUG-0025+BUG-0031
- [x] **KILL 覆盖：至少一条打 M3 标签的 KILL 行**（不变量 5 首个生效里程碑）
- [x] 签核：`doc/evidence/v0.3.20/signoff-M3.md`（C1/C2 兑现记录见该文件 §八，由 0.3.21 closer 卡追加）

## M4 — 六类覆盖 ≥90% 收敛 🔲

Exit criteria:

- [ ] **六类口径以 spec §0 #4 为准**：`line+cond+fsm+tgl+branch+assert`（VCS `-cm` 六个类型关键字，**不含 functional covergroup**——REV-011 §3.3 已裁定"M4 机器判据接不住 covergroup"，本页原"…functional"措辞与 spec 不符，本次订正为与 spec 一致的表述，非新解释）≥90%，DUT 范围含 `axi_xbar` 及其全部强制内部子模块（spec §0 #4 列举），缺口逐条或修或书面豁免（豁免须 rev 签核）
- [ ] functional covergroup（`cg_*`）非空转仍按既有 rubric 第 4/5 条人工抽查把关，不受本页六类机器口径约束
- [ ] BUG-0018 的 cross bin 盲区在此之前已解决（否则会以"永远填不满"形式再现）
- [ ] 签核后转 v1.0.0
