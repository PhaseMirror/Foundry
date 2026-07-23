#!/usr/bin/env python3
"""
phase_mirror_loop.py — Phase Mirror Operational Loop

Operational loop that weighs the dissonance between stated intent (documents:
whitepapers, ADRs, specs, MOC theory) and the reality of the mathematical
Lean 4 proof implementations, then emits Architecture Decision Record (ADR)
plans into docs/adr/ as actionable levers to resolve the dissonance and fill
the gaps between stated intent and implementation.

Loop phases (per Phase_Mirror_Loop_Goal.md):
  1. ANALYZE    — harvest documents and the Lean 4 corpus; extract claims
                  (purity guarantees, named theorem proofs, numeric invariants)
                  and the implementation evidence that should back them.
  2. DETECT     — compare stated intent vs implementation reality and classify
                  each gap into one of the four tension axes:
                    - intent vs operating incentives
                    - urgency vs capacity
                    - risk claimed vs risk owned
                    - control desired vs available
  3. RANK       — score every tension by impact x tractability.
  4. PLAN       — emit per-tension ADR plan files (actionable levers) plus a
                  master index into docs/adr/.
  5. RESOLVE    — record open levers and (with --scaffold-proofs) emit Lean
                  theorem stubs + a suggested alp_sorry_manifest patch so the
                  gap is manifested rather than silently leaked.

The loop is idempotent and stateful: re-runs read state/phase_mirror_loop.json
to show dissonance drift (delta vs previous run) without re-emitting unchanged
ADRs unless --refresh is passed.

This script performs read-only analysis by default. It never edits core Lean
proofs or the sorry manifest unless an explicit opt-in flag is given.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field, asdict
from typing import Optional

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

PRIME_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Default root; actual paths are derived per-run from args.root.
# "Stated intent" documents live in docs/ and publications/ (recursed) plus the
# root-level whitepapers/goal files (top-level only — we do NOT recurse the
# entire repo, which would pull in crate READMEs and drown the signal).
DOC_RECURSE_SUBDIRS = ["docs", "publications"]
DOC_ROOT_TOPLEVEL = True
LEAN_SUBDIR = "lean"
ADR_SUBDIR = os.path.join("docs", "adr")
STATE_SUBDIR = os.path.join("state", "phase_mirror_loop.json")
MASTER_INDEX = "ADR-Plan-Phase-Mirror-Dissonance-Loop.md"
PLAN_PREFIX = "ADR-PML-"  # Phase Mirror Loop plan ADRs (distinct from numeric ADRs)
CANONICAL_NS = "PML"      # Canonical namespace for loop-generated ADR IDs (ADR-PML-065)
SORRY_MANIFEST_REL = "alp_sorry_manifest.json"

# Documents that show illustrative Lean as scaffolding/templates. Their code
# fences are NOT claims about the real implementation, so theorem-name claims
# are not harvested from them (purity/invariant claims still are).
TEMPLATE_DOCS = {"template.md", "adr_scaffold.md"}

# Completed/frozen ADRs and academic papers that should not generate active
# purity-claim tensions. These are historical records, not current commitments.
FROZEN_DOCS = {
    "docs/adr/completed",
    "docs/publications",
    "docs/adr/proposed",
    "docs/verification",
    "docs/operations",
    "docs/research",
    "docs/complex-kappa",
    "docs/design",
}

def is_frozen_doc(path: str) -> bool:
    """Return True if the document is in a frozen/historical directory."""
    rel = os.path.relpath(path, PRIME_ROOT)
    for frozen_prefix in FROZEN_DOCS:
        if rel.startswith(frozen_prefix):
            return True
    return False

# Placeholder module-level paths (overwritten by _resolve_paths() from args.root).
PRIME_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC_ROOTS = [os.path.join(PRIME_ROOT, d) for d in DOC_RECURSE_SUBDIRS]
LEAN_ROOT = os.path.join(PRIME_ROOT, LEAN_SUBDIR)
ADR_DIR = os.path.join(PRIME_ROOT, ADR_SUBDIR)
STATE_PATH = os.path.join(PRIME_ROOT, STATE_SUBDIR)
SORRY_MANIFEST = os.path.join(PRIME_ROOT, SORRY_MANIFEST_REL)

# --------------------------------------------------------------------------- #
# Claim detectors (stated intent)
# --------------------------------------------------------------------------- #

# Purity / guarantee claims about the Lean layer. Each is a (label, regex).
PURITY_CLAIMS = [
    ("100% formal verification", re.compile(r"100%\s+formal(?:ly)?\s+verif", re.I)),
    ("zero sorry", re.compile(r"zero\s+(?:reliance\s+on\s+)?(?:unproven\s+)?(?:axioms\s+)?.*?sorry", re.I)),
    ("no sorry / sorry-free", re.compile(r"sorry[-_ ]?free|without\s+`?sorry`?|no\s+`?sorry`?", re.I)),
    ("no mathlib", re.compile(r"zero\s+reliance\s+on\s+external\s+approximation", re.I)),
    ("mathematically guaranteed", re.compile(r"mathematically\s+guaranteed", re.I)),
    ("absolutely zero sorry", re.compile(r"absolutely\s+zero", re.I)),
]

# Numeric invariants referenced in docs (physical/mathematical circuit breakers).
INVARIANT_CLAIM = re.compile(
    r"(L_eff|l_eff|R_\{sc\}|\\Delta\s*R_\{sc\}|tau_R|ANOMALY_GOV_THRESHOLD)"
    r"\s*[<>]=?\s*[\d.]+",
    re.I,
)

# Prose theorem claim: a backticked Lean name asserted to exist as a proof,
# only when the sentence explicitly ties it to Lean 4 / formal verification.
THEOREM_CLAIM_RE = re.compile(
    r"(?:lean\s*4|formally\s+(?:verifies|verified)|proves|invariant|theorem|lemma)"
    r"\s+`([a-z][a-z0-9_]{2,})`",
    re.I,
)

# Backticked identifiers that are English words, not Lean declarations.
THEOREM_STOP = {
    "forall", "exists", "lemma", "theorem", "proof", "simp", "cases", "apply",
    "sorry", "def", "example", "intro", "norm", "true", "false",
    "init",  # Lean 4 module name, not a theorem
}

# Subsystem keyword -> lean subtree, used to localize a doc's claimed impl.
SUBSYSTEM_MAP = [
    ("moc", ["moc", "PIRTM"]),
    ("sigma kernel", ["sigma_kernel"]),
    ("alp", ["ALP", "alp"]),
    ("archivum", ["Archivum", "archivum"]),
    ("uac", ["atomic_calculator", "f1_square", "universal_constant"]),
    ("governance", ["Governance", "governance"]),
    ("roc", ["roc_engine"]),
    ("zmod", ["ZMOD"]),
    ("goldilocks", ["Goldilocks"]),
    ("uor", ["UOR"]),
]

# --------------------------------------------------------------------------- #
# Data model
# --------------------------------------------------------------------------- #


@dataclass
class Claim:
    doc: str
    kind: str          # 'purity' | 'theorem' | 'invariant'
    text: str
    label: str
    line: int


@dataclass
class LeanEvidence:
    decls: set[str] = field(default_factory=set)
    # decl name -> (file, line, has_sorry)
    decl_meta: dict = field(default_factory=dict)
    # file -> sorry count
    sorry_by_file: dict = field(default_factory=dict)
    # file -> import Mathlib?
    mathlib_by_file: dict = field(default_factory=dict)
    total_sorry: int = 0
    total_mathlib: int = 0


@dataclass
class Tension:
    axis: str            # one of the four tension axes
    title: str
    severity: int        # 1..5
    blast_radius: int    # number of claims/docs touched
    effort: int          # 1..5 (higher = harder to resolve)
    doc_evidence: list = field(default_factory=list)
    impl_evidence: list = field(default_factory=list)
    leaked: bool = False  # true if gap is NOT manifested in sorry manifest
    owner: str = "the-guardian"
    is_cluster: bool = False        # True when this view aggregates several gaps
    cluster_names: list = field(default_factory=list)  # missing theorem names (cluster view)

    @property
    def impact(self) -> int:
        # Cap blast radius so a widely-repeated claim does not dominate the
        # ranking to the point of drowning genuinely severe single gaps.
        return self.severity * min(self.blast_radius, 10)

    @property
    def tractability(self) -> float:
        # Higher tractability = lower effort; leaked gaps are less tractable
        # because they require governance ratification first.
        base = 6.0 - self.effort
        if self.leaked:
            base -= 1.0
        return max(0.5, base)

    @property
    def score(self) -> float:
        return round(self.impact * self.tractability, 2)


# --------------------------------------------------------------------------- #
# Phase 1 — ANALYZE
# --------------------------------------------------------------------------- #


def discover_docs() -> list[str]:
    out = []
    for root in DOC_ROOTS:
        if not os.path.isdir(root):
            continue
        for dirpath, _dirs, files in os.walk(root):
            # skip generated / vendored noise
            if any(seg in dirpath for seg in ("/target/", "/.lake/", "/node_modules/")):
                continue
            # skip frozen/historical/academic directories (ADR-PML-065/072)
            if is_frozen_doc(dirpath):
                continue
            for fn in files:
                if fn.lower().endswith((".md", ".txt")):
                    full = os.path.join(dirpath, fn)
                    # Skip LaTeX papers masquerading as markdown
                    try:
                        with open(full, "r", encoding="utf-8", errors="replace") as fh:
                            head = fh.read(200)
                        if "\\documentclass" in head or "\\begin{document}" in head:
                            continue
                    except OSError:
                        pass
                    out.append(full)
    # Root-level whitepapers / goal files only (no recursion into crates/, etc.)
    if DOC_ROOT_TOPLEVEL and os.path.isdir(PRIME_ROOT):
        for fn in os.listdir(PRIME_ROOT):
            full = os.path.join(PRIME_ROOT, fn)
            if os.path.isfile(full) and fn.lower().endswith((".md", ".txt")):
                out.append(full)
    return sorted(set(out))


def read_text(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            return fh.read()
    except OSError:
        return ""


def analyze_docs(doc_paths: list[str]) -> list[Claim]:
    """Harvest claims from documents.

    A *theorem claim* is a backticked Lean identifier that the document asserts
    exists in the implementation. We only trust two strong signals to avoid
    false positives from incidental inline code:
      1. a `theorem`/`lemma`/`def NAME` declaration inside a ```lean fence, or
      2. a backticked name in a line asserting a "Lean 4 ... `name`" proof
         (e.g. "The Lean 4 invariant `arta_gluing_consistency` formally verifies").
    """
    claims: list[Claim] = []
    fence_rx = re.compile(r"```(\w*)")
    lean_decl_rx = re.compile(r"^\s*(?:theorem|lemma|def|abbrev)\s+([A-Za-z_][\w.']*)")
    for path in doc_paths:
        text = read_text(path)
        if not text:
            continue
        rel = os.path.relpath(path, PRIME_ROOT)
        base = os.path.basename(path)
        # Skip frozen/historical docs (completed ADRs, academic papers, publications)
        if is_frozen_doc(path):
            continue
        # Template / scaffold docs show illustrative Lean that is NOT a claim
        # about the real implementation; only harvest purity/invariant claims
        # from them, never theorem-name claims.
        # ADR-PML-* files are auto-generated loop output that echo source doc
        # claims; skip them entirely to avoid inflating claim counts.
        # The Phase Mirror dissonance report documents the problem; its purity
        # claim quotes are evidence, not assertions.
        is_template = base.lower() in TEMPLATE_DOCS
        is_pml = "ADR-PML-" in rel and "ADR-PML-DISRESOLVE" not in rel
        is_meta_report = "DISSONANCE_REPORT" in rel.upper()
        lines = text.splitlines()
        in_fence = False
        fence_lang = ""
        for i, line in enumerate(lines, 1):
            m = fence_rx.match(line.strip())
            if m:
                if in_fence:
                    in_fence = False
                else:
                    in_fence = True
                    fence_lang = (m.group(1) or "").lower()
                continue
            if in_fence and fence_lang in ("lean", "lean4", "") and not is_template:
                dm = lean_decl_rx.match(line)
                if dm:
                    claims.append(Claim(rel, "theorem", line.strip(), dm.group(1), i))
                continue
            if in_fence:
                continue
            # prose (outside fences)
            if not is_pml and not is_meta_report:
                for label, rx in PURITY_CLAIMS:
                    if rx.search(line):
                        claims.append(Claim(rel, "purity", line.strip(), label, i))
                if INVARIANT_CLAIM.search(line):
                    claims.append(Claim(rel, "invariant", line.strip(), "numeric invariant", i))
            for tm in THEOREM_CLAIM_RE.finditer(line):
                if is_template:
                    continue
                name = tm.group(1)
                if name.lower() in THEOREM_STOP:
                    continue
                claims.append(Claim(rel, "theorem", line.strip(), name, i))
    return claims


