-- BRA.lean: Formalization of Bounded Recomputational Autonomy (BRA)

/-!
# Bounded Recomputational Autonomy (BRA)

This file formalizes the core algebraic definitions used in the BRA framework.
-/

namespace BRA

/-- Type of indices for internal generators. -/
variable (ι : Type*)
/-- Type of indices for external generators. -/
variable (κ : Type*)

/-- Length of a word (number of generators). -/
def wordLength (w : List (Sum ι κ)) : Nat := w.length

/-- Number of external generators in a word. -/
def externalCount (w : List (Sum ι κ)) : Nat :=
  w.foldl (fun acc s => match s with | Sum.inr _ => acc + 1 | _ => acc) 0

/-- Depth of nested commutators. -/
def commutatorDepth (w : List (Sum ι κ)) : Nat := w.length

/-- Weight parameters. -/
variable (α β : ℝ)

/-- Cost functional `C`. -/
def cost (w : List (Sum ι κ)) : ℝ :=
  (wordLength w : ℝ) + α * (commutatorDepth w : ℝ) + β * (externalCount w : ℝ)

/-- Metric `d` on geometry states. -/
variable {G : Type*} (dist : G → G → ℝ)

/-- Reconstruction kernel `Π`. -/
variable (Π : List (Sum ι κ) → G → G)

/-- BRA definition: minimal cost to reconstruct `Hₜ` from seed `H₀` within tolerance `ε`. -/
variable (ε : ℝ)

def BRA (H₀ Hₜ : G) : ℝ :=
  Inf {c | ∃ w, cost α β w = c ∧ dist (Π w H₀) Hₜ ≤ ε}

end BRA
