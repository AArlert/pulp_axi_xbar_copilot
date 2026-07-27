# pulp_axi_xbar_copilot

Agent 驱动的全自动 IC 验证仓库。DUT 为 PULP 官方
[pulp-platform/axi](https://github.com/pulp-platform/axi) 的 `axi_xbar`
（AXI4+ATOP 全连接 crossbar），以只读快照 vendor 于本仓库（v0.39.9，
SHA 锁定见 `vendor/VENDOR.md`）。

工作流采用 [iverif-workflow](https://github.com/AArlert/iverif-workflow)
（copilot profile：orch 主会话纯调度，arch/de/dv/rev 子 agent 产出，
证据链即运行时接口）。本仓库是该工作流的首次实战应用，过程中发现的
框架摩擦记录于 `doc/fw-feedback.md` 并回流框架仓库。

本仓库的验证成果（spec 蒸馏、testplan、UVM 环境、覆盖率收敛过程）供
隔壁人工学习仓库 `pulp_axi_xbar` 参考。

- 上手：`make handover && make next`
- 仿真（VM 内）：`make smoke` / `make run TEST=<t> SEED=<n>` / `make regress`
- 文档约定：表头/机制英文（columns_preset=en），正文中文

## DUT 模块层级

以下为 `axi_xbar`（`vendor/axi/src/axi_xbar.sv`）自顶向下的模块例化关系，
经 grep 各文件的例化语句（含 `generate`/`for` 循环）逐级追出，收敛至
`common_cells`/`tech_cells_generic` 基础单元为止。数量标注（如
`×NoSlvPorts`）取自各自 `for` 循环的边界参数，不代表精确数值。

```
axi_xbar (vendor/axi/src/axi_xbar.sv)
├─ axi_xbar_unmuxed (vendor/axi/src/axi_xbar_unmuxed.sv)
│  ├─ addr_decode ×NoSlvPorts×2（AW/AR 各一次）(vendor/common_cells/src/addr_decode.sv)
│  │  └─ addr_decode_dync (vendor/common_cells/src/addr_decode_dync.sv)
│  │     └─ 叶子：纯组合逻辑，不再例化子模块
│  ├─ axi_demux ×NoSlvPorts (vendor/axi/src/axi_demux.sv)
│  │  ├─ spill_register ×7（AW/W/B/AR/R 流水线切割）(vendor/common_cells/src/spill_register.sv)
│  │  │  └─ spill_register_flushable (common_cells/tech_cells_generic 基础单元)
│  │  └─ axi_demux_simple ×1 (vendor/axi/src/axi_demux_simple.sv)
│  │     ├─ axi_demux_id_counters（UniqueIds 时，AW/AR 各一次）(vendor/axi/src/axi_demux_simple.sv)
│  │     │  └─ (common_cells/tech_cells_generic 基础单元，如 delta_counter ×NoCounters)
│  │     └─ (common_cells/tech_cells_generic 基础单元，如 counter/rr_arb_tree，用于 ID 占用计数与主端口仲裁)
│  ├─ axi_err_slv ×NoSlvPorts（译码错误从机，接在 demux 多出的一路上）(vendor/axi/src/axi_err_slv.sv)
│  │  ├─ axi_atop_filter（ATOPs 参数为真时）(vendor/axi/src/axi_atop_filter.sv)
│  │  │  └─ (common_cells/tech_cells_generic 基础单元，如 stream_register)
│  │  └─ (common_cells/tech_cells_generic 基础单元，如 fifo_v3 ×3、counter ×1)
│  └─ 交叉连接矩阵 ×NoSlvPorts×NoMstPorts（按 Connectivity[i][j] 二选一，逐格例化）
│     ├─ axi_multicut（Connectivity[i][j] 为真时，流水线切割）(vendor/axi/src/axi_multicut.sv)
│     │  └─ axi_cut ×NoCuts (vendor/axi/src/axi_cut.sv)
│     │     └─ (common_cells/tech_cells_generic 基础单元，如 spill_register ×5)
│     └─ axi_err_slv（Connectivity[i][j] 为假时，接入译码错误从机）(vendor/axi/src/axi_err_slv.sv)
│        └─ 子树同上（axi_atop_filter + common_cells 基础单元）
└─ axi_mux ×NoMstPorts (vendor/axi/src/axi_mux.sv)
   ├─ 分支一：NoSlvPorts==1（单主端口旁路）
   │  └─ (common_cells/tech_cells_generic 基础单元，如 spill_register ×7)
   └─ 分支二：NoSlvPorts>1（正常仲裁路径，与分支一二选一）
      ├─ axi_id_prepend ×NoSlvPorts (vendor/axi/src/axi_id_prepend.sv)
      │  └─ 叶子：纯组合逻辑，不再例化子模块
      └─ (common_cells/tech_cells_generic 基础单元，如 rr_arb_tree ×2、fifo_v3 ×1、spill_register ×6)
```
