# ADR-090: Time-Sieve Module (F⁻¹MₘF) — PIRTM Integration Phase 90

**Status:** Draft
**Date:** 2026-03-21
**Decision Authority:** Governance Committee / Constitutional Authority
**Parent:** ADR-087 (PM-2600)

## Purpose

Implement the time-sieve block `B = F⁻¹ Mₘ F` — the Fourier multiplier operator
on `L²(ℝ)` with prime-locked symbol `m(ω)` — as a named PIRTM session-graph attribute.
This block encodes temporal frequency structure using prime-harmonic clock resonances
and supplies the `[mMin, mMax]` band that enters GapLB computations.

**Epic:** PM-2600
**Story:** PM-2603
**Depends on:** ADR-088 (module type), ADR-089 (prime-spectral basis)

## Mathematical Specification

### Fourier Multiplier operator

```
B = F⁻¹ Mₘ F   on L²(ℝ)
```

where `F` is the unitary Fourier transform, `Mₘ` is multiplication by the real,
bounded symbol `m : ℝ → ℝ`, and:

```
m(ω) = a₀ + Σ_{p prime} aₚ · cos(ω · log p)
```

This is a **prime-locked Fourier symbol** — the harmonics are spaced logarithmically
at prime positions `{log 2, log 3, log 5, log 7, ...}`.

### Positivity Condition

`B ≥ 0` (as a bounded operator on `L²(ℝ)`) if and only if `m(ω) ≥ 0` for a.e. `ω`.

