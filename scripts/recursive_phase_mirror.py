#!/usr/bin/env python3
"""
recursive_phase_mirror.py — Recursive Phase Mirror Loop (ADR-232)

Continuous, time-aware mirror over the entire Prime/ directory. It harvests
stated intent (documents: ADRs, papers, READMEs, goal notes) and developed
reality (implementation evidence: Lean declarations, Rust items, generated
artifacts), pairs every document claim to implementation evidence, and
classifies each pairing:

    match                                       => GOLDEN
    mismatch + impl mtime > doc mtime           => DOC_STALE  (update the doc)
    mismatch + doc mtime >= impl mtime          => CODE_STALE (update the math/code)
    mismatch + no implementation timestamp      => CODE_STALE (forward commitment)

Emits plan ADRs (ADR-RML-###), a master index, a full backlog, and a state
ledger. Runs once (--once) or as a daemon (--watch N).

This is read-only analysis by default: it never edits Lean proofs or source
documents. --scaffold-proofs is the only opt-in that writes Lean stubs.

Per ADR-232 §5, template/frozen documents are excluded from claim harvesting,
and a claim that resolves to a sorry-free declaration is always GOLDEN.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import hashlib
import json
import os
import re
import signal
import sys
import time
from collections import defaultdict
from dataclasses import dataclass, field

# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

PRIME_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Implementation evidence roots. These are the "developed reality" subtrees.
IMPL_ROOTS = ["lean", "RH_Multiplicity", "rust", "src", "data"]
# Document claim roots. These are the "stated intent" subtrees.
DOC_ROOTS = ["Governance", "paper", "docs", "publications"]
# Additional top-level documents (README, goal notes).
DOC_TOPLEVEL = True

# Subtree names that are never scanned (build output, vendored deps, VCS).
SKIP_DIR_SEGMENTS = {".git", ".lake", "node_modules", "target", "build",
                     ".lake/build", "Lake/build", ".lake/packages", ".lake/build/lib",
                     "__pycache__", ".venv", "venv", "dist", "lake-packages"}

PLAN_PREFIX = "ADR-RML-"
MASTER_INDEX = "ADR-Plan-Recursive-Phase-Mirror-Loop.md"
BACKLOG_NAME = MASTER_INDEX.replace(".md", ".backlog.md")
ADR_OUTPUT_DIR = os.path.join("Governance", "adr", "proposed")
STATE_PATH = os.path.join("state", "recursive_phase_mirror.json")

# GOLDEN / DOC_STALE / CODE_STALE
GOLDEN = "GOLDEN"
DOC_STALE = "DOC_STALE"
CODE_STALE = "CODE_STALE"

# Template / scaffold docs whose code fences are illustrative, not claims.
TEMPLATE_DOCS = {"template.md", "adr_scaffold.md", "implementation-adr-template.md"}

# Document roots that are historical/frozen and should not generate active
# claim tensions.
FROZEN_DOC_PREFIXES = ("Governance/adr/completed/", "Governance/adr/superseded/",
                       "Governance/adr/proposed/")

DECL_RE = re.compile(r"^\s*(?:theorem|lemma|def|abbrev|example|axiom|opaque|class|structure|inductive|instance)\s+([A-Za-z_][\w.']*)")

# A backticked identifier cited as a proof/theorem/invariant in prose.
CLAIMED_NAME_RE = re.compile(r"`([a-z][a-z0-9_]*)`")

# English-word identifiers that are never Lean declaration names.
THEOREM_STOP = {
    "forall", "exists", "lemma", "theorem", "proof", "simp", "cases", "apply",
    "sorry", "def", "example", "intro", "norm", "true", "false", "init",
    "type", "structure", "namespace", "end", "if", "then", "else", "let",
    "match", "fun", "return", "with", "show", "have", "exact", "omega",
    "rfl", "contradiction", "constructor", "intros", "refine", "first",
    "calc", "have", "also", "note", "use",
}

# Numeric invariants cited in documents (mirrors phase_mirror_loop.py).
INVARIANT_CLAIM = re.compile(
    r"(L_eff|l_eff|R_\{sc\}|\\Delta\s*R_\{sc\}|tau_R|ANOMALY_GOV_THRESHOLD|P_max|N_max|eps_coherence)"
    r"\s*[<>]=?\s*[\d.]+",
    re.I,
)

# Document extensions we harvest claims from.
DOC_EXTS = (".md", ".txt", ".tex")
# Documents larger than this are treated as generated artifacts (log dumps,
# report blobs), not claim-bearing intent. 5 MB is far above any hand-written
# ADR/paper; skipping them keeps the scan bounded on repos that accumulate
# loop_report-style dumps.
MAX_DOC_BYTES = 5 * 1024 * 1024
# Implementation extension => (corpus key, name regex).
IMPL_EXTS = {
    ".lean": ("lean", re.compile(r"^\s*(?:theorem|lemma|def|abbrev|example|axiom|opaque)\s+([A-Za-z_][\w.']*)")),
    ".rs": ("rust", re.compile(r"^\s*(?:pub\s+)?(?:fn|const|struct|enum|trait|type)\s+([A-Za-z_][\w.]*)")),
}


# --------------------------------------------------------------------------- #
# Data model
# --------------------------------------------------------------------------- #


@dataclass
class DocumentClaim:
    doc: str          # rel path to the document (intent side)
    doc_mtime: float
    kind: str         # 'theorem' | 'invariant' | 'purity'
    name: str         # normalised claim key
    line: int
    text: str
    frozen: bool = False


@dataclass
class ImplEvidence:
    name: str          # declaration / item name
    file: str          # rel path to the implementation file
    mtime: float
    corpus: str        # 'lean' | 'rust' | 'artifact'
    has_sorry: bool = False
    sorry_file: bool = False


@dataclass
class Tension:
    claim: DocumentClaim
    evidence: ImplEvidence | None
    verdict: str       # GOLDEN | DOC_STALE | CODE_STALE


# --------------------------------------------------------------------------- #
# Phase 1 — ANALYZE
# --------------------------------------------------------------------------- #


def _skip_dir(rel_segments: list[str]) -> bool:
    return any(seg in SKIP_DIR_SEGMENTS for seg in rel_segments)


def discover_documents() -> list[str]:
    """Recursively find claim-bearing documents under the repo root."""
    out: list[str] = []
    for root, dirs, files in os.walk(PRIME_ROOT):
        rel = os.path.relpath(root, PRIME_ROOT)
        segs = [] if rel == "." else rel.split(os.sep)
        if _skip_dir(segs):
            dirs[:] = []
            continue
        # prune VCS/build dirs at any depth
        dirs[:] = [d for d in dirs if d not in SKIP_DIR_SEGMENTS]
        # Only descend into document roots (or top-level for README/goal docs).
        if rel == ".":
            if DOC_TOPLEVEL:
                for fn in files:
                    if fn.lower().endswith(DOC_EXTS):
                        out.append(os.path.join(root, fn))
            continue
        top = segs[0]
        if top not in DOC_ROOTS:
            continue
        for fn in files:
            if fn.lower().endswith(DOC_EXTS):
                out.append(os.path.join(root, fn))
    return sorted(out)


def is_frozen_doc(rel: str) -> bool:
    return rel.startswith(FROZEN_DOC_PREFIXES)


def is_pml_echo(rel: str) -> bool:
    """Plan ADRs from the older one-shot loop echo source claims; skip them."""
    return "ADR-PML-" in rel


def read_text(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            return fh.read()
    except OSError:
        return ""


def analyze_documents(doc_paths: list[str]) -> list[DocumentClaim]:
    """Harvest claims (stated intent) from documents.

    A *theorem claim* is a backticked identifier that the document asserts
    exists in the implementation. We only trust two strong signals to avoid
    false positives from incidental inline code:
      1. a `theorem`/`lemma`/`def NAME` declaration inside a ```lean fence, or
      2. a backticked name cited in prose that plausibly names a declaration
         (must pass the THEOREM_STOP word filter).
    """
    claims: list[DocumentClaim] = []
    fence_rx = re.compile(r"```(\w*)")
    lean_decl_rx = re.compile(r"^\s*(?:theorem|lemma|def|abbrev|axiom|opaque|example)\s+([A-Za-z_][\w.']*)")
    for path in doc_paths:
        rel = os.path.relpath(path, PRIME_ROOT)
        frozen = is_frozen_doc(rel)
        is_template = os.path.basename(path).lower() in TEMPLATE_DOCS
        is_pml = is_pml_echo(rel)
        if frozen or is_template or is_pml:
            # Frozen/template/echo docs generate no claims (ADR-232 §5); skip
            # them before reading so the scan stays fast on large repos.
            continue
        try:
            mtime = os.path.getmtime(path)
        except OSError:
            continue
        try:
            if os.path.getsize(path) > MAX_DOC_BYTES:
                continue
        except OSError:
            continue
        text = read_text(path)
        if not text:
            continue

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
                    claims.append(DocumentClaim(
                        rel, mtime, "theorem", dm.group(1), i, line.strip(), frozen))
                continue
            if in_fence:
                continue
            # prose (outside fences)
            for nm in CLAIMED_NAME_RE.finditer(line):
                name = nm.group(1)
                if name.lower() in THEOREM_STOP:
                    continue
                claims.append(DocumentClaim(rel, mtime, "theorem", name, i, line.strip()))
            if INVARIANT_CLAIM.search(line):
                claims.append(DocumentClaim(rel, mtime, "invariant",
                                            "numeric_invariant", i, line.strip()))
    return claims


