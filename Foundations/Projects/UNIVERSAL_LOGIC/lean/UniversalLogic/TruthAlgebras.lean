set_option autoImplicit false

/-!
# Truth-Value Algebras: Algebraic Properties & Involutions
-/

namespace UniversalLogic

-- 1. Classical Logic (Carrier Bool)
def classical_neg (x : Bool) : Bool := !x
def classical_conj (x y : Bool) : Bool := x && y
def classical_disj (x y : Bool) : Bool := x || y

theorem classical_double_neg (x : Bool) : classical_neg (classical_neg x) = x := by
  cases x <;> rfl

-- 2. Fuzzy MV-Algebra (Carrier [0, 1000] scaled integers)
def mv_neg (x : Nat) : Nat := 1000 - x.min 1000
def mv_conj (x y : Nat) : Nat :=
  let sum := x.min 1000 + y.min 1000
  if sum ≥ 1000 then sum - 1000 else 0
def mv_disj (x y : Nat) : Nat := (x.min 1000 + y.min 1000).min 1000

theorem mv_involution (x : Nat) (h : x ≤ 1000) : mv_neg (mv_neg x) = x := by
  dsimp [mv_neg]
  have h1 : x.min 1000 = x := Nat.min_eq_left h
  rw [h1]
  have h2 : 1000 - x ≤ 1000 := by omega
  have h3 : (1000 - x).min 1000 = 1000 - x := Nat.min_eq_left h2
  rw [h3]
  omega

-- 3. Fuzzy Gödel Logic (Carrier [0, 1000] scaled integers)
def godel_conj (x y : Nat) : Nat := x.min y
def godel_disj (x y : Nat) : Nat := x.max y

theorem godel_idempotent_conj (x : Nat) : godel_conj x x = x := by
  dsimp [godel_conj]
  exact Nat.min_self x

theorem godel_idempotent_disj (x : Nat) : godel_disj x x = x := by
  dsimp [godel_disj]
  exact Nat.max_self x

end UniversalLogic