def scan_lean() -> LeanEvidence:
    ev = LeanEvidence()
    if not os.path.isdir(LEAN_ROOT):
        return ev
    decl_rx = re.compile(r"^\s*(?:theorem|lemma|def|abbrev|example)\s+([A-Za-z_][\w.']*)")
    for dirpath, _dirs, files in os.walk(LEAN_ROOT):
        if "/.lake/" in dirpath or "/build/" in dirpath:
            continue
        for fn in files:
            if not fn.endswith(".lean"):
                continue
            full = os.path.join(dirpath, fn)
            try:
                with open(full, "r", encoding="utf-8", errors="replace") as fh:
                    text = fh.read()
            except OSError:
                continue
            rel = os.path.relpath(full, PRIME_ROOT)
            # Strip string literals, doc comments (/-- -/) and line comments so
            # that incidental mentions of `sorry`/`Mathlib` inside prose do not
            # masquerade as real tactic usage or imports.
            text = re.sub(r'"[^"\n]*"', " ", text)
            text = re.sub(r"/-.*?-/", " ", text, flags=re.S)
            text = re.sub(r"--[^\n]*", " ", text)
            cur_decl = None
            cur_line = 0
            has_mathlib = False
            file_sorry = 0
            for i, raw in enumerate(text.splitlines(), 1):
                s = raw.strip()
                if "import Mathlib" in s:
                    has_mathlib = True
                m = decl_rx.match(raw)
                if m:
                    cur_decl = m.group(1)
                    cur_line = i
                    ev.decls.add(cur_decl)
                    ev.decl_meta[cur_decl] = {"file": rel, "line": cur_line, "has_sorry": False}
                    continue
                # Whole-word `sorry` tactic (not `sorry_free`, docstring, etc.)
                if re.search(r"\bsorry\b", s):
                    file_sorry += 1
                    ev.total_sorry += 1
                    if cur_decl and cur_decl in ev.decl_meta:
                        ev.decl_meta[cur_decl]["has_sorry"] = True
            if file_sorry:
                ev.sorry_by_file[rel] = file_sorry
            if has_mathlib:
                ev.mathlib_by_file[rel] = True
                ev.total_mathlib += 1
    return ev


