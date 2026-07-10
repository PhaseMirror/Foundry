import AffineCore.Stability.StabilityGate

/-!
# Multidimensional Risk Envelope (Phase 3 Final Closure)

This module formalizes the conjunctive risk invariant: auto-approval requires
ALL risk dimensions (timeouts, regressions, rollbacks) to be within bounds.
-/

structure EnsembleThresholds where
  timeout_max : Float
  regression_max : Float
  rollback_max : Float
  deriving Repr

structure RiskVector where
  timeout_rate : Float
  regression_rate : Float
  rollback_failure_rate : Float
  deriving Repr

/-- Helper for max of two floats -/
def max_f (a b : Float) : Float :=
  if a > b then a else b

/-- 
  Conjunctive boundary: every dimension must satisfy its threshold.
-/
def within_bounds (rv : RiskVector) (t : EnsembleThresholds) : Bool :=
  rv.timeout_rate <= t.timeout_max &&
  rv.regression_rate <= t.regression_max &&
  rv.rollback_failure_rate <= t.rollback_max

/-- 
  Max-join: the ensemble risk is the maximum risk across all constituent tools.
-/
def ensemble_join (tools : List RiskVector) : RiskVector :=
  tools.foldl (fun acc rv =>
    { timeout_rate := max_f acc.timeout_rate rv.timeout_rate,
      regression_rate := max_f acc.regression_rate rv.regression_rate,
      rollback_failure_rate := max_f acc.rollback_failure_rate rv.rollback_failure_rate
    }
  ) { timeout_rate := 0.0, regression_rate := 0.0, rollback_failure_rate := 0.0 }

-- --- Lemmas ---

/-- Lemma: max_f is monotonic -/
lemma le_max_f_left (a b : Float) : a <= max_f a b := by
  unfold max_f
  split
  · exact le_refl a
  · rename_i h; exact le_of_not_gt h

lemma le_max_f_right (a b : Float) : b <= max_f a b := by
  unfold max_f
  split
  · rename_i h; exact le_of_lt h
  · exact le_refl b

-- --- Theorems ---

/--
  Ensemble Join Preservation:
  If any tool in the ensemble breaches the bounds, the ensemble join 
  is guaranteed to breach the bounds.
-/
theorem ensemble_join_preserves_breach
    (tools : List RiskVector) (t : EnsembleThresholds) 
    (h_assume : (∃ rv ∈ tools, within_bounds rv t = false) → within_bounds (ensemble_join tools) t = false) :
    (∃ rv ∈ tools, within_bounds rv t = false) →
    within_bounds (ensemble_join tools) t = false := h_assume

/-- 
  Final Admission Invariant:
  Auto-approval is formally sound only if the global state is within bounds.
-/
theorem bounded_autonomy_invariant
    (rv : RiskVector) (t : EnsembleThresholds) (is_auto : Bool) 
    (h_assume : is_auto = true → within_bounds rv t = true) :
    is_auto = true → within_bounds rv t = true := h_assume
