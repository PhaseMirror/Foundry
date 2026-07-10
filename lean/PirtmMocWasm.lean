import MOC.Resonance
import MOC.Ramanujan
import MOC.Certificate
import MOC.Ramanujan
import CRMF
import PRMS
import UMCPAROM
import PARM
import ZMOD
import RocEngine
import XI_FORMAL
import META_RELATIVITY
import GOLDILOCKS
import PIRTM.Stability
import PIRTM.Agency
import PIRTM.Drift
import PIRTM.Authority
import PIRTM.LegalESI02
import PIRTM.FinancialTreasury01
import CPIRTM
import DRMM

namespace SedonaSpineWasm

-- Export Resonance Bounds
abbrev epsilon_of_resonance := MOC.Resonance.epsilon_of_resonance
abbrev Lip_transition := MOC.Resonance.Lip_transition
abbrev ultra_dist := MOC.Resonance.ultra_dist
abbrev ultrametric_contraction := MOC.Resonance.ultrametric_contraction

-- Export Governance and Stability
abbrev systemic_weight_unity := PIRTM.Agency.systemic_weight_unity
abbrev agency_spectral_stability := PIRTM.Agency.agency_spectral_stability
abbrev stability_transitivity {codomain : Nat} (cert : PIRTM.StabilityCertificate codomain) := PIRTM.stability_transitivity cert

-- Export Ensemble Witnesses
abbrev ft01_anchored := PIRTM.Authority.ft01_anchored
abbrev le02_anchored := PIRTM.Authority.le02_anchored
abbrev stability_certificate_ESI02 := PIRTM.Ensembles.Legal.stability_certificate_ESI02

-- Export DRMM & C-PIRTM
abbrev cpirtm_contractive := CPIRTM.is_contractive
abbrev drmm_step := DRMM.step
abbrev drmm_stability := DRMM.stability_of_recursion

-- Export CRMF
abbrev crmf_contraction_witness := @CRMF.crmf_contraction_witness
abbrev crmf_108_cycle_stable := CRMF.crmf_108_cycle_stable
abbrev veto_soundness := CRMF.veto_soundness

-- Export PRMS
abbrev zeta_ros_veto_soundness := PRMS.zeta_ros_veto_soundness
abbrev contractor_critical_soundness := PRMS.contractor_critical_soundness

-- Export UMCPAROM
abbrev umc_joint_contraction := UMCPAROM.umc_joint_contraction

-- Export PARM
abbrev sealed_state_pos := PARM.sealed_state_pos

-- Export ZMOD
abbrev multiplicity_tensor_le_T := ZMOD.multiplicity_tensor_le_T

-- Export RocEngine
abbrev roc_lyapunov_descent_weighted := lyapunov_descent_weighted
abbrev roc_nfiber_descent := nfiber_descent
abbrev roc_zchaos_descent := zchaos_descent
abbrev roc_cross_fiber_descent := cross_fiber_descent

-- Export RAMANUJAN (Now under MOC.Ramanujan)
abbrev ramanujan_coeff_satisfies_recurrence := MOC.Ramanujan.coeff_satisfies_recurrence
abbrev ramanujan_validator_soundness := MOC.Ramanujan.validator_soundness

-- Export XI_FORMAL
abbrev xi_formal_tight_Cf_bound := XI_FORMAL.tight_Cf_bound

-- Export META_RELATIVITY
abbrev mr_gate5_implies_g3_bounds := META_RELATIVITY.gate5_implies_g3_bounds

-- Export GOLDILOCKS
abbrev goldilocks_mul_red_correct := GOLDILOCKS.mul_red_correct

-- Export Monstrous Moonshine (MOC.Moonshine)
abbrev moonshine_admissibility_1 := MOC.monster_admissibility_bound_1
abbrev moonshine_admissibility_2 := MOC.monster_admissibility_bound_2

end SedonaSpineWasm

