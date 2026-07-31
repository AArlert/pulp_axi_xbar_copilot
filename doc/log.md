# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.4.9] 2026-08-01 M4 收尾第一项：BUG-0041 分诊闭环——REV-020 终判 WONTFIX，新登记 BUG-0045（spec-gap 候选），BUG-0043 保持观察

**背景**：接手会话按 0.4.8 遗留的顺序裁决（M5 阶段 1-4 需排在 M4 签核之后）
执行，用户选定先做 `make next` 给出的两个 OPEN bug 分诊，作为 M4 收尾三项
（分诊两个 bug / 覆盖率基线重出 / REV-017 条件 3）的第一项。

**Done**
- **BUG-0041 完成分诊闭环**：派全新 rev 实例（L3/opus）出具
  `doc/review/REV-020.md`，独立逐行核验 `addr_decode_dync.sv` 头注释/组合
  译码/`ASSERT_FINAL`/宏体 + `tb/seq_lib.sv` 收尾腿工作绕过 + `doc/spec.md`
  §3.1/§3.2，不采信 DV 详情页的任何转述。终判：**DUT_BUG（候选）不予签核**
  （DUT 输出零失配，失败的是内部调试断言非功能输出，bar 未达）；**终态
  WONTFIX（accepted-vendor-quirk）**；P-xxx 补丁与库级 `disable_assert_
  final_checks` 逃生阀均排除（前者越只读红线，后者是断言库全局钝器，会
  掩盖真实的其它 `final` 断言缺陷）；上游 doc-clarification issue 建议但
  低优先、非阻塞。orch 应用终判：`doc/bugs.md` BUG-0041 行 `OPEN → WONTFIX`；
  `doc/bugs/BUG-0041.md` `## fix` 段落补裁决记录；`## regression_guard`
  按 REV-020 条件 2 收紧——原"未来可机械化为 lint 规则"的投机承诺降格为
  "why it cannot（末态地址驻留是运行时激励属性，非静态可判定的构造属性）"，
  改为 grep 锚（`more_than_1_bit_set`/`matched_rules`）+ 既有定向收尾腿模式。
- **新登记 BUG-0045**（OPEN，spec，SPEC_ISSUE 候选，非阻塞）：REV-020 仲裁
  过程中逐行亲读 `addr_decode_dync.sv` 时顺带发现——RTL L112 + 头注释 L60
  记录 `end_addr=='0` 视为地址空间末端的哨兵分支，`doc/spec.md` §3.2 与
  refmodel `decode_mst_port` 均未覆盖该分支；当前无场景构造此类地址表，
  缺口潜伏无碍。按无条件登记纪律（CLAUDE.md §2）落 bugs.md 行 +
  `doc/bugs/BUG-0045.md` 详情页，未越权代做 spec/RTL 改动，待后续 rev/arch
  裁决是否补 spec 条款或记为 residual risk。
- **BUG-0043 维持不动**：taxonomy TOOL_ENV（候选），触发条件未定位、
  间歇性、无可执行判据——其自身 `regression_guard` 已明确"暂不可机械复现"，
  本轮分诊结论就是"暂不派卡，保持 OPEN 观察"，不是遗漏。
- `make check`（docs-check + chain audit，无新增缺口，与 0.4.8 一致）、
  `make selftest`（61/61）本轮改动后复跑绿。

**Not done**
- M4 收尾其余两项未动：M4 六类覆盖率基线报告重出（REV-016 条件2遗留）、
  REV-017 条件3（atop_filter FSM 书面豁免 + BUG-0032 guard 抽查）。
- 完整 M4 签核（`make check MILESTONE=4` + rev 人工 rubric + KILL 核对 +
  `doc/evidence/v1.0.0/signoff-M4.md`）未启动。
- `BUG-0045` 本身尚待 rev/arch 裁决（补 spec 条款 vs 记为 residual risk），
  本条不阻塞 M4 签核（当前无场景触及该分支）。
