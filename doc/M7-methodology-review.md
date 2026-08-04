# M7 闭环 D：工业方法学对标评估

对照工业 IP 级验证 checklist 逐项三态评级：
- **达标**：本仓库在此维度的实践符合工业标准
- **不适用**：因 DUT 性质/项目范围此维度不构成评价项
- **缺口**：真实缺口，须新仓库补（标注具体差距）

---

## 1. 验证计划（vPlan）追溯

| 维度 | 评级 | 依据 |
|---|---|---|
| 场景注册先于编码 | **达标** | testplan 表头声明 "Register rows BEFORE coding"；git 历史可验证 |
| 场景绑定 spec 条款 | **达标** | 每行 description 显式引用 SPEC-X.Y，M7-traceability.md 已交叉验证 |
| 场景绑定复现命令 | **达标** | 每行 repro 列有 `make run TEST=<t> SEED=<n>` |
| 状态由脚本回填 | **达标** | 红线 1：`make evidence` 从 PASS log 提取，手改无效 |
| vPlan↔checker 列 | **缺口** | testplan 无 "checker" 列——场景描述内嵌 spec 引用但未显式标注 "由谁揪违反"。M7-traceability.md 弥补了此缺口但作为独立文档而非 testplan 内建列。**新仓库 vplan 须内建 "spec 条款" + "checker" 两列** |

## 2. 功能覆盖 vs 代码覆盖

| 维度 | 评级 | 依据 |
|---|---|---|
| 六类代码覆盖 ≥90% | **达标** | 132 cells，108≥90%，24 waivered，0 UNOWNED |
| 功能覆盖模型 | **缺口** | 有 `functional_coverage.sv` 含 covergroup（cg_stall、cg_tx_limit、cg_atop_read_interaction、cg_decode_error 等），但：(a) 无独立的功能覆盖收敛报告（功能覆盖数据散在 urg 报告中，无专项汇总）；(b) covergroup 设计与 spec 条款无系统化对应——是 bug 回归守卫和角落到达见证，不是 spec 条款驱动的交叉覆盖。**新仓库须按 vplan 行设计交叉覆盖 covergroup** |
| 功能/代码覆盖配比分析 | **缺口** | 工业实践要求分析"代码覆盖 100% 但功能覆盖仍有空洞"的场景——本仓库未做此分析。**新仓库须在覆盖率收敛时做一次功能/代码对比** |

## 3. 负面测试（错误路径 / 协议违反检测）

| 维度 | 评级 | 依据 |
|---|---|---|
| Decode error 路径 | **达标** | M3-DE01/DE02/OR04 + M4-RC01/EB01/EB02 + M6-CV01/05 全面覆盖 err_slv 应答形态、排序、背压 |
| 协议违反检测（主动注入非法激励）| **缺口** | 环境约束保证激励合法（§4.7 no ATOP to unmapped、§5.3.1 UniqueIds precondition、§6.4 ID uniqueness），但未主动注入违反这些约束的激励来验证 DUT 的鲁棒性或 checker 的检测能力。注：spec 明确声明违反这些约束时行为 undefined，因此**本 DUT 不要求鲁棒处理非法输入**——但 checker 自身的检测能力（env guard）仅在合法路径上被间接验证。**新仓库可考虑 checker 自测（故意注入违反 → env guard 必须红）** |
| 注伤自证（fault injection）| **达标** | M5 失败可追溯机制落地时两类注伤（id 破坏、addr 篡改）验证消息格式；M1-01 enrichment KILL-0005 注伤证伪 WRAP/strb 判决路径；soak 行 must-reach 机制要求"到不了即该行不成立" |

## 4. 协议 checker

| 维度 | 评级 | 依据 |
|---|---|---|
| AXI4 握手稳定性 | **达标** | axi_chan_sva.sv 5 通道各一条 SVA_*_STABLE |
| AXI4 复位行为 | **达标** | SVA_RST_IDLE + SVA_RST_RELEASE_IDLE |
| AXI4 burst 长度一致性 | **达标** | SVA_WLAST_LEN + SVA_RLAST_LEN |
| AXI4 独立协议 checker（如 VIP）| **缺口** | 未使用商业 AXI VIP 或开源独立协议 checker（如 Synopsys VIP、ARM AXI Protocol Checker）。当前 SVA 仅覆盖基本握手规则，不覆盖完整 AXI4 协议合规（如 exclusive access、cache 语义等）。注：xbar 是透传设备，不解释 cache/lock/exclusive 语义，故大部分高级协议规则不适用。**新仓库若扩展到这些信号的语义验证，须引入独立协议 checker** |

## 5. 回归卫生

| 维度 | 评级 | 依据 |
|---|---|---|
| 确定性复现 | **达标** | 每行固定种子，`make run TEST=<t> SEED=<n>` 稳定复现 |
| 多种子覆盖 | **达标** | 定向 N=5、时序/保序 N=10，241→266 行回归 |
| 无 flaky | **达标** | 241/241 → 266/266 PASS，无间歇失败 |
| 回归门禁（CI）| **缺口** | 有 `make check`（pre-commit hook），但无 CI 流水线（GitHub Actions / Jenkins）。本仓库为单人+agent 项目，手动 `make regress` 可接受；**新仓库若多人协作须加 CI** |

## 6. 签核产物

| 维度 | 评级 | 依据 |
|---|---|---|
| 覆盖率报告 | **达标** | urg 文本报告 + `cov_baseline.py` 现状表 + `doc/evidence/v0.6.3/M6-closeout.md` |
| 覆盖率豁免（waiver）| **达标** | `doc/coverage-waivers.md` 逐条 CW-001..019 + ext，每条有 RTL 行号 + urg 判据 + Kind-A 分类 |
| 追溯矩阵 | **达标** | `doc/M7-traceability.md`（闭环 B 产出）|
| 红线审计 | **达标** | `doc/M7-redline2-audit.md`（闭环 C 产出）|
| 里程碑签核记录 | **达标** | `doc/milestone.md` 每条 exit criteria 有 [x] + 兑现注记 |
| bug 台账 | **达标** | `doc/bugs.md` 五类分诊 + 逐条详细记录 + 关闭证据 |

