# M6 覆盖率缺口分诊（步 1）

**version**: 0.6.3  
**date**: 2026-08-04  
**input**: `doc/evidence/v0.6.1/M6-BL01-coverage-baseline.md`（30/132 cells <90%）  
**method**: urg modinfo.txt 逐格 bin 级别核查 + RTL 例化点/tie-off 交叉验证

## 分诊总表

30 格按处置路径分五组。每格注明：原始 %、现有 CW 覆盖、新 CW 候选、DV 需求、
waiver 排除后可达 %（CW+DV 全闭合后的期望值）。

### A. 纯 Kind-A 全覆盖——已关闭，无需动作（8 格）

| # | (模块, 类型) | raw % | CW | 说明 |
|---|---|---|---|---|
| 1 | `axi_atop_filter` Line | 48.18 | CW-001 | err_slv 内 6 例全死（§4 clause 7 环境约束） |
| 2 | `axi_atop_filter` Cond | 41.94 | CW-001 | 同上 |
| 3 | `axi_atop_filter` Toggle | 65.34 | CW-001 | 同上 |
| 4 | `axi_atop_filter` FSM | 14.29 | CW-001 | 同上 |
| 5 | `axi_atop_filter` Branch | 41.30 | CW-001 | 同上 |
| 6 | `addr_decode_dync` Branch | 83.33 | CW-008 | 唯一未覆盖 bin = config_ongoing tie-off |
| 7 | `stream_register` Line | 75.00 | CW-014 | 3 行全属 clr_i tie-off + push-gate 环境约束 |
| 8 | `stream_register` Branch | 50.00 | CW-014 | 4 支全属同上两根因 |

### B. bin-scoped Kind-A 全覆盖——已关闭（3 格）

| # | (模块, 类型) | raw % | CW | 说明 |
|---|---|---|---|---|
| 9 | `rr_arb_tree` Line | 80.00 | CW-010 | 3 行全在 `if(flush_i)` 块内，flush_i≡0 |
| 10 | `spill_register_flushable` Cond | 82.49 | CW-010 | 4 个未覆盖条件全为 flush_i=1 场景 |
| 11 | `spill_register_flushable` Assert | 0.00 | CW-010 | `flush_valid` 断言 vacuous（flush_i≡0） |

### C. Kind-A 使 raw % 永久 <90%——waiver 即解决方案（4 格）

这些格即便 DV 全闭合仍因结构死位无法达 90% raw。已有 CW 覆盖结构死因，
DV 闭合可达部分提升 raw % 但非必须跨越 90% 门槛——格的解决方案是 waiver 本身。

| # | (模块, 类型) | raw % | CW | DV 项 | 即便 DV 全闭 raw 上界 |
|---|---|---|---|---|---|
| 12 | `lzc` Toggle | 42.59 | CW-011 | DV-F（仲裁模式） | <90%（常量 LUT+padding 占主体） |
| 13 | `counter` Toggle | 43.48 | CW-013 | DV-A/G（r_counter 高位） | <90%（clear/load/d tie-off + overflow） |
| 14 | `delta_counter` Toggle | 41.20 | CW-013 | DV-G（in_flight 高位） | <90%（同上 tie-off） |
| 15 | `axi_id_prepend` Toggle | 78.26 | CW-012 | DV-C（b_readies） | ~87%（pre_id_i 常量 6 bit-dir） |

### D. CW + DV 混合——需 DV 场景（部分需新 CW）（4 格）

| # | (模块, 类型) | raw % | 现有 CW | 新 CW 候选 | DV 项 | CW 排除后可达 % |
|---|---|---|---|---|---|---|
| 16 | `axi_demux_simple` Cond | 82.76 | CW-009 (1 bin) | — | **DV-E**：AR ID 满 + ATOP R_RESP (4 bins) | 85.71% → DV 后 100% |
| 17 | `axi_err_slv` Toggle | 70.37 | CW-002..007 (291 bits) | **CW-015** `err_req.aw.atop[5:0]` 12 bit (atop_filter:252 清零) | **DV-A/B/J**：长 burst + 低 addr + size 变化 | 89.71% → CW-015 后 90.74% |
| 18 | `axi_mux` Toggle | 89.62 | CW-002/006/007 (11 bits) | — | DV-C/D（backpressure + resp/user） | **90.32%**（已 >90%，DV 可选） |
| 19 | `stream_register` Toggle | 22.00 | CW-014 (31 bits) | — | **DV-A**：len≥16 译码未命中写 burst (8 bits) | 57.89% → DV 后 100% |

