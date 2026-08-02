# Work log archive
## [0.4.38] 2026-08-02 BUG-0049 关闭（UNOWNED=∅ 经两条独立链确认）——并由复验反手挖出四条新账目缺陷 BUG-0050~0053

**背景**：M4 关门前置。BUG-0049 的修复面（REV-033 裁 CW-014 + arch 返工 + orch 应用）
已在 0.4.37 落地，本闭环只做**关闭**——按不变量 3（closer ≠ fixer）派全新 rev 实例
独立复验。orch 侧**同时**另跑四路互不知情的独立复算作收卡对抗验证：这是对
BUG-0049 根因之三（"orch 复验只抽查数字未做完备性交叉核对"）的直接反制。

**Done**
- **REV-034（closer 卡，rev·L3）**：从原始 urg 报告 `sim/out/urgText6/modlist.txt`
  独立重做 132 格三态（N/A 59 + PASS 43 + <90% 30）与 30 格四表集合差，**UNOWNED=∅**；
  例化闭包 22 成员经 RTL BFS 独立重建、与 urg 模块页集合双向差集为空；CW-014 逐 bin
  账平（39=4+1+26+8）、所引 RTL 事实逐条回源；D1 已录 §6.1 DV-A 且两侧措辞不矛盾。
  产物：`doc/review/REV-034.md`（含 30 格集合差附表，未来签核核读 UNOWNED=∅ 的底板）。
- **BUG-0049 CLOSED（机器背书）**：closer 跑
  `make evidence BUG=BUG-0049 CMD=… EXPECT='RESULT CELLS=132 LT90=30 UNOWNED=0'`
  一次跑通，脚本自行翻状态并写 `doc/evidence/v0.4.37/BUG-0049.log`（首行即 `CMD:`）。
  配套实质记录 `doc/evidence/v0.4.37/BUG-0049-closure.md`（BUG-0029 guard 要求的位置），
  两份文件的形式件/实质件分工已写进其抬头。orch 前置填 `fix_commit=861c7f8`
  （`BUG_STATES_NEED_COMMIT` 含 CLOSED）。
- **orch 四路独立复算（收卡对抗验证）**：正向枚举（从 §2.3 实测表）/ 反向枚举（从四个
  归属面）/ 直查覆盖库原始事实（绕过全部 markdown）/ 从 RTL 重推例化闭包，四路互不
  知情，再由第五个裁决者比对分歧。三路作答者的 30 格 below90 集合**逐格完全一致**，
  裁决者独立复算同得 `CELLS=132 LT90=30 UNOWNED=0` —— 与 REV-034 逐格吻合。
  **UNOWNED=∅ 由两条完全独立的证据链确认。**
- **新登记四条（无条件登记；三条系复验反手挖出，一条系 closer 报出）**：
  - **BUG-0050**（引用越界族，与 BUG-0049 互为镜像）：CW-010 认领 `fifo_v3` Cond 的
    flush 分量，而该 bin **物理不存在**（`fifo_v3.sv:122` 单项条件，26 个实例的
    Condition 段行号恒为 {73,88,101}）；CW-002/CW-007 被引用于其登记文本之外的模块页；
    BUG-0044 承接两格 Toggle 的链接只在 REV-030、未回写债务行本体。四条均为"过度引用"
    而非"无人认领"，**剥离后 UNOWNED 仍为 ∅**，故不影响 BUG-0049 的关闭。
  - **BUG-0051**（证据事实错抄族）：final-sweep §2.3 `counter` 实例数写 108（真值 12，
    系 `delta_counter` 之数误抄，已被 §6.3 继承）；脚注 3 对 `lzc` 的 Line/Cond/Branch
    N/A 陈述与同表 Cond=97.73/Branch=97.73 自相矛盾；脚注 6 对 `stream_register` Cond
    的成因被同一份 modinfo 证伪。**M4 出口第二条要求"附已核实成因"，成因写错等同未满足。**
  - **BUG-0052**（框架路径漂移）：`.claude/agents/{rev,dv}.md`、`dispatch/SKILL.md`、
    `doc/bugs.md:3` 表头共四处引用 0.8.0 已合并掉的 `workflow/review/*`、`workflow/fail/*`
    路径，`test -e` 逐条实测全 MISSING。REV-034 实例是第一个撞上并靠卡内订正绕过的。
  - **BUG-0053**（记录卫生）：`REV-033.md` 尾部工具标记随 `861c7f8` 入库；REV-034 实例
    写自己记录时**当场复现同一泄漏**（自检删除）——系统性写作陷阱，非一次性疏忽。

**Not done**
- 卡E（M4 签核重开）未派——`make check MILESTONE=4` 条件 3 尚红。
- BUG-0048（lint baseline 漂移）仍 OPEN，下一闭环主件（fixer + 独立 closer 两次派发）。
- BUG-0050~0053 均 OPEN：0050/0053 待 rev 裁决处置面，0051/0052 待派 fixer。**四条都压在
  M4 签核之前**——0050/0051 直接触及 M4 出口第二、三条的诚实性，0052/0053 是记录卫生。

**Next**
- 闭环2：BUG-0048 fixer（DV，逐站点分诊 62 个新 lint 站点 + 重同步基线；硬约束不得
  `make clean` 毁 `sim/out` 覆盖库）+ 独立 closer。
- 闭环3：BUG-0050~0053 处置（rev 裁决 + fixer）。
- 闭环4：卡E M4 签核（rev·L3 全 rubric），通过后 `make bump minor=1` + tag v0.5.0。

**How verified**
- `make evidence BUG=BUG-0049 …` 退出 0、签名命中，脚本自行回填 CLOSED + verify_evidence
  （非手改）；`doc/evidence/v0.4.37/BUG-0049.log` 首行为 `CMD:`。
- 四路复算的关键事实 orch 侧逐条机核复现：`grep -c i_counter_open_w/i_r_counter
  sim/out/urgText6/hierarchy.txt` 各得 6（counter=12，非 108）；`grep -n flush_i
  vendor/common_cells/src/fifo_v3.sv` 只得 :25/:122，遍历 26 个 fifo 实例 Condition 段
  无 LINE 122；`modlist.txt:48` lzc 行 Cond/Branch=97.73 与脚注 3 正文矛盾；四条 workflow
  死路径 `test -e` 全 MISSING；`tail -3 doc/review/REV-033.md` 见工具标记。
- `make check` docs-check passed、chain audit 无新增 gap 形状；`make selftest` 见本块提交。
- 本闭环零 RTL/TB 改动，未跑 sim、未 `make clean`、`sim/out/` 全程只读（覆盖库另备份至
  scratchpad 防误删）。

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

## [0.4.34] 2026-08-02 REV-030 三模块残余全面分诊——登记 Kind-A CW-009，五张 DV 构造指引卡（含 #16/#17/#18 终判）

**背景**：任务 #21。orch 用 urg 对 `axi_mux`/`axi_demux_simple`/
`axi_err_slv` 三模块做了一次全量快照，发现残余清单比原始 #16/#17/#18
三条更宽（`len[7:4]`/`addr[2:0]`/`size[1:0]` 单向等多个未登记位），派发
一张范围更宽的 rev 分诊卡，仅把三条原始任务作为背景线索、不作结论。

**Done**
- **rev 独立重生三模块 urg + 逐条对照既有 CW-001~008**：三模块大宗残余
  （err_slv 恒定输出/四模块 rst_ni/scan/size[2]/atop 非-load 子类型）
  均已被既有豁免或 BUG-0044 承接，pass、不重复登记；各 `≥90%` 类死位
  依 REV-028 先例由余量吸收，不登记。
- **登记 CW-009（Kind-A）**：`axi_demux_simple` Cond 82.76% 五个未覆盖
  bin 中，`w_open==15`（`axi_demux_simple.sv:168` 主表达式 term2）一 bin
  结构不可达——`IdCounterWidth=idx_width(MaxMstTrans=10)=4` 全一=15，但
  下游 `axi_mux i_w_fifo` 深度由 `axi_xbar.sv:141` 硬wire为
  `Cfg.MaxSlvTrans=6`，加 `PipelineStages=1` 缓冲，结构封顶远低于
  15——**orch 独立核实全部引用行号（`axi_demux_simple.sv:69`
  `idx_width`、`axi_mux.sv:319/46` `i_w_fifo` DEPTH、`axi_xbar.sv:141`
  MaxWTrans wiring）与 `cf_math_pkg::idx_width` 函数实现，逐字符合**；
  经验佐证（`slvport_agent.sv:448-466` `drive_burst_wopen` 注释）
  **orch 独立核对确认**：LEAD=6..10 全部干净完成、LEAD=11 触发
  watchdog 自死锁（driver 侧 AW→W 链无空间，非 DUT 死锁）。
- **其余 4 bin（`ar_id_cnt_full && atop[ATOP_R_RESP]` 双 1 交叉，即 #16）
  驳回登记豁免，判定可构造**：rev 逐层核实 `ar_id_cnt_full`（全桶 OR，
  L557/615）与 `atop[R_RESP]` 各自已被现有场景单独触达，唯缺同拍共存；
  填桶用从机侧 `resp_hold` 时间驱动自动释放，无死锁；stall 是 RTL 合法
  防溢出行为——**终判非 SPEC_ISSUE、非 TB_BUG，是普通定向可达
  planning-gap**。
- **五张 DV 构造指引**（rev 只给方向性技术要求，不写代码）：DV-A（请求
  属性取值域：窄传输/字节非对齐/长突发，err_slv 轨 L1 + mux 轨 L2，
  mux 轨须扩 `predict_beat_data` 并做 KILL）、DV-B（从机 resp/user 多样化，
  L1/L2）、DV-C=#17（mux `b_ready` 写背压，须新增背压驱动能力，L2）、
  DV-D=#18（err_slv `ar_ready` 读向背压，M4-EB01 直接镜像，机制全现成，
  L1）、DV-E=#16（demux atop-under-AR-full 混向构造，L2）。
- **发现一处交付缺口 flag（非新 bug）**：`addr[2:0]` 字节级非对齐被
  M3-DE01/M2-CFG01 反复标注"REV-026 C-1 territory"，但 C-1 实际交付
  （`slvport_sideband_div_seq`）从未驱动 `addr[2:0]≠0`——孤儿残余，归
  BUG-0047 伞下，orch 派 DV-A 时须明确其归属。
- **orch 独立复验**：`git diff` 逐行审读 CW-009 新增行；独立重跑 RTL 读取
  验证 `IdCounterWidth`/`idx_width` 函数实现/`i_w_fifo` DEPTH 绑定/
  `MaxSlvTrans=6`/`PipelineStages=1`/LEAD 边界经验注释，逐条与 rev 卡
  引用行号内容一致；独立核对 `axi_err_slv.sv` `ar_ready=~r_fifo_full`、
  `i_r_fifo` DEPTH 绑定 `MaxTrans`、`axi_xbar_unmuxed.sv:201`
  `.MaxTrans(4)`（当前 >1 slave 端口配置对应实例）。
- `doc/review/REV-030.md` 已写入磁盘。

**Not done**
- 五张 DV 卡（DV-A~E）均未派发，是本轮 M4 收尾工作的下一批主力。#14/#15
  仍未派发。

**Next**
- 依次派发 DV-D（#18，L1，机制全现成，最省力）→ DV-A err_slv 轨（L1）→
  DV-B/DV-C（L1/L2）→ DV-A mux 轨（L2，须扩预测器+KILL）→ DV-E（#16，
  L2，新混向 primitive）。

**How verified**
- 见上"orch 独立复验"段——git diff 审读 + 全部 RTL 行号引用逐条重新
  grep 核对 + `cf_math_pkg::idx_width` 函数体亲读，均未采信 rev 卡自报
  内容。
- `make check`（docs-check + chain audit 无新增 gap）本轮复跑绿；本卡
  未改 RTL/TB，无需重跑回归。

## [0.4.33] 2026-08-02 REV-029 裁决——addr_decode_dync Branch 83.33% 登记 Kind-A（CW-008），订正 REV-024 §2.2 行 6

**背景**：任务 #20，REV-028 的姊妹裁决。REV-028 顺带发现
`addr_decode_dync` 真正的 `<90%` 数字是 Branch 83.33%（唯一残余 =
`addr_decode_dync.sv:146` IF 语句 else 支，与 `config_ongoing_i` 无关），
flag 给 orch 另派卡处置，不越界代为登记。orch 只给全新 rev 实例原始
材料位置（RTL+行号、urg 取数命令、spec、REV-024/REV-028 原文、豁免
契约+先例），REV-028 的建议**仅作背景路由输入**、不作结论依据。

**Done**
- **rev 独立复算 else 唯一触达路径**：IF 条件
  `!$isunknown(addr_map_i) && ~config_ongoing_i`，因
  `config_ongoing_i≡1'b0`（`addr_decode.sv:106` tie-off）使
  `~config_ongoing_i` 恒真，else 唯一触达 = `addr_map_i` 取 X。
