# -*- coding: utf-8 -*-
"""生成 doc/attach/axi_xbar_dataflow.svg。

基线配置 NoSlvPorts=6 / NoMstPorts=8，交叉连接矩阵逐格展开（6×8 = 48 格）。
改配置只需改下面的 NS / NM，其余布局按常量自动铺开。

用法（仓库根目录）：python3 doc/attach/gen_dataflow_svg.py
"""

import os

# ---------------- 配置 ----------------
NS, NM = 6, 8                 # NoSlvPorts / NoMstPorts
EX_I, EX_J = 2, 5             # 高亮示例路径：slave 端口 EX_I -> master 端口 EX_J

# ---------------- 布局常量 ----------------
GAP = 34                      # 左侧流水线各级之间的水平间隔（须明显大于箭头长度 10）
ROW_PITCH = 80                # 行间距
ROW_Y0 = 156                  # 第 0 行 rail 的 y
BOX_H = 40                    # 左侧方块高度
CELL_H = 44                   # 矩阵格高度

S_X, S_W = 14, 76                          # 外部 AXI master
D_X, D_W = S_X + S_W + GAP, 92             # addr_decode
X_X, X_W = D_X + D_W + GAP, 86             # axi_demux

COL_W, COL_PITCH = 84, 94
COL_X0 = X_X + X_W + GAP
ERR_K = NM                                 # 最右一列 = demux 第 NoMstPorts 路（decode error）

RY = [ROW_Y0 + i * ROW_PITCH for i in range(NS)]

def cx(k): return COL_X0 + k * COL_PITCH
def cc(k): return cx(k) + COL_W // 2

MAT_X0, MAT_X1 = COL_X0 - 10, cx(ERR_K) + COL_W + 10
MAT_Y0, MAT_Y1 = RY[0] - CELL_H // 2 - 6, RY[-1] + CELL_H // 2 + 12

MUX_Y, MUX_H = MAT_Y1 + 30, 50             # axi_mux 一排
MP_Y, MP_H = MUX_Y + MUX_H + 34, 48        # 外部 AXI slave 一排
LY = MP_Y + MP_H + 38                      # 图例起始 y

W = MAT_X1 + 14
H = LY + 118

FONT = "'Segoe UI', 'PingFang SC', 'Microsoft YaHei', Helvetica, Arial, sans-serif"

o = []
a = o.append


def marker(mid, color, w=12, h=10):
    # markerUnits="userSpaceOnUse"：箭头尺寸与线宽解耦，避免箭头胀大后挤满间隔
    return (f'    <marker id="{mid}" markerUnits="userSpaceOnUse" markerWidth="{w}" '
            f'markerHeight="{h}" refX="10" refY="4" orient="auto">\n'
            f'      <path d="M0,0 L10,4 L0,8 Z" fill="{color}"/>\n    </marker>')


a(f'<svg viewBox="0 0 {W} {H}" xmlns="http://www.w3.org/2000/svg" font-family="{FONT}">')
a('  <defs>')
a(marker("arrowBlue", "#2563eb"))
a(marker("arrowOrange", "#c2410c"))
a('  </defs>')
a(f'  <rect x="0" y="0" width="{W}" height="{H}" rx="14" fill="#f5f6fa"/>')

# ---------------- 标题 ----------------
a(f'  <text x="{W//2}" y="36" text-anchor="middle" font-size="20" font-weight="700" fill="#1e293b">'
  f'axi_xbar 请求 / 响应数据流（基线配置 NoSlvPorts={NS}, NoMstPorts={NM}，交叉矩阵逐格展开）</text>')
a(f'  <text x="{W//2}" y="60" text-anchor="middle" font-size="12.5" fill="#475569">'
  f'外部 AXI master 接在 xbar 的 slave 端口 S0..S{NS-1}；外部 AXI slave 接在 xbar 的 master 端口 M0..M{NM-1}。'
  f'交叉矩阵 {NS}×{NM} = {NS*NM} 格，每格独立例化。</text>')
a(f'  <text x="{W//2}" y="80" text-anchor="middle" font-size="12.5" fill="#475569">'
  f'默认 <tspan font-weight="700">Connectivity = \'1</tspan>（全连接），故 {NS*NM} 格全部为 axi_multicut；'
  f'若某格 Connectivity[i][j]=0，该格改例化 axi_err_slv（见右下角）。</text>')

