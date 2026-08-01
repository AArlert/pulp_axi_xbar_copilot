# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

