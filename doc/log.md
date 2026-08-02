# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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


## [0.4.40] 2026-08-02 REV-037 批量裁决 14 条（14/14 判「修」）+ C1 全链闭合（BUG-0065/0055 CLOSED）——回源纪律在四个环节各拦下一处错误

**背景**：M4 出口条件 3 因 14 条 OPEN 恒红，签核卡无法派。本周期先用一张 rev
批量裁决卡把 14 条一次定终态并切出七张 fixer 卡的顺序，再跑通第一组（C1）的
`fixer → 独立 closer` 全链。每一环都强制"不得照抄上游结论、每个数字自己
回源"，**结果这条纪律在四个不同环节各拦下一处错误**——这是本周期最值得记的
部分，比关掉的两条 bug 更重要。

**Done**
- **REV-037（rev·L3）**：BUG-0052~0065 逐条终态 = **14/14 判「修」，零
  `ACCEPTED`，零 `WONTFIX`**。每条附处置面 + 可证伪复验签名 + fixer 类型 +
  分组。零接受的理由写在 §1 抬头：rubric #8 对"可证伪接受理由 + 到期条件"的
  要求是刻意昂贵的，本批每条订正成本都低于写一份站得住的接受理由；四条最接近
  可接受的（0057 半面 / 0059 / 0062 / 0064）在条目内写明被考虑过的接受论证及其
  败因，以免看起来像反射性盖章。切出七卡顺序 `C1 → C2 → C3a → C3b`，
  `C4/C5/C6` 并行。
- **C1 全链闭合**：BUG-0065（根 `Makefile` 加 `docs-archive: archive` 兼容
  别名，`scripts/docs.py` 零触碰）+ BUG-0055（删 19 条上游 tag、`.git/config`
  落 `tagOpt=--no-tags`、`CLAUDE.md` §5 两处命令订正）**双双 CLOSED**，
  证据 `doc/evidence/v0.4.39/BUG-{0065,0055}.log`。M4 条件 3 的 active
  由 17 降至 16。
- **tag 命名空间已净化**：本地 24 → 5 个 tag。归属判据为
  `merge-base --is-ancestor $(rev-parse "$t^{}")` 对 `master` /
  `upstream/master`，实测在 24 个 tag 上互斥且完备（5/19，both=0 neither=0）
  ⇒ 用判据分类而非人工名单。`git ls-remote --tags origin` 实测那 19 条从未推到
  origin ⇒ 删除是纯本地且可从 upstream 取回，非不可逆。
- **回源纪律的四次现场兑现**（本周期的主要产出）：
  1. **REV-037 推翻台账行内五处表述**——BUG-0052 死引用"4 处"实为 **7 处/4
     文件**（漏 `.claude/agents/dv.md:58`）· BUG-0055 称 `doc/milestone.md`
     规定 M4 关门须 `git tag v0.5.0`，实测**该文件从未规定 tag 动作** ·
     BUG-0056 称两份详情页 `ref:` 均含 `make clean`，实为 BUG-0048 的**已订正**
     且 `min_repro` 型 2 处**均已归档** · BUG-0057 称 scratchpad 目录不存在，
     实为**目录仍在**（判定不变、理由须换成"不在版本控制内"）· BUG-0061 称
     4 条 guard 受污染，实为 **16 个废 token/9 页、仅 3 页真丢失本意路径**。
     **即上一周期的缺陷登记本身就带错，5/14 的行内表述经不起回源。**
  2. **C1 fixer 拒绝在算术死角处静默取舍**——`CLAUDE.md` 天花板 9578
     （39500 − 其它四份 29922），基线 9570 ⇒ **余量仅 8 字节**，而三条强制
     操作性内容最省需 66 字节，无解。它删了 §5 末尾的 FB 快照枚举，并明确
     上报"这是卡面未授权的取舍，请复核"，未当默许吃掉。
  3. **C1 closer 拒绝照抄候选签名**——REV-037 给 BUG-0065 的候选是"看
     `make -n docs-archive` 退出码"。它审出该形态对一种真实退化是盲的：仅删
     规则体而保留 `.PHONY` 中的名字 → `exit 0` **假绿**；改为
     `diff <(make -n docs-archive) <(make -n archive)` 后同一注入判红。
     **照抄就会关掉一条其实没修好的 bug。**
  4. **closer 接住 orch 的一处记账缺陷**——BUG-0055 的〔勘误¹〕原指向
     `verify_evidence` 列，而 `evidence.py` 转 CLOSED 时机械覆写该列 ⇒ 勘误会被
     静默抹掉。已改为自包含并指向 `REV-037:204-215`。
