/-
F1 square — v0.22.0 Track 1, brick (argument axis): **the lower-sector argument** `CargLower`
(`Im z < 0`, `|Re/Im| ≤ ρ < 1`), the conjugate reflection of the upper sector.

ξ's zeros come in conjugate pairs, so the argument is needed below the real axis as well. By the
conjugate symmetry `arg(z̄) = −arg z`, the lower-sector argument is `CargLower z = −CargUpper(z̄)`
(`z̄ = Cconj z` lands in the upper sector when `Im z < 0`). It carries the genuine tangent
`tan(CargLower z) = Im z/Re z` (`CargLower_tan`, from `CargUpper_tan` + sin/cos parity), and its
additivity `CargLower(zw) = Carg z + CargLower w` (`CargLower_add`) reflects `CargUpper_add` through
`Cconj_Cmul` (`z̄w̄ = z̄·w̄`).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import F1Square.Analysis.ComplexArgUpperAdd

namespace UOR.Bridge.F1Square.Analysis

/-- **The lower-half-plane argument** `CargLower z = −arg(z̄)` for `Im z < 0` (so `z̄` is upper):
    `arg(z) = −arg(z̄)` by conjugate symmetry. Witness `k` for `(z̄).im = −Im z > 0`. -/
def CargLower (z : Complex) (k : Nat) (hk : Qlt (Qbound k) ((Cconj z).im.seq k))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv (Cconj z).re (Cconj z).im k hk).seq n)) ρ) : Real :=
  Rneg (CargUpper (Cconj z) k hk ρ hρ0 hρd hρlt hb)

set_option maxHeartbeats 1200000 in
/-- **★ the lower-half argument has the right tangent**: `tan(CargLower z) = Im z/Re z`, i.e.
    `sin(CargLower z) = (Im z/Re z)·cos(CargLower z)`. From `CargUpper_tan` of `z̄` (`tan = (−Im z)/Re z`)
    reflected by sin-oddness/cos-evenness: `sin(−A) = −sin A`, `cos(−A) = cos A`, and
    `−((−Im z)/Re z) = Im z/Re z`. Confirms `CargLower` is the genuine lower-sector argument. -/
theorem CargLower_tan (z : Complex) (k : Nat) (hk : Qlt (Qbound k) ((Cconj z).im.seq k))
    (kr : Nat) (hkr : Qlt (Qbound kr) (z.re.seq kr))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hρlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((Rdiv (Cconj z).re (Cconj z).im k hk).seq n)) ρ)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩) :
    Req (Rsin (CargLower z k hk ρ hρ0 hρd hρlt hb))
      (Rmul (Rdiv z.im z.re kr hkr) (Rcos (CargLower z k hk ρ hρ0 hρd hρlt hb))) := by
  have htan := CargUpper_tan (Cconj z) k hk kr hkr ρ hρ0 hρd hρlt hb hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1
  have hfac : Req (Rneg (Rdiv (Cconj z).im (Cconj z).re kr hkr)) (Rdiv z.im z.re kr hkr) :=
    Req_trans (Rneg_congr (Rmul_neg_left z.im (Rinv z.re kr hkr)))
      (Rneg_neg (Rmul z.im (Rinv z.re kr hkr)))
  show Req (Rsin (Rneg (CargUpper (Cconj z) k hk ρ hρ0 hρd hρlt hb)))
    (Rmul (Rdiv z.im z.re kr hkr) (Rcos (Rneg (CargUpper (Cconj z) k hk ρ hρ0 hρd hρlt hb))))
  refine Req_trans (Rsin_neg (CargUpper (Cconj z) k hk ρ hρ0 hρd hρlt hb)) ?_
  refine Req_trans (Rneg_congr htan) ?_
  refine Req_trans (Req_symm (Rmul_neg_left (Rdiv (Cconj z).im (Cconj z).re kr hkr)
    (Rcos (CargUpper (Cconj z) k hk ρ hρ0 hρd hρlt hb)))) ?_
  refine Req_trans (Rmul_congr hfac (Req_refl _)) ?_
  exact Rmul_congr (Req_refl _) (Req_symm (Rcos_neg (CargUpper (Cconj z) k hk ρ hρ0 hρd hρlt hb)))

