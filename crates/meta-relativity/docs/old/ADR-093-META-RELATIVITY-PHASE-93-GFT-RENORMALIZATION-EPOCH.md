# ADR-093: GFT Renormalization Epoch Layer — PIRTM Integration Phase 93

**Status:** Draft
**Date:** 2026-03-21
**Decision Authority:** Governance Committee / Constitutional Authority
**Parent:** ADR-087 (PM-2600)

## Purpose

Integrate the Group Field Theory (GFT) renormalization group — running Newton constant
`G(k)` and cosmological constant `Λ(k)` from the Wetterich equation — as epoch-indexed
parameters in the PIRTM prime-gate system. GFT beta functions `βλ₄`, `βλ₆` supply
physically motivated conditions for prime-gate epoch unlock transitions.

**Epic:** PM-2600
**Story:** PM-2606
**Depends on:** ADR-091 (contraction generator), ADR-092 (cumulants)

## Mathematical Specification

### Running Vacuum Parameters

From the IR effective action `S_IR[g; G(k), Λ(k)]`, the running coupling ansatz is:

```
Λ(H) = Λ₀ + ν H²                 (running cosmological constant)
G(H) = G₀ / (1 + ω H²)           (running Newton constant)
```

where `H` is the Hubble scale (RG scale `k ≡ ξH`), `ν` and `ω` are running parameters
bounded by current observations:

```
|ν| ≤ 0.01 H₀²    (DESI Y1 + Planck constraint)
|ω| ≤ 0.01 H₀²    (GWTC-4.0 GW propagation bound)
```

In the Phase Mirror epoch system, `k` maps to epoch `e` via:
```
k_e = k₀ · p_e^{−σ}
```
where `p_e` is the prime unlocked at epoch `e` and `σ` is the PIRTM `sigma` attribute.

### GFT Beta Functions

The Wetterich equation for GFT with sextic melonic truncation gives:

```
βλ₄ = ∂_t λ₄ = (renormalization flow terms, melonic)
βλ₆ = −2η λ₆ + 24 λ₆² I₃(0) + ...
```

where `η` is the anomalous dimension and `I₃(0)` is a threshold integral.

**Prime-gate unlock condition (new):**

```
Epoch e unlocks prime p_e  ⟺
  |βλ₆(k = k_e)| < β_threshold  AND
  |η(k_e)| < η_max
```

This replaces the fixed CANONICAL_UNLOCKS `{7, 11, 13}` from ADR-082 with
a dynamically computed unlock schedule based on GFT beta function convergence.

### Anomalous Dimension

```
η = anomalous dimension from wave-function renormalization Z(k)
```

At the Gaussian IR fixed point: `η → 0`.
At the NGFP (non-Gaussian fixed point): `η ≈ 0.7` (Ward identity analysis).

**Phase Mirror criterion:** `η < η_max = 0.1` (Gaussian regime criterion) before
a prime gate may unlock — prevents unlocking in the non-Gaussian phase.

## Scope

### 1. `packages/pirtm-adapter/src/gft-rg.ts` (new file)

