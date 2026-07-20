# ADR: Prime Move Rta Fitting Morphism

## 1. Executive Summary
This ADR formalizes the `Fit` operator (Ṛta morphism) and Gate 0.5 (Fitting Check) within the Sedona Spine. It provides a machine-checkable primitive that encodes the grammatical trace of "having been fitted" as a first-class operator, ensuring states are boundedly restored to the viability kernel without altering contraction certificates.

## 2. Gate 0.5 – Fitting Check
Insert a new predicate in the evaluation loop before Gate 1:
```
Gate 0.5 — Fitting Check:
  Δ_fit = R(t) - R(t-1) + contraction_margin
  Required: Δ_fit ≥ 0
```
Where `R(t)` is the resonance-coherence score and `contraction_margin` is `(1 - ε) - operator_norm(s)`.

## 3. Re-Fitting Operator (Ṛta Morphism)
In accordance with the Indo-Iranian concept of Ṛta as a “completed fitting that must be continually re-articulated,” the Embodied Triad layer now includes a formal `Fit` operator. This operator performs a canonical witness selection from the Operator-Word Calculus followed by a bounded resonance restoration, returning the local state to the viability kernel without breaking contraction. The resulting state preserves the prime-indexed signature and satisfies the participle invariant `Δ_fit ≥ 0`. In governance terms, this operator is invoked whenever Gate 0.5 fails or during scheduled re-alignment cadences (e.g., every major consensus round or after a critical Phase Mirror dissonance alert). It is the computational counterpart of ritual renewal: a re-enactment of the fitting that maintains the world’s coherence.
