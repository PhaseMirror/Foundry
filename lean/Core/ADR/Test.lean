import ADR.Core
import ADR.Logics
import ADR.Proofs
import ADR.History
import ADR.Governance
import ADR.Examples
import ADR.Export
open ADR ADR.Logics ADR.Proofs ADR.History ADR.Governance ADR.Examples ADR.Export
namespace ADR.Test

/-! ## Basic Property Checks -/

theorem adr120_is_accepted : adr120.status = ADRStatus.Accepted := rfl

theorem export_markdown_ok : (exportMarkdown adr120).length > 0 := by decide

theorem export_html_ok : (exportHTML adr120).length > 0 := by decide

/-! ## Test Runner -/

def runTests : IO Unit := do
  IO.println "=== ADR Scaffold Tests ==="
  IO.println s!"adr120 status OK: {adr120.status}"
  IO.println s!"exportMarkdown length: {(exportMarkdown adr120).length}"
  IO.println s!"exportHTML length: {(exportHTML adr120).length}"
  IO.println "=== All tests compiled successfully ==="

end ADR.Test

def main : IO Unit := do
  ADR.Test.runTests