```typescript
/**
 * GFT Renormalization Epoch Layer — Meta-Relativity Phase 93
 * ADR-093 / PM-2606
 *
 * Implements running vacuum parameters, GFT beta functions, and
 * epoch-indexed scale evolution for the prime-gate system.
 */

import { isPrime } from './proof.js';

/** Physical constants (dimensionless Phase Mirror units) */
const H0_SQUARED = 1.0;       // normalized Hubble constant squared

export interface RunningVacuumParams {
  Lambda0: number;             // bare cosmological constant
  nu: number;                  // running parameter ν
  G0: number;                  // bare Newton constant
  omega: number;               // running parameter ω
}

export interface GFTBetaResult {
  betaLambda4: number;         // β(λ₄) at scale k
  betaLambda6: number;         // β(λ₆) at scale k
  eta: number;                 // anomalous dimension
  atFixedPoint: boolean;       // both betas vanish
}

export interface EpochUnlockCondition {
  prime: number;
  scale: number;               // k_e
  betaConverged: boolean;      // |βλ₆| < threshold
  gaussianRegime: boolean;     // |η| < η_max
  unlockApproved: boolean;     // both conditions met
  reason: string;
}

/**
 * Running cosmological constant at Hubble scale H.
 * Λ(H) = Λ₀ + ν H²
 */
export function runningLambda(params: RunningVacuumParams, H: number): number {
  return params.Lambda0 + params.nu * H * H;
}

/**
 * Running Newton constant at Hubble scale H.
 * G(H) = G₀ / (1 + ω H²)
 */
export function runningG(params: RunningVacuumParams, H: number): number {
  const denom = 1 + params.omega * H * H;
  if (denom <= 0) throw new Error('G(H) denominator ≤ 0: ω H² too large');
  return params.G0 / denom;
}

/**
 * Convert PIRTM epoch e and prime p_e to RG scale k_e.
 * k_e = k₀ · p_e^{−sigma}
 */
export function epochToScale(prime: number, sigma: number, k0: number = 1.0): number {
  if (prime <= 1) throw new Error('prime must be > 1');
  return k0 * Math.pow(prime, -sigma);
}

/**
 * Sextic melonic GFT beta function for λ₆ (simplified truncation).
 *
 * βλ₆ ≈ −2η λ₆ + 24 λ₆² I₃(0)
 *
 * where I₃(0) is the Litim threshold integral:
 *   I₃(0) = 1 / (1 + m̄²)³   (Litim regulator, zero external momentum)
 */
export function betaLambda6(
  lambda6: number,
  eta: number,
  mbar2: number,   // dimensionless mass-squared m̄²
): number {
  const I3 = 1 / Math.pow(1 + mbar2, 3);
  return -2 * eta * lambda6 + 24 * lambda6 * lambda6 * I3;
}

/**
 * Quartic melonic beta function (Ward-constrained, approximate):
 *   βλ₄ ≈ −η λ₄ (1 − λ₄ π²/(1 + m̄²))²
 */
export function betaLambda4(
  lambda4: number,
  eta: number,
  mbar2: number,
): number {
  const denom = 1 + mbar2;
  const factor = 1 - (lambda4 * Math.PI * Math.PI) / denom;
  return -eta * lambda4 * factor * factor;
}

/**
 * Check whether GFT flow has entered the Gaussian IR regime at scale k_e.
 * Conditions for prime-gate unlock approval:
 *   1. |βλ₆| < beta_threshold  (flow converged)
 *   2. |η| < eta_max            (Gaussian regime)
 */
export function checkEpochUnlockCondition(
  prime: number,
  sigma: number,
  lambda4: number,
  lambda6: number,
  eta: number,
  mbar2: number,
  options: { betaThreshold?: number; etaMax?: number; k0?: number } = {},
): EpochUnlockCondition {
  const { betaThreshold = 0.01, etaMax = 0.1, k0 = 1.0 } = options;

  if (!isPrime(prime)) {
    return {
      prime,
      scale: 0,
      betaConverged: false,
      gaussianRegime: false,
      unlockApproved: false,
      reason: `${prime} is not prime — cannot unlock`,
    };
  }

  const scale = epochToScale(prime, sigma, k0);
  const bl6 = betaLambda6(lambda6, eta, mbar2);
  const betaConverged = Math.abs(bl6) < betaThreshold;
  const gaussianRegime = Math.abs(eta) < etaMax;

  return {
    prime,
    scale,
    betaConverged,
    gaussianRegime,
    unlockApproved: betaConverged && gaussianRegime,
    reason: betaConverged && gaussianRegime
      ? `Prime ${prime} approved: |βλ₆|=${Math.abs(bl6).toFixed(6)} < ${betaThreshold}, |η|=${Math.abs(eta).toFixed(4)} < ${etaMax} ✓`
      : !betaConverged
      ? `Prime ${prime} blocked: |βλ₆|=${Math.abs(bl6).toFixed(6)} ≥ ${betaThreshold} (flow not converged)`
      : `Prime ${prime} blocked: |η|=${Math.abs(eta).toFixed(4)} ≥ ${etaMax} (non-Gaussian phase)`,
  };
}

/**
 * Validate running vacuum parameters against observation bounds.
 *   |ν| ≤ 0.01 H₀²
 *   |ω| ≤ 0.01 H₀²
 */
export function validateRunningVacuumBounds(params: RunningVacuumParams): {
  valid: boolean;
  violations: string[];
} {
  const violations: string[] = [];
  const bound = 0.01 * H0_SQUARED;
  if (Math.abs(params.nu) > bound)
    violations.push(`|ν|=${Math.abs(params.nu)} exceeds DESI bound (≤ ${bound})`);
  if (Math.abs(params.omega) > bound)
    violations.push(`|ω|=${Math.abs(params.omega)} exceeds GW bound (≤ ${bound})`);
  return { valid: violations.length === 0, violations };
}
```