- **rev 独立核实 env 构造上从不驱动 addr_map_i 为 X**：亲读
  `tb/cfg_if.sv:26`→`tb_top.sv:59/142` 初始化路径 +
  `tb/seq_lib.sv:1323/1779/2478` 运行时重配路径，三处均只赋
  `xbar_types_pkg.sv` 三个 gen 函数产出的编译期具体 localparam（`idx`/
  `start_addr`/`end_addr` 全字段具体），全 tb 对 addr_map 检索
  force/isunknown/'x 路径为空集。spec §3.1/§3.2/§3.4 通篇假定地址表为
  具体合法值，无未知地址表语义——覆盖此 else 属无 spec 基础的
  X-theater（同 CW-006 rst_ni 先例的处置逻辑）。
- **裁决登记 Kind-A（CW-008）**：与 REV-028 对 config_ongoing_i 的"驳回
  登记"决定性轴不同——那案的残余落在已过 90% 门的 Toggle 类里，本案的
  IF-146 else 恰是 Branch **`<90%` 门的唯一致因**，门真失败，落
  `doc/coverage-waivers.md` 明文登记面（"有 bin、`<90%`"），须有书面
  可证伪豁免承接，否则即静默放水。`doc/coverage-waivers.md` 新增
  CW-008 一行（格式对齐既有 CW-001~007），解锁条件写两条具体可证伪
  事实：(i) `config_ongoing_i` tie-off 被推翻，(ii) 纳入地址表 X 测试
  **且先补齐 spec 未知地址表语义条款**（对齐 CW-006"解锁须先补 spec"
  先例，防止解锁沦为"造个 X 就算测过"）。**独立复核 REV-028 §4 建议并
  同意其 Kind-A 性质判断（自行从 RTL/TB/spec 重走一遍，非照抄），落地
  登记并对解锁条件做一处收紧精化**。
- **订正 REV-024 §2.2 行 6**：在 `doc/review/REV-024.md` 表后追加订正
  批注（原表格行一字未改），指明该行对 Branch 83.33% 的"地址多样性→
  补场景"归因失实——"更多样的已知地址仍使 addr_map 恒 known → else
  永不取"，处方不能闭合此 Branch；订正仅针对 Branch，行 6 对 Toggle
  53-57%（`addr_i[2:0]` bins）的结论不受影响、仍成立。
- **orch 独立复验**：`git diff` 逐行审读 `doc/coverage-waivers.md`
  （仅新增 CW-008 行 + "注"计数更新）与 `doc/review/REV-024.md`
  （仅追加订正段、原表格行零改动）；独立重新 grep 确认
  `tb/cfg_if.sv:26`/`tb_top.sv:59/142`/`tb/seq_lib.sv:1323/1779/2478`/
  `tb/xbar_types_pkg.sv` 三 gen 函数的内容与 rev 卡引用逐字一致，
  且 tb 对 addr_map 的 force/isunknown/'x 检索确认为空集；REV-028 会话
  中已亲自核对过 urg mod20.html 的 Branch 明细表（`IF 146`=1/2 covered、
  `MISSING_ELSE`），数据未变。
- `doc/review/REV-029.md` 已写入磁盘。

**Not done**
- 任务 #16-18（三张新加固卡，主攻 `axi_err_slv` 69.78% 与
  `axi_demux_simple` COND 残余）、#15、#14（最终 M4 签核卡）均未派发。

**Next**
- #16（`axi_demux_simple` COND 残余：ATOP×`ar_id_cnt_full` 交叉）。

**How verified**
- 见上"orch 独立复验"段——git diff 逐行审读 + RTL/TB 引用逐字核对 +
  urg Branch 明细表复用 REV-028 会话内已验证数据，均未采信 rev 卡自报
  内容。
- `make check`（docs-check + chain audit 无新增 gap）本轮复跑绿；本卡
  未改 RTL/TB，无需重跑回归。

## [0.4.32] 2026-08-02 REV-028 裁决——config_ongoing_i 覆盖率缺口候选驳回登记，订正 REV-024 一处 Branch 误归因

**背景**：任务 #19。B-3 加固卡（0.4.30）观察到 `addr_decode_dync` 的
`config_ongoing_i` 端口在 `addr_decode.sv:106` 被硬接 `1'b0`，疑似
Kind-A 覆盖率豁免候选。orch 只给 rev 卡原始材料位置（RTL 文件+行号、
urg 取数命令、spec、REV-024 §2.2、`doc/coverage-waivers.md` 全文），
不传递任何一方结论，由全新 rev 实例独立判断。

**Done**
- **rev 独立核实可达性成立**：`axi_xbar_unmuxed.sv:101/116` 例化的是
  `addr_decode`（非 napot、非直接 dync），其端口列表根本不含
  `config_ongoing_i`；`addr_decode.sv:106` 唯一驱动源为字面常量
  `1'b0`。结构不可达，Kind-A 之"质"成立。
- **但 rev 独立发现该缺口不构成需登记的"门失败"**：重生 urg 报告显示
  `(addr_decode_dync, Toggle)` 合并值 = **92.00% ≥ 90%**，已过门；
  `config_ongoing_i` 的 2 个死 bin 在分母内如实计入、非 silent
  exclude，被 8% 余量吸收。`doc/coverage-waivers.md` 抬头明文限定登记
  面为"有 bin、<90%"——此门不满足，登记反而是无失败 gate 却补一行的
  思辨性制品（`workflow/discipline.md` rule 2）。**裁决：驳回登记，
  不改 `doc/coverage-waivers.md`。**
- **rev 顺带独立发现该模块真正的 <90% 数字另有其人**：Branch 83.33% 唯一
  残余是 `addr_decode_dync.sv:146` 的 `IF` 语句 else 分支（urg Branch 表
  `IF 146` = 1/2 covered，`MISSING_ELSE`），条件为
  `!$isunknown(addr_map_i) && ~config_ongoing_i`——因
  `config_ongoing_i≡0` 恒不致 false，else 分支唯一触达路径是
  `addr_map_i` 出现 X，与 `config_ongoing_i` 无关。**REV-024 §2.2 行 6**
  把这条 Branch 残余笼统归为"地址/rule 多样性→补场景"，orch 独立核对
  REV-024 原文确认该行**从未提及** `config_ongoing_i`，且该 83.33% 数字
  自 REV-024 基线（M4 大量地址/rule 多样性加固卡落地后的今天）**分毫未
  变**——独立证实"更多样地址补场景"这条处方对这个 Branch 分支从未起过、
  也不可能起作用（X 注入无功能语义，rev 称为 toggle/branch-theater）。
  这是对 REV-024 一处历史误归因的订正，rev **未越界代为处置**，只 flag
  给 orch 另派卡。
- **orch 独立复验**：`doc/coverage-waivers.md` 确认零改动（`git status`
  无该文件变更）；亲自重新解析 `sim/out/urgReport/mod20.html`——
  头部汇总 `LINE 100.00/COND 100.00/TOGGLE 92.00/BRANCH 83.33/ASSERT
  100.00` 与 rev 卡自报逐字一致；Branch 明细表 `TERNARY 105`=2/2、
  `TERNARY 106`=2/2、`IF 146`=1/2（`MISSING_ELSE`），5/6=83.33% 精确
  对账；亲读 `doc/review/REV-024.md:126` 确认该行文本原文确实通篇只谈
  `addr_i`/rule 表 start/end、无 `config_ongoing_i` 字样。
- `doc/review/REV-028.md` 已写入磁盘（完整推导过程+裁决+分流建议）。

**Not done**
- IF-146 Branch else 残余（`addr_decode_dync` 真正的 <90% 数字）需独立
  另派 rev/DV 卡裁决（rev 建议候选 Kind-A：仿真专用 X-sanity 断言守卫、
  仅 X 注入可达、无功能覆盖意义），本卡不越界代为处置。任务 #16-18、
  #14、#15 仍未派发。

**Next**
- 新任务：IF-146 Branch else 独立裁决卡（订正 REV-024 §2.2 行 6 的
  Branch 归因，评估 Kind-A 登记）。随后继续 #16-18。

**How verified**
- 见上"orch 独立复验"段——urg HTML 逐字节解析比对 + REV-024 原文亲读 +
  `git status` 确认 coverage-waivers.md 零改动，均未采信 rev 卡自报
  数字。
- `make check`（docs-check + chain audit 无新增 gap）本轮复跑绿；本卡
  未改 RTL/TB，无需重跑回归。

## [0.4.31] 2026-08-02 REV-026 加固卡 C-2 落地——M2-AT01 ATOP 编码多样性转正，REV-026 十项加固卡清单收官

**背景**：REV-026 批准清单 C-2（aw.atop[5:0] 命中地址扩，(a)→M2-AT01，
附残余上报纪律）。这是 REV-026 十项 (a)-class 加固卡的**最后一项**——十项
至此全部落地。DV 卡先读 `doc/bugs.md` BUG-0044（ACCEPTED@M5：spec §6
只规定 ATOP atomic-load 的应答义务 B+R，atomicstore/atomicswap/
atomiccompare 三个子类型的应答义务全节未列），确认本卡构造边界须锁死在
atomic-load 编码子集内、残余引用该既有登记、不重复登记新 SPEC_ISSUE。

**Done**
- **`tb/seq_lib.sv`**：`slvport_at01_atop_seq` 唯一改动类（M3-AT02 的独立
  `ATOP_LOAD_ADD` 不动）。原固定单一编码
  `{ATOMICLOAD, LITTLE_END, ADD}` 改为 `load_encoding(idx4) =
  {ATOP_ATOMICLOAD, idx4}`，在 `ATOP[5:4]=ATOP_ATOMICLOAD` 子集内按端口
  索引确定性遍历 `ATOP[3:0]`（endianness×opcode）全部 16 种取值：Phase A
  每端口两笔（`(slv_port_idx*2+k)%16` 铺 0..11）+ Phase B 每端口一笔
  （`PHASE_B_IDX4='{12,13,1,14,3,15}`，非线性偏移表，专门让 `atop[2]`/
  `atop[3]` 在同一端口自身序列内既有上升又有下降拍，因 VCS toggle bin 需
  同 run 内的翻转、跨端口对比不算）。判决门不变，仍是既有 SPEC-6.3 B+R
  应答判据，opcode/endianness 加宽取值域不引入新判决维度。
- **testplan M2-AT01 行**追加 enrichment 说明句，如实注明"本卡只在
  atomic-load 编码子集内闭合，atomicstore/atomicswap/atomiccompare 未覆盖
  ，残余归属既有 BUG-0044（ACCEPTED@M5），不重复登记"。
- **orch 独立复验**：diff 审读确认只加一个类、testplan 只改一行，未越界；
  从 `make clean` 开始独立整跑全量回归确认 **29/29 PASS**；独立重跑
  `make cov TEST=m1_01_smoke_test` 生成 urg 合并报告，Python 直接解析
  `mod19.html`(axi_mux)/`mod12.html`(axi_demux_simple)/`mod32.html`
  (axi_err_slv) 的 toggle 表，**逐位核对与 DV 自报完全一致**：
  `aw.atop[3:0]`（合并视图）三模块均 No/No/No→**Yes/Yes/Yes**（双向全
  闭合）；`atop[4]` 三模块均维持 No/No/No（结构性摸不到——仅
  ATOMICSTORE/SWAP/CMP 才会置位，BUG-0044 边界，非本卡遗漏）；`atop[5]`
  三模块均维持 No/No/Yes（0→1 单向——1→0 同样需要非 atomic-load 类型才能
  摸到，同一边界）；`axi_err_slv` 的 `err_req.aw.atop[5:0]` 全部 7 组
  （6 实例+合并）维持 No/No/No，符合 BUG-0032 既有环境约束（未命中地址
  从未派发 ATOP，本卡命中地址构造未触碰该约束）。模块级 Toggle 现读数：
  `axi_mux` 89.34%、`axi_demux_simple` 93.73%（≥90%）、`axi_err_slv`
  69.78%（未达阈值，归入既有任务 #16-18 后续加固范围，非本卡目标）。
- Evidence 刷新：`doc/evidence/v0.4.30/M2-AT01.log`。
- 未新增 bug：确认本卡残余精确落在 BUG-0044 既有登记范围内，仅引用、不
  重复登记（orch 复核 `doc/bugs.md`/`doc/bugs/BUG-0044.md` 内容与本卡
  边界描述一致）。

**Not done**
- **REV-026 十项加固卡清单至此全部收官**。剩余：#14（M4 完整签核卡）、
  #15（BUG-0048 lint-baseline fixer）、#16-18（三张新发现的残余加固卡：
  demux COND ATOP×ar_id_cnt_full 交叉、mux fabric 级 ready 多笔背压、
  err_slv ar_ready 读方向背压）、#19（config_ongoing_i Kind-A 豁免 rev
  卡）均未派发。

**Next**
- 按队列继续：#19（Kind-A 豁免 rev 卡，DV 无权自行登记
  `doc/coverage-waivers.md`）优先，随后 #16-18 三张新加固卡，最后 #15
  （不阻塞门禁，视精力）与 #14（M4 最终签核，需等前述残余工作收敛后
  再评估是否需要更多卡或已可签核）。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + 从零全量回归 + urg 逐位核对（三
  模块 toggle 表 Python 直接解析，非人工估读），均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无新增
  gap（仅既有已知缺口）。

