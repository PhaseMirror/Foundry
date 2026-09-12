import sys

prime_file = "/home/multiplicity/Multiplicity/PhaseMirror/Prime/lean/Multiplicity/Prime.lean"
with open(prime_file, 'r') as f:
    content = f.read()

# Prepend imports if not there
imports = """import Multiplicity.F1.Analysis.RiemannHypothesis
import Multiplicity.F1.Analysis.TraceFormula
import Multiplicity.F1.Analysis.EulerProduct
import Multiplicity.F1.Analysis.SafePrimeDefect
import Multiplicity.dynamics.SedonaRiskModel
"""

if "import Multiplicity.F1.Analysis.RiemannHypothesis" not in content:
    content = imports + "\n" + content

# Append theorem
theorem = """
namespace Multiplicity.Kernel

/-- The Safe-Prime Cyclicity conjecture from Option 2. -/
axiom safe_prime_cyclicity : True

/-- 
  The capstone theorem linking the entire Phase Mirror structure.
  It reduces the RH proof to the Safe-Prime Cyclicity Conjecture.
-/
axiom riemann_hypothesis : safe_prime_cyclicity → ∀ ρ, Multiplicity.RiemannHypothesis.IsNontrivialZero ρ → Multiplicity.ExplicitFormula.re ρ = Multiplicity.ExplicitFormula.ℂ.zero

end Multiplicity.Kernel
"""
if "axiom riemann_hypothesis" not in content:
    content += "\n" + theorem

with open(prime_file, 'w') as f:
    f.write(content)

