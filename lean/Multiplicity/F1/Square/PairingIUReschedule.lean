/-
F1 square — schedule-independence and right-linearity of the extended L² pairing
(`PairingIUReschedule.lean`). `pairingIU Φ ψ h` reads `Φ` along the ψ-dependent schedule
`j ↦ selfBnd ψ · (j+1)`. This brick shows any coarser schedule `j ↦ B·(j+1)` with
`B ≥ selfBnd ψ` gives the SAME limit at rate `4/(k+1)` (`pairingIU_reschedule_rate`), and
derives right-additivity / -negation / -subtraction of `pairingIU` in the test argument
(`pairingIU_add_right`, `pairingIU_neg_right`, `pairingIU_sub_right`) — the linearity the
completion-level moment-determinacy argument consumes.

HONEST SCOPE. Schedule-independence and right-linearity of the extended pairing; NOT positivity,
NOT surjectivity. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1.Square.L2Complete

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small algebra helpers (local, private).
-- ===========================================================================

/-- `|z|² ≈ z²` (local copy of `PairingLimitI.abs_sq'`, which is private there). -/
private theorem abs_sq_loc (z : Real) : Req (Rmul (Rabs z) (Rabs z)) (Rmul z z) :=
  Req_trans (Req_symm (Rabs_Rmul z z)) (Rabs_of_nonneg (Rnonneg_Rmul_self z))

/-- `|a − b| ≈ |b − a|`. -/
private theorem abs_sub_comm (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Req_symm (Rabs_Rneg (Rsub a b))) (Rabs_congr (Rneg_Rsub a b))

/-- Turn a two-sided `|a − b| ≤ C/(k+1)` bound into `a ≈ b`. -/
private theorem Req_of_Rabs_sub_le {a b : Real} {C : Nat}
    (hk : ∀ k, Rle (Rabs (Rsub a b)) (ofQ (⟨(C : Int), k + 1⟩ : Q) (Nat.succ_pos k))) :
    Req a b :=
  Req_of_Rle_ofQ_all
    (fun k => Rle_of_Rabs_le (hk k))
    (fun k => Rle_trans (Rle_Rabs_self (Rsub b a))
      (Rle_trans (Rle_of_Req (abs_sub_comm b a)) (hk k)))

/-- `(a+b)+(c+d) ≈ (a+c)+(b+d)`. -/
private theorem add4_regroup (a b c d : Real) :
    Req (Radd (Radd a b) (Radd c d)) (Radd (Radd a c) (Radd b d)) :=
  Req_trans (Radd_assoc a b (Radd c d))
    (Req_trans (Radd_congr (Req_refl a) (Req_symm (Radd_assoc b c d)))
      (Req_trans (Radd_congr (Req_refl a) (Radd_congr (Radd_comm b c) (Req_refl d)))
        (Req_trans (Radd_congr (Req_refl a) (Radd_assoc c b d))
          (Req_symm (Radd_assoc a c (Radd b d))))))

/-- `(a+b) − (c+d) ≈ (a−c) + (b−d)`. -/
private theorem sub_add_regroup (a b c d : Real) :
    Req (Rsub (Radd a b) (Radd c d)) (Radd (Rsub a c) (Rsub b d)) :=
  Req_trans (Radd_congr (Req_refl (Radd a b)) (Rneg_Radd c d))
    (add4_regroup a b (Rneg c) (Rneg d))

/-- `(−a) − (−b) ≈ −(a − b)`. -/
private theorem sub_neg_neg (a b : Real) : Req (Rsub (Rneg a) (Rneg b)) (Rneg (Rsub a b)) :=
  Req_symm (Rneg_Radd a (Rneg b))

/-- **Additivity in the second slot** was proven in `IntegralBilinear`; the negation companion
    `⟨φ, −ψ⟩ ≈ −⟨φ, ψ⟩` follows by symmetry from `innerI_neg_left`. -/
private theorem innerI_neg_right (φ ψ : L2Test) :
    Req (innerI φ (L2Test.neg ψ)) (Rneg (innerI φ ψ)) :=
  Req_trans (innerI_symm φ (L2Test.neg ψ))
    (Req_trans (innerI_neg_left ψ φ) (Rneg_congr (innerI_symm ψ φ)))

