# lint 基线（`../tb/` 范围）

> **本文件是 BUG-0021 转 WONTFIX 的守卫载体**（REV-010 §4 指导 G3）。
> 它**不是**一份「允许的告警清单」，而是一条基线——
> **每里程碑跑一次强制重编 lint 与本文件做差分，出现新类别或新站点即须分诊**。

> 该守卫**以 BUG-0022 修复为前提**：在那之前，一次「根本没执行」的 lint 会被读成
> 「无新增告警」——与 BUG-0028 的「分母静默缩水」是同一个失效家族。

> **硬性红线不变**：不得靠放宽 `lint:` 过滤范围、加类别豁免、或摘 flist 文件让 lint 变绿。

生成命令（`.vcs.timestamp` 必须先删，否则撞 BUG-0022 假绿）：

```
rm -f sim/out/simv_lint.daidir/.vcs.timestamp
cd sim && make lint TEST=m2_or03_guard_test
```

基线快照：2026-07-28 · 框架 0.4.5 · 合计 **285** 条 · 唯一站点 **225** 个 · 类别 **8** 种

## 按类别

| 类别 | 条数 | 性质（BUG-0021 分诊 + REV-010 §3.1 复核） |
|---|---|---|
| `Lint-[NS]` | 76 | 风格（空语句）——BUG-0021 分诊逐条 67/67 全查，零空体 |
| `Lint-[SVA-AECASR]` | 54 | 风格（action block 内 UVM 报告 API 的固有保守告警）；真缺陷部分已于 c29bede 清零 |
| `Lint-[SVA-UA]` | 46 | 风格（未命名断言）；`scripts/svacheck.py` 两层判据均不依赖断言名 |
| `Lint-[SVA-CE]` | 40 | 风格（`disable iff` 参数非裸标识符） |
| `Lint-[SVA-DIU]` | 40 | 风格（`disable iff` 用法） |
| `Lint-[ULCO]` | 14 | 风格（`int unsigned` vs `logic [7:0]` 零扩展比较，IEEE 1800 §11.6/§11.8.1 语义正确） |
| `Lint-[SV-PIU]` | 9 | 风格（`$unit` 作用域 import）；可移植性债务，非缺陷 |
| `Lint-[WMIA-L]` | 6 | 风格（4 条为 UVM-1.2 宏展开体内的库代码，2 条为 3bit→int 加宽赋值） |

## 按文件