## [0.4.30] 2026-08-01 REV-026 加固卡 B-3 落地——addr_decode_dync Toggle 转正，副作用顺带闭合 F-1 目标；发现一个真 Kind-A 候选

**背景**：REV-026 批准清单 B-3（rule 边界重配，(a)→M2-CFG01/M3-CFG02）。
DV 卡先用 urg 核实：`addr_decode_dync` Toggle 89.00%（近阈值）/
Branch 83.33%（未到阈值）。判断"rule 边界重配多样性"实际该做的是
default-master-port 索引的双向翻转（`default_idx_i` 此前只单向从复位 0
抬升到 V1 值，从未下降），而非地址表本身。

**Done**
- **选择更安全的落地路径**：M3-CFG02 有 BUG-0031 guard 记录的脆弱三要素
  构造（重配后 + 同桶异完整 ID 兄弟 + 目标跨端口），DV 卡主动避开，只在
  M2-CFG01 上加。**`tb/xbar_types_pkg.sv`**：新增 `DEFAULT_MST_V2 =
  ~DEFAULT_MST_V1`（按位取反，`MST_PORT_IDX_W=3` 位恰好铺满
  `NoMstPorts=8`，取反结果必然仍是合法索引）。**`tb/seq_lib.sv`**：
  `m2_cfg01_reconfig_vseq` 追加 `do_reconfig_v2()`/`do_reconfig_v3()`
  （同既有 `do_reconfig()` 一样的全端口空闲窗口纪律）+
  `slvport_cfg01_defaultdiv_seq`——V1→V2（取反）验证一轮，V2→V3（复原
  为 V1，round-trip）再验证一轮，两步合起来补齐 V1 单向抬升遗留的
  每端口每一位缺口。
- **orch 独立复验**：diff 审读确认 M3-CFG02 相关文件（
  `tb/sva/axi_xbar_stall_sva.sv`/`tb/sva_bind.sv`/
  `slvport_cfg02_seq`）一行未动；亲跑
  `TEST=m3_cfg02_reconfig_test` 确认 BUG-0031 guard 的四类 cover 命中数
  （`c_sib_diff_aw/ar`、`c_bug31_livev1_aw/ar`）逐端口"1 match"与既有
  基线完全一致、无回归；从 `make clean` 开始独立整跑全量回归确认
  **29/29 PASS**；独立核对 `addr_decode_dync` Toggle **89.00%→92.00%
  （转正 ≥90%）**，Branch 维持 83.33%（符合预期，见下）。
- **发现一个真 Kind-A 候选**：Branch 83.33% 唯一残余（`addr_decode_dync.
  sv:146` 的 `if (!$isunknown(addr_map_i) && ~config_ongoing_i)` false
  分支）与部分 Toggle 残余同根——`config_ongoing_i` 在
  `addr_decode.sv:106` 每个例化点都硬接 `1'b0`，是 RTL 内部线网、非顶层
  可控端口，任何激励都摸不到。orch 独立核实成立。**已登记后续 rev 卡**
  （DV 无权自行登记 `doc/coverage-waivers.md`）。
- **顺手核实：F-1（default_mst_port_i 双向翻转）目标已被本卡副作用完整
  闭合**——orch 独立核对 `axi_xbar` 的 `default_mst_port_i[5:0][2:0]`
  现已 **Yes/Yes/Yes（全闭合）**，模块级 Toggle 由 P0 基线 40.74% 升至
  **94.44%**。F-1 无需再派独立 DV 卡，任务标记完成。
- Evidence 刷新：`doc/evidence/v0.4.29/M2-CFG01.log`。

**Not done**
- REV-026 最后一项 C-2（M2-AT01 ATOP 命中地址扩展）+ 三张新任务
  （#16-18）+ Kind-A 豁免 rev 卡（#19）+ BUG-0048 fixer 卡 + 最终 M4
  签核卡未派发。

**Next**
- C-2（M2-AT01 aw.atop[5:0] 命中地址扩展，REV-026 十项加固卡的最后
  一项，附 SPEC_ISSUE 残余上报纪律）。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + M3-CFG02 guard 数字核对 + 从零
  全量回归 + urg 逐字节核对（含顺手核实 F-1），均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无新增
  gap。

## [0.4.29] 2026-08-01 REV-026 加固卡 E-1 落地——M3-DE01 组收官，err_slv ID toggle 全闭合

**背景**：REV-026 批准清单 E-1（err_slv id[4:0]，(a)→M3-DE01），M3-DE01
组第二张（也是最后一张）。DV 卡先用 urg 核实：`slv_resp_o.b.id[4]` 在
全部 6 个实例上从未翻转过（既有场景写方向 ID 从未超过 9）、
`slv_resp_o.r.id[4]` 在 4 个实例上只翻过一个方向。

**Done**
- **`tb/seq_lib.sv`**：新增 `slvport_de01_iddiv_seq`，作为 M3-DE01 第三趟
  fanout 叠加（不改前两趟）。每端口驱动 id=0→id=31（`id_slv_t` 全 1）
  →id=0 的饱和往返，写/读方向各一次，同 A-1/A2 当初的地址镜像饱和读
  同一手法搬到 ID 维度。地址复用既有未命中窗口、取与前两趟不重叠的
  偏移量，`atop` 恒 `'0` 原样保留。
- **testplan M3-DE01 行**在 B-2 那句之后追加 E-1 的 enrichment 句。
- **orch 独立复验**：diff 审读确认只加不改；从 `make clean` 开始独立
  整跑全量回归确认 **29/29 PASS**；独立核对 `slv_resp_o.b.id[4:0]`/
  `slv_resp_o.r.id[4:0]` 均转为 **Yes/Yes/Yes（全闭合，双向）**——不只是
  bit4，饱和往返构造顺带闭合了其余位上零散残留的单向缺口；
  `axi_err_slv` 模块级 Toggle **68.59%→69.19%**，与 DV 卡自报数字完全
  一致。
- Evidence 刷新：`doc/evidence/v0.4.28/M3-DE01.log`。

**Not done**
- **M3-DE01 组（B-2/E-1）收官**。REV-026 剩余三项（B-3/C-2/F-1）+ 三张
  新任务（#16-18）+ BUG-0048 fixer 卡 + 最终 M4 签核卡均未派发。

**Next**
- B-3（M2-CFG01/M3-CFG02 rule 边界重配加宽）。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + 从零全量回归 + urg 逐字节核对，
  均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无新增
  gap。

## [0.4.28] 2026-08-01 REV-026 加固卡 B-2 落地——M3-DE01 err_slv 地址多样性自给自足

**背景**：REV-026 批准清单 B-2（err_slv 未命中 addr，(a)→M3-DE01）。DV 卡
落地前先用 urg 核实残余，发现一个值得记录的事实：**地址维度在本卡落地前
已经 100% 覆盖**——不是本场景自己做到的，而是 M1-01 的 A-1/A2/B-1/C-1
四张加固卡的地址多样化激励，作为副作用顺带翻转了 err_slv 入侧的地址位
（demux 的译码错误输出结构上总是把完整 aw/ar 字段送进 err_slv，只是
valid 按实际选中的目标门控——即使那笔事务本该命中别处，字段仍然"路过"
了 err_slv 的输入端口）。

**Done**
- **DV 卡诚实报告**：B-2 字面的数字目标在落地前已经满足，如实说明而非
  编造"大幅收敛"的叙事。
- **仍判断值得落地**：M3-DE01 目前的地址覆盖完全依赖一个**无关场景**
  的副作用，不是设计上的保证、脆弱。新增 `slvport_de01_addrdiv_seq`
  （独立类，不改共享的 `slvport_de01_seq`——零连带影响 M4-RC01/M4-EB01/
  M3-CF01/M3-CF02/M3-OR04，这些场景都复用后者），覆盖 rule 表边界外
  第一个地址、地址空间顶部饱和、两种交替位模式，四个地址构造上均
  `bit31=1`（读三份地址表生成器 `gen_addr_map`/`_v1`/`_ov1` 确认，
  任何配置下均落在 rule 表覆盖不到的区间），ID/len 复用既有映射不引入
  新 ID 取值（E-1 的范围）。
- **orch 独立复验**：diff 审读确认只加不改；从 `make clean` 开始独立
  整跑全量回归确认 **29/29 PASS**；独立核对 `axi_err_slv` Toggle
  **68.30%→68.59%**（小幅提升，符合预期——地址维度本就已满，这次
  提升实为重复相同 ID 映射时意外闭合的 `r.id[4]` 1→0 方向，DV 卡如实
  归因非编造）。
- Evidence 刷新：`doc/evidence/v0.4.27/M3-DE01.log`。

**Not done**
- E-1（err_slv id[4:0] 多样性）+ 队列剩余三项（B-3/C-2/F-1）+ 三张新
  任务（#16-18）+ BUG-0048 fixer 卡未派发。

**Next**
- E-1（err_slv id[4:0] 多样性，M3-DE01 组第二张）。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + 从零全量回归 + urg 逐字节核对，
  均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无新增
  gap。

## [0.4.27] 2026-08-01 REV-026 加固卡 D-1 落地——M1-01 组收官；DV 卡诚实标出三处结构性摸不到的残余，新登记三张后续卡

**背景**：REV-026 批准清单 D-1（简单 ready 翻转，条件化于 P0 残余）。
派卡前 orch 用 urg 定位到 axi_demux_simple 的全部 COND 残余集中在一个
ATOP×ar_id_cnt_full 交叉表达式，怀疑 D-1 原始设想（简单 ready 翻转）
碰不到它，明确要求 DV 先核实、允许如实报告"此路不通"而非硬凑数字。

**Done**
- **DV 卡独立核实**：确认 orch 的怀疑成立——axi_demux_simple COND 82.76%
  的全部 5 个未覆盖 bin 确实 100% 落在同一表达式，D-1 碰不到；但同时发现
  D-1 确实还有两处真实、可闭合的残余（`axi_mux`/`axi_demux_simple` 的
  `w_ready`/`r_ready` 从未独立翻转过）——**不是全有全无，落地了能落地的
  部分，如实标注碰不到的部分**。
- **`tb/mstport_agent.sv`**：新增独立旋钮 `bp_enable_w`（镜像既有
  `bp_enable`/`bp_enable_ar`，默认关闭），对 `w_ready` 施加周期性背压。
  **`tb/slvport_agent.sv`**：新增 `resp_ready_delay` 字段驱动的 `r_ready`
  有界拖延，**与该笔事务自己的 `r_valid`（ID 限定）同步**而非盲目提前
  脉冲（说明写得很仔细：流水级会把 AR 接受和 R 到达错开，提前起须的
  拖延窗口可能在 R 真正出现前就结束）。**`tb/seq_lib.sv`**：新增
  `slvport_readydelay_seq`，作为 M1-01 第五趟 fanout。
- **DV 卡的工程纪律亮点**：曾实现写方向 `b_ready` 拖延，urg 核实发现
  该 bin 已被 M4-EB01 顺带闭合、新代码零新增覆盖，**主动删除死代码**
  （而非留着凑行数）——同 `slvport_rdata_sat_seq` 当初"读专用、不加写腿"
  的判断一致。
- **orch 独立复验**：从 `make clean` 开始独立整跑全量回归确认
  **29/29 PASS**；独立核对 `axi_mux` Toggle 88.01%→**88.15%**、
  `axi_demux_simple` Toggle 92.48%→**92.73%**、COND 维持 82.76%（符合
  预期，本卡不动这个）——与 DV 卡自报数字完全一致。
- **新登记三张后续任务**（DV 卡诚实标出，非缺陷，均为覆盖率缺口）：
  (1) `axi_demux_simple` COND 残余——需 C-2（ATOP 命中地址）× BP02/BP03
  式饱和的交叉构造，现有任何已批准卡范围都不含；(2) `axi_mux` 内部
  fabric 级 `b_ready`/`r_ready`（`gen_mux.slv_b_readies`/`slv_r_readies`）
  ——被 demux→mux 间 `axi_multicut` 2 级流水缓冲吸收，M1-01 单笔在飞的
  构造结构性摸不到，需要"同端口 ≥2 笔响应同时挂起"的持续背压，量级大于
  D-1；(3) `axi_err_slv` `ar_ready`（Toggle 68.30%，此前未被点名）——
  需要 M4-EB01 的读方向对偶。
- Evidence 刷新：`doc/evidence/v0.4.26/M1-01.log`。

**Not done**
- M1-01 组（A-1/A2/B-1/C-1/D-1）全部完成，**M1-01 组收官**。REV-026
  剩余四项（B-2/E-1/B-3/C-2/F-1，注：C-2 现与新任务#16 有交叉，落地时
  一并考虑）+ 新增三项后续任务 + BUG-0048 fixer 卡均未派发。

**Next**
- 转向 M3-DE01 组：B-2（err_slv 未命中地址多样性）→ E-1（err_slv
  id[4:0] 多样性）。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + 从零全量回归 + urg 逐字节核对，
  均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无新增
  gap。

