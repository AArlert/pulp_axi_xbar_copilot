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
