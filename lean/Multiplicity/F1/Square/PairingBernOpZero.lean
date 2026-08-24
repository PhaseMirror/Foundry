/-
F1 square — **the Bernstein OPERATOR test pairs to zero at the completion level**
(`PairingBernOpZero.lean`). `innerI_bernOpCTest_zero` (`BernsteinOperatorTest.lean`, sub-brick H₄)
proved, for a FIXED moment-null test `φ`, that the clamped Bernstein operator as a test pairs to zero,
`⟨φ, B_n(χ)⟩ ≈ 0`. This brick lifts that to a **limit member**: for a uniformly-L²-Cauchy sequence `Φ`
whose extended moments `pairingIU Φ (xⁱ) h` all vanish, the extended pairing against the Bernstein
operator test of ANY approximated test `χ` vanishes (`pairingIU_bernOpCTest_zero`). The proof mirrors
`innerI_bernOpCTest_zero` exactly, with `innerI φ` (fixed test) replaced by `pairingIU Φ · h` (limit
member): finite-additivity over the basis (`pairingIU_L2sumN_zero`, mirroring `innerI_L2sumN_zero`),
each summand a real coefficient times a single basis pairing that already vanishes at the completion
level (`pairingIU_constMul_zero` ∘ `pairingIU_clampProd_zero`).

The one genuinely new ingredient is `pairingIU_constMul` — the real-scalar homogeneity of the EXTENDED
pairing, `pairingIU Φ ((constTest c)·ψ) h ≈ c · pairingIU Φ ψ h`. It is proved along the reschedule
skeleton of `pairingIU_add_right`: split each rescheduled read through `⟨Φ_{B(k+1)}, (constTest c)·ψ⟩`,
where `innerI_constMul` pulls `c` out of the fixed pairing, and bound the two halves by the reschedule
rate (`pairingIU_reschedule_rate`) — the `c`-slot contributing a factor `|c| ≤ mB ≤ Bnat`.

HONEST SCOPE. The extended pairing against the Bernstein operator test vanishes when all extended
moments vanish; a step toward completion-level moment determinacy. NOT positivity, NOT surjectivity.
Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1.Square.PairingBernBasisZero
import Multiplicity.F1.Square.BernsteinOperatorTest

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Local algebra helpers (private; copies of the reschedule-brick privates).
-- ===========================================================================

/-- `|a − b| ≈ |b − a|` (local copy). -/
private theorem abs_sub_comm (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Req_symm (Rabs_Rneg (Rsub a b))) (Rabs_congr (Rneg_Rsub a b))

/-- Turn a two-sided `|a − b| ≤ C/(k+1)` bound into `a ≈ b` (local copy). -/
private theorem Req_of_Rabs_sub_le {a b : Real} {C : Nat}
    (hk : ∀ k, Rle (Rabs (Rsub a b)) (ofQ (⟨(C : Int), k + 1⟩ : Q) (Nat.succ_pos k))) :
    Req a b :=
  Req_of_Rle_ofQ_all
    (fun k => Rle_of_Rabs_le (hk k))
    (fun k => Rle_trans (Rle_Rabs_self (Rsub b a))
      (Rle_trans (Rle_of_Req (abs_sub_comm b a)) (hk k)))

-- ===========================================================================
-- Piece A — the extended pairing of the zero test vanishes.
-- ===========================================================================

/-- **The extended pairing of the zero test vanishes** (re-derived local copy of the private helper in
    `PairingIULinear2`): each rescheduled read `⟨Φⱼ, 0⟩ ≈ 0`, so the limit is `0`. -/
private theorem pairingIU_zeroL2 (Φ : Nat → L2Test) (h : L2CauchyU Φ) :
    Req (pairingIU Φ zeroL2 h) zero :=
  Rlim_zero _ (pairingIU_RReg h zeroL2)
    (fun _j => Req_trans (innerI_symm _ zeroL2) (innerI_zeroL2 _))

-- ===========================================================================
-- Piece B — finite additivity of the extended pairing over a family of tests.
-- ===========================================================================

