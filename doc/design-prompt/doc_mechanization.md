# Design prompt — `doc_mechanization`（`scripts/docsx.py`，project-owned 文档断言机械化检查器）

> **约束层声明**：本文只规定 `scripts/docsx.py` 的**判据与接口**，不写实现代码。
> 这是一份**元工具**设计契约，不是 DUT 模块设计契约——它的判据不从 `doc/spec.md`
> 推导（那是 DUT 的 spec），也**不得**编码任何 DUT 行为。它的权威基础是：
> `doc/bugs.md` 的登记事实（BUG-0052/0053/0058/0060/0061/0063/0067/0069）、
> `doc/review/REV-035.md` §Q5、`doc/fw-feedback.md` FB-23、以及 CLAUDE.md 五条
> 不变量中的第 1 条（`✅` 只能由 `make evidence` 翻列）与第 4 条（期望只来自 pin 住
> 的 spec）。
>
> **behavior-leak / spec-from-RTL 边界**：本检查器**执行**仓内文本携带的命令，因此
> 天然踩在"证据从事实来"的红线边缘。边界由两条硬约束守住——(a) §F8 令
> `docsx` 拒绝在 `doc/spec.md` 内出现任何标记（机器核对语法若进 spec，就是 spec
> 期望被工具语法污染的另一扇门）；(b) §12 令执行器只跑我在此定义的**新字段**，
> 绝不跑存量文本携带的 `ref:`。这两条不是防御性过度工程，是**门**（discipline §2
> 例外条款）——不得为让本卡过而放宽。

## 0. 目标与范围（goal & scope）

`scripts/docsx.py` 是**项目自有**（project-owned）的文档断言机械化检查器，补
`scripts/docs.py`（上游文件，一行不改）留下的空白：现有检查全部作用于表格行 /
frontmatter 层，无一扫描正文自由文本，且多处只实现了单向核对（BUG-0060/0067）。

- **C0.1 文件头自声明**：`docsx.py` 文件头首段须写明
  `# project-owned (NOT an upstream file). 见 doc/fw-feedback.md FB-<n>.`——它不是
  canon，改它不登 FB；但它 **import** 的 `docs.py` 是 canon。
- **C0.2 复用而非重写解析**：可 `from docs import ...` 复用
  `parse_table` / `row_cells` / `check_table_structure` / `split_table_lines` /
  `check_evidence` / `count_mod_records` 及 `CFG`（列名口径的单一事实源）。
  **不得**另写第二套 markdown 表解析——列名漂移会让两套检查各读各的（BUG-0016 同形）。
- **C0.3 判据只从声明面与事实面之差推导**：本检查器不持有任何"期望值"，它只核
  "文档自己声称的"与"机器重算出来的"是否一致。凡写不出可注入证伪的 `red_when`
  的检查族，本设计不收（discipline §4：目标即门）。

## 1. 标记语法与活/冻结文件集（marker grammar & live/frozen sets）

- **C1.1 标记载体 = HTML 注释**：所有内联标记形如 `<!-- docsx:<verb> <k="v"> -->`。
  选 HTML 注释因其在渲染后不可见、不扰乱正文，且与 markdown 表格/frontmatter 正交。
  `<verb>` ∈ {`count`, `bidiff`}（正文标记）；guard/baseline 走结构化表，不用内联标记。
- **C1.2 活文件集（live set）= 显式白名单**：由 `docsx.py` 内一份显式清单定义，
  **硬要求含 `README.md`**。基线清单（可由 rev 增删）：`README.md`、`CLAUDE.md`、
  `doc/bugs.md`、`doc/fw-feedback.md`、`doc/milestone.md`、`doc/testplan.md`（除状态列，见 §F8）、
  `doc/feature-matrix.md`、`doc/coverage-waivers.md`、`doc/lint-waivers.md`、
  `doc/design-prompt/*.md`、`workflow/*.md`、`.claude/**/*.md`、`doc/guards.md`。
