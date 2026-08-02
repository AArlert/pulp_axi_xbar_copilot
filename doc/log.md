# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.5.2] 2026-08-03 文档漂移扫描:四份 agent 卡死引用 failure_taxonomy.md 顺手修

**Done**
- 用户要求「检查有没有文档漂移」——扫了 `make check` 机械门覆盖不到的手工
  引用面:docsx 残留字符串(全部是合法的冻结历史记录/FB-39/FB-40 主动指针,
  非漂移)、`.claude/agents/*.md` 与 `workflow/*.md`/CLAUDE.md/`.claude/skills/`
  的路径引用存在性。
- 找到一处真漂移:`.claude/agents/{arch,de,dv,rev}.md` 四份文件的
  "Taxonomy-class anomaly" 报告字段仍写 `` `failure_taxonomy.md` ``——该文件
  在 0.8.0 目录合并时并入 `workflow/bugs.md`,FB-35 当时修过 rev.md/dv.md 的
  其他几处旧路径,唯独漏了这一处四文件共有的提及。按新裁决(0.5.1 落地的
  两档制)属**顺手修**:未使任何已记录的绿翻红,当场改指
  `` `workflow/bugs.md`'s five classes ``,零登记。
- CLAUDE.md/workflow/*.md 的另几处路径疑似命中(`axi_demux.md`、
  `axi_pkg.sv`、`DESIGN.md` 等)核实为假阳性(共享目录前缀的散文省略 / 标注
  canon-only 的框架仓文件),未改动。

**Not done**
- M5 启动前置仍未动:L3 rev 卡(vm.md 决策点 2-4 + M5 出口条件即代码)。

**Next**
- 派 L3 rev 卡:vm.md 决策点 + M5 出口条件逐条机器可判化。

**How verified**
- `make check` 退出码 0;`make selftest` 102/102 OK。
- 四处改动仅涉及散文措辞(路径指向 + classes 复数语法订正),不改变任何
  agent 行为契约,人工通读确认句意通顺。

## [0.5.1] 2026-08-03 M4 复盘剃刀:文档缺陷两档制 + docsx.py 溶解回单脚本

**Done**
- **M4 复盘裁决落地**(用户批准的 plan;量化依据与完整裁决见 FB-39):M4
  功能封板后的收尾期几乎全部 token 耗在记账体系自身缺陷上,故:①文档/记账
  缺陷降出验证 bug 全重链——默认**顺手修**,唯一例外「修复需把已记录的绿翻
  红」才登记(`suspect=doc` 一行 + L0 卡,closer=机器门禁);②散文禁抄可
  推导事实(`workflow/records.md` 新契约);③ CLAUDE.md 不变量 3 限定、§2
  适用域、§5「上游」改双向回流。
- **docsx.py 溶解回 docs.py**(TOOL-M5-B 卡,sonnet;完整清单见 FB-40):
  先砍后并——F1/F3/F7/F10 四族 + §12 执行器退役(检查对象已被②消灭),
  幸存 F2/F4/F5/泄漏检查并入 `docs.py --check`,`make check` 收敛为单入口;
  `--guards` 输出契约逐字保持;删 `scripts/docsx.py`/`test_docsx.py`/
  `doc/docsx-baseline.md`(baseline 存量四类处置:FB-1~27 旧行整体搬
  `doc/archive/fw-feedback-archive.md`、真死引用就地修、示例路径改占位、
  ≤5 处行内豁免标记)。
- 必读面字节预算一度超限:未抬阈,压缩 rationale 散文回到预算内(G-0068)。

**Not done**
- M5 启动前置未动:vm.md 决策点 2-4 过 rev + M5 出口条件即代码(plan 步 2,
  合并为一张 L3 rev 卡)。
- ACCEPTED@M5 三条 spec 缺口(BUG-0044/0045/0046)+ BUG-0047 覆盖口径的
  arch 卡未派(plan 步 3)。
- BUG-0073(make 嵌套 banner 污染)fixer 未派。

**Next**
- L3 rev 卡:vm.md 决策点 + M5 出口条件逐条机器可判化接入
  `make check MILESTONE=5`,判断类条目显式入 spot-check 清单。
- 通过后派 arch 卡消化 spec 缺口,再开 M5 首张功能卡。

**How verified**
- `make check` 单入口退出码 0;`make selftest` 全绿(用例数见 selftest 输出;
  迁移前后对照记录在 FB-40/交付报告)。
- 幸存族注伤自证(kill_proof 替代形态):死路径/孤儿详情页/`</invoke>` 泄漏
  三者植入各自变红、复原变绿(B 卡交付报告 §4)。
- `suspect=doc` 三条红/绿用例入 `test_docs.py::TestSuspectDoc`。
- 定级 vs 实际:B 卡定 L1,实际工作量偏 L2(触及 19 文件),风险面仍工具层
  ——失配记录于此。

## [0.5.0] 2026-08-03 M4 签核 APPROVED 关门 + 文档体系机械化整轮，进 M5

**Done**
- **M4 APPROVED 关门**（REV-039，推翻旧 v0.4.13 REJECTED——旧「六类≥90%」口径随 0.4.37 里程碑重构作废）。`make check MILESTONE=4` 四条机器条件全 PASS，新口径出口（覆盖测量基建 + 全闭包三态扫描 + 每格具名归属 UNOWNED=∅ + KILL 覆盖）全部满足。
- **文档体系机械化落地**（本轮主线，回应用户「管住文档膨胀与数据漂移」）：新建 `scripts/docsx.py`（project-owned）七族检查——F1 数字断言（含元检查：复现命令自身须可执行非空，源自 FB-23 自带伪造复现命令的教训）/ F2 仓内路径存在性 / F3 双向集合 / F4 `doc/guards.md` 单表 / F5 孤儿双向 / F7 枚举快照(warning) / F10 存量 baseline；§12 词法执行器（allowlist + 拒命令替换 + 秒级超时 + cwd 锁根）。接 `make check` + `.githooks/pre-commit` 双门禁。selftest 72→143。
- **22 条 bug 全部 terminal**：BUG-0052~0069（REV-037 批量裁决面十六条）+ 期间新登 0070~0073，经 docsx 各族 fixer（卡2a/2b/2c/2g）+ 散文订正（2d）+ 独立族 closer（2e）批量关闭 + 签核裁（0070/0071 CLOSED、0073 ACCEPTED@M5）。P0 先拆两颗实雷（0066/0056：`regress.py` 默认不再摧毁覆盖库）。
- **guard 载体迁移**：49 页详情页 `## regression_guard` 段迁 `doc/guards.md` 单表（族级 guard 载体，满足 REV-035 §Q5）；BUG-0061 中文标点污染 paths 清 ASCII、恢复 3 处真丢失路径。

**Not done**
- **BUG-0073 ACCEPTED@M5**：make 嵌套调用 banner 污染 `tail` 的证据工具隐患，M5 排 fixer（可证伪解锁=evidence.py 清 MAKEFLAGS 后该形态转 PASS）。
- **轻量化 P5 未做**：review 常驻轮转留 3 份、evidence 叙事归档、字节棘轮——移 M5 期间穿插（常驻语料仍约 2.7MB，机制已建、批量搬运待做）。
- **vm.md 决策点 2-4 未过 rev**：M5 启动前置（约束随机/多种子回归/soak 三决策点仍「提案草案」），是下一步。

**Next**
- 派 rev 评审卡：`doc/design-prompt/verification_maturity.md` 决策点 2/3/4 过门（M5 三支柱架构输入）。通过后 orch 应用批注、更新 vm.md 抬头状态。
- 首批 M5 场景行随第一张 M5 DV 卡登记（登记先于编码，records 契约）。
- P5 轻量化搬运 M5 期间穿插；BUG-0073 M5 fixer。

**How verified**
- `make check MILESTONE=4` 四条全 PASS + `signoff-M4.md` 判词 APPROVED（本 closeout 亲跑）。
- docs+docsx 双门禁绿；`make selftest` 143 OK；KILL-0004~0007 覆盖功能 oracle + docsx 执行器。
- 机械化三则自证（机制真在干活）：pre-commit F2 拦下 orch 自己写入的死路径字面量 · BUG-0072 执行器引号内命令替换逃逸被 fixer 主动实测暴露并堵死（KILL-0007）· F10 反向 prune 在 BUG-0052 归档后自动删除其 stale baseline 行。
- 回源纪律三向兑现：下游拦上游（2d 拦 REV-037 台账 S 失实）、拦卡面（2c 拦「解析判词」误导）、拦机制自身（0072）。逐卡 fixer→独立 closer 两次派发，orch 收卡一律走集合差完备性核对。