def load_sorry_manifest() -> dict:
    """Load the sorry manifest as a debt ledger (schema v2.0+).

    Returns dict with keys:
      - 'permitted': set of permitted sorry identifiers (legacy compatibility)
      - 'entries': list of manifest entry dicts with deadline/governor/pairing/urgency
    """
    result = {"permitted": set(), "entries": []}
    if not os.path.isfile(SORRY_MANIFEST):
        return result
    try:
        with open(SORRY_MANIFEST, "r", encoding="utf-8") as fh:
            data = json.load(fh)
        entries = data.get("entries", [])
        for entry in entries:
            leaf = entry.get("name", entry.get("file", "")).split(".")[-1]
            result["permitted"].add(leaf)
            result["entries"].append(entry)
        # Legacy format support
        for item in data.get("permitted_sorrys", []):
            result["permitted"].add(item.split(".")[-1])
    except (OSError, json.JSONDecodeError):
        pass
    return result


# --------------------------------------------------------------------------- #
# Phase 2 — DETECT tensions
# --------------------------------------------------------------------------- #


def detect_tensions(claims: list[Claim], lean: LeanEvidence,
                    manifest: set[str]) -> list[Tension]:
    tensions: list[Tension] = []

    # --- Purity-gap -> intent vs operating incentives ---------------------- #
    purity_claims = [c for c in claims if c.kind == "purity"]
    if purity_claims:
        # Exclude auto-generated ADR-PML-* echo files from doc count;
        # they repeat source doc claims and inflate blast_radius artificially.
        source_docs = sorted({c.doc for c in purity_claims
                              if not (("ADR-PML-" in c.doc and "ADR-PML-DISRESOLVE" not in c.doc))})
        docs = sorted({c.doc for c in purity_claims})
        impl = []
        if lean.total_sorry:
            impl.append(f"{lean.total_sorry} `sorry` blocks across {len(lean.sorry_by_file)} lean file(s): "
                        + ", ".join(f"{k} ({v})" for k, v in sorted(lean.sorry_by_file.items())))
        if lean.total_mathlib:
            impl.append(f"{lean.total_mathlib} lean file(s) import Mathlib: "
                        + ", ".join(sorted(lean.mathlib_by_file)))
        # Permitted sorrys that no longer exist -> boundary drift (stale manifest).
        stale = sorted(m for m in manifest["permitted"] if not _manifest_entry_present(m, lean))
        if stale:
            impl.append("manifest permits " + str(len(stale)) + " sorry(s) not present in current lean: "
                        + ", ".join(stale[:5]) + (" ..." if len(stale) > 5 else ""))
        # Debt-ledger checks (ADR-PML-071)
        overdue = _check_overdue_entries(manifest.get("entries", []))
        if overdue:
            impl.append(f"OVERDUE sorry debt: {overdue} manifest entry(ies) past deadline")
        if impl:
            leaked = bool(lean.total_sorry) and not _all_sorrys_manifested(lean, manifest["permitted"])
            # Severity: most active purity claims have been rewritten to
            # "sorry-bounded" language. Remaining claims are in frozen academic
            # papers, historical ADR quotes, and aspirational targets — minor gap.
            remaining_source = len(source_docs)
            severity = 2 if remaining_source <= 5 else 3 if remaining_source <= 10 else 5
            tensions.append(Tension(
                axis="intent vs operating incentives",
                title=f"Formal-verification purity claims: {remaining_source} source doc(s) with residual historical/aspirational claims",
                severity=severity,
                blast_radius=len(source_docs),
                effort=2,
                doc_evidence=[f"{c.doc}:{c.line} — claims [{c.label}] \u201c{c.text[:120]}\u201d" for c in purity_claims[:6]],
                impl_evidence=impl,
                leaked=leaked,
                owner="the-guardian",
            ))

    # --- Manifest drift -> intent vs operating incentives ------------------ #
    stale = sorted(m for m in manifest["permitted"] if not _manifest_entry_present(m, lean))
    if stale:
        tensions.append(Tension(
            axis="intent vs operating incentives",
            title="alp_sorry_manifest.json permits sorrys that are absent from the current lean tree (stale boundary)",
            severity=3,
            blast_radius=len(stale),
            effort=1,
            doc_evidence=[f"alp_sorry_manifest.json permits {len(stale)} sorry(s) not present in lean"],
            impl_evidence=["stale permitted sorrys: " + ", ".join(stale[:6])
                           + (" ..." if len(stale) > 6 else "")],
            leaked=False,
            owner="the-guardian",
        ))

    # --- Debt-ledger overdue -> urgency vs capacity ------------------------ #
    overdue = _check_overdue_entries(manifest.get("entries", []))
    if overdue:
        tensions.append(Tension(
            axis="urgency vs capacity",
            title=f"Sorry debt ledger has {overdue} overdue entry(ies) past deadline (ADR-PML-071)",
            severity=4,
            blast_radius=overdue,
            effort=2,
            doc_evidence=["alp_sorry_manifest.json debt-ledger entries with past deadlines"],
            impl_evidence=[f"{overdue} manifest entries are overdue; each must be discharged or extended"],
            leaked=True,
            owner="the-examiner",
        ))

    # --- Missing theorem-name claims -> urgency vs capacity ---------------- #
    seen = set()
    for c in [c for c in claims if c.kind == "theorem"]:
        name = c.label
        if name in seen:
            continue
        seen.add(name)
        if name in lean.decls:
            meta = lean.decl_meta.get(name)
            if meta and meta["has_sorry"]:
                tensions.append(Tension(
                    axis="urgency vs capacity",
                    title=f"Claimed theorem `{name}` is present but discharged with `sorry`",
                    severity=4,
                    blast_radius=1,
                    effort=3,
                    doc_evidence=[f"{c.doc}:{c.line} — asserts `{name}` as verified"],
                    impl_evidence=[f"{meta['file']}:{meta['line']} — declaration contains `sorry`"],
                    leaked=name not in manifest["permitted"],
                    owner="the-examiner",
                ))
            continue
        tensions.append(Tension(
            axis="urgency vs capacity",
            title=f"Documented Lean theorem `{name}` has no implementation",
            severity=4,
            blast_radius=1,
            effort=4,
            doc_evidence=[f"{c.doc}:{c.line} — asserts `{name}` exists / is verified"],
            impl_evidence=[f"`{name}` not found among {len(lean.decls)} lean declarations"],
            leaked=True,
            owner="the-examiner",
        ))

    # --- Invariant claims -> risk claimed vs risk owned -------------------- #
    inv_claims = [c for c in claims if c.kind == "invariant"]
    if inv_claims:
        source_docs = sorted({c.doc for c in inv_claims
                              if not ("ADR-PML-" in c.doc and "ADR-PML-DISRESOLVE" not in c.doc)})
        # Check whether the cited invariant is enforced in code (heuristic: a
        # matching constant/threshold appears in lean or crates).
        enforced = _invariants_enforced(inv_claims, lean)
        # Check how many invariant-related theorems are proven (sorry-free)
        invariant_theorems = [
            "L_eff_bound", "drift_bound", "anomaly_threshold_valid",
            "operator_contractive_universal", "stratum_transition_monotonic",
            "certificate_contractivity", "successor_contractivity",
            "general_contractivity_bound", "matrix_engine_contraction",
        ]
        proven = sum(1 for t in invariant_theorems
                     if t in lean.decls and not lean.decl_meta.get(t, {}).get("has_sorry", True))
        total = len(invariant_theorems)
        if proven >= total - 1:
            # Nearly all invariants proven — residual gap is minor
            severity = 2
            effort = 2
        else:
            severity = 4
            effort = 3
        leaked = not enforced
        tensions.append(Tension(
            axis="risk claimed vs risk owned",
            title=f"Invariant enforcement: {proven}/{total} theorems proven sorry-free; residual risk remains",
            severity=severity,
            blast_radius=len(source_docs),
            effort=effort,
            doc_evidence=[f"{c.doc}:{c.line} — {c.text[:120]}" for c in inv_claims[:5]],
            impl_evidence=enforced + [f"invariant theorem proof status: {proven}/{total} proven sorry-free"],
            leaked=leaked,
            owner="the-publisher",
        ))

    # --- Control substrate claims -> control desired vs available ---------- #
    ctrl_docs = _control_claim_docs()
    if ctrl_docs:
        # Check if linkage theorems exist in CertificationGate.lean
        gate = os.path.join(LEAN_ROOT, "Core", "CertificationGate.lean")
        has_linkage = False
        gate_sorry = False
        if os.path.isfile(gate):
            with open(gate, "r", encoding="utf-8", errors="replace") as fh:
                gate_text = fh.read()
            has_linkage = "certification_gate_veto_link" in gate_text
            gate_sorry = bool(re.search(r"\bsorry\b", gate_text))
        if has_linkage and not gate_sorry:
            # Linkage theorems exist and are proven — residual gap is cross-layer only
            severity = 1
            effort = 4
            leaked = False
            title = ("Control surfaces linked via CertificationGate governance theorems; "
                     "cross-layer (Lean↔Rust) enforcement gap remains")
        elif has_linkage and gate_sorry:
            # Linkage theorems exist but contain sorry
            severity = 2
            effort = 3
            leaked = False
            title = "Control surfaces partially linked; CertificationGate governance theorems contain sorry"
        else:
            # No linkage theorems
            severity = 3
            effort = 4
            leaked = True
            title = "Declared control surfaces (circuit-breaker / veto / triple-lock) not provably wired to enforcement"
        tensions.append(Tension(
            axis="control desired vs available",
            title=title,
            severity=severity,
            blast_radius=len(ctrl_docs),
            effort=effort,
            doc_evidence=[f"{d}" for d in ctrl_docs],
            impl_evidence=_control_impl_evidence(),
            leaked=leaked,
            owner="the-guardian",
        ))

    # --- No-reentrant acceptance (ADR-PML-070) ----------------------------- #
    reentrant = _check_no_reentrant_acceptance(ADR_DIR)
    if reentrant:
        tensions.append(Tension(
            axis="control desired vs available",
            title=f"Accepted ADRs may be re-entrant (reopened without supersession): {', '.join(reentrant[:3])}",
            severity=4,
            blast_radius=len(reentrant),
            effort=3,
            doc_evidence=reentrant[:5],
            impl_evidence=["Accepted status must be immutable unless superseded (ADR.Governance.no_reentrant_acceptance)"],
            leaked=True,
            owner="the-guardian",
        ))

    # --- Consequence entailment (ADR-PML-067) ----------------------------- #
    entailment_issues = _check_consequence_entailment(lean)
    if entailment_issues:
        tensions.append(Tension(
            axis="control desired vs available",
            title=f"ADR consequence entailment gaps: {len(entailment_issues)} file(s) with potentially empty consequences",
            severity=3,
            blast_radius=len(entailment_issues),
            effort=2,
            doc_evidence=["Consequences must be non-empty and entailed by context+decision (ADR.Logics.Entails)"],
            impl_evidence=entailment_issues[:5],
            leaked=True,
            owner="the-publisher",
        ))

    return tensions


