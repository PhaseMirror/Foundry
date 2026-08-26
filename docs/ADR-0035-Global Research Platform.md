**ADR-0035: Global Research Platform**

**Status:** Accepted (blocked on Layer B)  
**Date:** 2026-08-26  
**Supersedes:** prior open-participation and minting drafts

## Context

A plan was advanced to convert the Multiplicity Sovereign Core into a public, downloadable, buildable, and certifiable research program. The intended capability set included:

- Public monorepo (GitHub/GitLab) containing lean/, crates/, packages/, Projects/, scripts/, docs/
- Licensing split: Apache 2.0 (code), CC-BY-4.0 (ADRs/specs), CERN OHL-S (hardware interlock)
- One-command local verification (`setup.sh` + `verify_all.sh`) that produces a private witness
- MSC-Cert v1 calibration certificate standard
- Minting of MSC tokens (ERC-721 or W3C Verifiable Credential) to builders who produce a valid certificate
- Verification service, contribution gates, anti-sybil measures, and community channels

Existing constraints remain binding and take precedence:

- ADR-008 records Layer B (git tag + content-addressed identifier) as missing. No `v1.0.0-Stable` tag exists on the chosen repository.
- ADR-Wyoming-DAO-Membrane-Overrides forbids any legal or token instrument until an immutable Article III identifier exists and Lean propositions are proved against types from that tagged tree.
- L0 requires zero residual human authority.
- Production_Mode_Lock freezes complexity at FeMoco 69 qudits and forbids larger targets until 30-day governance resilience is demonstrated.
- Sedona Spine Mandate and Action Prime 17 remain non-bypassable.

## Central Tension

Autonomy / community velocity versus membrane integrity and zero residual human authority.

## Binding Choices

1. Membrane invariant selected over community growth velocity.  
   Article III identifier must be immutable and must pre-exist any token or credential that claims sovereignty over the Multiplicity Sovereign Core.

2. MSC-Cert schema frozen as non-minting specification only (ADR-009).  
   No verification service may accept the schema.  
   No oracle may sign under the schema.  
   No token (ERC-721, W3C credential, or Archivum entry) may be issued that references the schema.  
   No public monorepo claim of stability is authorized.

## Decision

The Global Research Platform is defined as a future, Layer-B-gated capability. Until the annotated tag `v1.0.0-Stable` exists and its tree SHA is recorded in CONTRACT.md:

- All certification and minting paths remain fail-closed.
- The MSC-Cert v1 schema exists solely as a target format.
- Local verification scripts may generate private witnesses only.
- No human-operated service is authorized to validate or mint.
- Licensing, public README claims, contribution workflows that issue credentials, and any mint function remain deferred.

The platform does not reopen the FeMoco concurrency freeze or alter Production_Mode_Lock.

## Frozen Schema Reference (MSC-Cert v1)

```json
{
  "certificate_version": "1.0",
  "builder_public_key": "ed25519:...",
  "git_commit": "<sha of tagged tree only>",
  "environment": {
    "os": "linux|darwin|windows",
    "cpu": "x86_64|aarch64",
    "lean_version": "<exact>",
    "rust_version": "<exact>",
    "python_version": "<exact>"
  },
  "release_witness": {
    "merkle_root": "<tree SHA of v1.0.0-Stable only>",
    "leaves": ["..."]
  },
  "test_logs_hash": "sha256:...",
  "timestamp_iso": "YYYY-MM-DDTHH:MM:SSZ",
  "signature": "ed25519 over canonical JSON"
}
```

Constraint: `git_commit` and `release_witness.merkle_root` are valid only when they match the annotated tag `v1.0.0-Stable` recorded in CONTRACT.md. Any other value renders the certificate invalid by construction.

## Deferred Target Elements (Layer-B contingent)

- Repository licensing and public README badges
- `scripts/setup.sh` and `scripts/verify_all.sh` (local witness generation only until unblocked)
- Contribution process that issues MSC-Prover or equivalent credentials
- Verification service / oracle
- ERC-721 or W3C credential mint path
- Anti-sybil identity requirements beyond the tagged tree itself
- Community channels that claim verification status

None of the above may be activated by PR until a subsequent ADR re-opens the path under an existing Layer B tag.

## Invariants Preserved

- Zero residual human authority
- Fail-closed on missing Layer B
- Lean axiom-clean (no Mathlib, no sorry)
- Edge never runs a prover
- Action Prime 17 remains sole upgrade path
- Sedona Spine Mandate
- Production_Mode_Lock and FeMoco 69-qudit envelope

## Consequences

- Public launch and token issuance remain blocked.
- Schema may be refined as text only.
- Any PR that activates a mint function, verification endpoint, credential issuer, or public stability claim is rejected by governance until Layer B exists and a new ADR explicitly re-opens the path.

## Related Artifacts

- ADR-008-ZK-Code-Verification.md
- ADR-009-MSC-Cert-Schema-Freeze.md
- ADR-Wyoming-DAO-Membrane-Overrides.md
- Production_Mode_Lock.md
- UAC_OnChain_Finality_Lock.md

**Owner:** Formal methods + legal steward  
**Metric:** zero certificates accepted; zero tokens issued; Layer B tag absent  
**Horizon:** permanent until Layer B exists and a new ADR re-opens the path
