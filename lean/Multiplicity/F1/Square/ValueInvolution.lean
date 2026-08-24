/-
F1 square — **the value-level reflection involution** (`ValueInvolution.lean`): the pointwise
`clampedInv (clampedInv t) ≈ t` on the reciprocal-symmetric window `a ≤ t ≤ 1/a`, the value-level
form of the reflection involution needed to make the self-dual symmetry usable pointwise (feeding
`mulConv_congr_right`).

    `clampedInv a (clampedInv a t) ≈ t`     (`a ≤ t ≤ 1/a`, `t > 0` witness).

WHY (the self-dual arm). `logPull_reflect_involutive` gives the involution at `t = exp u`; the
convolution integrates over `t` directly, so the pointwise value-level form is what feeds
`mulConv_congr_right` to turn `reflectTest g ≈ g` into `autocorr(g) ≈ g ⋆ g`. On the window both
clamps are inert (`clampedInv a t = 1/t ≥ a` since `t ≤ 1/a`), so the double clamped reciprocal is the
genuine `1/(1/t) = t` — via the `Rinv` involution and the reciprocal ceiling lift `ofQ_inv_le_Rinv`.

HONEST SCOPE. The value-level `clampedInv` involution on the window (plus the `Rinv`/`Qinv`
involutions it rests on). It is NOT yet the pointwise self-duality of `selfDualTest` (next brick,
`φ.hfc` through this), NOT the autocorrelation-is-self-convolution identity, and applies NO step-4
positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.ClampedInv
import Multiplicity.F1.Analysis.ClampedInvLower
import Multiplicity.F1.Analysis.RealDiv
import Multiplicity.F1.Analysis.Pi

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The rational inverse is an involution** `Qinv (Qinv a) = a` (as `Qeq`), for `a.num > 0`:
    `Qinv a = ⟨a.den, a.num.toNat⟩`, so `Qinv (Qinv a) = ⟨a.num.toNat, a.den⟩ = a` since `a.num ≥ 0`. -/
private theorem Qinv_Qinv {a : Q} (han : 0 < a.num) : Qeq (Qinv (Qinv a)) a := by
  have hn : (Qinv (Qinv a)).num = a.num := by
    simp only [Qinv]; exact Int.toNat_of_nonneg (Int.le_of_lt han)
  have hd : ((Qinv (Qinv a)).den : Int) = (a.den : Int) := by
    simp only [Qinv]; omega
  show (Qinv (Qinv a)).num * (a.den : Int) = a.num * ((Qinv (Qinv a)).den : Int)
  rw [hn, hd]

/-- **The real inverse is an involution** `Rinv (Rinv x) ≈ x` (`x > 0` via the witnesses): from
    `x · (1/x) = 1` (`Rmul_Rinv_self`), `x` is the inverse of `1/x`. -/
private theorem Rinv_involutive {x : Real} {k : Nat} (hk : Qlt (Qbound k) (x.seq k))
    {k' : Nat} (hk' : Qlt (Qbound k') ((Rinv x k hk).seq k')) :
    Req (Rinv (Rinv x k hk) k' hk') x :=
  Req_symm
    (Req_trans (Req_symm (Rmul_one x))
      (Req_trans (Rmul_congr (Req_refl x) (Req_symm (Rmul_Rinv_self hk')))
        (Req_trans (Req_symm (Rmul_assoc x (Rinv x k hk) (Rinv (Rinv x k hk) k' hk')))
          (Req_trans (Rmul_congr (Rmul_Rinv_self hk) (Req_refl _))
            (Rone_mul (Rinv (Rinv x k hk) k' hk'))))))

/-- **The clamped reciprocal is an involution on the reciprocal-symmetric window**:
    `clampedInv a (clampedInv a t) ≈ t` for `a ≤ t ≤ 1/a` (`t > 0` witness). Both clamps are inert:
    `clampedInv a t ≈ 1/t` (`clampedInv_eq_of_ge`), `1/t ≥ a` (`ofQ_inv_le_Rinv` + `Qinv (Qinv a)=a`),
    so the outer clamp is inert too and `clampedInv a (1/t) ≈ 1/(1/t) ≈ t` (`Rinv` involution). This is
    the value-level reflection involution the self-dual autocorrelation arm consumes. -/
theorem clampedInv_involutive (a : Q) (han : 0 < a.num) (had : 0 < a.den) {t : Real} {kt : Nat}
    (hkt : Qlt (Qbound kt) (t.seq kt)) (ht_lo : Rle (ofQ a had) t)
    (ht_hi : Rle t (ofQ (Qinv a) (Qinv_den_pos han))) :
    Req (clampedInv a han had (clampedInv a han had t)) t := by
  -- inner clamp inert: clampedInv a t ≈ 1/t
  have hinner : Req (clampedInv a han had t) (Rinv t kt hkt) := clampedInv_eq_of_ge hkt ht_lo
  -- 1/t ≥ a : reciprocal ceiling lift of t ≤ 1/a, then Qinv (Qinv a) = a
  have hRinv_ge : Rle (ofQ a had) (Rinv t kt hkt) :=
    Rle_trans (Rle_of_Req (ofQ_congr had (Qinv_den_pos (Qinv_num_pos had)) (Qeq_symm (Qinv_Qinv han))))
      (ofQ_inv_le_Rinv (Qinv_den_pos han) (Qinv_num_pos had) hkt ht_hi)
  have hge : Rle (ofQ a had) (clampedInv a han had t) :=
    Rle_trans hRinv_ge (Rle_of_Req (Req_symm hinner))
  -- positivity witnesses for the outer clamp and the inner reciprocal
  obtain ⟨kt2, hkt2⟩ := Pos_of_Rle_ofQ han had hge
  obtain ⟨kt3, hkt3⟩ := Pos_of_Rle_ofQ han had hRinv_ge
  -- outer clamp inert, then Rinv involution
  refine Req_trans (clampedInv_eq_of_ge hkt2 hge) ?_
  exact Req_trans (Rinv_congr hkt2 hkt3 hinner) (Rinv_involutive hkt hkt3)

end Multiplicity.UOR.Bridge.F1Square.Square