**关键**：#17 `axi_err_slv` Toggle 需 **CW-015**（新）才能过 90% 门槛。

### E. UNOWNED——需新 CW + DV（11 格）

#### E1. `axi_demux_id_counters`（3 格）

| # | 类型 | raw % | 新 CW 候选 | DV 项 | 预期 |
|---|---|---|---|---|---|
| 20 | Line | 73.91 | **CW-017** AW inject tie-off (case 3'b110/3'b111 在 AW 实例结构死) | **DV-F**：AR 实例同周期 AR+ATOP 握手同 ID | CW+DV 后模块级 Line 100% |
| 21 | Toggle | 74.06 | **CW-017** cnt_delta[3:2] 死位 + overflow 实际不可达 + **CW-006ext** rst_ni | **DV-F/G**：ID 饱和 + in_flight 高位 | 需 CW 核算；DV 闭合可达部分 |
| 22 | Branch | 79.49 | **CW-017** 同 Line (16 支全在 case 3'b110/3'b111) | **DV-F**：同 Line | CW+DV 后模块级 Branch 100% |

**CW-017 范围**：`axi_demux_id_counters` Line+Branch+Toggle bin-scoped。根因：
- AW 实例 `inject_i` 硬接 `1'b0`（`axi_demux_simple.sv:222`），case 3'b110/3'b111 在 AW 实例结构死
- `cnt_delta[3:2]` 从未赋 ≥4 值（只用 0/1/2），4 bit `cnt_t` 的高 2 位结构死
- `overflow` 因 cnt_full 在 count=15 时 stall（delta=1），仅 delta=2（case 3'b110）+count=14 可触发，实际不可达

#### E2. `fifo_v3`（3 格）

| # | 类型 | raw % | 新 CW 候选 | DV 项 | 预期 |
|---|---|---|---|---|---|
| 23 | Cond | 80.19 | **CW-016** 全 5 bin 结构死 | — | CW 后 100% 可达（0 个可达未覆盖 bin） |
| 24 | Toggle | 82.09 | **CW-018** flush_i+testmode_i+rst_ni+status_cnt[3] 死位 | **DV-A/H**：r_fifo len 高位 + FIFO mem 多样 ID | CW+DV 后 >90% |
| 25 | Branch | 78.43 | **CW-018** flush(3)+FALL_THROUGH=0 死码(4)=7 bin | **DV-I**：FIFO 指针回卷（fill to cap） | CW+DV 后 >90% |

**CW-016 范围**：`fifo_v3` Cond。全 5 个未覆盖 bin 根因：
- 上游 push/pop 门控（`push_i & ~full_o` / `pop_i & ~empty_o`）使 push-when-full、pop-when-empty 结构不可达（3 bin）
- FALL_THROUGH=1 下 `empty_o = (cnt==0) & ~(1 & push_i)` 使 push=1 && empty=1 为逻辑矛盾（1 bin）
- 交叉重复（1 bin 同属上述两根因）

**CW-018 范围**：`fifo_v3` Branch+Toggle bin-scoped。根因：
- `flush_i` tie-off `1'b0`（同 CW-010 根因，CW-010 明确排除 fifo_v3 Cond/Toggle）
- `testmode_i` 经 `test_i` tie-off `1'b0`（`tb_top.sv:137`）
- `rst_ni` 1→0 无热复位语义（同 CW-006 根因）
- `status_cnt_q[3]` DEPTH=6 < 2³=8，MSB 结构死
- FALL_THROUGH=0 死码：`if(FALL_THROUGH && ...)` 分支在 FALL_THROUGH=0 实例恒假

#### E3. `rr_arb_tree` Toggle（1 格）

| # | 类型 | raw % | 新 CW 候选 | DV 项 | 预期 |
|---|---|---|---|---|---|
| 26 | Toggle | 77.63 | **CW-019** rr_i[2:0] ExtPrio=0 死 + tree geometry 死位 + **CW-010ext** flush_i + **CW-006ext** rst_ni + **CW-007ext** size[2] | **DV-A**：len[7:4], addr[2:0] | 需 CW 核算 |