## [0.4.26] 2026-08-01 REV-026 加固卡 C-1 落地——M1-01 五维 sideband 加宽 + KILL-0005 注伤自证，axi_demux_simple Toggle 转正（≥90%）

**背景**：REV-026 批准清单 C-1（attrs/burst[1]/len/strb/user，(a)→M1-01），
附两条硬条件：(i) 预测器扩展须做 KILL 注伤自证、期望锚 AXI4 非 RTL；
(ii) enrichment 须显式列入 testplan 行文本。本卡是 M1-01 组里最复杂的一张，
按 L2（触及 scoreboard_refmodel.sv 判决逻辑）派 opus。

**Done**
- **DV 卡独立技术核实**（orch 只给了初步印象，明确要求 DV 自己验证）：
  WRAP 读回卷与稀疏 wstrb 写完整性**均非新 checker 代码路径**——
  `predict_beat_data` 早已委托 vendor 通用 `axi_pkg::beat_addr`（AXI4
  A3-51 回卷语义）、写完整性本是全字 data+strb 透传比较对任意 strb 取值
  天然成立；真正的缺口是纯激励从未驱动过这些取值。属性字段
  （cache/prot/qos/region/lock/user）则是真实缺失环节——`axi_seq_item`
  原无这些字段，driver 硬编码 `'0`。
- **`tb/axi_txn.sv`**：`axi_seq_item` 新增 6 个 sideband 字段，`new()` 全
  默认 `'0`（既有全部激励逐字节不变）。**`tb/slvport_agent.sv`**：driver
  由硬编码 `'0` 改读 `item.*`（默认值下行为不变）。**`tb/seq_lib.sv`**：
  新增 `slvport_sideband_div_seq`，作为 M1-01 第四趟 fanout 叠加，逐条
  覆盖 WRAP/长突发(16 拍)/稀疏 strb(8 种轮换)/属性高低饱和对/user=1。
- **KILL-0005**（`doc/bugs.md`）：对 WRAP 回卷比较（`SB_RDATA`）与稀疏
  strb 写完整性比较（`SB_WDATA`）两条真实吃到的判决路径分别注伤——把
  `scoreboard_refmodel.sv:1053` 的 `ro.burst` 改常量 `BURST_INCR` →
  48 处 mismatch 见红；把 `:737` 期望 strb 异或扰动 → 234 处见红；均
  复原后归零。**orch 独立复现 KILL-A**（不只读文字记录）：亲自注入同一
  处改动重跑，得到与登记逐字节一致的错误信息（`slv port 4 id 'h1b R
  beat 1 mismatch: got data='h0 ... expected data='h1000000010`）；复原
  后 `git diff tb/scoreboard_refmodel.sv` 为 0 行、`UVM_ERROR:0`——KILL
  记录真实、非虚报。
- **orch 独立复验**：从 `make clean` 开始独立整跑全量回归确认
  **29/29 PASS**；独立生成 merged urg 报告核对 `axi_mux` Toggle
  **76.93%→88.01%**、`axi_demux_simple` Toggle **80.45%→92.48%**——
  **`axi_demux_simple` Toggle 首次转正（≥90%）**，与 DV 卡自报数字完全
  一致。
- Evidence 刷新：`doc/evidence/v0.4.25/M1-01.log`。

**Not done**
- M1-01 组的 D-1（条件性，视残余决定是否仍需要）+ 队列剩余六项
  （B-2/E-1/B-3/C-2/F-1）+ BUG-0048 fixer 卡未派发。

**Next**
- 评估 D-1（ready-delay 分布）是否仍有必要——`axi_mux`/`axi_demux_simple`
  当前 Cond/Branch 残余是否需要它，还是转向 M3-DE01 组（B-2/E-1）更值得。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + 从零全量回归 + urg 逐字节核对 +
  **亲自重现 KILL-A 注伤全过程**（红→复原→绿），均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无新增
  gap。

## [0.4.25] 2026-08-01 REV-026 加固卡 B-1 落地——M1-01 叠加写向地址饱和序列，axi_mux/demux addr toggle 进一步收敛

**背景**：REV-026 批准清单 B-1（addr 饱和，(a)→M1-01）。DV 卡落地前先用
urg 亲自核实残余现状（不假设 A-1/A2 已顺带解决），发现 A-1/A2 是纯读，
`aw.addr` 在同样的位位置仍全 No——B-1 的真实缺口是"写方向从未独立加宽过
地址取值"。

**Done**
- **`tb/seq_lib.sv`**：新增 `slvport_waddr_sat_seq`，与已落地的
  `slvport_rdata_sat_seq`（A-1/A2）逐字节镜像，只是作用于 `aw`/`w` 而非
  `ar`——同一 lo/hi/lo 饱和地址构造搬到写方向，同样作为 M1-01 的第三趟
  fanout 叠加（不替换前两趟）。
- **testplan M1-01 行**在 A-1/A2 的 enrichment 句之后追加 B-1 的
  enrichment 句（未覆盖前者）。
- **orch 独立复验**（不采信 DV 卡自报）：`git diff` 确认改动只加不改；
  从 `make clean` 开始独立整跑全量回归确认 **29/29 PASS**；亲自生成
  merged urg 报告，独立核对 `axi_mux` Toggle **73.49%→76.93%**、
  `axi_demux_simple` Toggle **77.07%→80.45%**——与 DV 卡自报数字完全
  一致。DV 卡如实标注残余归属：字节对齐位 `addr[2:0]`（C-1 范围，非本卡）
  + 部分 `addr[28:31]` 区域窗口位（仅重配 rule 表或未命中/default-port
  路由才会翻转，属 B-3/M3-DE02/M4-RC01 范围）——未为凑数字越界处理。
- Evidence 刷新：`doc/evidence/v0.4.24/M1-01.log`。
- Taxonomy 自查：`make lint-diff` 前后站点数一致（77 个，行号偏移但
  站点集合逐点比对为空差集），确认未引入新 lint 类别，不重复登记
  BUG-0048。

**Not done**
- REV-026 剩余七项加固卡（C-1/D-1/B-2/E-1/B-3/C-2/F-1）+ BUG-0048
  fixer 卡未派发。M1-01 组的 A-1/A2/B-1 三项均已落地。

**Next**
- C-1（M1-01 sideband 属性/WRAP/长突发/稀疏 strb，含 KILL 注伤自证，
  REV-026 附两条硬条件）。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + 从零全量回归 + urg 逐字节核对，
  均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无新增
  gap。

## [0.4.24] 2026-08-01 REV-026 加固卡 A-1+A-2 落地——M1-01 叠加地址镜像饱和读，axi_mux/demux r.data toggle 大幅收敛；顺手登记 BUG-0048（lint 基线过期）

**背景**：REV-026 批准清单 A-1/A-2（r.data 饱和，(a)→M1-01 合并卡）。技术
依据 M4-toggle-bit-decomposition.md：本环境读数据=地址镜像
（`predict_beat_data={beat_a,beat_a}`），故 all-0/all-1 饱和读序列即可
闭合 `axi_mux mst_resp_i.r.data[63:0]`/`axi_demux_simple
slv_resp_o.r.data[63:0]` 的逐位 toggle 缺口。

**Done**
- **`tb/seq_lib.sv`**：新增 `slvport_rdata_sat_seq`，在 M1-01 既有激励
  **之上叠加**（非替换）第二轮 fanout：每 slave 端口对每 master 端口各发
  低饱和（区间内地址位全 0）→高饱和（全 1）→低饱和的单拍读序列——
  lo/hi/lo 三段而非单一 lo→hi 对是刻意的：单一对只能证明一个 toggle
  方向，三段序列自身程序序即可独立完成双向翻转，不依赖其他 slave 端口
  并发流量的偶然交织。
- **testplan M1-01 行**按 REV-026 条件 2 显式列出 enrichment 维度文本
  （不是静默替换）。
- **orch 独立复验**（不采信 DV 卡自报）：`git diff` 确认改动只加不改
  （原 `slvport_basic_seq` 那趟 fanout 一字未动）；从 `make clean` 开始
  独立整跑全量回归确认 **29/29 PASS**；亲自生成 merged urg 报告，独立
  核对 `axi_mux` Toggle **62.55%→73.49%**、`axi_demux_simple` Toggle
  **72.56%→77.07%**——均为真实、显著提升，均未到 90%（DV 卡如实报告
  残余：`axi_mux` 剩 8 位是窄突发字节对齐位（C-1 范围）+ 2 位是仅
  M3-DE02/M4-RC01 default-port 路由才会翻转的地址位（不同场景范围，
  按"小闭环不堆 mega-edit"纪律未强行在本卡内解决），不为凑数字勉强）。
- Evidence 刷新：`doc/evidence/v0.4.23/M1-01.log`。
- **顺手登记 BUG-0048（TOOL_ENV，OPEN）**：DV 卡按纪律对自己改动的
  `tb/seq_lib.sv` 跑 `lint-diff` 做尽职检查，发现 `doc/lint-baseline.md`
  自 BUG-0040 的 2026-07-31 全量重同步后，六次 tb/ 落地（M4-EB01/BP02/
  BP02-w_open3-fix/BP03/本卡）从未重跑重同步步骤，累积 62-77 个新站点
  （0 新类别）。`git stash` 隔离确认与本卡自身改动无关、是既存漂移
  （BUG-0040 自己的 guard 早已预告"未来若不重跑会假绿"，这条正是该预告
  应验）。**orch 独立复核**：亲跑 `cd sim && make clean && make lint-diff
  TEST=m1_01_smoke_test`（本卡改动仍在工作区）确认 77 个新站点，数字
  与登记一致，非虚报。不阻塞 M4 覆盖率工作（lint 不在 `make check`/
  `make selftest` 门禁内）；已建后续 fixer 卡任务（closer≠fixer，逐站点
  分诊）。

**Not done**
- REV-026 剩余九项 (a)/(b) 加固卡（B-1/C-1/D-1/B-2/E-1/B-3/C-2/F-1）+
  BUG-0048 fixer 卡均未派发。

**Next**
- 继续 M1-01 组：B-1（地址饱和/rule 多样性）→ C-1（sideband 属性/WRAP/
  长突发/稀疏 strb，含 KILL 注伤自证）→ D-1（ready-delay 分布，视残余
  决定是否仍需要）。各自独立小闭环。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + 从零全量回归 + urg 逐字节核对 +
  BUG-0048 亲自复现，均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无新增
  gap。

## [0.4.23] 2026-08-01 REV-027 加固卡 B 落地——新场景 M4-BP03（AR 侧对偶），五件套一次性转正

**背景**：REV-027 §5「加固卡 B」+ M4-P0-remeasure.md §3 精确定位：
M4-BP02 是纯写场景，AR 侧对偶（`lock_ar`/`ar_id_cnt_full` 及其伴随的 3
条 valid-but-not-ready 断言）在全部既有场景里从未触达。派 L1 DV 卡落地。

**Done**
- **新 testplan 行 M4-BP03**（`doc/testplan.md`）：M4-BP02 的读方向对偶。
  单 slave 端口并发多笔读 burst（同桶）+ AR 持续背压（新增独立旋钮
  `bp_enable_ar`，`tb/mstport_agent.sv`，镜像 M4-AW01 的 `bp_enable`、
  默认关闭不影响任何既有场景）+ `resp_hold` 作用于 R 通道令同桶在飞读
  数压至 §5.4.1 有效上限。**无需新写驱动任务**——DV 卡指出一个干净的
  不对称性：写方向需要 `drive_burst_wopen` 是因为一个写子项的 W burst
  会在下一个 AW 出现前排空完，而读子项的整个请求阶段就是它的 AR 握手
  本身，既有 `drive_burst()` 非写分支早已背靠背连续发出 AR，读方向的
  持续压力从既有原语里自然落出，不必比照写向再造一个。
  `tb/functional_coverage.sv` 新增 `cg_ar_retry`（外部 valid/ready 观测，
  非判决，镜像 `cg_aw_retry`）。
- **orch 独立复验**（不采信 DV 卡自报）：`git diff` 逐文件读过，确认改动
  精确镜像既有 M4-AW01/BP02 模式、无越权；**从 `make clean` 开始独立
  整跑一次全量回归**确认 **29/29 PASS**；亲自生成 merged urg 报告，
  独立核对 5 项目标 gate 全部转正——`lock_ar_valid_q/_d`/`ar_id_cnt_full`
  在 `gen_slv_port_demux[0]` 实例转 Yes（确认是被本场景施压的那个实例，
  非巧合）；`ar_valid_stable`/`slv_ar_chan_stable`/`slv_ar_select_stable`
  三条 Assert 由 0 real-succeeded 转为各 22 次、0 failure。`axi_demux_simple`
  模块级聚合：LINE 91.86%→**100%**、BRANCH 88.89%→**100%**、
  ASSERT 71.43%→**92.86%**（=13/14，恰好符合预期——14 条中只剩
  `NoAtopAllowed` 在 baseline 下结构性 N/A，已在 cfgD 报告独立闭合，
  非缺口）、COND 79.31%→82.76%、TOGGLE 71.18%→72.56%。
- Evidence：`doc/evidence/v0.4.22/M4-BP03.log`（机械生成），
  `sim/regress/regress.list` 补行。