/-- **A FINITE SUM OF TESTS PAIRS TO ZERO AT THE COMPLETION LEVEL** if every summand does — the
    `pairingIU` mirror of `innerI_L2sumN_zero`, via right-additivity (`pairingIU_add_right`). -/
theorem pairingIU_L2sumN_zero (Φ : Nat → L2Test) (h : L2CauchyU Φ) (g : Nat → L2Test) :
    ∀ N, (∀ k, k < N → Req (pairingIU Φ (g k) h) zero) → Req (pairingIU Φ (L2sumN g N) h) zero
  | 0, _ => pairingIU_zeroL2 Φ h
  | N + 1, hk => by
    refine Req_trans (pairingIU_add_right Φ (L2sumN g N) (g N) h) ?_
    exact Req_trans (Radd_congr
      (pairingIU_L2sumN_zero Φ h g N (fun k hkk => hk k (Nat.lt_succ_of_lt hkk)))
      (hk N (Nat.lt_succ_self N))) (Radd_zero zero)

-- ===========================================================================
-- Piece C — real-scalar homogeneity of the extended pairing.
-- ===========================================================================

/-- **RIGHT REAL-SCALAR HOMOGENEITY OF THE EXTENDED PAIRING**:
    `pairingIU Φ ((constTest c)·ψ) h ≈ c · pairingIU Φ ψ h`. The completion-level mirror of
    `innerI_constMul`, proved along the reschedule skeleton of `pairingIU_add_right`. Reading `Φ` along
    the common schedule `B = selfBnd ((constTest c)·ψ) + selfBnd ψ`, split each side through
    `⟨Φ_{B(k+1)}, (constTest c)·ψ⟩`: the first half is the reschedule rate at `(constTest c)·ψ`, and the
    second half is `innerI_constMul` (pull `c` out of the fixed pairing) times the reschedule rate at
    `ψ`, the real scalar contributing `|c| ≤ mB ≤ Bnat := mB.num.toNat + 1`. Both halves close at rate
    `≤ (4 + 4·Bnat)/(k+1)`. -/
