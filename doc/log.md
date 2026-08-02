# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.4.37] 2026-08-02 里程碑重构落地——M4 出口重定义、新增 M6 承接 ≥90% 门，spec §0#4 重 pin（BUG-0047 选项 (ii) 兑现）

**背景**：用户裁定"覆盖率 90% 出口不该留在只有定向激励的里程碑"，走
BUG-0047 终判预留选项 (ii)。链条：arch 提案（卡B）→ rev 门禁（卡C，
REV-032）**首判 REJECTED**（轴 4 抓出 `stream_register` 三格漏账——
"UNOWNED=∅"宣告失实）→ orch 登记 BUG-0049 → 独立 rev 处置卡
（REV-033）裁归属 → arch 返工（G-1/G-2）→ rev 复审 **APPROVED** →
orch 机械应用 + 重 pin。

**Done**
- **REV-032（门禁 + 复审）**：七轴合格、轴 4 首判抓漏。复审对含
  stream_register 的 22×6 全格重做集合差——132 格与 final-sweep §2.3
  全一致，APPROVED 无条件。副产物：G-2 揪出 verification_maturity 四处
  v1.1 版本残留（orch 复核补出 L44 一处，比 REV-032 清单多一处）。
- **BUG-0049 登记**（无条件登记）：stream_register Line 75.00/Toggle
  22.00/Branch 50.00 三格漏账，归因三层如实入账（卡A §3 标注遗漏、
  orch 复验未做完备性交叉核对、REV-031 承接汇总清单为输入）。
- **REV-033**：三格独立裁决——Line/Branch 全 Kind-A、Toggle 拆 31 bit
  Kind-A（P1 tie-off/P2 push-gate 同 CW-001 INJECT_R 根因/P3 rst_ni）
  + `data_i.len[7:4]` 8 bit 定向可达路由 DV-A err_slv 宿主族。登记
  **CW-014**；顺带订正 REV-032 "非-load ATOP" 表述（`atop[5]` 实为
  读返回类原子，`axi_pkg.sv:447` 独立重推）。
- **提案返工（卡B'）**：G-1 五点（§6.2 收 CW-014、§6.1 收 D1、计数
  013→014 五处、UNOWNED 现状如实化、**新增 §6.3 22×6 全格→归属对照
  表**——未来签核 UNOWNED=∅ 核读的底板）+ G-2 四处版本残留 old/new。
- **orch 机械应用**（rev 批准后，零创作）：spec §0#4 一句替换 +
  修改记录 #12 行 + `docs.py --pin-spec` **重 pin**（新 sha
  `dad62e08…`）；milestone.md 从提案围栏块脚本拼装（M4 重定义 +
  M5 瘦身 + **M6 新增**，Abstract 修"0 场景行"漂移，M0-M3 零变化）；
  coverage-waivers 抬头 Kind-B 解锁改"M5 随机层 + M6 cov_loop"；
  verification_maturity 修订 A-E（Decision 5 移交 M6 + 版本残留清理）；
  BUG-0047 详情页追加选项 (ii) 落地段（冻结正文不回改，仅追加）；
  删 `milestone.md~` 杂物。
- **新里程碑架构生效**：M4 = 测量基建 + 三态扫描 + 每格具名归属
  （UNOWNED=∅，四表交叉核）；M5 = 纯方法论（随机层/多种子/soak，无
  百分比门，三条 `ACCEPTED@M5` 锚零移动）；M6 = 六类 ≥90% 收敛
  （cov_loop，random-first directed-fallback，v1.0.0 改挂 M6 签核）。

**Not done**
- 卡E（M4 签核重开，新出口条件下全 rubric）未派——下一闭环主件。
- BUG-0048（lint 门机制修）仍 OPEN，压在签核后（保 merged vdb）；
  BUG-0049 仍 OPEN（closer 另派，待 CW-014 已 pin〔本 commit 兑现〕+
  D1 已录 backlog〔提案 §6.1 已录〕后可派 closer）。
- M6 backlog 的 DV-A~G 七张定向卡均未派（M6 时 random-first 处置）。

**Next**
- 卡E：M4 签核重开（rev·L3，全 rubric，§6.3 对照表为 UNOWNED=∅ 核读
  底板；签核文含 15 条 RTL-only 条款 oracle 边界段）。通过后
  `make check MILESTONE=4` + bump minor + tag v0.5.0，M4 关门。

**How verified**
- REV-032 复审段独立重做 132 格集合差 + 四处 OLD 逐字 grep；orch 应用
  前对四处 old/new 做保真度 grep（全部唯一命中）、milestone 抬头 md5
  比对提案 §3.1 一致；应用后 `python3 scripts/docs.py --pin-spec` 成功
  重 pin（拒绝-登记-重试链：首次 pin 被脚本按"修改记录先行"规则正确
  拦截，补 #12 行后通过）。
- `make check`（docs-check passed + chain audit 无新增 gap 形状）与
  `make selftest`（61/61 OK）应用后复跑绿。本闭环零 RTL/TB 改动，无需
  重跑回归。