- **C1.3 冻结前缀白名单（frozen prefixes，跳过 §F1/§F2/§F7）**：`doc/review/`、
  `doc/evidence/`、`doc/archive/`、`doc/bugs/`（详情页作为历史记录）。依据 FB-23
  "冻结记录不回改"——对它们做活体核对等于逼人回改已冻结的一手件。
- **C1.4 可执行字段隔离（executable-field separation）**：**唯一**可被执行器接收的
  值是本设计新定义的字段——`count`/`bidiff` 标记的 `check=`/`left=`/`right=`，与
  `doc/guards.md` 的 `check` 列（`type: script` 行）。存量 `ref:` 字段（42 份详情页
  + `guards.md`）**永不**进执行器（§12）。

## F1. 数字断言（number assertion，活体/冻结两形态 + 元检查）

活文件正文的带单位计数须绑定一条产生它的命令。背景：BUG-0067 的行内计数
"23→27" 静态过期无机制提示；FB-23 的复现命令从写下当天就跑不出它声称的数字
（BRE 花括号不做 alternation）——证明"只核数字"不够，命令本身须被元检查。

- **判据**：
  - **活体** `<value> <!-- docsx:count check="<cmd>" -->`：执行器跑 `<cmd>`，取
    stdout 首个整数，须 `== <value>`；**每次 CI 重跑核对**。
  - **冻结** `<value> <!-- docsx:count frozen@<sha> check="<cmd>" -->`："截至 `<sha>`
    为真"，`<value>` **不**重比（仓库已前移，重比必假红）——只做元检查。
  - **元检查（两形态皆做）**：`<cmd>` 须**可执行、退出 0、stdout 非空**。这正是
    FB-23 命中的形状：原 BRE `grep -rc 'workflow/{a,b}/'` 零命中 → 退出 1 → 元检查
    红；改 ERE 后非空 → 过。冻结形态靠元检查拦"自带伪造复现命令"，无需重比数字。
- **red_when**：
  - 活体：把 `<value>` 改成与 `<cmd>` 输出不同的整数 → 红。
  - 冻结/活体元检查：把 `check=` 换成零命中命令（退出非零或 stdout 空，如上述原 BRE
    写法）→ 红；`check=` 缺失或为空串 → 红。
- **docs.py 复用**：无（正文扫描是 docsx 新增面）；`CFG.root` 定位仓库根供执行器
  锁 cwd。

## F2. 仓内路径存在性（in-repo path existence）

BUG-0052：四处框架文档指向不存在的 `workflow/` 路径，无任何机器检查覆盖"文档内
引用的仓内路径是否存在"。

- **判据**：扫活文件正文中形如仓内路径的 token（`(README\.md|doc|scripts|workflow|
  tb|sim|vendor|\.claude|\.githooks)/[\w./*-]+` 及顶层 `README.md`/`CLAUDE.md`）；
  每个 token 若不存在**且**不落在 §C1.3 冻结前缀下 → 红。含 glob（`*`）的 token：
  以 glob 匹配 ≥1 文件即算存在。存量无法立即修的合法引用走 §F10 baseline。
- **red_when**：向 `README.md`（活文件、硬含）加一行引用 `workflow/nonexistent.md`
  → 红；反证不误伤：加引用 `doc/evidence/vX/gone.md`（冻结前缀）→ **不**红。
- **docs.py 复用**：`CFG.root` 判存在；活文件集共用 §C1.2。

## F3. 双向集合断言（bidirectional set assertion）

形如"登记面↔事实面"的成对账目声明为双向差集为空并被机器重算。这是 §F5 孤儿与
REV-035 §Q5 族级 guard（D1/D2/D3）的**通用底座**。

- **判据**：`<!-- docsx:bidiff left="<cmdL>" right="<cmdR>" -->`——`<cmdL>`、
  `<cmdR>` 各产一个按行的集合；`left − right`（`comm -23`）或 `right − left`
  （`comm -13`）任一非空 → 红。两侧命令均受 §12 执行器约束与 §F1 元检查（退出 0）。
- **red_when**：向 `left` 侧塞一条 `right` 侧没有的幻影行 → `left−right` 非空 → 红；
  从 `right` 侧删一条 `left` 有的行 → `right−left` 非空 → 红（**两个方向都进退出码**，
  对 BUG-0058 单向教训的正面反例）。
