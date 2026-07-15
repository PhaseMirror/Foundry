# Integration Plan: Phase Mirror ↔ Kilo CLI (Production‑grade)

---

## 1. Overview
**Note:** The Kilo editor will be distributed as a standalone binary; flatpak integration is omitted.
This document describes a **production‑grade plan** to integrate the **Phase Mirror** stack ( `phase-mirror-gpt`, `phase-mirror-mcp`, `phase-mirror-cli` ) with the **Kilo** terminal text editor. The goal is to expose Phase Mirror’s AI‑assisted capabilities directly inside Kilo’s CLI workflow, while preserving the **Sedona Spine** governance model and supporting flatpak distribution.

---

## 2. Goals & Non‑Goals
| Goal | Description |
|------|-------------|
| **AI‑assisted editing** | Provide in‑editor commands (`:ai`, `:review`, `:explain`) that delegate to `phase-mirror-gpt` for code generation, summarisation, and risk assessment. |
| **Zero‑drift risk logic** | All preservation‑risk decisions continue to flow **Engine → SDK → CONTRACT → UI**, never re‑interpreted in Kilo. |
| **Flatpak‑ready** | The final package ships Kilo, Phase Mirror binaries, and required runtimes in a single Flatpak bundle. |
| **CI/CD automation** | Full build, lint, unit‑test, integration‑test, and packaging pipeline. |
| **Documentation & UX** | End‑user docs, man‑pages and in‑editor help. |

**Non‑Goals**: Re‑writing Phase Mirror in Rust; supporting non‑Linux platforms in this release.

---

## 3. Stakeholders
- **Multiplicity Core Team** – owns Phase Mirror and flatpak manifest.
- **UX/Design Team** – defines Kilo UI/UX for AI commands.
- **Security/Governance** – ensures Sedona Spine mandates are enforced.
- **CI Engineers** – maintain GitHub Actions pipelines.

---

## 4. Architecture Overview
```
+----------------+          +-------------------+          +-------------------+
|                |  JSON‑RPC|                   |  STDIN/STDOUT|                   |
|   Kilo CLI     +---------►+  Phase‑Mirror‑GPT +◄-----------+  Phase‑Mirror‑MCP |
| (C source)     |          |  (Rust binary)    |          |  (Rust server)   |
+----------------+          +-------------------+          +-------------------+
        ^                              ^                              ^
        |                              |                              |
        |   env vars / config file     |   env vars / config file     |   env vars / config file
        |                              |                              |
        +------------------------------+------------------------------+
                               Shared Runtime (Flatpak)
```
- **Kilo** stays a pure C editor; a lightweight **integration library** (C wrapper) talks to Phase Mirror via JSON‑RPC.
- **Phase Mirror‑GPT** is the **engine**; it performs all risk calculations and returns structured JSON.
- **Phase Mirror‑MCP** handles policy enforcement and contract validation.
- **Flatpak** provides an isolated runtime that bundles all binaries and declares the required permissions.

---

## 5. Integration Points
**Note:** Flatpak packaging is not part of this plan; integration will be provided as a standalone binary with optional components.
1. **Configuration Layer**
   - New file `~/.config/kilo/phase-mirror.yaml` containing:
   ```yaml
   gpt_binary: ${HOME}/.local/bin/phase-mirror-gpt
   mcp_binary: ${HOME}/.local/bin/phase-mirror-mcp
   enable_ai: true
   ```
   - Environment variables `PHASE_MIRROR_GPT_BINARY` / `PHASE_MIRROR_MCP_BINARY` as overrides (used by the SDK).
2. **C Wrapper (`pm_bridge.c`)**
   - Spawns the GPT binary with `std::process::Command`‑style pipe (via `fork/exec`).
   - Sends a JSON‑RPC request (`method: "ai/complete"`, `params: {text: …}`) and reads the response.
   - Exposes a simple API for Kilo: `int pm_ai_complete(const char *input, char *output, size_t out_len);`
3. **Kilo Command Extensions**
   - New keystroke `Ctrl‑A` opens a *mini‑command palette* where you can type `:ai <prompt>`.
   - The buffer content is sent to Phase Mirror, response inserted at cursor.
   - Additional commands:
     - `:review` – runs risk‑assessment on the current file (Phase Mirror‑MCP).
     - `:explain` – summarises selected text.
