/-
  Specifications/TensorSpec.lean
  Predicates for tensor network algorithms.
  Shared with Rust verification.
  No mathlib dependency.
-/

import Foundations.Basic
import Theorems.TensorNetworkTheorems

namespace Specifications.Tensor

-- ═══════════════════════════════════════════════════════════════
-- Valid Tensor
-- ═══════════════════════════════════════════════════════════════

def ValidTensor (dims : List Nat) (T : Theorems.TensorNetworks.Tensor dims) : Prop :=
  ∀ i, T i = T i  -- placeholder: all entries finite

-- ═══════════════════════════════════════════════════════════════
-- Valid Contraction
-- ═══════════════════════════════════════════════════════════════

def ValidContraction {d₁ d₂ : Nat}
    (T₁ : Theorems.TensorNetworks.Tensor [d₁, d₂])
    (T₂ : Theorems.TensorNetworks.Tensor [d₂, d₁])
    (result : Real) : Prop :=
  result = Theorems.TensorNetworks.contract T₁ T₂

-- ═══════════════════════════════════════════════════════════════
-- Valid Tensor Product
-- ═══════════════════════════════════════════════════════════════

def ValidTensorProduct {d₁ d₂ : Nat}
    (T₁ : Theorems.TensorNetworks.Tensor [d₁])
    (T₂ : Theorems.TensorNetworks.Tensor [d₂])
    (result : Theorems.TensorNetworks.Tensor [d₁ * d₂]) : Prop :=
  result = Theorems.TensorNetworks.tensorProduct T₁ T₂

-- ═══════════════════════════════════════════════════════════════
-- Multiplicity Encoding Specification
-- ═══════════════════════════════════════════════════════════════

def ValidMultiplicityEncoding
    (primes : List Nat) (exponents : List Nat) (result : Nat) : Prop =
  result = CulturalMath.multiplicityVal (primes.zip exponents)

-- ═══════════════════════════════════════════════════════════════
-- Postconditions for Rust verification
-- ═══════════════════════════════════════════════════════════════

def egyptian_mul_spec (a b result : Nat) : Prop :=
  result = a * b

def crt_spec (n₁ n₂ a₁ a₂ result : Nat) : Prop :=
  result % n₁ = a₁ % n₁ ∧ result % n₂ = a₂ % n₂

def pythagorean_gen_spec (m n a b c : Nat) : Prop :=
  m > n →
  CulturalMath.Pythagorean.euclidA m n = a ∧
  CulturalMath.Pythagorean.euclidB m n = b ∧
  CulturalMath.Pythagorean.euclidC m n = c

end Specifications.Tensor
