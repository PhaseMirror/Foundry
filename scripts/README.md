# Prime / Scripts

This directory contains automation, verification, and deployment scripts used across the Multiplicity repository.

## Overview

These scripts handle everything from Continuous Integration (CI) checks to local testing and deployment orchestrations.

### Key Scripts

- **Auditing & Verification:**
  - `honesty_audit.sh`: The mechanized honesty gate. It runs `#print axioms` over the Lean 4 proof layer to ensure no `sorry`, `native_decide`, or unauthorized axioms are used. Must pass in CI.
  - `verify_transpiler.py`: Verifies the transpilation pipelines.
- **Simulation & Testing:**
  - `simulate_end_to_end.sh`, `e2e_vin_loop_test.sh`: End-to-end integration tests for the protocol.
  - `simulate_swarm_agents.py`, `simulate_jit_invocation.py`: Simulates agent behaviors and JIT process invocations.
- **Deployment & Migration:**
  - `deploy_foundry_mic_drop.sh`: Deployment orchestration script.
  - `migrate_all.py`, `migrate_multi.py`: Data and state migration scripts.
- **Environment Setup:**
  - `setup-llvm15-prefix.sh`, `llvm15-config`: LLVM toolchain setup for compilation tasks.

**Note:** Any script that modifies state must emit a `UnifiedWitness` to the Archivum to remain compliant with the Sedona Spine mandate.
