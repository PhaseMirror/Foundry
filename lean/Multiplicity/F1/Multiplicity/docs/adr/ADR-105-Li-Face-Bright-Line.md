# ADR-105: Li Face Bright Line & Pos λ₁ Anchor

## Status
Accepted (v0.15.0–v0.22.0 ongoing)

## Context
Li's criterion (`λₙ ≥ 0 ∀ n ⟺ RH`) provides the computable analytic face of the crux. The first coefficient `λ₁` can be proved positive in the constructive-real substrate; the full infinite sequence cannot be kernel-proven due to bignum/denominator growth. Unscoped, this creates a temptation to overclaim — to present `λ₁ > 0` as evidence for RH or to attempt impossible kernel reductions.

## Decision
Enforce the **Bright Line of Honesty** on the Li face:

1. **Value realized ≠ positivity proven.** `Rlambda1` (the constructive real) is **defined and computable**. `Pos Rlambda1` is **proven** with explicit rational margin (~0.003). `liPositivityHolds` for the **full sequence** stays `none` (open).
2. **Accelerated constants.** `Rgamma_h` (accelerated Euler–Mascheroni) replaces naive harmonic series to avoid exponential denominator growth. `Rpi` bounded: `6/5 ≤ Rpi.seq n ≤ 7` (via arctanSum lemmas). `Rlog4pi ≤ 2.534`.
3. **Positive λ₁ assembly.** `Rlambda1 := 1 + ½·Rgamma_h − ½·Rlog4pic`. Positivity via `Pos_of_Rle_ofQ`: lower bound `1 + ½(0.577) − ½(2.534) = 0.003 > 0`.
4. **Remaining work is mechanical, not mathematical.** Steps 1–5 (Rpi → Rlogπc → Rlog4pic → Rlambda1 → Pos) are assembly over proven lemmas with all constants determined. The binding constraint is `γ₁` (currently bracketed an order of magnitude too loose), not `γ₂`.
5. **Kernel infeasibility is documented.** `LambdaOne.lean` records the computational wall: slow convergence of alternating ζ-series, explosive `lcm(1..n)` growth, kernel reduction infeasibility at the required precision for `n ≥ 2`.
6. **De-hedge and tag.** Every update to `RH_STATUS_LEDGER.md` reflects: `Li: BRIGHT LINE ANCHORED (Rlambda1 realized; Pos λ₁ proved with margin ~0.003; full sequence none/open)`.

## Consequences
- No `Pos λₙ` claim extends beyond `n = 1` without kernel verification.
- The Bright Line is a **protected constraint** on the representation: any future agent attempting bignum positivity proofs must pass through this boundary or escalate.
- The manuscript (`docs/F1SQUARE_FORMALIZATION.md` v1.4+) documents the positive `λ₁` anchor with pinned constants.
- The analytic face is now a **reliable pipeline** of anchored constructive constants (`Rgamma_h`, `Rlambda1`) rather than a source of drift.

## References
- `Prime/Prime Move_ Option 3 Confirmed.md` (Bright Line section)
- `Prime/F1Square Lean Formalization.md` (v0.15.3, v0.16.0, v0.19.0)
- `Analysis/LambdaOne.lean`, `Analysis/Gamma.lean`, `Analysis/LiOne.lean`
- `docs/adr/ADR-100-Conditional-Proof-Scaffold.md`
- `docs/adr/ADR-102-Missing-Object-Formalization.md`
