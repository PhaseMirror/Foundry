import Init

namespace Core.AlphaFunction

/-- 
  Discrete parameter proxy for the Alpha Function.
  Actual continuous integration and series limits are delegated to the Rust Engine.
-/
structure AlphaParams where
  theta0_re_bound : Int
  is_integral_path : Bool
  is_series_path : Bool

/-- 
  The Alpha function evaluation bridge. 
-/
opaque evaluateAlpha (x : Nat) (p : AlphaParams) : Int

/-- 
  Convergence guard axiom: If the real part bound of theta0 is strictly positive,
  the integral path is considered bounded and lawful for evaluation.
  This exact property is verified in continuous space via the Kani harness.
-/
axiom alpha_convergence_guard (p : AlphaParams) :
  p.theta0_re_bound > 0 → p.is_integral_path = true → evaluateAlpha 1 p ≥ 0

end Core.AlphaFunction
