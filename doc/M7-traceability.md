# M7 闭环 B：spec↔checker 可追溯性矩阵

逐条 `doc/spec.md` 条款，标注由谁负责揪违反（verdict = 判决权的拥有者）。

**checker 分类**：
- **SB_xxx**：scoreboard (`tb/scoreboard_refmodel.sv`) 中的 `uvm_error` 判决点
- **SVA_xxx**：SVA 断言 (`tb/sva/*.sv`) 中的 `assert property`
- **cover**：非判决，仅见证到达（`cover property` / `uvm_info`）
- **env guard**：环境约束守卫（SB 里的 env-violation 标记，揪 TB_BUG 而非 DUT_BUG）
- **implicit**：由 checker 整体设计隐含覆盖（如 decode 函数实现了 §3 全部语义）
- **—**：无人认领

**scope 分类**（非 checker 类条款）：
- **N/A-def**：定义/参数/结构性条款，非运行时可测行为
- **N/A-meta**：对 checker 自身的设计约束（如"不得断言固定周期数"），由 checker 设计遵循而非运行时检查
- **N/A-scope**：超出本 DUT 验证范围

---

## §0 验证适配表

| 条款 | verdict | checker | testplan | 说明 |
|---|---|---|---|---|
| §0 #1 验证对象 | N/A-def | — | — | 定义 DUT 范围 |
| §0 #2 基线配置 | N/A-def | — | — | 定义参数钉定值 |
| §0 #3 配置矩阵 | N/A-def | — | M3-CF01..04, M4-FT01 | 定义多配置测试矩阵 |
| §0 #4 覆盖率口径 | N/A-meta | — | M6-BL01 | 定义覆盖率计量标准 |
| §0 #5 范围外 | N/A-scope | — | — | 排除清单 |
| §0 #6 spec 歧义处理 | N/A-meta | — | — | 流程规范 |

## §1 概述（隐含行为属性）

§1 无编号条款。scoreboard/testplan 以 "SPEC-1" 引用的是从本节推导的隐含行为
属性：**payload 透传**——除 ID 前缀（§5.1）外，地址/数据/控制信号不经修改
通过 crossbar。

| 条款 | verdict | checker | testplan |
|---|---|---|---|
| §1 (implicit) payload 透传 | **SB** | SB_ROUTE (addr/len/size/burst/atop), SB_WDATA (write data/strb), SB_RDATA (read data vs predict_beat_data), SB_RBEATS (read beat count), SB_WDATA_LEN (write beat count), SB_BRESP (B resp==OKAY) | M1-01, M2-TL01, M2-WO01, M3-CF01..04, M5-RN03, M6-CV02..04, M5-AT03 |

## §2 参数与端口

定义性条款（参数类型/语义/端口方向），无运行时可测行为断言。参数值正确性由
tb 例化时 struct 类型绑定保证，不需运行时 checker。

## §3 地址译码与路由

| 条款 | verdict | checker | testplan |
|---|---|---|---|
| §3.1 cl.1 全局共享地址表 | **SB** (implicit) | decode_mst_port 全端口共用同一函数 | M1-01, M2-CFG01 |
| §3.1 cl.2 至少一条 rule；多 rule 可同目标；无 rule 指向的 master 合法 | **SB** (implicit) | decode_mst_port 遍历 rule；M3-CF04 cfgD 含无 rule master | M2-CFG01, M3-CF04 |
| §3.1 cl.3 重叠区间高位 rule 胜出 | **SB** | decode_mst_port 先匹配高位 rule | M4-OV01 |
| §3.2 cl.1 匹配语义 addr≥start && addr<end | **SB** | decode_mst_port 实现此公式 | M1-01, M3-DE01, M4-OV01 |
| §3.2 cl.2 约束 start_addr≤end_addr | N/A-def | — | — | 参数合法性约束 |
| §3.2 cl.3 end_addr=='0 哨兵（延伸到地址空间末尾）| env guard | BUG-0075：env 约束使哨兵构造性不可达 | — | 闭环 C 复核 |
| §3.2 cl.4 禁止空区间 + env 约束 end_addr!='0 | env guard | env 约束在位（BUG-0075 option 2） | — |
| §3.3 cl.1 每端口独立 default master port | **SB** (implicit) | decode_mst_port 处理 en_default + default_idx | M2-CFG01, M3-DE02 |
| §3.3 cl.2 使能时未匹配走 default 而非 err_slv | **SB** | decode_mst_port 分流逻辑 | M2-CFG01, M3-DE02, M5-RN02 |
| §3.4 cl.1 地址表运行时可变（valid 期间不可变）| **SVA** | SVA: a_cfg_stable_during_ax (route_sva:47) | M2-CFG01, M3-CFG02 |
| §3.4 cl.2 default port enable/idx 同受 valid 期间不可变约束 | **SVA** | SVA: a_cfg_stable_during_ax 含 en_default/default_mst | M2-CFG01, M4-RC01 |

