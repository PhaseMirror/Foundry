import LorenzAttractor.Core

/-! # LorenzAttractor.Dynamics

Continuous and discrete dynamics of the Lorenz system:
1. Classical differential equations and discrete Euler integration steps
2. 3D Jacobian matrix evaluations and trace invariant Tr(J) = -(sigma + 1 + beta)
3. Multiplicity-integrated eigenvalue sum Lambda(t)
4. Stability functional S(t) = integral_0^t exp(-Lambda(tau)) dtau
-/

namespace LorenzAttractor

/-- Discrete integration time step dt = 10 / FP_DEN = 0.010. -/
def DT_FP : Int := 10

/-- 3x3 Jacobian Matrix in fixed-point representation. -/
structure Jacobian3D where
  j11 : Int
  j12 : Int
  j13 : Int
  j21 : Int
  j22 : Int
  j23 : Int
  j31 : Int
  j32 : Int
  j33 : Int
  deriving Repr, DecidableEq

/-- Evaluate Jacobian matrix J(x, y, z) at a given point:
    J = [ -sigma,    sigma,   0   ]
        [  rho - z, -1,      -x   ]
        [  y,        x,      -beta]
-/
def evaluateJacobian (p : LorenzPoint) (params : LorenzParams) : Jacobian3D :=
  let betaVal := params.betaNum / params.betaDen
  ⟨ 0 - params.sigma, params.sigma, 0,
    params.rho - p.z, 0 - Int.ofNat FP_DEN, 0 - p.x,
    p.y, p.x, 0 - betaVal ⟩

/-- Trace of the Jacobian matrix Tr(J) = J11 + J22 + J33 = -(sigma + 1 + beta).
    Crucial physical invariant: strictly negative trace implies uniform volume contraction. -/
def jacobianTrace (j : Jacobian3D) : Int :=
  j.j11 + j.j22 + j.j33

/-- Theoretical Jacobian trace directly from parameters: -(sigma + 1 + beta). -/
def theoreticalTrace (params : LorenzParams) : Int :=
  let betaVal := params.betaNum / params.betaDen
  0 - (params.sigma + Int.ofNat FP_DEN + betaVal)

/-- Compute instantaneous Multiplicity eigenvalue metric Lambda(t):
    Lambda(t) = Tr(J) * (1 + multiplicity_weight)
    Incorporates eigenvalue multiplicity scaling. -/
def computeSpectralMultiplicity (p : LorenzPoint) (params : LorenzParams) : Int :=
  let j := evaluateJacobian p params
  let tr := jacobianTrace j
  -- Non-linear state modulation to reflect localized eigenvalue splitting
  let statePower := (pointNormSq p) / 1000
  let multFactor := Int.ofNat FP_DEN + Int.ofNat (statePower % 200)
  fpMulInt tr multFactor

/-- Compute Classical Lorenz State Velocity (dx/dt, dy/dt, dz/dt):
    dx = sigma * (y - x)
    dy = x * (rho - z) - y
    dz = x * y - beta * z
-/
def lorenzVelocity (p : LorenzPoint) (params : LorenzParams) : LorenzPoint :=
  let betaVal := params.betaNum / params.betaDen

  let dx := fpMulInt params.sigma (p.y - p.x)
  let dy := fpMulInt p.x (params.rho - p.z) - p.y
  let dz := fpMulInt p.x p.y - fpMulInt betaVal p.z

  ⟨dx, dy, dz⟩

/-- Single Classical Euler Step: p_{t+1} = p_t + v * dt. -/
def classicalStep (p : LorenzPoint) (params : LorenzParams) : LorenzPoint :=
  let v := lorenzVelocity p params
  let nextX := p.x + fpMulInt v.x DT_FP
  let nextY := p.y + fpMulInt v.y DT_FP
  let nextZ := p.z + fpMulInt v.z DT_FP
  clampPoint ⟨nextX, nextY, nextZ⟩ (100 * Int.ofNat FP_DEN)

end LorenzAttractor
