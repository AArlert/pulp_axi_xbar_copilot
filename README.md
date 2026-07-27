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

### 数据流概览

`axi_xbar` 对外是 `NoSlvPorts`（基线 6）个 slave 端口进、`NoMstPorts`（基线 8）个
master 端口出的全连接交叉开关：外部 AXI master 挂在 slave 端口上发起请求，外部
AXI slave 挂在 master 端口上接收请求；一笔事务从某个 slave 端口进来，查地址表决
定该走哪个 master 端口，穿过交叉矩阵后送出，响应原路返回。下图示意该数据流（省
略了逐格展开的连接矩阵与部分同构端口，仅体现路径与分支逻辑）：

![axi_xbar 请求/响应数据流](doc/attach/axi_xbar_dataflow.svg)

### 请求路径

1. **`addr_decode` 查地址表**：每个 slave 端口进来的 AW/AR 各查一次
   （`×NoSlvPorts×2`），得到目标 master 端口编号，或判为地址不匹配的错误。
2. **`axi_demux` 按端口分流**：每个 slave 端口一个，把这个端口的请求摆渡到对应
   出口方向；地址查不到就摆渡去 `axi_err_slv` 报错窗口。内部还管理"同 ID 事务未
   应答完前不能被同向抢先"（`axi_demux_id_counters`，仅 `UniqueIds` 关闭时需
   要），并插几级 `spill_register` 流水线改善时序。
3. **交叉连接矩阵**：`NoSlvPorts × NoMstPorts` 个格子，每格对应一条唯一路径。
   `Connectivity[i][j]` 规划为连通则走 `axi_multicut`（按 `LatencyMode` 插几级流
   水线切割，只加延迟不改数据）；矩阵里没修这条路（稀疏连接，M3 里会测）则走另
   一个 `axi_err_slv`，直接判错，不碰真实下游 slave。
4. **`axi_mux` 出口合流**：一个 master 端口可能同时收到好几个 slave 端口方向汇
   过来的车流，`axi_mux` 负责：① 用轮询仲裁器（`rr_arb_tree`）决定这一拍谁先
   走；② 把"这笔事务从哪个 slave 端口来"前缀进事务 ID（`axi_id_prepend`）——响应
   要靠这个前缀才能找到回家的路；③ 合并成一条 AXI 接口，驱动外部下游 slave。

### 响应路径

B/R 响应从 master 端口回来，`axi_mux` 用前缀进 ID 里的信息知道该分流回哪条来
路，一路走回对应 slave 端口的 `axi_demux`，最后从原来进来的那个 slave 端口把
B/R 吐给外部 master——全程原路返回，不重新查地址表。

### `axi_err_slv` 与 ATOP

两处 `axi_err_slv`（一处接"地址查不到"的车流，一处接"矩阵里没修这条路"的车
流）行为上是一回事，只是触发条件不同。若判错的事务恰好是 ATOP（读写合一的原子
操作），会产生两个响应（B 和 R），错误从机也得把两个都伪造出来，所以内部还带一
个 `axi_atop_filter` + 几个 `fifo_v3`。属实现细节，行为规格角度不需要深挖，只要
知道"ATOP 打开时，decode error 的错误从机也能正确生成双响应"这条行为在 spec §6
有描述，DV 记分板要覆盖到。

### 设计动机

- **先分后合**：slave 端口各自独立分流（`demux`），master 端口各自独立合流
  （`mux`），中间用交叉矩阵解耦，因此 `NoSlvPorts`/`NoMstPorts` 可独立配置、连
  接关系（`Connectivity`）也可稀疏。
- **ID 前缀是找路的钥匙**：进去时不记路，回来时全靠 ID 里前缀的"来源端口号"找
  到回家的路，这也是 spec §5（ID 与保序）重要的原因，直接决定 scoreboard 该怎
  么判断响应有没有走错端口。
- **两处"报错窗口"**：`axi_err_slv` 一处接"地址查不到"的车流，一处接"矩阵里没
  修这条路"的车流，行为上是一回事，只是触发条件不同。
