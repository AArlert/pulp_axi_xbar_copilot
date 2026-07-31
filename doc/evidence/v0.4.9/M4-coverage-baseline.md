# M4 六类覆盖率基线（重出，REV-016 条件 2 兑现；对照 v0.4.0）

首行重放（本轮方法论已简化——见 §0）：

```
cd sim && make clean && make regress COV=1
# 26/26 PASS（20 个 M1-M3+M4 基线拓扑场景 + upstream_sanity + cfgA/B/C/D/E）

# 逐组出 urg 报告（BUG-0037 修复后，COV_DIR 已按拓扑正确分流到 7 个互不
# 干扰的 cov.vdb；仍需用 TEST=/OUT= 挑一个该组内任意成员，让 Makefile 的
# ifeq 分支解出正确的 COV_DIR——不能裸跑 `make cov`，因为 TEST 缺省值
# upstream_sanity 会把裸调用解到 out/m0/cov.vdb，见 §0 脚注）
make cov TEST=m1_01_smoke_test          # 基线拓扑合并（20 场景，out/cov.vdb）
make cov TEST=upstream_sanity           # M0（out/m0/cov.vdb）
make cov TEST=m3_cf01_cfga_test         # cfgA（out/cfgA/cov.vdb）
make cov TEST=m3_cf02_cfgb_test         # cfgB
make cov TEST=m3_cf03_cfgc_test         # cfgC
make cov TEST=m3_cf04_cfgd_test         # cfgD
make cov TEST=m4_ft01_cfge_test         # cfgE（M4-FT01 专属配置点）
```

上述全部命令均已在本 VM 亲跑（VCS-MX O-2018.09-SP2）。每次 `make cov` 后即
grep 生成日志（`sim/cm.log`，urg 实际写入位置——不是 stdout tee，这点与
v0.4.0 报告一致）里的 `mismatch`/`CMR-VCINF`/`UCAPI-INSTANCEMISMATCH`，
**7 组全部 0 命中**（唯一一条非 mismatch 类告警：cfgD 报
`Warning-[UCAPI-SNF] 'Fsm' coverage shape is not there in the vdb`——这是
`ATOPs=1'b0` 下该配置点根本不例化 `axi_atop_filter` 的结构性事实，不是
BUG-0037 类合并告警，与 v0.4.0 §4 注 3 对 cfgD 的记录一致）。

## 0. 独立判断 1：现有 `sim/out` 覆盖率数据库能否复用？—— 不能，已重跑

核实过程：读 `sim/out/comp.log` 里记录的 VCS 编译命令行（时间戳
2026-08-01 00:03:09，本卡开始前最后一次编译），命令行里**没有** `-cm`
旗标——即当时的 `simv`/`out/cov.vdb` 是一次**非 `COV=1`** 的编译产物（大概率
是 orch 会话内先前为核对 M4-RC01/诊断 BUG-0043 反复跑的 `make run`/`make
regress` 遗留），不满足"干净 `COV=1` 全量回归"的前提。**因此按卡片指示重新
跑**：`cd sim && make clean && make regress COV=1`（§0 命令①），而非复用。

## 1. 独立判断 2：BUG-0037 修复后，三组隔离方法论是否仍必要？

**结论：命令层面已简化为一条 `make regress COV=1`（不再需要手写 `CM=
"-cm_dir out/cfgX/cov.vdb"` 命令行覆盖），但产出侧仍是"按拓扑分组读取"
而非"单一数字"**——这不是走回头路，是 BUG-0037 修复本身的设计意图
（见 `doc/bugs/BUG-0037.md` `## fix`）：`COV_DIR` 间接层让 `override
OUT`（cfgA-D/E）和显式 `COV_DIR :=`（M0）在 `run:`/`compile:` recipe
执行时各自解到独立的 `cov.vdb`，`make regress COV=1` 一次性把 26 个场景
的覆盖率正确写入 7 个互不合并的库，不再需要 DV 手动 `rm -rf out/cfgX`
+ 逐条 `CM=` 覆盖。