**CW-019 范围**：`rr_arb_tree` Toggle bin-scoped。根因：
- `rr_i[2:0]`：ExtPrio=0 使外部优先级输入未使用、tie-off `'0`（6 bit-dir）
- `gen_arbiter.req_nodes` 超范围节点：NumIn 非 2 的幂 → `g_out_of_range` 硬接 `1'b0`
- `gen_arbiter.index_nodes` 高位：窄树层级索引位结构未用
- `gen_arbiter.gen_int_rr.gen_fair_arb.upper_mask[0]`：unsigned `(0>rr_q)` 恒假
- `gen_arbiter.gen_int_rr.gen_fair_arb.lower_empty`：端口未连接

#### E4. spill_register 族 + axi_cut/multicut（5 格）

| # | (模块, 类型) | raw % | 新 CW 候选 | DV 项 | 预期 |
|---|---|---|---|---|---|
| 27 | `axi_cut` Toggle | 89.62 | **CW-007ext** size[2] + **CW-006ext** rst_ni | **DV-A/B/D/J** | CW+DV 后 >90% |
| 28 | `axi_multicut` Toggle | 89.62 | 同 axi_cut（纯 wrapper） | 同 axi_cut | CW+DV 后 >90% |
| 29 | `spill_register` Toggle | 88.77 | **CW-006ext** rst_ni + **CW-007ext** size[2] | **DV-A/B/D/J** | CW+DV 后 >90% |
| 30 | `spill_register_flushable` Toggle | 79.95 | **CW-010** flush_i (已有，bin-scoped) + **CW-006ext** rst_ni + **CW-007ext** size[2] | **DV-A/B/D/J** | CW+DV 后 >90% |

这 4 格的可达缺口根因一致——AXI 载荷信号透传过流水寄存器，缺口来自上游
激励多样性不足（len/addr/size/resp/user）而非模块自身结构。DV-A/B/D/J 闭合
上游多样性后自然收敛。

## 新 CW 候选汇总（待 rev 签核）

每条附**判据摘要**（RTL 行号 + urg 证据），rev 可据此快速抽查而不必重翻 urg 原文。

### CW-015：`axi_err_slv` Toggle bin-scoped — `err_req.aw.atop[5:0]` 12 bit-dir

- **根因**：`axi_atop_filter.sv:252` `mst_req_o.aw.atop = '0`——atop_filter 在
  master 侧硬清零 atop 字段，`axi_err_slv` 收到的 `err_req.aw.atop` 恒零
- **RTL 证据**：`vendor/axi/src/axi_atop_filter.sv:252`（FEEDTHROUGH 状态赋值
  `mst_req_o.aw.atop = '0`）；6 例 atop_filter 全在 err_slv 内
  （`axi_err_slv.sv:45-58` generate block）
- **urg 证据**：`modinfo.txt` L295059+ `axi_err_slv` Toggle Port/Signal Details：
  `err_req.aw.atop[5:0]` 全 6 位 × 2 方向 = 12 bit-dir 均 `No/No/No`
- **与 CW-001 关系**：同根因（CW-001 覆盖 atop_filter 自身六类，本条覆盖其
  master 侧输出在 err_slv 模块页的投影）
- **门槛影响**：排除后 `axi_err_slv` Toggle 可达 % 从 89.71% 升至 90.74%（跨
  90% 门槛的关键项）

### CW-016：`fifo_v3` Cond — 全 5 bin 结构不可达

- **根因**：上游 push/pop 门控使 push-when-full、pop-when-empty 不可达；
  FALL_THROUGH=1 下 empty_o 组合定义使 push=1 && empty=1 逻辑矛盾
- **RTL 证据**：
  - `axi_err_slv.sv:97` `w_fifo_push = err_req.aw_valid & ~w_fifo_full`（push 门控）
  - `axi_err_slv.sv:130` `b_fifo_push = w_fifo_pop & (w_cnt == '0)`（push 门控）
  - `axi_err_slv.sv:172` `r_fifo_push = err_req.ar_valid & ~r_fifo_full`（push 门控）
  - `axi_mux.sv:272/324/417` 三处 fifo push 均 AND `~full`
  - `vendor/common_cells/src/fifo_v3.sv:58` FALL_THROUGH 下
    `empty_o = (status_cnt_q == 0) & ~(FALL_THROUGH & push_i)` 使 push_i=1 →
    empty_o=0