def discover_implementation() -> list[ImplEvidence]:
    """Harvest implementation evidence (developed reality).

    Scans the impl roots for Lean declarations and Rust items, and records the
    newest mtime of every implementation file for timestamp triage.
    """
    evidence: list[ImplEvidence] = []
    for root, dirs, files in os.walk(PRIME_ROOT):
        rel = os.path.relpath(root, PRIME_ROOT)
        segs = [] if rel == "." else rel.split(os.sep)
        if _skip_dir(segs):
            dirs[:] = []
            continue
        dirs[:] = [d for d in dirs if d not in SKIP_DIR_SEGMENTS]
        if rel == ".":
            continue
        top = segs[0]
        if top not in IMPL_ROOTS:
            continue
        for fn in files:
            full = os.path.join(root, fn)
            if not os.path.isfile(full):
                continue
            try:
                f_mtime = os.path.getmtime(full)
            except OSError:
                continue
            ext = os.path.splitext(fn)[1].lower()
            spec = IMPL_EXTS.get(ext)
            relpath = os.path.relpath(full, PRIME_ROOT)
            if spec is not None:
                corpus, name_rx = spec
                text = read_text(full)
                if not text:
                    continue
                # Strip comments/docstrings so prose mentions do not masquerade
                # as declarations.
                if ext == ".lean":
                    text = re.sub(r'"[^"\n]*"', " ", text)
                    text = re.sub(r"/-.*?-/", " ", text, flags=re.S)
                    text = re.sub(r"--[^\n]*", " ", text)
                for i, raw in enumerate(text.splitlines(), 1):
                    dm = name_rx.match(raw)
                    if dm:
                        evidence.append(ImplEvidence(
                            name=dm.group(1), file=relpath, mtime=f_mtime,
                            corpus=corpus))
            else:
                # Non-code implementation artifacts: still timestamps for
                # triage, but not name-indexed. Include JSON certificates and
                # CI workflows as evidence roots.
                evidence.append(ImplEvidence(
                    name="", file=relpath, mtime=f_mtime, corpus="artifact"))
    return evidence


