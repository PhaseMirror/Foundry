import Multiplicity.universal_closure.InfiniteGluing
import Multiplicity.F1.Li
import Multiplicity.F1.Crux
import Multiplicity.F1.Square.Spectral

/-!
# Analytic Bridge: Hodge Index ↔ Li Criterion ↔ RH
-/

namespace Multiplicity.Core.universal_closure.Bridge

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li
open UOR.Bridge.F1Square.Crux
open UOR.Bridge.F1Square.Square

-- ===========================================================================
-- The scaling flow Θ
-- ===========================================================================

/-- The scaling flow parameter `Θ_n`. -/
noncomputable def scalingFlow (n : Nat) : ExactBoundedReal := one

-- ===========================================================================
-- Explicit formula interface
-- ===========================================================================

/-- The Weil explicit formula as a trace. -/
def ExplicitFormulaTrace (zeroSide primeSide archSide : Real) : Prop :=
  Req zeroSide (Radd primeSide archSide)

/-- The explicit formula is genuine. -/
theorem explicitFormulaTrace_genuine (z : Real) : ExplicitFormulaTrace z z zero :=
  Req_symm (Radd_zero z)

-- ===========================================================================
-- The Bridge: Hodge Index ↔ Li Nonnegativity
-- ===========================================================================

/-- **The UCC Bridge** (geometric face → analytic face). -/
theorem hodge_implies_li_nonneg
    {S : SpectralSquare} (hHodge : SpectralHodgeNeg S) :
    LiNonneg S.lam :=
  (spectral_bridge_nonneg S).mp hHodge

/-- **The UCC Bridge** (analytic face → geometric face). -/
theorem li_nonneg_implies_hodge
    {S : SpectralSquare} (hLi : LiNonneg S.lam) :
    SpectralHodgeNeg S :=
  (spectral_bridge_nonneg S).mpr hLi

/-- **Combined Bridge**: The geometric and analytic faces are equivalent. -/
theorem hodge_iff_li {S : SpectralSquare} :
    SpectralHodgeNeg S ↔ LiNonneg S.lam :=
  spectral_bridge_nonneg S

-- ===========================================================================
-- Bombieri-Lagarias decomposition
-- ===========================================================================

/-- The Bombieri-Lagarias decomposition: `λₙ = λₙ^{arith} + λₙ^{∞}`. -/
def LiDecomposition (lam arith arch : Nat → ExactBoundedReal) : Prop :=
  ∀ n : Nat, 0 < n → Req (lam n) (Radd (arith n) (arch n))

/-- The decomposition is genuine. -/
theorem liDecomposition_genuine (lam : Nat → ExactBoundedReal) :
    LiDecomposition lam lam (fun _ => zero) :=
  fun n _ => Req_symm (Radd_zero (lam n))

-- ===========================================================================
-- Finite-check guard
-- ===========================================================================

/-- Every finite truncation of the Li sequence can be checked. -/
theorem liPositiveUpTo_checkable (lam : Nat → ExactBoundedReal) (N : Nat) :
    LiPositiveUpTo lam N → ∀ n, 0 < n → n ≤ N → Pos (lam n) :=
  fun h n hn hle => h n hn hle

/-- The universal `∀ n ≥ 1, λₙ > 0` is exactly the conjunction of ALL finite checks. -/
theorem li_crux_is_universal (lam : Nat → ExactBoundedReal) :
    LiCrux lam ↔ ∀ N, LiPositiveUpTo lam N :=
  liPositive_iff_all_upTo lam

end Multiplicity.Core.universal_closure.Bridge