/-- **Conjugate distributes over product** `z̄·w̄ = (zw)‾` (up to `≈`): `Ceq (Cconj (Cmul z w))
    (Cmul (Cconj z) (Cconj w))`. Componentwise: Re uses `(−Im z)(−Im w) = Im z·Im w`, Im uses
    `−(Re z·Im w + Im z·Re w) = Re z·(−Im w) + (−Im z)·Re w`. -/
theorem Cconj_Cmul (z w : Complex) : Ceq (Cconj (Cmul z w)) (Cmul (Cconj z) (Cconj w)) := by
  have hnn : Req (Rmul (Rneg z.im) (Rneg w.im)) (Rmul z.im w.im) :=
    Req_trans (Rmul_neg_left z.im (Rneg w.im))
      (Req_trans (Rneg_congr (Rmul_neg_right z.im w.im)) (Rneg_neg (Rmul z.im w.im)))
  refine ⟨?_, ?_⟩
  · show Req (Rsub (Rmul z.re w.re) (Rmul z.im w.im))
      (Rsub (Rmul z.re w.re) (Rmul (Rneg z.im) (Rneg w.im)))
    exact Rsub_congr (Req_refl (Rmul z.re w.re)) (Req_symm hnn)
  · show Req (Rneg (Radd (Rmul z.re w.im) (Rmul z.im w.re)))
      (Radd (Rmul z.re (Rneg w.im)) (Rmul (Rneg z.im) w.re))
    refine Req_trans (Rneg_Radd (Rmul z.re w.im) (Rmul z.im w.re)) ?_
    exact Req_symm (Radd_congr (Rmul_neg_right z.re w.im) (Rmul_neg_left z.im w.re))

/-- **The upper-sector argument respects `≈`**: `z ≈ w` ⟹ `CargUpper z = CargUpper w`
    (`Rdiv_congr` + `RarctanR_congr` under the `π/2 −` shift). -/
theorem CargUpper_congr {z w : Complex} {kz kw : Nat} (hkz : Qlt (Qbound kz) (z.im.seq kz))
    (hkw : Qlt (Qbound kw) (w.im.seq kw)) (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hρlt : ρ.num.toNat < ρ.den) (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ)))
    (hbz : ∀ n, Qle (Qabs ((Rdiv z.re z.im kz hkz).seq n)) ρ)
    (hbw : ∀ n, Qle (Qabs ((Rdiv w.re w.im kw hkw).seq n)) ρ)
    (hzw : Ceq z w) :
    Req (CargUpper z kz hkz ρ hρ0 hρd hρlt hbz) (CargUpper w kw hkw ρ hρ0 hρd hρlt hbw) :=
  Rsub_congr (Req_refl Rpi_half)
    (RarctanR_congr (Rdiv z.re z.im kz hkz) (Rdiv w.re w.im kw hkw) ρ hρ0 hρd hρlt hρ2 hbz hbw
      (Rdiv_congr hkz hkw hzw.1 hzw.2))

set_option maxHeartbeats 4000000 in
/-- **★ lower-sector argument additivity** `CargLower(zw) = Carg z + CargLower w` — principal `z`
    times lower `w` (product lower). The conjugate reflection of `CargUpper_add`: `CargLower(zw) =
    −CargUpper((zw)‾) = −CargUpper(z̄·w̄) = −(Carg z̄ + CargUpper w̄) = Carg z + CargLower w`, using
    `Cconj_Cmul`, `CargUpper_congr`, `CargUpper_add`, and `Carg_conj`. -/
