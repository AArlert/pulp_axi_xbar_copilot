# Work log archive
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

## [0.4.6] 2026-07-31 M4 spec-gap 全面扫描——4 条候选场景注册 + 2 条 spec 提案仲裁应用 + REV-017 条件 2 部分兑现

**Done**
- **ARCH 自新实例（L3/opus，fresh instance）**：M4 spec-gap sweep，范围按
  用户要求扩展到"整个验证空间、已知+未知 gap、主动探索"，不止步于机械
  未引用小节清单。交付 `doc/review/M4-spec-gap-sweep.md`：11 个未引用小节
  逐条处置（以 declined 为主，均附理由）、4 条候选 M4 testplan 行
  （M4-RC01 default-port 运行时关闭方向、M4-AW01 mux 仲裁 lock-retry 背压、
  M4-OV01 重叠 rule 优先级、M4-FT01 `FallThrough=1`）、未知空间主动探索
  6 项 findings（含确认 atop_filter FSM 大缺口"不提案"判断成立）、2 条
  spec change proposal（§0 #3 配置矩阵 `FallThrough` 维度归属；§4 clause 7
  "译码未命中地址"范围两可）。分析用 `doc/evidence/v0.4.0/M4-coverage-baseline.md`
  实测覆盖率数字定位真实缺口，非空转清单。
- **REV 全新实例（L3/opus，与 arch 隔离，未共用）**：审核并出具
  `doc/review/REV-018.md`，CONDITIONAL PASS。4 条候选行全部注册（各附
  conditional 口径：判决门须锚 spec 性质、结构角落仅作非判决 cover，
  M4-FT01 以提案 1 取 (a) 为前提）；11 个 declined 逐条复核全部站得住
  （§6.2 建议补引 anchor）；提案 1 裁 **(a) 增维**（FallThrough 是可达
  spec 合法逻辑，豁免应留给不可达而非不想测）；提案 2 裁 **(b) 确认宽读
  有意保守**（与 M4-RC01 的运行时 default port 可变存在移动靶耦合，宽读
  恒稳且零功能增益）；两个 open risk 关联项均给出立场（RC01 与既有 AW 侧
  default assert 债务联动，留 DV 卡核对，不阻塞；M0-01 同意不回改）；无新
  taxonomy-class 异常。
- **orch 按 REV-018"可机械执行的落地清单"逐条应用**：`doc/spec.md` §0
  item 3 增列 `× FallThrough {0,1}` 维；§4 clause 7 追加范围澄清段（宽读
  有意保守 + 双条理由）；Change record #11；重 pin sha256（
  `a480b728...`）。`doc/testplan.md` 注册 4 条候选行（状态 🔲，判决门/红线
  /env 约束逐条写入描述，与 M2-WO01/M3-TL01 既有先例同款措辞纪律）；
  M3-DE01 约束句范围由"其余全部 M3 场景"扩为"M3 与 M4 全部场景"（REV-017
  条件 2 部分兑现——spec 侧 §4 clause 7 上周期已是"M3 与 M4"，本周期补齐
  testplan 侧措辞同步）；M3-CF04 env 约束锚点由 `SPEC-6` 精化为
  `SPEC-6/SPEC-6.2`（§6.2 补引，非新场景）。另提交并推送用户直接编辑的
  `doc/milestone.md` Abstract 汇总表（M0-M4 场景/状态一览）。

**Not done**
- 4 条新 M4 testplan 行仍是 🔲（planned）：未派 DV 卡实现、未跑仿真、未
  registered evidence——本周期只完成"注册"这一步（spec-gap sweep + rev
  仲裁 + 落地登记），场景实现是下一周期的事。
- 4 条新行暂无 feature-matrix 关联（`make check` 报 orphans 4 个，非阻塞
  gap，非 FAIL）——REV-018 落地清单未要求本周期做这步，留给对应 DV 卡
  实现时按需补（可能挂靠既有 F-M2-01/F-M3-03 或新开 F-M4-xx，由后续
  arch/orch 视实现范围判断，非本周期预判）。
- REV-017 条件 2 仍未**完全**闭合：spec+testplan 两侧措辞已同步"M3 与
  M4"，但条件 2 原文还要求"M4 config-matrix testplan 行须承载"——本周期
  四条新行均已承载该约束句（各行"env 约束"段），此条实质已随本周期落地
  行为同步兑现，留待 M4 签核时由 rev 复核确认。
- REV-017 条件 3（atop_filter FSM 书面豁免 + BUG-0032 guard 抽查）未动，
  仍留给 M4 签核。
- M4 覆盖率基线报告重出（REV-016 条件 2 遗留）未动。
- regress.list 未动（待 4 行任一转 ✅ 后才需要，BUG-0028/0036 纪律）。

**Next**
- 派 DV 卡实现 4 条新 M4 场景之一或多个（每卡独立、fresh instance，closer
  ≠ fixer 路由预先想清）；M4-OV01 落地时按 REV-018 纪律：若 SPEC-3.1.3
  取向消歧不清则登记 SPEC_ISSUE，不读 RTL；M4-RC01 落地时核对 open risk
  （AW 侧 default assert 是否随之 real-succeed，联动 BUG-0025/BUG-0031/
  M3-DE02）。
- 4 条场景任一 ✅ 后即时并入 `sim/regress/regress.list`（BUG-0028/0036
  常驻纪律）。
- 重出 M4 覆盖率基线报告（REV-016 条件 2 + 现有干净隔离的
  `out/{m0,cfgA..D}/cov.vdb`，同一份 vdb 不必重跑 `make regress COV=1`）。
- M4 签核前须兑现 REV-017 条件 3（atop_filter FSM 书面豁免 + BUG-0032
  guard 抽查）。

**How verified**
- `make check` 绿：docs-check passed；chain audit 未引用小节由 11 降至 7
  （§2.1/§6.2/§7.3/§7.4.3 经新行/anchor 补引清零，与 arch/rev 裁决的
  declined 集合一致，非误差）；dangling refs 0；orphans 4（本周期预期内的
  非阻塞可见性提示，见 Not done）。
- `doc/spec.sha256` 已重 pin 且与 `doc/spec.md` 当前内容一致
  （`python3 scripts/docs.py --pin-spec` 输出确认）。
- 本周期无仿真运行、无场景转 ✅，故无新 evidence 记录、无 testplan 状态
  回填——纯 spec/testplan/review 文档层落地，`make evidence` 门禁不适用。

## [0.4.5] 2026-07-30 BUG-0037 修复并关闭——COV=1 覆盖率数据库跨拓扑静默合并，orch 独立复验后机械关闭

**Done**
- **DV 自修卡（L1/sonnet，fresh 实例，仅做 fixer，未做 closer）**：诊断并修复
  BUG-0037（`make regress COV=1` 把 `upstream_sanity`/cfgA-D/baseline 三类
  结构不同的拓扑静默合并进同一 `out/cov.vdb`，`make cov` 报 825 行
  `UCAPI-INSTANCEMISMATCH` + 千余行 `CMR-VCINF`）。根因确认：
  `scripts/make/vcs-2018.mk` 的 `CM := ... -cm_dir $(OUT)/cov.vdb` 用 `:=`
  在 `include` 时提前展开、冻结默认 `OUT`，晚于其展开的 `sim/Makefile`
  per-config `override OUT` 改不动已展开字符串。修法两处：① `vcs-2018.mk`
  新增 `COV_DIR` 间接层，`CM`/`COV_DIR` 均改 `=`（递归展开，在
  `compile:`/`run:` recipe 执行时才求值，此时 per-config `override OUT`
  已生效）——cfgA-D 零改动自动获得正确隔离；② `sim/Makefile` 给
  `TEST=upstream_sanity` 分支单加 `COV_DIR := $(OUT)/m0/cov.vdb`，只挪覆盖率
  库路径、不动 `OUT` 本身（避免波及 `make clean` 默认作用域与 M0 构建产物
  路径）。`scripts/make/vcs-2018.mk` 是上游 pinned 文件，本地改动均按
  CLAUDE.md §5 加内联注释 + 登记 `doc/fw-feedback.md` FB-30。
- **orch 独立复验并直接关闭**（非另派 closer DV 实例——按本仓库既有先例
  BUG-0014/0019/0022，非仿真判定类 TOOL_ENV 修复由 orch 亲自复验即满足
  closer≠fixer）：亲跑 `make regress COV=1`（`sim/Makefile`/`scripts/`
  已改后），22/22 PASS 与修复前逐字一致；逐一 `make cov TEST=<domain>`
  核对 baseline（17 场景，确认仍正确合并、未被拆散）/ M0 / cfgA-D 共六个
  查询，0 处 `mismatch`/`CMR-VCINF`。经 `make evidence BUG=BUG-0037
  CMD=... EXPECT=BUG0037_VERIFIED_CLEAN` 机械关闭（非仿真判定关闭形态，
  BUG-0029 先例），证据 `doc/evidence/v0.4.4/BUG-0037.log`；`fix_commit`
  按既有先例（7ebff52 回填 BUG-0014 的做法）在拿到 commit hash 后单独一次
  小提交回填为 `13cdeda`。
- DV 卡在复验本卡自身 guard 清单（BUG-0014/0019/0021/0022）时意外发现
  `doc/lint-baseline.md` 快照（2026-07-28）落后于 `tb/` 0.4.2 重构提交
  （`01e7976`，2026-07-30），`make lint-diff` 报 153 个新站点（7 个既有
  类别、无新类别）；用 `git stash` 确认与本卡改动无关后，按登记无条件规则
  新开 **BUG-0040**（OPEN，TOOL_ENV），未分诊未修。

**Not done**
- BUG-0040 未分诊（153 个新站点风格 vs 真缺陷未逐条核实）、未修。
- 本周期未触碰 M4 backlog 的其余三项：REV-017 条件 2（M4 config-matrix
  testplan 行同步承载延展后的环境约束）、REV-016 条件 2 遗留（M4 覆盖率
  基线须按新三态口径重出，且应一并纳入 atop_filter FSM 书面豁免）、M4
  spec-gap 缺口探测（10 个未被引用的 spec 子节）。

**Next**
- 分诊 BUG-0040（`doc/lint-baseline.md` 差分重跑 + 153 站点逐条风格/真
  缺陷判定）
- 派 arch/dv 卡把 REV-017 延展后的约束落到 M4 config-matrix testplan 行，
  建议与 M4 spec-gap 缺口探测合并规划
- 重出 M4 覆盖率基线报告（REV-016 条件 2 + REV-017 条件 3 书面豁免一并
  纳入，同一份干净 vdb、不重跑仿真——现在有了本次修复后干净隔离的
  `out/{m0,cfgA..D}/cov.vdb`，可直接复用而不必二次跑 `make regress COV=1`）
- M4 签核前须兑现 REV-017 条件 3（atop_filter FSM 书面豁免 + BUG-0032
  guard 抽查）

**How verified**
- `make check` 绿（docs-check passed；chain audit gap 项与上周期一致，未
  新增）
- `make selftest` 61 tests OK
- `make regress COV=1` 修复前后均 22/22 PASS（功能判定不受本次改动影响，
  仅覆盖率数据库受影响）；修复后六个拓扑域查询 0 处
  `mismatch`/`CMR-VCINF`（orch 亲跑，非采信 DV 自报数字）
- `make evidence BUG=BUG-0037 CMD=... EXPECT=...` 生成
  `doc/evidence/v0.4.4/BUG-0037.log`，`doc/bugs.md` 状态机械回填为 CLOSED

## [0.4.4] 2026-07-30 BUG-0039 仲裁落地（REV-017）：§4 clause 7 环境约束延展至 M4 + atop_filter FSM 书面豁免出口，CONDITIONAL PASS 两条条件未兑现

**Done**
- **rev 卡（L3/opus，fresh 实例，未复用做过 REV-016 的实例）**：BUG-0039（M4
  六类收敛对 `axi_atop_filter` FSM 的要求与 spec §4 clause 7 的 BUG-0032 环境
  约束直接冲突）仲裁，产出 `doc/review/REV-017.md`。裁决 **CONDITIONAL
  PASS**。逐一亲验 BUG-0039 行陈述的三条事实为真（例化层次——全部 6 例
  `axi_atop_filter` 均在 `axi_err_slv.sv:45-58` 内例化、`axi_xbar_unmuxed.sv`
  grep "atop_filter" 零命中；FSM 必要条件——`axi_atop_filter.sv:138` 离开
  `W_FEEDTHROUGH`/`R_FEEDTHROUGH` 唯一触发即打到译码未命中地址；编码多样性
  已满足——`ATOP_ATOMICLOAD=2'b10 != ATOP_NONE=2'b00`，"补 AtomicCompare 序列"
  方向已被证伪）。**否决**"重开以定义 err_slv×ATOP 应答、放行激励"路径
  （REV-016 §6.2 选项 a/c）——五份许可来源仍皆空，放行等于让 checker 抄被测
  RTL 期望值，违不变量 #4。**采纳**选项 b：§4 clause 7 环境约束由 M3 延展至
  M3+M4（目的不变，M3/M4 许可来源沉默现状相同）+ `axi_atop_filter` FSM 中仅
  经被禁激励可达的状态/迁移弧走 §0 item 4"有 bin 但 <90%"分支出具 rev 签核
  书面豁免（不适用"无 bin ⇒ N/A"三态规则）。BUG-0032 guard 被延展、非解除。
- **orch 独立复核**（不采信卡内自报事实，亲跑 grep/sed 核对 REV-017 引用的
  四条承重事实 + `doc/testplan.md` M3-DE01/CF01-03 措辞，全部与 REV-017 一致）
  后**应用** REV-017 §"orch 应逐字应用的 spec 订正文本"：`doc/spec.md` §4
  clause 7 整条按逐字文本替换（相对现文四处改动：引用锚追加 REV-017、约束
  范围 M3→M3+M4、不阻塞范围同步扩、追加"M4 覆盖率后果"段），Change record
  追加第 10 行，`python3 scripts/docs.py --pin-spec` 重 pin（sha256
  `a177440c…c8fb083`）。§0 item 1-6、§4 clause 1-6、§6 全部未改动（surgical）。
- `doc/bugs.md` BUG-0039 行状态由 OPEN 转 **SPEC_CHANGED**，root_cause/
  verify_evidence 两列按 REV-017 逐字落，按 BUG-0029 guard 在两列写明实质
  复验位置 = `doc/review/REV-017.md`。新建详情页 `doc/bugs/BUG-0039.md`
  （原行内无该指针，本次按惯例补上 + 建页——REV-017 指出该详情页应承载本次
  仲裁的推理与事实认定），含 `## arbitration` 段引 REV-017 四条 Item 逐条
  摘要 + 三条未闭合条件清单。

**Not done**
- REV-017 CONDITIONAL PASS 的三条件只兑现了第 1 条（spec 应用 + 重 pin）。
  第 2 条（REV-013 重开要件 (b)：M4 config-matrix testplan 行须同步承载延展
  后的约束——现 `doc/testplan.md` 只有 M3-DE01 行范围为 M3，CF01-03 无该
  约束句）与第 3 条（M4 签核时 rev 出具 atop_filter FSM 书面豁免 + 跑
  BUG-0032 guard 抽查）均**未做**——M4 在此之前不得签核。
- BUG-0037（COV=1 多设计合并污染 `out/cov.vdb`）仍 OPEN，本周期未触碰。
- M4 尚无场景行、10 个 spec 子节无人引用（`make next` 第 3 项）——未派 arch
  spec-gap 卡；REV-017 条件 2 的 testplan 行自然应与该缺口一并规划，而非孤立
  补一行。
- REV-016 §11 记的"六问/七问"措辞漂移、REV-017 §"范围外观察"复述同一问题
  （`workflow/review/six_questions.md` 在本快照下为空、`workflow/review.md`
  首行仍写"seven questions"）——两次均判非 taxonomy 类，登记与否仍留 orch
  未决，本周期未处置。
- **续记（防丢失，`make archive` 已把上条 [0.4.3] 块滚入
  `doc/archive/log-archive.md`；BUG-0038 本周期同批被 `bug_done_keep=2` 挤出
  `doc/bugs.md` 滚入 `doc/archive/bugs-archive.md`，故此条不能只靠翻旧块
  找回）**：**REV-016 conditional pass 的条件 2 仍未兑现**——M4 覆盖率基线
  须按 BUG-0038/REV-016 定的新三态口径（无 bin ⇒ N/A + 已核实成因）**重出**
  报告（同一份干净 vdb、不重跑仿真），本行只完成条件 1（spec 应用+重 pin）。
  该重出工作理应把本周期 BUG-0039/REV-017 的 atop_filter FSM 书面豁免一并
  纳入同一份重出报告，不宜分两次改同一份文档。

**Next**
- 派 arch/dv 卡把延展后的约束落到 M4 config-matrix testplan 行（REV-017 条件
  2），建议与 M4 spec-gap 缺口探测（`make next` 第 3 项）合并规划，避免"孤立
  补一行"与"事后发现范围不够"两次改动
- 分诊 BUG-0037
- **重出 M4 覆盖率基线报告**（REV-016 条件 2，遗留未兑现；新文件，不回改
  v0.4.0 旧记录）——一并纳入 atop_filter FSM 的书面豁免记录（REV-017 条件 3）
- M4 签核前须兑现 REV-017 条件 3（书面豁免 + guard 抽查）——记入 M4 出口
  条件清单，避免届时遗漏

**How verified**
- `make check` 绿（docs-check passed；chain audit gap 项与上周期一致，未新增
  ——`make next` 第 3 项列的 10 个未引用子节、8 个仅锚定父节的引用、1 个
  M0-01 未引 spec 均为既有已知缺口）
- `make selftest` 61 tests OK
- `python3 scripts/docs.py --pin-spec` 重 pin 成功，新 sha256 已写入
  `doc/spec.sha256`
- REV-017 引用的四条承重结构事实（例化层次/FSM 转移条件/编码/testplan 现文）
  由 orch 亲跑 grep/sed 复核 vendor 原件与 `doc/testplan.md` 确认，非采信
  子代理自报
- 本周期**无仿真**：全部改动为 spec/台账/评审记录，无 RTL/TB 代码改动，故
  不产生也不登记任何 evidence 行

## [0.4.3] 2026-07-30 BUG-0038 仲裁落地：spec §0 覆盖率范围改例化闭包口径 + 新登记 BUG-0039（atop_filter FSM 可达性冲突）

**Done**
- **rev 卡（L3/opus，fresh 实例，定级 vs 实际一致）**：BUG-0038 spec 歧义
  仲裁，产出 `doc/review/REV-016.md`（579 行）。裁决 **conditional pass**，
  taxonomy 终判维持 SPEC_ISSUE，处置 SPEC_CHANGED。核心裁定：spec §0 item 4
  的"等"字**本就是例化闭包**（判据 = 是否出现在 `axi_xbar` 实例子树内，与
  模块所属上游库目录无关），依据是 item 5 原文已有的"间接例化即计入 #4"
  + REV-001 §3.3 C2 当年的判据本身就是例化关系而非模块名——故本次是**澄清
  而非范围扩张**。同时补上原文完全缺失的可判定性规则。
- **orch 应用（严格按 REV-016 §8 白名单，不外溢）**：`doc/spec.md` §0
  item 4 / item 5 各整行替换为 P-REV016-1 / P-REV016-2 逐字原文；Change
  record 追加第 9 行；`python3 scripts/docs.py --pin-spec` 重 pin
  （sha256 `0ce9fc3a…983191b2`）。**§4 clause 7 的 BUG-0032 环境约束一字
  未动**（REV-016 §8 明令，其重开是另案，不许搭顺风车）。
- **新口径实质**：判定单位 =（模块, 类型）二元组；三态判定——无 bin（空白）
  记 **N/A**，不入 ≥90% 的分子与分母，但**必须逐条写明已核实成因**；有 bin
  须 ≥90% 或走 rev 签核书面豁免。**空白不得记作 0%、不得记作 100%、不得省略
  不列**；父模块的 N/A 不得代表子模块达标。这正面回答了 BUG-0038 guard 点名
  的诉求（否则仪表盘上"M4 完成"与"M4 完成但两个没人商定过范围的空白 wrapper
  除外"完全同形）。
- **orch 独立复核（不采信卡内自报事实）**：亲跑 grep/sed 复核 REV-016 的四条
  承重结构事实，全部成立——(1) `axi_demux.sv` 有 7 个 `spill_register`
  （:89/102/119/132/145/162/175）；(2) `axi_xbar_unmuxed.sv` 全文无
  `atop_filter` 字样；(3) `axi_err_slv.sv:45-58` 才是 `axi_atop_filter` 的
  例化点；(4) `axi_atop_filter.sv:137` 的转移条件 vs `axi_pkg.sv:400/415`
  的 `ATOP_NONE`/`ATOP_ATOMICLOAD` 编码。
- **两处记录保真度订正**（rev 抓出，orch 复核后落）：`doc/bugs/BUG-0038.md`
  `## rca` 段"`axi_demux` 是纯透传 wrapper"**证伪**——它自身有 7 个
  `spill_register`（由 `axi_xbar_unmuxed.sv:178-182` 的 `LatencyMode[9:5]`
  驱动，即 spec §7.1 的物理载体）+ 4 条 assign，故其 Line/Cond/Branch 空白
  **尚未被证明是结构性的**；`addr_decode` 那一半成立。另一处
  （证据 §3.7 的 atop_filter 例化父模块记错）按 FB-23「冻结记录不回改」
  **不回改旧证据文件**，由新登记的 BUG-0039 行与未来重测记录承载。
- **BUG-0038 转 SPEC_CHANGED**，root_cause / verify_evidence 两列按 REV-016
  §10 逐字落；按 BUG-0029 guard（非仿真类缺陷无机械 `.log`）在两列**与**详情页
  `## rerun` 段三处写明实质复验位置 = `doc/review/REV-016.md §1/§3/§4`。
- **新登记 BUG-0039（OPEN，spec）——本周期最有价值的副产物**：M4 六类收敛
  对 `axi_atop_filter` FSM 的要求与 spec §4 clause 7 的 BUG-0032 环境约束
  **直接冲突**。该 DUT 内 6 个 atop_filter 实例**全在 `axi_err_slv` 内**，
  其 W FSM 离开 `W_FEEDTHROUGH` 的唯一条件是 `atop != 0` 的 AW 抵达 err_slv
  ⇒ 必须打到**译码未命中地址**，而 §4 clause 7 明令禁止。**连带证伪了
  0.4.1 记下的方向**：`doc/evidence/v0.4.0/M4-coverage-baseline.md` §4 第 1
  条把 FSM 7.14% 归因于"ATOP 编码多样性不足"，但现有 `ATOP_LOAD_ADD` 已含
  `ATOP_ATOMICLOAD=2'b10` ≠ `ATOP_NONE`，**编码条件早已满足**——缺的是地址
  落点。故"派场景卡补 AtomicCompare/AtomicSwap 编码"这条路**无效**，M4 最大
  缺口的钥匙一直找错了地方。

**Not done**
- REV-016 conditional pass 的三条件只兑现了第 1 条（spec 应用 + 重 pin）。
  第 2 条（M4 基线按新口径**重出**报告，同一份干净 vdb、不重跑仿真，每个 N/A
  附已核实成因）与第 3 条（BUG-0039 裁完才可推进 M4）均**未做**。
- BUG-0037（COV=1 多设计合并污染 `out/cov.vdb`）仍 OPEN，本周期未触碰。
- BUG-0039 只完成登记，未派仲裁卡。
- REV-016 §11 记的一处措辞漂移（`workflow/review.md` 现文是**七问**，
  CLAUDE.md L12 与派卡措辞沿用"六问"）**未登记也未订正**——rev 判其属文档
  指针问题、非 taxonomy 类，登记与否留给 orch，本周期未决。

