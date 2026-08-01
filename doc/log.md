# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.4.37] 2026-08-02 里程碑重构落地——M4 出口重定义、新增 M6 承接 ≥90% 门，spec §0#4 重 pin（BUG-0047 选项 (ii) 兑现）

**背景**：用户裁定"覆盖率 90% 出口不该留在只有定向激励的里程碑"，走
BUG-0047 终判预留选项 (ii)。链条：arch 提案（卡B）→ rev 门禁（卡C，
REV-032）**首判 REJECTED**（轴 4 抓出 `stream_register` 三格漏账——
"UNOWNED=∅"宣告失实）→ orch 登记 BUG-0049 → 独立 rev 处置卡
（REV-033）裁归属 → arch 返工（G-1/G-2）→ rev 复审 **APPROVED** →
orch 机械应用 + 重 pin。

**Done**
- **REV-032（门禁 + 复审）**：七轴合格、轴 4 首判抓漏。复审对含
  stream_register 的 22×6 全格重做集合差——132 格与 final-sweep §2.3
  全一致，APPROVED 无条件。副产物：G-2 揪出 verification_maturity 四处
  v1.1 版本残留（orch 复核补出 L44 一处，比 REV-032 清单多一处）。
- **BUG-0049 登记**（无条件登记）：stream_register Line 75.00/Toggle
  22.00/Branch 50.00 三格漏账，归因三层如实入账（卡A §3 标注遗漏、
  orch 复验未做完备性交叉核对、REV-031 承接汇总清单为输入）。
- **REV-033**：三格独立裁决——Line/Branch 全 Kind-A、Toggle 拆 31 bit
  Kind-A（P1 tie-off/P2 push-gate 同 CW-001 INJECT_R 根因/P3 rst_ni）
  + `data_i.len[7:4]` 8 bit 定向可达路由 DV-A err_slv 宿主族。登记
  **CW-014**；顺带订正 REV-032 "非-load ATOP" 表述（`atop[5]` 实为
  读返回类原子，`axi_pkg.sv:447` 独立重推）。
- **提案返工（卡B'）**：G-1 五点（§6.2 收 CW-014、§6.1 收 D1、计数
  013→014 五处、UNOWNED 现状如实化、**新增 §6.3 22×6 全格→归属对照
  表**——未来签核 UNOWNED=∅ 核读的底板）+ G-2 四处版本残留 old/new。
- **orch 机械应用**（rev 批准后，零创作）：spec §0#4 一句替换 +
  修改记录 #12 行 + `docs.py --pin-spec` **重 pin**（新 sha
  `dad62e08…`）；milestone.md 从提案围栏块脚本拼装（M4 重定义 +
  M5 瘦身 + **M6 新增**，Abstract 修"0 场景行"漂移，M0-M3 零变化）；
  coverage-waivers 抬头 Kind-B 解锁改"M5 随机层 + M6 cov_loop"；
  verification_maturity 修订 A-E（Decision 5 移交 M6 + 版本残留清理）；
  BUG-0047 详情页追加选项 (ii) 落地段（冻结正文不回改，仅追加）；
  删 `milestone.md~` 杂物。
- **新里程碑架构生效**：M4 = 测量基建 + 三态扫描 + 每格具名归属
  （UNOWNED=∅，四表交叉核）；M5 = 纯方法论（随机层/多种子/soak，无
  百分比门，三条 `ACCEPTED@M5` 锚零移动）；M6 = 六类 ≥90% 收敛
  （cov_loop，random-first directed-fallback，v1.0.0 改挂 M6 签核）。

**Not done**
- 卡E（M4 签核重开，新出口条件下全 rubric）未派——下一闭环主件。
- BUG-0048（lint 门机制修）仍 OPEN，压在签核后（保 merged vdb）；
  BUG-0049 仍 OPEN（closer 另派，待 CW-014 已 pin〔本 commit 兑现〕+
  D1 已录 backlog〔提案 §6.1 已录〕后可派 closer）。
- M6 backlog 的 DV-A~G 七张定向卡均未派（M6 时 random-first 处置）。

**Next**
- 卡E：M4 签核重开（rev·L3，全 rubric，§6.3 对照表为 UNOWNED=∅ 核读
  底板；签核文含 15 条 RTL-only 条款 oracle 边界段）。通过后
  `make check MILESTONE=4` + bump minor + tag v0.5.0，M4 关门。

**How verified**
- REV-032 复审段独立重做 132 格集合差 + 四处 OLD 逐字 grep；orch 应用
  前对四处 old/new 做保真度 grep（全部唯一命中）、milestone 抬头 md5
  比对提案 §3.1 一致；应用后 `python3 scripts/docs.py --pin-spec` 成功
  重 pin（拒绝-登记-重试链：首次 pin 被脚本按"修改记录先行"规则正确
  拦截，补 #12 行后通过）。
