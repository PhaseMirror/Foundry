# ADR-005: Repository Initialization & Version Control Standards

**Status:** Proposed

**Date:** 2026-06-15

**Owner:** Substrates Lead

## Context
The project currently operates without a version-controlled baseline, undermining the "Governance-by-Design" mandate. The absence of an immutable history prevents deterministic build verification and auditability.

## Decision
We define the repository baseline by identifying the Minimal Viable Source Set (MVSS). We will explicitly ignore all transient artifacts, logs, and local caches. The MVSS must be version-controlled, providing a reproducible cryptographic anchor for all production builds.

## Repository Inclusion Criteria
- **Core (Include)**: All `*.rs`, `*.circom`, `*.yaml`, `*.toml`, `*.sh` (orchestration/scripts), and `.md` (ADRs/documentation) files in `Multiplicity/Aiistech/` and `Multiplicity/Governance/`.
- **Infrastructure (Include)**: Verified deployment manifests in `Multiplicity/artifacts/deploy/`.
- **Transient (Exclude)**: All `target/`, `tmp/`, `.cache/`, `*.log`, `*.tar.gz`, and hidden system/IDE folders (`.agents/`, `.aitk/`, etc.).

## Consequences
- **Build Reproducibility**: `cargo build --locked` will become the definitive build procedure.
- **Auditability**: Every deployment will be tied to a specific Git commit hash, preventing unverified code from being "hardened" into production.

## Verification Plan
1. Audit all files in the current workspace.
2. Initialize Git repository with a strict `.gitignore` enforcing the MVSS inclusion criteria.
3. Commit the baseline at the verified state.
4. Validate `cargo build --release --locked` produces an identical binary to the sandbox baseline.