**Next**
- 派 rev 仲裁卡处置 BUG-0039（放宽 §4 clause 7 到 M4 / 出具 FSM 书面豁免 /
  其他路径）——它是 M4 的前置门，不裁完派场景卡会白派
- 按新口径重出 M4 基线报告（REV-016 条件 2；新文件，不回改 v0.4.0 旧记录）
- 分诊 BUG-0037

**How verified**
- `make check` 绿（docs-check passed；chain audit 的 gap 项均为既有信息项，
  本周期未新增）
- `make selftest` 61 tests OK
- `python3 scripts/docs.py --pin-spec` 重 pin 成功，新 sha256 已写入
  `doc/spec.sha256`
- REV-016 的四条承重结构事实由 orch 亲跑 grep/sed 复核 vendor 原件确认
  （见上 Done 第 4 条），非采信子代理自报
- 本周期**无仿真**：全部改动为 spec/台账/评审记录，无 RTL/TB 代码改动，
  故不产生也不登记任何 evidence 行

## [0.4.2] 2026-07-30 落地 code-suggestion.md 三条零风险重构 + doc/uvm.md 验证环境入门读物

**Done**
- **DV 卡（L1/opus，fresh 实例，分 Part A/B 两段）**：
  - **Part A 重构**（`doc/code-suggestion.md` 里明确标注"纯激励/纯编排/
    纯注释、不碰判决"的三条）：`tb/seq_lib.sv` 新增 `fill_wr_payload()`
    helper（消 17 处重复的 payload 填充惯用法）+ `fanout_per_slv#(SEQ_T)`
    静态类（消 13 个 vseq 的"每 slave 端口扇出"骨架重复，另有 9 处因带
    额外参数/两条 seq 而按红线原样保留、未强行归并）；
    `tb/scoreboard_refmodel.sv` 顶部新增事务流转 ASCII 注释（纯注释，
    diff 逐行核对确认零逻辑改动）
  - **Part A 验证**：全回归 `make regress` 22/22 PASS；点名的全部 bug
    守卫数字（BUG-0023 的 w_collide_q/kept_now=192/192、
    r_collide_q/kept_now=264/264，BUG-0024 的 aw/ar_stack_diff_now=24/24，
    BUG-0027 的 stall violations=0，BUG-0031 的 c_sib_diff/
    c_bug31_livev1 各 1match/端口，BUG-0034 的 at02 四路 checker 归零）
    重构前后逐位比对一致，无一处需回退
  - **Part B 文档**：新增 `doc/uvm.md`（仿 `doc/axi.md` 逐层递进风格，
    §0 UVM 分层速览 → §1 组件地图 → §2 跟着代码走一遍（一笔写事务 5 站
    到具体文件行号）→ §3 SVA+scoreboard 并存动机 → §4 常见误解 → §5
    术语表 → §6 延伸阅读）；新增 `doc/attach/gen_uvm_env_svg.py`（纯
    Python 标准库，仿 `gen_dataflow_svg.py` 约定）生成
    `doc/attach/uvm_env_overview.svg`；`README.md` 新增"验证环境概览"节
    + 一条入口项目符号，不改动任何既有内容
  - **orch 独立复核**（不采信卡内自报数字）：diff 逐行确认
    scoreboard 改动 100% 为注释/空行；确认 `build_or03_burst` 的 k%2
    AxLEN 交替逻辑原样保留；亲跑 `make regress` 复现 22/22 PASS；SVG 用
    `xml.etree.ElementTree` 解析确认合法；抽查 `doc/uvm.md` 里 11 处
    文件:行引用（`seq_lib.sv:31/40`、`slvport_agent.sv:70/300/315`、
    `scoreboard_refmodel.sv:27/421/587/702/841`、
    `mstport_agent.sv:176`）逐条与当前代码内容核对，全部准确；
    `make check`/`make selftest`（61 tests）通过

**Not done**
- BUG-0037（COV=1 覆盖率数据库多设计合并异常）/BUG-0038（addr_decode/
  axi_demux wrapper 与 spec §0#4 命名范围疑点）均未处置，留待下一步分诊
- `axi_atop_filter` FSM 缺口（ATOP 编码多样性不足，M4 当前最大单一缺口）
  是否派场景卡补——未决策
- `doc/code-suggestion.md` 里标记"需 rev"或"仅登记"的条目（SVA 字段
  拷贝块收敛、scoreboard 物理拆分、key 打包函数注释、`m_probe` 耦合）
  均未触碰，按原计划留给后续

**Next**
- 分诊 BUG-0037/BUG-0038 处置顺序
- 决定是否派 ATOP 编码多样性场景卡填 FSM 缺口
- 待用户下一步指示

**How verified**
- `make check` 绿；`make selftest`（61 tests）通过
- `make regress` 22/22 PASS（orch 亲跑复现，非采信卡内自报）
- scoreboard 改动经 `git diff | grep` 逐行确认零逻辑行变化
- `doc/uvm.md` 文件:行引用抽查 11 处，与当前代码逐条核对一致
- SVG 用 Python 标准库 XML parser 解析确认合法

## [0.4.1] 2026-07-30 M4 六类覆盖率基线测出，登记 BUG-0037/BUG-0038；并行完成 UVM 框架人工评审

**Done**
- **DV 卡（L1/sonnet，fresh 实例，纯测量不修复）**：`make regress COV=1`
  全量 22/22 PASS，但 `make cov` 的 `urg` 生成日志暴露两处覆盖率数据库
  合并异常（见下）。改按三组隔离命令重新测量（17 场景基线拓扑合并 / M0
  `upstream_sanity` 单独 / 4 个 M3 配置点各自隔离，共 22 次独立 `make run`，
  每条均用 `svacheck.py --judge` 复核 PASS），产出
  `doc/evidence/v0.4.0/M4-coverage-baseline.md`：六类基线（17 场景合并）
  = LINE 80.85 / COND 71.20 / TOGGLE 47.66 / FSM 7.14 / BRANCH 82.94 /
  ASSERT 78.88，并按 spec §0#4 命名模块逐实例给出细分表 + 6 条最具体缺口
  （`axi_atop_filter` FSM 5/7 状态从未覆盖，根因 stimulus 只构造过
  `ATOP_LOAD_ADD` 一种编码；`addr_decode`/`axi_demux` 四类结构性空白；
  `axi_xbar` 顶层 toggle 仅 29.63%；`default_aw_mst_port(_en)` assert
  real-succeeded 恒 0 对照 AR 侧 48；`axi_mux` AW 锁定重试路径 8 实例全
  未覆盖）
- **登记 BUG-0037（OPEN，TB）**：`vcs-2018.mk` 的 `CM := ... -cm_dir
  $(OUT)/cov.vdb` 用 `:=` 在 include 时提前展开，`sim/Makefile` 的
  M3-CF01~04 per-config `override OUT` 改不动已展开字符串 ⇒ 4 个不同
  拓扑配置点与 `upstream_sanity`/`tb_top` 系列全部静默写入同一
  `out/cov.vdb`（825 行 `UCAPI-INSTANCEMISMATCH` + 2971 行 `CMR-VCINF`）；
  功能判决不受影响，仅污染覆盖率数据库可信度；DV 未越权修改
  `sim/Makefile`/`vcs-2018.mk`，留 OPEN 待 orch 另派修复卡
- **登记 BUG-0038（OPEN，spec）**：spec §0#4 命名 `addr_decode`/
  `axi_demux` 为强制覆盖范围模块，但读 RTL 确认二者均为纯透传 wrapper
  （真正逻辑在未被明文列出的 `addr_decode_dync`/`axi_demux_simple`），
  Line/Cond/Branch/Assert 四类结构性空白——需 rev 仲裁"等"字兜底是否已
  覆盖这两个子模块
- **并行派发（Opus，独立于 M4 覆盖率卡，非里程碑门禁）**：UVM 框架可读性/
  可维护性人工评审，产出 `doc/code-suggestion.md`——只读不改代码，四维度
  （可读性/可维护性/结构合理性/逻辑清晰度）逐条给出文件路径+行号+改动
  性质（是否触碰判决），按性价比排出优先级；orch 逐条抽查行号引用（如
  `m_probe` 静态句柄、`default_aw_mst_port` assert 数字）确认非臆造；
  未发现新 taxonomy 异常
- **orch 独立复核**：`make check`（docs-check passed，chain audit 既有
  缺口数字不变）+ `make selftest`（61 tests）通过；核对两张卡的 `git
  status --short` 改动范围均与各自交付报告一致

**Not done**
- BUG-0037/BUG-0038 均未修复/仲裁——本卡只测量+登记，处置顺序留给 orch
  下一步分诊
- M4 六类是否达到 ≥90%、哪些缺口值得专门派卡填、`axi_atop_filter` 的
  ATOP 编码多样性缺口是否值得单独一张场景卡——均未决策，留待下一步
- `doc/code-suggestion.md` 的建议是否落地、落地哪几条——均未决策

**Next**
- 分诊 BUG-0037（覆盖率数据库合并机制缺陷，改 `sim/Makefile`/
  `vcs-2018.mk`，需走正常 fix 卡）与 BUG-0038（spec 措辞仲裁，走 rev）
- 决定是否派场景卡补 ATOP 编码多样性（AtomicStore/AtomicCompare 类），
  以填 `axi_atop_filter` FSM 缺口——这是当前六类基线里最大的单一缺口
- 决定 `doc/code-suggestion.md` 里"纯注释/纯激励/纯编排、零风险"的几条
  建议（payload helper / vseq 扇出基类 / scoreboard 流程图注释）是否
  现在派 L0/L1 卡落地

**How verified**
- `make check` 绿；`make selftest`（61 tests）通过
- 覆盖率基线的 22 次独立 `make run` 均逐条 `svacheck.py --judge` 复核
  PASS（非汇总口径）；orch 抽查 `doc/code-suggestion.md` 引用的具体行号/
  代码片段与仓库实际内容一致

## [0.4.0] 2026-07-30 M3→M4 里程碑转段（`make bump minor=1`），M4 出口条件订正

**Done**
- **`make next` 机械推导**：M3 四条机器硬条件均已满足 → 执行
  `make bump minor=1`（0.3.21 → 0.4.0，进入 M4）
- **`doc/milestone.md` 记账更新**（orch 直接维护，纯 bookkeeping，非技术
  制品）：M3 标题 🔲→✅，签核指针改为具体文件
  `doc/evidence/v0.3.20/signoff-M3.md`（含 0.3.21 closer 追加的 §八）
- **M4 出口条件措辞订正**：原文"line/toggle/branch/condition/fsm/
  **functional** 六类 ≥90%"与 `doc/spec.md` §0 #4 钉死的口径
  `line+cond+fsm+tgl+branch+**assert**`（VCS `-cm` 六个类型关键字，不含
  functional covergroup）不一致——该口径已由 **REV-011 §3.3** 明确裁定
  （"M4 机器判据接不住 covergroup"，即 BUG-0018 定档 M3 而非 M4 的依据），
  本卡只是把 milestone.md 的陈旧措辞订正为与已裁决事实一致，**非新解释**。
  订正后同时补一行："functional covergroup 非空转仍按既有 rubric 人工抽查
  把关，不受六类机器口径约束"，避免误读为"M4 不需要看 covergroup"
- **发现 git tag 命名撞车**：本地 `git tag -l` 显示 `v0.4.0`~`v0.8.0`
  已被 `upstream`（iverif-workflow 框架）远端的发布 tag 占用（`git fetch
  upstream` 拉取所得，`git merge-base --is-ancestor v0.4.0 HEAD` 为否，
  证实其与本项目历史无关）；而本项目自己的里程碑 tag（`v0.1.0`/`v0.2.0`/
  `v0.3.0`，均 `--is-ancestor HEAD` 为真）恰好在早期版本号上未撞车、侥幸
  留存。本次要打的 `v0.4.0`（M3→M4 转段）与框架的
  `v0.4.0`（"lean-and-turnkey overhaul"）撞名——**未打 tag**，留待用户裁决
  命名方案（例如加前缀区分，或本项目改用 `doc/status.jsonl`/`version.json`
  作为唯一版本真相、不再打本地 tag）

**Not done**
- git tag 命名冲突尚未解决，本次转段**未**执行 `git tag v0.4.0`
- M4 实质工作（六类覆盖率基线测量、缺口分析）尚未开始，留给下一张派发卡

**Next**
- 派 DV 卡（L1/sonnet）：`make regress COV=1` 全量重跑 + `make cov`
  生成 urg 报告，测出六类（line/cond/fsm/tgl/branch/assert）当前基线
  百分比与差距最大的模块/条目，作为 M4 缺口分析的起点（纯测量，不做修复）
- 待用户对 tag 命名冲突给出裁决后再补打 tag（或改用其他版本追踪方式）

**How verified**
- `make check`（非里程碑）docs-check passed，chain audit 既有缺口数字不变
- `make selftest`（61 tests）通过

## [0.3.21] 2026-07-30 closer 独立复验+收口 BUG-0036，M3 里程碑完整签核成立

**Done**
- **closer 卡（fresh 独立实例，非修复卡，DV/sonnet/L1）**：独立复验 0.3.20
  BUG-0036 修复（`4d712f9`：`sim/regress/regress.list` 补入
  `m3_cfg02_reconfig_test 1`）——亲跑 `make run TEST=m3_cfg02_reconfig_test
  SEED=1`（UVM_ERROR=0、SB 全 mismatch=0、2143 assertions 0 failures、
  `c_bug31_livev1_aw/ar` 六实例各 1 match）+ `make regress`（22/22 PASS）+
  证据链核对（`doc/evidence/v0.3.20/M3-CFG02.log` 首行即重放命令），未采信
  修复卡 `## rerun` 段的转述数字
- **BUG-0036 收口**：`make evidence BUG=BUG-0036 CMD='make regress'
  EXPECT='22/22'` 机械生成 `doc/evidence/v0.3.20/BUG-0036.log`，
  `doc/bugs.md` 行 status 转 `CLOSED`、`fix_commit=4d712f9`；
  `doc/bugs/BUG-0036.md` 追加「closer 收口」子节记录独立复验过程
- **KILL-0003 转录准确性核对**（C2）：对照 `doc/bugs/BUG-0034.md`
  `## rerun` 段两次独立红→绿注伤自证，逐字核对 `doc/bugs.md` KILL-0003
  行的四路数字/样本报文/证据路径，确认转录无误；未重新做 KILL 实验
- **`doc/evidence/v0.3.20/signoff-M3.md` 追加 §八「C1/C2 兑现记录」**
  （一至七节 rev 原文未改动，本卡只追加）：按 rev 终裁段预授权的机械路径
  确认 C1（BUG-0036 CLOSED）与 C2（KILL-0003 入台账）均已兑现，未重开任何
  功能验证、未新增 spot-check 判定
- **orch 独立复核**（本次收尾，不同于 closer）：亲跑 `make check
  MILESTONE=3`（4 条机器条件全 `[PASS]`：全 M3 场景 ✅、regress 摘要登记、
  bug 终态/证据、KILL 覆盖率 ≥1 条 M3 标签）+ `make selftest`（61 tests
  OK）+ diff 核对 closer 改动范围（`doc/bugs.md`/`doc/bugs/BUG-0036.md`/
  `doc/evidence/v0.3.20/signoff-M3.md` 仅追加、`doc/evidence/v0.3.20/
  BUG-0036.log` 新增），未采信 closer 的自我报告
- **M3 里程碑完整签核成立**：五张 M3 执行卡（CF01-04+AT02）+ 4 个配置点 +
  DE01/DE02/OR04/OR05/TL01/CFG02 共 11 条场景全绿 + BUG-0010/0011/0012/
  0013/0016/0018/0021/0023/0024/0025/0028/0031/0032/0033/0034/0036 全部
  终态或已接受 + KILL-0001/0002/0003 三条注伤自证 + rev 签核记录齐备

**Not done**
- M4（六类功能覆盖率收敛 ≥90%）尚未启动，待用户确认后再排期；BUG-0018
  cross bin 待 M4 重采；lint baseline 285+ 条装饰性告警持续差分中
- chain audit 既有记账缺口（M0-01 缺 spec_ref、8 处父节点锚定、10 个未
  引用 spec 子节、22/22 evidence 缺 spec_ref header）本卡未触碰、未变化

**Next**
- 若用户确认推进：scope M4（六类覆盖率收敛）为下一里程碑；否则等待用户
  下一步指示

**How verified**
- `make check MILESTONE=3` 全绿（4 条机器条件 PASS，signoff 文件存在）
- `make selftest`（61 tests）通过
- closer 与 orch 两次独立复跑 `make run TEST=m3_cfg02_reconfig_test
  SEED=1` / `make regress`，数字逐位吻合，非采信

## [0.3.20] 2026-07-30 落地 M3-TL01：BUG-0010 跨桶定向回归守卫，M3 testplan 全绿

**Done**
- **DV 场景卡（L1/sonnet，fresh 实例）落地 `M3-TL01`**：单 slave 端口构造
  2 个不同低位 ID 桶（低 `AxiIdUsedSlvPorts=3` 位互不相同），同方向背靠背
  各压 10 笔（合计 20 > `MaxMstTrans=10`，仍在结构有效上限 15 之内，
  BUG-0016 口径），两桶经同一 `axi_burst_item` 拼接后一次性 `drive_burst`
  发出、无逐项等待，确保真正并发在飞而非先后填充
- **判据 (1) 判决锚点**：scoreboard 路由/数据/响应/完成全绿，零 mismatch，
  证明 DUT 在该合计规模下合法全部接受、无非预期停顿或拒收——**DUT 未表现
  为扁平**，BUG-0010 分桶口径由"文档信任"实证升级为"波形经验确认"，未
  触发对 demux.md 的 DUT_BUG/文档-实现分歧复核
- **判据 (2) 达标覆盖**：新增非判决 covergroup `cg_xbucket_total`
  （`tb/functional_coverage.sv`），由 scoreboard 既有 `or_open_q` 逐桶表
  （`cg_tx_limit` 同源，非二次解码）在 `write_slv_req_accept` 处求和触发，
  仅当"合计 > `Cfg.MaxMstTrans`（pinned spec 参数，非 RTL 观测值）且 ≥2
  桶同时非空"时采样——命中 samples=20 inst_cov=100%。未新增/修改任何
  assert（BUG-0016 红线：判决性上限仍只准锚定 spec 公式导出的有效上限，
  非本卡范围）
- **BUG-0028 checklist**：`sim/regress/regress.list` 追加
  `m3_tl01_xbucket_test`；全回归 **21/21 PASS**
- **evidence**：`doc/evidence/v0.3.19/M3-TL01.log`（`make evidence
  SCEN=M3-TL01 TEST=m3_tl01_xbucket_test SEED=1`），testplan 行由
  evidence.py 机械回填 🔲→✅

**Not done**
- M3 里程碑收尾（`make check MILESTONE=3` + rev 全 rubric，须显式引用
  REV-015 residual risk 披露）与 lint-baseline 重生成——testplan M3 现已
  11/11 全绿，可以着手评估签核前置条件，留给下一张 L3 signoff 卡
- `make check` 既有记账缺口（M0-01 缺 spec_ref、8 处父节点锚定、10 个未引用
  spec 子节、22/22 evidence 缺 spec_ref header）本卡未触碰、未变化

**Next**
- M3 里程碑签核卡：`make check MILESTONE=3` + rev 全 rubric + lint-baseline
  重生成
- 五条不变量 KILL 记账核对（M3 内已有 BUG-0033/BUG-0034 两次 KILL，签核卡
  按 `make check MILESTONE=3` 条件 4 复核是否满足"每 milestone 每类
  checker 至少一次"）

**How verified**
- `make run TEST=m3_tl01_xbucket_test SEED=1` PASS（0 UVM_ERROR/FATAL，自然
  结束）；`make regress` 21/21 PASS；`make evidence` 生成证据文件、
  `make check` chain audit 干净（无新增 dangling/gap，既有缺口数字不变）；
  `make selftest`（60 tests）通过

## [0.3.19] 2026-07-30 closer 独立复验+收口，BUG-0034 全链路终结（诊断→REV-015→修复→CLOSED）

**Done**
- **closer 卡（fresh 独立实例，非修复卡）**：独立重跑回归防线（5 个相邻
  场景）+ 本条核心场景 `m3_at02_atop_read_test`（多拍构造）+ 独立做一遍
  KILL 自证（手法与修复卡不同：折叠 monitor `rid` + SVA 三处 per-id key
  为常量，而非修复卡的具体折叠方式）——红→绿数字与 `## rerun` 记载基线
  **逐位吻合**；亲读修复后代码确认 BUG-0015 红线守住（per-id 状态只在
  `always_ff` 内读写，无 property/cover 直读）。全回归 20/20 PASS
- **状态判断（closer 自主完成，非机械操作）**：核对 BUG-0031 先例（同为
  TB 性质、代码修复、独立复验后终态是 `CLOSED`+`fix_commit`，非停留字面
  `TB_BUG`）+ REV-015 自身安排"由非修复者跑 make evidence 收口"，判定
  **CLOSED 才是本条修复完成后的恰当终态**——REV-015 的"终态改判 TB_BUG"
  指 taxonomy 定档，非状态字段冻结
- **发现并妥善处理一处自动化空档**：BUG-0034 的行此前已因 `TB_BUG` ∈
  `BUG_DONE_STATES` 被 `make archive` 归档（修复落地前即被视为"终态"扫入
  归档），`make evidence` 找不到 live 表里的行而报错（证据文件本身已
  正常生成，只是 `update_row` 失败）。closer 未强行 un-archive 走完整
  机械路径（那属记忆系统维护、orch `make` 范畴），而是就地把归档行的
  `status`/`fix_commit`/`verify_evidence` 三列手工回填为
  `make evidence` 本该写入的值——不是编造数据，只是把已经真实产生的
  结果落到正确位置，如实上报供 orch 复核
- **BUG-0034 终态**：`status=CLOSED`、`fix_commit=d7f5011`、
  `verify_evidence=doc/evidence/v0.3.18/BUG-0034.log`。至此 BUG-0034
  的完整链路（三工具诊断 → REV-015 独立仲裁否决 DUT_BUG candidate、改判
  TB_BUG → 独立 TB 修复卡 → closer 独立复验收口）走完，全程 fixer/closer/
  诊断/仲裁四个环节均为不同实例，无一次自我认证

**Not done**
- lint-diff 基线陈旧问题（closer 独立复现，与 fixer 观察一致，非本轮
  改动引入）仍未处理——留给 M3 签核卡按 BUG-0021 既定纪律重生成基线
- 本次 doc 改动（archive 行 + 详情页 + evidence 文件）尚待本次 closeout
  提交；修复本身（`d7f5011`）已在此前提交推送

**Next**
- **M3 里程碑收尾**：`make check MILESTONE=3` + rev 全 rubric——五张
  M3 执行卡序列 + BUG-0034 全链路均已完成，可以着手评估里程碑签核前置
  条件；须显式引用 REV-015 的 residual risk 披露（守卫已落地，签核卡
  复核确认解除）+ lint-baseline 重生成

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap）
- `make selftest`（60 tests）通过
- KILL 自证独立复现两次（fixer 一次、closer 一次，手法不同），数字均
  与 BUG-0034 记载基线逐位吻合，非巧合

## [0.3.18] 2026-07-30 BUG-0034 TB 修复落地：R burst 重建改按 r_id 逐拍分流