- `make check`（docs-check passed + chain audit 无新增 gap 形状）与
  `make selftest`（61/61 OK）应用后复跑绿。本闭环零 RTL/TB 改动，无需
  重跑回归。

## [0.4.36] 2026-08-02 卡A 覆盖率全景复测 + REV-031 UNOWNED 分诊——M4 残余首次达成"每格有归属"，CW-010~013 登记

**背景**：用户裁定 M4"六类硬 ≥90%"出口与定向激励约束的张力走 BUG-0047
终判选项 (ii)（重议判据口径），路线 = 里程碑重构（M4 出口改"测量+分诊
完成"、新增 M6 承接 ≥90% 数字门、M5 保持纯方法论）。重构提案（arch 卡）
动笔前，先以一张 DV 测量卡（卡A）取权威数字、一张 rev 卡（REV-031）关掉
无归属缺口——backlog 表须基于实测，不抄旧表。

**Done**
- **卡A（DV·L1）**：`doc/evidence/v0.4.35/M4-coverage-final-sweep.md`。
  merged vdb 完整性核验（24 基线场景，cfgE 经亲测 UCAPI-INSTANCEMISMATCH
  证实结构不可并入，非构建隔离习惯）；六类全闭包三态扫描（22 DUT 模块，
  22+13=35 与 modlist 逐位对账）；<90% 格逐一归属标注。三大发现：
  (i) REV-024 两悬案自然消解——`axi_xbar` Toggle 40.74→94.44 PASS、
  `axi_xbar_unmuxed` Assert 53.85→100 PASS（历史加固卡副作用关闭，无人
  回测过）；(ii) 9 个 UNOWNED (模块,类型) 格子（8 个首次按模块页测量的
  闭包内 common_cells 模块）；(iii) CW-001 对 `r_state_q.R_HOLD` 论证
  失实（普通读背压可达、已 Covered、与 ATOP 无关）。
- **REV-031（rev·L3）**：9 格逐格独立裁决（测量卡建议仅作路由输入）。
  新登记 **CW-010~013** 四条 Kind-A（flush_i 全例化点 tie-0 根因一行承接
  多格 bin-scoped 分量 / lzc 常量 LUT+非 2 幂 padding / axi_id_prepend
  pre_id_i generate 常量 / counter-delta_counter tie-off 位），各附可证伪
  解锁；**零 Kind-B**（BUG-0047 guard 合规）。混合格拆分：结构位入豁免、
  定向位路由 DV——新增 **DV-F**（rr_arb_tree 仲裁竞争多样性）、**DV-G**
  （id_counters push+inject 同拍同 index，DV-E 家族）两张待派卡；薄壳
  Toggle（89.22/88.51）判 DV-A/B 阴影不新开卡。CW-001 措辞订正（R_HOLD
  除外标注，豁免主体维持）；REV-024 §2.2 行 9 表后追加勘误批注（
  multicut/cut 结构无 Cond bin，"55-65%"应属 spill_register_flushable，
  原表格行一字未改）；"待建档项" spill bypass 经 urg 反证（Bypass=0/1
  两参数均例化）撤项。
