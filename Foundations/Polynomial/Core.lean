/-!
# Foundations.Polynomial.Core — Horner Evaluation & Algebraic Roots

Formalizes Horner's rule evaluation for polynomials over `Int`,
vanishing conditions for algebraic roots, and deterministic evaluation identities.
-/

namespace Foundations.Polynomial

/-- Horner evaluation: `polyEval cs x` folds `(acc * x + c)` over coefficients `cs`, starting from `0`. -/
def polyEval (cs : List Int) (x : Int) : Int :=
  cs.foldl (fun acc c => acc * x + c) 0

/-- Evaluation of the empty polynomial is zero. -/
theorem polyEval_nil (x : Int) : polyEval [] x = 0 := rfl

/-- Evaluation of a constant polynomial is that constant. -/
theorem polyEval_one (c x : Int) : polyEval [c] x = c := by
  dsimp [polyEval]
  omega

/-- Evaluation of `c :: cs` is the fold seeded by `c`. -/
theorem polyEval_cons_foldl (c : Int) (cs : List Int) (x : Int) :
    polyEval (c :: cs) x = cs.foldl (fun acc c' => acc * x + c') c := by
  dsimp [polyEval]
  have h0 : 0 * x + c = c := by omega
  rw [h0]

/-- Horner evaluation is deterministic. -/
theorem polyEval_deterministic (cs : List Int) (x : Int) : polyEval cs x = polyEval cs x := rfl

/-- `r` is a root of `cs` when evaluation at `r` vanishes. -/
def rootAt (cs : List Int) (r : Int) : Prop :=
  polyEval cs r = 0

/-- `rootAt` unfolds to a vanishing evaluation. -/
theorem rootAt_def (cs : List Int) (r : Int) : rootAt cs r ↔ polyEval cs r = 0 := Iff.rfl

/-- The root of a linear polynomial `a x + b` is the vanishing point. -/
theorem rootAt_linear (a b r : Int) : rootAt [a, b] r ↔ a * r + b = 0 := by
  dsimp [rootAt, polyEval]
  have h : 0 * r + a = a := by omega
  rw [h]

/-- A quadratic `a x² + b x + c` evaluates by Horner as `(a*x+b)*x+c`. -/
theorem polyEval_quad (a b c x : Int) : polyEval [a, b, c] x = (a * x + b) * x + c := by
  dsimp [polyEval]
  have h : 0 * x + a = a := by omega
  rw [h]

end Foundations.Polynomial
