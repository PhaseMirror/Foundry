# ADR-0019: Technology Portfolio — Evidence, Risk, and Feasibility

**Status:** Accepted

## Context
The Foundation's technology claims must be recut to what public sources actually support. The evidence cut (10 September 2026) reconciles a prior management inventory of 19 assets against a GitHub search result of 15 public repositories, classifies each asset, and grades visible external evidence on the E0–E6 scale. The gap between internal claims and externally verifiable evidence is the standing risk.

## Decision
Adopt the Technology Portfolio Evidence, Risk, and Feasibility Appendix as the canonical evidence recut.

- **Evidence method.** Observe (record what public artifacts currently state); Map (classify authority, maturity, dependencies, and evidence); Interface (define the smallest decision or test that raises confidence).
- **Portfolio register.** Every asset is classified against the evidence classes — Normative, Reference, Experimental, Historical — with authority and dependency notes. Concrete conformance artifacts are cited in the register (e.g., UOR-Framework's 361 tests, 20 demos, 19,074 Unicode vectors across 5 identities with Rust/JS/Python/C/WASM surfaces; NANDA DataFacts structural addressing with 14 namespaces, 82 classes, 120 properties, Apache-2.0).
- **Maturity rating.** Technology is substantive and broad; the operating system around it is immature. Reconciling inventory: 19 assets listed by management vs 15 public repositories found; every discrepancy is dispositioned, not hand-waved.
- **Evidence grading.** External evidence is graded E0–E6 with cited dates and owners. Findings: the strongest visible external-facing evidence is E2; a Foundation-authored adapter, benchmark, or upstream issue is not the same as upstream evaluation, independent conformance, or adoption. No public E4–E6 evidence exists; claims at E3 or above require attestation per the evidence policy.
- **Feasibility.** Conditional-go on a narrow baseline only. Required work items carry effort cards (e.g., 20 h / 40 h classes) with owners, so ratification is tied to a real capacity envelope.
- **Priorities, in order.** (1) Correct public truth — fix what the repo and docs publicly claim; (2) ratify authority — name who decides; (3) verify stewardship — evidence owners on the record; (4) one independent implementation — at least one external conformance run, not Foundation-authored.

## Consequences
* Public claims are downgraded to E0–E2 until independently evidenced; the appendix is the binding recut.
* The 19-vs-15 inventory deltas become action items with owners rather than silent discrepancies.
* Scope is deliberately narrow: ratification buys the four priorities, not the full research portfolio.
* UAC-type research claims are explicitly excluded from feasibility scope until partner queues and classical baselines exist.

## Traceability & Artifact Links
* **[Source File]** `docs/papers/UOR_Final_Technology_Portfolio_Evidence_Risk_and_Feasibility_Appendix.docx` — "UOR Foundation Reinitialization: Technology Portfolio, Evidence, Risk and Feasibility Appendix" (evidence cut 10 September 2026).
* **[Related ADR]** ADR-0018 — the decision brief that ratifies this evidence recut.
* **[Related ADR]** ADR-0017 — external validation workstream consuming the E0–E6 grades.
* **[Related ADR]** `ADR-010.md` — proof-debt policy aligned with the E0–E6 evidence grades.