-- import UAC.Core

namespace Multiplicity.UAC.SQD

-- 1. SQD Constants for Q-SQD Quantization and Stability Bounds
-- These must be scaled to avoid floating point in Lean
def B_DEFAULT : Nat := 50
def LAMBDA_GUARD_SCALED : Nat := 20000 -- 2.0 * 10000
def MAX_WEIGHT : Nat := 2

-- 2. C-SQD Multiplicity (Hamming combination for formalization)
def computeHamming : Nat → Nat → Nat
| _, 0 => 1
| 0, _ + 1 => 0
| n + 1, k + 1 => computeHamming n k + computeHamming n (k + 1)

-- 3. Q-SQD Instability Predicate
-- |f_hat - q/B| < lambda * se
-- Scaled up by B * SCALE to avoid floats:
-- |f_hat_scaled * B - q * SCALE| < lambda_scaled * se_scaled * B / SCALE
def checkStability (f_hat_scaled : Int) (q : Int) (se_scaled : Int) (b_val : Nat) (lambda_scaled : Nat) (scale : Nat) : Bool :=
  let lhs_diff := f_hat_scaled * (b_val : Int) - q * (scale : Int)
  let lhs := lhs_diff.natAbs * scale
  let rhs := lambda_scaled * se_scaled.natAbs * b_val
  lhs < rhs

end Multiplicity.UAC.SQD
