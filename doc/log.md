# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