- **顺手补 feature-matrix**（L0 haiku 卡，独立复核）：新场景导致 chain
  audit 新增 1 个 gap（M4-BP03 无 feature-matrix 行），当场派卡补
  F-M4-07（镜像 F-M4-06 的读方向表述），`make check` 复核 gap 归零。

**Not done**
- REV-026 十项 (a) 加固卡均未派发——两张 REV-027 加固卡已全部落地，
  下一步转向 A-F 队列。

**Next**
- 开始 REV-026 十项 (a) 加固卡：优先处理全部合并进 M1-01 的一组
  （A-1+A-2/B-1/C-1/D-1，各自独立小闭环、不堆 mega-edit），再到
  M3-DE01（B-2/E-1）、M2-CFG01/M3-CFG02（B-3）、M2-AT01（C-2）、
  M3-DE02/M2-CFG01（F-1）。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + 从零全量回归 + urg 逐字节核对
  三重独立复核，均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无残留
  gap（含新场景的 feature-matrix 行已补齐）。

## [0.4.22] 2026-08-01 REV-027 加固卡 A 落地——M4-BP02 写向 w_open[3] 转正，LEAD 深度经验安全上探

**背景**：REV-027 驳回 w_open[3] 豁免、判定其是驱动 LEAD 窗口过保守的产物
而非结构不可达，给出加固方向（LEAD 从 MaxSlvTrans-1 抬高到真实下游吸收
深度）。派 L1 DV 卡（sonnet）落地，dv 独立读 REV-027 全文取技术依据，本卡
不代其转述。

**Done**
- **`tb/slvport_agent.sv`**：`drive_burst_wopen` 的 `LEAD` 由固定
  `MaxSlvTrans-1`（=5）改为 `MaxSlvTrans + 2*PipelineStages + 1`（=9，
  只用 Cfg 参数推导，不抄 RTL 值）。**经验探测过程**（每步套 `timeout`
  防止真死锁）：LEAD=6..10 全部干净结束、跨 SEED=1/2/3/42 完成时刻
  逐位一致（确定性非运气）；**LEAD=11 触发驱动任务自死锁**，被
  `tb_top` 自带 watchdog 安全捕获（`UVM_FATAL`，非真挂起）——证实这是
  单线程"先开窗后排空"驱动任务自身的阈值，非 DUT 死锁，与 REV-027 的
  判断一致。最终值留 1 笔余量于探得安全上限（10）、2 笔余量于首次失败
  点（11）。
- `tb/seq_lib.sv` 同步订正两处随之过时的旧注释（不再声称 LEAD 卡在 mux
  FIFO 深度下）。
- **orch 独立复验**（不采信 DV 卡自报）：`git diff` 确认改动只有 3 个
  文件、36 行，外科手术式；单跑 `make run TEST=m4_bp02_demuxlock_test
  SEED=1` 确认 `UVM_ERROR:0`、`SB_SUMMARY` 全零 mismatch、svacheck
  PASS；**从 `make clean` 开始独立整跑一次全量回归**（不复用 DV 卡自己
  的构建产物）确认 28/28 PASS；亲自生成 merged urg 报告，逐字节核对
  `axi_demux_simple` 实例 0（本场景施压的实例）的 `genblk1.w_open[3:0]`
  三列 toggle 状态**全 Yes**（此前 baseline 下该实例与其余实例一样
  `w_open[3]=No`）——`w_open[3]` 转正证据独立复核，非采信转述。
  `axi_demux_simple` 模块级 Toggle 聚合由 70.93%（P0 基线）微升至
  71.18%（符合预期——本卡只关一个 bit，不是全部残余）。
- Evidence 刷新：`doc/evidence/v0.4.21/M4-BP02.log`（`make evidence`
  机械生成，非手写），testplan M4-BP02 行证据路径同步更新，判决门/红线
  正文未变。

**Not done**
- REV-027 加固卡 B（AR 侧对偶：`lock_ar`/`ar_id_cnt_full` + 3 条 AR 侧
  valid-but-not-ready 断言，五件套）尚未派发。
- REV-026 十项 (a) 加固卡均未派发。

**Next**
- 派发加固卡 B（AR 侧对偶新场景）。

**How verified**
- 见上"orch 独立复验"段——单场景 + 从零全量回归 + urg 逐字节核对三重
  独立复核，均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无新增
  gap 类别。

## [0.4.21] 2026-08-01 P0 全量合并重测完成，精确核出十项加固卡当前真实残余（doc/evidence/v0.4.20/M4-P0-remeasure.md）

**背景**：REV-026 强制要求全体 (a) 加固卡派发前先做一次全量 COV=1 合并
重测，用当前（含 M4-EB01/BP02/CW-006/007 落地后）真实数字定各卡精确
scope，而非沿用 v0.4.13 旧 signoff 的过时残余风险表。

**Done**
- `cd sim && make clean && make regress COV=1`：**28/28 PASS**（含全部
  M0-M4 场景）。baseline 拓扑合并报告（22 场景）+ cfgD 独立报告，逐模块
  对照旧 v0.4.13 残余风险表，写入
  `doc/evidence/v0.4.20/M4-P0-remeasure.md`（纯记账，不含处置判断）。
- **确认已完全闭合、无需再派卡的三项**：`axi_xbar_unmuxed` Assert
  53.85%→**100%**（M4-AW01/BP02 的下游背压顺带闭合）；`axi_demux_simple`
  Line 83.72%→**91.86%**；`axi_err_slv` Cond 83.33%→**100%**。
- **确认 REV-026 批准的十项 (a) 加固全部仍有真实残留**，无一项因合并后
  自然闭合而作废——各卡按原批准范围继续派发（P0 本身即 REV-026 条件 1
  的兑现证据）。
- **精确定位 axi_demux_simple 14 条 Assert 中 4 条 0-real-success 的
  逐条性质**：`NoAtopAllowed` 在 baseline（ATOPs=1）结构性不可达属正常，
  已在 cfgD（ATOPs=0，M3-CF04）独立报告中 real-succeeded 24 次，**非
  缺口**；`ar_valid_stable`/`slv_ar_chan_stable`/`slv_ar_select_stable`
  （AW 侧三条稳定性断言的 AR 镜像）**真实未闭合**——与 REV-027 §2.5 核实
  的 `lock_ar_valid_q/_d`/`ar_id_cnt_full` 同根，同一个 AR 侧持续背压
  构造应一并闭合这 5 项（3 Assert + 2 Toggle）。已更新任务清单：
  REV-027 加固卡 B 的验收判据据此加精。

**Not done**
- 十项 (a) 加固卡 + REV-027 两张加固卡均未派发——本轮只完成 P0 记账。

**Next**
- 开始逐条派发：优先 REV-027 加固卡 A（w_open[3] LEAD 加深，M4-BP02 上
  改动）与加固卡 B（AR 侧对偶，五件套一次闭合），再回到 A-F 十项，逐条
  小闭环、独立核实、evidence、closeout、push。

**How verified**
- `make regress COV=1` 亲跑 28/28 PASS；`make cov` 分别生成 baseline 与
  cfgD 报告，urg HTML 逐模块/逐断言亲读取数（非采信任何转述），取数命令
  见 `doc/evidence/v0.4.20/M4-P0-remeasure.md` 首行。
- `make check`/`make selftest` 本轮收尾前复跑（见下）。

## [0.4.20] 2026-08-01 feature-matrix 补齐 6 条 M4 行（chain audit gap 清零）+ P0 全量合并重测已在后台起跑

**背景**：用户授权 orch 全权自动推进 M4 到极致，每闭环推送，不中途请示。
按 REV-026 汇总清单，第一步是全体加固卡的强制前置——P0 merge-remeasure
（`make regress COV=1` 全量重跑，供后续各条 (a) 加固定精确范围）；与此
并行，先处理一张互不冲突（纯文档，不碰 tb/、不跑仿真）的 L0 卡，避免
干等。

**Done**
- **L0 文档卡（haiku，无 rev）**：`doc/feature-matrix.md` 补齐 F-M4-01~06
  六行，对应 M4-RC01/AW01/OV01/FT01/EB01/BP02。orch 独立复核：`git diff`
  确认只改了这一个文件、6 行纯新增；`make check` 复跑确认 chain audit 的
  "scenarios in no feature-matrix row" gap 由 6→0，无新增 gap 类别。
- **P0 merge-remeasure 已在后台发起**：`cd sim && make clean && make
  regress COV=1`（28 个场景，含 0.4.18 新增的 M4-EB01/BP02）。用于给
  REV-026 批准清单里的 A-1/A-2/B-1/B-2/B-3/C-1/C-2/D-1/E-1/F-1 十项
  (a) 加固卡定精确残余范围（先合并再定范围，REV-026 §汇总："这是 M4
  出口的正确下一动作"）。

**Not done**
- P0 合并重测本轮尚未跑完（后台运行中，跨轮次继续等待，完成后独立核对
  真实残余数字，非采信任何转述）。
- REV-026 批准清单里的十项 (a) 加固卡、REV-027 的两张读/写向补场景卡、
  以及最终 M4 签核卡均未派发——依赖 P0 结果定范围，本轮暂不能派。

**Next**
- P0 跑完后：逐条核对 v0.4.13 旧 signoff 残余风险表 + M4-toggle-bit-
  decomposition.md 的六类缺口，在当前（含 EB01/BP02/CW-006/CW-007）
  基线上哪些已经关闭、哪些仍残留，据此定十项加固卡的精确 scope，逐条
  派 DV 卡（同一目标 testplan 行的多项加固仍按 REV-026 条件 6 拆成独立
  小闭环，不堆 mega-edit），每卡独立核实+evidence+closeout+push。

**How verified**
- feature-matrix 补行：`make check` chain audit 段落亲跑核对（见上）。
- `make selftest` 本轮收尾前复跑（见下）。

## [0.4.19] 2026-08-01 REV-027——w_open[3] 覆盖率豁免驳回（非结构不可达，是激励产物），顺带查出 M4-BP02 只闭合 AW 侧、AR 侧对偶缺口仍开

**背景**：0.4.18 遗留的 open risk——DV 卡称 w_open[3]（值≥8）在基线
`MaxSlvTrans=6` 下"结构性不可达"、建议 Kind-A 豁免。用户授权 orch 全权
派卡裁决。派发一张 L3 rev 卡（独立首过，opus，全 rubric），只给一手材料
文件/行号清单，不带任何一方结论（含 26 条 make guards 命中，Hard/Context
分栏逐字粘贴）。

**Done**
- **rev 独立裁决完毕，doc/review/REV-027.md**：**驳回豁免**（不登记任何
  coverage-waivers.md 条目，CW-008 保留未用）。核心发现：w_open 是
  demux 内部"W 解复用控制计数器"（4 位，由 `MaxMstTrans=10` 定宽），RTL
  门仅在满量程 15 设限，**不在 8**；spec §5.4.2"基线见证达 8>6"讨论的是
  另一个计数器（每桶 AW ID 计数器，pop 于 B），**不是** w_open（pop 于
  W）——DV 卡的转述张冠李戴。w_open 真实上界 = 下游 AW 吸收深度（mux
  w_fifo 深度 6 + demux→mux `axi_multicut` spill 容量 2 + demux 自身
  lock 1 ≈ 8~9），且随 `LatencyMode` 逐 config 浮动（cfgB 更宽）——结构
  上足以翻 bit3，非结构常量。观测峰值 5 = 驱动 `drive_burst_wopen` 自设
  `LEAD=MaxSlvTrans-1` 的产物（基于"LEAD≥mux FIFO 深度即死锁"这一**不
  准确**的前提——mux w_fifo 满是可恢复背压，W 末拍无条件弹出、与 full
  无关）。Kind-A 举证责任未尽；Kind-B 被 BUG-0047 guard + REV-024 §4
  （控制/计数位排除在外）双重禁止。
- **rev 亲自重跑取数**：裁决开始时 sim/out 是未带 COV=1 的空壳（同
  KILL-0004 型号），亲自 `make clean && make regress COV=1`（28/28
  PASS）后从真实 merged 基线 vdb 用 `urg` 取逐位 toggle（本机 xcov 因
  Verdi 版本早于受测基线不可用，记 TOOL_ENV、非阻塞）。
- **顺带查出（rev Q5 核实）**：M4-toggle-bit-decomposition.md 原把
  `lock_aw/ar`、`aw/ar_id_cnt_full` 成对列为缺口，M4-BP02 是纯写场景，
  **只闭合了 AW 侧**（`lock_aw_valid_q/_d` 全 7 实例 Yes、`aw_id_cnt_full`
  受压端口 Yes、`w_open[2:0]` 全 Yes）；**AR 侧（`lock_ar_valid_q/_d`、
  `ar_id_cnt_full`）全 7 实例仍为 No，完全未闭合**——0.4.18 未点出这一半
  缺口，本次据真库补记。