- M5 阶段 1-4 仍未启动（按 REV-019 裁决，正确顺序）。

**Next**
- 按 CLAUDE.md 派卡定级表，从 M4 收尾剩余两项中选一项派发：M4 覆盖率基线
  重出（可复用现有 cov.vdb 若仍在，否则 `make regress COV=1`）或 REV-017
  条件3（atop_filter FSM 书面豁免卡）。
- 之后走完整 M4 签核，`doc/milestone.md` M4 转 ✅，版本转段（建议 v1.0.0）。
- `doc/bugs/BUG-0045.md` 待排期一张 rev/arch 裁决卡（非阻塞，可与 M4 收尾
  并行或稍后处理）。

**How verified**
- `make check`：docs-check passed；chain audit 缺口与 0.4.8 一致（无新增）。
- `make selftest`：61/61 OK。
- 本周期无仿真运行（纯 bug 分诊/仲裁/登记），无新增 evidence、无 testplan
  状态变化——`make evidence` 门禁不适用。
- `doc/bugs.md` 净变化：1 行状态转态（BUG-0041 OPEN→WONTFIX）+ 1 行新增
  （BUG-0045），`doc/review/` 新增 1 份（REV-020），均按无条件登记纪律留痕。

## [0.4.8] 2026-08-01 M5 立项阶段 0 完成——验证方法学拓展提案过 rev 门禁；下一步转回 M4 收尾（重要顺序裁决，见 Next）

**背景（供接手会话快速理解本次转折，非仅本条自己看）**：本周期用户提出重大
范围拓展——要求把项目验证方法学补齐到工业界标准（约束随机测试、多种子回归、
压力/soak 测试、覆盖率驱动闭环），已用 EnterPlanMode 产出分阶段派卡计划并获
用户批准，**完整计划存档于 `/home/icarray/.claude/plans/misty-petting-horizon.md`
——接手会话必读**。该计划把工作分五个阶段：阶段 -1（收尾在飞的 M4 spec-gap
sweep，已完成，见上一条 0.4.7）→ 阶段 0（arch 起草方法学提案 + rev 把关）→
阶段 1（既有场景补多种子回归）→ 阶段 2（约束随机基础设施）→ 阶段 3（压力/soak）
→ 阶段 4（覆盖率驱动闭环脚本）。

**Done**
- **阶段 0 完成**：ARCH 全新实例（L3/opus）交付
  `doc/design-prompt/verification_maturity.md`（348 行提案），覆盖五个决策点：
  1. 里程碑归属——建议新开 **M5**，且**排在 M4 签核之后**（正交轴论证：M4 是
     结构覆盖率百分比单一轴，M5 是验证方法论成熟度轴；并入会让 M4 出口条件
     失焦）；
  2. 约束随机架构——`axi_seq_item` 四个既有 `rand` 字段（`is_write/addr/
     len/id`，现状：声明了但全仓 `.randomize()`/`constraint` 使用次数均为 0）
     配硬约束（spec 合法性边界，如 §4 clause 7 ATOP×未命中地址环境约束）+
     软约束（角落加权，如同桶 ID 撞车概率显式抬高——直接呼应本周期抓到的
     BUG-0009/0023/0042「同拍时序巧合」类缺陷）；`atop` 升级为有界随机
     （限定 `{'0} ∪ 合法 atomic-load 编码`，不放开 store/swap/compare，因为
     spec §6 对后者无应答义务条款——此缺口即下述 BUG-0044）；集中 ID 分配器
     兜住跨事务不变量（§5.3.1 UniqueIds / §6.4 ATOP 全方向唯一）；
  3. 多种子回归——N=5 底线（时序敏感子集 N=10），给出编译 vs 运行时开销的
     量化经济学论证（种子扫描复用已编译 simv，纯运行时开销）；
  4. 压力/soak——多拓扑饱和场景 + watchdog 活性检查（新判据，非固定拍数
     断言）+ 覆盖率饱和作停止判据（非 PASS/FAIL）；
  5. 覆盖率驱动闭环——`scripts/cov_loop.py` 功能规格（覆盖率只测量不做
     oracle、脚本不 turn green 任何行）。
  全程恪守 arch 自己声明的四条治理边界 B0.1-B0.4（期望值只来自 spec、覆盖率
  非 oracle、不 turn green 任何行、延迟不敏感）。