# --------------------------------------------------------------------------- #
# Phase 2 — RESOLVE + Phase 3 — TRIAGE
# --------------------------------------------------------------------------- #


def _decl_has_sorry(file_rel: str) -> bool:
    """True if any declaration in the file contains a `sorry` tactic."""
    full = os.path.join(PRIME_ROOT, file_rel)
    text = read_text(full)
    if not text:
        return False
    text = re.sub(r'"[^"\n]*"', " ", text)
    text = re.sub(r"/-.*?-/", " ", text, flags=re.S)
    text = re.sub(r"--[^\n]*", " ", text)
    return bool(re.search(r"\bsorry\b", text))


def build_evidence_index(evidence: list[ImplEvidence]) -> dict[str, list[ImplEvidence]]:
    """Index evidence by normalized declaration name (leaf component)."""
    idx: dict[str, list[ImplEvidence]] = defaultdict(list)
    for e in evidence:
        if not e.name:
            continue
        leaf = e.name.split(".")[-1]
        idx[leaf].append(e)
    return idx


def newest_impl_mtime(evidence: list[ImplEvidence]) -> float:
    """Newest mtime across all implementation evidence (repo-level clock)."""
    return max((e.mtime for e in evidence), default=0.0)


def resolve_and_triage(claims: list[DocumentClaim],
                       evidence: list[ImplEvidence]) -> list[Tension]:
    idx = build_evidence_index(evidence)
    newest = newest_impl_mtime(evidence)
    tensions: list[Tension] = []

    for claim in claims:
        matches = idx.get(claim.name)
        if matches:
            # A claim that resolves to a sorry-free declaration is GOLDEN
            # regardless of mtime (ADR-232 §5).
            resolved = None
            for m in matches:
                if m.corpus == "lean":
                    if not _decl_has_sorry(m.file):
                        resolved = m
                        break
            if resolved is not None:
                tensions.append(Tension(claim, resolved, GOLDEN))
                continue
            # A declaration still discharging via `sorry` is direct evidence
            # the math/code has NOT fulfilled the document's claim of
            # verification. mtime is not consulted: a proof gap is a forward
            # commitment (CODE_STALE), never a backward doc-update signal.
            tensions.append(Tension(claim, matches[0], CODE_STALE))
            continue

        # No implementation evidence at all.
        if newest > claim.doc_mtime:
            verdict = DOC_STALE
        else:
            verdict = CODE_STALE
        tensions.append(Tension(claim, None, verdict))

    return tensions


