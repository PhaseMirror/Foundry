import Foundations.ADR
import Foundations.ALP
import Foundations.AffineCore
import Foundations.CRMF
import Foundations.CertificationGate
import Foundations.ConstraintNerve
import Foundations.Drift
import Foundations.ExportThresholds
import Foundations.GOLDILOCKS
import Foundations.Governance
import Foundations.LinearAlgebra.Matrix
import Foundations.MOC
import Foundations.Multiset
import Foundations.PARM
import Foundations.PIRTM
import Foundations.PRMS
import Foundations.RocEngine
import Foundations.S4_Spectral
import Foundations.SpectralCert
import Foundations.Stability
import Foundations.UMCPAROM
import Foundations.UOR
import Foundations.Widgets
import Foundations.XI_FORMAL
import Foundations.ZMOD

-- Export selected symbols for convenience
export Core.ADR (ADRStatus ADR ArtifactLink is_valid_entailment checkAcyclic)
export Core.Drift (Drift)
export Core.matrix (Matrix)
export Core.PARM (sealed_state sealed_state_loop sealed_state_deterministic sealed_state_108_cycle sealed_state_one_injective)
export Core.PRMS (scale LineageMetrics ComplianceBudget TelemetryFrame PrmsTelemetryWitness isValidLineage isValidBudget isValidFrame isValidWitness lineage_metrics_preserved lineage_age_monotone telemetry_frame_valid compliance_budget_respected)
export Core.RocEngine (RocEngine)
export Core.S4_Spectral (S4_Spectral)
export Core.Stability (Stability)
export Core.UMCPAROM (UMCPAROM)
export Core.UOR (UOR)
export Core.Widgets (Widgets)
export Core.ZMOD (ZMOD)

/-!
## Usage

Downstream modules can simply `open Core` after importing this file, gaining
access to the core types, theorems, and utility functions without needing to
track the individual import paths.
-/
