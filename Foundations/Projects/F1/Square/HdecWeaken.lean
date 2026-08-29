/-
F1 square — **window-decay constant weakening** (`HdecWeaken.lean`): a test's order-`(n+2)` window
decay at a constant `C₁` implies the same at any larger `C₂` (`Qle C₁ C₂`). The uniform tool the
`c ≥ 1` covariance wall-break uses to lift the reconstruction's tight `Cf`-decay of `φ` / the `c ≥ 1`
dilate to the larger per-approximant constant `C' = (Cf+φ.M)·(2·qk.den)^{n+2}` that
`covariance_at_rational_dilateTestR` demands (its `hdec_dil`/`hdec_phi` share one `C` with the fine
decay).

HONEST SCOPE. One monotone weakening of the window-decay hypothesis. NO covariance, NO factorization,
NO positivity, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MellinHat
import Foundations.F1.Square.WindowPower
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Window-decay weakening.** If `ψ` has order-`(n+2)` window decay at constant `C₁`, and `C₁ ≤ C₂`,
    then it has the same decay at `C₂` — since `C₁/(m+1)^{n+2} ≤ C₂/(m+1)^{n+2}` (`ofQ` monotone in the
    numerator constant, `qmul_le_right_mono`). Generic in the test `ψ`, so it serves both `φ` and the
    dilated test. -/
theorem hdec_window_weaken (ψ : L2Test) (n : Nat) {C1 C2 : Q}
    (hCd1 : 0 < C1.den) (hCd2 : 0 < C2.den) (hC12 : Qle C1 C2)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (ψ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C1 (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd1 (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (ψ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C2 (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd2 (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))) := by
  intro m x h0 h1
  refine Rle_trans (hdec m x h0 h1) (Rle_ofQ_ofQ
    (Qmul_den_pos hCd1 (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))
    (Qmul_den_pos hCd2 (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))
    (qmul_le_right_mono hC12 (by decide : (0 : Int) ≤ 1)))

end Multiplicity.UOR.Bridge.F1Square.Square
