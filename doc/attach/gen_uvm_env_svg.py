# -*- coding: utf-8 -*-
"""生成 doc/attach/uvm_env_overview.svg。

画的是**验证环境（UVM TB）**的组件连接图 + 一笔写事务在 TB 侧的数据流
（不是 DUT 内部路径——那张图是 axi_xbar_dataflow.svg）：seq 产生 item →
slvport_driver 打到 DUT slave 端口 → 两个 monitor 在 DUT 两侧观测 →
analysis port 送进 scoreboard 的四个 handler → 与 DUT 响应比对判决。

配色/线型与 axi_xbar_dataflow.svg 保持一致：蓝实线=请求正向、橙虚线=响应
回程、青虚线=analysis port（TB 观测流）、绿框=TB 组件、靛框=DUT 黑盒、
琥珀框=scoreboard、紫虚框=分组边界。

改布局只需改下面的「布局常量」区：三行 y（ROW_Y / MON_Y / SB_Y）定三层高度，
各组件的 (x, w) 定水平位置与宽度，其余文字/箭头按这些常量自动铺开。

用法（仓库根目录）：python3 doc/attach/gen_uvm_env_svg.py
"""

import os

# ---------------- 布局常量 ----------------
W, H = 1020, 700

ROW_Y = 150          # 第 1 层：请求流水线（seq → driver → DUT → responder）中心 y
MON_Y = 270          # 第 2 层：两个 monitor 的中心 y
SB_Y0 = 396          # 第 3 层：scoreboard 大框顶 y

BOX_H = 66           # 流水线方块高度
MON_H = 52           # monitor 方块高度

# 第 1 层各组件 (左 x, 宽 w)
SEQ_X, SEQ_W = 24,  156     # seq_lib.sv 序列 / 虚序列
SQR_X, SQR_W = 202, 126     # slvport_sequencer（虚序列器聚合）
DRV_X, DRV_W = 350, 132     # slvport_driver
DUT_X, DUT_W = 520, 152     # DUT: axi_xbar（黑盒）
RSP_X, RSP_W = 828, 168     # mstport_responder（反应式 slave）

# 第 2 层：两个 monitor（居中对齐 DUT 两侧的观测边界，见 SLV_B / MST_B）
SMON_W, MMON_W = 152, 148
SLV_B = (DRV_X + DRV_W + DUT_X) // 2   # slave 端口边界 x（driver↔DUT 之间）
MST_B = (DUT_X + DUT_W + RSP_X) // 2   # master 端口边界 x（DUT↔responder 之间）
SMON_X = SLV_B - SMON_W // 2           # slvport_monitor 居中在 slave 边界下方
MMON_X = MST_B - MMON_W // 2           # mstport_monitor 居中在 master 边界下方

# 第 3 层：scoreboard_refmodel 大框 + 内部四 handler；右侧 coverage / SVA
SB_X, SB_W, SB_H = 24, 700, 176
COV_X, COV_W = 748, 118      # functional_coverage
SVA_X, SVA_W = 878, 118      # tb/sva/*

FONT = "'Segoe UI', 'PingFang SC', 'Microsoft YaHei', Helvetica, Arial, sans-serif"

REQ   = "#2563eb"   # 蓝：请求正向 / 驱动
RESP  = "#c2410c"   # 橙：响应回程
ANA   = "#0d9488"   # 青：analysis port（TB 观测流）
INK   = "#1e293b"
SUB   = "#64748b"

o = []
a = o.append


def marker(mid, color):
    return (f'    <marker id="{mid}" markerUnits="userSpaceOnUse" markerWidth="12" '
            f'markerHeight="10" refX="10" refY="4" orient="auto">\n'
            f'      <path d="M0,0 L10,4 L0,8 Z" fill="{color}"/>\n    </marker>')


def box(x, y, w, h, fill, stroke, sw=1.4, rx=8):
    a(f'  <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" '
      f'fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>')


