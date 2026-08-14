# ADR-088: Kronecker-Sum Type Extensions — PIRTM Dialect Phase 88

**Status:** Draft
**Date:** 2026-03-21
**Decision Authority:** Governance Committee / Constitutional Authority
**Parent:** ADR-087 (PM-2600)

## Purpose

Extend the `pirtm.module` type definition to carry the five new attributes required
to represent the Meta-Relativity universal operator `U = A ⊗ I ⊗ I + I ⊗ B ⊗ I + I ⊗ I ⊗ E`
within the PIRTM dialect. This gate establishes the type-system contract that all
later phases build on.

**Epic:** PM-2600
**Story:** PM-2601

## Mathematical Specification

The full module metadata in the Kronecker-sum picture is:

```
pirtm.module {
  // --- existing ADR-004/ADR-073 attributes ---
  prime_index  : integer           // index of the prime p ∈ P assigned to this module
  epsilon      : float             // Ξ-block contractivity bound (‖Ξ‖ ≤ epsilon)
  op_norm_T    : float             // operator norm ‖T‖ of the evolution step
                                   // L0: op_norm_T * epsilon < 1  (contractivity)

  // --- new Kronecker-sum attributes (ADR-088) ---
  sigma        : float             // prime-sector decay exponent σ; Dσ entries = p^{-σ}
                                   // σ > 0 required for summability of ℓ²(P)
  alpha        : float             // Gram kernel decay exponent α; HS requires α > 1/2
  xi_block_dim : integer           // dimension d of the Cᵈ internal block (defaults to 1)
  gap_lb       : float             // GapLB lower bound on spectral gap (certified at link time)
  slope_ub     : float             // SlopeUB upper bound on parametric slope (certified at link time)
}
```

### New L0 Invariants

| Attribute  | Verifier Rule                     | Error message |
|------------|-----------------------------------|---------------|
| `sigma`    | `sigma > 0`                       | `"sigma=%f must be positive (prime-sector decay requires σ > 0)"` |
| `alpha`    | `alpha > 0.5`                     | `"alpha=%f violates Hilbert-Schmidt condition (requires α > 1/2)"` |
| `xi_block_dim` | `xi_block_dim ≥ 1`           | `"xi_block_dim=%d must be ≥ 1"` |
| `gap_lb`   | `gap_lb > 0` at link time         | `"gap_lb=%f must be positive (spectral gap not certified)"` |
| `slope_ub` | `slope_ub < ∞` (finite positive)  | `"slope_ub=%f must be finite and positive"` |

These extend — never replace — the existing L0 invariants:
- `op_norm_T * epsilon < 1` (ADR-004)
- `prime_index` is prime (ADR-004 Miller-Rabin)

## Scope

### 1. TableGen TypeDef Extension (`pirtm.td`)

Add new `OptionalAttr` fields to the existing `PirtmModuleType`:

```tablegen
def PirtmModuleType : PirtmType<"Module", "module"> {
  let parameters = (ins
    // existing
    "int64_t":$prime_index,
    "double":$epsilon,
    "double":$op_norm_T,
    // new — ADR-088
    "double":$sigma,
    "double":$alpha,
    "int64_t":$xi_block_dim,
    "double":$gap_lb,         // 0.0 = unresolved at transpile time
    "double":$slope_ub        // 0.0 = unresolved at transpile time
  );
  let genVerifyDecl = 1;
  let assemblyFormat = [{
    `<` `mod=` $prime_index `,`
        `eps=` $epsilon `,`
        `T=` $op_norm_T `,`
        `sigma=` $sigma `,`
        `alpha=` $alpha `,`
        `d=` $xi_block_dim `>`
  }];
}
```

At **transpile time**: `gap_lb` and `slope_ub` are stored as `0.0` (unresolved).
At **link time**: `spectral-small-gain` pass fills them; verifier enforces `> 0`.

### 2. Verifier Implementation (`pirtm_types.cpp`)

Extend `PirtmModuleType::verify()`:

```cpp
// Existing checks (unchanged)
if (!isPrime(prime_index))
  return emitError() << "prime_index=" << prime_index
                     << " is not prime (" << factored(prime_index) << ")";
if (epsilon <= 0.0 || op_norm_T <= 0.0 || epsilon * op_norm_T >= 1.0)
  return emitError() << "contractivity violated: epsilon=" << epsilon
                     << " * op_norm_T=" << op_norm_T << " >= 1.0";

// New checks (ADR-088)
if (sigma <= 0.0)
  return emitError() << "sigma=" << sigma
                     << " must be positive (prime-sector decay requires σ > 0)";
if (alpha <= 0.5)
  return emitError() << "alpha=" << alpha
                     << " violates Hilbert-Schmidt condition (requires α > 1/2)";
if (xi_block_dim < 1)
  return emitError() << "xi_block_dim=" << xi_block_dim << " must be ≥ 1";
// gap_lb and slope_ub checked only at link time (may be 0.0 at transpile time)
```

