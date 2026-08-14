import Multiplicity.ADR
import Multiplicity.ALP
import Multiplicity.AffineCore
import Multiplicity.CRMF
import Multiplicity.CertificationGate
import Multiplicity.ConstraintNerve
import Multiplicity.Drift
import Multiplicity.ExportThresholds
import Multiplicity.GOLDILOCKS
import Multiplicity.Governance
import Multiplicity.LinearAlgebra.Matrix
import Multiplicity.MOC
import Multiplicity.Multiset
import Multiplicity.PARM
import Multiplicity.PIRTM
import Multiplicity.PRMS
import Multiplicity.RocEngine
import Multiplicity.S4_Spectral
import Multiplicity.SpectralCert
import Multiplicity.Stability
import Multiplicity.UMCPAROM
import Multiplicity.UOR
import Multiplicity.Widgets
import Multiplicity.XI_FORMAL
import Multiplicity.ZMOD

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
