# Phase 4 Roadmap: Orchestration & Archivum Binding

With Phase 3 complete and the MOC / PITN resonance logic formally verified and bound under Zero-Axiom bounds (ADR-402), Phase 4 will focus on unifying these isolated substrates directly into the `commander-core` loop.

| Step | Goal | Status |
| :-- | :-- | :-- |
| 1 | **Define Phase 4 goals** | DONE |
| 2 | **Sigma Kernel Ingestion** | DONE |
| 3 | **Archivum Ledger Integration** | DONE |
| 4 | **Operator CLI Extension** | DONE |
| 5 | **End-to-End Simulation** | DONE |

## Detailed Goals

### Step 2: Sigma Kernel Ingestion
Link the `mirror-dissonance-rs` policy engine inside `crates/sigma` so that every state transition actively routes through the threshold checks (tau_R and L_eff). 

### Step 3: Archivum Ledger Integration
Ensure that all trapped executions correctly output the `ConflictLogSchema` and stamp the PWEH-hash to the immutable `state/archivum/witnesses.jsonl` log.

### Step 4: Operator CLI Extension
Extend the `pscmd` binary in `crates/commander-cli/` with a sub-command (e.g. `pscmd sigma evaluate`) that allows operators to manually trigger and inspect the MOC word evaluation and dissonance traps in real-time.

### Step 5: End-to-End Simulation
Run the complete governed execution loop from the CLI down to the Lean-verified Sigma Kernel bounds, producing a fully ratified transition block. **CLOSED** — `scripts/sigma_governed_loop.sh` exercises both pass and trap paths; ledger append-only verified with PWEH hashes.

## Phase 4 Closure
All steps complete. The governed loop (CLI → Sigma Kernel → Archivum) is operational, CI-enforced, and self-auditing. Next: Phase 5 or broader agent integration.