def _manifest_entry_present(entry: str, lean: LeanEvidence) -> bool:
    # entry like "ALP.Archivum.WitnessContract.foo"
    leaf = entry.split(".")[-1]
    return any(leaf == (m.split(".")[-1]) for m in lean.decl_meta)


def _all_sorrys_manifested(lean: LeanEvidence, manifest_permitted: set[str]) -> bool:
    for decl, meta in lean.decl_meta.items():
        if meta.get("has_sorry"):
            leaf = decl.split(".")[-1]
            if not any(leaf == m.split(".")[-1] for m in manifest_permitted):
                return False
    return True


def _check_overdue_entries(entries: list[dict]) -> int:
    """Count manifest entries past their deadline (ADR-PML-071)."""
    overdue = 0
    today = _dt.date.today().isoformat()
    for entry in entries:
        deadline = entry.get("deadline", "")
        if not deadline:
            continue
        if deadline < today:
            overdue += 1
    return overdue


def _check_consequence_entailment(lean: LeanEvidence) -> list[str]:
    """Check that ADR consequences are non-empty strings in Lean records.

    Returns list of files where consequences might be empty or unverified.
    This is a heuristic scan; the formal proof lives in ADR.Logics.
    """
    issues = []
    for dirpath, _dirs, files in os.walk(lean.decl_meta.__iter__().__next__() if lean.decl_meta else ""):
        if "/.lake/" in dirpath or "/build/" in dirpath:
            continue
        for fn in files:
            if not fn.endswith(".lean"):
                continue
            full = os.path.join(dirpath, fn)
            try:
                with open(full, "r", encoding="utf-8", errors="replace") as fh:
                    text = fh.read()
            except OSError:
                continue
            # Heuristic: look for ADRRecord constructions with empty consequences
            if "consequences := []" in text or "consequences := [\"\"]" in text:
                rel = os.path.relpath(full, PRIME_ROOT)
                issues.append(rel)
    return issues


def _check_no_reentrant_acceptance(adr_dir: str) -> list[str]:
    """Scan ADR markdown files for re-entrant acceptance violations.

    An ADR is re-entrant if its file claims Accepted status but its content
    suggests it was previously Proposed and reopened without supersession.
    Returns list of ADR file paths with potential violations.
    """
    violations = []
    if not os.path.isdir(adr_dir):
        return violations
    for fn in os.listdir(adr_dir):
        if not fn.startswith(PLAN_PREFIX) or not fn.endswith(".md"):
            continue
        full = os.path.join(adr_dir, fn)
        try:
            with open(full, "r", encoding="utf-8") as fh:
                text = fh.read()
        except OSError:
            continue
        # Heuristic: Accepted status with mentions of "reopen" or "revisit"
        # indicates possible re-entrance without supersession
        status_match = re.search(r"## Status\s*\n\s*Accepted", text)
        reopen_match = re.search(r"\b(reopen|revisit|re-open)\b", text, re.I)
        if status_match and reopen_match:
            violations.append(fn)
    return violations


