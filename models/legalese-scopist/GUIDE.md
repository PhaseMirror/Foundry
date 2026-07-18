# Counsel Guide: `legalese-scopist`

The `legalese-scopist` model drives the **Sedona Spine** ESI (Electronically Stored Information) logic.

## Overview
This engine is built on a verified Rust and Lean 4 core, enforcing mathematical stability boundaries on legal risk evaluations.

## How it Computes Litigation Hold Risks
1. **Inputs**: The model takes spoliation potential and preservation urgency as continuous metrics.
2. **Spectral Bound Validation**: These legal inputs are mathematically transformed into a 2x2 density matrix. The model then evaluates whether this matrix satisfies strict "axiom-clean" spectral bounds.
3. **Risk Levels**:
   - `Critical`: Generated whenever the ESI inputs violate the mathematical bounds of stability (i.e. high spoliation risk coupled with urgent preservation constraints).
   - `High`: Generated when the bounds are technically stable but the spectral radius indicates high volatility.
   - `Medium`: The standard bounds condition is safely met.
4. **Assurance**: Every evaluation emits a `UnifiedWitness`, which guarantees that the logic cannot drift when translated to UI components or external AI agents.