- **taxonomy-class anomaly（rev 强制字段）**：否——w_open[3]/lock_ar/
  ar_id_cnt_full 是覆盖率缺口（零 mismatch、无 checker 见红），非
  failure_taxonomy 五类失败，不开 bugs.md 行；DV 转述的两处事实性偏差
  （"结构不可达"框架、"LEAD≥FIFO 即死锁"注释）是本次裁决订正的评审发现，
  非 DUT/TB/工具/spec/约束缺陷，M4-BP02 场景本身判决无泄漏、功能正确。
- **rev 交付 guidance（不写激励代码）**：排两张独立"需补场景"DV 卡，供
  orch 后续按 REV-024 §2 既定处置排队派发——加固卡 A（写向，关
  `w_open[3]`）：把 LEAD 从 `MaxSlvTrans-1` 经验性提高到真实下游吸收深度
  （≈8，须探定安全上界而非盲设常数，LEAD 推导只准用 Cfg 参数+经验探测，
  不得抄 RTL 内部信号值）；加固卡 B（读向，关 `lock_ar`/`ar_id_cnt_full`）
  ：AR 持续背压 + 读桶在飞数压至 §5.4.1 有效上限，判决门复用既有读向
  判据。两卡均不占用 coverage-waivers.md 条目。
- **定级 vs 实际**：L3/opus/全 rubric 与实际工作量相符（多文件 RTL/spec
  交叉推导 + 独立取数复验），无失配。
- 首轮派发因 orch 自己给的 Workflow 结构化输出 schema 设计缺陷
  （`taxonomy_anomaly` 字段声明为"必填+可空对象"，subagent 工具调用层
  反复无法满足校验，5 次重试耗尽后 workflow 报错退出）导致一次空跑；
  rev 的实际投入（186807 tokens、63 次工具调用、约 23 分钟）**并未浪费**
  ——doc/review/REV-027.md 已被完整写出（非结构化回传失败与审阅记录落盘
  是两件独立的事），orch 从磁盘上的记录文件直接读取裁决全文，未采信任何
  转述。schema 已改为扁平字段（去掉嵌套可空对象）供下次复用，但本次未
  重新触发 agent 调用（记录已存在，无需重跑）。

**Not done**
- 加固卡 A/B（w_open[3] 写向、lock_ar/ar_id_cnt_full 读向）尚未派发——
  按"小闭环即停"原则，本轮只完成裁决闭环，派发留给下一轮。
- 清单 B 剩余 (a) 类加固（A-1/A-2/B-1/B-2/B-3/C-1/C-2/D-1/E-1/F-1）仍未
  动手，需串行处理（REV-026 条件 6）。

**Next**
- 派发加固卡 A（w_open[3]，写向 LEAD 加深）与加固卡 B（AR 侧对偶缺口）
  ——两者互相独立、不触碰同一 seq 类的同一段代码（A 改 drive_burst_wopen
  的 LEAD 计算，B 是新读向场景），但均触及 tb/seq_lib.sv/slvport_agent.sv
  等共享文件，按 REV-026 条件 6 精神串行排队，不并行 worktree。
- 之后再回到清单 B 剩余 (a) 类加固。

**How verified**
- rev 亲自 `make clean && make regress COV=1`（28/28 PASS）+ `urg` 真库
  逐位 toggle 核对，非采信任何转述（doc/review/REV-027.md §0/§2.5）。
- orch 独立复核：确认 doc/review/REV-027.md 已完整落盘（六问结构齐备、
  Overall verdict 明确），未采信失败的 StructuredOutput 回传碎片。
- `make check`/`make selftest` 本轮收尾前复跑（见下）。

## [0.4.18] 2026-08-01 M4-EB01/M4-BP02 落地转绿——两张 DV 卡并行 worktree 实现，独立复验+合并冲突手工消解

**背景**：清单 B 批准清单里的两条新场景（err_slv B 通道背压 / demux 锁定
FSM+ID 计数饱和叠加压力）互相独立、非 merge-gated，用两个并行 worktree
隔离的 DV 卡实现，避免同时编辑共享 tb/ 文件互相踩踏。

**Done**
- **M4-EB01（独立 worktree，DV 卡）**：新增 `slvport_eb01_seq`/
  `m4_eb01_errbp_vseq`/`m4_eb01_errbp_test`，`axi_burst_item` 加
  `b_backpressure` 字段，`slvport_driver`/`slvport_monitor` 实现 B 通道
  持续背压 + `cg_errbp` 非空转见证。判决门复用 M3-DE01 的
  `SB_DECERR_*` 判据族（不新发明期望值）。**orch 独立复验**：亲跑
  `make run TEST=m4_eb01_errbp_test SEED=1` 确认 `UVM_ERROR:0`、
  svacheck CLEAN、`resp match=60 mismatch=0`、`cg_errbp samples=564
  inst_cov=100%`（背压确实被激励到，非空转）；检查 diff 干净、无越权
  改动。DV 卡如实指出卡片指示的文件名有误（`mstport_agent.sv`应为
  `slvport_agent.sv`——err_slv 挂在 slave 侧非 master 侧），已自行纠正，
  未盲从。
- **M4-BP02（独立 worktree，DV 卡）**：新增 `slvport_bp02_seq`/
  `m4_bp02_demuxlock_vseq`/`m4_bp02_demuxlock_test`，`axi_burst_item` 加
  `wopen_mode` 字段 + 滑动窗口驱动 `drive_burst_wopen`（保持 ≥3 个 W
  burst 同时打开）+ 复用 M4-AW01 的 `aw_ready` 背压机制 + 复用
  M2-TL01/M3-TL01 的 `resp_hold` 机制把同桶在飞数压至 §5.4.1 有效上限
  15。**orch 独立复验**：亲跑确认 `UVM_ERROR:0`、CLEAN、
  `route/resp/worder match=15 mismatch=0`、`cg_tx_limit inst_cov=100%`
  （含 `at_effective_ceiling=15` bin）、`cg_aw_retry samples=15
  inst_cov=100%`。DV 卡顺手报告了内部 RTL 事实（xdebug，仅供参考非判决
  依据）：`w_open` 峰值 5、`lock_aw_valid_q` 22 次翻转、
  `aw_id_cnt_full` 曾置位——证明结构覆盖非空转。**Open risk**（DV 卡
  如实标注，非隐瞒）：`w_open[3]`（≥8）在基线 `MaxSlvTrans=6` 下结构性
  不可达（mux AW→W FIFO 封顶），是覆盖率豁免候选而非"需要更强激励"。
- **两个 worktree 独立编写、独立通过后，orch 合并回 master**：
  `doc/testplan.md`/`sim/regress/regress.list`/`sim/result_summary.txt`/
  `tb/test_lib.sv` 四处产生真实文本冲突（两卡各自新增行相邻/两卡各自
  新增 test class 相邻），手工消解——保留两条新增内容而非二选一（doc/
  testplan.md 两行都转 ✅ 各自 evidence 路径；regress.list/
  result_summary.txt 两个 TEST 都保留；test_lib.sv 两个 class 都保留）；
  `tb/axi_txn.sv`/`tb/seq_lib.sv`/`tb/slvport_agent.sv` 三个文件 git
  自动三路合并成功（无冲突，两卡分别新增的字段/函数/类互不重叠）。
  **合并后 orch 在主目录里重新独立验证**：单跑 M4-EB01/M4-BP02 各自仍
  CLEAN，全量回归 `make regress` **28/28 PASS**（较之前 26/26 净增两条，
  证明两个 worktree 的改动合并后确实互不干扰）。
- `make check`/`make selftest`（61/61）复跑绿。

**Not done**
- `w_open[3]`（M4-BP02 open risk）尚未走 rev 裁决——是否登记为
  `doc/coverage-waivers.md` 的又一条 Kind-A（结构性不可达，`MaxSlvTrans`
  封顶导致），还是先按下不表，留给后续覆盖率复核时处理。
- 清单 B 剩余的 (a) 类加固（A-1/A-2/B-1/B-2/B-3/C-1/C-2/D-1/E-1/F-1）
  仍未动手——这些都会触及 M1-01/M2-AT01/M3-DE01/M2-CFG01 等既有场景的
  共享激励代码，按 REV-026 条件 6 的"小闭环、非并行"要求排队处理。

**Next**
- 用户表态继续多 subagent 开工；下一批可考虑：(1) 派 rev 卡处置
  `w_open[3]` 覆盖率豁免；(2) 开始清单 B 的 (a) 类加固——因需触及共享
  激励文件，建议串行（pipeline）而非 worktree 并行处理，逐条走"小闭环
  即停"。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口类别。
- `make selftest`：61/61 OK。
- 两张 DV 卡各自独立 worktree 内均已验证转绿（orch 亲跑，非采信自报）；
  合并后主目录里对两个场景分别单跑复核仍 CLEAN；全量回归 28/28（含
  M4-EB01/M4-BP02），交叉核对 `sim/result_summary.txt`。

## [0.4.17] 2026-08-01 清单 B 分诊 + rev 门禁应用——注册 M4-EB01/M4-BP02，登记 CW-006/007；orch 独立复核纠正"P0 merge-remeasure"前提错误

**背景**：用 Workflow 派 arch 把清单 B（Toggle 定向覆盖缺口）分诊成"(a) 扩充
既有场景/(b) 新 testplan 行"两类提案，再派独立 rev 门禁审核（REV-026，
CONDITIONAL PASS）。

**Done**
- **arch 分诊**：清单 B 六类（A-F）逐条给出 (a)/(b) 归属 + 具体构造思路；
  新增两条 testplan 行草案（M4-EB01：err_slv B 通道背压，非 merge-gated；
  M4-BP02：demux 锁定 FSM + ID 计数饱和，arch 原判 merge-gated）；
  `rst_ni` 运行中复位给出二选一建议（范围豁免 vs 造一个"空闲窗口热复位"
  新场景），不自行拍板；顺手核实 size[2] 转正前置（全配置 DATA_W=64）。
- **REV-026（独立 rev 实例）门禁**：CONDITIONAL PASS。批准 A-1/A-2/B-1/
  B-2/B-3/E-1（(a) 加固，无新判决维度）；C-1 需修改后批准（预测器扩展
  须做 KILL 注伤自证+期望锚 AXI4 非 RTL，enrichment 须显式列入 testplan
  行禁静默改激励）；C-2 批准附残余上报纪律（exotic ATOP 编码走
  SPEC_ISSUE，不现场解释）；M4-EB01 批准可直接派；M4-BP02 批准为条件
  注册；**独立裁决 rst_ni**——采纳范围豁免（CW-006），**明确驳回**
  "造一个空闲窗口热复位场景"这个方案（判定其为"toggle-theater"：构造性
  保证零在飞、不测试任何有意义的复位语义，纯粹为翻一个 toggle 位造场景，
  违反"目标即门"纪律）；size[2] 独立复核确认转正前置已解。
- **orch 独立复验并发现一处重要premise错误**：REV-026 把"P0 merge-
  remeasure"定为全体加固卡的强制前置（理由：怀疑 M2-TL01/TL02/M3-TL01/
  M4-AW01/M3-DE02/M2-CFG01 等场景的覆盖率数字未被合并进基线报告）。
  orch 独立核查 `sim/Makefile` `COV_DIR` 解析逻辑 + `sim/regress/
  regress.list` + `doc/testplan.md` 各行拓扑列，证实：**这个前提是错的**
  ——这 6 个场景全部是 baseline 拓扑（`COV_DIR` 默认走同一个
  `out/cov.vdb`），且全部在 `regress.list` 里，`make regress COV=1`
  会把它们的覆盖率累积合并进同一份数据库；`doc/evidence/v0.4.15/
  M4-toggle-bit-decomposition.md` 引用的 `urgReport_baseline` 报告本就是
  这次合并后的产物（`make cov TEST=m1_01_smoke_test` 只是借用一个基线
  拓扑成员的名字去解析已合并数据库的路径，不是"只测了 m1_01 一个"）。
  **结论：不需要另跑一次"合并重测"——现有残余数字已经是真实合并后数字**，
  `lock_aw/ar` FSM 与 `w_open[3:2]` 的缺口是确凿的、可以直接注册
  M4-BP02，不必等待一个实际上已经做过的步骤。
- **orch 应用**：`doc/testplan.md` 注册 M4-EB01（🔲）+ M4-BP02（🔲，
  行文本按 arch 草案 + 前提纠正说明）；`doc/coverage-waivers.md` 新增
  CW-006（`rst_ni` 运行中复位范围豁免）+ CW-007（`size[2]` 总线宽度上限
  位，转正）；`doc/review/REV-026.md` 落盘。
- `make check`/`make selftest`（61/61）复跑绿。

**Not done**
- M4-EB01/M4-BP02 均只是**注册**（🔲），尚未实现——下一步要派 DV 卡写场景。
- 清单 B 的 (a) 类加固（A-1/A-2/B-1/B-2/B-3/C-1/C-2/D-1/E-1/F-1）均未
  动手——已有明确构造思路，等待 DV 卡逐条落地。
- CW-006 平行的 spec §2.3 条款订正（P-REV026-1）未走——REV-026 明确这是
  独立门禁、非 CW-006 生效阻塞，可稍后处理。
- `spill_register` tie-off 的 Kind-A 论证仍待建档。

