# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

