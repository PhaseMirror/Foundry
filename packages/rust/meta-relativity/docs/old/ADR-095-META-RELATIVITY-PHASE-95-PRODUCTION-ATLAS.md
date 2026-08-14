# ADR-095: Production Atlas & Frame Invariance — PIRTM Integration Phase 95

**Status:** Draft
**Date:** 2026-03-21
**Decision Authority:** Governance Committee / Constitutional Authority
**Parent:** ADR-087 (PM-2600)

## Purpose

Produce the final production-ready deliverables for the Meta-Relativity × Spin-Foam
PIRTM integration program:

1. **Operator Atlas** — complete mapping from `U = A⊗I + I⊗B + I⊗E` to PIRTM
   runtime attributes and JSON state fields.
2. **Frame Invariance Certification** — Theorem 13 formal test: spectral gap invariant
   under diagonal unitary conjugation.
3. **Ξ-Constitution Integration** — link Theorem 13 to Article I §1 spectral axiom.
4. **Analog Sovereignty Alignment** — confirm contractivity invariants satisfy the
   sovereignty constraint from `Ξ-Constitution.md`.
5. **Full 8-gate `xi-certify.mjs`** — gates G1–G8 complete, ADR-094 gates included.
6. **Operator Atlas Document** — `docs/adr/ADR-087-operator-atlas.md`.

**Epic:** PM-2600
**Story:** PM-2608
**Depends on:** ADR-088 through ADR-094

## Mathematical Specification

### Operator Atlas (U = A ⊗ I ⊗ I + I ⊗ B ⊗ I + I ⊗ I ⊗ E)

| Operator Component | Symbol | PIRTM Attribute | State Field |
|--------------------|--------|-----------------|-------------|
| Prime diagonal | Dσ, σ | `meta.sigma` | `epoch_counter.gft_rg.—` |
| Gram kernel | K_pq, α | `meta.alpha` | `xi_certification.spectral_cert.k_psd` |
| Prime-sector block | A = Dσ+K | `meta.opNormT` | `xi_certification.spectral_cert.gap_lb` |
| Time multiplier | m(ω) | `meta.sieve.mMin` / `mMax` | `xi_certification.spectral_cert.bochner_positive` |
| Fourier sieve | B = F⁻¹MₘF | ε·‖T‖ < 1 (L0) | `xi_certification.spectral_cert.ace_dominance` |
| Internal block | E = Ξ | `meta.xi_block_dim` | `xi_certification.xi_eigenvalue_min` |
| Spectral gap | GapLB | gate G7a | `xi_certification.spectral_cert.gap_lb` |
| Slope bound | SlopeUB | gate G7b/G7c | `xi_certification.spectral_cert.slope_ub` |
| ACE dominance | γ = mMin+λ_min(Ξ) | gate G7c | `xi_certification.spectral_cert.ace_dominance` |
| Frame invariance | Theorem 13 | gate G8 | `xi_certification.spectral_cert.frame_invariant` |
| Foam cumulants | C₂, C₃, C₄ | `meta.foam_cumulants` | `state/foam_drift.json` |
| Running G(k) | G(H) | `meta.running_G` | `epoch_counter.running_vacuum.G0, omega` |
| Running Λ(k) | Λ(H) | `meta.running_Lambda` | `epoch_counter.running_vacuum.Lambda0, nu` |
| GFT beta | βλ₆ | gate (epoch unlock) | `epoch_counter.gft_rg.beta_lambda6` |

### Theorem 13 (Spectral Invariance)

**Statement:** Let `D = diag(e^{iθₚ₁}, e^{iθₚ₂}, ..., e^{iθₚₙ})` be any diagonal
unitary on `ℓ²(P_N)`. Then:

```
σ(D A D†) = σ(A)
GapLB(D A D†) = GapLB(A)
```

**Proof sketch:** A is Hermitian. Conjugation by a unitary preserves eigenvalues
(`D A D† ∼ A` by similarity); thus all spectral gaps, spectral radii, and the Gershgorin
bounds derived from eigenvalues are preserved. □

**Certification test:** The Phase Mirror system certifies Theorem 13 numerically at 5
random diagonal unitaries on the prime set used at the current epoch.

### Ξ-Constitution Article I Integration

Article I §1 spectral axiom (from `Ξ-Constitution.md`):

> *The internal state of the Phase Mirror is a contraction semigroup generator; no
>  semigroup with spectral radius ≥ 1 may be admitted.*

Theorem 13 extends this axiom: **the contraction property (spectral radius < 1) is
frame-covariant** — it cannot be unlocked by a local phase rotation.

Formal cross-reference schema:

```json
{
  "xi_constitution_ref": "Article I §1",
  "theorem": "Theorem 13 (Spectral Invariance)",
  "adr": "ADR-095",
  "invariant": "spectral radius < 1 under all diagonal unitary conjugations",
  "certified": false
}
```

