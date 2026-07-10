# Multiplicity Substrates — Root Repository

This is the root repository for the Multiplicity Sovereign Core framework, containing formal Lean 4 verification, Rust engines, and the Phase Mirror Commander ecosystem. All developments are bound by the **Sedona Spine** policy and the Ξ-Constitution.

## Governance Mandate

All code changes follow the **Consciousness-First Protocol (CFP)**:
- Every workflow execution produces exactly one `UnifiedWitness` in `state/archivum/witnesses.jsonl`
- Every witness is automatically committed to Git for immutable audit trail
- Every MCP tool call passes through the ALP policy gate before any process spawns
- `cargo test --test governance` must pass on every commit

## Repository Structure

```
Substrates/
├── README.md                    # This file
├── AGENTS.md                    # PhaseSpace Commander coding instructions
├── Ξ-Constitution.md            # Constitutional law (Ξ-Constitution v1.0)
├── Ξ-Constitutional-Core.md     # MOC Lawful Recursion specification
├── GEMINI.md                    # Project mandates (Sedona Spine, ADR references)
├── MOC.md                       # Multiplicity Operator Calculus
├── SECURITY.md                  # Security policy
│
├── lean/                        # F1 Square formalization (v0.22.0 in progress)
│   ├── README.md                # F1 Square program documentation
│   ├── ROADMAP.md               # Completion roadmap (v0.15.0 → v0.22.0)
│   ├── F1Square.lean            # Status rollup and interface definitions
│   ├── CPIRTM.lean              # Contractive PIRTM framework
│   ├── AFFINE_CORE/             # Stability dynamics and operators
│   ├── CRMF/                    # Contraction witness formalization
│   ├── ZMOD/                    # Z/(2^n)Z core
│   ├── UOR/                     # Universal Object Reference structures
│   ├── UMCPAROM/                # UMC Parom contraction dynamics
│   ├── XI_FORMAL/               # Stability dynamics (Ξ-formal)
│   ├── scripts/honesty_audit.sh   # Mechanized honesty gate (CI)
│   ├── .github/workflows/ci.yml   # Lean build + axiom-clean verification
│   └── docs/                    # Theory specifications
│
├── multiplicity/                # Λ-RMAM-ZΞ 7.3 Rust Engine
│   ├── README.md                # Engine overview (triple-lock verification)
│   └── rust/src/                # Implementation modules
│       ├── lib.rs               # Master update rule
│       ├── strata.rs            # Operational strata (S0, S2, S4)
│       ├── gate.rs              # Entropy-Inverse Gate
│       ├── zk_trace.rs          # ZK-trace generation
│       └── ...
│
├── models/                      # Model-specific implementations
│   ├── the-commander/           # Commander crates and core
│   ├── phase-mirror/            # Phase Mirror Observatory
│   ├── legalese-scopist/       # Legal governance substrate
│   └── ...
│
├── .github/workflows/           # CI workflows
│   └── sedona_spine_ci.yml      # Sedona Spine frontend validation gate
│
└── Cargo.toml                   # Workspace definition
```

## Key Projects

| Component | Path | Description |
|-----------|------|-------------|
| **F1 Square** | `lean/` | 𝔽₁-square formalization for the Riemann Hypothesis program (v0.22.0) |
| **Λ-RMAM-ZΞ 7.3** | `multiplicity/rust/` | Recursive prime-meta-ensemble architecture with ZK-audit |
| **Phase Mirror** | `models/phase-mirror/` | Discrete state observatory with `ExactRat` foundation |
| **Commander** | `models/the-commander/crates/` | Governance orchestration (ALP + Sigma + Archivum) |

## Integration Status

| Component | Status | Description |
|-----------|--------|-------------|
| **Certificate Emitted** | ✅ Done | MOC core engine produces prime-gated contraction certificates |
| **MCP Wired** | ✅ Done | Exposed via `validate_l0_invariants` to Phase Mirror Oracle |
| **ADR Governance** | ✅ Ratified | See ADR-042 for MOC Certificate Integration |
| **CI Matrix** | ✅ Done | Validates schema emission, cryptographic signatures, axiom-clean proofs |
| **Agent E2E** | ✅ Done | TS parser verifies `proof_hash` and triggers fail-close on drift |

## Build & Test

```bash
# Build all Rust crates
cargo build --workspace

# Run Lean F1 Square build + honesty audit
cd lean
lake build
bash scripts/honesty_audit.sh

# Run Rust tests
cargo test -p multiplicity

# Run governance test suite
cargo test --test governance
```

## Sedona Spine Compliance

All changes must comply with the **Sedona Spine** governance invariants:

1. **No bypassable L0 invariants** — Successor predicates, multiplicity conservation, and Rational64 exactness are first-class compilation errors at front-matter entry points
2. **No invalid strata materialization** — AST construction and documentation updates must not emit/store invalid P_N(t) strata without Rational64 exactness and ContractivityReceipt linkage
3. **Full provenance** — Every front-matter/doc change must have trace completeness to Archivum Ledger

See `docs/adr/ADR-001-Combined-Mandate.md` for the constitutional basis.

## Documentation

- **Theory**: `lean/docs/f1_square_intersection_theory.md`, `lean/docs/missing_object_over_Q.md`
- **Architecture**: `Ξ-Constitutional-Core.md`, `MOC.md`
- **Governance**: `GEMINI.md`, `AGENTS.md`
- **ADR Records**: `docs/adr/` (ADR-044 ratified, ADR-043 ratified)

## License

The Prime Materia Commons — see [LICENSE](LICENSE)

<!-- LawfulRecursionVersion:1.0 -->