- **docs.py 复用**：无（命令自带解析）；结果签名格式呼应 REV-035 §Q5 点 1
  "一条命令、三个差集、一个退出码"的可粘贴形态。

## F4. guard 载体（`doc/guards.md` 单表）

新建 `doc/guards.md` 承载**全部** `regression_guard`（现散落在 42 份详情页——
`grep -l '## regression_guard' doc/bugs/*.md | wc -l`，orch 亲跑 2026-08-02）。它
同时是 REV-035 §Q5 族级 guard 的落地载体，schema 须满足其 Q5 点 3 归属规定
（多条 bug 指向同一实现，各自 `note` 只写对应哪个差集）。

- **表 schema（columns_preset=en）**：`| id | bugs | type | paths | check | note |`
  - `id`：guard id（`G-xxx`）。
  - `bugs`：所属 bug id，逗号分隔——**族级 guard 一行列多个**（如
    `BUG-0049,BUG-0050,BUG-0051`），满足 Q5 点 3"同一实现、各自归属"。
  - `type`：`script` | `checklist`。
  - `paths`：仅 ASCII + glob，空白/逗号分隔（BUG-0061 中文顿号教训——中文标点使
    `docs.py:1156` 的 `re.split(r"[,\s]+", …)` 并成永不匹配的废 token）。
  - `check`：`type: script` 行的可执行命令（进执行器，§12）；`type: checklist`
    行填 `-`。
  - `note`：一行；族级 guard 在此写各 bug 对应的差集（`D1=BUG-0049 格∖归属;
    D2=BUG-0050 引用∖登记; D3=BUG-0051 声明∖实有`），呼应 Q5 点 3。
- **判据（硬要求）**：
  - `type: checklist` 的**新增行即红**（不在 §F10 baseline 中即为新增）——REV-035
    §Q3(b)：checklist 是机械化 TODO，把今天能关的门写成 TODO 等于留开它；新 guard
    一律 `type: script`。存量 checklist guard 经 baseline 豁免。
  - `paths` 单元格含非 ASCII 字符（中文顿号 `、`、全角括号 `（）` 等）→ 红。
  - `type: script` 行的 `check` 空或不可执行 → 红（§F1 元检查同款）。
- **red_when**：加一行 `type: checklist` 且不在 baseline → 红；`paths` 写
  `doc/milestone.md（M4/M5 节）` → 红（含 `（）`）。
- **docs.py 复用**：`parse_table`（读 guards.md）、`check_table_structure`（列数
  一致）、`row_cells`。

## F5. 孤儿双向（orphan bidirectional）

BUG-0067：69 条 bug 行中 27 条无详情页，而 `docs.py:519-535` 的孤儿检查是**单向**
（页无行报错、**行无页不报**）。BUG-0060：`evidence.py` 先写盘后校验，一次笔误在
`doc/evidence/` 留永久孤儿工件，`docs.py:527-531` 只覆盖 `doc/bugs/*.md`、对
`doc/evidence/` 无对应检查。两方向都须进退出码。

- **判据**（两对，各双向；均可表达为 §F3 的 `bidiff`）：
  - **bug 行 ↔ 详情页**：`doc/bugs.md`(+archive) 每个 bug id 须有
    `doc/bugs/<id>.md`（行→页，**按 id、非按文本引用**——补 docs.py 只在有
    `doc/bugs/<id>.md` 文本引用时才要求页的缺口）；反向页→行已由 docs.py 覆盖，
    docsx 只补行→页方向并把两向并成一个退出码。
  - **evidence 文件 ↔ bugs.md 引用**：`doc/evidence/**` 下每份 `.log`/证据文件须
    被 `doc/bugs.md`(+archive) 或 `doc/testplan.md` 的某行引用；反向引用须指向存在
    的文件。
- **red_when**：登一条 bug 行、不建 `doc/bugs/<id>.md` → 红（BUG-0067）；往
  `doc/evidence/vX/` 放一份无任何行引用的 `.log` → 红（BUG-0060，现状 `make check`
  绿）。
