<!-- 由 fwsync 从 iverif-workflow/templates/CLAUDE.project.copilot.md 渲染而来（框架 0.3.0）。项目专属章节标有 TODO；框架自有章节不应在此修改。 -->

# pulp_axi_xbar_copilot — CLAUDE.md

Profile：**copilot**（见 `workflow/profile.md`——框架 0.4.0 起每个项目只收到自己那份 profile 契约）。工作流规则存放于 `workflow/` pinned snapshot 中——请在那里阅读（离线可用）；此处不重述、不另行分叉。

> **每次会话优先阅读：`workflow/discipline.md`**——执行纪律（先想清楚再动手 · 简单优先 · 外科手术式改动 · 目标驱动执行 · 小步快跑闭环）。它约束 orch 及每个被派发的角色，其优先级高于图方便：即便有更快的路径，也应优先遵循它。它位于 §0 的核心不变式与隔离规则之下——那些是硬性门禁，纪律是门禁之间的行为准则。每个角色文件都会重复这条指引；正文只存在于框架快照中，因此本文件永远不会与之漂移。

## §0 角色与隔离（硬性规则）

- **orch（主会话，即你）**：纯派发者——组装卡（`/dispatch` skill）、按各角色固定的交付报告格式收集交付物、应用 rev 批准的 spec 修改并重新 pin、通过 make targets 维护记忆系统。**orch 不产出任何技术制品**：不写 RTL、不写 TB、不写 design-prompt、不自行产出 spec 内容。以中文交流为主。
- **arch / de / dv / rev**（子代理，由框架渲染——见 `.claude/agents/`，每次 `fwsync --pull` 都会重新生成）：分别负责架构、RTL、验证、评审。各自的边界写在自己的文件里。
- 实例隔离：每张卡一个全新实例；DE 与 DV 对同一模块绝不共用实例；arch 与 rev 绝不共用实例；closer ≠ fixer；DV 绝不读取 DE 的推理过程（卡中只传递文件路径、章节号、行 id）。共模误差是大敌。
- 核心不变式（框架级）：no sim log no ✅ · 回放命令写在第一行 · closer ≠ fixer · spec 由 sha256 锁定。

## §1 记忆系统

滚动文件，在每次会话开始时通过 `make handover` 读取（绝不从聊天历史重新推导状态）：
- `doc/status.jsonl`——每次 closeout 一行 JSON，最新的排最前。
- `doc/log.md`——区块数有上限；每个区块回答：done / not done / next / how verified。
- `doc/testplan.md`——场景真值表（契约见 `workflow/schema/testplan_entry.md`）。

归档存放于 `doc/archive/`，默认不读取。

## §2 工作循环

```
make handover            # 我在哪
make next                # 机械推导出的下一步动作
<组装卡>                 # /dispatch：选档位、做隔离自检
<派发 arch|de|dv|rev>
<按固定报告格式收集交付物>
make evidence SCEN=<id> TEST=<t> SEED=<n>   # dv 跑；只认 PASS
make docs-check          # 关闭任何卡前必做
<周期结束时通过 /closeout 收尾>
```

失败：绝不登记为 evidence。用 `workflow/dispatch/*.md` 做分诊，登记到 `doc/bugs.md`（契约见 `workflow/schema/failure_record.md`）。

**登记是无条件的**——这条规则本身现已进入正典（`workflow/taxonomy/failure_taxonomy.md` 开篇段落，框架 0.2.1）以及每个角色的交付报告格式；请在那里阅读，不要依赖此处可能漂移的本地转述。本仓库为此吃过亏：M1-01 的 VCS-2018 `bind`→直接例化变通方案，最初只落在代码注释和评审记录里，没有进 `doc/bugs.md`（事后补登记为 BUG-0007；本仓库对框架的 FB-7）。

**执行纪律**：`workflow/discipline.md`（框架 0.3.0）——五条规则约束 orch 及每个被派发的角色。本仓库的"小步快跑"成为了其中第 5 条；其余四条随它一起到来。仅本地的仪式：门禁全绿**且** `/closeout` 完成后，一个 chunk 才算"落地"——然后 `git push`，等待下一条指令。

## §3 门禁顺序（派发前置条件）

- 任何 DE 新功能卡派发前，其 design-prompt 必须先通过 rev 门禁（行为泄漏检查）。
- 任何 bug 卡派发前，bugs.md 对应行必须已存在（不允许口头派发）。
- 任何里程碑关闭前，`make signoff-check` 的机器条件与 rev 签核记录（`doc/evidence/v*/signoff-M<n>.md`）二者缺一不可。

## §4 环境

