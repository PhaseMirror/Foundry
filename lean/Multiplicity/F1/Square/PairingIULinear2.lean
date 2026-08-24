/-
F1 square — scalar (ℕ) homogeneity and `[0,1]`-congruence of the extended L² pairing
(`PairingIULinear2.lean`), continuing `PairingIUReschedule.lean`. Two facts the completion-level
moment-determinacy argument consumes:

  • `pairingIU_natScale` — `pairingIU Φ (natScale c ψ) h = c · pairingIU Φ ψ h` (`natScaleR`), by
    induction from right-additivity (`pairingIU_add_right`) with base `pairingIU Φ zeroL2 h = 0`.
  • `pairingIU_unit_congr` — the extended pairing only sees the test's values on `[0,1]`: if
    `ψ ≈ ψ'` there, then `pairingIU Φ ψ h ≈ pairingIU Φ ψ' h`. Proof through the reschedule rate
    (`pairingIU_reschedule_rate`) at a common schedule `B = selfBnd ψ + selfBnd ψ'`, where the two
    `B`-scheduled reads agree by `innerI_right_congr_on_unit`.

These lift the H₁ Bernstein-basis reduction (`innerI_clampProd_zero`) from a fixed test to a limit
member: the scalar law handles the binomial normalization, the `[0,1]`-congruence handles the Pascal
recursion's unit-restriction step.

HONEST SCOPE. Scalar homogeneity and `[0,1]`-congruence of the extended pairing; NOT positivity, NOT
surjectivity. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1.Square.PairingIUReschedule
import Multiplicity.F1.Square.PairingUnitCongr
import Multiplicity.F1.Square.DeepMemberThree
import Multiplicity.F1.Square.ContinuousMomentGenScale

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Local algebra helpers (private).
-- ===========================================================================

/-- `|a − b| ≈ |b − a|` (local copy). -/
private theorem abs_sub_comm2 (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Req_symm (Rabs_Rneg (Rsub a b))) (Rabs_congr (Rneg_Rsub a b))

/-- Turn a two-sided `|a − b| ≤ C/(k+1)` bound into `a ≈ b` (local copy). -/
private theorem Req_of_Rabs_sub_le2 {a b : Real} {C : Nat}
    (hk : ∀ k, Rle (Rabs (Rsub a b)) (ofQ (⟨(C : Int), k + 1⟩ : Q) (Nat.succ_pos k))) :
    Req a b :=
  Req_of_Rle_ofQ_all
    (fun k => Rle_of_Rabs_le (hk k))
    (fun k => Rle_trans (Rle_Rabs_self (Rsub b a))
      (Rle_trans (Rle_of_Req (abs_sub_comm2 b a)) (hk k)))

/-- **The extended pairing of the zero test vanishes**: each read `⟨Φⱼ, 0⟩ ≈ 0`, so the limit is `0`. -/
private theorem pairingIU_zeroL2 (Φ : Nat → L2Test) (h : L2CauchyU Φ) :
    Req (pairingIU Φ zeroL2 h) zero :=
  Rlim_zero _ (pairingIU_RReg h zeroL2)
    (fun j => Req_trans (innerI_symm _ zeroL2) (innerI_zeroL2 _))

-- Unfold the sealed `natScale` as propositional equalities (the pattern from
-- `ContinuousMomentGenScale`/`DurrmeyerConverge`).
unseal natScale in
private theorem natScale_zero_p (φ : L2Test) : natScale 0 φ = zeroL2 := rfl

unseal natScale in
private theorem natScale_succ_p (k : Nat) (φ : L2Test) :
    natScale (k + 1) φ = L2Test.add φ (natScale k φ) := rfl

-- ===========================================================================
-- Scalar (ℕ) homogeneity.
-- ===========================================================================

/-- **RIGHT ℕ-HOMOGENEITY**: `pairingIU Φ (natScale c ψ) h = c · pairingIU Φ ψ h`
    (`natScaleR`, the real repeated-`Radd`). Induction on `c`: base is `pairingIU_zeroL2`, step is
    `pairingIU_add_right` folding one copy off. -/
