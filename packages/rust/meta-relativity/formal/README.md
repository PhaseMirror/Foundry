# meta_relativity_formalized — DEPRECATED

> **This formalization is deprecated and replaced by the gated Nat-based approach.**
>
> See `lean/gated/META_RELATIVITY/` for the production formalization.
> See `docs/ADR-META_RELATIVITY-Formalization.md` for the migration decision.

## Status

| Property | Value |
|---|---|
| **Status** | DEPRECATED |
| **Replacement** | `lean/gated/META_RELATIVITY/` |
| **Axioms** | 23 (unsound `Real` reconstruction) |
| **Sorries** | 0 |
| **Last updated** | 2025-07-20 |

## Why Deprecated

This formalization used 23 axioms to reconstruct `Real`, `Complex`, `norm`, `inner_prod`,
`MetricSpace`, `NormedAddCommGroup`, etc. from scratch. The `Real` type was declared as
opaque with no field axioms, making it unsound — no algebraic properties could be proven.

The replacement (`lean/gated/META_RELATIVITY/`) uses:
- **Zero axioms, zero sorry** across all 7 modules
- **Nat-based discrete arithmetic** with `scale = 10000`
- **Rust/Kani** for numerical bounds verification
- **Full operator stack** (A+B+E), spectral invariants, certification, security

## Migration

All definitions in this directory have been re-implemented in the gated project.
No code should import from this directory.

## Retention

This directory is retained for historical reference only. Do not add new code here.
