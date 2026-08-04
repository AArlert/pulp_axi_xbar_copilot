# 迁移手册：从旧仓库到新仓库

> 本文固化旧仓库（`pulp_axi_xbar_copilot`，M0–M7）全生命周期中积累的决策、
> 模板和教训，为新仓库 bootstrap 提供唯一输入。读者 = 未来在新仓库里工作的
> 人和 agent。

---

## 1. 新仓库目录结构

```
README.md                    ← 文档地图（一段话 + 文件清单超链接）
CLAUDE.md                    ← 两条红线 + 分工三区 + 学习机制
.gitattributes               ← 换行符锁定（从旧仓库搬）
.githooks/                   ← pre-commit hook（从旧仓库搬）
vendor/                      ← DUT 只读快照（同 SHA，照 VENDOR.md）
  axi/
  common_cells/
  VENDOR.md
doc/
  spec.md                    ← DUT 行为规格（单一事实源，含 [HV] 标记位）
  vplan.md                   ← 验证计划表（内建 spec 条款 + checker 两列）
  waivers.md                 ← 覆盖率豁免登记本
  bugs.md                    ← bug 台账（五环模板）
  log.md                     ← 工作日志（用户亲写，agent 只核事实）
  milestone.md               ← 里程碑进度表
  evidence/                  ← 仿真证据摘录（make evidence 产出）
  guide/
    axi.md                   ← 被测对象教学（从旧仓库迁移/修订）
    uvm.md                   ← 验证环境教学
    coverage.md              ← 覆盖率教学
    glossary.md              ← 术语表
    workflow.md              ← agent 协作工作流说明
tb/
  sva/                       ← SVA 套件（从零手写，ABV 主轴）
  ...                        ← UVM env 骨架（从旧仓库复用）
sim/
  Makefile                   ← 仿真入口（从旧仓库适配）
  flist/                     ← 文件列表
  regress/                   ← 回归列表
scripts/
  docs.py                    ← evidence/门禁/格式脚本
```

**关键原则**：每份文档只回答一个问题（见 §7），不交叉维护同形表格。

## 2. vplan 表 schema

旧仓库 `testplan.md` 的列：`id | config | description | status | evidence | repro | tags`

新仓库 `vplan.md` 增加两列，追溯矩阵内建：

| 列 | 说明 |
|---|---|
| id | 场景编号（M<n>-XX<nn>） |
| config | 配置点名 |
| spec-clause | 被验证的 spec 条款编号（如 SPEC-5.2.1）。一行可列多条 |
| checker | 由谁揪违反（SB_xxx / SVA_xxx / env guard）。须具体到 tag 名 |
| description | 场景描述 + 判据 + must-reach 角落 |
| status | 🔲 / ✅（只经 `make evidence` 翻绿）|
| evidence | 证据文件路径 |
| repro | `make run TEST=<t> SEED=<n>` |

**与旧仓库 testplan 的区别**：spec-clause 和 checker 两列使追溯矩阵内建——
不再需要独立的 `M7-traceability.md` 来事后补。G1 缺口（`doc/M7-methodology-review.md`）
的对策。

## 3. bug 页五环模板

每条 bug 按五个环节记录，环间前驱依赖（上一环没做完不跳下一环）：

### 模板

```markdown
## BUG-NNNN: [一句话标题]

**类别**：[TOOL_ENV / TB_BUG / CONSTRAINT_BUG / SPEC_ISSUE / DUT_BUG]
**状态**：[OPEN / FIXING / CLOSED / CLOSED-STATIC / ACCEPTED@M<n>]
**人的假设（agent 分析前）**：[用户在看到 agent 分析前的第一判断，即便错了也留着]

### 环 1：现象（含复现命令）
make run TEST=<t> SEED=<n>
[仿真日志中的关键行]

### 环 2：三方对照
| 项 | DUT 实际 | 期望值（来源 spec §X.Y） | 差异 |
|---|---|---|---|
| ... | ... | ... | ... |

### 环 3：分诊排他（按顺序排查，首个命中即停）
1. TOOL_ENV？→ [排除/确认理由]
2. TB_BUG？→ [排除/确认理由]
3. CONSTRAINT_BUG？→ [排除/确认理由]
4. SPEC_ISSUE？→ [排除/确认理由]
5. DUT_BUG？→ [排除/确认理由]

### 环 4：RCA（Root Cause Analysis）
[根因分析，指向具体代码行]

### 环 5：修复 + 复验
- Fix commit: [hash]
- 复验: make run TEST=<t> SEED=<n> → PASS
- evidence: doc/evidence/v<ver>/...
```