- **REV 全新实例**（与 arch 隔离）出具 `doc/review/REV-019.md`，**CONDITIONAL
  PASS**（四决策点 CONDITIONAL PASS + 一决策点 PASS）。逐条独立核实 spec 引用
  与历史 bug 细节引用的真实性（非采信 arch 自报），四条闭合条件：
  1. 一处引用勘误（watchdog 活性判据真实出处是 §5.5.4，提案误引 §5.5.3）；
  2. 提案设计约束随机化时主动发现的 SPEC_ISSUE（spec §6 对 ATOP
     atomicstore/atomicswap/atomiccompare 三个子类型无应答义务条款）——
     "仲裁可以延后，但登记不可延后"；
  3. 多种子落地卡必须显式承接"`regress.list ⊇ testplan ✅ 集合`这条既有
     隐性完备度纪律（BUG-0028/0036 经验），种子行从个位数膨胀到约 120 行后
     如何保持可审"——REV-019 亲验 `scripts/docs.py`/`scripts/regress.py`
     均无任何机器交叉校验此差集，现状纯人工比对；
  4. 一处未经 spec 授权的 DUT 行为断言（"crossbar 单次译码不逐拍重译码"）
     需软化为纯参考模型简化理由。
- **orch 逐条应用四条条件**：两处引用勘误（design-prompt + milestone 各一
  处）；登记 **BUG-0044**（SPEC_ISSUE，`ACCEPTED@M5`，containment=有界随机
  子集，不阻塞 M5）；design-prompt Decision 3 段落补充完备度审计的强制范围
  条款（供后续落地卡执行）；C2.1 措辞改写（不再对 DUT 译码基数下断言）。
  `doc/milestone.md` 已有完整 M5 章节草稿（Abstract 表 + 出口条件），状态
  标"🔲 提案"（未派 DE/DV 卡）。
- `make check`/`make selftest` 每次改动后复跑绿。

**Not done**
- **M5 阶段 1-4 均未开始**——按 REV-019 的裁决（本条最重要的信息），M5 应排
  在 **M4 正式签核之后**才启动，理由是两条轴不同、且不应往在飞的 M4 里程碑
  注入大改动。故下一步**不是**直接派阶段 1（多种子回归）的 DV 卡。
- **M4 尚未签核**，遗留三项前置工作（均在本周期之前就已存在，非本周期新增）：
  1. `REV-017` 条件 3 未兑现——atop_filter FSM 书面豁免 + `BUG-0032` guard
     抽查，M4 签核前置条件；
  2. M4 六类覆盖率基线报告需要重出（`REV-016` 条件 2 遗留）——现在 M4-OV01/
     FT01/RC01/AW01 四条新场景已落地（0.4.6-0.4.7 完成），是重出这份报告
     收益最大的时机，能看到真实收敛效果；
  3. 走完整 M4 签核流程：`make check MILESTONE=4` 机器条件 + rev 人工抽查
     rubric + KILL coverage 核对 + `doc/evidence/v1.0.0/signoff-M4.md`
     （或按实际版本号）。
- `BUG-0041`（OPEN，DUT 候选，`addr_decode_dync` 调试断言与重叠特性冲突）与
  `BUG-0043`（OPEN，TOOL_ENV 候选，间歇性仿真进程非零退出）仍未分诊/仲裁，
  与 M4 签核有交集（BUG-0041 底层 RTL 处置需要 rev 裁决，可能影响签核范围
  判断）——建议 M4 签核前一并核对处置。
