import Core.ADR
import Core.ALP
import Core.AffineCore
import Core.CRMF
import Core.CertificationGate
import Core.ConstraintNerve
import Core.Drift
import Core.ExportThresholds
import Core.GOLDILOCKS
import Core.Governance
import Core.matrix
import Core.MOC
import Core.Multiset
import Core.PARM
import Core.PIRTM
import Core.PRMS
import Core.RocEngine
import Core.S4_Spectral
import Core.SpectralCert
import Core.Stability
import Core.UMCPAROM
import Core.UOR
import Core.Widgets
import Core.XI_FORMAL
import Core.ZMOD

-- Export selected symbols for convenience
export Core.ADR (ADRStatus ADR ArtifactLink is_valid_entailment checkAcyclic)
export Core.Drift (Drift)
export Core.matrix (Matrix)
export Core.MOC (MOC)
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
