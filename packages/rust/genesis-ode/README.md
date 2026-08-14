# Genesis Governance (v0.5.0)

A production-grade, governed experimental nonlinear systems-dynamics architecture.

## Overview

Genesis Governance models and stress-tests persistence dynamics across multiple substrates (e.g., Metallurgical, Cognitive, Organizational, Semiconductor). It implements a **Governed Twin Architecture**:
- **Scalar Core:** An immutable, substrate-indexed ODE engine (Lane A).
- **Exploder:** An adversarial interrogation harness that produces `ShrapnelMaps`.
- **Builder:** A provenance-preserving assembly engine that proposes state updates.
- **Elastic Tether (τ):** A quantitative metric gating the promotion of experimental results.
- **Adaptive Multiplicity (v0.5.0):** Automated prime-band allocation for sparse, self-tuning metadata encodings.

This architecture ensures a **Protected Innovation Budget**: multiplicity-aware work is quarantined in exploratory tiers until certified and admitted by the Builder.

## Repository Structure

- `docs/adr/`: Architecture Decision Records (ADR-001 to ADR-010).
- `src/genesis_governance/`:
    - `core/`: Immutable scalar engine.
    - `exploder/`: Adversarial simulation and parameter sweeps.
    - `builder/`: Constructive assembly logic.
    - `governance/`: Review, rollback, and tiered decision logic.
    - `shared/`: Persistent history and novelty detection.
- `examples/`: Reproducible demo scripts.
- `tests/golden/`: Canonical simulation artifacts for regression testing.

## Getting Started

### Installation

```bash
make install
```

### Core Workflows

1. **Run a single trajectory:**
   ```bash
   genesis run --ramp 0.1
   ```
2. **Run a heterogeneous sweep (Met + AI):**
   ```bash
   make sweep-met-ai
   ```
3. **Review an artifact:**
   ```bash
   genesis review --input output/test_run.json
   ```
4. **Generate Self-Tuning Report:**
   ```bash
   genesis report --self-tuning
   ```
5. **Run high-frequency stress interrogation (Lane C):**
   ```bash
   PYTHONPATH=src python3 examples/semi_jitter_stress.py
   ```
6. **Reflect on trajectory history:**
   ```bash
   genesis review --trajectory
   ```

## Foundational Meta-Trajectory Complete (v0.5.1)

The Genesis Governance foundational trajectory is now closed. The platform stands as a stable, replayable, and self-improving collaborative launchpad.

- **Capstone Report:** [v0.5.1 Capstone Report](output/v0.5.1_capstone_report.md)
- **Trajectory Log:** [Genius v2 Meta-Closure](docs/trajectories/v0.5.1-meta-closure.md)
- **Status:** External Ready / Collaborative Equilibrium
- **The self-tuning loop is now algorithmic and reflexively governed.**

## Governance Invariants


- **Immutable Core:** No structural mutation of the scalar core is permitted from experimental branches.
- **Fail-Closed:** Every artifact must carry a `schema_version`, `run_id`, and explicit `tier` ([E], [S], or [I]).
- **Novelty Freeze:** Encountering an unseen fragility class triggers an automatic quarantine and manual review.

## Prime Move Logging

Researchers are encouraged to record their "Prime Move Sequences" (Exploder runs + persistence + review) for reflective self-tuning. Use the `--trajectory` flag to surface suggested prime-preference adjustments based on historical data.