**Done**
- **卡⑧（DV fixer，L2，独立于诊断/落地实例）**：按 REV-015 要求修复
  BUG-0034——`tb/slvport_agent.sv` 的 UVM monitor R burst 重建由单槽
  `r_busy`/`r_cur` 状态机改为按 `id_slv_t` 索引的关联数组（可并发跟踪
  多个不同 r_id 的 burst）；`tb/sva/axi_chan_sva.sv` 的 `SVA_RLAST_LEN`
  同步改为按 r_id 索引的 beat index/期望长度（atop 影子读的期望长度改
  从其自身 AW handshake 取，而非依赖不存在的 AR）。全部 per-id 状态只在
  `always_ff` 内读写、判决点为 immediate assert，不违反 BUG-0015（无
  property/cover 直读 always_ff 状态）；未引入"断言交织不该发生"的判决
  （spec §5.5.4 红线）；`scoreboard_refmodel.sv` 判决本体未改动（只读
  核实 `SB_RBEATS` 依赖上游重建、monitor 修好后自动对齐）
- 恢复 `tb/seq_lib.sv` `slvport_at02_seq` 多拍构造（leg A `p.len` 改回
  `len_t'(3)`），`m3_at02_atop_read_test` 复跑：四路 checker 全部归零、
  UVM_ERROR=0，M3-AT02 三条判据（含 `colliding_read_present` 达标 cover）
  在多拍构造下依然满足
- **KILL 自证（regression_guard 要求）**：临时去掉两处新增的 r_id 分流，
  同 TEST+SEED 重跑，四路 checker 精确复现 BUG-0034 记载的基线数字
  （`MON_RNOAR`=2/`SVA_RLAST_LEN`=3/`SB_RBEATS`=3/`SB_ATOP_DANGLING`=2，
  UVM_ERROR=8）；恢复分流后再次归零。红→绿闭合，证明这四个 checker 确实
  能对该条件见红，非恒真空转。KILL 临时改动已全部还原
- 回归防线（改动落地后、验证本条前）：既有非交织场景逐位对照改动前
  快照一致；全量 `make regress` = 20/20 PASS
- `doc/bugs/BUG-0034.md` 的 `## fix`/`## rerun`/`## regression_guard`
  三段按落地情况做记录性更新（非状态转换，closer≠fixer：状态字段仍是
  REV-015 终判的 `TB_BUG`，未被 fixer 触碰）

**Not done**
- BUG-0034 尚未走独立 closer 复验 + `make evidence` 收口（fixer 不得
  自己关闭）
- fixer 观测到 `make lint-diff` 在**未改动的干净 master** 上对某些 UVM
  test 即报新站点（本卡改动只贡献同文件既有风格类的行号平移，无新类别）
  ——未新开 bug 行（fixer 主动避免越权/状态漂移），提请 orch 裁决是否
  与 BUG-0021 已记载的"lint baseline 里程碑内正常漂移、签核时重生成"
  同属一事；本轮判断：是同一现象，不新开行，留给 M3 签核卡处理

**Next**
- 派 closer 卡：独立复验修复（含独立重跑 KILL 自证，不采信 fixer 数字）、
  确认无误后填 fix_commit、`make evidence BUG=BUG-0034 ...` 收口
- M3 里程碑收尾：`make check MILESTONE=3` + rev 全 rubric，引用 REV-015
  的 residual risk 披露（守卫落地后应已解除，签核卡复核确认）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap）
- `make selftest`（60 tests）通过
- KILL 自证红→绿数字与 BUG-0034 记载的原始基线逐位吻合，非近似值

## [0.3.17] 2026-07-30 5 个 M3 covergroup 落地；BUG-0034 三工具诊断→rev 否决 DUT_BUG、改判 TB_BUG

**Done**
- **卡⑥（DV，L2）**：落地 `doc/design-prompt/functional_coverage.md` §4
  规划、`functional_coverage.sv` 此前未实现的 5 个 M3 covergroup
  （`cg_decode_error`/`cg_decerr_shape`/`cg_miss_order`/
  `cg_default_port_tracked`/`cg_live_addr_map`）——按用户明确原则，真正
  实现而非走"文档指向已有 SVA cover"的捷径；两个与既有 `stall_sva.sv`
  SVA cover（`c_bug25_default_*`/`c_bug31_livev1_*`）重叠的项，接的是
  同一信号事实源（桥接静态句柄 `m_probe`，喂入已折叠的 always_comb/wire
  事实，BUG-0015 安全），不重复实现判断逻辑；判决 assert/property 条件
  零改动。回归防线逐位对照 HEAD 通过；全回归 20/20 PASS。副产物登记
  **BUG-0035**（TOOL_ENV，回归防线期间手工 stash+增量编译触发
  `VFS_ZLIB_ERROR`，clean rebuild 不复现，同 `scripts/regress.py` 已知
  VFS_SDB_ERROR class；orch 收卡时发现该卡自行设成 CLOSED——违反
  closer≠fixer 且证据列不合规，改判 **WONTFIX**，对齐 BUG-0017/BUG-0030
  同类先例）
- **卡⑦（DV 诊断卡）**：对 BUG-0034 用 xdebug（改用 `event.export`，
  非上一轮踩坑的 `value.at`）+ xwave（独立实现交叉核对）+ xtrace（RTL
  因果）三工具诊断，物理层证据扎实（两个独立 FSDB 解析器逐拍一致：id0
  4 拍、id8 单拍插入其中）——但**诊断卡自己给出的 taxonomy 结论（DUT_BUG
  candidate）经 rev 独立复核被否决**（见下）
- **rev 卡 → REV-015**：独立复核 100% 采信诊断卡的 RTL/波形观测，但指出
  其援引的"spec §1/§5.5.3 禁止读交织"在 spec 钉定本中**不存在**——真实
  条款只在 §5.5.1 禁 **W** 通道交织，R/响应侧 §5.1.4 + 上游
  `axi_mux.md:18` **明文允许**不同完整 ID 响应交织（框定为性能特性），
  §5.5.4 明文禁止 checker 断言 round-robin 发生序。逐拍代入诊断卡自己
  的表格，证明四路"证据"是 `slvport_agent.sv` monitor 与 `axi_chan_sva`
  bind SVA **共模同一"R 永不交织"重建假设**在合法交织下的必然误报，非
  DUT 协议违反；物理层收发计数全对、无数据丢失。**taxonomy 改判
  TB_BUG，不发起上游 issue、不走 P-xxx**——DUT 行为与其自身上游文档
  （`axi_demux.md` §Atomic Transactions 原文承认此交互"额外假冲突
  stall"，从未框定为正确性问题）一致，二者无矛盾
- `doc/bugs/BUG-0034.md` 按 fl_schema_enforce 的英文标准 section
  （symptom/first_anomaly/taxonomy/rca/fix/rerun/regression_guard/
  similar）重新组织（原文件全用中文自定 header，状态转终态后触发
  schema 检查失败，趁此机会订正结构，内容无损）

**Not done**
- BUG-0034 修复（r_id 感知的 R burst 重建）未派发——按 REV-015 要求须
  独立 TB 修复卡（不与诊断/落地同链），随后由非修复者复跑收 evidence
- 遗留的 M3-AT02 多拍交织覆盖缺口尚未在任何签核记录里正式披露（REV-015
  Item 4 要求 M3 签核时须记 residual risk 或 `ACCEPTED@M<n>`）

**Next**
- 派独立 TB 修复卡：`tb/slvport_agent.sv`/`tb/sva/axi_chan_sva.sv` 的 R
  burst 重建改按逐拍 r_id 分流；修复后恢复 M3-AT02 多拍两腿复跑转绿，
  regression_guard 由非修复者收口
- M3 里程碑收尾：`make check MILESTONE=3` + rev 全 rubric，须显式引用
  REV-015 的 residual risk 披露

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap；
  `doc/bugs/BUG-0034.md` schema 校验通过）
- `make selftest`（60 tests）通过
- rev 独立复核的方法学价值：证明"三个工具观测一致"不等于"观测解读正确"
  ——这正是派发 REV-015 时特意提醒的陷阱，实测命中

## [0.3.16] 2026-07-30 卡⑤（五张 M3 执行卡收官）：M3-CF02/03/04+AT02 转绿

**Done**
- **卡⑤（DV，L2，升级自原计划 L1）**：复用卡④建的多配置构建机制，扩展
  `xbar_types_pkg.sv`/`sim/Makefile` 补齐 cfgB/C/D 三个配置点（`UniqueIds`/
  `ATOPs`/`Connectivity`/地址表覆盖维度接入选点机制）；`tb/functional_
  coverage.sv` 新增 `cg_cfg_point`（design-prompt functional_coverage.md
  §4 规划、义务范围内的唯一一项，其余四个 M3 covergroup 明确留在范围外）。
  落地并转绿四条 testplan 行：**M3-CF02**（cfgB 6×1+`CUT_ALL_PORTS`）、
  **M3-CF03**（cfgC 4×4+`UniqueIds=1`，env 侧 `SB_UNIQUEIDS` 兜底监视）、
  **M3-CF04**（cfgD 4×4+稀疏 `Connectivity`+`ATOPs=0`，按 tb_top.md C5.7
  逐字构造）、**M3-AT02**（ATOP 跨方向假冲突守卫）。基线+cfgA 回归防线
  在验证新场景前先行核对，逐位一致（C5.4 持续成立）。全回归 20/20 PASS
- **KILL-0002**：为 cfgC 的 `SB_UNIQUEIDS` 兜底监视做注伤自证——植入
  §5.3.1 违例（同完整 ID/同方向/异目标 master 端口）→ 红
  （`violations=1`）→ 撤销 → 绿，证明该监视器非恒真空转
- **新发 BUG-0034（OPEN，DUT/TB 未决，不阻塞）**：M3-AT02 构造多拍两腿
  重叠时，slave 端口 R 通道四路独立证据（`MON_RNOAR`/`SVA_RLAST_LEN`/
  `SB_RBEATS`/`SB_ATOP_DANGLING`）同时命中，疑似 atop 影子读 R 与同桶
  普通读 R 交织（AXI4 §1 禁止读交织）；`r_ready` 恒 1 排除背压，xdebug
  `signal.changes` 显示同一连续 `r_valid` 块内 `r_id` 跳变 3 次，是交织
  的结构性证据。**DUT_BUG（真交织）vs TB_BUG（monitor/SVA 无交织重建
  缺口）未决**——需波形逐 beat decode `r_id`/`r_last` 定性，本卡 `value.at`
  在该 FSDB 上返回 unknown，未能落定，留待专卡。本卡**合法绕过**：
  M3-AT02 改单拍两腿，§6.5 假冲突仍真实发生、三条判据完整满足，不阻塞
  M3；未在判决本体加临时补丁、未把观测行为抄成期望值

**Not done**
- BUG-0034 定性未决（需要 xdebug 更细粒度取证或 Verdi 波形逐 beat decode，
  留待独立诊断卡）
- 遗留四个 M3 covergroup 缺口（`cg_decode_error`/`cg_decerr_shape`/
  `cg_miss_order`/`cg_default_port_tracked`/`cg_live_addr_map`，早于本次
  五卡序列即存在，design-prompt 已规划但 `functional_coverage.sv` 未实现）
  ——非本卡引入，留给独立记账/整改卡
- cfgC 的 §5.3.1 前置保证目前靠单发（single-outstanding）构造性满足；
  若 M4 需要多发在飞需补集中式 ID 分配器（fixer 交付报告已记）

**Next**
- **五张 M3 执行卡序列至此全部完成**（①②③④⑤ + 各自 closer/rev 支线）。
  剩余 M3 收尾项：BUG-0034 定性（独立诊断卡）、四个遗留 covergroup 缺口
  （独立整改卡）、M3 里程碑签核（`make check MILESTONE=3` + rev 全 rubric）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap）
- `make selftest`（60 tests）通过
- 全回归 20/20 PASS（基线 + cfgA + 卡①②③④已交付场景 + 本卡四场景）

## [0.3.15] 2026-07-30 卡④：M3 多配置构建机制落地 + M3-CF01（cfgA）转绿

**Done**
- **卡④（DV，L2）**：落地 `doc/design-prompt/tb_top.md` §5 C5.1-C5.6 的多
  配置构建机制——`tb/xbar_types_pkg.sv` 把硬编码的 `NO_SLV_PORTS`/
  `NO_MST_PORTS`/`LatencyMode` 等改为按编译期宏（`` `ifdef``/`` `elsif``）
  选点，缺省（无宏）逐位等于今日基线（C5.4）；`sim/Makefile` 建立
  `TEST` 名 → 配置点宏 + 独立 `OUT` 子目录（`out/cfgA/`）的映射，基线
  `TEST` 的产物路径/`-l` 目标不变（C5.1/C5.2）；仿真开头新增
  `[CFG_REPORT]` 自报生效的完整 13 字段 `Cfg` + `ATOPs` + `Connectivity`
  + 地址表（C5.3）；`scoreboard_refmodel.sv`/`axi_xbar_worder_sva.sv`/
  `axi_xbar_txlimit_sva.sv` 的 ID 前缀改为移位表达式 + `PREFIX_SW=
  max(PREFIX_W,1)` 存储宽，支持 `NoSlvPorts=1` 的 0 位前缀退化（C5.6）
  不触碰 `scripts/make/vcs-2018.mk`（上游 pinned，C5.1/C5.2 全在
  `sim/Makefile` 本地层解决，无需 fw-feedback）
- 落地 **M3-CF01**（cfgA：1×8 拓扑 + `LatencyMode=NO_LATENCY`），
  `m3_cf01_cfga_test` 转绿：route/resp/resp-route 零失配、decode error
  应答正确、`[CFG_REPORT]` 确认 `PREFIX_W=0`/`Connectivity=0xff`/
  `LatencyMode` 全 0
- **C5.4 基线不变验证（fixer 自证 + orch 独立复核）**：fixer 用
  `git stash` 隔离本卡改动后在 HEAD 重跑关键场景做逐位对照，确认零影响；
  orch 落盘前额外直接核查 `sim/out/simv` 与 `sim/out/cfgA/simv` 是**两个
  独立文件**（非共享产物），佐证 C5.2 落地属实，非文档声明
- 全回归 16/16 PASS（含新场景）；`make check`/`make selftest` 绿

**Not done**
- 机制目前只路由了 cfgA 实际用到的三维（NoSlvPorts/NoMstPorts/
  LatencyMode）；cfgB/C/D 还需要的 UniqueIds/ATOPs/Connectivity/地址表
  覆盖维度尚未接入选点机制——留给卡⑤在同一 `` `ifdef`` 块内补齐
  （fixer 已在交付报告里列出各配置点的坑，见卡⑤派发依据）
- lint-diff 相对冻结基线新增 20 个站点（全部风格类、行号平移导致，非
  新类别）——按 BUG-0021 WONTFIX 载体的既定纪律，属里程碑内正常漂移，
  留给 M3 签核卡重生成基线，非本卡范围
- 五张 M3 执行卡序列中，⑤仍未派（M3-CF02/03/04 + M3-AT02）

**Next**
- 卡⑤：M3-CF02/03/04 + M3-AT02（L1，复用卡④机制，需先补齐 UniqueIds/
  ATOPs/Connectivity/地址表覆盖维度的选点分支）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap）
- `make selftest`（60 tests）通过
- 高风险项（C5.2 产物隔离、C5.4 基线不变）均有独立于 fixer 自述的核验：
  fixer 的 git-stash 隔离对照 + orch 直接核查两份 simv 物理独立

## [0.3.14] 2026-07-29 closer 独立复推 cp_stall_state 论证一致，BUG-0018 转 CLOSED

**Done**
- **closer 卡（fresh 独立实例，非卡③ fixer）**：独立重跑 M2-OR01/M2-WO01 +
  15 场景全回归，全 PASS、UVM_ERROR=0；历史守卫（M2-OR03 的 collide/
  stack_diff/w_lost/r_lost 系列）字节级未受判决输入管线改动影响
- **独立重新推导 cp_stall_state 几何论证**（不采信 fixer 结论，从
  `cg_stall` covergroup 定义 + `stall_cls` 赋值逻辑 + M2-OR01 激励构造
  逐步重推）：确认 `cp_stall_state` 只有 3 个 bin（SC_STALLED/SC_SAME_TGT/
  SC_DIFF_DIR），M2-OR01 的构造（同方向、不同目标 master 端口）结构性只能
  触达 SC_STALLED 一类，天花板即 33.33%、且读腿在修复前已达标——**closer
  独立复核后与 fixer 结论一致**：REV-011 §3.3 该子句对 M2-OR01 几何不可达，
  实质判据是 `x_state_dir[stalled][write]`（已由空转非空达标）。订正写入
  `doc/bugs.md`/`doc/bugs/BUG-0018.md`
- 填 `fix_commit=7a1c912`（`git show --stat` 核实确含三份修复文件），
  `make evidence BUG=BUG-0018 TEST=m2_or01_stall_test SEED=1` 一次通过，
  **BUG-0018 转 CLOSED**

**Not done**
- 五张 M3 执行卡序列中，④⑤仍未派（多配置基建 + M3-CF01；M3-CF02/03/04 +
  M3-AT02）

**Next**
- 卡④：多配置基建 + M3-CF01（L2，须先于⑤）→ ⑤ M3-CF02/03/04 + M3-AT02（L1）

**How verified**
- `make check` 绿（docs-check passed；无 terminal rows/blocks 溢出，未跑
  archive）
- closer≠fixer 落地形态：关闭实例独立重跑+独立推导，未采信任何转述数字或
  结论，最终结论与 fixer 一致但过程完全独立

## [0.3.13] 2026-07-29 卡③：BUG-0018 修复落地——scoreboard 增 AW/AR 接受事件流，M2-OR01/WO01 覆盖率转绿

**Done**
- **卡③（DV fixer，L2）**：落地 BUG-0018——`tb/slvport_agent.sv` 新增一路
  payload-free 的 `req_accept_ap`，在 AW 接受（写）/ AR 接受（读）当拍即
  发布，与现有携带完整 wdata/wstrb、在 `w_last` 才发布的 `req_ap` **并存**
  （不删除、不改语义）；`tb/scoreboard_refmodel.sv` 新增
  `write_slv_req_accept` handler，把 `or_open_q`/`worder_pend` 注册与
  `stall_cls`/`sample_tx_limit` 采样从"迟到的 w_last"搬到"真实的 AW/AR
  接受时刻"，§5.2.3 完成序判决本体、`accept_time`/`or_key` 语义均未改动；
  `tb/xbar_env.sv` 接线新 analysis port。刷新 M2-OR01/M2-WO01 证据
  （`make evidence` 对已 ✅ 场景的重新注册验证生效）
- **实测结果**：`x_state_dir`（M2-OR01）由 16.67%→**33.33%**，
  `[stalled][write]` 格由空转非空；`cp_w_contention`（M2-WO01）由
  50.00%→**100.00%**（`multi_source_contended` 精确填满）；两次运行
  `SB_SUMMARY` 均 `mismatch=0`、`UVM_ERROR:0`；全回归 15/15 + 交叉核对
  `m3_cfg02_reconfig_test` PASS；`m2_or03_guard_test` 历史见证（collide
  192/192、264/264，stack_diff 24/24，w/r_lost 456/162）字节级不变；
  `cg_tx_limit`（TL01 80.00%/TL02 53.33%）无回归
- **fixer 如实上报一处判据文字问题（未自行处置）**：REV-011 §3.3 原文
  "`cp_stall_state` 由 33.33% 上升"对 M2-OR01 **几何上不可达**——该场景的
  构造只触达 `SC_STALLED` 一个 stall class（无 `SC_SAME_TGT`/`SC_DIFF_DIR`），
  `cp_stall_state` 在此场景的结构性天花板本就是 33.33%（读腿在修复前就已
  达到），写腿补齐只会体现在更细的 `x_state_dir` 交叉 bin（已验证达标），
  不可能让粗粒度的 `cp_stall_state` 再往上"升"。fixer 未擅自改判据、未
  隐瞒，留给 closer 复核

**Not done**
- BUG-0018 状态未变（仍 `ACCEPTED@M3`，closer≠fixer，fixer 未动状态字段）
- REV-011 §3.3 的 `cp_stall_state` 子句需要 closer 复核确认后，在关闭记录
  里写明"几何不可达、以 x_state_dir/[stalled][write] 为实质判据"的订正
- 五张 M3 执行卡序列中，④⑤仍未派（多配置基建 + M3-CF01；M3-CF02/03/04 +
  M3-AT02）

**Next**
- 提交本次改动后派 closer 卡：独立复验（含亲自重新推导 cp_stall_state 的
  几何论证）、通过后走 `make evidence BUG=BUG-0018 ...` 转 CLOSED
- 卡④：多配置基建 + M3-CF01（L2，须先于⑤）→ ⑤ M3-CF02/03/04 + M3-AT02（L1）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap）
- `make selftest`（60 tests）通过
- 判决输入管线改动的回归面广：15/15 canonical regress + 4 条交叉核对场景
  全 PASS，历史 covergroup/SVA 见证（BUG-0023/0024/0027 相关）数值不变

## [0.3.12] 2026-07-29 卡②：BUG-0024 (b) 收窄 + M3-OR05 落地，closer 转 WONTFIX

**Done**
- **卡②（DV fixer，L2）**：落地 REV-011 §2.3 对 BUG-0024 的裁决——择路 (b)，
  收窄 `tb/sva/axi_xbar_stall_sva.sv` 的判决范围至"每完整 ID 至多一笔在飞"，
  N≥2 明文交给 `tb/scoreboard_refmodel.sv` C5.1/C5.2 每事务队列判据承担。
  `w_reorder()`/`r_reorder()` 新增独立于既有 §5.2.6 `is_err` 排除的 N≥2
  早退分支（复用既有 `w_n[]`/`r_n[]` 在飞计数，不新造机制），文件头注 +
  `doc/design-prompt/sva_bind.md` C3.2 补齐范围声明。落地 testplan
  **M3-OR05**（REV-011 §2.2 四步构造的定向证伪场景，读/写镜像跨多桶迭代）
- **closer 卡（fresh 独立实例）**：亲读代码独立复验 b-1~b-4——b-1 两处范围
  声明齐备；b-2 亲读 `w_reorder`/`r_reorder` 确认新排除分支真实存在且与
  `is_err` 排除并存不覆盖，独立重跑 `m3_or05_range_test`
  `SVA_OR_W_REORDER`/`R_REORDER` 命中 0；b-3 据实报出 `w_lost_now`=144、
  `r_lost_now`=138（范围边界被真实触达，非要求归零）；b-4 全回归 11/11
  PASS；另交叉核对 BUG-0023/0025/0031 共享同一函数的既有 cover 命中数未受
  扰动。四项齐备后**亲自**把 `doc/bugs.md`/`doc/bugs/BUG-0024.md` 转
  `WONTFIX`（范围声明为 rationale，引 REV-011 §2.3）——WONTFIX 不经
  `make evidence` 机制、不需要 `fix_commit`
- `make archive` 消化转态触发的终态行 5>4 溢出（bugs.md 归档 3 行、
  log.md/status.jsonl 各归档 1 块/1 行）

**Not done**
- 五张 M3 执行卡序列中，③④⑤仍未派（BUG-0018 修 + 重跑 M2-OR01/WO01；多
  配置基建 + M3-CF01；M3-CF02/03/04 + M3-AT02）

**Next**
- 卡③起严格顺序：③ BUG-0018 修 + 重跑 M2-OR01/WO01（L2）→ ④ 多配置基建 +
  M3-CF01（L2，须先于⑤）→ ⑤ M3-CF02/03/04 + M3-AT02（L1）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap；
  终态行数由 5 降至 archive 后的合规值）
- `make selftest`（60 tests）通过
- closer≠fixer 落地形态：转态实例（本卡 closer）与落地 (b) 修复的实例
  （卡②）分离，转态前逐条亲读代码 + 独立重跑，未采信 fixer 交付报告数字

## [0.3.11] 2026-07-29 closer-v2：填 fix_commit + 独立复验，BUG-0025/BUG-0031 转 CLOSED

**Done**
- **closer 卡（fresh 独立实例，非上一张 closer、非任何 fixer）**：上一轮
  closer 已确认 BUG-0025/BUG-0031 全部到期验收判据通过，但因修复代码当时
  未提交、`fix_commit` 空而被 `docs.py --check` 拦下机械关闭。0.3.10 commit
  `482a47e` 落定后，本卡先自行 `git log`/`git show --stat` 核实该 commit
  确含 `tb/sva/axi_xbar_stall_sva.sv`/`tb/sva_bind.sv`/
  `tb/scoreboard_refmodel.sv` 等修复文件（不盲信提示里的 sha），把
  `doc/bugs.md` 两行的 `fix_commit` 列由 `-` 填为 `482a47e`（只改此列）
- **独立重跑三条判据场景**（不采信任何转述数字）：`m3_or04_order_test`
  （BUG-0025 完整 ID + 桶级半边）、`m3_de02_default_test`（BUG-0025 default
  port 半边）、`m3_cfg02_reconfig_test`（BUG-0031 全部六条），逐条核对
  `## regression_guard` 点名的 cover 命中数（`c_bug25_default_aw/ar`
  0/2/4 端口各 1、`c_bug25_errbucket_aw/ar` 六端口各 1、`c_sib_diff_*`/
  `c_bug31_livev1_*` 六端口各 1、双向无假红），与详情页记载一致
