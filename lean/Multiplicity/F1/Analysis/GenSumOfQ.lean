/-
F1 square — **genSum of embedded rationals collapses to a single rational** (`GenSumOfQ.lean`):

    `genSum (fun i => ofQ (g i)) N  ≈  ofQ (qGenSum g N)`,

where `qGenSum g` is the rational partial-sum mirroring `genSum` term-for-term. A finite real
partial sum whose every summand is an embedded rational is itself an embedded rational — its value
is the rational range-sum, computed once at the `Q` level.

WHY. The Mellin scale-continuity gap (`covComb_scale_split`) carries a "head" term
`head_N = genSum (fun m => ofQ (φ.L·(m+2)·(powWinTest m n).M)) N` — a `genSum` of `ofQ` constants.
This lemma exposes `head_N` as `ofQ (H_N)` for the concrete rational `H_N = qGenSum … N`, which is
exactly what lets a *rational* index schedule drive the continuity gap to `0` and discharge the
covariance's `hbound` (making the real-scale dilation covariance unconditional). It is the `genSum`
analog of `RsumN_ofQ_qsumL_range`, proved directly (no `List.range` detour).

HONEST SCOPE. One substrate identity about finite sums of embedded rationals — no analysis, no
transform, no positivity, no crux.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.ComplexDigamma
import Multiplicity.F1Square.Analysis.RealPow

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- The rational partial sum mirroring `genSum` term-for-term. -/
def qGenSum (g : Nat → Q) : Nat → Q
  | 0 => (⟨0, 1⟩ : Q)
  | (N + 1) => add (qGenSum g N) (g N)

/-- `qGenSum` has positive denominators when its summands do. -/
theorem qGenSum_den (g : Nat → Q) (hg : ∀ i, 0 < (g i).den) : ∀ N, 0 < (qGenSum g N).den
  | 0 => Nat.one_pos
  | (N + 1) => add_den_pos (qGenSum_den g hg N) (hg N)

/-- **`genSum` of embedded rationals is the embedded rational partial sum.** -/
theorem genSum_ofQ (g : Nat → Q) (hg : ∀ i, 0 < (g i).den) (N : Nat) :
    Req (genSum (fun i => ofQ (g i) (hg i)) N) (ofQ (qGenSum g N) (qGenSum_den g hg N)) := by
  induction N with
  | zero => exact Req_of_seq_Qeq (fun _ => Qeq_refl _)
  | succ N ih =>
    refine Req_trans (Radd_congr ih (Req_refl _)) ?_
    exact Radd_ofQ_ofQ (qGenSum_den g hg N) (hg N)

end Multiplicity.UOR.Bridge.F1Square.Analysis
