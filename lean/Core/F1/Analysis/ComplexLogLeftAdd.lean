/-
F1 square — Track 1, item-0 brick: **left-sector complex-log additivity** `ClogLeft(zw) = ClogLeft z +
Clog w` (left `z` times principal `w`, product left). The `Clog`-level lift of `CargLeft_add`,
completing the four-sector `log(zw) = log z + log w` law toward `log ξ`.

Mirrors `ClogUpper_add`/`ClogLower_add`: the real part is the modulus-log additivity `½·log|zw|² =
½·log|z|² + ½·log|w|²` (the `hmod` congruence `|zw|² = |z|²·|w|²`, carried as a hypothesis, plus
`Rmul_distrib`), and the imaginary part is the left-sector argument additivity `CargLeft_add`. (The
modulus witnesses are named `mn…` to avoid clashing with `CargLeft_add`'s `(−z).re` argument witness
`knz`.)

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Core.F1.Analysis.ComplexLogLeft
import Core.F1.Analysis.ComplexArgLeftAdd

namespace UOR.Bridge.F1Square.Analysis

/-- **★ left-sector log additivity** `ClogLeft(zw) = ClogLeft z + Clog w` — left `z` times principal
    `w`. Real part: modulus-log additivity (`hmod` + `Rmul_distrib half`); imaginary part: the
    left-sector argument additivity `CargLeft_add`. -/
theorem ClogLeft_add (z w : Complex)
    (mnz : Nat) (hmnz : Qlt (Qbound mnz) ((cnormSq z).seq mnz))
    (mnw : Nat) (hmnw : Qlt (Qbound mnw) ((cnormSq w).seq mnw))
    (mnzw : Nat) (hmnzw : Qlt (Qbound mnzw) ((cnormSq (Cmul z w)).seq mnzw))
    (knz : Nat) (hknz : Qlt (Qbound knz) ((Cneg z).re.seq knz))
    (kw : Nat) (hkw : Qlt (Qbound kw) (w.re.seq kw))
    (kzw : Nat) (hkzw : Qlt (Qbound kzw) ((Cneg (Cmul z w)).re.seq kzw))
    (kp : Nat) (hkp : Qlt (Qbound kp) ((Cmul (Cneg z) w).re.seq kp))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩)
    (hbnz : ∀ n, Qle (Qabs ((Rdiv (Cneg z).im (Cneg z).re knz hknz).seq n)) ρ)
    (hbw : ∀ n, Qle (Qabs ((Rdiv w.im w.re kw hkw).seq n)) ρ)
    (hbzw : ∀ n, Qle (Qabs ((Rdiv (Cneg (Cmul z w)).im (Cneg (Cmul z w)).re kzw hkzw).seq n)) ρ)
    (hbp : ∀ n, Qle (Qabs ((Rdiv (Cmul (Cneg z) w).im (Cmul (Cneg z) w).re kp hkp).seq n)) ρ)
    (hbvv : ∀ n, Qle (Qabs (vval ((Rdiv (Cneg z).im (Cneg z).re knz hknz).seq n)
      ((Rdiv w.im w.re kw hkw).seq n))) ρ)
    (hmod : Req (RlogPos (cnormSq (Cmul z w)) mnzw hmnzw)
      (Radd (RlogPos (cnormSq z) mnz hmnz) (RlogPos (cnormSq w) mnw hmnw))) :
    Ceq (ClogLeft (Cmul z w) mnzw hmnzw kzw hkzw ρ hρ0 hρd hlt hbzw)
        (Cadd (ClogLeft z mnz hmnz knz hknz ρ hρ0 hρd hlt hbnz)
              (Clog w mnw hmnw kw hkw ρ hρ0 hρd hlt hbw)) :=
  ⟨Req_trans (Rmul_congr (Req_refl half) hmod)
      (Rmul_distrib half (RlogPos (cnormSq z) mnz hmnz) (RlogPos (cnormSq w) mnw hmnw)),
   CargLeft_add z w knz hknz kw hkw kzw hkzw kp hkp ρ hρ0 hρd hlt hlt16 h2ρ hhalf hρ4 hρ2 hρ8
     hρ1 hbnz hbw hbzw hbp hbvv⟩

end UOR.Bridge.F1Square.Analysis
