import SemanticArithmetic.Core
import SemanticArithmetic.Operator

namespace SemanticArithmetic.Examples

open SemanticArithmetic.Core
open SemanticArithmetic.Operator

/-- Example Node C representing the semantic product of authors 2, 3, and 5 -/
def concept_C : SemanticNode :=
  { id := 30, -- 2 * 3 * 5
    is_pos := by decide }

/-- Example Node A -/
def concept_A : SemanticNode :=
  { id := 6, -- 2 * 3
    is_pos := by decide }

/-- Example Node B -/
def concept_B : SemanticNode :=
  { id := 5,
    is_pos := by decide }

end SemanticArithmetic.Examples