# ---------------- 矩阵区域 ----------------
a(f'  <rect x="{MAT_X0}" y="{MAT_Y0}" width="{MAT_X1-MAT_X0}" height="{MAT_Y1-MAT_Y0}" rx="10" '
  f'fill="#f7f6ff" stroke="#6d28d9" stroke-width="1.4" stroke-dasharray="7,4"/>')
a(f'  <text x="{MAT_X0+4}" y="{MAT_Y0-10}" font-size="12.5" font-weight="700" fill="#4338ca">'
  f'交叉连接矩阵（axi_xbar_unmuxed 内，gen_xbar_slv_cross / gen_xbar_mst_cross 双层 generate）</text>')

# 行 rail（demux 的 NoMstPorts+1 路扇出），画在格子底下
for y in RY:
    a(f'  <line x1="{X_X+X_W}" y1="{y}" x2="{cx(ERR_K)+COL_W}" y2="{y}" stroke="#c7d2fe" stroke-width="2"/>')
# 列汇流线，向下进 axi_mux
for j in range(NM):
    a(f'  <line x1="{cc(j)}" y1="{RY[0]-CELL_H//2}" x2="{cc(j)}" y2="{MUX_Y-6}" '
      f'stroke="#c7d2fe" stroke-width="2" marker-end="url(#arrowBlue)"/>')

# ---------------- 高亮示例路径（画在格子底下）----------------
ey, ex = RY[EX_I], cc(EX_J)
a(f'  <polyline points="{X_X+X_W},{ey} {ex},{ey} {ex},{MP_Y}" fill="none" stroke="#a5b4fc" '
  f'stroke-width="13" stroke-linecap="round" stroke-linejoin="round" opacity="0.75"/>')
a(f'  <polyline points="{X_X+X_W},{ey} {ex},{ey} {ex},{MP_Y-4}" fill="none" stroke="#2563eb" '
  f'stroke-width="2.2" marker-end="url(#arrowBlue)"/>')
a(f'  <polyline points="{ex+8},{MP_Y} {ex+8},{ey+8} {X_X+X_W},{ey+8}" fill="none" stroke="#c2410c" '
  f'stroke-width="1.8" stroke-dasharray="6,4" marker-end="url(#arrowOrange)"/>')

# ---------------- 矩阵格子 ----------------
for i, y in enumerate(RY):
    for j in range(NM):
        hot = (i == EX_I and j == EX_J)
        a(f'  <rect x="{cx(j)}" y="{y-CELL_H//2}" width="{COL_W}" height="{CELL_H}" rx="6" '
          f'fill="{"#d1fae5" if hot else "#ecfdf5"}" stroke="{"#065f46" if hot else "#10b981"}" '
          f'stroke-width="{2.2 if hot else 1.1}"/>')
        # 格内只标索引，模块名交给图例（缩放后仍读得清）
        a(f'  <text x="{cc(j)}" y="{y+6}" text-anchor="middle" font-size="16" font-weight="700" fill="#065f46">[{i}][{j}]</text>')
    # demux 第 NoMstPorts 路：本 slave 端口专属的 decode error 从机
    a(f'  <rect x="{cx(ERR_K)}" y="{y-CELL_H//2}" width="{COL_W}" height="{CELL_H}" rx="6" '
      f'fill="#fef2f2" stroke="#b91c1c" stroke-width="1.1"/>')
    a(f'  <text x="{cc(ERR_K)}" y="{y+6}" text-anchor="middle" font-size="16" font-weight="700" fill="#991b1b">[{i}][{NM}]</text>')

