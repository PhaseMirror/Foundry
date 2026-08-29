import moc.Ramanujan.Core

/-! # Ramanujan Multiplicity Theorems (ADR-233)

Formal theorems for the Ramanujan Multiplicity Project.
Every theorem is -- TODO: replace sorry-free.
-/

namespace MOC.Ramanujan

/-! ### Basic Properties -/

/-! d(1) = 1. -/
theorem divisor_of_one : divisorCount 1 = 1 := by
  unfold divisorCount multiplicityProfile
  simp

/-! τ(1) = 1. -/
theorem tau_one : tau 1 = 1 := by
  unfold tau
  simp

/-! p(0) = 1. -/
theorem partition_zero : partitionCount 0 = 1 := by
  unfold partitionCount
  simp

/-! tauPrimePower base cases. -/
theorem tau_prime_power_zero (p : Nat) : tauPrimePower p 0 = 1 := by
  unfold tauPrimePower
  simp

theorem tau_prime_power_one (p : Nat) : tauPrimePower p 1 = tauPrime p := by
  unfold tauPrimePower
  simp

/-! Computational checks for small values. -/
theorem divisor_count_2 : divisorCount 2 = 2 := by native_decide
theorem divisor_count_3 : divisorCount 3 = 2 := by native_decide
theorem divisor_count_4 : divisorCount 4 = 3 := by native_decide
theorem divisor_count_6 : divisorCount 6 = 4 := by native_decide

theorem tau_1 : tau 1 = 1 := by native_decide
theorem tau_2 : tau 2 = -24 := by native_decide
theorem tau_3 : tau 3 = 252 := by native_decide
theorem tau_4 : tau 4 = -1472 := by native_decide
theorem tau_6 : tau 6 = 6048 := by native_decide

theorem partition_1 : partitionCount 1 = 1 := by native_decide
theorem partition_2 : partitionCount 2 = 2 := by native_decide
theorem partition_3 : partitionCount 3 = 3 := by native_decide
theorem partition_4 : partitionCount 4 = 5 := by native_decide
theorem partition_5 : partitionCount 5 = 7 := by native_decide

end MOC.Ramanujan
