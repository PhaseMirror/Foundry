# Phase Mirror Loop – ADR Plan

## 1. Goal Analysis
The **Phase Mirror Loop** (`Phase_Mirror_Loop_Goal.md`) defines a five‑step workflow:
1. Analyze goals, claims, math, policy, constraints.
2. Identify tensions between intent vs incentives, urgency vs capacity, risk claimed vs risk owned, control desired vs available.
3. Rank tensions by impact and tractability.
4. Produce an ADR plan to address the tensions.
5. Commence production‑grade resolution of the dissonance.

Our current state already implements the core mathematical foundation (Lean 4 axioms, Rust/Kani verified resolvent) and the data‑handoff bridge. The remaining work is to formalize the **tension analysis** and **ADR plan** that will guide the production rollout.

## 2. Identified Tensions
| # | Tension Category | Description | Why it matters |
|---|------------------|-------------|----------------|
| 1 | Intent vs Incentives | The *intent* is to provide a mathematically provable spectral analysis pipeline; the *incentive* for developers is to ship a fast WASM binary. Potential friction: developers might shortcut verification for speed. |
| 2 | Urgency vs Capacity | The paper deadline creates urgency, but the team’s capacity to refactor existing Python‑heavy code into Rust is limited. |
| 3 | Risk Claimed vs Risk Owned | The FTSA‑ZSD paper claims zero‑drift risk, yet the Rust build currently disables Kani (due to nightly feature restrictions). The risk of undetected overflow remains. |
| 4 | Control Desired vs Available | Desired: end‑to‑end control of the entire stack (Lean → Rust → WASM). Available: separate repositories and a workspace that does not enforce a unified CI pipeline. |
| 5 | Documentation vs Implementation Gap | The formal ADRs exist, but the high‑level documentation for external contributors is missing, causing onboarding friction. |

## 3. Ranking (Impact × Tractability)
| Rank | Tension # | Impact | Tractability | Score |
|------|-----------|--------|--------------|-------|
| 1 | 3 | High | Medium | 8 |
| 2 | 1 | High | Easy | 7 |
| 3 | 4 | Medium | Medium | 6 |
| 4 | 2 | Medium | Hard | 5 |
| 5 | 5 | Low | Easy | 3 |

**Top priorities**: (1) close the Kani verification gap (Tension 3), then (2) codify developer incentives (Tension 1).

## 4. ADRs (Production‑Grade)
### ADR 1 – Reinstate Kani Verification in CI
- **Context**: CI builds disable Kani because of nightly‑only features, leaving a potential overflow risk.
- **Decision**: Move the repository to the nightly toolchain for CI only. Add a `build.rs` that emits `cargo::rustc-check-cfg=cfg(kani)` and guard Kani‑specific code with `#[cfg(feature = "kani")]`.
- **Consequences**: Guarantees the same bounded model checks used locally also run on CI. Introduces a nightly dependency but isolates it to verification steps.
- **Implementation**: Add `features = ["kani"]` in `Cargo.toml`, create a `build.rs`, and adjust CI to run `cargo kani --all-features`.

### ADR 2 – Incentive Alignment via Cargo‑scripts
- **Context**: Developers may skip verification for speed.
- **Decision**: Provide a `cargo verify` script that runs `cargo kani && cargo test`. Make it a prerequisite for any `cargo publish` or `cargo build --release`.
- **Consequences**: Enforces verification without manual effort; fails fast if any Kani proof regresses.

### ADR 3 – Unified CI Pipeline
- **Context**: Lean proofs, Python export, and Rust builds live in separate repos.
- **Decision**: Introduce a top‑level GitHub Actions workflow that:
  1. Runs `lake build && lake test` on the Lean core.
  2. Executes `python generate_rust_vals.py`.
  3. Runs `cargo kani --all-features`.
  4. Builds the WASM target.
- **Consequences**: Guarantees end‑to‑end integrity for each commit.

### ADR 4 – Documentation Gap Closure
- **Context**: External contributors lack a clear “how‑to” for the Triple‑Lock pipeline.
- **Decision**: Add `docs/TRIPLE_LOCK_OVERVIEW.md` that explains the flow, the required toolchains, and the verification steps.
- **Consequences**: Low‑effort, high impact on onboarding.

## 5. Production‑Grade Resolution Steps
1. Apply ADR 1 – update `Cargo.toml`, add `build.rs`, adjust CI.
2. Apply ADR 2 – add `scripts/verify.sh` wrapper and README badges.
3. Apply ADR 3 – create `.github/workflows/ci.yml`.
4. Apply ADR 4 – write documentation file.
5. Run full verification: CI, Kani proofs, rebuild WASM.

All artifacts are now present in the repository:
- `src/spectral_resolvent.rs`
- `examples/resolvent_scan.rs`
- `triple_lock_certification.md` (artifact)
- Placeholder ADR file now stored in this location.