# ---------------- 左侧各行 ----------------
for i, y in enumerate(RY):
    t, hot = y - BOX_H // 2, (i == EX_I)
    ring, sw = ("#2563eb", 2.0) if hot else ("#334155", 1.4)
    a(f'  <rect x="{S_X}" y="{t}" width="{S_W}" height="{BOX_H}" rx="7" fill="#ffffff" stroke="{ring}" stroke-width="{sw}"/>')
    a(f'  <text x="{S_X+S_W//2}" y="{y-3}" text-anchor="middle" font-size="13" font-weight="700" fill="#1e293b">S{i}</text>')
    a(f'  <text x="{S_X+S_W//2}" y="{y+12}" text-anchor="middle" font-size="8.5" fill="#64748b">AXI master</text>')
    a(f'  <line x1="{S_X+S_W+3}" y1="{y}" x2="{D_X-3}" y2="{y}" stroke="#2563eb" stroke-width="1.8" marker-end="url(#arrowBlue)"/>')

    a(f'  <rect x="{D_X}" y="{t}" width="{D_W}" height="{BOX_H}" rx="7" fill="#ffffff" stroke="{ring}" stroke-width="{sw}"/>')
    a(f'  <text x="{D_X+D_W//2}" y="{y-3}" text-anchor="middle" font-size="11" font-weight="700" fill="#1e293b">addr_decode</text>')
    a(f'  <text x="{D_X+D_W//2}" y="{y+12}" text-anchor="middle" font-size="8.5" fill="#64748b">AW / AR 各一个</text>')
    a(f'  <line x1="{D_X+D_W+3}" y1="{y}" x2="{X_X-3}" y2="{y}" stroke="#2563eb" stroke-width="1.8" marker-end="url(#arrowBlue)"/>')

    a(f'  <rect x="{X_X}" y="{t}" width="{X_W}" height="{BOX_H}" rx="7" fill="#ffffff" stroke="{ring}" stroke-width="{sw}"/>')
    a(f'  <text x="{X_X+X_W//2}" y="{y-3}" text-anchor="middle" font-size="11" font-weight="700" fill="#1e293b">axi_demux</text>')
    a(f'  <text x="{X_X+X_W//2}" y="{y+12}" text-anchor="middle" font-size="8.5" fill="#64748b">{NM+1} 路输出，选 1</text>')

a(f'  <text x="{S_X}" y="{MAT_Y0-10}" font-size="11.5" font-weight="700" fill="#334155">每个 slave 端口一路（×{NS}）</text>')

# 示例路径标注（落在两行之间的空隙里，垫一层与矩阵同色的底避免压线）
a(f'  <rect x="{X_X+X_W+4}" y="{ey-CELL_H//2-24}" width="440" height="18" rx="4" fill="#f7f6ff"/>')
a(f'  <text x="{X_X+X_W+9}" y="{ey-CELL_H//2-10}" font-size="10.5" font-weight="700" fill="#1d4ed8">'
  f'示例路径：S{EX_I} → 格 [{EX_I}][{EX_J}] → axi_mux {EX_J} → M{EX_J}（蓝色高亮）；B/R 沿原路返回（橙色虚线）</text>')

# ---------------- axi_mux + master 端口 ----------------
for j in range(NM):
    hot = (j == EX_J)
    ring, sw = ("#2563eb", 2.0) if hot else ("#334155", 1.4)
    a(f'  <rect x="{cx(j)}" y="{MUX_Y}" width="{COL_W}" height="{MUX_H}" rx="7" fill="#ffffff" stroke="{ring}" stroke-width="{sw}"/>')
    a(f'  <text x="{cc(j)}" y="{MUX_Y+19}" text-anchor="middle" font-size="11" font-weight="700" fill="#1e293b">axi_mux</text>')
    a(f'  <text x="{cc(j)}" y="{MUX_Y+33}" text-anchor="middle" font-size="8.5" fill="#64748b">{NS} 入 1 出 · 仲裁</text>')
    a(f'  <text x="{cc(j)}" y="{MUX_Y+45}" text-anchor="middle" font-size="8.5" fill="#64748b">ID 前缀来源端口号</text>')
    a(f'  <line x1="{cc(j)}" y1="{MUX_Y+MUX_H+3}" x2="{cc(j)}" y2="{MP_Y-3}" stroke="#2563eb" stroke-width="1.8" marker-end="url(#arrowBlue)"/>')
    a(f'  <rect x="{cx(j)}" y="{MP_Y}" width="{COL_W}" height="{MP_H}" rx="7" fill="#ffffff" stroke="{ring}" stroke-width="{sw}"/>')
    a(f'  <text x="{cc(j)}" y="{MP_Y+23}" text-anchor="middle" font-size="13" font-weight="700" fill="#1e293b">M{j}</text>')
    a(f'  <text x="{cc(j)}" y="{MP_Y+38}" text-anchor="middle" font-size="8.5" fill="#64748b">AXI slave</text>')

