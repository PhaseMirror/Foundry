/-
F1 square — **the rational↔real dilation bridge for the Mellin transform**
(`DilateTestBridge.lean`): at a rational scale `q`, the rational-scale dilation `dilateTest q φ` and
the real-scale dilation `dilateTestR (ofQ q) φ` have LITERALLY IDENTICAL values
(`(dilateTest q φ).f x = φ.f (Rmul (ofQ q) x) = (dilateTestR (ofQ q) φ).f x`), differing only in their
Lipschitz-modulus field (`φ.L·q` vs `φ.L·S`). Since the certified Mellin objects depend only on the
integrand values (certificate independence), the two representations give the SAME moment, the SAME
twisted tail, and the SAME transform.

WHY (rung 6, connecting the two dilation representations). The unconditional rational-scale half-line
covariance (`mellinHat_dilate_covariance_uncond`) is stated with `dilateTest` (rational scale), while
the real-scale continuity foundation (`mellinMoment_scale_lipschitz` and friends) is stated with
`dilateTestR` (real scale). The real-scale covariance capstone approximates the real scale `c` by
rationals `q_k`, applies the covariance at each `q_k` (in `dilateTest` form), and passes to the limit
against the continuity (in `dilateTestR` form). This file is the connective tissue: it lets the
`dilateTest`-form covariance be read as a `dilateTestR`-form statement at every rational scale.

The bridges are pure certificate independence: `mellinMoment_bridge` is one application of
`riemannIntegral_certif_irrel` on the common (defeq) product integrand; `twTail_bridge` is
`Rlim_congr` + `genSum_congr` over the per-window `twTerm_bridge` (`riemannIntegralI_certif_irrel`);
`mellinHat_bridge` adds the two halves (`Radd_congr`). The decay hypothesis transfers verbatim because
the two tests have defeq `.f`.

HONEST SCOPE. A representation bridge only — equating the two dilation forms' Mellin data at a rational
scale. It builds NO real-scale covariance, NO continuity, NO factorization, NO half-line assembly, NO
positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.TestAlgebra
import Multiplicity.F1Square.Analysis.DilateTestR
import Multiplicity.F1Square.Square.MultShift
import Multiplicity.F1Square.Analysis.IntegralCertIrrel
import Multiplicity.F1Square.Square.MellinLinear
import Multiplicity.F1Square.Square.MellinHat
import Multiplicity.F1Square.Analysis.ComplexDigammaConj
import Multiplicity.F1Square.Analysis.RlimProps

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The compact moment agrees across the two dilation representations**:
    `mellinMoment (dilateTest q φ) n = mellinMoment (dilateTestR (ofQ q) φ) n`. Both are `∫₀¹` of the
    SAME (defeq) product integrand `φ(q·x)·clamp01(x)ⁿ`; they differ only in the Lipschitz modulus
    (`φ.L·q` vs `φ.L·S`), removed by `riemannIntegral_certif_irrel`. -/
theorem mellinMoment_bridge (φ : L2Test) (n : Nat) (q : Q)
    (hqn : 0 < q.num) (hqd : 0 < q.den)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num) (hqS : Rle (Rabs (ofQ q hqd)) (ofQ S hSd)) :
    Req (mellinMoment (dilateTest q hqn hqd φ) n)
        (mellinMoment (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) n) :=
  riemannIntegral_certif_irrel
    (l2L_den (dilateTest q hqn hqd φ) (powTest n)) (l2L_num (dilateTest q hqn hqd φ) (powTest n))
    (l2lip (dilateTest q hqn hqd φ) (powTest n)) (l2fc (dilateTest q hqn hqd φ) (powTest n))
    (l2L_den (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) (powTest n))
    (l2L_num (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) (powTest n))
    (l2lip (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) (powTest n))
    (l2fc (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) (powTest n))

/-- **The per-window twisted term agrees across the two dilation representations** — the same
    `∫_{[m+1, m+2]}` integrand at two moduli, by `riemannIntegralI_certif_irrel`. -/
private theorem twTerm_bridge (φ : L2Test) (n m : Nat) (q : Q)
    (hqn : 0 < q.num) (hqd : 0 < q.den)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num) (hqS : Rle (Rabs (ofQ q hqd)) (ofQ S hSd)) :
    Req (twTerm (dilateTest q hqn hqd φ) n m)
        (twTerm (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) n m) :=
  riemannIntegralI_certif_irrel
    (l2L_den (dilateTest q hqn hqd φ) (powWinTest m n))
    (l2L_num (dilateTest q hqn hqd φ) (powWinTest m n))
    (l2lip (dilateTest q hqn hqd φ) (powWinTest m n))
    (l2fc (dilateTest q hqn hqd φ) (powWinTest m n))
    (l2L_den (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) (powWinTest m n))
    (l2L_num (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) (powWinTest m n))
    (l2lip (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) (powWinTest m n))
    (l2fc (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) (powWinTest m n))
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)

/-- **The twisted tail agrees across the two dilation representations**:
    `twTail (dilateTest q φ) n = twTail (dilateTestR (ofQ q) φ) n`. The two tails are `Rlim`s of the
    SAME dyadic schedule over term-wise-equal `twTerm` sequences (`twTerm_bridge`), so `Rlim_congr` +
    `genSum_congr` identify them. The decay hypothesis `hdec` transfers verbatim (defeq `.f`). -/
theorem twTail_bridge (φ : L2Test) (n : Nat) (q : Q)
    (hqn : 0 < q.num) (hqd : 0 < q.den)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num) (hqS : Rle (Rabs (ofQ q hqd)) (ofQ S hSd))
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest q hqn hqd φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (twTail (dilateTest q hqn hqd φ) n hCd hCn hdec)
        (twTail (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) n hCd hCn hdec) :=
  Rlim_congr _ _ _ _
    (fun _ => genSum_congr _ _
      (fun m => twTerm_bridge φ n m q hqn hqd S hSd hSn hqS) _)

/-- **The Mellin transform agrees across the two dilation representations**:
    `mellinHat (dilateTest q φ) n = mellinHat (dilateTestR (ofQ q) φ) n`. Sum of the moment bridge and
    the tail bridge (`mellinHat = mellinMoment + twTail`, `Radd_congr`). This lets the `dilateTest`-form
    rational-scale covariance be read in `dilateTestR` form at every rational scale — the connector the
    real-scale covariance capstone consumes. -/
theorem mellinHat_bridge (φ : L2Test) (n : Nat) (q : Q)
    (hqn : 0 < q.num) (hqd : 0 < q.den)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num) (hqS : Rle (Rabs (ofQ q hqd)) (ofQ S hSd))
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest q hqn hqd φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (mellinHat (dilateTest q hqn hqd φ) n hCd hCn hdec)
        (mellinHat (dilateTestR (ofQ q hqd) S hSd hSn hqS φ) n hCd hCn hdec) :=
  Radd_congr (mellinMoment_bridge φ n q hqn hqd S hSd hSn hqS)
    (twTail_bridge φ n q hqn hqd S hSd hSn hqS hCd hCn hdec)

end Multiplicity.UOR.Bridge.F1Square.Square
