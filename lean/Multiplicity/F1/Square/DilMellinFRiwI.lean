/-
F1 square — **the inner integral evaluated: `cⁿ⁺¹·dilMellinF = riwI`** (`DilMellinFRiwI.lean`): the
convolution–Mellin inner `x`-integral at the moment window, scaled by `cⁿ⁺¹`, is the real-window
integral of `f` against the twist weight:

    `cⁿ⁺¹ · dilMellinF f (powTest n) S a t [0,1]  =  riwI (f · powBandGen_{[0,B]}) qk …`,
    `c = clampedInv(a,t)`,

i.e. `dilMellinF = c^{-(n+1)}·∫_0^c (f·xⁿ)` — the change-of-variables that turns the dilated inner
integral into a genuine window integral of `f`. A one-line composition of the two committed results:
`dilMellinF_eq_mellinMoment` (`dilMellinF = mellinMoment(dilateTestR c f) n`) and the real-scale moment
covariance `riwI_moment_covariance` (`riwI = cⁿ⁺¹·mellinMoment(dilateTestR c f) n`).

WHY. `mellinConv_gpull` writes the convolution–Mellin pairing as `∫_t (g(t)·clampedInv(a,t))·dilMellinF(t) dt`.
Substituting `dilMellinF = c_t^{-(n+1)}·riwI` (this lemma) is the step that turns the inner integral into a
scaled window integral of `f`; the `∫_t` assembly (the scaled-window tiling reconstructing `M[f]`) is what
remains for the factorization `M[f⋆g]=M[f]·M[g]`.

HONEST SCOPE. The evaluated inner integral (moment window). It builds NO `∫_t` assembly, NO factorization,
NO half-line assembly, NO positivity, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.DilMellinFEval
import Multiplicity.F1Square.Square.RiwIMomentCovariance

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **`cⁿ⁺¹·dilMellinF = riwI`.** The convolution–Mellin inner integral at the moment window `[0,1]`,
    scaled by `cⁿ⁺¹` (`c = clampedInv(a,t)`), is the real-window integral of `f` against the twist
    weight — the change-of-variables `dilMellinF = c^{-(n+1)}·∫_0^c (f·xⁿ)`. Composition of
    `dilMellinF_eq_mellinMoment` and `riwI_moment_covariance`. -/
theorem dilMellinF_pow_eq_riwI (f : L2Test) (n : Nat) (B S : Q) (hBd : 0 < B.den)
    (hleB : Qle (⟨0, 1⟩ : Q) B) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real)
    (hS1 : Qle (⟨1, 1⟩ : Q) S)
    (hcS : Rle (Rabs (clampedInv a han had t)) (ofQ S hSd))
    (qk : Nat → Q) (hqk_pos : ∀ k, 0 < (qk k).num) (hqk_den : ∀ k, 0 < (qk k).den)
    (hqk_fast : ∀ j k, Qle (mul (Qabs (Qsub (qk j) (qk k))) (bandTwistTest f B hBd hleB n).M)
      (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
    (m : Nat → Nat) (hm : ∀ k, k ≤ m k)
    (hqk_B : ∀ k, Qle (add (qk (m k)) (⟨1, 1⟩ : Q)) B)
    (hqk_mS : ∀ k, Rle (Rabs (ofQ (qk (m k)) (hqk_den (m k)))) (ofQ S hSd))
    (hconv : ∀ k, Rle (Rabs (Rsub (clampedInv a han had t) (ofQ (qk (m k)) (hqk_den (m k)))))
      (ofQ (⟨1, momCovIdx f S n k + 1⟩ : Q) (Nat.succ_pos (momCovIdx f S n k)))) :
    Req (Rmul (Rpow (clampedInv a han had t) (n + 1))
          (dilMellinF f (powTest n) S hSd a han had t (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q)
            (by decide) (by decide) (by decide)))
        (riwI (bandTwistTest f B hBd hleB n) qk hqk_pos hqk_den hqk_fast) :=
  Req_trans
    (Rmul_congr (Req_refl _)
      (dilMellinF_eq_mellinMoment f n S hSd a han had t hS1 S hSd hSn hcS))
    (Req_symm (riwI_moment_covariance f n B S hBd hleB hSd hSn
      (clampedInv a han had t) hcS qk hqk_pos hqk_den hqk_fast m hm hqk_B hqk_mS hconv))

end Multiplicity.UOR.Bridge.F1Square.Square
