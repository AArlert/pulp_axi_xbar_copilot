# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