### Analog Sovereignty Constraint

From `contracts/analog_sovereignty.yaml` (governance invariant):

```yaml
sovereignty_constraint:
  mirror_must_not_yield:
    - spectral_radius_ge_1
    - contraction_broken
  certified_by: xi-certify.mjs Gates G1–G8
```

After this ADR lands, the certification chain G1–G8 is **the** machine-readable proof
that the Analog Sovereignty contract is satisfied for every admitted module.

## Scope

### 1. `docs/adr/ADR-087-operator-atlas.md` (new file)

Full operator atlas document with:
- Component decomposition table (above)
- Runtime attribute mapping diagram (ASCII art)
- Gate-to-theorem mapping table
- Prime-epoch schedule example (primers 2, 3, 5, 7, 11, 13)

### 2. `packages/pirtm-adapter/src/atlas.ts` (new file)

```typescript
/**
 * Operator Atlas — Meta-Relativity Phase 95
 * ADR-095 / PM-2608
 *
 * Provides the canonical attribute → mathematical-object mapping
 * and the Theorem 13 frame invariance test.
 */

import { ModuleMetadata } from './index.js';
import { SpectralCertResult } from './certify.js';

export interface OperatorAtlasEntry {
  symbol: string;
  description: string;
  pirtmAttr: string;
  stateField: string;
  gateId: string | null;
  theoremRef: string | null;
}

/**
 * Static operator atlas: maps every mathematical symbol to its PIRTM location.
 */
export const OPERATOR_ATLAS: readonly OperatorAtlasEntry[] = [
  { symbol: 'σ',    description: 'Prime-diagonal exponent',              pirtmAttr: 'sigma',           stateField: 'meta.sigma',                           gateId: 'G4', theoremRef: null },
  { symbol: 'α',    description: 'Gram-kernel HS exponent',              pirtmAttr: 'alpha',           stateField: 'meta.alpha',                           gateId: 'G4', theoremRef: null },
  { symbol: 'A',    description: 'Prime-sector block A = Dσ + K',       pirtmAttr: 'opNormT',         stateField: 'spectral_cert.gap_lb',                 gateId: 'G7a', theoremRef: 'Theorem 8' },
  { symbol: 'B',    description: 'Time-sieve B = F⁻¹MₘF',              pirtmAttr: 'sieve_mMin',      stateField: 'spectral_cert.bochner_positive',        gateId: 'G7b', theoremRef: 'Theorem 9' },
  { symbol: 'E=Ξ',  description: 'Internal dynamics block',              pirtmAttr: 'xi_block_dim',    stateField: 'xi_eigenvalue_min',                    gateId: 'G7b', theoremRef: 'Theorem 9' },
  { symbol: 'γ',    description: 'ACE dominance bound',                  pirtmAttr: 'ace_gamma',       stateField: 'spectral_cert.ace_dominance',          gateId: 'G7c', theoremRef: 'Theorem 10' },
  { symbol: 'C₂',   description: 'Gaussian foam cumulant',               pirtmAttr: 'foam_C2',         stateField: 'foam_drift.C2',                        gateId: 'G6', theoremRef: null },
  { symbol: 'G(H)', description: 'Running Newton constant',              pirtmAttr: 'running_G',       stateField: 'running_vacuum.G0',                    gateId: null, theoremRef: null },
  { symbol: 'Λ(H)', description: 'Running cosmological constant',        pirtmAttr: 'running_Lambda',  stateField: 'running_vacuum.Lambda0',               gateId: null, theoremRef: null },
  { symbol: 'βλ₆',  description: 'GFT sextic beta function',             pirtmAttr: 'beta_lambda6',    stateField: 'gft_rg.beta_lambda6',                  gateId: null, theoremRef: null },
  { symbol: 'Δ',    description: 'Spectral gap GapLB',                   pirtmAttr: 'gap_lb',          stateField: 'spectral_cert.gap_lb',                 gateId: 'G7a', theoremRef: 'Theorem 8' },
  { symbol: 'L',    description: 'Slope bound SlopeUB',                  pirtmAttr: 'slope_ub',        stateField: 'spectral_cert.slope_ub',               gateId: 'G7b', theoremRef: 'Theorem 8' },
] as const;

/**
 * Theorem 13 frame-invariance report for a completed certification.
 */
export interface FrameInvarianceReport {
  theorem: 'Theorem 13';
  certResult: Pick<SpectralCertResult, 'g8'>;
  xiConstitutionRef: 'Article I §1';
  analogSovereigntyRef: 'sovereignty_constraint.mirror_must_not_yield';
  certifiedAt: string | null;     // ISO timestamp
}

/**
 * Build the Theorem 13 attestation report from a completed certification.
 */
export function buildFrameInvarianceReport(
  certResult: SpectralCertResult,
): FrameInvarianceReport {
  return {
    theorem: 'Theorem 13',
    certResult: { g8: certResult.g8 },
    xiConstitutionRef: 'Article I §1',
    analogSovereigntyRef: 'sovereignty_constraint.mirror_must_not_yield',
    certifiedAt: certResult.g8.pass ? new Date().toISOString() : null,
  };
}

/**
 * Check that all OPERATOR_ATLAS entries have corresponding fields
 * in the provided metadata object (validation helper).
 */
export function validateAtlasCompleteness(
  meta: Record<string, unknown>,
  stateFields: Record<string, unknown>,
): { complete: boolean; missing: string[] } {
  const missing: string[] = [];
  for (const entry of OPERATOR_ATLAS) {
    if (entry.pirtmAttr && !(entry.pirtmAttr in meta) && !(entry.pirtmAttr in stateFields)) {
      missing.push(entry.symbol);
    }
  }
  return { complete: missing.length === 0, missing };
}
```

