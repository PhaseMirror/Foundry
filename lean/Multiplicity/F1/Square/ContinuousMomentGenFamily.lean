/-
F1 square — **the pre-Hilbert layer, brick 122** (`ContinuousMomentGenFamily.lean`): **the ℤ-linear
continuous transform COMPUTES in closed form on a genuine ℤ⁺-family** —
`compactMomentGenLim (k·clampTest) n ≈ k/(n+2)` (`compactMomentGenLim_natScale_clamp`), for every
integer scale `k` and every integer exponent `n`.

WHY (the Sonine route, step 3, the transform PAIR). Homogeneity (brick 121) and the single-test closed
form (brick 116, `compactMomentGenLim clampTest n = 1/(n+2)`) together give the transform's value on the
whole `ℤ⁺`-orbit of `clampTest` with no new analysis: `transform(k·clampTest)(n) ≈ k·transform(clampTest)(n)
= k·(1/(n+2)) = k/(n+2)`. This is the concrete payoff of the linearity arc — the continuous transform,
now a genuine `ℤ`-linear map, evaluates to an explicit rational on an infinite family of tests, exhibiting
it as a computable map rather than a mere existence object.

HONEST SCOPE. A closed-form evaluation of the (already-constructed, already-linear) transform on the
`ℤ⁺`-clamp family at integer exponents. NOT the pairing/inversion, NOT any positivity. Step 4 is RH; crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.ContinuousMomentGenScale
import Multiplicity.F1.Square.ContinuousMomentClampValue

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `natScaleR` respects `Req` in its real argument (a `k`-fold `Radd_congr`). -/
private theorem natScaleR_congr {a b : Real} (hab : Req a b) :
    ∀ k, Req (natScaleR k a) (natScaleR k b)
  | 0 => Req_refl _
  | k + 1 => Radd_congr hab (natScaleR_congr hab k)

/-- The `k`-fold real sum of a rational is that rational scaled by `k`: `k·(ofQ q) ≈ ofQ (k·q)`. -/
private theorem natScaleR_ofQ (q : Q) (hq : 0 < q.den) :
    ∀ k, Req (natScaleR k (ofQ q hq)) (ofQ (mul (⟨(k : Int), 1⟩ : Q) q) (Qmul_den_pos Nat.one_pos hq))
  | 0 => Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨0, 1⟩ : Q) (mul (⟨(0 : Int), 1⟩ : Q) q)
      simp only [Qeq, mul]; push_cast; ring_uor)
  | k + 1 => by
      refine Req_trans (Radd_congr (Req_refl _) (natScaleR_ofQ q hq k)) ?_
      refine Req_trans (Radd_ofQ_ofQ hq (Qmul_den_pos Nat.one_pos hq)) ?_
      refine Req_of_seq_Qeq (fun _ => ?_)
      show Qeq (add q (mul (⟨(k : Int), 1⟩ : Q) q)) (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) q)
      simp only [Qeq, add, mul]; push_cast; ring_uor

/-- **★ THE ℤ-LINEAR TRANSFORM COMPUTES ON THE ℤ⁺-CLAMP FAMILY**: `compactMomentGenLim (k·clampTest) n ≈
    k/(n+2)`. Homogeneity (brick 121) carries the single-test closed form (brick 116, `1/(n+2)`) across
    the whole `ℤ⁺`-orbit; `natScaleR_ofQ` collapses `k·(1/(n+2))` to `k/(n+2)`. -/
theorem compactMomentGenLim_natScale_clamp (k n : Nat) :
    Req (compactMomentGenLim (natScale k clampTest) (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q)
          Nat.one_pos (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n)))
        (ofQ (⟨(k : Int), n + 2⟩ : Q) (Nat.succ_pos (n + 1))) := by
  refine Req_trans (compactMomentGenLim_natScale clampTest (natExpR_nonneg n) (⟨(n : Int), 1⟩ : Q)
    Nat.one_pos (Int.ofNat_nonneg n) (Rle_of_Req (natExpR_eq_ofQ n)) k) ?_
  refine Req_trans (natScaleR_congr (compactMomentGenLim_clamp_eq n) k) ?_
  refine Req_trans (natScaleR_ofQ (⟨1, n + 2⟩ : Q) (Nat.succ_pos (n + 1)) k) ?_
  refine ofQ_congr _ _ ?_
  show Qeq (mul (⟨(k : Int), 1⟩ : Q) (⟨1, n + 2⟩ : Q)) (⟨(k : Int), n + 2⟩ : Q)
  simp only [Qeq, mul]; push_cast; ring_uor

end Multiplicity.UOR.Bridge.F1Square.Square
