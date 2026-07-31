# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.4.10] 2026-08-01 M4 收尾第二项：六类覆盖率基线重出（REV-016 条件2兑现），regress evidence 登记；M4 机器门禁 4 条中 2 条转 PASS

**Done**
- **DV 卡（L1/sonnet，fresh instance，纯测量不修复）**重出
  `doc/evidence/v0.4.9/M4-coverage-baseline.md`：核实现有 `sim/out` 覆盖率
  库不可信复用（`comp.log` 显示上次编译未带 `-cm`），`make clean && make
  regress COV=1` 全量重跑 26/26 PASS；BUG-0037 修复（`COV_DIR` 间接层）
  已让单条 `make regress COV=1` 正确按 7 个拓扑分流覆盖率库，7 组
  `make cov` 均 0 mismatch/CMR-VCINF/UCAPI-INSTANCEMISMATCH。六类基线数字
  较 v0.4.0 逐项对比：`axi_mux` 仲裁重试路径 Line/Branch 72.41/71.43→
  100/100（M4-AW01 之功，但**逐实例**核对后只有背压的那 1/8 实例真转绿，
  其余 7 个未变——如实标注避免过度解读模块级并集数字）；`axi_xbar` 顶层
  Toggle 29.63%→40.74%（M4-RC01 补齐 `en_default_mst_port_i` 的 1→0 方向）；
  `axi_atop_filter` FSM 两条状态机与 v0.4.0 完全相同、未见任何改善
  （M4 四条新场景均不涉及 AtomicStore/AtomicCompare，REV-017 条件 3 的
  书面豁免仍未兑现，本卡如实标注"转交 orch"）；`axi_xbar_unmuxed`/
  `axi_demux_simple` 的 AW 侧 valid-but-not-ready 类 assert 仍 0
  real-succeeded（与 M4-RC01 testplan 行"DV 核对项（非阻塞）"预告一致，
  未改善）。REV-016 澄清后首次单独测量 `addr_decode_dync`/
  `axi_demux_simple`/`axi_multicut`/`axi_cut`/`spill_register` 五个子
  模块（均 <90%，是"有 bin 需补场景"而非结构性 N/A）。无新 taxonomy 异常
  （一处操作细节：裸 `make cov` 因 `TEST` 缺省值解到 `out/m0/cov.vdb`，
  已记录不登记新 bug）；未撞见 BUG-0043 同型号异常。
- **orch 独立复验**（不采信卡内自报数字）：对照 `sim/result_summary.txt`
  逐行核实 26 PASS/0 FAIL 与报告 §2 一致；`make check`/`make selftest`
  （61/61）复跑绿；确认本卡未改动任何 RTL/TB/spec（`git status` 只有新增
  的 evidence 目录）。
- **orch 机械登记**：`cp sim/result_summary.txt doc/evidence/v0.4.9/
  result_summary.txt`，满足 `make check MILESTONE=4` 条件 2（regress
  summary registered as evidence）——该条件只要求文件按名落在
  `doc/evidence/v0.4.*` 下，纯机械操作，非产出技术判断。
- `make check MILESTONE=4` 复跑：4 条机器门禁中 2 条（1. 全部 M4 场景 ✅；
  2. regress evidence 已登记）转 **PASS**；另 2 条仍 FAIL（见 Not done）。

**Not done**
- **`make check MILESTONE=4` 条件 3**：`BUG-0045`/`BUG-0043` 仍是 OPEN，
  按机器门禁"所有 bug 须终态或 ACCEPTED-unexpired"，M4 不得签核——上一
  周期我曾误判这两条"不阻塞 M4"，已在会话内向用户澄清并订正。
- **`make check MILESTONE=4` 条件 4**：M4 尚无任何打 M4 标签的 KILL 行
  （不变量 5 要求每 milestone 每类 checker 至少一次注伤自证）。
- **REV-017 条件 3**：`axi_atop_filter` FSM 书面豁免 + BUG-0032 guard
  机械抽查——本轮报告 §5 第 3 条再次确认该缺口未获改善，仍待 rev 在 M4
  签核时一并出具（REV-017 原文即把此条件挂在"M4 签核时"，非独立前置卡）。
- 签核文件 `signoff-M4*.md` 未生成。
- `doc/evidence/v0.4.9/M4-coverage-baseline.md` §6 列出的多项"需补场景"
  残余缺口（`axi_xbar` Toggle、`addr_decode_dync`/`axi_demux_simple` 多类、
  `axi_mux` Toggle、`axi_err_slv` Cond/Toggle 等）——本卡明确声明"只测量
  不判定"，是否需要为这些缺口另开 testplan 行或走书面豁免，留给 M4 签核
  卡的 rev rubric 判断，不是本条自动待办。

**Next**
1. 派 rev 卡仲裁 BUG-0045（当前唯一路径，`make next` 已给出）。
2. 处置 BUG-0043（无可执行判据，大概率走 ACCEPTED/WONTFIX 终态，需 rev
   record 背书）。
3. 补 M4 至少一条 KILL 覆盖行（挑一个 M4 新 checker，注伤→红→恢复→绿）。
4. 三项齐备后派完整 M4 签核卡（L3/opus/rev）：`make check MILESTONE=4`
   全绿 + rev 人工 rubric（`workflow/review.md` 七问 + 第 5/6 条抽查）+
   REV-017 条件 3（FSM 书面豁免 + BUG-0032 guard 抽查）一并出具 +
   `doc/evidence/v0.4.*/signoff-M4.md`。**M4 签核本身不转版本**（用户已
   订正：v1.0.0 转段挂在 M5 签核后，见 `doc/milestone.md`）。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- `make check MILESTONE=4`：4 条机器门禁中 2 条 PASS（较上次全 4 条中
  1 条 PASS 有进展），2 条仍 FAIL（如上）。
- regress 数字交叉核实：`doc/evidence/v0.4.9/result_summary.txt` 与
  `sim/result_summary.txt` 逐行一致，26 PASS/0 FAIL。
- 本周期无新增 bugs.md 行/状态变化（DV 卡确认无新 taxonomy 异常）。

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

