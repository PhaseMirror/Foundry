import ADR.Core

/-!
# ADR Registry Examples
Instantiations of the core ADR structures for all accepted ADRs.
-/

namespace ADR.Examples

open ADR

def prop_0013_main := PropToken.atom "UOR Civic Infrastructure"

def ADR0013 : ADR := {
  id := "0013"
  title := "UOR Civic Infrastructure"
  status := .Accepted
  context := [prop_0013_main]
  decision := [prop_0013_main]
  consequences := [prop_0013_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0013-UOR Civic Infrastructure.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0014_main := PropToken.atom "UCC as a Service — Year One Roadmap"

def ADR0014 : ADR := {
  id := "0014"
  title := "UCC as a Service — Year One Roadmap"
  status := .Accepted
  context := [prop_0014_main]
  decision := [prop_0014_main]
  consequences := [prop_0014_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0014-UCC as a Service Year One Roadmap.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0015_main := PropToken.atom "Unified Civic Infrastructure Outline"

def ADR0015 : ADR := {
  id := "0015"
  title := "Unified Civic Infrastructure Outline"
  status := .Accepted
  context := [prop_0015_main]
  decision := [prop_0015_main]
  consequences := [prop_0015_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0015-Unified Civic Infrastructure Outline.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0016_main := PropToken.atom "UOR Civic Infrastructure — Three Epochs"

def ADR0016 : ADR := {
  id := "0016"
  title := "UOR Civic Infrastructure — Three Epochs"
  status := .Accepted
  context := [prop_0016_main]
  decision := [prop_0016_main]
  consequences := [prop_0016_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0016-UOR Civic Infrastructure Three Epochs.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0017_main := PropToken.atom "Reinitialization — 90-Day Operating Plan and Volunteer Talent Model"

def ADR0017 : ADR := {
  id := "0017"
  title := "Reinitialization — 90-Day Operating Plan and Volunteer Talent Model"
  status := .Accepted
  context := [prop_0017_main]
  decision := [prop_0017_main]
  consequences := [prop_0017_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0017-90-Day Operating Plan and Talent Model.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0018_main := PropToken.atom "Reinitialization — Executive Decision Brief"

def ADR0018 : ADR := {
  id := "0018"
  title := "Reinitialization — Executive Decision Brief"
  status := .Accepted
  context := [prop_0018_main]
  decision := [prop_0018_main]
  consequences := [prop_0018_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0018-Executive Decision Brief.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0019_main := PropToken.atom "Technology Portfolio — Evidence, Risk, and Feasibility"

def ADR0019 : ADR := {
  id := "0019"
  title := "Technology Portfolio — Evidence, Risk, and Feasibility"
  status := .Accepted
  context := [prop_0019_main]
  decision := [prop_0019_main]
  consequences := [prop_0019_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0019-Technology Portfolio Evidence and Risk.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0020_main := PropToken.atom "HQ & Sovereign Node Deployment"

def ADR0020 : ADR := {
  id := "0020"
  title := "HQ & Sovereign Node Deployment"
  status := .Accepted
  context := [prop_0020_main]
  decision := [prop_0020_main]
  consequences := [prop_0020_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0020-HQ and Sovereign Node Deployment.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0021_main := PropToken.atom "UOR Mechanics — The Exact Math of Prime-Indexing"

def ADR0021 : ADR := {
  id := "0021"
  title := "UOR Mechanics — The Exact Math of Prime-Indexing"
  status := .Accepted
  context := [prop_0021_main]
  decision := [prop_0021_main]
  consequences := [prop_0021_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0021-UOR Mechanics Prime-Indexing.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0022_main := PropToken.atom "Symmetry-Matched Polarization Analysis in MnF₂"

def ADR0022 : ADR := {
  id := "0022"
  title := "Symmetry-Matched Polarization Analysis in MnF₂"
  status := .Accepted
  context := [prop_0022_main]
  decision := [prop_0022_main]
  consequences := [prop_0022_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0022-Symmetry-Matched Polarization Analysis in MnF2.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0023_main := PropToken.atom "The δJ7 Principle — Symmetry-Complement Source Sectors in Altermagnetic MnF₂"

def ADR0023 : ADR := {
  id := "0023"
  title := "The δJ7 Principle — Symmetry-Complement Source Sectors in Altermagnetic MnF₂"
  status := .Accepted
  context := [prop_0023_main]
  decision := [prop_0023_main]
  consequences := [prop_0023_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0023-The dJ7 Principle Symmetry Complement Source Sectors in MnF2.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0024_main := PropToken.atom "Reversal-Space Tomography of Weak Altermagnetic Exchange in MnF₂"

def ADR0024 : ADR := {
  id := "0024"
  title := "Reversal-Space Tomography of Weak Altermagnetic Exchange in MnF₂"
  status := .Accepted
  context := [prop_0024_main]
  decision := [prop_0024_main]
  consequences := [prop_0024_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0024-Reversal Space Tomography of Weak Altermagnetic Exchange in MnF2.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0025_main := PropToken.atom "Static Multipolar Order and Dynamical Chiral Response — Probe–Tensor Correspondence in MnF₂"

def ADR0025 : ADR := {
  id := "0025"
  title := "Static Multipolar Order and Dynamical Chiral Response — Probe–Tensor Correspondence in MnF₂"
  status := .Accepted
  context := [prop_0025_main]
  decision := [prop_0025_main]
  consequences := [prop_0025_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0025-Static Multipolar Order and Dynamical Chiral Response in MnF2.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0026_main := PropToken.atom "Symmetry-Complement Coordinates Across Altermagnets — Cross-Material Falsification"

def ADR0026 : ADR := {
  id := "0026"
  title := "Symmetry-Complement Coordinates Across Altermagnets — Cross-Material Falsification"
  status := .Accepted
  context := [prop_0026_main]
  decision := [prop_0026_main]
  consequences := [prop_0026_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0026-Symmetry Complement Coordinates Across Altermagnets.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0027_main := PropToken.atom "When Null Does Not Mean Absent — Measurement-Map Geometry and Null–Witness Duality"

def ADR0027 : ADR := {
  id := "0027"
  title := "When Null Does Not Mean Absent — Measurement-Map Geometry and Null–Witness Duality"
  status := .Accepted
  context := [prop_0027_main]
  decision := [prop_0027_main]
  consequences := [prop_0027_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0027-When Null Does Not Mean Absent Measurement Map Geometry.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def prop_0028_main := PropToken.atom "Target-First Observability Calculus — Admissible Ambiguity and Dual Obstructions"

def ADR0028 : ADR := {
  id := "0028"
  title := "Target-First Observability Calculus — Admissible Ambiguity and Dual Obstructions"
  status := .Accepted
  context := [prop_0028_main]
  decision := [prop_0028_main]
  consequences := [prop_0028_main]
  supersedes := none
  links := [{ relation := "Source File", target := "docs/adr/accepted/0028-Target First Observability Calculus with Admissible Ambiguity.md" }]
  entailment_proof := by
    intro c hc
    exact Or.inl hc
    
    
}

def Registry : List ADR := [ADR0013, ADR0014, ADR0015, ADR0016, ADR0017, ADR0018, ADR0019, ADR0020, ADR0021, ADR0022, ADR0023, ADR0024, ADR0025, ADR0026, ADR0027, ADR0028]

end ADR.Examples