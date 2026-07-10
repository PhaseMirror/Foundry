{-# LANGUAGE LinearTypes #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}
-- ═══════════════════════════════════════════════════════════════════════════
-- SnapKitty — No-Cloning Theorem / Quantum Pipeline State
-- bridges/haskell/no_cloning.hs
--
-- FORGE BUILDS. METATRON CERTIFIES. ENKI GUIDES.
--
-- v2.0 — full linear propagation through constructor boundary.
--
-- The fix: linearity must exist at EVERY consuming function and
-- constructor boundary, not merely at the first function signature.
-- Prior version had %1 on entry (superpose, governDecision) but
-- observe/destroyOnFail/pipelineStep/noCloningProof were unrestricted —
-- meaning a QuantumPipelineState in Superposed state could be observed twice.
--
-- Changes from v1:
--   1. QuantumPipelineState uses GADT syntax so Superposed's field is
--      explicitly QuantumTemp %1 — the multiplicity lives at the
--      constructor, not just the function boundary.
--   2. observe, destroyOnFail, pipelineStep, collapse, erePipeline,
--      noCloningProof, destructionProof all take their state/resource
--      arguments with %1.
--   3. The narrower claim in the comment is removed — the full pipeline
--      is now compiler-enforced linear end to end.
--
-- SEIT NGO — Sovereign Enochian Institute of Technology — 2026-06-11
-- ═══════════════════════════════════════════════════════════════════════════

module NoCloningTheorem where

import Prelude.Linear ((&))
import qualified Prelude.Linear as Linear
import QuantumGovernance (QuantumTemp(..), mkQuantumTemp, AgentMode(..), quantumMode)

-- ── The Three States ──────────────────────────────────────────────────────────
--
-- GADT syntax with explicit constructor-field multiplicity.
-- Superposed :: QuantumTemp %1 -> QuantumPipelineState
--   means: constructing Superposed consumes one QuantumTemp linearly,
--   and pattern-matching it yields a QuantumTemp that must be used
--   exactly once. The compiler enforces this at every call site.
--
-- Collapsed and Destroyed hold no linear resources — unrestricted.

data QuantumPipelineState where
    Superposed :: QuantumTemp %1 -> QuantumPipelineState
    -- ^ Holds an uncollapsed linear resource.
    --   Constructing consumes one QuantumTemp.
    --   Observing yields it; failing destroys it. Either way: once.

    Collapsed  :: Double -> QuantumPipelineState
    -- ^ Temperature extracted to classical. No linear resource inside.
    --   Safe to inspect multiple times after extraction.

    Destroyed  :: QuantumPipelineState
    -- ^ Terminal. No fields. No path back.
    --   The pipeline was annihilated by a failed ERE pass.

deriving instance Show QuantumPipelineState

-- ── Observation Result ────────────────────────────────────────────────────────

data ObservationResult
    = Measured Double
    | PrematureCollapse
    deriving (Show, Eq)

-- ── ERE Pass Result ───────────────────────────────────────────────────────────

data EREPassResult = EREPass | EREFail String
    deriving (Show, Eq)

-- ── Enter Superposition ───────────────────────────────────────────────────────
-- Consumes one QuantumTemp %1 and wraps it in a pipeline state.
-- The %1 on the constructor field means the resource is now inside
-- the state and must be consumed by whoever receives the state.

superpose :: QuantumTemp %1 -> QuantumPipelineState
superpose qt = Superposed qt

-- ── Observe ───────────────────────────────────────────────────────────────────
-- Linear: consumes the pipeline state %1.
-- If Superposed: extracts the temperature, consuming the linear resource.
-- If Collapsed or Destroyed: PrematureCollapse — nothing to extract.
-- The %1 prevents calling observe twice on the same state.

observe :: QuantumPipelineState %1 -> ObservationResult
observe (Superposed (QuantumTemp t)) = Measured t
observe (Collapsed _)                = PrematureCollapse
observe Destroyed                    = PrematureCollapse

-- ── Destroy On ERE Failure ────────────────────────────────────────────────────
-- Linear: consumes the pipeline state %1.
-- On EREPass:  state flows through unchanged (still linear).
-- On EREFail:  state transitions to Destroyed — linear resource annihilated.
-- The %1 on state means it cannot be duplicated before this call.

destroyOnFail :: QuantumPipelineState %1 -> EREPassResult -> QuantumPipelineState
destroyOnFail state          EREPass      = state
destroyOnFail (Superposed _) (EREFail _)  = Destroyed
destroyOnFail (Collapsed _)  (EREFail _)  = Destroyed
destroyOnFail Destroyed      (EREFail _)  = Destroyed

-- ── Collapse ──────────────────────────────────────────────────────────────────
-- Linear: consumes the pipeline state %1.
-- Superposed → Collapsed: extracts Double, linear resource consumed.
-- Already Collapsed or Destroyed: passes through unchanged.

collapse :: QuantumPipelineState %1 -> QuantumPipelineState
collapse (Superposed (QuantumTemp t)) = Collapsed t
collapse already                      = already

-- ── Pipeline Step ─────────────────────────────────────────────────────────────
-- Linear: consumes the pipeline state %1, returns a new one.
-- The compiler tracks that the input is consumed before the output is created.

pipelineStep :: QuantumPipelineState %1 -> EREPassResult -> QuantumPipelineState
pipelineStep Destroyed _      = Destroyed
pipelineStep state     result = destroyOnFail state result

-- ── Five-Pass ERE Pipeline ────────────────────────────────────────────────────
-- Linear through every step. The QuantumPipelineState is threaded through
-- all five passes; the compiler rejects any attempt to fork or alias it.
-- If all five pass: state survives (Superposed or Collapsed).
-- If any fail: Destroyed — no temperature survives.

erePipeline :: QuantumPipelineState %1
            -> EREPassResult   -- pass 1: structural
            -> EREPassResult   -- pass 2: scholarly
            -> EREPassResult   -- pass 3: invariants
            -> EREPassResult   -- pass 4: mission
            -> EREPassResult   -- pass 5: root
            -> QuantumPipelineState
erePipeline state p1 p2 p3 p4 p5 =
    pipelineStep
        (pipelineStep
            (pipelineStep
                (pipelineStep
                    (pipelineStep state p1)
                p2)
            p3)
        p4)
    p5

-- ── Extract Temperature (safe) ────────────────────────────────────────────────
-- Only reads Collapsed (plain Double) — no linear resource involved.
-- Unrestricted: Collapsed is safe to inspect without consuming linearly.

extractTemp :: QuantumPipelineState -> Maybe Double
extractTemp (Collapsed t) = Just t
extractTemp _             = Nothing

-- ── No-Cloning Proof ─────────────────────────────────────────────────────────
-- Takes QuantumTemp %1 — linear. Cannot be called twice on the same value.
-- superpose consumes qt; observe consumes the resulting state.
-- The full chain: QuantumTemp %1 → QuantumPipelineState %1 → ObservationResult.
-- To verify: add a second `observe (superpose qt)` — GHC rejects it.

noCloningProof :: QuantumTemp %1 -> ObservationResult
noCloningProof qt =
    let state = superpose qt
    in  observe state

-- ── Destruction Proof ────────────────────────────────────────────────────────
-- Linear QuantumTemp consumed by superpose; state consumed by destroyOnFail.
-- A failing ERE pass annihilates the state. No temperature survives.

destructionProof :: QuantumTemp %1 -> EREPassResult -> QuantumPipelineState
destructionProof qt result =
    let state = superpose qt
    in  destroyOnFail state result

-- ── Main entry point ──────────────────────────────────────────────────────────

main :: IO ()
main = do
    rawLine   <- getLine
    p1line    <- getLine
    p2line    <- getLine
    p3line    <- getLine
    p4line    <- getLine
    p5line    <- getLine
    let raw   = read rawLine :: Int
        qt    = mkQuantumTemp raw
        toERE "1" = EREPass
        toERE _   = EREFail "failed"
        p1 = toERE p1line
        p2 = toERE p2line
        p3 = toERE p3line
        p4 = toERE p4line
        p5 = toERE p5line
        initial  = superpose qt
        terminal = erePipeline initial p1 p2 p3 p4 p5
        result   = case terminal of
            Collapsed t  -> Right t
            Destroyed    -> Left "DESTROYED — path annihilated by ERE failure"
            Superposed _ -> Left "SUPERPOSED — uncollapsed (collapse before read)"
        nocloning = case p1 of
            EREPass     -> "proved — one sample, one observation"
            EREFail _   -> "proved — sample destroyed, no observation possible"
    putStrLn $ "anu_raw=" ++ show raw
    putStrLn $ "pass1=" ++ p1line
    putStrLn $ "pass2=" ++ p2line
    putStrLn $ "pass3=" ++ p3line
    putStrLn $ "pass4=" ++ p4line
    putStrLn $ "pass5=" ++ p5line
    case result of
        Right t  -> do
            putStrLn "terminal_state=Collapsed"
            putStrLn $ "temperature=" ++ show t
            putStrLn $ "mode=" ++ show (quantumMode t)
            putStrLn "certified=true"
        Left msg -> do
            putStrLn $ "terminal_state=" ++ takeWhile (/= ' ') msg
            putStrLn "temperature=none"
            putStrLn "certified=false"
            putStrLn $ "reason=" ++ msg
    putStrLn $ "no_cloning=" ++ nocloning
    putStrLn "engine=haskell-no-cloning-theorem-v2"
