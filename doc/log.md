# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