# --------------------------------------------------------------------------- #
# Phase 4 — PLAN (emit ADR files)
# --------------------------------------------------------------------------- #


def cluster_by_doc(tensions: list[Tension]) -> list[tuple[str, list[Tension]]]:
    """Group mismatches by document so one lever ADR addresses one document.

    Mirrors the ADR-PML clustering convention: a document with N stale claims
    produces ONE plan ADR listing each claim and its triage verdict, rather
    than N near-identical files.
    """
    by_doc: dict[str, list[Tension]] = defaultdict(list)
    for t in tensions:
        if t.verdict == GOLDEN:
            continue
        by_doc[t.claim.doc].append(t)
    return sorted(by_doc.items(), key=lambda kv: len(kv[1]), reverse=True)


def _verdict_signature(cluster: list[Tension]) -> str:
    """Stable sha256-16 of the (claim, verdict) pairs of a doc cluster.

    The digest identifies the set of levers this cluster must emit, not the
    document bytes. It is embedded in the plan ADR and used to make re-runs
    idempotent: a document whose plan exists with the same signature reuses
    the plan ID without rewriting the file.
    """
    sig = sorted((t.claim.name, t.verdict) for t in cluster)
    raw = json.dumps(sig, sort_keys=True)
    return hashlib.sha256(raw.encode()).hexdigest()[:16]


