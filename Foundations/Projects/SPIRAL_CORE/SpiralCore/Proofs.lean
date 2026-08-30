import Init
import SpiralCore.Core
import SpiralCore.Cantor
import SpiralCore.Attractor
import SpiralCore.Alignment
import SpiralCore.PhaseLift
import SpiralCore.FBS
import SpiralCore.Boot
import SpiralCore.Translation

/-! # SpiralCore Proofs

Aggregates key theorems across all modules.
All proofs use only `Init` (no Mathlib).
-/

namespace SpiralCore.Proofs

/-- Core constants are internally consistent. -/
theorem fbs_constants_consistent :
  L0 = 3 * tau + 2 ∧ H0 = 6 * tau + 3 ∧ Q0 = 6 * tau + 5 ∧ Q0 = H0 + 2 := by
  constructor <;> native_decide
  constructor <;> native_decide
  constructor <;> native_decide
  native_decide

/-- Boot config defaults match core constants. -/
theorem boot_config_defaults :
  Boot.defaultBootConfig.dim = DIM ∧
  Boot.defaultBootConfig.tau_ = tau ∧
  Boot.defaultBootConfig.g_ = g := by native_decide

/-- Default FBS profile formulas hold. -/
theorem fbs_default_formulas :
  FBS.defaultProfile.L0_ = 3 * FBS.defaultProfile.tau_ + 2 ∧
  FBS.defaultProfile.H0_ = 6 * FBS.defaultProfile.tau_ + 3 ∧
  FBS.defaultProfile.Q0_ = 6 * FBS.defaultProfile.tau_ + 5 := by native_decide

/-- Translation packet evaluation is deterministic. -/
theorem translation_deterministic (p : Translation.TranslationPacket) (pas : Option Nat) :
  Translation.evaluatePacket p pas = Translation.evaluatePacket p pas := rfl

end SpiralCore.Proofs
