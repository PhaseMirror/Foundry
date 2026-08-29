/-
F1 square — **the Bernstein basis pairs to zero at the completion level**
(`PairingBernBasisZero.lean`). H₁'s `innerI_clampProd_zero`/`innerI_bernBasis_zero` proved, for a fixed
test `φ` with vanishing moments, that `⟨φ, C(n,k)·xᵏ(1−x)ⁿ⁻ᵏ⟩ ≈ 0`. This brick lifts that to a **limit
member**: for a uniformly-L²-Cauchy sequence `Φ` whose extended moments `pairingIU Φ (xⁱ) h` all
vanish, the extended pairing against every Bernstein basis element vanishes
(`pairingIU_bernBasis_zero`). The proof is the identical Pascal recursion, with `innerI` replaced by
`pairingIU` throughout: `pairingIU_unit_congr` carries the unit-restriction step, `pairingIU_sub_right`
the split, and `pairingIU_natScale` the binomial normalization.

HONEST SCOPE. The extended pairing against a Bernstein basis vanishes when all extended moments vanish;
a step toward completion-level moment determinacy. NOT positivity, NOT surjectivity. Step 4 is RH; the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.PairingIULinear2
import Foundations.F1.Square.BernsteinBasisZero

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `natScaleR` respects `Req`. -/
private theorem natScaleR_congr {a b : Real} (hab : Req a b) :
    ∀ c, Req (natScaleR c a) (natScaleR c b)
  | 0 => Req_refl _
  | c + 1 => Radd_congr hab (natScaleR_congr hab c)

/-- `c · 0 = 0` (real repeated addition of `zero`). -/
private theorem natScaleR_zero : ∀ c, Req (natScaleR c zero) zero
  | 0 => Req_refl zero
  | c + 1 => Req_trans (Radd_congr (Req_refl zero) (natScaleR_zero c)) (Radd_zero zero)

/-- **THE CLAMP-PRODUCT FACTOR PAIRS TO ZERO AT THE COMPLETION LEVEL**: if every extended moment of `Φ`
    vanishes, then `pairingIU Φ (clamp01ᵏ·(1−clamp01)ᵐ) h ≈ 0` for every `k, m`. Induction on `m`: the
    base `m = 0` is the `k`-th extended moment (via `[0,1]`-congruence to `xᵏ`); the step is the Pascal
    recursion, carried by `pairingIU_unit_congr` and split by `pairingIU_sub_right`. -/
theorem pairingIU_clampProd_zero (Φ : Nat → L2Test) (h : L2CauchyU Φ)
    (hmom : ∀ i, Req (pairingIU Φ (powTest i) h) zero) :
    ∀ m k, Req (pairingIU Φ (clampProdTest k m) h) zero
  | 0, k => by
    refine Req_trans (pairingIU_unit_congr Φ (clampProdTest k 0) (powTest k) h ?_) (hmom k)
    intro x _ _
    show Req (Rmul ((powTest k).f x) one) ((powTest k).f x)
    exact Rmul_one _
  | m + 1, k => by
    refine Req_trans (pairingIU_unit_congr Φ (clampProdTest k (m + 1))
      (L2Test.sub (clampProdTest k m) (clampProdTest (k + 1) m)) h
      (fun x _ _ => clampProd_step_pt k m x)) ?_
    refine Req_trans (pairingIU_sub_right Φ (clampProdTest k m) (clampProdTest (k + 1) m) h) ?_
    exact Req_trans (Rsub_congr (pairingIU_clampProd_zero Φ h hmom m k)
      (pairingIU_clampProd_zero Φ h hmom m (k + 1))) (Radd_neg zero)

/-- **★ THE BERNSTEIN BASIS PAIRS TO ZERO AT THE COMPLETION LEVEL**: if every extended moment of `Φ`
    vanishes, then `pairingIU Φ (C(n,k)·clamp01ᵏ·(1−clamp01)ⁿ⁻ᵏ) h ≈ 0` — the normalized basis, through
    the `ℕ`-homogeneity of the extended pairing (`pairingIU_natScale`). -/
theorem pairingIU_bernBasis_zero (Φ : Nat → L2Test) (h : L2CauchyU Φ)
    (hmom : ∀ i, Req (pairingIU Φ (powTest i) h) zero) (n k : Nat) :
    Req (pairingIU Φ (bernBasisTest n k) h) zero := by
  show Req (pairingIU Φ (natScale (choose n k) (clampProdTest k (n - k))) h) zero
  refine Req_trans (pairingIU_natScale Φ (choose n k) (clampProdTest k (n - k)) h) ?_
  refine Req_trans (natScaleR_congr (pairingIU_clampProd_zero Φ h hmom (n - k) k) (choose n k)) ?_
  exact natScaleR_zero (choose n k)

end Multiplicity.UOR.Bridge.F1Square.Square