-- ===========================================================================
-- The two-schedule rational core.
-- ===========================================================================

/-- **THE RESCHEDULE INEQUALITY** (asymmetric): with `B ≥ S ≥ 1`, the squared cross-schedule
    modulus `(1/(B(k+1)+1) + 1/(S(k+1)+1))²`, times the energy bound `S`, stays below
    `(2/(k+1))²`. The `B`-slot only helps (`1/(B(k+1)+1) ≤ 1/(S(k+1)+1)`), so after
    monotonicity the estimate collapses to the symmetric `S`-step `S·(k+1)² ≤ (S(k+1)+1)²`. -/
private theorem reschedule_Q (S B k : Nat) (hS : 1 ≤ S) (hB : S ≤ B) :
    Qle (mul (mul (add (⟨1, B * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))
                  (add (⟨1, B * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)))
             (⟨((S : Nat) : Int), 1⟩ : Q))
        (mul (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
             (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q))) := by
  have hFd : 0 < (add (⟨1, B * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)).den :=
    add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)
  have hFn : 0 ≤ (add (⟨1, B * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)).num :=
    Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide)
  have hGd : 0 < (add (⟨1, S * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)).den :=
    add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)
  have hinv : Qle (⟨1, B * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q) := by
    have hmul : S * (k + 1) ≤ B * (k + 1) := Nat.mul_le_mul hB (Nat.le_refl (k + 1))
    show (1 : Int) * ((S * (k + 1) + 1 : Nat) : Int) ≤ (1 : Int) * ((B * (k + 1) + 1 : Nat) : Int)
    omega
  have hFG : Qle (add (⟨1, B * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))
                 (add (⟨1, S * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)) :=
    Qadd_le_add hinv (Qle_refl _)
  have hFsq : Qle (mul (add (⟨1, B * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))
                       (add (⟨1, B * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)))
                  (mul (add (⟨1, S * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))
                       (add (⟨1, S * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))) :=
    Qmul_le_mul hFd hGd hFd hFn hFn hFG hFG
  have hSnn : (0 : Int) ≤ ((S : Nat) : Int) := Int.ofNat_nonneg _
  have hFsqS := Qmul_le_mul_right (c := (⟨((S : Nat) : Int), 1⟩ : Q)) hSnn hFsq
  have hlast : Qle (mul (mul (add (⟨1, S * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))
                             (add (⟨1, S * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)))
                        (⟨((S : Nat) : Int), 1⟩ : Q))
                   (mul (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
                        (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q))) := by
    have hs1 : (1 : Int) ≤ (S : Int) := by omega
    have hs0 : (0 : Int) ≤ (S : Int) := by omega
    have hsm : (0 : Int) ≤ (S : Int) - 1 := by omega
    have hw0 : (0 : Int) ≤ (k : Int) + 1 := by omega
    have hsw0 : (0 : Int) ≤ (S : Int) * ((k : Int) + 1) + 1 := by
      have := Int.mul_nonneg hs0 hw0; omega
    have hfac : (0 : Int) ≤ (S : Int) * ((k : Int) + 1) * ((k : Int) + 1) * ((S : Int) - 1)
        + 2 * (S : Int) * ((k : Int) + 1) + 1 := by
      have h1 : (0 : Int) ≤ (S : Int) * ((k : Int) + 1) * ((k : Int) + 1) * ((S : Int) - 1) :=
        Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg hs0 hw0) hw0) hsm
      have h2 : (0 : Int) ≤ 2 * (S : Int) * ((k : Int) + 1) :=
        Int.mul_nonneg (Int.mul_nonneg (by decide) hs0) hw0
      omega
    have hprod : (0 : Int) ≤ 4 * ((S : Int) * ((k : Int) + 1) + 1) * ((S : Int) * ((k : Int) + 1) + 1)
        * ((k : Int) + 1) * ((k : Int) + 1)
        * ((S : Int) * ((k : Int) + 1) * ((k : Int) + 1) * ((S : Int) - 1)
           + 2 * (S : Int) * ((k : Int) + 1) + 1) :=
      Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg
        (Int.mul_nonneg (by decide) hsw0) hsw0) hw0) hw0) hfac
    simp only [Qle, mul, add]
    push_cast
    refine Int.le_of_sub_nonneg ?_
    have heq : (1 * ((k : Int) + 1) + 1 * ((k : Int) + 1)) * (1 * ((k : Int) + 1) + 1 * ((k : Int) + 1)) *
          (((S : Int) * ((k : Int) + 1) + 1) * ((S : Int) * ((k : Int) + 1) + 1)
            * (((S : Int) * ((k : Int) + 1) + 1) * ((S : Int) * ((k : Int) + 1) + 1)) * 1) -
        (1 * ((S : Int) * ((k : Int) + 1) + 1) + 1 * ((S : Int) * ((k : Int) + 1) + 1))
          * (1 * ((S : Int) * ((k : Int) + 1) + 1) + 1 * ((S : Int) * ((k : Int) + 1) + 1)) * (S : Int) *
            (((k : Int) + 1) * ((k : Int) + 1) * (((k : Int) + 1) * ((k : Int) + 1)))
        = 4 * ((S : Int) * ((k : Int) + 1) + 1) * ((S : Int) * ((k : Int) + 1) + 1)
          * ((k : Int) + 1) * ((k : Int) + 1)
          * ((S : Int) * ((k : Int) + 1) * ((k : Int) + 1) * ((S : Int) - 1)
             + 2 * (S : Int) * ((k : Int) + 1) + 1) := by ring_uor
    rw [heq]
    exact hprod
  exact Qle_trans (Qmul_den_pos (Qmul_den_pos hGd hGd) Nat.one_pos) hFsqS hlast

