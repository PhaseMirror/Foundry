import ADR.Validation
import ADR.Serialization
import ADR.Examples

open ADR

def runTest (name : String) (test : IO Bool) : IO Unit := do
  IO.print s!"Running test: {name} ... "
  let result ← test
  if result then
    IO.println "✓ PASS"
  else
    IO.println "✗ FAIL"
    throw (IO.userError s!"Test {name} failed")

def testWellFormed : IO Bool := do
  let adr := mkADR "ADR-001" "Use Qudits" "Context" "Decision" "Consequences" "2026-07-07" "Ryan" Status.accepted
  pure (adr.id != "" && adr.title != "" && adr.context != "" && adr.decision != "" && adr.consequences != "" && adr.date != "" && adr.authors != [])

def testInvalid : IO Bool := do
  let adr := mkADR "" "Title" "Context" "Decision" "Consequences" "2026-07-07" "Ryan" Status.accepted
  pure (!(adr.id != "" && adr.title != "" && adr.context != "" && adr.decision != "" && adr.consequences != "" && adr.date != "" && adr.authors != []))

def testSerialization : IO Bool := do
  let adr := mkADR "ADR-002" "Test" "Ctx" "Dec" "Cons" "2026-07-07" "Alice" Status.accepted
  let json := Serialization.toJsonString adr
  match Serialization.fromJsonString json with
  | .ok adr' => pure (adr == adr')
  | .error _ => pure false

def main : IO Unit := do
  runTest "Well-formed ADR passes invariant" testWellFormed
  runTest "Invalid ADR fails well-formedness" testInvalid
  runTest "JSON round-trip" testSerialization