**新发现的操作细节（非缺陷，记录以便后续复用）**：`make cov`（裸调用，
不带 `TEST=`）会因 `TEST` 缺省值 `upstream_sanity` 解到 `ifeq
($(TEST),upstream_sanity)` 分支，读到 `out/m0/cov.vdb`——这是 BUG-0037
修复给 M0 单开 `COV_DIR` 分支的直接后果，不是新缺陷；查询任一其他组
时须显式传一个落在该组的 `TEST=`（或该组的 `OUT=`，但后者要小心：
`OUT=out/cfgA` 配合缺省 `TEST` 仍会先进 upstream_sanity 分支算出
`out/cfgA/m0/cov.vdb`，踩到同一个坑——已亲测踩中并改用 `TEST=`
选择法绕开，见下方 `## 附：一次踩坑记录`）。这条已口头验证但不构成
`failure_taxonomy.md` 里任何一类异常（脚本行为符合其自身设计意图，
只是没写操作文档），不登记新 bug，仅在此记录供下次操作参考。

## 2. 场景状态（26/26 PASS）

```
pulp_axi_xbar_copilot regression  date=2026-08-01  passed=26/26
PASS   upstream_sanity SEED=1
PASS   m1_01_smoke_test SEED=1
PASS   m1_02_id_prefix_test SEED=1
PASS   m2_cfg01_reconfig_test SEED=1
PASS   m2_or01_stall_test SEED=1
PASS   m2_or02_nonstall_test SEED=1
PASS   m2_or03_guard_test SEED=1
PASS   m2_tl01_txlimit_test SEED=1
PASS   m2_tl02_slvtrans_test SEED=1
PASS   m2_wo01_worder_test SEED=1
PASS   m2_at01_atop_test SEED=1
PASS   m3_de01_decerr_test SEED=1
PASS   m3_de02_default_test SEED=1
PASS   m3_or04_order_test SEED=1
PASS   m3_or05_range_test SEED=1
PASS   m3_cf01_cfga_test SEED=1
PASS   m3_cf02_cfgb_test SEED=1
PASS   m3_cf03_cfgc_test SEED=1
PASS   m3_cf04_cfgd_test SEED=1
PASS   m3_at02_atop_read_test SEED=1
PASS   m3_tl01_xbucket_test SEED=1
PASS   m3_cfg02_reconfig_test SEED=1
PASS   m4_ov01_overlap_test SEED=1
PASS   m4_ft01_cfge_test SEED=1
PASS   m4_rc01_reclose_test SEED=1
PASS   m4_aw01_awbp_test SEED=1
```

未撞见 BUG-0043（"日志干净但进程非零退出"）同型号现象——`regress.py`
本身以 `rc==0` 且 26/26 判为 PASS 结束，无需在 `doc/bugs/BUG-0043.md`
追加出现记录。

## 3. 六类总体基线（7 组，整个已编译设计，未按 DUT 范围过滤；GROUP 仅供
参考，按 REV-011 §3.3/milestone.md 不计入判据）