4. **Flatpak Manifest Additions**
   - Add modules for `phase-mirror-gpt` and `phase-mirror-mcp` (as in the existing `com.citizengardens.agiOS.yaml`).
   - Declare `--share=network` and `--socket=wayland` to satisfy Phase Mirror runtime requirements.

---

## 6. Implementation Steps
**Note:** Steps related to flatpak packaging have been removed; focus on building Kilo and Phase Mirror components as separate binaries.
| Phase | Tasks |
|------|-------|
| **0 Preparation** | - Fork `antirez/kilo` into `multiplicity/kilo‑phase‑mirror`. <br> - Create a new repo `multiplicity/phase‑mirror‑kilo‑integration`. |
| **1 SDK Bridge** | - Add `pm_bridge.c/h` to the Kilo source tree. <br> - Write thin wrapper that spawns `${PHASE_MIRROR_GPT_BINARY}` using `posix_spawn` and pipes stdin/stdout. <br> - Include JSON‑RPC serialization (use `cJSON` library). |
| **2 Editor Commands** | - Extend `kilo.c` parsing to recognise `:` commands. <br> - Map `:ai`, `:review`, `:explain` to `pm_*` functions. <br> - Provide UI feedback (status line). |
| **3 Configuration** | - Add loader for `~/.config/kilo/phase-mirror.yaml`. <br> - Validate presence of binaries; fallback to env vars. |
| **4 Testing** | - Unit tests for `pm_bridge` (mock GPT script). <br> - Integration test: run Kilo headless and assert AI‑generated text appears. |
| **5 CI/CD Pipeline** | - **GitHub Actions** workflow `ci.yml`: <br>   1. Install Rust toolchain (stable). <br>   2. Build Phase Mirror binaries (`cargo build --release`). <br>   3. Build Kilo (`make`). <br>   4. Run `cargo test` + `make test`. <br>   5. Lint with `clang-tidy` and `cargo clippy`. <br>   6. Package flatpak (`flatpak-builder`). |
| **6 Flatpak Packaging** | - Create a new module `kilo-phase-mirror` that depends on the Phase Mirror modules. <br> - Update `com.citizengardens.agiOS.yaml` to copy `kilo` binary to `/app/bin/kilo`. <br> - Add runtime permissions for `process-spawn` (Flatpak policy). |
| **7 Release** | - Tag `v1.0.0‑ai` and publish to Flathub. <br> - Generate release notes and user guide. |

---

## 7. Security & Compliance (Sedona Spine)
1. **Zero‑Drift** – All preservation‑risk calculations stay inside `phase-mirror-gpt` / `phase-mirror-mcp`. Kilo only forwards the **facts** and displays the **verdict**.
2. **Policy‑Driven** – Any policy changes (e.g., allowed file types for AI assistance) are stored in `templates/*.yaml` and consumed by the MCP server.
3. **Event‑Log** – Every AI request from Kilo is logged to `$XDG_STATE_HOME/kilo/pm_audit.log` with a timestamp, user ID, and request hash.
4. **Contract Enforcement** – Before Kilo inserts AI output, it validates the response against `CONTRACT.md` (signature, status). If validation fails, the editor displays an error and aborts insertion.
5. **Sandboxing** – The Flatpak runtime isolates the editor and Phase Mirror binaries; no host filesystem access beyond what is declared (`--filesystem=xdg-documents/PhaseMirror:create`).

---

## 8. Testing Strategy
- **Unit Tests** (C & Rust):
  - Mock `pm_bridge` using a lightweight Python script that returns a fixed JSON payload.
  - Verify JSON‑RPC request/response round‑trip.
- **Integration Tests**:
  - Use `expect` scripts to simulate user typing `:ai hello` inside Kilo and assert the buffer contains the AI‑generated text.
  - Run end‑to‑end inside the flatpak sandbox (`flatpak run com.citizengardens.agiOS`).
- **Performance Tests**:
  - Measure latency of AI calls (target < 500 ms for short prompts).
- **Security Tests**:
  - Verify that tampered GPT output is rejected by the contract validator.
