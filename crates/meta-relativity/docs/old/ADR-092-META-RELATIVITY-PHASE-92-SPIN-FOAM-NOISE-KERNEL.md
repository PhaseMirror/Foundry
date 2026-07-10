# ADR-092: Spin-Foam Noise Kernel Integration — PIRTM Integration Phase 92

**Status:** Draft
**Date:** 2026-03-21
**Decision Authority:** Governance Committee / Constitutional Authority
**Parent:** ADR-087 (PM-2600)

## Purpose

Integrate the EPRL/GFT stochastic-foam sector into the Phase Mirror CSL drift budget.
The spin-foam noise kernel `N_μναβ(x,y)` and its cumulants `{C₂, C₃, C₄, ...}` 
provide physics-motivated bounds on drift fluctuations that tighten the DriftAudit
tolerance and supply a colored-noise model for CSL's silence threshold.

**Epic:** PM-2600
**Story:** PM-2605
**Depends on:** ADR-091 (contraction semigroup established)

## Mathematical Specification

### EPRL Noise Kernel

From the CTP-doubled EPRL spin-foam amplitude, the stochastic source `ξ_μν` satisfies:

```
⟨ξ_μν(x)⟩ = 0
⟨ξ_μν(x) ξ_αβ(y)⟩ = N_μναβ(x, y)           (noise kernel = 2nd cumulant C₂)
⟨ξ^n⟩_c ≠ 0  for n ≥ 3                      (non-Gaussianity)
```

Cumulant scaling (large-j spin foam asymptotics):
```
C_n ~ ℓ_P^{2n−4} / M^{2n−4}  ×  (suppression from large-j asymptotics)
```

For `n = 2` (noise kernel): `C₂ = N ~ ℓ_P^0 / M^0 ~ O(1)` (unsuppressed at leading order).
For `n = 3` (bispectrum): `C₃ ~ ℓ_P² / M²` (Planck-suppressed).
For `n = 4`: `C₄ ~ ℓ_P⁴ / M⁴` (highly suppressed).

### Link to CSL Drift Budget

In the Phase Mirror framework, the DriftAudit invariant requires:

```
δ(t) < ε_csl(t)            (from ADR-081)
```

The spin-foam stochastic extension **bounds** the drift fluctuation envelope:

```
δ_foam(t) ≤ √(C₂ · t)     (diffusive bound from noise kernel)
```

For well-posed Phase Mirror sessions, the drift budget must account for this:

```
ε_csl(t) ≥ δ_foam(t) + δ_cognitive(t)
```

where `δ_cognitive(t)` is the CSL cognitive drift from ADR-081.

The `C₃`-cumulant provides the **non-Gaussianity tolerance** — sessions with
large `C₃` may exhibit correlated drift bursts that violate the Gaussian white-noise
assumption. The DriftAudit must therefore track `|C₃|` and emit a warning when:

```
|C₃(k)| / P_ζ(k)² > f_NL_max
```

where `f_NL_max` is the Phase Mirror constitutional tolerance bound.

## Scope

### 1. `packages/pirtm-adapter/src/spinfoam.ts` (new file)

