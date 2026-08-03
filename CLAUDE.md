# pulp_axi_xbar_copilot — CLAUDE.md

**项目现状**：这是一个接手的验证项目。前任团队为 `axi_xbar` 搭好了 UVM tb、
写完 M0–M4（smoke → 功能场景 → 多配置回归 → 覆盖测量），随后离开；他们的
流程仪式很重，0.5.4 重置时已整体拆除（现场锁在 tag `v0.5.3-pre-reset`，
git 即历史）。我们轻装继续：M5 约束随机，M6 覆盖率收敛（`doc/milestone.md`）。
信任 agent 的判断；机械脚本只负责替 agent 免除手抄手搬。

## 两条红线（不可让）

1. **testplan 翻绿只能经 `make evidence`**——脚本从真实仿真 log 提取摘录、
   回填状态；手改状态列无效。失败 log 绝不登记为证据。
2. **checker/SVA 的期望值只准从 `doc/spec.md` 推导**，绝不来自被测 RTL。
   波形/覆盖率是观测事实，可以看，不得抄成期望值。spec 有缺口 → 登记
   bug（SPEC_ISSUE）→ 补 spec 条款 → 再写 checker。

## 工作习惯

- **失败可追溯**：任何失败要能凭 testplan/bugs 里记录的一条命令
  （`make run TEST=<t> SEED=<n>`）稳定复现。M5 第一张活就是把失败报告做成
  自包含（seed + 操作轨迹 + DUT/期望/spec 三方文本），见 `doc/milestone.md`。
- **失败无条件登记** `doc/bugs.md`（五类分诊速查在该文件头部），不因已绕过
  而豁免。文档笔误顺手修，零登记。
- **rev 评审**（`.claude/agents/rev.md`，只读分析）用在三处：spec 条款
  变更、checker/oracle 设计评审、里程碑收口。其余工作 orch 直接做，需要
  并行或隔离视角时派普通 subagent。
- 想清再动手；最小实现；一个闭环 → push → 停，不连轴推进。

## 工作循环

```
make handoff             # 会话开始：读状态（绝不从聊天历史重推）
make next                # 机械推导的下一步
<干活：写 tb / 跑仿真 / 修 bug>
make evidence SCEN=<id> TEST=<t> SEED=<n>   # 场景翻绿（只认 PASS）
make check               # 提交前门禁（pre-commit 也跑它）
make bump && 填 log/status && make commit && git push
```

`make archive` 滚动记忆文件（log/status/bugs 超限时自动搬入 doc/archive/）。

## 环境

- 仿真在 VM（Ubuntu 22.04，VCS/Verdi O-2018）；宿主机开发、克隆进 VM 跑。
  变通汇总见 `scripts/make/vcs-2018.mk` 头注。换行符由 `.gitattributes`
  锁定，不要与它对抗。
- VCS-2018 拒绝 `bind <interface> <module>`（`Error-[IIM]`）——SVA 一律在
  `tb_top` generate 循环内直接例化，来龙去脉见 `doc/uvm.md` §3。
- **xverif 工具体系**（xdebug/xcov/xbit/xloc/xsva 等）不在 PATH：入口
  `$XVERIF_ROOT/tools/`（默认 `/home/open_tools/xverif`，由 `vcs-2018.mk`
  导出）；需先 `export VERDI_HOME`；用 `test -x $XVERIF_ROOT/tools/xcov`
  探测，**绝不用 `command -v`**。优先用它取事实（失配定位、覆盖率核对、
  bit 计算），而非心算——但期望值仍只准从 spec 推导（红线 2）。
- 每次 clone 后一条一次性设置：`git config core.hooksPath .githooks`。
- Conventional commits；证据与它所证明的代码落同一 commit；`make commit`
  只到本地，push 是显式动作。

## 项目专属

- **DUT**：pulp-platform/axi v0.39.9 的 `axi_xbar`（AXI4+ATOP 全连接
  crossbar）。只读 vendor 快照于 `vendor/`（SHA 见 `vendor/VENDOR.md`）；
  本仓库无 rtl/，疑似 DUT 行为错误走 DUT_BUG + 上游 issue，绝不本地改行为。
- **spec 的许可来源**（`doc/spec.md` 蒸馏自）：`vendor/axi/doc/axi_xbar.md`
  （+ demux/mux.md）、`axi_pkg.sv` 定义段、`axi_xbar.sv` 头注释。仅有 RTL
  来源的条款标注"（来源：RTL——上游文档未载）"。
- **核心文档**：`doc/spec.md`（判据唯一来源）· `doc/testplan.md`（场景真值
  表）· `doc/axi.md` / `doc/uvm.md`（给人的读物：被测对象 / 验证环境）·
  `doc/feature-matrix.md` · `doc/milestone.md`。testplan/老文档里指向
  `doc/evidence|review|...` 的旧路径是重置前产物，用
  `git show v0.5.3-pre-reset:<path>` 查阅。
- **tb 架构**：`tb_top` 例化单 `axi_xbar` + N 主 M 从接口；UVM env = 多
  master agent + 多 slave agent + spec 推导的地址路由参考模型记分板；SVA 在
  `tb/sva/`。基线 6 主 × 8 从，配置矩阵见 spec §0。
- **flist**：`sim/flist/{vendor,dut,tb_upstream,tb}.f`（Bender 序）；仿真
  入口 `sim/Makefile`（license 覆盖值 `27000@icarray-virtual-machine`）。
- **文档语言**：表头/机制英文，正文中文。
