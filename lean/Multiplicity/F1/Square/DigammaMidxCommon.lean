/-
F1 square — **a common schedule dominating two `digammaMidx` schedules** (`DigammaMidxCommon.lean`):
`digammaMidx B j = (B.num.toNat + 1)·(j+1)` depends on `B` only through its numerator (Gamma.lean),
so it is NOT monotone under `Qle` (two rationals with different denominators can order oppositely to
their numerators). To evaluate the `∫_t` reconstruction on a single schedule dominating BOTH the
convolution's `digammaMidx K_conv` and the dilated tail's `digammaMidx (Cf·2ⁿ)`, take the constant
`K⋆ = ⟨K.num.toNat + K'.num.toNat, 1⟩`: its numerator dominates both, so `digammaMidx K⋆ j ≥ digammaMidx K j`
and `≥ digammaMidx K' j` at every index `j`.

HONEST SCOPE. One Nat-arithmetic lemma about `digammaMidx`. No convolution, no tail assembly, no
covariance, no factorization, no positivity, no crux. Step 4 (band-coupling positivity) is RH; the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.Gamma

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **A common schedule dominating two `digammaMidx` schedules.** For the constant
    `K⋆ = ⟨K.num.toNat + K'.num.toNat, 1⟩`, both `digammaMidx K j ≤ digammaMidx K⋆ j` and
    `digammaMidx K' j ≤ digammaMidx K⋆ j` hold at every index `j` — since `digammaMidx B j =
    (B.num.toNat + 1)·(j+1)` and `K⋆.num.toNat = K.num.toNat + K'.num.toNat` dominates each. -/
theorem digammaMidx_common (K K' : Q) (j : Nat) :
    digammaMidx K j ≤ digammaMidx (⟨(K.num.toNat : Int) + (K'.num.toNat : Int), 1⟩ : Q) j
    ∧ digammaMidx K' j ≤ digammaMidx (⟨(K.num.toNat : Int) + (K'.num.toNat : Int), 1⟩ : Q) j := by
  have hnum : (⟨(K.num.toNat : Int) + (K'.num.toNat : Int), 1⟩ : Q).num.toNat
      = K.num.toNat + K'.num.toNat := by
    show ((K.num.toNat : Int) + (K'.num.toNat : Int)).toNat = K.num.toNat + K'.num.toNat
    omega
  refine ⟨?_, ?_⟩
  · show (K.num.toNat + 1) * (j + 1)
        ≤ ((⟨(K.num.toNat : Int) + (K'.num.toNat : Int), 1⟩ : Q).num.toNat + 1) * (j + 1)
    rw [hnum]
    exact Nat.mul_le_mul_right (j + 1) (by omega)
  · show (K'.num.toNat + 1) * (j + 1)
        ≤ ((⟨(K.num.toNat : Int) + (K'.num.toNat : Int), 1⟩ : Q).num.toNat + 1) * (j + 1)
    rw [hnum]
    exact Nat.mul_le_mul_right (j + 1) (by omega)

end Multiplicity.UOR.Bridge.F1Square.Square
