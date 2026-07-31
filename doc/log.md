# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

