# ADR-091: Dissipative Generator Certification (GapLB/SlopeUB) — PIRTM Integration Phase 91

**Status:** Draft
**Date:** 2026-03-21
**Decision Authority:** Governance Committee / Constitutional Authority
**Parent:** ADR-087 (PM-2600)

## Purpose

Implement the Meta-Relativity spectral certification bounds — `GapLB` (spectral gap
lower bound) and `SlopeUB` (parametric slope upper bound) — as certified attributes
on every PIRTM module, and implement the two dissipative generator theorems from the
paper as link-time gates.

**Epic:** PM-2600
**Story:** PM-2604
**Depends on:** ADR-088, ADR-089, ADR-090 (full `U = A + B + E` can be assembled)

## Mathematical Specification

### Certification Bounds (Theorem 8 from Meta-Relativity)

Given a parameterized perturbation budget `{wₚ, bₚ, Lₚ}` and unperturbed gap `δS`:

```
GapLB(w) ≥ inf_θ [δS(θ) − 2 Σ_p |wₚ| bₚ]
SlopeUB(w) ≤ Σ_p |wₚ| Lₚ
```

These are **conservative certified bounds**. They are computed once at link time and
stored in `pirtm.module.gap_lb` / `pirtm.module.slope_ub`.

**Interpretation in PIRTM:**
- `δS` = minimum eigenvalue gap of `A_N` (finite prime truncation)
- `bₚ` = operator norm bound on perturbation `Bₚ` for prime `p`
- `Lₚ` = Lipschitz bound on `∂_θ Bₚ`
- `wₚ` = weight vector (budget)
- `GapLB > 0` means the spectral gap is certified to be positive — PIRTM runs are
  safe from spectral collapse

### Dissipative Generator Theorems

**Theorem 9 (Positivity-Certified):**
If `K ≥ 0` (HS Gram, diagonal retained), `m(ω) ≥ 0` (Bochner), and `Ξ ≥ 0`:
```
U ≥ 0   ⟹   𝒜 = −U generates a uniformly continuous contraction semigroup e^{t𝒜}
```

**Theorem 10 (ACE-Style Dominance):**
Let `γ = inf_ω m(ω) + λ_min(E)`. If `γ ≥ ‖A‖`:
```
B + E ⪰ ‖A‖ I   ⟹   U ⪰ 0   ⟹   𝒜 = −U is a contraction generator
```

**Link to PIRTM contractivity:** The existing L0 invariant `ε · ‖T‖ < 1` is the
*instance-level* contractivity check. Theorem 9/10 are the *global generator-level*
contractivity checks — they certify that the PIRTM runtime is a contraction semigroup
over all time, not just for a single step.

## Scope

### 1. Extension to `spectral.ts`

Add the GapLB/SlopeUB computation functions:

```typescript
export interface PerturbationBudget {
  weights: Map<number, number>;      // primeIndex → wₚ
  normBounds: Map<number, number>;   // primeIndex → bₚ (‖Bₚ‖ bound)
  lipschitzBounds: Map<number, number>; // primeIndex → Lₚ
}

/**
 * Compute GapLB — certified lower bound on the spectral gap.
 *
 * GapLB = δS − 2 · Σ_p |wₚ| · bₚ
 *
 * where δS is the minimum gap in the unperturbed spectrum of A_N.
 */
export function computeGapLB(
  primes: number[],
  sigma: number,
  alpha: number,
  budget: PerturbationBudget,
): number {
  const A = buildPrimeSpectralBasis(primes, sigma, alpha);
  // Compute minimum gap: min eigenvalue of A (for N ≤ 50, use exact)
  // Use Gershgorin lower bound as proxy (conservative)
  const minDiag = Math.min(...primes.map(p => diagonalEntry(p, sigma)));
  const maxOffDiag = Math.max(
    ...primes.map((p, i) => {
      let offSum = 0;
      for (let j = 0; j < primes.length; j++) {
        if (j !== i) offSum += Math.abs(A[i][j]);
      }
      return offSum;
    }),
  );
  // Conservative gap: min(λ) ≥ minDiag − maxOffDiag
  const deltaS = Math.max(0, minDiag - maxOffDiag);

  let perturbationShift = 0;
  for (const [p, w] of budget.weights) {
    const b = budget.normBounds.get(p) ?? 0;
    perturbationShift += Math.abs(w) * b;
  }
  return deltaS - 2 * perturbationShift;
}

/**
 * Compute SlopeUB — certified upper bound on parametric slope.
 *
 * SlopeUB = Σ_p |wₚ| · Lₚ
 */
export function computeSlopeUB(budget: PerturbationBudget): number {
  let slope = 0;
  for (const [p, w] of budget.weights) {
    const L = budget.lipschitzBounds.get(p) ?? 0;
    slope += Math.abs(w) * L;
  }
  return slope;
}

/**
 * Verify Theorem 9 (positivity-certified generator):
 *   K ≥ 0 (HS Gram, diagonal retained) — always true by construction
 *   m(ω) ≥ 0 (Bochner positivity from time-sieve)
 *   Ξ ≥ 0 (internal block non-negative)
 */
export function verifyPositivityCertifiedGenerator(
  bochnerPositive: boolean,
  xiMinEigenvalue: number,  // min eigenvalue of internal block Ξ
): { certified: boolean; theorem: 'T9' | 'T10' | 'none'; message: string } {
  if (bochnerPositive && xiMinEigenvalue >= 0) {
    return {
      certified: true,
      theorem: 'T9',
      message: `Theorem 9: K ≥ 0 (HS Gram), m(ω) ≥ 0 (Bochner), Ξ ≥ 0 → 𝒜 = −U is contraction generator ✓`,
    };
  }
  return {
    certified: false,
    theorem: 'none',
    message: `Theorem 9 not satisfied: bochner=${bochnerPositive}, xiMin=${xiMinEigenvalue}`,
  };
}

/**
 * Verify Theorem 10 (ACE-style dominance):
 *   γ = inf m(ω) + λ_min(Ξ) ≥ ‖A‖
 */
export function verifyACEDominance(
  mMin: number,             // inf m(ω) from time-sieve
  xiMinEigenvalue: number,  // λ_min(Ξ)
  opNormA: number,          // ‖A‖ (prime-sector operator norm)
): { certified: boolean; theorem: 'T9' | 'T10' | 'none'; gamma: number; message: string } {
  const gamma = mMin + xiMinEigenvalue;
  const certified = gamma >= opNormA;
  return {
    certified,
    theorem: certified ? 'T10' : 'none',
    gamma,
    message: certified
      ? `Theorem 10: γ = m_min(${mMin}) + λ_min(Ξ)(${xiMinEigenvalue}) = ${gamma.toFixed(6)} ≥ ‖A‖=${opNormA.toFixed(6)} → ACE dominance ✓`
      : `Theorem 10 not satisfied: γ=${gamma.toFixed(6)} < ‖A‖=${opNormA.toFixed(6)}`,
  };
}
```

