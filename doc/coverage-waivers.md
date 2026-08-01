# Coverage waivers（rev 签核；REV-024 建档，REV-016 §9.5 触发）

覆盖率缺口（有 bin、<90%）的书面豁免登记本。凡 silent exclude（无本表条目的
排除）失效（`workflow/bugs.md` L229）。每条豁免须声明 **Kind** 与**可证伪解锁**。

- **Kind-A 结构/环境不可达（永久）**：解锁 = 某具体事实被推翻。
- **Kind-B 方法论受限、延后 M5（临时）**：解锁 = M5 约束随机重测后仍 <90% 才
  讨论转永久；被推翻即作废 = 任一 M5 随机跑使该 bin ≥90%。**须附逐位 toggle 分解**。

| waiver-id | (模块,类型) | 具体 bin/信号范围 | Kind | 可证伪论证（不可达性 / 方法论受限） | 解锁条件 | rev 记录 |
| --- | --- | --- | --- | --- | --- | --- |
| CW-001 | `axi_atop_filter` 六类 | 非-FEEDTHROUGH 状态/迁移及其从属 line/cond/tgl/branch（逐弧见 `doc/evidence/v0.4.13/signoff-M4.md` §REV-017 兑现段） | A | §4 clause 7 环境约束：全部 6 例在 `axi_err_slv` 内，进入其状态须 `atop!=0` 抵达译码未命中地址，被环境约束构造性禁止 | 补 err_slv×ATOP 应答许可来源 + 重开 `BUG-0032` | `doc/evidence/v0.4.13/signoff-M4.md` §REV-017 兑现段 / `doc/review/REV-016.md` §6.2 / `doc/review/REV-017.md` |
| CW-002 | `axi_xbar` Toggle | `test_i` scan-enable 位 | A | scan 模式出验证范围（spec §0 未纳入 scan 验证） | 验证范围纳入 scan 测试（若项目决定收窄/取消本豁免） | 待 rev 卡填 |
| CW-003 | `axi_err_slv` Toggle | `slv_resp_o.r.data[63:0]`（全部 64 位恒定） | A | `err_resp.r.data = RespData`（`axi_err_slv.sv:196`），`RespData` 为编译期参数常量 `64'hCA11AB1EBADCAB1E`（`:25`），`axi_xbar_unmuxed.sv` 两处例化点均未 override；为 1 的位永 1、为 0 的位永 0，任何激励不可翻 | xbar 例化改为可变 `RespData`，或该参数被证实运行时可变 | `doc/review/REV-025.md` V1（rev 亲验 RTL + 例化点未 override） |
| CW-004 | `axi_err_slv` Toggle | `r.resp[1:0]`/`b.resp[1:0]`（恒定 `2'b11`） | A | `err_resp.r.resp`/`err_resp.b.resp = Resp`（`:197`/`:145`），`Resp` 默认 `RESP_DECERR`（`:23`）未被 override，两字段全程恒定 `2'b11` | xbar 例化改为可变 `Resp`，或该参数被证实运行时可变 | `doc/review/REV-025.md` V1 |
| CW-005 | `axi_err_slv` Toggle | 出侧 `r.user`/`b.user`（tie-off 恒 0） | A | `err_resp.r`/`err_resp.b` 先赋 `'0` 再只赋 `id`/`resp`/`data`/`valid`（`:191`/`:143`），`user` 字段从未被赋非零值 | 若 `err_resp` 结构改为显式驱动 `user`（当前设计无此路径） | `doc/review/REV-025.md` V1 |
| CW-006 | `axi_xbar`/`axi_mux`/`axi_demux_simple`/`axi_err_slv` Toggle | `rst_ni` 1→0（运行中复位）四模块一致未覆盖方向 | A | spec §2.3（`doc/spec.md` L90）仅定义 `rst_ni` 为"复位，异步、低有效"，未定义运行中（事务在飞时）复位的恢复形态——复位断言时在飞事务去向、复位释放后内部计数器/FSM 恢复语义，五份许可来源皆无。M4 若引入带在飞事务的热复位，checker 期望只能来自 RTL，属 spec-from-RTL 越界（同 BUG-0002/0003/0032 未定义→范围约束先例）；构造"零在飞热复位"场景虽可翻此 toggle 位但不测试任何有意义的复位语义（toggle-theater，REV-026 明确驳回），故按范围外处置 | 验证范围纳入运行中复位测试，且先补齐 spec §2.3 复位恢复语义条款（P-REV026-1，独立 spec-review 门禁） | `doc/review/REV-026.md`（rst_ni 独立裁决段：采纳范围豁免、驳回"空闲窗口热复位脉冲"新场景方案） |
| CW-007 | `axi_mux`/`axi_demux_simple`/`axi_err_slv` Toggle | `aw/ar.size[2]` 总线宽度上限位 | A | 64-bit 数据总线下合法 `AxSIZE≤3'b011`，`size[2]` 结构恒 0，任何合法激励不可达；`tb/xbar_types_pkg.sv:132` `DATA_W` 为单一 `localparam=64`，cfgA-E 配置块（L35-123）均未 override，故全部受验配置数据总线宽度一致为 64 位——REV-025 V4 暂缓转正的前置条件（"须先确认全部配置 ≤64"）已由 REV-026 独立复核确认解除 | 若未来配置矩阵新增更宽数据总线配置点，须重新核实 `size[2]` 可达性，本条即时作废 | `doc/review/REV-025.md` V4 + `doc/review/REV-026.md`（size[2] 独立验证段） |
| CW-008 | `addr_decode_dync` Branch | `proc_check_addr_map`（`addr_decode_dync.sv:146`）的 IF else 支（`MISSING_ELSE`，urg mod20.html Branch 表 IF-146=2/1；模块 Branch 83.33% 的**唯一**未覆盖 bin） | A | IF 条件 `!$isunknown(addr_map_i) && ~config_ongoing_i`：`config_ongoing_i≡1'b0`（`addr_decode.sv:106` 硬 tie-off，xbar 走普通 `addr_decode` 变体、`config_ongoing_i` 非其对外端口，交叉核对 `addr_decode_napot.sv:89` 亦 tie-off）使 `~config_ongoing_i≡1` 恒真 → **else 唯一触达路径 = `addr_map_i` 取 X**。该块为 `ifndef SYNTHESIS` 仿真专用地址表 sanity 断言守卫（`ASSUME_I` check_start/check_overlap）的跳过分支，else 体为空（无 DUT 功能语义）；env 只以具体合法 localparam 驱动地址表、从不注 X（`tb_top.sv:59`、`seq_lib.sv:1323/1779/2478` 仅赋 `ADDR_MAP`/`_V1`/`_OV1`，无 force/isunknown/X 路径），唯一 X 暴露仅 time-0 上电前瞬态、非功能激励且经 urg 证实未触达 else。spec §3.1/§3.2/§3.4 均假定地址表为具体合法值（≥1 rule、`start≤end`、运行时仅在全端口 AW/AR-idle 窗切换），**无未知/X 地址表语义**——构造 X 注入覆盖它属无 spec 基础的 X-theater，其 checker 期望只能来自 RTL（spec-from-RTL 越界，同 CW-006 rst_ni toggle-theater 先例的范围外处置） | 任一具体事实被推翻即作废重裁：(i) `addr_decode.sv:106` 的 `config_ongoing_i` tie-off 改为运行时可驱动非 0（config_ongoing 路径转活）；或 (ii) 验证范围纳入"地址表 X/未配置窗口"测试**且先补齐 spec 对未知地址表语义的条款**（当前 spec §3.1/§3.2/§3.4 无 X 语义，须先补 spec 方有可写 checker 的期望来源——同 CW-006 解锁须先补 spec §2.3 的先例） | `doc/review/REV-029.md`（rev 亲验 RTL tie-off + TB 驱动源 + urg Branch 表；承 REV-028 §4 分流建议独立复核并落地登记） |

**注**：CW-001~CW-008 均为 Kind-A，论证已就绪。**Kind-B 模板行经逐位分解
（`doc/evidence/v0.4.15/M4-toggle-bit-decomposition.md`）+ 独立 rev 复核
（`doc/review/REV-025.md`）后，结论是当前 M4 阶段的合法 Kind-B 豁免集为
**空集**——唯一有结构依据的候选（axi_mux R.data）被证实实为地址派生位、
定向饱和读（all-0/all-1 两向量）即可闭合，不满足"纯定向不经济"这一 Kind-B
判据。故模板行继续保留但不实例化任何具体信号，供未来若真的出现合规 Kind-B
候选时使用。

## 待建档项（Kind-A 候选，尚未走 rev 卡确认，非本表正式条目）

- `spill_register` 参数 tie-off 的 bypass 路径
