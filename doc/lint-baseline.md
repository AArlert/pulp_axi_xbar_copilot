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

基线快照：2026-07-31 · 框架 0.4.6 · 合计 **296** 条 · 唯一站点 **236** 个 · 类别 **8** 种

> **2026-07-31 全量重同步说明（BUG-0040 分诊卡）**：上一次快照（2026-07-28）
> 冻结之后，`tb/` 又落地了若干本身已各自登记在案的合法变更——BUG-0034 修复
> (`d7f5011`)、5 个 M3 covergroup + BUG-0024/0025/0031 相关的 SVA cover 补齐
> (`0e9d516`/`68b6cca`/`482a47e`)、M3 多配置构建 (`c105d2d`)、M3-TL01 守卫
> (`bff8a04`)、0.4.2 零风险重构 (`01e7976`，消 seq_lib.sv 重复循环体)——但
> `doc/lint-baseline.md` 从未跟着重新生成过，导致 `make lint-diff` 报出 153
> 个「新站点」（BUG-0040）。逐条读码分诊（方法论沿用 BUG-0021，见该页
> `## rca`）：**153/153 全部风格，0 条真缺陷**——绝大多数是「同一条已被
> BUG-0021 判过风格的断言/cover，只是所在文件插入了新代码导致行号后移」，
> 少数（`ULCO` 8 处，`tb/seq_lib.sv`）是 0.4.2 重构合并重复循环体后的净减少
> （真实代码消失，非行号漂移）。因此本次没有对 225 条旧站点逐条「追加」新
> 站点、留着 142 条对不上当前代码的陈旧行号——而是按本文件自己头部写明的
> 生成命令，对当前 `out/lint.log` 做一次**全量重取**，产出下面这份自洽的
> 236 行唯一站点表（296 条原始计数，含 `axi_chan_sva.sv` 等多实例化文件的
> 重复计数，方法与 REV-010 时期一致）。**判定结论对旧站点无一条改判**——
> 每一条能对上旧表的站点，风格结论原样沿用；新增的站点全部套用 BUG-0021
> 已确立的机械判据逐条核实（详见 `doc/bugs/BUG-0040.md` `## triage`）。

## 按类别

| 类别 | 条数 | 性质（BUG-0021 分诊 + REV-010 §3.1 复核 + BUG-0040 2026-07-31 重同步复核） |
|---|---|---|
| `Lint-[NS]` | 85 | 风格（空语句/多行语句终止符：`wait fork;`/`@(posedge clk);`/`do…while(…);`/`repeat(n) @(posedge clk);`/`cover property(…);` 等）——BUG-0021 分诊全查零空体；BUG-0040 复核新增的 46 处逐条确认同属该形态，无 `if(…);`/`for(…);` |
| `Lint-[SVA-AECASR]` | 54 | 风格（action block 内 UVM 报告 API 的固有保守告警，或 `always_ff` 内立即断言的过程代码，均非 preponed/observed 采样竞争）；真缺陷部分已于 c29bede 清零，BUG-0040 新增 11 处逐条确认零函数调用进入 property 判决表达式 |
| `Lint-[SVA-UA]` | 44 | 风格（未命名断言）；`scripts/svacheck.py` 两层判据均不依赖断言名；BUG-0040 复核确认「带标签 cover 不报」的判据在新站点上同样成立 |
| `Lint-[SVA-CE]` | 46 | 风格（`disable iff` 参数非裸标识符） |
| `Lint-[SVA-DIU]` | 46 | 风格（`disable iff` 用法） |
| `Lint-[ULCO]` | 6 | 风格（`int unsigned` vs `logic [7:0]` 零扩展比较，IEEE 1800 §11.6/§11.8.1 语义正确）——0.4.2 重构合并 `tb/seq_lib.sv` 重复循环体后从 14 降到 6，净减少非新增，无需分诊 |
| `Lint-[SV-PIU]` | 9 | 风格（`$unit` 作用域 import）；可移植性债务，非缺陷 |
| `Lint-[WMIA-L]` | 6 | 风格（4 条为 UVM-1.2 宏展开体内的库代码；2 条 `scoreboard_refmodel.sv` 的 `ro.id >> ID_W_SLV` 右移改写零扩展赋值——`xbit eval` 核实 `8'hFF >> 5` 与 `8'hFF[7:5]` 数值等价，widening、无截断） |

## 按文件