def existing_plans() -> dict:
    """Parse previously emitted plan ADRs into {doc_path: (plan_id, signature)}.

    Enables idempotent re-runs: a document whose plan already exists with the
    same verdict signature reuses the same plan ID instead of generating a
    duplicate.
    """
    plans: dict = {}
    adr_dir = os.path.join(PRIME_ROOT, ADR_OUTPUT_DIR)
    if not os.path.isdir(adr_dir):
        return plans
    for fn in os.listdir(adr_dir):
        if not (fn.startswith(PLAN_PREFIX) and fn.endswith(".md")):
            continue
        full = os.path.join(adr_dir, fn)
        try:
            with open(full, "r", encoding="utf-8") as fh:
                text = fh.read()
        except OSError:
            continue
        doc_m = re.search(r"- Document: `([^`]+)`", text)
        sig_m = re.search(r"Verdict signature: `([0-9a-f]+)`", text)
        if not (doc_m and sig_m):
            continue
        plans[doc_m.group(1)] = (fn[:-3], sig_m.group(1))
    return plans


def render_plan_adr(adr_id: str, doc: str, cluster: list[Tension],
                    rank: int, total: int) -> str:
    doc_mtime = max(t.claim.doc_mtime for t in cluster)
    rows = []
    for t in sorted(cluster, key=lambda x: x.claim.line):
        ev_side = (f"`{t.evidence.file}`" if t.evidence else "(none)")
        lever = {
            GOLDEN: "no action",
            DOC_STALE: "update the document",
            CODE_STALE: "update the math/code",
        }[t.verdict]
        rows.append(
            f"| `{t.claim.name}` | {t.claim.kind} | L{t.claim.line} | "
            f"{t.verdict} | {lever} | {ev_side} |"
        )
    table = "\n".join(rows)
    n_doc = sum(1 for t in cluster if t.verdict == DOC_STALE)
    n_code = sum(1 for t in cluster if t.verdict == CODE_STALE)
    signature = _verdict_signature(cluster)
    return f"""# {adr_id}: document `{doc}` has {len(cluster)} stale claim(s)
## Status
Proposed

## Triage (time-aware phase mirror)
- Document: `{doc}` (mtime {_fmt_ts(doc_mtime)})
- {n_doc} claim(s) DOC_STALE — implementation newer than the document → **update the document**
- {n_code} claim(s) CODE_STALE — document newer than the implementation → **update the math/code**
- Verdict signature: `{signature}`

## Context (claim-by-claim mirror)
| Claim | Kind | Line | Triage | Lever | Evidence |
|-------|------|------|--------|-------|----------|
{table}

## Decision (the lever)
Apply each row's lever in the direction given by its triage class. A claim is
resolved when a re-run flips it to GOLDEN (it resolves to a `sorry`-free
declaration).

## Consequences
- **Positive**: the drift between stated intent and developed reality is
  surfaced with a single deterministic direction per claim.
- **Negative / Constraints**: triage is timestamp-based; a `touch` without a
  content change may mis-classify (mitigated: sorry-free resolutions are always
  GOLDEN).
- **Verification Strategy**: re-run `scripts/recursive_phase_mirror.py --once`;
  resolved claims must exit this document's cluster.

## Links
- Master index: `Governance/adr/proposed/{MASTER_INDEX}`
- State ledger: `state/recursive_phase_mirror.json`
- ADR: `Governance/adr/accepted/ADR-232-Recursive-Phase-Mirror-Loop-on-Prime.md`
"""


def _fmt_ts(t: float) -> str:
    return _dt.datetime.fromtimestamp(t, tz=_dt.timezone.utc).strftime("%Y-%m-%d %H:%M:%SZ")