| 文件 | 条数 |
|---|---|
| `tb/tb/sva/axi_chan_sva.sv` | 81 |
| `tb/tb/sva/axi_xbar_stall_sva.sv` | 71 |
| `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 33 |
| `tb/tb/slvport_agent.sv` | 24 |
| `tb/tb/seq_lib.sv` | 20 |
| `tb/tb/sva/axi_xbar_atop_sva.sv` | 16 |
| `tb/tb/mstport_agent.sv` | 12 |
| `tb/tb/sva/axi_xbar_route_sva.sv` | 8 |
| `tb/tb/tb_top.sv` | 6 |
| `tb/tb/scoreboard_refmodel.sv` | 5 |
| `tb/tb/sva/axi_xbar_worder_sva.sv` | 5 |
| `tb/tb/axi_txn.sv` | 4 |

## 站点明细（类别 × 文件 × 行）

差分以本表为准——**同类别同文件但新行号 = 新站点 = 须分诊**。

| 类别 | 文件 | 行 |
|---|---|---|
| `Lint-[NS]` | `tb/tb/mstport_agent.sv` | 79 |
| `Lint-[NS]` | `tb/tb/mstport_agent.sv` | 92 |
| `Lint-[NS]` | `tb/tb/mstport_agent.sv` | 119 |
| `Lint-[NS]` | `tb/tb/mstport_agent.sv` | 141 |
| `Lint-[NS]` | `tb/tb/mstport_agent.sv` | 143 |
| `Lint-[NS]` | `tb/tb/mstport_agent.sv` | 148 |
| `Lint-[NS]` | `tb/tb/mstport_agent.sv` | 156 |
| `Lint-[NS]` | `tb/tb/mstport_agent.sv` | 158 |
| `Lint-[NS]` | `tb/tb/mstport_agent.sv` | 169 |
| `Lint-[NS]` | `tb/tb/mstport_agent.sv` | 223 |
| `Lint-[NS]` | `tb/tb/scoreboard_refmodel.sv` | 281 |
| `Lint-[NS]` | `tb/tb/scoreboard_refmodel.sv` | 282 |
| `Lint-[NS]` | `tb/tb/scoreboard_refmodel.sv` | 290 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 89 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 187 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 301 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 367 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 493 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 596 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 697 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 760 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 888 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 983 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 993 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 997 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 50 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 56 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 84 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 93 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 109 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 131 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 137 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 163 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 174 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 192 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 212 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 216 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 226 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 231 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 234 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 236 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 245 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 277 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 295 |
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 365 |
| `Lint-[NS]` | `tb/tb/sva/axi_chan_sva.sv` | 239 |
| `Lint-[NS]` | `tb/tb/sva/axi_chan_sva.sv` | 255 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 162 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 169 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 59 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 361 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 363 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 369 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 371 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 379 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 381 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 388 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 389 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 390 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 391 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 398 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 400 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 401 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 402 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 253 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 255 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 257 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 259 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 264 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 266 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 268 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 270 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_worder_sva.sv` | 107 |
| `Lint-[NS]` | `tb/tb/tb_top.sv` | 32 |
| `Lint-[NS]` | `tb/tb/tb_top.sv` | 33 |
| `Lint-[NS]` | `tb/tb/tb_top.sv` | 41 |
| `Lint-[SV-PIU]` | `tb/tb/sva/axi_chan_sva.sv` | 39 |
| `Lint-[SV-PIU]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 31 |
| `Lint-[SV-PIU]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 23 |
| `Lint-[SV-PIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 51 |
| `Lint-[SV-PIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 76 |
| `Lint-[SV-PIU]` | `tb/tb/sva/axi_xbar_worder_sva.sv` | 27 |
| `Lint-[SV-PIU]` | `tb/tb/tb_top.sv` | 10 |
| `Lint-[SV-PIU]` | `tb/tb/tb_top.sv` | 13 |
| `Lint-[SV-PIU]` | `tb/tb/tb_top.sv` | 14 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 167 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 171 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 175 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 179 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 183 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 192 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 196 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 236 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 252 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 154 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 50 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 347 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 353 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_chan_sva.sv` | 165 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_chan_sva.sv` | 169 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_chan_sva.sv` | 173 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_chan_sva.sv` | 177 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_chan_sva.sv` | 181 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 152 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 161 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 168 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 47 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 58 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 345 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 351 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 360 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 362 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 368 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 370 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 378 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 380 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 388 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 389 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 390 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 391 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 397 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 399 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 401 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 402 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 252 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 254 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 256 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 258 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 263 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 265 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 267 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 269 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_worder_sva.sv` | 107 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_chan_sva.sv` | 165 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_chan_sva.sv` | 169 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_chan_sva.sv` | 173 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_chan_sva.sv` | 177 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_chan_sva.sv` | 181 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 152 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 161 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 168 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 47 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 58 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 345 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 351 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 360 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 362 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 368 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 370 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 378 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 380 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 388 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 389 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 390 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 391 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 397 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 399 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 401 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 402 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 252 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 254 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 256 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 258 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 263 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 265 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 267 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 269 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_worder_sva.sv` | 107 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 165 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 169 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 173 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 177 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 181 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 190 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 194 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 235 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 251 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 152 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 161 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 168 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 345 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 351 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 360 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 362 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 368 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 370 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 378 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 380 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 388 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 389 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 390 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 391 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 397 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 399 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 401 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 402 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 252 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 254 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 256 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 258 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 263 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 265 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 267 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 269 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_worder_sva.sv` | 107 |
| `Lint-[ULCO]` | `tb/tb/mstport_agent.sv` | 159 |
| `Lint-[ULCO]` | `tb/tb/mstport_agent.sv` | 166 |
| `Lint-[ULCO]` | `tb/tb/seq_lib.sv` | 49 |
| `Lint-[ULCO]` | `tb/tb/seq_lib.sv` | 146 |
| `Lint-[ULCO]` | `tb/tb/seq_lib.sv` | 225 |
| `Lint-[ULCO]` | `tb/tb/seq_lib.sv` | 240 |
| `Lint-[ULCO]` | `tb/tb/seq_lib.sv` | 531 |
| `Lint-[ULCO]` | `tb/tb/seq_lib.sv` | 544 |
| `Lint-[ULCO]` | `tb/tb/seq_lib.sv` | 818 |
| `Lint-[ULCO]` | `tb/tb/seq_lib.sv` | 932 |
| `Lint-[ULCO]` | `tb/tb/slvport_agent.sv` | 87 |
| `Lint-[ULCO]` | `tb/tb/slvport_agent.sv` | 90 |
| `Lint-[ULCO]` | `tb/tb/slvport_agent.sv` | 168 |
| `Lint-[ULCO]` | `tb/tb/slvport_agent.sv` | 171 |
| `Lint-[WMIA-L]` | `tb/tb/axi_txn.sv` | 31 |
| `Lint-[WMIA-L]` | `tb/tb/axi_txn.sv` | 32 |
| `Lint-[WMIA-L]` | `tb/tb/axi_txn.sv` | 33 |
| `Lint-[WMIA-L]` | `tb/tb/axi_txn.sv` | 34 |
| `Lint-[WMIA-L]` | `tb/tb/scoreboard_refmodel.sv` | 493 |
| `Lint-[WMIA-L]` | `tb/tb/scoreboard_refmodel.sv` | 561 |
