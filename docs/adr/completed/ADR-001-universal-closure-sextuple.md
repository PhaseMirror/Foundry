---
status: completed
date: 2026-07-21
decision-maker: PhaseMirror Team
---

# ADR-001: Universal Closure Sextuple

## Context

The Universal Closure Theory (UCT) requires a formal definition of the sextuple (X, ∘, α, μ, F, Δ) that captures the algebraic structure of partial-to-total completion.

## Decision

Adopt the sextuple definition where:
- **X**: carrier type
- **∘**: binary composition operation
- **α**: closure operator (idempotent)
- **μ**: defect measure (monotone under closure)
- **F**: free functor (completion)
- **Δ**: associator defect

## Consequences

- Provides a unified framework for both classical and quantum UC instances
- Enables formal verification via Lean 4
- Enables bounded model checking via Kani
