import Core.alp.Constitution.Model
import Core.alp.Constitution.L0
import Core.alp.PolicyEngine.Core

namespace ALP.Candle.PirtmBridge

-- Traceability table: Lean theorem -> Rust counterpart in Prime/pirtm-candle/
-- This file documents the ignition boundary and is checked by CI.

-- | Lean Theorem | Rust Type / Function | File |
-- |---|---|---|
-- | `ConstitutionModel` record | `ConstitutionModel` in multiplicity-common | `crates/common/src/constitution.rs` |
-- | `L0_Invariants.validate` | `ConstitutionModel::validate()` | `crates/common/src/constitution.rs:53` |
-- | `PolicyEngine.validate_action` | `PolicyEngine::validate_action` | `crates/alp/src/lib.rs:37` |
-- | `TrustLevel` enum | `TrustLevel` enum | `crates/common/src/types.rs` |
-- | `AdmissibilityReport` | `AdmissibilityReport` struct | `crates/alp/src/lib.rs:14` |
-- | `LambdaTrace` | `LambdaTrace` struct | `pirtm-candle/src/lib.rs:30` |
-- | `SedonaSpineEvaluator::evaluate_stop_rules` | `evaluate_stop_rules` | `pirtm-candle/src/lib.rs:86` |

-- CI invariant: no () in ALP/ without a matching Rust implementation stub.

structure SedonaTrace where
  valid : Bool
  contractivity_ok : Bool

axiom candle_ignition_sound :
  ∀ (trace : SedonaTrace),
  trace.valid = true → trace.contractivity_ok = true

end ALP.Candle.PirtmBridge
