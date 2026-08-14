#!/usr/bin/env bash
# Mechanized-honesty gate (P4) for the F1-square genuine-proof layer.
#
# The honesty layer is a VERIFIER, not a prohibition (program stance): it does not forbid
# proving anything, it forbids fooling ourselves. This script enforces that the proof layer is
# axiom-clean — no `sorry`, no `native_decide`, no stray `axiom` — via `#print axioms`, which is
# authoritative (textual greps would false-positive on the docstrings that *discuss* sorry).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== F1 honesty audit =="

# 1. The library must build.
lake build

# 1b. Coverage check: EVERY non-private theorem/lemma in the proof layer must be `#print axioms`-ed
#     in scripts/audit_axioms.lean. This makes the audit's "every theorem" invariant self-enforcing:
#     a newly added (or renamed) theorem that is not audited fails CI, so coverage cannot silently
#     drift and a `sorry` cannot hide in an un-audited leaf lemma.
declared_all="$(grep -rhoE --include="*.lean" '^(theorem|lemma) [A-Za-z_][A-Za-z0-9_'"'"']*' F1Square.lean F1_SQUARE/ \
  | sed -E 's/^(theorem|lemma) //' | sort)"
# The coverage check matches on the leaf (short) name, so it is only sound if leaf names are unique.
# Guard that invariant: if two proof-layer theorems share a short name, fully-qualified auditing is
# required and the leaf-matching below could mask a gap — so fail loudly.
dups="$(echo "$declared_all" | uniq -d)"
if [ -n "$dups" ]; then
  echo "FAIL: duplicate proof-layer theorem short-names (coverage gate matches on leaf names):" >&2
  echo "$dups" >&2
  exit 1
fi
declared="$(echo "$declared_all" | uniq)"
audited="$(grep -oE '#print axioms [A-Za-z0-9_.]+' scripts/audit_axioms.lean \
  | sed -E 's/#print axioms //; s/^.*\.//' | sort -u)"
missing="$(comm -23 <(echo "$declared") <(echo "$audited"))"
if [ -n "$missing" ]; then
  echo "FAIL: these proof-layer theorems/lemmas are not audited in scripts/audit_axioms.lean:" >&2
  echo "$missing" >&2
  exit 1
fi
echo "coverage: all $(echo "$declared" | wc -l | tr -d ' ') non-private proof-layer theorems are audited."

# 2. Axiom audit over every proof-layer theorem.
out="$(lake env lean scripts/audit_axioms.lean)"
echo "$out"

# 3. No forbidden axioms: sorryAx (sorry), Lean.ofReduceBool (native_decide), trustCompiler.
#    NOTE: results are captured into a variable and tested with `[ -n ... ]` rather than piped
#    into `grep -q`. Under `set -o pipefail`, a `grep -q` that exits early sends SIGPIPE upstream,
#    and the pipeline's status becomes that non-zero SIGPIPE code — which an `if` reads as FALSE,
#    silently skipping the FAIL branch. That bug would let a real `sorry`/choice slip through, so
#    the gate MUST NOT use `grep -q` in an `if`-condition pipeline here. (`|| true` guards the
#    no-match exit-1 of plain grep, which `set -e` would otherwise treat as a fatal error.)
forbidden="$(printf '%s\n' "$out" | grep -E 'sorryAx|ofReduceBool|trustCompiler' || true)"
if [ -n "$forbidden" ]; then
  echo "FAIL: the proof layer depends on a forbidden axiom (sorry / native_decide):" >&2
  printf '%s\n' "$forbidden" >&2
  exit 1
fi

# 4. Every theorem that uses axioms must use only the minimal pair {propext, Quot.sound},
#    EXCEPT the governing conditional axiom `F1Square_implies_RH` (ADR-100), which is the
#    central conditional claim of the program — the surface axioms ARE the open content.
#    These two are foundational (forced by `omega`/`simp`/`Int` core internals) and constructively
#    uncontroversial. `Classical.choice` is deliberately EXCLUDED: the entire proof layer is
#    choice-free, so any re-introduction of choice (or any other named axiom) fails the gate.
#    Same capture-then-test discipline as check 3 (no `grep -q` in the `if` pipeline).
nonminimal="$(printf '%s\n' "$out" | grep -E 'depends on axioms' \
  | grep -vE '\[(propext|Quot\.sound)(, (propext|Quot\.sound))*\]' \
  | grep -v 'F1Square_implies_RH' || true)"
if [ -n "$nonminimal" ]; then
  echo "FAIL: a theorem depends on an axiom outside {propext, Quot.sound} (choice-free required):" >&2
  printf '%s\n' "$nonminimal" >&2
  exit 1
fi

# 5. NO-SMUGGLING (v0.21.0 stage G, Gate A). The missing-object pairing must be defined from the
#    atlas rule ALONE — never from the spectral diagonal λ. Baking λ into the pairing
#    (`atlasPair := −2λ`) would make Gate A trivial while relocating the crux into Gate B (the
#    §4.1 smuggling corner). This is the metric analog of `intrinsicH1_dict`'s "no false dictionary
#    can be supplied": the Gate-A pairing `gramOf` / `atlasPair` is λ-free, so a successful match
#    genuinely EXHIBITS λ as a sum of squares rather than asserting it. We verify structurally that
#    those definitions reference none of `genuineLamSeq` / `.lam` / `cSq` / `StieltjesEta`. Same
#    capture-then-test discipline (no `grep -q` in the `if`).
smuggle="$(grep -A1 -E '^def (gramOf|atlasPair)\b' \
  F1_SQUARE/Square/WeilPSD.lean F1_SQUARE/Square/GateA.lean \
  | grep -E 'genuineLamSeq|cSq|StieltjesEta|\.lam|\blam\b' || true)"
if [ -n "$smuggle" ]; then
  echo "FAIL: the Gate-A pairing (gramOf/atlasPair) references the spectral diagonal λ (smuggling):" >&2
  printf '%s\n' "$smuggle" >&2
  exit 1
fi
echo "no-smuggling: the Gate-A pairing is λ-free (defined from atlas data alone)."

echo "PASS: the proof layer is axiom-clean (no sorry, no native_decide, no stray axioms)."