| 集合 | 场景数 | LINE | COND | TOGGLE | FSM | BRANCH | ASSERT | GROUP(参考) | mismatch |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **基线拓扑合并（本报告主数字，6x8）** | 20（较 v0.4.0 的 17 多 3：新增 M4-RC01/AW01/OV01） | 80.84 | 71.66 | 47.87 | 7.14 | 82.99 | 78.62 | 90.89 | 0 |
| M0 upstream_sanity | 1 | 81.34 | 78.32 | 70.55 | 7.14 | 83.91 | 87.18 | n/a | 0 |
| cfgA（1×8，NO_LATENCY） | 1 | 69.69 | 54.21 | 28.09 | 7.14 | 73.01 | 55.93 | 27.11 | 0 |
| cfgB（6×1，CUT_ALL_PORTS） | 1 | 70.06 | 55.38 | 40.46 | 7.14 | 68.95 | 56.44 | 30.44 | 0 |
| cfgC（4×4，UniqueIds=1） | 1 | 77.17 | 59.18 | 34.59 | 7.14 | 77.60 | 64.12 | 27.11 | 0 |
| cfgD（4×4，稀疏 Connectivity，ATOPs=0） | 1 | 67.73 | 57.87 | 34.66 | （空白，结构性，ATOPs=0 不例化 atop_filter） | 69.66 | 65.43 | 30.44 | 0 |
| **cfgE（同基线；`FallThrough=1'b1`，M4-FT01 新增，v0.4.0 无此行）** | 1 | 77.03 | 60.87 | 36.43 | 7.14 | 77.85 | 68.88 | 30.44 | 0 |

**注**：M0/cfgA/B/C 数字与 v0.4.0 几乎逐位相同（cfgA/B/C 的 LINE/BRANCH/
ASSERT 有 ±0.05~0.65pp 的细微下降，例如 cfgA LINE 70.04→69.69）——根因
不是 cfgA 本身场景变了（M3-CF01 场景内容未改），而是 `tb.f` 全量编译
单元里新增了 M4 四条场景的 seq/sva 代码，把"整个编译设计"（分母含
tb 脚手架）的总代码行数拉大，cfgA 场景本身没有练到这些新增 tb 代码
（因为 cfgA 只跑 `m3_cf01_cfga_test`），所以分子不变、分母略增、百分比
略降——**这是"整个编译设计"口径的正常噪声，不代表 cfgA 本身覆盖率
退步**；DUT 范围口径（§4）不受此噪声影响，因为 DUT 端模块的代码本身
未变。

## 4. 按模块细分（DUT 范围，spec §0#4 例化闭包口径；数字取自基线拓扑
20 场景合并报告，逐模块列出）

### 4.1 顶层与强制内部子模块（沿用 v0.4.0 §3 结构）

| 模块 | 实例数 | Line | Cond | Toggle | FSM | Branch | Assert |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `axi_xbar`（顶层） | 1 | N/A（无本体过程代码） | N/A | **40.74**（v0.4.0: 29.63，↑11.11pp） | N/A（自身无 FSM） | N/A | 100.00 |
| `axi_xbar_unmuxed` | 1 | N/A（纯 generate 例化壳） | 100.00 | **88.15**（v0.4.0: 85.93，↑2.22pp） | N/A | 100.00 | 53.85（不变，26 attempted/14 real-succeeded，见 §5 第 2 条） |
| `addr_decode` | 12 | N/A（结构性，BUG-0038 已终判） | N/A | 43.90~50.00（v0.4.0: 43.90~48.78，个别实例 ↑1.22pp） | N/A | N/A | N/A |
| `axi_demux` | 6 | N/A（同上） | N/A | 62.32~63.19（v0.4.0: 62.01~63.19，基本持平） | N/A | N/A | N/A |
| `axi_mux` | 8 | **100.00**（v0.4.0: 72.41，↑27.59pp，见 §5 第 1 条） | **100.00**（v0.4.0: 85.71~100.00） | 55.75~58.63（v0.4.0: 56.24~58.63，持平） | N/A（组合 rr_arb_tree，非本报告口径 FSM） | **100.00**（v0.4.0: 71.43，↑28.57pp） | 100.00（不变） |
| `axi_err_slv` | 6 | 100.00（不变） | 83.33（不变） | 42.37~44.07（v0.4.0: 42.37~43.93，持平） | N/A | 100.00（不变） | 100.00（不变） |
| `axi_atop_filter` | 6 | 46.36（不变） | 35.48（不变） | 40.34（不变） | **7.14（不变，见 §5 第 3 条——M4 未新增任何 ATOP 场景）** | 34.78（不变） | 100.00（不变） |

