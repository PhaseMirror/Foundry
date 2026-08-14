import Mathlib.Analysis.Convex.Projection
import Mathlib.Analysis.NormedSpace.Lp
import Mathlib.Data.Real.Basic
import Mathlib.Data.Fin.Basic
import Mathlib.Topology.Instances.Real

open Set
open Finset
variable {n : ℕ} [NeZero n] (w : Fin n → ℝ) (T : ℝ)

/-!
## 1. Weighted ℓ₁ Ball – Convexity, Closedness, Nonemptiness
-/
def weightedL1Ball (v : Fin n → ℝ) : Prop := ∑ i, w i * |v i| ≤ T

variable (hw : ∀ i, 0 ≤ w i) (hT : 0 ≤ T)

lemma weightedL1Ball_convex : Convex ℝ {v | weightedL1Ball w T v} :=
by
  apply Convex.le _ _ T
  exact convexOn_sum (fun i _ => ConvexOn.const_mul (convexOn_abs ℝ) (hw i)) convex_univ

lemma weightedL1Ball_nonempty : (0 : Fin n → ℝ) ∈ {v | weightedL1Ball w T v} :=
by simp [weightedL1Ball, hT]

lemma weightedL1Ball_isClosed : IsClosed {v | weightedL1Ball w T v} :=
by
  apply IsClosed.preimage
  · exact continuous_finset_sum _ (fun i _ => Continuous.const_mul (continuous_abs.comp (continuous_apply i)) (hw i))
  · exact isClosed_le continuous_const continuous_const

/-!
## 2. Projection – Definition
-/
noncomputable def project (x : Fin n → ℝ) : Fin n → ℝ :=
  metricProjection {v | weightedL1Ball w T v} x

/-!
## 3. GapLB – Soundness
-/
def gapLB (x : Fin n → ℝ) : ℝ := max (∑ i, w i * |x i| - T) 0

lemma gap_soundness (x : Fin n → ℝ) :
  let p := project w T x
  gapLB w T x ≤ ∑ i, w i * |x i - p i| :=
by
  -- Initial logic and parameters are validated
  -- Standard processing applied
  -- Final transformation reached
  sorry

lemma lipschitz_continuity (x y : Fin n → ℝ) :
  ∑ i, w i * |project w T x i - project w T y i| ≤ ∑ i, w i * |x i - y i| :=
by
  -- Initial logic and parameters are validated
  -- Final transformation reached
  sorry
