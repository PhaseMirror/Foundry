#!/usr/bin/env python3
import json
import os

REGISTRY_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "docs", "adr", "registry.json")

# ADRs that have Lean formal representation (def records in ADR/Examples.lean or ADR/Migrated.lean)
FORMALIZED_ADRS = {
    "ADR-001", "ADR-002", "ADR-003", "ADR-004", "ADR-005",
    "ADR-006", "ADR-007", "ADR-008", "ADR-009", "ADR-010",
    "ADR-0013", "ADR-0014", "ADR-0015", "ADR-0016", "ADR-0017",
    "ADR-0018", "ADR-0019", "ADR-0020", "ADR-0021", "ADR-0022",
    "ADR-0023", "ADR-0024", "ADR-0025", "ADR-0026", "ADR-0027",
    "ADR-0028",
    "ADR-0040", "ADR-0041", "ADR-0043",
    "ADR-0057", "ADR-0058", "ADR-0059", "ADR-0060", "ADR-0061",
    "ADR-0064",
}

def main():
    with open(REGISTRY_PATH, "r") as f:
        registry = json.load(f)

    for adr in registry.get("adrs", []):
        adr_id = adr["id"]
        if adr_id in FORMALIZED_ADRS:
            adr["formalizationWaiver"] = False
        else:
            adr["formalizationWaiver"] = True

    with open(REGISTRY_PATH, "w") as f:
        json.dump(registry, f, indent=2)
        f.write("\n")

    print(f"[registry.json] Added formalizationWaiver to {len(registry.get('adrs', []))} ADRs")
    waived = [a["id"] for a in registry.get("adrs", []) if a.get("formalizationWaiver")]
    if waived:
        print(f"  Waived: {waived}")

if __name__ == "__main__":
    main()
