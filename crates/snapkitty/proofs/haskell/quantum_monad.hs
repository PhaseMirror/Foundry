-- ═══════════════════════════════════════════════════════════════════════════
-- SnapKitty — Quantum Monad
-- bridges/haskell/quantum_monad.hs
--
-- FORGE BUILDS. ENKI GUIDES. METATRON CERTIFIES.
--
-- Innovation 1: amplitude-weighted superposition of agent temperatures.
--
-- The quantum monad holds a VECTOR of possible temperatures simultaneously.
-- Each branch has a weight (probability amplitude squared — Born rule).
-- Binding (>>=) distributes computation across all branches in parallel.
-- ThermalWindow (from thermal.hs) filters which ANU samples enter the
-- superposition — hot friction narrows the window, reducing branch count.
-- Born-rule collapse: the highest-weight surviving branch becomes the decision.
--
-- Chain: thermal_loop → quantum_monad → no_cloning_theorem
--   thermal.hs      computes Friction → ThermalWindow + sampleCount
--   quantum_monad   builds filtered superposition, collapses to temperature
--   no_cloning.hs   enforces single-use linearity on the collapsed temperature
--
-- Vacuum state: if all ANU samples fall outside the ThermalWindow, the
-- superposition is empty. No temperature is produced. The decision is aborted.
-- This is the thermodynamic equivalent of the no-cloning Destroyed state.
--
-- SEIT NGO — Sovereign Enochian Institute of Technology — 2026-05-30
-- ═══════════════════════════════════════════════════════════════════════════

module QuantumMonad where

import Data.List (maximumBy)
import Data.Ord (comparing)
import Data.Word (Word16)
import ThermalEngine
    ( ThermalWindow(..)
    , Friction(..)
    , computeThermalWindow
    , normalizeWithinWindow
    )
import QuantumGovernance (AgentMode(..), quantumMode)

-- ── Quantum Amplitude ─────────────────────────────────────────────────────────
-- A single weighted branch in the superposition.
-- weight = probability amplitude (Born rule: probability ∝ weight)

data QuantumAmplitude a = QuantumAmplitude
    { qaWeight :: Double
    , qaBranch :: a
    } deriving (Show)

-- ── Quantum Superposition ─────────────────────────────────────────────────────
-- A vector of weighted branches representing simultaneous possibilities.
-- [] is the vacuum state — no possibilities survived filtering or ERE passes.

newtype QuantumSuperposition a = QuantumSuperposition
    { qsBranches :: [QuantumAmplitude a] }
    deriving (Show)

-- The Functor maps over branch values, preserving weights.
instance Functor QuantumSuperposition where
    fmap f (QuantumSuperposition bs) =
        QuantumSuperposition (map (\qa -> qa { qaBranch = f (qaBranch qa) }) bs)

-- pure wraps a single classical value as a unit-weight branch.
-- <*> is the outer product: every function branch applied to every value branch.
instance Applicative QuantumSuperposition where
    pure x = QuantumSuperposition [QuantumAmplitude 1.0 x]
    (QuantumSuperposition fs) <*> (QuantumSuperposition xs) =
        QuantumSuperposition
            [ QuantumAmplitude (wf * wx) (f x)
            | QuantumAmplitude wf f <- fs
            , QuantumAmplitude wx x <- xs
            ]

