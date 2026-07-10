# ADR-401: Identity System Integration — Prime-MOC Lift

## Status
**Proposed** — 2026-06-25

## Context
The Prime-MOC scaffold provides bright-line guarantees for prime-indexed mechanisms. This ADR integrates the general Identity System 𝒥 = (A, C, D) while preserving:
- Unique decomposition (FTA)
- Per-channel λ_p-budgeted contraction
- Spectral detectability via prime-gap statistics
- Choice-free verifiability

## Decision
Implement Identity.lean with:
1. **Identity System Structure**: Functors preserving decomposition and contraction budgets
2. **PrimeMOC Instance**: Drop-in header for prime families with idempotents
3. **BitL0 Transport**: Functor to/from Boolean L0 preserving persistence
4. **Verification Layer**: Choice-free axioms with explicit sorry placeholders

## Consequences
- Prime indexing remains the canonical high-power arithmetic case
- Generalization preserves mechanical verifiability guarantees
- No loss of λ_p L_p < 1 contraction or prime-gap χ²
- Phase Mirror governance maintained

## References
- ADR-100 (F1-Square Conditional Proof Scaffold)
- ADR-400 (Spectral Gap Documentation)
- MOC.Core.lean (existing operator definitions)
- PIRTM/CRMF axioms (transition/core structures)