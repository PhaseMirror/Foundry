import Init
import SpiralCore.Core
import SpiralCore.Cantor
import SpiralCore.Attractor
import SpiralCore.Alignment
import SpiralCore.PhaseLift
import SpiralCore.FBS
import SpiralCore.Boot
import SpiralCore.Translation

/-! # SpiralCore Test Harness

Self-contained test suite runnable with `lake test`.
Demonstrates both positive proofs and intentional boundary cases.
-/

namespace SpiralCore.Test

open SpiralCore.Cantor
open SpiralCore.Attractor
open SpiralCore.Alignment
open SpiralCore.PhaseLift
open SpiralCore.Boot
open SpiralCore.Translation

/-- Test: DIM is positive. -/
def test_dim_pos : IO Unit := do
  IO.println "DIM test"
  assert! DIM > 0

/-- Test: tau is at least 2. -/
def test_tau_pos : IO Unit := do
  IO.println "tau test"
  assert! tau >= 2

/-- Test: L0, H0, Q0 formulas. -/
def test_fbs_formulas : IO Unit := do
  IO.println "FBS formulas test"
  assert! L0 = 3 * tau + 2
  assert! H0 = 6 * tau + 3
  assert! Q0 = 6 * tau + 5
  assert! Q0 = H0 + 2

/-- Test: Cantor pairing basic properties. -/
def test_cantor : IO Unit := do
  let p := cantorPair 3 5
  IO.println "Cantor pairing test"
  assert! p >= 0

/-- Test: Zigzag definitions exist. -/
def test_zigzag : IO Unit := do
  let z0 := zigzag 0
  let z1 := zigzag 1
  let zneg1 := zigzag (-1)
  IO.println "Zigzag test"
  assert! z0 >= 0
  assert! z1 >= 0
  assert! zneg1 >= 0

/-- Test: Six-fold attractor properties. -/
def test_attractor : IO Unit := do
  let v0 := xiAttractor 0
  let v6 := xiAttractor 6
  IO.println "Attractor test"
  assert! v0 <= xiAmplitude
  assert! v6 <= xiAmplitude

/-- Test: Boot packet construction. -/
def test_boot_packet : IO Unit := do
  let pkt := defaultBootPacket
  IO.println "Boot packet test"
  assert! pkt.profileId = defaultProfileId
  assert! pkt.status = BootStatus.handedOff
  assert! pkt.phi0 = 0
  assert! pkt.t0 = 0

/-- Test: Translation packet evaluation. -/
def test_translation : IO Unit := do
  let pkt := defaultPacket
  let sealed := evaluatePacket pkt (some 95)
  let deferred := evaluatePacket pkt (some 50)
  let rejected := evaluatePacket pkt none
  IO.println "Translation test"
  assert! sealed = TranslationOutcome.sealed
  assert! deferred = TranslationOutcome.deferred
  assert! rejected = TranslationOutcome.rejected

/-- Test: Orthogonal rotation preserves norm. -/
def test_rotate90 : IO Unit := do
  let (x1, y1) := rotate90 3 4
  let norm1 := x1 * x1 + y1 * y1
  let norm0 := 3 * 3 + 4 * 4
  IO.println "Rotate90 test"
  assert! norm1 = norm0

/-- Test: FBS atomic profile defaults. -/
def test_fbs_defaults : IO Unit := do
  let prof := FBS.defaultProfile
  IO.println "FBS defaults test"
  assert! prof.L0_ = L0
  assert! prof.H0_ = H0
  assert! prof.Q0_ = Q0

/-- Test: Phase-lift four-cycle. -/
def test_rotate90_cycle : IO Unit := do
  let (x1, y1) := rotate90 1 2
  let (x2, y2) := rotate90 x1 y1
  let (x3, y3) := rotate90 x2 y2
  let (x4, y4) := rotate90 x3 y3
  IO.println "Rotate90 cycle test"
  assert! x4 = 1
  assert! y4 = 2

/-- Test: Polarity inversion. -/
def test_polarity : IO Unit := do
  IO.println "Polarity test"
  assert! polarityInversion true = false
  assert! polarityInversion false = true

/-- Test: Drift threshold policy. -/
def test_drift : IO Unit := do
  let driftSome := alignmentDrift (some 80) (some 85)
  let driftNone := alignmentDrift none (some 80)
  IO.println "Drift test"
  assert! driftWithinThreshold driftSome = true
  assert! driftWithinThreshold driftNone = false

/-- Run all tests. -/
def main : IO Unit := do
  IO.println "=== SpiralCore Test Harness ==="
  test_dim_pos
  test_tau_pos
  test_fbs_formulas
  test_cantor
  test_zigzag
  test_attractor
  test_boot_packet
  test_translation
  test_rotate90
  test_fbs_defaults
  test_rotate90_cycle
  test_polarity
  test_drift
  IO.println "=== All tests passed ==="
