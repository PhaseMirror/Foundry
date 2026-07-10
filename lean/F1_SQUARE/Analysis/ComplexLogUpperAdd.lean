/-
F1 square — v0.22.0 Track 1, brick (argument axis): **cross-sector complex-logarithm additivity**
`ClogUpper(zw) = Clog z + ClogUpper w` (principal `z` × upper `w`, product upper).

The principal `Clog_add` (`ComplexArgAdd.lean`) extends here past `|arg| < π/4`: with `z` in the
principal sector and `w, zw` in the upper sector, `Clog(zw) = Clog z + Clog w` holds with the upper
factors read by `ClogUpper`. As in `Clog_add`, the modulus/real half is the explicit hypothesis
`hmod` (`log|zw|² = log|z|² + log|w|²`, the general positive-real log-multiplicativity, isolated as
the one audit-visible heavy input); the imaginary half is the *fully discharged* cross-sector
argument additivity `CargUpper_add` (`ComplexArgUpperAdd.lean`).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import F1Square.Analysis.ComplexLogUpper
import F1Square.Analysis.ComplexArgUpperAdd

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000 in
/-- **★ cross-sector complex-logarithm additivity** `ClogUpper(zw) = Clog z + ClogUpper w`. Real part:
    `½·log|zw|² ≈ ½(log|z|² + log|w|²)` from `hmod` + `Rmul_distrib`. Imaginary part: the cross-sector
    argument additivity `CargUpper_add`. The complex logarithm is additive across the principal/upper
    boundary (`|arg| < π/4`), the second-sector capstone of substrate item 0. -/
theorem ClogUpper_add (z w : Complex)
    (knz : Nat) (hknz : Qlt (Qbound knz) ((cnormSq z).seq knz))
    (knw : Nat) (hknw : Qlt (Qbound knw) ((cnormSq w).seq knw))
    (knzw : Nat) (hknzw : Qlt (Qbound knzw) ((cnormSq (Cmul z w)).seq knzw))
    (kz : Nat) (hkz : Qlt (Qbound kz) (z.re.seq kz))
    (kw : Nat) (hkw : Qlt (Qbound kw) (w.im.seq kw))
    (kzw : Nat) (hkzw : Qlt (Qbound kzw) ((Cmul z w).im.seq kzw))
    (kp : Nat) (hkp : Qlt (Qbound kp) ((Cmul (swapC w) (Cconj z)).re.seq kp))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩)
    (hbz : ∀ n, Qle (Qabs ((Rdiv z.im z.re kz hkz).seq n)) ρ)
    (hbcz : ∀ n, Qle (Qabs ((Rdiv (Cconj z).im (Cconj z).re kz hkz).seq n)) ρ)
    (hbw : ∀ n, Qle (Qabs ((Rdiv w.re w.im kw hkw).seq n)) ρ)
    (hbzw : ∀ n, Qle (Qabs ((Rdiv (Cmul z w).re (Cmul z w).im kzw hkzw).seq n)) ρ)
    (hbp : ∀ n, Qle (Qabs ((Rdiv (Cmul (swapC w) (Cconj z)).im
      (Cmul (swapC w) (Cconj z)).re kp hkp).seq n)) ρ)
    (hbvv : ∀ n, Qle (Qabs (vval ((Rdiv (swapC w).im (swapC w).re kw hkw).seq n)
      ((Rdiv (Cconj z).im (Cconj z).re kz hkz).seq n))) ρ)
    (hmod : Req (RlogPos (cnormSq (Cmul z w)) knzw hknzw)
      (Radd (RlogPos (cnormSq z) knz hknz) (RlogPos (cnormSq w) knw hknw))) :
    Ceq (ClogUpper (Cmul z w) knzw hknzw kzw hkzw ρ hρ0 hρd hlt hbzw)
        (Cadd (Clog z knz hknz kz hkz ρ hρ0 hρd hlt hbz)
              (ClogUpper w knw hknw kw hkw ρ hρ0 hρd hlt hbw)) :=
  ⟨Req_trans (Rmul_congr (Req_refl half) hmod)
      (Rmul_distrib half (RlogPos (cnormSq z) knz hknz) (RlogPos (cnormSq w) knw hknw)),
   CargUpper_add z w kz hkz kw hkw kzw hkzw kp hkp ρ hρ0 hρd hlt hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1
     hbz hbcz hbw hbzw hbp hbvv⟩

end UOR.Bridge.F1Square.Analysis