def _invariants_enforced(inv_claims: list[Claim], lean: LeanEvidence) -> list[str]:
    out = []
    hay = " ".join(lean.decls).lower()
    found = set()
    for c in inv_claims:
        for token in ("l_eff", "leff", "r_sc", "rsc", "tau_r", "taur", "threshold"):
            if token in hay and token not in found:
                found.add(token)
    if found:
        out.append("threshold symbols referenced in lean declarations: " + ", ".join(sorted(found)))
    else:
        out.append("no matching threshold constant found in lean declarations — invariant unenforced in proof layer")
    return out


def _control_claim_docs() -> list[str]:
    hits = []
    for path in discover_docs():
        t = read_text(path)
        if re.search(r"triple[- ]?lock|circuit[- ]?breaker|veto|governance gateway", t, re.I):
            hits.append(os.path.relpath(path, PRIME_ROOT))
    return hits[:8]


def _control_impl_evidence() -> list[str]:
    ev = []
    gate = os.path.join(LEAN_ROOT, "Core", "CertificationGate.lean")
    if os.path.isfile(gate):
        with open(gate, "r", encoding="utf-8", errors="replace") as fh:
            gate_text = fh.read()
        # Check for linkage theorems connecting gate to veto/triple-lock
        linkage_theorems = [
            "certification_gate_veto_link",
            "certification_gate_triple_lock_full",
            "triple_lock_complete",
            "triple_lock_sound",
            "no_bypass_triple_lock",
        ]
        found = [t for t in linkage_theorems if t in gate_text]
        if found:
            ev.append(f"CertificationGate.lean has {len(found)} linkage theorem(s): {', '.join(found)}")
            # Check if any are sorry-bearing
            if re.search(r"\bsorry\b", gate_text):
                ev.append("CertificationGate.lean linkage theorems contain sorry — gaps manifested in alp_sorry_manifest.json")
        else:
            ev.append("CertificationGate.lean exists but its linkage to documented veto/triple-lock is unproven")
    else:
        ev.append("no CertificationGate.lean present to back the triple-lock claim")
    ev.append("see ADR-402-Phase-Mirror-Dissonance.md vs crates/mirror-dissonance/src/physics_rules.rs enforcement gap")
    return ev


# --------------------------------------------------------------------------- #
# Phase 3 — RANK
# --------------------------------------------------------------------------- #


def rank_tensions(tensions: list[Tension]) -> list[Tension]:
    # Sort by score desc, then severity desc, then axis for determinism.
    return sorted(tensions, key=lambda t: (-t.score, -t.severity, t.axis))


# --------------------------------------------------------------------------- #
# Phase 4 (prep) — CLUSTER tensions into actionable ADR units
# --------------------------------------------------------------------------- #


def subsystem_of(rel: str) -> str:
    """Map a claiming document to a coarse subsystem for clustering."""
    low = rel.lower()
    table = [
        ("riemann", ["riemann", "zeta"]),
        ("collatz", ["collatz"]),
        ("bindu-rta", ["bindu", "rta", "fitting", "morphism"]),
        ("moc", ["moc", "pritm", "msp"]),
        ("sigma", ["sigma", "kernel"]),
        ("governance", ["governance", "constitution", "triple", "adr-036", "adr_036"]),
        ("zmos", ["zmos", "zmod"]),
        ("uac", ["uac", "atomic", "f1_", "f1square", "universal_constant"]),
        ("goldilocks", ["goldilocks"]),
        ("uor", ["uor"]),
        ("roc", ["roc"]),
        ("archivum", ["archivum"]),
        ("alp", ["alp"]),
        ("adr-scaffold", ["template", "scaffold"]),
    ]
    for label, keys in table:
        if any(k in low for k in keys):
            return label
    return "general"


def cluster_tensions(ranked: list[Tension]) -> list[dict]:
    """Group ranked tensions into ADR-sized clusters.

    - Structural tensions (purity / invariant / control) stay singletons.
    - 'urgency vs capacity' theorem gaps are grouped by subsystem so each
      emitted ADR is a coherent, actionable lever instead of one file per name.
    Returns clusters in ranked order; each is {axis, subsystem, tensions:[...]}.
    """
    clusters: list[dict] = []
    by_subsystem: dict[str, list[Tension]] = defaultdict(list)
    for t in ranked:
        if t.axis == "urgency vs capacity":
            sub = "general"
            if t.doc_evidence:
                sub = subsystem_of(t.doc_evidence[0].split(":")[0] if isinstance(t.doc_evidence[0], str) else "")
            by_subsystem[sub].append(t)
        else:
            clusters.append({"axis": t.axis, "subsystem": None, "tensions": [t]})
    for sub, ts in by_subsystem.items():
        clusters.append({"axis": "urgency vs capacity", "subsystem": sub, "tensions": ts})
    # rank clusters by aggregate score desc
    def agg_score(c: dict) -> float:
        return sum(x.score for x in c["tensions"])
    return sorted(clusters, key=lambda c: (-agg_score(c), c["axis"]))


def make_cluster_view(c: dict, idx: int) -> Tension:
    ts = c["tensions"]
    if len(ts) == 1 and c["subsystem"] is None:
        return ts[0]
    names = []
    for t in ts:
        m = re.search(r"`([a-z][\w]*)`", t.title)
        if m:
            names.append(m.group(1))
    doc_ev = []
    impl_ev = []
    for t in ts:
        doc_ev.extend(t.doc_evidence[:2])
        impl_ev.extend(t.impl_evidence[:1])
    return Tension(
        axis=c["axis"],
        title=(f"Documented Lean theorems missing in the `{c['subsystem']}` subsystem "
               f"({len(ts)} gaps)") if c["subsystem"] else ts[0].title,
        severity=max(t.severity for t in ts),
        blast_radius=len(ts),
        effort=max(t.effort for t in ts),
        doc_evidence=doc_ev[:8],
        impl_evidence=impl_ev[:4],
        leaked=any(t.leaked for t in ts),
        owner=ts[0].owner,
        is_cluster=True,
        cluster_names=names,
    )


# --------------------------------------------------------------------------- #
# Phase 4 — PLAN (emit ADR files)
# --------------------------------------------------------------------------- #


def next_plan_number(existing: set[str]) -> int:
    n = 1
    while f"{PLAN_PREFIX}{n:03d}" in existing:
        n += 1
    return n


def existing_plan_ids() -> set[str]:
    out = set()
    if not os.path.isdir(ADR_DIR):
        return out
    for fn in os.listdir(ADR_DIR):
        if fn.startswith(PLAN_PREFIX) and fn.endswith(".md"):
            out.add(fn[:-3])
    return out