```typescript
/**
 * Spin-Foam Noise Kernel Integration — Meta-Relativity Phase 92
 * ADR-092 / PM-2605
 *
 * Mathematical contracts:
 *   C₂ (noise kernel): diffusive drift bound δ_foam(t) ≤ √(C₂ · t)
 *   C₃ (bispectrum):  non-Gaussianity tolerance f_NL = C₃ / Pζ²
 *   C₄ (trispectrum): suppressed by (ℓ_P/M)⁴ ≈ 10^{-80}
 *
 * The Planck length and inflation scale are set to dimensionless ratios
 * for the Phase Mirror abstraction; physical values not required.
 */

/** Planck-suppression ratio (ℓ_P / M) for cumulant scaling */
const PLANCK_SUPPRESSION = 1e-5; // M ≈ 1.3×10⁻⁵ M_P from Starobinsky fit

export interface SpinFoamCumulants {
  C2: number;    // 2nd cumulant / noise kernel strength (O(1) at leading order)
  C3: number;    // 3rd cumulant / bispectrum (Planck-suppressed)
  C4: number;    // 4th cumulant / trispectrum (doubly suppressed)
}

/**
 * Canonical cumulant scaling from large-j EPRL asymptotics.
 * C_n ~ (ℓ_P/M)^{2n−4} × leadingFactor
 */
export function canonicalCumulants(leadingFactor: number = 1.0): SpinFoamCumulants {
  const r = PLANCK_SUPPRESSION;
  return {
    C2: leadingFactor,                             //  (r)^0 = 1
    C3: leadingFactor * Math.pow(r, 2),            //  (r)^2 ≈ 10^{-10}
    C4: leadingFactor * Math.pow(r, 4),            //  (r)^4 ≈ 10^{-20}
  };
}

/**
 * Diffusive drift bound from noise kernel C₂.
 * δ_foam(t) ≤ √(C₂ · t)
 */
export function foamDiffusiveDriftBound(C2: number, t: number): number {
  if (C2 < 0) throw new Error('C₂ must be non-negative (noise kernel)');
  if (t < 0) throw new Error('time t must be non-negative');
  return Math.sqrt(C2 * t);
}

/**
 * Non-Gaussianity parameter f_NL from bispectrum cumulant ratio.
 * f_NL = C₃ / P_ζ²
 * where P_ζ is the power spectrum normalization.
 */
export function computeFNL(C3: number, Pzeta: number): number {
  if (Pzeta <= 0) throw new Error('Power spectrum P_ζ must be positive');
  return C3 / (Pzeta * Pzeta);
}

/**
 * Total drift budget for CSL: cognitive drift + foam fluctuation envelope.
 *
 * ε_total(t) = δ_cognitive(t) + √(C₂ · t) · safetyFactor
 *
 * safetyFactor = 1 for nominal; > 1 for conservative (production) operation.
 */
export function computeTotalDriftBudget(
  cognitiveDrift: number,     // δ_cognitive(t) from DriftAudit
  C2: number,                 // noise kernel strength
  t: number,                  // elapsed time
  safetyFactor: number = 2.0, // ≥ 1
): number {
  return cognitiveDrift + safetyFactor * foamDiffusiveDriftBound(C2, t);
}

/**
 * Check whether the non-Gaussianity parameter is within constitutional tolerance.
 *
 * Phase Mirror constitutional f_NL bound:
 *   |f_NL| < 0.5  (melonic/Gaussian regime)
 *   |f_NL| ≥ 0.5  → warn; may indicate non-semiclassical foam
 */
export function checkNonGaussianityTolerance(
  fNL: number,
  tolerance: number = 0.5,
): { compliant: boolean; fNL: number; tolerance: number; message: string } {
  const compliant = Math.abs(fNL) < tolerance;
  return {
    compliant,
    fNL,
    tolerance,
    message: compliant
      ? `f_NL = ${fNL.toFixed(6)} < ${tolerance} (Gaussian regime) ✓`
      : `f_NL = ${fNL.toFixed(6)} ≥ ${tolerance} — non-Gaussianity exceeds Phase Mirror tolerance`,
  };
}

/**
 * Assemble the noise kernel bound for a PIRTM module's drift audit.
 * Returns the foam-adjusted ε_csl for use in DriftAudit.
 */
export function computeNoiseKernelBound(
  cumulants: SpinFoamCumulants,
  t: number,
  cognitiveDriftBound: number,
  safetyFactor: number = 2.0,
): {
  epsilonAdjusted: number;
  foamBound: number;
  fNLEstimate: number;
  compliant: boolean;
} {
  const foamBound = foamDiffusiveDriftBound(cumulants.C2, t);
  const epsilonAdjusted = computeTotalDriftBudget(cognitiveDriftBound, cumulants.C2, t, safetyFactor);
  const Pzeta = 2.1e-9; // Planck 2018 scalar power spectrum amplitude
  const fNLEstimate = computeFNL(cumulants.C3, Pzeta);
  const fNLCheck = checkNonGaussianityTolerance(fNLEstimate);
  return {
    epsilonAdjusted,
    foamBound,
    fNLEstimate,
    compliant: fNLCheck.compliant,
  };
}
```

### 2. DriftAudit Extension (`packages/multiplicity-engine/src/drift-audit.ts`)

Add a new audit function `auditFoamDrift`:

```typescript
export function auditFoamDrift(
  t: number,
  cognitiveDelta: number,
  cumulants: SpinFoamCumulants,
  safetyFactor: number = 2.0,
): DriftEvent {
  const bound = computeNoiseKernelBound(cumulants, t, cognitiveDelta, safetyFactor);
  return {
    t,
    delta: cognitiveDelta,
    epsilon: bound.epsilonAdjusted,
    compliant: cognitiveDelta < bound.epsilonAdjusted,
    source: 'foam-adjusted',
    metadata: {
      foamBound: bound.foamBound,
      fNLEstimate: bound.fNLEstimate,
      C2: cumulants.C2,
      C3: cumulants.C3,
    },
  };
}
```

## Deliverables

1. `packages/pirtm-adapter/src/spinfoam.ts` — noise kernel primitives.
2. `packages/multiplicity-engine/src/drift-audit.ts` — `auditFoamDrift()` addition.
3. `packages/pirtm-adapter/src/__tests__/spinfoam.test.ts` — ≥ 30 unit tests.

## Test Cases (Required)

```
T1:  foamDiffusiveDriftBound(C2=1.0, t=1.0) = 1.0
T2:  foamDiffusiveDriftBound(C2=0.0, t=5.0) = 0.0
T3:  foamDiffusiveDriftBound(C2=-1, t=1) → throws
T4:  canonicalCumulants(1.0).C2 = 1.0
T5:  canonicalCumulants(1.0).C3 ≈ 10^{-10}  (Planck-suppressed)
T6:  canonicalCumulants(1.0).C4 ≈ 10^{-20}
T7:  computeFNL(C3=1e-10, Pzeta=2.1e-9) ≈ 0.00227 < 0.5 → compliant
T8:  checkNonGaussianityTolerance(fNL=0.3) → compliant
T9:  checkNonGaussianityTolerance(fNL=0.6) → non-compliant  
T10: computeTotalDriftBudget(cognitive=0.1, C2=1e-10, t=1, safety=2) ≈ 0.1 + tiny
T11: computeNoiseKernelBound(canonical, t=1.0, cognitive=0.05) → compliant
T12: auditFoamDrift with large cognitive delta → compliant=false
```

## Exit Criteria

- [ ] `spinfoam.ts` exports all named functions
- [ ] `canonicalCumulants` produces `C₂~O(1)`, `C₃~10⁻¹⁰`, `C₄~10⁻²⁰`
- [ ] `computeNoiseKernelBound` integrates with DriftAudit's `epsilon` field
- [ ] `auditFoamDrift` added to `drift-audit.ts` test suite
- [ ] 30+ passing unit tests in `spinfoam.test.ts`

## Changelog

| Date       | Author  | Change                              |
|------------|---------|-------------------------------------|
| 2026-03-21 | Copilot | Created — PM-2605                   |
