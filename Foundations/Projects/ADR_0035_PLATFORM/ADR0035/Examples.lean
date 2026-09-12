import ADR0035.Core
import ADR0035.LayerBGate

/-!
# ADR0035.Examples

Concrete instantiations and simulation scenarios:
1. `sampleADR008`: ADR-008 ZK-Code-Verification
2. `sampleADR009`: ADR-009 MSC-Cert-Schema-Freeze
3. `sampleADR035`: ADR-0035 Global-Research-Platform
4. Simulation scenarios demonstrating fail-closed gating on missing Layer B.
-/

namespace ADR0035

/-- ADR-008: ZK Code Verification & Missing Layer B -/
def sampleADR008 : ADR := {
  id           := 8,
  title        := "ZK Code Verification",
  status       := ADRStatus.Accepted,
  context      := "Layer B tag v1.0.0-Stable missing; zero on-chain authority without immutable anchor.",
  decision     := "Require Layer B content-addressed identifier before enabling ZK code attestation.",
  consequences := ["All ZK mint paths fail closed", "Private local witnesses only"],
  supersedes   := none,
  links        := [{ label := "ADR-008", uri := "docs/adr/ADR-008.md" }],
  isLayerBGated:= true
}

/-- ADR-009: MSC-Cert Schema Freeze -/
def sampleADR009 : ADR := {
  id           := 9,
  title        := "MSC-Cert Schema Freeze",
  status       := ADRStatus.Accepted,
  context      := "MSC-Cert v1 calibration schema must not be used for minting credentials.",
  decision     := "Freeze MSC-Cert schema as non-minting specification only.",
  consequences := ["No verification service accepts schema", "Zero tokens issued"],
  supersedes   := none,
  links        := [{ label := "ADR-009", uri := "docs/adr/ADR-009.md" }],
  isLayerBGated:= true
}

/-- ADR-035: Global Research Platform -/
def sampleADR035 : ADR := {
  id           := 35,
  title        := "Global Research Platform",
  status       := ADRStatus.Accepted,
  context      := "Proposal to convert Sovereign Core into public research program with credentials.",
  decision     := "Define platform as future Layer-B-gated capability; remain fail-closed.",
  consequences := [
    "Zero certificates accepted",
    "Zero tokens minted",
    "Local verification generates private witnesses only"
  ],
  supersedes   := none,
  links        := [
    { label := "ADR-035", uri := "lean/docs/ADR-0035-Global Research Platform.md" },
    { label := "ADR-008", uri := "docs/adr/ADR-008.md" },
    { label := "ADR-009", uri := "docs/adr/ADR-009.md" }
  ],
  isLayerBGated:= true
}

/-- Registry list of sample ADRs -/
def sampleRegistry : List ADR := [sampleADR008, sampleADR009, sampleADR035]

/-- Sample unratified tag (wrong tag name) -/
def sampleUnratifiedTag : LayerBTag := {
  tagName              := "v0.9.0-Beta",
  treeSHA              := "42904c3c118524425c8c4cd66d001d3b7a5cf45c",
  isRecordedInContract := false,
  isArticleIIIMatching := false
}

/-- Sample mock MSC-Cert payload -/
def sampleMSCCert : MSCCertSchema := {
  version       := "1.0",
  builderPubKey := "ed25519:abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789",
  gitCommit     := "42904c3c118524425c8c4cd66d001d3b7a5cf45c",
  merkleRoot    := "42904c3c118524425c8c4cd66d001d3b7a5cf45c",
  testLogsHash  := "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  timestampIso  := "2026-08-26T00:00:00Z",
  signature     := "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
}

end ADR0035
