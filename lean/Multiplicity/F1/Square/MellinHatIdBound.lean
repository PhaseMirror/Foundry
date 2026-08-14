/-
F1 square — **a rational magnitude bound on the UNDILATED Mellin transform `mellinHat f`**
(`MellinHatIdBound.lean`): the identity-scale analog of `mellinHat_abs_le`. Where that bounds
`mellinHat (dilateTestR c φ)`, this bounds the plain `mellinHat φ` by an EXPLICIT rational
`mellinHatIdBnd φ n C`, so it can serve as the constant test's rational modulus:

    `|mellinHat φ n|  ≤  ofQ (mellinHatIdBnd φ n C)`.

WHY (grounding `v = ĝ`). The reconstruction's head test `Whead.f t = g(t)·max(t,a)ⁿ·M[f]` carries the
constant real `M[f] = mellinHat f` as a factor, and `constTest` needs a RATIONAL bound `mB` on it. The
existing `mellinHat_abs_le` bound is scale-independent but stated for the dilated test; this file mirrors
it for the plain `f` (same crude estimate: the moment `≤ φ.M/(n+1)` by `mellinMoment_abs_le`, the tail by
the finite window sum `+2`), then collapses the `genSum`-of-`ofQ` bound to a single `ofQ` via
`genSum_ofQ` — the rational `Whead`'s `constTest` consumes.

HONEST SCOPE. A magnitude bound — a rational modulus for the constant `M[f]`. It builds NO head test, NO
factorization `M[f⋆g]=M[f]·M[g]`, grounds NO `v = ĝ`, and — emphatically — applies NO step-4
band-coupling positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MellinHatBound
import Multiplicity.F1Square.Analysis.GenSumOfQ

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `|a| ≤ |a − b| + |b|` (triangle through `b`; re-derived here since the `MellinHatBound` copy is
    private). -/
private theorem Rabs_le_dist_add' (a b : Real) :
    Rle (Rabs a) (Radd (Rabs (Rsub a b)) (Rabs b)) := by
  have htel : Req a (Radd (Rsub a b) b) :=
    Req_symm (Req_trans (Radd_assoc a (Rneg b) b)
      (Req_trans (Radd_congr (Req_refl a) (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b)))
        (Radd_zero a)))
  exact Rle_trans (Rle_of_Req (Rabs_congr htel)) (Rabs_Radd (Rsub a b) b)

/-- Finite-sum triangle for `genSum` (re-derived; the `MellinHatBound` copy is private). -/
private theorem genSum_Rabs_le'' (T : Nat → Real) :
    ∀ N, Rle (Rabs (genSum T N)) (genSum (fun m => Rabs (T m)) N)
  | 0 => Rle_of_Req Rabs_zero
  | (N + 1) =>
      Rle_trans (Rabs_Radd (genSum T N) (T N))
        (Radd_le_add (genSum_Rabs_le'' T N) (Rle_of_Req (Req_refl _)))

/-- **Crude bound on the undilated twisted term** `|twTerm φ n m| ≤ φ.M·(powWinTest m n).M` — mirror of
    `twTerm_crude_bound` with `φ` in place of the dilated test (the sup bound `φ.hbd` is scale-free). -/
theorem twTerm_id_crude_bound (φ : L2Test) (n m : Nat) :
    Rle (Rabs (twTerm φ n m))
      (ofQ (mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
        (Qmul_den_pos (by decide) (Qmul_den_pos φ.hMd (powWinTest m n).hMd))) := by
  refine riemannIntegralI_abs_le_window
    (l2L_den φ (powWinTest m n)) (l2L_num φ (powWinTest m n))
    (l2lip φ (powWinTest m n)) (l2fc φ (powWinTest m n))
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M)
    Nat.one_pos (by decide) (by decide) (Qmul_den_pos φ.hMd (powWinTest m n).hMd)
    (fun x _ _ => ?_)
  refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs _) (φ.hbd _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ φ.hMd φ.hMn) ((powWinTest m n).hbd _)) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ φ.hMd (powWinTest m n).hMd)

