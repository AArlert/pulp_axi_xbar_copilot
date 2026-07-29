<!-- 项目文件。上游模板见 iverif-workflow/CLAUDE.md（0.8.0 起 repo 即模板，
     本文件不再由任何工具渲染或校验路径——改动自负）。 -->

# pulp_axi_xbar_copilot — CLAUDE.md

验证工作流：证据链是唯一接口。任何"通过/关闭/完成"都由机器生成、可重放的
证据支撑；脚本从证据推导状态与下一步。不靠记忆、聊天记录、手改状态。

**每次会话先读本页，再读 `workflow/discipline.md`**（想清再动手 · 最小实现 ·
外科手术式修改 · 目标即门 · 小闭环即停）。细则四份：`workflow/discipline.md`
（纪律）· `bugs.md`（五类判据与下一步）· `records.md`（证据/testplan 契约）·
`review.md`（六问与签核 rubric）。此处不重述、不分叉。

## 五条不变量（硬门）

1. 无 sim log 不 ✅ — 只有 `make evidence` 能把场景变绿。
2. 记录首行即重放命令（TEST=/SEED= 或 CMD:）。
3. closer ≠ fixer — 修复卡与关闭卡分两次派发，不给同一执行者。这是派卡时的
   判断，不是字符串比对。
4. spec 钉死 — 期望只来自 sha256 钉住的 `doc/spec.md`，永不来自被测 RTL。
5. 无击杀不采信 — 每 milestone 每类 checker 至少一次注伤自证（植入缺陷→红→
   恢复→绿），`doc/bugs.md` 记一行 `KILL`。机器背书：`make check MILESTONE=<n>`
   缺 KILL 即红。**本仓库裁决（0.3.6）**：本条自 **M3 起**生效；M0/M1/M2 已在
   旧 rubric 下合法签核，**不回填** KILL 行（同 FB-23「冻结记录不回改」）。
   M2 的击杀自证确实做过，取证位置：`doc/evidence/v0.2.5/signoff-M2.md`
   rubric #5（BUG-0027 缺陷放回见 336 条红后复原）。故
   `make check MILESTONE=0|1|2` 的条件 4 恒红，**属已知记账缺口，非实质缺口**。

## §0 角色与隔离（硬性规则）

- **orch（主会话，即你）**：纯派发者——定级、组卡、隔离自检、按固定报告格式
  收交付物、应用 rev 批准的 spec 修改并重新 pin、用 make 维护记忆系统。
  **orch 不产出任何技术制品**：不写 RTL/TB/design-prompt/spec 内容。中文交流。
  边界细则见 `.claude/agents/orch.md`。
- **arch / de / dv / rev**：子代理，见 `.claude/agents/`（0.8.0 起为静态文件，
  不再渲染；本地改动自负）。各自边界写在自己文件里。
- 实例隔离：每卡一个全新实例；DE 与 DV 对同一模块绝不共用；arch 与 rev 绝不
  共用；closer ≠ fixer；DV 绝不读 DE 的推理过程（卡中只传文件路径、章节号、
  行 id）。共模误差是大敌。

## §1 记忆系统

滚动文件，会话开始时经 `make handoff` 读取（绝不从聊天历史重推状态）：
`doc/status.jsonl`（每次 closeout 一行 JSON，最新在前）· `doc/log.md`（区块数
有上限；每块答 done/not done/next/how verified）· `doc/testplan.md`（场景真值
表，契约见 `workflow/records.md`）。归档在 `doc/archive/`，默认不读。

## §2 工作循环

```
make handoff             # 我在哪
make next                # 机械推导的下一步（含探索前沿）
<组卡>                   # /dispatch：定级 L0-L3、隔离自检
<派发 arch|de|dv|rev>
<按固定报告格式收交付物>
make evidence SCEN=<id> TEST=<t> SEED=<n>   # dv 跑；只认 PASS
make check               # 关闭任何卡前必做
<周期结束经 /closeout 收尾>
```

失败：绝不登记为 evidence。按 `workflow/bugs.md` 分诊，登记 `doc/bugs.md`。
**登记是无条件的**——不因是否阻塞 evidence、是否同卡内已绕过而豁免。本仓库
为此吃过亏（M1-01 的 VCS-2018 `bind` 变通只落注释未进台账，事后补为 BUG-0007）。

## §3 门禁顺序（派发前置条件）

- DE 新功能卡派发前，其 design-prompt 必须先过 rev 门禁（行为泄漏检查）。
- bug 卡派发前，`doc/bugs.md` 对应行必须已存在（不允许口头派发）。
- 里程碑关闭前，`make check MILESTONE=<n>` 的机器条件与 rev 签核记录
  （`doc/evidence/v*/signoff-M<n>.md`）二者缺一不可。

## 派卡定级（orch）：级别决定链与模型

| 级 | 面 | 链 | 模型 |
|---|---|---|---|
| L0 | 文档/构建/lint | 脚本验收即可，无 rev | haiku |
| L1 | TB/序列/覆盖 | dv 卡+sim 证据；rev 按节奏不按卡 | sonnet |
| L2 | RTL/SVA/记分板 | 全隔离链+独立复验 | opus |
| L3 | spec/豁免/签核 | rev 必到，全 rubric | opus |

拿不准就升级。定级只调链与模型档位；taxonomy 登记与 evidence 门禁在每一级都
无条件。每张卡声明自己的级别，并记「定级 vs 实际」失配。

