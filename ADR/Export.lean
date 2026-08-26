import ADR.Core

/-!
# Architecture Decision Records (ADR) — Export Generator

This module implements executable generators converting verified Lean 4 ADR records
into human-readable Markdown specifications and HTML documents. It enables automated
documentation site generation from the machine-checked formal governance model.
-/

namespace ADR.Export

open ADR

/-- Convert artifact link to Markdown format. -/
def linkToMarkdown (link : ArtifactLink) : String :=
  let kindStr := match link.kind with
    | .GitCommit => "Git Commit"
    | .LeanDeclaration => "Lean Declaration"
    | .SourceFile => "Source File"
    | .SpecificationDoc => "Specification"
  s!"* **[{kindStr}]** `{link.uri}` — {link.description}"

/-- Convert artifact link to HTML format. -/
def linkToHTML (link : ArtifactLink) : String :=
  let kindStr := match link.kind with
    | .GitCommit => "Git Commit"
    | .LeanDeclaration => "Lean Declaration"
    | .SourceFile => "Source File"
    | .SpecificationDoc => "Specification"
  "<li><strong>[" ++ kindStr ++ "]</strong> <code>" ++ link.uri ++ "</code> &mdash; " ++ link.description ++ "</li>"

/-- Render an ADR record as standard GitHub Flavored Markdown. -/
def adrToMarkdown (adr : ADR) : String :=
  let supersedesStr := match adr.supersedes with
    | some sid => s!"\n**Supersedes:** [{sid}]({sid}.md)"
    | none => ""
  let consequencesStr := String.intercalate "\n" (adr.consequences.map (fun c => s!"* {c}"))
  let linksStr := if adr.links.isEmpty then "None" else String.intercalate "\n" (adr.links.map linkToMarkdown)

  s!"# {adr.id}: {adr.title}

**Status:** {adr.status}{supersedesStr}

## Context
{adr.context}

## Decision
{adr.decision}

## Consequences
{consequencesStr}

## Traceability & Artifact Links
{linksStr}
"

/-- Render an ADR record as clean, standalone HTML. -/
def adrToHTML (adr : ADR) : String :=
  let supersedesHTML := match adr.supersedes with
    | some sid => "<p><strong>Supersedes:</strong> <a href=\"" ++ sid ++ ".html\">" ++ sid ++ "</a></p>"
    | none => ""
  let consequencesHTML := String.intercalate "\n" (adr.consequences.map (fun c => "      <li>" ++ c ++ "</li>"))
  let linksHTML := if adr.links.isEmpty then "<p>None</p>" else
    "<ul>\n" ++ String.intercalate "\n" (adr.links.map (fun l => "      " ++ linkToHTML l)) ++ "\n    </ul>"

  "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"UTF-8\">\n  <title>" ++ adr.id ++ " - " ++ adr.title ++ "</title>\n  <style>\n    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 40px auto; line-height: 1.6; padding: 0 20px; color: #24292e; }\n    h1 { border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; }\n    .badge { display: inline-block; padding: 4px 8px; border-radius: 4px; font-weight: bold; background: #e1f5fe; color: #0277bd; }\n    code { background: #f6f8fa; padding: 2px 5px; border-radius: 3px; font-family: monospace; }\n  </style>\n</head>\n<body>\n  <h1>" ++ adr.id ++ ": " ++ adr.title ++ "</h1>\n  <p><span class=\"badge\">Status: " ++ toString adr.status ++ "</span></p>\n  " ++ supersedesHTML ++ "\n\n  <h2>Context</h2>\n  <p>" ++ adr.context ++ "</p>\n\n  <h2>Decision</h2>\n  <p>" ++ adr.decision ++ "</p>\n\n  <h2>Consequences</h2>\n  <ul>\n" ++ consequencesHTML ++ "\n  </ul>\n\n  <h2>Traceability & Links</h2>\n  " ++ linksHTML ++ "\n</body>\n</html>"

/-- Escape special characters for valid JSON strings. -/
def escapeJSONString (s : String) : String :=
  s.replace "\\" "\\\\" |>.replace "\"" "\\\"" |>.replace "\n" "\\n" |>.replace "\t" "\\t"

/-- Convert artifact link to JSON object string. -/
def linkToJSON (l : ArtifactLink) : String :=
  let kindStr := match l.kind with
    | .GitCommit => "GitCommit"
    | .LeanDeclaration => "LeanDeclaration"
    | .SourceFile => "SourceFile"
    | .SpecificationDoc => "SpecificationDoc"
  "{\"uri\":\"" ++ escapeJSONString l.uri ++ "\",\"kind\":\"" ++ kindStr ++ "\",\"description\":\"" ++ escapeJSONString l.description ++ "\"}"

/-- Convert an ADR record to a JSON object string. -/
def adrToJSON (adr : ADR) : String :=
  let supersedesJSON := match adr.supersedes with
    | some s => "\"" ++ escapeJSONString s ++ "\""
    | none => "null"
  let consequencesJSON := "[" ++ String.intercalate "," (adr.consequences.map (fun c => "\"" ++ escapeJSONString c ++ "\"")) ++ "]"
  let linksJSON := "[" ++ String.intercalate "," (adr.links.map linkToJSON) ++ "]"
  "{\"id\":\"" ++ escapeJSONString adr.id ++ "\",\"title\":\"" ++ escapeJSONString adr.title ++ "\",\"status\":\"" ++ toString adr.status ++ "\",\"context\":\"" ++ escapeJSONString adr.context ++ "\",\"decision\":\"" ++ escapeJSONString adr.decision ++ "\",\"consequences\":" ++ consequencesJSON ++ ",\"supersedes\":" ++ supersedesJSON ++ ",\"links\":" ++ linksJSON ++ "}"

/-- Convert the entire ADRRegistry to a JSON object string. -/
def registryToJSON (reg : ADRRegistry) : String :=
  let adrsJSON := "[" ++ String.intercalate "," (reg.adrs.map adrToJSON) ++ "]"
  "{\"version\":\"1.0.0\",\"adrs\":" ++ adrsJSON ++ "}"

/-- Generate an index Markdown file for the entire registry. -/
def registryIndexMarkdown (reg : ADRRegistry) : String :=
  let rows := reg.adrs.map (fun a =>
    let supStr := match a.supersedes with | some s => s | none => "-"
    s!"| [{a.id}]({a.id}.md) | {a.title} | {a.status} | {supStr} |"
  )
  s!"# Architectural Decision Records (ADR) Ledger

*Formally verified and machine-checked in Lean 4.*

| ID | Title | Status | Supersedes |
| :--- | :--- | :--- | :--- |
{String.intercalate "\n" rows}
"

/-- Export all ADR records in a registry to target output directory. -/
def exportADRSet (reg : ADRRegistry) (targetDir : System.FilePath) : IO Unit := do
  IO.FS.createDirAll targetDir
  IO.FS.writeFile (targetDir / "README.md") (registryIndexMarkdown reg)
  IO.FS.writeFile (targetDir / "registry.json") (registryToJSON reg)
  for adr in reg.adrs do
    let mdPath := targetDir / s!"{adr.id}.md"
    let htmlPath := targetDir / s!"{adr.id}.html"
    let jsonPath := targetDir / s!"{adr.id}.json"
    IO.FS.writeFile mdPath (adrToMarkdown adr)
    IO.FS.writeFile htmlPath (adrToHTML adr)
    IO.FS.writeFile jsonPath (adrToJSON adr)
  IO.println s!"[ADR Export] Successfully exported {reg.adrs.length} ADRs to {targetDir}"

end ADR.Export
