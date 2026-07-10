/-
F1 square — reusable limit-congruence infrastructure for Bishop's `Rlim`.

Two structural facts about the diagonal limit `(lim X)ₙ = (X(4n+3))_{4n+3}`:
* `Rlim_congr` — pointwise-`≈` regular sequences have `≈` limits (from `Req` at the diagonal index,
  since `2/(4n+4) ≤ 2/(n+1)`);
* `Rlim_neg` — the limit of the negated sequence is the negated limit (seq-equal, hence definitional).

These are the limit-level congruences any property/convergence argument over `Rlim`-built objects needs
(e.g. the complex digamma `CDigamma`'s symmetries, and the eventual `CSpougeGamma → Γ` convergence).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import F1Square.Analysis.Complete
import F1Square.Analysis.RealDiv

namespace UOR.Bridge.F1Square.Analysis

/-- **`Rinv` respects `≈`** (even across different positivity witnesses): `x ≈ y ⟹ 1/x ≈ 1/y`. No
    witness-dependent reindexing is needed — the cancellation `1/x ≈ (1/x)·(y·(1/y)) ≈ (1/x)·(x·(1/y))
    ≈ ((1/x)·x)·(1/y) ≈ 1·(1/y) ≈ 1/y` routes through `Rmul_Rinv_self` on both sides. -/
theorem Rinv_congr {x y : Real} {kx ky : Nat} (hkx : Qlt (Qbound kx) (x.seq kx))
    (hky : Qlt (Qbound ky) (y.seq ky)) (h : Req x y) :
    Req (Rinv x kx hkx) (Rinv y ky hky) := by
  have h1 : Req (Rinv x kx hkx) (Rmul (Rinv x kx hkx) (Rmul y (Rinv y ky hky))) :=
    Req_trans (Req_symm (Rmul_one (Rinv x kx hkx)))
      (Rmul_congr (Req_refl _) (Req_symm (Rmul_Rinv_self hky)))
  have h2 : Req (Rmul (Rinv x kx hkx) (Rmul y (Rinv y ky hky)))
      (Rmul (Rinv x kx hkx) (Rmul x (Rinv y ky hky))) :=
    Rmul_congr (Req_refl _) (Rmul_congr (Req_symm h) (Req_refl _))
  have h3 : Req (Rmul (Rinv x kx hkx) (Rmul x (Rinv y ky hky))) (Rinv y ky hky) :=
    Req_trans (Req_symm (Rmul_assoc _ _ _))
      (Req_trans (Rmul_congr (Req_trans (Rmul_comm _ _) (Rmul_Rinv_self hkx)) (Req_refl _))
        (Req_trans (Rmul_comm one _) (Rmul_one _)))
  exact Req_trans h1 (Req_trans h2 h3)

/-- **`Rlim` respects pointwise `≈`**: if `X j ≈ Y j` for every `j`, then `lim X ≈ lim Y`. At index `n`
    both limits read their diagonal entry at `4n+3`; the hypothesis at `(4n+3, 4n+3)` bounds the gap by
    `2/(4n+4) ≤ 2/(n+1)`. -/
theorem Rlim_congr (X Y : Nat → Real) (hX : RReg X) (hY : RReg Y) (h : ∀ j, Req (X j) (Y j)) :
    Req (Rlim X hX) (Rlim Y hY) := by
  intro n
  rw [Rlim_seq, Rlim_seq]
  have hb := h (4 * n + 3) (4 * n + 3)
  have hstep : Qle (⟨2, (4 * n + 3) + 1⟩ : Q) (⟨2, n + 1⟩ : Q) := by
    show (2 : Int) * ((n + 1 : Nat) : Int) ≤ (2 : Int) * (((4 * n + 3) + 1 : Nat) : Int)
    push_cast; omega
  exact Qle_trans (Nat.succ_pos _) hb hstep

/-- **`Rlim` commutes with negation**: `lim (−X) ≈ −(lim X)`. Both sides have the identical diagonal
    `seq` `neg (X(4n+3))_{4n+3}`, so this is definitional. -/
theorem Rlim_neg (X : Nat → Real) (hX : RReg X) (hNX : RReg (fun j => Rneg (X j))) :
    Req (Rlim (fun j => Rneg (X j)) hNX) (Rneg (Rlim X hX)) :=
  Req_of_seq_Qeq (fun _ => Qeq_refl _)

/-- **A pointwise-`0` regular sequence has limit `0`**: `(∀ j, X j ≈ 0) ⟹ lim X ≈ 0` (the `≈ 0`
    specialization of `Rlim_congr`). -/
theorem Rlim_zero (X : Nat → Real) (hX : RReg X) (hz : ∀ j, Req (X j) zero) :
    Req (Rlim X hX) zero := by
  intro n
  rw [Rlim_seq]
  have hstep : Qle (⟨2, (4 * n + 3) + 1⟩ : Q) (⟨2, n + 1⟩ : Q) := by
    show (2 : Int) * ((n + 1 : Nat) : Int) ≤ (2 : Int) * (((4 * n + 3) + 1 : Nat) : Int)
    push_cast; omega
  exact Qle_trans (Nat.succ_pos _) (hz (4 * n + 3) (4 * n + 3)) hstep

end UOR.Bridge.F1Square.Analysis