- **docs.py 复用**：`parse_table`（bug_rows/abug_rows）、`CFG.bug_pages` /
  `CFG.bugs` / `CFG.bugs_archive` 路径口径；复用 :523-526 的 `state_by_id` 构造法。

## F6. 单元格字节上限（cell byte cap）

机器表单元格超限即红。BUG-0067 实测：summary 单元格 186–963 字符、root_cause
1111 字符；`workflow/bugs.md` 点名 "3000-character table cells proved unreadable"。

- **判据**：对 `doc/bugs.md`、`doc/testplan.md`、`doc/coverage-waivers.md` 三张机器表
  的每个数据行单元格，`len(cell.encode('utf-8')) > CAP` → 红。**CAP 数值待 rev 裁**
  （设计建议：普通列 CAP=2000 字节；`root_cause` 一列因其正当长度另设更高上限或
  豁免——见 §取舍 2）。
- **red_when**：把任一单元格填成 `"x" * (CAP+1)` → 红。
- **docs.py 复用**：`parse_table` / `row_cells`（取单元格）；`CFG.C` 提供各表列名。

## F7. 枚举快照禁写死（enum snapshot must not be hardcoded）

活文件中"当前已改 X、Y"型静态列表禁止，须指向 `make handoff`/`make next` 现算。
背景：FB-25/BUG-0052 型——手写的"当前状态"枚举随框架改路径静默腐烂。

- **判据**：活文件正文命中快照引导短语的**denylist**（如
  `当前已(改|迁移|完成|修复).{0,40}[、,，]` 等，具体正则集在 §skill 层维护）且该
  处无 `docsx:count`/`docsx:bidiff` 标记、也无 `make handoff`/`make next` 指向 →
  红。**本族天生启发式、必不完备**（见 §取舍 3）。
- **red_when**：向 `README.md` 加一行 `当前已改：workflow/a.md、workflow/b.md`
  （无标记、无 make 指向）→ 红。
- **docs.py 复用**：无（正文扫描）。

## F8. 红线（red lines，enforce 不变量 1 与 4）

- **判据 A（spec 红线，不变量 4）**：`doc/spec.md` 内出现任何 `<!-- docsx:… -->`
  标记 → 红。期望只来自 pin 住的 spec；机器核对语法若进 spec，就是 spec 期望被
  工具语法污染的另一扇门。
- **判据 B（testplan 状态列红线，不变量 1）**：`doc/testplan.md` 的状态列
  （`CFG.C["tp_status"]`）单元格出现任何 `docsx:` 标记 → 红。`✅` 只能由
  `make evidence` 翻列，标记不得触碰该列。
- **red_when**：在 `doc/spec.md` 任意处插 `<!-- docsx:count check="echo 1" -->`
  → 红；在 `doc/testplan.md` 某行状态列写 `<!-- docsx:count … -->` → 红。
- **docs.py 复用**：`parse_table` + `CFG.C["tp_status"]` 定位状态列；spec 全文
  子串扫描。

## F9 / §12. 执行器安全契约（executor safety，rev 重点审）

任何"执行仓内文本携带命令"的检查只跑 §C1.4 定义的新字段，**绝不**跑存量 `ref:`。
背景：`doc/bugs/BUG-0040.md` 的存量 `ref` 含 `make clean`（BUG-0056 行），执行它
会摧毁 `sim/out` 覆盖取证。

- **C12.1 唯一可执行面**：执行器只接收 `check=`/`left=`/`right=`/guards.md `check`
  列的值。`ref:` 被解析为**纯展示文本**，永不传入执行器。