- `BUG-0044`（新登记）仲裁本身延迟，不阻塞任何当前工作。

**Next（接手会话按此顺序执行，不要跳到 M5）**
1. **先收尾 M4**：重出 M4 六类覆盖率基线报告（复用现有干净隔离的
   `out/{m0,cfgA..E}/cov.vdb` 若仍在，否则重跑 `make regress COV=1`）→ 兑现
   `REV-017` 条件 3（atop_filter FSM 书面豁免，派 REV 卡）→ 视情况处置
   `BUG-0041`/`BUG-0043` → 走完整 M4 签核（`make check MILESTONE=4` + rev
   人工 rubric）→ `doc/milestone.md` M4 标记转 ✅、版本转段（建议 v1.0.0，
   与 M5 草稿里"M4 签核转 v1.0.0"的占位假设一致）。
2. **M4 签核后**才开始 M5 阶段 1（既有场景补多种子回归）——完整五阶段计划见
   `/home/icarray/.claude/plans/misty-petting-horizon.md`，阶段 0 的具体
   技术方案见 `doc/design-prompt/verification_maturity.md`（已过 rev 门禁，
   可直接作为阶段 1-4 派卡的设计输入，不需要重新起草）。

**How verified**
- `make check` 绿：docs-check passed，chain audit 无新增缺口（与 0.4.7 一致）。
- `make selftest` 61/61 OK。
- 本周期无仿真运行（纯文档/提案层落地），故无新 evidence 记录、无 testplan
  状态变化——`make evidence` 门禁不适用。
- `doc/bugs.md` 新增 1 行（BUG-0044），`doc/review/` 新增 1 份（REV-019），
  均按无条件登记纪律留痕。

## [0.4.7] 2026-08-01 M4 spec-gap sweep 收官——4 条候选场景全部落地，发现并处理 3 个真实缺陷/异常

**Done**
- 上周期（0.4.6）REV-018 裁决注册的 4 条 M4 候选场景全部实现并转 ✅，每张
  DV 卡均 fresh instance，orch 逐一独立复验（亲跑单场景 + 全量回归 + make
  check/selftest，不采信卡内自报数字）后才 commit+push：
  - **M4-OV01**（重叠 rule 优先级）：`decode_mst_port()` 改"扫描全表取最高
    下标命中"（对既有全部非重叠配置行为逐位不变）。落地中发现
    **BUG-0041**（OPEN，DUT 候选）——`addr_decode_dync` 末尾调试专用
    onehot0 断言与其自身文档化的重叠特性冲突，激励侧收尾腿绕过，留 rev
    裁决底层 RTL 是否需上游报告。
  - **M4-FT01**（新增 cfgE，`FallThrough=1`）：非判决 cover 诚实报告 0
    命中（结构性不可达，未凑数）。落地中发现并修复 **BUG-0042**（TB_BUG
    终态）——`mstport_agent.sv`/`axi_chan_sva.sv` 的 AW/W FIFO 配对逻辑
    隐含假设"AW 恒不晚于自己的 W"，`FallThrough=1` 打破该假设，三处组件
    统一改对称双队列修复。orch 复验全量回归时抓到一次自报"24/24"与亲跑
    "23/24"的真实出入（`m1_02_id_prefix_test` 间歇性进程非零退出、日志
    内容干净、后续两次独立复现均转绿），登记 **BUG-0043**（OPEN，
    TOOL_ENV 候选，未定位具体触发条件，判非本次改动回归）。
  - **M4-RC01**（default port 运行时"使能→关闭"回路，此前只测过反方向）：
    两阶段重配，复用既有 scoreboard cfg_hist 机制，无新判决逻辑。顺带核对
    REV-018 遗留开放风险——确认 BUG-0025/BUG-0031 的 TB 修复确实已在位，
    DUT 内建 default 相关 assert real-succeeded 仍为 0 系正交的激励形态
    缺口（读 RTL 确认前提条件从未被满足），非遗留债务。
  - **M4-AW01**（mux 仲裁背压）：`mstport_agent.sv` 加默认关闭、per-instance
    开启的背压开关，激励复用既有 `m2_wo01_worder_vseq` 不改。非判决 cover
    `cg_aw_retry` 39/39 命中，证明仲裁重试路径确实被激励到。
