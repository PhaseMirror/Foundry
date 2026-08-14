/-
F1 square — **the honest ASYMMETRIC autocorrelation factorization** (`ConvAutocorrFactor.lean`):
Milestone B sub-goal 2, g-side, made kernel-explicit — including exactly where the wall is.

For self-dual tests `g_i = selfDualTest a φ_i`, `g_j = selfDualTest a φ_j` (with `φ_j` vanishing
outside the reciprocal-symmetric window `(a, 1/a)`), on the maximal admissible window `[a, 1]`,

    `convMellinHat g_i (reflectTest a g_j) m  ≈  mellinHat g_i m · mellinMoment g_j m`
    (`M[g_i ⋆ g_j^τ](m) = mellinHat(g_i)(m) · mellinMoment(g_j)(m)`).

The route composes the built pieces: `convMellinHat_eq_MfMoment` (window `[a,1]`) factors the
convolution transform into `mellinHat(g_i) · ∫_{[a,1]}(reflectTest a g_j)·tᵐ`; then
`windowMoment_reflect_selfDual` (brick 1) swaps the reflected weight for the plain one, and
`windowMoment_eq_mellinMoment` (brick 2, fed the `[0,a]`-vanishing from `selfDual_vanish_below_floor`)
collapses `∫_{[a,1]} g_j·tᵐ` to `mellinMoment g_j m`. No change of variables.

WHY THIS IS THE HONEST BOUNDARY. The factorization is genuinely **asymmetric**: the `f`-side carries
`g_i`'s FULL half-line transform `mellinHat(g_i)`, the `g`-side only the `[0,1]` moment
`mellinMoment(g_j)`. The coupled kernel's `weilPrimeGram (vHat g)(i,j) = Σ Λ·mellinMoment(g_i)·
mellinMoment(g_j)` is **symmetric in `mellinMoment`**, so identifying it with the autocorrelation prime
side would require the f-side collapse `mellinHat(g_i)(m) = mellinMoment(g_i)(m)` — which is FALSE for a
self-dual test straddling `x = 1` (`twTail(g_i) ≠ 0`; `mellinHat_compact` needs `supp ⊆ [0,1]`). That is
the window wall, and this file does **not** cross it — it states exactly how far the congruence route
reaches.

HONEST SCOPE. The asymmetric factorization `M[g_i⋆g_j^τ] = mellinHat(g_i)·mellinMoment(g_j)` on `[a,1]`.
NOT the symmetric transform Gram identification (the wall above), NOT any point-value Weil-prime-side
identity (a different functional — conflating them would be smuggling), and NO step-4 positivity
(`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ConvMellinHatFactor
import Multiplicity.F1Square.Square.SelfDualMomentSymmetry

set_option maxHeartbeats 4000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The honest asymmetric autocorrelation factorization**: `convMellinHat g_i (reflectTest a g_j) m ≈
    mellinHat g_i m · mellinMoment g_j m` for self-dual `g_i, g_j` on the window `[a,1]`. Composes
    `convMellinHat_eq_MfMoment` (factors into `mellinHat(g_i)·∫_{[a,1]}(reflectTest a g_j)·tᵐ`), brick 1
    `windowMoment_reflect_selfDual` (drops the reflection), and brick 2 `windowMoment_eq_mellinMoment`
    (fed `selfDual_vanish_below_floor`, collapses to `mellinMoment g_j`). The f-side stays the FULL
    transform `mellinHat(g_i)` — the asymmetry is the window wall, not crossed here. -/
theorem convAutocorr_factor_selfDual (φi φj : L2Test) (m : Nat) {Cf : Q}
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs ((selfDualTest a han had φi).f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (m + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (hlo0j : ∀ y, Rle y (ofQ a had) → Req (φj.f y) zero)
    (hhi0j : ∀ y, Rle (ofQ (Qinv a) (Qinv_den_pos han)) y → Req (φj.f y) zero)
    (hw2n : (0 : Int) ≤ (Qsub (⟨1, 1⟩ : Q) a).num)
    (hw1 : Qle (add a (Qsub (⟨1, 1⟩ : Q) a)) (⟨1, 1⟩ : Q))
    (hhi1 : Qle (add a (Qsub (⟨1, 1⟩ : Q) a)) (Qinv a)) :
    Req (convMellinHat (selfDualTest a han had φi)
          (reflectTest a han had (selfDualTest a han had φj)) m hCfd hCfn hfdec a han had ha1
          a (Qsub (⟨1, 1⟩ : Q) a) had (Qsub_den_pos (by decide) had) hw2n hw1)
        (Rmul (mellinHat (selfDualTest a han had φi) m hCfd hCfn
                (hdec_window_of_hfdec (selfDualTest a han had φi) m hCfd hCfn hfdec))
          (mellinMoment (selfDualTest a han had φj) m)) := by
  refine Req_trans
    (convMellinHat_eq_MfMoment (selfDualTest a han had φi)
      (reflectTest a han had (selfDualTest a han had φj)) m hCfd hCfn hfdec a han had ha1
      a (Qsub (⟨1, 1⟩ : Q) a) had (Qsub_den_pos (by decide) had) hw2n hw1 (Qle_refl a)) ?_
  refine Rmul_congr (Req_refl _) ?_
  refine Req_trans
    (windowMoment_reflect_selfDual a han had φj m a (Qsub (⟨1, 1⟩ : Q) a) had
      (Qsub_den_pos (by decide) had) hw2n (Qle_refl a) hhi1) ?_
  exact windowMoment_eq_mellinMoment (selfDualTest a han had φj) m a han had ha1 hw2n
    (fun x _ hxa => (selfDual_vanish_below_floor a han had φj hlo0j hhi0j hxa).2)

end Multiplicity.UOR.Bridge.F1Square.Square
