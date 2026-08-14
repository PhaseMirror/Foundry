# 0001. Record architecture decisions

Date: 2026-05-24

## Status
Accepted

## Context
The kernel needs explicit governance artifacts so validation logic, CLI behavior, and proof generation can evolve without hidden assumptions.

## Decision
Store ADRs in `docs/adr` and require architectural changes affecting validation semantics, proof formats, or CI release policy to land with an ADR.

## Consequences
Decision lineage becomes auditable.
Review cost rises slightly, but kernel drift becomes visible.
