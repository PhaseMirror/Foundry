/-
F1 square — **the per-`k` `hcov` ingredient of the `c ≥ 1` Mellin dilation covariance**
(`CovarianceAtQk.lean`): for a rational scale `q ≥ 1` it produces exactly the per-approximant
covariance equality

    `qⁿ⁺¹ · mellinHat (dilateTestR (ofQ q) φ) n  =  mellinHat φ n`

stated at the reconstruction's UNIFORM decay constant `Cf` — the shape the base density capstone
`mellinHat_dilate_covariance_real` (`MellinHatDilateCovarianceReal.lean`) consumes as its `hcov`.

WHY (decay-constant independence). The rational-scale covariance `covariance_at_rational_dilateTestR`
requires ALL of its decay data (`hdec_dil`, `hdec_phi`, `hdec_fine`) at a SINGLE constant, and the fine
(`1/q.den`) dilation only decays at the LARGE per-`q` constant `C' = (Cf+φ.M)·(2·q.den)^{n+2}`
(`dilateTest_fine_window_decay`). So we run the rational covariance at a constant `Cbig` large enough to
carry the fine decay AND to make the `qⁿ⁺¹`-scaled twisted tail's canonical schedule regular
(`Cbig := qⁿ⁺¹·Cf + C' + Cf`, dominating both `qⁿ⁺¹·Cf` and `C'`), then bridge every `mellinHat` back
to `Cf` by `mellinHat_decay_indep`. The scalar `(ofQ q)ⁿ⁺¹` is normalised to `ofQ (qpow q (n+1))` by
`Rpow_ofQ`. The regularity witness `hReg` at `Cbig` is discharged from `scaledTwTerm_bound` (whose
`qⁿ⁺¹·Cf·2ⁿ` modulus is dominated by `Cbig·2ⁿ`) through `genSum_RReg`.

HONEST SCOPE. Object-grounding substrate: the per-`k` covariance equality at the uniform decay
constant, the `hcov` slot of the `c ≥ 1` density capstone. It builds NO real-scale covariance (that is
the capstone `mellinHat_dilate_covariance_real`), NO factorization `M[f⋆g]=M[f]·M[g]`, NO grounding of
`v = ĝ`, and — emphatically — NO step-4 band-coupling positivity (`ArchDominatesPrime`), which is RH.
The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.CovarianceAtRational
import Multiplicity.F1Square.Square.MellinHatDecayIndep
import Multiplicity.F1Square.Square.DilateTestFineDecay
import Multiplicity.F1Square.Square.WindowPower
import Multiplicity.F1Square.Analysis.IntegralBilinear
import Multiplicity.F1Square.Analysis.ExpLog

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- **The per-`k` `hcov` ingredient at the uniform decay constant `Cf`.** For a rational scale
    `q ≥ 1` (bounded by `S`) and clean order-`(n+2)` decay data at the uniform constant `Cf`,

      `qⁿ⁺¹ · mellinHat (dilateTestR (ofQ q) φ) n  =  mellinHat φ n`.

    Routed through the rational-scale covariance `covariance_at_rational_dilateTestR` at the large
    per-`q` constant `Cbig := qⁿ⁺¹·Cf + C' + Cf` (which carries the fine-`1/q.den` decay `C'` and the
    `qⁿ⁺¹`-scaled twisted regularity), then bridged back to `Cf` by `mellinHat_decay_indep`; the scalar
    `(ofQ q)ⁿ⁺¹` normalised by `Rpow_ofQ`. This is the exact `hcov k` the density capstone
    `mellinHat_dilate_covariance_real` consumes. -/
