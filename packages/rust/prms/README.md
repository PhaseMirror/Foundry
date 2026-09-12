# Prime-Recursive Multiplicity Substrate (PRMS)

PRMS is a core mathematical and architectural layer of the Phase Mirror engine, implementing Endogenous Spectral Self-Regulation through prime-indexed direct-sum Hilbert spaces and PETC (Prime-Efficient Tensor Construction).

## Components

- **PETC (Constructor):** Type-correct tensor construction and invariant tracking.
- **Contractor:** Strict Banach contraction mapping for spectral stability.
- **DAE (Differential-Algebraic Equation):** Continuous dynamics and Lyapunov feedback.
- **ZetaROS:** Lawfulness auditing and provenance verification.
- **Formal Verification:** Lean 4 proofs for mathematical stability invariants.

## Architecture Decisions

Architecture decisions are documented as ADRs in [docs/adr/](docs/adr/README.md).
Specifically, see [ADR-008](docs/adr/proposed/0008-lean4-formalization-harness.md) for the Lean 4 formalization strategy.

## Development

PRMS is implemented in Rust with Lean 4 formalization.

```bash
# Run Rust tests and generate Lawfulness Report
cargo test --test lawfulness_harness -- --nocapture

# Build Lean proofs manually
cd formal && lake build
```
