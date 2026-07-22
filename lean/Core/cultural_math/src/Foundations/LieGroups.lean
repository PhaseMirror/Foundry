/-
  Foundations/LieGroups.lean
  Lie groups and algebras, exponential map, generators.
  No mathlib dependency.
-/

import Foundations.Basic

namespace Foundations.LieGroups

-- ═══════════════════════════════════════════════════════════════
-- Matrix (finite-dimensional)
-- ═══════════════════════════════════════════════════════════════

def Matrix (n m : Nat) := Fin n → Fin m → Real

def matMul {n m k : Nat} (A : Matrix n m) (B : Matrix m k) : Matrix n k :=
  fun i j => ∑ p : Fin m, A i p * B p j

def matAdd {n m : Nat} (A B : Matrix n m) : Matrix n m :=
  fun i j => A i j + B i j

def matScale {n m : Nat} (c : Real) (A : Matrix n m) : Matrix n m :=
  fun i j => c * A i j

def matZero {n m : Nat} : Matrix n m :=
  fun _ _ => 0

def matId {n : Nat} : Matrix n n :=
  fun i j => if i = j then 1 else 0

-- ═══════════════════════════════════════════════════════════════
-- Lie Algebra
-- ═══════════════════════════════════════════════════════════════

def LieBracket {n : Nat} (A B : Matrix n n) : Matrix n n :=
  matMul A B - matMul B A

notation:100 "⁅" A ", " B "⁆" => LieBracket A B

def LieAlgebra (n : Nat) : Prop :=
  ∀ X Y Z : Matrix n n,
   ⁅X, Y⁆ + ⁅Y, Z⁆ + ⁅Z, X⁆ = matZero  -- Jacobi identity
    ∧ ∀ c : Real, ⁆matScale c X, Y⁆ = matScale c ⁆X, Y⁆

-- ═══════════════════════════════════════════════════════════════
-- Matrix Exponential
-- ═══════════════════════════════════════════════════════════════

def matPow {n : Nat} (A : Matrix n n) : Nat → Matrix n n
  | 0 => matId
  | k + 1 => matMul A (matPow A k)

def matFactorial : Nat → Nat
  | 0 => 1
  | k + 1 => (k + 1) * matFactorial k

def matExp {n : Nat} (A : Matrix n n) : Nat → Matrix n n
  | 0 => matId
  | k + 1 => matExp A k + matScale (1 / (matFactorial k : Real)) (matPow A k)

-- ═══════════════════════════════════════════════════════════════
-- Lie Group
-- ═══════════════════════════════════════════════════════════════

structure LieGroup (n : Nat) where
  mul : Matrix n n → Matrix n n → Matrix n n
  inv : Matrix n n → Matrix n n
  one : Matrix n n
  assoc : ∀ a b c, mul (mul a b) c = mul a (mul b c)
  one_mul : ∀ a, mul one a = a
  mul_one : ∀ a, mul a one = a
  mul_inv : ∀ a, mul a (inv a) = one
  inv_mul : ∀ a, mul (inv a) a = one

-- ═══════════════════════════════════════════════════════════════
-- Generators
-- ═══════════════════════════════════════════════════════════════

def Generates {n : Nat} (G : LieGroup n) (S : Fin k → Matrix n n) : Prop :=
  ∀ g : Matrix n n, ∃ params, g = G.mul (S 0) (S 1)

-- Adjoint representation
def Adjoint {n : Nat} (G : LieGroup n) (g : Matrix n n) (X : Matrix n n) : Matrix n n :=
  matMul g (matMul X (G.inv g))

end Foundations.LieGroups
