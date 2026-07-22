# ADR-103: T3 Intersection Harness & Candidate Testing

## Status
Accepted (v0.18.0–v0.22.0 in progress)

## Context
Ad-hoc Gram matrices and magnitude-bounding approaches were ruled out as low-leverage dead-ends. The F1-Square program requires a **decidable, machine-checked filter** that any candidate surface construction must pass before it can be considered a valid `𝔽₁`-square. The T3 rung (intersection pairing reproducing boundary numbers) is the precise gate: a finite truncation whose intersection matrix must exhibit signature `(1, ρ−1)` on the primitive complement.

## Decision
Deploy a **T3 candidate testing harness** as the mandatory gate for all surface proposals:

1. **Lattice basis.** For a finite prime set `P = {p₁, …, p_n}`, define distinguished divisor classes:
   - Horizontal rulings `H_i` (one per prime).
   - Vertical rulings `V_i` (one per prime).
   - Diagonal `Δ`.
   - Scaling graphs `Γ_i` (Frobenius action, shift lengths `Λ(p) = log p`).
2. **Intersection relations (sourced from function-field template).**
   - `⟨H_i, H_j⟩ = 0`, `⟨V_i, V_j⟩ = 0`.
   - `⟨H_i, V_j⟩ = δ_{ij}`.
   - `⟨H_i, Δ⟩ = 1`, `⟨V_i, Δ⟩ = 1`.
   - `⟨Δ, Δ⟩ = d` (self-intersection parameter).
   - `Γ_i` intersections derived from explicit-formula trace parameters.
3. **Signature theorem.** The full `(3n+1)`-dimensional space has signature `(1, 3n)`. The Hodge index corollary: negative-definiteness on `H^⊥` (signature `(0, 3n)`) assuming `H^2 > 0` for ample class `H = Σ H_i + Σ V_i`.
4. **Lean implementation.** `Square/IntersectionTemplate.lean` + `Square/Pencil.lean` + `Square/Polarized.lean` implement the computable matrix and signature proof. `DeitmarTest.lean` provides the decidable `DeitmarTest N` predicate.
5. **Numerical probe.** 17-prime truncation (`P = [2,3,5,7,11,13,17]`) yields signature `(1, 1, 13)` on basis `{F_h, F_v, Δ}` — one positive eigenvalue, remainder negative, consistent with Hodge-index template.
6. **Build integrity.** Full F1Square package builds (16 jobs), zero-sorry for core conditional proof.

## Consequences
- Any candidate `𝔽₁`-square can be **mechanically falsified** by instantiating `DeitmarTest N`.
- Failed candidates produce explicit obstruction signatures, not vague "doesn't look right."
- The harness decouples candidate exploration from the analytic/geometric proof layer.
- Finite truncations (increasing `N`) provide a falsifiable path toward the infinite surface — each step is a theorem.

## References
- `Prime/F1-Square T3 Harness Milestone.md`
- `Prime/F1 Substrate + Multiplicity_RH Narrative (1).md`
- `Prime/Formal F1-Square Conditional Riemann Proof.md`
- `Prime/f1_square_intersection_theory.md`
- `docs/adr/ADR-013-F1-Square-Signature-Check.md`
- `docs/adr/ADR-100-Conditional-Proof-Scaffold.md`
