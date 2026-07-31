# Milestones

版本号 0.M.P，M 即里程碑号。出口条件由 `make check MILESTONE=<n>` 机器核验（全场景 ✅ · regress 摘要入证据 · bugs 终态或未到期 ACCEPTED · **KILL 覆盖**）加 rev 签核记录 `doc/evidence/v0.M.*/signoff-M<n>.md`，二者缺一不可。

> **KILL 覆盖（不变量 5）自 M3 起生效。** 
> - M0/M1/M2 在旧 rubric 下已合法签核，按「冻结记录不回改」裁决**不回填** KILL 行，故其条件 4 恒红——已知记账缺口，非实质缺口。
> - M2 的击杀自证取证位置：`doc/evidence/v0.2.5/signoff-M2.md` rubric #5（BUG-0027 缺陷放回，见 336 条红后复原）。裁决记于 log [0.3.6]。

## Abstract

| 里程碑 | 内容 | 场景 | 状态 |
|---|---|---|---|
| M0 | 基建 + upstream sanity + spec v0 | 1/1 | ✅ |
| M1 | UVM env + smoke | 2/2 | ✅ |
| M2 | 功能场景 + SVA + 功能覆盖 | 8/8 | ✅ |
| M3 | 多配置回归 + 错误路径 | 11/11 | ✅ |
| M4 | 六类覆盖 ≥90% | 0 场景行 | 🔲 进行中 |
| M5 | 约束随机 + 多种子回归 + 压力/soak + 覆盖率驱动闭环 | 草稿（提案，rev 未过） | 🔲 提案 |

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
- [ ] **覆盖率缺口的书面豁免须声明种类并登记于 `doc/coverage-waivers.md`**（每条一行，rev 签核；REV-024 裁决）：
  - **Kind-A（结构/环境不可达，永久）**：给可证伪的**不可达性**论证——哪个具体事实被推翻则本豁免作废。例：`axi_atop_filter` FSM（§4 clause 7 环境约束，REV-017）、`test_i` scan（出验证范围）、`axi_err_slv` 恒定错误应答数据位。
  - **Kind-B（方法论受限、延后 M5，临时）**：**仅限**经 rev 逐 bin 判定为"宽数据**载荷**位翻转、纯定向激励不经济可达"的 (模块,类型) 子集（判据见 REV-024 §2.1，须附**逐信号/逐位 toggle 分解**为前置证据）。出口 = **书面记录残余风险 + Kind-B 豁免条目**，**非当下 ≥90%**。可证伪解锁 = **M5 决策点 2（约束随机激励层）落地 + 决策点 5（cov_loop）对这些具体 bin 重新测量；若仍 <90% 方可讨论转 Kind-A 或补定向**；被推翻即作废 = 任一 M5 随机跑使该 bin ≥90%。
  - **控制/使能/模式/窄配置索引/握手背压/地址-rule 多样性/实例级颗粒度/Cond/Branch/Line/Assert 类缺口一律不得记入 Kind-B**——那些是定向可达的"需补场景"，走正常 DV 微闭环。
- [ ] functional covergroup（`cg_*`）非空转仍按既有 rubric 第 4/5 条人工抽查把关，不受本页六类机器口径约束
- [ ] BUG-0018 的 cross bin 盲区在此之前已解决（否则会以"永远填不满"形式再现）

## M5 — 约束随机 + 多种子回归 + 压力/soak + 覆盖率驱动闭环 🔲（提案草稿，rev 未过）

> **性质：arch 提案草稿，未经 rev 门禁，orch 未落地。** 设计输入与五个决策点见
> `doc/design-prompt/verification_maturity.md`。轴与 M4 正交：M4 是结构覆盖率百分比
> 单一轴，本里程碑是验证方法论成熟度轴；二者关系是"M5 随机/闭环产出**可能**帮更
> 省力关上 M4 结构缺口"，但目标性质不同（提案 Decision 1，C1.1–C1.4）。
> 定向优先（M4）、随机后（M5）是证据链项目的正确顺序——
> 随机只能加固/发现，不能替代 M4 的定向关闭（每 ✅ 行须是有 spec 引用、可证伪描述的
> 具名场景）。

Exit criteria（草稿，rev 门禁前不生效）：

- [ ] **约束随机激励层**：`axi_seq_item` 四 `rand` 字段配 rev 批准的 `constraint`
      块（合法性边界编码进约束、非事后 scoreboard 兜底），`atop` 升为有界 `rand`
      （`{'0} ∪ 合法 atomic-load 编码`，零 spec 改动）；一条配置无关的通用随机
      虚拟序列（`xbar_random_vseq`）在 baseline + cfgA–E 全配置点复用跑通
      （design-prompt Decision 2，C2.1–C2.7）
- [ ] **多种子回归**：M1–M4 全 UVM 定向场景至少 N=5 固定记录种子全过（时序/保序
      高价值子集 N=10），`sim/regress/regress.list` 承载种子行，`result_summary.txt`
      捕获入回归证据显示全部种子 `passed=N/N`（testplan 行 canonical 种子不变、
      scripts schema 零改动，design-prompt Decision 3）
- [ ] **压力/soak**：每拓扑类（baseline 6×8 + cfgB 6×1 + cfgA 1×8）至少一条长随机
      饱和场景，判据 = 自检三层（scoreboard/SVA/functional cov）零 mismatch/零 assert
      失败 + **无 watchdog 超时（liveness，引 §5.5.4，REV-019 校正）** + **覆盖率趋于饱和**（连续
      K 窗口增量 < ε，作停止判据非 PASS/FAIL）；判决延迟不敏感（§7.4），各桶在飞
      同时压到 §5.4.1 有效上限（design-prompt Decision 4）
- [ ] **覆盖率驱动闭环**：`scripts/cov_loop.py` 跑确定性随机种子、查功能+结构覆盖、
      缺口未闭合则继续、饱和/预算上限则停，逐种子记边际贡献 + 停止时残余缺口清单；
      残余缺口 → 派生定向 testplan 行**或**书面记随机不可达（脚本不 turn green 任何
      行，覆盖率只测量不作 oracle，design-prompt Decision 5，B0.2/B0.3）
- [ ] **KILL 覆盖（不变量 5）**：M5 新引入的每类 checker（soak watchdog liveness、
      饱和探测器、随机约束合法性 env 兜底监视）各至少一条打 M5 标签的 KILL 行
- [ ] 签核：`doc/evidence/v1.1.*/signoff-M5.md`（rev 全 rubric）
- [ ] 签核后转 v1.0.0
