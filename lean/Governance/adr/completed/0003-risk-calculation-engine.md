# ADR 0003: Risk Calculation Engine

Status: Accepted
Date: 2026-05-24

## Context
A mechanism is needed to continuously evaluate agent trust based on incoming risk signals. The Python implementation uses a reactive + periodic model.

## Decision
We will implement a `RiskScorer` that recalculates total scores based on:
1. Reactive recalculation on `Critical` severity signals.
2. Periodic/On-demand recalculation for other signals based on recent history (last 24 hours).

## Consequences
- Immediate response to critical threats.
- Balanced computational cost for non-critical signals.
- Consistent risk score updates across the mesh.
EOF