- **CI Integration**:
  - All tests must pass before any merge to `main`.

---

## 9. Packaging & Distribution
**Note:** Distribution will be via standard Linux packages (deb, rpm) or tarballs; flatpak modules are omitted.
1. **Flatpak Modules**
   ```yaml
   - name: phase-mirror-gpt
     buildsystem: simple
     build-commands:
       - cargo build --release --manifest-path "Phase Mirror/phase-mirror-gpt/Cargo.toml"
       - install -D target/release/phase-mirror-gpt /app/bin/pm-gpt
   - name: phase-mirror-mcp
     buildsystem: simple
     build-commands:
       - cargo build --release --manifest-path "Phase Mirror/phase-mirror-mcp/Cargo.toml"
       - install -D target/release/phase-mirror-mcp /app/bin/pm-mcp
   - name: kilo-phase-mirror
     buildsystem: simple
     build-commands:
       - make -C Kilo
       - install -D kilo /app/bin/kilo
   ```
2. **Permissions**
   - `process-spawn` for invoking GPT/MCP binaries.
   - `--filesystem=home/.config/kilo:create` for configuration files.
3. **Update Manifest** (`com.citizengardens.agiOS.yaml`)
   - Add the new modules under `modules:`.
   - Add `install -D scripts/flatpak/kilo-orchestrator.sh /app/bin/kilo-orchestrator` if a wrapper script is needed.

---

## 10. Release Process
**Note:** Release will publish standalone Kilo binary and Phase Mirror components separately; no flatpak submission.
1. **Feature Freeze** – All integration code merged to `release/1.0`.
2. **Beta Testing** – Distribute a beta flatpak to internal reviewers; collect feedback via GitHub Issues.
3. **Tag & Publish** – `git tag -a v1.0.0-ai -m "Production release with Phase Mirror integration"` and push.
4. **Flathub Submission** – Follow Flathub’s review checklist (metadata, screenshots, changelog).
5. **Post‑Release Monitoring** – Enable telemetry in `pm_audit.log`; set alerts for failure rates > 2%.

---

## 11. Documentation & UX
- **Man page**: `kilo(1)` updated with a *AI* section.
- **Help Overlay** (`Ctrl‑H`) showing available `:ai`, `:review`, `:explain` commands.
- **Online Docs**: Markdown page `docs/phase-mirror-integration.md` with installation steps, config examples, and troubleshooting.
- **Tutorial Video** – short (2 min) GIF showing `:ai write a for‑loop` inside Kilo.

---

## 12. Risks & Mitigation
| Risk | Impact | Mitigation |
|------|--------|------------|
| AI output contains confidential data | High (spoliation risk) | Enforce contract validation; log every request; optionally disable AI for sensitive directories via config. |
| Flatpak packaging size > 200 MB | Medium | Use stripped release binaries, enable `strip` in Cargo, compress assets. |
| Compatibility with existing Kilo plugins | Low | Preserve the original Kilo API; integration is additive and guarded by `enable_ai` flag. |
| Runtime permission errors in Flatpak | Medium | Explicitly declare all required permissions; include automated `flatpak-builder --run` smoke test in CI. |

---

## 13. Timeline (8 weeks)
| Week | Milestone |
|------|-----------|
| 1 | Repo setup, fork Kilo, scaffold integration library. |
| 2 | Implement `pm_bridge.c` and config loader. |
| 3 | Add editor command extensions and UI feedback. |
| 4 | Write unit & integration tests; CI pipeline initial version. |
| 5 | Flatpak module definitions; build and smoke‑test locally. |
| 6 | Security review – audit logs, contract enforcement. |
| 7 | Beta release to internal testers; collect feedback. |
| 8 | Final release, publish to Flathub, update docs. |

---

# Acceptance Criteria
- `kilo -h` lists the new `:ai`, `:review`, `:explain` commands.
- Running `:ai "write a hello‑world function"` inserts valid Rust/Go code generated by Phase Mirror‑GPT.
- All AI calls are logged and validated against `CONTRACT.md`.
- Flatpak bundle size < 250 MB and passes Flathub’s automated tests.
- CI pipeline reports **green** on every push to `main`.

---

*Prepared by the Antigravity AI assistant for the Multiplicity team.*