## §4 错误处理（decode error）

| 条款 | verdict | checker | testplan |
|---|---|---|---|
| §4 cl.1 每端口独立 err_slv | N/A-def | — | — | 结构性 |
| §4 cl.2 未匹配+default 关闭 → err_slv | **SB** | decode_mst_port 路由到 err_slv 路径 | M3-DE01, M3-DE02, M4-RC01 |
| §4 cl.3 err_slv 应答形态（DECERR + 正确 beat 数）| **SB** | SB_DECERR_BRESP (§4.3), SB_DECERR_RBEATS (§4.3) | M3-DE01, M4-EB01/02, M6-CV01/05 |
| §4 cl.4 ERR_RDATA = 64'hCA11AB1EBADCAB1E | **SB** | SB_DECERR_RDATA (§4.3/§4.4)，常量 pinned from spec | M3-DE01, M6-CV05 |
| §4 cl.5 err_slv 响应 ID/握手遵循 AXI4 | **SB** (implicit) | SB_RESP_ROUTE 覆盖 err_slv 响应路由 | M3-DE01 |
| §4 cl.6 err_slv 完成序由 §5.2.6 治理 | **SB** | SB_DECERR_ORDER (§5.2.6 cl.2a / §4) | M3-DE02, M3-OR04 |
| §4 cl.7 ATOP×decode-miss undefined; env 约束 | env guard | SB_ATOP_DECODE (§4.7 / BUG-0032) | M3-DE01, M5-AT03 |

## §5 ID 与保序

### §5.1 ID 前缀机制

| 条款 | verdict | checker | testplan |
|---|---|---|---|
| §5.1 cl.1 master 侧 ID 宽 = slave 侧 + clog2(NoSlvPorts) | N/A-def | — | — | 参数约束 |
| §5.1 cl.2 前缀 = slave port index 拼接到高位 | **SB** | build_exp_id() → SB_ROUTE 检查 ID | M1-01, M1-02 |
| §5.1 cl.3 可观测 ID = {port_idx, orig_id} | **SB** | SB_NOPEND (prefix lookup miss = misroute) | M1-01, M1-02 |
| §5.1 cl.4 不同 slave port 的 ID 空间互斥 | **SB** (implicit) | 前缀机制自然保证；SB_RESP_ROUTE 揪跨端口错送 | M1-02 |

### §5.2 同 ID 保序与 stall

