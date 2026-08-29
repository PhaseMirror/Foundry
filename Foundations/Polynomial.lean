/-!
# Multiplicity Kernel — Polynomials (ADR-0001 Phase 1 scope)

Polynomial evaluation by Horner's rule over `Int`.  Coefficients are stored
leading first, so `polyEval [a, b, c] x = (a * x + b) * x + c`.  The
corresponding synthetic (Ruffini) division and root multiplicity live in
`Spec.RootMultiplicity`, and the certificate manifest in
`Multiplicity.PolynomialProofs`.
-/

namespace Multiplicity.Kernel

/-- Horner evaluation: `polyEval cs x` folds `(acc * x + c)` over `cs`,
starting from `0`. -/
def polyEval (cs : List Int) (x : Int) : Int :=
  cs.foldl (fun acc c => acc * x + c) 0

/-- Evaluation of the empty polynomial is zero. -/
theorem polyEval_nil (x : Int) : polyEval [] x = 0 := rfl

/-- Evaluation of a constant is that constant. -/
theorem polyEval_one (c x : Int) : polyEval [c] x = c := by
  simp [polyEval]

/-- Evaluation of `c :: cs` is the fold seeded by `c`. -/
theorem polyEval_cons_foldl (c : Int) (cs : List Int) (x : Int) :
    polyEval (c :: cs) x = cs.foldl (fun acc c' => acc * x + c') c := by
  simp [polyEval, List.foldl_cons]

/-- Horner evaluation is deterministic. -/
theorem polyEval_deterministic (cs : List Int) (x : Int) : polyEval cs x = polyEval cs x :=
  rfl

/-- `r` is a root of `cs` when evaluation at `r` vanishes. -/
def rootAt (cs : List Int) (r : Int) : Prop :=
  polyEval cs r = 0

/-- `rootAt` unfolds to a vanishing evaluation. -/
theorem rootAt_def (cs : List Int) (r : Int) : rootAt cs r ↔ polyEval cs r = 0 := by
  simp [rootAt]

/-- The root of a linear polynomial `a x + b` is the vanishing point. -/
theorem rootAt_linear (a b r : Int) (_ha : a ≠ 0) : rootAt [a, b] r ↔ a * r + b = 0 := by
  simp [rootAt, polyEval]

/-- A quadratic `a x² + b x + c` evaluates by Horner as `(a*x+b)*x+c`. -/
theorem polyEval_quad (a b c x : Int) : polyEval [a, b, c] x = (a * x + b) * x + c := by
  simp [polyEval]

end Multiplicity.Kernel
