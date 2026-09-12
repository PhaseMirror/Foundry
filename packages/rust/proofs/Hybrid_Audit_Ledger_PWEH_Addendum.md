# Addendum: Hybrid Audit Ledger & Long-Term PWEH Integration

**Date:** 2026-06-30
**Owner:** L0 Substrate Team

## 1. Canonical Checkpoint Format
The decade-scale audit strategy replaces continuous full-trajectory event logging with discrete, prefix-committing checkpoints. The **PWEH Receipt** (comprising $S_{\text{integrity}}(t)$, the prime move $p_t$, policy root $R_\pi$, CRMF contraction certificate, and $\Lambda_m$ resonance score) is hereby ratified as the canonical checkpoint format. This structure is mathematically grounded in the `receipt_validation_soundness` Lean 4 theorem.

## 2. Replay Trigger Conditions
Full trajectory reconstruction is strictly unnecessary during routine long-term maintenance. The hybrid ledger mandates selective replay governed by L2 variance monitoring. 

A trajectory reconstruction is triggered **only** if the variance jump ($\Delta V$) between any two sequential PWEH checkpoints exceeds the system's autoimmune threshold ($\Theta_{\text{autoimmune}}$). If the resonance score shifts outside the validated bounds, the core halts and forces a replay.

## 3. 30-Day Reconstruction Bound
In the event a replay trigger condition is met, the system operates under a strict 30-day reconstruction bound. Verifiers are never required to replay a decade of operational logs. Any 30-day window is verified by replaying solely the prime-gated segments that produced variance jumps above $\Theta_{\text{autoimmune}}$, bounded securely by the surrounding PWEH checkpoints.

This strategy guarantees computational feasibility and mathematical continuity for 10-year horizons without unbounded storage requirements.