- 全部 4 张卡均遵守"判决门锚 spec 性质、结构角落仅非判决 cover"纪律
  （REV-018 guidance），无一处把结构覆盖动机写成判决期望值。
- `sim/regress/regress.list` 从 22 行增至 26 行，`doc/testplan.md` M4 四行
  全部 ✅（M4: 4/4，此前 0/4）。

**Not done**
- BUG-0041/0043 仍 OPEN，未仲裁/未分诊（前者需 rev 裁决底层 RTL 处置，
  后者需进一步定位触发条件或接受为已知瞬时抖动）。
- REV-017 条件 3（atop_filter FSM 书面豁免 + BUG-0032 guard 抽查）未动，
  仍留给 M4 签核。
- M4 覆盖率基线报告重出（REV-016 条件 2 遗留）未动——现在 4 条新场景已
  落地，是重出这份报告的合适时机（能看到真实收敛效果）。
- 4 条新场景暂无 feature-matrix 关联（非阻塞 gap，留后续视实现范围判断）。
- **用户已批准一项重大范围拓展**：本周期对话中用户要求把验证方法学拓展到
  工业界标准——约束随机测试、多种子回归、压力/soak 测试、覆盖率驱动闭环
  （现状实测：25→26 个场景全部 `SEED=1`、`axi_seq_item` 声明 `rand` 字段
  但全仓 `.randomize()`/`constraint` 使用次数均为 0、无 soak 测试、覆盖率
  是事后测量非实时闭环）。已用 EnterPlanMode 产出分阶段派卡计划并获批准，
  存档于 `/home/icarray/.claude/plans/misty-petting-horizon.md`：阶段 0
  （arch 起草方法学拓展提案 + rev 把关，含"M5 新开 vs 并入 M4"的里程碑
  归属裁决）→ 阶段 1（既有场景补多种子回归，零新 TB 代码）→ 阶段 2（约束
  随机基础设施 + 首条随机化场景）→ 阶段 3（压力/soak 测试）→ 阶段 4
  （覆盖率驱动闭环脚本）。本周期尚未开始阶段 0。

**Next**
- 启动阶段 0：派 ARCH 起草验证方法学拓展提案（里程碑归属、约束随机架构、
  多种子回归策略、压力测试定义、覆盖率驱动闭环机制），REV 把关后 orch
  应用进 `doc/milestone.md`/`doc/spec.md` §0/`doc/design-prompt/`。
- 分诊 BUG-0041（等 rev 裁决）/ BUG-0043（间歇性异常，视后续复现情况）。
- M4 覆盖率基线报告重出（REV-016 条件 2，现在 4 条新场景已落地，收益最大
  的时机）。
- M4 签核前须兑现 REV-017 条件 3。

**How verified**
- 4 张 DV 卡各自的场景独立重跑 PASS；4 次独立全量回归（22→23→24→25→26
  场景规模递增）逐次亲跑，除一次间歇性 flake（已登记 BUG-0043、非本周期
  改动回归）外全部干净；`make check`/`make selftest` 每张卡收尾均复跑绿。
- 逐 diff 核对每张卡的判决逻辑改动（`decode_mst_port`/`mstport_agent.sv`
  对称双队列/`cg_*` 非判决 cover 定义）与红线合规性，未发现越权把结构角落
  写成判决期望值的情况。
- `doc/evidence/v0.4.6/` 新增 4 条 evidence 记录（M4-OV01/FT01/RC01/AW01），
  `doc/bugs.md` 新增 3 行（BUG-0041/0042/0043），均按无条件登记纪律留痕。

