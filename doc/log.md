# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

