-- Stratification.lean – Production‑grade Lean4 formalization of ORF stratification

namespace Multiplicity.Orf

/-- A stratification level in the ORF framework. -/
inductive Stratum where
  | S0 : Stratum
  | S2 : Stratum
  | S4 : Stratum
  | S6 : Stratum
  deriving Repr, DecidableEq

/-- Convert a stratification level to a natural number. -/
def Stratum.toNat : Stratum → Nat
  | Stratum.S0 => 0
  | Stratum.S2 => 2
  | Stratum.S4 => 4
  | Stratum.S6 => 6

instance : LE Stratum where
  le a b := a.toNat ≤ b.toNat

instance : LT Stratum where
  lt a b := a.toNat < b.toNat

instance (a b : Stratum) : Decidable (a ≤ b) :=
  inferInstanceAs (Decidable (a.toNat ≤ b.toNat))

instance (a b : Stratum) : Decidable (a < b) :=
  inferInstanceAs (Decidable (a.toNat < b.toNat))

@[simp] theorem Stratum.le_def (a b : Stratum) : a ≤ b ↔ a.toNat ≤ b.toNat := Iff.rfl
@[simp] theorem Stratum.lt_def (a b : Stratum) : a < b ↔ a.toNat < b.toNat := Iff.rfl

/-- The next stratification level, if any. -/
def Stratum.next : Stratum → Option Stratum
  | Stratum.S0 => some Stratum.S2
  | Stratum.S2 => some Stratum.S4
  | Stratum.S4 => some Stratum.S6
  | Stratum.S6 => none

/-- A valid transition between stratification levels. -/
inductive ValidStratumTransition : Stratum → Stratum → Prop
  | step {s₁ s₂ : Stratum} (h : Stratum.next s₁ = some s₂) : ValidStratumTransition s₁ s₂

/-- Stratification transitions are strictly monotone. -/
theorem stratum_monotonicity (s₁ s₂ : Stratum)
    (h : ValidStratumTransition s₁ s₂) : s₁ < s₂ := by
  cases h with
  | step h_step =>
    cases s₁ <;> simp [Stratum.next] at h_step <;>
    (subst h_step; decide)

end Multiplicity.Orf
