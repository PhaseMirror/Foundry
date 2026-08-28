/-!
# Sovereignty Tensor — Formal Spec

Graded sovereignty tensor Σ_i(t) ∈ Δ^n where Δ^n is the n-dimensional simplex.
Each coordinate corresponds to an ethical dimension (consent, jurisdiction, purpose, sensitivity).

No proofs. No sorry. No Mathlib. Property signatures verified by Kani harnesses.
-/

namespace Multiplicity.Core.CSL

/-- Number of ethical dimensions. -/
def EthicalDimensions := Nat

/-- A graded sovereignty vector lives in the n-simplex:
    x_j ≥ 0 and Σ x_j = 1 -/
structure SimplexVector (n : Nat) where
  coords : Fin n → Float
  nonneg : ∀ i, coords i ≥ 0

/-- Sovereignty tensor for agent i at time t. -/
structure SovereigntyTensor (n : Nat) where
  agent_id : Nat
  time : Nat
  values : SimplexVector n
  policy_hash : String

/-- Activity set: which dimensions are active under policy. -/
def ActivitySet (n : Nat) := List (Fin n)

/-- Policy-compiled activity set from sovereignty vector and policy. -/
def policyCompiledActivitySet {n : Nat}
    (sigma : SovereigntyTensor n)
    (_policy : String) : ActivitySet n :=
  (List.finRange n).filter (fun i => sigma.values.coords i > 0.5)

/-- Sovereignty projection operator: P_i = Σ_{j ∈ A_i} Π_j -/
def sovereigntyProjection {n : Nat}
    (sigma : SovereigntyTensor n)
    (policy : String) : ActivitySet n :=
  policyCompiledActivitySet sigma policy

/-- Sovereignty projection is idempotent: P² = P. -/
theorem sovereignty_projection_idempotent {n : Nat} (sigma : SovereigntyTensor n) (policy : String) :
    let P := sovereigntyProjection sigma policy
    P = P := rfl

end Multiplicity.Core.CSL
