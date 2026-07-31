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
| (Kind-B 模板，逐位分解已完成，当前结论为空集——见下方说明) | `axi_mux` Toggle | 无——`mst_resp_i.r.data[63:0]` 曾是唯一候选，已被 3/3 对抗票反驳（实为地址镜像，见 `doc/evidence/v0.4.15/M4-toggle-bit-decomposition.md`） | B | （模板保留，供后续真正出现 Kind-B 候选时使用） | M5 决策点 2 约束随机 + 决策点 5 cov_loop 重测；仍 <90% 才议 | `doc/review/REV-025.md`（Conditional pass，结论：M4 阶段 Kind-B 集合为空集） |

**注**：CW-001~CW-005 均为 Kind-A，论证已就绪。**Kind-B 模板行经逐位分解
（`doc/evidence/v0.4.15/M4-toggle-bit-decomposition.md`）+ 独立 rev 复核
（`doc/review/REV-025.md`）后，结论是当前 M4 阶段的合法 Kind-B 豁免集为
**空集**——唯一有结构依据的候选（axi_mux R.data）被证实实为地址派生位、
定向饱和读（all-0/all-1 两向量）即可闭合，不满足"纯定向不经济"这一 Kind-B
判据。故模板行继续保留但不实例化任何具体信号，供未来若真的出现合规 Kind-B
候选时使用。

## 待建档项（Kind-A 候选，尚未走 rev 卡确认，非本表正式条目）

- `axi_mux`/`axi_demux_simple`/`axi_err_slv` 的 `aw/ar.size[2]` 总线宽度
  上限位（64-bit 数据总线下合法 AxSIZE≤3，`size[2]` 结构恒 0）——
  `doc/review/REV-025.md` V4 已亲验 64-bit 基线下成立，但**转正前须先确认
  全部受验配置（cfgA-E）数据总线宽度均 ≤64**，否则更宽配置下 `size[2]`
  可达、不得记 Kind-A。这是一条真实开放项，非走过场。
- `spill_register` 参数 tie-off 的 bypass 路径
- `rst_ni`（若裁定为"验证范围不含运行中复位"而非补场景——待裁决，二选一）
