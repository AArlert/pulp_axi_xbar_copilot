# M4 逐位 Toggle 分解——Kind-B 豁免登记前置证据

首行重放（覆盖率数据库刷新，供后续任何人重新核对本报告引用的 urg 数字）：

```
cd sim && make clean && make regress COV=1   # 26/26 PASS
make cov TEST=m1_01_smoke_test                # 基线拓扑合并（out/urgReport_baseline）
make cov TEST=upstream_sanity                 # M0（out/urgReport_m0）
make cov TEST=m3_cf01_cfga_test               # cfgA（out/cfgA/urgReport）
make cov TEST=m3_cf02_cfgb_test               # cfgB
make cov TEST=m3_cf03_cfgc_test               # cfgC
make cov TEST=m3_cf04_cfgd_test               # cfgD
make cov TEST=m4_ft01_cfge_test               # cfgE
```

**性质**：本文件是 `doc/review/REV-024.md` §5「Kind-B 豁免正式登记前必须先有逐位
toggle 分解」这一前置条件的兑现证据，由多 agent 工作流产出（覆盖率数据刷新 →
4 模块并行逐位分解 → 每条"载荷候选"3 独立怀疑者对抗性核实 → 综合报告），
经独立 rev 复核（`doc/review/REV-025.md`）后由 orch 应用。**本文件只是测量与
分解记录，不判定哪条缺口该走哪条处置路径——最终裁决见 REV-025**。

## 0. 覆盖率数据完整性核实

orch 独立复验：本次刷新前 `sim/out` 是一个非 instrumented 空壳（上次编译无
`-cm` 标志，`out/cov.vdb` 不存在——这是 KILL-0004/M4 签核卡两次不带 `COV=1`
的 `make regress` 的预期后果，非新缺陷）。干净重跑 `make clean && make regress
COV=1` 后 26/26 PASS，**基线聚合数字与 v0.4.9 逐位一致**（LINE 80.84 /
COND 71.66 / TOGGLE 47.87 / FSM 7.14 / BRANCH 82.99 / ASSERT 78.62 /
GROUP 90.89，与 `doc/evidence/v0.4.9/M4-coverage-baseline.md` 表格逐位核对
一致），证明本次数据库确系真实 instrumented、非空壳。7 组 `make cov` 均 0
mismatch/CMR-VCINF/UCAPI-INSTANCEMISMATCH（BUG-0037 guard）。

**报告路径提示**（供后续复核者）：`make cov TEST=m1_01_smoke_test`（基线）与
`make cov TEST=upstream_sanity`（M0）原生都写 `out/urgReport`（因
upstream_sanity 只重定向 `COV_DIR`、`OUT` 仍是 `out`，BUG-0037/FB-30 已知
设计），为共存已分别移至 `out/urgReport_baseline`/`out/urgReport_m0`——
**不要预期存在裸的 `out/urgReport`**。cfgD 会报
`Warning-[UCAPI-SNF] 'Fsm' coverage shape is not there`，这是 `ATOPs=1'b0`
下不例化 `axi_atop_filter` 的结构性事实（与 v0.4.9 §3 一致），非 BUG-0037
类合并告警。mod*.html 编号**逐组不同**（基线 134 个、M0 132、cfgA 49、
cfgB 63、cfgC 75、cfgD 71、cfgE 134），不得假设跨组同编号对应同模块。

## 1. 综合分解报告

来源：4 个独立模块分解 agent（axi_mux / axi_xbar / axi_demux_simple /
axi_err_slv）+ 对抗性核实（每条载荷候选 3 独立怀疑者投票）。判据基线：
`doc/review/REV-024.md` §2.1（Kind-B 双判据 + 反向排除）、
`doc/coverage-waivers.md`（现有格式）。

### 头条结论

- **对抗性投票后存活的 Kind-B 载荷候选 = 0 条**。
- 唯一被分解 agent 明确标为 `payload_kind_b_candidate` 的信号——
  **axi_mux `mst_resp_i.r.data[63:0]`**——被 **3/3 票反驳**。
- **M4 阶段合法 Kind-B 豁免集 = 空集**。`doc/coverage-waivers.md` 的
  Kind-B 模板行维持为模板、不实例化任何具体信号。
- 新增可落的 **Kind-A** 候选：`axi_err_slv` 恒定错误应答数据/应答码/
  tie-off（结构常量，见 REV-025 转正登记）；`axi_mux`/`axi_demux_simple`
  `size[2]` 总线宽度上限位（结构候选，待跨配置确认，REV-025 暂缓）。

