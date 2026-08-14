import SemanticArithmetic.Core
import SemanticArithmetic.Operator
import SemanticArithmetic.Examples
import SemanticArithmetic.VerifyBasis

open SemanticArithmetic.Operator
open SemanticArithmetic.Examples

def main : IO Unit := do
  let trace_C := Xi_trace concept_C
  if trace_C == [2, 3, 5] then
    IO.println "Test Passed: Xi(t) successfully traced concept C to origins [2, 3, 5]."
  else
    IO.println s!"Test Failed: Trace mismatch. Got {trace_C}"
  
  let composed := compose_nodes concept_A concept_B
  if composed.id == concept_C.id then
    IO.println "Test Passed: Composition of A (6) and B (5) correctly yields C (30)."
  else
    IO.println "Test Failed: Composition mismatch."

  IO.println "\nRunning formal verification of Python basis (basis_factors.json)..."
  match ← load_and_verify "basis_factors.json" with
  | some data =>
    IO.println s!"✅ All {data.basis.length} entries verified against Xi_trace."
    IO.println "Semantic trace uniqueness holds for the entire numerical basis."
  | none =>
    IO.println "❌ Basis verification failed."