**Next**
- 派多个 DV 卡实现批准清单：M4-EB01/M4-BP02 两条新场景（相互独立，可
  并行）；M1-01 目标的多项 (a) 加固（A-1+A-2/B-1/C-1/D-1）因同时触及
  同一份激励代码，按"小闭环、非并行"顺序处理；M2-AT01（C-2）/M3-DE01
  （B-2+E-1）/M2-CFG01+M3-CFG02（B-3+F-1）等目标不同场景的加固可与
  M4-EB01/M4-BP02 并行。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口（testplan 新增
  2 行计入既有 feature-matrix gap 类别，非新增 gap 类型）。
- `make selftest`：61/61 OK。
- orch 独立核查 `sim/Makefile` COV_DIR 解析逻辑（`ifeq ($(TEST),
  upstream_sanity)` 分支外一律走默认 `out/cov.vdb`）+ `grep` 确认 6 个
  场景均在 `regress.list` + `doc/testplan.md` 拓扑列均为 baseline，
  纠正 REV-026 的 merge-premise 错误，证据充分、可复核。

## [0.4.16] 2026-08-01 逐位 Toggle 分解完成（Kind-B 前置兑现）——M4 阶段合法 Kind-B 豁免集为空集，转正 3 条 Kind-A（err_slv 恒定输出）

**背景**：REV-024 授权了 Kind-B（方法论受限、延后 M5）豁免路径，但明确"不
预先授予任何具体豁免，须先有逐信号/逐位 toggle 分解证据"。本周期用
Workflow 工具跑一套多 agent 流水线兑现这个前置：刷新覆盖率数据 → 4 模块
（axi_mux/axi_xbar/axi_demux_simple/axi_err_slv）并行逐位分解 → 每条
"载荷候选"由 3 个独立怀疑者做对抗性反驳投票 → 综合报告 → 独立 rev 复核
（REV-025）。

**Done**
- **覆盖率数据刷新**：核实并确认此前 sim/out 已因两次不带 COV=1 的
  make regress（KILL-0004 自证卡、M4 签核卡 falsification）变成非
  instrumented 空壳，干净重跑 make clean && make regress COV=1（26/26
  PASS）；基线聚合数字与 v0.4.9 逐位一致（LINE 80.84/COND 71.66/
  TOGGLE 47.87/FSM 7.14/BRANCH 82.99/ASSERT 78.62/GROUP 90.89，orch 独立
  核对 doc/evidence/v0.4.9/M4-coverage-baseline.md 表格逐位吻合），证明
  数据库确系真实 instrumented。
- **4 模块并行逐位分解**：每个模块独立读 urg Toggle Port Details 报告 +
  RTL 逐信号核实语义。关键发现——
  - `axi_mux` 是唯一被标"载荷候选"的模块：`mst_resp_i.r.data[63:0]`
    （散布 ~30/64 位未双向翻）。同模块 `mst_req_o.w.data[63:0]` 与
    `id[7:0]` 前缀+原ID 两段经核实**已 100% 覆盖、非缺口**，直接反驳
    REV-024 把 W/R.data 打包处理的假设。
  - `axi_xbar` 顶层核实"0 载荷位"——54 个 toggle 位全是窄控制/配置
    （clk/rst/test/en_default/default_mst_port），载荷 toggle 转移到子
    模块度量，无残余宽载荷缺口。
  - `axi_demux_simple` 写载荷 100% 覆盖，读载荷 87.5%（8 位残），主导
    缺口是属性字段（119/225 bin）与地址（67/225 bin），均非载荷类。
  - `axi_err_slv` 入侧写载荷 100% 覆盖；出侧发现三处**恒定常量输出**
    （`r.data=RespData`、`r.resp/b.resp=Resp`、`user` tie-off）——
    结构性 Kind-A，非 Kind-B。
- **对抗性核实**：唯一"载荷候选"（axi_mux R.data）被 3/3 独立怀疑者
  反驳——核心证据：TB `predict_beat_data` 返回 `{beat_a,beat_a}`（32-bit
  地址镜像拼成 64-bit），R.data 实际由读地址决定、并非不透明随机载荷；
  toggle 覆盖每位只需 all-0/all-1 两个饱和向量即可翻遍，根本不需要
  "扫大量互异取值"，故不满足 Kind-B 判据(2)"纯定向不经济"。
- **REV-025（独立 rev 实例）复核**：亲验 `axi_err_slv.sv`/
  `axi_xbar_unmuxed.sv`/`xbar_types_pkg.sv`/`mstport_agent.sv`/
  `seq_lib.sv` 具体行号，确认综合报告结论成立且比报告自述更强（R.data
  的判据(1)"纯载荷"本身也不成立，两判据双失）。Conditional pass，三条
  应用条件：仅新增 Kind-A A-1/A-2/A-3；size[2] 暂缓转正（须先确认 cfgA-E
  全部配置数据总线 ≤64 位）；订正报告一处内部措辞不一致。
- **orch 独立复验**（不采信自报）：亲读 `axi_err_slv.sv:23-27/145/
  188-198` 确认三个常量赋值点；亲读 `axi_xbar_unmuxed.sv:195-211` 确认
  两处例化点均未 override `RespData`；亲读 `xbar_types_pkg.sv:374-385`
  确认 `predict_beat_data` 返回值；亲读 `seq_lib.sv:32-35` 确认 wdata 用
  `$urandom` 随机填充；交叉核对覆盖率数字与 v0.4.9 基线逐位一致。
- **orch 应用**：`doc/coverage-waivers.md` 新增 CW-003/004/005（err_slv
  三条 Kind-A，引 REV-025）；Kind-B 模板行保留但注明"当前结论为空集"；
  待建档区新增 size[2] 条目（附暂缓理由）；`doc/bugs/BUG-0047.md` 标记
  逐位分解前置已完成、清单 B 已具体化到信号/位段级。产出
  `doc/evidence/v0.4.15/M4-toggle-bit-decomposition.md`（完整分解报告 +
  4 模块附录）+ `doc/review/REV-025.md`（仲裁记录）。
- `make check`/`make selftest`（61/61）复跑绿。

**Not done**
- **清单 B**（约 6 类具体信号/位段，已在证据文件里具体化到信号级）仍
  需逐条派 DV 定向覆盖卡——不因本次分解免除，反而更精确（如 axi_mux/
  demux 的 r.data 现在明确知道"定向饱和读 all-0→all-1 即可闭"，不再是
  笼统的"需补场景"）。
- size[2] Kind-A 候选转正前需要一次跨配置（cfgA-E）数据总线宽度确认。
- M4 仍未签核（REJECTED 判决未变，本轮工作是把"该走哪条路"这件事从
  猜测变成了有逐位证据支撑的确定结论——净结果是收窄了处置空间：没有
  Kind-B 可用，全部要么已覆盖、要么走 Kind-A、要么得真去补场景）。

**Next**
- 用户已完成本轮方法学张力优先项。下一步需用户决定：是逐条铺开清单 B
  的 DV 定向覆盖卡（现在已经有信号级精确指引），还是先处理 size[2] 的
  跨配置确认，或是先看其它待建档 Kind-A 项（`rst_ni`、
  `spill_register` tie-off）。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- 覆盖率数字交叉核对：本次刷新的基线聚合数字与 v0.4.9 报告逐位一致。
- REV-025 亲验的全部 RTL/TB 行号，orch 二次独立核对（见 Done 段），
  均准确无误。
- 本周期产生真实仿真（make regress COV=1，26/26），但非 testplan 场景
  评审——不涉及 evidence.py 登记，是覆盖率测量性质的证据文件。

## [0.4.15] 2026-08-01 BUG-0047 方法学张力仲裁应用——建 doc/coverage-waivers.md、milestone.md M4 追加 Kind-A/Kind-B 豁免框架，划界远比表面窄

**背景**：用户对 BUG-0047（M4"六类含 Toggle≥90%"vs"M5 前仅定向"的可行性
张力）给出方向性意见——"定向能做到的都做到，不强制要求全部 90%"。派
REV-024 独立仲裁，特别要求它自行核实用户意见的适用范围，不得被用来
夹带真正"没写场景"的缺口。

**Done**
- **REV-024（L3/opus，独立 rev 实例）**逐条独立划界（核对
  `M4-coverage-baseline.md` §6 九行 + 亲读 RTL 结构 `axi_xbar.sv:92`/
  `axi_mux.sv:33/39`）：**BUG-0047 的方法论受限面远比表面窄**——证据
  里 ~6 类"可达未测"缺口中，**仅宽 W/R.data 载荷位翻转属方法论受限**
  （当前只有 `axi_mux` Toggle 子集有明确结构依据：承载 64-bit
  `w_chan_t`/`r_chan_t`）；`addr_decode_dync`（地址/rule 多样性不足，
  非载荷）、`axi_xbar` 的 `default_mst_port_i`（6×3-bit 窄索引，非
  载荷）、各 Cond/Branch/Assert、握手背压、实例级颗粒度**均不属，
  维持需补场景**——这正是防止用户方向性意见被夹带滥用的关键划界。
  **顺带纠正一处记录失实**：BUG-0047 原表述"位翻转组合数随总线宽度
  指数增长/组合爆炸"是错误框架——Toggle 覆盖逐位线性（2×width），
  真正原因是"定向用例只用少数固定取值，多数载荷位未双向翻转"；错误
  框架会把它推向永久结构豁免，正确框架才支撑"临时、可 M5 解锁"处置。
  **处置**：不扩展 pinned spec §0 三态（测量规则与豁免种类正交，更
  外科、免重 pin）；改为 `doc/milestone.md` M4 追加子项 + 新建
  `doc/coverage-waivers.md`，引入 Kind-A（结构/环境不可达，永久，
  给可证伪不可达论证）/ Kind-B（方法论受限延后 M5，临时，可证伪解锁=
  M5 约束随机重测后若仍<90%才议）双类豁免框架。**本裁决不预先授予
  任何 Kind-B 豁免**——须先有逐信号/逐位 toggle 分解证据；**M4 签核
  REJECTED 判决因此整体仍然成立**，本裁决只给出合法出口框架、不清空
  残余。taxonomy 终判 SPEC_CHANGED（治理文档订正，非 pinned-spec 行为
  条款改动）。
- **orch 应用裁决**（独立复核）：`doc/milestone.md` M4 节追加 Kind-A/
  Kind-B 豁免框架子项；新建 `doc/coverage-waivers.md`（CW-001
  atop_filter FSM 环境约束 + CW-002 test_i scan 两条 Kind-A 已就绪，
  Kind-B 留模板待逐位分解卡产出证据后填）；`doc/bugs.md` BUG-0047 行
  `OPEN → SPEC_CHANGED`（**未跑 `docs.py --pin-spec`**——本条不改
  `doc/spec.md` 正文，重 pin 会是误操作，已用 `git diff doc/spec.md
  doc/spec.sha256` 确认二者确实未变）；`doc/bugs/BUG-0047.md` 订正
  `## rca` 里"组合爆炸"表述、新增 `## arbitration` 段、收紧
  `## regression_guard`（Kind-B 登记前置 = 逐位分解证据，且明确点名
  哪些条目不得被误记为 Kind-B）。
- `make check`/`make selftest`（61/61）复跑绿。

**Not done**
- Kind-B 豁免尚无任何一条正式登记——需要先派一张**逐位 toggle 分解卡**
  （`axi_mux`/`axi_xbar`/`axi_demux_simple`/`axi_err_slv`），把"宽载荷
  位"与"定向可达位"分开，才能据此填 `doc/coverage-waivers.md` 的
  Kind-B 行。
- "清单 B"（`addr_decode_dync` 等"可达未测"缺口）仍需逐条派 DV 定向
  覆盖卡，不因本次裁决免除。
- M4 仍未签核（REJECTED 判决未被本次裁决推翻，只是收窄了残余、给出
  了框架）。

**Next**
- 用户已表态优先处理方法学张力，本轮已完成。下一步需用户决定：是先
  派逐位 toggle 分解卡（Kind-B 路径的前置），还是先铺开"清单 B"的
  DV 定向覆盖卡，或是先处理其它 Kind-A 候选项（`axi_err_slv` 恒定
  应答位、`rst_ni`、`spill_register` tie-off）的豁免论证。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- `git diff doc/spec.md doc/spec.sha256`：均无输出，确认未误改/误重 pin。
- 本周期无仿真运行（纯治理文档订正+登记），无新增 sim evidence。

## [0.4.14] 2026-08-01 M4 完整签核卡：REJECTED——四条机器门禁全绿不等于签核，覆盖率定义性出口条件未满足；新登记 BUG-0047（判据可行性张力）

**背景**：0.4.9-0.4.13 五个周期把 `make check MILESTONE=4` 的四条机器
门禁逐条转绿（场景 ✅、regress evidence、bug 终态、KILL 覆盖）。本周期
派出全套 rev 签核 rubric 卡，本以为是收尾的最后一步，结果卡本身给出了
**REJECTED** 判决——这是本轮 M4 收尾里最重要的一次纠偏：机器门禁全绿
从未等于"可以签核"，签核判的是"证据是否支撑风险已收敛"。

