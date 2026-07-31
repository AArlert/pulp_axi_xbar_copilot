# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.4.16] 2026-08-01 逐位 Toggle 分解完成（Kind-B 前置兑现）——M4 阶段合法 Kind-B 豁免集为空集，转正 3 条 Kind-A（err_slv 恒定输出）

**背景**：REV-024 授权了 Kind-B（方法论受限、延后 M5）豁免路径，但明确"不
预先授予任何具体豁免，须先有逐信号/逐位 toggle 分解证据"。本周期用
Workflow 工具跑一套多 agent 流水线兑现这个前置：刷新覆盖率数据 → 4 模块
（axi_mux/axi_xbar/axi_demux_simple/axi_err_slv）并行逐位分解 → 每条
"载荷候选"由 3 个独立怀疑者做对抗性反驳投票 → 综合报告 → 独立 rev 复核
（REV-025）。

**Done**
- **覆盖率数据刷新**：核实并确认此前 sim/out 已因两次不带 COV=1 的
  make regress（KILL-0004 自证卡、M4 签核卡 falsification）变成非
  instrumented 空壳，干净重跑 make clean && make regress COV=1（26/26
  PASS）；基线聚合数字与 v0.4.9 逐位一致（LINE 80.84/COND 71.66/
  TOGGLE 47.87/FSM 7.14/BRANCH 82.99/ASSERT 78.62/GROUP 90.89，orch 独立
  核对 doc/evidence/v0.4.9/M4-coverage-baseline.md 表格逐位吻合），证明
  数据库确系真实 instrumented。
- **4 模块并行逐位分解**：每个模块独立读 urg Toggle Port Details 报告 +
  RTL 逐信号核实语义。关键发现——
  - `axi_mux` 是唯一被标"载荷候选"的模块：`mst_resp_i.r.data[63:0]`
    （散布 ~30/64 位未双向翻）。同模块 `mst_req_o.w.data[63:0]` 与
    `id[7:0]` 前缀+原ID 两段经核实**已 100% 覆盖、非缺口**，直接反驳
    REV-024 把 W/R.data 打包处理的假设。
  - `axi_xbar` 顶层核实"0 载荷位"——54 个 toggle 位全是窄控制/配置
    （clk/rst/test/en_default/default_mst_port），载荷 toggle 转移到子
    模块度量，无残余宽载荷缺口。
  - `axi_demux_simple` 写载荷 100% 覆盖，读载荷 87.5%（8 位残），主导
    缺口是属性字段（119/225 bin）与地址（67/225 bin），均非载荷类。
  - `axi_err_slv` 入侧写载荷 100% 覆盖；出侧发现三处**恒定常量输出**
    （`r.data=RespData`、`r.resp/b.resp=Resp`、`user` tie-off）——
    结构性 Kind-A，非 Kind-B。
- **对抗性核实**：唯一"载荷候选"（axi_mux R.data）被 3/3 独立怀疑者
  反驳——核心证据：TB `predict_beat_data` 返回 `{beat_a,beat_a}`（32-bit
  地址镜像拼成 64-bit），R.data 实际由读地址决定、并非不透明随机载荷；
  toggle 覆盖每位只需 all-0/all-1 两个饱和向量即可翻遍，根本不需要
  "扫大量互异取值"，故不满足 Kind-B 判据(2)"纯定向不经济"。
- **REV-025（独立 rev 实例）复核**：亲验 `axi_err_slv.sv`/
  `axi_xbar_unmuxed.sv`/`xbar_types_pkg.sv`/`mstport_agent.sv`/
  `seq_lib.sv` 具体行号，确认综合报告结论成立且比报告自述更强（R.data
  的判据(1)"纯载荷"本身也不成立，两判据双失）。Conditional pass，三条
  应用条件：仅新增 Kind-A A-1/A-2/A-3；size[2] 暂缓转正（须先确认 cfgA-E
  全部配置数据总线 ≤64 位）；订正报告一处内部措辞不一致。
- **orch 独立复验**（不采信自报）：亲读 `axi_err_slv.sv:23-27/145/
  188-198` 确认三个常量赋值点；亲读 `axi_xbar_unmuxed.sv:195-211` 确认
  两处例化点均未 override `RespData`；亲读 `xbar_types_pkg.sv:374-385`
  确认 `predict_beat_data` 返回值；亲读 `seq_lib.sv:32-35` 确认 wdata 用
  `$urandom` 随机填充；交叉核对覆盖率数字与 v0.4.9 基线逐位一致。
