# ADR-402: Phase Mirror Dissonance Ratification

## Status
Proposed

## Context
The MOC pipeline (canonical NF, resonance invariance under slides, contraction budgets) has been formally verified and integrated into the `PAROM` engine. Validated MOC transitions successfully produce measurable state evaluations ($R_{sc}$, $L_{eff}$). However, edge cases and unverified external operator states require a robust dissonance surface to prevent non-compliant state pollution. When the evaluated resonance metric ($R_{sc}$) diverges from the null-model threshold ($\tau_R$), or when the effective Lipschitz contraction ($L_{eff}$) violates strict stability bounds, the orchestration loop must safely trap and halt these operations.

## Decision
We establish a formal governance boundary mapping the **Sigma Kernel** directly to the **mirror-dissonance-rs** policy engine.

1. **Metric Mapping**: The MOC evaluation metrics, specifically the resonance scale delta ($\Delta R_{sc} = |R_{sc} - \tau_R|$) and the effective contraction ($L_{eff}$), will be systematically recorded within the `Conflict Log Schema`.
2. **Circuit-Breaker Routing**: Any invariant breach—specifically, evaluating to $\Delta R_{sc} > \tau_R$ or $L_{eff} \ge 1.0$—is aggressively trapped. The Sigma kernel will route the failed execution receipt directly into the `tokio`-based `mirror-dissonance` engine.
3. **CSL Projector Ratification**: The Continuous Stability Ledger (CSL) projector is appointed as the final arbiter. It enforces the ratification of dissonance logs, permanently recording trapped states to the Archivum.

## Consequences
- **Positive**: 
  - Non-compliant states and diverging sequences are deterministically trapped before polluting the phase state.
  - Strict preservation of overarching governance (Zero Drift mandate) is assured.
  - Transparent auditing via structured conflict logs.
- **Negative / Constraints**: 
  - Slight latency overhead during state transition validation due to the asynchronous policy engine routing.
- **Verification Strategy**: 
  - Develop integration tests that simulate a critical invariant breach ($L_{eff} \ge 1.0$ or divergent $R_{sc}$) and verify that the `mirror-dissonance-rs` engine triggers an immediate halt and correctly emits the expected conflict log schema.

## Metrics
- **Trigger Condition 1**: $\Delta R_{sc} > \tau_R$
- **Trigger Condition 2**: $L_{eff} \ge 1.0$ 
If either condition is met, ratification is triggered, and the state change is vetoed.