-- ===========================================================================
-- The reschedule rate.
-- ===========================================================================

/-- **SCHEDULE-INDEPENDENCE OF THE EXTENDED PAIRING**: reading `Φ` along ANY schedule
    `j ↦ B·(j+1)` with `B ≥ selfBnd ψ` converges to the SAME limit `pairingIU Φ ψ h`, at
    rate `4/(k+1)`. -/
theorem pairingIU_reschedule_rate (Φ : Nat → L2Test) (ψ : L2Test) (h : L2CauchyU Φ)
    (B : Nat) (hB : selfBnd ψ ≤ B) (k : Nat) :
    Rle (Rabs (Rsub (innerI (Φ (B * (k + 1))) ψ) (pairingIU Φ ψ h)))
        (ofQ (⟨4, k + 1⟩ : Q) (Nat.succ_pos k)) := by
  have hE : 0 < (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q)).den :=
    add_den_pos (Nat.succ_pos k) (Nat.succ_pos k)
  have hEn : 0 ≤ (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q)).num :=
    Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide)
  have hMd : 0 < (mul (add (⟨1, B * (k + 1) + 1⟩ : Q) (⟨1, selfBnd ψ * (k + 1) + 1⟩ : Q))
                      (add (⟨1, B * (k + 1) + 1⟩ : Q) (⟨1, selfBnd ψ * (k + 1) + 1⟩ : Q))).den :=
    Qmul_den_pos (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
                 (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
  -- The cross-schedule gap `D = ⟨Φ_{B(k+1)}, ψ⟩ − ⟨Φ_{S(k+1)}, ψ⟩` is bounded by `2/(k+1)`.
  have hDsq : Rle (Rmul (Rabs (Rsub (innerI (Φ (B * (k + 1))) ψ)
                                    (innerI (Φ (selfBnd ψ * (k + 1))) ψ)))
                        (Rabs (Rsub (innerI (Φ (B * (k + 1))) ψ)
                                    (innerI (Φ (selfBnd ψ * (k + 1))) ψ))))
                  (Rmul (ofQ (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) hE)
                        (ofQ (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) hE)) := by
    refine Rle_trans (Rle_of_Req (abs_sq_loc _)) ?_
    refine Rle_trans (innerI_sub_sq_le (Φ (B * (k + 1))) (Φ (selfBnd ψ * (k + 1))) ψ) ?_
    refine Rle_trans (Rmul_le_Rmul_both
      (dist2I_nonneg (Φ (B * (k + 1))) (Φ (selfBnd ψ * (k + 1))))
      (Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg _))
      (h (B * (k + 1)) (selfBnd ψ * (k + 1)))
      (innerI_self_le_selfBnd ψ)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ hMd Nat.one_pos)) ?_
    refine Rle_trans (Rle_ofQ_ofQ (Qmul_den_pos hMd Nat.one_pos) (Qmul_den_pos hE hE)
      (reschedule_Q (selfBnd ψ) B k (selfBnd_pos ψ) hB)) ?_
    exact Rle_of_Req (Req_symm (Rmul_ofQ_ofQ hE hE))
  have hDbound : Rle (Rabs (Rsub (innerI (Φ (B * (k + 1))) ψ)
                                 (innerI (Φ (selfBnd ψ * (k + 1))) ψ)))
                     (ofQ (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) hE) :=
    Rle_of_Rsq_le (Rnonneg_Rabs _) (Rnonneg_ofQ hE hEn) hDsq
  -- Split `⟨Φ_{B(k+1)},ψ⟩ − pairingIU` through `⟨Φ_{S(k+1)},ψ⟩` and add the tail rate.
  have hsplit : Req (Rsub (innerI (Φ (B * (k + 1))) ψ) (pairingIU Φ ψ h))
      (Radd (Rsub (innerI (Φ (B * (k + 1))) ψ) (innerI (Φ (selfBnd ψ * (k + 1))) ψ))
            (Rsub (innerI (Φ (selfBnd ψ * (k + 1))) ψ) (pairingIU Φ ψ h))) :=
    Req_symm (Rsub_split (innerI (Φ (B * (k + 1))) ψ)
      (innerI (Φ (selfBnd ψ * (k + 1))) ψ) (pairingIU Φ ψ h))
  have hQ4 : Qle (add (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q)) (⟨2, k + 1⟩ : Q)) (⟨4, k + 1⟩ : Q) :=
    Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)
  refine Rle_trans (Rle_of_Req (Rabs_congr hsplit)) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add hDbound (pairingIU_dist Φ ψ h k)) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ hE (Nat.succ_pos k))) ?_
  exact Rle_ofQ_ofQ (add_den_pos hE (Nat.succ_pos k)) (Nat.succ_pos k) hQ4

