import Init

/-! # AZ-TFTC — Core Types and Constants

Foundational discrete arithmetic for AZ-TFTC.
-/

namespace AZTFTC

/-- Fixed-point denominator. -/
def FP_DEN : Nat := 100

/-- Valid fixed-point value. -/
def validFP (x : Nat) : Prop := 0 <= x ∧ x <= FP_DEN

/-- Decidable fixed-point check. -/
def isValidFP (x : Nat) : Bool := x >= 0 && x <= FP_DEN

/-- Fixed-point addition. -/
def fpAdd (x y : Nat) : Nat :=
  let z := x + y; if z > FP_DEN then FP_DEN else z

/-- Fixed-point subtraction. -/
def fpSub (x y : Nat) : Nat :=
  let z := x - y; if z < 0 then 0 else z

/-- Fixed-point multiplication. -/
def fpMul (x y : Nat) : Nat := (x * y) / FP_DEN

/-- Default parameters. -/
def defaultNPrimes : Nat := 200
def defaultSigma : Nat := 20
def defaultG : Nat := 5
def defaultEta : Nat := 1

/-- Log-coordinate bounds. -/
def uMinFP : Int := -300
def uMaxFP : Int := 700
def defaultM : Nat := 1200

/-- Grid spacing as Float. -/
def duFPfloat : Float := (700.0 - (-300.0)) / Float.ofNat defaultM

/-! ## Primes and log-coordinates -/

/-- Trial division primality test. -/
def isPrime (n : Nat) : Bool :=
  n >= 2 ∧ (n == 2 ∨ (n % 2 == 1 ∧ (List.range (n / 2 + 1)).all (fun d => d < 2 ∨ d >= n ∨ n % d != 0)))

/-- Primes up to n. -/
def primesUpTo (n : Nat) : List Nat := (List.range (n + 1)).filter isPrime

/-- π(n). -/
def pi (n : Nat) : Nat := (primesUpTo n).length

/-- First N primes (filter-based). -/
def firstNPrimes (N : Nat) : List Nat :=
  let all := (List.range 200).filter isPrime
  all.take N

/-- Log of prime scaled by 100. -/
def logPrimeFP (p : Nat) : Nat := (Float.log (Float.ofNat p) * 100.0).floor.toUInt64.toNat

/-- Grid index to u coordinate. -/
def indexToU (j : Nat) (uMin : Float) (du : Float) : Float :=
  uMin + Float.ofNat j * du

/-- Convert u to x. -/
def uToX (uFP : Nat) : Float := Float.exp (Float.ofNat uFP / 100.0)

/-- Verified properties. -/
theorem isPrime_2 : isPrime 2 = true := rfl
theorem isPrime_3 : isPrime 3 = true := rfl
theorem notPrime_4 : isPrime 4 = false := rfl
theorem pi_ten : pi 10 = 4 := rfl
theorem pi_twenty : pi 20 = 8 := rfl
theorem first5_primes : firstNPrimes 5 = [2, 3, 5, 7, 11] := rfl

end AZTFTC