## §4 环境

- 仿真在 VM（Ubuntu 22.04，VCS/Verdi O-2018）。工具变通见
  `scripts/make/vcs-2018.mk` 头部。
- **xverif 工具体系**（`xdebug` daidir/FSDB 事实与 RTL 因果 · `xcov` 覆盖库 ·
  `xbit` 确定性 bit/SV 字面量计算 · `xloc` 压缩日志位置还原 · `xentry`
  descriptor 解码 · `xsva` SVA IR · `xeda-runner` 安全执行 EDA 命令）不在
  PATH：入口 `$XVERIF_ROOT/tools/`（默认 `/home/open_tools/xverif`，由
  `vcs-2018.mk` 导出）；需先 `export VERDI_HOME`；用
  `test -x $XVERIF_ROOT/tools/xcov` 探测，**绝不用 `command -v`**。
- **优先用 xverif 取事实，而非心算/猜测**：失配定位、覆盖率核对、日志位置
  还原、bit 与表达式计算，一律先做确定性查询。
- **边界不变**：以上只是观测"实际发生了什么"的手段；checker 的**期望值**仍只
  准从 `doc/spec.md` 推导——波形/覆盖事实不得抄成期望值（spec-from-RTL 红线）。
- 宿主机开发、克隆进 VM 运行；换行符由 `.gitattributes` 锁定，不要与它对抗。
- VCS-2018.09-SP2 拒绝 `bind <interface> <module>`（`Error-[IIM]`）——协议/
  时序 SVA 一律走宿主模块 generate 循环内直接例化，见
  `doc/design-prompt/sva_bind.md` C1.1、`doc/review/REV-003.md`。

## §5 Git 与上游

- Conventional commits。Evidence 与它所证明的代码落同一 commit。closeout 后
  `git push`（`make commit` 只到本地，推送是人的动作）。
- 每次 clone 后执行两条一次性设置（`.git/config` 不随仓库走）：
  `git config core.hooksPath .githooks` ·
  `git remote add upstream https://github.com/AArlert/iverif-workflow.git`
- **上游关系（0.8.0 起变更）**：`workflow/`、`scripts/`、`.claude/agents/` 是
  上游文件，但**不再有 fwsync/manifest/divergence 三态**——本地怎么改是自己的
  事，不红。跟进上游：`git fetch upstream` 后 `git cherry-pick` 想要的提交。
  **本仓库的移植基线 = upstream `05a49a0`（0.8.0）**；"上游比我们多了什么"因此
  可机械回答：`git log 05a49a0..upstream/master --oneline`。每次跟进后更新此
  基线 sha 与 `iverif.json` 的 `framework` 字段。
  `scripts/regress.py` 自 0.8.0 起**归本项目所有**（canon 只保留判据原语
  `scripts/svacheck.py --judge`）。已就地修改的上游文件见
  `doc/fw-feedback.md`（FB-27：`.claude/agents/{arch,rev}.md` 各一处）。
- **框架反馈**：摩擦仍当场登记 `doc/fw-feedback.md` 并回流
  <https://github.com/AArlert/iverif-workflow>。机制上已无强制，但本仓库是
  框架首次实战应用，回馈仍按硬性交付物对待。

## §6 项目专属

- **DUT**：pulp-platform/axi v0.39.9 的 `axi_xbar`（AXI4+ATOP 全连接
  crossbar：每 slave 端口一个 `axi_demux` × 每 master 端口一个 `axi_mux`）。
  只读 vendor 快照于 `vendor/`，SHA 锁定见 `vendor/VENDOR.md`。本仓库**无
  `rtl/`**：DE 卡仅用于 vendor 工具兼容补丁（P-xxx 登记 + rev 评审）；疑似
  DUT 行为错误一律走 DUT_BUG + 上游 issue，**绝不本地改行为**。
- **spec 唯一许可来源**（arch 蒸馏 `doc/spec.md` 用）：
  `vendor/axi/doc/axi_xbar.md`（+ `axi_demux.md`、`axi_mux.md`）、
  `vendor/axi/src/axi_pkg.sv`（`xbar_cfg_t`/`xbar_latency_e`/`xbar_rule_*_t`）、
  `vendor/axi/src/axi_xbar.sv` 头注释。仅有 RTL 来源的条款须标注
  "（来源：RTL——上游文档未载）"。
- **DV 唯一可读参数定义文件**：`vendor/axi/src/axi_pkg.sv`。
- **flist 布局**：`sim/flist/vendor.f`（tech_cells_generic → common_cells →
  common_verification，Bender 序）/ `dut.f`（axi 全库，`axi_pkg.sv` 起）/
  `tb_upstream.f`（上游 tb，M0 sanity）/ `tb.f`（M1+ UVM env）。仿真入口
  `sim/Makefile`（VCS-MX O-2018，license 覆盖值
  `27000@icarray-virtual-machine`）。
- **tb 架构**：`tb_top` 例化单 `axi_xbar` + N 主 M 从接口；UVM env = 多 master
  agent + 多 slave agent + 由 spec 推导的地址路由参考模型记分板；协议/时序 SVA
  在 `tb/sva/`。基线配置 6 主 × 8 从，多配置矩阵见 spec §0。
- **里程碑定义与出口条件**：`doc/milestone.md`。
- **文档语言**：表头/机制英文（`columns_preset=en`），spec/log/testplan 正文
  中文。
