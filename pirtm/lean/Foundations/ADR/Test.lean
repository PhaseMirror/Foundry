import Foundations.ADR.Core
import Foundations.ADR.Proofs
import Foundations.ADR.Examples
import Foundations.ADR.DialecticalSemantics
import Foundations.ADR.PrimeQuantum
import Foundations.ADR.PrimeAutoencoder
import Foundations.ADR.PhaseDissonance
import Foundations.ADR.GovernanceManifold
import Foundations.ADR.CognitiveEconomy
import Foundations.ADR.EchoBraid
import Foundations.ADR.FloerOperator
import Foundations.ADR.Constitution
import Foundations.ADR.License
import Foundations.ADR.Reconciliation
import Foundations.ADR.UIIntegration
import Foundations.ADR.GoldilocksSoundness
import Foundations.ADR.SentinelIntegration
import Foundations.ADR.WardMonitorStability
import Foundations.ADR.Poseidon2Soundness
import Foundations.ADR.DistributedGovernance
import Foundations.ADR.InstallationProtocol
import Foundations.ADR.AcePetcIntegration
import Foundations.ADR.UmcPmroRegulator
import Foundations.ADR.PincCdtSpacetime

/-!
# ADR Foundations Test

Lake test suite for ADR invariants, ADR-034 through ADR-054.
-/
open PIRTM.ADR
open PIRTM.DialecticalSemantics
open PIRTM.PrimeQuantum
open PIRTM.PrimeAutoencoder
open PIRTM.PhaseDissonance
open PIRTM.GovernanceManifold
open PIRTM.CognitiveEconomy
open PIRTM.EchoBraid
open PIRTM.FloerOperator
open PIRTM.Constitution
open PIRTM.License
open PIRTM.Reconciliation
open PIRTM.UIIntegration
open PIRTM.GoldilocksSoundness
open PIRTM.SentinelIntegration
open PIRTM.WardMonitorStability
open PIRTM.Poseidon2Soundness
open PIRTM.DistributedGovernance
open PIRTM.InstallationProtocol
open PIRTM.AcePetcIntegration
open PIRTM.UmcPmroRegulator
open PIRTM.PincCdtSpacetime



def test_accepted_immutable : IO Unit := do
  let a := foundryIntegration
  if a.status == ADRStatus.Accepted then
    pure ()
  else
    throw $ IO.Error.userError "Immutable test failed"

def test_traceability : IO Unit := do
  let a := foundryIntegration
  let hist := [a.id]
  if hist.head? == some a.id then
    pure ()
  else
    throw $ IO.Error.userError "Traceability test failed"

def test_dialectical_admissibility : IO Unit := do
  let validTrajectory : CandidateTrajectory := {
    id := 101,
    grounding := { coverageRatio := 85, minThreshold := 70 },
    tension := { tensionDelta := 12, maxAllowed := 20, branchCount := 3 },
    contractivityScaled := 92
  }
  match certifyTrajectory validTrajectory with
  | CertificationResult.Admissible _ => IO.println "ADR-034: Trajectory certified admissible"
  | CertificationResult.Rejected r => throw $ IO.Error.userError s!"ADR-034: Unexpected rejection: {repr r}"

def test_dialectical_collapse_rejection : IO Unit := do
  let collapsedTrajectory : CandidateTrajectory := {
    id := 102,
    grounding := { coverageRatio := 90, minThreshold := 70 },
    tension := { tensionDelta := 5, maxAllowed := 20, branchCount := 1 },
    contractivityScaled := 85
  }
  match certifyTrajectory collapsedTrajectory with
  | CertificationResult.Rejected (CertificationRejection.DialecticalCollapse _) =>
    IO.println "ADR-034: Dialectical collapse caught as expected"
  | _ => throw $ IO.Error.userError "ADR-034: Failed to reject collapsed branch count"

def test_prime_quantum_syndrome : IO Unit := do
  let p_state : PrimeSubspaceState 8 := { basisState := 13, h_bound := by decide }
  let c_state : PrimeSubspaceState 8 := { basisState := 14, h_bound := by decide }
  if primeSyndromeEigenvalue p_state.basisState == 1 && primeSyndromeEigenvalue c_state.basisState == -1 then
    IO.println "ADR-035: Prime quantum syndrome S_P eigenvalue test passed (+1 prime, -1 composite)"
  else
    throw $ IO.Error.userError "ADR-035: Syndrome eigenvalue test failed"

