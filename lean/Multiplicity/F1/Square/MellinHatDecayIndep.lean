/-
F1 square — **the twisted tail / Mellin transform is independent of the decay constant** used to
witness convergence (`MellinHatDecayIndep.lean`): `twTail φ n` and `mellinHat φ n` do not depend on
WHICH valid order-`(n+2)` decay constant `C` is supplied — two admissible constants `C₁, C₂` give the
SAME value. This is the schedule-bridge the `c ≥ 1` covariance wall-break needs: the rational covariance
at each approximant `qk` is proved at that approximant's own (large) fine-decay constant
`C = (Cf+φ.M)·(2·qk.den)^{n+2}`, but the reconstruction consumes `mellinHat` at the uniform `Cf`; this
result reconciles the two.

The proof is pure schedule-independence: `twTail φ n hCd₁ … hdec₁` and `twTail φ n hCd₂ … hdec₂` are the
Bishop limits of the SAME window sums `genSum (twTerm φ n)` on the two schedules
`digammaMidx (C₁·2ⁿ)` and `digammaMidx (C₂·2ⁿ)`; both agree within `1/(j+1)` with the common dominating
schedule `digammaMidx K⋆` (`genSum_close`, `digammaMidx_common`), so their limits coincide
(`Rlim_approx_eq`). `mellinMoment` carries no decay data, so `mellinHat = mellinMoment + twTail` inherits
the independence by `Radd_congr`.

HONEST SCOPE. Decay-constant independence of `twTail`/`mellinHat` only. It builds NO covariance, NO
factorization `M[f⋆g]=M[f]·M[g]`, NO positivity, NO crux. Step 4 (band-coupling positivity) is RH; the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ImproperScheduleIndep
import Multiplicity.F1Square.Square.DigammaMidxCommon
import Multiplicity.F1Square.Square.MellinHat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

/-- `|a − d| ≤ |a − b| + |b − d|` at the real level (triangle through `b`). -/
private theorem Rabs_Rsub_tri3 (a b d : Real) :
    Rle (Rabs (Rsub a d)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b d))) := by
  have htel : Req (Rsub a d) (Radd (Rsub a b) (Rsub b d)) := by
    show Req (Radd a (Rneg d)) (Radd (Radd a (Rneg b)) (Radd b (Rneg d)))
    refine Req_symm (Req_trans (Radd_assoc a (Rneg b) (Radd b (Rneg d))) ?_)
    refine Radd_congr (Req_refl a) ?_
    refine Req_trans (Req_symm (Radd_assoc (Rneg b) b (Rneg d))) ?_
    refine Req_trans (Radd_congr (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b))
      (Req_refl (Rneg d))) ?_
    exact Req_trans (Radd_comm zero (Rneg d)) (Radd_zero (Rneg d))
  exact Rle_trans (Rle_of_Req (Rabs_congr htel)) (Rabs_Radd (Rsub a b) (Rsub b d))

/-- `|a − b| ≈ |b − a|` at the real level. -/
private theorem Rabs_Rsub_comm3 (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Rabs_congr (Req_symm (Rneg_Rsub_flip b a))) (Rabs_Rneg (Rsub b a))

/-- **The twisted tail is independent of the witnessing decay constant.** For `φ` admitting two valid
    order-`(n+2)` window-decay constants `C₁, C₂`, `twTail φ n` computed with either is the same real —
    both are the limit of `genSum (twTerm φ n)` reconciled through the common schedule `digammaMidx K⋆`
    (`K⋆ = ⟨(C₁·2ⁿ).num.toNat + (C₂·2ⁿ).num.toNat, 1⟩`). -/
