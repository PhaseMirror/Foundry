import moc.Ramanujan.Core
import moc.Ramanujan.Theorems
open MOC.Ramanujan

/-! # Ramanujan Test Harness

Run with `lake test`.

Tests cover:
1. Prime factorization and valuation
2. Divisor function d(n), Ω(n), ω(n)
3. Highly composite numbers
4. Multiplicity entropy
5. τ-function
6. Partition function
7. Profile reconstruction and sorting
-/

/-! Test divisor count for small values. -/
def test_divisor_count_small : Bool :=
  divisorCount 1 = 1 &&
  divisorCount 2 = 2 &&
  divisorCount 12 = 6 &&
  divisorCount 60 = 12

/-! Test big_omega and small_omega. -/
def test_omega_small : Bool :=
  bigOmega 1 = 0 &&
  bigOmega 12 = 3 &&
  smallOmega 12 = 2 &&
  smallOmega 60 = 3

/-! Test HCN sequence start. -/
def test_hcn_start : Bool :=
  isHCN 1 = true &&
  isHCN 2 = true &&
  isHCN 4 = true &&
  isHCN 6 = true &&
  isHCN 12 = true &&
  isHCN 8 = false &&
  isHCN 9 = false

/-! Test τ-function small values. -/
def test_tau_small : Bool :=
  tau 1 = 1 &&
  tau 2 = -24 &&
  tau 3 = 252 &&
  tau 4 = -1472 &&
  tau 5 = -4830 &&
  tau 6 = 6048 &&
  tau 7 = -16744 &&
  tau 8 = 84480 &&
  tau 9 = -39408 &&
  tau 10 = -39024

/-! Test partition function small values. -/
def test_partition_small : Bool :=
  partitionCount 0 = 1 &&
  partitionCount 1 = 1 &&
  partitionCount 2 = 2 &&
  partitionCount 3 = 3 &&
  partitionCount 4 = 5 &&
  partitionCount 5 = 7 &&
  partitionCount 10 = 42

/-! Test entropy of prime is zero. -/
def test_entropy_prime_zero : Bool :=
  multiplicityEntropy 2 = 0 &&
  multiplicityEntropy 97 = 0

/-! Test entropy of 12. -/
def test_entropy_12 : Bool :=
  let e := multiplicityEntropy 12
  let expected := -((2 : Float) / 3 * ((2 : Float) / 3).log + (1 : Float) / 3 * ((1 : Float) / 3).log)
  Float.abs (e - expected) < 1e-10

/-! Test profile reconstructs to n. -/
def test_profile_reconstructs : Bool :=
  let profile := multiplicityProfile 12
  factorProductFromProfile profile = 12

/-! Test profile is sorted. -/
def test_profile_sorted : Bool :=
  let profile := multiplicityProfile 60
  match profile with
  | [] => true
  | [_] => true
  | p1 :: p2 :: rest => p1.prime < p2.prime && test_profile_sorted_aux (p2 :: rest)
where
  test_profile_sorted_aux : MultiplicityProfile → Bool
    | [] => true
    | [_] => true
    | p1 :: p2 :: rest => p1.prime < p2.prime && test_profile_sorted_aux (p2 :: rest)

/-! Test τ multiplicative on coprimes. -/
def test_tau_multiplicative : Bool :=
  tauMultiplicative 2 3 = tau 2 * tau 3 &&
  tauMultiplicative 4 3 = tau 4 * tau 3 &&
  tauMultiplicative 2 5 = tau 2 * tau 5

/-! Test pentagonal function. -/
def test_pentagonal : Bool :=
  pentagonalPos 1 = 1 &&
  pentagonalPos 2 = 5 &&
  pentagonalPos 3 = 12 &&
  pentagonalNeg 1 = 2 &&
  pentagonalNeg 2 = 7

/-! Test gcd and lcm. -/
def test_gcd_lcm : Bool :=
  gcd 12 18 = 6 &&
  lcm 4 6 = 12 &&
  gcd 17 97 = 1

def main : IO Unit := do
  IO.println "Running Ramanujan Multiplicity Test Harness..."

  if test_divisor_count_small then
    IO.println "✓ Divisor count tests pass."
  else
    IO.println "✗ Divisor count tests failed."
    return

  if test_omega_small then
    IO.println "✓ Omega tests pass."
  else
    IO.println "✗ Omega tests failed."
    return

  if test_hcn_start then
    IO.println "✓ HCN tests pass."
  else
    IO.println "✗ HCN tests failed."
    return

  if test_tau_small then
    IO.println "✓ τ-function tests pass."
  else
    IO.println "✗ τ-function tests failed."
    return

  if test_partition_small then
    IO.println "✓ Partition tests pass."
  else
    IO.println "✗ Partition tests failed."
    return

  if test_entropy_prime_zero then
    IO.println "✓ Entropy of prime is zero."
  else
    IO.println "✗ Entropy of prime test failed."
    return

  if test_entropy_12 then
    IO.println "✓ Entropy of 12 matches analytic formula."
  else
    IO.println "✗ Entropy of 12 test failed."
    return

  if test_profile_reconstructs then
    IO.println "✓ Profile reconstructs to n."
  else
    IO.println "✗ Profile reconstruction test failed."
    return

  if test_profile_sorted then
    IO.println "✓ Profile sorted by prime."
  else
    IO.println "✗ Profile sorted test failed."
    return

  if test_tau_multiplicative then
    IO.println "✓ τ multiplicative on coprimes."
  else
    IO.println "✗ τ multiplicative test failed."
    return

  if test_pentagonal then
    IO.println "✓ Pentagonal numbers correct."
  else
    IO.println "✗ Pentagonal test failed."
    return

  if test_gcd_lcm then
    IO.println "✓ GCD/LCM tests pass."
  else
    IO.println "✗ GCD/LCM tests failed."
    return

  IO.println "All Ramanujan multiplicity tests passed!"