### 4.2 REV-016 澄清后首次单独测量的例化闭包子模块（BUG-0038 裁决落地，
v0.4.0 未曾单列——本节数字是本轮新增的测量粒度，非"变化"）

| 模块 | 实例数 | Line | Cond | Toggle | FSM | Branch | Assert |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `addr_decode_dync`（`addr_decode` 内真正承载逻辑的子模块） | 12 | 100.00 | 100.00 | 53.00~57.00 | N/A（无 FSM 构造） | 83.33 | 100.00 |
| `axi_demux_simple`（`axi_demux` 内真正承载逻辑的子模块） | 6 | 83.72 | 72.41~75.86 | 68.42~69.30 | N/A | 77.78 | 50.00（14 条 assert，7 条 real-succeeded 0 次，见 §5 第 4 条） |
| `axi_multicut` | 1 | N/A | 55.96 | N/A | N/A | N/A | 100.00 |
| `axi_cut` | 4（`PipelineStages=1` 时每 master 端口 1 个） | N/A | 55.96 | N/A | N/A | N/A | N/A |
| `spill_register`（`axi_cut`/`axi_demux` 内共同例化的 common_cells 原语） | 多例 | N/A | 65.16 | N/A | N/A | N/A | N/A |

## 5. 差距最大的具体缺口——较 v0.4.0 逐条核对，如实报告改善/未改善

**1. `axi_mux.sv:292-298/308-309/315`（AW 仲裁"下游背压后锁定重试"路径）
——已被 M4-AW01 完全覆盖，v0.4.0 头号 Line/Branch 缺口彻底关闭**
- 逐行核查 `mod19.html`（urg module 页）：`lock_aw_valid_q`/`load_aw_lock`
  相关全部行现均 `1/1`（Line 覆盖），`if (lock_aw_valid_q)`/
  `if (mst_aw_ready)` 分支 `MISSING_ELSE` 之外均命中。
- **重要澄清（避免"模块级 100% ⇒ 全部 8 个实例都测到"这一过度解读）**：
  模块级数字是**跨 8 个实例的并集**（VCS module-definition coverage 语义，
  与 v0.4.0 报告口径一致，非本轮引入的新算法）。查 `mod19.html` 的
  per-instance 表：只有 `gen_mst_port_mux[0].i_axi_mux`（M4-AW01 实际
  背压的那个 master 端口）达到 Line/Cond/Branch 全 100.00，其余 7 个实例
  （`gen_mst_port_mux[1..7]`）仍停留在 Line 72.41/Cond 85.71/Branch 71.43
  ——与 v0.4.0 数字逐位相同。故本条改善是"模块级判据已达标"（满足
  spec §0 item4"判定单位=（模块,类型）二元组，取子树内全部实例合并值"
  的字面要求），但**不是"8 个实例均已覆盖该路径"**——如需后者，需要
  M4-AW01 式背压覆盖全部 8 个 master 端口，testplan 未要求、本报告
  仅如实注明这一实例级颗粒度差异。

**2. `axi_xbar_unmuxed` 内建 Assert `default_aw_mst_port`/
`default_aw_mst_port_en`（6 实例）—— 仍 0 real-succeeded，M4-RC01
未能改善（与其 testplan 行"DV 核对项（非阻塞）"预告的核对结果一致）**
- 逐实例核对 `mod8.html`：6 个 `gen_slv_port_demux[i].default_aw_mst_port`
  /`_en` 的 Attempts=4919、Real Successes=**0**、Failures=0——与 v0.4.0
  记录的数字（Attempts=4542，因本轮多 3 个 baseline 场景 attempts 数增至
  4919，但 real-succeeded 依旧为 0）同构未变。对照组 AR 侧
  `default_ar_mst_port`/`_en` 6 实例仍为 Real Successes=48（不变）。