### 3. TypeScript Interface Extension (`packages/pirtm-adapter/src/interfaces.ts`)

Extend `ModuleMetadata`:

```typescript
export interface ModuleMetadata {
  // existing
  primeIndex: number;
  epsilon: number;
  opNormT: number;
  proofHash: string;
  modulePath: string;

  // new — ADR-088 Kronecker-sum attributes
  sigma: number;         // σ > 0; default 1.0
  alpha: number;         // α > 0.5; default 0.8
  xiBlockDim: number;    // d ≥ 1; default 1
  gapLb: number;         // computed at link time; 0 = unresolved
  slopeUb: number;       // computed at link time; 0 = unresolved
}
```

Backward-compatible defaults:
```typescript
const KRONECKER_DEFAULTS = {
  sigma: 1.0,
  alpha: 0.8,
  xiBlockDim: 1,
  gapLb: 0,
  slopeUb: 0,
};
```

### 4. Validation Gate in `proof.ts`

Add `validateKroneckerAttr(meta: ModuleMetadata)`:

```typescript
export function validateKroneckerAttr(meta: ModuleMetadata): ValidationResult {
  const checks: ValidationCheck[] = [];

  checks.push({
    name: 'sigma-positive',
    passed: meta.sigma > 0,
    message: meta.sigma > 0
      ? `sigma=${meta.sigma} > 0 ✓`
      : `sigma=${meta.sigma} must be positive`,
  });

  checks.push({
    name: 'hs-condition',
    passed: meta.alpha > 0.5,
    message: meta.alpha > 0.5
      ? `alpha=${meta.alpha} > 0.5 (HS) ✓`
      : `alpha=${meta.alpha} violates Hilbert-Schmidt condition (α > 1/2 required)`,
  });

  checks.push({
    name: 'xi-block-dim',
    passed: meta.xiBlockDim >= 1,
    message: meta.xiBlockDim >= 1
      ? `xi_block_dim=${meta.xiBlockDim} ≥ 1 ✓`
      : `xi_block_dim=${meta.xiBlockDim} must be ≥ 1`,
  });

  const valid = checks.every(c => c.passed);
  return { valid, checks, reason: valid ? undefined : checks.find(c => !c.passed)?.message };
}
```

## Deliverables

1. `pirtm/dialect/pirtm.td` — PirtmModuleType with 5 new attributes.
2. `pirtm/dialect/pirtm_types.cpp` — Extended verifier with 3 new checks.
3. `packages/pirtm-adapter/src/interfaces.ts` — Extended `ModuleMetadata` type.
4. `packages/pirtm-adapter/src/proof.ts` — `validateKroneckerAttr()`.
5. `packages/pirtm-adapter/src/__tests__/kronecker.test.ts` — ≥ 20 unit tests.

## Test Cases (Required)

```
T1: alpha=0.3 → verifier rejects with "violates Hilbert-Schmidt"
T2: alpha=0.5 → verifier rejects (boundary: α > 1/2 is strict)
T3: alpha=0.51 → verifier accepts
T4: sigma=0.0 → verifier rejects "must be positive"
T5: sigma=-1.0 → verifier rejects
T6: sigma=0.3 → verifier accepts
T7: xi_block_dim=0 → verifier rejects
T8: xi_block_dim=1 → verifier accepts
T9: all defaults (sigma=1.0, alpha=0.8, d=1) → validateKroneckerAttr PASS
T10: existing contractivity gate still fires when epsilon*opNormT ≥ 1
```

## Exit Criteria

- [ ] `pirtm.module<mod=7, eps=0.5, T=0.8, sigma=1.0, alpha=0.8, d=1>` parses correctly
- [ ] `pirtm.module` with `alpha=0.3` emits `"violates Hilbert-Schmidt condition"`
- [ ] `validateKroneckerAttr` passes for valid defaults
- [ ] `validateKroneckerAttr` fails for `alpha ≤ 0.5` with correct message
- [ ] `ModuleMetadata` interface extended and backward-compatible
- [ ] 20+ passing unit tests

## Changelog

| Date       | Author  | Change                              |
|------------|---------|-------------------------------------|
| 2026-03-21 | Copilot | Created — PM-2601                   |
