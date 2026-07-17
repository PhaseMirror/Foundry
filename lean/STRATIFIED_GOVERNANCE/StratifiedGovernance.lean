/-!
# Stratified Governance
Formalized stratified resource allocation and authority system.
-/

namespace StratifiedGovernance

inductive Stratum
  | S0  -- Unverified / experimental
  | S2  -- Light verification
  | S4  -- Standard production
  | S6  -- Full Triple-Lock verification
  deriving Repr, DecidableEq

def Stratum.toNat : Stratum → Nat
  | Stratum.S0 => 0
  | Stratum.S2 => 2
  | Stratum.S4 => 4
  | Stratum.S6 => 6

instance : LT Stratum where
  lt a b := a.toNat < b.toNat

instance : LE Stratum where
  le a b := a.toNat ≤ b.toNat

instance (a b : Stratum) : Decidable (a < b) :=
  inferInstanceAs (Decidable (a.toNat < b.toNat))

instance (a b : Stratum) : Decidable (a ≤ b) :=
  inferInstanceAs (Decidable (a.toNat ≤ b.toNat))

def Stratum.next : Stratum → Option Stratum
  | Stratum.S0 => some Stratum.S2
  | Stratum.S2 => some Stratum.S4
  | Stratum.S4 => some Stratum.S6
  | Stratum.S6 => none

inductive ValidStratumTransition : Stratum → Stratum → Prop
  | step {s₁ s₂ : Stratum} (h : Stratum.next s₁ = some s₂) : ValidStratumTransition s₁ s₂

theorem stratum_monotonicity (s₁ s₂ : Stratum)
  (h : ValidStratumTransition s₁ s₂) :
  s₁ < s₂ := by
  cases h; rename_i h_next
  cases s₁ <;> cases s₂ <;> revert h_next <;> decide

structure ResourceBudget where
  max_compute_cycles : Nat
  max_memory_bytes : Nat
  max_latency_ns : Nat
  deriving Repr

def budgetForStratum : Stratum → ResourceBudget
  | Stratum.S0 => { max_compute_cycles := 1000, max_memory_bytes := 1024, max_latency_ns := 500000 }
  | Stratum.S2 => { max_compute_cycles := 10000, max_memory_bytes := 8192, max_latency_ns := 5000000 }
  | Stratum.S4 => { max_compute_cycles := 100000, max_memory_bytes := 65536, max_latency_ns := 50000000 }
  | Stratum.S6 => { max_compute_cycles := 1000000, max_memory_bytes := 524288, max_latency_ns := 500000000 }

structure ActionConsumption where
  cycles : Nat
  memory : Nat
  latency : Nat

def respectsBudget (c : ActionConsumption) (b : ResourceBudget) : Prop :=
  c.cycles ≤ b.max_compute_cycles ∧ 
  c.memory ≤ b.max_memory_bytes ∧ 
  c.latency ≤ b.max_latency_ns

theorem resource_budget_monotonic (s₁ s₂ : Stratum) (c : ActionConsumption)
  (h_le : s₁ ≤ s₂)
  (h_respects : respectsBudget c (budgetForStratum s₁)) :
  respectsBudget c (budgetForStratum s₂) := by
  change s₁.toNat ≤ s₂.toNat at h_le
  rcases h_respects with ⟨h1, h2, h3⟩
  revert h1 h2 h3 h_le
  cases s₁ <;> cases s₂ <;> 
  simp [budgetForStratum, Stratum.toNat, respectsBudget] <;>
  intro h1 h2 h3 <;> exact ⟨by omega, by omega, by omega⟩

end StratifiedGovernance
