# RESONANCE-CORE

Ahmad's math engine for the SnapKitty Sovereign OS. Pure functions, zero dependencies, compiler-proven invariants.

## Structure

```
resonance-core/
├── config/math_constants.yaml   — all constants (physical, thermal, quantum, ERE, borrow chain)
├── docs/math/                   — LaTeX formal specifications
│   ├── 01-entropy.tex           — Shannon & Von Neumann entropy
│   ├── 02-quantum-monad.tex     — Quantum monad, Watchtowers, METATRON
│   ├── 03-thermal.tex           — Thermodynamic window engine (proven lo < hi)
│   ├── 04-borrow-chain.tex      — Linear type theory, verdict algebra
│   └── 05-ere-scoring.tex       — 5-pass ERE verification mathematics
├── lib/math/                    — Pure ESM implementations
│   ├── entropy.mjs              — Shannon entropy, KL divergence, cross-entropy
│   ├── quantum.mjs              — Superposition, bind, Born collapse, 49th Call
│   ├── thermal.mjs              — EMA friction decay, thermal window, Boltzmann
│   ├── ere.mjs                  — 5-pass ERE scoring, Watchtower search orders
│   ├── borrow-chain.mjs         — Verdict algebra, WORM invariants, JIT/Cap validation
│   └── index.mjs                — barrel export
└── tests/fixtures/              — JSON test fixtures
```

## The Core Chain

```
thermal.hs → quantum_monad.hs → no_cloning.hs
friction  → ThermalWindow → filtered ANU superposition → Born collapse
```

- Haskell owns proof-level math (compiler-enforced invariants, LinearTypes)
- This package implements the same math in pure JS for browser/Node/edge use
- TypeScript displays. Haskell proves. JavaScript bridges.

## The 49th Call

`call_49(X) = reverse(X)` — one operation, three languages, one truth:

| Language | Year | Expression |
|----------|------|------------|
| APL      | 1962 | `⌽X` |
| Prolog   | 1972 | `call_49(X, Y) :- reverse(X, Y).` |
| Haskell  | 1990 | `call49 = reverse` |

Mirror identity: `call_49(call_49(X)) = X`

## METATRON Certification

All five ERE passes must succeed. Weighted watchtower majority (≥ 0.5) required for METATRON to certify.

## License

Sovereign Source License v1.0