- 执行 `make evidence BUG=BUG-0025 TEST=m3_or04_order_test SEED=1` /
  `make evidence BUG=BUG-0031 TEST=m3_cfg02_reconfig_test SEED=1`——两条
  命令均一次通过（`fix_commit` 已非空），机械回填 `CLOSED` +
  `verify_evidence`（`doc/evidence/v0.3.10/BUG-0025.log`、`BUG-0031.log`）

**Not done**
- 五张 M3 执行卡序列中，②③④⑤仍未派（BUG-0024 (b) 收窄 + M3-OR05；BUG-0018
  修 + 重跑 M2-OR01/WO01；多配置基建 + M3-CF01；M3-CF02/03/04 + M3-AT02）
- 本 commit 未触发 bugs.md 归档阈值（terminal rows 未 > 4），未跑
  `make archive`

**Next**
- 卡②起严格顺序：② BUG-0024 (b) + M3-OR05（L2）→ ③ BUG-0018 修 + 重跑
  M2-OR01/WO01（L2）→ ④ 多配置基建 + M3-CF01（L2，须先于⑤）→ ⑤
  M3-CF02/03/04 + M3-AT02（L1）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap）
- `make selftest`（60 tests）通过
- closer≠fixer 落地形态：关闭实例（本卡）与修复实例（0.3.10 各卡）分离，
  `fix_commit` 精确指向修复真正落盘的 commit

## [0.3.10] 2026-07-29 BUG-0025+0031 修复落地、BUG-0033 新发→REV-014 仲裁→应用，closer 卡查明关闭被 fix_commit 空挡住

**Done**
- **卡①（DV，L2）**：BUG-0025+BUG-0031 同卡修复落地——`tb/sva/axi_xbar_stall_sva.sv`
  三层译码未命中保序改造（default port 半边入表 / 完整 ID 半边纳入判决 /
  桶级半边显式排除引 §5.2.6）+ `tb/sva_bind.sv` 给该模块接入 `cfg_if` 活值
  地址表（参照 `axi_xbar_route_sva` 现成接法）；M3-CFG02 转绿。M3-DE01/DE02/
  OR04 首次仿真时浮出**新 SPEC_ISSUE：BUG-0033**（err_slv 译码错误读响应
  数据值与 spec §4.4 矛盾，doc-vs-RTL，同 BUG-0016 家族）——按纪律无条件
  登记、未抄 RTL 值入 checker、未派修复，交 rev 仲裁
- **rev 仲裁卡（fresh 独立实例，L3）→ REV-014**：BUG-0033 taxonomy 终判
  SPEC_ISSUE（**不改判 DUT_BUG**——错误响应 `RDATA` 协议上 don't-care，
  DUT 未违反任何显式条款，`RespData` 魔数为刻意设计常量），处置
  SPEC_CHANGED，提案 P-REV014-1：校正 spec §4 clause 4 为 err_slv 默认
  `RespData=64'hCA11AB1EBADCAB1E` 按 `AxiDataWidth` 零扩展/截断（**保持
  宽度参数化**——rev 追加核验发现原文档 L33 只在 32 位宽下恰好正确，不可
  硬编码成 64 位常量）。orch 应用：spec §4 clause 4 外科手术式改写 + change
  record #8 + 重 pin（新 sha `ad5bf8b7…6b3a2c`）；`doc/bugs.md`/
  `doc/bugs/BUG-0033.md` 回填裁决、状态转 `SPEC_CHANGED`；补齐详情页此前
  缺失的 `## regression_guard` 段（docs-check 一度因此报红，已修）
- **卡①.6（DV fixer，L2）**：`tb/scoreboard_refmodel.sv` 的 `ERR_RDATA`
  常量从 pinned spec §4.4 推导校正（不引 RTL 行号），转绿 M3-DE01/DE02/
  OR04；按 CLAUDE.md 不变量 5（本仓库 M3 起生效）做**注伤自证**——
  `KILL-0001`：植入缺陷（高 32 位改回 0）→红（12/3/18 处，落 BUG-0033.md
  §scope 基线区间）→恢复→绿；`sim/regress/regress.list` 补录三行
- **closer 卡（fresh 独立实例）**：独立复验 BUG-0025（三层判据）+ BUG-0031
  （六条判据），逐条核对 cover/assert 命中数（不采信任何转述），**技术判据
  全部通过**；执行 `make evidence BUG=BUG-0025 ...` 时被 `docs.py --check`
  的 `fix_commit` 空值硬门拦下（此前全部修复尚未提交，无 sha 可填）——
  closer 正确回退了这次误关闭尝试、清理孤儿 evidence 文件，**未强行绕过**，
  如实退回 orch
- 顺带：应用 REV-014 时同步 `doc/testplan.md` M3-DE01 crit(2) 措辞；根
  `Makefile` 新增 `help` 目标（列全部 16 个目标+用法，含 `evidence` 三种
  调用形式）+ `.DEFAULT_GOAL := help`（用户直接请求的构建层改动，未走
  dispatch，orch 自行完成并用 `make help`/裸 `make` 验证）；`git fetch
  upstream` 跟进框架仓库（新增 1 个纯文档提交，删除框架自己的
  `doc/VENDOR.md` 模板，与本仓库无关，仅推进移植基线指针至 `e23d938`，
  CLAUDE.md 已记）；`git pull` origin 三个已推送的文档提交（README 数据流图
  微调 + 新增 `doc/axi.md` 面向人的 AXI 入门读物 + `doc/attach/` 配图）

**Not done**
- **BUG-0025/BUG-0031 仍 `ACCEPTED@M3`**（未转 `CLOSED`）——技术判据已满足，
  纯粹卡在 `fix_commit` 空。本次 closeout 提交落定后需**另派一张新 closer
  卡**（非本次任何 fixer/前一 closer 实例）用本 commit 的 sha 填 `fix_commit`
  列、重跑 `make evidence BUG=... TEST=... SEED=...` 完成关闭；预期触发
  终态行数 5>4 归档阈值，须随附 `make archive`
- 五张 M3 执行卡序列中，②③④⑤仍未派（BUG-0024 (b) 收窄 + M3-OR05；BUG-0018
  修 + 重跑 M2-OR01/WO01；多配置基建 + M3-CF01；M3-CF02/03/04 + M3-AT02）
- `doc/testplan.md` M3-DE02/OR04 判据措辞未同步校正后 SPEC-4.4——REV-014
  §4.1 判定不需要（两行不逐字引旧值 `32'hBADCAB1E`，随 refmodel 常量自动
  生效），非遗漏

**Next**
- 派新 closer 卡：commit 落定后为 BUG-0025/BUG-0031 走独立复验→关闭闭环
  （fix_commit 已有 sha 可填），随附 `make archive`
- 卡②起严格顺序：② BUG-0024 (b) + M3-OR05（L2）→ ③ BUG-0018 修 + 重跑
  M2-OR01/WO01（L2）→ ④ 多配置基建 + M3-CF01（L2，须先于⑤）→ ⑤
  M3-CF02/03/04 + M3-AT02（L1）

**How verified**
- `make check` 绿（docs-check passed；chain audit 无新增 dangling/gap；
  `KILL-0001` 使 `make check MILESTONE=3` 条件 4 由红转绿）
- closer 卡独立复验（不采信任何转述数字）：BUG-0025 三层判据（`c_bug25_
  default_aw/ar`、完整 ID 完成序 `order_violations=0`、`c_bug25_errbucket_
  aw/ar`）+ BUG-0031 六条判据（`c_sib_diff_*`、`c_bug31_livev1_*`、双向
  无假红）逐条核对通过；全回归 10 个历史场景 + 4 个新场景全 PASS、
  UVM_ERROR=0、0 assertion failures
- `python3 scripts/docs.py --pin-spec` 的 anti-sneak-edit 检查在 REV-014
  应用时再次验证生效（先加 change-record 行才允许重 pin）
- 注伤自证 `KILL-0001` 数字（12/3/18）精确落在 `doc/bugs/BUG-0033.md`
  §scope 基线区间（12/3-4/18-19）内

## [0.3.9] 2026-07-29 应用 P-REV012-1：spec §4 新增 clause 7 + §6 交叉引用，BUG-0032 落地闭环

**Done**
- **派 arch 卡（L2）起草 P-REV012-1 的 spec 变更提案**：按 REV-012 §Item 1 批准
  的四段模板（照搬 §8.2-8.4/§6 clause 2），起草 §4 新 clause 7（ATOP × 译码
  未命中应答形态许可来源未定义 + env 构造性约束）+ §6 clause 3 交叉引用，
  original/new text、rationale、对 testplan/design-prompt 的 impact 齐全，
  未越 REV-012 已批处置半步
- **派 rev 卡（新实例，L2，spec review 任务型）对该提案文本做 pin 前门禁**：
  产出 `doc/review/REV-013.md`，**CONDITIONAL PASS**——内容/四段结构/上游
  静默（rev 自跑 grep 复验，非采信 arch 复述）/编号惯例四项核查通过，**唯一
  必改**：提案原文两处 `M3/M4` 收窄为 `M3`。理由：REV-012 处置确认句与
  BUG-0032 fix 段均锚 M3；BUG-0032 更明写 M4 覆盖率收敛是最可能触发该组合、
  须重开仲裁的场景；"照搬 §8.4 模板"是形态指令非范围授权，写 M4 会让 spec
  断言一个当前无 M4 config-matrix testplan 行承载的约束（Retention 不一致）。
  reopening 路径由 part④ + guard 承接，收窄不损失
- **orch 按 REV-013 订正后的逐字文本应用**：`doc/spec.md` §4 追加 clause 7、
  §6 clause 3 追加交叉引用（均为外科手术式追加，§4.1-6/§6.1-2/4-5 正文未改
  一字）；change record 新增 #7（引 REV-012+REV-013 为依据）；
  `python3 scripts/docs.py --pin-spec` 重 pin，新 sha256
  `9347b4ac71f824a05581468502109d78160781fd1712710d0d783a2f03b3b806`
- `doc/bugs.md` BUG-0032 行与 `doc/bugs/BUG-0032.md` `## arbitration` 段回填
  REV-013 门禁记录 + 应用记录（spec 锚点、change record 序号、新 sha256）——
  BUG-0032 的约束持久归宿自此是 spec 正文本身，不再只活在 testplan/
  design-prompt/guard 三处
- **卡分级 vs 实际**：arch 卡定级 L2、rev 门禁卡定级 L2，两者实际交付均与
  定级相符，无失配。本次采用"三步子闭环"（arch 起草→rev 门禁→orch 应用）
  而非单卡直接应用，符合高后果动作（spec pin 变更）应有独立把关的谨慎度

**Not done**
- `doc/testplan.md` M3-DE01 行与 `doc/design-prompt/uvm_env.md` §6 C6.2**未
  补充引用新 spec 锚点** SPEC-4.7——arch 交付已指出这是可选的 impact 项（约束
  内容不变，只是引用权威从"review 记录"升级为"spec 正文"），非本次必需，留
  作后续小改
- 本 chunk 不含任何仿真，testplan 计数不变（M3 仍 ✅0/11）
- FB-24 仍 `open`；五张 M3 执行卡仍全部待派
- **REV-012/REV-013 的门禁副作用**：chain-audit 的 parent-anchored 由 15 降至
  8（clause 7 正文内联提及 §4.2/§4.3/§6.3，§6 clause 3 交叉引用内联提及 §6.3）
  ——这是 FB-24 已诊断的解析器口径本身的自然结果（内联提及即计入"被引用"），
  不是本卡刻意追求的指标，未做任何"为降数字而写"的编辑（REV-012 §Item 2 明确
  否决了那类动机）；如实记录以免误读为本卡目标

**Next**
- 五张 M3 执行卡（严格顺序，④ 先于 ⑤）：① BUG-0025+0031 同卡修 +
  M3-DE01/DE02/OR04/CFG02（L2）② BUG-0024 (b) + M3-OR05（L2）③ BUG-0018 修 +
  重跑 M2-OR01/WO01（L2）④ 多配置基建 + M3-CF01（L2）⑤ M3-CF02/03/04 +
  M3-AT02（L1）
- FB-23~27 按 0.3.7 新性质重新分类（local/noted/upstreamed）——仍是欠框架的
  观察项

**How verified**
- `make check` 绿（docs-check passed；chain-audit dangling 仍 0，本 chunk
  无新增悬空引用）
- `python3 scripts/docs.py --pin-spec` 的 anti-sneak-edit 检查实测生效：先加
  change-record 行后才允许重 pin（脚本对比 change-record 行数 vs git HEAD，
  行数未增会直接 `sys.exit`）
- `grep -n "REV-013\|clause 7" doc/spec.md` 确认新 clause 7 与 §6 交叉引用均
  已落盘；`grep -n "9347b4ac" doc/spec.sha256` 确认新 sha 已写入 pin 文件
- `doc/bugs.md`/`doc/bugs/BUG-0032.md` 均已回填应用记录，`grep -n "已应用"
  doc/bugs/BUG-0032.md` 实读确认
- 三步子闭环的隔离自检：arch 卡与 rev 门禁卡为独立新实例（非同一 session），
  rev 门禁卡自行复验上游 grep 而非采信 arch 复述的静默断言

## [0.3.8] 2026-07-29 派 rev 仲裁卡 REV-012：BUG-0032→SPEC_CHANGED、否决 §4/§5.3 自引用提案、3 处 orch 自标越界均未越界

**Done**
- **派发首张按 0.8.0 新版 `/dispatch` + 静态角色卡实测的 rev 仲裁卡（L3）**，
  一卡三事，`doc/review/REV-012.md` 落盘：
  - **① BUG-0032 终判**：rev 亲跑 grep 复验五份许可来源（xbar.md/demux.md/
    mux.md/axi_pkg.sv/xbar.sv 头注释）确认 err_slv 对要求读响应的 ATOP 应答
    形态确系空白、非蒸馏遗漏；SPEC_ISSUE 分类与 env 构造性约束处置（同
    BUG-0002/0003 先例）均确认成立。但**升级为 `SPEC_CHANGED`**（非
    `ACCEPTED@M4`）——约束目前只活在 testplan/design-prompt/guard，spec §4
    正文只字未提该缺口，与两条被引先例（约束均已写入 spec 正文）不同形。
    **approve P-REV012-1**：补 §4 平行条款（四段模板同 §8.4）+ §6 clause 3
    交叉引用；rev 明确"exact wording 由 orch/arch 拟，rev 不代写"——按
    `CLAUDE.md` §0 与 `.claude/agents/arch.md`（"Proposals are arbitrated by
    rev, then applied... by orch — you never edit the spec body yourself"），
    实际起草者只能是 arch，orch 仅机械应用+重 pin。故 P-REV012-1 的文本草拟
    是**下一张卡**（arch），本 chunk 不产出 spec 正文
  - **② §4/§5.3 自引用提案：REJECTED**。rev 独立复核 FB-24 举证（spec 只有
    两级标题、§4.2/§5.3.1 全程是 inline clause reference 而非标题）与
    parent-anchored=15 的构成（现场重跑 chain-audit，15 条中确认多条正是
    `SPEC-4.2/4.3/4.4→§4`、`SPEC-6.3→§6`、`SPEC-5.3.1/5.3.3→§5.3` 这类幻影
    模式）——裁定这是内容迁就工具口径、零验证收益，持久归宿仍是 FB-24（上游
    修解析器）
  - **③ 复核 3 处 orch 自标越界**（0.3.4 design-prompt 3 行 token 迁移 /
    0.3.6 `.claude/agents/*` 底盘移植+新增 orch.md / 0.3.7 删 orch.md 并入
    `/dispatch`）：**三处均未越 dispatcher-only 实质边界**——§0 的禁令精确
    列举四类技术制品（RTL/TB/design-prompt 内容/spec 内容），三处编辑全部是
    机械可证、零语义的底盘/路径维护，本属 orch 职责。B、C 予以底盘豁免存档；
    A 予以豁免，**并现场查出一条新 corrective**：0.8.0 重排已把
    `workflow/fail/` 整个折进 `workflow/bugs.md`，A 当时改的三处
    design-prompt 引用已再次变成死指针
  - **rev 强制字段**：taxonomy-class anomaly = 否（BUG-0032 已是行；design-
    prompt 死指针与 FB-24 均属框架/文档摩擦，非五分类项目失效）
- **orch 落实 REV-012 查出的 corrective**：`doc/design-prompt/
  {functional_coverage,sva_bind,uvm_env}.md` 三处 `workflow/fail/
  coverage_hole.md` 死指针迁移至 0.8.0 现址 `workflow/bugs.md`「Dispatch:
  coverage hole」节——纯 token 替换，referent 存在，word-diff 自证零语义，
  与 rev 裁定的"orch 可对活文档做机械可证、零语义迁移"的豁免线相符，无需
  另派卡
- **卡分级 vs 实际**：本卡定级 L3，实际交付（spec 仲裁 + 3 处流程自审）与
  定级相符，无失配

**Not done**
- **P-REV012-1 尚未应用**——spec §4 平行条款 + §6 交叉引用的具体文本待 arch
  起草（rev 明确拒绝代写正文），本 chunk 只留下已批准的方向与模板；BUG-0032
  行状态已改 `SPEC_CHANGED` 但 spec.md 正文与 sha256 pin 均未动，约束的活
  载体暂仍是 testplan M3-DE01 + uvm_env C6.2 + guard
- 本 chunk 不含任何仿真，testplan 计数不变（M3 仍 ✅0/11）
- FB-24 仍 `open`（upstream 解析器修复，未回流）；FB-23/25/26/27 状态未动
- 五张 M3 执行卡仍全部待派

**Next**
- 派 arch 卡（L2，草拟 spec 变更提案）：按 REV-012 approve 的模板（同 §4.2
  BUG-0003 四段式、§8.4 BUG-0002 四段式）为 §4 起草平行条款 + 为 §6 clause 3
  加交叉引用，原文/新文/rationale/impact 齐全，引用 REV-012 §Item 1 为基准；
  orch 应用该提案时机械核对措辞落在批准模板内，写 change record + 重 pin
- 五张 M3 执行卡（严格顺序，④ 先于 ⑤）：① BUG-0025+0031 同卡修 +
  M3-DE01/DE02/OR04/CFG02（L2）② BUG-0024 (b) + M3-OR05（L2）③ BUG-0018 修 +
  重跑 M2-OR01/WO01（L2）④ 多配置基建 + M3-CF01（L2）⑤ M3-CF02/03/04 +
  M3-AT02（L1）
- FB-23~27 按 0.3.7 的新性质裁决重新分类（local/noted/upstreamed）——本
  chunk 未做，仍是欠框架的观察项

**How verified**
- `make check` 绿（docs-check passed；chain-audit 与升级前一致：dangling
  仍 0、parent-anchored 仍 15——REV-012 否决 §4/§5.3 提案后本就不该变、rev
  在裁决中现场重跑验证过这一点）
- `doc/bugs.md` BUG-0032 行与 `doc/bugs/BUG-0032.md` `## arbitration` 段均
  已写入 REV-012 引用与终判，`grep -n "BUG-0032" doc/bugs.md` 实读确认
  ruling 列含 "REV-012 §Item 1 终判"字样
- 三处 design-prompt 死指针迁移后 `grep -rn "workflow/fail/coverage_hole"
  doc/design-prompt/` 零命中，`grep -n "Dispatch: coverage hole"
  workflow/bugs.md` 确认目标锚点存在
- 派卡自检：card 只含 scope list（文件路径/行号/commit sha）与判据源，未
  夹带任何一方结论——rev 交付里三项 verdict 均为其独立复验产物（如 Item 1
  的五源 grep、Item 2 的 chain-audit 现场重跑），非对 orch 卡面结论的背书

## [0.3.7] 2026-07-29 删除 orch.md 并入 /dispatch；反馈台账转为实践记录

**Done**
- **裁决：与上游的关系反转。** 0.8.0 删掉 fwsync/manifest/divergence 三态后
  已无回流机制，用户裁定新姿势为——**我们先实践，做得好让上游来
  cherry-pick**。本 chunk 落实这条裁决的两个后果
- **删除 `.claude/agents/orch.md`，内容并入 `/dispatch` skill + `CLAUDE.md`
  §0**（登记 FB-28，status `local`）。**机制事实为本会话直接观测所得、非
  推断**：`.claude/agents/*.md` 在 Claude Code 里只注册**可派发的子代理
  类型**，正文仅在派发时注入**新实例**；主会话收到的只有 frontmatter 的
  `description` 一行。⇒ 那 87 行通篇写着 "You are orch — the main session"
  的硬规则，**唯一读不到它的就是主会话**，直到有人显式 `Read`
- **它也不该被派发**：嵌套 orch 会同时违反它自己两条规则——(1) §"Handoffs
  are records, not conversation" 禁止只传上下文的旁路，而子代理唯一的回传
  形式就是口头摘要；(2) §"Closer ≠ fixer is your call" 要求 orch 自己追踪
  路由，嵌套实例的路由对持有台账的主会话不可见。且它写不了
  `status.jsonl`/`log.md`。**唯一站得住的用法是反过来**：当独立的组卡
  审查员（审隔离与共模防火墙），那是审计不是编排
- **放大风险已识别**：0.8.0 同时废弃 `.claude/skills/`（orch 手册原本住那儿、
  主会话会读）**又**把规则搬进 agent 卡（主会话读不到）⇒ 对严格照上游默认
  走的采纳者，orch 的隔离硬规则**没有任何人读得到**。本仓库侥幸没事，只因
  0.3.6 选择保留四个 skill 作本地资产——那个选择比当时看起来重要得多
- **并入 `/dispatch` 的三块是它原本没有的**：① **closer ≠ fixer 的路由判断**
  （skill 此前完全没提这四个字）② **rev 卡只给范围不给结论**（"a card that
  hands rev a conclusion instead of a scope list is malformed"）③ 新增
  **§3b「旁路即漂移」**——两角色需要同一背景时指向同一份归档记录而非互相
  转述；一方挖出的上下文另一方要重挖是**留存失败**而非效率损失，修法是把
  发现写到下一张卡找得到的地方，**永不为此放宽防火墙**
