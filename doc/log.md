# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

