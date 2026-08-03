# Work log

滚动工作日志（最新在前，块数超限经 `make archive` 滚入 `doc/archive/`）。
每块回答四问：done / not done / next / how verified。0.5.4 之前的历史
见 `git show v0.5.3-pre-reset:doc/log.md` 及其归档。

## [0.5.4] 2026-08-03 大重置：拆除仪式层，以接手者姿态进入 M5

**Done**
- 用户裁决执行：文档/流程仪式整体拆除（doc 从 3.6MB/234 文件砍到核心集）。
  删：`workflow/` 四细则、`doc/review`（1.1M）、`doc/evidence` 存档（828K）、
  `doc/archive` 旧内容、终态 bug 单页（仅留 BUG-0044）、`doc/design-prompt`
  （干货已蒸馏进 `doc/uvm.md`/`doc/milestone.md`）、guards/fw-feedback/
  code-suggestion、arch/de/dv 三个 agent、全部 skills、`scripts/tests` 60 单测。
  现场先锁 `git tag v0.5.3-pre-reset`。
- 机械层收编为单脚本：`scripts/docs.py`（handoff/next/check/archive/evidence/
  bump，evidence.py 与 bump.py 并入，无 cmd_ 前缀）；Makefile 同步收缩；
  `iverif_config.py` 瘦身（svacheck/regress 仍依赖）。
- spec 就地裁决（原 BUG-0074）：§4 clause 7 与 §8 clause 3 两条环境约束由
  "M3/M4"逐字作用域改为**里程碑无关**写法（随机层须编码进 constraint），
  Change record 表与 sha256 pin 机制删除（git 即历史）。
- CLAUDE.md 重写（接手叙事 + 两条红线）；bugs.md 重建（五类速查 + 总表，
  仅存 BUG-0044）；milestone.md M5/M6 重写（含约束设计蒸馏、6 行场景骨架、
  反稀释四条）；uvm.md/axi.md/README 清死链；记忆文件清零重开。

**Not done**
- M5 步 0（VM 内 `make regress` 确认接手基线全绿）——本机无 VCS，未跑。
- testplan 的 M5 六行场景尚未注册（等基线确认后落）。

**Next**
- VM 内 `make regress` 跑一遍确认基线绿；然后 M5 第一张活：失败可追溯机制
  （失败报告自包含 seed+轨迹+DUT/期望/spec 三方文本），见 milestone.md M5。

**How verified**
- `make check` 绿（瘦身版门禁）；`make handoff`/`make next` 输出正常；
  `python3 -m py_compile scripts/*.py` 全过；旧产物引用统一注记脚本跑过
  （testplan/axi.md/coverage-waivers/BUG-0044 四文件加注）；仿真未跑（见上）。