theorem pairingIU_natScale (Φ : Nat → L2Test) (c : Nat) (ψ : L2Test) (h : L2CauchyU Φ) :
    Req (pairingIU Φ (natScale c ψ) h) (natScaleR c (pairingIU Φ ψ h)) := by
  induction c with
  | zero =>
    rw [natScale_zero_p]
    exact pairingIU_zeroL2 Φ h
  | succ c ih =>
    rw [natScale_succ_p]
    exact Req_trans (pairingIU_add_right Φ ψ (natScale c ψ) h)
      (Radd_congr (Req_refl (pairingIU Φ ψ h)) ih)

-- ===========================================================================
-- `[0,1]`-congruence in the test argument.
-- ===========================================================================

/-- **RIGHT `[0,1]`-CONGRUENCE**: the extended pairing sees the test only through its values on
    `[0,1]`. Reading `Φ` along the common schedule `B = selfBnd ψ + selfBnd ψ'`, the two `B`-scheduled
    reads `⟨Φ_{B(k+1)}, ψ⟩` and `⟨Φ_{B(k+1)}, ψ'⟩` agree (`innerI_right_congr_on_unit`), so both
    extended pairings agree up to `8/(k+1)` (`pairingIU_reschedule_rate` twice) — hence equal. -/
theorem pairingIU_unit_congr (Φ : Nat → L2Test) (ψ ψ' : L2Test) (h : L2CauchyU Φ)
    (hunit : ∀ x, Rle zero x → Rle x one → Req (ψ.f x) (ψ'.f x)) :
    Req (pairingIU Φ ψ h) (pairingIU Φ ψ' h) := by
  refine Req_of_Rabs_sub_le2 (C := 8) (fun k => ?_)
  have hBψ : selfBnd ψ ≤ selfBnd ψ + selfBnd ψ' := by omega
  have hBψ' : selfBnd ψ' ≤ selfBnd ψ + selfBnd ψ' := by omega
  have h4 : 0 < (⟨(4 : Int), k + 1⟩ : Q).den := Nat.succ_pos k
  -- the two B-scheduled reads agree on [0,1].
  have hreads : Req (innerI (Φ ((selfBnd ψ + selfBnd ψ') * (k + 1))) ψ)
                    (innerI (Φ ((selfBnd ψ + selfBnd ψ') * (k + 1))) ψ') :=
    innerI_right_congr_on_unit (Φ ((selfBnd ψ + selfBnd ψ') * (k + 1))) ψ ψ' hunit
  have hsplit : Req (Rsub (pairingIU Φ ψ h) (pairingIU Φ ψ' h))
      (Radd (Rsub (pairingIU Φ ψ h)
                  (innerI (Φ ((selfBnd ψ + selfBnd ψ') * (k + 1))) ψ'))
            (Rsub (innerI (Φ ((selfBnd ψ + selfBnd ψ') * (k + 1))) ψ')
                  (pairingIU Φ ψ' h))) :=
    Req_symm (Rsub_split _ _ _)
  -- first piece: rewrite ⟨·,ψ'⟩ back to ⟨·,ψ⟩, flip, reschedule at ψ.
  have hfirst : Rle (Rabs (Rsub (pairingIU Φ ψ h)
        (innerI (Φ ((selfBnd ψ + selfBnd ψ') * (k + 1))) ψ')))
      (ofQ (⟨4, k + 1⟩ : Q) (Nat.succ_pos k)) := by
    refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_refl _) (Req_symm hreads)))) ?_
    refine Rle_trans (Rle_of_Req (abs_sub_comm2 _ _)) ?_
    exact pairingIU_reschedule_rate Φ ψ h _ hBψ k
  -- second piece: reschedule at ψ'.
  have hsecond : Rle (Rabs (Rsub (innerI (Φ ((selfBnd ψ + selfBnd ψ') * (k + 1))) ψ')
        (pairingIU Φ ψ' h)))
      (ofQ (⟨4, k + 1⟩ : Q) (Nat.succ_pos k)) :=
    pairingIU_reschedule_rate Φ ψ' h _ hBψ' k
  have hQ8 : Qle (add (⟨4, k + 1⟩ : Q) (⟨4, k + 1⟩ : Q)) (⟨8, k + 1⟩ : Q) :=
    Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)
  refine Rle_trans (Rle_of_Req (Rabs_congr hsplit)) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add hfirst hsecond) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ h4 h4)) ?_
  exact Rle_ofQ_ofQ (add_den_pos h4 h4) (Nat.succ_pos k) hQ8

end Multiplicity.UOR.Bridge.F1Square.Square
