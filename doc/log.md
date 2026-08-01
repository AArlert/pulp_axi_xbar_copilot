# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