- **orch 应用**：`doc/coverage-waivers.md` 新增 CW-003/004/005（err_slv
  三条 Kind-A，引 REV-025）；Kind-B 模板行保留但注明"当前结论为空集"；
  待建档区新增 size[2] 条目（附暂缓理由）；`doc/bugs/BUG-0047.md` 标记
  逐位分解前置已完成、清单 B 已具体化到信号/位段级。产出
  `doc/evidence/v0.4.15/M4-toggle-bit-decomposition.md`（完整分解报告 +
  4 模块附录）+ `doc/review/REV-025.md`（仲裁记录）。
- `make check`/`make selftest`（61/61）复跑绿。

**Not done**
- **清单 B**（约 6 类具体信号/位段，已在证据文件里具体化到信号级）仍
  需逐条派 DV 定向覆盖卡——不因本次分解免除，反而更精确（如 axi_mux/
  demux 的 r.data 现在明确知道"定向饱和读 all-0→all-1 即可闭"，不再是
  笼统的"需补场景"）。
- size[2] Kind-A 候选转正前需要一次跨配置（cfgA-E）数据总线宽度确认。
- M4 仍未签核（REJECTED 判决未变，本轮工作是把"该走哪条路"这件事从
  猜测变成了有逐位证据支撑的确定结论——净结果是收窄了处置空间：没有
  Kind-B 可用，全部要么已覆盖、要么走 Kind-A、要么得真去补场景）。

**Next**
- 用户已完成本轮方法学张力优先项。下一步需用户决定：是逐条铺开清单 B
  的 DV 定向覆盖卡（现在已经有信号级精确指引），还是先处理 size[2] 的
  跨配置确认，或是先看其它待建档 Kind-A 项（`rst_ni`、
  `spill_register` tie-off）。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- 覆盖率数字交叉核对：本次刷新的基线聚合数字与 v0.4.9 报告逐位一致。
- REV-025 亲验的全部 RTL/TB 行号，orch 二次独立核对（见 Done 段），
  均准确无误。
- 本周期产生真实仿真（make regress COV=1，26/26），但非 testplan 场景
  评审——不涉及 evidence.py 登记，是覆盖率测量性质的证据文件。

## [0.4.15] 2026-08-01 BUG-0047 方法学张力仲裁应用——建 doc/coverage-waivers.md、milestone.md M4 追加 Kind-A/Kind-B 豁免框架，划界远比表面窄

**背景**：用户对 BUG-0047（M4"六类含 Toggle≥90%"vs"M5 前仅定向"的可行性
张力）给出方向性意见——"定向能做到的都做到，不强制要求全部 90%"。派
REV-024 独立仲裁，特别要求它自行核实用户意见的适用范围，不得被用来
夹带真正"没写场景"的缺口。

**Done**
- **REV-024（L3/opus，独立 rev 实例）**逐条独立划界（核对
  `M4-coverage-baseline.md` §6 九行 + 亲读 RTL 结构 `axi_xbar.sv:92`/
  `axi_mux.sv:33/39`）：**BUG-0047 的方法论受限面远比表面窄**——证据
  里 ~6 类"可达未测"缺口中，**仅宽 W/R.data 载荷位翻转属方法论受限**
  （当前只有 `axi_mux` Toggle 子集有明确结构依据：承载 64-bit
  `w_chan_t`/`r_chan_t`）；`addr_decode_dync`（地址/rule 多样性不足，
  非载荷）、`axi_xbar` 的 `default_mst_port_i`（6×3-bit 窄索引，非
  载荷）、各 Cond/Branch/Assert、握手背压、实例级颗粒度**均不属，
  维持需补场景**——这正是防止用户方向性意见被夹带滥用的关键划界。
  **顺带纠正一处记录失实**：BUG-0047 原表述"位翻转组合数随总线宽度
  指数增长/组合爆炸"是错误框架——Toggle 覆盖逐位线性（2×width），
  真正原因是"定向用例只用少数固定取值，多数载荷位未双向翻转"；错误
  框架会把它推向永久结构豁免，正确框架才支撑"临时、可 M5 解锁"处置。
  **处置**：不扩展 pinned spec §0 三态（测量规则与豁免种类正交，更
  外科、免重 pin）；改为 `doc/milestone.md` M4 追加子项 + 新建
  `doc/coverage-waivers.md`，引入 Kind-A（结构/环境不可达，永久，
  给可证伪不可达论证）/ Kind-B（方法论受限延后 M5，临时，可证伪解锁=
  M5 约束随机重测后若仍<90%才议）双类豁免框架。**本裁决不预先授予
  任何 Kind-B 豁免**——须先有逐信号/逐位 toggle 分解证据；**M4 签核
  REJECTED 判决因此整体仍然成立**，本裁决只给出合法出口框架、不清空
  残余。taxonomy 终判 SPEC_CHANGED（治理文档订正，非 pinned-spec 行为
  条款改动）。