| 条款 | verdict | checker | testplan |
|---|---|---|---|
| §5.2 cl.1 跨目标 stall → 完成序保序 | **SB + SVA** | SB_OR_REORDER (§5.2.1/§5.2.3) + SVA_OR_W_REORDER / SVA_OR_R_REORDER (stall_sva:450-461) | M2-OR01, M3-CFG02, M4-BP02/03 |
| §5.2 cl.2 低位比较（假冲突仅影响性能）| **SB** (implicit) | stall 分类用 AxiIdUsedSlvPorts 位比较 | M2-OR01 |
| §5.2 cl.3 设计原理（无重排缓冲）| N/A-meta | — | — | 设计原理说明 |
| §5.2 cl.4 同目标不 stall | **SB** | SB_OR_REORDER 排除同目标；cover c_sib_diff / 同目标 cover | M2-OR02, M3-OR05 |
| §5.2 cl.5 ATOP 跨方向 stall（正常行为）| cover | cg_atop_read_interaction (SB:311-317) | M3-AT02 |
| §5.2 cl.6 item 1 default port 事务同等保序 | **SB** | SB_OR_REORDER 不区分 default vs rule-matched | M3-DE02 |
| §5.2 cl.6 item 2a 同 full-ID 完成序=接受序 | **SB** | SB_DECERR_ORDER (§5.2.6 cl.2a / §4) | M3-OR04 |
| §5.2 cl.6 item 2b 桶级跨 err_slv 完成序 undefined | cover | cover c_bug25_errbucket (stall_sva:514-517) | M3-OR04 |
| §5.2 cl.6 item 3 显式排除要求 | **SB** (implicit) | err_order_q 显式按 full-ID 判断，不依赖默认值 | M3-OR04 |

### §5.3 UniqueIds

| 条款 | verdict | checker | testplan |
|---|---|---|---|
| §5.3 cl.1 前置条件（同 ID 同向须同目标或唯一）| env guard | SB_UNIQUEIDS (§5.3.1) | M3-CF03, M5-RN01 |
| §5.3 cl.2 硬件简化 | N/A-def | — | — | 设计意图 |
| §5.3 cl.3 前置条件违反时行为未定义 | env guard | SB_UNIQUEIDS 揪违反 | M3-CF03 |

### §5.4 事务数上限

| 条款 | verdict | checker | testplan |
|---|---|---|---|
| §5.4 cl.1 有效上限 = 2^idx_width(MaxMstTrans)−1 | **cover** (非判决) | txlimit_sva cover (达到/超过 ceiling)；SB cg_tx_limit | M2-TL01, M3-TL01 |
| §5.4 cl.2 MaxSlvTrans 非每 ID 上界 | N/A-meta | — | M2-TL02 | 负面断言（无上界） |
| §5.4 cl.3 达到上限时端口停止接受 | **cover** (非判决) | txlimit_sva cover | M2-TL01 |

> **注**：§5.4 cl.1/cl.3 的判决权因 BUG-0016/REV-007 从 assert 降级为 cover
> （SPEC_CHANGED：上游文档数字与 RTL 不符，有效上限是计数器满量程而非文档值）。
> 现状 = 只见证到达/超过，不判决违反。

### §5.5 W 通道次序

| 条款 | verdict | checker | testplan |
|---|---|---|---|
| §5.5 cl.1 W burst 按 AW 序发，不交织 | **SB** | SB_WORDER (§5.5.1) | M2-WO01, M4-AW01 |
| §5.5 cl.2 同源 W burst 与 AW 保持序；round-robin 合并 | **SB** (partial) | SB_WORDER + SVA_WLAST_LEN (beat count) | M2-WO01, M3-CF02 |
| §5.5 cl.3 B/R 响应 round-robin 合并 | — | **无人认领** | — |
| §5.5 cl.4 checker 不得断言特定 round-robin 序 | N/A-meta | — | — |

> **注**：§5.5 cl.3 标为无人认领，但 §5.5 cl.4 **明确禁止**断言特定
> round-robin 序。实际不可写 assert：只能验证"每个持续 valid 的请求最终被
> 授权"（liveness，由 soak 行的 watchdog 超时隐式覆盖）。归类为
> **设计性不可测**而非真正缺口。

## §6 ATOP 支持

