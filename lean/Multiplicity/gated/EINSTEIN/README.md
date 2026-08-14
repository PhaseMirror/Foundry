# README for gated Einstein implementation

This directory contains the production‑grade implementation of the Multiplicity Theory extensions to Einstein’s Field Equations. All changes must pass the gated validation pipeline before being merged.

## Structure
- `Einstein.lean` – Lean source defining the prime‑sector stress tensor and typed gravitational equation.
- `build_gated.py` – Pre‑receive Git hook that runs all validation scripts.

## Development Workflow
1. Make changes locally.
2. Push to `lean/gated/Einstein/` branch.
3. The pre‑receive hook validates the change.
4. CI builds and signs the artifact.
5. Only signed artifacts are promoted to production.
