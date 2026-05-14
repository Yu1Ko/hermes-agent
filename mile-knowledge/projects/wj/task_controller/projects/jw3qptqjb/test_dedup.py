#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HotPointMap 分支1去重验证脚本
用法：python3 test_dedup.py Data.json

把去重前后的每个格子的条目数列出来，一眼看出效果。
"""
import json
import sys

def dedup_branch1(data: dict) -> dict:
    """分支1：每个格子只保留Ms最大（性能最差）的一条"""
    perf = data.get("performanceData", {})
    for key, entries in list(perf.items()):
        # testGM 占位数据不动
        has_testgm = any("testGM" in str(e) for e in entries)
        if has_testgm or len(entries) <= 1:
            continue
        best_idx = 0
        best_ms = 0.0
        for i, entry in enumerate(entries):
            parts = str(entry).split(",")
            try:
                ms = float(parts[8])
            except (IndexError, ValueError):
                continue
            if ms > best_ms:
                best_ms = ms
                best_idx = i
        perf[key] = [entries[best_idx]]
    return data

def main():
    if len(sys.argv) < 2:
        print("用法: python3 test_dedup.py Data.json")
        return

    with open(sys.argv[1], "r", encoding="utf-8") as f:
        original = json.load(f)

    deduped = dedup_branch1(json.loads(json.dumps(original)))

    perf_orig = original.get("performanceData", {})
    perf_dedup = deduped.get("performanceData", {})

    print(f"总格子数: {len(perf_orig)}")
    print()

    total_orig = 0
    total_dedup = 0
    for key in sorted(perf_orig.keys()):
        n_orig = len(perf_orig[key])
        n_dedup = len(perf_dedup.get(key, []))
        total_orig += n_orig
        total_dedup += n_dedup
        if n_orig != n_dedup:
            tag = " ← 已去重" if n_dedup == 1 else ""
            print(f"  {key}: {n_orig}条 → {n_dedup}条{tag}")

    print(f"\n去重前总条目: {total_orig}")
    print(f"去重后总条目: {total_dedup}")
    print(f"删除了 {total_orig - total_dedup} 条")

    out_path = sys.argv[1].replace(".json", "_dedup.json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(deduped, f, ensure_ascii=False, indent=2)
    print(f"\n去重后文件: {out_path}")


if __name__ == "__main__":
    main()
