/-
F1 square — **the pre-Hilbert layer, brick 76** (`L2DefiniteDensity.lean`): **THE TRANSPORT HALF
OF DENSITY** — brick 74 gave `∫₀¹ φ² ≈ 0 ⟹ φ(p) ≈ 0` at dyadic `p`. This carries that value to
any point the dyadics approximate:

    `∫₀¹ φ² ≈ 0`,  `|x − p| ≤ e` at a dyadic `p`   ⟹   `|φ(x)| ≤ L·e`
      (`abs_le_of_near_dyadic`)
    `∫₀¹ φ² ≈ 0`,  `x` dyadically approximable to every rate   ⟹   `φ(x) ≈ 0`
      (`zero_of_dyadic_approximable`).

The transport is one line of Lipschitz — `|φ(x)| = |φ(x) − φ(p)| ≤ L|x − p|` — and the passage to
the limit is the Archimedean criterion. What it buys is that the remaining work is now a **single,
purely metric** statement with no analysis in it: `DyadicApproximable x`, that every rate is met by
some dyadic point.

HONEST SCOPE — WHAT IS AND IS NOT PROVEN. `zero_of_dyadic_approximable` is stated **under**
`DyadicApproximable x` as a hypothesis. That hypothesis is **not discharged here** for a general
`x ∈ [0,1]`, so this brick does **not** by itself upgrade brick 74 from dyadic points to all
points. Discharging it needs two things the repo lacks: a bound `|x − ofQ (x.seq N)| ≤ 1/(N+1)`
relating a real to its own approximants, and a clamp of `⌊q·2^m⌋` into `[0, 2^m)` for a rational
`q` that may sit slightly outside `[0,1)` (brick 75 supplies the floor itself, but assumes the
rational is already in range). Until both land, the definiteness statement of record remains
`innerI_self_zero_imp_dyadic_zero`, at dyadic points.

Nothing here touches the Weil form, and nothing here bears on the moment problem — a nonzero test
with all *moments* vanishing is a different question, still open. Step 4 is RH. The crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.DyadicApprox

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The dyadic point `j/2^m`. -/
def dyadPt (m j : Nat) : Real := ofQ (⟨(j : Int), 2 ^ m⟩ : Q) (two_pow_pos m)

/-- **Dyadic approximability**: every rate `1/(k+1)` is met by some dyadic point of `[0,1)`.
    A purely metric condition — no integral, no test function. -/
def DyadicApproximable (x : Real) : Prop :=
  ∀ k : Nat, ∃ m j : Nat, j < 2 ^ m ∧
    Rle (Rabs (Rsub x (dyadPt m j))) (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k))

/-- **THE TRANSPORT**: with the value at a dyadic point known to vanish, the Lipschitz certificate
    carries the bound to any nearby point. -/
theorem abs_le_of_near_dyadic (φ : L2Test) (h : Req (innerI φ φ) zero)
    (x : Real) (m j : Nat) (hj : j < 2 ^ m) {e : Q} (hed : 0 < e.den)
    (hnear : Rle (Rabs (Rsub x (dyadPt m j))) (ofQ e hed)) :
    Rle (Rabs (φ.f x)) (Rmul (ofQ φ.L φ.hLd) (ofQ e hed)) := by
  have hp : Req (φ.f (dyadPt m j)) zero :=
    innerI_self_zero_imp_dyadic_zero φ h m j hj
  -- `|φ(x)| = |φ(x) − φ(p)|` since `φ(p) ≈ 0`
  have hrw : Req (Rabs (φ.f x)) (Rabs (Rsub (φ.f x) (φ.f (dyadPt m j)))) := by
    refine Rabs_congr ?_
    refine Req_symm (Req_trans (Radd_congr (Req_refl _) (Rneg_congr hp)) ?_)
    exact Req_trans (Radd_congr (Req_refl _) Rneg_zero) (Radd_zero _)
  refine Rle_trans (Rle_of_Req hrw) ?_
  refine Rle_trans (φ.hlip x (dyadPt m j)) ?_
  exact Rmul_le_Rmul_left (Rnonneg_ofQ φ.hLd φ.hLn) hnear

/-- **DENSITY, CONDITIONALLY**: a dyadically approximable point is a zero of any test whose
    `L²` energy vanishes. -/