def title(cx, y, s, size=12, weight=700, fill=INK):
    a(f'  <text x="{cx}" y="{y}" text-anchor="middle" font-size="{size}" '
      f'font-weight="{weight}" fill="{fill}">{s}</text>')


def sub(cx, y, s, size=8.6, fill=SUB):
    a(f'  <text x="{cx}" y="{y}" text-anchor="middle" font-size="{size}" fill="{fill}">{s}</text>')


def harrow(x1, x2, y, color, dash=False, mark=True):
    d = ' stroke-dasharray="6,4"' if dash else ''
    m = f' marker-end="url(#{ "arrowResp" if color==RESP else "arrowAna" if color==ANA else "arrowReq"})"' if mark else ''
    a(f'  <line x1="{x1}" y1="{y}" x2="{x2}" y2="{y}" stroke="{color}" stroke-width="1.9"{d}{m}/>')


def varrow(x, y1, y2, color, dash=False):
    d = ' stroke-dasharray="6,4"' if dash else ''
    m = f' marker-end="url(#{ "arrowResp" if color==RESP else "arrowAna" if color==ANA else "arrowReq"})"'
    a(f'  <line x1="{x}" y1="{y1}" x2="{x}" y2="{y2}" stroke="{color}" stroke-width="1.9"{d}{m}/>')


# ---------------- 画布 ----------------
a(f'<svg viewBox="0 0 {W} {H}" xmlns="http://www.w3.org/2000/svg" font-family="{FONT}">')
a('  <defs>')
a(marker("arrowReq", REQ))
a(marker("arrowResp", RESP))
a(marker("arrowAna", ANA))
a('  </defs>')
a(f'  <rect x="0" y="0" width="{W}" height="{H}" rx="14" fill="#f5f6fa"/>')

