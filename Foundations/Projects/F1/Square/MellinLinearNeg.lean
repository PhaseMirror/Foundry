/-
F1 square — **the pre-Hilbert layer, brick 86** (`MellinLinearNeg.lean`): **THE MELLIN TRANSFORM
RESPECTS NEGATION AND SUBTRACTION** — `(−φ)^(n) ≈ −φ̂(n)` and `(φ−ψ)^(n) ≈ φ̂(n) − ψ̂(n)`,
completing the transform's linear structure alongside `mellinHat_add` (`MellinLinear.lean`).

The transform `mellinHat φ n = mellinMoment φ n + twTail φ n` splits into a compact `[0,1]` moment
piece and a twisted half-line tail. Each respects negation: the moment by `innerI_neg_left`, the
twisted window integrals by `riemannIntegralI_neg` (`twTerm_neg`), and the tail by
`genSum_Rneg_of_termwise` + `Rlim_neg` (`twTail_neg`). Subtraction then composes add and neg
(`L2Test.sub φ ψ = add φ (neg ψ)`). So the transform-side vanishing conditions (`HatVanishes`) cut
out genuine linear **sub**spaces of the test class, closed under `+`, `−`, and scalar negation.

HONEST SCOPE. The transform's linear structure at the integer sample points `f̂(n)`, on the
decaying-test class. This does not build the continuous Mellin parameter, the transform *pair*, or
inversion — those remain open. Nothing here touches the Weil form. Step 4 is RH. The crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MellinLinear
import Foundations.F1.Square.PairingLimitI
import Foundations.F1.Analysis.T4PoleAPieces
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The twisted window integrals negate**: `twTerm (−φ) ≈ −twTerm φ`. -/
theorem twTerm_neg (φ : L2Test) (n m : Nat) :
    Req (twTerm (L2Test.neg φ) n m) (Rneg (twTerm φ n m)) := by
  have hlipn := lip_neg (hLd := l2L_den φ (powWinTest m n)) (l2lip φ (powWinTest m n))
  have hfcn := congr_neg (l2fc φ (powWinTest m n))
  refine Req_trans (riemannIntegralI_congr (l2L_den φ (powWinTest m n)) (l2L_num φ (powWinTest m n))
    (l2lip (L2Test.neg φ) (powWinTest m n)) (l2fc (L2Test.neg φ) (powWinTest m n))
    hlipn hfcn
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)
    (fun x => Rmul_neg_left (φ.f x) ((powWinTest m n).f x))) ?_
  exact riemannIntegralI_neg (l2L_den φ (powWinTest m n)) (l2L_num φ (powWinTest m n))
    (l2lip φ (powWinTest m n)) (l2fc φ (powWinTest m n)) hlipn hfcn
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) (by decide)

/-- `(−a) + (−b) ≈ −(a+b)` (both read their arguments at the same depth). -/
private theorem neg_add_local (a b : Real) : Req (Radd (Rneg a) (Rneg b)) (Rneg (Radd a b)) := by
  apply Req_of_seq_Qeq
  intro n
  simp only [Qeq, Radd, Rneg, add, neg]
  push_cast
  ring_uor

/-- **The twisted tails negate** (shared decay constant, hence shared schedule):
    `twTail (−φ) ≈ −twTail φ`. -/
theorem twTail_neg (φ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdφ : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdS : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((L2Test.neg φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (twTail (L2Test.neg φ) n hCd hCn hdS) (Rneg (twTail φ n hCd hCn hdφ)) :=
  Req_trans
    (Rlim_congr _ _
      (genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos)
        (Int.mul_nonneg hCn (Int.ofNat_nonneg _)) (twTerm_bound (L2Test.neg φ) n hCd hCn hdS))
      (RReg_Rneg _ (genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos)
        (Int.mul_nonneg hCn (Int.ofNat_nonneg _)) (twTerm_bound φ n hCd hCn hdφ)))
      (fun j => genSum_Rneg_of_termwise (fun m => twTerm_neg φ n m)
        (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)))
    (Rlim_neg _
      (genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos)
        (Int.mul_nonneg hCn (Int.ofNat_nonneg _)) (twTerm_bound φ n hCd hCn hdφ))
      (RReg_Rneg _ (genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos)
        (Int.mul_nonneg hCn (Int.ofNat_nonneg _)) (twTerm_bound φ n hCd hCn hdφ))))

/-- **THE MELLIN TRANSFORM RESPECTS NEGATION**: `(−φ)^(n) ≈ −φ̂(n)` — compact piece by
    `innerI_neg_left`, tail by `twTail_neg`. -/
theorem mellinHat_neg (φ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdφ : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdS : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((L2Test.neg φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (mellinHat (L2Test.neg φ) n hCd hCn hdS) (Rneg (mellinHat φ n hCd hCn hdφ)) :=
  Req_trans (Radd_congr (innerI_neg_left φ (powTest n)) (twTail_neg φ n hCd hCn hdφ hdS))
    (neg_add_local (mellinMoment φ n) (twTail φ n hCd hCn hdφ))

/-- The decay bound transfers through negation (`|−x| = |x|`). -/
private theorem hd_neg (ψ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdψ : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (ψ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((L2Test.neg ψ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))) :=
  fun m x h0 h1 => Rle_trans (Rle_of_Req (Rabs_Rneg
    (ψ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x))))
    (hdψ m x h0 h1)

/-- **THE MELLIN TRANSFORM RESPECTS SUBTRACTION**: `(φ−ψ)^(n) ≈ φ̂(n) − ψ̂(n)` — compose
    `mellinHat_add` with `mellinHat_neg` through `L2Test.sub = add _ (neg _)`. -/
theorem mellinHat_sub (φ ψ : L2Test) (n : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdφ : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdψ : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (ψ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdD : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((L2Test.sub φ ψ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Req (mellinHat (L2Test.sub φ ψ) n hCd hCn hdD)
        (Rsub (mellinHat φ n hCd hCn hdφ) (mellinHat ψ n hCd hCn hdψ)) :=
  Req_trans (mellinHat_add φ (L2Test.neg ψ) n hCd hCn hdφ (hd_neg ψ n hCd hCn hdψ) hdD)
    (Radd_congr (Req_refl _) (mellinHat_neg ψ n hCd hCn hdψ (hd_neg ψ n hCd hCn hdψ)))

end Multiplicity.UOR.Bridge.F1Square.Square
