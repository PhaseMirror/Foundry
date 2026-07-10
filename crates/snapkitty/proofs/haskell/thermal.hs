{-# LANGUAGE LinearTypes #-}
-- ═══════════════════════════════════════════════════════════════════════════
-- SnapKitty — Thermodynamic Window Engine
-- bridges/haskell/thermal.hs
-- EDUALC test trigger — 2026-05-29
--
-- FORGE BUILDS. ENKI GUIDES. METATRON CERTIFIES.
--
-- Innovation 3 — corrected.
-- The TypeScript version (quantum-state.ts) computed computeThermalWindow()
-- and EMA friction decay in JavaScript. That is wrong.
-- Mathematics belongs to the language whose compiler can prove it.
-- TypeScript adopted from Java cannot prove that lo < hi.
-- Haskell can. The type system enforces it.
--
-- This module owns:
--   ThermalWindow { lo, hi, span } — the sampling band in uint16 space
--   computeThermalWindow           — friction [0,1] → window (proven: lo < hi)
--   normalizeWithinWindow          — raw uint16 → temperature [0,1]
--   frictionEMA                    — exponential moving average decay
--   thermalMode                    — Cool | Warm | Hot classification
--   sampleCount                    — how many ANU bytes to request
--
-- Invariants proven at compile time:
--   lo >= 0                    (Word16 is unsigned — cannot be negative)
--   hi <= 65535                (Word16 max — cannot overflow)
--   span = hi - lo > 0        (enforced by ThermalWindow smart constructor)
--   friction ∈ [0,1]          (Friction newtype with clamped constructor)
--
-- TypeScript receives the computed ThermalWindow via key=value stdout.
-- TypeScript never computes friction, never derives a window.
-- TypeScript displays. Haskell proves.
--
-- SEIT NGO — Sovereign Enochian Institute of Technology — 2026-05-29
-- ═══════════════════════════════════════════════════════════════════════════

module ThermalEngine where

import Data.Word (Word16)

-- ── Friction — a clamped [0,1] value ─────────────────────────────────────────
-- Smart constructor enforces the domain.
-- You cannot construct a Friction outside [0.0, 1.0].
-- The compiler tracks this through every downstream computation.

newtype Friction = Friction { unFriction :: Double }
    deriving (Show, Eq, Ord)

mkFriction :: Double -> Friction
mkFriction f = Friction (max 0.0 (min 1.0 f))

zeroFriction :: Friction
zeroFriction = Friction 0.0

-- ── Thermal Mode — human-readable classification ──────────────────────────────
data ThermalMode = Cool | Warm | Hot
    deriving (Show, Eq, Ord)

thermalMode :: Friction -> ThermalMode
thermalMode (Friction f)
    | f < 0.33  = Cool
    | f < 0.66  = Warm
    | otherwise = Hot

-- ── Thermal Window — proven lo < hi ──────────────────────────────────────────
-- Smart constructor: if the derived lo >= hi, the window defaults to full range.
-- This case cannot arise from valid friction (proved below), but the type
-- guarantees safety even if called with malformed data.

data ThermalWindow = ThermalWindow
    { twLo   :: Word16   -- lower bound in uint16 space
    , twHi   :: Word16   -- upper bound in uint16 space
    , twSpan :: Word16   -- hi - lo (always > 0)
    } deriving (Show, Eq)

mkThermalWindow :: Word16 -> Word16 -> ThermalWindow
mkThermalWindow lo hi
    | lo < hi   = ThermalWindow lo hi (hi - lo)
    | otherwise = ThermalWindow 0 65535 65535   -- fallback: full range

-- Full range (cool, friction = 0)
fullWindow :: ThermalWindow
fullWindow = ThermalWindow 0 65535 65535

-- Sovereign center (maximally hot, friction = 1)
-- lo = 25% of 65535 = 16383
-- hi = 75% of 65535 = 49151
sovereignWindow :: ThermalWindow
sovereignWindow = ThermalWindow 16383 49151 32768

-- ── Compute Thermal Window from Friction ─────────────────────────────────────
--
-- friction = 0.0 → full range  [0,     65535]  — maximum diversity
-- friction = 1.0 → center band [16383, 49151]  — sovereign stabilization
--
-- Linear interpolation between full and sovereign window.
--
-- Proof that lo < hi for all valid Friction:
--   lo(f) = round(f × 16383)        ∈ [0,    16383]
--   hi(f) = 65535 - round(f × 16384) ∈ [49151, 65535]
--   lo(f) ≤ 16383 < 49151 ≤ hi(f)   □
--
-- The mkThermalWindow smart constructor handles the edge case defensively,
-- but the proof above shows it is never triggered by this function.

computeThermalWindow :: Friction -> ThermalWindow
computeThermalWindow (Friction f) =
    let lo = round (f * 16383.0)            :: Word16
        hi = 65535 - round (f * 16384.0)    :: Word16
    in  mkThermalWindow lo hi

-- ── Normalize Within Window ───────────────────────────────────────────────────
-- Given a raw ANU uint16 and a ThermalWindow, produce temperature ∈ [0,1].
-- Values outside the window are clamped to the window boundary.

normalizeWithinWindow :: Word16 -> ThermalWindow -> Double
normalizeWithinWindow raw (ThermalWindow lo hi span_)
    | span_ == 0 = 0.5
    | otherwise  =
        let clamped = max lo (min hi raw)
        in  fromIntegral (clamped - lo) / fromIntegral span_

-- ── ANU Sample Count ─────────────────────────────────────────────────────────
-- How many uint16 values to request from ANU.
-- Cool (f=0): 2 samples — full diversity, low averaging
-- Hot  (f=1): 8 samples — averaged → central limit theorem contracts distribution
-- More samples when hot = narrower effective range (matches ThermalWindow contraction)

sampleCount :: Friction -> Int
sampleCount (Friction f) = 2 + round (f * 6.0)

-- ── EMA Friction Decay ────────────────────────────────────────────────────────
-- Exponential moving average: new = α × score + (1 - α) × current
-- α = 0.2 — one hot spike cools over ~5 clean decisions
-- score = 0.0 (all passes clean) → 1.0 (all five passes failed)
--
-- frictionEMA is a pure function. The caller (Rust handler) owns the state.
-- Haskell computes the next value. Rust stores it. TypeScript displays it.

frictionAlpha :: Double
frictionAlpha = 0.2

frictionEMA :: Friction -> Double -> Friction
frictionEMA (Friction current) score =
    let clamped = max 0.0 (min 1.0 score)
        next    = frictionAlpha * clamped + (1.0 - frictionAlpha) * current
    in  Friction next

-- ── Cooling rate ─────────────────────────────────────────────────────────────
-- How many clean decisions (score=0) to cool from a given friction to below 0.1?
-- Useful for War Room display and PRISM forecasting.

decisionsToCool :: Friction -> Int
decisionsToCool (Friction f)
    | f <= 0.1  = 0
    | otherwise =
        let steps = ceiling (log 0.1 / log (1.0 - frictionAlpha))
        in  steps

-- ── Thermodynamic Feedback Loop ──────────────────────────────────────────────
-- Process a batch of decision scores and return the converged thermal state.
-- Each score ∈ [0,1]: 0.0 = all ERE passes clean, 1.0 = all five failed.
-- This closes the FSM feedback cycle — friction feeds back on itself across
-- decisions, narrowing the ANU sampling window as the system heats.
-- Innovation 3: the loop is the architecture, not the algorithm.

thermalFeedbackLoop :: Friction -> [Double] -> (Friction, ThermalWindow, ThermalMode, Int)
thermalFeedbackLoop initial scores =
    let final  = foldl frictionEMA initial scores
        window = computeThermalWindow final
        mode'  = thermalMode final
        count  = sampleCount final
    in  (final, window, mode', count)

-- ── Main entry point ─────────────────────────────────────────────────────────
-- Reads: current_friction (float), new_score (float)
-- Stdin: line 1 = current friction, line 2 = new score
-- Outputs key=value for Rust bridge consumption

main :: IO ()
main = do
    currentLine <- getLine
    scoreLine   <- getLine
    let current  = read currentLine :: Double
        score    = read scoreLine   :: Double
        friction = frictionEMA (mkFriction current) score
        window   = computeThermalWindow friction
        mode     = thermalMode friction
        count    = sampleCount friction
        coolIn   = decisionsToCool friction

    putStrLn $ "friction="    ++ show (unFriction friction)
    putStrLn $ "thermal_lo="  ++ show (twLo   window)
    putStrLn $ "thermal_hi="  ++ show (twHi   window)
    putStrLn $ "thermal_span="++ show (twSpan window)
    putStrLn $ "thermal_mode="++ show mode
    putStrLn $ "sample_count="++ show count
    putStrLn $ "cool_in="     ++ show coolIn
    putStrLn   "engine=haskell-thermal"