- **orch 应用裁决**（独立复核）：`doc/milestone.md` M4 节追加 Kind-A/
  Kind-B 豁免框架子项；新建 `doc/coverage-waivers.md`（CW-001
  atop_filter FSM 环境约束 + CW-002 test_i scan 两条 Kind-A 已就绪，
  Kind-B 留模板待逐位分解卡产出证据后填）；`doc/bugs.md` BUG-0047 行
  `OPEN → SPEC_CHANGED`（**未跑 `docs.py --pin-spec`**——本条不改
  `doc/spec.md` 正文，重 pin 会是误操作，已用 `git diff doc/spec.md
  doc/spec.sha256` 确认二者确实未变）；`doc/bugs/BUG-0047.md` 订正
  `## rca` 里"组合爆炸"表述、新增 `## arbitration` 段、收紧
  `## regression_guard`（Kind-B 登记前置 = 逐位分解证据，且明确点名
  哪些条目不得被误记为 Kind-B）。
- `make check`/`make selftest`（61/61）复跑绿。

**Not done**
- Kind-B 豁免尚无任何一条正式登记——需要先派一张**逐位 toggle 分解卡**
  （`axi_mux`/`axi_xbar`/`axi_demux_simple`/`axi_err_slv`），把"宽载荷
  位"与"定向可达位"分开，才能据此填 `doc/coverage-waivers.md` 的
  Kind-B 行。
- "清单 B"（`addr_decode_dync` 等"可达未测"缺口）仍需逐条派 DV 定向
  覆盖卡，不因本次裁决免除。
- M4 仍未签核（REJECTED 判决未被本次裁决推翻，只是收窄了残余、给出
  了框架）。

**Next**
- 用户已表态优先处理方法学张力，本轮已完成。下一步需用户决定：是先
  派逐位 toggle 分解卡（Kind-B 路径的前置），还是先铺开"清单 B"的
  DV 定向覆盖卡，或是先处理其它 Kind-A 候选项（`axi_err_slv` 恒定
  应答位、`rst_ni`、`spill_register` tie-off）的豁免论证。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- `git diff doc/spec.md doc/spec.sha256`：均无输出，确认未误改/误重 pin。
- 本周期无仿真运行（纯治理文档订正+登记），无新增 sim evidence。

## [0.4.14] 2026-08-01 M4 完整签核卡：REJECTED——四条机器门禁全绿不等于签核，覆盖率定义性出口条件未满足；新登记 BUG-0047（判据可行性张力）

**背景**：0.4.9-0.4.13 五个周期把 `make check MILESTONE=4` 的四条机器
门禁逐条转绿（场景 ✅、regress evidence、bug 终态、KILL 覆盖）。本周期
派出全套 rev 签核 rubric 卡，本以为是收尾的最后一步，结果卡本身给出了
**REJECTED** 判决——这是本轮 M4 收尾里最重要的一次纠偏：机器门禁全绿
从未等于"可以签核"，签核判的是"证据是否支撑风险已收敛"。