## 7. 约束随机方法学

| 维度 | 评级 | 依据 |
|---|---|---|
| 硬约束编码 spec 合法性边界 | **达标** | §3.2 匹配边界、§4.7 ATOP 约束、§5.3.1 UniqueIds、§6.4 ID 唯一性、§8.3 Connectivity 均有硬约束 |
| 软约束/分布加权角落 | **达标** | len/addr/id 角落加权，桶撞车概率抬升 |
| 反稀释机制（must-reach）| **达标** | 四条反稀释规则 + 具名 must-reach coverpoint |
| 饱和停止判据 | **达标** | 连续 K 窗口增量 < ε 只是停止判据不是 PASS |

## 8. 多配置验证

| 维度 | 评级 | 依据 |
|---|---|---|
| 配置矩阵定义 | **达标** | spec §0 #3 定义 5 配置点（baseline + cfgA–E）|
| 跨配置回归 | **达标** | cfgA–E 各有专属测试 + soak 跨三拓扑 |
| 参数空间抽样合理性 | **达标** | 抽样覆盖：拓扑（1×N/N×1/4×4/6×8）、LatencyMode（3 档）、UniqueIds、ATOPs、Connectivity、FallThrough |

## 9. bug 追踪与分诊纪律

| 维度 | 评级 | 依据 |
|---|---|---|
| 无条件登记 | **达标** | CLAUDE.md 规定"不因已绕过而豁免"；6 条 bug 全部正式登记 |
| 五类分诊 | **达标** | TOOL_ENV → TB_BUG → CONSTRAINT_BUG → SPEC_ISSUE → DUT_BUG 顺序排查 |
| 关闭须复验证据 | **达标** | 每条 CLOSED bug 有 evidence 列（log 或静态论证）|
| 静态关闭标记 | **缺口** | BUG-0075 以静态论证关闭但无显式 `CLOSED-STATIC` 标记区分证据强度。**新仓库 bug 模板须加 `CLOSED-STATIC` 弱证据显式标记** |

## 10. ABV（断言基础验证）

| 维度 | 评级 | 依据 |
|---|---|---|
| SVA 覆盖关键协议规则 | **达标** | 14 条 assert（握手稳定性/复位/burst 长度/保序/ATOP/配置不变量）|
| SVA 与 scoreboard 互补 | **达标** | 保序（§5.2）同时有 SB_OR_REORDER 和 SVA_OR_W/R_REORDER 双重判决 |
| SVA 覆盖率收集 | **缺口** | 32 条 cover property 存在但未系统收集 assertion coverage 作为签核产物（assertion pass/fail/vacuity 统计在 urg 的 assert 类型中，但无独立 assertion coverage 报告）。**新仓库 SVA 主轴须产出独立 assertion coverage 报告** |
| formal 验证 | **不适用** | 当前工具链（VCS-2018）不支持 formal；spec/SVA 写法已保持 formal-ready（门开不关） |

## 11. 覆盖率闭合工作流

| 维度 | 评级 | 依据 |
|---|---|---|
| random-first, directed-fallback | **达标** | M6 原则：先跑随机测量，只对未命中 bin 写定向场景 |
| 逐格分诊 | **达标** | `doc/M6-cov-triage.md` 30 格逐格 urg bin 级 + RTL 交叉验证 |
| per-seed 边际贡献分析 | **缺口** | EC-3 scope reduction：计划中的 per-seed 工具被定向闭合路线替代。功能上达标但方法学工具缺失。**新仓库若需覆盖率收敛效率可补 per-seed 工具** |

---

## 汇总

| 评级 | 维度数 | 清单 |
|---|---|---|
| **达标** | 30 | 大部分核心维度 |
| **不适用** | 1 | formal 验证（工具链限制）|
| **真实缺口** | 8 | 见下表 |

### 真实缺口清单（新仓库须补）

| # | 缺口 | 严重度 | 新仓库对策 |
|---|---|---|---|
| G1 | vPlan 无 "checker" 列 | 中 | vplan schema 内建 spec 条款 + checker 两列 |
| G2 | 功能覆盖模型非 spec 驱动 | 中 | 按 vplan 行设计交叉覆盖 covergroup |
| G3 | 功能/代码覆盖配比分析缺失 | 低 | 覆盖率收敛阶段做一次对比 |
| G4 | 无主动协议违反注入测试 checker 自身 | 低 | checker 自测：故意违反 env 约束 → guard 必须红 |
| G5 | 无独立 AXI4 协议 checker（VIP）| 低 | xbar 透传设备大部分高级协议不适用；按需引入 |
| G6 | 无 CI 流水线 | 低 | 新仓库加 GitHub Actions |
| G7 | bug 页无 CLOSED-STATIC 显式标记 | 低 | bug 模板加标记 |
| G8 | 无独立 assertion coverage 报告 | 中 | SVA 主轴须产出独立报告 |

**整体评价**：本仓库的验证方法学骨架（UVM env + scoreboard + SVA + 约束随机 +
多配置回归 + 覆盖率收敛 + bug 纪律 + 签核产物）符合工业 IP 级验证的核心要求。
8 个缺口中无致命项，多数属于"深度/精度"层面（功能覆盖模型的 spec 驱动性、
vPlan 追溯粒度、assertion 报告独立性），是新仓库以 SVA 主轴做深时自然需要
补齐的。