theorem zero_of_dyadic_approximable (φ : L2Test) (h : Req (innerI φ φ) zero)
    (x : Real) (hx : DyadicApproximable x) :
    Req (φ.f x) zero := by
  -- `|φ(x)| ≤ L/(k+1)` for every `k`
  have hbound : ∀ k : Nat,
      Rle (Rabs (φ.f x)) (ofQ (mul φ.L (⟨1, k + 1⟩ : Q)) (Qmul_den_pos φ.hLd (Nat.succ_pos k))) := by
    intro k
    obtain ⟨m, j, hj, hnear⟩ := hx k
    refine Rle_trans (abs_le_of_near_dyadic φ h x m j hj (Nat.succ_pos k) hnear) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ φ.hLd (Nat.succ_pos k))
  -- Archimedean collapse: `|φ(x)| ≤ 0`
  have habs : Rle (Rabs (φ.f x)) zero := by
    refine Rle_of_Rsub_le_eps (C := φ.L.num.toNat) (fun k => ?_)
    refine Rle_trans (Rle_of_Req (Req_trans (Radd_congr (Req_refl _) Rneg_zero)
      (Radd_zero (Rabs (φ.f x))))) ?_
    refine Rle_trans (hbound k) ?_
    refine Rle_ofQ_ofQ _ (Nat.succ_pos k) ?_
    show φ.L.num * 1 * ((k + 1 : Nat) : Int)
        ≤ ((φ.L.num.toNat : Nat) : Int) * (((φ.L.den * (k + 1) : Nat)) : Int)
    have hnum : ((φ.L.num.toNat : Nat) : Int) = φ.L.num := Int.toNat_of_nonneg φ.hLn
    have hd1 : (1 : Int) ≤ ((φ.L.den : Nat) : Int) := by have := φ.hLd; omega
    have hk : (0 : Int) ≤ ((k + 1 : Nat) : Int) := Int.ofNat_nonneg _
    have hLnn : (0 : Int) ≤ φ.L.num := φ.hLn
    rw [hnum]
    push_cast
    have e : φ.L.num * ((φ.L.den : Int) * ((k : Int) + 1))
        = (φ.L.num * ((k : Int) + 1)) * (φ.L.den : Int) := by ring_uor
    rw [e]
    have hk1 : (0 : Int) ≤ (k : Int) + 1 := by omega
    have hprod : (0 : Int) ≤ φ.L.num * ((k : Int) + 1) := Int.mul_nonneg hLnn hk1
    have hstep : φ.L.num * ((k : Int) + 1) * 1
        ≤ φ.L.num * ((k : Int) + 1) * ((φ.L.den : Int)) :=
      Int.mul_le_mul_of_nonneg_left hd1 hprod
    have e2 : φ.L.num * 1 * ((k : Int) + 1) = φ.L.num * ((k : Int) + 1) * 1 := by ring_uor
    rw [e2]
    exact hstep
  -- `|y| ≤ 0` and `|y| ≥ 0` force `y ≈ 0`
  have hz : Req (Rabs (φ.f x)) zero :=
    Rle_antisymm habs (Rle_zero_of_Rnonneg (Rnonneg_Rabs _))
  refine Rle_antisymm (Rle_trans (Rle_Rabs_self _) (Rle_of_Req hz)) ?_
  have hneg : Rle (Rneg (φ.f x)) zero :=
    Rle_trans (Rle_Rabs_self (Rneg (φ.f x)))
      (Rle_of_Req (Req_trans (Rabs_Rneg (φ.f x)) hz))
  refine Rle_trans (Rle_of_Req (Req_symm Rneg_zero)) ?_
  exact Rle_trans (Rle_Rneg hneg) (Rle_of_Req (Rneg_neg (φ.f x)))

/-- Dyadic points are themselves approximable — the criterion is inhabited, so the conditional
    theorem above is not vacuous. (It recovers brick 74's statement, no more.) -/
theorem dyadicApproximable_dyadPt (m j : Nat) (hj : j < 2 ^ m) :
    DyadicApproximable (dyadPt m j) := by
  intro k
  refine ⟨m, j, hj, ?_⟩
  refine Rle_trans (Rle_of_Req (Rabs_congr (Radd_neg (dyadPt m j)))) ?_
  refine Rle_trans (Rle_of_Req Rabs_zero) ?_
  exact Rle_zero_of_Rnonneg (Rnonneg_ofQ (Nat.succ_pos k) (by show (0 : Int) ≤ 1; decide))

end Multiplicity.UOR.Bridge.F1Square.Square