- **事实核实（读 RTL 属性定义得到，仅用于理解"real-succeeded"这一指标
  含义，未用于任何 checker 期望值）**：该 assert 的前提
  (`slv_ports_req_i[i].aw_valid && !slv_ports_resp_o[i].aw_ready`)
  只有在 demux **slave 端口侧** AW 出现"valid 但未被 ready"（即该
  slave 端口的 AW 请求本身被 demux 内部拒收/延迟接受）时才算一次
  非空转匹配；M4-RC01 背压的是**已使能 default port 关闭后走 err_slv
  的应答路径**，未在 slave 端口 AW 接受阶段本身制造背压，故其对这条
  assert 的匹配条件天然不触达——与该 testplan 行"非阻塞核对项"的预期
  相符，不升级为新缺陷。
- **同源现象扩大到 `axi_demux_simple`（本轮首次单独测得，§4.2）**：
  该模块 14 条内建 assert 里 7 条（`ar_valid_stable`/`aw_valid_stable`/
  `slv_ar_chan_stable`/`slv_ar_select_stable`/`slv_aw_chan_stable`/
  `slv_aw_select_stable`/`NoAtopAllowed`）Real Successes 均为 0，
  Attempts=29514——同一类"该端口这一拍从未处于"valid-but-not-ready""
  现象的独立佐证（`NoAtopAllowed` 为另一根因：`AtopSupport=1` 配置下
  该 assert 的触发前提本身构造性不可达，与 ATOP 支持配置有关，非本条
  同源）。**不重复登记新 bug**——与 M3-DE02/BUG-0025 既有债务同根，
  testplan M4-RC01 行已预告"非阻塞"性质。

**3. `axi_atop_filter` FSM（w_state_q 2/7 状态、1/20 迁移；r_state_q
2/4 状态、1/8 迁移）—— 逐状态/迁移弧核对，与 v0.4.0 完全一致，M4 四条
新场景均未触达**
- 未覆盖状态与行号核对结果同 v0.4.0：`ABSORB_W`(:167)、`BLOCK_AW`(:151)、
  `HOLD_B`(:161)、`INJECT_B`(:163)、`WAIT_R`(:228)（w 侧）、
  `INJECT_R`(:281)、`R_HOLD`(:275)（r 侧）。
- 符合预期——M4-RC01/AW01/OV01/FT01 四条场景分别针对 default port
  运行时关闭、mux 仲裁背压、地址表重叠 rule、`FallThrough` 配置点，
  **均不涉及 ATOP AtomicStore/AtomicCompare 编码**（`tb/seq_lib.sv`
  全仓库 ATOP 序列仍只用 `ATOP_LOAD_ADD`，见 v0.4.0 §4 第 1 条根因，
  本轮未新增任何 ATOP 序列变体）。这与 spec Change record #10
  （BUG-0039/REV-017）"M4 覆盖率后果"条款描述的**环境约束致不可达**
  分类完全对应——该条款要求 rev 在 M4 签核时对此出具书面豁免（REV-017
  条件 3），本报告到此为止未见该豁免已兑现的证据，**仍是待兑现项**，
  不在本卡范围内处理，转交 orch。

**4. `addr_decode`/`axi_demux`（各 12/6 实例）Line/Cond/Branch/Assert
结构性 N/A —— 判定不变（BUG-0038 已终判为 SPEC_CHANGED，例化闭包澄清
后其"可覆盖逻辑"归属子模块 `addr_decode_dync`/`axi_demux_simple`）**
- 本轮首次按 REV-016 裁决的例化闭包口径单独测量了这两个子模块（§4.2），
  数字见上表——`addr_decode_dync` Line/Cond/Assert 均 100%，Branch
  83.33%，Toggle 53~57%；`axi_demux_simple` Line 83.72%、Cond
  72.41~75.86%、Branch 77.78%、Assert 50.00%（Toggle 68.42~69.30%）。
  这些数字回答了 v0.4.0 §4 第 3 条遗留的问题（"这两个子模块的真实覆盖率
  是多少"）——**均未达到 spec §0 item4 的 ≥90% 门槛**，是本报告新增的
  实质性残余缺口（不是"结构性 N/A"，是"有 bin 但 <90%"，需要下一步补
  场景或书面豁免，见 §6）。