- **新登记四条存量/机制缺陷**（登记无条件）：**BUG-0066** `scripts/regress.py:50`
  无条件 `make clean` → `rm -rf sim/out`，跑一次 `make regress` 即摧毁 7 个
  `cov.vdb` + `urgText6/`（危害面比 BUG-0056 大一个量级：不需照抄文档命令，而
  M4 条件 2 与 M5 出口都要求跑它）· **BUG-0067** 65 条 bug 行中 23 条无详情页，
  而 `regression_guard` 只存在于详情页 ⇒ 已 CLOSED 的 0049/0050/0051 三条**没有
  任何 guard 载体**；`docs.py` 孤儿检查单向 · **BUG-0068** `CLAUDE.md` 预算饱和
  （余量 +8 字节），且上游只设上限、**没设溢出时该删什么的判据** ·
  **BUG-0069** `make evidence` 的 `CMD` 若含字面 `$(...)` 会被 GNU Make 的 recipe
  展开静默吞空（凶险分支是"跑得通但验的不是原意图"）。

**Not done**
- **C2~C6 六张卡未派**：BUG-0052/0053/0054/0056/0057/0058/0059/0060/0061/0062/
  0063/0064 十二条仍 OPEN，加新登四条中的三条 ⇒ **条件 3 active 16 条**，M4
  签核卡（卡E）仍不能派。
- **BUG-0068 须 rev 裁决**两件事：(a) 追认或推翻 C1 对 `CLAUDE.md` §5 那段 FB
  枚举的删除；(b) 结构面走哪条路（抬 `TOTAL_BUDGET`——`test_budgets.py` 断言
  消息明写抬阈是 "a reviewed decision" / 按 FB-28 已论证的分层下沉到 skill 层 /
  维持现状并接受每次新增都要删）。**在裁决前，`CLAUDE.md` 正文增删一律须 orch
  明示授权。**
- **族级 guard（REV-035 §Q5）仍未落地，且连载体都不存在**——REV-037 §5 问 1
  实测 `grep -rln "UNOWNED=" scripts/ sim/ Makefile` 零命中，且三条 CLOSED 行
  无详情页 ⇒ §Q5.3 的归属规定今天无法被满足。已裁为 **M4 签核卡前置**，非本批
  关闭前置。
- **BUG-0066 未修 ⇒ 全仓禁 `make regress` / `make clean`**（REV-037 §7 条件 5）。
  M4 条件 2 现由既有 `result_summary.txt` 满足，但 M5 的 N=5 多种子回归会撞上。

**Next**
- 派 **C2**（BUG-0056 + BUG-0061），rev 排的第二组；随后 `C3a → C3b`，
  `C4/C5/C6` 可并行。每组仍走 `fixer → 独立 closer` 两次派发。
- **BUG-0066 宜插队**：它是唯一一条"不需任何人犯错、只需按既定流程跑一次就
  损毁取证基础"的缺陷，且 M5 出口必然要跑 `make regress`。
- 一张 rev 卡合并处理 BUG-0068 的两问 + 族级 guard 的落地形状（两者都在"机制
  层"，宜同卡）。
- 之后卡E M4 签核（全 rubric），通过后关门。

**How verified**
- 两条 bug 均由 `make evidence BUG=… CMD=… EXPECT=…` 机器背书翻列：
  `doc/evidence/v0.4.39/BUG-{0065,0055}.log`，首行 `CMD:` **全命令内联、从仓库
  根可重放**（不同于 BUG-0057 那种指向已消失 session scratchpad 的死链接），且
  echo 的签名串**嵌入实测值**、`EXPECT` 正则把数字钉死 ⇒ 不可靠一句 `echo` 伪造。