a(f'  <text x="{cc(ERR_K)}" y="{MUX_Y+18}" text-anchor="middle" font-size="9.5" font-weight="700" fill="#991b1b">无 master 端口</text>')
a(f'  <text x="{cc(ERR_K)}" y="{MUX_Y+33}" text-anchor="middle" font-size="9" fill="#b91c1c">事务在此终结，</text>')
a(f'  <text x="{cc(ERR_K)}" y="{MUX_Y+46}" text-anchor="middle" font-size="9" fill="#b91c1c">B/R 沿本行返回</text>')

# ---------------- 图例 ----------------
a(f'  <line x1="24" y1="{LY}" x2="80" y2="{LY}" stroke="#2563eb" stroke-width="2.2" marker-end="url(#arrowBlue)"/>')
a(f'  <text x="94" y="{LY+4}" font-size="11.5" fill="#334155">'
  f'请求（AW/W/AR）：Sx → addr_decode → axi_demux 选中 {NM+1} 路之一 → 格 [i][j] → 列汇入 axi_mux j → Mj</text>')
a(f'  <line x1="24" y1="{LY+24}" x2="80" y2="{LY+24}" stroke="#c2410c" stroke-width="2.2" stroke-dasharray="6,4" marker-end="url(#arrowOrange)"/>')
a(f'  <text x="94" y="{LY+28}" font-size="11.5" fill="#334155">'
  f'响应（B/R）：沿同一条路径反向返回；axi_mux 凭 ID 高位里前缀的来源端口号 i 分流回本行，不重新查地址表</text>')
a(f'  <rect x="24" y="{LY+41}" width="56" height="13" rx="3" fill="#ecfdf5" stroke="#10b981" stroke-width="1.1"/>')
a(f'  <text x="94" y="{LY+52}" font-size="11.5" fill="#334155">'
  f'<tspan font-weight="700">绿格 = axi_multicut</tspan>：连通格的流水线切割（NoCuts = Cfg.PipelineStages），只加延迟不改数据</text>')
a(f'  <rect x="24" y="{LY+65}" width="56" height="13" rx="3" fill="#fef2f2" stroke="#b91c1c" stroke-width="1.1"/>')
a(f'  <text x="94" y="{LY+76}" font-size="11.5" fill="#334155">'
  f'<tspan font-weight="700">红列 = axi_err_slv</tspan>：每个 slave 端口专属的 decode error 从机（地址不匹配任何 rule，'
  f'且该端口未使能 default master port 时走这里）</text>')
a(f'  <text x="94" y="{LY+100}" font-size="11.5" fill="#334155">'
  f'<tspan font-weight="700">格内标号 [i][j]</tspan> = 该格在 axi_xbar_unmuxed 里的信号索引 slv_reqs[i][j] / slv_resps[i][j]；'
  f'j = {NM} 即 demux 多出的那一路（decode error）</text>')

# ---------------- 右下角：Connectivity=0 的格子长什么样 ----------------
IW, IH = 196, 78
IX, IY = W - IW - 16, LY - 14
a(f'  <rect x="{IX}" y="{IY}" width="{IW}" height="{IH}" rx="8" fill="#ffffff" stroke="#6d28d9" stroke-width="1.2" stroke-dasharray="5,3"/>')
a(f'  <text x="{IX+IW//2}" y="{IY+18}" text-anchor="middle" font-size="9.5" font-weight="700" fill="#4338ca">若 Connectivity[i][j] = 0，该格改为：</text>')
a(f'  <rect x="{IX+(IW-COL_W)//2}" y="{IY+26}" width="{COL_W}" height="30" rx="6" fill="#fef2f2" stroke="#b91c1c" stroke-width="1.1"/>')
a(f'  <text x="{IX+IW//2}" y="{IY+39}" text-anchor="middle" font-size="9.5" font-weight="700" fill="#991b1b">axi_err_slv</text>')
a(f'  <text x="{IX+IW//2}" y="{IY+51}" text-anchor="middle" font-size="8.5" fill="#b91c1c">[i][j]</text>')
a(f'  <text x="{IX+IW//2}" y="{IY+70}" text-anchor="middle" font-size="9" fill="#6366f1">且 mst_ports_req_o[j][i] 恒为 \'0</text>')

a('</svg>')

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "axi_xbar_dataflow.svg")
with open(out, "w", encoding="utf-8") as f:
    f.write("\n".join(o) + "\n")
print(f"wrote {out}  ({W}x{H})")
