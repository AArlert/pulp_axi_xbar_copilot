# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