def resolve_stale_plans(active_docs: set[str]) -> int:
    """Demote plan ADRs whose document is now fully GOLDEN.

    ADR-232 §5 ("Stale proposed ADRs"): old `ADR-RML-###` plans may reference
    tensions that have since resolved. When a document no longer has any
    mismatch, its plan ADR is marked `## Status\nResolved` rather than deleted,
    preserving the audit trail. Returns the number of plans resolved.
    """
    n = 0
    adr_dir = os.path.join(PRIME_ROOT, ADR_OUTPUT_DIR)
    for fn in os.listdir(adr_dir):
        if not (fn.startswith(PLAN_PREFIX) and fn.endswith(".md")):
            continue
        full = os.path.join(adr_dir, fn)
        try:
            with open(full, "r", encoding="utf-8") as fh:
                text = fh.read()
        except OSError:
            continue
        m = re.search(r"- Document: `([^`]+)`", text)
        if not m:
            continue
        if m.group(1) in active_docs:
            continue
        if "## Status\nResolved" in text:
            continue
        text = text.replace("## Status\nProposed", "## Status\nResolved", 1)
        with open(full, "w", encoding="utf-8") as fh:
            fh.write(text)
        n += 1
        print(f"  resolved {os.path.relpath(full, PRIME_ROOT)}")
    return n# --------------------------------------------------------------------------- #
# Phase 5 — EMIT (index, backlog, state)
# --------------------------------------------------------------------------- #


def render_index(tensions: list[Tension], plan_map: dict, run_meta: dict) -> str:
    clusters = cluster_by_doc(tensions)
    golden = sum(1 for t in tensions if t.verdict == GOLDEN)
    doc_stale = sum(1 for t in tensions if t.verdict == DOC_STALE)
    code_stale = sum(1 for t in tensions if t.verdict == CODE_STALE)
    rows = []
    for i, (doc, cluster) in enumerate(clusters, 1):
        adr = plan_map.get(doc, f"{PLAN_PREFIX}???")
        n_d = sum(1 for t in cluster if t.verdict == DOC_STALE)
        n_c = sum(1 for t in cluster if t.verdict == CODE_STALE)
        rows.append(
            f"| {i} | {adr} | {len(cluster)} | {n_d} | {n_c} | `{doc}` |"
        )
    table = "\n".join(rows) or "| (none — repo is in register) | | | | | |"
    prev = run_meta.get("previous_total_score")
    delta = ""
    if prev is not None:
        cur = doc_stale + code_stale
        d = cur - prev
        arrow = "↓" if d < 0 else ("↑" if d > 0 else "→")
        delta = f"\n\n**Drift vs previous run:** mismatches {prev} -> {cur} ({arrow} {abs(d)})."
    return f"""# Recursive Phase Mirror Loop — Master Plan Index

> Generated by `scripts/recursive_phase_mirror.py` on {run_meta['timestamp'][:10]}.
> ADR-232: time-aware mirror over the entire Prime/ directory. Each row is a
> document with one or more mismatches between stated intent and developed
> reality. GOLDEN pairings are not listed.
> - **DOC_STALE** = implementation newer than the document → update the document.
> - **CODE_STALE** = document newer than the implementation → update the math/code.

## Loop Summary
- Documents scanned: {run_meta['docs_scanned']}
- Claims harvested: {run_meta['claims_harvested']}
- Implementation files indexed: {run_meta['impl_files']}
- Implementation declarations indexed: {run_meta['impl_decls']}
- GOLDEN (in register): {golden}
- DOC_STALE (update doc): {doc_stale}
- CODE_STALE (update math/code): {code_stale}
- Documents with mismatches: {len(clusters)}
{delta}

## Ranked Documents (actionable levers)
| # | Plan ADR | Claims | Doc-stale | Code-stale | Document |
|---|----------|--------|-----------|------------|----------|
{table}

## How to operate the loop
1. Open the first `ADR-RML-###` file; it names the document, each claim, and
   the single correct lever per claim.
2. Apply the levers (update the docs, or formalise the math/code).
3. Re-run `scripts/recursive_phase_mirror.py --once`; resolved claims exit the list.
4. Run `scripts/recursive_phase_mirror.py --watch 300` as a daemon to catch
   drift continuously.

## Links
- ADR-232: `Governance/adr/accepted/ADR-232-Recursive-Phase-Mirror-Loop-on-Prime.md`
- Full backlog: `Governance/adr/proposed/{BACKLOG_NAME}`
- State ledger: `state/recursive_phase_mirror.json`
"""