## [0.4.36] 2026-08-02 卡A 覆盖率全景复测 + REV-031 UNOWNED 分诊——M4 残余首次达成"每格有归属"，CW-010~013 登记

**背景**：用户裁定 M4"六类硬 ≥90%"出口与定向激励约束的张力走 BUG-0047
终判选项 (ii)（重议判据口径），路线 = 里程碑重构（M4 出口改"测量+分诊
完成"、新增 M6 承接 ≥90% 数字门、M5 保持纯方法论）。重构提案（arch 卡）
动笔前，先以一张 DV 测量卡（卡A）取权威数字、一张 rev 卡（REV-031）关掉
无归属缺口——backlog 表须基于实测，不抄旧表。

**Done**
- **卡A（DV·L1）**：`doc/evidence/v0.4.35/M4-coverage-final-sweep.md`。
  merged vdb 完整性核验（24 基线场景，cfgE 经亲测 UCAPI-INSTANCEMISMATCH
  证实结构不可并入，非构建隔离习惯）；六类全闭包三态扫描（22 DUT 模块，
  22+13=35 与 modlist 逐位对账）；<90% 格逐一归属标注。三大发现：
  (i) REV-024 两悬案自然消解——`axi_xbar` Toggle 40.74→94.44 PASS、
  `axi_xbar_unmuxed` Assert 53.85→100 PASS（历史加固卡副作用关闭，无人
  回测过）；(ii) 9 个 UNOWNED (模块,类型) 格子（8 个首次按模块页测量的
  闭包内 common_cells 模块）；(iii) CW-001 对 `r_state_q.R_HOLD` 论证
  失实（普通读背压可达、已 Covered、与 ATOP 无关）。
- **REV-031（rev·L3）**：9 格逐格独立裁决（测量卡建议仅作路由输入）。
  新登记 **CW-010~013** 四条 Kind-A（flush_i 全例化点 tie-0 根因一行承接
  多格 bin-scoped 分量 / lzc 常量 LUT+非 2 幂 padding / axi_id_prepend
  pre_id_i generate 常量 / counter-delta_counter tie-off 位），各附可证伪
  解锁；**零 Kind-B**（BUG-0047 guard 合规）。混合格拆分：结构位入豁免、
  定向位路由 DV——新增 **DV-F**（rr_arb_tree 仲裁竞争多样性）、**DV-G**
  （id_counters push+inject 同拍同 index，DV-E 家族）两张待派卡；薄壳
  Toggle（89.22/88.51）判 DV-A/B 阴影不新开卡。CW-001 措辞订正（R_HOLD
  除外标注，豁免主体维持）；REV-024 §2.2 行 9 表后追加勘误批注（
  multicut/cut 结构无 Cond bin，"55-65%"应属 spill_register_flushable，
  原表格行一字未改）；"待建档项" spill bypass 经 urg 反证（Bypass=0/1
  两参数均例化）撤项。
- **orch 独立复验**：卡A——git status 单文件、modlist/modinfo 抽查
  spill_flushable 82.49/lzc 42.59/id_counters 73.91/xbar 94.44/unmuxed
  Assert 100/ar_ready Yes×3/R_HOLD Covered 全对上、格式对齐 v0.4.0 先例。
  REV-031——编辑面精确 3 文件、REV-024 批注纯追加（diff 全 + 行）、
  flush 六处 tie-off/pre_id_i/lzc LUT/counter 三 tie-off/down_i(1'b1)
  逐一亲验 RTL 对上。counter 实例数分歧（卡A 108 vs REV-031 12，实为
  delta_counter 之数）不影响任何百分比与处置，已记 REV-031 §6。
- **M4 残余状态**：至此全部 <90% 格子首次达成"每格有归属"——CW-001~013 /
  BUG-0044 / DV-A~G 待派清单 / 已吸收，UNOWNED = 空集。

**Not done**
- 里程碑重构提案（arch 卡B：spec §0#4 修订 + milestone M4/M5/M6 + backlog
  表）及其 rev 门禁（卡C）未派——本闭环只做了它的数据前置。
- DV-A/B/C/E/F/G 六张定向卡均未派（重构落地后按 M6 backlog 处置）。
- BUG-0048（lint 基线漂移）未修——已决策：机制修（lint-diff 挂进门禁），
  排在 M4 签核后以保住 merged vdb 供签核 rev 独立复算。

**Next**
- 卡B：arch 里程碑重构提案（M4 出口改"测量+分诊完成、无 silent gap"，
  新增 M6 承接六类 ≥90%，M5 纯方法论；backlog 表数据源 = 本闭环
  final-sweep + REV-030 DV-A~E + REV-031 DV-F/G）→ 卡C rev 门禁 →
  orch 应用重 pin → M4 签核重开。

**How verified**
- 见上"orch 独立复验"段——两卡数字均未采信自报，urg text 报告与 RTL
  例化点逐项亲验。
- `make check` 本轮复跑绿（docs-check passed；chain audit 仅既有已知
  形状，"仅锚父节"14 处与 0.4.35 记录一致，无新增 gap）。本闭环零
  RTL/TB 改动，无需重跑回归。

