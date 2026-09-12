import Init

/-! # MOperator.Core

Foundational discrete fixed-point arithmetic, Multiplicity constants (phi, delta_I, lambda_m),
vectorized 3D state representations, and CSL metric definitions.
-/

namespace MOperator

/-- Fixed-point denominator: 1000 represents 1.000. -/
def FP_DEN : Nat := 1000

/-- Signed fixed-point multiplication: (x * y) / FP_DEN. -/
def fpMulInt (x y : Int) : Int :=
  (x * y) / (Int.ofNat FP_DEN)

/-- Signed fixed-point division: (x * FP_DEN) / y. -/
def fpDivInt (x y : Int) : Int :=
  if y == 0 then x * (Int.ofNat FP_DEN) else (x * (Int.ofNat FP_DEN)) / y

/-- Golden ratio phi ~ 1.618 in fixed point (1618 / 1000). -/
def PHI_FP : Int := 1618

/-- Inverse Golden Ratio phi^-1 = lambda_m ~ 0.618 in fixed point (618 / 1000). -/
def LAMBDA_M_FP : Int := 618

/-- Interaction Depth Constant delta_I = phi^-2 ~ 0.382 in fixed point (382 / 1000). -/
def DELTA_I_FP : Int := 382

/-- Non-linear regularization weight alpha = 0.500 in fixed point. -/
def ALPHA_NL_FP : Int := 500

/-- CSL Coherence threshold epsilon = 0.050 in fixed point (50 / 1000). -/
def EPSILON_CSL_FP : Int := 50

/-- 3D Vectorized State Point in fixed-point representation. -/
structure MVector3 where
  x : Int
  y : Int
  z : Int
  deriving Repr, DecidableEq

/-- Standard fixed point phi vector (phi, phi, phi). -/
def phiVector : MVector3 :=
  ⟨PHI_FP, PHI_FP, PHI_FP⟩

/-- Origin vector (0, 0, 0). -/
def zeroVector : MVector3 :=
  ⟨0, 0, 0⟩

/-- Euclidean distance squared in fixed-point representation: (dx^2 + dy^2 + dz^2) / FP_DEN. -/
def vectorDistSq (v1 v2 : MVector3) : Nat :=
  let dx := v1.x - v2.x
  let dy := v1.y - v2.y
  let dz := v1.z - v2.z
  let sq := (dx * dx + dy * dy + dz * dz).toNat
  sq / FP_DEN

/-- Bounding clamp for coordinates within [-maxBound, maxBound]. -/
def clampVector (v : MVector3) (maxBound : Int) : MVector3 :=
  let cx := if v.x > maxBound then maxBound else if v.x < -maxBound then -maxBound else v.x
  let cy := if v.y > maxBound then maxBound else if v.y < -maxBound then -maxBound else v.y
  let cz := if v.z > maxBound then maxBound else if v.z < -maxBound then -maxBound else v.z
  ⟨cx, cy, cz⟩

/-- State of an M-Operator agent at time step t. -/
structure AgentState where
  time : Nat
  position : MVector3
  drift : Nat
  collapseCount : Nat
  isCoherent : Bool
  deriving Repr, DecidableEq

end MOperator