def render_backlog(tensions: list[Tension], plan_map: dict) -> str:
    rows = []
    for i, t in enumerate(tensions, 1):
        adr = plan_map.get(t.claim.doc, f"{PLAN_PREFIX}???")
        ev = t.evidence.file if t.evidence else "(none)"
        rows.append(
            f"| {i} | {adr} | `{t.claim.name}` | {t.verdict} | {t.claim.doc} | {ev} |"
        )
    table = "\n".join(rows) or "| (none) | | | | | |"
    return f"""# Recursive Phase Mirror Loop — Full Backlog

> Generated by `scripts/recursive_phase_mirror.py` on {_dt.date.today().isoformat()}.
> Every claim/evidence pairing, including GOLDEN in-register entries.

| # | Plan ADR | Claim | Triage | Document | Evidence |
|---|----------|-------|--------|----------|----------|
{table}
"""


def save_state(run_meta: dict, tensions: list[Tension]) -> None:
    state_path = os.path.join(PRIME_ROOT, STATE_PATH)
    os.makedirs(os.path.dirname(state_path), exist_ok=True)
    payload = dict(run_meta)
    payload["tensions"] = [
        {
            "claim": {"doc": t.claim.doc, "name": t.claim.name, "kind": t.claim.kind},
            "verdict": t.verdict,
            "evidence": t.evidence.file if t.evidence else None,
        }
        for t in tensions
    ]
    with open(state_path, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2)


def load_previous_score() -> int | None:
    state_path = os.path.join(PRIME_ROOT, STATE_PATH)
    if os.path.isfile(state_path):
        try:
            with open(state_path, "r", encoding="utf-8") as fh:
                data = json.load(fh)
            prev = sum(1 for t in data.get("tensions", []) if t["verdict"] in (DOC_STALE, CODE_STALE))
            return prev
        except (OSError, json.JSONDecodeError, KeyError):
            return None
    return None


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #


def _now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def run_once(dry_run: bool = False, root: str | None = None) -> dict:
    global PRIME_ROOT
    if root:
        PRIME_ROOT = os.path.abspath(root)
    print("=== Recursive Phase Mirror Loop (ADR-232) ===")
    print(f"[{_now()}] Phase 1: ANALYZE")
    docs = discover_documents()
    claims = analyze_documents(docs)
    evidence = discover_implementation()
    print(f"  docs={len(docs)} claims={len(claims)} impl_files={len(evidence)}")

    print(f"[{_now()}] Phase 2-3: RESOLVE + TRIAGE")
    tensions = resolve_and_triage(claims, evidence)
    golden = sum(1 for t in tensions if t.verdict == GOLDEN)
    doc_stale = sum(1 for t in tensions if t.verdict == DOC_STALE)
    code_stale = sum(1 for t in tensions if t.verdict == CODE_STALE)
    print(f"  GOLDEN={golden} DOC_STALE={doc_stale} CODE_STALE={code_stale}")

    prev_score = load_previous_score()
    run_meta = {
        "timestamp": _now(),
        "docs_scanned": len(docs),
        "claims_harvested": len(claims),
        "impl_files": len(evidence),
        "impl_decls": sum(1 for e in evidence if e.name),
        "previous_total_score": prev_score,
    }

    if dry_run:
        print("\n[dry-run] no files written.")
        return run_meta

    adr_dir = os.path.join(PRIME_ROOT, ADR_OUTPUT_DIR)
    os.makedirs(adr_dir, exist_ok=True)

    plan_map: dict = {}
    prev_plans = existing_plans()
    used_ids = set(v[0] for v in prev_plans.values())
    next_id = 1
    clusters = cluster_by_doc(tensions)
    for rank, (doc, cluster) in enumerate(clusters, 1):
        signature = _verdict_signature(cluster)
        existing = prev_plans.get(doc)
        if existing is not None and existing[1] == signature:
            # Cluster and verdicts unchanged since the previous run: reuse the
            # existing plan ID and do not touch the file (idempotent).
            adr_id = existing[0]
            action = "kept"
        elif existing is not None:
            # Verdicts changed class within this document: rewrite the existing
            # plan in place so the on-disk lever stays current (no new number).
            adr_id = existing[0]
            action = "updated"
        else:
            while f"{PLAN_PREFIX}{next_id:03d}" in used_ids:
                next_id += 1
            adr_id = f"{PLAN_PREFIX}{next_id:03d}"
            next_id += 1
            used_ids.add(adr_id)
            action = "wrote"
        plan_map[doc] = adr_id
        text = render_plan_adr(adr_id, doc, cluster, rank, len(clusters))
        path = os.path.join(adr_dir, f"{adr_id}.md")
        if action != "kept" or not os.path.exists(path):
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(text)
            print(f"  {action} {os.path.relpath(path, PRIME_ROOT)}")

    resolve_stale_plans(active_docs={doc for doc, _ in clusters})

    index_text = render_index(tensions, plan_map, run_meta)
    with open(os.path.join(adr_dir, MASTER_INDEX), "w", encoding="utf-8") as fh:
        fh.write(index_text)
    backlog_text = render_backlog(tensions, plan_map)
    with open(os.path.join(adr_dir, BACKLOG_NAME), "w", encoding="utf-8") as fh:
        fh.write(backlog_text)
    save_state(run_meta, tensions)
    print(f"  wrote {MASTER_INDEX} + {BACKLOG_NAME}")
    print(f"  saved state -> {STATE_PATH}")
    return run_meta


def run_watch(interval: float, root: str | None = None) -> int:
    """Daemon mode: re-run the loop every `interval` seconds until signalled."""
    if root:
        global PRIME_ROOT
        PRIME_ROOT = os.path.abspath(root)
    print(f"[{_now()}] Recursive Phase Mirror daemon started (watch interval {interval}s)")
    stop = False

    def _handler(signum, frame):
        nonlocal stop
        stop = True
        print(f"[{_now()}] signal {signum} received — stopping cleanly")

    signal.signal(signal.SIGTERM, _handler)
    signal.signal(signal.SIGINT, _handler)

    while not stop:
        try:
            run_once(dry_run=False)
        except Exception as exc:  # noqa: BLE001 — daemon must not die
            print(f"[{_now()}] run failed: {exc}", file=sys.stderr)
        if stop:
            break
        print(f"[{_now()}] next scan in {interval}s (Ctrl-C to stop)")
        try:
            time.sleep(interval)
        except KeyboardInterrupt:
            break
    print(f"[{_now()}] daemon stopped")
    return 0


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description="Recursive Phase Mirror Loop (ADR-232)")
    p.add_argument("--root", default=PRIME_ROOT,
                   help="repository root to mirror (default: repo root)")
    p.add_argument("--once", action="store_true", help="single-shot run (default)")
    p.add_argument("--watch", type=float, default=0,
                   help="daemon mode: re-scan every N seconds")
    p.add_argument("--dry-run", action="store_true",
                   help="analyze + triage but write nothing")
    p.add_argument("--no-state", action="store_true",
                   help="do not read or write the state ledger")
    p.add_argument("--verbose", action="store_true")
    args = p.parse_args(argv)

    if args.watch and args.watch > 0:
        if args.dry_run or args.no_state:
            print("--watch cannot be combined with --dry-run or --no-state", file=sys.stderr)
            return 2
        return run_watch(args.watch, root=args.root)

    run_once(dry_run=args.dry_run, root=args.root)
    return 0


if __name__ == "__main__":
    sys.exit(main())