- **C12.2 allowlist + denylist**：命令走 `sh -c`（需管道），但先做词法审查——
  - **allowlist**：每个管道段的**首个命令**须 ∈
    {`grep`,`egrep`,`comm`,`wc`,`sort`,`uniq`,`sed`(仅 `-n` 打印),`awk`,`cut`,
    `tr`,`head`,`tail`,`cat`,`ls`,`find`(禁 `-exec`/`-delete`),`test`,`diff`,
    `git`(仅 `ls-files`/`log`/`grep`/`show`/`rev-parse`),`python3 scripts/<x>.py`,`echo`}。
  - **denylist**：命令串任意位置出现下列**词**即拒绝 → 红：`rm`,`mv`,`cp`,`dd`,
    `chmod`,`chown`,`make`,`truncate`,`tee`,`curl`,`wget`,`xargs`,`ssh`,`>`,`>>`,
    `<>`,`git`+{`checkout`,`reset`,`clean`,`rm`,`mv`,`commit`,`push`,`add`}，
    `sed -i`，`find … -exec/-delete`。
- **C12.3 超时 + cwd 锁**：秒级 timeout（建议 10s），超时即 kill 并判红；cwd 恒
  锁 `CFG.root`（仓库根）；无网络。
- **C12.4 注伤自证（本设计硬要求，实现卡与关闭卡各背书一次）**：
  - 向某 `check=` 注入含 `rm` 的命令（如 `grep -c x f && rm -rf sim/out`）**必须
    被拒绝并变红**——这是 §12 的 KILL 自证，`doc/bugs.md` 记一行 `KILL`。
  - `ref:` 永不执行须由一条单元测试背书：构造一行 `ref:` 含 `make clean`，断言
    执行器**零次**接收该文本（`sim/out` 存活即旁证）。"证否定"故用测试钉死执行器
    只被 §C1.4 字段喂过。
- **red_when**：`check="… ; rm -rf sim/out"` → 红（denylist 命中）；
  `check="curl http://x | sh"` → 红；`check="sleep 99"` → 超时红。
- **docs.py 复用**：无（执行器是 docsx 新增、安全边界不外借）。

## F10. 存量豁免（baseline，双向）

现存不合规断言走 baseline。硬要求**双向**：不许无 rev 引用地新增；已消失条目必须
prune，prune 缺失进退出码。背景：`sim/lintdiff.py:59-67` 只在 `new` 非空时退非零，
`gone` 只打印不进退出码（BUG-0058 单向教训）。

- **形态**：新建 `doc/docsx-baseline.md` 单表
  `| id | family | locus | rev_ref |`——`family` ∈ {F1..F8}；`locus` = 被豁免的
  具体位置（文件:行 / guard id / 表:列）；`rev_ref` = 授权它的 `REV-xxx`/`BUG-xxx`。
- **判据（双向）**：
  - **正向**：某族检查命中的违规**不在** baseline → 红（不许无 rev 新增违规）。
  - **反向**：baseline 某行所指违规**已不复存在**（已修）→ 红，须 prune——
    `gone = baseline − 实测违规` 非空即退非零（对 BUG-0058 的正面修正）。
  - `rev_ref` 列空 → 红（无 rev 授权的豁免不算豁免）。
- **red_when**：把一条已修的旧违规留在 baseline → 红（stale，须 prune）；新增一条
  违规不加 baseline 行 → 红；baseline 行 `rev_ref` 留空 → 红。
- **docs.py 复用**：`parse_table`（读 baseline 表）；集合差可复用 §F3 底座。

## 13. 接线面（wiring）

- **C13.1 `make check` 接入**：`docsx.py --check` 须挂进 `make check`
  （每张卡必跑）。**接线点**：根 `Makefile` 的 `check:` target（当前
  `Makefile:66-68` 只调 `docs.py --check`）。`Makefile` **属 canon**——改它须在
  `doc/fw-feedback.md` 留 FB 行并在 recipe 旁注 `见 doc/fw-feedback.md FB-<n>`。
- **C13.2 `.githooks/pre-commit` 软门**：`pre-commit`（`.githooks/pre-commit:5`
  现只跑 `docs.py --check`）追加 `docsx.py --check`。同样记 FB 行。
- **C13.3 `make guards` 改源（interface 后果，须 rev 裁）**：guards 迁到
  `doc/guards.md` 后，`make guards`（现 `Makefile:72-73` → `docs.py --guards`，读
  42 份详情页的 `## regression_guard`）将读到空。须把 `guards:` target 改指
  `docsx.py --guards`（读 `guards.md`）——canon Makefile 改动、记 FB 行；
  `docs.py:1138` 的 `cmd_guards` 随之退役（不删、上游文件）。此为迁移的必然接线
  后果，列入 §开放风险。