- **分层理由记明**：`CLAUDE.md` 是常驻但**字节受限**层，skill 是用时载入、
  不受预算约束层，而 `/dispatch` 恰在每次派卡前被调用 ⇒ **消费时机比
  CLAUDE.md 更准**。故 §0 留简版 + 指针，操作细则全在 skill
- **`doc/fw-feedback.md` 性质变更，但文件名与 `FB-` 编号一律不动**。用户提
  "甚至可以删掉"，实测否决：`FB-xx` 被引用 **165 次 / 20 个文件**，文件名
  被引 **29 次**，其中 **10 处在冻结记录里**（`signoff-M0`/`signoff-M2`、
  `REV-004`/`REV-010`、三份 bug 详情页、三份归档）——按 FB-23 裁决那些不得
  回改。⇒ 删或改名会一次性制造死引用，且**我们自己规定了不许去修**。
  改的是这个文件**是什么**，不是它在哪
- **新旧性质写进抬头**：旧（FB-1~27）= 向上游提交的反馈台账；新（FB-28 起）
  = **实践记录**，每行回答"我们改了什么、为什么、上游要不要抄"。新 status
  词表 `local` / `noted` / `upstreamed` 取代 `open`/`reported`/`fixed@ver`
- **唯一的硬要求反而更重了**：既然已无 manifest 记录我们动过哪些上游文件，
  **本台账就是那份记录本身**。任何对 `workflow/`/`scripts/`/`.claude/` 的
  本地改动必须留行 + 代码旁注明 `见 doc/fw-feedback.md FB-xx`，漏了就退化成
  FB-7/BUG-0007 那个形状，**而这次连 `fw-check` 都不会再提醒**。该要求同时
  写进 `CLAUDE.md` §5

**Not done**
- **本 chunk 不含任何仿真**，无新证据，testplan 计数不变（M3 仍 ✅0/11）
- **字节预算逼近上限：39369 / 39500，仅剩 131 字节**。下次往 `CLAUDE.md`
  加任何东西必须先删等量内容。结构性成因已看清但**暂不登记**（痛点未真正
  发生）：该预算覆盖 `CLAUDE.md` + `workflow/*.md`，而 `workflow/` 的
  29922 字节是上游文风、我们不控制 ⇒ 上游一长，采纳者记录项目事实的空间
  就被挤压，而"抬高上限"按纪律属于为过卡放宽门。真撞上再登记
- **L0–L3 分级仍是零实走**（连续第四个 chunk），失配数据产量仍为 0
- FB-23/24/25/26/27 五条仍 `open`；按新裁决它们不再是"等上游修"，而是
  "我们可以自己动手" —— 尚未逐条重新分类
- `/dispatch` 的新增内容（closer≠fixer 路由、rev 范围卡、§3b）**未经真实
  派卡检验**

**Next**
- 派 rev 仲裁卡（L3），一卡四事：① BUG-0032 终判 ② §4/§5.3 自引用提案
  **建议否决**（须带 FB-24 根因入卡）③ 复核 orch 三处越界判断（0.3.4 动
  design-prompt 三行、0.3.6 动两张角色卡、本次删 orch.md 并改写 skill）
  ④ 该卡本身即 `/dispatch` 新内容的首次实检
- 五张 M3 执行卡（严格顺序，④ 先于 ⑤）：① BUG-0025+0031 同卡修 +
  M3-DE01/DE02/OR04/CFG02（L2）② BUG-0024 (b) + M3-OR05（L2）③ BUG-0018 修 +
  重跑 M2-OR01/WO01（L2）④ 多配置基建 + M3-CF01（L2）⑤ M3-CF02/03/04 +
  M3-AT02（L1）。**其中至少一张须兑现 M3 的 KILL 行**
- 把 FB-23~27 按新性质重新分类：哪些我们直接动手（转 `local`）、哪些只是
  记录（转 `noted`）

**How verified**
- `make check` 绿；`make selftest` **60/60 OK**（删除 orch.md 未触发任何
  测试——已先 `grep` 确认 `scripts/*.py` 与 `scripts/tests/*.py` 对
  `orch.md`/`agents/` **零引用**，删除是机械无风险的）
- `.claude/agents/` 现为 arch/de/dv/rev 四份，`ls` 实测
- 删除决策的证据非目测：`grep -ro "FB-[0-9]*"` 得 165 处 id 引用、
  `grep -ro "fw-feedback"` 得 29 处文件名引用，再对
  `doc/{evidence,review,bugs,archive}` 单独求交得出 10 处落在冻结记录
- orch.md 正文不可达的判断源自**本会话的直接观测**：该文件出现时系统提示
  只给了一行 `description`，正文直到显式 `Read` 才可见——非查文档推断
- 字节预算 `wc -c CLAUDE.md workflow/*.md` = 39369 / 39500，实测

## [0.3.6] 2026-07-29 框架 0.8.0 换底盘：手工移植「repo 即模板」模型

**Done**
- **框架 0.7.1 → 0.8.0，性质是断裂而非升级**：上游删除 `fwsync.py`，
  `make fw-pull` **没有对端**；官方升级路径是 `git cherry-pick`，而 0.8.0 是
  一次 24 份契约→4 份的重排，cherry-pick 到本仓库（46 commit / 3 个里程碑
  证据）只会得到冲突堆。⇒ **只能手工移植**，本 chunk 即该移植
- **移植前先在隔离 worktree 实做一遍完整迁移**（删旧机械层→植入 0.8.0→
  跑全部 target→观察），确认可行后才动主树；试迁移 worktree 已清理
- **关键实测结论：数据层 100% 兼容，`doc/` 一个字未改**。`make handoff` /
  `check` / `next` / `guards` 直接跑通既有 testplan / bugs / evidence /
  feature-matrix；`ACCEPTED@M<n>`、`columns_preset` 均保留。换掉的纯是机械层
- **机械层替换清单**：`workflow/` 27 份 → 4 份
  （`discipline` / `bugs` / `records` / `review`）；删
  `scripts/fwsync.py`、`scripts/iverif.manifest.json`、
  `scripts/make/{core,evidence}.mk`；`.claude/agents/` 改为静态 5 份
  （**新增 `orch.md`**，不再渲染）；根 `Makefile` 换成 canon 版 + 追加本项目
  的 sim 转发（smoke/cov/lint/verdi/clean）
- **命令改名对照**（已同步进所有活文件）：`handover`→`handoff` ·
  `docs-check`/`chain-audit`/`signoff-check`/`explore` 四个动词收成一个
  `check`（`SCEN=`/`MILESTONE=` 决定视图）· `docs-archive`→`archive` ·
  `bump-minor`→`bump minor=1` · `replay` 取消（不变量 2 已保证首行即命令）·
  新增 `commit`（add+commit，**永不 push**）与 `selftest`
- **`scripts/regress.py` 保留，归属改为本项目**——0.8.0 删了它但同时明说
  「canon 不再拥有循环，项目拥有循环」，而 `sim/Makefile:72` 实际调用它、
  M2 签核的 11/11 独立重跑依赖它逐字工作。删掉重写属无谓风险
- **`doc/design-prompt/` 路径未动**：核实 `iverif_config.py:181` 仍要求
  `doc/design-prompt/README.md`，CLAUDE.md 表里写 `design-prompt/` 是简写。
  省掉一次会再制造数十处死指针的路径迁移（FB-23 的教训）
- **`CLAUDE.md` 重写**：0.8.0 把 L0–L3 分级表移入项目 CLAUDE.md **并加了
  测试强制它在场**；同时旧文引用的 `constitution.md` / `profile.md` /
  「hash 锁定的框架快照」/ `fw-check` / `docs-check` 全部已不存在。新版
  保留 §0 隔离、§4 环境（xverif 体系与 VCS-2018 变通）、§6 项目专属，
  新增五条不变量与分级表，里程碑定义移出至 `doc/milestone.md`
- **新建 `doc/milestone.md`**（0.8.0 的 orch 自有文件）：M0–M4 出口条件逐条
  落盘，含 M3 的多配置声明式子集裁决与 KILL 要求
- **裁决：不变量 5「无击杀不采信」自 M3 起生效，M0/M1/M2 不回填 KILL 行**
  （同 FB-23「冻结记录不回改」）。实测 `make check MILESTONE=2` 条件 4 现为
  FAIL——但 M2 **确实做过**击杀自证，取证位置
  `doc/evidence/v0.2.5/signoff-M2.md` rubric #5（BUG-0027 缺陷放回见 336 条
  红后复原）。⇒ 已知**记账**缺口，非实质缺口；该判断连同取证位置同时写入
  `CLAUDE.md` 不变量 5 与 `doc/milestone.md` 抬头，避免后人误读为真缺口
- **四个 skill 保留为本地资产并重写**（0.8.0 上游已废弃 `.claude/skills/`）：
  `handover`→`handoff` 目录改名以对齐 make 目标；`closeout` 的门禁步骤改
  `check`+`selftest`；`dispatch` 的分级表**删除本地副本、改为指向 CLAUDE.md**
  （0.8.0 移动它的用意就是终结双份漂移）；`evidence` 的 `replay`/
  `signoff-check` 改为新形态
- **CI 与 hook 修复**：`ci.yml` 两处失效调用（`docs.py --handover` 已改名、
  `fwsync.py --check` 文件已删）→ 改为 `--handoff` + 以 `selftest` 顶替
  fw-check 的位置；`.githooks/pre-commit` 删除 fwsync 那两行（原为
  `|| echo`，不挡提交但会每次提交打一句假警告）
- **登记 FB-27**（annoyance，open）：**0.8.0 删掉四个 make 动词，但它自己
  发布的两张角色卡仍在指令角色执行其中两个**——`.claude/agents/arch.md:34`
  写 `make explore`、`rev.md:51` 写 `make signoff-check`，二者均已 retire。
  命中面精确落在最坏位置：这不是背景说明而是 arch 的 spec-gap sweep 与 rev
  的里程碑签核**各自主任务的操作指令**，照做直接 `No rule to make target`。
  两处已就地修并在代码旁注明 `见 FB-27`
- **订正 FB-25（不改原文，并列存证）**：FB-25 断言「没有任何门禁读 CLAUDE.md
  的内容」，0.8.0 起**部分不成立**——`scripts/tests/test_docs.py:477` 会读
  项目 CLAUDE.md 断言 L0–L3 表在场；本仓库迁移时正是被这条挂掉 1/60 才发现。
  FB-25 现只在「路径有效性」半边成立
- **`doc/fw-feedback.md` 抬头仪式改写**：0.8.0 删掉三态漂移检测后，「绝不
  本地修改 scripts/workflow」这条红线**在机制上已不存在**。本仓库改采
  「**先登记、可就地修，两者都做**」，且就地修的每一处必须在台账留行 + 代码
  旁注明 FB 编号——否则退化成 FB-7/BUG-0007 那个形状（变通只落注释、无人可
  grep）
- **收尾时补上一个自造的接手缺口**：迁移中我删掉了 `iverif.json` 的
  `framework_repo`（fwsync 已亡，该字段无人读），但 CLAUDE.md §5 仍写着
  「跟进上游：**保留 remote**」——而 `git remote -v` 里根本没有那个 remote，
  上游位置遂无处可查。**这正是本会话反复报的「指令没有机制」，且是我自己
  造的**。已补：加 `upstream` remote 指向 GitHub（`.git/config` 不随仓库走，
  故同时把这条与 hooksPath 并列写进 CLAUDE.md §5 的一次性设置）；并**记录
  移植基线 `upstream 05a49a0`（0.8.0）**，使「上游比我们多了什么」成为一条
  机械命令：`git log 05a49a0..upstream/master --oneline`。实测该命令当场
  返回 1 条（`e23d938 删除 VENDOR.md`——删的是上游 `doc/VENDOR.md` 壳文件，
  本仓库用的是 `vendor/VENDOR.md`，不受影响）

**Not done**
- **本 chunk 不含任何仿真**，无新证据，testplan 计数不变（M3 仍 ✅0/11）
- **M3 的 KILL 行尚未产生**——不变量 5 自 M3 生效，但注伤自证要到执行卡才
  做得出来。`make check MILESTONE=3` 条件 4 现为 FAIL，属预期，须在 M3 签核
  前由某张执行卡兑现
- FB-23/24/25/26/27 五条均 `open`，本 chunk 只登记未回流
- **L0–L3 分级仍是零实走**（连续第三个 chunk）：本会话三次框架变更、零张卡，
  「定级 vs 实际」失配数据产量仍为 0。此即 FB-26 报告的现象在继续发生
- 0.8.0 的 `workflow/` 四份契约（含新的 `bugs.md` 13.7KB）**未逐字通读**——
  只核对了本仓库直接依赖的接口（KILL、ACCEPTED、五类判据名）。若其中有细则
  变更，会在下一张卡的交付报告格式上暴露
- `DESIGN.md`（上游 canon-only 沿革文档）未克隆进本仓库，需要时去框架 repo 读

**Next**
- 派 rev 仲裁卡（L3），一卡三事：① BUG-0032 终判 ② §4/§5.3 自引用提案
  **建议否决**（须把 FB-24 的根因分析入卡，否则 rev 会在不知道
  parent-anchored=15 是解析器产物的前提下裁决）③ 复核本 chunk 的两处 orch
  越界判断——0.3.4 动 design-prompt 三行、本次动 `.claude/agents/` 两处
  （后者在 0.8.0 语义下已属本地文件，但仍是 orch 改角色卡）
- 五张 M3 执行卡（严格顺序，④ 先于 ⑤）：① BUG-0025+0031 同卡修 +
  M3-DE01/DE02/OR04/CFG02（L2）② BUG-0024 (b) + M3-OR05（L2）③ BUG-0018 修 +
  重跑 M2-OR01/WO01（L2）④ 多配置基建 + M3-CF01（L2）⑤ M3-CF02/03/04 +
  M3-AT02（L1）。**其中至少一张须兑现 M3 的 KILL 行**
- 首次派卡时同时验证：新版静态角色卡的实际行为、L0–L3 定级失配记录、
  `/dispatch` skill 指向 CLAUDE.md 分级表是否真的可用

**How verified**
- `make check` 绿（docs-check passed + chain audit，dangling 仍 0）；
  `make selftest` **60/60 OK**（移植过程中一度 59/60，挂的正是
  `test_claude_md_carries_risk_grades`，重写 CLAUDE.md 后转绿——该失败即
  FB-25 订正的直接证据）
- `make handoff` / `make next` / `make guards FILES=...` 三条均实跑，输出与
  0.7.1 下逐项一致（next 12 条动作、guards 正确命中 BUG-0007）
- `make check MILESTONE=2` 与 `MILESTONE=3` 均实跑，条件 4 FAIL 系亲眼所见
  而非推断；M2 击杀自证的取证位置经 `doc/status.jsonl` 0.3.0 行复核
- 字节预算：`CLAUDE.md` + `workflow/*.md` = **38531 / 39500**，较迁移前
  （39042）**更宽松**——旧 CLAUDE.md 9120B 换成新版后总量下降
- 失效引用清扫：`grep` 全部活文件（CLAUDE.md / .claude/ / doc 表头 /
  .githooks / .github）确认无残留旧命令名与旧 workflow 路径；命中的剩余项
  全部位于 `doc/fw-feedback.md` 的**冻结历史行**，按 FB-23 裁决不动
- 上游动词悬空（FB-27）非目测：`grep -o "^[a-z]*:" Makefile` 取实有目标集，
  与 `grep -on "make [a-z-]*" .claude/agents/*.md` 求差得出
- 接手性实测（本 chunk 收尾）：`make handoff` 实跑，版本/状态/log 尾块正常
  读出；`git status` 0 未提交、`git log origin/master..HEAD` 0 未推送；
  `git log 05a49a0..upstream/master` 实跑返回 1 条，证明新加的上游基线机制
  确实可用而非又一条空指令

## [0.3.5] 2026-07-29 pull 框架 0.7.1 + 压测 explore：§id 解析器幻影率 44%（FB-24）

**Done**
- **pull 框架 0.7.0 → 0.7.1**（27 files pinned）。与 0.3.4 那次不同，**本次是
  行为变更**：两行从 deferred 台账**由用户裁决提前毕业**，CHANGELOG 明写
  「to be stress-walked by the adopters」——那个 adopter 就是本仓库。同样先在
  隔离 worktree 预演（fw-check / docs-check / chain-audit 全绿，chain-audit
  逐项与 0.7.0 一致）后才落主树
- **(a) spec-gap 探索器**（`docs.py --explore` / `make explore`）：chain-audit
  图的规划视图，把 uncited 章节连同标题列成候选 testplan 行。附带一个
  `--next` 规划期提示，**仅在当前里程碑零登记行时触发**——本仓库 M3 已有 11
  行 ⇒ 实测正确保持沉默（无 FB-19 那种常驻唠叨）。新增 copilot 卡型
  「arch spec-gap sweep」，契约要求 explore 列表**逐字进卡**且禁止 orch 掺入
  自己的场景想法
- **(b) L0–L3 风险分级**进 dispatch 手册，取代原「模型档位」清单：L0 文档/
  构建 · L1 TB/序列/覆盖 · L2 RTL/SVA/scoreboard · L3 spec/豁免/签核。分级
  **只调链条重量**，taxonomy 登记与 evidence 门禁在每一级都无条件。每张卡须
  声明分级，且**每卡记录「分级 vs 实际」的失配**——该裁决推翻了 0.4.6 的
  观察者设计，理由锋利：无人抱怨流程重 ≠ 流程轻，因为每个子代理只看见自己
  那张卡、链条重量只有 orch 看得见、而**orch 不疼**。零记录 ≠ 零重量
- **压测 `make explore` 当场命中一条实质缺陷 → 登记 FB-24**（annoyance，
  open）：explore 交给 arch 的 9 条前沿里 **4 条不是 spec 章节，幻影率 44%**。
  `§1.3` 实为 `spec.md:436` 的 **`REV-011 §1.3`**（评审记录章节号被吸进 spec
  命名空间）；`§7.1.2`/`§7.4.3`/`§7.4.4` 是 `§7.1`/`§7.4` **正文有序列表的第
  2/3/4 条**（实读 `spec.md:328-345`、`376-400` 确认 §7.4 body 是 1.–5. 列表、
  无任何子标题）
- **全谱实算**（脚本，非目测）：spec 有 **25 个真标题**，正文出现 **45 个
  §id**，其中 **22 个无对应标题**——`§5.4.1` 被引 9 次、`§5.2.1`/`§5.2.3` 各
  7 次。⇒ 本仓库 spec 的**主导引用惯例就是「§<标题>.<列表项>」**，是文体不是
  笔误。0.6.0 引入 inline-token 解析本为让 `SPEC-5.2.1` 可解析（否则 100%
  假阳），代价即 uncited 集合混入列表项
- **定性：不是回归，是「无消费者的不精确，在获得消费者的当天暴露」**——
  chain-audit 阶段它只是个没人行动的计数（FB-21 同族），0.7.1 把它变成派工
  指令且**禁止 orch 过滤**，不精确遂变成错工单
- **比幻影更糟的一类已识别**：`§7.4.3` 是真条款但内容为**禁令**（「任何
  latency checker **不得**断言固定周期数」）。禁令由 checker 的**缺席**满足，
  语义上永远无法被场景覆盖 ⇒ arch 只能逐条写 decline，而 decline 按卡契约是
  narrowing 须 rev 门禁 ⇒ **解析器的不精确机械地制造 rev 工作量**
- **同一根因解释了 parent-anchored=15**：`§4` 只有 `## 4.` 一个标题、条款是
  列表项 4.1–4.5；testplan 引 SPEC-4.1~4.5，其中在正文被 inline 提及的
  （§4.1/§4.5）解析成功，未提及的（§4.2/4.3/4.4）跌回父级 §4。**据此建议
  否决 arch 在 0.3.3 提的「§4/§5.3 补自引用以降 parent-anchored」提案**——
  那实质是往 spec 正文里写字去迁就解析器，spec 文体不该为工具让步；根因在
  FB-24，修在框架侧
- **对 FB-22 的自我订正已存证**：FB-22 举证「静默截断丢掉 §7.4.3/§7.4.4/
  §8.3/§8.4」，按今日全谱统计**这四个 id 全是幻影**。FB-22 核心主张（字符串
  序 + 无提示截断）不受影响且已正确修复；受影响的只是「被隐藏的是什么」这半
  段举证。按 FB-23 同一裁决**不改 FB-22 原文**，在台账并列一行 `recorded` 存证

**Not done**
- **本 chunk 不含任何仿真**，无新证据，testplan 计数不变（M3 仍 ✅0/11）
- FB-24 与 FB-23 均 `open`，尚未回流框架仓库
- **L0–L3 分级机制一次也没实走**——本会话仍未派任何卡，「分级 vs 实际」失配
  数据（0.7.1 明说这才是提前释出的目的）产量为 **0**。本条是欠框架的
- M3 实质工作仍一步未动：rev 仲裁卡与五张执行卡全部待派
- explore 的另外 5 条（§2.1/§2.2/§2.3/§7.1/§7.3，均为真标题）**未评估**是否
  值得建行——那是 arch 的判断，orch 不代劳

**Next**
- **arch spec-gap 卡在 FB-24 闭环前不派**——卡契约要求 explore 列表逐字进卡
  且禁止 orch 过滤，现在派就是让 arch 按 44% 错的清单干活
- 派 rev 仲裁卡（L3）：BUG-0032 终判 + **§4/§5.3 自引用提案建议否决**（须把
  FB-24 的根因分析一并入卡，否则 rev 会在不知道 parent-anchored 是解析器
  产物的前提下裁决）。该卡同时是 L0–L3 分级与新版角色文件的首次实测
- 五张 M3 执行卡（**严格顺序**，④ 先于 ⑤）：① BUG-0025+0031 同卡修 +
  M3-DE01/DE02/OR04/CFG02（L2）② BUG-0024 (b) + M3-OR05（L2）③ BUG-0018 修 +
  重跑 M2-OR01/WO01（L2）④ 多配置基建 + M3-CF01（L1/L2）⑤ M3-CF02/03/04 +
  M3-AT02（L1）——分级为初判，派卡时按 dispatch 手册复核并记失配
- 若 rev 认为 0.3.4 里 orch 动 design-prompt 三行越界，回退那三行

**How verified**
- `make fw-check` 绿（framework 0.7.1，27 files pinned）；`make docs-check` 绿
- `make chain-audit` 逐项与 0.7.0 完全一致（dangling 仍 0 / sourceless 1 /
  orphans 0 / parent-anchored 15 / uncited 9）⇒ 0.7.1 未改判据，explore 与
  chain-audit 共用 `chain_gaps()` 属实
- `make explore` 实跑，输出 9 条前沿 + 「M3, 11 scenario rows registered」；
  `make next` 实跑确认规划期 nag **未**触发（M3 非零登记行）
- 幻影认定非目测：逐个 `grep "^#\+ *§\?<id>"` 确认无标题，再 `sed -n` 实读
  §7.1（L328-345）与 §7.4（L376-400）正文确认是有序列表；`§1.3` 实读
  `spec.md:436` 确认前缀为 `REV-011`
- 25/45/22 三个数字由一次性 python 脚本实算（正则提取标题集与 inline §id 集
  求差），非估计
- 升级前预演在 `git worktree` 隔离副本完成，主工作树全程干净，预演后
  `worktree remove --force` + `prune`

## [0.3.4] 2026-07-29 pull 框架 0.7.0（结构重排）+ 路径迁移的活/冻二分裁决

