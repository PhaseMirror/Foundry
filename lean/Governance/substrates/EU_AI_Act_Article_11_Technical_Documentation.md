# EU AI Act – Article 11 Technical Documentation
**High-Risk AI System: F1Square Governance-by-Design Module**  
**(Zeta-Schrödinger Dynamics – H_ZSD + Drift Audit)**

**Version**  
0.9.0-draft (post GeneticFidelity type fixes – 2026-06-22)

**Provider**  
Ryan O. Van Gelder / Citizen Gardens (501(c)(3)) / Multiplicity Foundation  
189 Private Dr. 123, Crown City, Ohio 45623  
ryvngldr@gmail.com

**System**  
F1Square Governance Substrate v0.9.0  
Components: `DriftAudit.lean` (H_ZSD specs + explicit Art. 11/12 mappings),  
`GeneticFidelity.lean` (ContractivityReceipt + Tropical hooks – now type-correct),  
core `F1Square.lean`, Analysis substrate (ExactBounded, constructive ℝ/exp/ζ, Li boundary),  
Tropical/Characteristic-1 stack (R1–R16, honesty-audited).

**Intended Purpose**  
Governance, drift detection, contractivity certification and fidelity-auditing layer for formal mathematical research platforms and precision decision-support tools (INTRINSICA, EchoMirror-HQ, H-Calculator, Master Primatician Λₘ interfaces). Provides machine-checked traceability, viability kernels and contraction receipts. Research / internal governance tooling; external high-risk use requires separate conformity assessment.

**Classification**  
High-risk (supporting safety-critical or rights-impacting decisions) with clear scoping to limited-risk for pure internal formal-math research.

## 1. General Description (Art. 11(1)(a))
The module embeds **Zeta-Schrödinger Dynamics (H_ZSD)** as the core dynamical model for drift in formal artefacts. It supplies:
- Tropical content-address κ (permutation-invariant canonical form).
- `ContractivityReceipt` structures (dualCertified ∧ totalDriftBound – now correctly typed).
- Genetic fidelity hooks witnessing invariance (R3) while separating representation from property (R9/R10).
- Honest `F1SquareStatus` roll-up (`some true` vs `none` for the open Hodge-index crux).
- Self-enforcing honesty audit (`scripts/honesty_audit.sh`) – only {propext, Classical.choice, Quot.sound} axioms permitted.

Governance-by-design: every critical artefact carries independently re-verifiable machine-checked evidence.

## 2. Architecture & Development Process (Art. 11(1)(b))
**Modular stack** (wired into `F1Square.lean`):  
Core F1Square ← Governance (`DriftAudit.lean` + `GeneticFidelity.lean`) ← Analysis bricks (Bishop ℝ, completeness, exp, ExactBounded ζ, Li boundary) ← Tropical/Characteristic-1 verified layer (R1–R16).

**Quality controls**  
- All load-bearing claims kernel-checked or explicitly marked open.  
- Pinned Lean 4 v4.16.0 + UOR-Framework v0.5.2.  
- CI gate: `lake build && ./scripts/honesty_audit.sh`.  
- Reproducibility & provenance via lake-manifest, git, Zenodo-ready CITATION.cff.

## 3. Data Used (Art. 11(1)(c))
No classical ML training data. Mathematical objects formalised in Lean (prime-indexed operators, ExactBounded ζ(s) for integer s ≥ 2, tropical weighted graphs, regular sequences, cached zeta zeros for spot-checks). All artefacts content-addressed (κ) or exact-bounded (width 2/(n+1)). Provenance cryptographic (Lean kernel + git). R9/R10 result used as formal guard against representation determinism.

## 4. Functioning & Logic (Art. 11(1)(d)–(e))
**H_ZSD + Receipts**  
Drift modelled as Schrödinger-like evolution coupling analytic (zeta/explicit-formula) and geometric (intersection/Hodge) sides. Contractivity/viability witnessed by `ContractivityReceipt` whose `valid` field is a kernel-checked proof of the conjunction. Tropical hooks supply permutation-invariant canonical forms while preserving the κ ⊥ spectrum separation. Li-positive boundary and exact-bounded objects anchor analytic robustness. Open status of the Hodge-index crux is carried explicitly and never asserted as proven.

**Human Oversight (Art. 14)**  
Phase Mirror role architecture + Master Primatician Λₘ patterns. No autonomous orchestrator. Every decision touching an open `none` field or receipt requires human review. Receipts are rejectable by human auditors.

**Robustness / Accuracy / Cybersecurity (Art. 15)**  
Robustness via uniform contraction lemmas, viability kernels, Bishop regularity (modulus carried in data, choice-free), honesty audit. Accuracy via exact-bounded reals, rigorous rational tail bounds, Archimedean lemmas, finite-check guards on Li positivity. Cybersecurity via sandboxed builds, pinned deps, axiom audit, content-addressing for artefact integrity.

## 5. Record-Keeping / Logging (Art. 12) – Mapping from DriftAudit.lean
`DriftAudit.lean` encodes:
- Automatic logging of every drift-audit event, receipt generation, gate evaluation (timestamp, artefact κ, gate conditions, result).
- Full traceability to the exact Lean theorem/receipt that witnessed the outcome.
- Human-readable + machine-verifiable export (`ContractivityReceipt` structure = canonical log entry).
- Retention & integrity via content-addressing + git (+ optional provenance layer).
- No circumvention: honesty_audit CI gate blocks unaudited bypasses.

Full H_ZSD ↔ Art. 11/12 obligation mapping tables live inside `DriftAudit.lean`.

## 6. Risk Management (Art. 9)
Integrated with Phase Mirror / Multiplicity governance stack.  
Key risks & mitigations: over-claiming open results (explicit `none` flags + honesty audit), IP/provenance issues (MNDA carve-outs, defensive pubs, Greenberg Traurig trail), model drift (H_ZSD + receipts + periodic re-verification), misuse in safety-critical pipelines (explicit scoping + mandatory human oversight on open fields). Residual risk (Hodge-index positivity on 𝕊) is declared open and deployment relying on it as proven is forbidden by formal status.

## 7. Instructions for Use & Update Procedure
**Build & Verify**  
```sh
lake update && lake build && ./scripts/honesty_audit.sh
```

**Generating / Interpreting Receipts**  
See examples in `DriftAudit.lean`. Only `some true` fields or inhabited `valid` proofs may be treated as established.

**Integration**  
Governance layer must be consulted on every critical path for INTRINSICA / EchoMirror-HQ / H-Calculator etc. Receipts logged and retained per applicable regulation (MDR/IVDR/EU AI Act).

**Change Control**  
Any proof-layer modification triggers full re-audit. SemVer bump + CHANGELOG + template update required before release.

## 8. Conformity Assessment
This document + the machine-checked Lean artefacts (`F1Square.lean`, `DriftAudit.lean`, fixed `GeneticFidelity.lean`, honesty_audit gate, pinned manifest, verified tropical/analytic substrate) constitute the Article 11 technical documentation. The system supports (never replaces) human expert judgment in formal mathematics and precision domains.

Full conformity assessment under EU AI Act (and MDR/IVDR if reclassified) will be completed prior to any external high-risk deployment.

**Declaration of Conformity** (post-assessment placeholder)  
[To be signed]

**Regulatory Contact**  
ryvngldr@gmail.com

---
*Template aligned with F1Square v0.9.0 epistemic conventions and the explicit Art. 11/12 mappings in DriftAudit.lean. Rigorous Lean verification is treated as a primary control for accuracy, robustness, traceability and non-discrimination.*
