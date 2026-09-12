import Foundations.ADR.Export
import Foundations.ADR.Test

def main : IO UInt32 := do
  test_accepted_immutable
  test_traceability
  test_dialectical_admissibility
  test_dialectical_collapse_rejection
  test_prime_quantum_syndrome
  test_prime_autoencoder_rank_surrogate
  test_phase_dissonance_in_bounds
  test_governance_manifold_arbitration
  test_ethical_projection_idempotence
  test_echobraid_prediction_bound
  test_floer_flow_bound
  test_csl_constitution_gate
  test_lawful_license_certification
  test_registry_reconciliation_promotion
  test_ui_integration_receipt
  test_goldilocks_preservation
  test_sentinel_never_kills_admissible
  test_ward_monitor_lyapunov_stability
  test_poseidon2_soundness
  test_distributed_governance_consensus
  test_installation_protocol_soundness
  test_ace_petc_integration
  test_umc_pmro_regulator
  test_pinc_cdt_spacetime
  exportAll


  IO.println "All Lean ADR tests and documentation exports executed successfully."
  return 0
