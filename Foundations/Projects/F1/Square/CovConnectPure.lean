/-
F1 square — **the covConnect algebra** (`CovConnectPure.lean`): the pure real rearrangement that turns
the dilation covariance into the `∫_t` reconstruction's per-`t` integrand split `U = Whead − Tmom`. With
`mellinHat(dilate c f)` abstracted as `mom + tw` (its definition `mellinMoment + twTail`), the covariance
`cⁿ⁺¹·(mom+tw) = M` and the reciprocal `T·c = 1` give

    `g · c · tw  ≈  (g · Tⁿ · M)  −  (g · c · mom)`.

WHY (grounding `v = ĝ`). The tail commute (`convTwTail_eq_intTail`) consumes the per-`t` integrand
`g(t)·c·twTail(dilate c f)` (`c = clampedInv(a,t) ≥ 1`, `T = max(t,a)`, `T·c = 1` by `Rmul_Rinv_self`).
This file isolates the exact algebra that rewrites it as the difference of a HEAD test
`Whead.f t = g·Tⁿ·M[f]` (`M[f] = mellinHat f`, via `Rmul_head_of_covariance`) and a MOMENT test
`Tmom.f t = g·c·mellinMoment(dilate c f)` — so `U = Whead − Tmom` discharges the tail commute's `hU`.

HONEST SCOPE. A pure real identity (no test, no clampedInv, no integral) built on the covariance head
`Rmul_head_of_covariance`. It supplies NO `U` (that instantiates `mom`/`tw` at the genuine clampedInv
mellinHat), builds NO factorization `M[f⋆g]=M[f]·M[g]`, grounds NO `v = ĝ`, and — emphatically — applies
NO step-4 band-coupling positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.CovarianceHead

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `(a + b) − a ≈ b` (from `Radd` associativity/commutativity; `Rsub x y` is `Radd x (Rneg y)`). -/
private theorem Rsub_Radd_cancel_left (a b : Real) : Req (Rsub (Radd a b) a) b :=
  Req_trans (Radd_assoc a b (Rneg a))
    (Req_trans (Radd_congr (Req_refl a) (Radd_comm b (Rneg a)))
      (Req_trans (Req_symm (Radd_assoc a (Rneg a) b))
        (Req_trans (Radd_congr (Radd_neg a) (Req_refl b))
          (Req_trans (Radd_comm zero b) (Radd_zero b)))))

/-- **The covConnect algebra.** With `mellinHat(dilate c f) = mom + tw`, the covariance
    `cⁿ⁺¹·(mom+tw) ≈ M` and the reciprocal `T·c ≈ 1` give the tail integrand as the head/moment
    difference `g·c·tw ≈ (g·Tⁿ·M) − (g·c·mom)`. -/
theorem covConnect_pure {g c T mom tw M : Real} (n : Nat)
    (hcov : Req (Rmul (Rpow c (n + 1)) (Radd mom tw)) M)
    (htc : Req (Rmul T c) one) :
    Req (Rmul (Rmul g c) tw)
        (Rsub (Rmul (Rmul g (Rpow T n)) M) (Rmul (Rmul g c) mom)) := by
  -- head: `c·(mom+tw) ≈ Tⁿ·M`.
  have hhead : Req (Rmul c (Radd mom tw)) (Rmul (Rpow T n) M) :=
    Rmul_head_of_covariance n hcov htc
  -- `c·tw ≈ Tⁿ·M − c·mom`.
  have hctw : Req (Rmul c tw) (Rsub (Rmul (Rpow T n) M) (Rmul c mom)) :=
    Req_symm (Req_trans (Rsub_congr (Req_symm hhead) (Req_refl (Rmul c mom)))
      (Req_trans (Rsub_congr (Rmul_distrib c mom tw) (Req_refl (Rmul c mom)))
        (Rsub_Radd_cancel_left (Rmul c mom) (Rmul c tw))))
  -- assemble: `g·c·tw ≈ g·(Tⁿ·M − c·mom) ≈ (g·Tⁿ·M) − (g·c·mom)`.
  exact Req_trans (Rmul_assoc g c tw)
    (Req_trans (Rmul_congr (Req_refl g) hctw)
      (Req_trans (Rmul_sub_distrib g (Rmul (Rpow T n) M) (Rmul c mom))
        (Rsub_congr (Req_symm (Rmul_assoc g (Rpow T n) M))
          (Req_symm (Rmul_assoc g c mom)))))

end Multiplicity.UOR.Bridge.F1Square.Square
