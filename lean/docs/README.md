# ADR Index

This directory contains the Architecture Decision Records (ADRs) for the Multiplicity project.

## ADR Registry

| ID | Title | Status | Document |
|---|---|---|---|
| ADR-0000 | Completion Report | Accepted | [ADR-0000-Completion-Report.md](ADR-0000-Completion-Report.md) |
| ADR-0001 | Multiplicity Foundations | Accepted | [ADR-0001-Multiplicity Foundations.md](ADR-0001-Multiplicity%20Foundations.md) |
| ADR-0002 | The Multiplicities of Multiplicity | Accepted | [ADR-0002-The Multiplicities of Multiplicity.md](ADR-0002-The%20Multiplicities%20of%20Multiplicity.md) |
| ADR-0003 | Ramanujan Multiplicity | Accepted | [ADR-0003-Ramanujan Multiplicity.md](ADR-0003-Ramanujan%20Multiplicity.md) |
| ADR-0004 | Euclid Multiplicity | Accepted | [ADR-0004-Euclid Multiplicity.md](ADR-0004-Euclid%20Multiplicity.md) |
| ADR-0005 | Gauss Multiplicity | Accepted | [ADR-0005-Gauss Multiplicity.md](ADR-0005-Gauss%20Multiplicity.md) |
| ADR-0006 | Dirichlet Multiplicity | Accepted | [ADR-0006-Dirichlet Multiplicity.md](ADR-0006-Dirichlet%20Multiplicity.md) |
| ADR-0007 | Riemann Multiplicity | Accepted | [ADR-0007-Riemann Multiplicity.md](ADR-0007-Riemann%20Multiplicity.md) |
| ADR-0008 | Ramanujan Bridge | Accepted | [ADR-0008-Ramanujan Bridge.md](ADR-0008-Ramanujan%20Bridge.md) |
| ADR-0009 | Kummer Multiplicity | Accepted | [ADR-0009-Kummer Multiplicity.md](ADR-0009-Kummer%20Multiplicity.md) |
| ADR-0010 | Dedekind Multiplicity | Accepted | [ADR-0010-Dedekind Multiplicity.md](ADR-0010-Dedekind%20Multiplicity.md) |
| ADR-0011 | Hardy-Littlewood Multiplicity | Accepted | [ADR-0011-Hardy-Littlewood Multiplicity.md](ADR-0011-Hardy-Littlewood%20Multiplicity.md) |
| ADR-0012 | Selberg Multiplicity | Accepted | [ADR-0012-Selberg Multiplicity.md](ADR-0012-Selberg%20Multiplicity.md) |
| ADR-0013 | Erdős Multiplicity | Accepted | [ADR-0013-Erdős Multiplicity.md](ADR-0013-Erd%C5%91s%20Multiplicity.md) |
| ADR-0014 | Serre Multiplicity | Accepted | [ADR-0014-Serre Multiplicity.md](ADR-0014-Serre%20Multiplicity.md) |
| ADR-0015 | Grothendieck Multiplicity | Accepted | [ADR-0015-Grothendieck Multiplicity.md](ADR-0015-Grothendieck%20Multiplicity.md) |
| ADR-0016 | Hund Multiplicity | Accepted | [ADR-0016-Hund Multiplicity.md](ADR-0016-Hund%20Multiplicity.md) |
| ADR-0017 | Dedekind Multiplicity Bridge | Accepted | [ADR-0017-Dedekind Multiplicity Bridge.md](ADR-0017-Dedekind%20Multiplicity%20Bridge.md) |
| ADR-0018 | Ramanujan Full Circle | Accepted | [ADR-0018-Ramanujan Full Circle.md](ADR-0018-Ramanujan%20Full%20Circle.md) |
| ADR-0019 | Terence Tao Multiplicity | Accepted | [ADR-0019-Terence Tao Multiplicity.md](ADR-0019-Terence%20Tao%20Multiplicity.md) |
| ADR-0020 | Mirror Symmetry | Accepted | [ADR-0020-Mirror Symmetry.md](ADR-0020-Mirror%20Symmetry.md) |
| ADR-0021 | HoTT/∞-Multiplicities | Accepted | [ADR-0021-HoTT∞‑Multiplicities.md](ADR-0021-HoTT%E2%88%9E%E2%80%8B-Multiplicities.md) |
| ADR-0022 | Quantum Multiplicity | Accepted | [ADR-0022-Quantum Multiplicity.md](ADR-0022-Quantum%20Multiplicity.md) |
| ADR-0023 | Neural Multiplicities | Accepted | [ADR-0023-Neural Multiplicities.md](ADR-0023-Neural%20Multiplicities.md) |
| ADR-0024 | 108-Cycle Multiplicity | Accepted | [ADR-0024-108-Cycle Multiplicity.md](ADR-0024-108-Cycle%20Multiplicity.md) |
| ADR-0025 | Multiplicity Stable Coin | Accepted | [ADR-0025-Multiplicity Stable Coin.md](ADR-0025-Multiplicity%20Stable%20Coin.md) |

## Genealogy Chain

```
Euclid → Euler → Gauss → Dirichlet → Riemann → Kummer → Hardy/Littlewood
→ Selberg → Erdős → Serre → Grothendieck → Hund → Dedekind → Ramanujan → Tao
```

## Phase 7 Status

| Criterion | Status |
|---|---|
| cargo test/vitest/npm run build in CI | ✅ Implemented |
| clippy -D warnings + fmt enforced | ✅ Passing |
| Cross-language chain/witness parity | ✅ Verified |
| Release artifacts + checksums | ✅ Implemented |
| Coverage ≥70% measured | ✅ 76-80% on core crates |
| scripts/e2e.sh | ✅ Implemented |

## Lean Formalizations

All ADRs have corresponding Lean 4 formalizations in:
- `lean/Multiplicity/dynamics/*.lean`
- `lean/ADR-System/ADR/Examples.lean`

## Rust Implementations

Key crates with coverage:
- `ramanujan-multiplicity`: 79.7%
- `multiplicity-core`: 76.0%
- `phase-mirror-agent`: 0.0% (3 tests, no lines hit)