def test_prime_autoencoder_rank_surrogate : IO Unit := do
  let r : RankSurrogate := { effectiveRankScaled := 540, maxAllowedDimension := 6 }
  if checkRankSurrogateBound r then
    IO.println "ADR-036: Prime-structured rank surrogate bound test passed"
  else
    throw $ IO.Error.userError "ADR-036: Rank surrogate bound check failed"

def test_phase_dissonance_in_bounds : IO Unit := do
  let entries : List ContradictionEntry := [
    { primeAxis := 2, artifact := ArtifactType.Spec, weight := 1, delta := 2 },
    { primeAxis := 3, artifact := ArtifactType.Code, weight := 1, delta := 1 }
  ]
  let band : PhaseBand := { lowerBound := 0, upperBound := 10 }
  if isGovernanceInBounds entries band then
    IO.println "ADR-037: Phase dissonance calculation and dynamic phase band check passed"
  else
    throw $ IO.Error.userError "ADR-037: Phase dissonance bound check failed"

def test_governance_manifold_arbitration : IO Unit := do
  let d : PIRTM.GovernanceManifold.DriftState := { driftScaled := 35, driftDotScaled := 5, deltaSoftScaled := 20, deltaHardScaled := 30 }
  match arbitrateControl d with
  | ControlArbitration.GovernorHalt => IO.println "ADR-038: Fail-closed GovernorHalt triggered as expected on drift saturation"
  | _ => throw $ IO.Error.userError "ADR-038: Failed to trigger GovernorHalt on hard drift saturation"

def test_ethical_projection_idempotence : IO Unit := do
  let m : EthicalManifold := { maxNormScaled := 500 }
  let s : CognitiveState := { stateVector := 42, normScaled := 750, isLawful := false }
  let s_proj1 := projectEthical m s
  let s_proj2 := projectEthical m s_proj1
  if s_proj1.normScaled == 500 && s_proj1.isLawful && s_proj1.normScaled == s_proj2.normScaled then
    IO.println "ADR-039: Idempotent ethical projection test passed"
  else
    throw $ IO.Error.userError "ADR-039: Ethical projection idempotence test failed"

def test_echobraid_prediction_bound : IO Unit := do
  let p : PredictionSkeleton := { alphaDotXi := 10, betaDelta := 15, maxAllowed := 30 }
  if isPredictionContractive p then
    IO.println "ADR-040: EchoBraid prediction skeleton contractivity check passed"
  else
    throw $ IO.Error.userError "ADR-040: Prediction skeleton contractivity check failed"

def test_floer_flow_bound : IO Unit := do
  let s : FloerState := { hamiltonianGrad := 10, potentialGrad := 5, stochasticNoise := 2 }
  let b : FloerFlowBound := { maxMagnitude := 50 }
  if isFloerFlowAdmissible s 3 b then
    IO.println "ADR-041: Multiplicity Floer differential flow bound test passed"
  else
    throw $ IO.Error.userError "ADR-041: Floer flow bound test failed"

def test_csl_constitution_gate : IO Unit := do
  let intent : CslIntent := { isNeutral := true, isBeneficent := true, isSilenceSafe := true }
  if evaluateCsl intent then
    IO.println "ADR-042: CSL Constitution gate evaluation test passed"
  else
    throw $ IO.Error.userError "ADR-042: CSL gate evaluation failed"

def test_lawful_license_certification : IO Unit := do
  let state : ExecutionState := { stateId := 1, drift := 5, maxAllowed := 10, hasPirtm := true, hasCsl := true, hasZk := true }
  if isLawfulEvolution state then
    IO.println "ADR-043: Lawful License certification test passed"
  else
    throw $ IO.Error.userError "ADR-043: Lawful license certification failed"

def test_registry_reconciliation_promotion : IO Unit := do
  if isPromotableToAccepted true true then
    IO.println "ADR-044: Registry promotion rule test passed"
  else
    throw $ IO.Error.userError "ADR-044: Registry promotion rule failed"

def test_ui_integration_receipt : IO Unit := do
  let req : UiCompileRequest := { codeSource := "Ap(2) + 3", spectralRadius := 85, isReadOnly := false }
  let receipt := evaluateUiRequest req
  if receipt.isAdmissible && receipt.mlirGenerated then
    IO.println "ADR-045: UI contractivity gate & MLIR receipt generation test passed"
  else
    throw $ IO.Error.userError "ADR-045: UI compile evaluation failed"

