#!/usr/bin/env bash
set -euo pipefail

# honesty_audit.sh: Verifies the UAC-ALP boundary by ensuring 'sorry' blocks
# only exist for explicitly manifested declarations.
#
# 2026-08-25 (ADR-PML-001 cycle): repaired for the current repository layout
# (manifest + lean/ at repo root; legacy Prime/ layout still honored via
# fallback). Declaration extraction now reuses scripts/phase_mirror_loop.py's
# scan_lean()/load_sorry_manifest() so this audit can never disagree with the
# operational loop about what is counted and what is permitted.
#
# 2026-08-24 (ADR-PML-005 Decision steps 1-2): scan_lean now attributes inline
# `:= sorry` declaration lines, so the tally covers Facet A + Facet B; the
# former open-lever advisory is replaced by an independent parity cross-check.
#
# 2026-08-25 (ADR-PML-007): axiom-boundary parity lines added. The axiom
# boundary is enforced by the operational loop's "Unledgered axioms" tension;
# here it is reported informationally (non-gating) so drift is visible on
# every CI run without widening this script's sorry-boundary contract.

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "=== Honesty Audit: UAC-ALP Boundary ==="

if [[ -f "${ROOT_DIR}/alp_sorry_manifest.json" ]]; then
  MANIFEST="${ROOT_DIR}/alp_sorry_manifest.json"
elif [[ -f "${ROOT_DIR}/Prime/alp_sorry_manifest.json" ]]; then
  MANIFEST="${ROOT_DIR}/Prime/alp_sorry_manifest.json"   # legacy layout
else
  echo "❌ Error: alp_sorry_manifest.json not found!"
  exit 1
fi

if [[ -d "${ROOT_DIR}/lean" ]]; then
  LEAN_ROOT="${ROOT_DIR}/lean"
else
  LEAN_ROOT="${ROOT_DIR}/Prime"                           # legacy layout
fi

LEAN_ROOT="$LEAN_ROOT" python3 - <<'EOF'
import os, sys, re

root = os.environ["LEAN_ROOT"]
sys.path.insert(0, os.path.join(os.path.dirname(root), "scripts"))

# Reuse the operational loop's own evidence gathering for exact parity.
from phase_mirror_loop import scan_lean, load_sorry_manifest

ev = scan_lean()
man = load_sorry_manifest()
permitted = man["permitted"]

unauthorized = []
for decl, meta in ev.decl_meta.items():
    if not meta.get("has_sorry"):
        continue
    leaf = decl.split(".")[-1]
    if not any(leaf == p.split(".")[-1] for p in permitted):
        unauthorized.append(f"{meta['file']}:{meta['line']}  {decl}")

print(f"Scanned {len(ev.decl_meta)} declarations under {root}")
print(f"Manifest permits in force: {len(permitted)}")
_decl_blocks = [m for m in ev.decl_meta.values() if m.get("has_sorry")]
_inline_n = sum(1 for m in _decl_blocks if m.get("inline_sorry"))
print(f"sorry-bearing declaration blocks: {len(_decl_blocks)} "
      f"(Facet A inline `:= sorry`: {_inline_n}; Facet B block-level: {len(_decl_blocks) - _inline_n})")

# Independent parity cross-check (ADR-PML-005 Metrics #1): the shared tally
# must agree with a naive strip-comments-and-count pass over lean/. Counted
# line-wise to match scan_lean semantics (one hit per line, not per occurrence).
independent = 0
for dirpath, _dirs, files in os.walk(root):
    if "/.lake/" in dirpath or "/build/" in dirpath:
        continue
    for fn in files:
        if not fn.endswith(".lean"):
            continue
        full = os.path.join(dirpath, fn)
        try:
            text = open(full, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        text = re.sub(r'"[^"\n]*"', " ", text)
        text = re.sub(r"/-.*?-/", " ", text, flags=re.S)
        text = re.sub(r"--[^\n]*", " ", text)
        independent += sum(1 for ln in text.splitlines() if re.search(r"\bsorry\b", ln))
if independent != ev.total_sorry:
    print(f"❌ Parity drift (ADR-PML-005): independent strip-and-count {independent} "
          f"vs loop tally {ev.total_sorry}")
else:
    print(f"Parity: loop tally {ev.total_sorry} == independent strip-and-count {independent}")

# Axiom boundary (ADR-PML-007) — informational parity, non-gating.
manifested_leaves = {e.get("name", "").split(".")[-1] for e in man.get("entries", [])}
unledgered = [n for n in ev.axioms if n.split(".")[-1] not in manifested_leaves]
posts = sum(1 for n in unledgered if ev.axioms[n]["postulate"])
ax_rx = re.compile(r"^\s*(?:@\[[^\]]*\]\s*)*"
                   r"(?:private\s+|protected\s+|noncomputable\s+|partial\s+)*"
                   r"axiom\s+([A-Za-z_][\w.']*)")
indep_names = set()
for dirpath, _dirs, files in os.walk(root):
    if "/.lake/" in dirpath or "/build/" in dirpath:
        continue
    for fn in files:
        if fn.endswith(".lean"):
            try:
                for ln in open(os.path.join(dirpath, fn), encoding="utf-8", errors="replace"):
                    m = ax_rx.match(ln)
                    if m:
                        indep_names.add(m.group(1))
            except OSError:
                pass
n_math = sum(1 for v in ev.axioms.values() if v["postulate"])
print(f"Axiom boundary: {len(ev.axioms)} distinct postulates "
      f"({n_math} mathematical / {len(ev.axioms) - n_math} infrastructure); "
      f"unledgered: {len(unledgered)} ({posts} mathematical)")
if indep_names != set(ev.axioms):
    only_indep = sorted(indep_names - set(ev.axioms))[:5]
    only_loop = sorted(set(ev.axioms) - indep_names)[:5]
    print(f"❌ Axiom parity drift (ADR-PML-007): independent distinct-axiom set "
          f"{len(indep_names)} vs loop tally {len(ev.axioms)}; "
          f"only-independent: {only_indep}; only-loop: {only_loop}")
    sys.exit(1)
elif unledgered:
    print(f"⚠️  {len(unledgered)} axiom(s) not yet manifested — ratify the ADR-PML-007 "
          f"amnesty batch (state/amnesty_batch_PML-007.json).")
else:
    print("Axiom parity OK: every axiom under lean/ is ledgered (ADR-PML-007).")

if unauthorized:
    print(f"❌ Audit Failed: {len(unauthorized)} unmanifested sorry block(s) crossing the boundary:")
    for u in sorted(unauthorized):
        print("   ", u)
    print("   Resolution path: ratify the ADR-PML-005 debt-amnesty batch "
          "(state/amnesty_batch_PML-005.json) at the next governance cycle.")
    sys.exit(1)

print("✅ Audit Passed: every counted sorry block is bounded within the manifest.")
EOF