- **orch 独立复验**：卡A——git status 单文件、modlist/modinfo 抽查
  spill_flushable 82.49/lzc 42.59/id_counters 73.91/xbar 94.44/unmuxed
  Assert 100/ar_ready Yes×3/R_HOLD Covered 全对上、格式对齐 v0.4.0 先例。
  REV-031——编辑面精确 3 文件、REV-024 批注纯追加（diff 全 + 行）、
  flush 六处 tie-off/pre_id_i/lzc LUT/counter 三 tie-off/down_i(1'b1)
  逐一亲验 RTL 对上。counter 实例数分歧（卡A 108 vs REV-031 12，实为
  delta_counter 之数）不影响任何百分比与处置，已记 REV-031 §6。
- **M4 残余状态**：至此全部 <90% 格子首次达成"每格有归属"——CW-001~013 /
  BUG-0044 / DV-A~G 待派清单 / 已吸收，UNOWNED = 空集。

**Not done**
- 里程碑重构提案（arch 卡B：spec §0#4 修订 + milestone M4/M5/M6 + backlog
  表）及其 rev 门禁（卡C）未派——本闭环只做了它的数据前置。
- DV-A/B/C/E/F/G 六张定向卡均未派（重构落地后按 M6 backlog 处置）。
- BUG-0048（lint 基线漂移）未修——已决策：机制修（lint-diff 挂进门禁），
  排在 M4 签核后以保住 merged vdb 供签核 rev 独立复算。

**Next**
- 卡B：arch 里程碑重构提案（M4 出口改"测量+分诊完成、无 silent gap"，
  新增 M6 承接六类 ≥90%，M5 纯方法论；backlog 表数据源 = 本闭环
  final-sweep + REV-030 DV-A~E + REV-031 DV-F/G）→ 卡C rev 门禁 →
  orch 应用重 pin → M4 签核重开。

**How verified**
- 见上"orch 独立复验"段——两卡数字均未采信自报，urg text 报告与 RTL
  例化点逐项亲验。
- `make check` 本轮复跑绿（docs-check passed；chain audit 仅既有已知
  形状，"仅锚父节"14 处与 0.4.35 记录一致，无新增 gap）。本闭环零
  RTL/TB 改动，无需重跑回归。

## [0.4.35] 2026-08-02 REV-030 DV-D（#18）落地——M4-EB02 err_slv 读方向背压，M4-EB01 读向对偶；随后暂停派卡，等用户裁定 M4 出口条件

**背景**：REV-030 §3 DV-D 构造指引，五张 DV 卡中估级最低（L1，机制
全部现成）的一张，优先派发。**本卡收尾后，用户叫停——M4 六类硬 90%
出口条件与"结构性可达但性价比低"这类残余（DV-A~E 这一批）持续矛盾，
需要先裁定 milestone 出口条件本身，暂停继续派发 DV-A/B/C/E 与 #14/#15，
等用户决策。**

**Done**
- **`tb/axi_txn.sv`**：新增 `r_backpressure` 字段（镜像既有
  `b_backpressure`）。**`tb/slvport_agent.sv`**：`drive_burst` 新增
  `BP_R_HOLD_CYC=50` 有界 `r_ready` 保持窗口（镜像 `BP_B_HOLD_CYC`）；
  monitor 新增 `EB_AR_HELD` 覆盖点采样（`ar_valid && !ar_ready`，纯外部
  握手观测，非判决）。**`tb/seq_lib.sv`**：新增 `slvport_eb02_seq`
  （`num_rd=10 > err_slv r_fifo 深度 4`，单拍读、未命中地址、`atop='0`）
  + `m4_eb02_errbp_vseq`。**`tb/test_lib.sv`**：新增
  `m4_eb02_errbp_test`（镜像 `m4_eb01_errbp_test`）。**testplan 新行
  M4-EB02**（M4-EB01 读向对偶）+ **feature-matrix F-M4-08**。判决门
  **原样复用** `scoreboard_refmodel.sv` 既有 `SB_DECERR_*` 判据族——
  **零改动 scoreboard 任何一行**（orch `git diff --stat` 确认）。
- **未做 KILL 注伤自证，理由经查证成立**：零新增期望值推导路径。orch
  独立核实 M4-EB01 自己当初落地（0.4.18 版本块，见 `doc/archive/
  log-archive.md`）同样"判决门复用 M3-DE01 的 SB_DECERR_* 判据族（不新
  发明期望值）"、同样未做 KILL——本卡与该先例判断口径一致，非临时找
  借口。
- **orch 独立复验**：diff 审读确认全部改动为纯加型（新字段/新
  localparam/新覆盖点/新 seq/新 test 类），`scoreboard_refmodel.sv`
  确认零改动；从 `make clean` 开始独立整跑全量回归确认 **30/30 PASS**
  （含新场景 `m4_eb02_errbp_test`）；独立重新生成 urg 合并报告，直接
  解析 `axi_err_slv`（mod32.html）模块级汇总：**SCORE 94.04/LINE
  100/COND 100/TOGGLE 69.78%→70.22%/BRANCH 100/ASSERT 100**，
  `slv_resp_o.ar_ready` 由 No/No/No 转 **Yes/Yes/Yes（全部 6 实例+合并
  视图，双向翻转）**，与 DV 卡自报数字完全一致。
- Evidence 刷新：`doc/evidence/v0.4.34/M4-EB02.log`。
- DV 卡如实登记一处流程偏差（非 taxonomy 五类）：受"先建后测"实际执行
  顺序影响，未在动手前单独重跑一次排除本场景的基线核实 REV-030 引用的
  69.78%/No,No,No，改用落地后交叉核验弥补（单跑新场景确认非判决 cover
  `cp_chan` 精确只命中 `ar_held`，证明改动范围精确）。orch 认为该弥补
  手法可接受，不影响本卡收版。

**Not done**
- **暂停**：DV-A/B/C/E 四张卡、#14（M4 签核卡）、#15（BUG-0048 fixer）
  均未派发，等待用户对 M4 出口条件的裁定后再定后续动作。

**Next**
- 视用户裁定结果而定——可能是新增处置类别（如"定向可达但性价比劣于
  M5 约束随机"的第三类豁免）、可能是重写 M4 出口条件本身（六类硬 90%
  →更灵活的判据），也可能是维持现状继续按 REV-030 五张卡推进。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + scoreboard 零改动确认 + 从零全量
  回归 + urg 逐字段核对 + M4-EB01 KILL 先例交叉核实，均未采信 DV 卡
  自报数字。
- `make check`（chain audit 无新增异常 gap，只是"仅锚父节"计数从 13→14
  的已知形状增量）/`make selftest`（61/61）本轮复跑绿。

