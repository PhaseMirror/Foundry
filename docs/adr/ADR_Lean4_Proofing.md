# ADR: Production‑Grade Lean 4 Proofing of Multiplicity Theory

**Status:** Proposed

## 1. Context & Motivation
The document *Multiplicity Theory* (\[source\]([Multiplicity_Theory.md](file:///home/multiplicity/Multiplicity/Phase%20Mirror/Prime/docs/Multiplicity_Theory.md))) defines a large, interdisciplinary mathematical framework that mixes number theory, multiset theory, quantum physics, and philosophy.  For PhaseMirror‑Legal we need **formal, production‑grade proofs** that are:
- **Axiom‑clean** (no `sorry` or external Mathlib imports) – must live in `lean/`.
- **Governed** – any change to the logical core must be traceable through the Sedona Spine pipeline (Rust → WASM SDK → CONTRACT → UI).
- **CI‑validated** – each commit must compile, pass `lean --make` and run the **governance test suite**.
- **Auditable** – every proof artifact is recorded as a `UnifiedWitness` and anchored to the Git ledger.

## 2. Goals
| # | Goal | Success Metric |
|---|------|----------------|
| G1 | Translate the full theory into a self‑contained Lean 4 library (`lean/`). | `lean --make` succeeds with **zero** `sorry` statements. |
| G2 | Provide a **stable API** for downstream Rust/WASM components (e.g., `Engine → SDK`). | Auto‑generated Lean‑to‑WASM bindings compile and expose required theorems. |
| G3 | Enforce **continuous governance**: every proof addition produces a `UnifiedWitness`. | CI produces exactly one witness per PR merge. |
| G4 | Enable **incremental verification** for future extensions (playbooks, policy YAML). | New modules can be added without breaking existing theorems. |

## 3. Scope
- **In‑scope:** Core definitions (primes, multiset encoding, multiplicity matrices), main theorems (Stability Theorem, Prime‑Based Interaction, Time‑Dependent Extensions), and accompanying lemmas needed for those theorems.
- **Out‑of‑scope:** Exploratory `lean/legacy/` modules that rely on Mathlib, performance benchmarks, or non‑formal narrative text.

## 4. Architecture
```
prime_root/
├─ lean/                     ← production‑grade, axiom‑clean core
│   ├─ Core/                 # basic number‑theoretic primitives
│   │   ├─ Prime.lean        # definitions, primality proofs
│   │   ├─ Multiset.lean     # prime‑encoded multiset operations
│   │   └─ Matrix.lean       # multiplicity matrices, eigen‑theory
│   ├─ Dynamics/            # time‑dependent / nonlinear dynamics
│   │   ├─ Differential.lean # ODE / PDE encodings (no external libs)
│   │   └─ Quantum.lean      # prime‑encoded quantum state abstractions
│   ├─ Applications/         # high‑level theorems used by playbooks
│   │   ├─ Crypto.lean
│   │   ├─ Biology.lean
│   │   └─ Astrophysics.lean
│   └─ Tests/                # `#eval` sanity checks and `lean test`
│       └─ SmokeTest.lean
└─ lean/legacy/              ← non‑production, experimental proofs
```
All public definitions are exported via a single **namespace** `Multiplicity` to keep the SDK surface stable.

## 5. Proof Development Process
1. **Design Review** – a short ADR (this file) is opened, reviewed by the legal‑engine team, and approved via PR.
2. **Lean Stub** – create a new `*.lean` file under `lean/Core/` with **type signatures** only, no `sorry`.
3. **Proof Implementation** – fill in the proof using only core Lean definitions (`Nat`, `Int`, `Set`, `Finset`). No `import Mathlib.*`.
4. **Local Verify** – run:
   ```bash
   cd /home/multiplicity/Multiplicity/Phase\ Mirror/Prime
   lean --make
   ```
   The command must finish with `0` exit code.
5. **Witness Generation** – the CI pipeline runs `cargo run --bin generate_witness` which calls the Rust engine, creates a `UnifiedWitness` referencing the new theorem, and pushes it to the Git ledger.
6. **Merge** – only after the CI reports *all* checks passed (Lean compile, witness, policy validation) may the PR be merged.

## 6. CI / Automation
- **GitHub Actions** (or self‑hosted runner):
  ```yaml
  name: Lean CI
  on: [push, pull_request]
  jobs:
    build:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v3
        - name: Install Lean
          run: curl -sSfL https://raw.githubusercontent.com/leanprover/lean4/master/scripts/install.sh | bash
        - name: Build Lean library
          run: lean --make
        - name: Run governance tests
          run: cargo test --test governance
        - name: Generate witness
          run: cargo run --bin generate_witness
  ```
- The **governance test** asserts that exactly one `UnifiedWitness` JSON line is emitted per PR.
- Failure of any step blocks the merge.

## 7. Documentation & Export
- Each public theorem gets an auto‑generated **markdown stub** via `lean --doc` placed in `docs/lean/` for UI consumption.
- The WASM SDK (`models/legalese-scopist/`) reads the compiled `.olean` files, extracts theorems through the engine’s reflection API, and exposes them as TypeScript types.

## 8. Review & Auditing
| Role | Responsibility |
|------|-----------------|
| **Proof Author** | Write axiom‑clean Lean code, add unit tests. |
| **Policy Engineer** | Verify that the new theorem respects the Sedona Spine policy (no risk‑level changes). |
| **Auditor** | Check `UnifiedWitness` integrity, confirm the commit is anchored. |
| **Maintainer** | Merge after CI passes, bump version tag. |

All reviews are recorded in the **Archivum** witness log.

## 9. Risks & Mitigations
- **Risk:** Introducing external imports (`Mathlib`) would break the axiom‑clean mandate. 
  - *Mitigation:* Lint rule (`no-import-mathlib`) enforced in CI.

## Enforcement Mechanism

The repository enforces the *no‑Mathlib* invariant with a **text‑search lint step** in the echo‑kernel CI workflow (`.github/workflows/ci.yml`).
The step executes `git grep -n "import Mathlib" | grep -v "@\\[mathlib_exempt\\]"` **before** the Lean toolchain is installed.
This grep‑based check is the **authoritative enforcement mechanism** for the invariant until a native, reflectable Lean attribute is implemented in a future ADR.

*Limitations:* The grep cannot detect Mathlib imports introduced via macros, conditional compilation (`#if`/`if`), `#eval` runtime loading, or string‑concatenated import paths. These vectors are **accepted risks** and must be manually identified during PR review.

*Review requirement:* Reviewers must explicitly examine any new Lean code for macro definitions, conditional imports, or runtime evaluation constructs that could bring in Mathlib without the `@[mathlib_exempt]` marker, and reject such changes unless an exemption is granted.

- **Risk:** Large proof files cause compile time blow‑up.
  - *Mitigation:* Split into focused modules, keep each file < 500 lines.
- **Risk:** Divergence between Rust engine and Lean proofs.
  - *Mitigation:* The `generate_witness` binary runs a diff against the previously stored witness hash.

## 10. Timeline (Milestones)
| Milestone | Target Date |
|-----------|-------------|
| ADR approved | 2026‑07‑07 |
| Core `Prime` and `Multiset` modules compiled | 2026‑07‑14 |
| Dynamics (ODE + Quantum) compiled | 2026‑07‑28 |
| Full application layer (Crypto, Biology, Astrophysics) compiled | 2026‑08‑15 |
| CI pipeline fully stable with witness generation | 2026‑08‑22 |
| Production release (v1.0) | 2026‑09‑01 |

---
*Generated by Antigravity – PhaseSpace Commander Coding Agent*