theorem covariance_at_qk_baseform (phi : L2Test) (n : Nat) (q : Q) (hqn : 0 < q.num) (hqd : 0 < q.den)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num) (hqS : Rle (Rabs (ofQ q hqd)) (ofQ S hSd))
    {Cf : Q} (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
       Rle (Rabs (phi.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
         (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (hdec_qk : ∀ (m : Nat) x, Rle zero x → Rle x one →
       Rle (Rabs ((dilateTestR (ofQ q hqd) S hSd hSn hqS phi).f
             (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
         (ofQ (mul Cf (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
           (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_phi : ∀ (m : Nat) x, Rle zero x → Rle x one →
       Rle (Rabs (phi.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
         (ofQ (mul Cf (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
           (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (Rmul (Rpow (ofQ q hqd) (n + 1))
          (mellinHat (dilateTestR (ofQ q hqd) S hSd hSn hqS phi) n hCfd hCfn hdec_qk))
        (mellinHat phi n hCfd hCfn hdec_phi) := by
  -- the fine (`1/q.den`) decay constant, and the enlarged working constant that dominates it
  let Cp : Q := mul (add Cf phi.M) (⟨(((2 * q.den) ^ (n + 2) : Nat) : Int), 1⟩ : Q)
  let Cbig : Q := add (add (mul (qpow q (n + 1)) Cf) Cp) Cf
  -- denominator / numerator positivity
  have hCpd : 0 < Cp.den := Qmul_den_pos (add_den_pos hCfd phi.hMd) Nat.one_pos
  have hCpn : 0 ≤ Cp.num :=
    Int.mul_nonneg (Qadd_num_nonneg_loc hCfn phi.hMn) (Int.ofNat_nonneg _)
  have hqpd : 0 < (mul (qpow q (n + 1)) Cf).den := Qmul_den_pos (qpow_den_pos hqd (n + 1)) hCfd
  have hqpn : 0 ≤ (mul (qpow q (n + 1)) Cf).num :=
    Int.mul_nonneg (qpow_nonneg (Int.le_of_lt hqn) (n + 1)) hCfn
  have haddd : 0 < (add (mul (qpow q (n + 1)) Cf) Cp).den := add_den_pos hqpd hCpd
  have haddn : 0 ≤ (add (mul (qpow q (n + 1)) Cf) Cp).num := Qadd_num_nonneg_loc hqpn hCpn
  have hCbigd : 0 < Cbig.den := add_den_pos haddd hCfd
  have hCbign : 0 ≤ Cbig.num := Qadd_num_nonneg_loc haddn hCfn
  -- the three domination facts, all via `Qle_self_add`/`Qle_self_add_l`
  have hCf_Cbig : Qle Cf Cbig := Qle_self_add_l haddn
  have hCp_Cbig : Qle Cp Cbig :=
    Qle_trans haddd (Qle_self_add_l hqpn) (Qle_self_add hCfn)
  have hqpowCf_Cbig : Qle (mul (qpow q (n + 1)) Cf) Cbig :=
    Qle_trans haddd (Qle_self_add hCpn) (Qle_self_add hCfn)
  -- the scaled-twisted modulus `qⁿ⁺¹·Cf·2ⁿ` is dominated by `Cbig·2ⁿ`
  have hassoc : Qeq (mul (qpow q (n + 1)) (mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)))
      (mul (mul (qpow q (n + 1)) Cf) (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) := by
    simp only [Qeq, mul]; push_cast; ring_uor
  have hKle : Qle (mul (qpow q (n + 1)) (mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)))
      (mul Cbig (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) :=
    Qle_trans (Qmul_den_pos hqpd Nat.one_pos) (Qeq_le hassoc)
      (qmul_le_right_mono hqpowCf_Cbig (Int.ofNat_nonneg _))
  -- the `q`-dilate decay in `dilateTest` form (defeq to the `dilateTestR` form of `hdec_qk`)
  have hdil : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest q hqn hqd phi).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul Cf (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))) :=
    hdec_qk
  -- weaken the three decay data to the enlarged constant `Cbig`
  have hdec_dil_big : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest q hqn hqd phi).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul Cbig (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCbigd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))) :=
    fun m x hx0 hx1 => Rle_trans (hdil m x hx0 hx1)
      (Rle_ofQ_ofQ _ _ (qmul_le_right_mono hCf_Cbig (by show (0 : Int) ≤ 1; decide)))
  have hdec_phi_big : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (phi.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul Cbig (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCbigd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))) :=
    fun m x hx0 hx1 => Rle_trans (hdec_phi m x hx0 hx1)
      (Rle_ofQ_ofQ _ _ (qmul_le_right_mono hCf_Cbig (by show (0 : Int) ≤ 1; decide)))
  have hdec_fine_big : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTest (⟨1, q.den⟩ : Q) Int.zero_lt_one hqd phi).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul Cbig (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCbigd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))) :=
    fun m x hx0 hx1 =>
      Rle_trans (dilateTest_fine_window_decay phi n hCfd hCfn hfdec q.den hqd m x hx0 hx1)
        (Rle_ofQ_ofQ _ _ (qmul_le_right_mono hCp_Cbig (by show (0 : Int) ≤ 1; decide)))
  -- the regularity witness at `Cbig`, from `scaledTwTerm_bound` weakened along `hKle`
  have hReg_big : RReg (fun j => genSum (fun m => scaledTwTerm phi q hqn hqd n m)
      (digammaMidx (mul Cbig (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)) :=
    genSum_RReg (fun m => scaledTwTerm phi q hqn hqd n m)
      (Qmul_den_pos hCbigd Nat.one_pos)
      (Int.mul_nonneg hCbign (Int.ofNat_nonneg _))
      (fun m hm => by
        obtain ⟨lo, hi⟩ := scaledTwTerm_bound phi q hqn hqd n hCfd hCfn hdil m hm
        have hstep : Qle (mul (mul (qpow q (n + 1)) (mul Cf (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)))
              (⟨1, (m + 1) * m⟩ : Q))
            (mul (mul Cbig (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (⟨1, (m + 1) * m⟩ : Q)) :=
          qmul_le_right_mono hKle (by show (0 : Int) ≤ 1; decide)
        exact ⟨Rle_trans (Rle_Rneg (Rle_ofQ_ofQ _ _ hstep)) lo,
               Rle_trans hi (Rle_ofQ_ofQ _ _ hstep)⟩)
  -- assemble: normalise the scalar, bridge `Cf → Cbig`, apply the rational covariance, bridge back
  refine Req_trans (Rmul_congr (Rpow_ofQ hqd (n + 1)) (Req_refl _)) ?_
  refine Req_trans (Rmul_congr (Req_refl _)
    (mellinHat_decay_indep (dilateTestR (ofQ q hqd) S hSd hSn hqS phi) n
      hCfd hCfn hdec_qk hCbigd hCbign hdec_dil_big)) ?_
  refine Req_trans (covariance_at_rational_dilateTestR phi n q hqn hqd S hSd hSn hqS
    hCbigd hCbign hdec_dil_big hdec_phi_big hdec_fine_big hReg_big) ?_
  exact mellinHat_decay_indep phi n hCbigd hCbign hdec_phi_big hCfd hCfn hdec_phi

end Multiplicity.UOR.Bridge.F1Square.Square