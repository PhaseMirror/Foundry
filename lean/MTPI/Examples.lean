import MTPI.ADR

open MTPI.ADR

/-! Example ADRs for testing and demonstration. -/

namespace MTPI.Examples

/-- Example ADR-045: Automated Recursive DevOps for Multiplicity on openSUSE Tumbleweed. -/
def mtpi_adr_045 : ADR := {
  id := { number := 45 },
  title := "Automated Recursive DevOps for Multiplicity on openSUSE Tumbleweed",
  status := ADRStatus.Accepted,
  context := "Multiplicity Theory, PhaseMirror-Prime Stack (P²C Core v1.1). Deploying the Multiplicity stack—including the Rust execution engine, Lean 4 formal verification compiler, and the PIRTM runtime—on an openSUSE Tumbleweed host introduces specific architectural challenges: Rolling Release Volatility (Tumbleweed's cutting-edge kernel and toolchains evolve rapidly, risking drift away from frozen ZK circuit constraints); State Mutation Integrity (traditional configuration management violates Zero Drift and fail-closed constitutional mandates); Atomic Rollback Requirements (host OS must leverage openSUSE's native transactional capabilities tied directly to a Phase Mirror health check).",
  decision := "Implement a Recursive DevOps Automation Pipeline explicitly tailored for openSUSE Tumbleweed, governed by: (1) Transactional OS State via transactional-update, Btrfs & Snapper Integration wrapping every deployment in atomic transactions with pre/post Snapper snapshots and automatic rollback on drift or regression; (2) Containerized & Static Compilation Boundaries for core binaries; (3) CI/CD Pipeline with automated health probes via WardMonitor sidecar and PWEH audit trail.",
  consequences := [
    "Guarantees bit-level reproducibility and atomic recovery across Tumbleweed's rolling kernel and library updates.",
    "Aligns OS-level infrastructure management with the core Multiplicity principle: death (or rollback) is cheaper than unverified execution.",
    "Eliminates manual configuration drift in edge-deployed nodes or commercial VPC instances running openSUSE.",
    "All deployment snapshots, rollback triggers, and cryptographic verification receipts are logged to the local WORM/CRMF audit ledger tied to the active LawfulRecursionHash."
  ],
  supersedes := none,
  links := []
}

/-- Example ADR-002: Lean 4 Formal Verification Compiler Integration. -/
def mtpi_adr_002 : ADR := {
  id := { number := 2 },
  title := "Lean 4 Formal Verification Compiler Integration",
  status := ADRStatus.Accepted,
  context := "The PIRTM runtime requires machine-checked proofs of correctness for all critical compiler passes. Existing integration with Lean 4 provides the formal verification substrate, but the compiler bridge needs explicit governance.",
  decision := "Integrate the Lean 4 formal verification compiler as a mandatory pre-deployment gate, ensuring all PIRTM compiler passes produce machine-checkable proofs before binary emission.",
  consequences := [
    "All compiler passes must emit proof artifacts alongside binaries.",
    "Build pipeline latency increases due to formal verification overhead."
  ],
  supersedes := none,
  links := []
}

/-- Example ADR-003: Deprecated Legacy Snapper Scripts. -/
def mtpi_adr_003 : ADR := {
  id := { number := 3 },
  title := "Deprecation of Legacy Snapper Scripts",
  status := ADRStatus.Deprecated,
  context := "Legacy Snapper scripts were used before the automated pipeline was established. They are now superseded by the certified transactional deployment system.",
  decision := "Deprecate all legacy Snapper scripts in favor of the automated pre/post-snapshot certification loop.",
  consequences := [
    "Legacy scripts remain available for emergency manual recovery only.",
    "All new deployments must use the certified pipeline."
  ],
  supersedes := none,
  links := []
}

end MTPI.Examples
