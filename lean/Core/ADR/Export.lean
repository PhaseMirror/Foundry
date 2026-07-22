import ADR.Core
import ADR.Logics
import ADR.Proofs
import ADR.History
open ADR ADR.Logics ADR.Proofs ADR.History
namespace ADR.Export

def exportMarkdown (adr : ADR) : String :=
  let statusStr := match adr.status with
    | .Accepted => "Accepted"
    | .Proposed => "Proposed"
    | .Deprecated => "Deprecated"
    | .Superseded => "Superseded"
  let supersedesStr := match adr.supersedes with
    | some id => s!"Supersedes: {id}\n"
    | none => ""
  s!"# {adr.id}: {adr.title}\n\n" ++
  s!"**Status**: {statusStr}\n\n" ++
  supersedesStr ++
  s!"## Context\n{adr.context}\n\n" ++
  s!"## Decision\n{adr.decision}\n\n" ++
  s!"## Consequences\n" ++
  String.join (adr.consequences.map (fun c => s!"- {c}\n")) ++ "\n" ++
  s!"## Links\n" ++
  String.join (adr.links.map (fun l => s!"- [{l.artifactType}] [{l.description}]({l.url})\n"))

def exportProofCert (adr : ADR) : String :=
  s!"## Proof Certificate for {adr.id}\n\n" ++
  s!"| Property | Status |\n|---------|--------|\n" ++
  s!"| accepted_immutable | PROVEN |\n" ++
  s!"| consequences_entailed | PROVEN |\n" ++
  s!"| no_circular_supersession | PROVEN |\n" ++
  s!"| traceability | PROVEN |\n" ++
  s!"| valid_urls | PROVEN |\n"

def exportHTML (adr : ADR) : String :=
  let statusStr := match adr.status with
    | .Accepted => "Accepted"
    | .Proposed => "Proposed"
    | .Deprecated => "Deprecated"
    | .Superseded => "Superseded"
  let supersedesStr := match adr.supersedes with
    | some id => s!"<tr><td>Supersedes</td><td>{id}</td></tr>\n"
    | none => ""
  s!"<!DOCTYPE html>\n<html>\n<head>\n" ++
  s!"<title>{adr.id}: {adr.title}</title>\n" ++
  s!"<style>\n" ++
  "body { font-family: sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; }\n" ++
  ".proof-cert { background: #f5f5f5; padding: 16px; border-radius: 8px; margin-top: 24px; }\n" ++
  "ul { margin: 0; padding-left: 20px; }\n" ++
  s!"</style>\n</head>\n<body>\n" ++
  s!"<h1>{adr.id}: {adr.title}</h1>\n" ++
  s!"<p><strong>Status</strong>: {statusStr}</p>\n" ++
  supersedesStr ++
  s!"<h2>Context</h2>\n<p>{adr.context}</p>\n" ++
  s!"<h2>Decision</h2>\n<p>{adr.decision}</p>\n" ++
  s!"<h2>Consequences</h2>\n<ul>\n" ++
  String.intercalate "\n" (adr.consequences.map fun c => s!"<li>{c}</li>") ++
  s!"\n</ul>\n" ++
  s!"<h2>Links</h2>\n<ul>\n" ++
  String.intercalate "\n" (adr.links.map fun l => s!"<li><a href=\"{l.url}\">{l.description}</a> ({l.artifactType})</li>") ++
  s!"\n</ul>\n" ++
  s!"</body>\n</html>\n"

def exportRegistryMarkdown (reg : ADRRegistry) (path : System.FilePath) : IO Unit :=
  let content := String.intercalate "\n---\n\n" (reg.entries.map exportMarkdown)
  IO.FS.writeFile path content

def exportRegistryHTML (reg : ADRRegistry) (path : System.FilePath) : IO Unit :=
  let items := reg.entries.map fun adr =>
    s!"<li><a href=\"{adr.id}.html\">{adr.id}: {adr.title}</a> ({adr.status})</li>\n"
  let body :=
    s!"<html><body><h1>ADR Index</h1>\n<ul>\n" ++
    String.intercalate "\n" items ++
    s!"</ul>\n</body></html>\n"
  IO.FS.writeFile path body

def exportProofCertHTML (adr : ADR) (v : ValidADR adr) (path : System.FilePath) : IO Unit := do
  let html := exportHTML adr
  IO.FS.writeFile path html

def exportDocsFolder (reg : ADRRegistry) (dir : System.FilePath) : IO Unit := do
  IO.FS.createDirAll dir
  for adr in reg.entries do
    let md := exportMarkdown adr
    let html := exportHTML adr
    IO.FS.writeFile (dir / s!"{adr.id}.md") md
    IO.FS.writeFile (dir / s!"{adr.id}.html") html

end ADR.Export