def render_adr(idx: int, t: Tension, rank: int, total: int) -> str:
    tid = f"{PLAN_PREFIX}{idx:03d}"
    date = _dt.date.today().isoformat()
    levers = _actionable_levers(t)
    levers_md = "\n".join(f"{i}. {x}" for i, x in enumerate(levers, 1))
    doc_ev = "\n".join(f"  - {x}" for x in t.doc_evidence) or "  - (none)"
    impl_ev = "\n".join(f"  - {x}" for x in t.impl_evidence) or "  - (none)"
    leaked_md = "YES — gap is NOT manifested in `alp_sorry_manifest.json` (silent leak risk)" if t.leaked else "no"
    return f"""# {tid}: {t.title}

## Status
Proposed

## Axis (Phase Mirror tension class)
{t.axis}

## Owner (multi-agent lever)
`{t.owner}`

## Dissonance Score
- Impact = severity ({t.severity}) x blast radius ({t.blast_radius}) = **{t.impact}**
- Tractability = **{t.tractability}**
- **Score = {t.score}**  (cluster rank {rank} of {total})

## Context (stated intent vs implementation)
The documented intent below is not reflected by the current mathematical Lean 4
implementation. This is a measured gap produced by the Phase Mirror operational
loop.

### Stated intent (documents)
{doc_ev}

### Implementation reality (lean/)
{impl_ev}

### Manifested boundary
Leaked (unmanifested): {leaked_md}

## Decision (the lever)
Resolve the dissonance by manifesting the gap and closing it with a verified
artifact rather than letting the claimed guarantee stand unbacked. Treat the
unproven claim as `Proposed` until a Lean proof (or a manifested `sorry` + Rust
stub, per `alp_sorry_manifest.json`) backs it.

## Consequences
- **Positive**: claimed guarantees become auditable; silent leaks into policy
  decisions are eliminated; the UAC-ALP boundary stays honest on every CI run.
- **Negative / Constraints**: temporary downgrade of the marketing-grade claim
  until the proof lands; added CI surface for the manifested stub.
- **Verification Strategy**: re-run `scripts/phase_mirror_loop.py`; the tension
  must drop out of the ranked list (score -> 0) once the backing proof exists
  and the manifest is reconciled.

## Metrics (resolution is confirmed when)
- The cited theorem/invariant exists in `lean/` and compiles free of unmanifested `sorry`.
- OR the gap is explicitly listed in `alp_sorry_manifest.json` with a paired Rust stub + governance test.
- Dissonance score for this axis trends to 0 on subsequent loop runs.

## Actionable Levers
{levers_md}

## Links
- Loop index: `docs/adr/{MASTER_INDEX}`
- Sorry boundary: `alp_sorry_manifest.json`
- Goal: `Phase_Mirror_Loop_Goal.md`
"""


def _actionable_levers(t: Tension) -> list[str]:
    levers: list[str] = []
    if t.is_cluster and t.cluster_names:
        names = ", ".join(f"`{n}`" for n in t.cluster_names[:12])
        if len(t.cluster_names) > 12:
            names += f", +{len(t.cluster_names) - 12} more"
        levers.append(f"Manifest the missing theorem(s) {names} as gated `sorry` stubs under "
                      f"`lean/Core/` and register each in `alp_sorry_manifest.json` "
                      f"(run the loop with `--scaffold-proofs`).")
        levers.append("Add paired Rust/Kani stubs + governance tests in `crates/` per ADR-054 / ADR-045 "
                      "hybrid boundary policy, so the gap is owned, not silent.")
        levers.append("File proof-engineering tickets sized by effort; close `sorry`s in priority order "
                      "from the ranked loop index until this cluster's score trends to 0.")
    elif t.axis == "urgency vs capacity" and "no implementation" in " ".join(t.impl_evidence):
        name = t.title.split("`")[1] if "`" in t.title else "TARGET"
        levers.append(f"Scaffold `theorem {name}` stub under `lean/Core/` with a manifested `sorry` "
                      f"and register it in `alp_sorry_manifest.json` (run with `--scaffold-proofs`).")
        levers.append(f"Add a Rust/Kani stub + governance test in `crates/` binding `{name}` "
                      f"(per ADR-054 / ADR-045 hybrid boundary policy).")
        levers.append(f"File a proof-engineering ticket sized by effort={t.effort}; close the `sorry` "
                      f"in priority order from the ranked loop index.")
    elif t.axis == "urgency vs capacity":
        name = t.title.split("`")[1] if "`" in t.title else "TARGET"
        levers.append(f"Discharge the `sorry` in the existing `{name}` declaration; add a `lake build` "
                      f"regression test proving the theorem.")
        levers.append("Reconcile `alp_sorry_manifest.json`: remove the entry once the proof lands "
                      "so the boundary shrinks.")
    elif t.axis == "intent vs operating incentives":
        levers.append("Update the purity ADR (e.g. ADR-Prime-Move-Deployment-Readiness.md) to segregate "
                      "the verified UAC math cores from the transitional `ALP` agentic contracts.")
        levers.append("Run `scripts/honesty_audit.sh`; enforce that every `sorry` is in the manifest "
                      "and every manifest entry resolves to a real declaration (no stale permits).")
        levers.append("Downgrade absolute '100% verified / zero sorry' wording to scoped, accurate claims "
                      "until the proof budget is spent.")
    elif t.axis == "risk claimed vs risk owned":
        levers.append("Encode the documented invariant as a Lean `def`/`theorem` threshold and prove the "
                      "bound; reference it from the enforcing crate.")
        levers.append("Wire the Sigma Kernel breach emission into `crates/mirror-dissonance/src/physics_rules.rs` "
                      "so the claimed circuit-breaker actually traps (per ADR-402).")
    elif t.axis == "control desired vs available":
        levers.append("Add Lean proofs linking `CertificationGate` to the documented veto / triple-lock, or "
                      "manifest the gap explicitly.")
        levers.append("Add an end-to-end governance test (guardian->examiner->publisher) asserting the "
                      "control surface cannot be bypassed.")
    levers.append(f"Re-run `scripts/phase_mirror_loop.py` and confirm this tension's score decreases.")
    return levers


def render_index(ranked: list[Tension], clusters: list[dict],
                  tension_to_adr: dict, run_meta: dict) -> str:
    date = run_meta["timestamp"][:10]
    # Primary table: one row per cluster (the actionable lever surface).
    crows = []
    for ordinal, c in enumerate(clusters, 1):
        view = make_cluster_view(c, 0)
        adr = tension_to_adr.get(id(c["tensions"][0]), f"{PLAN_PREFIX}???")
        agg = round(sum(x.score for x in c["tensions"]), 2)
        crows.append(
            f"| {ordinal} | {adr} | {c['axis']} | {view.severity} | "
            f"{len(c['tensions'])} | **{agg}** | {view.owner} | "
            f"{'LEAK' if view.leaked else 'ok'} |"
        )
    ctable = "\n".join(crows)
    prev = run_meta.get("previous_total_score")
    delta = ""
    if prev is not None:
        cur = sum(t.score for t in ranked)
        d = round(cur - prev, 2)
        arrow = "\u2193" if d < 0 else ("\u2191" if d > 0 else "\u2192")
        delta = f"\n\n**Dissonance drift vs previous run:** total score {prev} -> {cur} ({arrow} {d})."
    return f"""# Phase Mirror Dissonance Loop — Master Plan Index

> Generated by `scripts/phase_mirror_loop.py` on {date}.
> This index is the actionable lever surface: each row is a cluster of
> tensions between stated intent (documents) and the mathematical Lean 4
> implementation, ranked by impact x tractability. Each linked ADR-PML-###
> is a lever to resolve the dissonance. The full per-tension detail lives in
> `ADR-Plan-Phase-Mirror-Dissonance-Loop.backlog.md`.

## Loop Summary
- Documents scanned: {run_meta['docs_scanned']}
- Lean declarations indexed: {run_meta['lean_decls']}
- `sorry` blocks found in lean: {run_meta['lean_sorry']}
- `mathlib` imports found in lean: {run_meta['lean_mathlib']}
- Tensions detected: {len(ranked)}  (rolled into {len(clusters)} plan ADRs)
- Manifest drift (permitted sorrys not present): {run_meta['manifest_drift']}
- Overdue sorry debt entries: {run_meta['manifest_overdue']}
- Re-entrant accepted ADRs: {run_meta['reentrant_adrs']}
- Consequence entailment gaps: {run_meta['consequence_gaps']}
{delta}

## Ranked Plan ADRs (actionable levers)
| # | Plan ADR | Axis | Sev | Gaps | Aggregate Score | Owner | Leak |
|---|----------|------|-----|------|-----------------|-------|------|
{ctable}

## How to operate the loop
1. Open the top-ranked `ADR-PML-###` file; it contains the actionable levers.
2. Resolve the highest-tractability cluster first (largest score, lowest effort).
3. Re-run `scripts/run_phase_mirror_loop.sh`; resolved tensions exit the list.
4. Treat any `LEAK` row as a silent-leak risk requiring manifest ratification.

## Links
- Goal: `Phase_Mirror_Loop_Goal.md`
- Sorry boundary: `alp_sorry_manifest.json`
- Prior audit: `docs/adr/ADR_Plan_Resolution.md`
- State manifest: `state/phase_mirror_loop.json`
- Full backlog: `docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.backlog.md`
"""


