# ADR-101: Characteristic-1 Substrate Foundation

## Status
Accepted (v0.15.0–v0.17.0 shipped)

## Context
The F1-Square program requires a verified base over characteristic 1 (idempotent / max-plus arithmetic `ℝ_max`) before any surface construction can be attempted. Without a clean, mechanized substrate, every subsequent claim (intersection pairing, Hodge index, explicit formula trace) rests on unverified foundations.

## Decision
Adopt the **characteristic-1 substrate** as the immutable base layer for all F1-Square work:

1. **Semifield `ℝ_max`.** `(ℝ ∪ {−∞}, ⊕ = max, ⊗ = +)` with idempotence `x ⊕ x = x`. Verified as semifield in `Prime/characteristic_1_constructions.md` (R1).
2. **Tropical content-address `κ`.** The order-independent canonical invariant `κ(W) = sorted multiset of finite off-diagonal entries of W*` (Kleene star `W* = I ⊕ W ⊕ W^{⊗2} ⊕ …`). Permutation invariance: `κ(σ·W) = κ(W)` (R2–R3).
3. **Cycle-mean spectrum.** Multiset of simple-cycle means under max-plus multiplication; dominant value = max cycle mean (Karp/Perron). Verified on stable-regime example graph (R4).
4. **Prime-cycle Euler product.** Verified factorization of the dynamical zeta via cycle means; zero-temperature bridge from classical transfer operator to tropical eigenvalue (R5–R6, R7–R8 numerical).
5. **κ-spectrum independence (the headline).** `κ` does **not** determine the spectrum — a finite, decidable, Lean-checked theorem (R9). Over ℝ this would be an open question; over `ℝ_max` it is a computation with a definite answer: **no**.
6. **Full resolution (R13–R16).** κ-fiber is a mappable poset; reversal symmetry is a theorem; tropical intersection-positivity is automatic; κ and spectrum are mutually independent complementary coordinates.
7. **Analysis substrate.** Exact ℚ (ordered field), reflective ℤ ring normalizer + `ring_uor` tactic, constructive ℝ as Bishop regular sequences, ℂ ≠ ℝ×ℝ (commutative ring up to ≈), Cauchy completeness, order ≤, and the transcendentals arc (e, exp(q) on [0,1], exp on ℝ). All axiom-clean `{propext, Quot.sound}`.

## Consequences
- All subsequent F1-Square constructions (`Square/`, `Analysis/`) build on this substrate.
- `κ` serves as the content-addressing layer for MAP objects and the gap tensor; it is a genuine structural factor in characteristic 1, not a metaphor.
- The independence result (`κ` ⊥ spectrum) is the decidable characteristic-1 counterpart of the open ℚ-question "does representation determine property?"
- No `sorry`, no Mathlib, no `native_decide` — pure Lean 4 core only.

## References
- `Prime/characteristic_1_constructions.md`
- `docs/adr/ADR-001-Combined-Mandate.md`
- `Governance/GeneticFidelity.lean`