theorem pairingIU_constMul (Φ : Nat → L2Test) (ψ : L2Test) (c : Real) {mB : Q}
    (hMd : 0 < mB.den) (hMn : 0 ≤ mB.num) (hb : Rle (Rabs c) (ofQ mB hMd)) (h : L2CauchyU Φ) :
    Req (pairingIU Φ (L2Test.mul (constTest c mB hMd hMn hb) ψ) h) (Rmul c (pairingIU Φ ψ h)) := by
  refine Req_of_Rabs_sub_le (C := 4 + 4 * (mB.num.toNat + 1)) (fun k => ?_)
  -- The common schedule `B = selfBnd ((constTest c)·ψ) + selfBnd ψ` dominates both slots.
  have hBcψ : selfBnd (L2Test.mul (constTest c mB hMd hMn hb) ψ)
      ≤ selfBnd (L2Test.mul (constTest c mB hMd hMn hb) ψ) + selfBnd ψ := by omega
  have hBψ : selfBnd ψ ≤ selfBnd (L2Test.mul (constTest c mB hMd hMn hb) ψ) + selfBnd ψ := by omega
  -- `|c| ≤ mB ≤ ⟨Bnat, 1⟩`, where `Bnat = mB.num.toNat + 1`.
  have hcBnat : Rle (Rabs c) (ofQ (⟨((mB.num.toNat + 1 : Nat) : Int), 1⟩ : Q) Nat.one_pos) := by
    refine Rle_trans hb ?_
    refine Rle_ofQ_ofQ hMd Nat.one_pos ?_
    refine Qle_trans Nat.one_pos (Qle_toNat hMn hMd) ?_
    show (mB.num.toNat : Int) * 1 ≤ ((mB.num.toNat + 1 : Nat) : Int) * (1 : Int)
    push_cast; omega
  -- Split `pairingIU cψ − c·pairingIU ψ` through `⟨Φ_{B(k+1)}, cψ⟩`.
  have hsplit : Req (Rsub (pairingIU Φ (L2Test.mul (constTest c mB hMd hMn hb) ψ) h)
        (Rmul c (pairingIU Φ ψ h)))
      (Radd (Rsub (pairingIU Φ (L2Test.mul (constTest c mB hMd hMn hb) ψ) h)
                  (innerI (Φ ((selfBnd (L2Test.mul (constTest c mB hMd hMn hb) ψ) + selfBnd ψ) * (k + 1)))
                          (L2Test.mul (constTest c mB hMd hMn hb) ψ)))
            (Rsub (innerI (Φ ((selfBnd (L2Test.mul (constTest c mB hMd hMn hb) ψ) + selfBnd ψ) * (k + 1)))
                          (L2Test.mul (constTest c mB hMd hMn hb) ψ))
                  (Rmul c (pairingIU Φ ψ h)))) :=
    Req_symm (Rsub_split _ _ _)
  -- First half: the reschedule rate at `cψ`.
  have hfirst : Rle (Rabs (Rsub (pairingIU Φ (L2Test.mul (constTest c mB hMd hMn hb) ψ) h)
        (innerI (Φ ((selfBnd (L2Test.mul (constTest c mB hMd hMn hb) ψ) + selfBnd ψ) * (k + 1)))
                (L2Test.mul (constTest c mB hMd hMn hb) ψ))))
      (ofQ (⟨4, k + 1⟩ : Q) (Nat.succ_pos k)) :=
    Rle_trans (Rle_of_Req (abs_sub_comm _ _))
      (pairingIU_reschedule_rate Φ (L2Test.mul (constTest c mB hMd hMn hb) ψ) h _ hBcψ k)
  -- Second half: pull `c` out (`innerI_constMul`) then reschedule at `ψ`.
  have heq2 : Req (Rsub (innerI (Φ ((selfBnd (L2Test.mul (constTest c mB hMd hMn hb) ψ) + selfBnd ψ) * (k + 1)))
                                (L2Test.mul (constTest c mB hMd hMn hb) ψ))
                        (Rmul c (pairingIU Φ ψ h)))
      (Rmul c (Rsub (innerI (Φ ((selfBnd (L2Test.mul (constTest c mB hMd hMn hb) ψ) + selfBnd ψ) * (k + 1))) ψ)
                    (pairingIU Φ ψ h))) :=
    Req_trans (Rsub_congr (innerI_constMul
        (Φ ((selfBnd (L2Test.mul (constTest c mB hMd hMn hb) ψ) + selfBnd ψ) * (k + 1))) ψ c hMd hMn hb)
        (Req_refl _))
      (Req_symm (Rmul_sub_distrib c
        (innerI (Φ ((selfBnd (L2Test.mul (constTest c mB hMd hMn hb) ψ) + selfBnd ψ) * (k + 1))) ψ)
        (pairingIU Φ ψ h)))
  have hQ2 : Qle (mul (⟨((mB.num.toNat + 1 : Nat) : Int), 1⟩ : Q) (⟨4, k + 1⟩ : Q))
                 (⟨4 * ((mB.num.toNat + 1 : Nat) : Int), k + 1⟩ : Q) :=
    Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor)
  have hsecond : Rle (Rabs (Rsub
        (innerI (Φ ((selfBnd (L2Test.mul (constTest c mB hMd hMn hb) ψ) + selfBnd ψ) * (k + 1)))
                (L2Test.mul (constTest c mB hMd hMn hb) ψ))
        (Rmul c (pairingIU Φ ψ h))))
      (ofQ (⟨4 * ((mB.num.toNat + 1 : Nat) : Int), k + 1⟩ : Q) (Nat.succ_pos k)) := by
    refine Rle_trans (Rle_of_Req (Rabs_congr heq2)) ?_
    refine Rle_trans (Rle_of_Req (Rabs_Rmul c
      (Rsub (innerI (Φ ((selfBnd (L2Test.mul (constTest c mB hMd hMn hb) ψ) + selfBnd ψ) * (k + 1))) ψ)
            (pairingIU Φ ψ h)))) ?_
    refine Rle_trans (Rmul_le_Rmul_both (Rnonneg_Rabs c)
      (Rnonneg_ofQ (Nat.succ_pos k) (show (0 : Int) ≤ 4 by decide)) hcBnat
      (pairingIU_reschedule_rate Φ ψ h _ hBψ k)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ Nat.one_pos (Nat.succ_pos k))) ?_
    exact Rle_ofQ_ofQ (Qmul_den_pos Nat.one_pos (Nat.succ_pos k)) (Nat.succ_pos k) hQ2
  -- Combine the two halves.
  have hQC : Qle (add (⟨4, k + 1⟩ : Q) (⟨4 * ((mB.num.toNat + 1 : Nat) : Int), k + 1⟩ : Q))
                 (⟨((4 + 4 * (mB.num.toNat + 1) : Nat) : Int), k + 1⟩ : Q) :=
    Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)
  refine Rle_trans (Rle_of_Req (Rabs_congr hsplit)) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add hfirst hsecond) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k))) ?_
  exact Rle_ofQ_ofQ (add_den_pos (Nat.succ_pos k) (Nat.succ_pos k)) (Nat.succ_pos k) hQC