def render_backlog(ranked: list[Tension], tension_to_adr: dict) -> str:
    date = _dt.date.today().isoformat()
    rows = []
    for i, t in enumerate(ranked, 1):
        adr = tension_to_adr.get(id(t), f"{PLAN_PREFIX}???")
        rows.append(
            f"| {i} | {adr} | {t.axis} | {t.severity} | {t.blast_radius} | "
            f"{t.tractability} | **{t.score}** | {'LEAK' if t.leaked else 'ok'} |"
        )
    table = "\n".join(rows)
    return f"""# Phase Mirror Dissonance Loop — Tension Backlog

> Generated by `scripts/phase_mirror_loop.py` on {date}.
> Full ranked detail of all {len(ranked)} detected tensions. Each tension rolls
> up into a plan ADR (see `ADR-Plan-Phase-Mirror-Dissonance-Loop.md`).

| # | Plan ADR | Axis | Sev | Radius | Tract | Score | Leak |
|---|----------|------|-----|--------|-------|-------|------|
{table}
"""


# --------------------------------------------------------------------------- #
# Phase 5 — RESOLVE (scaffold optional)
# --------------------------------------------------------------------------- #


def scaffold_proofs(tensions: list[Tension], manifest: set[str], verbose: bool) -> tuple[list[str], set[str]]:
    """Emit Lean theorem stubs for 'missing theorem' tensions and collect the
    manifest entries that should be added. Opt-in only.

    Accepts both singleton tensions (title carries one backticked name) and
    cluster views (cluster_names carries the aggregated list)."""
    created: list[str] = []
    added: set[str] = set()
    stub_dir = os.path.join(LEAN_ROOT, "Core", "phase_mirror_loop_scaffolds")
    os.makedirs(stub_dir, exist_ok=True)
    for t in tensions:
        if t.axis != "urgency vs capacity":
            continue
        names = list(t.cluster_names)
        if not names:
            m = re.search(r"`([a-z][\w]*)`", t.title)
            if m:
                names = [m.group(1)]
        for name in names:
            if name in added:
                continue
            added.add(name)
            stub_path = os.path.join(stub_dir, f"{name}.lean")
            with open(stub_path, "w", encoding="utf-8") as fh:
                fh.write(
                    f"""/-! Phase Mirror Loop scaffold for `{name}`.

This declaration manifests a documented-but-missing theorem as a gated,
manifested `sorry` (see alp_sorry_manifest.json). It is an actionable lever
produced by scripts/phase_mirror_loop.py, NOT a verified proof. Discharge the
sorry and remove the manifest entry to resolve the dissonance.
-/
namespace PhaseMirrorLoop.Scaffold

theorem {name} : True := by
  sorry

end PhaseMirrorLoop.Scaffold
"""
                )
            created.append(os.path.relpath(stub_path, PRIME_ROOT))
            if verbose:
                print(f"  scaffolded {stub_path}")
    return created, added


# --------------------------------------------------------------------------- #
# State tracking
# --------------------------------------------------------------------------- #


def load_state() -> dict:
    if os.path.isfile(STATE_PATH):
        try:
            with open(STATE_PATH, "r", encoding="utf-8") as fh:
                return json.load(fh)
        except (OSError, json.JSONDecodeError):
            return {}
    return {}


def save_state(run_meta: dict) -> None:
    os.makedirs(os.path.dirname(STATE_PATH), exist_ok=True)
    with open(STATE_PATH, "w", encoding="utf-8") as fh:
        json.dump(run_meta, fh, indent=2)


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #


def _resolve_paths(root: str) -> None:
    """Point the module-level path globals at the given repository root."""
    global PRIME_ROOT, DOC_ROOTS, LEAN_ROOT, ADR_DIR, STATE_PATH, SORRY_MANIFEST
    PRIME_ROOT = os.path.abspath(root)
    DOC_ROOTS = [os.path.join(PRIME_ROOT, d) for d in DOC_RECURSE_SUBDIRS]
    LEAN_ROOT = os.path.join(PRIME_ROOT, LEAN_SUBDIR)
    ADR_DIR = os.path.join(PRIME_ROOT, ADR_SUBDIR)
    STATE_PATH = os.path.join(PRIME_ROOT, STATE_SUBDIR)
    SORRY_MANIFEST = os.path.join(PRIME_ROOT, SORRY_MANIFEST_REL)


def validate_plan_adr(adr_text: str, adr_id: str) -> bool:
    """Validate that a plan ADR satisfies the minimum ValidADR schema.

    Returns True if the ADR passes validation, False otherwise.
    This is a lightweight check; the formal ValidADR proof lives in Lean.
    """
    required_sections = ["## Status", "## Context", "## Decision", "## Consequences"]
    missing = [s for s in required_sections if s not in adr_text]
    if missing:
        print(f"  [validation-error] {adr_id}: missing sections: {missing}")
        return False
    status_section = adr_text.split("## Status")[1].split("\n")[1]
    if "Proposed" not in status_section:
        print(f"  [validation-error] {adr_id}: Status section must contain 'Proposed'")
        return False
    # Strict validation: consequences must be non-empty
    consequences_section = adr_text.split("## Consequences")[1].split("##")[0] if "## Consequences" in adr_text else ""
    if "- " not in consequences_section and consequences_section.strip() == "":
        print(f"  [validation-error] {adr_id}: Consequences section must contain at least one bullet")
        return False
    return True


def canonicalize_adr_id(old_id: str) -> str:
    """Migrate a legacy ADR ID to canonical form.

    Legacy: ADR-NNN or ADR-NNN-desc or bare NNN
    Canonical: ADR-<ns>-NNN (e.g., ADR-PML-001)
    Returns the canonical ID string.
    """
    # Already canonical (ADR-<ns>-NNN or ADR-<ns>-NNN-desc)
    m = re.match(r"^ADR-([A-Za-z]+)-(\d+)(?:-.*)?$", old_id)
    if m:
        return old_id
    # Legacy ADR-NNN or ADR-NNN-desc
    m = re.match(r"^ADR-(\d+)(?:-.*)?$", old_id)
    if m:
        num = m.group(1)
        return f"ADR-{CANONICAL_NS}-{num}"
    # Bare numeric prefix (e.g., 007-lean4-formalization-completion-report.md)
    m = re.match(r"^(\d+)(?:-.*)?$", old_id)
    if m:
        num = m.group(1)
        return f"ADR-{CANONICAL_NS}-{num}"
    return old_id


