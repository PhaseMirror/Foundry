# Haskell Proofs

Three compiler-enforced theorems. GHC 9.4.8.

## The Chain

```
thermal.hs → quantum_monad.hs → no_cloning.hs
```

1. `thermal.hs` — computes `Friction → ThermalWindow + sampleCount`
2. `quantum_monad.hs` — builds filtered superposition, collapses to temperature
3. `no_cloning.hs` — enforces single-use linearity on the collapsed temperature

## Files

### thermal.hs — ThermalEngine
**Innovation 3:** Mathematics belongs to the language whose compiler can prove it. TypeScript cannot prove `lo < hi`. Haskell can.

Key types:
- `Friction` (newtype, clamped `[0,1]` by smart constructor)
- `ThermalWindow { lo, hi, span }` (smart constructor ensures `lo < hi`)
- `ThermalMode = Cool | Warm | Hot`

Key functions:
- `computeThermalWindow :: Friction -> ThermalWindow` (proven: `lo < hi` for all valid `f`)
- `frictionEMA :: Friction -> Double -> Friction` (EMA decay, α=0.2)
- `thermalFeedbackLoop` (closes the FSM — the loop IS the architecture)

### quantum_monad.hs — Quantum Superposition Monad
**Innovation 1:** amplitude-weighted superposition of agent temperatures.

Key types:
- `QuantumAmplitude a` = `{ qaWeight :: Double, qaBranch :: a }`
- `QuantumSuperposition a` = `[QuantumAmplitude a]`

Key functions:
- `fromSamples :: [Word16] -> ThermalWindow -> QuantumSuperposition Double`
- `prune`, `renormalize` — remove destroyed branches
- `collapseMax :: QuantumSuperposition a -> Maybe a` (Born-rule collapse)
- `collapse :: QuantumSuperposition Double -> CollapseResult`

Vacuum state: all branches destroyed → `collapseMax = Nothing` → no decision.

### no_cloning.hs — No-Cloning Theorem (v2.0)
**LinearTypes GADT with constructor-level multiplicity.**

Key types:
- `QuantumPipelineState` (GADT):
  - `Superposed :: QuantumTemp %1 -> ...` — linear resource at constructor
  - `Collapsed :: Double -> ...` — classical, safe to read multiple times
  - `Destroyed` — terminal, no fields, no path back

Key functions:
- `superpose :: QuantumTemp %1 -> QuantumPipelineState` — consumes linearly
- `observe :: QuantumPipelineState %1 -> ObservationResult` — consumes linearly
- `destroyOnFail :: QuantumPipelineState %1 -> EREPassResult -> ...`
- `erePipeline` — 5 ERE passes chained linearly
- `noCloningProof :: QuantumTemp %1 -> ObservationResult` — compiler proof

```bash
# Verify no-cloning pipeline
echo -e "32767\n1\n1\n1\n1\n1" | runghc no_cloning.hs
```

## Build

```bash
# With cabal (uses DEVFLOW-FINANCE/bridges/bridges-haskell.cabal)
cabal build

# Or standalone (requires GHC 9.4.8)
runghc thermal.hs     # line 1: friction, line 2: score
runghc no_cloning.hs  # line 1: raw ANU, lines 2-6: pass results (1=pass)
```