theorem CargLower_add (z w : Complex)
    (kz : Nat) (hkz : Qlt (Qbound kz) (z.re.seq kz))
    (kw : Nat) (hkw : Qlt (Qbound kw) ((Cconj w).im.seq kw))
    (kzw : Nat) (hkzw : Qlt (Qbound kzw) ((Cconj (Cmul z w)).im.seq kzw))
    (kp : Nat) (hkp : Qlt (Qbound kp) ((Cmul (swapC (Cconj w)) (Cconj (Cconj z))).re.seq kp))
    (kc : Nat) (hkc : Qlt (Qbound kc) ((Cmul (Cconj z) (Cconj w)).im.seq kc))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩)
    (hbz : ∀ n, Qle (Qabs ((Rdiv z.im z.re kz hkz).seq n)) ρ)
    (hbcz : ∀ n, Qle (Qabs ((Rdiv (Cconj z).im (Cconj z).re kz hkz).seq n)) ρ)
    (hbczz : ∀ n, Qle (Qabs ((Rdiv (Cconj (Cconj z)).im (Cconj (Cconj z)).re kz hkz).seq n)) ρ)
    (hbw : ∀ n, Qle (Qabs ((Rdiv (Cconj w).re (Cconj w).im kw hkw).seq n)) ρ)
    (hbzw : ∀ n, Qle (Qabs ((Rdiv (Cconj (Cmul z w)).re (Cconj (Cmul z w)).im kzw hkzw).seq n)) ρ)
    (hbc : ∀ n, Qle (Qabs ((Rdiv (Cmul (Cconj z) (Cconj w)).re
      (Cmul (Cconj z) (Cconj w)).im kc hkc).seq n)) ρ)
    (hbp : ∀ n, Qle (Qabs ((Rdiv (Cmul (swapC (Cconj w)) (Cconj (Cconj z))).im
      (Cmul (swapC (Cconj w)) (Cconj (Cconj z))).re kp hkp).seq n)) ρ)
    (hbvv : ∀ n, Qle (Qabs (vval ((Rdiv (swapC (Cconj w)).im (swapC (Cconj w)).re kw hkw).seq n)
      ((Rdiv (Cconj (Cconj z)).im (Cconj (Cconj z)).re kz hkz).seq n))) ρ) :
    Req (CargLower (Cmul z w) kzw hkzw ρ hρ0 hρd hlt hbzw)
      (Radd (Carg z kz hkz ρ hρ0 hρd hlt hbz) (CargLower w kw hkw ρ hρ0 hρd hlt hbw)) := by
  -- CargUpper((zw)‾) ≈ CargUpper(z̄·w̄)   (congruence + Cconj_Cmul)
  have hcong : Req (CargUpper (Cconj (Cmul z w)) kzw hkzw ρ hρ0 hρd hlt hbzw)
      (CargUpper (Cmul (Cconj z) (Cconj w)) kc hkc ρ hρ0 hρd hlt hbc) :=
    CargUpper_congr hkzw hkc ρ hρ0 hρd hlt hρ2 hbzw hbc (Cconj_Cmul z w)
  -- CargUpper(z̄·w̄) ≈ Carg z̄ + CargUpper w̄   (cross-sector additivity, z̄ principal, w̄ upper)
  have hadd := CargUpper_add (Cconj z) (Cconj w) kz hkz kw hkw kc hkc kp hkp ρ
    hρ0 hρd hlt hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1 hbcz hbczz hbw hbc hbp hbvv
  -- Carg z̄ ≈ −Carg z   (conjugate symmetry)
  have hconj : Req (Carg (Cconj z) kz hkz ρ hρ0 hρd hlt hbcz)
      (Rneg (Carg z kz hkz ρ hρ0 hρd hlt hbz)) :=
    Carg_conj z kz hkz ρ hρ0 hρd hlt hρ2 hbz hbcz
  -- CargUpper((zw)‾) ≈ Carg z̄ + CargUpper w̄ ; negate and regroup
  have hkey : Req (CargUpper (Cconj (Cmul z w)) kzw hkzw ρ hρ0 hρd hlt hbzw)
      (Radd (Rneg (Carg z kz hkz ρ hρ0 hρd hlt hbz))
        (CargUpper (Cconj w) kw hkw ρ hρ0 hρd hlt hbw)) :=
    Req_trans hcong (Req_trans hadd (Radd_congr hconj (Req_refl _)))
  show Req (Rneg (CargUpper (Cconj (Cmul z w)) kzw hkzw ρ hρ0 hρd hlt hbzw))
    (Radd (Carg z kz hkz ρ hρ0 hρd hlt hbz) (CargLower w kw hkw ρ hρ0 hρd hlt hbw))
  refine Req_trans (Rneg_congr hkey) ?_
  -- −(−Carg z + CargUpper w̄) = Carg z + (−CargUpper w̄) = Carg z + CargLower w
  refine Req_trans (Rneg_Radd (Rneg (Carg z kz hkz ρ hρ0 hρd hlt hbz))
    (CargUpper (Cconj w) kw hkw ρ hρ0 hρd hlt hbw)) ?_
  exact Radd_congr (Rneg_neg (Carg z kz hkz ρ hρ0 hρd hlt hbz)) (Req_refl _)

end UOR.Bridge.F1Square.Analysis