**Done**
- **pull 框架 0.6.1 → 0.7.0**（27 files pinned，较 0.6.1 +1）。**升级前先在
  临时 worktree 实拉预演**（`git worktree add --detach` → `fwsync --pull` →
  跑全部门禁 → `worktree remove`），未采信 CHANGELOG 自述；预演证实：
  fw-check / docs-check / handover / chain-audit 四项全绿，本仓库
  `scripts/iverif.divergence.json` 为空 ⇒ 无本地改动需 re-key，10 个孤儿
  文件被 fwsync 自动清扫
- **实测认定 0.7.0 为纯结构重排、零行为规则变更**。逐字读 diff（13 文件
  45+/30-）后归为三类且仅此三类：① 路径重命名（`workflow/signoff/` →
  `workflow/review/`；`workflow/{schema,taxonomy,dispatch}/` → 顶层 +
  `workflow/fail/`）；② 每份文档新增 provenance 标头（`Axioms:` /
  `Consumer:`）；③ 一处死指针订正——`discipline.md` 原写"四条核心不变式
  (README)"，而 README 不在快照内 ⇒ **该指针在每个项目副本里都是死的**，
  0.7.0 改指新增的 `workflow/constitution.md`。**无一条判据/门禁阈值/角色
  边界/报告格式变化** ⇒ M2 已签核的 8 条证据与 M3 已交付的设计输入均不受
  影响，无需重跑任何仿真
- 新增 `workflow/constitution.md`（4800B 硬上限）：五条公理（自反·独立·
  落盘·消费·痛点）+ 一张机器循环图 + 四条核心不变式的正式归属地 + 文档→
  公理→消费者索引表。会话阅读序变为 constitution → discipline → profile
- **活文件路径迁移（框架不自动改，须手工）**：`CLAUDE.md` 三条框架路径
  （§1 testplan 契约 / §2 分诊表 + failure_record / §2 failure_taxonomy）
  + 抬头补 constitution read-first 行 + 渲染来源注释改指
  `harness/templates/`；`doc/testplan.md:3` 与 `doc/bugs.md:3` 表头契约路径
  （**核实过**：0.7.0 的 `fwsync.py:340-363` seed 已写新路径，但只在
  `--init` 生成，既有仓库不会自动更新）；`doc/fw-feedback.md:7` 的
  `iverif-workflow/docs/adoption.md` → `governance/adoption.md`
- **三份 design-prompt 的 `workflow/dispatch/coverage_hole.md` 死指针已修**
  （`sva_bind.md:81`、`functional_coverage.md:127`、`uvm_env.md:99`）——这
  三份正是 M3 五张执行卡的输入，留着会让 DV 实例按图索骥扑空。**边界声明**：
  design-prompt 属 arch 制品（CLAUDE.md §0「orch 不写 design-prompt」），
  orch 此处只做**纯路径 token 替换**，每份净变更 1 行、`git diff
  --word-diff` 已自证除路径外一字未动；派 arch 卡改三个路径不合比例
  （公理 4 痛点 / discipline rule 2 简单优先）。若 rev 认为仍越界，回退成本
  为三行
- **裁决：冻结记录一律不迁移**——`doc/review/REV-*.md`、
  `doc/evidence/*/signoff-M*.md`、`doc/bugs/BUG-*.md`、`doc/archive/` 共
  **16 份文件 39 处**旧路径引用保持原样。理由：它们记录的是"当时那份契约在
  哪"，回改等于伪造审计线索，与 evidence 不可回改同一条道理。代价是这 39
  处从此指向不存在的路径，且**没有任何门禁会报**（docs-check/fw-check/
  chain-audit 都不校验 workflow 路径引用）
- **登记 FB-23**（annoyance，open）：canon 重排在采纳者冻结记录里留下永久
  死指针，而 0.7.0 升级须知只覆盖活文件（CLAUDE.md / divergence.json /
  next_phrases_override），对不得回改的记录只字未提。含一处框架内部真张力
  （落盘公理 vs evidence 不可回改 ⇒ 指针必然死，非谁做错），故需一条明写
  约定否则每个采纳者各判一遍；本仓库实证含三份签核书的"判据来源"抬头指向
  已不存在的 `workflow/signoff/rubric.md`——**签核书声明自己依据的那份判据
  路径已不存在**。三条建议：① CHANGELOG 明文声明"冻结记录保留旧路径是正确
  行为"；② 加只追加的 `governance/path-map.md` 供反查（落在消费公理上：
  这些指针的消费者是未来回溯审计线索的人，今天无机制服务他）；③ 由 fwsync
  从历次 manifest 差分机械生成该表

**Not done**
- **本 chunk 不含任何仿真**——纯框架升级 + 文档路径迁移，无新证据登记，
  testplan 计数不变（M3 仍 ✅0/11）
- FB-23 状态 `open`，尚未回流框架仓库（框架作者在隔壁 session，可当日闭环）
- M3 实质工作一步未动：rev 仲裁卡（BUG-0032）与五张执行卡仍全部待派
- `.claude/agents/` 四份角色文件已由 pull 重新生成，但**本会话未实际派发过
  任何卡** ⇒ 新版角色文件在真实派发下的行为未经实测（adoption.md 提示
  agent 类型注册有延迟，首次派发若报 "Agent type not found" 是已知现象，
  重启会话即可，不要去 debug 卡本身）

**Next**
- 派 rev 仲裁卡：BUG-0032 状态终判（沿用 BUG-0002/0003 先例是否成立）+
  是否需要 spec 补条款；顺带评估 §4/§5.3 自引用编辑提案是否值得动 pin。
  **该卡同时是新版角色文件的首次实测**
- 按 arch 建议的五块切分派发 M3 执行卡（**严格顺序**，④ 必须先于 ⑤）：
  ① BUG-0025+0031 同卡修 + M3-DE01/DE02/OR04/CFG02 ② BUG-0024 (b) 路线 +
  M3-OR05 ③ BUG-0018 修 + 重跑 M2-OR01/WO01 ④ 多配置基建（tb_top
  C5.1-C5.7 声明式配置点）+ M3-CF01 ⑤ M3-CF02/03/04 + M3-AT02
- 若 rev 认为 orch 动 design-prompt 越界，回退那三行并改派 arch 卡
- M3 签核卡需重做"判决活性矩阵"（M2 签核人交办）；BUG-0025/0031 详情页
  `ref: 待定` 待其修复卡落地时填入具体 cover/assert 名

**How verified**
- `make fw-check` 绿（framework 0.7.0，27 files pinned）；`make docs-check`
  绿；`make handover` 正常读出状态
- `make chain-audit`：dangling **仍为 0**；sourceless 1 / matrix orphans 0 /
  parent-anchored 15 / uncited 9 / 无 spec_ref 头 11——**逐项与升级前
  （0.3.3 区块记录）完全一致**，证实升级未改变任何审计判据
- 升级前预演在 `git worktree` 隔离副本中完成，主工作树全程干净
  （`git status --short` 空），预演结束 `worktree remove --force` +
  `worktree prune`
- design-prompt 三处改动的"纯路径替换"以 `git diff --word-diff=plain` +
  `--numstat` 双重自证：每份 `1  1`，词级 diff 仅显示路径 token 一对一替换
- 冻结记录死指针规模以 `grep -rl` / `grep -ro` 双计得出：16 份文件、39 处

## [0.3.3] 2026-07-29 arch 卡：M3 场景清单落地 + 推翻 orch 的 constrained-random 决定

**Done**
- **arch 设计输入卡交付**：`doc/testplan.md` 新增 11 条 M3 场景
  （DE01/DE02/OR04/CFG02/OR05/AT02/CF01~04/TL01——TL01 系既有行，核对满足
  BUG-0010 guard 三要素，未改动）；`doc/feature-matrix.md` 新增
  F-M3-02~F-M3-10；`doc/design-prompt/` 五份文件（tb_top/uvm_env/
  scoreboard_refmodel/sva_bind/functional_coverage）各补 M3 增量段
- **arch 反驳了 orch 关于"M3 引入配置维 constrained-random"的决定，
  orch 采纳**。反驳给出三条可机械核验的事实（均已复核为真）：(1) 配置维
  全部是 elaboration 期 `localparam`（`tb/xbar_types_pkg.sv:19-83`），SV
  `randomize()` 是运行期求解器，语义上落不了地；(2) `+ntb_random_seed`
  只进 `run:` 不进 `compile:`（`sim/Makefile:64` vs `:32-35`），要让种子
  决定配置须让 elaboration 消费 SEED，即每种子一次全量重编；(3) 更要命的
  是 `run: compile` 只产一个固定名 `simv`——配置随种子变而产物名不变时，
  VCS 增量编译一旦复用旧 `simv`，"配置 X 通过"与"基线又跑一遍"在日志上
  **完全同形**，与 BUG-0022（lint 假绿）/BUG-0028（分母缩水）同一沉默通过
  家族，且比二者更隐蔽——判决路径的随机缺陷至少会以失配现形，配置随机的
  缺陷表现为"跑的根本不是你以为的那个设计"。**替代方案**：配置维不做随机，
  做**声明式覆盖子集**（4 个配置点 + 基线，spec §0 行 3 每维度每取值至少
  出现一次，72 点全叉 → 5 点），组合爆炸同样被治住而每点由 `TEST` 名唯一
  确定、可复现、可归因。事务序列保持定向未受影响
- 四条 `ACCEPTED@M3` 债务逐条给出场景归属：BUG-0025+BUG-0031 同卡登记
  （M3-DE02 第 1 层 + M3-OR04 第 2/3 层 + M3-CFG02，满足 REV-011 §4 G4 的
  同卡修要求）；BUG-0024 → M3-OR05；**BUG-0018 判定不需要新场景**——新建
  test 会与"逐 test 看、不看 merged"的判据相冲突，到期验收就是逐 test 重跑
  既有 M2-OR01/WO01
- BUG-0012 guard 点名"随条款落地补齐"的定向场景（条款 0.2.0 起已落地但一直
  无人认领）补注册为 M3-AT02
- **新登 BUG-0032**（SPEC_ISSUE，OPEN）：err_slv 对 ATOP 的应答形态许可来源
  未定义——§4.3 按读/写二分只给"写事务返回单拍 B"，§6.3 要求原子读 B/R
  双通道返回，err_slv 该产几拍 R、什么数据、什么响应码，无条款可推；
  arch 亲跑 grep 确认上游文档 §Decode Errors 全段无 ATOP 命中。处置沿用
  BUG-0002/0003 先例：env 构造性约束使其不可触发 + 列上游确认项，不阻塞
  M3——但**状态未终判**，见 Not done
- 一条可选 spec 编辑提案（非强制）：§4/§5.3 正文从不自引用其编号子条款，
  致 `chain-audit` 的 parent-anchored 由 5 增至 15；arch 建议保留精确引用、
  不退化为父级引用，未落地，交 rev 判断是否值得动 pin

**Not done**
- **BUG-0032 未终判**——orch 不得自填状态（同 BUG-0031 先例，ACCEPTED 的
  rationale 须 rev 签名），需派 rev 仲裁卡确认 SPEC_ISSUE 处置 + 是否需要
  spec 补条款
- M3 尚未派发任何 DV/DE 执行卡，五份 design-prompt 增量与 11 条场景描述均
  停留在设计输入阶段
- `make signoff-check` 现状：条件 1 open 11 行、条件 3 active 多 BUG-0032、
  accepted debt due 4 条——均是 M3 正常态，非本 chunk 遗留问题

**Next**
- 派 rev 仲裁卡：BUG-0032 状态终判（沿用 BUG-0002/0003 先例是否成立）+
  是否需要 spec 补条款；顺带评估那条可选的 §4/§5.3 自引用编辑提案是否值得动
- 按 arch 建议的五块切分派发 M3 执行卡（**严格顺序**，④ 必须先于 ⑤）：
  ① BUG-0025+0031 同卡修 + M3-DE01/DE02/OR04/CFG02
  ② BUG-0024 (b) 路线 + M3-OR05
  ③ BUG-0018 修 + 重跑 M2-OR01/WO01 对口场景
  ④ 多配置基建（tb_top C5.1-C5.7 声明式配置点）+ M3-CF01——验收锚点须含
     "既有 11 条证据仍逐字节可复现"
  ⑤ M3-CF02/03/04 + M3-AT02（依赖 ④ 的配置基建）
- M3 签核卡需重做"判决活性矩阵"（M2 签核人交办，非任一 DV 卡交付物）；
  §5.2.6 2.b 非判决 cover 落 `cg_miss_order.same_bucket_diff_full_id_with_err_slv`
  （M3-OR04）
- BUG-0025/BUG-0031 详情页 `ref: 待定` 未填——待其修复卡落地时一次性填入
  具体 cover/assert 名，M3 签核时不得仍是"待定"

**How verified**
- `make docs-check` 绿；`make fw-check` 绿（框架 0.6.1，26 files pinned）
- `make chain-audit`：dangling **仍为 0**（hard-fail 未被本卡触发）；
  uncited 由 19 降至 9（§4.1/§4.5/§5.2.6/§5.3/§5.5.3/§6.5/§7.2/§8.3 均已
  被新场景覆盖）；parent-anchored 由 5 增至 15（软缺口，见"可选提案"段）
- orch 独立复核 arch 反驳的三条事实：`grep localparam tb/xbar_types_pkg.sv`
  确认配置维全为 elaboration 期常量；`grep ntb_random_seed sim/Makefile`
  确认仅在 `run:` recipe；`grep -n "^run:\|^compile:\|simv" sim/Makefile`
  确认固定产物名 `$(OUT)/simv`——三条独立验证，非采信 arch 转述
- M3-TL01 未改动，核对 BUG-0010 guard 三要素（跨 ID 桶压满 / 单端口合计远超
  扁平上限 / 扁平表现触发 DUT_BUG 复核路径）逐条已具备

## [0.3.2] 2026-07-28 拉框架 0.6.1：FB-21/FB-22 当日闭环，M3 开工前底座就位

**Done**
- **`make fw-pull` → 框架 0.6.1**（commit `87e2eef`），`fw-check`（26 files
  pinned）/ `docs-check` 双绿
- **FB-21 → `fixed@0.6.1`**：按本仓库处方「被看见而非必须绿」落地 ②+①——
  `docs.py --signoff` 现**内嵌打印 chain-audit 全文**，`rubric.md` 新增 **#8
  「Chain audit answered」**（签核记录须粘贴一次运行、逐 gap 类给出处置或书面
  接受；**悬空引用只许修、不许接受**）。刻意不做硬门禁，本仓库「0/23 采纳率下
  硬红 = 豁免压力」的论证原文入框架 CHANGELOG。框架侧原样收下了「无消费者家族
  第三撞、且发生在采纳该教训当天」这一指控，并据此加 fuse 钉住 rubric #8 与
  `--signoff` 输出的永久一致
- **FB-22 → `fixed@0.6.1`**：三条建议全部采纳——数值序 + **全量打印** + fuse
  钉住 §2.1 排在 §10.1 之前。框架侧把本条记为「审计工具的静默截断优先隐藏它
  本该发现的东西」
- 附带观察（列数校验只覆盖 `doc/bugs.md`）**框架侧暂拒**，理由本仓库认同：
  校验跟着门禁走，而 fw-feedback 表上没有门禁判据落着；哪天有机制开始机械读
  它，自动成为 deferred 候选

**Not done**
- M3 场景清单未设计；四条 `ACCEPTED@M3` 债务未修；M3-TL01 未落地
- chain-audit 的 gap 一条未处置——**它们是 M3 的输入，不是欠账**

**Next**
- 派 **arch 设计输入卡：M3 场景清单**（错误路径 / decode error / 多配置回归）
- 开工前待拍板：M3 是否引入真正的 constrained-random（配置矩阵铺开后定向激励
  组合数爆炸；「激励到不了硬情形导致旧绿灯空过」是本仓库已栽四次的地方）

**How verified**
- **两条修复均实测验收，非采信**：
  - FB-21 —— `make signoff-check` 输出中人工抽查第 8 条存在，**其后紧接
    `== chain audit ==` 全文六行**，即工具与 rubric 同时改了（这正是 FB-18
    当初的病：只改文档没改工具）
  - FB-22 —— 同一条 `make chain-audit`，**计数 19、列出 19**，尾部
    §7.4.3/§7.4.4/§8.3/§8.4 已出现，排序为数值序
- `make fw-check` 绿（0.6.1，26 files pinned）；`make docs-check` 绿

## [0.3.1] 2026-07-28 拉框架 0.6.0（chain-audit 毕业）+ 登记 FB-21/FB-22

**Done**
- **`make fw-pull` → 框架 0.6.0**，`fw-check`（26 files pinned）/ `docs-check`
  双绿。0.6.0 的主体是 **`make chain-audit` 从 deferred 毕业**——spec ↔ testplan
  ↔ feature-matrix ↔ evidence 的断链审计，**其触发器就是本仓库的 signoff-M2**
  （框架 CHANGELOG 记为"生态首次覆盖驱动签核"）。同时 0.5.4 的 FB-19 例外条款
  原样落地在 `.claude/skills/dispatch/SKILL.md`，验收无异议
- **chain-audit 首次运行**（本仓库 M2 文档）：`0 dangling / 1 sourceless(M0-01)
  / 0 orphans / 5 parent-anchored / 19 uncited / 11-of-11 evidence 缺
  spec_ref header`。工具本身有价值——**§5.2.6**（REV-011 当天新增的条款）被
  正确标为"尚无场景引用"，正是该审计存在的意义（M3 缺口）
- **登记 FB-21**（annoyance）：**chain-audit 没有任何门禁或判据来源消费它**。
  实测 grep `chain.audit` / `chain_audit` 于 `rubric.md`、`workflow/*.md`、
  所有 skill = **空集**；`signoff-check` 机器条件 1-3 与人工抽查 4-7 均未提及；
  `docs-check` 不调用；`make next` 不提示。而 0.6.0 CHANGELOG 自己写明它的
  触发器是"the first coverage-driven milestone signoff"——**为签核而生的工具，
  签核却不调用它**。与 FB-11 判例 (a) 逐字同构（`make lint` 从 M0 起就是坏的，
  正因为它不在任何门禁清单里）。本仓库第三次撞同一家族。建议**明确不做成硬
  门禁**（`spec_ref` 采纳率 0/23，硬失败会立刻制造豁免压力），诉求是"签核时
  必须**被看见**"而非"必须绿"
- **登记 FB-22**（annoyance）：**uncited 行静默截断，且截断方向系统性偏向编号
  最大的章节**。`docs.py:1023-1025` 是 `uncited[:15]`，无省略号/无 "+N more"；
  本仓库实测**计数 19、列出 15、静默丢 4**，而同一报告另外四行全量打印 ⇒
  报告内部自相矛盾。排序用 `sorted()` **字符串序** ⇒ 砍掉的恒是编号最大的
  一批：本仓库丢的是 **§7.4.3 / §7.4.4 / §8.3 / §8.4**，即延迟不敏感原则与
  Connectivity 稀疏矩阵，**正好是 M3 的主题地盘**；且 §7.4.4 与 §8.4 恰是
  spec §5.2.6 第 2.b 条引作"上游确认项、不阻塞里程碑"先例的两节。
  ⇒ **一个为发现里程碑缺口而生的审计工具，其静默截断优先隐藏下一个里程碑的
  缺口。**违反框架 0.4.3 为 FB-13/14 立的"可见截断"约定，属本仓库 BUG-0028
  "分母静默缩水"同族
- FB-21/22 + 一条附带观察（**`docs-check` 的表格列数校验只覆盖 `doc/bugs.md`**
  ——写 FB-21 时误打一个字面量 `|` 使该行变 7 列，门禁照样通过）当日送达
  iverif-workflow 侧

**Not done**
- 三条反馈均未闭环（不阻塞本仓库任何工作）
- chain-audit 报出的 gap 一条未处置：1 sourceless（M0-01，上游 tb sanity，
  本就无 spec 条款可引）、5 parent-anchored、19 uncited、11/11 缺 spec_ref
  header。**这些是 M3 的输入，不是本 chunk 的欠账**——尤其 §5.2.6 无场景引用，
  正是 M3 错误路径场景要填的
- M3 场景清单未设计；四条 `ACCEPTED@M3` 债务未修

**Next**
- 派 **arch 设计输入卡：M3 场景清单**（错误路径 / decode error / 多配置回归）。
  输入已齐：spec §5.2.6 三层判据、chain-audit 的 uncited 清单（**含被截断的
  §7.4.3/§7.4.4/§8.3/§8.4——手工补回，不能只看工具输出**）、四条 ACCEPTED@M3
  的到期验收形态、REV-011 §4 G4（BUG-0025+0031 同卡修、守卫场景与 M3
  decode-error 场景同卡注册）
- M3 大概率需要引入真正的 constrained-random：配置矩阵（spec §0 #3）铺开后
  纯定向激励组合数会爆炸，而"激励到不了硬情形导致旧绿灯空过"正是本仓库已栽
  过四次的地方（BUG-0018/0023/0024/0031）。附带效果：`CONSTRAINT_BUG` 这一
  taxonomy 类目前是**结构上不可能**（全仓无一个 `constraint` 块、无一处
  `randomize()` 调用，`axi_txn.sv:15-20` 的 `rand` 限定符是死装饰）

**How verified**
- `make fw-check` 绿（0.6.0，26 files pinned）；`make docs-check` 绿
- FB-21 的"空集"是**实测**而非印象：grep 两式于三处判据来源载体，无命中；
  并逐行读 `make signoff-check` 全部输出（机器 1-3 + 人工 4-7）确认未提及
- FB-22 的 4 条丢失项是**独立复算**得到的，不是从工具输出反推：用与
  `docs.py` 同构的正则重算 `uncited`，得 19 条、前 15 条与工具输出逐字相同、
  尾 4 条为 §7.4.3/§7.4.4/§8.3/§8.4
- 0.6.0 的 pull 范围逐 diff 核对：`docs.py`(+74) / `evidence.mk`(+7，新增
  `chain-audit` target) / `dispatch/SKILL.md`（FB-19 例外条款）/ manifest /
  iverif.json + 4 个重新渲染的 agent 文件，无外溢

## [0.3.0] 2026-07-28 M2 里程碑签核 PASS，收官转入 M3

**Done**
- **M2 签核 PASS**（`doc/evidence/v0.2.5/signoff-M2.md`，rev 新实例——REV-011
  作者不得签自己裁的债）。`make signoff-check` 四项全绿：机器条件 1/2/3 +
  `[yes] signoff file`
- 签核人**没有接受"树未动故条件 2 无需重跑"这条转述**（那是我在卡里给的环境
  事实）：独立重跑 `make regress` 得 11/11，重写 `sim/result_summary.txt` 后
  `git status` 不变脏 ⇒ 与登记证据逐字节相同。并核对分母——`regress.list`
  11 行 ↔ testplan ✅ 11 行、差集为空（BUG-0028 guard 指派给签核人的动作已履行）
- **rubric #5 的证伪是真做的**：废弃分支 `rev011-falsify-scratch` 上把 BUG-0027
  的原缺陷放回 `tb/scoreboard_refmodel.sv`（删掉完成认领 `foreach` 里的
  `break;`），`m2_or03_guard_test SEED=1` ⇒ **`UVM_ERROR: 336` /
  `stall(C5.1/C5.2): violations=336`**，与详情页基线精确相符；复原后归零、
  `SB_SUMMARY` 与登记证据逐字段相同，分支已销毁、工作树干净。选它是因为它守的
  是**七行 M2 场景共用的判决锚点**