### 新增字段说明

- **"人的假设"**：预测先行机制（§4 学习机制 #1）——用户在 agent 开始分析前
  写下自己的判断（哪类 bug、可能原因），对了增强信心，错了复盘假设偏差。
  agent 不得覆盖此字段。
- **CLOSED-STATIC**：以静态论证（非仿真 PASS 证据）关闭的 bug。旧仓库
  BUG-0075 就是此类——env 约束论证封死全部触发路径，但没有 FAIL→PASS 的
  仿真日志差异。显式标记弱证据强度。G7 缺口的对策。

## 4. 分工三区 + 学习机制

### 分工三区

| 区域 | 谁做 | 举例 |
|---|---|---|
| **脚本区** | agent 写脚本，用户跑 | evidence 提取、门禁检查、格式校验、urg 报告生成 |
| **亲手区** | 用户做，agent 不代写 | SVA 编写、失配调试第一轮、五类分诊裁定、waiver 裁定 |
| **协作区** | agent 起草样板，用户逐行过 | spec 条款草案、vplan 行草案、教学文档 |

### 学习机制五条

| # | 机制 | 怎么做 | 目的 |
|---|---|---|---|
| 1 | **预测先行** | bug 页"人的假设"字段——agent 分析前先写判断 | 练分诊直觉，错了复盘偏差 |
| 2 | **explain-back** | `log.md` 由用户亲写（agent 只核事实） | 迫使用户用自己的话概括做了什么 |
| 3 | **惰性走查 [HV]** | spec 条款首次被用作 SVA/checker 判据时，用户对照上游原文核一次、打 `[HV]` 标 | 按需深读，不一次看完 |
| 4 | **棘轮式移交** | agent 完整交付第一类任务，之后同类任务用户做、agent 只答疑 | 技能迁移不退化 |
| 5 | **面试防线测试** | 对已完成的工作设计面试拷问（"为什么这里用 Kind-A 不用 Kind-B？"） | 验证理解深度 |

## 5. 签核级"完成"定义

新仓库验收 = 以下五项全部满足：

1. **vplan 100% 翻绿**——所有注册行 status = ✅，经 `make evidence` 从 PASS
   log 提取（红线 1）
2. **覆盖率门槛**——六类代码覆盖全部（模块,类型）格 ≥90% 或有 rev 签核
   waiver，UNOWNED = 空集
3. **waiver 签核**——每条 waiver 有 RTL 行号 + urg 判据 + Kind 分类 + 可证伪
   解锁条件 + 独立 rev 签核
4. **assertion coverage**——SVA 断言覆盖率独立报告，vacuous 断言须解释
   （G8 缺口的对策）
5. **追溯矩阵无空行**——vplan 的 spec-clause 和 checker 列无空（内建追溯，
   G1 缺口的对策）

## 6. 迁移资产清单

| 处置 | 资产 | 说明 |
|---|---|---|
| **原样搬** | 两条红线（CLAUDE.md，见下文引述）| 不改 |
| **原样搬** | `make evidence` 脚本机制 | 红线 1 的执行层 |
| **原样搬** | 五类分诊顺序 | bug 页模板固化 |
| **原样搬** | `.gitattributes` / `.githooks` | 换行符 + pre-commit |
| **复用** | UVM env 骨架（agent/driver/monitor/scoreboard 框架）| 按新 vplan 适配 |
| **复用** | Makefile / flist 体系 | sim/ 目录结构不变 |
| **复用** | `vendor/` 快照 | 同 SHA 同 VENDOR.md |
| **复用** | 教学文档（axi.md/uvm.md/coverage.md/glossary.md）| 迁到 `doc/guide/`，按需修订 |
| **从零手写** | SVA 套件 | ABV 主轴，用户亲手写（亲手区） |
| **从零手写** | vplan.md | 新 schema（§2），用户从 spec 推导首批行（亲手区） |
| **agent 重写** | spec.md | 按 `[HV]` 机制迁入——agent 搬全文，全部条款初始无 `[HV]` 标；首次用作判据时用户核对上游原文打标 |
| **agent 重写** | bugs.md | 搬五类分诊表头 + 新五环模板（§3）；旧 bug 不搬（新仓库零开始） |

### 两条红线原文（原样搬入新 CLAUDE.md）

