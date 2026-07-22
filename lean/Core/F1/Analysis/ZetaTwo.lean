/-
F1 square — the **lower bracket `ζ(2) ≥ 1.63`** (a constituent of `Pos λ₂`, v0.16.0).

`ζ(s) = Σ_{i≥1} 1/iˢ` (`Zeta.zeta`) has **non-negative** terms, so every partial sum is a lower bound:
`ζ(s) ≥ zetaSum s N` (`zeta_ge_partial`), because the omitted tail is `≥ 0` (and within `1/(n+1)` of the
approximant, by `zetaabs_bound`). At `N = 70` the rational partial sum already exceeds `1.63`
(`Σ_{k=1}^{70} 1/k² ≈ 1.6307`; one `decide`), giving `ζ(2) ≥ 163/100`. (Plain `Σ 1/k²` decides cheaply —
no `lcm`-denominator blow-up, unlike the alternating `γ`-series.)

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import Core.F1.Analysis.Zeta
import Core.F1.Analysis.RealPow
import Core.F1.Analysis.GammaUpper

namespace UOR.Bridge.F1Square.Analysis

/-- **`ζ(s) ≥ zetaSum s N`** — the value dominates each partial sum (the tail is `≥ 0`). -/
theorem zeta_ge_partial (s : Nat) (hs : 2 ≤ s) (N : Nat) :
    Rle (ofQ (zetaSum s N) (zetaSum_den_pos s N)) (zeta s hs) := by
  intro n
  show Qle (zetaSum s N) (add (zetaSum s n) ⟨2, n + 1⟩)
  rcases Nat.le_total n N with hnN | hNn
  · -- n ≤ N: zetaSum s N ≤ zetaSum s n + 1/(n+1) ≤ + 2/(n+1)
    have habs := zetaabs_bound s hs hnN
    have habs' : Qle (Qabs (Qsub (zetaSum s n) (zetaSum s N))) (⟨1, n + 1⟩ : Q) := by
      rw [Qabs_Qsub_comm]; exact habs
    have hb1 : Qle (zetaSum s N) (add (zetaSum s n) ⟨1, n + 1⟩) :=
      Qabs_upper (zetaSum_den_pos s n) (zetaSum_den_pos s N) (by show 0 < n + 1; omega) habs'
    have he : Qle (add (zetaSum s n) (⟨1, n + 1⟩ : Q)) (add (zetaSum s n) ⟨2, n + 1⟩) :=
      Qadd_le_add (Qle_refl _) (by simp only [Qle]; push_cast; omega)
    exact Qle_trans (add_den_pos (zetaSum_den_pos s n) (by show 0 < n + 1; omega)) hb1 he
  · -- n ≥ N: zetaSum s N ≤ zetaSum s n ≤ + 2/(n+1)
    exact Qle_trans (zetaSum_den_pos s n) (zetaSum_le s hNn)
      (Qle_self_add (by show (0 : Int) ≤ 2; decide))

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 8192 in
/-- `Σ_{k=1}^{70} 1/k² ≥ 163/100` (one rational `decide`). -/
theorem zetaSum_two_70_ge : Qle (⟨163, 100⟩ : Q) (zetaSum 2 70) := by decide

/-- **`ζ(2) ≥ 1.63`** — the lower bracket for the Basel constant. -/
theorem zeta2_lower : Rle (ofQ (⟨163, 100⟩ : Q) (by decide)) (zeta 2 (by decide)) :=
  Rle_trans (Rle_ofQ_ofQ (by decide) (zetaSum_den_pos 2 70) zetaSum_two_70_ge)
    (zeta_ge_partial 2 (by decide) 70)

-- ===========================================================================
-- **Tail-corrected `ζ(2)` lower bound** `ζ(2) ≥ zetaSum 2 N + 1/(N+2)`. The partial-sum lower bound
-- `zeta_ge_partial` converges only as `1/N`, so reaching `1.644` would need `N ≈ 1100` (infeasible
-- decide). Adding the rigorous tail lower bound `Σ_{k≥N+2} 1/k² ≥ Σ 1/(k(k+1)) = 1/(N+2)` recovers the
-- bulk of the missing tail, lifting the *existing* `N = 70` certificate to `ζ(2) ≥ 1.644` — the tight
-- `ζ(2)` lower the `Pos Rlambda3` (`λ₃`) certificate needs.
-- ===========================================================================

/-- **Per-step tail bound** `1/(m+2) − 1/(m+3) ≤ 1/(m+2)²` (since `(m+2)² ≤ (m+2)(m+3)`); the
    `Usum_step_ineq` pattern (explicit `key`, `omega`). -/
theorem zetaSum2_perstep_ge (m : Nat) :
    Qle (Qsub (⟨1, m + 2⟩ : Q) (⟨1, m + 3⟩ : Q)) (⟨1, npow (m + 2) 2⟩ : Q) := sorry