| 条款 | verdict | checker | testplan |
|---|---|---|---|
| §6 cl.1 ATOP 定义（aw.atop != '0）| N/A-def | — | — |
| §6 cl.2 ATOPs=0 时 ATOP 未定义; env 约束 | env guard | SB_ATOP_DECODE (隐含); cfgD 硬约束 atop=='0 | M3-CF04, M5-RN02 |
| §6 cl.3 atomic load 需 B+R 双响应 | **SB** | SB_ATOP_DANGLING (§6.3) | M2-AT01, M5-AT03 |
| §6 cl.4 ATOP ID 须与所有在飞 ID 不同 | **SB + SVA** | SB_ATOP_OVERLAP (§6.4) + SVA_ATOP_ID_UNIQ (atop_sva:152) | M2-AT01, M5-AT03, M6-CV04 |
| §6 cl.5 ATOP 跨方向 stall（正常行为）| cover | cg_atop_read_interaction (§6.5 + §5.2.5) | M3-AT02 |
| §6 cl.6 atomicstore 只返 B 不返 R | **SB** | ATOP pairing: ATOP_R_RESP=0 路径跳过 R 追踪 | M5-AT03 |
| §6 cl.7 atomicswap 需 B+R | **SB** | SB_ATOP_DANGLING (§6.7) | M5-AT03 |
| §6 cl.8 atomiccompare 需 B+R | **SB** | SB_ATOP_DANGLING (§6.8) | M5-AT03 |

## §7 Latency 模式

| 条款 | verdict | checker | testplan |
|---|---|---|---|
| §7.1 cl.1 spill register 位置语义 | N/A-def | — | — | 结构/参数定义 |
| §7.1 cl.2 spill register 切全组合路径 | N/A-def | — | — | 时序属性 |
| §7.1 cl.3 内部无 pipeline（仅 PipelineStages）| N/A-def | — | — | 结构属性 |
| §7.3 cl.1 推荐 CUT_ALL_AX + FallThrough=0 | N/A-meta | — | — | 推荐值 |
| §7.3 cl.2 双向互联须两侧均切 | N/A-scope | — | — | 单 xbar DUT 超范围 |
| §7.4 cl.1 AXI 延迟不敏感协议 | N/A-meta | — | — |
| §7.4 cl.2 spill/multicut 不改功能响应 | **SB** (implicit) | 多 LatencyMode 配置点共用同一 checker 无差别 PASS | M3-CF01 (NO_LAT), M3-CF02 (CUT_ALL_PORTS), M4-FT01 (FallThrough) |
| §7.4 cl.3 不得断言固定周期数 | N/A-meta | — | — |
| §7.4 cl.4 基线延迟不影响 M1 checker | N/A-meta | — | — |
| §7.4 cl.5 不得以接受拍作判决锚点 | N/A-meta | — | — |

## §8 Connectivity 稀疏连接

| 条款 | verdict | checker | testplan |
|---|---|---|---|
| §8 cl.1 Connectivity 矩阵定义（默认全连接）| N/A-def | — | — |
| §8 cl.2 稀疏时译码到非连通端口行为未定义 | N/A-def | — | — |
| §8 cl.3 env 约束：不译码到非连通端口 | env guard | cfgD 地址表+约束构造性排除 | M3-CF04, M5-RN02 |
| §8 cl.4 故意违反 §8.3 为开放项 | N/A-scope | — | — | 上游待确认 |

---

## 无人认领条款汇总

以下条款为有运行时可测行为但当前无硬 verdict（assert/uvm_error）的条款：

| 条款 | 现状 | 评估 |
|---|---|---|
| §5.4 cl.1 有效在飞上限 | cover 非判决（BUG-0016 降级）| **已知限制**：上游文档数字与 RTL 不符，assert 被废除只留 cover。如需恢复判决须先补 spec 修订。新仓库可考虑按 RTL 有效上限（2^idx_width−1）重写 assert |
| §5.4 cl.3 达到上限时端口停止接受 | cover 非判决 | 同上 |
| §5.5 cl.3 B/R 响应 round-robin 合并 | 无 checker | **设计性不可测**：§5.5 cl.4 明确禁止断言 round-robin 序。唯一可测属性是 liveness（无饿死），由 soak 行 watchdog 隐式覆盖。不构成真实缺口 |
| §5.2 cl.5 / §6 cl.5 ATOP 跨方向 stall | 仅 cover 见证 | **预期行为**：spec 明确声明此为正常设计行为而非缺陷（§6.5）。cover 证明场景确实到达，不需判决 |