## 14. 人读说明落点（human-readable notes）

- **C14.1 落 `.claude/skills/` 层**：新标记语法与各族规则的人读说明落
  `.claude/skills/doc-mechanization/SKILL.md`（project-owned）。**禁**进
  `CLAUDE.md`/`workflow/*.md`——`scripts/tests/test_budgets.py` 的必读面聚合预算
  余量仅 **71 字节**（39429/39500，orch 亲跑
  `CLAUDE.md + workflow/*.md`），任何正文增量都会撞线；抬预算是 rev 决策、不是
  修法。§F7 的快照短语正则集亦维护在此 skill、不硬编进 CLAUDE.md。

## 15. 交付形态与验收锚点

- **产物**：`scripts/docsx.py`（project-owned）+ `doc/guards.md`（迁移 42 条）+
  `doc/docsx-baseline.md`（存量豁免）+ `.claude/skills/doc-mechanization/SKILL.md`
  + `Makefile`/`pre-commit` 接线（各记 FB 行）。**均由后续实现卡产出，本卡只定契约。**
- **验收判据**：
  - 十族各自的 `red_when` 逐条可注入证伪（实现卡须逐族演示红→修→绿）。
  - §12 的两条注伤自证背书到位：含 `rm` 的 `check=` 被拒变红（`doc/bugs.md` 记
    `KILL` 行）；`ref:` 含 `make clean` 零执行由单元测试钉死。
  - `docsx.py --check` 挂进 `make check` 后全绿；`test_budgets.py` 仍绿（人读说明
    未进必读面）。
  - guards.md schema 满足 REV-035 §Q5 点 3：族级 guard 一行多 bug、`note` 各自
    归属 D1/D2/D3。

## 16. 决策点待裁清单（open decisions for rev）

- **D-1 可执行命令的载体**（**待 rev 裁**）：选择 = 命令内联在正文标记的 `check=`；
  反方形态 = 可执行面全部收敛进 `doc/guards.md`/baseline 结构化表、正文标记只引
  guard id；选它的理由 = FB-23 的教训是复现命令须与它证明的数字同行 travel，安全
  由 §12 执行器契约兜底而非靠藏命令。
- **D-2 F6 CAP 数值与 `root_cause` 例外**（**待 rev 裁**，与 §F6 正文标记一致）：
  选择 = 普通列 CAP=2000 字节、`root_cause` 一列另设更高上限或豁免；反方形态 =
  全列一刀切单一 CAP；选它的理由 = BUG-0053 的 `root_cause` 实测 1111 字符是合法
  长文，一刀切会误伤正当长内容。
- **D-3 F7 启发式的去留**（**待 rev 裁**）：选择 = 以脆弱正则 ship，正则集关进
  skill 层可迭代；反方形态 = 降级/deferred，等第二次实例触发再落地（discipline §2
  deferred-ledger）；选它的理由 = 快照短语 denylist 天生不完备、且可能误伤正当
  正文，够不够格 ship 由 rev 定夺。

## 引用（authority basis）

`doc/bugs.md`：BUG-0052（路径漂移）· 0053（工具标记/checklist guard）· 0058
（单向差分）· 0060（孤儿证据）· 0061（中文标点污染 paths）· 0063（订正段错抄）·
0067（单向孤儿 + 行内计数过期）· 0069（CMD 变量吞空，旁证执行器须元检查）。
`doc/review/REV-035.md` §Q5（族级 guard D1/D2/D3、点 3 归属写法、type: script 优于
checklist）。`doc/fw-feedback.md` FB-23（冻结记录不回改 → §C1.3 白名单）、FB-25/27
（活文件路径腐烂无门禁）。CLAUDE.md 不变量 1（`✅` 只由 `make evidence` 翻列 →
§F8-B）、不变量 4（期望只来自 pin 住 spec → §F8-A）。`doc/bugs/BUG-0040.md`
（存量 `ref:` 含 `make clean` → §12 执行器边界）。
