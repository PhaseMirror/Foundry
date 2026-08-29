set_option autoImplicit false

/-!
# PedersenLemmas — Algebraic Foundations of Pedersen Commitments

Formalizes:
1. Hiding Match: A change in committed value v -> v' can be perfectly absorbed
   by an additive shift in the blinding scalar rho -> rho + (v - v') * h.
2. Collision Reduction: Any two distinct openings (v, rho) != (v', rho') for the
   same commitment yield the discrete logarithm relation:
   (v' - v) * h = rho - rho'.
-/

namespace ToyContractivity

/-- Generic discrete additive group commitment: C(rho, v, h) = rho + v * h. -/
def pedersen_eval (rho v h : Int) : Int :=
  rho + v * h

/-- Theorem (Hiding Match): For any commitment C(rho, v, h) and target value v',
    setting rho' = rho + (v - v') * h yields identical commitment valuation. -/
theorem hiding_match (rho v v' h : Int) :
    let rho' := rho + (v - v') * h
    pedersen_eval rho' v' h = pedersen_eval rho v h := by
  intro rho'
  dsimp [rho', pedersen_eval]
  have h1 : (v - v') * h = v * h - v' * h := Int.sub_mul v v' h
  rw [h1]
  omega

/-- Theorem (Collision Reduction): If two openings (rho, v) and (rho', v') yield
    the same commitment under generator multiplier h, then (v' - v) * h = rho - rho'. -/
theorem collision_gives_multiple (rho rho' v v' h : Int)
    (heq : pedersen_eval rho v h = pedersen_eval rho' v' h) :
    (v' - v) * h = rho - rho' := by
  dsimp [pedersen_eval] at heq
  have h1 : (v' - v) * h = v' * h - v * h := Int.sub_mul v' v h
  rw [h1]
  omega

end ToyContractivity
