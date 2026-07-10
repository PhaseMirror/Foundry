namespace PARM

/-- Computes the sealed state V_N for a sequence of primes (or arbitrary natural numbers). -/
def sealed_state_loop (v : Nat) : List Nat → Nat
  | [] => v
  | [last] => (last * last) * (v + last)
  | p :: ps => sealed_state_loop (p * (v + p)) ps

def sealed_state (primes : List Nat) : Nat :=
  match primes with
  | [] => 0
  | [p] => p * p
  | p :: ps => sealed_state_loop (p * p) ps

end PARM