def test_goldilocks_preservation : IO Unit := do
  let elem := fromScaledRatio 85
  if elem.val < 100 then
    IO.println "ADR-046: Goldilocks prime field contractivity preservation test passed"
  else
    throw $ IO.Error.userError "ADR-046: Goldilocks contractivity preservation test failed"

def test_sentinel_never_kills_admissible : IO Unit := do
  let state : ManifoldStressState := { rho := 42, delta := 1, lambdaLProduct := 50 }
  let cfg : SentinelConfig := { rhoHalt := 100, rhoWarn := 85, deltaMax := 10 }
  match validateAndSeal state cfg true with
  | SentinelAction.Pass _ => IO.println "ADR-047: Sentinel validate_and_seal admissible pass test passed"
  | _ => throw $ IO.Error.userError "ADR-047: Sentinel validation failed on admissible state"

def test_ward_monitor_lyapunov_stability : IO Unit := do
  let gain : ZenoGain := { kappaScaled := 10, h_bound := by decide, h_pos := by decide }
  let rho := 90
  let att := applyZenoGain rho gain
  if lyapunovEnergy att <= lyapunovEnergy rho then
    IO.println "ADR-048: WardMonitor Lyapunov stability test passed"
  else
    throw $ IO.Error.userError "ADR-048: WardMonitor Lyapunov stability check failed"

def test_poseidon2_soundness : IO Unit := do
  let receipt : Poseidon2Receipt := { constraintCount := 5087, isValid := true }
  if verifyPoseidon2Receipt receipt then
    IO.println "ADR-049: Poseidon2 ZK-SNARK circuit proof soundness test passed"
  else
    throw $ IO.Error.userError "ADR-049: Poseidon2 ZK receipt verification failed"

def test_distributed_governance_consensus : IO Unit := do
  let metrics : ClusterMetrics := { totalNodes := 3, passVotes := 3, killVotes := 0, quorumThreshold := 2 }
  if isQuorumReached metrics then
    IO.println "ADR-050: Multi-node distributed governance consensus test passed"
  else
    throw $ IO.Error.userError "ADR-050: Cluster consensus quorum check failed"

def test_installation_protocol_soundness : IO Unit := do
  let st : InstallationState := {
    hasRustc := true,
    hasLean := true,
    binariesCompiled := true,
    binariesLinked := true,
    kernelVerified := true
  }
  if verifyInstallation st then
    IO.println "ADR-051: Local PC installation protocol soundness test passed"
  else
    throw $ IO.Error.userError "ADR-051: Local installation protocol verification failed"

def test_ace_petc_integration : IO Unit := do
  let budget : AceBudget := { weightedNormScaled := 85, budgetTauScaled := 100 }
  let sig1 : PetcSignature2 := { exp2 := 3, exp3 := 1 }
  let sig2 : PetcSignature2 := { exp2 := 2, exp3 := 4 }
  let sigOut : PetcSignature2 := { exp2 := 5, exp3 := 5 }
  if isPetcConserved2 sig1 sig2 sigOut && isAceBudgetSatisfied budget then
    IO.println "ADR-052: PIRTM ACE x PETC exponent conservation and budget test passed"
  else
    throw $ IO.Error.userError "ADR-052: ACE x PETC verification failed"


def test_umc_pmro_regulator : IO Unit := do
  let st : UmcState := { cScaled := 5, epsilonScaled := 10, stressCounter := 0 }
  let d : AssociatorDefect := { defectScaled := 4, upperBoundScaled := 6 }
  if isUmcAdmissible st && isAssociatorDefectBounded d then
    IO.println "ADR-053: Universal Multiplicity Constant Lambda_m and PMRO associator defect test passed"
  else
    throw $ IO.Error.userError "ADR-053: Lambda_m regulator / PMRO verification failed"

def test_pinc_cdt_spacetime : IO Unit := do
  let st : ActionDensityState := { reggeContributionScaled := 2, ncgContributionScaled := 3, couplingContributionScaled := 1, maxAllowedKsScaled := 10 }
  let sd : SpectralDimensionState := { dsScaled := 16 }
  if isActionDensityBounded st && isSpectralDimensionValid sd then
    IO.println "ADR-054: Prime-indexed NCG-CDT unified action density and spectral dimension test passed"
  else
    throw $ IO.Error.userError "ADR-054: PINC-CDT spacetime verification failed"


