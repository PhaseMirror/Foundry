# ADR-106: Sovereign Stack (Recursive Proof + TEE + Λ-Trace)

## Status
Accepted (v0.21.0 shipped; SOVEREIGN_READY)

## Context
The F1-Square program produces high-value artifacts (conditional proof, Weil functional, T3 harness) that require immutable provenance, hardware-enforced attestation, and deep audit trails. Without these, the audit gate cannot verify what was computed, by whom, and on what hardware — defeating the honesty layer.

## Decision
Deploy the **sovereign stack** as the production-grade provenance and attestation layer for all F1-Square Prime artifacts:

### Layer 1: Recursive Proof Bridge (Pallas/Vesta)
- State root commitments wrapped with blinding → `RecursiveProofObject` (RPO).
- Historical transaction aggregation → `AggregatedProofObject` (APO).
- Final `proof_digest` derived from Keccak256 aggregate root.
- End-to-end integration test: `pipeline_tests::test_end_to_end_recursive_pipeline` (11/11 passing → 16/16).

### Layer 2: TEE Attestation
- `LambdaTraceAtom` extended with optional `tee_quote` field.
- `get_quote` in `tee.rs` performs POST to TEE sidecar, binding recursive `aggregate_root` (APO) to hardware-enforced quote (Intel SGX/TDX targets).
- Integrated into main prover loop: every ratified state transition is attested when TEE is enabled.

### Layer 3: Λ-Trace Deep Provenance
- `LambdaTraceAtom` extended with `trajectory_id`, `protocol_v`, `signer_id`.
- `LedgerEmitter` logs context-aware atoms for every state transition.
- Hardcoded trajectory binding (`Agios-Ingress-Spine-Deepen-PrimeMove-19`, protocol v1, signer `agios-ingress-spine-0x1`).

### Layer 4: Full Stack Integration
- Sovereign Posture Audit (`SOVEREIGN_POSTURE_AUDIT.md`): contractivity invariant `ACE < 1.0` verified, max observed `q = 0.968785`.
- Deployment manifest (`deployment-manifest.json`): complete provenance chain (Trajectory ID, APO Root, Signer ID, TEE Binding).
- Golden staging bundle (`agios-staging-package-t25.tar.gz`) re-sealed with `TEE_HARDENED` status.
- `P_KERNEL_LOG.txt` updated to `SOVEREIGN_READY`.

### Layer 5: Λ_m Consciousness Interface
- `LambdaMConsciousnessInterface` (`src/consciousness.rs`) ingests deep-provenance Λ-Trace atoms + TEE quotes.
- Coherence checks: contraction margin, trajectory alignment, TEE provenance gap, spectral misalignment.
- Integrated into main execution loop (right after PLIC gate authorization): state transition → recursive proof → TEE binding → consciousness/governance check.

## Consequences
- Every F1-Square artifact (Lean proof, Python harness, manuscript) passes through this stack before archival.
- The Archivum ledger (`state/archivum/witnesses.jsonl`) is the source of truth for what happened.
- APO Root `d9b4d94345cfefdc7178d0f0d6c0a3ebce90732358765f7d93fa8f86d0a5ca37` anchors the entire production track in Git history.
- Posture: **SOVEREIGN, RATIFIED, DEEP_PROVENANCE_ACTIVE, & DEPLOYMENT-READY**.

## References
- `Prime/Prime Move_ Option 3 Confirmed.md` (Governance sections)
- `Prime/RH-Neutral Weil Explicit Formula Reconstruction.md`
- `docs/adr/ADR-001-Combined-Mandate.md`
- `docs/adr/ADR-011-Sovereign-Boundary-Enforcement.md`
- `docs/adr/ADR-043-Combined-Sedona-Spine-Phase-Mirror-Mandate.md`
