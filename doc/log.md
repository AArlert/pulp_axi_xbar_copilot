# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.5.3] 2026-08-03 M4 遗留四条债务清空:0073 修+关、0045/0046 合并入 spec §3.2、0044 记录

**Done**
- **BUG-0073（TOOL_ENV）修复并关闭**。根因:`scripts/evidence.py` 的 `--cmd`
  分支起 `subprocess.run(shell=True)` 时未清 `MAKEFLAGS`/`MAKELEVEL`/`MFLAGS`,
  该子进程是 `make evidence` recipe 的子进程,CMD 内嵌套的 `make <target>` 据此
  误判自己是子 make、打印 GNU Make 的进入/离开目录横幅,且"离开目录"行落在最后
  ——污染任何按位置摘取(`tail -N`)的证据签名。修法:`os.environ.copy()` 后 pop
  掉这三个变量再传 `env=`,只清这三个、不动其余(commit `89002ab`)。fixer 与
  closer 两次独立派发(closer≠fixer),closer 用两份隔离 worktree(修复前父提交
  vs 修复后)跑同一条 CMD 对照,确认转绿,并为该行本身生成真实证据
  `doc/evidence/v0.5.2/BUG-0073.log`(commit `82d522e`)。登记 FB-41。
- **BUG-0045 + BUG-0046 合并终结为 SPEC_CHANGED**——`doc/spec.md` §3.2 新增
  clause 3(终址哨兵 `end_addr=='0'` ⇒ 等效终址 `2^AxiAddrWidth`,非零长度区间)
  与 clause 4(实现侧区间非空约束 + DV 地址表环境约束 `start<effective_end`),
  spec Change record #13,已重 pin。**合并的技术依据**:`addr_decode_dync` 的
  `check_start`(`start_addr < end_addr || end_addr=='0'`)把哨兵解码后等价于
  **单一**严格判据 `start_addr < effective_end`(`start_addr` 为 `AxiAddrWidth`
  位,恒 `< 2^AxiAddrWidth`),故 `|| end_addr=='0'` **不是**"豁免分支"、而是同
  一条严格 `<` 在哨兵编码下的写法;BUG-0046 所称"RTL 禁止 `start==end`"必须以
  BUG-0045 的哨兵为前提才能准确陈述(`start==end=='0'` 合法且覆盖全地址空间,
  `start==end!='0'` 才非法)⇒ 两条是同一条区间契约的主干与编码约定,不可分。
  clause 2 的权威 `<=` **一字未改**(spec 仍站 `axi_xbar.md` L26 一侧,未反向
  对齐 RTL)。G-0045/G-0046 两条 guard 已从"M5 到期须再裁决"改写为守卫落地态。
- **BUG-0044 记录已核实事实,维持 ACCEPTED@M5**(用户指示先不展开,留给 M5 构造
  场景时做):三问查清并写入详情页 `## orch investigation note`——(1) 上游许可
  来源三份文档对 atomicstore/swap/compare 应答义务**全部沉默**,只有
  `axi_pkg.sv` 387-415 注释有定义,而该文件的许可范围按 CLAUDE.md §6 只覆盖
  `xbar_cfg_t` 等类型定义、不含这段 ATOP 语义;(2) DUT **会**走到这三类——
  `axi_demux_simple.sv:162/185` 的 AR 注入判据只看 `atop[ATOP_R_RESP]`(第 5
  位),该位对 load/swap/compare 均为 1、仅 store 为 0,是通用机制而非
  atomic-load 特判;(3) TB 目前**不会**——M5 决策点 2 已把 `atop` 随机空间硬限
  在 `{'0} ∪ 合法 atomic-load 编码`。
- 3 条终态行经 `make docs-archive` 轮转出主表(BUG-0073/0045/0046)。

**Not done**
- **refmodel 哨兵分支故意未实现**——`tb/xbar_types_pkg.sv` 的 `decode_mst_port`
  仍只做半开区间比较,不认 `end_addr=='0'`。这是尊重 REV-021"不实现即无不可
  证伪死代码"的反对(该反对在 refmodel 半边成立、在 spec 半边不成立,因为本项目
  本就容忍 spec 条款跑在场景前面)。约束写进 G-0045:未来构造该类地址表时,
  testplan 行 + refmodel 分支 + 判决锚必须同批落地。
- BUG-0044 的补全三件套(spec §6 条款 + 定向场景 + refmodel oracle)未做。
- M5 场景探索本身未开始(本轮目标就是把 M4 遗留债务清干净再进 M5)。

**Next**
- M5 场景探索:`make explore` → arch spec-gap 卡(M5 尚无场景行,且 7 个 spec
  小节无场景引用)。
- 仍挂账:L3 rev 卡(vm.md 决策点 + M5 出口条件即代码)。

**How verified**
- `make check` 退出码 0(`docs-check passed`;4 类 `[gap]` 为既有信息性缺口,
  与上一版逐项相同,无新增)。`make selftest` 102/102 OK。
- BUG-0073:修复前后对照见上;closer 独立复验未读 fixer 草稿(scratchpad 分子
  目录隔离)。
- spec 改动:`python3 scripts/docs.py --pin-spec` 重 pin 通过(sha
  `c8279a87…`),Change record #13 已录,spec 变更门禁(改动须配变更记录+重 pin)
  绿。
- guard 面未失守:`make guards FILES="doc/spec.md"` 仍命中 5 条,含改写后的
  G-0045/G-0046。
- 上游活跃度为一手核验(非推测):`addr_decode_dync.sv` 自 2023-09-26 引入
  (common_cells PR #198)至今日 master(已随 PR #290 更名
  `cc_addr_decode_dync.sv`)`check_start` 逻辑一字未改;`axi_xbar.md` 的 `<=`
  措辞同样未变;两仓 issue/PR 无人跟踪此不一致。vendored 副本与 pin 的 SHA
  `9ca8a765` 逐字节相同(`diff` 确认)。

**流程偏离(留痕)**
- CLAUDE.md §0 规定 orch 不产出技术制品、spec 改动按定级表属 L3(arch 起草 →
  rev 门禁 → orch 应用并重 pin)。本轮 §3.2 clause 3/4 由 **orch 直接撰写**,
  未派 arch/rev 卡——用户在会话中明确指示"既然已经明白了设计意图,spec 标注
  即可,你做了就行"。风险自评:本次是对**已由双方独立核实的上游既定事实**做
  记录性标注,未引入任何新的期望值推导;clause 2 权威口径未动,spec-from-RTL
  红线未破;refmodel 未动,故无 checker 期望值受影响。若日后 rev 认为该 clause
  措辞需订正,按常规 spec 修订流程重开即可。
- 同时用户指示放宽 closer≠fixer 的执行成本:凡"跑一条命令/一次仿真即可判定"
  的复验,由 orch 自己跑或派 haiku 跑并汇报,不再派 sonnet/opus 独立实例。本轮
  BUG-0073 的 closer 卡是在该指示**之前**派的,故仍走了完整独立实例。

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

