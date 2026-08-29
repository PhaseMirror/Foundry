import Foundations.ADR.Core
import Foundations.ADR.Examples
import Foundations.ADR.GlobalResearchPlatform

/-!
# Architecture Decision Records (ADR) — Export Generator

This module implements executable generators converting verified Lean 4 ADR records
into human-readable Markdown specifications and HTML documents. It enables automated
documentation site generation from the machine-checked formal governance model.
-/

namespace Foundations.ADR.Export

open Foundations.ADR
open Foundations.ADR.GlobalResearchPlatform

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
  for adr in reg.adrs do
    let mdPath := targetDir / s!"{adr.id}.md"
    let htmlPath := targetDir / s!"{adr.id}.html"
    IO.FS.writeFile mdPath (adrToMarkdown adr)
    IO.FS.writeFile htmlPath (adrToHTML adr)
  IO.println s!"[ADR Export] Successfully exported {reg.adrs.length} ADRs to {targetDir}"

/-! ## ADR-0035 Global Research Platform Governance Report -/

/-- Membrane posture derived from the global Layer B state. Mirrors `membraneState`
but operates over the raw `Option LayerBIdentity` so it can be rendered without first
constructing a `KnownLayerB` witness. -/
def grpPosture (globalLayerB : Option LayerBIdentity) : String :=
  match globalLayerB with
  | none => "FailClosed (no Layer B present)"
  | some b =>
    if b.tag == requiredLayerBTag && b.recordedInContract
    then "Operational"
    else "FailClosed (Layer B present but not contract-recorded as v1.0.0-Stable)"

/-- Render the ADR-0035 Global Research Platform governance report: membrane posture,
Layer-B gate status, and the verified ADR slice. The report is timestamp-free so that
exported bytes are deterministic across runs (CI gate `git diff --exit-code`). -/
def grpGovernanceReport (globalLayerB : Option LayerBIdentity) (reg : ADRRegistry) : String :=
  let gateStr := match globalLayerB with
    | none => "ABSENT — all certification and minting paths fail-closed"
    | some b =>
      if b.tag == requiredLayerBTag && b.recordedInContract
      then s!"OPEN ({b.tag} / treeSHA {b.treeSHA})"
      else "PRESENT-BUT-INVALID — fail-closed"
  s!"# ADR-0035 Global Research Platform — Governance Report

**Status:** Accepted (blocked on Layer B)
**Membrane posture:** {grpPosture globalLayerB}
**Layer-B gate:** {gateStr}

> The MSC-Cert v1 schema is a frozen, non-minting target format. Per ADR-0035, no
> verification service may accept it, no oracle may sign under it, and no token
> (ERC-721, W3C credential, or Archivum entry) may be issued that references it while
> the gate is closed.

## Verified ADR Slice
{registryIndexMarkdown reg}
"

/-- Export the ADR-0035 governance report and the verified GRP ADR slice to `targetDir`. -/
def exportGRP (globalLayerB : Option LayerBIdentity) (reg : ADRRegistry) (targetDir : System.FilePath) : IO Unit := do
  IO.FS.createDirAll targetDir
  IO.FS.writeFile (targetDir / "ADR-0035-GOVERNANCE.md") (grpGovernanceReport globalLayerB reg)
  for adr in reg.adrs do
    IO.FS.writeFile (targetDir / s!"{adr.id}.md") (adrToMarkdown adr)
  IO.println s!"[GRP Export] Successfully exported governance report + {reg.adrs.length} ADRs to {targetDir}"

end Foundations.ADR.Export
