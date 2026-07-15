# ADR-012: Dual-Profile Flatpak Permission Strategy

## Status
Proposed | **Accepted**

## Context
PhaseMirror-HQ requires high-performance GPU acceleration (CUDA) for its PIRTM/ODE simulation engine (verified in Phase 3B). Distribution on Pop!_OS 24 via Flatpak introduces a "sandbox tension": high-performance execution vs. strict security governance. 

Standard Flatpak distribution (Flathub) discourages broad device permissions like `--device=all`, yet local development requires these for rapid hardware validation and reproducibility.

## Decision
We will maintain two distinct Flatpak manifests to separate development agility from release security:

1.  **Developer Manifest (`org.citizengardens.PhaseMirror.dev.yaml`):**
    *   **Permission:** Includes `--device=all` to ensure immediate CUDA/NVIDIA hardware access.
    *   **Scope:** Intended only for local testing and internal benchmarking.
    *   *Usage:* Installed via `flatpak --user install` to limit system-wide exposure.

2.  **Release Manifest (`org.citizengardens.PhaseMirror.yaml`):**
    *   **Permission:** Defaults to `--device=dri` and standard GL extensions.
    *   **Scope:** The canonical manifest for public distribution (Pop!_Shop/Flathub).
    *   **Governance:** Any elevation of device permissions must be separately justified and documented via a Multiplicity Improvement Proposal (MIP).

## Consequences
*   **Safety:** Prevents "permission creep" where temporary developer debugging exceptions are accidentally shipped to end-users.
*   **Velocity:** Allows the Desktop Engineering team to validate Phase 3 workloads inside the sandbox without waiting for finalized security audits.
*   **Validation:** Provides a clear path to measure if `--device=all` is truly necessary or if the Freedesktop NVIDIA GL extension is sufficient for production.

## References
*   [Phase 3B: GPU Acceleration Design](../agi-os/packages/digital_twin/simulation/PHASE3B_GPU_DESIGN.md)
*   [Flatpak Sandbox Permissions Issue #3330](https://github.com/flatpak/flatpak/issues/3330)