**5. `axi_xbar`（顶层）Toggle 40.74%（v0.4.0: 29.63%，↑11.11pp）——
`en_default_mst_port_i[5:0]` 的 1→0 方向已被 M4-RC01 补齐，
`default_mst_port_i[*][*]` 具体 bit 与 `rst_ni` 仍未**
- 逐信号核对 `mod39.html` Toggle Port Details：`en_default_mst_port_i
  [5:0]` 现 **Toggle 1->0 = Yes**（v0.4.0 明确记录"只 0→1、从未 1→0"，
  本轮由 M4-RC01"运行时把已使能 default port 关闭"直接补齐——是本报告
  唯一一处逐信号可验证的"场景关闭了 v0.4.0 点名缺口"的例子）。
- 仍未覆盖（v0.4.0 同款记录，未变）：`rst_ni`（本仓库回归里没有任何
  "运行中二次复位"场景，见 §7 沿用）、`default_mst_port_i[1][0]`/
  `[2][1]`/`[3][1:0]`/`[4][2]`/`[5][0]`/`[5][2]` 等具体 bit 的 1→0
  方向——**M4-RC01 只把 `en_default_mst_port_i` 位从 1 改回 0，未在同一
  次运行里把 `default_mst_port_i` 索引本身从非零值改回 0**（testplan
  M4-RC01 行原文"关闭（位 1→0）**并/或**把索引改回更低值"是"或"关系，
  实际落地大概率只做了前者）；`test_i` 全程 0（scan 模式未激励，非
  缺口，与 v0.4.0 相同）。

## 6. 残余缺口清单与三态判定（spec §0 item4；逐条区分"结构性 N/A（不入
分子分母）"/"需补场景"/"需 rev 书面豁免"）

| 模块 | 类型 | 数值 | 判定 | 下一步 |
| --- | --- | --- | --- | --- |
| `axi_xbar` | Toggle | 40.74% | 有 bin，<90% | 需补场景（`default_mst_port_i` 具体 bit 双向翻转）+ 一处结构性豁免候选（`rst_ni` 无热复位场景、`test_i` scan 模式不在验证范围） |
| `axi_xbar_unmuxed` | Assert | 53.85% | 有 bin，<90% | 需补场景或书面豁免（AW 侧 default port assert 需要 slave 端口 AW valid-but-not-ready 的构造，现有 M4-RC01 未覆盖此条件，见 §5 第 2 条） |
| `addr_decode`/`axi_demux`（父模块） | Line/Cond/Branch/Assert | 空白 | N/A（结构性，纯例化壳，已核实成因＝无过程语句，BUG-0038 终判） | 不适用；判据转交 `addr_decode_dync`/`axi_demux_simple` |
| `addr_decode_dync` | Toggle/Branch | 53~57% / 83.33% | 有 bin，<90% | 需补场景（更多样地址/rule 组合、边界条件分支） |
| `axi_demux_simple` | Line/Cond/Branch/Assert | 83.72% / 72~76% / 77.78% / 50.00% | 有 bin，<90% | 需补场景；Assert 50% 主要是"valid-but-not-ready 稳定性"类断言从未非空转匹配，需要专门构造 slave 端口侧 AW/AR 阶段的持续背压（而非当前场景的下游/mux 侧背压） |
| `axi_mux` | Toggle | 55.75~58.63%（模块级并集，不区分实例） | 有 bin，<90% | 需补场景（ID/地址/数据位更广泛翻转，非本卡范围） |
| `axi_err_slv` | Cond/Toggle | 83.33% / 42~44% | 有 bin，<90% | 需补场景 |
| `axi_atop_filter` | Line/Cond/Toggle/FSM/Branch | 46.36/35.48/40.34/7.14/34.78 | **有 bin，<90%，环境约束致不可达（REV-017 M4 覆盖率后果条款）** | **需 rev 签核书面豁免（REV-017 条件 3，尚未兑现）**——不属本卡范围，转交 orch |
| `axi_multicut`/`axi_cut`/`spill_register` | 除 Cond/Assert 外全空白 | Cond 55.96%~65.16% | 部分 N/A（结构性，父子透传壳）+ 部分有 bin<90%（Cond） | Cond 需补场景；空白维度成因已核实（同 addr_decode 模式，纯例化透传） |

