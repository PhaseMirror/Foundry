/-
F1 square — **the rational-scale dilation covariance in `dilateTestR` form** (`CovarianceAtRational.lean`):
the unconditional rational-scale Mellin dilation covariance
`qⁿ⁺¹·mellinHat(dilateTest q φ) = mellinHat φ` (`mellinHat_dilate_covariance_uncond`) read against the
REAL-scale dilation `dilateTestR (ofQ q)`:

    `qⁿ⁺¹ · mellinHat (dilateTestR (ofQ q) φ) n  =  mellinHat φ n`.

WHY (rung 6, staging the real-scale covariance capstone). The covariance is proven in `dilateTest`
(rational-scale) form, whereas the real-scale continuity foundation (`mellinHat_scale_split`) and the
capstone's approximating sequence `q_k → c` live in `dilateTestR` form. This file rewrites the
covariance through the representation bridge (`mellinHat_bridge`, which equates the two forms' Mellin
data at a rational scale) so it reads in `dilateTestR` form — the exact shape the real-scale limit
`q_k → c` consumes: it lets `mellinHat φ` be replaced by `q_kⁿ⁺¹·mellinHat(dilateTestR (ofQ q_k) φ)` at
every rational `q_k`, whose limit against `mellinHat_scale_split` + `Rpow_base_lip` is the real-scale
covariance.

The proof is a one-step composition: pull the bridge (`mellinHat_bridge`) inside the scalar `qⁿ⁺¹`
(`Rmul_congr`), then apply the covariance (`mellinHat_dilate_covariance_uncond`). It changes only the
REPRESENTATION of the covariance, not its content.

HONEST SCOPE. The rational-scale covariance re-expressed in `dilateTestR` form only. It builds NO
real-scale covariance (that is the capstone: pass this to the limit `q_k → c`), NO factorization, NO
half-line assembly, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH;
the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.DilateTestBridge
import Multiplicity.F1Square.Square.HtileDischarge

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The rational-scale dilation covariance in `dilateTestR` form.** For a rational scale `q > 0`
    bounded by `S`, `qⁿ⁺¹ · mellinHat (dilateTestR (ofQ q) φ) n = mellinHat φ n`. The unconditional
    covariance `mellinHat_dilate_covariance_uncond` (stated with `dilateTest q`) transported through the
    representation bridge `mellinHat_bridge` (which equates `mellinHat (dilateTest q φ)` and
    `mellinHat (dilateTestR (ofQ q) φ)`). The decay/regularity data are exactly those the covariance
    itself requires (`hdec_dil` serves both `dilateTest q φ` and — by defeq `.f` — `dilateTestR (ofQ q) φ`).
    The rational-scale covariance in the shape the real-scale limit `q_k → c` consumes. -/
theorem covariance_at_rational_dilateTestR (φ : L2Test) (n : Nat) (q : Q)
    (hqn : 0 < q.num) (hqd : 0 < q.den)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num) (hqS : Rle (Rabs (ofQ q hqd)) (ofQ S hSd))
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec_dil : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest q hqn hqd φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_phi : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_fine : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest (⟨1, q.den⟩ : Q) Int.zero_lt_one hqd φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hReg : RReg (fun j => genSum (fun m => scaledTwTerm φ q hqn hqd n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))) :
    Req (Rmul (ofQ (qpow q (n + 1)) (qpow_den_pos hqd (n + 1)))
          (mellinHat (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) n hCd hCn hdec_dil))
        (mellinHat φ n hCd hCn hdec_phi) := by
  refine Req_trans (Rmul_congr (Req_refl _) (Req_symm
    (mellinHat_bridge φ n q hqn hqd S hSd hSn hqS hCd hCn hdec_dil))) ?_
  exact mellinHat_dilate_covariance_uncond φ n q hqn hqd hCd hCn hdec_dil hdec_phi hdec_fine hReg

end Multiplicity.UOR.Bridge.F1Square.Square