### 最终分类总表

Kind 列取值：**B候选**（存活载荷候选，可进 Kind-B）/ **补场景**（需补定向
场景，清单 B）/ **A候选**（结构性不可达）/ **无缺口**（已覆盖，非缺口）。

| 模块 | 信号 / 位段 | 分解 agent 原分类 | 对抗票 | 最终 Kind | 依据 |
|---|---|---|---|---|---|
| axi_mux | `mst_resp_i.r.data[63:0]`（散布 ~30/64 位未双向翻） | payload_kind_b_candidate | **3/3 反驳** | **补场景** | 判据(1)成立(纯载荷)但判据(2)不成立：3 位怀疑者独立亲读 RTL+TB，证 toggle 关闭只需 all-0/all-1 两饱和值定向读；且 TB `predict_beat_data`=`{beat_a,beat_a}`，r.data 实为地址镜像→地址多样性缺口，属 REV-024 §2.1 反向排除 |
| axi_mux | `mst_req_o.w.data[63:0]` | control_needs_scenario（COVERED） | — | **无缺口** | 模块 union + inst mux[0]/mux[7] 全 Yes/Yes/Yes；直接反驳 REV-024 §5 把 W.data 打包进 Kind-B 的假设 |
| axi_mux | aw/ar/r/b `.id[7:0]`（[7:5]路由前缀+[4:0]原ID） | control_needs_scenario（COVERED） | — | **无缺口** | 两段均 Yes/Yes/Yes，ID-trap 在本模块 moot |
| axi_mux | `aw/ar.addr[31:0]` 部分位 | control_needs_scenario | — | **补场景** | 地址=语义路由位，§2.1 反向排除；补地址/rule 多样性 |
| axi_mux | `aw/ar.len[7:3]` | control_needs_scenario | — | **补场景** | 窄突发长度控制位；补长突发 |
| axi_mux | `aw/ar.{cache,prot,qos,region,lock}` | control_needs_scenario | — | **补场景** | 窄属性控制位；补属性多样性 |
| axi_mux | `aw/ar.burst[1]` | control_needs_scenario | — | **补场景** | WRAP 编码；补 WRAP 突发 |
| axi_mux | `aw/ar.size[2]` | control_needs_scenario（倾向 Kind-A） | — | **A候选（暂缓）** | 64-bit 总线合法 AxSIZE≤3，size[2] 结构恒 0；REV-025 V4：须先确认全部受验配置数据总线宽度 ≤64 才能转正 |
| axi_mux | `aw.atop[5:0]`（[4:0]恒定，[5]仅0→1） | control_needs_scenario | — | **补场景** | 窄 ATOP 控制；受 env 约束（挂 CW-001/BUG-0032 ATOP 债） |
| axi_mux | `aw/ar/w/r/b.user`（USER_W=1） | ambiguous | — | **补场景** | 1-bit sideband，非宽载荷（失判据1"宽"）；驱动 user=1 即翻 |
| axi_mux | `b_ready / w_ready / ar_ready` | control_needs_scenario | — | **补场景** | 握手/背压，§2.1 反向排除 |
| axi_mux | `test_i` | control_needs_scenario | — | **A候选** | scan 出验证范围（=CW-002） |
| axi_mux | `rst_ni`（仅0→1） | control_needs_scenario | — | **补场景/范围** | 运行中复位定向或范围裁决，随机不助 |
| axi_xbar | 顶模块 54 toggle 位全景（clk/rst/test/en_default/default_mst_port） | control_needs_scenario | — | **补场景（部分A/无缺口）** | **关键**：顶边界 0 载荷位，54 位全为窄控制/配置；无宽载荷残余（agent2 逐位核对，见附录） |
| axi_xbar | 宽 struct 端口（req/resp/addr_map，含 64-bit W/R.data） | ambiguous | — | **无缺口（本边界）** | 顶模块 toggle 未计入这些 struct 端口（0/54 位）；载荷 toggle 在子模块度量（mod19/mod12/mod32） |
| axi_xbar | `default_mst_port_i[5:0][2:0]`（29/54 未覆盖方向） | control_needs_scenario | — | **补场景** | 窄默认端口索引；双向驱动不同索引值 |
| axi_xbar | `rst_ni`（1→0未覆盖） | control_needs_scenario | — | **补场景/范围** | 同 mux rst_ni |
| axi_xbar | `test_i` | control_needs_scenario | — | **A候选** | =CW-002 |
| axi_xbar | `en_default_mst_port_i[5:0]` | control_needs_scenario（全覆盖） | — | **无缺口** | 12/12 方向全 Yes |
| axi_demux_simple | `slv_req_i.w.data[63:0]`+id[4:0]+select[3:0] | ambiguous（COVERED） | — | **无缺口** | w.data 128/128 bin 100%；id/select 100%；写载荷零债 |
| axi_demux_simple | `slv_resp_o.r.data[63:0]`（8 位/16 bin 未覆盖，87.5%） | ambiguous（borderline） | 未投票 | **补场景** | 未进对抗投票（不满足 payload_kind_b_candidate 分类门槛，故未入投票池）；同套定向下 w.data 已达 100%，同 axi_mux r.data 反驳逻辑（定向饱和读即闭）→ 归补场景 |
| axi_demux_simple | aw/ar 属性字段（region/qos/prot/cache/lock/burst[1]/size[2]/len[7:3]/user/atop） | control_needs_scenario | — | **补场景**（size[2]→A候选暂缓） | 主导缺口 119/225 bin；属性控制位，补场景 |
| axi_demux_simple | `aw/ar.addr[31:0]` 部分 | control_needs_scenario | — | **补场景** | 67/225 bin，地址语义位，补 rule 多样性 |
| axi_demux_simple | `slv_req_i.w.strb[7:0]` | control_needs_scenario | — | **补场景** | 字节使能控制，补部分写/稀疏 strobe |
| axi_demux_simple | `rst_ni` / `test_i` | control_needs_scenario | — | **补场景/范围** + **A候选(test_i)** | 同上 |
| axi_demux_simple | `r_ready/b_ready/*.user` | control_needs_scenario | — | **补场景** | 握手+1bit sideband |
| axi_demux_simple | 内部控制寄存器（lock_aw/ar FSM、id_cnt_full、w_open[3:2]） | control_needs_scenario | — | **补场景** | valid-but-not-ready lock FSM + ID 计数饱和；补 slave 侧背压+MaxTrans 饱和 |
| axi_err_slv | `slv_resp_o.r.data[63:0]` | ambiguous | — | **A候选（已转正，REV-025）** | `err_resp.r.data=RespData`(64'hCA11AB1EBADCAB1E 编译期常量)，任何激励不可翻 |
| axi_err_slv | `r.resp[1:0]` / `b.resp[1:0]` | ambiguous | — | **A候选（已转正，REV-025）** | 恒 `RESP_DECERR`=2'b11，结构常量 |
| axi_err_slv | `r.user/b.user` + 入侧 user/strb | ambiguous | — | **A候选（出侧，已转正）**/**补场景（入侧）** | 出侧 `err_resp='0` tie-off；入侧未被消费 |
| axi_err_slv | `slv_req_i.w.data[63:0]` | control_needs_scenario（COVERED） | — | **无缺口** | 入侧唯一宽载荷全翻，反驳 REV-024 §2.2 row8 入侧 Kind-B 推测 |
| axi_err_slv | `id[4:0]`（入侧全翻/出侧高位残） | control_needs_scenario | — | **补场景** | slave 侧无路由前缀（BUG-0033），窄 5-bit，补更多 ID 值 |
| axi_err_slv | aw/ar 属性+len+atop / addr | control_needs_scenario | — | **补场景**（size[2]→A候选暂缓） | 属性控制+地址语义，补场景 |
| axi_err_slv | `ar_ready/aw_ready` | control_needs_scenario | — | **补场景** | fifo 背压，补 MaxTrans miss 突发 |
| axi_err_slv | Cond LINE 112 `!w_fifo_empty && !b_fifo_full` | control_needs_scenario | — | **补场景** | B 通道背压条件（唯一未覆盖 Cond 项），补 B-ready 拉低 |
| axi_err_slv | `rst_ni` / `test_i` | control_needs_scenario | — | **补场景/范围** + **A候选(test_i)** | 同上 |

### 清单 B 具体化——需补定向场景，供后续 DV 定向覆盖卡（方向性构造思路，不写实现）

**A. 载荷/数据类（由载荷候选降级，定向饱和即闭）**
- **axi_mux `mst_resp_i.r.data[63:0]`**（原候选，3/3 反驳，REV-025 定向构造 =
  all-0(64'h0)→all-1(64'hFFFF_FFFF_FFFF_FFFF) 饱和读序列即闭全部 64 位双向；
  因 `predict_beat_data={beat_a,beat_a}`，亦可等价驱动多样化地址）。
- **axi_demux_simple `slv_resp_o.r.data[63:0]`**（8 位残 16 bin，borderline）：
  同上，扩 slave 响应数据多样性/饱和读即可闭。

**B. 地址/rule 多样性类**
- axi_mux/demux/err_slv `aw/ar.addr[31:0]` 未翻位：驱动覆盖各 rule 区域的
  多样地址 + M4 内重配 rule 表边界；err_slv 侧额外覆盖多样 miss 地址。

**C. AXI 属性/控制字段类**（demux 侧为主导缺口 119/225 bin）
- `aw/ar.{cache,prot,qos,region,lock}`、`burst[1]`(WRAP)、`len[7:3]`
  (长突发)、`w.strb[7:0]`(部分写/稀疏 strobe)、`user`(驱动 user=1)：定向
  轮换属性取值。
- `aw.atop[5:0]`：更多 ATOP 编码——**注意受 env 约束**，与既有
  CW-001/BUG-0032 ATOP 应答许可债耦合，构造前先查该债状态。

**D. 握手/背压类**
- axi_mux `b_ready/w_ready/ar_ready`、demux `r_ready/b_ready`、err_slv
  `ar_ready/aw_ready` 及 **Cond LINE 112**（B 通道 b_fifo 满）：定向背压
  场景（拉低下游 ready / 背靠背写超过 fifo 深度 / MaxTrans miss 突发填满
  fifo）。M4-AW01 已是此模式，可复用。

**E. ID 与内部 FSM 类**
- err_slv 出侧 `id[4:0]` 高位、demux 内部 `lock_aw/ar FSM`、
  `aw/ar_id_cnt_full`、`w_open[3:2]`：驱动更多互异 5-bit ID + slave 侧
  AW/AR 保持 valid-but-not-ready + ID 计数饱和场景。

**F. 配置/复位类**
- axi_xbar `default_mst_port_i[5:0][2:0]`：对 6 个 slave 端口双向驱动不同
  默认端口索引值（运行时切换）。
- `rst_ni`（mux/xbar/demux/err_slv 均 1→0 未覆盖）：定向运行中复位场景；
  **或**裁决为"验证范围不含运行中复位"→ 转 Kind-A 范围豁免（二选一，
  需 rev 裁）。

### Kind-A 结构性候选（供独立 rev 卡登记）

- **A-1/A-2/A-3**（`axi_err_slv` 恒定 `r.data`/`resp`/`user` tie-off）：
  **REV-025 已亲验转正**，见 `doc/coverage-waivers.md` CW-003/CW-004/CW-005。
- **A-4**（`test_i` scan-enable，四模块一致）：=既有 CW-002，勿重复建档。
- **A-5**（`aw/ar.size[2]` 总线宽度上限位，mux+demux+err_slv 一致）：
  **REV-025 暂缓转正**——64-bit 基线下结构成立，但须先确认全部受验配置
  （cfgA-E）数据总线宽度均 ≤64 才能记为永久 Kind-A，否则更宽配置下
  `size[2]` 可达，不得记 Kind-A。

### 相对 REV-024 §2 原判断的差异

REV-024 §2.2/§5 的原判断：**仅 axi_mux Toggle 的 W/R.data 子集"有明确结构
依据"可为 Kind-B；其它模块（xbar/demux/err_slv）的宽载荷可能性"未量化"，
不据"等"字放行。** 本次逐位分解：

1. **证实（结构事实层面）**：axi_xbar 顶边界 0 载荷 toggle 位（全 54 位
   窄控制），载荷 toggle 只在子模块度量。REV-024"载荷在子模块度量"的
   结构判断成立。
2. **推翻（分类层面，本次最重要）**：REV-024 唯一点名"有明确结构依据"
   的 Kind-B 候选——**axi_mux W/R.data 子集**——经逐位分解**不成立**：
   W.data 已 100% 覆盖（非缺口，REV-024 把它与 R.data 打包属过度包含）；
   R.data 经 3/3 对抗票反驳（toggle 逐位线性、两饱和向量即闭；且实为地址
   镜像，属地址多样性类反向排除）。
3. **补充（量化 REV-024 未量化项）**：对 xbar/demux/err_slv 的宽载荷
   "未量化"空白给出逐位结论——**均无残余 Kind-B 载荷债**：demux `r.data`
   87.5% 已覆盖（补场景）；err_slv 入侧 w.data 全翻（非缺口），出侧
   r.data/resp 为恒定常量（Kind-A，非 Kind-B）。

**综合差异一句话**：REV-024 保守地"授权 Kind-B 路径但不预授任何豁免、待
逐位分解"。逐位分解的结论比 REV-024 更收窄——**M4 阶段合法 Kind-B 豁免集
为空集**；REV-024 悬置的"axi_mux W/R.data 子集"一项被拆为"W.data 非缺口 +
R.data 定向可达补场景"，另于 err_slv 侧新识别出一批 Kind-A 恒定输出候选。
这不与 REV-024 冲突，而是兑现其 §5 前置条件后得出的、方向一致但更严格的
量化结果。

## 2. 独立仲裁裁决

见 `doc/review/REV-025.md`——独立 rev 实例亲读 RTL/TB（`axi_err_slv.sv`
L23-27/145/191-197、`axi_xbar_unmuxed.sv` L195-211、`xbar_types_pkg.sv`
L374-385、`mstport_agent.sv` L244-253、`seq_lib.sv` L32-35）核实本报告
核心结论，Conditional pass，三条应用条件（Kind-A 转正 A-1/A-2/A-3、A-5
暂缓、record 措辞订正）。

## 3. 附录——4 模块逐位分解原始产出（各自独立、互不知晓对方结果）

<details>
<summary>axi_xbar（顶层）</summary>

见工作流原始 JSON 产出，逐信号：`(module-level Toggle scope)`（54 位全景，
证顶层 0 载荷位）、`slv_ports_req_i` 等宽 struct 端口（0 位贡献，载荷转移
子模块度量）、`default_mst_port_i[5:0][2:0]`（18 位，29/54 未覆盖方向主因）、
`rst_ni`、`test_i`、`en_default_mst_port_i[5:0]`（全覆盖）。逐条 rtl_citation
均锚 `vendor/axi/src/axi_xbar.sv` 具体行号，urg_citation 锚
`sim/out/urgReport_baseline/mod39.html` 具体行区间。完整字段见工作流
journal（`agentId` 对应本会话 wf_0b15aff9-ff3 的 decompose:axi_xbar 结果）。

</details>

<details>
<summary>axi_mux</summary>

12 条 findings，含唯一载荷候选 `mst_resp_i.r.data[63:0]`（后被反驳）、
`mst_req_o.w.data[63:0]`（COVERED 反证）、id 前缀 split 核实（moot）、
addr/len/属性/burst/size/atop/user/握手/rst/test 逐条。锚
`vendor/axi/src/axi_mux.sv` 具体行号 + `sim/out/urgReport_baseline/
mod19.html` Toggle Port Details（模块并集 + per-instance mux[0]/mux[7]）。

</details>

<details>
<summary>axi_demux_simple</summary>

9 条 findings，含 `slv_req_i.w.data[63:0]`+id+select（全覆盖反证）、
`slv_resp_o.r.data[63:0]`（87.5%，borderline→补场景）、属性字段（主导
缺口 119/225 bin）、addr（67/225 bin）、w.strb、rst/test、握手+user、
内部控制寄存器（lock FSM/id_cnt_full/w_open 高位）。锚
`vendor/axi/src/axi_demux_simple.sv` 具体行号 + `sim/out/urgReport_baseline/
mod12.html` 具体行区间。

</details>

<details>
<summary>axi_err_slv</summary>

9 条 findings，含三条 Kind-A 恒定输出（r.data/resp/user tie-off）、入侧
w.data 全覆盖反证、id 前缀陷阱核实（本例化点在 slave 侧、无前缀）、属性+
addr+握手+Cond L112+rst/test。锚 `vendor/axi/src/axi_err_slv.sv` 具体行号 +
`sim/out/urgReport_baseline/mod32.html` 具体行区间。

</details>

完整逐条原始 JSON（含每条 finding 的 `toggle_numbers`/`rtl_citation`/
`urg_citation` 精确字段）保留在本次工作流运行记录（run id
`wf_0b15aff9-ff3`）的 journal 中；本文件正文表格已完整转录其结论与关键
引用，供本仓库长期查阅。