| 文件 | 条数 |
|---|---|
| `tb/tb/sva/axi_xbar_stall_sva.sv` | 87 |
| `tb/tb/sva/axi_chan_sva.sv` | 81 |
| `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 33 |
| `tb/tb/slvport_agent.sv` | 24 |
| `tb/tb/sva/axi_xbar_atop_sva.sv` | 16 |
| `tb/tb/seq_lib.sv` | 15 |
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
| `Lint-[NS]` | `tb/tb/scoreboard_refmodel.sv` | 385 |
| `Lint-[NS]` | `tb/tb/scoreboard_refmodel.sv` | 386 |
| `Lint-[NS]` | `tb/tb/scoreboard_refmodel.sv` | 394 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 109 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 544 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 883 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 893 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 897 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 1039 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 1042 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 1178 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 1182 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 1186 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 1368 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 1402 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 1429 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 1432 |
| `Lint-[NS]` | `tb/tb/seq_lib.sv` | 1453 |
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
| `Lint-[NS]` | `tb/tb/slvport_agent.sv` | 390 |
| `Lint-[NS]` | `tb/tb/sva/axi_chan_sva.sv` | 256 |
| `Lint-[NS]` | `tb/tb/sva/axi_chan_sva.sv` | 276 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 162 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 169 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 59 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 469 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 471 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 475 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 477 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 481 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 483 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 486 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 487 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 488 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 489 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 493 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 495 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 496 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 497 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 505 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 507 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 515 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 517 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 524 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 526 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 257 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 259 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 261 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 263 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 268 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 270 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 272 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 274 |
| `Lint-[NS]` | `tb/tb/sva/axi_xbar_worder_sva.sv` | 112 |
| `Lint-[NS]` | `tb/tb/tb_top.sv` | 32 |
| `Lint-[NS]` | `tb/tb/tb_top.sv` | 33 |
| `Lint-[NS]` | `tb/tb/tb_top.sv` | 41 |
| `Lint-[SV-PIU]` | `tb/tb/sva/axi_chan_sva.sv` | 40 |
| `Lint-[SV-PIU]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 31 |
| `Lint-[SV-PIU]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 23 |
| `Lint-[SV-PIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 80 |
| `Lint-[SV-PIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 76 |
| `Lint-[SV-PIU]` | `tb/tb/sva/axi_xbar_worder_sva.sv` | 27 |
| `Lint-[SV-PIU]` | `tb/tb/tb_top.sv` | 10 |
| `Lint-[SV-PIU]` | `tb/tb/tb_top.sv` | 13 |
| `Lint-[SV-PIU]` | `tb/tb/tb_top.sv` | 14 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 168 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 172 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 176 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 180 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 184 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 193 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 197 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 253 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_chan_sva.sv` | 273 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 154 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 50 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 452 |
| `Lint-[SVA-AECASR]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 458 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_chan_sva.sv` | 166 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_chan_sva.sv` | 170 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_chan_sva.sv` | 174 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_chan_sva.sv` | 178 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_chan_sva.sv` | 182 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 152 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 161 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 168 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 47 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 58 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 450 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 456 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 468 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 470 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 474 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 476 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 480 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 482 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 486 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 487 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 488 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 489 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 492 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 494 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 496 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 497 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 504 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 506 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 514 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 516 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 523 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 525 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 256 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 258 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 260 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 262 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 267 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 269 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 271 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 273 |
| `Lint-[SVA-CE]` | `tb/tb/sva/axi_xbar_worder_sva.sv` | 112 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_chan_sva.sv` | 166 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_chan_sva.sv` | 170 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_chan_sva.sv` | 174 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_chan_sva.sv` | 178 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_chan_sva.sv` | 182 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 152 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 161 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 168 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 47 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_route_sva.sv` | 58 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 450 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 456 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 468 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 470 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 474 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 476 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 480 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 482 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 486 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 487 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 488 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 489 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 492 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 494 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 496 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 497 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 504 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 506 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 514 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 516 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 523 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 525 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 256 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 258 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 260 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 262 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 267 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 269 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 271 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 273 |
| `Lint-[SVA-DIU]` | `tb/tb/sva/axi_xbar_worder_sva.sv` | 112 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 166 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 170 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 174 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 178 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 182 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 191 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 195 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 252 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_chan_sva.sv` | 272 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 152 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 161 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_atop_sva.sv` | 168 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 450 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 456 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 474 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 476 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 480 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 482 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 486 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 487 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 488 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 489 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 492 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 494 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 496 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_stall_sva.sv` | 497 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 256 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 258 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 260 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 262 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 267 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 269 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 271 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_txlimit_sva.sv` | 273 |
| `Lint-[SVA-UA]` | `tb/tb/sva/axi_xbar_worder_sva.sv` | 112 |
| `Lint-[ULCO]` | `tb/tb/mstport_agent.sv` | 159 |
| `Lint-[ULCO]` | `tb/tb/mstport_agent.sv` | 166 |
| `Lint-[ULCO]` | `tb/tb/slvport_agent.sv` | 87 |
| `Lint-[ULCO]` | `tb/tb/slvport_agent.sv` | 90 |
| `Lint-[ULCO]` | `tb/tb/slvport_agent.sv` | 168 |
| `Lint-[ULCO]` | `tb/tb/slvport_agent.sv` | 171 |
| `Lint-[WMIA-L]` | `tb/tb/axi_txn.sv` | 31 |
| `Lint-[WMIA-L]` | `tb/tb/axi_txn.sv` | 32 |
| `Lint-[WMIA-L]` | `tb/tb/axi_txn.sv` | 33 |
| `Lint-[WMIA-L]` | `tb/tb/axi_txn.sv` | 34 |
| `Lint-[WMIA-L]` | `tb/tb/scoreboard_refmodel.sv` | 761 |
| `Lint-[WMIA-L]` | `tb/tb/scoreboard_refmodel.sv` | 831 |