/-- **Crude bound on the undilated twisted tail** — mirror of `twTail_crude_bound` with `φ`. -/
theorem twTail_id_crude_bound (φ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Rle (Rabs (twTail φ n hCd hCn hdec))
      (Radd (genSum (fun m => ofQ (mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
              (Qmul_den_pos (by decide) (Qmul_den_pos φ.hMd (powWinTest m n).hMd)))
              (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0))
            (ofQ (⟨2, 1⟩ : Q) (by decide))) := by
  have wReg : RReg (fun i => genSum (fun m => twTerm φ n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) i)) :=
    genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos) (Int.mul_nonneg hCn (Int.ofNat_nonneg _))
      (twTerm_bound φ n hCd hCn hdec)
  refine Rle_trans (Rabs_le_dist_add' _
    (genSum (fun m => twTerm φ n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0))) ?_
  refine Rle_trans (Radd_le_add
    (Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) (Rabs_dist_Rlim wReg 0))
    (Rle_trans (genSum_Rabs_le'' _ _)
      (genSum_le (fun m => twTerm_id_crude_bound φ n m) _))) ?_
  exact Rle_of_Req (Radd_comm _ _)

/-- **The magnitude bound on the undilated Mellin transform** `|mellinHat φ n|` — moment `+` tail. -/
theorem mellinHat_id_abs_le (φ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Rle (Rabs (mellinHat φ n hCd hCn hdec))
      (Radd (ofQ (mul φ.M (⟨1, n + 1⟩ : Q)) (Qmul_den_pos φ.hMd (Nat.succ_pos n)))
        (Radd (genSum (fun m => ofQ (mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
                (Qmul_den_pos (by decide) (Qmul_den_pos φ.hMd (powWinTest m n).hMd)))
                (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0))
              (ofQ (⟨2, 1⟩ : Q) (by decide)))) := by
  show Rle (Rabs (Radd (mellinMoment φ n) (twTail φ n hCd hCn hdec))) _
  refine Rle_trans (Rabs_Radd _ _) ?_
  exact Radd_le_add (mellinMoment_abs_le φ n) (twTail_id_crude_bound φ n hCd hCn hdec)

/-- **The rational modulus** for `mellinHat φ n` — the collapse of `mellinHat_id_abs_le`'s bound to a
    single rational (`genSum`-of-`ofQ` → `ofQ` via `genSum_ofQ`, then `Radd_ofQ_ofQ`). -/
def mellinHatIdBnd (φ : L2Test) (n : Nat) (C : Q) : Q :=
  add (mul φ.M (⟨1, n + 1⟩ : Q))
    (add (qGenSum (fun m => mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
            (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0))
         (⟨2, 1⟩ : Q))

/-- The rational modulus has positive denominator. -/
theorem mellinHatIdBnd_den (φ : L2Test) (n : Nat) (C : Q) : 0 < (mellinHatIdBnd φ n C).den :=
  add_den_pos (Qmul_den_pos φ.hMd (Nat.succ_pos n))
    (add_den_pos (qGenSum_den _
        (fun m => Qmul_den_pos (by decide) (Qmul_den_pos φ.hMd (powWinTest m n).hMd)) _)
      (by decide))

/-- **`|mellinHat φ n| ≤ ofQ (mellinHatIdBnd φ n C)`** — the rational-modulus form the head test's
    `constTest` consumes. -/
theorem mellinHat_id_abs_le_ofQ (φ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Rle (Rabs (mellinHat φ n hCd hCn hdec))
      (ofQ (mellinHatIdBnd φ n C) (mellinHatIdBnd_den φ n C)) := by
  refine Rle_trans (mellinHat_id_abs_le φ n hCd hCn hdec) (Rle_of_Req ?_)
  have hg : ∀ m, 0 < (mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M)).den :=
    fun m => Qmul_den_pos (by decide) (Qmul_den_pos φ.hMd (powWinTest m n).hMd)
  refine Req_trans (Radd_congr (Req_refl _)
    (Radd_congr (genSum_ofQ _ hg (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0))
      (Req_refl _))) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (Radd_ofQ_ofQ (qGenSum_den _ hg _) (by decide))) ?_
  exact Radd_ofQ_ofQ (Qmul_den_pos φ.hMd (Nat.succ_pos n))
    (add_den_pos (qGenSum_den _ hg _) (by decide))

end Multiplicity.UOR.Bridge.F1Square.Square