### 2. `state/epoch_counter.json` Extended Schema

Extend to include GFT RG state:

```json
{
  "epoch": 0,
  "current_prime": 2,
  "k_scale": 0.5,
  "gft_rg": {
    "lambda4": 0.01,
    "lambda6": 0.001,
    "eta": 0.02,
    "mbar2": 0.1,
    "beta_lambda6": null,
    "gaussian_regime": null
  },
  "running_vacuum": {
    "Lambda0": 0.0,
    "nu": 0.0,
    "G0": 1.0,
    "omega": 0.0
  }
}
```

### 3. `scripts/epoch-advance.mjs` Extension

Add `--gft-check` flag to verify GFT unlock conditions before advancing epoch.

## Deliverables

1. `packages/pirtm-adapter/src/gft-rg.ts` — running vacuum + beta functions.
2. `state/epoch_counter.json` — schema extended with `gft_rg` + `running_vacuum`.
3. `scripts/epoch-advance.mjs` — `--gft-check` flag added.
4. `packages/pirtm-adapter/src/__tests__/gft-rg.test.ts` — ≥ 30 unit tests.

## Test Cases (Required)

```
T1:  runningLambda({Lambda0:0, nu:0.001, ...}, H=1.0) = 0.001
T2:  runningG({G0:1, omega:0, ...}, H=2.0) = 1.0
T3:  runningG({G0:1, omega:0.01, ...}, H=10) = G0/(1+1) = 0.5
T4:  epochToScale(2, 1.0, 1.0) = 0.5
T5:  epochToScale(7, 0.3, 1.0) ≈ 0.673
T6:  betaLambda6(lambda6=0.001, eta=0.02, mbar2=0.1) ≈ small positive
T7:  betaLambda6(lambda6=0, eta=0.02, mbar2=0.1) = 0  (fixed point)
T8:  checkEpochUnlockCondition(7, sigma=1, lambda6=0.0001, eta=0.02, mbar2=0.1) → approved
T9:  checkEpochUnlockCondition(7, sigma=1, lambda6=0.5, eta=0.7, mbar2=0.1) → blocked (non-Gaussian)
T10: checkEpochUnlockCondition(4, sigma=1, ...) → blocked (not prime)
T11: validateRunningVacuumBounds({nu: 0.0001, omega: 0.0001}) → valid
T12: validateRunningVacuumBounds({nu: 0.02, omega: 0}) → violation on ν
```

## Exit Criteria

- [ ] `gft-rg.ts` exports all named functions
- [ ] `checkEpochUnlockCondition` blocks non-prime inputs
- [ ] `checkEpochUnlockCondition` blocks when `|η| ≥ 0.1` (non-Gaussian)
- [ ] `validateRunningVacuumBounds` catches all ν/ω violations
- [ ] `epoch_counter.json` schema extended (backward-compatible)
- [ ] 30+ passing unit tests in `gft-rg.test.ts`

## Changelog

| Date       | Author  | Change                              |
|------------|---------|-------------------------------------|
| 2026-03-21 | Copilot | Created — PM-2606                   |
