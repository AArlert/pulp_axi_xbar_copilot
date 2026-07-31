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
| (Kind-B 模板，须先出逐位分解方可填) | `axi_mux` Toggle | 仅 W.data/R.data[63:0] 载荷位子集（**排除** id/addr/控制/实例 7-8 可达位） | B | 载荷位取值为被搬运数据、不对应控制决策；纯定向仅用少数固定取值，扫遍 64 位双向须海量互异取值（线性但不经济），属随机方法论用途 | M5 决策点 2 约束随机 + 决策点 5 cov_loop 重测；仍 <90% 才议 | 待逐位分解卡 + rev 卡填 |

**注**：CW-001/CW-002 为 Kind-A，论证已就绪可直接落；Kind-B 行为**模板**——
`doc/review/REV-024.md` **不预先授予任何 Kind-B 豁免**，须先有逐信号/逐位
toggle 分解证据（见该记录 §5「对 M4 签核本身的影响」两张清单）方可正式登记。

## 待建档项（Kind-A 候选，尚未走 rev 卡确认，非本表正式条目）

以下项经 `doc/review/REV-024.md` §7 指出为 Kind-A 候选，尚需各自的 rev 卡
给出可证伪的不可达性论证后才能转正为本表条目：

- `axi_err_slv` 恒定错误应答数据位（读响应数据固定值，见 BUG-0033/REV-014）
- `spill_register` 参数 tie-off 的 bypass 路径
- `rst_ni`（若裁定为"验证范围不含运行中复位"而非补场景——待裁决，二选一）
