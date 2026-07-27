# Vendored DUT snapshot

Upstream code under `vendor/` is a **read-only snapshot**, SHA-locked below.
Never edit vendored files directly; behavioral deviations go through the
P-xxx patch flow so every delta from upstream is recorded, justified, and
rev-reviewed.

## Locked upstream versions

| Component | Upstream repo | Version/tag | Commit SHA | License | Copied scope |
| --- | --- | --- | --- | --- | --- |
| axi/ | https://github.com/pulp-platform/axi | v0.39.9 | a256a3b86394fedf19e361047fccfdd7f6ef83e4 | SHL-0.51 | src/ + include/ + test/{tb_axi_xbar.sv, tb_axi_xbar_pkg.sv} + doc/{axi_xbar, axi_demux, axi_mux}.md |
| common_cells/ | https://github.com/pulp-platform/common_cells | v1.39.0 | 9ca8a7655f741e7dd5736669a20a301325194c28 | SHL-0.51 | src/ + include/ |
| common_verification/ | https://github.com/pulp-platform/common_verification | v0.2.5 | fb1885f48ea46164a10568aeff51884389f67ae3 | SHL-0.51 | src/ |
| tech_cells_generic/ | https://github.com/pulp-platform/tech_cells_generic | v0.2.13 | 7968dd6e6180df2c644636bc6d2908a49f2190cf | SHL-0.51 | src/ |

**来源注记**：
- 各库 `src/` + `include/` 复制自同机 `floo_axi_chimney/vendor/`
  （其 pin 记录见该仓库 `vendor/VENDOR.md`，版本基准为 FlooNoC v0.8.4
  的 Bender.lock；该仓库唯一本地补丁 P-001 仅涉及 `floonoc/`，本处
  四库为上游纯净快照）。
- `axi/test/` 两个文件与 `axi/doc/` 三个文档于 2026-07-27 按**同 tag
  v0.39.9** 从 `raw.githubusercontent.com/pulp-platform/axi/v0.39.9/`
  直接拉取（本地快照原拷贝范围不含 test/ 与 doc/）。
- 版本自洽性：axi v0.39.9 的 Bender.yml 依赖 common_cells ^1.39.0、
  common_verification ^0.2.5、tech_cells_generic ^0.2.2，上表均满足。
- DUT 本体：`vendor/axi/src/axi_xbar.sv`。上游最新 release 为
  v0.39.10；升级评估已登记为 M1 任务（见 CLAUDE.md §6 里程碑）。

## Patches (P-xxx)

Applied only when the snapshot cannot run in this environment (tool
compatibility) or a confirmed upstream bug blocks work. Behavior-equivalent
unless the linked bug record says otherwise.

| ID | File(s) | Reason | Behavior impact | Bug/FL ref | rev review |
| --- | --- | --- | --- | --- | --- |

Flow: patch → register the row here → request rev review → **main session
backfills the review column** (rev has no write access to this file). An
empty review cell on an applied patch is a gate finding.

Confirmed upstream bugs (taxonomy `DUT_BUG`): record as an FL, patch with a
P-xxx row, and consider reporting upstream.
