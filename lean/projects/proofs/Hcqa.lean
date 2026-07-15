import Kernel

/-!
# Hcqa — causal-graph reachability (acyclicity primitives)

Formalizes the core invariant of the Hierarchical Causal QA graph: reachability is a
transitive reflexive-transitive closure, so causal influence composes. No `Mathlib`,
no `sorry`.
-/
namespace Hcqa

open proofs.Kernel

/-- A finite causal graph: successors of each node `i : Fin n`. -/
def Graph (n : Nat) := Fin n → List (Fin n)

/-- Reachability is the reflexive-transitive closure of the edge relation. -/
def reaches {n : Nat} (g : Graph n) : Fin n → Fin n → Prop :=
  Relation.reflTransGen (fun a b => b ∈ g a)

/-- An edge implies one-step reachability. -/
theorem reaches_edge {n : Nat} (g : Graph n) (a b : Fin n) (hb : b ∈ g a) :
    reaches g a b := Relation.reflTransGen.single hb

/-- Reachability is transitive (causal influence composes). -/
theorem reaches_trans {n : Nat} (g : Graph n) (a b c : Fin n) :
    reaches g a b → reaches g b c → reaches g a c := Relation.reflTransGen.trans

/-- A graph with no edges is acyclic: reachability coincides with equality. -/
theorem no_edge_only_eq {n : Nat} (g : Graph n) (a b : Fin n) (h : ∀ i, g i = []) :
    reaches g a b → a = b := by
  intro r
  cases r
  · rfl
  · simp [h] at r.head
    contradiction