-- ===========================================================================
-- Piece D — the constant-scaled basis vanishes, then the operator assembly.
-- ===========================================================================

/-- **THE CONSTANT-SCALED TEST PAIRS TO ZERO AT THE COMPLETION LEVEL**: if `pairingIU Φ ψ h ≈ 0` then
    `pairingIU Φ ((constTest c)·ψ) h ≈ 0` — the real coefficient multiplies a vanishing extended
    pairing. The completion-level mirror of `innerI_constMul_zero`. -/
theorem pairingIU_constMul_zero (Φ : Nat → L2Test) (ψ : L2Test) (c : Real) {mB : Q}
    (hMd : 0 < mB.den) (hMn : 0 ≤ mB.num) (hb : Rle (Rabs c) (ofQ mB hMd)) (h : L2CauchyU Φ)
    (hz : Req (pairingIU Φ ψ h) zero) :
    Req (pairingIU Φ (L2Test.mul (constTest c mB hMd hMn hb) ψ) h) zero :=
  Req_trans (pairingIU_constMul Φ ψ c hMd hMn hb h)
    (Req_trans (Rmul_congr (Req_refl c) hz) (Rmul_zero c))

/-- **★ THE BERNSTEIN OPERATOR TEST PAIRS TO ZERO AT THE COMPLETION LEVEL**: if every extended moment
    of `Φ` vanishes, then `pairingIU Φ (B_n(χ)) h ≈ 0` for ANY approximated test `χ`. The completion-
    level mirror of `innerI_bernOpCTest_zero`: each operator summand is a real coefficient times a
    single Bernstein-basis pairing that already vanishes (`pairingIU_constMul_zero` ∘
    `pairingIU_clampProd_zero`), and the finite sum stays zero (`pairingIU_L2sumN_zero`). -/
theorem pairingIU_bernOpCTest_zero (Φ : Nat → L2Test) (h : L2CauchyU Φ)
    (hmom : ∀ i, Req (pairingIU Φ (powTest i) h) zero) (χ : L2Test) (n : Nat) (hn : 0 < n) :
    Req (pairingIU Φ (bernOpCTest χ n hn) h) zero :=
  pairingIU_L2sumN_zero Φ h (bernTermCTest χ n hn) (n + 1) (fun k _ =>
    pairingIU_constMul_zero Φ (clampProdTest k (n - k)) (bernCoef χ n hn k)
      (Qmul_den_pos χ.hMd Nat.one_pos)
      (Int.mul_nonneg χ.hMn (Int.ofNat_nonneg (choose n k))) (bernCoef_bound χ n hn k) h
      (pairingIU_clampProd_zero Φ h hmom (n - k) k))

end Multiplicity.UOR.Bridge.F1Square.Square