**Sufficient condition** (Bochner's theorem / cosine series):
```
a₀ ≥ Σ_p |aₚ|  ⟹  m(ω) ≥ 0  for all ω
```

When this holds, `U ≥ 0` and the generator `𝒜 = −U` is dissipative.

### Essential Spectrum

```
σ(B) = ess ran(m) = [m_min, m_max]
```

where:
```
m_min = a₀ − Σ_p |aₚ|   (achieved when cosines align at −1)
m_max = a₀ + Σ_p |aₚ|   (achieved when cosines align at +1)
```

These bounds contribute directly to `σess(U) = σ(A) + [m_min, m_max] + σ(E)`.

### Link to PIRTM Session Graph

Per ADR-004 L0 invariant #4:
> `pirtm.session_graph.gain_matrix` is **never** a transpile-time attribute.
> At transpile time it must be `#pirtm.unresolved_coupling`.

The time-sieve coefficients `{a₀, {aₚ}}` are **NOT** the gain matrix — they are
part of the module's frequency encoding and may be fixed at transpile time.
The resulting `[m_min, m_max]` band is resolved at link time by the
`spectral-small-gain` pass.

## Scope

### 1. `packages/pirtm-adapter/src/timesieve.ts` (new file)

```typescript
/**
 * Time-Sieve Module (F⁻¹MₘF) — Meta-Relativity temporal frequency layer
 * ADR-090 / PM-2603
 *
 * Mathematical contract:
 *   m(ω) = a₀ + Σ_{p prime} aₚ cos(ω log p)
 *   B ≥ 0  ⟺  a₀ ≥ Σ_p |aₚ|  (Bochner positivity)
 *   σ(B) = ess ran(m) = [m_min, m_max]
 */

export interface TimeSieveCoefficients {
  a0: number;                     // constant term
  ap: Map<number, number>;        // prime → aₚ coefficient
}

export interface TimeSieveBands {
  mMin: number;                   // a₀ − Σ|aₚ|
  mMax: number;                   // a₀ + Σ|aₚ|
  isPositive: boolean;            // mMin ≥ 0 (B ≥ 0)
  l1BudgetUsed: number;           // Σ|aₚ|
}

/**
 * Evaluate the prime-locked Fourier symbol at frequency ω.
 * m(ω) = a₀ + Σ_p aₚ cos(ω log p)
 */
export function evaluateSymbol(coeffs: TimeSieveCoefficients, omega: number): number {
  let val = coeffs.a0;
  for (const [p, ap] of coeffs.ap) {
    val += ap * Math.cos(omega * Math.log(p));
  }
  return val;
}

/**
 * Compute the essential spectrum band [m_min, m_max].
 * Uses the cosine-sum bound:
 *   m_min = a₀ − Σ|aₚ|
 *   m_max = a₀ + Σ|aₚ|
 */
export function computeEssentialBand(coeffs: TimeSieveCoefficients): TimeSieveBands {
  let l1 = 0;
  for (const ap of coeffs.ap.values()) l1 += Math.abs(ap);
  const mMin = coeffs.a0 - l1;
  const mMax = coeffs.a0 + l1;
  return {
    mMin,
    mMax,
    isPositive: mMin >= 0,
    l1BudgetUsed: l1,
  };
}

/**
 * Verify Bochner positivity condition: a₀ ≥ Σ|aₚ|
 * Sufficient for m(ω) ≥ 0 for all ω (hence B ≥ 0).
 */
export function verifyBochnerPositivity(coeffs: TimeSieveCoefficients): boolean {
  let l1 = 0;
  for (const ap of coeffs.ap.values()) l1 += Math.abs(ap);
  return coeffs.a0 >= l1;
}

/**
 * Sample m(ω) over a grid and find numerical [min, max].
 * More accurate than the analytic bound when harmonics partially cancel.
 */
export function sampleSymbolBands(
  coeffs: TimeSieveCoefficients,
  gridPoints: number = 2001,
  omegaRange: [number, number] = [-10, 10],
): { sampledMin: number; sampledMax: number } {
  const [lo, hi] = omegaRange;
  let sampledMin = Infinity;
  let sampledMax = -Infinity;
  for (let i = 0; i < gridPoints; i++) {
    const omega = lo + (i / (gridPoints - 1)) * (hi - lo);
    const v = evaluateSymbol(coeffs, omega);
    if (v < sampledMin) sampledMin = v;
    if (v > sampledMax) sampledMax = v;
  }
  return { sampledMin, sampledMax };
}

/**
 * Construct the canonical Prime-Mirror time-sieve from the paper's
 * statistical-mechanics exemplar:
 *   a₀ = 0.3, aₚ = 0.4 · p^{-2}
 * Verified: [m_min, m_max] ≈ [0.12, 0.48], B ≥ 0.
 */
export function canonicalPaperSieve(primes: number[]): TimeSieveCoefficients {
  const ap = new Map<number, number>();
  for (const p of primes) ap.set(p, 0.4 * Math.pow(p, -2));
  return { a0: 0.3, ap };
}
```

### 2. Session-Graph Attribute (`pirtm.td`)

Add to `pirtm.session_graph` op:

```tablegen
// Time-sieve band resolved at link time (unresolved = [0,0])
OptionalAttr<F64Attr>:$m_min,
OptionalAttr<F64Attr>:$m_max,
// Bochner positivity flag
OptionalAttr<BoolAttr>:$sieve_positive,
```

At transpile time: `m_min = m_max = 0.0` (unresolved).
At link time: `spectral-small-gain` pass fills these from the module's sieve coefficients.

### 3. Validation in `proof.ts`

```typescript
export function validateTimeSieve(
  coeffs: TimeSieveCoefficients,
): ValidationResult {
  const band = computeEssentialBand(coeffs);
  const bochner = verifyBochnerPositivity(coeffs);
  const checks: ValidationCheck[] = [
    {
      name: 'bochner-positivity',
      passed: bochner,
      message: bochner
        ? `Bochner: a₀=${coeffs.a0} ≥ Σ|aₚ|=${band.l1BudgetUsed.toFixed(6)} ✓`
        : `Bochner FAIL: a₀=${coeffs.a0} < Σ|aₚ|=${band.l1BudgetUsed.toFixed(6)}`,
    },
    {
      name: 'band-finite',
      passed: isFinite(band.mMin) && isFinite(band.mMax),
      message: isFinite(band.mMin)
        ? `band [${band.mMin.toFixed(4)}, ${band.mMax.toFixed(4)}] finite ✓`
        : 'band is non-finite',
    },
    {
      name: 'band-ordered',
      passed: band.mMin <= band.mMax,
      message: `m_min(${band.mMin}) ≤ m_max(${band.mMax})`,
    },
  ];
  const valid = checks.every(c => c.passed);
  return { valid, checks, reason: valid ? undefined : checks.find(c => !c.passed)?.message };
}
```

## Deliverables

1. `packages/pirtm-adapter/src/timesieve.ts` — time-sieve primitives.
2. `packages/pirtm-adapter/src/proof.ts` — `validateTimeSieve()` added.
3. `pirtm/dialect/pirtm.td` — `m_min`/`m_max`/`sieve_positive` session attrs.
4. `packages/pirtm-adapter/src/__tests__/timesieve.test.ts` — ≥ 30 unit tests.

## Test Cases (Required)

```
T1:  evaluateSymbol(canonical sieve, ω=0) = a₀ + Σaₚ = m_max ≈ 0.48
T2:  evaluateSymbol(canonical sieve, ω→∞) ≈ a₀ (cosines average to 0)
T3:  computeEssentialBand(canonical) → mMin ≈ 0.12, mMax ≈ 0.48
T4:  verifyBochnerPositivity(canonical) === true
T5:  verifyBochnerPositivity({a0: 0.1, ap: {2: 0.2}}) === false
T6:  sampleSymbolBands(canonical) should confirm sampled ≈ analytic bounds
T7:  validateTimeSieve(canonical) → PASS
T8:  validateTimeSieve({a0: 0.1, ap: new Map([[2, 0.2]])}) → FAIL Bochner
T9:  canonicalPaperSieve([2,3,5]) → a0=0.3, ap={2:0.1, 3:0.044, 5:0.016}
T10: m(ω) is continuous (evaluateSymbol ω→ω+δ changes by δ-small amount)
```

## Exit Criteria

- [ ] `timesieve.ts` exports all named functions above
- [ ] `canonicalPaperSieve` produces `mMin ≈ 0.12`, `mMax ≈ 0.48`
- [ ] `validateTimeSieve` integrates into `runPirtm` gate sequence
- [ ] 30+ passing unit tests in `timesieve.test.ts`
- [ ] Session-graph `m_min`/`m_max` attrs in TableGen (unresolved at transpile time)

## Changelog

| Date       | Author  | Change                              |
|------------|---------|-------------------------------------|
| 2026-03-21 | Copilot | Created — PM-2603                   |
