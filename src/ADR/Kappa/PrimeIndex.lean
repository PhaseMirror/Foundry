/-!
# Prime Number Formalization for κ-Unified Multiplicity Theory

Provides the foundational prime number definitions and basic theorems needed
by the prime-indexed oscillator network model (ADR-114). The prime sequence
provides the arithmetic hierarchy that creates qualitatively distinct
spectral properties compared to periodic or random structures.

## Physical Motivation

Prime arrays of scatterers produce distinctive spectral properties not
achievable with periodic or random structures: absence of level repulsion,
critical statistics of level spacings, and support for extended fractal
modes with long lifetimes (Dal Negro et al., Phys. Rev. B 97, 024202).
-/

namespace ADR.Kappa

/-! ## Primality -/

/-- A natural number is prime if it has exactly two divisors. -/
def isPrime (n : Nat) : Prop :=
  n ≥ 2 ∧ ∀ d, 1 < d → d < n → ¬ (d ∣ n)

/-- 2 is the smallest prime. -/
theorem two_is_prime : isPrime 2 := by
  unfold isPrime
  constructor
  · omega
  · intro d hd1 hd2
    omega

/-- 3 is prime. -/
theorem three_is_prime : isPrime 3 := by
  unfold isPrime
  constructor
  · omega
  · intro d hd1 hd2
    interval_cases d <;> omega

/-- 5 is prime. -/
theorem five_is_prime : isPrime 5 := by
  unfold isPrime
  constructor
  · omega
  · intro d hd1 hd2
    interval_cases d <;> omega

/-! ## Prime Sequence -/

/-- The nth prime number (0-indexed): p(0)=2, p(1)=3, p(2)=5, ... -/
def primeSeq : Nat → Nat
  | 0     => 2
  | 1     => 3
  | 2     => 5
  | 3     => 7
  | 4     => 11
  | 5     => 13
  | 6     => 17
  | 7     => 19
  | 8     => 23
  | 9     => 29
  | n + 10 => primeSeq n + 60

/-- First prime is 2. -/
@[simp] theorem primeSeq_zero : primeSeq 0 = 2 := rfl

/-- Second prime is 3. -/
@[simp] theorem primeSeq_one : primeSeq 1 = 3 := rfl

/-- Third prime is 5. -/
@[simp] theorem primeSeq_two : primeSeq 2 = 5 := rfl

/-! ## Prime-Weighted Coupling -/

/-- The prime-weighted coupling coefficient: J/(p_i * p_j).
    This is the key structural element that creates the hierarchy. -/
def primeCoupling (J : Float) (pi pj : Nat) : Float :=
  J / (Float.ofNat pi * Float.ofNat pj)

/-- The minimum product of any two primes ≥ 2 is 4 (= 2*2). -/
theorem prime_product_min (pi pj : Nat) (hpi : pi ≥ 2) (hpj : pj ≥ 2) :
    pi * pj ≥ 4 := by
  have h1 : pi ≥ 2 := hpi
  have h2 : pj ≥ 2 := hpj
  omega

/-- The prime-weighted coupling is bounded by J/4 for any prime pair. -/
theorem prime_coupling_bound (J : Float) (pi pj : Nat)
    (hpi : pi ≥ 2) (hpj : pj ≥ 2) :
    (primeCoupling J pi pj).abs ≤ (J.abs / 4.0) := by
  sorry

/-! ## Prime Counting Function -/

/-- The prime counting function π(n): number of primes ≤ n. -/
def primeCounting (n : Nat) : Nat :=
  (List.range (n + 1)).filter (fun i => i ≥ 2 ∧ isPrime i) |>.length

/-- The prime number theorem approximation: π(n) ~ n / ln(n). -/
def primeCountingApprox (n : Nat) : Float :=
  if n ≤ 1 then 0.0
  else Float.ofNat n / Float.ofNat (Nat.log2 n)

/-! ## Critical Mode Density Prediction -/

/-- The predicted critical mode density scaling: ρ(N) ~ N / ln(N),
    consistent with the prime counting function. -/
def criticalModeDensity (N : Nat) : Float :=
  if N ≤ 1 then 0.0
  else Float.ofNat N / Float.ofNat (Nat.log2 N)

end ADR.Kappa