**Done**
- **M4 完整签核卡（L3/opus，fresh instance，与本轮全部 M4 相关卡作者
  均不共享）**产出 `doc/evidence/v0.4.13/signoff-M4.md`。逐项：
  - **机器条件（rubric #1-4）**：亲跑确认全绿，但明确指出机器脚本
    `scripts/docs.py` **不检查覆盖率百分比**——四条绿只覆盖"场景/
    证据/bug 状态/KILL"，不覆盖 M4 的定义性出口条件本身。
  - **rubric #5**（coverage closure≠risk closure）：挑 3 个良好命中
    bin 逐一核实确系预期场景命中（含 `axi_mux` 仲裁重试路径的
    "模块级 100% 实为跨 8 实例并集、实际仅 1/8 端口真转绿"这一颗粒度
    警示）；重读 atop_filter 环境约束不可达论证并**活体证伪**佐证
    （注入 atop 到未命中地址后 FSM 确实 engage）。
  - **rubric #6**（guard 消费+证伪）：实地证伪 BUG-0032 guard——注入
    `atop=6'h30` 到 M3-DE01 未命中序列，`SB_ATOP_DECODE` 6 端口报红；
    恢复后 `git diff` 净。
  - **rubric #7/#8**（spec debt / accepted debt）：BUG-0044/0045/0046
    均确认有可证伪解锁条件、非软承诺。
  - **rubric #9**（chain audit）：逐类给处置意见。
  - **REV-017 条件 3 正式兑现**：atop_filter FSM 书面豁免（逐弧列出
    未覆盖状态/迁移，行号对当前 vendor 树逐条复核——orch 独立复验
    `grep vendor/axi/src/axi_atop_filter.sv` 确认 BLOCK_AW:151/
    HOLD_B:161/INJECT_B:163/ABSORB_W:167/WAIT_R:228/R_HOLD:275/
    INJECT_R:281 全部准确）+ BUG-0032 guard 机械抽查（grep + 计数=0
    两种形态均满足）。
  - **核心否决理由**：M4-coverage-baseline.md §6 的 ~9 类残余缺口里
    只有 2 类得到合法处置（atop_filter 环境约束豁免 + addr_decode/
    axi_demux 结构性 N/A），其余 ~6 类（`axi_demux_simple`/
    `addr_decode_dync`/`axi_mux` Toggle/`axi_err_slv`/`spill_register`
    等）是"可达但未测"——按 REV-016 §9，豁免须给可证伪的不可达论证，
    这些是"没测"非"测不到"，**不可合法豁免，必须补定向场景**。
  - **附带发现并建议登记的方法学张力**：M4 出口条件"六类含 Toggle
    ≥90%"与项目"M5 前仅定向、随机不得替代 M4 定向关闭"纪律叠加，对
    宽 AXI 总线的 Toggle bin 产生可行性冲突——两条规则各自无误，组合
    时无解，需 rev/arch 后续裁决扩展豁免框架或重议判据口径。
- **orch 独立复验**（不采信卡内自报）：`git status`/`git diff` 确认
  falsification 改动已完全恢复；`make check MILESTONE=4` 复跑确认四条
  仍绿、签核文件条目转"yes"；`grep vendor/axi/src/axi_atop_filter.sv`
  逐行核对 FSM 豁免的 7 处行号（100% 命中）；`sed` 核对 BUG-0032
  guard 的注入点（`tb/seq_lib.sv:962` `atop='0`）与检测点
  （`tb/scoreboard_refmodel.sv:469-472` `SB_ATOP_DECODE`）均如实存在。
- **orch 按无条件登记纪律登记 BUG-0047**（OPEN，spec，SPEC_ISSUE 候选，
  非本条自身触发失败——是签核卡的附带发现）：M4 出口条件与"M5 前仅
  定向"纪律的可行性张力，详见 `doc/bugs/BUG-0047.md`。
- `make check`/`make selftest`（61/61）复跑绿。**`doc/milestone.md` M4
  状态维持 🔲，不转 ✅**（rev 明确裁决，未由 orch 越权改动）。

**Not done**
- M4 仍未签核。REJECTED verdict 给出的后续方向（signoff 记录已列，
  非本周期落地）：
  1. DV 定向覆盖卡（针对 ~6 类"可达但未测"缺口，逐（模块,类型）补
     spec 引用+可证伪具名场景）；
  2. rev 覆盖率豁免卡（先建 `doc/coverage-waivers.md`，为 `rst_ni`/
     `test_i` scan/AW valid-but-not-ready 断言类等真正需要论证的项
     出具可证伪不可达论证）；
  3. **BUG-0047 方法学张力裁决**（arch/rev，二选一：成本豁免扩展 /
     重议 Toggle 判据口径）——这条建议先走，因为它决定其余 Toggle
     类缺口该走"补场景"还是"豁免"这条路；
  4. feature-matrix 补 4 行（M4-RC01/AW01/OV01/FT01，chain audit
     既有 gap）。
- 上述四项工作量不小，且互相有依赖（尤其 3 影响 1 的范围），需要用户
  确认优先级/是否现在就铺开，不是一次性能收尾的小任务。

**Next**
- 向用户汇报 REJECTED 判决全貌，请用户决定：先处理 BUG-0047 方法学
  张力裁决，还是先铺开 DV 定向覆盖卡补场景，还是先建
  `doc/coverage-waivers.md` 做豁免分诊，或调整 M4 出口条件本身的
  优先级安排。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- `make check MILESTONE=4`：4/4 机器门禁仍 PASS（signoff 文件条目
  转"yes"，但 verdict 本身是 REJECTED——机器门禁与签核判断是两回事，
  本周期最大的一次认知纠偏）。
- 独立复验详见 Done 段——FSM 行号逐条 grep 核对、guard 注入/检测点
  逐行核对、falsification 恢复用 git diff 核实为空。

## [0.4.13] 2026-08-01 M4 收尾第三项完成：BUG-0046 仲裁应用——`make check MILESTONE=4` 四条机器门禁全绿

**Done**
- **REV-023（独立 rev 实例）仲裁 BUG-0046**：补核许可来源
  `vendor/axi/doc/axi_xbar.md`（L26"must be less than or **equal to**"，
  非严格 `<=`）——**推翻**本条原登记的框架（当初误判"spec 蒸馏遗漏/spec
  允许 RTL 会炸"）。真相：`doc/spec.md` §3.2 条 2 的 `<=` 是这条权威文档
  的**忠实、正确蒸馏**，spec 侧无误；真实矛盾是**上游内部** doc-vs-RTL
  不一致（`axi_xbar.md` `<=` vs common_cells `addr_decode_dync.sv`
  `check_start` 断言 `<`，且该文件自身头注释 L26/L36-38 亦互相矛盾）。
  taxonomy 重框为该上游矛盾的 SPEC_ISSUE 变体，处置 **ACCEPTED@M5**
  （到期锚点与姐妹条 BUG-0045 对齐）——**独立否决"现在把 spec 收紧为
  `<`"**：该路径预设的"文字性错误、成本极低"前提经核实为假，收紧只会
  让 spec 偏离权威文档反向对齐 RTL（spec-from-RTL 红线）。给出可证伪
  解锁条件（任何场景构造 `start==end` 即作废）+ M5 到期二选一动作
  （DV 环境约束 + spec 注记两件套 / 具体论证转 WONTFIX）。
- **orch 应用裁决**（独立复核，未盲从）：`doc/bugs.md` BUG-0046 行
  `OPEN → ACCEPTED@M5`，`suspect` 由 `spec` 订正为 `upstream`（反映
  "spec 无误、根因上游不一致"），`summary`/`root_cause` 按 REV-023 的
  订正框架重写（不再说"spec 允许 RTL 会炸"），`verify_evidence` 点名
  REV-023；`doc/bugs/BUG-0046.md` 顶部加订正提示 + 重写 `## symptom`/
  `## taxonomy`/`## rca`（纠正失实归因）+ 新增 `## arbitration`（含
  addr_decode_dync 头注释内部自相矛盾的上游 issue 线索，并入本条不单开
  行）+ `## regression_guard` 补到期锚点（M5 + 点名 REV-023）。
- `make check`/`make selftest`（61/61）复跑绿。
- **`make check MILESTONE=4` 四条机器门禁全部转 PASS**：1. 全部 M4
  场景 ✅；2. regress evidence 已登记；3. 全部 bug 终态/ACCEPTED-
  unexpired；4. KILL 覆盖已登记（KILL-0004）。仅剩签核文件本身
  （`signoff-M4*.md` "not yet"）+ rev 人工 rubric（第 5-9 条）+
  REV-017 条件 3 未走。

**Not done**
- REV-017 条件 3（atop_filter FSM 书面豁免 + BUG-0032 guard 机械抽查）
  仍未走——按 REV-017 原文，此条件挂在"M4 签核时"一并出具，非独立前置卡。
- 签核文件 `signoff-M4*.md` 未生成，rev 人工 rubric（`workflow/review.md`
  第 5-9 条：coverage closure 抽查、guards 证伪、SPEC_ISSUE 清单核对、
  ACCEPTED 债务可证伪性、chain audit 归档）未走。

**Next**
- 派完整 M4 签核卡（L3/opus/rev，fresh instance）：机器条件（已全绿）
  + rev 人工 rubric 七问/五条抽查 + REV-017 条件 3（FSM 书面豁免 +
  BUG-0032 guard 抽查）+ 产出 `doc/evidence/v0.4.*/signoff-M4.md`。
  **M4 签核本身不转版本**（v1.0.0 转段挂 M5 签核后，见 `doc/milestone.md`）。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- `make check MILESTONE=4`：**4/4 机器门禁 PASS**（本周期完成条件 3
  最后一项）。
- 本周期无仿真运行（纯裁决应用），无新增 evidence/testplan 状态变化。

## [0.4.12] 2026-08-01 M4 收尾第三项（下半）：KILL-0004 登记（M4-OV01 tie-break 自证），M4 机器门禁 4 条中 3 条转 PASS

**Done**
- **DV 卡（L1/sonnet，fresh instance）**完成 M4-OV01 重叠 rule tie-break
  参考模型（`tb/xbar_types_pkg.sv` `decode_mst_port`）的注伤自证：临时给
  扫描全表的 `for` 循环加一行 `break;`，把 tie-break 从"扫描全表、后命中
  覆盖前命中（SPEC-3.1.3 高位置胜出）"改成"取第一个命中即停"。重跑
  `make run TEST=m4_ov01_overlap_test SEED=1`：注伤后 `route: match=12
  mismatch=48`、`UVM_ERROR:49`（DUT 仍正确路由到 port=7，即高位置
  `OV1_HIGH_RULE` 胜出；被注伤的参考模型错误期望 port=0，证明是 TB 侧
  故障非 DUT 问题）；恢复后同 SEED 复跑 `route: match=60 mismatch=0`、
  `UVM_ERROR:0`；全量回归 `make regress` 26/26 PASS。
- **orch 独立复验**：`git status`/`git diff tb/xbar_types_pkg.sv` 确认
  恢复后无残留改动（逐字节一致）；`sim/result_summary.txt` 交叉核对
  26 PASS/0 FAIL 与 `m4_ov01_overlap_test PASS` 一致；`make check`/
  `make selftest`（61/61）复跑绿。
- **orch 登记 KILL-0004**（`doc/bugs.md`，status=KILL，summary 含"M4"
  裸词满足机器门禁扫描）：完整转录注伤/恢复的具体数字、样本报文、重放
  命令，`fix_commit` 列填 `-`（自证记录非缺陷，无 fix 对象）。首次登记时
  误将 KILL-0004 行与紧随的 BUG-0046 行合并到同一物理行（Edit 工具替换
  时遗漏行边界），当场发现并修正——`grep`/`awk` 核实两行独立、8 列结构
  完整后 `make check` 复跑绿。
- `make check MILESTONE=4` 复跑：4 条机器门禁中 **3 条转 PASS**
  （1. 全部 M4 场景 ✅；2. regress evidence 已登记；4. KILL 覆盖已登记）；
  仅剩条件 3（`BUG-0046` 仍 OPEN，REV-023 仲裁中，见 Not done）。

**Not done**
- **条件 3**：`BUG-0046` 仍 OPEN，REV-023（独立 rev 实例）仲裁中，未交付。
- REV-017 条件 3、签核文件仍未动——待条件 3 转 PASS 后再派完整签核卡。

**Next**
1. REV-023 交付后，orch 应用裁决到 `doc/bugs.md`（预期 BUG-0046 转终态
   或 ACCEPTED，视裁决而定）。
2. `make check MILESTONE=4` 四条机器门禁全绿后，派完整 M4 签核卡（L3/opus/
   rev）：机器条件 + rev 人工 rubric + REV-017 条件 3（FSM 书面豁免 +
   BUG-0032 guard 抽查）+ `doc/evidence/v0.4.*/signoff-M4.md`。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- `make check MILESTONE=4`：条件 1/2/4 PASS（较上次 1/2 PASS 有进展），
  条件 3 仍 FAIL（阻塞项 = BUG-0046，仲裁中）。
- 本周期无新 evidence 文件；`doc/bugs.md` 新增 1 行（KILL-0004）。

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