- **urg 证据**：`modinfo.txt` L180753+ `fifo_v3` Cond 表：
  - FALL_THROUGH=1 (DEPTH=4)：bin A1 L73 `1,0` (push+full) / A2 L101 `1,1,0,1`
    (push+pop+full) / A3 L101 `1,1,1,0` (push+pop+empty) = 3 bin Not Covered
  - FALL_THROUGH=0：bin B1 L101 `1,1,0,1` / B2 L101 `1,1,1,0` = 2 bin Not Covered
  - 模块级合并：5 bin 全 Not Covered

### CW-017：`axi_demux_id_counters` Line+Branch+Toggle bin-scoped

- **根因 1**：AW 实例 `inject_i` tie-off `1'b0`
  - RTL：`axi_demux_simple.sv:221-222` `.inject_i(1'b0), .inject_axi_id_i('0)` —— AW
    id counter 的 inject 硬接零（对比 AR 实例 `:245` `.inject_i(atop_inject)` 为活信号）
  - 影响：`axi_demux_id_counters.sv:563` case 语句中 `3'b110`（push+inject）和
    `3'b111`（push+inject+pop）在 AW 实例结构死
  - urg：`modinfo.txt` L164912+ Line 表 L582-584 (case 3'b110) × 8 counters = 24 行 +
    L587-589 (case 3'b111) × 8 counters = 24 行 = 48 行全 Not Covered
  - 注意：模块级合并——AR 实例覆盖即可翻绿（DV-F 目标）

- **根因 2**：`cnt_delta[3:2]` 死位
  - RTL：`axi_demux_id_counters.sv:563` case 语句只赋值 `cnt_delta` ∈ {0,1,2}，
    最大值 2=4'b0010，bit[3:2] 从未赋非零——`cnt_t` 为 `logic[3:0]`
    （`CounterWidth=idx_width(MaxMstTrans=10)=4`），高 2 位结构死
  - urg：Toggle Details `gen_counters[0..7].cnt_delta[3:1]` = 8×3×2 = 48 bit-dir
    Not Covered（其中 [1] 在 case 3'b110 delta=2 时可达，[3:2] 结构死）

- **根因 3**：`overflow` 实际不可达
  - RTL：`delta_counter` overflow 需 in_flight + delta 发生无符号溢出；`cnt_full`
    在 in_flight=15 时 stall（delta=1 路径），唯一溢出路径 = delta=2（case 3'b110）+
    in_flight=14——依赖 case 3'b110 先被覆盖且恰在 in_flight=14 命中
  - urg：`gen_counters[0..7].overflow` 8×2 = 16 bit-dir 全 Not Covered

### CW-018：`fifo_v3` Branch+Toggle bin-scoped

- **根因 1**：`flush_i` tie-off（同 CW-010 根因，CW-010 明确排除 fifo_v3 Cond/Toggle）
  - RTL：`axi_err_slv.sv:97/130/172` `.flush_i(1'b0)` × 3 + `axi_mux.sv:272/324/417`
    `.flush_i(1'b0)` × 3 = 全部 6 例化点
  - urg Branch：IF-117 `(0,1)` = flush_i taken，3 groups × 1 bin = 3 bin Not Covered
  - urg Toggle：`flush_i` 2 bit-dir Not Covered（各实例）

- **根因 2**：`testmode_i` tie-off
  - RTL：`tb_top.sv:137` `.test_i(1'b0)`，经 `axi_xbar.sv:74` 直连全子模块
  - urg Toggle：`testmode_i` 2 bit-dir Not Covered

- **根因 3**：`rst_ni` 1→0（同 CW-006 根因）
  - urg Toggle：`rst_ni` 1→0 方向 1 bit-dir Not Covered

- **根因 4**：`status_cnt_q[3]` MSB 死位（DEPTH=6 mux w_fifo）
  - RTL：`fifo_v3.sv` DEPTH=6, ADDR_DEPTH=3, status_cnt 为 4 位 `[3:0]`，
    max fill=6=4'b0110，bit[3] 需 ≥8 不可达
  - urg Toggle：`status_cnt_n[3]`/`status_cnt_q[3]` 4 bit-dir Not Covered（8 个 mux 实例）

- **根因 5**：FALL_THROUGH=0 死码
  - RTL：`fifo_v3.sv:105` `if (FALL_THROUGH && ...)` 分支在 FALL_THROUGH=0 实例恒假
  - urg Branch：IF-105 `(1,1)` 和 `(1,0)` = 4 bin Not Covered（仅 FALL_THROUGH=0 groups）

### CW-019：`rr_arb_tree` Toggle bin-scoped

- **根因 1**：`rr_i[2:0]` ExtPrio=0 死输入
  - RTL：`rr_arb_tree.sv:43` `parameter int unsigned ExtPrio = 0`——全部闭包内实例
    ExtPrio=0，`rr_i` 输入未使用（`:164` `if (ExtPrio)` 分支恒假）
  - 例化点：`axi_demux_simple.sv:273/391`（i_aw/i_ar_arbiter）、`axi_mux.sv:272/324/417`
    （i_b/i_r_mux）——全部 `.rr_i('0)` 或未接
  - urg Toggle：`rr_i[2:0]` 6 bit-dir Not Covered（NumIn=6 实例）

- **根因 2**：tree geometry 死位（NumIn 非 2 的幂）
  - RTL：`rr_arb_tree.sv:86-89` `gen_out_of_range` 把 `2*l >= NumIn-1` 的树节点
    `req_nodes` / `index_nodes` 硬接 `1'b0`/`'0`
  - NumIn=6：`req_nodes[6]`（l=3, 2*3=6 ≥ 5）硬接 0，`index_nodes` 高位多条死
  - NumIn=9：同构 padding 更多
  - urg Toggle：`gen_arbiter.req_nodes[6]`、`gen_levels[2].gen_level[3].sel`、
    `index_nodes` 高位——各 Not Covered

- **根因 3**：unsigned 比较恒真/恒假
  - RTL：`rr_arb_tree.sv:198-199` `(0 > gen_arbiter.rr_q)` 对 unsigned rr_q 恒假，
    `(0 <= gen_arbiter.rr_q)` 恒真
  - urg Toggle：`upper_mask[0]` 恒 0（恒假分支输出），`lower_empty` 端口未连接

### CW-006ext：rst_ni 1→0 扩至全闭包

- **范围**：CW-006 现覆盖 `axi_xbar`/`axi_mux`/`axi_demux_simple`/`axi_err_slv`
  4 个模块。同根因（spec §2.3 无热复位语义）适用于闭包内全部模块：
  `axi_cut`/`axi_multicut`/`spill_register`/`spill_register_flushable`/
  `rr_arb_tree`/`fifo_v3`/`axi_demux_id_counters`/`counter`/`delta_counter`/
  `addr_decode`/`addr_decode_dync`/`axi_id_prepend`/`lzc`/`stream_register`
- **urg**：各模块 Toggle Details `rst_ni` 均 `Yes/No`（0→1 covered, 1→0 Not Covered）

### CW-007ext：size[2] 扩至全闭包

- **范围**：CW-007 现覆盖 `axi_mux`/`axi_demux_simple`/`axi_err_slv` 3 个模块。
  同根因（64-bit bus 下 AxSIZE ≤ 3'b011，bit[2] 恒 0）适用于：
  `axi_cut`/`axi_multicut`/`spill_register`/`spill_register_flushable`/
  `rr_arb_tree`（data_o.size[2]）
- **RTL**：`tb/xbar_types_pkg.sv:132` `DATA_W=64`，cfgA-E 均未 override
- **urg**：各模块 Toggle Details `*.size[2]` = `No/No/No INPUT`

## DV 场景汇总（登记 testplan）

| DV-id | 场景 | 闭合目标（格） | testplan id |
|---|---|---|---|
| DV-A+B+J | 长 decode-miss burst + 低 addr + size 变化 | #17,19,21,24,25,27-30 | M6-CV01 |
| DV-D | slave 非 OKAY 响应 + 非零 user | #18,27-30 | M6-CV02 |
| DV-C | B/R 通道 backpressure 多样化 | #15,18 | M6-CV03 |
| DV-E+F+G | ID 饱和 + ATOP inject | #16,20-22 | M6-CV04 |
| DV-H+I | err_slv FIFO 容量 + 多样 ID | #24,25 | M6-CV05 |

## 下一步

1. **本闭环**：DV 场景 M6-CV01..05 登记进 testplan（见下方 `doc/testplan.md` 新行）
2. **闭环 4**：rev 评审 CW-015..019 + CW-006ext/007ext → 签核后登记 `doc/coverage-waivers.md`
3. **闭环 5+**：实现 DV 测试代码 → `make regress COV=1` 重测 → 重跑 `cov_baseline.py` 核对
