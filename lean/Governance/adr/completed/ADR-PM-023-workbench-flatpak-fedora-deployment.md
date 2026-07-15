# ADR-PM-023: Local Flatpak Deployment for PhaseMirror Workbench on Fedora

- Status: proposed
- Date: 2026-06-16
- Owners: Desktop Engineering, Governance Team
- Tags: deployment, flatpak, fedora, workbench, isolation
- Depends On: ADR-PM-006, ADR-012, Sedona Spine Mandate (GEMINI.md)
- Phase: phase-3

## 1. Context
The PhaseMirror Workbench (located in `./workbench`) is an Angular-based governance cockpit that provides the primary interface for managing ESI retention and litigation hold logic. Currently, it runs as a standard Node.js application, which introduces environmental drift and security risks when deployed across diverse Fedora-based developer workstations. 

To satisfy the "Sedona Spine Mandate" and ensure a consistent "Path of Integrity" (Engine -> SDK -> Contract -> UI), we require a production-grade local deployment strategy that:
1.  Isolates the Workbench UI from the host system.
2.  Bundles the `legalese-scopist` (Sedona Spine) daemon.
3.  Integrates seamlessly with Fedora's desktop environment (GNOME/KDE).
4.  Supports local-first data sovereignty and offline operation.

## 2. Decision
We will adopt **Flatpak** as the primary local deployment vehicle for the PhaseMirror Workbench on Fedora. This involves creating a unified Flatpak manifest that packages both the Angular frontend and the Rust-based `legalese-scopist` sidecar.

### 2.1 Architecture
- **App ID**: `org.citizengardens.PhaseMirror.Workbench`
- **Runtime**: `org.freedesktop.Platform` (24.08)
- **SDK**: `org.freedesktop.Sdk` (24.08)
- **Execution Model**:
    - A wrapper script (`phasemirror-workbench-shell`) will start the `legalese-scopist` daemon in the background.
    - The Angular app will be served via a local `httpd` or `nginx` instance inside the sandbox, or bundled as a standalone binary using a Node.js runtime (e.g., `pkg` or simply `node` serving static files).
    - The UI communicates with the daemon via `localhost` (within the sandbox network namespace).

### 2.2 Permissions (Least Privilege)
- `--share=network`: Required for internal communication between UI and Daemon.
- `--socket=wayland`, `--socket=x11`: GUI access.
- `--device=dri`: GPU acceleration for Dissonance Graph rendering.
- `--filesystem=xdg-documents/PhaseMirror:create`: Persistent storage for local legal policies and matter playbooks.
- `--metadata=X-D-Bus-Proxy=true`: To support future portal-based integrations.

### 2.3 Fedora-Specific Wiring
- Use `flatpak-builder` with `--user` installation for developer agility.
- Integration with Fedora's `dnf` is not required; the bundle is self-contained.
- Support for `silverblue`/`kinoite` (Atomic Fedora) via immutable sandbox paths.
- **Deployment Command**:
  ```bash
  flatpak-builder --user --install --force-clean build-dir Governance/packaging/flatpak/org.citizengardens.PhaseMirror.Workbench.yaml
  ```

## 3. Relationship with IDE Workbench (ADR-PM-006)
While ADR-PM-006 defines the integration of a VS Code-based "IDE Workbench" for technical rule editing, this ADR (ADR-PM-023) focuses on the "Governance Workbench" (Angular). These two workbenches will coexist:
- **IDE Workbench**: For engineers (rule development, MCP orchestration).
- **Governance Workbench**: For legal counsel and risk officers (ESI retention, litigation hold dashboard).
They both utilize the same `legalese-scopist` (Sedona Spine) backend for truth extraction.

## 4. Implementation Plan
1.  **Manifest Creation**: Define `org.citizengardens.PhaseMirror.Workbench.yaml` in `Governance/packaging/flatpak/`.
2.  **Wrapper Script**: Implement `scripts/flatpak/phasemirror-workbench-shell.sh` to orchestrate the dual-process startup.
3.  **Build Pipeline**:
    - Module `node`: Build Angular artifacts from `./workbench`.
    - Module `rust`: Build `legalese-scopist` from `./Multi-Ensembles/legalese-scopist`.
4.  **Verification**: 
    - Smoke test: `flatpak run org.citizengardens.PhaseMirror.Workbench --debug`.
    - Integrity Check: Verify that the UI correctly fetches risk levels from the bundled Sedona Spine.

## 5. Alternatives Considered
- **Native RPM**: Rejected. Managing Node.js and Rust dependencies across Fedora versions is fragile and violates the requirement for an isolated "Path of Integrity."
- **AppImage**: Rejected. Lacks the robust sandboxing and permission management required by the Sedona Spine Mandate.
- **Docker-Desktop**: Rejected. Overkill for a local GUI app and introduces unnecessary virtualization overhead.

## 6. Risks
- **Sandbox Communication**: If the `legalese-scopist` requires access to host-level ESI (e.g., local mail stores), additional filesystem permissions will be needed.
- **Resource Usage**: Running a Node.js and Rust process in a single sandbox may increase memory footprint.

## 7. Consequences
- **Positive**: Consistent developer environment; "it works on my Fedora."
- **Positive**: Clear security boundary; legal data stays inside the designated XDG folders.
- **Negative**: Initial complexity in maintaining the Flatpak manifest and build modules.
- **Positive**: Simplifies onboarding; `flatpak install` replaces a complex multi-tool setup.