theorem twTail_decay_indep (φ : L2Test) (n : Nat) {C1 C2 : Q}
    (hCd1 : 0 < C1.den) (hCn1 : 0 ≤ C1.num)
    (hdec1 : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C1 (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd1 (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hCd2 : 0 < C2.den) (hCn2 : 0 ≤ C2.num)
    (hdec2 : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C2 (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd2 (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (twTail φ n hCd1 hCn1 hdec1) (twTail φ n hCd2 hCn2 hdec2) := by
  refine Rlim_approx_eq _ _
    (genSum_RReg (fun m => twTerm φ n m) (Qmul_den_pos hCd1 Nat.one_pos)
      (Int.mul_nonneg hCn1 (Int.ofNat_nonneg _)) (twTerm_bound φ n hCd1 hCn1 hdec1))
    (genSum_RReg (fun m => twTerm φ n m) (Qmul_den_pos hCd2 Nat.one_pos)
      (Int.mul_nonneg hCn2 (Int.ofNat_nonneg _)) (twTerm_bound φ n hCd2 hCn2 hdec2))
    (C := 2) (fun j => ?_)
  -- triangle through the common schedule K⋆
  refine Rle_trans (Rabs_Rsub_tri3
    (genSum (fun m => twTerm φ n m) (digammaMidx (mul C1 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))
    (genSum (fun m => twTerm φ n m) (digammaMidx
      (⟨((mul C1 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int)
        + ((mul C2 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int), 1⟩ : Q) j))
    (genSum (fun m => twTerm φ n m) (digammaMidx (mul C2 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))) ?_
  refine Rle_trans (Radd_le_add
    (Rle_trans (Rle_of_Req (Rabs_Rsub_comm3 _ _))
      (genSum_close (fun m => twTerm φ n m)
        (K := mul C1 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (Qmul_den_pos hCd1 Nat.one_pos)
        (Int.mul_nonneg hCn1 (Int.ofNat_nonneg _)) (twTerm_bound φ n hCd1 hCn1 hdec1)
        (fun i => digammaMidx (⟨((mul C1 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int)
          + ((mul C2 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int), 1⟩ : Q) i)
        (fun i => (digammaMidx_common (mul C1 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))
          (mul C2 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) i).1) j))
    (genSum_close (fun m => twTerm φ n m)
        (K := mul C2 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) (Qmul_den_pos hCd2 Nat.one_pos)
        (Int.mul_nonneg hCn2 (Int.ofNat_nonneg _)) (twTerm_bound φ n hCd2 hCn2 hdec2)
        (fun i => digammaMidx (⟨((mul C1 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int)
          + ((mul C2 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)).num.toNat : Int), 1⟩ : Q) i)
        (fun i => (digammaMidx_common (mul C1 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q))
          (mul C2 (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) i).2) j)) ?_
  refine Rle_of_Req (Req_trans (Radd_ofQ_ofQ (Nat.succ_pos j) (Nat.succ_pos j)) ?_)
  refine ofQ_congr (a := add (⟨1, j + 1⟩ : Q) (⟨1, j + 1⟩ : Q)) (b := (⟨2, j + 1⟩ : Q))
    (add_den_pos (Nat.succ_pos j) (Nat.succ_pos j)) (Nat.succ_pos j) ?_
  simp only [Qeq, add]; push_cast; ring_uor

/-- **The Mellin transform is independent of the witnessing decay constant.**
    `mellinHat φ n = mellinMoment φ n + twTail φ n` and `mellinMoment` carries no decay data, so the
    independence of `twTail` (`twTail_decay_indep`) lifts through `Radd_congr`. -/
theorem mellinHat_decay_indep (φ : L2Test) (n : Nat) {C1 C2 : Q}
    (hCd1 : 0 < C1.den) (hCn1 : 0 ≤ C1.num)
    (hdec1 : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C1 (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd1 (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hCd2 : 0 < C2.den) (hCn2 : 0 ≤ C2.num)
    (hdec2 : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C2 (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd2 (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (mellinHat φ n hCd1 hCn1 hdec1) (mellinHat φ n hCd2 hCn2 hdec2) :=
  Radd_congr (Req_refl (mellinMoment φ n))
    (twTail_decay_indep φ n hCd1 hCn1 hdec1 hCd2 hCn2 hdec2)

end Multiplicity.UOR.Bridge.F1Square.Square