**Done**
- **M4 完整签核卡（L3/opus，fresh instance，与本轮全部 M4 相关卡作者
  均不共享）**产出 `doc/evidence/v0.4.13/signoff-M4.md`。逐项：
  - **机器条件（rubric #1-4）**：亲跑确认全绿，但明确指出机器脚本
    `scripts/docs.py` **不检查覆盖率百分比**——四条绿只覆盖"场景/
    证据/bug 状态/KILL"，不覆盖 M4 的定义性出口条件本身。
  - **rubric #5**（coverage closure≠risk closure）：挑 3 个良好命中
    bin 逐一核实确系预期场景命中（含 `axi_mux` 仲裁重试路径的
    "模块级 100% 实为跨 8 实例并集、实际仅 1/8 端口真转绿"这一颗粒度
    警示）；重读 atop_filter 环境约束不可达论证并**活体证伪**佐证
    （注入 atop 到未命中地址后 FSM 确实 engage）。
  - **rubric #6**（guard 消费+证伪）：实地证伪 BUG-0032 guard——注入
    `atop=6'h30` 到 M3-DE01 未命中序列，`SB_ATOP_DECODE` 6 端口报红；
    恢复后 `git diff` 净。
  - **rubric #7/#8**（spec debt / accepted debt）：BUG-0044/0045/0046
    均确认有可证伪解锁条件、非软承诺。
  - **rubric #9**（chain audit）：逐类给处置意见。
  - **REV-017 条件 3 正式兑现**：atop_filter FSM 书面豁免（逐弧列出
    未覆盖状态/迁移，行号对当前 vendor 树逐条复核——orch 独立复验
    `grep vendor/axi/src/axi_atop_filter.sv` 确认 BLOCK_AW:151/
    HOLD_B:161/INJECT_B:163/ABSORB_W:167/WAIT_R:228/R_HOLD:275/
    INJECT_R:281 全部准确）+ BUG-0032 guard 机械抽查（grep + 计数=0
    两种形态均满足）。
  - **核心否决理由**：M4-coverage-baseline.md §6 的 ~9 类残余缺口里
    只有 2 类得到合法处置（atop_filter 环境约束豁免 + addr_decode/
    axi_demux 结构性 N/A），其余 ~6 类（`axi_demux_simple`/
    `addr_decode_dync`/`axi_mux` Toggle/`axi_err_slv`/`spill_register`
    等）是"可达但未测"——按 REV-016 §9，豁免须给可证伪的不可达论证，
    这些是"没测"非"测不到"，**不可合法豁免，必须补定向场景**。
  - **附带发现并建议登记的方法学张力**：M4 出口条件"六类含 Toggle
    ≥90%"与项目"M5 前仅定向、随机不得替代 M4 定向关闭"纪律叠加，对
    宽 AXI 总线的 Toggle bin 产生可行性冲突——两条规则各自无误，组合
    时无解，需 rev/arch 后续裁决扩展豁免框架或重议判据口径。
- **orch 独立复验**（不采信卡内自报）：`git status`/`git diff` 确认
  falsification 改动已完全恢复；`make check MILESTONE=4` 复跑确认四条
  仍绿、签核文件条目转"yes"；`grep vendor/axi/src/axi_atop_filter.sv`
  逐行核对 FSM 豁免的 7 处行号（100% 命中）；`sed` 核对 BUG-0032
  guard 的注入点（`tb/seq_lib.sv:962` `atop='0`）与检测点
  （`tb/scoreboard_refmodel.sv:469-472` `SB_ATOP_DECODE`）均如实存在。
- **orch 按无条件登记纪律登记 BUG-0047**（OPEN，spec，SPEC_ISSUE 候选，
  非本条自身触发失败——是签核卡的附带发现）：M4 出口条件与"M5 前仅
  定向"纪律的可行性张力，详见 `doc/bugs/BUG-0047.md`。
- `make check`/`make selftest`（61/61）复跑绿。**`doc/milestone.md` M4
  状态维持 🔲，不转 ✅**（rev 明确裁决，未由 orch 越权改动）。

**Not done**
- M4 仍未签核。REJECTED verdict 给出的后续方向（signoff 记录已列，
  非本周期落地）：
  1. DV 定向覆盖卡（针对 ~6 类"可达但未测"缺口，逐（模块,类型）补
     spec 引用+可证伪具名场景）；
  2. rev 覆盖率豁免卡（先建 `doc/coverage-waivers.md`，为 `rst_ni`/
     `test_i` scan/AW valid-but-not-ready 断言类等真正需要论证的项
     出具可证伪不可达论证）；
  3. **BUG-0047 方法学张力裁决**（arch/rev，二选一：成本豁免扩展 /
     重议 Toggle 判据口径）——这条建议先走，因为它决定其余 Toggle
     类缺口该走"补场景"还是"豁免"这条路；
  4. feature-matrix 补 4 行（M4-RC01/AW01/OV01/FT01，chain audit
     既有 gap）。
- 上述四项工作量不小，且互相有依赖（尤其 3 影响 1 的范围），需要用户
  确认优先级/是否现在就铺开，不是一次性能收尾的小任务。

**Next**
- 向用户汇报 REJECTED 判决全貌，请用户决定：先处理 BUG-0047 方法学
  张力裁决，还是先铺开 DV 定向覆盖卡补场景，还是先建
  `doc/coverage-waivers.md` 做豁免分诊，或调整 M4 出口条件本身的
  优先级安排。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- `make check MILESTONE=4`：4/4 机器门禁仍 PASS（signoff 文件条目
  转"yes"，但 verdict 本身是 REJECTED——机器门禁与签核判断是两回事，
  本周期最大的一次认知纠偏）。
- 独立复验详见 Done 段——FSM 行号逐条 grep 核对、guard 注入/检测点
  逐行核对、falsification 恢复用 git diff 核实为空。

