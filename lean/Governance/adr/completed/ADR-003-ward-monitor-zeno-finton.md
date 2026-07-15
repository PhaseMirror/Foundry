# ADR‑003: WardMonitor / Zeno‑Finton Runtime Drift Detection

## Status
**Accepted** (implemented)

## Context
The PIRTM compiler enforces mathematical invariants at compile time (constructor pattern) and build time (CI proof gate). However, the runtime environment can drift due to external factors, user input, or state corruption. The `WardMonitor` closes this loop.

## Decision
We implement a daemon that:
- Polls the manifold state at regular intervals (default 100ms).
- Computes **ρ** (KL‑divergence drift) and **δ** (liquidity pool drift).
- Applies **Zeno‑Finton gain** κ(t) = κ₀ · exp(‑α·t) to attenuate drift.
- Triggers a **SIG_GOV_KILL** if:
  - ρ ≥ ρ_halt (= 1.0)
  - δ ≥ 1e‑4 (Finton constraint)
  - λₚ · Lₚ ≥ 1 (stability violation)
- Emits warnings if ρ ≥ ρ_warn (= 0.85).
- Records all events to the Antigrav audit ledger.

## Consequences
- The governance loop is now closed: source → AST → MLIR → runtime.
- No unverified state can persist without triggering a kill.
- The Zeno gain ensures that small drifts are naturally suppressed over time.

## Implementation
- Crate: `pirtm-monitor`
- Trait: `ManifoldStateProvider` for pluggable state sources.
- Binary: `pirtm-monitor` daemon.
- CLI: `pirtm monitor` subcommand.

## Testing
- Unit tests cover all threshold violations.
- Integration tests simulate drift and verify kill behavior.
