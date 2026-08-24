/-
F1 square — **the pre-Hilbert layer, brick 4** (`StableInner.lean`): the `N → ∞` passage for the
finitely-supported space — the truncated forms STABILIZE, so the inner product and the Weil
pairing are genuine numbers on the space, not truncation families.

`FinSupp f B` says the family vanishes from `B` on. Then:

- `RsumN_stable` / `innerN_stable` — past the support bound the truncated sums and inner products
  stop moving: `⟨f,g⟩_N ≈ ⟨f,g⟩_B` for every `N ≥ B`. The direct limit is ATTAINED, not
  approached: `innerN_welldef` makes `⟨f,g⟩` well-defined on the finitely-supported space
  (any two truncations past the bound agree up to `≈`).
- `weilQuad_stable` / `weilQuad_welldef` — the same passage for the quadratic form: for a
  finitely-supported test family the Weil pairing `weilQuad M c N` is constant (up to `≈`) in
  `N ≥ B`. The `∀ N` quantifier of `WeilPSD` — the direct-limit reading — collapses to a single
  value on each finitely-supported test.
- `FinSupp_bandProj` — the band projection preserves finite support: the projection operator of
  brick 3 acts ON the space.

WHY (the Sonine route, step 3). The layer lacked "the `N → ∞` passage (completeness/limits of the
truncated forms)". For the DENSE subspace every discrete Sonine statement actually quantifies over
— finitely-supported test families — the passage is stabilization, and this brick proves it. What
remains of the axis is genuine completeness (Cauchy families with a modulus, the Bishop route) and
the L² objects over the certified integral.

HONEST SCOPE. Stabilization on the finitely-supported subspace only; no completion is constructed,
no claim that the pairing extends past finite support. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.Projection

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Finite support**: the family vanishes (up to `≈`) from `B` on. -/
def FinSupp (f : Nat → Real) (B : Nat) : Prop :=
  ∀ i, B ≤ i → Req (f i) zero

/-- **Stabilization of finite sums**: if the terms vanish from `B` on, the sum stops moving —
    `Σ_{i<N} F ≈ Σ_{i<B} F` for every `N ≥ B`. -/
theorem RsumN_stable {F : Nat → Real} {B : Nat} (h : ∀ i, B ≤ i → Req (F i) zero)
    {N : Nat} (hBN : B ≤ N) : Req (RsumN F N) (RsumN F B) := by
  induction hBN with
  | refl => exact Req_refl _
  | step hm ih => exact Req_trans (Radd_congr ih (h _ hm)) (Radd_zero _)

/-- A vanishing left factor kills the product. -/
private theorem Rmul_zero_left_of {x : Real} (h : Req x zero) (y : Real) :
    Req (Rmul x y) zero :=
  Req_trans (Rmul_congr h (Req_refl y)) (Req_trans (Rmul_comm zero y) (Rmul_zero y))

/-- **Stabilization of the inner product**: `⟨f,g⟩_N ≈ ⟨f,g⟩_B` for `N ≥ B` when `f` is
    supported below `B`. -/
theorem innerN_stable {f : Nat → Real} {B : Nat} (hf : FinSupp f B) (g : Nat → Real)
    {N : Nat} (hBN : B ≤ N) : Req (innerN f g N) (innerN f g B) :=
  RsumN_stable (fun i hi => Rmul_zero_left_of (hf i hi) (g i)) hBN

/-- **The inner product is well-defined on the finitely-supported space**: any two truncations
    past the support bound agree — the `N → ∞` limit is ATTAINED. -/
theorem innerN_welldef {f : Nat → Real} {B : Nat} (hf : FinSupp f B) (g : Nat → Real)
    {N N' : Nat} (hN : B ≤ N) (hN' : B ≤ N') : Req (innerN f g N) (innerN f g N') :=
  Req_trans (innerN_stable hf g hN) (Req_symm (innerN_stable hf g hN'))

/-- **Stabilization of the Weil quadratic form**: for a finitely-supported test family the
    pairing `weilQuad M c N` stops moving past the support bound — both summation levels
    collapse through the vanishing coefficients. -/
theorem weilQuad_stable {c : Nat → Real} {B : Nat} (hc : FinSupp c B)
    (M : Nat → Nat → Real) {N : Nat} (hBN : B ≤ N) :
    Req (weilQuad M c N) (weilQuad M c B) := by
  have hinner : ∀ i, Req (RsumN (fun j => Rmul (c i) (Rmul (c j) (M i j))) N)
      (RsumN (fun j => Rmul (c i) (Rmul (c j) (M i j))) B) := by
    intro i
    refine RsumN_stable (fun j hj => ?_) hBN
    exact Req_trans (Rmul_congr (Req_refl (c i)) (Rmul_zero_left_of (hc j hj) (M i j)))
      (Rmul_zero (c i))
  refine Req_trans (RsumN_congr N (fun i _ => hinner i)) ?_
  refine RsumN_stable (fun i hi => ?_) hBN
  exact RsumN_zero B (fun j _ => Rmul_zero_left_of (hc i hi) (Rmul (c j) (M i j)))

/-- **The Weil pairing is a genuine number on the finitely-supported space**: the `∀ N`
    (direct-limit) quantifier of `WeilPSD` collapses to a single value on each
    finitely-supported test family — the `N → ∞` passage of the layer, for the dense subspace
    every discrete Sonine statement quantifies over. -/
theorem weilQuad_welldef {c : Nat → Real} {B : Nat} (hc : FinSupp c B)
    (M : Nat → Nat → Real) {N N' : Nat} (hN : B ≤ N) (hN' : B ≤ N') :
    Req (weilQuad M c N) (weilQuad M c N') :=
  Req_trans (weilQuad_stable hc M hN) (Req_symm (weilQuad_stable hc M hN'))

/-- The band projection preserves finite support: the projection operator acts ON the
    finitely-supported space. -/
theorem FinSupp_bandProj {c : Nat → Real} {B : Nat} (hc : FinSupp c B) :
    FinSupp (bandProj c) B := by
  intro i hi
  by_cases h : i = 1
  · subst h; exact Req_refl zero
  · show Req (if i = 1 then zero else c i) zero
    rw [if_neg h]
    exact hc i hi

end Multiplicity.UOR.Bridge.F1Square.Square