**结论**：无"真实无人认领且可写 assert 却未写"的条款。三类弱覆盖均有充分理由：
(1) §5.4 判决因 spec/RTL 不符被主动降级；(2) §5.5 cl.3 被 spec 自身禁止断言；
(3) §6.5 是 spec 声明的正常行为。

---

## 附：checker 判决点 ↔ spec 条款交叉索引

| SB/SVA 判决点 | 主要 spec 条款 | 文件:行 |
|---|---|---|
| SB_ROUTE | §3.1/§3.2/§1/§6.1 | scoreboard_refmodel.sv:746 |
| SB_WDATA | §1 | scoreboard_refmodel.sv:763 |
| SB_WDATA_LEN | §1 | scoreboard_refmodel.sv:755 |
| SB_RDATA | §1 | scoreboard_refmodel.sv:1082 |
| SB_RBEATS | §1 | scoreboard_refmodel.sv:1071 |
| SB_BRESP | §1 (implicit) | scoreboard_refmodel.sv:1058 |
| SB_NOPEND | §5.1.1 | scoreboard_refmodel.sv:734 |
| SB_RESP_ROUTE | §5.1.2/§5.1.3 | scoreboard_refmodel.sv:888 |
| SB_DANGLING | §5.1.1/§3.1 | scoreboard_refmodel.sv:1129 |
| SB_RESP_DANGLING | §5.1.2/§5.1.3 | scoreboard_refmodel.sv:1141 |
| SB_OR_REORDER | §5.2.1/§5.2.3 | scoreboard_refmodel.sv:1000 |
| SB_OR_DANGLING | §5.2.1/§5.2.3 | scoreboard_refmodel.sv:1164 |
| SB_DECERR_ORDER | §5.2.6 cl.2a / §4 | scoreboard_refmodel.sv:916 |
| SB_DECERR_BRESP | §4.3 | scoreboard_refmodel.sv:1029 |
| SB_DECERR_RBEATS | §4.3 | scoreboard_refmodel.sv:1037 |
| SB_DECERR_RDATA | §4.3/§4.4 | scoreboard_refmodel.sv:1045 |
| SB_WORDER | §5.5.1 | scoreboard_refmodel.sv:832 |
| SB_WORDER_DANGLING | §5.5.1 | scoreboard_refmodel.sv:1180 |
| SB_ATOP_OVERLAP | §6.4 | scoreboard_refmodel.sv:563 |
| SB_ATOP_DANGLING | §6.3/§6.7/§6.8 | scoreboard_refmodel.sv:1151 |
| SB_ATOP_DECODE | §4.7 (env) | scoreboard_refmodel.sv:491 |
| SB_UNIQUEIDS | §5.3.1 (env) | scoreboard_refmodel.sv:633 |
| SVA_AW/W/B/AR/R_STABLE | §1 (AXI4 handshake) | sva/axi_chan_sva.sv:166-185 |
| SVA_RST_IDLE | §2.3/§1 | sva/axi_chan_sva.sv:191-198 |
| SVA_WLAST_LEN (a/b) | §1 / §4.3 | sva/axi_chan_sva.sv:262-295 |
| SVA_RLAST_LEN | §1 / §4.3 | sva/axi_chan_sva.sv:314-318 |
| SVA_ATOP_ID_UNIQ | §6.4 | sva/axi_xbar_atop_sva.sv:152 |
| a_cfg_stable_during_ax | §3.4 | sva/axi_xbar_route_sva.sv:47 |
| SVA_OR_W/R_REORDER | §5.2.1/§5.2.3 | sva/axi_xbar_stall_sva.sv:450-461 |