> **红线 1**：testplan 翻绿只能经 `make evidence`——脚本从真实仿真 log 提取
> 摘录、回填状态；手改状态列无效。失败 log 绝不登记为证据。

> **红线 2**：checker/SVA 的期望值只准从 `doc/spec.md` 推导，绝不来自被测
> RTL。波形/覆盖率是观测事实，可以看，不得抄成期望值。spec 有缺口 → 登记
> bug（SPEC_ISSUE）→ 补 spec 条款 → 再写 checker。

## 7. 文档-问题对照表

每份文档回答**一个**核心问题（防止职责重叠导致信息漂移）：

| 文档 | 回答什么问题 |
|---|---|
| `spec.md` | DUT 应该怎么做？（判据唯一来源） |
| `vplan.md` | 打算验证什么？怎么验？谁揪违反？ |
| `waivers.md` | 哪些覆盖率 bin 结构不可达？论据是什么？ |
| `bugs.md` | 出了什么问题？根因是什么？怎么修的？ |
| `log.md` | 做了什么？下一步？ |
| `milestone.md` | 到哪了？出口条件满足了吗？ |
| `guide/axi.md` | AXI 协议和 DUT 怎么工作？（教学） |
| `guide/uvm.md` | 验证环境怎么搭的？（教学） |
| `guide/coverage.md` | 覆盖率怎么测/怎么收敛？（教学） |
| `guide/glossary.md` | 这个术语是什么意思？（查表） |
| `CLAUDE.md` | agent 的行为约束（红线/分工/流程）|

**规则**：如果两份文档对同一事实各维护一份，删一份留指针。旧仓库 milestone.md
与 testplan.md 的"场景骨架表"漂移就是反例（v0.5.7 修复）。

## 8. agent 工作流复盘

### 教训 1：M4 空转

M4 初期 agent 在覆盖率数字上循环跑仿真，未先分诊 bin——跑再多随机也打不中
结构死 bin。修正后：先 urg 逐格看明细，再决定走 waiver 还是定向。

**新仓库规则**：覆盖率收敛阶段，先分诊再编码，不盲跑种子。

### 教训 2：orch 主干活模式

agent 分两级：orch（主循环）做决策和编码，subagent 做机械扫描和独立评审。
orch 不把决策委托给 subagent，subagent 不改代码。这比"派 subagent 全权干活"
的模式更可靠——subagent 上下文有限，判断力不如 orch。

**新仓库规则**：rev 做评审、explore 做搜索、orch 做判断和编码，职责不混。

### 教训 3：单一事实源（single source of truth）

旧仓库有一次已发生的漂移和两项从一开始就采取的预防措施：
- **已发生漂移**：testplan.md vs milestone.md 的场景表（v0.5.7 修复——删一份留指针）
- **预防措施**：coverage-waivers.md vs M6-cov-triage.md 的 CW 编号用引用而非复制
- **预防措施**：spec.md vs checker 代码中的注释只引用 §编号不复述内容

**新仓库规则**：每个事实只在一处为真。其他地方用链接或编号引用。如果发现
两处维护同一事实——立即消除一份。

### 教训 4：小闭环 + rev 门禁

从 v0.5.8 起强制"做完一个闭环 → rev 评审 → push → 停"。之前偶有连轴推进
导致错误累积（M5 收口审计发现 3 处 must-reach 未兑现就翻绿——如果每步都有
rev 独立核查，这些不会积到收口才发现）。

**新仓库规则**：一个闭环 → rev 过了 → push → 等用户指令。不连轴。

### 教训 5：完备性核对——两个独立教训

**5a. 全表↔子表完备性核对（BUG-0049）**：三级复核（卡 A / REV-031 / orch）
均以同一份 §8 汇总清单为输入，无人与 urg 原始模块清单做集合差——共模失效，
遗漏了部分覆盖格。根因不是 subagent 未返回，而是所有层级共享同一个不完整输入。

**5b. 收 subagent 产出必数（M5 收口教训）**：并行派多个 subagent 扫描时，
orch 收齐结果后必须做集合差核对（"计划派 N 个，实际收到 N 个？有遗漏？"）。
M5 收口审计发现 3 处 must-reach 未兑现，部分归因于 orch 未验证 subagent
产出的完备性就开始长跑。

**新仓库规则**：(a) 不同层级不共享同一份输入做互相核对；(b) 并行扫描后
orch 先数、再定稿。
