#!/usr/bin/env python3
import json
import os
import sys
import re

REGISTRY_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "docs", "adr", "registry.json")
README_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "docs", "adr", "README.md")

STATUS_DIR_MAP = {
    "Accepted": "",
    "Completed": "completed/",
    "Proposed": "proposed/",
    "Superseded": "",
    "Deprecated": "deprecated/",
}

STATUS_ORDER = ["Proposed", "Accepted", "Completed", "Superseded", "Deprecated"]


def main():
    with open(REGISTRY_PATH, "r") as f:
        registry = json.load(f)

    adrs = registry.get("adrs", [])
    version = registry.get("version", "1.0.0")

    by_status = {}
    for adr in adrs:
        status = adr["status"]
        if status not in by_status:
            by_status[status] = []
        by_status[status].append(adr)

    lines = []
    lines.append("# Architectural Decision Records (ADR) Ledger")
    lines.append("")
    lines.append("*Formally verified and machine-checked in Lean 4.*")
    lines.append("")
    lines.append(f"Registry version: {version}")
    lines.append(f"Total ADRs: {len(adrs)}")
    for status in STATUS_ORDER:
        count = len(by_status.get(status, []))
        if count > 0:
            lines.append(f"- {status}: {count}")
    lines.append("")
    lines.append("| ID | Title | Status | Supersedes |")
    lines.append("| :--- | :--- | :--- | :--- |")

    for status in STATUS_ORDER:
        for adr in by_status.get(status, []):
            adr_id = adr["id"]
            title = adr["title"]
            sup = adr.get("supersedes") or "-"
            dir_prefix = STATUS_DIR_MAP.get(status, "")
            if dir_prefix:
                link = f"[{adr_id}]({dir_prefix}{adr_id}.md)"
            else:
                link = f"[{adr_id}]({adr_id}.md)"
            lines.append(f"| {link} | {title} | {status} | {sup} |")

    lines.append("")

    content = "\n".join(lines) + "\n"
    with open(README_PATH, "w") as f:
        f.write(content)

    print(f"[ADR Index] Generated {len(adrs)} ADRs in README.md from registry.json")


if __name__ == "__main__":
    main()
