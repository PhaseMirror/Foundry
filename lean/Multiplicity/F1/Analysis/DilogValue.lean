/-
F1 square — **the certified dilog lower bound** (`DilogValue.lean`):

    `t4Dilog ≥ 1909/1000 = 1.909`     (true value `∫₁⁴ log x/(x−1) dx = −Li₂(−3) ≈ 1.93939`).

The three piece bounds instantiate `dilogPiece_ge` with the short variation witnesses
`V₀ = 8/25 (≥ 0.3108)`, `V₁ = 3/20 (≥ 0.1490)`, `V₂ = 1/10 (≥ 0.0927)`, each certified against the
exact rational `qVc` by `decide`; the closing inequality is ONE rational `decide` over the three
`16×128`-point folds (outer dyadic level `M = 4`, kernel level `m = 7` — denominators astronomical,
arithmetic exact). No logs, no wedges: the first fully rational bracket of a log-type integral in
the repo.

HONEST SCOPE. A lower bound on the constructed dilog; nothing else. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.DilogPieces

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

set_option maxRecDepth 200000 in
set_option maxHeartbeats 64000000 in
/-- Variation witness, piece `[1,2]`: `qVc 0 ≤ 8/25`. -/
private theorem qVc0_le : Qle (qVc 0 7) (⟨8, 25⟩ : Q) := by decide

set_option maxRecDepth 200000 in
set_option maxHeartbeats 64000000 in
/-- Variation witness, piece `[2,3]`: `qVc 1 ≤ 3/20`. -/
private theorem qVc1_le : Qle (qVc 1 7) (⟨3, 20⟩ : Q) := by decide

set_option maxRecDepth 200000 in
set_option maxHeartbeats 64000000 in
/-- Variation witness, piece `[3,4]`: `qVc 2 ≤ 1/10`. -/
private theorem qVc2_le : Qle (qVc 2 7) (⟨1, 10⟩ : Q) := by decide

set_option maxRecDepth 200000 in
set_option maxHeartbeats 64000000 in
/-- **The certified dilog lower bound**: `t4Dilog ≥ 1.909` — the three rational piece bounds
    assemble and ONE exact rational comparison closes it. -/
theorem t4Dilog_ge : Rle (ofQ (⟨1909, 1000⟩ : Q) (by decide)) t4Dilog := by
  have h0 := dilogPiece_ge 0 (by omega) (V := (⟨8, 25⟩ : Q)) (by decide) (by decide) qVc0_le
  have h1 := dilogPiece_ge 1 (by omega) (V := (⟨3, 20⟩ : Q)) (by decide) (by decide) qVc1_le
  have h2 := dilogPiece_ge 2 (by omega) (V := (⟨1, 10⟩ : Q)) (by decide) (by decide) qVc2_le
  refine Rle_trans ?_ (Radd_le_add (Radd_le_add h0 h1) h2)
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (Req_trans
    (Radd_congr (Radd_ofQ_ofQ _ _) (Req_refl _)) (Radd_ofQ_ofQ _ _))))
  exact Rle_ofQ_ofQ (by decide) _ (by decide)

end Multiplicity.UOR.Bridge.F1Square.Analysis