- 仿真运行在 VM 中（Ubuntu 22.04，VCS/Verdi O-2018）。已知工具变通方案见 `scripts/make/vcs-2018.mk` 头部。xverif 工具体系（`xdebug`/`xcov`/`xsva`/`xloc`）不在 PATH 上：入口为 `$XVERIF_ROOT/tools/`（默认 `/home/open_tools/xverif`，由 `scripts/make/vcs-2018.mk` 导出）；需先 `export VERDI_HOME`；用 `test -x $XVERIF_ROOT/tools/xcov` 探测，绝不用 `command -v`。
- **优先用 xverif 取事实，而非纯模型推理/手算**：DV/REV 但凡涉及失配定位、覆盖率核对、日志位置还原、bit/SV 字面量或表达式计算，应先用 xverif 工具体系做确定性查询，不自行心算/猜测——它专为 EDA 产物设计，接入方式含交互式 MCP 工具（`xverif` skill）与脚本化 SDK-free wrapper 两种；它覆盖了：
    - `xdebug`：daidir/FSDB 事实、RTL 因果；
    - `xcov`：VCS/Verdi coverage database；
    - `xbit`：确定性 bit/SV 字面量/表达式计算，代替手算；
    - `xloc`：还原压缩日志位置 ID；
    - `xentry`：entry/descriptor 片段解码；
    - `xsva`：SVA IR 解析；
    - `xeda-runner`：安全执行 EDA 命令。
- **边界不变**：以上只是观测"实际发生了什么"/做确定性计算的手段；checker 的**期望值**仍只准从 `doc/spec.md` 推导——xdebug/xcov 看到的波形/覆盖事实不得直接抄成期望值（spec-from-RTL 红线不变，dv 角色 Input boundary 照旧）。
- 本仓库在宿主机上开发，克隆进 VM 中运行；换行符由 `.gitattributes` 锁定——不要与它对抗。
- VCS-2018.09-SP2 拒绝 `bind <interface> <module>`（`Error-[IIM]`）——挂接协议/时序 SVA 一律走宿主模块（`tb_top` 等）generate 循环内直接例化，见 `doc/design-prompt/sva_bind.md` C1.1、`doc/review/REV-003.md`。

## §5 Git

- Conventional commits。Evidence 与它所证明的代码落在同一个 commit 里。closeout 后 push。
- Hooks：每次 clone 后执行一次 `git config core.hooksPath .githooks`。
- `scripts/`、`workflow/`、`.claude/skills/` 是 hash 锁定的框架快照（`make fw-check`）；`.claude/agents/` 每次 pull 都会重新生成。改进请先流向框架仓库：<https://github.com/AArlert/iverif-workflow>

## §6 项目专属

- **DUT**：pulp-platform/axi v0.39.9 的 `axi_xbar`（AXI4+ATOP 全连接 crossbar：每 slave 端口一个 `axi_demux` × 每 master 端口一个 `axi_mux`）。只读 vendor 快照于 `vendor/`，SHA 锁定见 `vendor/VENDOR.md`。本仓库**无 `rtl/`**：DE 卡仅用于 vendor 工具兼容补丁（P-xxx 登记 + rev 评审）；疑似 DUT 行为错误一律走 DUT_BUG 失败记录 + 上游 issue，绝不本地改行为。
- **spec 来源清单**（arch 蒸馏 `doc/spec.md` 的唯一许可来源）：  `vendor/axi/doc/axi_xbar.md`（+ `axi_demux.md`、`axi_mux.md`）、  `vendor/axi/src/axi_pkg.sv`（`xbar_cfg_t`/`xbar_latency_e`/`xbar_rule_*_t`）、`vendor/axi/src/axi_xbar.sv` 头注释。仅有 RTL 来源的条款须标注"（来源：RTL——上游文档未载）"。
- **DV 唯一可读参数定义文件**：`vendor/axi/src/axi_pkg.sv`。
- **flist 布局**：`sim/flist/vendor.f`（tech_cells_generic → common_cells → common_verification，Bender 序）/ `dut.f`（axi 全库，  `axi_pkg.sv` 起）/ `tb_upstream.f`（上游 tb_axi_xbar，M0 sanity）/`tb.f`（M1+ UVM env）。仿真入口 `sim/Makefile`（VCS-MX O-2018，license 覆盖值 `27000@icarray-virtual-machine`）。
- **tb 架构（M1+ 草图）**：`tb_top` 例化单 `axi_xbar` + N 主 M 从接口；UVM env = 多 master agent + 多 slave agent + 由 spec 推导的地址路由
  参考模型记分板；协议/时序 SVA 在 `tb/sva/` 经 `bind` 挂接。基线配置取上游 tb 默认（6 主 × 8 从），多配置矩阵见 spec §0。
- **里程碑**（版本 0.M.P）：M0 基建+sanity+spec v0 → M1 UVM env+smoke（并评估 v0.39.10 升级）→ M2 功能场景+SVA+功能覆盖 → M3 多配置回归+
  错误路径 → M4 六类覆盖 ≥90% 收敛 → v1.0.0。
- **文档语言**：表头/机制英文（`columns_preset=en`），spec/log/testplan 描述等正文中文（与人工学习仓库 `pulp_axi_xbar` 的阅读习惯一致）。
- **框架反馈**：任何 iverif-workflow 摩擦当场登记 `doc/fw-feedback.md`，回流节奏与仪式见该文件头注；本仓库是框架首次实战应用，回馈是硬性交付物之一。
