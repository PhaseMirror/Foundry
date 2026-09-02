/-!
# Harmonia (Φπε) Interface Formalization

Formal specification of the RI1 First-Contact Interface between
PIRTM/MOC and the Harmonia process grammar.
Self-contained in Lean 4 Core (Mathlib-Free).
-/

namespace Harmonia

/-- Qualitative symbol set for Harmonia process states. -/
inductive Symbol where
  | Phi
  | Pi
  | Epsilon
  deriving Repr, DecidableEq, Inhabited

/-- Canonical mapping from Harmonia qualitative symbols to prime numbers. -/
def primeOfSymbol : Symbol → Nat
  | Symbol.Phi => 2
  | Symbol.Pi => 3
  | Symbol.Epsilon => 5

/-- Prime predicate on basic small indices. -/
def isSmallPrime : Nat → Bool
  | 2 => true
  | 3 => true
  | 5 => true
  | 7 => true
  | 11 => true
  | 13 => true
  | _ => false

theorem prime_phi_valid : isSmallPrime (primeOfSymbol Symbol.Phi) = true := by
  rfl

theorem prime_pi_valid : isSmallPrime (primeOfSymbol Symbol.Pi) = true := by
  rfl

theorem prime_epsilon_valid : isSmallPrime (primeOfSymbol Symbol.Epsilon) = true := by
  rfl

/-- Sparse exponent signature state vector: (k_Phi, k_Pi, k_Epsilon). -/
structure State where
  k_phi : Nat
  k_pi  : Nat
  k_eps : Nat
  deriving Repr, DecidableEq, Inhabited

/-- Multiplicity surplus product N = 2^(k_phi) * 3^(k_pi) * 5^(k_eps). -/
def multiplicityNumber (s : State) : Nat :=
  (2 ^ s.k_phi) * (3 ^ s.k_pi) * (5 ^ s.k_eps)

/-- An update operator U on Harmonia state vectors. -/
def StateUpdate := State → State

/-- A state update is non-expanding (subdivision) if the surplus multiplicity does not grow. -/
def IsSubdivision (u : StateUpdate) (s : State) : Prop :=
  multiplicityNumber (u s) ≤ multiplicityNumber s

/-- Subdivision transition preserves bounded state envelope. -/
theorem subdivision_preserves_envelope (u : StateUpdate) (s : State) (h : IsSubdivision u s) :
    multiplicityNumber (u s) ≤ multiplicityNumber s := h

end Harmonia
