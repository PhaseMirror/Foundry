/-
F1 square — **the covariance HEAD identity** (`CovarianceHead.lean`): the pure real-power rearrangement
that turns the dilation covariance `cⁿ⁺¹·H = M` into the `∫_t` reconstruction's head factor. For a
reciprocal pair `t·c = 1` (on the window `c = clampedInv(a,t) = 1/t`, `t = max(t,a)`),

    `cⁿ⁺¹ · H = M`   and   `t · c = 1`   ⟹   `c · H = tⁿ · M`.

WHY (the covConnect). The tail commute (`convTwTail_eq_intTail`) consumes the per-`t` integrand
`g(t)·c·twTail(dilateTestR c f)`. Splitting `twTail = mellinHat − mellinMoment` and applying the
covariance `cⁿ⁺¹·mellinHat(dilate c f) = mellinHat f` (`mellinHat_dilate_covariance_real_ge1`, valid at
`c = clampedInv ≥ 1`) gives the HEAD `c·mellinHat(dilate c f) = tⁿ·mellinHat f` — the `g·tⁿ·M[f]` piece
of `U = Whead − Tmom`. This file isolates the algebra: `tⁿ·M = tⁿ·cⁿ⁺¹·H = (t·c)ⁿ·c·H = 1ⁿ·c·H = c·H`.

HONEST SCOPE. A pure real-power identity (no mellinHat, no test, no integral). It builds NO covConnect on
its own, NO factorization `M[f⋆g]=M[f]·M[g]`, NO grounding of `v = ĝ`, and — emphatically — NO step-4
band-coupling positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.Pow
import Foundations.F1.Analysis.RealPow

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `oneⁿ ≈ one` (the power of the multiplicative unit collapses). -/
private theorem Rpow_one_eq : ∀ n, Req (Rpow one n) one
  | 0 => Req_refl one
  | (n + 1) => Req_trans (Req_trans (Rmul_comm one (Rpow one n)) (Rmul_one (Rpow one n)))
      (Rpow_one_eq n)

/-- **The covariance head identity.** From the dilation covariance `cⁿ⁺¹·H ≈ M` and the reciprocal
    relation `t·c ≈ 1`, `c·H ≈ tⁿ·M` — the head factor of the `∫_t` reconstruction. -/
theorem Rmul_head_of_covariance {c t H M : Real} (n : Nat)
    (hcov : Req (Rmul (Rpow c (n + 1)) H) M) (htc : Req (Rmul t c) one) :
    Req (Rmul c H) (Rmul (Rpow t n) M) := by
  -- key: `tⁿ · cⁿ⁺¹ ≈ c`.
  have hkey : Req (Rmul (Rpow t n) (Rpow c (n + 1))) c :=
    Req_trans (Rmul_congr (Req_refl (Rpow t n)) (Rmul_comm c (Rpow c n)))
      (Req_trans (Req_symm (Rmul_assoc (Rpow t n) (Rpow c n) c))
        (Req_trans (Rmul_congr (Req_symm (Rpow_mul_dist t c n)) (Req_refl c))
          (Req_trans (Rmul_congr (Rpow_congr htc n) (Req_refl c))
            (Req_trans (Rmul_congr (Rpow_one_eq n) (Req_refl c))
              (Req_trans (Rmul_comm one c) (Rmul_one c))))))
  -- `tⁿ·M ≈ tⁿ·(cⁿ⁺¹·H) ≈ (tⁿ·cⁿ⁺¹)·H ≈ c·H`.
  exact Req_symm (Req_trans (Rmul_congr (Req_refl (Rpow t n)) (Req_symm hcov))
    (Req_trans (Req_symm (Rmul_assoc (Rpow t n) (Rpow c (n + 1)) H))
      (Rmul_congr hkey (Req_refl H))))

end Multiplicity.UOR.Bridge.F1Square.Square