-- >>= distributes f across all branches; inner weights are scaled by outer weight.
-- This is the quantum parallel evaluation: every branch is evaluated,
-- every result is weighted by the product of parent and child amplitudes.
instance Monad QuantumSuperposition where
    return = pure
    (QuantumSuperposition bs) >>= f =
        QuantumSuperposition
            [ QuantumAmplitude (w * w') v
            | QuantumAmplitude w  x  <- bs
            , QuantumAmplitude w' v  <- qsBranches (f x)
            ]

-- ── Build Superposition from ANU Samples ─────────────────────────────────────
-- Create a uniform superposition from raw ANU uint16 samples.
-- Samples outside the ThermalWindow are excluded (the window is the prior).
-- Surviving samples receive equal weight: 1/n (maximum entropy within window).

fromSamples :: [Word16] -> ThermalWindow -> QuantumSuperposition Double
fromSamples raws tw =
    let valid = filter (\r -> r >= twLo tw && r <= twHi tw) raws
        n     = length valid
    in  case n of
            0 -> QuantumSuperposition []
            _ -> let w = 1.0 / fromIntegral n
                 in  QuantumSuperposition
                         [ QuantumAmplitude w (normalizeWithinWindow raw tw)
                         | raw <- valid
                         ]

-- ── Prune and Renormalize ─────────────────────────────────────────────────────
-- Remove zero-weight branches (destroyed by ERE failure via >>=).
-- Renormalize so surviving weights sum to 1 (valid probability distribution).

prune :: QuantumSuperposition a -> QuantumSuperposition a
prune (QuantumSuperposition bs) =
    QuantumSuperposition (filter (\qa -> qaWeight qa > 0.0) bs)

renormalize :: QuantumSuperposition a -> QuantumSuperposition a
renormalize (QuantumSuperposition []) = QuantumSuperposition []
renormalize (QuantumSuperposition bs) =
    let total = sum (map qaWeight bs)
    in  if total <= 0.0
        then QuantumSuperposition []
        else QuantumSuperposition (map (\qa -> qa { qaWeight = qaWeight qa / total }) bs)

-- ── Born-Rule Collapse ────────────────────────────────────────────────────────
-- The branch with the highest amplitude wins.
-- This is the single observation that produces the agent's temperature.
-- Vacuum state collapses to Nothing — no decision is possible.

collapseMax :: QuantumSuperposition a -> Maybe a
collapseMax (QuantumSuperposition []) = Nothing
collapseMax (QuantumSuperposition bs) = Just . qaBranch $ maximumBy (comparing qaWeight) bs

-- ── Collapse Result ───────────────────────────────────────────────────────────
data CollapseResult = CollapseResult
    { crBranchCount    :: Int
    , crDominantTemp   :: Maybe Double
    , crDominantMode   :: Maybe AgentMode
    , crTotalAmplitude :: Double
    , crIsVacuum       :: Bool
    } deriving (Show)

collapse :: QuantumSuperposition Double -> CollapseResult
collapse qs@(QuantumSuperposition bs) =
    let dominant = collapseMax qs
    in  CollapseResult
            { crBranchCount    = length bs
            , crDominantTemp   = dominant
            , crDominantMode   = fmap quantumMode dominant
            , crTotalAmplitude = sum (map qaWeight bs)
            , crIsVacuum       = null bs
            }

-- ── Main entry point ──────────────────────────────────────────────────────────
-- Stdin:
--   Line 1: current friction (float, 0.0–1.0)
--   Line 2: space-separated ANU uint16 raw samples
-- Computes ThermalWindow from friction, builds filtered superposition,
-- renormalizes, collapses to dominant temperature.
-- Outputs key=value for Rust bridge.

main :: IO ()
main = do
    frictionLine <- getLine
    samplesLine  <- getLine
    let f       = read frictionLine :: Double
        tw      = computeThermalWindow (Friction f)
        rawInts = map read (words samplesLine) :: [Int]
        raws    = map fromIntegral rawInts :: [Word16]
        qs      = fromSamples raws tw
        normed  = renormalize (prune qs)
        result  = collapse normed
    putStrLn $ "branch_count="    ++ show (crBranchCount result)
    putStrLn $ "total_amplitude=" ++ show (crTotalAmplitude result)
    putStrLn $ "is_vacuum="       ++ if crIsVacuum result then "true" else "false"
    case crDominantTemp result of
        Nothing -> do
            putStrLn "dominant_temp=none"
            putStrLn "dominant_mode=none"
        Just t  -> do
            putStrLn $ "dominant_temp=" ++ show t
            putStrLn $ "dominant_mode=" ++ show (quantumMode t)
    putStrLn "engine=haskell-quantum-monad"
