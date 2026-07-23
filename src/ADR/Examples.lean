import ADR.Core
import ADR.Proofs

/-!
# Example ADRs with proofs
-/

open ADR

namespace ADR.Examples

def adr1 : ADR := {
  id := ADRId.canonical "0001" 1,
  title := "Adopt Lean 4 for ADR verification",
  status := ADRStatus.Accepted,
  context := "Team needs provable invariants for architectural decisions.",
  decision := "All ADRs will be expressed as Lean structures.",
  consequences := ["Formal proofs available", "Tooling integration"],
  supersedes := none,
  links := [{ uri := "https://github.com/leanprover/lean4", description := "Lean 4 repo" }],
  riskLevel := RiskLevel.Low
}

def adr2 : ADR := {
  id := ADRId.canonical "0002" 2,
  title := "Deprecate Java ADR pipeline",
  status := ADRStatus.Deprecated,
  context := "Java pipeline lacks formal verification.",
  decision := "Migrate to Lean 4 pipeline.",
  consequences := ["Reduced manual review"],
  supersedes := some (ADRId.canonical "0001" 1),
  links := [],
  riskLevel := RiskLevel.Medium
}

def adr5 : ADR := {
  id := ADRId.canonical "0005" 5,
  title := "Lean‑Governance‑Uniformity integration for Echo‑Kernel",
  status := ADRStatus.Accepted,
  context := "Echo‑Kernel must conform to repository‑wide L0 invariant.",
  decision := "Encode ADR 005 as a Lean value, provide Mathlib exemption attribute, and enforce CI gate.",
  consequences := ["Kernel ADRs are formally tracked", "CI guarantees uniformity"],
  supersedes := some (ADRId.canonical "0001" 1),
  links := [{ uri := "file:///substrates/echo-kernel/adr-kernel-rs/docs/adr/adr-0005-learn-governance-uniformity.md", description := "ADR 5 Markdown" }],
  riskLevel := RiskLevel.Low
}

def adr5_sanity : Unit := by
  exact Unit.unit

end ADR.Examples