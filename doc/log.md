# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

