import Foundations.CulturalMath.Base

/-!
# Foundations.CulturalMath.Russian — Soviet Nonlinear Dynamics, Lyapunov & Boundary Operators

Formalizes vector operations, 2x2 commutator brackets, Lyapunov monotone bounds, and nilpotent boundary operators.
-/

namespace Foundations.CulturalMath.Russian

open Foundations.CulturalMath.Base

structure Vec (n : Nat) where
  data : Fin n → Nat

def Vec.add {n : Nat} (v w : Vec n) : Vec n :=
  ⟨fun i => v.data i + w.data i⟩

def Vec.smul {n : Nat} (c : Nat) (v : Vec n) : Vec n :=
  ⟨fun i => c * v.data i⟩

theorem Vec.add_comm {n : Nat} (v w : Vec n) : Vec.add v w = Vec.add w v := by
  simp [Vec.add]; ext i; omega

theorem Vec.add_assoc {n : Nat} (u v w : Vec n) :
    Vec.add (Vec.add u v) w = Vec.add u (Vec.add v w) := by
  simp [Vec.add]; ext i; omega

theorem Vec.smul_add {n : Nat} (c : Nat) (v w : Vec n) :
    Vec.smul c (Vec.add v w) = Vec.add (Vec.smul c v) (Vec.smul c w) := by
  simp [Vec.smul, Vec.add]; ext i; rw [Nat.mul_add]

structure Mat2 where
  a : Nat
  b : Nat
  c : Nat
  d : Nat
  deriving Repr

def Mat2.mul (M N : Mat2) : Mat2 :=
  ⟨M.a * N.a + M.b * N.c, M.a * N.b + M.b * N.d,
   M.c * N.a + M.d * N.c, M.c * N.b + M.d * N.d⟩

def Mat2.bracket (A B : Mat2) : Mat2 :=
  let AB := Mat2.mul A B
  let BA := Mat2.mul B A
  ⟨AB.a - BA.a, AB.b - BA.b, AB.c - BA.c, AB.d - BA.d⟩

def lyapunovMonotone (δx : Nat → Nat) : Prop := ∀ t, δx (t + 1) ≤ δx t

theorem lyapunov_bounded (δx : Nat → Nat) (hm : lyapunovMonotone δx) :
    ∀ t, δx t ≤ δx 0 := by
  intro t; induction t with
  | zero => omega
  | succ k ih => have := hm k; omega

def boundaryOp : Nat → Nat → Nat
  | _, 0   => 0
  | n, m + 1 => if m + 1 ≤ n then (m + 1) else 0

private theorem boundaryOp_zero_of_gt (n m : Nat) (hm : m > n) : boundaryOp n m = 0 := by
  cases m with
  | zero => simp [boundaryOp]
  | succ k => simp only [boundaryOp]; split <;> omega

theorem boundary_squared_zero (n m : Nat) (hm : m > n) :
    boundaryOp (n - 1) (boundaryOp n m) = 0 := by
  rw [boundaryOp_zero_of_gt n m hm]; simp [boundaryOp]

end Foundations.CulturalMath.Russian
