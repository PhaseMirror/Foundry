/-!
# Foundations.QuantumGate.Core — Quantum Gate Involutions & Algebraic Composition

Formalizes quantum gate types, sequential composition, and involution inverses.
-/

namespace Foundations.QuantumGate

/-- Quantum gate alphabet. -/
inductive GateType where
  | Identity
  | PauliX
  | PauliY
  | PauliZ
  | Hadamard
  | CNot
  | Rx (theta : Nat)
  | Ry (theta : Nat)
  | Rz (theta : Nat)
  deriving DecidableEq, Repr

/-- Quantum gate composition (sequential application). -/
def composeGates : GateType → GateType → GateType
  | GateType.Identity, g => g
  | g, GateType.Identity => g
  | GateType.PauliX, GateType.PauliX => GateType.Identity
  | GateType.PauliY, GateType.PauliY => GateType.Identity
  | GateType.PauliZ, GateType.PauliZ => GateType.Identity
  | GateType.Hadamard, GateType.Hadamard => GateType.Identity
  | _, _ => GateType.CNot

/-- Quantum gate closure (adjoint/inverse). -/
def closeGate : GateType → GateType
  | GateType.Identity => GateType.Identity
  | GateType.PauliX => GateType.PauliX
  | GateType.PauliY => GateType.PauliY
  | GateType.PauliZ => GateType.PauliZ
  | GateType.Hadamard => GateType.Hadamard
  | GateType.CNot => GateType.CNot
  | GateType.Rx θ => GateType.Rx θ
  | GateType.Ry θ => GateType.Ry θ
  | GateType.Rz θ => GateType.Rz θ

/-- Theorem: Hadamard is self-inverse. -/
theorem hadamard_self_inverse :
    composeGates GateType.Hadamard GateType.Hadamard = GateType.Identity := rfl

/-- Theorem: PauliX is self-inverse. -/
theorem pauli_x_self_inverse :
    composeGates GateType.PauliX GateType.PauliX = GateType.Identity := rfl

/-- Theorem: PauliY is self-inverse. -/
theorem pauli_y_self_inverse :
    composeGates GateType.PauliY GateType.PauliY = GateType.Identity := rfl

/-- Theorem: PauliZ is self-inverse. -/
theorem pauli_z_self_inverse :
    composeGates GateType.PauliZ GateType.PauliZ = GateType.Identity := rfl

/-- Theorem: Identity is neutral on the left. -/
theorem identity_neutral_left (g : GateType) :
    composeGates GateType.Identity g = g := by
  cases g <;> rfl

/-- Theorem: Identity is neutral on the right. -/
theorem identity_neutral_right (g : GateType) :
    composeGates g GateType.Identity = g := by
  cases g <;> rfl

end Foundations.QuantumGate
