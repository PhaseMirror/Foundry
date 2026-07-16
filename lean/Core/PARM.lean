// Core/PARM module – integration of PARM sealed state as a core primitive

namespace Core.PARM

/-- Computes the sealed state V_N for a sequence of primes (or arbitrary natural numbers). -/

def sealed_state_loop (v : Nat) : List Nat → Nat
  | [] => v
  | [last] => (last * last) * (v + last)
  | p :: ps => sealed_state_loop (p * (v + p)) ps

/-- Entry point for sealed state computation. -/

def sealed_state (primes : List Nat) : Nat :=
  match primes with
  | [] => 0
  | [p] => p * p
  | p :: ps => sealed_state_loop (p * p) ps

/-- Determinism: the function always returns the same value for the same input. -/
@[simp]
theorem sealed_state_deterministic (primes : List Nat) :
  sealed_state primes = sealed_state primes := by rfl

/-- Injectivity for single‑element lists: different inputs give different outputs. -/

theorem sealed_state_one_injective {p q : Nat} (h : p ≠ q) :
  sealed_state [p] ≠ sealed_state [q] := by
  intro h_eq
  have hmul : p * p = q * q := by
    simpa [sealed_state] using h_eq
  have : p = q := by
    exact (Nat.mul_self_eq_mul_self_iff.mp hmul)
  exact h this

/-- Example sealed‑state computation for the sequence [3, 3, 3, 2, 2]. -/

theorem sealed_state_108_cycle :
  sealed_state [3, 3, 3, 2, 2] = 960 := by
  native_decide

end Core.PARM
