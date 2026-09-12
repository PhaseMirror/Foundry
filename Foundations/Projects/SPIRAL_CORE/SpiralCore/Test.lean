import Init
import SpiralCore.Core
import SpiralCore.Cantor
import SpiralCore.Attractor
import SpiralCore.Alignment
import SpiralCore.PhaseLift
import SpiralCore.FBS
import SpiralCore.Boot
import SpiralCore.Translation
import SpiralCore.FeynmanPath
import SpiralCore.PersistenceCanopies
import SpiralCore.SubsetSelection
import SpiralCore.FisherSharpness
import SpiralCore.GkMapper
import SpiralCore.HodgeSurrogates
import SpiralCore.VertexGuard
import SpiralCore.GeometricTrees
import SpiralCore.SpiralcoreV13
import SpiralCore.SpiralcoreV13Test
import SpiralCore.MorseTransform
import SpiralCore.V4pVsam
import SpiralCore.WadaLada

/-! # SpiralCore Test Harness

Self-contained test suite runnable with `lake test`.
Demonstrates both positive proofs and intentional boundary cases,
covering the SpiralCore v14.1 core plus ADR-0030..0043 formal models.
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
  let (x1, y1) := rotate90 (3, 4)
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
  let p1 := rotate90 (1, 2)
  let p2 := rotate90 p1
  let p3 := rotate90 p2
  let p4 := rotate90 p3
  IO.println "Rotate90 cycle test"
  assert! p4.1 = 1
  assert! p4.2 = 2

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

/-- Test: Feynman path (ADR-0030): equal-strength composition and gate. -/
def test_feynman_path : IO Unit := do
  IO.println "Feynman path test"
  let count := 1419857
  let total := FeynmanPath.totalAmplitude count
  assert! total = count * FeynmanPath.unitAmplitude
  assert! FeynmanPath.gateClosed count total FeynmanPath.fidelityTolerance = true

/-- Test: Persistence canopies (ADR-0031): diagonal split and pairing. -/
def test_persistence_canopies : IO Unit := do
  IO.println "Canopies persistence test"
  assert! PersistenceCanopies.inUpperHalfSpace 5 5 = true
  assert! PersistenceCanopies.inOpenUpperHalfSpace 5 5 = false

/-- Test: Subset selection (ADR-0032): Monge matrices and singleton optima. -/
def test_subset_selection : IO Unit := do
  IO.println "Subset selection test"
  assert! SubsetSelection.feasibleTransition 3 3 = false
  assert! SubsetSelection.feasibleTransition 2 5 = true
  assert! SubsetSelection.empty_archive_canonical_prop

/-- Test: Fisher sharpness (ADR-0033): metric policy and flat-minima bias. -/
def test_fisher_sharpness : IO Unit := do
  IO.println "Fisher sharpness test"
  assert! FisherSharpness.admissibleFlatnessMetric "trace_hessian" = false
  assert! FisherSharpness.admissibleFlatnessMetric "SR" = true
  assert! FisherSharpness.stationaryMass 10 20 10 <= FisherSharpness.stationaryMass 30 20 10

/-- Test: GK-Mapper (ADR-0034): fuzzifier and edge thresholds. -/
def test_gk_mapper : IO Unit := do
  IO.println "GK-Mapper test"
  assert! GkMapper.admissibleFuzzifier 20 = true
  assert! GkMapper.admissibleFuzzifier 5 = false
  assert! GkMapper.edgeExists 40 40 = true
  assert! GkMapper.edgeExists 5 5 = false

/-- Test: Hodge surrogates (ADR-0035): Betti kernel and hard limit. -/
def test_hodge_surrogates : IO Unit := do
  IO.println "Hodge surrogates test"
  assert! HodgeSurrogates.hardLimitBettiPreserved 3 0 5 = true
  assert! HodgeSurrogates.isClique (fun _ _ => false) [] = true
  assert! HodgeSurrogates.traceSurrogate 7 7 = 100

/-- Test: Vertex guard (ADR-0036): coverage and escalation gates. -/
def test_vertex_guard : IO Unit := do
  IO.println "Vertex guard test"
  assert! VertexGuard.deploymentSafe [] 0 = true
  assert! VertexGuard.escalateIfUnderCovered [0] 1 = true
  assert! VertexGuard.clearsFeasibility [] 0 = true

/-- Test: Geometric trees (ADR-0037): PSD matrix and normalization. -/
def test_geometric_trees : IO Unit := do
  IO.println "Geometric trees test"
  assert! GeometricTrees.diagonalMatrix_psd_check 5
  assert! GeometricTrees.simplexNormalized 30 40 30 100 = true

/-- Test: SpiralCore v13 (ADR-0038): constants and Collatz floor. -/
def test_spiralcore_v13 : IO Unit := do
  IO.println "SpiralCore v13 test"
  assert! SpiralcoreV13.dim13 < SpiralcoreV13.l0Floor
  assert! SpiralcoreV13.dimScale1 = 3 * SpiralcoreV13.dim13
  assert! SpiralcoreV13.bifurcationA = 27 && SpiralcoreV13.bifurcationB = 28
  assert! SpiralcoreV13.pdvLimit100 < SpiralcoreV13.cvcThresh100

