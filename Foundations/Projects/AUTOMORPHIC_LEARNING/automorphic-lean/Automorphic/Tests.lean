import Automorphic

/-!
# Automorphic Learning: Test Harness
Examples and evaluations for the automorphic learning framework.
-/

namespace Automorphic.Tests

/-- Legendre symbol χ_7(3) = -1 (3 is a non-residue mod 7). -/
#eval legendreSymbol 3 7

/-- Legendre symbol χ_7(2) = 1 (2 is a residue mod 7: 3² ≡ 2 mod 7). -/
#eval legendreSymbol 2 7

/-- Example: AGL(1,7) element g(x) = 2x + 1 mod 7. -/
def exampleAgl : AglElement 7 :=
  ⟨⟨2, by omega⟩, ⟨1, by omega⟩, by omega⟩

theorem legendreSymbol_test : legendreSymbol 3 7 = -1 := rfl

end Automorphic.Tests
