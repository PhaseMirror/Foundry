/-
F1 square — v0.22.0 Track 1, brick (argument axis): **the second-sector / upper-half argument**
`arg(z) = π/2 − arctan(Re z / Im z)` for `Im z > 0` and `|Re z / Im z| ≤ ρ < 1`.

The principal-sector `Carg` (`ComplexArg.lean`) covers `Re z > 0`, `|Im/Re| < 1` (i.e. `|arg| < π/4`).
Past that — toward the upper imaginary axis (`|arg| → π/2`) — the standard reciprocal reduction
`arctan t = π/2 − arctan(1/t)` applies: where `Im z` dominates (`|Re/Im| < 1`), the argument is
`π/2 − arctan(Re/Im)`. This file packages that as `CargUpper`, anchored by `arg(i) = π/2`
(`Carg_I`), using the constructive `π/2 = Rpi_half` (`TanPiQuarter.lean`, where `cos(π/2) = 0`,
`sin(π/2) = 1` are proved).

`CargUpper` is the second-sector value by definition (just as the principal `Carg` is `arctan(Im/Re)`
by definition); its agreement with the principal `Carg` in the overlap, and its additivity, are the
following bricks (they need the real-argument value identity `sin(RarctanR t) = t·cos(RarctanR t)`,
a continuity lift).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import F1Square.Analysis.ComplexArg
import F1Square.Analysis.TanPiQuarter
import F1Square.Analysis.RArctanValue
import F1Square.Analysis.RArctanCongr
import F1Square.Analysis.Reflection

namespace UOR.Bridge.F1Square.Analysis

/-- **The upper-half-plane argument**: `arg(z) = π/2 − arctan(Re z / Im z)` for `Im z > 0`
    (witness `k`) and `|Re z / Im z| ≤ ρ < 1`. The reciprocal-reduction value where `Im z`
    dominates `Re z` (`|arg| ∈ (π/4, π/2]`), complementing the principal `Carg`. -/
def CargUpper (z : Complex) (k : Nat) (hk : Qlt (Qbound k) (z.im.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv z.re z.im k hk).seq n)) ρ) : Real :=
  Rsub Rpi_half (RarctanR (Rdiv z.re z.im k hk) ρ hρ0 hρd hρlt hb)

/-- **`arg(i) = π/2`** — the imaginary unit has argument `π/2`. With `Im i = 1 > 0` and
    `Re i = 0`, the ratio `Re/Im = 0/1` has vanishing numerators, so `arctan(Re/Im) = 0`
    (`RarctanR_of_num_zero`) and `CargUpper i = π/2 − 0 = π/2`. The upper-sector anchor, the
    counterpart of `Carg_ofReal_pos` (`arg(x) = 0` on the positive real axis). -/
theorem Carg_I (k : Nat) (hk : Qlt (Qbound k) (I.im.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv I.re I.im k hk).seq n)) ρ) :
    Req (CargUpper I k hk ρ hρ0 hρd hρlt hb) Rpi_half := by
  unfold CargUpper
  have hz : Req (RarctanR (Rdiv I.re I.im k hk) ρ hρ0 hρd hρlt hb) zero := by
    refine RarctanR_of_num_zero (Rdiv I.re I.im k hk) ?_ ρ hρ0 hρd hρlt hb
    intro n
    show ((Rmul zero (Rinv I.im k hk)).seq n).num = 0
    show (mul (zero.seq (Ridx zero (Rinv I.im k hk) n))
        ((Rinv I.im k hk).seq (Ridx zero (Rinv I.im k hk) n))).num = 0
    rw [zero_seq]; simp [mul]
  exact Req_trans (Rsub_congr (Req_refl Rpi_half) hz) (Rsub_zero Rpi_half)

/-- **★ the upper-half argument has the right tangent**: `sin(CargUpper z) = (Im z/Re z)·cos(CargUpper
    z)`, i.e. `tan(CargUpper z) = Im z/Re z` — the genuine argument tangent. For `Im z > 0`, `Re z`
    apart from `0`, and `|Re z/Im z| ≤ ρ < 1/16` (the steep wedge near, but off, the imaginary axis).
    Confirms `CargUpper` is the genuine second-sector argument (not merely a definition): via the
    reciprocal reduction, `tan(π/2 − arctan(Re/Im)) = 1/(Re/Im) = Im/Re`. Combines the real-argument
    value identity `RarctanR_value_eq` (`tan(arctan(Re/Im)) = Re/Im`) with the real complementary
    tangent `Rsin_cos_pi_half_sub_tan_real` and the reciprocal `(Im/Re)·(Re/Im) = 1`
    (`Rmul_Rinv_self`). The second-sector analogue of `tan(Carg z) = Im/Re` for the principal sector. -/
