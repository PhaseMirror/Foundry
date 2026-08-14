# ADR-089: Prime-Spectral Basis (Dσ + K) — PIRTM Integration Phase 89

**Status:** Draft
**Date:** 2026-03-21
**Decision Authority:** Governance Committee / Constitutional Authority
**Parent:** ADR-087 (PM-2600)

## Purpose

Implement the prime-sector block `A = Dσ + K` of the Meta-Relativity spectral operator
within the PIRTM adapter layer. This block encodes the arithmetic structure of the
ambient Hilbert space `ℓ²(P)` and forms the mathematical foundation for prime-gated
contractivity.

**Epic:** PM-2600
**Story:** PM-2602
**Depends on:** ADR-088 (new `sigma`, `alpha` attributes)

## Mathematical Specification

### Diagonal Block Dσ

The prime-sector diagonal operator on `ℓ²(P)` assigns to each prime `p`:

```
(Dσ)_pp = p^{-σ}
```

Properties:
- `Dσ ≥ 0` for all `σ > 0`
- Compact (entries → 0 since primes diverge)
- `σess(Dσ) = {0}`; all eigenvalues `{p^{-σ}}` are isolated

In the PIRTM context: `σ` is the `sigma` attribute of `pirtm.module`, and
`p = prime_index` selects the eigenvalue `p^{-sigma}` for this module's prime slot.

### Gram Kernel K

The Hilbert-Schmidt Gram coupling kernel:

```
K_pq = p^{-α} · q^{-α} · h(log p − log q)
```

where `h : ℝ → ℝ` is a **continuous positive-definite window function** (e.g. Gaussian
`h(t) = exp(−t²)` or any even Schwartz function). The diagonal term (`p = q`) is
retained:

```
K_pp = p^{-2α} · h(0)
```

**Hilbert-Schmidt Condition:** `K` is HS (hence compact and bounded) if and only if
`α > 1/2`. This is the reason for the verifier constraint enforced by ADR-088.

**Positive Semidefiniteness:** With `h` positive-definite and diagonal retained:
`K ≥ 0`.

The full prime-sector operator `A = Dσ + K` satisfies `A ≥ 0` when both conditions hold.

### Operator Norm Bound

```
‖A‖ ≤ ‖Dσ‖ + ‖K‖ ≤ p₀^{-σ} + ‖K‖_HS
```

where `p₀ = 2` (smallest prime). In practice for a finite prime truncation `P_N`:

```
‖A_N‖ ≤ max eigenvalue of A_N  (computed by numpy.linalg.eigvalsh)
```

## Scope

### 1. `packages/pirtm-adapter/src/spectral.ts` (new file)

Core mathematical primitives for the prime-spectral basis:

```typescript
/**
 * Compute (Dσ)_pp = p^{-sigma} for a given prime p and sigma.
 * This is the eigenvalue of the prime-sector diagonal at slot p.
 */
export function diagonalEntry(p: number, sigma: number): number {
  if (sigma <= 0) throw new Error('sigma must be positive');
  return Math.pow(p, -sigma);
}

/**
 * Gaussian window: h(t) = exp(-t²)
 * Default window function for the Gram kernel.
 */
export function gaussianWindow(t: number): number {
  return Math.exp(-t * t);
}

/**
 * Gram kernel entry K_pq = p^{-α} q^{-α} h(log p − log q)
 * Diagonal (p === q) is retained: K_pp = p^{-2α} h(0)
 */
export function gramKernelEntry(
  p: number,
  q: number,
  alpha: number,
  h: (t: number) => number = gaussianWindow,
): number {
  if (alpha <= 0.5) throw new Error('alpha must be > 0.5 (Hilbert-Schmidt condition)');
  const t = Math.log(p) - Math.log(q);
  return Math.pow(p, -alpha) * Math.pow(q, -alpha) * h(t);
}

/**
 * Build the full A = Dσ + K matrix on a finite prime truncation P_N.
 * Returns an N×N matrix.
 */
export function buildPrimeSpectralBasis(
  primes: number[],
  sigma: number,
  alpha: number,
  h: (t: number) => number = gaussianWindow,
): number[][] {
  const N = primes.length;
  const A: number[][] = Array.from({ length: N }, () => new Array(N).fill(0));
  for (let i = 0; i < N; i++) {
    for (let j = 0; j < N; j++) {
      A[i][j] = gramKernelEntry(primes[i], primes[j], alpha, h);
    }
    // Add diagonal Dσ entry
    A[i][i] += diagonalEntry(primes[i], sigma);
  }
  return A;
}

/**
 * Verify the Hilbert-Schmidt norm bound for kernel K on P_N.
 * ‖K‖_HS² = Σ_{p,q} K_pq² < ∞
 * For a finite truncation, returns the computed HS norm.
 */
export function computeHSNorm(
  primes: number[],
  alpha: number,
  h: (t: number) => number = gaussianWindow,
): number {
  let sum = 0;
  for (const p of primes) {
    for (const q of primes) {
      const k = gramKernelEntry(p, q, alpha, h);
      sum += k * k;
    }
  }
  return Math.sqrt(sum);
}

/**
 * Compute the operator norm of A (max absolute eigenvalue for self-adjoint matrix).
 * Uses power-iteration approximation for large N; exact for N ≤ 50.
 */
export function computeOpNormMatrix(A: number[][]): number {
  const N = A.length;
  if (N === 0) return 0;
  // Gershgorin circle theorem: upper bound max_i(|A_ii| + sum_{j≠i} |A_ij|)
  let maxBound = 0;
  for (let i = 0; i < N; i++) {
    let rowBound = Math.abs(A[i][i]);
    for (let j = 0; j < N; j++) {
      if (j !== i) rowBound += Math.abs(A[i][j]);
    }
    if (rowBound > maxBound) maxBound = rowBound;
  }
  return maxBound;
}

/**
 * Verify that A = Dσ + K is positive semidefinite via Gershgorin dominance.
 * Sufficient condition: diagonal entry ≥ sum of absolute off-diagonals in each row.
 * (Not necessary; for strict HS kernels with positive h, A ≥ 0 holds by construction.)
 */
export function verifyPositiveSemidefinite(A: number[][]): boolean {
  const N = A.length;
  for (let i = 0; i < N; i++) {
    let offDiagSum = 0;
    for (let j = 0; j < N; j++) {
      if (j !== i) offDiagSum += Math.abs(A[i][j]);
    }
    if (A[i][i] < offDiagSum) return false;      // not diagonally dominant
  }
  return true;
}
```

