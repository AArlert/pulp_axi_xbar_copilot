# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.4.11] 2026-08-01 M4 收尾第三项（上半）：BUG-0045/0043 转终态，新登记 BUG-0046（同批发现的独立 spec-gap）

**Done**
- 并行派两张独立 rev 仲裁卡（L3/opus，各自 fresh instance，互不共享，均只产出
  裁决记录不改 bugs.md）+ 一张 M4 KILL 覆盖自证 DV 卡：
  - **REV-021 仲裁 BUG-0045**（spec §3.2 未载 `end_addr=='0` 末端哨兵）：
    独立核实（算术自验 8 条 rule 的 `end_addr` 不回绕到 0 + tb 全域构造点
    扫描）确认"当前无场景触及"为真——taxonomy 维持 SPEC_ISSUE（潜伏型，
    "完全未定义"支），处置 **ACCEPTED@M5**，排除"现在补 spec"（会造不可
    证伪 refmodel 死代码）与 WONTFIX（会永久埋没 RTL 全链路一等公民
    特性）。给出可证伪解锁条件（任何场景构造 `end_addr=='0` 即刻作废）+
    M5 到期二选一动作（覆盖哨兵走标准处置三件套 / 具体论证转 WONTFIX）+
    ready-to-apply 的 spec 条款草案备料。**核实过程中独立发现新缺口**：
    spec §3.2 条 2 `start_addr<=end_addr`（非严格）与 RTL `check_start`
    严格 `<` 约束松紧不符——独立、非阻塞，orch 按无条件登记纪律登记为
    **BUG-0046**（OPEN，spec，SPEC_ISSUE 候选）。
  - **REV-022 处置 BUG-0043**（间歇性 `make regress` 非零退出）：独立复算
    退出码机制归因（`rc!=0→FAIL` 是 `vcs-2018.mk` 明载的有意设计）+ 三次
    两清一异事实链，taxonomy 确认 TOOL_ENV，终态 **WONTFIX（accepted-
    transient）**——排除 `ACCEPTED@M<n>`（无可调度工作、无可证伪到期
    条件，强设只会把不可复现现象伪装成日程债）。给出收紧后的
    `regression_guard` 建议文本（声明终态、明确复现不重开本行、机械化
    TODO 写诚实——诊断采集方向而非自动重跑）。
  - **M4 KILL 覆盖自证卡**：仍在跑（见 Not done）。
- **orch 应用两张裁决**（独立复核裁决记录，非采信自报结论）：
  - `doc/bugs.md` BUG-0045 行 `OPEN → ACCEPTED@M5`（verify_evidence 点名
    REV-021）；`doc/bugs/BUG-0045.md` `## fix` 段落补裁决记录，
    `## regression_guard` 补到期锚点（M5 + 点名 REV-021）。
  - `doc/bugs.md` BUG-0043 行 `OPEN → WONTFIX`（`fix_commit`/
    `verify_evidence` 均 `-`，与既有 WONTFIX 行先例 BUG-0021/0024 写法
    一致；suspect 保持 TB，class=TOOL_ENV 记在详情页）；
    `doc/bugs/BUG-0043.md` `## fix` 补裁决记录，`## regression_guard`
    按 REV-022 建议文本整体替换（声明终态 + 复现处置 + 可证伪解锁 +
    不可机械化理由与唯一可行的诊断采集改进方向）。
  - **新登记 BUG-0046**（OPEN，spec，SPEC_ISSUE 候选，非阻塞）：`doc/spec.md`
    §3.2 条 2 用非严格 `<=`，RTL `check_start` 用严格 `<` 并对
    `start==end`（`end≠0`）的 rule 判 fatal——spec 允许 RTL 会炸的配置。
    与 BUG-0045 同源（同一次 REV-021 逐行核验）但内容/解锁条件独立，
    不合并登记（`doc/bugs/BUG-0046.md`）。
- `make check`/`make selftest`（61/61）复跑绿。

**Not done**
- **`make check MILESTONE=4` 条件 3 仍红，但阻塞项已从 BUG-0045/0043 转移
  到新登记的 BUG-0046**——已派 REV-023（并行）仲裁，待其交付后 orch 应用。
- **条件 4（KILL 覆盖）仍红**：M4-OV01 tie-break 的 KILL 自证 DV 卡仍在
  后台跑，交付后 orch 登记 KILL-0004 行。
- REV-017 条件 3、签核文件仍未动——待条件 3/4 转 PASS 后再派完整签核卡。

**Next**
1. REV-023（BUG-0046 仲裁）+ KILL 自证 DV 卡交付后，orch 应用两者到
   `doc/bugs.md`。
2. `make check MILESTONE=4` 四条机器门禁全绿后，派完整 M4 签核卡（L3/opus/
   rev）：机器条件 + rev 人工 rubric + REV-017 条件 3（FSM 书面豁免 +
   BUG-0032 guard 抽查）+ `doc/evidence/v0.4.*/signoff-M4.md`。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- `make check MILESTONE=4`：条件 1/2 PASS，条件 3 阻塞项从"BUG-0045,
  BUG-0043"变为"BUG-0046"（净减少两项、新增一项，均为同批核验中独立
  发现，非遗漏），条件 4 仍 FAIL（KILL 自证进行中）。
- 本周期无仿真运行（纯裁决应用/登记），无新增 evidence/testplan 状态
  变化——`make evidence` 门禁不适用。

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