theorem CargUpper_tan (z : Complex) (k : Nat) (hk : Qlt (Qbound k) (z.im.seq k))
    (kr : Nat) (hkr : Qlt (Qbound kr) (z.re.seq kr))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv z.re z.im k hk).seq n)) ρ)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩) :
    Req (Rsin (CargUpper z k hk ρ hρ0 hρd hρlt hb))
      (Rmul (Rdiv z.im z.re kr hkr) (Rcos (CargUpper z k hk ρ hρ0 hρd hρlt hb))) := by
  -- (Im/Re)·(Re/Im) = 1
  have hts : Req (Rmul (Rdiv z.im z.re kr hkr) (Rdiv z.re z.im k hk)) one := by
    show Req (Rmul (Rmul z.im (Rinv z.re kr hkr)) (Rmul z.re (Rinv z.im k hk))) one
    refine Req_trans (Rmul_assoc z.im (Rinv z.re kr hkr) (Rmul z.re (Rinv z.im k hk))) ?_
    refine Req_trans (Rmul_congr (Req_refl z.im)
      (Req_trans (Req_symm (Rmul_assoc (Rinv z.re kr hkr) z.re (Rinv z.im k hk)))
        (Rmul_congr (Req_trans (Rmul_comm (Rinv z.re kr hkr) z.re) (Rmul_Rinv_self hkr))
          (Req_refl (Rinv z.im k hk))))) ?_
    exact Req_trans (Rmul_congr (Req_refl z.im) (Rone_mul_loc (Rinv z.im k hk))) (Rmul_Rinv_self hk)
  -- tan(arctan(Re/Im)) = Re/Im  (real-argument value identity)
  have hval := RarctanR_value_eq (Rdiv z.re z.im k hk) ρ hρ0 hρd hρlt hb hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1
  -- π/2 − arctan(Re/Im) has tangent Im/Re
  exact Rsin_cos_pi_half_sub_tan_real (RarctanR (Rdiv z.re z.im k hk) ρ hρ0 hρd hρlt hb)
    (Rdiv z.re z.im k hk) (Rdiv z.im z.re kr hkr) hval hts

/-- **★ argument conjugate symmetry** `arg(z̄) = −arg z` (principal sector): `Carg(Cconj z) =
    −Carg z`. Since `Cconj z = ⟨Re z, −Im z⟩`, its ratio `Im/Re = −(Im z/Re z)`, and `arctan` is odd
    (`RarctanR_neg`). The complex form of arctan oddness — a building block of cross-sector
    additivity (it converts a subtracted angle into a conjugate factor). -/
theorem Carg_conj (z : Complex) (k : Nat) (hk : Qlt (Qbound k) (z.re.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ)))
    (hb : ∀ n, Qle (Qabs ((Rdiv z.im z.re k hk).seq n)) ρ)
    (hbc : ∀ n, Qle (Qabs ((Rdiv (Cconj z).im (Cconj z).re k hk).seq n)) ρ) :
    Req (Carg (Cconj z) k hk ρ hρ0 hρd hρlt hbc) (Rneg (Carg z k hk ρ hρ0 hρd hρlt hb)) := by
  have hbn : ∀ n, Qle (Qabs ((Rneg (Rdiv z.im z.re k hk)).seq n)) ρ := by
    intro n
    show Qle (Qabs (neg ((Rdiv z.im z.re k hk).seq n))) ρ
    rw [Qabs_neg]; exact hb n
  have hratio : Req (Rdiv (Cconj z).im (Cconj z).re k hk) (Rneg (Rdiv z.im z.re k hk)) :=
    Rmul_neg_left z.im (Rinv z.re k hk)
  refine Req_trans (RarctanR_congr (Rdiv (Cconj z).im (Cconj z).re k hk)
    (Rneg (Rdiv z.im z.re k hk)) ρ hρ0 hρd hρlt hρ2 hbc hbn hratio) ?_
  exact RarctanR_neg (Rdiv z.im z.re k hk) ρ hρ0 hρd hρlt hb hbn

end UOR.Bridge.F1Square.Analysis
