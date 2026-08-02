# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.4.38] 2026-08-02 BUG-0049 关闭（UNOWNED=∅ 经两条独立链确认）——并由复验反手挖出四条新账目缺陷 BUG-0050~0053

**背景**：M4 关门前置。BUG-0049 的修复面（REV-033 裁 CW-014 + arch 返工 + orch 应用）
已在 0.4.37 落地，本闭环只做**关闭**——按不变量 3（closer ≠ fixer）派全新 rev 实例
独立复验。orch 侧**同时**另跑四路互不知情的独立复算作收卡对抗验证：这是对
BUG-0049 根因之三（"orch 复验只抽查数字未做完备性交叉核对"）的直接反制。

**Done**
- **REV-034（closer 卡，rev·L3）**：从原始 urg 报告 `sim/out/urgText6/modlist.txt`
  独立重做 132 格三态（N/A 59 + PASS 43 + <90% 30）与 30 格四表集合差，**UNOWNED=∅**；
  例化闭包 22 成员经 RTL BFS 独立重建、与 urg 模块页集合双向差集为空；CW-014 逐 bin
  账平（39=4+1+26+8）、所引 RTL 事实逐条回源；D1 已录 §6.1 DV-A 且两侧措辞不矛盾。
  产物：`doc/review/REV-034.md`（含 30 格集合差附表，未来签核核读 UNOWNED=∅ 的底板）。
- **BUG-0049 CLOSED（机器背书）**：closer 跑
  `make evidence BUG=BUG-0049 CMD=… EXPECT='RESULT CELLS=132 LT90=30 UNOWNED=0'`
  一次跑通，脚本自行翻状态并写 `doc/evidence/v0.4.37/BUG-0049.log`（首行即 `CMD:`）。
  配套实质记录 `doc/evidence/v0.4.37/BUG-0049-closure.md`（BUG-0029 guard 要求的位置），
  两份文件的形式件/实质件分工已写进其抬头。orch 前置填 `fix_commit=861c7f8`
  （`BUG_STATES_NEED_COMMIT` 含 CLOSED）。
- **orch 四路独立复算（收卡对抗验证）**：正向枚举（从 §2.3 实测表）/ 反向枚举（从四个
  归属面）/ 直查覆盖库原始事实（绕过全部 markdown）/ 从 RTL 重推例化闭包，四路互不
  知情，再由第五个裁决者比对分歧。三路作答者的 30 格 below90 集合**逐格完全一致**，
  裁决者独立复算同得 `CELLS=132 LT90=30 UNOWNED=0` —— 与 REV-034 逐格吻合。
  **UNOWNED=∅ 由两条完全独立的证据链确认。**
- **新登记四条（无条件登记；三条系复验反手挖出，一条系 closer 报出）**：
  - **BUG-0050**（引用越界族，与 BUG-0049 互为镜像）：CW-010 认领 `fifo_v3` Cond 的
    flush 分量，而该 bin **物理不存在**（`fifo_v3.sv:122` 单项条件，26 个实例的
    Condition 段行号恒为 {73,88,101}）；CW-002/CW-007 被引用于其登记文本之外的模块页；
    BUG-0044 承接两格 Toggle 的链接只在 REV-030、未回写债务行本体。四条均为"过度引用"
    而非"无人认领"，**剥离后 UNOWNED 仍为 ∅**，故不影响 BUG-0049 的关闭。
  - **BUG-0051**（证据事实错抄族）：final-sweep §2.3 `counter` 实例数写 108（真值 12，
    系 `delta_counter` 之数误抄，已被 §6.3 继承）；脚注 3 对 `lzc` 的 Line/Cond/Branch
    N/A 陈述与同表 Cond=97.73/Branch=97.73 自相矛盾；脚注 6 对 `stream_register` Cond
    的成因被同一份 modinfo 证伪。**M4 出口第二条要求"附已核实成因"，成因写错等同未满足。**
  - **BUG-0052**（框架路径漂移）：`.claude/agents/{rev,dv}.md`、`dispatch/SKILL.md`、
    `doc/bugs.md:3` 表头共四处引用 0.8.0 已合并掉的 `workflow/review/*`、`workflow/fail/*`
    路径，`test -e` 逐条实测全 MISSING。REV-034 实例是第一个撞上并靠卡内订正绕过的。
  - **BUG-0053**（记录卫生）：`REV-033.md` 尾部工具标记随 `861c7f8` 入库；REV-034 实例
    写自己记录时**当场复现同一泄漏**（自检删除）——系统性写作陷阱，非一次性疏忽。

**Not done**
- 卡E（M4 签核重开）未派——`make check MILESTONE=4` 条件 3 尚红。
- BUG-0048（lint baseline 漂移）仍 OPEN，下一闭环主件（fixer + 独立 closer 两次派发）。
- BUG-0050~0053 均 OPEN：0050/0053 待 rev 裁决处置面，0051/0052 待派 fixer。**四条都压在
  M4 签核之前**——0050/0051 直接触及 M4 出口第二、三条的诚实性，0052/0053 是记录卫生。

**Next**
- 闭环2：BUG-0048 fixer（DV，逐站点分诊 62 个新 lint 站点 + 重同步基线；硬约束不得
  `make clean` 毁 `sim/out` 覆盖库）+ 独立 closer。
- 闭环3：BUG-0050~0053 处置（rev 裁决 + fixer）。
- 闭环4：卡E M4 签核（rev·L3 全 rubric），通过后 `make bump minor=1` + tag v0.5.0。

**How verified**
- `make evidence BUG=BUG-0049 …` 退出 0、签名命中，脚本自行回填 CLOSED + verify_evidence
  （非手改）；`doc/evidence/v0.4.37/BUG-0049.log` 首行为 `CMD:`。
- 四路复算的关键事实 orch 侧逐条机核复现：`grep -c i_counter_open_w/i_r_counter
  sim/out/urgText6/hierarchy.txt` 各得 6（counter=12，非 108）；`grep -n flush_i
  vendor/common_cells/src/fifo_v3.sv` 只得 :25/:122，遍历 26 个 fifo 实例 Condition 段
  无 LINE 122；`modlist.txt:48` lzc 行 Cond/Branch=97.73 与脚注 3 正文矛盾；四条 workflow
  死路径 `test -e` 全 MISSING；`tail -3 doc/review/REV-033.md` 见工具标记。
- `make check` docs-check passed、chain audit 无新增 gap 形状；`make selftest` 见本块提交。
- 本闭环零 RTL/TB 改动，未跑 sim、未 `make clean`、`sim/out/` 全程只读（覆盖库另备份至
  scratchpad 防误删）。

