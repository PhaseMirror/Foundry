# Multiplicity Substrate: User Guide

Welcome to the Multiplicity Substrate. This guide provides initial instructions for setting up, building, and verifying the system.

## 1. Prerequisites
- **Rust Toolchain**: `rustc` 1.78.0 or later, `cargo`.
- **System Dependencies**: Standard Linux build tools (`gcc`, `make`, `cmake`).
- **Python (Optional)**: Required only if running legacy Python-based integrity harnesses in `agiOS/`.

## 2. Setup
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd PhaseMirror-HQ
   ```

2. Initialize environment (if needed):
   ```bash
   # Run system checks
   ./validate_phase2_env.sh
   ```

## 3. Building
The substrate is built as a set of modular crates in `packages/`.
To build all core components:
```bash
cd packages
cargo build --release
```

## 4. Running the Substrate
The primary interface is the `multiplicity-cli`.
```bash
# Build the CLI
cd packages/multiplicity-cli
cargo build --release

# Run a diagnostic check
./target/release/m validate
```

## 5. Verification & Conformance
The substrate must satisfy **PREP-2026** bounds for operational status.
To run the automated conformance runner:
```bash
cd packages/pirtm-rs
cargo run --bin prep_conform -- --out-dir ./evidence --json
```

## 6. Security & Auditing
- **Audit Logs**: All state-changing actions are logged automatically by `security-rs` to the `artifacts/audit.jsonl` file.
- **Commitments**: System state commitments are handled by `CasRegistry` in `security-rs`.

## 7. Governance Ritual
Phase Mirror enforces architectural compliance through automated governance checks. To ensure your changes are aligned with project mandates:

1. **Integrated Governance Check**:
   Before committing, validate your changes against project ADRs:
   ```bash
   # Run governance drift detection on a specific file
   # (Note: This is automatically integrated into the commit workflow)
   pscmd mcp call --stdio <<< '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"check_drift","arguments":{"file_path":"<your-file>","content":"<your-content>"}}}'
   ```

2. **Pre-commit Enforcement**:
   The repository includes an automated pre-commit hook that enforces these checks.
   - If a governance violation is detected (e.g., forbidden cloud SDK, missing governance tags), the commit will be rejected.
   - **Remediation**: Fix the reported violation and stage the file again.
   - **Bypass (Use sparingly)**: If you must bypass, use `git commit --no-verify`.

3. **Recommended Workflow**:
   ```
   (Edit) → (check-governance) → (Fix) → (Commit)
   ```

## 8. Troubleshooting
- **Build Errors**: Ensure `wasm-bindgen` and associated features are available if compiling Wasm-targets.
- **Governance Halts**: If the system enters a `NormViolation` state, verify state against `agiOS/state/live_state.yaml` and run the `verify_constitutional_state.py` harness.
- **Pre-commit Rejections**: If your commit is rejected by governance, check the violation details provided by the `check_drift` tool and follow the remediation suggestions.