-- ===========================================================================
-- Right-linearity of the extended pairing.
-- ===========================================================================

/-- **RIGHT-ADDITIVITY**: `pairingIU Φ (ψ + χ) = pairingIU Φ ψ + pairingIU Φ χ`. -/
theorem pairingIU_add_right (Φ : Nat → L2Test) (ψ χ : L2Test) (h : L2CauchyU Φ) :
    Req (pairingIU Φ (L2Test.add ψ χ) h)
        (Radd (pairingIU Φ ψ h) (pairingIU Φ χ h)) := by
  refine Req_of_Rabs_sub_le (C := 12) (fun k => ?_)
  have hBψ : selfBnd ψ ≤ selfBnd ψ + selfBnd χ + selfBnd (L2Test.add ψ χ) := by omega
  have hBχ : selfBnd χ ≤ selfBnd ψ + selfBnd χ + selfBnd (L2Test.add ψ χ) := by omega
  have hBψχ : selfBnd (L2Test.add ψ χ) ≤ selfBnd ψ + selfBnd χ + selfBnd (L2Test.add ψ χ) := by omega
  have h4 : 0 < (⟨(4 : Int), k + 1⟩ : Q).den := Nat.succ_pos k
  -- split through `⟨Φ_{B(k+1)}, ψ + χ⟩`.
  have hsplit : Req (Rsub (pairingIU Φ (L2Test.add ψ χ) h)
        (Radd (pairingIU Φ ψ h) (pairingIU Φ χ h)))
      (Radd (Rsub (pairingIU Φ (L2Test.add ψ χ) h)
                  (innerI (Φ ((selfBnd ψ + selfBnd χ + selfBnd (L2Test.add ψ χ)) * (k + 1)))
                          (L2Test.add ψ χ)))
            (Rsub (innerI (Φ ((selfBnd ψ + selfBnd χ + selfBnd (L2Test.add ψ χ)) * (k + 1)))
                          (L2Test.add ψ χ))
                  (Radd (pairingIU Φ ψ h) (pairingIU Φ χ h)))) :=
    Req_symm (Rsub_split _ _ _)
  -- first piece: the reschedule rate at `ψ + χ`.
  have hfirst : Rle (Rabs (Rsub (pairingIU Φ (L2Test.add ψ χ) h)
        (innerI (Φ ((selfBnd ψ + selfBnd χ + selfBnd (L2Test.add ψ χ)) * (k + 1)))
                (L2Test.add ψ χ))))
      (ofQ (⟨4, k + 1⟩ : Q) (Nat.succ_pos k)) :=
    Rle_trans (Rle_of_Req (abs_sub_comm _ _))
      (pairingIU_reschedule_rate Φ (L2Test.add ψ χ) h _ hBψχ k)
  -- second piece: split `⟨·, ψ + χ⟩ = ⟨·, ψ⟩ + ⟨·, χ⟩`, then reschedule at ψ and χ.
  have hregroup : Req (Rsub (innerI (Φ ((selfBnd ψ + selfBnd χ + selfBnd (L2Test.add ψ χ)) * (k + 1)))
                                    (L2Test.add ψ χ))
                            (Radd (pairingIU Φ ψ h) (pairingIU Φ χ h)))
      (Radd (Rsub (innerI (Φ ((selfBnd ψ + selfBnd χ + selfBnd (L2Test.add ψ χ)) * (k + 1))) ψ)
                  (pairingIU Φ ψ h))
            (Rsub (innerI (Φ ((selfBnd ψ + selfBnd χ + selfBnd (L2Test.add ψ χ)) * (k + 1))) χ)
                  (pairingIU Φ χ h))) :=
    Req_trans (Rsub_congr (innerI_add_right _ ψ χ) (Req_refl _))
      (sub_add_regroup _ _ _ _)
  have hsecond : Rle (Rabs (Rsub
        (innerI (Φ ((selfBnd ψ + selfBnd χ + selfBnd (L2Test.add ψ χ)) * (k + 1))) (L2Test.add ψ χ))
        (Radd (pairingIU Φ ψ h) (pairingIU Φ χ h))))
      (Radd (ofQ (⟨4, k + 1⟩ : Q) (Nat.succ_pos k)) (ofQ (⟨4, k + 1⟩ : Q) (Nat.succ_pos k))) := by
    refine Rle_trans (Rle_of_Req (Rabs_congr hregroup)) ?_
    refine Rle_trans (Rabs_Radd _ _) ?_
    exact Radd_le_add (pairingIU_reschedule_rate Φ ψ h _ hBψ k)
      (pairingIU_reschedule_rate Φ χ h _ hBχ k)
  have hQ12 : Qle (add (⟨4, k + 1⟩ : Q) (add (⟨4, k + 1⟩ : Q) (⟨4, k + 1⟩ : Q))) (⟨12, k + 1⟩ : Q) :=
    Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)
  refine Rle_trans (Rle_of_Req (Rabs_congr hsplit)) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add hfirst hsecond) ?_
  refine Rle_trans (Rle_of_Req (Req_trans (Radd_congr (Req_refl _) (Radd_ofQ_ofQ h4 h4))
    (Radd_ofQ_ofQ h4 (add_den_pos h4 h4)))) ?_
  exact Rle_ofQ_ofQ (add_den_pos h4 (add_den_pos h4 h4)) (Nat.succ_pos k) hQ12

