/-
F1 square — Track 1, item-0 brick: **lower-sector complex-log additivity** `ClogLower(zw) = Clog z +
ClogLower w` (principal `z` times lower `w`, product lower). The `Clog`-level lift of `CargLower_add`,
completing the lower half of the four-sector `log(zw) = log z + log w` law toward `log ξ`.

Mirrors `ClogUpper_add` (`ComplexLogUpperAdd.lean`): the real part is the modulus-log additivity
`½·log|zw|² = ½·log|z|² + ½·log|w|²` (the `hmod` congruence `|zw|² = |z|²·|w|²`, carried as a hypothesis,
plus `Rmul_distrib`), and the imaginary part is the lower-sector argument additivity `CargLower_add`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Core.F1.Analysis.ComplexLogLower

namespace UOR.Bridge.F1Square.Analysis

/-- **★ lower-sector log additivity** `ClogLower(zw) = Clog z + ClogLower w` — principal `z` times lower
    `w`. Real part: modulus-log additivity (`hmod` + `Rmul_distrib half`); imaginary part: the
    lower-sector argument additivity `CargLower_add`. -/
theorem ClogLower_add (z w : Complex)
    (knz : Nat) (hknz : Qlt (Qbound knz) ((cnormSq z).seq knz))
    (knw : Nat) (hknw : Qlt (Qbound knw) ((cnormSq w).seq knw))
    (knzw : Nat) (hknzw : Qlt (Qbound knzw) ((cnormSq (Cmul z w)).seq knzw))
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
      ((Rdiv (Cconj (Cconj z)).im (Cconj (Cconj z)).re kz hkz).seq n))) ρ)
    (hmod : Req (RlogPos (cnormSq (Cmul z w)) knzw hknzw)
      (Radd (RlogPos (cnormSq z) knz hknz) (RlogPos (cnormSq w) knw hknw))) :
    Ceq (ClogLower (Cmul z w) knzw hknzw kzw hkzw ρ hρ0 hρd hlt hbzw)
        (Cadd (Clog z knz hknz kz hkz ρ hρ0 hρd hlt hbz)
              (ClogLower w knw hknw kw hkw ρ hρ0 hρd hlt hbw)) :=
  ⟨Req_trans (Rmul_congr (Req_refl half) hmod)
      (Rmul_distrib half (RlogPos (cnormSq z) knz hknz) (RlogPos (cnormSq w) knw hknw)),
   CargLower_add z w kz hkz kw hkw kzw hkzw kp hkp kc hkc ρ hρ0 hρd hlt hlt16 h2ρ hhalf hρ4 hρ2 hρ8
     hρ1 hbz hbcz hbczz hbw hbzw hbc hbp hbvv⟩

end UOR.Bridge.F1Square.Analysis
