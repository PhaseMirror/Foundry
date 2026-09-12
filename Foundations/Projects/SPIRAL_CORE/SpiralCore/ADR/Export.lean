import Init
import SpiralCore.ADR.Core
import SpiralCore.ADR.Examples

namespace SpiralCore.ADR.Export

open SpiralCore.ADR
open SpiralCore.ADR.Examples

def generateHeader (adr : ADR) : String :=
  s!"<!-- LEAN_ADR_ID: {adr.id} STATUS: {repr adr.status} CLAIM_CLASS: {repr adr.claimClass} -->"

def verifyFileNoDrift (adr : ADR) : IO Unit := do
  let path := s!"docs/{adr.id}.md"
  let fp : System.FilePath := System.FilePath.mk path
  let fileExists ← fp.pathExists
  let header := generateHeader adr
  if fileExists then
    let content ← IO.FS.readFile path
    if content.startsWith header then
      IO.println s!"[SYNC] {path} header matches Lean formal ADR record."
    else
      throw (IO.userError s!"[DRIFT ERROR] {path} header drifted from Lean kernel state. Refusing to overwrite.")
  else
    IO.println s!"[CREATE] Generating governance artifact {path}."
    IO.FS.writeFile path (header ++ s!"\n# {adr.id}: {adr.title}\n")

def runExport : IO Unit := do
  IO.println "=== Running ADR Synchronized Drift-Detection Verification ==="
  for adr in sampleRegistry do
    verifyFileNoDrift adr
  IO.println "=== ADR Verification Complete — Zero Drift Detected ==="

end SpiralCore.ADR.Export

def main : IO Unit := SpiralCore.ADR.Export.runExport
