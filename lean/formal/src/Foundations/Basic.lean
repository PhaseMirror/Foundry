-- Foundations/Basic.lean
-- Core definitions for Multiplicity Theory

namespace Multiplicity

/-- A multiplicity value quantifies the density of connections of a node -/
def MultiplicityVal := Nat

/-- A node in the directed graph -/
structure Node where
  id : Nat
  multiplicity : MultiplicityVal

/-- An edge between two nodes -/
structure Edge where
  source : Node
  target : Node
  weight : MultiplicityVal

/-- A directed graph with multiplicity values -/
structure MultiplicityGraph where
  nodes : List Node
  edges : List Edge
  -- Every node referenced in an edge must exist in nodes
  edges_valid : ∀ e ∈ edges, e.source ∈ nodes ∧ e.target ∈ nodes

/-- The degree of a node (number of outgoing edges) -/
def degree (g : MultiplicityGraph) (n : Node) : Nat :=
  g.edges.filter (fun e => e.source = n).length

/-- A node is a sink if it has no outgoing edges -/
def isSink (g : MultiplicityGraph) (n : Node) : Prop :=
  degree g n = 0

/-- A node is a source if it has no incoming edges -/
def isSource (g : MultiplicityGraph) (n : Node) : Prop :=
  g.edges.filter (fun e => e.target = n).length = 0

end Multiplicity
