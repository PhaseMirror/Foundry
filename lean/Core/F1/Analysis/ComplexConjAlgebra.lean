/-
F1 square — Track 1: **conjugation algebra** — `Cconj` as a ring/limit homomorphism: congruence,
involution, distribution over `Cadd`/`Cneg`, fixing of reals, and commuting with the complex finite
sum `CsumN`.

These are the reusable componentwise/induction lemmas the *assembly* conjugations need — the
`CSpougeGammaW` Spouge bracket `c₀ + Σ cₖ/(s+k)` (a `CsumN`/`Cadd` of `Cinv` terms, toward the Γ-side
of `Cxi_conj`) and the `Ceta` block sums (the ζ-side). With `Cconj_Cmul` (`ComplexArgLower`),
`Cexp_conj`/`Cinv_conj` (`ComplexDigammaConj`), `Cpow_conj` (`ComplexLogConj`), and `Clim_Cconj`, this
completes the conjugation toolbox.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ComplexSeries
import Core.F1.Analysis.Reflection

namespace UOR.Bridge.F1Square.Analysis

/-- `Cconj` respects `≈` (real part fixed, imaginary part negated). -/
theorem Cconj_congr {z w : Complex} (h : Ceq z w) : Ceq (Cconj z) (Cconj w) :=
  ⟨h.1, Rneg_congr h.2⟩

/-- **`Cconj` is an involution**: `conj(conj z) = z`. -/
theorem Cconj_Cconj (z : Complex) : Ceq (Cconj (Cconj z)) z :=
  ⟨Req_refl z.re, Rneg_neg z.im⟩

/-- **`Cconj` distributes over `Cadd`**: `conj(z + w) = conj z + conj w`. -/
theorem Cconj_Cadd (z w : Complex) : Ceq (Cconj (Cadd z w)) (Cadd (Cconj z) (Cconj w)) :=
  ⟨Req_refl (Radd z.re w.re), Rneg_Radd z.im w.im⟩

/-- **`Cconj` commutes with `Cneg`**: `conj(−z) = −conj z`. -/
theorem Cconj_Cneg (z : Complex) : Ceq (Cconj (Cneg z)) (Cneg (Cconj z)) :=
  ⟨Req_refl (Rneg z.re), Req_refl (Rneg (Rneg z.im))⟩

/-- **`Cconj` fixes the reals**: `conj(ofReal x) = ofReal x`. -/
theorem Cconj_ofReal (x : Real) : Ceq (Cconj (ofReal x)) (ofReal x) :=
  ⟨Req_refl x, Rneg_zero⟩

/-- **`Cconj` fixes `0`**: `conj 0 = 0`. -/
theorem Cconj_Czero : Ceq (Cconj Czero) Czero :=
  ⟨Req_refl zero, Rneg_zero⟩

/-- **`Cconj` commutes with the complex finite sum**: `conj(Σ_{k<N} F k) = Σ_{k<N} conj(F k)`. The
    bridge for conjugating the Spouge bracket and the `Ceta` blocks. -/
theorem CsumN_Cconj (F : Nat → Complex) : ∀ N,
    Ceq (Cconj (CsumN F N)) (CsumN (fun n => Cconj (F n)) N)
  | 0 => Cconj_Czero
  | (n + 1) =>
      Ceq_trans (Cconj_Cadd (CsumN F n) (F n))
        (Cadd_congr (CsumN_Cconj F n) (Ceq_refl (Cconj (F n))))

end UOR.Bridge.F1Square.Analysis
