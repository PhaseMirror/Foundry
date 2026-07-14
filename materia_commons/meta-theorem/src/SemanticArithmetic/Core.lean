namespace SemanticArithmetic.Core

/-- A semantic node mapped directly to an integer space -/
structure SemanticNode where
  id : Nat
  is_pos : id > 0
  deriving Repr, DecidableEq

/-- Prime property -/
def is_prime (n : Nat) : Prop := n > 1 ∧ ∀ m, m ∣ n → m = 1 ∨ m = n

/-- An atomic operator is a semantic node whose ID is a prime number -/
def AtomicOperator (n : SemanticNode) : Prop :=
  is_prime n.id

end SemanticArithmetic.Core