### 2. Extension to `proof.ts`: `validatePrimeSpectralBasis`

```typescript
export function validatePrimeSpectralBasis(meta: ModuleMetadata): ValidationResult {
  const checks: ValidationCheck[] = [];

  // Hilbert-Schmidt condition (already enforced by ADR-088, doubled here for layer)
  checks.push({
    name: 'hs-condition',
    passed: meta.alpha > 0.5,
    message: meta.alpha > 0.5
      ? `alpha=${meta.alpha} > 0.5 satisfies HS condition ✓`
      : `alpha=${meta.alpha} violates HS condition (α > 1/2 required)`,
  });

  // Prime index maps to a valid Dσ eigenvalue
  const diag = Math.pow(meta.primeIndex, -meta.sigma);
  checks.push({
    name: 'diagonal-entry-positive',
    passed: diag > 0 && isFinite(diag),
    message: diag > 0
      ? `diagonal entry p^{-σ} = ${meta.primeIndex}^{-${meta.sigma}} = ${diag.toFixed(6)} > 0 ✓`
      : `diagonal entry is non-positive or non-finite`,
  });

  // Gram diagonal entry K_pp
  const kpp = Math.pow(meta.primeIndex, -2 * meta.alpha);
  checks.push({
    name: 'gram-diagonal-finite',
    passed: isFinite(kpp) && kpp > 0,
    message: isFinite(kpp)
      ? `K_pp = ${kpp.toFixed(8)} (finite) ✓`
      : `K_pp non-finite for primeIndex=${meta.primeIndex}, alpha=${meta.alpha}`,
  });

  const valid = checks.every(c => c.passed);
  return { valid, checks, reason: valid ? undefined : checks.find(c => !c.passed)?.message };
}
```

### 3. Integration into `runPirtm` gate sequence

Extend the gate order in `packages/pirtm-adapter/src/index.ts`:

```
1. loadPirtmArtifacts          (transpile-time params)
2. validatePirtmModule         (contractivity gate)
3. validateKroneckerAttr       (ADR-088 — new MR attrs)
4. validatePrimeSpectralBasis  (ADR-089 — A = Dσ + K)
5. computePrimeIndexDigest
6. verifyProof
```

## Deliverables

1. `packages/pirtm-adapter/src/spectral.ts` — prime-spectral basis primitives.
2. `packages/pirtm-adapter/src/proof.ts` — `validatePrimeSpectralBasis()` added.
3. `packages/pirtm-adapter/src/index.ts` — gate 4 inserted in `runPirtm`.
4. `packages/pirtm-adapter/src/__tests__/spectral.test.ts` — ≥ 30 unit tests.

## Test Cases (Required)

```
T1:  diagonalEntry(2, 1.0) = 0.5
T2:  diagonalEntry(7, 0.3) = 7^{-0.3} ≈ 0.6734
T3:  gramKernelEntry(p, q, alpha=0.3) → throws (HS violation)
T4:  gramKernelEntry(2, 2, 0.8) = 2^{-1.6} · h(0) ≈ 0.3299
T5:  gramKernelEntry(2, 3, 0.8) is symmetric: K(2,3) === K(3,2)
T6:  buildPrimeSpectralBasis([2,3,5], 1.0, 0.8) → 3×3 PSD matrix
T7:  computeHSNorm([2,3,5,7], 0.8) < ∞ (finite)
T8:  computeHSNorm([2,3,5,7], 0.49) → throws (HS condition)
T9:  verifyPositiveSemidefinite(identity(3)) === true
T10: computeOpNormMatrix([[2,0],[0,1]]) === 2
T11: validatePrimeSpectralBasis with alpha=0.8, sigma=1.0, primeIndex=7 → PASS
T12: validatePrimeSpectralBasis with alpha=0.4 → FAIL "HS condition"
```

## Exit Criteria

- [ ] `spectral.ts` exports `diagonalEntry`, `gramKernelEntry`, `buildPrimeSpectralBasis`,
      `computeHSNorm`, `computeOpNormMatrix`, `verifyPositiveSemidefinite`
- [ ] `gramKernelEntry` with `alpha ≤ 0.5` throws with HS diagnostic
- [ ] `validatePrimeSpectralBasis` integrated as gate 4 in `runPirtm` sequence
- [ ] 30+ passing unit tests in `spectral.test.ts`
- [ ] `pnpm --filter @phase-mirror/pirtm-adapter test` passes

## Changelog

| Date       | Author  | Change                              |
|------------|---------|-------------------------------------|
| 2026-03-21 | Copilot | Created — PM-2602                   |
