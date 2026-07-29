# Milestones

版本号 0.M.P，M 即里程碑号。出口条件由 `make check MILESTONE=<n>` 机器核验
（全场景 ✅ · regress 摘要入证据 · bugs 终态或未到期 ACCEPTED · **KILL 覆盖**）
加 rev 签核记录 `doc/evidence/v0.M.*/signoff-M<n>.md`，二者缺一不可。

> **KILL 覆盖（不变量 5）自 M3 起生效。** M0/M1/M2 在旧 rubric 下已合法签核，
> 按「冻结记录不回改」裁决**不回填** KILL 行，故其条件 4 恒红——已知记账缺口，
> 非实质缺口。M2 的击杀自证取证位置：`doc/evidence/v0.2.5/signoff-M2.md`
> rubric #5（BUG-0027 缺陷放回，见 336 条红后复原）。裁决记于 log [0.3.6]。

## M0 — 基建 + sanity + spec v0 ✅

Exit criteria:

- 仿真基建可跑：flist 分层（vendor/dut/tb_upstream）、`sim/Makefile` 入口、
  VCS-MX O-2018 跑通上游 tb sanity
- `doc/spec.md` v0 由 arch 从许可来源蒸馏，经 rev 评审后 sha256 钉死
- 签核：`doc/evidence/v0.0.2/signoff-M0.md`

## M1 — UVM env + smoke ✅

Exit criteria:

- `tb_top` + UVM env（多 master/slave agent + 地址路由参考模型记分板）可跑
- smoke 场景 ✅，证据入库
- 附带评估 vendor v0.39.9 → v0.39.10 升级（结论记于评审记录）
- 签核：`doc/evidence/v0.1.2/signoff-M1.md`

## M2 — 功能场景 + SVA + 功能覆盖 ✅

Exit criteria:

- 八条功能场景全 ✅，`make regress` 11/11 独立重跑
- 协议/时序 SVA 挂接并非空转（每 assert 配同触发前提的 cover）
- 功能覆盖 covergroup 落地，非空转自证
- 签核：`doc/evidence/v0.2.5/signoff-M2.md`（rubric #7 首次实战）

## M3 — 多配置回归 + 错误路径 🔲

Exit criteria:

- 11 条场景全 ✅（DE01/DE02/OR04/CFG02/OR05/AT02/CF01~04/TL01）
- 多配置维以**声明式覆盖子集**实现（4 配置点 + 基线，每维度每取值至少出现
  一次），**不做 constrained-random**——配置维全是 elaboration 期 localparam，
  且 `run: compile` 产物名固定 `simv`，随机化会让"配置 X 通过"与"基线又跑一遍"
  在日志上同形（裁决见 log [0.3.3]）
- 四条 `ACCEPTED@M3` 债务逐条了结：BUG-0018 / BUG-0024 / BUG-0025+BUG-0031
- **KILL 覆盖：至少一条打 M3 标签的 KILL 行**（不变量 5 首个生效里程碑）
- 签核：`doc/evidence/v0.3.*/signoff-M3.md`

## M4 — 六类覆盖 ≥90% 收敛 🔲

Exit criteria:

- line/toggle/branch/condition/fsm/functional 六类 ≥90%，缺口逐条或修或
  书面豁免（豁免须 rev 签核）
- BUG-0018 的 cross bin 盲区在此之前已解决（否则会以"永远填不满"形式再现）
- 签核后转 v1.0.0
