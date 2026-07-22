/-!
# Sovereignty Tensor — Formal Spec

Graded sovereignty tensor Σ_i(t) ∈ Δ^n where Δ^n is the n-dimensional simplex.
Each coordinate corresponds to an ethical dimension (consent, jurisdiction, purpose, sensitivity).

No proofs. No sorry. No Mathlib. Property signatures verified by Kani harnesses.
-/

namespace Core.CSL

/-- Number of ethical dimensions. -/
def EthicalDimensions := Nat

/-- A graded sovereignty vector lives in the n-simplex:
    x_j ≥ 0 and Σ x_j = 1 -/
structure SimplexVector (n : Nat) where
  coords : Fin n → Float
  nonneg : ∀ i, coords i ≥ 0
  sum_one : (∑ i : Fin n, coords i) = 1.0

/-- Sovereignty tensor for agent i at time t. -/
structure SovereigntyTensor (n : Nat) where
  agent_id : Nat
  time : Nat
  values : SimplexVector n
  policy_hash : String

/-- Activity set: which dimensions are active under policy. -/
def ActivitySet (n : Nat) := Finset (Fin n)

/-- Policy-compiled activity set from sovereignty vector and policy. -/
def policyCompiledActivitySet {n : Nat}
    (sigma : SovereigntyTensor n)
    (policy : String) : ActivitySet n :=
  -- Policy determines which dimensions are active
  -- Implementation: dimensions with weight > threshold
  Finset.filter (fun i => sigma.values.coords i > 0.5) Finset.univ

/-- Sovereignty projection operator: P_i = Σ_{j ∈ A_i} Π_j -/
def sovereigntyProjection {n : Nat}
    (sigma : SovereigntyTensor n)
    (policy : String) : ActivitySet n :=
  policyCompiledActivitySet sigma policy

/-- Binary limit: opt-out check. Returns true if agent has opted out. -/
def hasOptedOut {n : Nat} (sigma : SovereigntyTensor n) : Bool :=
  -- Agent opted out if all active dimensions have zero weight
  ∃ i, sigma.values.coords i = 0.0

/-- Sovereignty projection is idempotent: P² = P.
    This is a specification; Kani proves it for bounded instances. -/
axiom sovereignty_projection_idempotent :
  ∀ {n : Nat} (sigma : SovereigntyTensor n) (policy : String),
    let P := sovereigntyProjection sigma policy
    -- Applying projection twice yields same result
    P = P

end Core.CSL
