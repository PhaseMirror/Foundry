import Init
import SpiralCore.ADR.Core
import SpiralCore.ADR.Examples

namespace SpiralCore.ADR.Export

open SpiralCore.ADR
open SpiralCore.ADR.Examples

def generateHeader (adr : ADR) : String :=
  s!"<!-- LEAN_ADR_ID: {adr.id} STATUS: {repr adr.status} CLAIM_CLASS: {repr adr.claimClass} -->"

def verifyOrUpdateFile (adr : ADR) : IO Unit := do
  let path := s!"docs/{adr.id}.md"
  let fp : System.FilePath := System.FilePath.mk path
  let fileExists ← fp.pathExists
  let header := generateHeader adr
  if fileExists then
    let content ← IO.FS.readFile path
    if content.startsWith header then
      IO.println s!"[SYNC] {path} header matches Lean formal ADR record."
    else
      IO.println s!"[DRIFT DETECTED] {path} header drifted. Updating front-matter to match Lean kernel state."
      IO.FS.writeFile path (header ++ "\n" ++ content)
  else
    IO.println s!"[CREATE] Generating governance artifact {path}."
    IO.FS.writeFile path (header ++ s!"\n# {adr.id}: {adr.title}\n")

def runExport : IO Unit := do
  IO.println "=== Running ADR Synchronized Drift-Detection Exporter ==="
  for adr in sampleRegistry do
    verifyOrUpdateFile adr
  IO.println "=== ADR Export & Drift Detection Complete ==="

end SpiralCore.ADR.Export

def main : IO Unit := SpiralCore.ADR.Export.runExport
