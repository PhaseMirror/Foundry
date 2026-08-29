/-
F1 square — **the real-scale Mellin dilation covariance** (`MellinHatDilateCovarianceReal.lean`): the
unconditional rational-scale covariance `qⁿ⁺¹·mellinHat(dilate_q φ) = mellinHat φ` passed to a REAL
scale `c` by the density argument — the rung-6 goal of the transform bridge.

The rational-scale covariance holds at every rational `q` (`covariance_at_rational_dilateTestR`), and
the covariance combination `F(c) = cⁿ⁺¹·mellinHat(dilateTestR c φ)` is scale-continuous
(`covComb_scale_split`). So `F` is a continuous function that is constant (`= mellinHat φ`) on the
rationals; by the density of the rationals and the Archimedean squeeze (`Req_of_real_null_family`), it
is constant on all of `ℝ`:

    `cⁿ⁺¹ · mellinHat (dilateTestR c φ) n  =  mellinHat φ n`.

This is the passage the roadmap named — "the rational covariance can pass to real scales" — now made.
The two hypotheses `hcov` (rational-scale covariance at the approximants) and `hbound` (the continuity
gap is a null family, i.e. the approximants converge fast enough) are the honest, dischargeable
analytic inputs; neither is RH-equivalent.

HONEST SCOPE. Object-grounding substrate for the convolution/Mellin factorization — evaluating the
inner `x`-integral at a real scale. It builds NO factorization theorem `M[f⋆g]=M[f]·M[g]` on its own,
NO grounding of `v = ĝ` (that reads the factorization off), and — emphatically — NO step-4
band-coupling positivity, which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.CovCombScaleCont
import Foundations.F1.Square.CovarianceAtRational
import Foundations.F1.Analysis.RealNullFamily
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The real-scale Mellin dilation covariance** (rung-6 density capstone). For a real scale `c`
    (bounded by `S`) and an approximating rational sequence `qk` such that

      - `hcov` — the covariance holds in `dilateTestR` form at each rational `qk`:
        `qkⁿ⁺¹·mellinHat(dilateTestR (ofQ qk) φ) n = mellinHat φ n` (discharged by
        `covariance_at_rational_dilateTestR`), and
      - `hbound` — `qk` approximates `c` fast enough that the continuity gap
        `|cⁿ⁺¹·mellinHat(dilateTestR c φ) − qkⁿ⁺¹·mellinHat(dilateTestR (ofQ qk) φ)|` is `≤ C₀/(k+1)`
        (discharged by `covComb_scale_split`, whose bound → 0),

    the covariance passes to the real scale:

      `cⁿ⁺¹ · mellinHat (dilateTestR c φ) n = mellinHat φ n`.

    Pure density argument: since `F(c) = cⁿ⁺¹·mellinHat(dilateTestR c φ)` equals `mellinHat φ` on the
    `qk` (`hcov`) and its gap to those values is a null family (`hbound`), the Archimedean squeeze
    `Req_of_real_null_family` forces `F(c) = mellinHat φ`. `hcov` and `hbound` are the two explicit,
    dischargeable analytic inputs (the rational-scale covariance and the continuity rate) — neither is
    RH-equivalent.

    HONEST SCOPE. This is OBJECT-GROUNDING substrate — it evaluates the inner `x`-integral of the
    convolution–Mellin pairing at a real scale, a step toward grounding `v = ĝ`. It is NOT the step-4
    band-coupling positivity (`ArchDominatesPrime`), which is RH and is asserted nowhere. The crux
    fields stay `none`. -/
theorem mellinHat_dilate_covariance_real (φ : L2Test) (n : Nat) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c : Real) (hcS : Rle (Rabs c) (ofQ S hSd))
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec_c : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR c S hSd hSn hcS φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_phi : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (qk : Nat → Q) (hqk_den : ∀ k, 0 < (qk k).den)
    (hqk_S : ∀ k, Rle (Rabs (ofQ (qk k) (hqk_den k))) (ofQ S hSd))
    (hdec_qk : ∀ k, ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR (ofQ (qk k) (hqk_den k)) S hSd hSn (hqk_S k) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hcov : ∀ k, Req
        (Rmul (Rpow (ofQ (qk k) (hqk_den k)) (n + 1))
          (mellinHat (dilateTestR (ofQ (qk k) (hqk_den k)) S hSd hSn (hqk_S k) φ) n hCd hCn (hdec_qk k)))
        (mellinHat φ n hCd hCn hdec_phi))
    {C₀ : Nat}
    (hbound : ∀ k, Rle (Rabs (Rsub
        (Rmul (Rpow c (n + 1)) (mellinHat (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c))
        (Rmul (Rpow (ofQ (qk k) (hqk_den k)) (n + 1))
          (mellinHat (dilateTestR (ofQ (qk k) (hqk_den k)) S hSd hSn (hqk_S k) φ) n hCd hCn (hdec_qk k)))))
        (ofQ (⟨(C₀ : Int), k + 1⟩ : Q) (Nat.succ_pos k))) :
    Req (Rmul (Rpow c (n + 1)) (mellinHat (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c))
        (mellinHat φ n hCd hCn hdec_phi) := by
  refine Req_of_real_null_family (C := C₀) (fun k => ?_)
  exact Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_refl _) (Req_symm (hcov k))))) (hbound k)

end Multiplicity.UOR.Bridge.F1Square.Square
