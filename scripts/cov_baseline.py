#!/usr/bin/env python3
"""Parse urg text modlist.txt → (module, type) grid for DUT closure modules.

Usage: python3 scripts/cov_baseline.py sim/out/urgText6/modlist.txt
"""
import re
import sys

DUT_CLOSURE = {
    "axi_xbar", "axi_xbar_unmuxed",
    "addr_decode", "addr_decode_dync",
    "axi_demux", "axi_demux_simple", "axi_demux_id_counters",
    "counter", "delta_counter",
    "axi_err_slv", "axi_atop_filter", "stream_register",
    "axi_mux", "axi_id_prepend",
    "rr_arb_tree", "lzc", "fifo_v3",
    "axi_multicut", "axi_cut",
    "spill_register", "spill_register_flushable",
    "axi_pkg",
}

TYPES = ["Line", "Cond", "Toggle", "FSM", "Branch", "Assert"]

M4_UNOWNED = {
    ("axi_demux_id_counters", "Line"), ("axi_demux_id_counters", "Toggle"),
    ("axi_demux_id_counters", "Branch"),
    ("axi_id_prepend", "Toggle"),
    ("rr_arb_tree", "Line"), ("rr_arb_tree", "Toggle"),
    ("lzc", "Toggle"),
    ("fifo_v3", "Cond"), ("fifo_v3", "Toggle"), ("fifo_v3", "Branch"),
    ("counter", "Toggle"), ("delta_counter", "Toggle"),
    ("axi_multicut", "Toggle"), ("axi_cut", "Toggle"),
    ("spill_register", "Toggle"),
    ("spill_register_flushable", "Cond"), ("spill_register_flushable", "Toggle"),
    ("spill_register_flushable", "Assert"),
}

M4_WAIVERED = {
    ("addr_decode_dync", "Branch"): "CW-008",
    ("axi_demux_simple", "Cond"): "CW-009+DV-E",
    ("axi_err_slv", "Toggle"): "CW-003/004/005/006/002/007+DV",
    ("axi_atop_filter", "Line"): "CW-001",
    ("axi_atop_filter", "Cond"): "CW-001",
    ("axi_atop_filter", "Toggle"): "CW-001",
    ("axi_atop_filter", "FSM"): "CW-001",
    ("axi_atop_filter", "Branch"): "CW-001",
    ("axi_mux", "Toggle"): "CW-002/006/007+DV",
    ("stream_register", "Line"): "CW-014",
    ("stream_register", "Toggle"): "CW-014(partial)",
    ("stream_register", "Branch"): "CW-014",
}


def parse_modlist(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        lines = f.readlines()
    header_re = re.compile(
        r"^\s*SCORE\s+LINE\s+COND\s+TOGGLE\s+FSM\s+BRANCH\s+ASSERT\s+NAME")
    data_re = re.compile(
        r"^\s*([\d.]+|--)\s+([\d.]+|--)\s+([\d.]+|--)\s+([\d.]+|--)\s+"
        r"([\d.]+|--)\s+([\d.]+|--)\s+([\d.]+|--)\s+(\S+)")
    results = {}
    for line in lines:
        m = data_re.match(line)
        if not m:
            continue
        name = m.group(8).strip()
        if "(" in line or name not in DUT_CLOSURE or name in results:
            continue
        vals = {}
        for i, t in enumerate(TYPES):
            raw = m.group(i + 2)
            vals[t] = float(raw) if raw != "--" else None
        results[name] = vals
    return results


def classify(mod, typ, val, m4_val):
    key = (mod, typ)
    if val is None:
        return "N/A"
    if val >= 90.0:
        return ">=90 PASS"
    if key in M4_WAIVERED:
        return "waiver %s" % M4_WAIVERED[key]
    if key in M4_UNOWNED:
        delta = ""
        if m4_val is not None and m4_val != val:
            delta = " (M4: %.2f→%.2f)" % (m4_val, val)
        return "UNOWNED%s" % delta
    return "<90 TODO"


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: %s modlist.txt [m4_modlist.txt]" % sys.argv[0])
    data = parse_modlist(sys.argv[1])
    m4_data = parse_modlist(sys.argv[2]) if len(sys.argv) > 2 else {}

    header = "| module | Line | Cond | Toggle | FSM | Branch | Assert |"
    sep = "| --- | --- | --- | --- | --- | --- | --- |"
    print(header)
    print(sep)
    order = [m for m in [
        "axi_xbar", "axi_xbar_unmuxed", "addr_decode", "addr_decode_dync",
        "axi_demux", "axi_demux_simple", "axi_demux_id_counters",
        "counter", "delta_counter", "axi_err_slv", "axi_atop_filter",
        "stream_register", "axi_mux", "axi_id_prepend", "rr_arb_tree", "lzc",
        "fifo_v3", "axi_multicut", "axi_cut", "spill_register",
        "spill_register_flushable", "axi_pkg",
    ] if m in data]

    below90 = 0
    for mod in order:
        vals = data[mod]
        m4_vals = m4_data.get(mod, {})
        cells = []
        for t in TYPES:
            v = vals.get(t)
            m4_v = m4_vals.get(t)
            if v is None:
                cells.append("N/A")
            else:
                tag = classify(mod, t, v, m4_v)
                if v >= 90:
                    cells.append("**%.2f**" % v)
                else:
                    cells.append("%.2f [%s]" % (v, tag))
                    below90 += 1
        print("| `%s` | %s |" % (mod, " | ".join(cells)))

    print()
    print("Below 90%%: %d cells" % below90)


if __name__ == "__main__":
    main()
