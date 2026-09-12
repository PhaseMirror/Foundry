import EigenSolvers.Core
import EigenSolvers.Tensor

/-!
# Prime-Encoded Eigen Solvers: Concrete Computational Examples

Reference implementation and concrete evaluation suite for a 3x3 Hermitian system.
Reference: docs/templateArxiv.tex Section 5 (Code Sketch) & Section 2
-/

namespace EigenSolvers.Examples

open EigenSolvers.Core
open EigenSolvers.Tensor

/-! ## 1. 3-Step Prime-Weighted Lanczos Flow Instance -/

/-- Step 1 module M_1: α_1 = 4.0, p_1 = 2. -/
def module_M1 : PrimeKrylovModule :=
  initKrylovModule 4.0 2

/-- Step 2 module M_2: α_2 = 3.0, raw β_1 = 1.0 (eff = 2.0), p_2 = 3. -/
def module_M2 : PrimeKrylovModule :=
  advanceKrylovStep module_M1 3.0 1.0 3

/-- Step 3 module M_3: α_3 = 2.0, raw β_2 = 1.0 (eff = 3.0), p_3 = 5. -/
def module_M3 : PrimeKrylovModule :=
  advanceKrylovStep module_M2 2.0 1.0 5

/-- Resulting Tridiagonal Matrix T_3:
    diag = [4.0, 3.0, 2.0], off-diag = [2.0, 3.0]. -/
def tridiagonal_T3 : TridiagonalMatrix :=
  toTridiagonal module_M3

/-! ## 2. Invariant Evaluations on M_3 -/

/-- Trace of M_3: Tr(M_3) = 4.0 + 3.0 + 2.0 = 9.0. -/
def trace_M3 : Float :=
  trace module_M3

/-- Prime-weighted off-diagonal energy: E(M_3) = 2.0^2 + 3.0^2 = 4.0 + 9.0 = 13.0. -/
def energy_M3 : Float :=
  primeWeightedEnergy module_M3

/-- Scale-free coupling ratio r_2 = (1.0 * 3) / (1.0 * 2) = 1.5. -/
def couplingRatios_M3 : List Float :=
  scaleFreeCouplingRatios module_M3

/-- Prime-exponent signature: s_3 = log_2(2) + log_3(3) = 1.0 + 1.0 = 2.0. -/
def exponentSignature_M3 : Float :=
  primeExponentSignature module_M3

/-! ## 3. Recursive Feedback Dynamics -/

/-- Feedback refinement starting from initial estimate λ_0 = 5.0 with learning rate 0.1. -/
def refinedLambda_step5 : Float :=
  recursiveFeedbackUpdate 5.0 0.1 [2, 3, 5] [0.5, 0.5, 0.5] 5

/-! ## 4. Prime Tensor Module & QPE Distribution -/

/-- Prime tensor module N_3 with prime-encoded eigenpairs:
    p=2 -> λ=5.214, p=3 -> λ=3.0, p=5 -> λ=0.786. -/
def tensorModule_N3 : PrimeTensorModule :=
  {
    dim := 3
    eigenpairs := [
      { primeLabel := 2, eigenvalue := 5.214 },
      { primeLabel := 3, eigenvalue := 3.0 },
      { primeLabel := 5, eigenvalue := 0.786 }
    ]
  }

/-- Prime tensor state Ψ(t). -/
def tensorState_N3 : PrimeTensorState :=
  makeTensorState tensorModule_N3

/-- QPE measurement probability distribution. -/
def qpeDistribution_N3 : PhaseEstimationDistribution :=
  phaseEstimationFunctor tensorModule_N3

end EigenSolvers.Examples