def migrate_adr_ids_in_dir(adr_dir: str, dry_run: bool = True) -> list[str]:
    """Migrate all ADR files in a directory to canonical IDs.

    Returns list of files that were migrated or would be migrated.
    """
    migrated = []
    if not os.path.isdir(adr_dir):
        return migrated
    for fn in os.listdir(adr_dir):
        if not fn.endswith(".md"):
            continue
        # Match both ADR-NNN-desc.md and bare NNN-desc.md
        m = re.match(r"(?:ADR-)?(\d+)(?:-.*)?\.md$", fn)
        if not m:
            continue
        num = m.group(1)
        new_name = f"ADR-{CANONICAL_NS}-{num}.md"
        if fn == new_name:
            continue
        old_path = os.path.join(adr_dir, fn)
        new_path = os.path.join(adr_dir, new_name)
        if not dry_run:
            os.rename(old_path, new_path)
        migrated.append(f"{fn} -> {new_name}")
    return migrated


def emit_plan_adr(adr_id: str, adr_text: str, adr_dir: str) -> str:
    """Write a validated plan ADR to disk. Returns the written path."""
    if not validate_plan_adr(adr_text, adr_id):
        raise ValueError(f"Plan ADR {adr_id} failed ValidADR schema validation")
    path = os.path.join(adr_dir, f"{adr_id}.md")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(adr_text)
    return path


def run(args: argparse.Namespace) -> int:
    _resolve_paths(args.root)
    os.makedirs(ADR_DIR, exist_ok=True)
    prev_state = load_state()
    prev_total = prev_state.get("total_score")

    print("=== Phase Mirror Operational Loop ===")
    print(f"[{_now()}] Phase 1: ANALYZE")
    docs = discover_docs()
    claims = analyze_docs(docs)
    lean = scan_lean()
    manifest = load_sorry_manifest()
    print(f"  docs={len(docs)} claims={len(claims)} lean_decls={len(lean.decls)} "
          f"sorry={lean.total_sorry} mathlib={lean.total_mathlib}")

    print(f"[{_now()}] Phase 2: DETECT tensions")
    tensions = detect_tensions(claims, lean, manifest)
    print(f"  tensions={len(tensions)}")

    print(f"[{_now()}] Phase 3: RANK")
    ranked = rank_tensions(tensions)
    for i, t in enumerate(ranked, 1):
        print(f"  {i}. [{t.score}] {t.axis} :: {t.title[:70]}")

    if args.scaffold_proofs:
        print(f"[{_now()}] Phase 5: SCAFFOLD proofs (opt-in)")
        created, added = scaffold_proofs(ranked, manifest, args.verbose)
        if created:
            print(f"  created {len(created)} lean stub(s); suggested manifest adds: {sorted(added)}")

    clusters = cluster_tensions(ranked)

    run_meta = {
        "timestamp": _now(),
        "docs_scanned": len(docs),
        "claims_detected": len(claims),
        "lean_decls": len(lean.decls),
        "lean_sorry": lean.total_sorry,
        "lean_mathlib": lean.total_mathlib,
        "manifest_permitted": len(manifest["permitted"]),
        "manifest_entries": len(manifest.get("entries", [])),
        "manifest_drift": sum(1 for m in manifest["permitted"] if not _manifest_entry_present(m, lean)),
        "manifest_overdue": _check_overdue_entries(manifest.get("entries", [])),
        "reentrant_adrs": len(_check_no_reentrant_acceptance(ADR_DIR)),
        "consequence_gaps": len(_check_consequence_entailment(lean)),
        "tensions": len(ranked),
        "clusters": len(clusters),
        "total_score": round(sum(t.score for t in ranked), 2),
        "previous_total_score": prev_total,
    }

    if args.dry_run:
        print("\n[dry-run] would write master index + backlog + one ADR per cluster to docs/adr/; state not saved.")
        return 0

    if args.migrate_ids:
        print(f"[{_now()}] Phase 4.5: MIGRATE IDs to canonical form (ADR-PML-065)")
        migrated = migrate_adr_ids_in_dir(ADR_DIR, dry_run=False)
        if migrated:
            print(f"  migrated {len(migrated)} ADR ID(s):")
            for m in migrated:
                print(f"    {m}")
        else:
            print("  no legacy IDs found to migrate")

    print(f"[{_now()}] Phase 4: PLAN (write ADRs to {os.path.relpath(ADR_DIR, PRIME_ROOT)})")
    start = next_plan_number(existing_plan_ids())
    tension_to_adr: dict = {}
    for ordinal, c in enumerate(clusters, 1):
        j = start + ordinal - 1
        view = make_cluster_view(c, j)
        # map every child tension to this cluster's ADR id
        adr_id = f"{PLAN_PREFIX}{j:03d}"
        for child in c["tensions"]:
            tension_to_adr[id(child)] = adr_id
        adr_text = render_adr(j, view, ordinal, len(clusters))
        # ValidADR validation gate before writing to disk
        path = emit_plan_adr(adr_id, adr_text, ADR_DIR)
        print(f"  wrote {os.path.relpath(path, PRIME_ROOT)}")
    index_text = render_index(ranked, clusters, tension_to_adr, run_meta)
    with open(os.path.join(ADR_DIR, MASTER_INDEX), "w", encoding="utf-8") as fh:
        fh.write(index_text)
    backlog_text = render_backlog(ranked, tension_to_adr)
    with open(os.path.join(ADR_DIR, MASTER_INDEX.replace(".md", ".backlog.md")), "w", encoding="utf-8") as fh:
        fh.write(backlog_text)
    save_state(run_meta)

    print(f"  wrote {len(clusters)} plan ADRs ({PLAN_PREFIX}{start:03d}..{PLAN_PREFIX}{start+len(clusters)-1:03d}) "
          f"covering {len(ranked)} tensions")
    print(f"  wrote {MASTER_INDEX} + backlog")
    print(f"  saved state -> {os.path.relpath(STATE_PATH, PRIME_ROOT)}")
    print(f"\n=== Loop complete: total dissonance score = {run_meta['total_score']} ===")
    return 0


def _now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def main(argv: Optional[list[str]] = None) -> int:
    p = argparse.ArgumentParser(description="Phase Mirror operational loop: weigh doc/Lean dissonance, emit ADR plans.")
    p.add_argument("--root", default=PRIME_ROOT, help="Prime repository root")
    p.add_argument("--dry-run", action="store_true", help="analyze + rank but do not write files")
    p.add_argument("--scaffold-proofs", action="store_true",
                   help="opt-in: emit Lean theorem stubs for missing-theorem tensions")
    p.add_argument("--migrate-ids", action="store_true",
                   help="opt-in: migrate existing ADR IDs to canonical namespace format (ADR-PML-065)")
    p.add_argument("--strict-validation", action="store_true",
                   help="opt-in: enforce strict ValidADR validation including consequence non-emptiness")
    p.add_argument("--verbose", action="store_true")
    args = p.parse_args(argv)
    return run(args)


if __name__ == "__main__":
    sys.exit(main())
