import ADR.Core

/-!
# Export ADRs to Markdown and HTML
-/

open ADR

namespace ADR.Export

/-- String representation of ADRStatus. -/
def adrStatusToString : ADRStatus → String
  | ADRStatus.Proposed => "Proposed"
  | ADRStatus.Accepted => "Accepted"
  | ADRStatus.Deprecated => "Deprecated"
  | ADRStatus.Superseded => "Superseded"

/-- String representation of RiskLevel. -/
def riskLevelToString : RiskLevel → String
  | RiskLevel.Critical => "Critical"
  | RiskLevel.High => "High"
  | RiskLevel.Medium => "Medium"
  | RiskLevel.Low => "Low"

def renderMarkdown (a : ADR) : String :=
  "## ADR " ++ (toString a.id.value) ++ ": " ++ a.title ++ "\n\n" ++
  "**Status**: " ++ (adrStatusToString a.status) ++ "\n" ++
  "**Context**\n" ++ a.context ++ "\n" ++
  "**Decision**\n" ++ a.decision ++ "\n" ++
  "**Consequences**\n" ++ (String.intercalate "\n- " a.consequences) ++ "\n" ++
  "**Risk Level**: " ++ (riskLevelToString a.riskLevel) ++ "\n" ++
  "**Links**\n" ++ (String.intercalate "\n- " (a.links.map (fun l => "[" ++ l.description ++ "](" ++ l.uri ++ ")"))) ++ "\n"

end ADR.Export