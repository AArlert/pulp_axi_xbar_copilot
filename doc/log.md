# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

