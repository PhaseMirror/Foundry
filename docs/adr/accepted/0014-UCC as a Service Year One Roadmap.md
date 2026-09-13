# ADR-0014: UCC as a Service — Year One Roadmap

**Status:** Accepted

## Context
The year-one window (2 September 2026 – 2 September 2027) needs an operator product that is lawful, deliverable, and free of unimplemented research claims. UAC chemistry (FeMoco, 100-way MA-VQE, 69-qubit concurrency) remains research-path until a partner queue exists. A caller submits a partial system; the only honest answer is a lawful closure, a named defect if composition is unlawful, a versioned receipt, and levers — not a vibe, not a proof of the Riemann Hypothesis, not a diploma. The kernel's credibility depends on never claiming lawfulness it has not been proven to hold.

## Decision
Adopt the Universal Closure Calculator (UCC) as a hosted kernel service for year one.

- **Four artifacts, every call.** Closure — completed relation under lawful composition (Dirichlet / union-find kernel). Defect — Δ = 0 or Δ named in English a node can act on. Receipt — input hash + kernel version + Lean/Kani build id + timestamp (optional attestation later). Levers — `[Owner] — action — metric — horizon` when Δ ≠ 0.
- **Non-goals.** No FeMoco / 100-way MA-VQE / 69-qubit product (UAC waits on a partner). No "UCC proves RH" claims; the SLA is kernel version, latency, and receipt integrity; lawfulness ⇔ Li ⇔ RH stays in the paper. The kernel is not on the UNA balance sheet — the operator hosts, the UNA holds the literary definition and receives remittance. No PMCP issuance for seats or equity. No neutral-atom array purchase.
- **Two civic closure objects before any outside customer.** (1) A Civic R&D spend over $2,500; (2) a credit exchange against Governing Principles §6.4 caps. If they fail, there is no service.
- **Layers versus quarters.** Public spec of the sextuple surface `(X, ∘, α, μ, F, Δ)` as an input schema (one page + example JSON); Rust completion kernel + Kani harness green on lawfulness (the kernel never adds an unlawful composition); physics/Rydberg limited to an optional calibration adapter (one documented analog job or a written deferral); EVM attestation receipt-first (off-chain signed receipt in Q2, testnet attest only if a paying user asks); the intertwiner/Multiplicity layer embeds 2R+1 and §6.4 credit caps as a closure class.
- **Kill-switches.** Refuse a wire that requires "we proved RH." Halt the API if Kani adds an unlawful composition. Halt cert talk (not necessarily the kernel) if equity skips PMCP gates. Stop cloud QPU jobs above the labeled calibration cap. A gift to the UNA does not convert into UCC seats.
- **Named tensions, bound.** Beautiful math vs callable product (two civic objects close first); RH paper vs SLA; UAC hunger vs UCC focus (UAC is research-path until a partner queue exists); open core vs hosted oracle (Lean public or embargoed in writing; kernel is licensed); operator yield vs garden purpose (remittance labeled remittance).

## Consequences
* Year-one priority is receipts that change decisions, not revenue; no hardware round is forecast; a Pro seat may exist.
* Budget range $40k (low) / $180k (plausible); treasuries are not mixed; Q0 opens with a dual-control $2,500 envelope.
* SKU line: Community (self-host core, no receipt, no managed-service right), Pro (hosted `/close`, receipt, audit log), Enterprise (only if a paying caller funds isolation up front), PMCP (may call Pro; may not grant or revoke the kernel; revenue share on branded delivered work).
* Quarter exit gates: Q0 — a local CLI closes a toy system and prints Δ in English; Q1 — both civic objects produce stored receipts with a labeled remittance line; Q2 — 10 closures that are not self-tests and one written defect that changed a real decision; Q3 — a stranger calls the API from the public spec without a founder on the call; Q4 — a public year-one card a hostile reader would still accept.
* Precision left open: whether the first outside caller is a Civic R&D peer, a PMCP candidate, or an operator subscriber must be picked before Q2 cash; the API does not change.

## Traceability & Artifact Links
* **[Source File]** `docs/papers/UCC_Year_One_Roadmap.docx` — Citizen Gardens, "UCC as a Service — Year One Roadmap" (LawfulRecursionVersion 1.0; companion to Unified Civic Infrastructure Outline v1.1 and the Universal Closure Calculator).
* **[Related ADR]** `0013-UOR Civic Infrastructure.md` — governing civic model this product plan operationalizes.
* **[Related ADR]** ADR-0021 — prime-indexed lawful composition the closure kernel implements.
* **[Source File]** `lean/MTPI/ADR0013.lean` — canonical BCS serialization and PWEH integrity substrate underlying receipt integrity.