### 3. `scripts/xi-certify.mjs` — Final 8-Gate Version

The final gate sequence:

```javascript
async function runXiCertify(modulePath, options = {}) {
  // G1: Load artifacts
  const artifacts = await loadPirtmArtifacts(modulePath);
  // G2: Validate module
  await validatePirtmModule(artifacts.meta);
  // G3: Prime-index digest
  await computePrimeIndexDigest(artifacts.meta);
  // G4: Prime-spectral basis (ADR-089)
  await validatePrimeSpectralBasis(artifacts.meta);
  // G5: Time-sieve Bochner (ADR-090)
  await validateTimeSieve(artifacts.sieveCoeffs);
  // G6: Dissipative certification (ADR-091)
  await certifySpectralAttributes(artifacts.meta, primes, budget);
  // G7: Spectral certification (ADR-094)
  const certResult = await runSpectralCertification(certInput);
  if (!certResult.overall) throw new CertificationError(certResult.failedGates);
  // G8: Frame invariance (ADR-094)
  // (included in certResult.g8)

  // Write certification
  await writeXiCertification({
    ...certResult,
    theorem_certified: certResult.overall,
    certify_timestamp: new Date().toISOString(),
  });
}
```

## Deliverables

1. `docs/adr/ADR-087-operator-atlas.md` — static atlas document.
2. `packages/pirtm-adapter/src/atlas.ts` — runtime atlas + Theorem 13 report.
3. `scripts/xi-certify.mjs` — 8-gate final version.
4. `packages/pirtm-adapter/src/__tests__/atlas.test.ts` — ≥ 20 unit tests.

## Test Cases (Required)

```
T1:  OPERATOR_ATLAS has exactly 12 entries (one per mathematical symbol)
T2:  All entries with gateId have non-null theoremRef or null (only specific theorems referenced)
T3:  buildFrameInvarianceReport with pass=true → certifiedAt non-null ISO string
T4:  buildFrameInvarianceReport with pass=false → certifiedAt null
T5:  validateAtlasCompleteness all fields present → complete=true, missing=[]
T6:  validateAtlasCompleteness missing sigma → missing=['σ']
T7:  OPERATOR_ATLAS entry for 'E=Ξ' has gateId='G7b'
T8:  OPERATOR_ATLAS entry for 'γ' has theoremRef='Theorem 10'
T9:  OPERATOR_ATLAS entry for 'Δ' (GapLB) has gateId='G7a', theoremRef='Theorem 8'
T10: buildFrameInvarianceReport xiConstitutionRef = 'Article I §1'
```

## Exit Criteria

- [ ] `atlas.ts` exports `OPERATOR_ATLAS`, `buildFrameInvarianceReport`, `validateAtlasCompleteness`
- [ ] `ADR-087-operator-atlas.md` published under `docs/adr/`
- [ ] `xi-certify.mjs` runs all 8 gates in order
- [ ] `xi_certification.json` writes `theorem_certified: true` only when G8 passes
- [ ] 20+ passing unit tests in `atlas.test.ts`

## Program Completion Criteria (PM-2600)

The ADR-087 integration program is **complete** when all of the following are true:

1. ADR-088 transpiler-time type checks pass for `sigma`, `alpha`, `xi_block_dim`
2. ADR-089 `spectral.ts` PSD validation passes for all canonical test primes
3. ADR-090 `timesieve.ts` Bochner check passes for `canonicalPaperSieve`
4. ADR-091 `certifySpectralAttributes` passes for canonical perturbation budget
5. ADR-092 `checkNonGaussianityTolerance` green for `f_NL < 0.5`
6. ADR-093 `checkEpochUnlockCondition` gates epochs for `η < 0.1`
7. ADR-094 `runSpectralCertification` passes all 4 sub-gates G7a/b/c + G8
8. ADR-095 `validateAtlasCompleteness` returns `complete=true` for full metadata

## Changelog

| Date       | Author  | Change                              |
|------------|---------|-------------------------------------|
| 2026-03-21 | Copilot | Created — PM-2608                   |
