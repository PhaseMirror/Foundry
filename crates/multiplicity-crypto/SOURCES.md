# SOURCES.md

File provenance for `multiplicity-crypto/`.

## TypeScript — `ts/src/`

| Consolidated file | Original |
|-------------------|----------|
| `ts/src/qkd.ts` | `packages/agiOS/src/qkd.ts` |
| `ts/src/aead.ts` | `packages/agiOS/src/aead.ts` |
| `ts/src/keyderivation.ts` | `packages/agiOS/src/keyderivation.ts` |
| `ts/src/commitment.ts` | `packages/agiOS/src/commitment.ts` |
| `ts/src/transcript.ts` | `packages/agiOS/src/transcript.ts` |
| `ts/src/multiplicity.ts` | `packages/agiOS/src/multiplicity.ts` |
| `ts/src/frequency.ts` | `packages/agiOS/src/frequency.ts` |
| `ts/src/feedback.ts` | `packages/agiOS/src/feedback.ts` |
| `ts/src/__tests__/qkd-roundtrip.test.ts` | `packages/agiOS/src/__tests__/qkd-roundtrip.test.ts` |
| `ts/src/__tests__/adr-007-e2e-cryptographic-roundtrip.test.ts` | `packages/agiOS/src/__tests__/adr-007-e2e-cryptographic-roundtrip.test.ts` |

## Python — `py/multiplicity/`

| Consolidated file | Original |
|-------------------|----------|
| `py/multiplicity/__init__.py` | `packages/agiOS/src/multiplicity/__init__.py` (adjusted) |
| `py/multiplicity/crypto/__init__.py` | `packages/agiOS/src/multiplicity/crypto/__init__.py` (paths adjusted) |
| `py/multiplicity/math/__init__.py` | `packages/agiOS/src/multiplicity/math/__init__.py` (adjusted) |
| `py/multiplicity/math/core_math.py` | `packages/agiOS/src/multiplicity/math/core_math.py` |
| `py/multiplicity/math/cas_registry.py` | `packages/agiOS/src/multiplicity/math/cas_registry.py` |
| `py/multiplicity/mkt/__init__.py` | `packages/agiOS/src/multiplicity/mkt/__init__.py` |
| `py/multiplicity/mkt/mkt_commitment.py` | `packages/agiOS/src/multiplicity/mkt/mkt_commitment.py` |
| `py/multiplicity/cert/__init__.py` | `packages/agiOS/src/multiplicity/cert/__init__.py` |
| `py/multiplicity/cert/test_ace_crypto_integration.py` | `packages/agiOS/src/multiplicity/cert/test_ace_crypto_integration.py` |

## Rust — `rust/src/`

| Consolidated file | Original |
|-------------------|----------|
| `rust/src/transcript.rs` | `packages/agiOS/crates/prover/src/transcript.rs` |
| `rust/src/lib.rs` | New barrel module |
| `rust/Cargo.toml` | New minimal crate definition |

## Documentation — `docs/`

| Consolidated file | Original(s) |
|-------------------|----------|
| `docs/qkd-hybrid-encryption-v1.0-systems.md` | `packages/agiOS/src/multiplicity/library/articles/05-systems/cryptography/Qkd Hybrid Encryption V1.0.md` |
| `docs/qkd-hybrid-encryption-v1.0-case-studies.md` | `packages/agiOS/src/multiplicity/library/articles/03-case-studies/Qkd Hybrid Encryption V1.0.md` |

## Adjustments made during consolidation

- `py/multiplicity/crypto/__init__.py`: `TS_PACKAGE_DIR` path updated from `parents[3] / "crypto"` to `parents[3] / "ts"` so the bridge resolves the TypeScript sources in the new layout.
- `py/multiplicity/__init__.py`: top-level imports wrapped in `try/except` so the package loads gracefully when optional sub-modules are absent.
- `py/multiplicity/math/__init__.py`: `omega_operator` import removed (not part of this consolidation) and wrapped in safe fallback.
- `rust/src/lib.rs`: new barrel module added so the crate has an entry point.
