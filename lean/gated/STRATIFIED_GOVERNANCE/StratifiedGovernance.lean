namespace StratifiedGovernance

inductive Stratum
  | S0
  | S2
  | S4
  | S6
  deriving Repr, DecidableEq

def Stratum.toNat : Stratum → Nat
  | S0 => 0
  | S2 => 2
  | S4 => 4
  | S6 => 6

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
  cases h with
  | step h_step =>
    cases s₁ <;> simp [Stratum.next] at h_step <;>
    (subst h_step; decide)

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

def actualConsumption (s : Stratum) : List ResourceBudget := [budgetForStratum s]

instance : LE ResourceBudget where
  le a b := a.max_compute_cycles ≤ b.max_compute_cycles ∧
            a.max_memory_bytes ≤ b.max_memory_bytes ∧
            a.max_latency_ns ≤ b.max_latency_ns

@[simp] theorem ResourceBudget.le_def (a b : ResourceBudget) :
  a ≤ b ↔ a.max_compute_cycles ≤ b.max_compute_cycles ∧
          a.max_memory_bytes ≤ b.max_memory_bytes ∧
          a.max_latency_ns ≤ b.max_latency_ns := Iff.rfl

theorem resource_budget_monotonic (s₁ s₂ : Stratum)
  (h : s₁ ≤ s₂) :
  ∀ b, b ∈ actualConsumption s₁ → b ≤ budgetForStratum s₂ := by
  intro b hb
  cases hb with
  | mem_cons head tail =>
    cases s₁ with
    | S0 =>
      cases s₂ with
      | S0 => simp [budgetForStratum] at h ⊢; exact h
      | S2 => simp [budgetForStratum]
      | S4 => simp [budgetForStratum]
      | S6 => simp [budgetForStratum]
    | S2 =>
      cases s₂ with
      | S0 => simp [budgetForStratum] at h
      | S2 => simp [budgetForStratum] at h ⊢; exact h
      | S4 => simp [budgetForStratum]
      | S6 => simp [budgetForStratum]
    | S4 =>
      cases s₂ with
      | S0 => simp [budgetForStratum] at h
      | S2 => simp [budgetForStratum] at h
      | S4 => simp [budgetForStratum] at h ⊢; exact h
      | S6 => simp [budgetForStratum]
    | S6 =>
      cases s₂ with
      | S0 => simp [budgetForStratum] at h
      | S2 => simp [budgetForStratum] at h
      | S4 => simp [budgetForStratum] at h
      | S6 => simp [budgetForStratum] at h ⊢; exact h

end StratifiedGovernance
