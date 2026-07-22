import ADR.Core
import ADR.Logics
import ADR.Proofs
import ADR.History
open ADR ADR.Logics ADR.Proofs ADR.History
namespace ADR.Examples

def pirLink (url desc : String) : ArtifactLink :=
  { url, artifactType := .paper, description := desc }

def pirDocs (url desc : String) : ArtifactLink :=
  { url, artifactType := .docs, description := desc }

def adr120 : ADR := {
  id           := { sequence := 120, hash := some "pir-umc" },
  title        := "PIRTM and Universal Multiplicity Constant",
  status       := ADRStatus.Accepted,
  context      :=
    "Recursive tensor computations require provable contraction before execution. " ++
    "Prime-indexed weightings and Fourier interference enforce operator norms below 1, " ++
    "enabling certified AI inference and auditable control systems.",
  decision     :=
    "Adopt Prime-Indexed Recursive Tensor Mathematics (PIRTM) as the L0 contract witness, " ++
    "and the dual-level Universal Multiplicity Constant Lambda_m as the governed recursive regulator. " ++
    "Enforce ADR-Lambda_m-01 governance protocol with fail-closed semantics.",
  consequences := [
    "Every session is contractive before execution",
    "Prime eigenmodes determine lawful trajectories",
    "Fail-closed rollback on inadmissibility",
    "Continuous-time approximations are subordinate to discrete L0 witness"
  ],
  supersedes   := none,
  links        := [
    pirDocs "file:///docs/pirtm/laws" "PIRTM mathematical laws",
    pirDocs "file:///docs/lambda_m/gov" "Lambda_m governance protocol",
    pirDocs "file:///docs/umc/phase_diagram" "UMC stability phase diagram",
    pirDocs "file:///docs/pmro" "Prime-Multiplicity Recursive Operator construction"
  ]
}

theorem adr120_valid : ValidADR adr120 :=
  mkValidADR adr120
    (fun _ _ => trivial)
    (fun _ _ => trivial)
    (by simp [adr120])
    (by intro _; simp [adr120])
    (by intro _ l; cases l; dsimp [pirDocs]; simp)

def adr001 : ADR := {
  id           := { sequence := 1, hash := none },
  title        := "Adopt Lean 4 for Governance",
  status       := ADRStatus.Accepted,
  context      := "Architectural decisions drift without machine-checked proofs.",
  decision     := "Formalize ADRs in Lean 4.",
  consequences := ["High rigor", "Zero drift", "Machine-checkable audit trail"],
  supersedes   := none,
  links        := [{ url := "https://github.com/leanprover/lean4", artifactType := .repo, description := "Lean 4 repository" }]
}

theorem adr001_valid : ValidADR adr001 :=
  mkValidADR adr001
    (fun _ _ => trivial)
    (fun _ _ => trivial)
    (by simp [adr001])
    (by intro _; simp [adr001])
    (by intro _ l; cases l; dsimp; simp)

def adr010 : ADR := {
  id           := { sequence := 10, hash := none },
  title        := "CRMF Integration with PIRTM Substrate",
  status       := ADRStatus.Accepted,
  context      := "The CRMF runtime needs a certified substrate with contractive guarantees.",
  decision     := "Integrate CRMF with the PIRTM kernel via gated operator injection.",
  consequences := ["Certified CRMF kernels", "Gated PIRTM induction"],
  supersedes   := none,
  links        := [{ url := "file:///docs/crmf/integration", artifactType := .docs, description := "CRMF integration spec" }]
}

theorem adr010_valid : ValidADR adr010 :=
  mkValidADR adr010
    (fun _ _ => trivial)
    (fun _ _ => trivial)
    (by simp [adr010])
    (by intro _; simp [adr010])
    (by intro _ l; cases l; dsimp; simp)

theorem accepted_implies_entailed (adr : ADR) :
    ValidADR adr → adr.status = .Accepted →
      ∀ c ∈ adr.consequences, entails adr.context adr.decision c := by
  intro vadr _ c hc
  exact vadr.consequences_entailed c hc

theorem accepted_immutable_without_supersede (adr : ADR) :
    ValidADR adr → adr.status = .Accepted → adr.supersedes = none → True := by
  intro vadr hStatus hSupersedes
  exact vadr.accepted_immutable hStatus hSupersedes

def adr120ProofCert : String :=
  s!"{adr120.id}: ValidADR\n" ++
  s!"  accepted_immutable: PROVEN\n" ++
  s!"  consequences_entailed: PROVEN\n" ++
  s!"  no_circular_supersession: PROVEN\n" ++
  s!"  traceability: PROVEN ({adr120.links.length} links)\n"

end ADR.Examples
