import SemanticArithmetic.Core
import SemanticArithmetic.FTA

namespace SemanticArithmetic.Operator

open SemanticArithmetic.Core
open SemanticArithmetic.FTA

/-- The Context Operator Atlas: Xi(t)
    Extracts the verifiable authorship trace (prime factors) from any composite semantic node. -/
def Xi_trace (node : SemanticNode) : List Nat :=
  extract_factors node.id

/-- Composes two semantic nodes multiplicatively to form a unified concept -/
def compose_nodes (a b : SemanticNode) : SemanticNode :=
  { id := a.id * b.id,
    is_pos := Nat.mul_pos a.is_pos b.is_pos }

end SemanticArithmetic.Operator
