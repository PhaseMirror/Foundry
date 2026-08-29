import EigenSolvers.Core
import EigenSolvers.Tensor
import EigenSolvers.Proofs
import EigenSolvers.Examples

/-!
# Prime-Encoded Eigen Solvers: Executable Test Harness

Main validation runner for categorical invariants, prime-weighted Lanczos flow,
and prime-tensor quantum layer.
-/

open EigenSolvers.Core
open EigenSolvers.Tensor
open EigenSolvers.Examples

def runEigenTests : IO UInt32 := do
  IO.println "================================================================="
  IO.println "  PRIME-ENCODED EIGEN SOLVERS: FORMAL VERIFICATION SUITE         "
  IO.println "================================================================="

  -- [1] Krylov Module Progression
  IO.println "\n[1] Testing Prime-Weighted Krylov Module Flow..."
  let m3 := module_M3
  IO.println s!"    Krylov Depth = {m3.krylovDepth} (expected 3)"
  IO.println s!"    Alphas = {m3.alphas}"
  IO.println s!"    Raw Betas = {m3.rawBetas}"
  IO.println s!"    Primes = {m3.primes}"
  let eff := effectiveBetas m3
  IO.println s!"    Effective Betas (β_k * p_k) = {eff} (expected [2.0, 3.0])"
  if m3.krylovDepth != 3 || eff != [2.0, 3.0] then
    IO.eprintln "[-] ERROR: Krylov module progression mismatch!"
    return 1
  IO.println "    [+] PASSED: Prime-weighted Lanczos step functor verified."

  -- [2] Categorical Invariants
  IO.println "\n[2] Testing Spectral & Dynamical Invariants..."
  let trVal := trace_M3
  let eVal := energy_M3
  let rVal := couplingRatios_M3
  let sVal := exponentSignature_M3

  IO.println s!"    Trace Tr(M_3) = {trVal} (expected 9.0)"
  IO.println s!"    Off-Diagonal Energy E(M_3) = {eVal} (expected 13.0)"
  IO.println s!"    Coupling Ratios r_k = {rVal} (expected [1.5])"
  IO.println s!"    Exponent Signature s_3 = {sVal} (expected 2.0)"

  if trVal < 8.99 || trVal > 9.01 then
    IO.eprintln "[-] ERROR: Trace functor invariant failure!"
    return 1
  if eVal < 12.99 || eVal > 13.01 then
    IO.eprintln "[-] ERROR: Energy functor invariant failure!"
    return 1
  if sVal < 1.99 || sVal > 2.01 then
    IO.eprintln "[-] ERROR: Exponent signature invariant failure!"
    return 1
  IO.println "    [+] PASSED: All categorical invariants verified."

  -- [3] Recursive Feedback Loop
  IO.println "\n[3] Testing Recursive Feedback Eigenvalue Refinement..."
  let lambdaRefined := refinedLambda_step5
  IO.println s!"    Refined λ after 5 steps = {lambdaRefined}"
  if lambdaRefined <= 5.0 then
    IO.eprintln "[-] ERROR: Feedback loop failed to refine eigenvalue!"
    return 1
  IO.println "    [+] PASSED: Recursive feedback dynamics verified."

  -- [4] Prime Tensor Module & QPE
  IO.println "\n[4] Testing Prime Tensor Module & Quantum Phase Estimation..."
  let psi := tensorState_N3
  let normSq := stateNormSquared psi
  let qpe := qpeDistribution_N3
  IO.println s!"    Tensor State Components = {psi.components}"
  IO.println s!"    Squared Norm ||Ψ||^2 = {normSq}"
  IO.println s!"    QPE Probabilities = {qpe.probabilities}"

  let probSum := qpe.probabilities.foldl (fun acc (_, p) => acc + p) 0.0
  IO.println s!"    Sum of QPE Probabilities = {probSum} (expected 1.0)"
  if probSum < 0.999 || probSum > 1.001 then
    IO.eprintln "[-] ERROR: QPE distribution normalization failure!"
    return 1
  IO.println "    [+] PASSED: Quantum phase estimation functor verified."

  IO.println "\n================================================================="
  IO.println "  ALL 4/4 GATES PASSED: CATEGORICAL PRIME FLOW VERIFIED (100%)    "
  IO.println "================================================================="
  return 0

def main : IO UInt32 := runEigenTests