- **orch 收卡复验一律走集合差而非抽查**（BUG-0049 的教训）：REV-037 收卡
  `OPEN 行集合 ⊖ 裁决集合` 双向 **∅/∅**（14/14 全覆盖）；C1 收卡
  `现存 tag ⊖ origin 5 条` 双向 **∅/∅**（没多删也没少删）+ 逐 tag 归属复算
  `ours=5 theirs=0`；证据孤儿检测 `v0.4.39` 下 **2 文件 vs bugs.md 2 引用**
  精确相等。
- **orch 独立证伪四次**（不采信 closer 的报告，自己注入）：`.PHONY` 陷阱
  （裸 `make -n` exit 0 假绿 / 签名 exit 1 真红，当场对照）· 完整删别名 ·
  `git tag v0.5.0 fb2c193` · `git config --unset remote.upstream.tagOpt`——
  **四次全部真红且复绿，工作区零残留**（tag=5、`tagOpt=--no-tags` 原样）。
- 两条签名各从仓库根**全新 shell 重放** → exit 0，输出与 log 逐字一致。
- BUG-0069 由 orch 独立复现：`CMD='echo $(pwd)'` → `--cmd 'echo '`（吞空）；
  `CMD='echo $$(pwd)'` → `--cmd 'echo $(pwd)'`（正确）。
- BUG-0066 由 orch 独立回源三处坐实：`regress.py:50` · `sim/Makefile:187` ·
  `sim/out/` 下 8 项覆盖工件实存（**未实跑回归**，复现即损毁）。
- BUG-0067 的 23 条由 orch 独立集合差复算，反向差集为空。
- 门：`docs-check passed` · `make selftest` **61/61 OK** · 7 个 `cov.vdb` 全程
  完好（全链未 `make clean`、未 `make regress`）。

## [0.4.39] 2026-08-02 BUG-0048/0050/0051 三条 CLOSED——M4 出口第二/三(b)条转为成立；复验链反手挖出十条存量缺陷（BUG-0052~0065）

**背景**：M4 关门前置。本周期跑了三条独立的 fixer→closer 链（每条 closer 都是与
fixer 无关的全新实例），并在每一环强制"不得照抄上游结论、每个数字自己回源"。
结果：三条目标缺陷全部关闭，**同时**这条纪律本身在三处拦下了会继续繁殖的错误。

**Done**
- **BUG-0048 CLOSED**（lint 基线重同步）：`doc/lint-baseline.md` 236→264 唯一站点，
  83 条新站点逐站点分诊 **83/83 风格、0 真缺陷**（51 条 difflib 行映射对上旧表、
  32 条按 BUG-0021 判据重推；ULCO 用 `xbit` 实算零扩展边界）。判据零放宽
  （`sim/Makefile`/`sim/lintdiff.py` 逐字未改）。独立 closer 另写解析器做**双向**
  集合差 0/0，并设计出比 fixer 更强的关闭签名——`exit 0` 蕴含 `实测 ⊆ 基线`，
  签名钉死 `|实测|=|基线|=264` ⇒ 集合相等 ⇒ 幽灵站点 = ∅，**用算术补上了
  `lintdiff.py` 只打印从不判红的那个方向**。
- **BUG-0050 + BUG-0051 CLOSED**（引用越界 + 证据事实错抄）：CW-002 登记列扩至三模块
  （bin 锁死 `test_i` 单一位）+ rev 记录列双引填实；CW-010 去掉 `fifo_v3` **Cond**
  （该 bin 物理不存在，Branch IF-117 实存故 Branch 认领有效）；§6.3 删三处越权 token、
  counter 例列 108→12、两格 N/A 成因就地重写。证据文件按 FB-23 边界处理：**字节级
  零覆写零删除**（closer 逐行验证 391/395 行逐字存在，4 处均为加法）。
- **M4 出口条件第二条与第三条 (b) 由 REV-035 判定的"不成立"转为 REV-036 判定的
  "成立"**：两处 N/A 成因已各补一条被原始 urg **正向支持**的表述；waivers 全表
  14 行零占位、全 Kind-A、所引 11 份 REV/signoff 文件逐个 `test -f` 实存。
  UNOWNED=∅ 经第三次独立复算仍成立。
