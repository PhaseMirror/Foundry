import Init
import SpiralCore.ADR.Core

namespace SpiralCore.ADR.Examples

open SpiralCore.ADR

def makeSampleADR (num : String) (title : String) (claim : ClaimClass) : ADR :=
  { id := s!"ADR-00{num}",
    title := title,
    status := ADRStatus.Proposed,
    claimClass := claim,
    context := [.var "context_valid"],
    decision := [.var "decision_enforced"],
    consequences := [.var "system_governed"],
    supersedes := none }

def adr_0030 := makeSampleADR "30" "Feynman Path Integral Formal Model" ClaimClass.computationalSurrogate
def adr_0031 := makeSampleADR "31" "Persistence Canopies Specification" ClaimClass.computationalSurrogate
def adr_0032 := makeSampleADR "32" "Integral R2 Subset Selection" ClaimClass.policy
def adr_0033 := makeSampleADR "33" "Fisher Geometric Sharpness Policy" ClaimClass.policy
def adr_0034 := makeSampleADR "34" "GK-Mapper Stability Framework" ClaimClass.policy
def adr_0035 := makeSampleADR "35" "Hodge Spectral Surrogates Specification" ClaimClass.computationalSurrogate
def adr_0036 := makeSampleADR "36" "Vertex-Guard Geo-Free Policy" ClaimClass.policy
def adr_0037 := makeSampleADR "37" "Geometric Trees Quadratic Forms" ClaimClass.computationalSurrogate
def adr_0038 := makeSampleADR "38" "SpiralCore v13 Specification" ClaimClass.definition
def adr_0039 := makeSampleADR "39" "SpiralCore v13 Test Suite" ClaimClass.implementationRequirement
def adr_0040 := makeSampleADR "40" "SpiralCore v14.1 System Specification" ClaimClass.definition
def adr_0041 := makeSampleADR "41" "Morse Transform Shape Analysis" ClaimClass.computationalSurrogate
def adr_0042 := makeSampleADR "42" "V4P-VSAM Internet Draft Specification" ClaimClass.definition
def adr_0043 := makeSampleADR "43" "WADA-LADA Agent Topology Policy" ClaimClass.policy

def sampleRegistry : Registry := [
  adr_0030, adr_0031, adr_0032, adr_0033, adr_0034,
  adr_0035, adr_0036, adr_0037, adr_0038, adr_0039,
  adr_0040, adr_0041, adr_0042, adr_0043
]

theorem sampleRegistry_uniqueIds : uniqueIds sampleRegistry = true := by native_decide
theorem sampleRegistry_noSelfSupersede : noSelfSupersede sampleRegistry = true := by native_decide
theorem sampleRegistry_validSupersedeTargets : validSupersedeTargets sampleRegistry = true := by native_decide
theorem sampleRegistry_isAcyclic : isAcyclic sampleRegistry = true := by native_decide
theorem sampleRegistry_consequencesEntailed : consequencesEntailed sampleRegistry = true := by native_decide

theorem sampleRegistry_wellFormed : WellFormed sampleRegistry := by
  dsimp [WellFormed]
  refine ⟨sampleRegistry_uniqueIds, sampleRegistry_noSelfSupersede, sampleRegistry_validSupersedeTargets, sampleRegistry_isAcyclic, sampleRegistry_consequencesEntailed⟩

def sampleValidRegistry : ValidRegistry := ⟨sampleRegistry, sampleRegistry_wellFormed⟩

end SpiralCore.ADR.Examples
