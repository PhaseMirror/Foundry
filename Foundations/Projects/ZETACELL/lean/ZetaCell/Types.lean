set_option autoImplicit false

/-!
# Project ZETACELL: Core Types and Mathematical Specifications
Finite-Dimensional Coupling of Prime Channels to Zeta-Zero Spectral Witnesses
-/

namespace ZetaCell

/-- Dimension configuration for dual-sector state space H_ζ = H_p ⊕ H_z. -/
structure SectorDimensions where
  n_p : Nat -- number of prime channels
  n_f : Nat -- prime channel features
  n_z : Nat -- number of zeta-zero witnesses
  n_g : Nat -- zeta-zero channel features
  deriving Repr, DecidableEq

/-- State energy metrics on H_p and H_z. -/
structure SectorEnergy where
  prime_energy : Nat -- scaled integer norm
  zero_energy  : Nat -- scaled integer norm
  deriving Repr, DecidableEq

/-- ZetaCell Configuration parameters. -/
structure CellConfig where
  lambda_m_scaled : Nat -- multiplicity constant Λ_m scaled by 1000
  safety_clip     : Nat -- CSL row cap norm
  diversity_target: Nat -- target entropy
  deriving Repr, DecidableEq

end ZetaCell