- **隔离纪律的三次现场兑现**（本周期最值得记的部分）：
  1. arch fixer 拒绝照抄 REV-035 —— 实测 `lzc.sv:56 always_comb` 存在，
     推翻其"无一个 `always` 块（亲读）"的论证理由（结论对、理由错）。**若照抄，
     等于把一个未核实成因洗成"已核实"，即 BUG-0051 换个载体第三次复发。**
  2. DV closer 拒绝沿用 BUG-0040 的签名体例（自印口令），改为把数字钉进签名。
     而 BUG-0048 的 fixer 原本正是照那份先例设计的——**坏先例在被发现前已繁殖一代。**
  3. rev closer 拒绝采信"已提交"的交接，动手前先 `diff` 确认被审对象未变。
- **新登记十条存量缺陷**（无条件登记，均非本周期引入）：BUG-0052 `workflow/` 死路径 ·
  0053 工具标记入库 · 0054 `make next` 把 REJECTED 签核书读成"可进下一里程碑" ·
  0055 tag 命名空间与上游冲突（`v0.5.0` 已被占用）· 0056 guard ref 含破坏性
  `make clean` · 0057 BUG-0040 关闭证据不可重放且签名自印 · 0058 `lintdiff.py`
  幽灵方向不判红 · 0059 子代理 scratchpad 未按实例隔离 · 0060 `evidence.py`
  先写盘后校验留孤儿工件（`make check` 检不出，经受控实验证实静默）·
  0061 四条 guard 的 `paths:` 被中文标点污染从未匹配（含专为 M4 签核卡写的
  BUG-0047 那条）· 0063~0065 订正段自述数字失准 / 同构缺陷处置不对称 /
  `docs.py` 提示不存在的 make target。
- **缺陷族谱成形**：BUG-0049（漏账）→ 0050（超额认领）→ 0051（事实错抄）→
  0058（lint 基线同形）→ 0060（证据孤儿）→ 0063（订正段自身错抄），六者同根——
  **声明面与事实面之间没有机器核对**。REV-035 §Q5 已裁"值得一条族级 guard
  （三个差集 D1/D2/D3 + 输入白名单），承载而非叠加于各自 guard"。

**Not done**
- 卡E（M4 签核）未派——`make check MILESTONE=4` 条件 3 尚红（14 条 active）。
- BUG-0052~0065 共 **14 条 OPEN**，全部阻塞条件 3。其中 **BUG-0055（tag 冲突）
  须用户裁决**：处置涉及已入库 tag 的去留（删除不可逆），orch 不自行决定。
- 族级 guard（REV-035 §Q5）未落地；BUG-0062（REV-035 自身的事实错误）未裁。

**Next**
- 请用户裁 tag 处置面（加前缀 / 跳号 / 删本地上游 tag + `--no-tags` / 移入独立
  refs 命名空间）。
- 一张 rev 批量裁决卡定 14 条的终态（修 / `ACCEPTED@M<n>` / WONTFIX），再派
  fixer + 独立 closer。多数是几行订正，宜合并。
- 之后卡E M4 签核（全 rubric），通过后关门。

**How verified**
- 三条 bug 均由 `make evidence BUG=… CMD=… EXPECT=…` 机器背书翻列（非手改）：
  `BUG-0048.log` / `BUG-0050.log` / `BUG-0051.log` 落 `doc/evidence/v0.4.38/`，
  首行均为 `CMD:` 且从仓库根可重放（不同于 BUG-0057 那种死链接）。
- 三条签名均先证伪后采用：BUG-0048 一次（删基线一行 → 精确点名变红）、
  BUG-0050/0051 共八次（scratch 镜像，仓内零改动，每次红点与注入缺陷一一对应）。
- UNOWNED=∅ 至此有**三条互相独立的证据链**：REV-034 closer、orch 四路复算 +
  裁决者、REV-036 closer 自写脚本。
- orch 侧受控实验证实 BUG-0060 的静默性：放一份构造的孤儿 `.log` 后
  `make check` 仍 `docs-check passed`。
- `make check` docs-check passed（`make archive` 归档三条终态行后）；
  `make selftest` 61/61 OK；7 个 `cov.vdb` 全程完好（三条链均未 `make clean`）。

