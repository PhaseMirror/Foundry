-- Minimal matrix library without Std.Finset

namespace Multiplicity.Core

open Nat

-- Helper sum over Fin n using List.finRange

def finSum {n : Nat} (f : Fin n → Nat) : Nat :=
  (List.finRange n).foldl (fun acc i => acc + f i) 0

/-- Matrix definition as function from two Fin indices to Nat -/

def Matrix (n : Nat) : Type := Fin n → Fin n → Nat

/-- Identity matrix -/
@[simp] def identity (n : Nat) : Matrix n :=
  fun i j => if i = j then 1 else 0

/-- Diagonal matrix -/
@[simp] def diag {n : Nat} (vals : Fin n → Nat) : Matrix n :=
  fun i j => if i = j then vals i else 0

/-- Matrix multiplication using finSum -/
@[simp] def mul {n : Nat} (A B : Matrix n) : Matrix n :=
  fun i j => finSum (fun k => A i k * B k j)

infix:70 " ⬝ " => mul

/-- Matrix exponentiation -/
@[simp] def matPow {n : Nat} (M : Matrix n) : Nat → Matrix n
  | 0 => identity n
  | k+1 => M ⬝ matPow M k

-- Theorems are omitted; they can be reinstated once a proper Finset library is available.

end Multiplicity.Core
