-- Foundations/Basic.lean
-- Core definitions for Multiplicity Theory

namespace Multiplicity

/-- A multiplicity value quantifies the density of connections of a node -/
def MultiplicityVal := Nat

/-- A node in the directed graph -/
structure Node where
  id : Nat
  multiplicity : MultiplicityVal

instance : DecidableEq Node := by decide

instance : DecidableEq Edge := by decide

/-- A directed graph with multiplicity values -/
structure MultiplicityGraph where
  nodes : List Node
  edges : List Edge
  -- Every node referenced in an edge must exist in nodes
  edges_valid : ∀ e ∈ edges, e.source ∈ nodes ∧ e.target ∈ nodes

/-- The degree of a node (number of outgoing edges) -/
def degree (g : MultiplicityGraph) (n : Node) : Nat :=
  (List.filter (fun (e : Edge) => decide (e.source = n)) g.edges).length

/-- A node is a sink if it has no outgoing edges -/
def isSink (g : MultiplicityGraph) (n : Node) : Prop :=
  degree g n = 0

/-- A node is a source if it has no incoming edges -/
def isSource (g : MultiplicityGraph) (n : Node) : Prop :=
  (List.filter (fun (e : Edge) => decide (e.target = n)) g.edges).length = 0

end Multiplicity