## 7. covreset 说明（沿用 v0.4.0，未变——本仓库回归里仍无"运行中热复位"
场景）

同 v0.4.0 §5 原文：`sim/regress/regress.list` 26 个场景（含新增 3 个
M4 基线拓扑场景 + 1 个 cfgE）里仍没有一个是专门的"运行中复位"测试，
`rst_ni` 在全部场景里都只在各自独立仿真的 t≈0 附近有一次 0→1。该坑在
字面意义上仍"不适用"（无可 merge 的对象）。这仍是一个值得让 orch 知道
的事实性缺口，不是本卡要处理的问题。

## 8. 较 v0.4.0 的变化（汇总）

- **场景数**：基线拓扑合并 17→20（+M4-RC01/AW01/OV01）；新增 cfgE
  （M4-FT01，v0.4.0 无此配置点）。
- **六类总体数字**：LINE 80.85→80.84（持平）、COND 71.20→71.66
  （+0.46pp）、TOGGLE 47.66→47.87（+0.21pp）、FSM 7.14→7.14（不变）、
  BRANCH 82.94→82.99（+0.05pp）、ASSERT 78.88→78.62（-0.26pp，M4 新增
  tb 代码令分母略增）、GROUP 89.58→90.89（+1.31pp，供参考）。
- **实质性改善（有具体信号/行号可核实）**：
  1. `axi_mux` 仲裁重试路径（`lock_aw_valid_q` 相关行）Line/Branch
     从 72.41/71.43 → 100.00/100.00（模块级并集口径，M4-AW01 之功）。
  2. `axi_xbar` 顶层 Toggle 29.63%→40.74%，`en_default_mst_port_i`
     首次测到 1→0 方向（M4-RC01 之功）。
- **未改善（如实报告，非预设"新场景一定补上"）**：
  1. `axi_atop_filter` FSM 两条状态机（w_state_q/r_state_q）逐状态/
     迁移弧与 v0.4.0 完全相同——M4 四条候选场景均未构造
     AtomicStore/AtomicCompare 编码，环境约束（REV-017）仍生效。
  2. `axi_xbar_unmuxed`/`axi_demux_simple` 的"AW 侧 valid-but-not-ready
     稳定性"类 assert 仍 0 real-succeeded——M4-RC01 背压点位于 default
     port 应答路径而非 slave 端口 AW 接受阶段，未覆盖该条件（testplan
     行已预告"非阻塞"）。
- **本轮新增测量粒度（非"变化"，是"首次测到"）**：`addr_decode_dync`/
  `axi_demux_simple`/`axi_multicut`/`axi_cut`/`spill_register` 五个
  子模块首次按 REV-016 例化闭包口径单独测量（BUG-0038 终判后的直接
  产出）；v0.4.0 报告对这五个模块均未单列。

## 9. 结论边界重申

本文件只是测量记录：**不判定 M4 是否达标、不判定哪个缺口该由哪张卡去
补**。§6 列出的"需 rev 书面豁免"项（`axi_atop_filter` 六类，对应
REV-017 条件 3）与"需补场景"项，均留给 orch 收到本报告后分诊；本卡
过程中未发现需要新登记的 taxonomy 异常（§0 记录的"裸 `make cov` 解到
错误 `COV_DIR`"是操作细节而非缺陷，未登记新 bug）。
