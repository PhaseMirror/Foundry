/-
F1 square — **certified integration: the FINITE TELESCOPING of adjacent-window interval integrals**
(`IntervalTelescope.lean`), exhaustion rung 3. For an increasing rational endpoint sequence
`c : ℕ → ℚ`, the sum of the adjacent-window interval integrals collapses to the whole-interval
integral:

    `Σ_{m<N} ∫_{c m}^{c (m+1)} f  ≈  ∫_{c 0}^{c N} f`   (`riemannIntegralI_telescope`).

The proof is a pure finite-additivity induction on `N` driven by the interval-level general
split-point additivity `riemannIntegralI_split_at` (brick `IntervalSplitAtCap`). At level `N+1` the
whole window `[c 0, c (N+1)]` is split at the node `c N` (split width `Qsub (c N) (c 0)`), whose
left piece is `[c 0, c N]` (the inductive whole, matched by the endpoint congruence
`riemannIntegralI_congr_Q`) and whose right piece is the new window `[c N, c (N+1)]`. The degenerate
base rungs (`N = 0`, width-zero whole; `N = 1`, a single window against the empty prefix) are handled
directly, since `riemannIntegralI_split_at` requires a strictly positive split width.

HONEST SCOPE. The finite telescoping of adjacent-window interval integrals over an increasing
rational sequence (`RsumN` of the windows = the whole-interval integral), by
`riemannIntegralI_split_at` induction. It builds NO improper integral, NO limit, NO dilation
covariance, NO factorization, NO positivity, NO determinacy, NO crux. The improper-level
exhaustion-independence (`Rlim`) is a LATER rung, not performed here. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.IntervalSplitAtCap
import Multiplicity.F1.Square.IntervalPiece
import Multiplicity.F1.Analysis.RSum

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000 in
/-- **THE FINITE TELESCOPING OF ADJACENT-WINDOW INTERVAL INTEGRALS.** For an increasing rational
    endpoint sequence `c` (denominators positive, adjacent/whole widths nonnegative, whole widths
    strictly positive from level 1, monotone, remainders nonnegative), the sum of the `N` adjacent
    windows `[c m, c (m+1)]` equals the whole interval integral `[c 0, c N]`:

      `Σ_{m<N} ∫_{c m}^{c (m+1)} f  ≈  ∫_{c 0}^{c N} f`.

    Pure finite additivity by induction on `N`, driven by `riemannIntegralI_split_at` splitting the
    whole window at the last node `c N` and reconciled through `riemannIntegralI_congr_Q`. -/
theorem riemannIntegralI_telescope {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (c : Nat → Q)
    (hc_den : ∀ m, 0 < (c m).den)
    (hwin : ∀ m, 0 ≤ (Qsub (c (m + 1)) (c m)).num)
    (hWn : ∀ N, 0 ≤ (Qsub (c N) (c 0)).num)
    (hWpos : ∀ N, 0 < (Qsub (c (N + 1)) (c 0)).num)
    (hWle : ∀ N, Qle (Qsub (c N) (c 0)) (Qsub (c (N + 1)) (c 0)))
    (hrem : ∀ N, 0 ≤ (Qsub (Qsub (c (N + 1)) (c 0)) (Qsub (c N) (c 0))).num) :
    ∀ N, Req
      (RsumN (fun m => riemannIntegralI hLd hLn hlip hfc (c m) (Qsub (c (m + 1)) (c m))
          (hc_den m) (Qsub_den_pos (hc_den (m + 1)) (hc_den m)) (hwin m)) N)
      (riemannIntegralI hLd hLn hlip hfc (c 0) (Qsub (c N) (c 0))
          (hc_den 0) (Qsub_den_pos (hc_den N) (hc_den 0)) (hWn N)) := by
  intro N
  induction N with
  | zero =>
    -- `Σ_{m<0} = 0` and the whole is a width-zero integral, itself `≈ 0`.
    refine Req_symm ?_
    have hnum0 : (Qsub (c 0) (c 0)).num = 0 := by simp only [Qsub, add, neg]; ring_uor
    have hz : Req (ofQ (Qsub (c 0) (c 0)) (Qsub_den_pos (hc_den 0) (hc_den 0))) zero :=
      Req_trans
        (ofQ_congr (b := (⟨0, (Qsub (c 0) (c 0)).den⟩ : Q))
          (Qsub_den_pos (hc_den 0) (hc_den 0)) (Qsub_den_pos (hc_den 0) (hc_den 0))
          (by simp only [Qeq]; rw [hnum0]))
        (ofQ_zero_num (Qsub_den_pos (hc_den 0) (hc_den 0)))
    exact Req_trans (Rmul_congr hz (Req_refl _)) (Req_trans (Rmul_comm zero _) (Rmul_zero _))
  | succ N IH =>
    cases N with
    | zero =>
      -- level 1: the single window `[c 0, c 1]` against the empty prefix `0`.
      exact Req_trans (Radd_comm zero _) (Radd_zero _)
    | succ N' =>
      -- level `N' + 2`: split the whole window `[c 0, c (N'+2)]` at the node `c (N'+1)`.
      have hsplit := riemannIntegralI_split_at hLd hLn hlip hfc (c 0)
        (Qsub (c (N' + 2)) (c 0)) (Qsub (c (N' + 1)) (c 0)) (hc_den 0)
        (Qsub_den_pos (hc_den (N' + 2)) (hc_den 0)) (hWn (N' + 2))
        (Qsub_den_pos (hc_den (N' + 1)) (hc_den 0)) (hWpos N') (hWle (N' + 1)) (hrem (N' + 1))
      have hbaseQeq : Qeq (add (c 0) (Qsub (c (N' + 1)) (c 0))) (c (N' + 1)) := by
        simp only [Qeq, add, Qsub, neg]; push_cast; ring_uor
      have hwidQeq : Qeq (Qsub (Qsub (c (N' + 2)) (c 0)) (Qsub (c (N' + 1)) (c 0)))
          (Qsub (c (N' + 2)) (c (N' + 1))) := by
        simp only [Qeq, add, Qsub, neg]; push_cast; ring_uor
      refine Req_trans (Radd_congr IH (Req_refl _)) (Req_symm (Req_trans hsplit ?_))
      refine Radd_congr (Req_refl _) ?_
      exact riemannIntegralI_congr_Q hLd hLn hlip hfc
        (add (c 0) (Qsub (c (N' + 1)) (c 0)))
        (Qsub (Qsub (c (N' + 2)) (c 0)) (Qsub (c (N' + 1)) (c 0)))
        (c (N' + 1)) (Qsub (c (N' + 2)) (c (N' + 1)))
        (add_den_pos (hc_den 0) (Qsub_den_pos (hc_den (N' + 1)) (hc_den 0)))
        (Qsub_den_pos (Qsub_den_pos (hc_den (N' + 2)) (hc_den 0))
          (Qsub_den_pos (hc_den (N' + 1)) (hc_den 0)))
        (hrem (N' + 1))
        (hc_den (N' + 1)) (Qsub_den_pos (hc_den (N' + 2)) (hc_den (N' + 1))) (hwin (N' + 1))
        hbaseQeq hwidQeq

end Multiplicity.UOR.Bridge.F1Square.Square
