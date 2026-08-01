# Feature matrix

feature → deliverable → testplan scenarios. Delivery/verification are computed live by the scripts, never stored. Every feature maps to ≥1 existing scenario id (ghost references fail docs-check).

| id | milestone | feature | module | scenes |
| --- | --- | --- | --- | --- |
| F-M0-01 | M0 | 仿真基建：vendored DUT + 依赖库在 VCS-2018 下编译/弹性/运行 | (infra) | M0-01 |
| F-M1-01 | M1 | UVM env 骨架：tb_top 单 axi_xbar + 6 slave/8 master 接口 + master/slave agent + env 编译弹起并跑通 baseline smoke | tb_top+uvm_env | M1-01 |
| F-M1-02 | M1 | 地址路由参考模型记分板：地址译码（SPEC-3.1/3.2）+ 目标 master 端口 idx 路由 + 数据完整性（SPEC-1）判决 | scoreboard_refmodel | M1-01 |
| F-M1-03 | M1 | ID 前缀响应路由参考模型：master 端口侧 ID 前缀（SPEC-5.1）与响应回送源 slave 端口正确性 | scoreboard_refmodel | M1-02 |
| F-M1-04 | M1 | 协议/时序 SVA bind 挂接：tb/sva 经 bind 挂到 DUT 每 slave/master 端口，smoke 期间 AXI4 协议基线 passive 零告警 | sva_bind | M1-01, M1-02 |
| F-M2-01 | M2 | 运行时地址表/default port 重配置：仅在全部 slave 端口 AW/AR 均空闲的窗口更改，随后事务按新表路由（SPEC-3.1/3.3/3.4） | uvm_env+scoreboard_refmodel | M2-CFG01 |
| F-M2-02 | M2 | 同 ID（低 `AxiIdUsedSlvPorts` 位）同向跨 master 端口保序 stall：第二笔在第一笔完成前不被接受（SPEC-5.2.1/5.2.2） | uvm_env+scoreboard_refmodel | M2-OR01, M2-OR03 |
| F-M2-03 | M2 | 同 ID 同向同目标 master 端口 / 同 ID 异向：不受 §5.2 stall 约束（SPEC-5.2.4） | uvm_env+scoreboard_refmodel | M2-OR02, M2-OR03 |
| F-M2-04 | M2 | 事务数上限：每 slave 端口（MaxMstTrans）、每 master 端口每 ID（MaxSlvTrans）在飞事务达上限即暂停接受（SPEC-5.4） | uvm_env+scoreboard_refmodel | M2-TL01, M2-TL02 |
| F-M2-05 | M2 | W 通道次序：≥2 个 slave 端口并发写同一 master 端口时，W burst 按 AW 接受序、不与他源交织（SPEC-5.5.1/5.5.2） | uvm_env+scoreboard_refmodel | M2-WO01 |
| F-M2-06 | M2 | ATOP 原子读：B 与 R 两通道成对返回 + 环境侧 ID 唯一性约束（SPEC-6.3/6.4） | uvm_env+scoreboard_refmodel | M2-AT01 |
| F-M2-07 | M2 | 协议/时序 SVA M2 激活集（design-prompt sva_bind.md C3.1-C3.5）：配置稳定性(C3.1) / 保序 stall(C3.2) / W 次序(C3.3，cover-only、不新增独立断言) / 事务上限(C3.4) / ATOP 成对+ID 唯一(C3.5)，各配一条非判决性 cover property 佐证非空转 | sva_bind | M2-CFG01, M2-OR01, M2-OR02, M2-TL01, M2-TL02, M2-WO01, M2-AT01, M2-OR03 |
| F-M2-08 | M2 | functional + assert 功能覆盖采集基建：六类覆盖口径（SPEC-0 行4）中 functional（covergroup）与 assert（cover property）两维度在 M2 场景落地 | functional_coverage | M2-CFG01, M2-OR01, M2-OR02, M2-TL01, M2-TL02, M2-WO01, M2-AT01 |
| F-M3-01 | M3 | `MaxMstTrans` 跨（低位 ID 桶×方向）聚合在飞规模合法性确认：≥2 个不同 ID 桶同时压满、单 slave 端口合计在飞数远超扁平上限仍被合法接受，将 demux.md 分桶口径由文档信任升级为波形经验确认（SPEC-5.4.1，BUG-0010 裁决守卫） | uvm_env+scoreboard_refmodel | M3-TL01 |
| F-M3-02 | M3 | decode error slave 应答参考模型判据：`RESP_DECERR` + 读出齐 `AxLEN+1` beats 且末拍 `RLAST` + 写单拍 B + 读数据 `32'hBADCAB1E` 零扩展（SPEC-4.1/4.2/4.3/4.4/4.5） | scoreboard_refmodel | M3-DE01, M3-CF01, M3-CF02 |
| F-M3-03 | M3 | default master port 路由：逐 slave 端口独立使能，未命中地址改走 default 而非 err_slv，与命中路由/ID 前缀/响应回送共存（SPEC-3.3/4.2/5.1） | uvm_env+scoreboard_refmodel | M3-DE02, M3-CF04 |
| F-M3-04 | M3 | 译码未命中事务的保序地位落地（SPEC-5.2.6）：default port 半边纳入跟踪表、完整 ID 维度纳入完成序判决、低位桶维度显式引条款排除并配非判决 cover（BUG-0025 三层守卫） | sva_bind+scoreboard_refmodel | M3-DE02, M3-OR04 |
| F-M3-05 | M3 | SVA 判决路径的运行时配置可见性：地址表/`en_default`/`default_mst_port` 取运行时活值而非编译期常量，与 scoreboard 共用同一份活值译码（SPEC-3.4/3.1，BUG-0031 守卫） | sva_bind | M3-CFG02 |
| F-M3-06 | M3 | stall SVA 判决范围声明与范围外解除武装：范围 = 每完整 ID 至多一笔在飞，N≥2 由 scoreboard 每事务队列判据承担；范围外不得产出乱序告警（SPEC-5.2.4/5.2.3，BUG-0024 路线 (b) 守卫） | sva_bind | M3-OR05 |
| F-M3-07 | M3 | AW/AR 接受时刻观测事件流：覆盖采样相位与判决输入管线对齐，使 §5.2/§5.5 相关 cross bin 在**各自对口场景**内命中（BUG-0018 守卫；不新增场景，验收=重跑对口 M2 场景） | uvm_env+functional_coverage | M2-OR01, M2-OR02, M2-WO01 |
| F-M3-08 | M3 | 多配置构建与回归基建：配置点由 TEST 名唯一选定、每配置独立构建产物、运行日志自报生效的全部 `Cfg` 字段与模块参数，基线配置逐位不变（M0-M2 既有证据保持可复现） | tb_top | M3-CF01, M3-CF02, M3-CF03, M3-CF04 |
| F-M3-09 | M3 | 配置矩阵维度覆盖（SPEC-0 行 3）：拓扑 1×N / N×1 / 4×4、`LatencyMode` NO_LATENCY / CUT_ALL_PORTS（CUT_ALL_AX 由基线承担）、`UniqueIds=1`、`ATOPs=0`、稀疏 `Connectivity`——每个维度取值至少出现在一个配置点 | tb_top+uvm_env | M3-CF01, M3-CF02, M3-CF03, M3-CF04 |
| F-M3-10 | M3 | ATOP 原子读的跨方向假冲突 stall：条款化后的定向守卫——该交互只影响是否被 stall、不影响功能正确性，保序判据对它不报违反是有意的范围边界（SPEC-6.5/5.2.5，BUG-0012 守卫） | uvm_env+functional_coverage | M3-AT02 |
| F-M4-01 | M4 | default master port 运行时动态关闭与降位：已使能的 default 端口在 AW/AR 空闲窗口关闭或改索引，原经该端口路由的未命中事务改走 err_slv，前后两批事务按生效时刻配置正确路由（SPEC-3.4.2、BUG-0025/BUG-0031 守卫） | uvm_env+scoreboard_refmodel | M4-RC01 |
| F-M4-02 | M4 | AW 通道选定后下游背压的锁定-重试机制：mux 入侧背压下路由决策锁定、下拍重试不改路由，背压下路由/数据/W burst 同序无交织正确，无跨源仲裁序断言（SPEC-5.5.1/5.5.4、REV-006 守卫） | uvm_env+scoreboard_refmodel | M4-AW01 |
| F-M4-03 | M4 | 地址表重叠 rule 优先级与路由正确性：重叠区间按高位 rule 胜出，路由/ID 前缀/响应回送/数据完整性正确，无跨端口错送（SPEC-3.1.3） | uvm_env+scoreboard_refmodel | M4-OV01 |
| F-M4-04 | M4 | W 通道直通模式（FallThrough）：W beat 与对应 AW 同拍被接受，功能等价于非直通模式，延迟不敏感判据、无固定时序断言（SPEC-7.3.1、SPEC-7.4.3） | uvm_env+scoreboard_refmodel | M4-FT01 |
| F-M4-05 | M4 | err_slv 写响应背压传导与接收侧稳定性：B 响应缓冲堆积至结构容量上界、反压 aw_ready，释放后单拍 B(DECERR) 无丢失重复、响应回送正确（SPEC-4.2/4.3/5.1、BUG-0025 守卫） | uvm_env+scoreboard_refmodel | M4-EB01 |
| F-M4-06 | M4 | 多层压力叠加：W burst 通道饱和（≥3 个）+ AW 锁定-重试 + 同桶事务上限聚合、路由/数据/wstrb/wlast/响应/完成序全部正确无饿死，结构覆盖动机、无内部 FSM 状态/计数具体值断言（SPEC-5.3/5.4.1/5.5.1/5.5.3、BUG-0016/REV-007 守卫） | uvm_env+scoreboard_refmodel | M4-BP02 |
| F-M4-07 | M4 | 多层压力叠加：R burst 通道拖延（有界）+ AR 锁定-重试 + 同桶事务上限聚合、路由/数据/响应/完成序全部正确无饿死，结构覆盖动机、延迟不敏感判据、无内部 FSM 状态/计数具体值断言（SPEC-5.3/5.4.1/5.5.3、BUG-0016/REV-007 守卫） | uvm_env+scoreboard_refmodel | M4-BP03 |
