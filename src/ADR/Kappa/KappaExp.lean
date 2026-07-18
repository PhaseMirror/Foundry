/-!
# κ-Deformed Exponential and Logarithm

Formalizes the Kaniadakis κ-exponential and κ-logarithm used in the
stationary distribution of the prime-indexed oscillator network. These
functions interpolate between exponential behavior (|x| ≪ 1/κ) and
power-law behavior (|x| ≫ 1/κ).

## Key Properties

- κ-exp(x) = (√(1 + κ²x²) + κx)^(1/κ)
- ln_κ(x) = (x^κ - x^{-κ}) / (2κ)
- κ → 0 recovers standard exponential/logarithm

## Usage

The κ-deformed distribution applies to **classical** probability
distributions on oscillator amplitudes, NOT to quantum state evolution.
This is a deliberate design choice per the revised ADR-114 framework.
-/

namespace ADR.Kappa

/-! ## κ-Deformed Exponential -/

/-- The κ-exponential: exp_κ(x) = (√(1 + κ²x²) + κx)^(1/κ).
    For κ = 0, this reduces to exp(x). -/
def kappaExp (κ x : Float) : Float :=
  if κ == 0.0 then Float.exp x
  else
    let inner := Float.sqrt (1.0 + κ * κ * x * x) + κ * x
    Float.pow inner (1.0 / κ)

/-- The κ-exponential at x = 0 is always 1. -/
@[simp] theorem kappaExp_zero (κ : Float) : kappaExp κ 0.0 = 1.0 := by
  simp [kappaExp]
  split
  · simp
  · simp

/-- For small κ, κ-exp(x) ≈ exp(x). -/
def kappaExpApproximatesExp (κ x : Float) (h_small : Float.abs κ < 0.01) : Prop :=
  Float.abs (kappaExp κ x - Float.exp x) < 0.1 * Float.abs (Float.exp x)

/-! ## κ-Deformed Logarithm -/

/-- The κ-logarithm: ln_κ(x) = (x^κ - x^{-κ}) / (2κ).
    For κ = 0, this reduces to ln(x). -/
def kappaLog (κ x : Float) : Float :=
  if κ == 0.0 then Float.log x
  else if x ≤ 0.0 then 0.0
  else (Float.pow x κ - Float.pow x (-κ)) / (2.0 * κ)

/-- The κ-logarithm of 1 is always 0. -/
@[simp] theorem kappaLog_one (κ : Float) : kappaLog κ 1.0 = 0.0 := by
  simp [kappaLog]
  split
  · simp
  · split
    · simp
    · simp

/-! ## Stationary Distribution -/

/-- The prime-weighted energy for a state vector. -/
def primeEnergy (z : List Float) (primes : List Nat) : Float :=
  (z.zip primes).foldl (fun acc (zi, pi) =>
    acc + zi * zi / Float.ofNat pi
  ) 0.0

/-- The κ-deformed Boltzmann distribution: P_κ(z) ∝ exp_κ(-E(z)/kT). -/
def kappaBoltzmann (κ kT : Float) (z : List Float) (primes : List Nat) : Float :=
  let E := primeEnergy z primes
  kappaExp κ (-E / kT)

/-! ## Non-Additive Entropy Composition -/

/-- The κ-entropy composition rule:
    S_κ(A ∪ B) = S_κ(A) + S_κ(B) + κ · S_κ(A) · S_κ(B) -/
def kappaEntropyCompose (κ SA SB : Float) : Float :=
  SA + SB + κ * SA * SB

/-- For κ = 0, entropy composition is additive (standard). -/
theorem kappa_entropy_additive (SA SB : Float) :
    kappaEntropyCompose 0.0 SA SB = SA + SB := by
  simp [kappaEntropyCompose]

/-! ## Convergence Timescale -/

/-- The κ-corrected convergence timescale:
    τ^κ ~ (1 / η·min_k(γ_k)) · ln_κ(D_KL / ε) -/
def kappaConvergenceTime (κ eta gammaMin dkl epsilon : Float) : Float :=
  if gammaMin > 0.0 ∧ epsilon > 0.0 then
    (1.0 / (eta * gammaMin)) * kappaLog κ (dkl / epsilon)
  else 0.0

end ADR.Kappa
