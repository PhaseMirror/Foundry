namespace ZMOD

/-- Scale: 10000 = 1.0 -/
def scale : Nat := 10000

/-- 
  Interaction of prime p with gradient at step t.
  Mapped to Nat domain: returns `scale` (1.0) if grad is divisible by p, else 0.
-/
def step_interaction (grad : Nat) (p : Nat) : Nat :=
  if p > 0 ∧ grad % p == 0 then scale else 0

/-- Accumulation of interactions over a list of gradients. -/
def multiplicityTensor (grads : List Nat) (p : Nat) : Nat :=
  match grads with
  | [] => 0
  | g :: gs => step_interaction g p + multiplicityTensor gs p

end ZMOD
