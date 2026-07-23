# ADR-PML-073: Proposed ADRs Misclassified as Academic Papers — ADR-120, ADR-121 have zero ADR structure

## Status
Accepted
Proposed

## Axis
urgency vs capacity

## Owner
`the-publisher`

## Dissonance Score
- Impact = severity (3) x blast radius (1) = **3**
- Tractability = **4.0**
- **Score = 12.0**

## Context
`Prime/docs/adr/proposed/` contains two files:
- `ADR-120-PIRTM_UMC.md`
- `ADR-121-Coupled_Harmonic_Oscillators.md`

Both are LaTeX academic papers (744 lines and 166 lines respectively) with:
- `\documentclass{article}`, `\usepackage{...}`, `\begin{document}`
- `\maketitle`, `\section{Introduction}`, `\begin{abstract}`
- Zero ADR sections (`## Status`, `## Context`, `## Decision`, `## Consequences`).

They are stored in `proposed/` but cannot be validated by `ValidADR` because
they are not ADR Records — they are publications. The formal ADR model requires
that every accepted ADR have a reconstructible history; academic papers lack the
structured metadata needed for traceability.

### Manifested boundary
Leaked (unmanifested): YES — non-ADR artifacts occupy the proposed namespace,
polluting the gap-detection and coverage signals of the dissonance loop.

## Decision
Reclassify `ADR-120` and `ADR-121` from `proposed/` to `publications/` or
`papers/`, and create proper ADR proposals that *reference* the papers if the
decisions they document are architectural. If the papers are purely prior-art
defensive publications with no architectural decision, they should never have
been placed in `docs/adr/`.

## Consequences
- **Positive**: `proposed/` contains only valid ADR candidates; the dissonance
  loop's coverage and gap metrics become accurate.
- **Negative / Constraints**: moving files breaks relative links in existing
  ADRs that reference `ADR-120` by path.
- **Verification Strategy**: `phase_mirror_loop.py` should skip markdown files
  that contain `\begin{document}` rather than `## Status`.

## Metrics (resolution is confirmed when)
- `proposed/` contains only files with valid ADR frontmatter (`## Status`,
  `## Context`, `## Decision`, `## Consequences`).
- `phase_mirror_loop.py` skips LaTeX papers during ADR harvesting.
- `lake test` passes the `adr_test` integration that checks `proposed/`
  directory conformance.

## Actionable Levers
1. Move `ADR-120-PIRTM_UMC.md` and `ADR-121-Coupled_Harmonic_Oscillators.md`
   to `docs/publications/`.
2. Add a LaTeX-content skip heuristic to `phase_mirror_loop.py:224`
   (`analyze_docs`).
3. If the decisions merit ADRs, create replacement ADRs with proper structure
   that cite the papers as supporting documents.
4. Re-run `phase_mirror_loop.py`; proposed-ADR gap metrics should realign.

## Links
- Misclassified files: `Prime/docs/adr/proposed/ADR-120-PIRTM_UMC.md`
- Misclassified files: `Prime/docs/adr/proposed/ADR-121-Coupled_Harmonic_Oscillators.md`
- Loop scanner: `Prime/scripts/phase_mirror_loop.py:224`
