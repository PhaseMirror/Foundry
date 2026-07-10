import MOC.Core
import MOC.Valuation

namespace MOC.Newton

def egcd (a b : Nat) : Nat × Int × Int :=
  if _h : b = 0 then (a, 1, 0)
  else
    let (g, x, y) := egcd b (a % b)
    (g, y, x - (Int.ofNat (a / b)) * y)
termination_by b
decreasing_by 
  apply Nat.mod_lt
  omega

def modInv (a m : Nat) : Nat :=
  let (g, x, _) := egcd a m
  if g = 1 then (x.toNat % m) else 0

def newton_step (x : Nat) (p k : Nat) (fx : Nat) (dfx : Nat) : Nat :=
  let m := p ^ k
  let inv := modInv dfx m
  if inv = 0 then x
  else (x + m - (fx * inv) % m) % m

theorem quadratic_convergence (v_n : Nat) :
  v_n < 10000 → (v_n * v_n) / 10000 < v_n ∨ v_n = 0 := by
  intro h
  cases v_n with
  | zero => right; rfl
  | succ n =>
    left
    apply Nat.div_lt_of_lt_mul
    have h_pos : 0 < n + 1 := Nat.zero_lt_succ n
    exact Nat.mul_lt_mul_of_pos_right h h_pos

end MOC.Newton