### 2. Link-Time Pass Integration

The `spectral-small-gain` pass (MLIR) should:
1. Assemble `A_N`, call `computeGapLB`, `computeSlopeUB`
2. Write `gap_lb` / `slope_ub` into the module attribute
3. Verify `gap_lb > 0`; emit error if not

TypeScript analog (for adapter layer):

```typescript
export function certifySpectralAttributes(
  meta: ModuleMetadata,
  primes: number[],
  budget: PerturbationBudget,
): { gapLb: number; slopeUb: number; valid: boolean; message: string } {
  const gapLb = computeGapLB(primes, meta.sigma, meta.alpha, budget);
  const slopeUb = computeSlopeUB(budget);
  const valid = gapLb > 0 && isFinite(slopeUb);
  return {
    gapLb,
    slopeUb,
    valid,
    message: valid
      ? `Spectral certification: GapLB=${gapLb.toFixed(6)} > 0, SlopeUB=${slopeUb.toFixed(6)} ✓`
      : `Spectral certification FAILED: GapLB=${gapLb.toFixed(6)} ≤ 0`,
  };
}
```

## Deliverables

1. `packages/pirtm-adapter/src/spectral.ts` — `computeGapLB`, `computeSlopeUB`,
   `verifyPositivityCertifiedGenerator`, `verifyACEDominance`, `certifySpectralAttributes`.
2. `packages/pirtm-adapter/src/proof.ts` — `validateDissipativeGenerator()` gate.
3. `packages/pirtm-adapter/src/__tests__/dissipative.test.ts` — ≥ 30 unit tests.
4. `docs/adr/ADR-091-spec-examples.md` — worked numerical example with exact values.

## Test Cases (Required)

```
T1:  computeGapLB([2,3,5], sigma=1.0, alpha=0.8, budget=zero) > 0
T2:  computeGapLB with large perturbation budget → can go negative (over-perturbed)
T3:  computeSlopeUB(budget with w={7:0.1}, L={7:0.5}) = 0.05
T4:  verifyPositivityCertifiedGenerator(bochner=true, xiMin=0) → T9 certified
T5:  verifyPositivityCertifiedGenerator(bochner=false, xiMin=0) → not certified
T6:  verifyACEDominance(mMin=0.12, xiMin=0, opNormA=0.10) → T10 certified
T7:  verifyACEDominance(mMin=0.05, xiMin=0, opNormA=0.20) → not certified (γ < ‖A‖)
T8:  certifySpectralAttributes(canonical meta, [2,3,5,7], small budget) → valid
T9:  GapLB monotone: larger perturbation budget → smaller GapLB
T10: SlopeUB = 0 when all Lₚ = 0 (no parametric variation)
```

## Exit Criteria

- [ ] `computeGapLB` returns a conservative (possibly negative) certified bound
- [ ] `certifySpectralAttributes` produces `gapLb > 0` for canonical parameters
- [ ] Theorem 9 and Theorem 10 checks return correct certified/uncertified classifications
- [ ] 30+ passing unit tests in `dissipative.test.ts`
- [ ] `meta.gapLb` and `meta.slopeUb` are populated after link-time certification

## Changelog

| Date       | Author  | Change                              |
|------------|---------|-------------------------------------|
| 2026-03-21 | Copilot | Created — PM-2604                   |