- **rubric #7（0.5.3 新条）首次实战，四条 `ACCEPTED@M3` 全数通过**——签核人是
  **带着推翻意图**去查的，12 项承重事实无一得手：BUG-0024 的假红构造三个结构
  前提逐条验证（`stall_sva.sv:131` 无条件覆写 / `:273-283` 合取式里确实没有
  `w_id_open[completing_id]` 项 / `:120-127` 复位只清 `*_id_open`）；BUG-0031
  的三条 grep 事实推翻不了；BUG-0025 的否定性证据复核（`grep -in
  "err_slv|error slave|decode error" axi_demux.md axi_mux.md` = **空集**，
  xbar.md L33/L35/L86 三处引文逐字属实，spec 应用文本与提案逐字相同、无 RTL
  来源）；BUG-0018 的 M4→M3 提前推理成立（`doc/spec.md:25` 六类确不含
  covergroup）。无顺延条目（`ACCEPTED@M<n>` 今日首用），已按 rubric 明确确认
- **一处超出既有记载的发现**：BUG-0018 的盲区差点动摇 **M2-WO01**——其非空转
  判据要求"≥2 不同源 AW 未决"被激励到，而 covergroup 侧 `cp_w_contention` 恰被
  该盲区打空（50%，只填 `single_source`）。实测证明判据由 assert 维度独立承担：
  `axi_xbar_worder_sva.sv:107` 在 master 端口 0 上 `207 attempts, 46 match`
  （同场景 [1..7] 全 0），与 WO01"多源汇聚同一 master 端口"的构造精确吻合
  ⇒ 豁免成立，✅ 不动摇
- REV-011 两条交接条件均已执行，且签核人把 §5.4 那条**推广**成了一张 8 行的
  **判决活性矩阵**——此前记载里只有 CFG01 与 TL02 两个孤点
- **登记 FB-20**（annoyance，由签核人报出）：**终态行携带的未兑现义务对
  `signoff-check` 条件 3 完全不可见——终态即免检**。实例 BUG-0030（WONTFIX，
  却挂着"`LD_LIBRARY_PATH` 必须*恰为*"是否属过度归纳的未做实验）。与 FB-18(b)
  是同一缺口的两侧
- 版本 0.2.5 → **0.3.0（M3）**，tag `v0.3.0`

**Not done**
- 四条 `ACCEPTED@M3` 债务本身未修（0018/0024/0025/0031）——**到期点就是 M3
  签核**，届时 `docs.py:855` 会拦，且不得续期（顺延须重走仲裁，rubric #7）
- BUG-0030 的"恰为"二值实验未做（需 FSDB，已登记为守卫义务 + FB-20）
- M3-TL01 已注册未落地；M3 场景清单尚未设计
- **框架 0.5.4 尚未 pull**（FB-19 已 fixed@0.5.4）——签核卡跑完前刻意不拉，
  避免在其脚下换掉判据来源；现在可拉

**Next**
- `make fw-pull` → 0.5.4
- 派 arch 设计输入卡：**M3 场景清单**（错误路径 / decode error / 多配置回归）。
  两条前置已备好：spec §5.2.6 已定案（译码未命中事务的保序地位三层判据），
  BUG-0025 + BUG-0031 应**同一张修复卡**且其守卫场景与 M3 decode-error 场景
  在**同一张 arch 注册卡**里登记（REV-011 §4 G4）
- 签核人留的两条 M3 指导：(1) `axi_xbar_stall_sva` 的判决活性矩阵须在 M3 新
  场景落地后**重做**；(2) **§5.2.6 2.b 的非判决 cover 是 M3 的硬性抽查项**
  ——M3 主题即错误路径，它缺席时"显式排除"与"忘了写"在报告上同形

**How verified**
- `make signoff-check` 四项全 `[PASS]`/`[yes]`；`make docs-check` / `make
  fw-check`（0.5.3，26 files pinned）绿
- 签核记录 `doc/evidence/v0.2.5/signoff-M2.md`（46 KB）含机器条件输出原文粘贴、
  抽查 4/5/6/7 各自的引证、残留风险 R1–R7、判决 **PASS**
- 判 PASS 而非 conditional 的理由（签核人原文口径）：查出的每一处残留风险
  **都已有登记载体与到期点**，没有一条属于"新发现且无人认领"或"须在 M2 内补做
  才能让 ✅ 成立"；八行 ✅ 的判决锚点均被验证为**存在、非空转、且可变红**
- Taxonomy-class anomaly：**no**。三处候选追查后判定不构成新行，逐条留痕于
  签核记录 §10（`cg_stall` 的 `SC_NONE` 无 bin 是有意设计；stall_sva 空转的成因
  已分属 BUG-0024/0025/0031；BUG-0030 的待兑现实验已在其详情页 `:103-110`）
- 派卡规则偏离（FB-19 那处）经签核人裁断：**未损害本次签核**——rubric #5 本就
  命令签核人自跑同一命令、跑出的 22 条与索引逐条相符；省下的预算实际用在读
  10 份 raw log 与 6 个源文件上，而那正是全部实测结论的来源

**这一轮最该记住的一件事**：本轮三条框架反馈（FB-18/19/20）指向的是**同一个
形状**——机制把最后一道防线放在执行者的自觉上。FB-18(b) 是 ACCEPTED 的
rationale 无人复核，FB-19 是 orch 自行裁量要不要遵守派卡规则，FB-20 是终态行
的未兑现义务无人看见。三次都靠自觉挡住了，三次都说明**凡是需要靠自觉的地方，
就是规则该补的地方**——这句话已入框架 CHANGELOG。与 0.2.1 那轮"看到绿灯要先问
它覆盖了什么"互为表里：那条问的是**门禁的覆盖面**，这条问的是**门禁之外靠什么
兜底**。

## [0.2.5] 2026-07-28 拉框架 0.5.3：FB-18 当日闭环，M2 签核卡解除暂停

**Done**
- **`make fw-pull` → 框架 0.5.3**，`fw-check`（26 files pinned）/ `docs-check`
  双绿。pull 只动 4 个文件（+4 个重新渲染的 agent 文件），逐 diff 核对无外溢：
  `workflow/signoff/rubric.md`、`scripts/docs.py`、`scripts/iverif.manifest.json`、
  `iverif.json`
- **FB-18 → `fixed@0.5.3`**（框架 commit `12b1548`），两半全采纳：
  - (a) rubric 机器条件 3 同步为 "terminal **or unexpired `ACCEPTED@M<n>`**"
  - (b) 新增人工抽查**第 7 条**（`docs.py --signoff` 同步打印，实测已见）：
    "each `ACCEPTED@M<n>` row: the cited REV record states a *falsifiable*
    rationale …… Carry-overs were re-arbitrated — never auto-extended — and
    say why the previous due date slipped"
  ⇒ 本仓库 REV-011 §4 G3 的项目自立规则**入 canon**，§5.4 作为参考形状记入框架
  CHANGELOG；框架侧另加 fuse 钉住 rubric/工具在条件 3 与第 7 条上的永久一致
- **FB-11 → `fixed@0.5.2`**：gate 自证教义按本仓库送出的**对抗原型证伪结论**
  （stamp 候选形态的两个洞 + "elaboration done" 在 VCS O-2018 根本不存在）
  全文重写进框架 deferred 台账；本仓库 `sim/Makefile`（BUG-0022 的无条件重跑 +
  逐文件执行证明）被记为参考实现。本仓库原待办两项已随 BUG-0022 完成，无欠账
- **BUG-0030 上游订正落页，但**不**关闭**：框架 0.5.2（`iverif-workflow@68a7e83`）
  承认尾冒号是**快照缺陷而非环境约束**，`vcs-2018.mk` 改条件拼接。本仓库实测该
  fragment 单独展开确已无尾冒号。**但框架"`env -i` 绕法可退役"的结论未采信**：
  本页判据写的是"必须**恰为** `$VERDI_HOME/share/PLI/VCS/LINUX64`"，而
  `sim/Makefile` 走完整 include 链后实测仍带 VCS lib 前缀 ⇒ **仍不"恰为"**。
  尾冒号与"恰为"是两件事，上游只修了前者；当初的二分定位是逐项**加**变量做的，
  没测过"带无关前缀但无尾冒号"这一形态 ⇒ 二者未经实测无法区分。维持 WONTFIX，
  并在其 `## regression_guard` 登记一项**待兑现的附带义务**（下一张需要 xdebug
  的卡本来就会产 FSDB，顺手做一次二值实验：成功则绕法退役、本条转 CLOSED 走
  FB-16 的 `CMD=`/`EXPECT=` 形态；失败则"恰为"成立、绕法保留）

**Not done**
- M2 签核未做（本 chunk 只解除其前置阻塞）
- BUG-0030 的二值实验未做（需 FSDB，不为不阻塞门禁的终态条目单独烧一次
  编译+仿真；已登记为守卫义务，不是遗忘）
- 四条 ACCEPTED@M3 债务本身未修；M3-TL01 未落地

**Next**
- **派 M2 签核卡**（rev，新实例——REV-011 作者不得签自己裁的债）。三条交接条件：
  1. rubric #4"再读一个被豁免的洞"**明确挑 BUG-0018**（REV-011 §3.3 指定）
  2. **不得**把 `axi_xbar_stall_sva` 的通过计为 M2-CFG01 的独立证据——84/84
     零命中即其空转的机械证明（REV-011 §5.4）
  3. rubric #7 是**新条**，四行 ACCEPTED@M3 全部落在它的抽查范围内
- 签核 PASS 后 `make bump-minor` → 0.3.0 / M3 + `git tag`

**How verified**
- `make fw-check` 绿（0.5.3，26 files pinned）；`make docs-check` 绿
- 新 rubric 逐条读过：条件 3 措辞已含 "or unexpired `ACCEPTED@M<n>`"，人工抽查
  第 7 条存在且 `make signoff-check` 尾部确实打印它（**不是只改文档没改工具**）
- `make signoff-check` 条件 1/2/3 全 PASS，仅余 `[not yet] signoff file`
- BUG-0030 的上游修法是**实测**而非采信：`make -f -` 求值一个只 include 该
  fragment 的临时 Makefile，父变量为空时结果恰为单一路径；对照 `sim/Makefile`
  完整链的实测值带 VCS lib 前缀——正是这个对照支撑了"不采信绕法退役"的判断
- `make guards FILES="sim/Makefile"` 7 条命中，含 BUG-0030 的新增待兑现义务

## [0.2.4] 2026-07-28 FB-18 回流并阻塞 M2 签核：ACCEPTED 只落到机器侧，rubric 两处未同步

**Done**
- 组 M2 签核卡时核对判据来源，发现 **FB-18（blocking）** 并登记 +
  当日送达 iverif-workflow 侧（session「工作流反馈审查」）。两半：
  - **(a) 字面矛盾**：`workflow/signoff/rubric.md:14` 机器条件 3 仍写
    "All bug rows are in terminal states (`CLOSED / TB_BUG / SPEC_CHANGED /
    WONTFIX`)"，而 `scripts/docs.py:877` 已是 "all bugs terminal **or
    ACCEPTED-unexpired**"。0.5.0 改了 `failure_record.md` / `docs.py` /
    `evidence.mk`，**漏了 `rubric.md`**。本仓库正好有四行 `ACCEPTED@M3`
    ⇒ 认真读判据来源的 rev 会判条件 3 不满足，与它自己跑出的 `[PASS]` 冲突。
    按工具走则判据来源形同虚设（连带贬值 rubric #5"必须真做一次证伪"那类
    **只存在于 rubric、无机器背书**的条目）；按 rubric 走则里程碑签不掉
  - **(b) 更实质**：rubric **没有任何条目**要求签核人复核 ACCEPTED 的
    rationale。机器只验两件形式——行内含 `REV-`（`docs.py:489`）、目标里程碑
    未过期（`docs.py:855`）；那份 rationale 是否真的存在、是否可证伪、上一轮
    到期判据是否兑现，**无人查**。而 rubric #6 对 spec debt 恰有同构条目，
    FB-17 提案时正是引它作先例，落地时没推广到 bug debt 这一侧
- 建议两条：机器条件 3 同步措辞；新增人工抽查第 7 条（与 #6 同构，要求
  rationale 存在 + 给出可证伪判据 + 顺延须说明上次判据为何未兑现）。并把
  `doc/review/REV-011.md` §5.4 作为合格形状的参考实现一并送出

**Not done**
- **M2 签核卡按用户指令暂停派发**，待框架闭环 FB-18 → `fwsync --pull` 后再派。
  理由：拿一份已知会误导的判据来源去派签核卡，与 FB-11 那句"没看见错 ≠
  查过了"是同一族错误。绕法（在卡里写明"以 docs.py:877 为准"）存在但没用——
  那等于让项目侧口头覆盖框架文档，不是项目该有的权限
- 四条 ACCEPTED@M3 债务本身未修（语义即如此）；M3-TL01 未落地

**Next**
- 等 iverif-workflow 侧闭环 FB-18 → `make fw-pull` → `make fw-check` 复绿
- 然后派 M2 签核卡（REV-011 交下的两条硬性交接条件不变：rubric #4 明确挑
  BUG-0018；不得把 `axi_xbar_stall_sva` 的通过计为 M2-CFG01 的独立证据，
  84/84 零命中即其空转的机械证明）

**How verified**
- 漂移是逐行比对确认的，非印象：`rubric.md:14` 与 `docs.py:877` 两处原文并列
- `make docs-check` 绿（FB-18 行 6 列）；`make fw-check` 绿（0.5.2，26 files
  pinned——**框架文件一字未改**，本条只走回流，不本地修补）
- `make signoff-check` 条件 1/2/3 仍全 PASS、仅余 `[not yet] signoff file`
  ——即本次暂停**不是**因为机器条件退化，而是因为人工判据来源不可用
- 自 `594bf94`（0.2.1）以来 `tb/`、`sim/` 一字未动，11/11 回归证据与当前树
  逐字节一致，签核恢复时条件 2 无需重跑

## [0.2.3] 2026-07-28 REV-011 台账落地：四条债务转 ACCEPTED@M3 + 新登 BUG-0031，signoff-check 条件 3 转绿

**Done**
- **REV-011 条件 C-2/C-3/C-4 落地**（C-1 spec 部分见 0.2.2）：
  - **C-2 新登 BUG-0031**（TB_BUG）：`tb/sva/axi_xbar_stall_sva.sv:99-100` 调
    `decode_mst_port(aw_addr, **ADDR_MAP**, …)`，地址表取编译期 localparam，而
    `tb/sva_bind.sv:33-35` 该模块**结构上拿不到** `cfg_if`（隔壁 `:41-47` 的
    `axi_xbar_route_sva` 却接了）。`design-prompt/sva_bind.md` §3 明文要求改传
    运行时活值表——函数签名已改（`xbar_types_pkg.sv:148` 收 `amap` 形参），
    **调用点没改，要求只落实了一半**。M2-CFG01 确实在运行时改表
    （`seq_lib.sv:993-996`，rule 0 的 idx 0→5）⇒ 重配后命中 region0 的事务
    `w_id_tgt` 记 mst0、实际 mst5。**误差双向（可假红）**，与 0023/0024/0025 的
    单向漏检不同类
  - **C-3 三条 `## regression_guard` 改写**：0024 的 (a) 路线旧口径
    （"`w_lost_now` 归零即修复"）**明文作废**——(b) 路线下该数不必归零，两种
    口径不得并存；0025 由"待 spec 结论"改为按 §5.2.6 定形的三段式；0018 补入
    M3 归属理由与逐 test 基线数
  - **C-4 三处订正同步进详情页正文**：0024 `## symptom`（"只漏检不会假红"
    不成立，附四步假红构造）、0025 `## symptom`/`## rca` 第 3 点/`## 对已登记
    证据的影响`（"读到 X 恒假"错、"从未被触发"错）、0018 `## symptom` scope
    补 `cg_tx_limit`
  - 额外订正一处 rev 未点到的矛盾：**BUG-0025 的 `min_repro` 列**原值是
    "无（当前激励集全为译码命中路径，本条不可触发）"，与 REV-011 §5.2 的实测
    直接冲突，已改为 `make run TEST=m2_cfg01_reconfig_test SEED=1`
- **BUG-0031 的状态退回 rev 补裁**（orch 不自填）：`ACCEPTED@M<n>` 的 rationale
  按 schema 须 rev 签名，而 `docs.py:489` 只校验行内含 `REV-`、校验不了那份
  rationale 是否真的存在——orch 自行落 ACCEPTED 恰是 REV-011 §4 G3 警告的
  "ACCEPTED 变成新地毯"。rev 补裁 **`ACCEPTED@M3`**（REV-011 §5.4），并给出
  三条**可被同样 grep 推翻**的依据：(1) 全仓只有 `tb_top.sv:59` 与
  `seq_lib.sv:994` 两处写 `cfg_vif.addr_map` ⇒ 除 CFG01 外所有场景编译期表恒等
  于活值表；(2) 唯一用到陈旧表的 `m2_cfg01_reconfig_test_1.log` 里该模块
  **84 条 cover 行全部 0 match**（对照 or01 同名 cover 非零 ⇒ 非日志假象）⇒
  结构性空转、贡献零判决；(3) testplan M2-CFG01 的判决锚点是 scoreboard +
  独立 SVA C3.1，**不含** C3.2。任一条被证伪则该裁决失效、须改判 M2 内修
- **`make signoff-check` 条件 3 转 PASS**：四条 active bug（0018/0024/0025/0031）
  各自获得一份 rev 签名、各自带证伪条件的排期理由，到期点**均为 M3 签核**
  （`docs.py:855`：n ≤ 被签核里程碑即拦）

**Not done**
- M2 里程碑签核（`doc/evidence/v0.2.*/signoff-M2.md`）未做——`signoff-check`
  仅剩 `[not yet] signoff file` 一项
- 四条 ACCEPTED 债务本身未修（这正是 ACCEPTED 的语义：已分析、已排期、未做）
- M3-TL01 已注册但未落地

**Next**
- 派 **M2 签核卡**（rev，新实例）。REV-011 交下来两条**硬性交接条件**：
  1. rubric 第 4 条"再读一个被豁免的洞"**明确挑 BUG-0018**，不得绕开它另挑
     好看的 bin；
  2. **不得**把 `axi_xbar_stall_sva` 的"通过"计为 M2-CFG01 的独立证据——
     84/84 零命中即其空转的机械证明；该场景证据链是 scoreboard
     （`route: match=30 mismatch=0`）+ `axi_xbar_route_sva`(C3.1)。与 BUG-0024
     的 b-3 同一条纪律：任何"SVA 也过了"必须附上那次运行的空转/范围见证
  rubric 第 5 条用 `make guards FILES=<里程碑触及文件>` 定复核范围，至少证伪一条
- M3 开工时：BUG-0025 + BUG-0031 **同一张修复卡**（同一调用点的两个实参，
  REV-011 §4 G4），其守卫场景与 M3 decode-error 场景应在**同一张 arch 注册卡**
  里登记（构造要素重叠）

**How verified**
- `make docs-check` 绿；`make fw-check` 绿（框架 0.5.2，26 files pinned）
- `make signoff-check` 条件 1/2/3 全 PASS，仅余 `[not yet] signoff file`
- `make guards FILES="tb/sva/axi_xbar_stall_sva.sv"` **8 条命中**（原 7 条 +
  新登的 BUG-0031）——新 guard 的注入机制生效得证，下一张动该文件的卡会自动
  收到它
- 台账终态核对：0018/0024/0025/0031 四行均 `ACCEPTED@M3`，各行文本含 `REV-011`
  （`docs.py:489` 的两道校验：须含 `REV-`、n ≥ 当前里程碑）

**这一段最该记住的一件事**：登记 BUG-0031 让刚刚转绿的条件 3 **立刻又变红**，
而把它填成 ACCEPTED 只需我改一个单词、机器完全查不出来。门禁在这里挡不住
orch——挡住的是"ACCEPTED 的 rationale 必须由 rev 签名"这条**约定**，以及
rev 交回来的那三条**可被 grep 推翻**的依据。可证伪性是自愿交出来的，不是被
门禁逼出来的；这与 REV-011 §4 G1 的"沉默的通过"是同一枚硬币的两面。

## [0.2.2] 2026-07-28 REV-011 spec 条款落地：译码未命中事务的保序地位（BUG-0025 SPEC_ISSUE 半边裁决）

**Done**
- rev 卡 **REV-011** 交付（`doc/review/REV-011.md`）：对 M2 仅剩的三条 active
  bug（0018/0024/0025）做终态再裁决，并**当场完成** BUG-0025 的 SPEC_ISSUE
  半边仲裁。本 chunk 只落地其中的 spec 部分（C-1），其余四项条件（C-2 新登
  BUG-0031、C-3 改写三条 regression_guard、C-4 详情页正文订正、C-5 另派签核
  卡）留给后续 chunk
- **应用条款提案 P-REV011-1**：`doc/spec.md` §5.2 新增第 6 条「译码未命中
  事务的保序地位」——(1) 走 §3.3 default master port 的事务其目标是**真实
  master 端口**（xbar.md L35），§5.2.1-4 原样适用；(2) 走 §4 decode error
  slave 的事务分两层：**完整 ID 维度可断言**（同一 slave 端口上完整 ID 相同、
  同方向事务的 B/rlast 完成序须与接受序一致，**无论**路由去向；依据 §1 +
  §4.5 + §5.2.3 + xbar.md L86 "same ID and direction must remain ordered"
  ——该义务只依赖 slave 端口是 AXI4 接口、不依赖内部路由），**低位 ID 桶
  维度不可断言**（完整 ID 不同且其一走 err_slv 时，次序关系许可来源未定义：
  xbar.md §Ordering and Stalls 只约束"不同 master 端口"、§Decode Errors 未涉
  次序、demux.md/mux.md 对 err_slv 无记载 ⇒ 不得写断言，以非判决 cover 留痕 +
  列上游确认项 + 不阻塞里程碑，同 §7.4.4/§8.4 处置）；(3) checker 对该排除
  必须**显式引本条**，不得以"未登记⇒读默认值⇒比较恰好为假"实现
- **应用条款提案 P-REV011-2**：`doc/spec.md` §4 新增第 6 条一行交叉指针至
  §5.2.6。§5.2.1-5 与 §4.1-5 正文一字未动（surgical）
- Change record 第 6 行登记 + `docs.py --pin-spec` 重 pin（`doc/spec.sha256`
  `bfe8542b…` → `0fd431f7…`）

**Not done**
- REV-011 的其余四项 orch 条件（C-2/C-3/C-4/C-5）——下一 chunk
- 三条 bug 的 `ACCEPTED@M3` 状态改写虽已由 rev 卡在工作树中完成，但**不在本
  commit**：本 chunk 严格限定为 spec 应用，bug 台账变更随 C-2/C-3/C-4 一并
  提交，以免 spec 变更与台账变更混进同一个不可分割的 commit
- M2 里程碑签核（signoff-M2）未做

**Next**
- C-2 登记 BUG-0031（`stall_sva.sv:99-100` 编译期 `ADDR_MAP` 译码 vs
  `sva_bind.sv:33-35` 未传 `cfg_if`——design-prompt §3 的要求只落实了一半，
  误差**双向可假红**）+ C-3 三条 regression_guard 改写 + C-4 详情页正文订正
- C-5 M2 签核卡（rubric #4 明确挑 BUG-0018 作"再读一个被豁免的洞"，#5 须真做
  一次守卫证伪）

**How verified**
- `make docs-check` 绿；`make fw-check` 绿（框架 0.5.2，26 files pinned）
- 结构核对：新条款落在 `doc/spec.md:201`（§5.2 第 6 条，位于原第 5 条之后、
  `### 5.3` 之前）与 `doc/spec.md:151`（§4 第 6 条），编号连续无跳号；
  Change record 第 6 行列数 = 6，与表头一致（FB-14 那类静默串列的自检）
