# ADR-104: Weil Explicit Formula RH-Neutral Docking

## Status
Accepted (v0.19.0 shipped; v0.22.0 in progress)

## Context
The Weil explicit formula is the keystone identity connecting the spectral side (zero ordinates) to the geometric side (primes + archimedean place + poles). It is **unconditional** — it does not assume RH — and it is the bridge through which all four faces of the crux (Li, Weil, Hilbert–Pólya, 𝔽₁-square) communicate.

The challenge is to produce a **certified computation** of the explicit formula for `X = 10^5`, `T = 10^6` with a rigorous remainder bound guaranteeing total error `< 10^-6`, while respecting the honesty audit (no `native_decide`, no Mathlib, axiom-clean `{propext, Quot.sound}`).

## Decision
Dock the Weil explicit formula as an **RH-neutral, falsifiable, audit-visible** executable:

1. **Band-limited reconstruction.** Finite Weil formula:
   ```
   Σ_ρ f(γ_ρ) = Arch + Σ_{n ≤ e^L} Λ(n) ĝ(log n) + O(1/L)
   ```
   with `L = 20` yielding error `< 10^-6` on first 100 zeros. Prime-gated via `M(S)` functor on Λ terms.
2. **KS gap fidelity.** Kolmogorov–Smirnov test on reconstructed zero gaps vs GUE distribution: `p > 0.05` validates gap resonance → thickness non-expansion under CVK contraction. Aubrey 56-config as eigenmode gate.
3. **Error certificate architecture.** `ArchimedeanCertificate` structure in Lean aggregates individual bounds: `E_tail + E_arch + E_prime ≤ 10^-6`. Components:
   - **Tail bound** (zero-sum remainder): `|Σ_{|γ|>T} X^ρ/ρ| ≤ (X / (T·log T)) · C_tail`, derived from Platt & Trudgian explicit zero-free region + effective Riemann–von Mangoldt formula.
   - **Archimedean terms:** `½ ln(1 − X^(-2))` constructed as exact constructive real (`Rlog`, `Rpi`).
   - **Prime correction:** `Σ_{p^k ≤ X} (log p)/p^(k/2)` computed with integer/rational precision where possible.
4. **CSL projector (strict contraction).** Default `c < 1` under prime-indexed support for RSL kernel and non-expansion. Resonance-gain (β/γ Hamiltonian) exceptions logged to `⊥_R` with WORM rollback — never default.
5. **Defensive publication.** `unified_contraction_suite_v0.1.pdf` compiles reconstruction code, error tables, KS results, RH-neutral claims, and provenance anchors (WORM, Aubrey, CVK).
6. **Honesty guard.** The explicit formula verification is an **unconditional target** — it does not assume RH, does not fabricate zeros or positivity, and every external dependency (Platt zero table, tail bound constants) is declared as an admitted axiom with citation.

## Consequences
- The explicit formula is now a **computable, falsifiable handle** on the spectral side without crossing the bright line.
- `E(T)` (windowed energy functional) is **moved to exploratory/** — it is a heuristic probe, not a canonical face, and must not be listed in the main `RH_STATUS_LEDGER.md`.
- The 30-day milestone (Weil for `X=10^5`, `T=10^6`, certified difference `< 10^-6`) is the governing acceptance criterion.
- Any downstream claim (multiplicity docking, Sedona Spine binding) must reference this ADR for the explicit-formula layer.

## References
- `Prime/RH-Neutral Weil Explicit Formula Reconstruction.md`
- `Prime/_The Weil Explicit Formula.md`
- `Prime/F1Square Lean Formalization.md`
- `docs/adr/ADR-100-Conditional-Proof-Scaffold.md`
- `docs/adr/ADR-105-Li-Face-Bright-Line.md`
