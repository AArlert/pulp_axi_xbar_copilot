# Vendor upgrade evaluation — pulp-platform/axi v0.39.9 → v0.39.10

> 评估性文档（M1 任务，CLAUDE.md §6 里程碑）。**本文只做评估，不改动
> `vendor/` 与 `vendor/VENDOR.md`。** 采纳与否由 orch 依本文裁决后另行走 pin 流程。

- 当前 pin：v0.39.9，SHA `a256a3b86394fedf19e361047fccfdd7f6ef83e4`（`vendor/VENDOR.md`）
- 目标：v0.39.10（2026-06-19 release）
- 比对方法：拉取 v0.39.10 tag 下 `src/{axi_xbar,axi_pkg,axi_demux,axi_mux}.sv` 与
  `doc/{axi_xbar,axi_demux,axi_mux}.md`，逐文件 `diff` 对本地 vendored 快照
  （`doc/spec.md` §0 声明的全部 spec 蒸馏来源清单）+ 通读 v0.39.10 CHANGELOG。

## 1. 结论（TL;DR）

**Defer（暂不升级）。** v0.39.10 对 `axi_xbar` **无任何 spec 相关变更**：接口、参数、
类型定义、下层强制子模块 RTL、上游文档全部逐字节或功能不变；唯一的 `axi_xbar.sv`
实质变更是删除一段冗余的 elaboration 断言（#407），不改变任何外部可见行为。升级带来的
唯一潜在收益是 tb/CI 侧弹起修复（#414/#417），但其针对 Verilator/yosys-slang，而本项目
实跑工具链为 VCS-2018，故不解决我们的 P-001/P-002 workaround。综合「零 spec 收益 + 需
重做 P-002 补丁并重跑 M0 sanity + 需重 pin」的成本，**推迟到后续里程碑（建议 M2/M3
需要更广 vendor 刷新时一并评估）**，不阻塞 M1。

## 2. spec 来源清单逐文件比对（`doc/spec.md` §0 蒸馏来源）

| 文件 | v0.39.9 → v0.39.10 | spec 相关性 |
| --- | --- | --- |
| `doc/axi_xbar.md` | **逐字节相同** | 无 |
| `doc/axi_demux.md` | **逐字节相同** | 无 |
| `doc/axi_mux.md` | **逐字节相同** | 无 |
| `src/axi_pkg.sv`（`xbar_cfg_t`/`xbar_latency_e`/`xbar_rule_*_t` 定义段等全文） | **逐字节相同** | 无（DV 唯一可读参数定义文件不变） |
| `src/axi_demux.sv`（xbar 强制内部子模块） | **逐字节相同** | 无 |
| `src/axi_mux.sv`（xbar 强制内部子模块） | **逐字节相同** | 无 |
| `src/axi_xbar.sv` | 唯一实质差异见 §3（另有本地 P-002 localparam 与本次比对无关） | 见 §3：非行为、非接口 |

> 说明：本地 `src/axi_xbar.sv` 含 P-002 补丁（`AddrMapMsb` localparam + 两处端口
> 位宽改写），diff 中出现的相关行是**我们的补丁**，与上游 v0.39.9→v0.39.10 演进无关，
> 已剔除后判定。

## 3. `axi_xbar.sv` 的唯一上游实质变更（#407）

v0.39.10 删除了 `axi_xbar` module 体内一段位于
`pragma translate_off / ifndef VERILATOR / ifndef XSIM` 保护下的 `check_params`
initial 断言块，该块在 elaboration 期检查
`$bits(slv_ports_req_i[0].aw.id) == Cfg.AxiIdWidthSlvPorts` 与
`$bits(slv_ports_resp_o[0].r.id) == Cfg.AxiIdWidthSlvPorts`（对应 CHANGELOG
「`axi_xbar`: Remove redundant assertions. #407」）。

- 性质：**类型宽度一致性的 elaboration 期自检**，非功能/时序/响应行为；删除它不改变
  任何 spec §1–§8 描述的外部可见行为，也不改端口/参数/类型。
- 对本项目影响：无。我们本就用 `AXI_TYPEDEF` 宏按 `Cfg` 一致绑定类型（tb_top C1.3），
  该冗余断言在正确绑定下恒不触发；删或留对 M1 env 落地无差别。

## 4. CHANGELOG 中其余 v0.39.10 条目的相关性研判

| 条目 | 判定 |
| --- | --- |
| #406 `axi_demux_id_counters`: 拆分为独立 module 并加端口 | **不影响**：v0.39.10 的 `axi_demux.sv` 与 v0.39.9 逐字节相同、未引用任何新独立 module，故该新模块**不进入** `axi_xbar` 的强制内部子模块例化树（spec §0 行 4 覆盖率层次不变） |
| #413 参数端口列表加 `DECL` 宏 / #405 `axi_xbar_unmuxed` 排除 Genus 多维接口 | 未落到本项目比对的 `axi_xbar.sv`/子模块可见差异；对 struct 参数化 API 例化无影响 |
| #391 用 XSIM define 移除 `src` 下 default disable 块 / #414 修 Verilator/yosys-slang elaboration / #417 修 tb queue 格式符 | tb/CI/其他仿真器向工具修复；本项目工具链为 **VCS-2018**，不受益、亦不需要；#414/#417 与我们 P-001（tb `$sformatf` NCE）/P-002（端口位宽 NCE）不同根因（Verilator/yosys-slang vs VCS-MX 常量折叠），升级**不消除**我们的补丁需求 |
| #412/#418/#409/#403 等（`axi_lite_mailbox`/`axi_to_detailed_mem`/`axi_id_remap`/`axi_fifo_delay_dyn`） | 均为 `axi_xbar` **从不例化**的旁系模块（spec §0 行 5 范围外），无关 |

## 5. 采纳成本与建议

- **收益**：对 `axi_xbar` DUT 验证为**零**（spec 来源全不变）。
- **成本**：需将 P-002 端口位宽补丁重做/重核到新 `axi_xbar.sv`（行号漂移），重跑 M0
  上游 sanity 确认无回归，更新 `vendor/VENDOR.md` pin（SHA/tag/来源注记）。`doc/spec.md`
  的 sha256 pin **无需**变更（蒸馏来源逐字节不变，spec 正文不动）。
- **建议**：**Defer**。M1 在现 pin（v0.39.9）上推进 UVM env 与 smoke 无任何阻碍；
  待后续里程碑（如 M2 引入更广工具/依赖刷新，或上游出现 `axi_xbar` **行为/文档**级
  变更）时再统一评估升级。若届时采纳，按上述成本清单执行并重新走本评估。