/-- Test: SpiralCore v13 gates (ADR-0039): PASS/FAIL boundaries. -/
def test_spiralcore_v13_gates : IO Unit := do
  IO.println "SpiralCore v13 gates test"
  assert! SpiralcoreV13Test.lorienRoutingLocked 96 = true
  assert! SpiralcoreV13Test.lorienShearFail 55 = true
  assert! SpiralcoreV13Test.braidbackBreach 35 = false
  assert! SpiralcoreV13Test.braidbackBreach 65 = true
  assert! SpiralcoreV13Test.cathedralStable 5 = true
  assert! SpiralcoreV13Test.cathedralStable 15 = false
  assert! SpiralcoreV13Test.fbsRunaway 15 = true
  assert! SpiralcoreV13Test.millenniumClosed 95 5 = true
  assert! SpiralcoreV13Test.millenniumClosed 60 5 = false
  assert! SpiralcoreV13Test.millenniumClosed 95 35 = false
  assert! SpiralcoreV13Test.godelDirectiveBound 99 = true
  assert! SpiralcoreV13Test.godelDirectiveBound 45 = false
  assert! SpiralcoreV13Test.cycleWithinBinder SpiralcoreV13.ultraBinderLimit13 = true

/-- Test: Morse transform (ADR-0041): type classification. -/
def test_morse_transform : IO Unit := do
  IO.println "Morse transform test"
  assert! MorseTransform.typeOfBetti 0 0 = MorseTransform.CriticalType.peak
  assert! MorseTransform.typeOfBetti 1 0 = MorseTransform.CriticalType.trough
  assert! MorseTransform.typeOfBetti 0 2 = MorseTransform.CriticalType.saddle
  assert! MorseTransform.plainMorseDim < MorseTransform.supplementedMorseDim

/-- Test: V4P-VSAM (ADR-0042): nibble round-trip and example. -/
def test_v4p_vsam : IO Unit := do
  IO.println "V4P-VSAM test"
  assert! V4pVsam.highNibble 10 = 0 && V4pVsam.lowNibble 10 = 10
  assert! V4pVsam.highNibble 81 = 5 && V4pVsam.lowNibble 81 = 1
  assert! V4pVsam.highNibble 47 = 2 && V4pVsam.lowNibble 47 = 15
  assert! V4pVsam.signed4 8 = 0
  assert! V4pVsam.sameSemanticObject "sc.abraxas.v1" "code.search.v1" "10.81.33.47" "10.81.33.47" = false
  assert! V4pVsam.addressGrantsPermission "read" = false
  assert! V4pVsam.conflictPolicy true = false

/-- Test: WADA-LADA (ADR-0043): loop prevention and role confinement. -/
def test_wada_lada : IO Unit := do
  IO.println "WADA-LADA test"
  let msg : WadaLada.StateMessage := {
    stateId := "sha256:5b18", basisId := "sc.abraxas.v1", address := "10.81.33.47",
    path := ["agent-dubai-17", "hlca-dubai-01"], ttl := 8,
    signatureValid := true, policyAllowsTransit := true,
    basisSupported := true, stateClassAllowed := true }
  let msgBadSig : WadaLada.StateMessage := { msg with signatureValid := false }
  let msgBadBasis : WadaLada.StateMessage := { msg with basisSupported := false }
  -- drop/quarantine gates
  assert! WadaLada.shouldDrop msg "agent-rome-01" = false
  assert! WadaLada.shouldDrop msgBadSig "agent-rome-01" = true
  assert! WadaLada.shouldDrop msgBadBasis "agent-rome-01" = true
  -- loop prevention and TTL
  let msgLooped : WadaLada.StateMessage := { msg with path := ["agent-rome-01", "hlca"] }
  let msgTtl0 : WadaLada.StateMessage := { msg with ttl := 0 }
  assert! WadaLada.shouldDrop msgLooped "agent-rome-01" = true
  assert! WadaLada.dropTtl msgTtl0 = true
  -- root election hysteresis
  assert! WadaLada.mayReplaceRoot 95 80 10 5 5 = true
  assert! WadaLada.mayReplaceRoot 85 80 10 5 5 = false
  -- manual root and role confinement
  assert! WadaLada.manualOverrideValid false false false false = true
  assert! WadaLada.manualOverrideValid true false false false = false
  assert! WadaLada.workerMayAdvertiseAsRoot false = false
  assert! WadaLada.workerMayAdvertiseAsRoot true = true
  -- merge and conflict preservation
  assert! WadaLada.conflictPreserved false = true
  assert! WadaLada.fusionTruthClaim = false

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
  test_feynman_path
  test_persistence_canopies
  test_subset_selection
  test_fisher_sharpness
  test_gk_mapper
  test_hodge_surrogates
  test_vertex_guard
  test_geometric_trees
  test_spiralcore_v13
  test_spiralcore_v13_gates
  test_morse_transform
  test_v4p_vsam
  test_wada_lada
  IO.println "=== All tests passed ==="