title(W // 2, 34, "验证环境（UVM TB）组件图 —— 一笔写事务的判决数据流", size=19)
sub(W // 2, 56,
    "外部 AXI 由 TB 扮演：slave 侧是主动 driver，master 侧是反应式 responder（TB 在此当被动 slave）。"
    "monitor 只观测、不驱动。", size=12, fill="#475569")

# ---------------- 分组虚框：slvport_agent / mstport_agent ----------------
# 两个 agent 框都纵跨第 1 层（driver/responder）与第 2 层（monitor）。
GTOP = ROW_Y - BOX_H // 2 - 12
GBOT = MON_Y + MON_H // 2 + 10
slv_gx0, slv_gx1 = DRV_X - 12, SMON_X + SMON_W + 12
box(slv_gx0, GTOP, slv_gx1 - slv_gx0, GBOT - GTOP, "#f7f6ff", "#6d28d9", 1.2, 10)
a(f'  <text x="{slv_gx0 + 6}" y="{GTOP - 6}" font-size="10.5" '
  f'font-weight="700" fill="#4338ca">slvport_agent ×NoSlvPorts</text>')

mst_gx0, mst_gx1 = MMON_X - 12, RSP_X + RSP_W + 12
box(mst_gx0, GTOP, mst_gx1 - mst_gx0, GBOT - GTOP, "#f7fbff", "#6d28d9", 1.2, 10)
a(f'  <text x="{mst_gx0 + 6}" y="{GTOP - 6}" font-size="10.5" '
  f'font-weight="700" fill="#4338ca">mstport_agent ×NoMstPorts</text>')

# ---------------- 第 1 层：请求流水线 ----------------
cy = ROW_Y
top = cy - BOX_H // 2


def pipebox(x, w, name, sub1, sub2, fill, stroke, sw=1.4):
    box(x, top, w, BOX_H, fill, stroke, sw)
    title(x + w // 2, cy - 8, name, size=11.5)
    sub(x + w // 2, cy + 9, sub1)
    if sub2:
        sub(x + w // 2, cy + 22, sub2)


pipebox(SEQ_X, SEQ_W, "seq_lib.sv", "seq / vseq", "fanout_per_slv#(T)", "#ffffff", "#334155")
pipebox(SQR_X, SQR_W, "slvport_sequencer", "由 xbar_vseqr 聚合", "slv_sqr[i]", "#ffffff", "#334155")
pipebox(DRV_X, DRV_W, "slvport_driver", "drive_write / _read", "drive_pair / _burst", "#ffffff", "#334155")
pipebox(DUT_X, DUT_W, "DUT: axi_xbar", "被测黑盒", "slave 端口 ↔ master 端口", "#eef2ff", "#4338ca", 2.0)
pipebox(RSP_X, RSP_W, "mstport_responder", "反应式 AXI slave", "b/r_respond_loop", "#ffffff", "#334155")

# 请求正向箭头（蓝实线）
harrow(SEQ_X + SEQ_W + 3, SQR_X - 3, cy, REQ)
harrow(SQR_X + SQR_W + 3, DRV_X - 3, cy, REQ)
# driver → DUT slave 端口：AW/W
a(f'  <line x1="{DRV_X + DRV_W + 3}" y1="{cy - 8}" x2="{DUT_X - 3}" y2="{cy - 8}" '
  f'stroke="{REQ}" stroke-width="1.9" marker-end="url(#arrowReq)"/>')
a(f'  <text x="{(DRV_X + DRV_W + DUT_X) // 2}" y="{cy - 14}" text-anchor="middle" '
  f'font-size="8.5" fill="{REQ}">AW/W</text>')
# DUT master 端口 → responder：AW/W
a(f'  <line x1="{DUT_X + DUT_W + 3}" y1="{cy - 8}" x2="{RSP_X - 3}" y2="{cy - 8}" '
  f'stroke="{REQ}" stroke-width="1.9" marker-end="url(#arrowReq)"/>')
# responder → DUT → driver：B 响应回程（橙虚线，沿下缘反向）
a(f'  <line x1="{RSP_X - 3}" y1="{cy + 12}" x2="{DUT_X + DUT_W + 3}" y2="{cy + 12}" '
  f'stroke="{RESP}" stroke-width="1.8" stroke-dasharray="6,4" marker-end="url(#arrowResp)"/>')
a(f'  <line x1="{DUT_X - 3}" y1="{cy + 12}" x2="{DRV_X + DRV_W + 3}" y2="{cy + 12}" '
  f'stroke="{RESP}" stroke-width="1.8" stroke-dasharray="6,4" marker-end="url(#arrowResp)"/>')
a(f'  <text x="{(DUT_X + DUT_W + RSP_X) // 2}" y="{cy + 24}" text-anchor="middle" '
  f'font-size="8.5" fill="{RESP}">B</text>')

# ---------------- 第 2 层：两个 monitor ----------------
mtop = MON_Y - MON_H // 2
box(SMON_X, mtop, SMON_W, MON_H, "#ffffff", "#0f766e", 1.6)
title(SMON_X + SMON_W // 2, MON_Y - 6, "slvport_monitor", size=11, fill="#0f766e")
sub(SMON_X + SMON_W // 2, MON_Y + 9, "req_accept_ap · req_ap · resp_ap", size=8.2)

box(MMON_X, mtop, MMON_W, MON_H, "#ffffff", "#0f766e", 1.6)
title(MMON_X + MMON_W // 2, MON_Y - 6, "mstport_monitor", size=11, fill="#0f766e")
sub(MMON_X + MMON_W // 2, MON_Y + 9, "req_ap（请求侧观测）", size=8.2)

# monitor 观测抽头（青虚线，从 DUT 两侧端口边界向下引到 monitor 顶部中心）
a(f'  <line x1="{SLV_B}" y1="{cy + BOX_H // 2}" x2="{SLV_B}" y2="{mtop - 3}" '
  f'stroke="{ANA}" stroke-width="1.6" stroke-dasharray="3,3" marker-end="url(#arrowAna)"/>')
a(f'  <text x="{SLV_B + 5}" y="{(cy + BOX_H // 2 + mtop) // 2}" font-size="8" '
  f'fill="{ANA}">观测 slave 端口</text>')
a(f'  <line x1="{MST_B}" y1="{cy + BOX_H // 2}" x2="{MST_B}" y2="{mtop - 3}" '
  f'stroke="{ANA}" stroke-width="1.6" stroke-dasharray="3,3" marker-end="url(#arrowAna)"/>')
a(f'  <text x="{MST_B + 5}" y="{(cy + BOX_H // 2 + mtop) // 2}" font-size="8" '
  f'fill="{ANA}">观测 master 端口</text>')

# ---------------- 第 3 层：scoreboard_refmodel + coverage + SVA ----------------
box(SB_X, SB_Y0, SB_W, SB_H, "#fffbeb", "#b45309", 1.8, 10)
a(f'  <text x="{SB_X + 10}" y="{SB_Y0 + 18}" font-size="12.5" font-weight="700" '
  f'fill="#92400e">scoreboard_refmodel.sv —— spec 推导的参考模型 + 五合一判决</text>')

# 四个 handler 子框
HW, HH, HGAP = 158, 96, 12
HY = SB_Y0 + 34
hx0 = SB_X + 14
handlers = [
    ("write_slv_req_accept", "AW/AR-accept 流", "or_open_q 开单 · cg_stall", "cg_tx_limit · worder_pend", "#0f766e"),
    ("write_slv_req", "w_last 流（写）", "查活表定目标 master 端口", "登记 pending_by_id 路由期望", "#0f766e"),
    ("write_mst_req", "master 端口请求侧", "SB_ROUTE：端口/前缀 ID 对不对", "SB_WORDER：同源 W 保序", "#b45309"),
    ("write_resp", "B/R 响应流", "SB_RESP_ROUTE · SB_OR_REORDER", "SB_DECERR_ORDER · atop 配对", "#c2410c"),
]
for k, (nm, s0, s1, s2, col) in enumerate(handlers):
    hx = hx0 + k * (HW + HGAP)
    box(hx, HY, HW, HH, "#ffffff", col, 1.5, 7)
    title(hx + HW // 2, HY + 18, nm, size=10, fill=col)
    sub(hx + HW // 2, HY + 34, s0, size=8.4)
    sub(hx + HW // 2, HY + 52, s1, size=8.2, fill="#475569")
    sub(hx + HW // 2, HY + 68, s2, size=8.2, fill="#475569")
    sub(hx + HW // 2, HY + 86, "判据锚回 doc/spec.md", size=7.6, fill="#94a3b8")

# analysis port 竖直连线：monitor → 对应 handler（青虚线，带标签）
h_cx = [hx0 + k * (HW + HGAP) + HW // 2 for k in range(4)]
smon_bot = mtop + MON_H
# slvport_monitor 三条 ap → handler 0/1/3
for k, lbl in [(0, "req_accept_ap"), (1, "req_ap"), (3, "resp_ap")]:
    x_out = SMON_X + 24 + (k if k < 3 else 2) * 44
    a(f'  <polyline points="{x_out},{smon_bot} {x_out},{smon_bot + 14} '
      f'{h_cx[k]},{smon_bot + 14} {h_cx[k]},{HY - 3}" fill="none" '
      f'stroke="{ANA}" stroke-width="1.5" stroke-dasharray="4,3" marker-end="url(#arrowAna)"/>')
a(f'  <text x="{SMON_X + 2}" y="{smon_bot + 26}" font-size="8" fill="{ANA}">'
  f'req_accept_ap / req_ap / resp_ap</text>')
# mstport_monitor req_ap → handler 2
xm = MMON_X + MMON_W // 2
a(f'  <polyline points="{xm},{smon_bot} {xm},{smon_bot + 24} '
  f'{h_cx[2]},{smon_bot + 24} {h_cx[2]},{HY - 3}" fill="none" '
  f'stroke="{ANA}" stroke-width="1.5" stroke-dasharray="4,3" marker-end="url(#arrowAna)"/>')
a(f'  <text x="{xm + 6}" y="{smon_bot + 20}" font-size="8" fill="{ANA}">req_ap</text>')

# functional_coverage + SVA 侧框
box(COV_X, SB_Y0, COV_W, SB_H, "#ecfdf5", "#10b981", 1.6, 10)
title(COV_X + COV_W // 2, SB_Y0 + 20, "functional_", size=10.5, fill="#065f46")
title(COV_X + COV_W // 2, SB_Y0 + 34, "coverage.sv", size=10.5, fill="#065f46")
sub(COV_X + COV_W // 2, SB_Y0 + 58, "独立 covergroup 集", size=8.4, fill="#047857")
sub(COV_X + COV_W // 2, SB_Y0 + 74, "由 scoreboard 采样喂入", size=8.0, fill="#047857")
sub(COV_X + COV_W // 2, SB_Y0 + 96, "cg_stall / cg_tx_limit", size=7.8, fill="#059669")
sub(COV_X + COV_W // 2, SB_Y0 + 110, "cg_w_order …", size=7.8, fill="#059669")
# scoreboard → coverage 采样箭头
a(f'  <line x1="{SB_X + SB_W + 2}" y1="{SB_Y0 + SB_H // 2}" x2="{COV_X - 3}" y2="{SB_Y0 + SB_H // 2}" '
  f'stroke="{ANA}" stroke-width="1.6" marker-end="url(#arrowAna)"/>')

box(SVA_X, SB_Y0, SVA_W, SB_H, "#f5f3ff", "#6d28d9", 1.6, 10)
title(SVA_X + SVA_W // 2, SB_Y0 + 20, "tb/sva/*", size=10.5, fill="#5b21b6")
sub(SVA_X + SVA_W // 2, SB_Y0 + 42, "协议 / 时序 SVA", size=8.4, fill="#6d28d9")
sub(SVA_X + SVA_W // 2, SB_Y0 + 58, "generate 直接例化", size=8.0, fill="#6d28d9")
sub(SVA_X + SVA_W // 2, SB_Y0 + 72, "（非 bind，见头注）", size=7.6, fill="#7c3aed")
sub(SVA_X + SVA_W // 2, SB_Y0 + 94, "axi_chan / route /", size=7.8, fill="#7c3aed")
sub(SVA_X + SVA_W // 2, SB_Y0 + 108, "stall / worder …", size=7.8, fill="#7c3aed")

# ---------------- 图例 ----------------
LY = SB_Y0 + SB_H + 30
a(f'  <line x1="30" y1="{LY}" x2="78" y2="{LY}" stroke="{REQ}" stroke-width="2" marker-end="url(#arrowReq)"/>')
a(f'  <text x="88" y="{LY + 4}" font-size="11" fill="#334155">请求正向：seq → sequencer → driver → DUT slave 端口 → DUT master 端口 → responder</text>')
a(f'  <line x1="30" y1="{LY + 22}" x2="78" y2="{LY + 22}" stroke="{RESP}" stroke-width="2" stroke-dasharray="6,4" marker-end="url(#arrowResp)"/>')
a(f'  <text x="88" y="{LY + 26}" font-size="11" fill="#334155">响应回程：responder 回 B/R → 沿原路经 DUT → 被 slvport_monitor 在源 slave 端口观测</text>')
a(f'  <line x1="30" y1="{LY + 44}" x2="78" y2="{LY + 44}" stroke="{ANA}" stroke-width="2" stroke-dasharray="4,3" marker-end="url(#arrowAna)"/>')
a(f'  <text x="88" y="{LY + 48}" font-size="11" fill="#334155">analysis port（TB 观测流）：monitor 把观测到的事务经 analysis port 送进 scoreboard 对应 handler 判决</text>')

a('</svg>')

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uvm_env_overview.svg")
with open(out, "w", encoding="utf-8") as f:
    f.write("\n".join(o) + "\n")
print(f"wrote {out}  ({W}x{H})")
