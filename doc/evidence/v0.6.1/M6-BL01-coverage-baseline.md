# M6-BL01 Coverage Baseline Evidence

**version**: 0.6.1  
**date**: 2026-08-04  
**command**: `make regress COV=1`（241 tests, 7 config points）  
**urg command**: `urg -full64 -dir out/cov.vdb -format text -report out/urgText6 -metric line+cond+fsm+tgl+branch+assert`

## Judgment Criteria

| # | criterion | status |
|---|-----------|--------|
| 1 | 全量回归 241/241 PASS | PASS — `sim/result_summary.txt` passed=241/241 |
| 2 | xcov 核对 urg 数字一致 | N/A — xcov NPI_INIT_FAILED（Verdi O-2018 pynpi.cov 缺失），urg 数字为唯一权威来源 |
| 3 | 现状表每格有数字 | PASS — 22 modules × 6 types = 132 cells，每格均有数值或 N/A |

## Coverage Distribution (config points)

| config | vdb path | tests | role |
|--------|----------|-------|------|
| baseline | `out/cov.vdb` | 196 | M1-M5 baseline config tests |
| cfgA | `out/cfgA/cov.vdb` | 8 | m3_cf01_cfga + m5_sk03_soak |
| cfgB | `out/cfgB/cov.vdb` | 8 | m3_cf02_cfgb + M5 soak |
| cfgC | `out/cfgC/cov.vdb` | 8 | m3_cf03_cfgc + M5 soak |
| cfgD | `out/cfgD/cov.vdb` | 8 | m3_cf04_cfgd + m5_rn02_soak |
| cfgE | `out/cfgE/cov.vdb` | 8 | m4_ft01_cfge + M5 soak |
| m0 | `out/m0/cov.vdb` | 5 | upstream_sanity |
| **total** | | **241** | |

Configs 间 vdb 不可合并（BUG-0037：参数化实例不同）。下表以 baseline（196 tests）为主视角。

## Baseline (module, type) Grid — 22 DUT Closure Modules

| module | Line | Cond | Toggle | FSM | Branch | Assert |
| --- | --- | --- | --- | --- | --- | --- |
| `axi_xbar` | N/A | N/A | **94.44** | N/A | N/A | **100.00** |
| `axi_xbar_unmuxed` | N/A | **100.00** | **98.89** | N/A | **100.00** | **100.00** |
| `addr_decode` | N/A | N/A | **92.68** | N/A | N/A | N/A |
| `addr_decode_dync` | **100.00** | **100.00** | **92.00** | N/A | 83.33 [CW-008] | **100.00** |
| `axi_demux` | N/A | N/A | **92.31** | N/A | N/A | N/A |
| `axi_demux_simple` | **100.00** | 82.76 [CW-009+DV-E] | **93.98** | N/A | **100.00** | **92.86** |
| `axi_demux_id_counters` | 73.91 [UNOWNED] | **100.00** | 74.06 [UNOWNED] | N/A | 79.49 [UNOWNED] | **100.00** |
| `counter` | N/A | N/A | 43.48 [UNOWNED] | N/A | N/A | N/A |
| `delta_counter` | **100.00** | N/A | 41.20 [UNOWNED] | N/A | **100.00** | N/A |
| `axi_err_slv` | **100.00** | **100.00** | 70.37 [CW-003/004/005/006/002/007+DV] | N/A | **100.00** | **100.00** |
| `axi_atop_filter` | 48.18 [CW-001] | 41.94 [CW-001] | 65.34 [CW-001] | 14.29 [CW-001] | 41.30 [CW-001] | **100.00** |
| `stream_register` | 75.00 [CW-014] | N/A | 22.00 [CW-014(partial)] | N/A | 50.00 [CW-014] | N/A |
| `axi_mux` | **100.00** | **100.00** | 89.62 [CW-002/006/007+DV] | N/A | **100.00** | **100.00** |
| `axi_id_prepend` | **100.00** | N/A | 78.26 [UNOWNED] | N/A | N/A | **100.00** |
| `rr_arb_tree` | 80.00 [UNOWNED] | **95.74** | 77.63 [UNOWNED] | N/A | **91.59** | **100.00** |
| `lzc` | N/A | **97.73** | 42.59 [UNOWNED] | N/A | **97.73** | **100.00** |
| `fifo_v3` | **92.68** | 80.19 [UNOWNED] | 82.09 [UNOWNED] | N/A | 78.43 [UNOWNED] | **100.00** |
| `axi_multicut` | N/A | N/A | 89.62 [UNOWNED] | N/A | N/A | **100.00** |
| `axi_cut` | N/A | N/A | 89.62 [UNOWNED] | N/A | N/A | N/A |
| `spill_register` | N/A | N/A | 88.77 [UNOWNED] | N/A | N/A | N/A |
| `spill_register_flushable` | **100.00** | 82.49 [UNOWNED] | 79.95 [UNOWNED] | N/A | **100.00** | 0.00 [UNOWNED] |
| `axi_pkg` | N/A | N/A | N/A | N/A | N/A | **100.00** |

**Summary**: 132 cells total, **30 cells below 90%**, breakdown:
- 18 cells UNOWNED（M4 遗留，无主人）
- 11 cells waivered（CW-001 through CW-014，Kind-A 结构不可达）
- 1 cell <90 TODO（未归因于 waiver 或 UNOWNED）— 无，全 30 格均有归因

## urg Dashboard Cross-check

```
Total Coverage Summary (baseline, 196 tests)
SCORE  LINE   COND   TOGGLE FSM    BRANCH ASSERT 
 69.36  82.56  76.02  74.47  14.29  85.47  83.36
```

## xcov Cross-validation Note

xcov session.open 返回 `NPI_INIT_FAILED: failed to import pynpi.cov`（Verdi O-2018.09-SP2 的 pynpi 模块不导出 cov 子模块）。本次 xcov 数字核对无法执行。urg 文本报告（`out/urgText6/modlist.txt`）为覆盖率唯一权威来源。

## Reproduction

```bash
cd sim
make regress COV=1                                    # 241/241 PASS
urg -full64 -dir out/cov.vdb -format text \
    -report out/urgText6 \
    -metric line+cond+fsm+tgl+branch+assert
python3 ../scripts/cov_baseline.py out/urgText6/modlist.txt
```