/-- **RIGHT-NEGATION**: `pairingIU Φ (−ψ) = −pairingIU Φ ψ`. -/
theorem pairingIU_neg_right (Φ : Nat → L2Test) (ψ : L2Test) (h : L2CauchyU Φ) :
    Req (pairingIU Φ (L2Test.neg ψ) h) (Rneg (pairingIU Φ ψ h)) := by
  refine Req_of_Rabs_sub_le (C := 8) (fun k => ?_)
  have hBnψ : selfBnd (L2Test.neg ψ) ≤ selfBnd ψ + selfBnd (L2Test.neg ψ) := by omega
  have hBψ : selfBnd ψ ≤ selfBnd ψ + selfBnd (L2Test.neg ψ) := by omega
  have h4 : 0 < (⟨(4 : Int), k + 1⟩ : Q).den := Nat.succ_pos k
  have hsplit : Req (Rsub (pairingIU Φ (L2Test.neg ψ) h) (Rneg (pairingIU Φ ψ h)))
      (Radd (Rsub (pairingIU Φ (L2Test.neg ψ) h)
                  (innerI (Φ ((selfBnd ψ + selfBnd (L2Test.neg ψ)) * (k + 1))) (L2Test.neg ψ)))
            (Rsub (innerI (Φ ((selfBnd ψ + selfBnd (L2Test.neg ψ)) * (k + 1))) (L2Test.neg ψ))
                  (Rneg (pairingIU Φ ψ h)))) :=
    Req_symm (Rsub_split _ _ _)
  have hfirst : Rle (Rabs (Rsub (pairingIU Φ (L2Test.neg ψ) h)
        (innerI (Φ ((selfBnd ψ + selfBnd (L2Test.neg ψ)) * (k + 1))) (L2Test.neg ψ))))
      (ofQ (⟨4, k + 1⟩ : Q) (Nat.succ_pos k)) :=
    Rle_trans (Rle_of_Req (abs_sub_comm _ _))
      (pairingIU_reschedule_rate Φ (L2Test.neg ψ) h _ hBnψ k)
  have hstep : Req (Rsub (innerI (Φ ((selfBnd ψ + selfBnd (L2Test.neg ψ)) * (k + 1))) (L2Test.neg ψ))
                         (Rneg (pairingIU Φ ψ h)))
      (Rneg (Rsub (innerI (Φ ((selfBnd ψ + selfBnd (L2Test.neg ψ)) * (k + 1))) ψ)
                  (pairingIU Φ ψ h))) :=
    Req_trans (Rsub_congr (innerI_neg_right _ ψ) (Req_refl _)) (sub_neg_neg _ _)
  have hsecond : Rle (Rabs (Rsub
        (innerI (Φ ((selfBnd ψ + selfBnd (L2Test.neg ψ)) * (k + 1))) (L2Test.neg ψ))
        (Rneg (pairingIU Φ ψ h))))
      (ofQ (⟨4, k + 1⟩ : Q) (Nat.succ_pos k)) := by
    refine Rle_trans (Rle_of_Req (Rabs_congr hstep)) ?_
    refine Rle_trans (Rle_of_Req (Rabs_Rneg _)) ?_
    exact pairingIU_reschedule_rate Φ ψ h _ hBψ k
  have hQ8 : Qle (add (⟨4, k + 1⟩ : Q) (⟨4, k + 1⟩ : Q)) (⟨8, k + 1⟩ : Q) :=
    Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)
  refine Rle_trans (Rle_of_Req (Rabs_congr hsplit)) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add hfirst hsecond) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ h4 h4)) ?_
  exact Rle_ofQ_ofQ (add_den_pos h4 h4) (Nat.succ_pos k) hQ8

/-- **RIGHT-SUBTRACTION**: `pairingIU Φ (ψ − χ) = pairingIU Φ ψ − pairingIU Φ χ`. -/
theorem pairingIU_sub_right (Φ : Nat → L2Test) (ψ χ : L2Test) (h : L2CauchyU Φ) :
    Req (pairingIU Φ (L2Test.sub ψ χ) h)
        (Rsub (pairingIU Φ ψ h) (pairingIU Φ χ h)) :=
  Req_trans (pairingIU_add_right Φ ψ (L2Test.neg χ) h)
    (Radd_congr (Req_refl (pairingIU Φ ψ h)) (pairingIU_neg_right Φ χ h))

end Multiplicity.UOR.Bridge.F1Square.Square
