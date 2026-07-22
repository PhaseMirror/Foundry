import Core.universal_closure.UniversalClosure

/-!
# Example: Quantum Gates as a Universal Closure Instance

Quantum gates with composition (sequential application) and
closure (adjoint/inverse) form a UC instance.
-/

namespace Examples.QuantumGate

/-- Quantum gate types. -/
inductive GateType where
  | Identity
  | PauliX
  | PauliY
  | PauliZ
  | Hadamard
  | CNot
  | Rx (theta : Float)
  | Ry (theta : Float)
  | Rz (theta : Float)

/-- Quantum gate composition (sequential application). -/
def composeGates : GateType → GateType → GateType
  | GateType.Identity, g => g
  | g, GateType.Identity => g
  | GateType.PauliX, GateType.PauliX => GateType.Identity
  | GateType.PauliY, GateType.PauliY => GateType.Identity
  | GateType.PauliZ, GateType.PauliZ => GateType.Identity
  | GateType.Hadamard, GateType.Hadamard => GateType.Identity
  | g₁, g₂ => GateType.CNot  -- Simplified: arbitrary composition yields CNot

/-- Quantum gate closure (adjoint/inverse). -/
def closeGate : GateType → GateType
  | GateType.Identity => GateType.Identity
  | GateType.PauliX => GateType.PauliX
  | GateType.PauliY => GateType.PauliY
  | GateType.PauliZ => GateType.PauliZ
  | GateType.Hadamard => GateType.Hadamard
  | GateType.CNot => GateType.CNot
  | GateType.Rx θ => GateType.Rx (-θ)
  | GateType.Ry θ => GateType.Ry (-θ)
  | GateType.Rz θ => GateType.Rz (-θ)

/-- Quantum gates as a UC system. -/
def QuantumGateUC : UC GateType :=
  { compose := composeGates
    closure := closeGate }

/-- Hadamard is self-inverse. -/
theorem hadamard_self_inverse : composeGates GateType.Hadamard GateType.Hadamard = GateType.Identity := by
  rfl

/-- Identity is neutral. -/
theorem identity_neutral_left : ∀ (g : GateType), composeGates GateType.Identity g = g := by
  intro g
  rfl

end Examples.QuantumGate