- pin 一致性：`sha256sum doc/spec.md` 与 `doc/spec.sha256` 相符
- spec-from-RTL 红线：REV-011 §1.3 明确声明未读 `axi_xbar.sv`/`axi_demux.sv`
  实现体，条款的许可来源清单全部为 `vendor/axi/doc/*.md` 与 spec 内部章节；
  `axi_mux.md` 对 err_slv 无记载被作为"未定义"的**否定性证据**引用

## [0.2.1] 2026-07-28 M2 场景收官 + 框架五版回流 + bug 台账 12→4：签核前最后一段

**Done**
- **F-M2-08 功能覆盖采集基建落地**：`tb/functional_coverage.sv` 六个 covergroup，
  采样点全部取自既有 monitor/scoreboard 的判决状态（单一事实源，未新增第三套解码）。
  merged 后 `cg_addr_reconfig`/`cg_w_order` 100%、`cg_stall` 88.9%、`cg_tx_limit` 80%，
  其中 `above_max_11/12` 各命中 12 次——BUG-0016 的越限现象被 covergroup 独立留痕。
  派卡前发现四份 design-prompt 落后于 BUG-0016 重 pin 后的 spec（REV-007 §5 只列了
  spec 正文、漏了设计输入同步），先派 arch 再锚定 + REV-008 增量门禁才放行。
- **M2-OR03 守卫场景落地**（testplan 由 7 条增至 8 条，全 ✅）：为 BUG-0023/0024 定向
  构造「同完整 ID 多笔在飞 + 目标跨 master 端口切换」。BUG-0023 守卫闭环——
  `w/r_collide_kept_now` 由既有 9 场景的 0/0 变 192/264，且去掉同沿保护后双双归 0
  （证伪成立，不是恒真空守卫）。写方向原本打不中的原因值得留档：均匀 `AxLEN=0` 的
  写流与 B 流锁相，同沿永不发生；按 `k%2` 交替 `AxLEN` 扫相位后才命中。
- **`make lint` 门禁从「三层坏」修到可用**：BUG-0014（缺 `-assert svaext`）→ 暴露
  BUG-0019（缺 `-top`）→ 暴露 BUG-0021（285 条既有告警）→ 分诊出 11 条真缺陷
  （F1/F2/F3，全在 `tb/sva/`）→ 修复期又撞出 BUG-0022（增量假绿）。BUG-0022 的修法是
  **无条件重跑 + 逐文件执行证明**（枚举源是 `find ../tb` 而非 flist，故 flist 缩水也挡得住）。
- **BUG-0020 修复**：`make run … FSDB=1` 可选波形路径，默认路径成本逐项对齐未变；
  `xdebug session.open` 首次在本仓库成功（`mode: waveform`）。
- **框架 0.3.0 → 0.4.5 连拉五版**，FB-10~FB-17 八条回流，其中 FB-10（guard 注入）
  当日进入 canon 0.4.1：`regression_guard` 新增 `paths:` glob、`make guards` 纯路径求交、
  dispatch + rubric #5 双消费挂点。本仓库 18 条存量 guard 全部回填 `paths:`，复验
  `make guards FILES="tb/sva/axi_xbar_stall_sva.sv"` 命中含 BUG-0015——**被 F1 违反的
  正是它**，缺口关闭得证。此后每张卡都按该机制注入，DV 反馈「BUG-0013 没有它我很可能会漏」。
- **bug 台账 12 条 active → 4 条**（REV-010 逐条裁决 + 复验）：5 条 CLOSED（rev 在
  一次性 worktree 内亲手证伪，非仅看日志）、3 条 WONTFIX（0017 版本墙 / 0021 附守卫
  改写 / 0030 环境约束）、2 条由 orch 复验后 CLOSED（0020/0022）。新增
  `doc/lint-baseline.md` 作为 BUG-0021 WONTFIX 的守卫载体（285 条按类别×文件×行登记），
  `make lint-diff` 为其执行入口。

**Not done**
- **M2 未签核**：`signoff-check` 条件 3 剩 4 条 active——BUG-0018（covergroup 采样相位，
  rev 判为 **M4** 前置而非 M3）、BUG-0024（`w_id_open` 单 bit，须择 REV-010 §4 G4 的
  (a) 重建队列 / (b) 正式收窄 SVA 判决范围）、BUG-0025（含**必须先仲裁的 SPEC_ISSUE
  半边**：error slave 响应能否越过更老响应，spec 未定义）、BUG-0029（等框架 FB-16）。
- `doc/evidence/v0.2.0/signoff-M2.md` 未出（rubric 人工抽查三项未做）。
- M3-TL01 已注册但未落地（BUG-0010 守卫，其 guard 原文钉在 M3/M4，不挡 M2）。

**Next**
- BUG-0025 的 SPEC_ISSUE 半边派 rev 仲裁——**必须在 M3 场景被设计之前**完成，
  M3 判据形态取决于结论。
- BUG-0024 择 G4 的 (a) 或 (b)；BUG-0018 落终态（M4 前置的书面接受理由）。
- 四条清零后派 rev 签核卡（rubric #5 现要求「里程碑触及文件命中的全部 guard 入围复核 +
  至少证伪一条」，用 `make guards` 定范围）。

**How verified**
- `make regress` **11/11 PASS**（此前只有 3/3——BUG-0028：七个 M2 场景自落地起从未进过
  回归清单，`make regress` 报绿而分母静默缩水，本轮补齐并登记
  `doc/evidence/v0.2.0/result_summary.txt`）。
- 八条 M2 证据全部重跑重登记（框架 0.4.3 起每条含 5 个 SVA 模块的聚合行，
  `axi_xbar_stall_sva.sv: 60 properties/covers, 2640 attempts, 24 match` 首次进入证据——
  正是 BUG-0026 说「从来就不在证据文件里」的那个数字，该条据此 CLOSED）。
- orch 独立复验 BUG-0020/0022（非修复方）：lint 连跑三次 exit 2/假绿签名归零/
  `lint-diff` 225/225；默认 `make run` 不产波形而 `FSDB=1` 产出 345 KB 且 xdebug 可开 session。
- `make docs-check` / `make fw-check`（框架 0.4.5，26 files pinned）全绿。

**这一轮最该记住的一件事**：`make lint` 从 M0 起就是坏的，因为它**不在任何门禁清单里**——
没有机制去验证「验证工具本身是否有效」。同一形状在本轮出现了五次（lint 假绿 / fwsync 缺
profile 静默降级 / bugs.md 表格错位后门禁照过 / regress 分母缩水 / BUG-0015 的 guard 写下了
却没有强制消费）。前四条已回流框架成 FB-11/12/14 与 BUG-0028，第五条促成了 0.4.1 的
guard 注入机制。**看到绿灯要先问它覆盖了什么。**

## [0.2.0] 2026-07-27 M1 里程碑签核 PASS：M1-02 落地 + BUG-0008/0009 终态 + regress 覆盖补全，转入 M2

**Done**
- DV 卡：M1-02（ID 前缀响应路由 smoke）落地——`tb/seq_lib.sv`/`test_lib.sv`
  新增 `m1_02_id_prefix_{seq,vseq,test}`（多 slave 端口共享低位 ID、各指
  不同 master 端口，规避 §5.2.1 假冲突 stall）；`tb/scoreboard_refmodel.sv`
  新增 C3.2 源端口响应路由判据（`resp_expect[]`，独立于既有 payload/resp-
  code 判据，可捕获 B 通道无 payload 的跨端口错送）；evidence
  `doc/evidence/v0.1.2/M1-02.log`（96/96/96 match），testplan M1-02 🔲→✅
- 落地期发现并修复 **BUG-0009**（TB_BUG，CLOSED）：`mstport_monitor` 单槽
  AW/W 配对方案在 master 端口 AW-W 解耦/多写 burst 汇聚时错配（第二个 AW
  覆盖首个未收尾 burst 的元数据）；改 AW FIFO 队列配对（`aw_q[$]`，镜像
  `mstport_responder` 既有写法）；同轮修复 scoreboard `pending_by_id` 键加
  方向位（读写独立通道，同 id 不再别名）。DUT 全程功能正确（resp-route
  C3.2 96/0）。detail page `doc/bugs/BUG-0009.md` 补齐（orch 发现该行初始
  漏建详情页 + taxonomy 标签误用非正典的 "DV_ISSUE"，均已订正为 TB_BUG）
- rev 卡 REV-004：仲裁 BUG-0008（M0 三条存量证据 `## Key check lines` 段
  为空）处置——赞同不追溯重写、不改 signoff-M0，并纠正终态应由 OPEN 转
  **WONTFIX**（已应用）；独立核验 CLAUDE.md 两处"本地重述→指针"收成
  （taxonomy 登记无条件、执行纪律→discipline.md）语义无损，本地仪式
  （`/closeout`+`git push`+等待指令）确认仍落在保留句里，未悄悄消失
- 补全 `sim/regress/regress.list`：M0 期只有 `upstream_sanity`，M1 落地后
  一直未跟进；补入 `m1_01_smoke_test`/`m1_02_id_prefix_test`（恰对应
  BUG-0007/0009 的 min_repro，满足清单自身"每个已闭合 bug 失败 seed 永久
  入列"的约定），`make regress` 3/3 PASS，`doc/evidence/v0.1.2/
  result_summary.txt` 登记，`make signoff-check` 机器条件三项转全绿
- rev 卡：M1 里程碑签核 `doc/evidence/v0.1.2/signoff-M1.md`——**PASS**（带
  2 项非阻塞残留风险：R1 已登记的 `v0.1.0/M1-01.log` 字节滞后于 BUG-0009
  后的当前树，功能面由回归摘要+详情页+签核三路独立复跑覆盖；R2 本轮改动
  提交前 `fix_commit` 为占位，随本次 closeout 提交回填）。人工抽查 5 对
  BUG-0009 做了真实的一次性废弃分支守卫证伪：回退 monitor 单槽版本后
  确定性复现"4 route 失配+7 dangling"登记签名，逐字节复原后丢弃分支

**Not done**
- M2（功能场景 + SVA + 功能覆盖）未开始
- BUG-0008 存量三条 M0 证据仍未重生成（REV-004 裁决为不重写，非待办）
- signoff-M1 R1：`doc/evidence/v0.1.0/M1-01.log` 未随 BUG-0009 修复重生
  （非阻塞，功能面已三路复验覆盖，留给后续视需要处理）

**Next**
- 派 arch 设计输入卡：M2 功能场景清单（保序/stall/decode error/ATOP 等，
  design-prompt C2/C5 已成文待激活）+ SVA 覆盖点规划
- M2 功能覆盖率采集基建（六类覆盖率路线图见 CLAUDE.md §6）

**How verified**
- 独立重跑 `make run TEST=m1_02_id_prefix_test SEED=1`（96/96/96 match，
  UVM_ERROR 0，SVA 0 failures）与 `make run TEST=m1_01_smoke_test SEED=1`
  回归（48/48/48，0 错误，新判据无回归）；`make regress` 3/3 PASS；
  `make signoff-check` 全绿（含 `[yes] signoff file`）；`make docs-check`/
  `make fw-check` 全绿；REV-004/signoff-M1 见 `doc/review/`、
  `doc/evidence/v0.1.2/`

## [0.1.2] 2026-07-27 框架 0.2.0 → 0.3.0 两轮回流闭环 + BUG-0008 补登

**Done**
- FB 首轮回流闭环：FB-1~FB-7 全部落入框架 0.2.1，本仓库 `fwsync --pull`
  两次（0.2.1 → 0.3.0），`doc/fw-feedback.md` 七行 `open` → `fixed@0.2.1`
  并加头注。实质拿回来的变化：`evidence.py` 非 UVM tb 摘要窗口 2 → 20 行
  + 关键行正则增补（FB-6）；`.claude/agents/de.md` 修复交付改置 FIXING，
  fix_commit 与 FIX_READY 归 orch 提交后回填（FB-5，绕行作废）；四角色
  交付报告新增强制字段"本卡是否命中 taxonomy 异常（含已绕过的）"
  + taxonomy 正典补"登记无条件"段（FB-7）；`vcs-2018.mk` 的
  `LM_LICENSE_FILE` 注释挑明是必须覆盖的占位值（FB-2）。
- 框架 0.3.0 带来 `workflow/discipline.md`（执行纪律五条，优先级高于便利、
  低于核心不变量与角色隔离），CLAUDE.md 与四个角色文件都指向它。本仓库
  自产的"小步快跑"被上收为正典 rule 5。
- 反漂移清理两处本地重述：CLAUDE.md §2 的 taxonomy 登记表述、以及那段
  自产"执行纪律"三条，都收成指向正典的指针，只保留本仓库特有的内容
  （M1-01 案例、落地判据含 `/closeout` 的本地仪式）。
- **BUG-0008 补登**（TOOL_ENV，OPEN）：`doc/evidence/v0.0.1/` 三条 M0 证据
  的 `## Key check lines` 段为空。此事 signoff-M0 抽检 R1 就发现了，却只
  进了 `doc/fw-feedback.md` FB-6 和评审记录，`doc/bugs.md` 一直没有行——
  与 BUG-0007 同一形状的可追溯性缺口，按"登记无条件"补上。

**Not done**
- 存量三条 M0 证据未重新生成。`doc/evidence/v0.0.1/` 是 signoff-M0 已签核
  指向的产物，用新抽取器覆写会改动被签核对象而签核记录无法同步重签；
  权衡后判定"摘要不全"轻于"签核指向的证据在签核后被改过"。是否重生成
  属 rev 裁决，orch 不自行 WONTFIX（路径写在 BUG-0008 的 `## rerun`）。
- M1-02 未动（scoreboard_refmodel / sva_bind 两行仍非 ✅）。

**Next**
- 派 rev 卡：① 裁决 BUG-0008 存量是否重生成；② 复核本轮两处本地重述收编
  是否有语义丢失。
- 派 DV 卡推进 M1-02。

**How verified**
- 每轮 pull 后 `make fw-check` + `make docs-check` 双绿（当前
  framework 0.3.0，26 个 pin 文件）；BUG-0008 行与详情页加入后 docs-check
  仍绿（FL 详情页非终态可部分填写，本页已按 schema 八段写全）。
- 框架侧 48 例自测全过（新增一例钉住 discipline.md 到位且两种 profile 下
  每个角色文件都指向它），framework master 与两个标签已推送。
- FB-6 的修复在框架侧有保险丝：还原窗口与正则后 48 例中恰好只有
  `test_plain_nonuvm_verdict_line_captured` 失败。

## [0.1.1] 2026-07-27 M1 首个场景：UVM env 骨架落地 + M1-01 smoke ✅

**Done**
- arch 设计输入卡：`doc/design-prompt/{tb_top,uvm_env,scoreboard_refmodel,sva_bind}.md`（每约束引 spec 章节）+ feature-matrix `F-M1-01~04` + testplan `M1-01`/`M1-02`（🔲）+ vendor 升级评估 `doc/vendor-upgrade-v0.39.10.md`（结论 Defer：v0.39.9→v0.39.10 对 axi_xbar 全部 spec 蒸馏来源逐字节相同，唯一差异为非行为的冗余 elaboration 断言删除 #407）
- rev 交付门 `REV-002`：M1 design-prompt 集放行（cleared for DV），未见 behavior-leak；`sva_bind.md` 两处引用瑕疵（PASS-with-notes，非阻塞）；vendor 升级 memo 结论逐条实测证实
- DV 卡：`tb/` UVM env 骨架（tb_top + slave/master agent + 地址路由/ID 前缀参考模型记分板 + SVA）落地，`sim/flist/tb.f` + `sim/Makefile`（按 TEST 名切换 M0 上游 tb / M1 UVM tb_top，M0-01 复现命令不变）；M1-01 smoke 通过（scoreboard route/resp 48/48 match、SVA 2119 assertions 0 failures、UVM_ERROR 0、自然终止），evidence 登记 `doc/evidence/v0.1.0/M1-01.log`；`sva_bind.md` 两处引用瑕疵随手订正
- 工具偏离处理：VCS-2018.09-SP2 拒绝 `bind <interface> <module>`（`Error-[IIM]`），DV 改直接例化挂 SVA；rev 独立复核 `REV-003`（含最小探针复现该报错签名）确认行为等价、放行，`sva_bind.md` C1.1 补订正说明，CLAUDE.md §4 补记该工具限制供后续卡参考
- 附带完成（同周期、独立提交推送）：README 新增"DUT 模块层级"小节（grep 例化关系逐级追至叶子/common_cells 基础单元）+ "数据流概览"讲解 + `doc/attach/axi_xbar_dataflow.svg` 示意图

**Not done**
- `M1-02`（ID 前缀响应路由 smoke）未做，仍 🔲；`scoreboard_refmodel.md` 里为 M1-02 预留的判决路径仍是 stub
- M1 里程碑未收官（尚缺 M1-02 + 里程碑签核）
- `FB-1~FB-6` 批量回流 iverif-workflow 框架仓库仍未做——里程碑边界约定时点已过一个版本周期，欠账中

**Next**
- 派 DV 卡实现 `M1-02`
- `FB-1~FB-6` 批量回流 iverif-workflow（已逾期一个周期，优先级提高）
- M1 里程碑收官（M1-02 完成后）

**How verified**
- 独立重跑 `make compile`（0 error/0×NCE）+ `make run TEST=m1_01_smoke_test SEED=1`（scoreboard 48/48 match、SVA 0 failures、UVM_ERROR 0，与 DV 交付报告一致）+ `make run TEST=upstream_sanity SEED=1`（M0-01 回归不变，Tests Failed 0）；`make docs-check`/`make fw-check` 全绿；`REV-002`/`REV-003` 见 `doc/review/`

## [0.1.0] 2026-07-27 M0 里程碑签核 PASS：基建+sanity+spec v0 收官，转入 M1

**Done**
- rev 全新实例（非本里程碑任何 review/fix 当事人）执行 M0 里程碑签核：机器条件 3×PASS 自跑复核 + 3 项人工抽查（抽查 4 覆盖闭合 N/A 但按精神等价核验目标机制命中；抽查 5 守卫证伪——一次性废弃分支 revert BUG-0006 修复、`make compile` 复现原 6×NCE 签名、清理分支；抽查 6 spec 债务清零核对 REV-001 §5 逐条裁决）
- 签核记录 `doc/evidence/v0.0.2/signoff-M0.md`：总体裁决 **PASS**，2 项非阻塞残留风险（R1 证据摘要窗口未捕获非 UVM 记分板判决行；R2 末拍在飞断言，良性）
- R1 回流 `doc/fw-feedback.md` FB-6（kernel/evidence.py，annoyance）
- `make signoff-check` 全绿（含 signoff 文件识别）；`make bump-minor` 0.0.2→0.1.0

**Not done**
- M1（UVM env + smoke，评估 v0.39.10 升级）未开始
- FB-1~FB-6 回流框架仓库（iverif-workflow）未做——里程碑边界批量回流的约定时点已到，尚待执行
- R1（evidence.py 摘要窗口）本身未修——按框架红线本仓库不改 scripts/，需上游修复

**Next**
- FB-1~FB-6 批量回流 iverif-workflow（里程碑边界回流仪式，见 CLAUDE.md §5）
- 派 arch 设计输入卡：M1 UVM env 骨架（tb_top + 多 master/slave agent + 地址路由参考模型记分板）+ 评估 v0.39.10 升级影响
- `git tag v0.1.0`

**How verified**
- `make signoff-check` 全绿（机器条件 3×PASS + signoff 文件 `[yes]`）；`make docs-check` / `make fw-check` 全绿；签核记录见 `doc/evidence/v0.0.2/signoff-M0.md` §5 裁决

## [0.0.2] 2026-07-27 DV 复验闭环：M0-01 ✅ + BUG-0001/0006 CLOSED

**Done**
- DV 复验卡（全新实例，closer≠fixer）：`make compile`（clean rebuild）0×Error-[NCE]、`make smoke TEST=upstream_sanity SEED=1` 自然终止零 mismatch（178296/178296，SVA 3198 assertions 0 failures）、`make regress` 1/1 PASS
- 三条 evidence 经 `make evidence` 机械登记：BUG-0001、BUG-0006、M0-01（均落 `doc/evidence/v0.0.1/`，line 1 replay + 生成戳）
- BUG-0001 FIX_READY → CLOSED；BUG-0006 FIX_READY → CLOSED；testplan M0-01 ❌ → ✅（状态格由 evidence.py 回填，非手改）
- `sim/result_summary.txt` 拷入 `doc/evidence/v0.0.1/`，`make signoff-check` 机器条件 1~3 全 PASS
- CLAUDE.md §2 新增原则"小步快跑"（Small closed loops, then stop）：长任务切小块闭环，完成即推送并等待用户指令

**Not done**
- M0 里程碑未收官：rev signoff 卡未派（`signoff-M0*.md` 缺失，`make signoff-check` 卡在人工抽检 4~6 项）
- FB-1~FB5 回流框架仓库未做

**Next**
- 派 rev 里程碑签核卡（覆盖闭合抽检 + guard falsification + SPEC_ISSUE 清单）→ signoff-M0 记录 → `make bump-minor` → tag v0.1.0
- FB 批量回流 iverif-workflow

**How verified**
- `make docs-check` / `make fw-check` 全绿；`make signoff-check` 机器条件 1~3 PASS（4~6 待 rev）；见 `doc/evidence/v0.0.1/{BUG-0001,BUG-0006,M0-01,result_summary}`

## [0.0.1] 2026-07-27 M0 基建首循环：vendor pin + 编译排雷 + spec v0

**Done**
- iverif-workflow 0.2.0 首次实战接入（copilot/en，正文中文约定见 CLAUDE.md §6）；fw-feedback.md 台账建立并登记 FB-1~FB-5
- vendor pin：axi v0.39.9 + 三依赖库（SHA 见 vendor/VENDOR.md），上游 tb/doc 按同 tag 补拉
- sim 基建：flist 三件套（floo 已验证 Bender 序）+ sim/Makefile（VCS-2018 workaround + SIM_OPTS_2018）
- 编译排雷：BUG-0001（P-001，$sformatf/genvar NCE，@1a15627）与 BUG-0006（P-002，struct 成员端口位宽 NCE 共 3 处，@8062976）均 FIX_READY，make compile 全过（simv 生成）
- spec v0：arch 蒸馏 → REV-001 评审（条件通过，C1~C5）→ 修订应用 → 重 pin（@cbd2b09）；四 spec 缺口（BUG-0002~0005）经 rev 裁决 SPEC_CHANGED（环境约束/延迟不敏感/采信主文档）

**Not done**
- M0-01 仍 ❌：DV 复验未跑（编译已通，仿真 + evidence 未执行——本循环按"小步快跑"在此暂停）
- BUG-0001/0006 未 CLOSED（等 DV 复验闭环，closer ≠ fixer）
- regress/result_summary 归档、rev 签核、M0 里程碑完成均未开始
- fw-feedback 回流框架仓库未做（FB-1~FB-5 全部 open）

**Next**
- 派 DV 复验卡：重跑 M0-01（make smoke）→ make evidence SCEN=M0-01 → make evidence BUG=0001/0006 闭环 → regress + result_summary 归档（顺带实证 FB-3 的 Summary 行悬案）
- 之后：rev 签核卡（含 P-001/P-002 补丁评审回填 VENDOR.md review 列）+ signoff-check + bump-minor → v0.1.0 tag；FB 批量回流 iverif-workflow

**How verified**
- make docs-check / fw-check 全绿（本块提交前复跑）；make compile 结论见 BUG-0006 root_cause 实证（out/simv 生成、comp.log 0×NCE）；spec pin=2637206e…（提交 cbd2b09）

## [0.0.0] 2026-07-27 scaffolded

**Done**
- fwsync --init (framework snapshot + doc seeds)

**Not done**
- everything else

**Next**
- M0 bring-up: vendor/flists/sim Makefile, spec v0

**How verified**
- make docs-check

