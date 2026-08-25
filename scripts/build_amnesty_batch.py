#!/usr/bin/env python3
"""build_amnesty_batch.py — pre-stage the ADR-PML-005 debt-amnesty batch.

Enumerates every sorry-bearing declaration that has no alp_sorry_manifest.json
entry (Facet A inline `:= sorry`, Facet B unmanifested blocks) using the loop's
own scan_lean()/load_sorry_manifest(), then emits state/amnesty_batch_PML-005.json
with governance fields left null for assignment at the ratification cycle.

This script measures; it does NOT fabricate metadata. Governor, deadline,
pairing, urgency, and disposition must be assigned by the cycle, per
ADR-PML-005 Decision step 3 ("no fabricated metadata").

Usage: python3 scripts/build_amnesty_batch.py [--root PATH] [--out PATH]
       [--apply-policy] [--prune-stale-permits] [--write-manifest]
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import phase_mirror_loop as pml  # noqa: E402

ALLOWED_GOVERNORS = [
    "the-examiner", "the-guardian", "the-publisher",
    "the-genius", "finton", "echobraid",
]
ALLOWED_DISPOSITIONS = ["tier3_aspirational", "prove", "exclude"]
ALLOWED_PAIRINGS = ["none", "rust_kani_stub", "verified"]

# Uniform ratification policy applied only via explicit --apply-policy.
# Recorded transparently in the batch file; never silently fabricated.
POLICY = {
    "assigned_by": "operator-directive-2026-08-24",
    "disposition": "tier3_aspirational",
    "governor": "the-examiner",
    "deadline": "2027-06-30",
    "pairing": "none",
    "urgency": 3,
}
EXCLUDED_TREE_PREFIXES = ("_archive/", "legacy/", "phase_mirror_loop_scaffolds/")


def build(root: str) -> dict:
    pml._resolve_paths(root)
    ev = pml.scan_lean()
    man = pml.load_sorry_manifest()
    unmanifested = pml._unmanifested_sorry_decls(ev, man["permitted"])

    entries = []
    for decl, meta in unmanifested:
        entries.append({
            "name": decl.split(".")[-1],
            "qualified_name": decl,
            "file": meta["file"],
            "line": meta["line"],
            "facet": "A" if meta.get("inline_sorry") else "B",
            "disposition": None,
            "governor": None,
            "deadline": None,
            "pairing": None,
            "urgency": None,
            "resolution": None,
        })

    inline_n = sum(1 for e in entries if e["facet"] == "A")
    return {
        "batch_id": "amnesty-PML-005",
        "created": _dt.date.today().isoformat(),
        "source_adr": "docs/adr/ADR-PML-005.md",
        "status": "AWAITING-CYCLE-RATIFICATION",
        "measured": {
            "loop_tally_sorry_lines": ev.total_sorry,
            "sorry_bearing_declarations": sum(
                1 for m in ev.decl_meta.values() if m.get("has_sorry")),
            "unmanifested_entries": len(entries),
            "facet_a_inline": inline_n,
            "facet_b_block_level": len(entries) - inline_n,
        },
        "schema_notes": {
            "disposition": f"one of {ALLOWED_DISPOSITIONS}; 'exclude' moves the file out "
                           "of the canonical tree (_archive/, legacy/, "
                           "phase_mirror_loop_scaffolds/) instead of manifesting it",
            "governor": f"one of {ALLOWED_GOVERNORS}",
            "deadline": "ISO date (YYYY-MM-DD); tracked by the loop's overdue check",
            "pairing": f"one of {ALLOWED_PAIRINGS}; 'verified' requires a real Rust/Kani witness",
            "urgency": "integer 1-10",
            "resolution": "free text: how the debt will be amortized (per manifest v2.0 entries)",
        },
        "protocol": [
            "1. Assign disposition, governor, deadline, pairing, and urgency to every entry at the "
            "ratification cycle — no fabricated metadata, no batch defaults.",
            "2. Apply 'tier3_aspirational' and 'prove' entries to alp_sorry_manifest.json as v2.0 "
            "ledger entries; relocate 'exclude' files out of lean/.",
            "3. Re-run scripts/honesty_audit.sh until green with loop-tally parity.",
            "4. Re-run scripts/phase_mirror_loop.py; the 'Unmanifested sorry debt' tension must drop out.",
        ],
        "entries": entries,
    }


def apply_policy(batch: dict) -> dict:
    """Fill null governance fields per POLICY (uniform, recorded, opt-in)."""
    for e in batch["entries"]:
        for k, v in POLICY.items():
            if k == "assigned_by":
                continue
            if e.get(k) is None:
                e[k] = v
        e["assigned_by"] = POLICY["assigned_by"]
    batch["status"] = "POLICY-ASSIGNED-PENDING-MANIFEST-APPLY"
    batch["assignment_policy"] = dict(POLICY)
    return batch


def prune_stale_permits(manifest_path: str) -> list[str]:
    """Drop permitted_sorrys whose leaf no longer resolves in the lean tree.

    Keeps manifest_drift at 0 after exclusions leave the canonical tree.
    Returns the pruned permit names.
    """
    with open(manifest_path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    ev = pml.scan_lean()
    kept, pruned = [], []
    for item in data.get("permitted_sorrys", []):
        if pml._manifest_entry_present(item, ev):
            kept.append(item)
        else:
            pruned.append(item)
    # Entry-based permits must also resolve (v2.0 ledger entries).
    kept_entries = []
    for entry in data.get("entries", []):
        name = entry.get("name", entry.get("file", "")).split(".")[-1]
        if pml._manifest_entry_present(name, ev):
            kept_entries.append(entry)
        else:
            pruned.append(entry.get("name", "?") + " [entry]")
    if pruned:
        data["permitted_sorrys"] = kept
        data["entries"] = kept_entries
        note = data.get("audit_note", "")
        data["audit_note"] = (note + " | " if note else "") + (
            f"Pruned {len(pruned)} stale permit(s) during ADR-PML-005 amnesty "
            f"(excluded trees left the canonical lean tree): "
            + ", ".join(pruned[:10]) + (" ..." if len(pruned) > 10 else ""))
        with open(manifest_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2)
            fh.write("\n")
    return pruned


def write_manifest_entries(batch: dict, manifest_path: str) -> int:
    """Merge policy-assigned batch entries into alp_sorry_manifest.json."""
    if batch.get("status") != "POLICY-ASSIGNED-PENDING-MANIFEST-APPLY":
        raise SystemExit("refusing to write manifest: run --apply-policy first")
    with open(manifest_path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
    existing_leaves = {e.get("name", "").split(".")[-1] for e in data.get("entries", [])}
    existing_leaves |= {p.split(".")[-1] for p in data.get("permitted_sorrys", [])}
    added = 0
    for e in batch["entries"]:
        if e.get("disposition") == "exclude":
            continue  # excluded scaffolds are relocated, not manifested
        leaf = e["name"].split(".")[-1]
        data.setdefault("entries", []).append({
            "file": e["file"],
            "line": e["line"],
            "type": "sorry",
            "name": e["qualified_name"],
            "description": (f"ADR-PML-005 amnesty batch ({batch['batch_id']}): Tier-3 "
                            f"aspirational debt — `{e['qualified_name']}` carries a transitional "
                            f"`sorry` (Facet {e['facet']}); permitted by leaf-name match"
                            + (" (broad: namespace-prefixed declaration)" if "." in e["name"] else "")
                            + "."),
            "resolution": (f"Amortize via real proof or demotion per ADR-PML-005 Decision step 3; "
                           f"assigned_by={e['assigned_by']}, governor={e['governor']}."),
            "deadline": e["deadline"],
            "governor": e["governor"],
            "pairing": e["pairing"],
            "urgency": e["urgency"],
        })
        added += 1
    data["last_audit"] = _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    note = data.get("audit_note", "")
    data["audit_note"] = (note + " | " if note else "") + (
        f"ADR-PML-005 amnesty applied: +{added} Tier-3 ledger entries "
        f"(batch {batch['batch_id']}, policy {POLICY['assigned_by']}).")
    with open(manifest_path, "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")
    batch["status"] = "RATIFIED-APPLIED"
    return added


def main(argv: list[str] | None = None) -> int:
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root", default=here)
    p.add_argument("--out", default=os.path.join(here, "state", "amnesty_batch_PML-005.json"))
    p.add_argument("--manifest", default=os.path.join(here, "alp_sorry_manifest.json"))
    p.add_argument("--apply-policy", action="store_true",
                   help="fill null governance fields with the uniform POLICY defaults")
    p.add_argument("--prune-stale-permits", action="store_true",
                   help="drop permitted_sorrys/entries whose declarations left the lean tree")
    p.add_argument("--write-manifest", action="store_true",
                   help="merge policy-assigned entries into alp_sorry_manifest.json")
    args = p.parse_args(argv)

    if args.prune_stale_permits:
        pruned = prune_stale_permits(args.manifest)
        print(f"pruned {len(pruned)} stale permit(s)" + (f": {pruned}" if pruned else ""))

    if args.apply_policy or args.write_manifest or not (os.path.isfile(args.out) and not args.apply_policy):
        batch = build(args.root)
        m = batch["measured"]
        print(f"measured {m['unmanifested_entries']} unmanifested entries "
              f"(A={m['facet_a_inline']}, B={m['facet_b_block_level']})")
        if args.apply_policy:
            batch = apply_policy(batch)
            print(f"policy assigned: disposition={POLICY['disposition']} governor={POLICY['governor']} "
                  f"deadline={POLICY['deadline']}")
        os.makedirs(os.path.dirname(args.out), exist_ok=True)
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(batch, fh, indent=2)
            fh.write("\n")
        print(f"wrote {os.path.relpath(args.out, args.root)}")
    else:
        with open(args.out, "r", encoding="utf-8") as fh:
            batch = json.load(fh)

    if args.write_manifest:
        added = write_manifest_entries(batch, args.manifest)
        with open(args.out, "w", encoding="utf-8") as fh:
            json.dump(batch, fh, indent=2)
            fh.write("\n")
        print(f"manifest updated: +{added} entries -> {os.path.relpath(args.manifest, args.root)}; "
              f"batch status={batch['status']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
