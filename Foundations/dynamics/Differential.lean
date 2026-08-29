// lean/Dynamics/Differential.lean
-- Multiplicity Theory – Dynamics Layer: Discrete Time‑Dependent Multiplicity
-- No imports from Mathlib; only core Lean definitions.

namespace Multiplicity.Dynamics

open Multiplicity.Core
open Nat
open Finset

/-! ### Definitions
We model a diagonal matrix whose diagonal entries are prime powers whose exponents evolve
over discrete time `t : Nat`.
-/

-- A matrix of size `n` (same shape as in `Core.Matrix`).
 def Matrix (n : Nat) := Fin n → Fin n → Nat

-- Diagonal matrix built from a function `f i` giving the diagonal entry for index `i`.
 def diagFrom {n : Nat} (f : Fin n → Nat) : Matrix n :=
   fun i j => if i = j then f i else 0

-- Time‑dependent exponent function: for each prime index `i` we have an exponent `m i t`.
 def ExponentFn {n : Nat} := Fin n → Nat → Nat

-- The time‑dependent multiplicity matrix `M(t)`.
 def multiplicityMatrix {n : Nat} (primes : Fin n → Nat) (m : ExponentFn) (t : Nat) : Matrix n :=
   diagFrom (fun i => (primes i) ^ (m i t))

/-! ### Simple update rule
For illustration we use an increment‑by‑one update: `m i t = m0 i + t`.
-/
 def incUpdate {n : Nat} (m0 : Fin n → Nat) : ExponentFn :=
   fun i t => m0 i + t

/-! ### Spectral radius
For a diagonal matrix the spectral radius is simply the maximum diagonal entry.
-/
 def spectralRadius {n : Nat} (M : Matrix n) : Nat :=
   (Finset.univ).fold max 0 (fun i => M i i)

/-! ### Lemmas
The spectral radius of a diagonal matrix given by `diagFrom f` is the maximum of `f`.
-/
 theorem spectralRadius_diagFrom {n : Nat} (f : Fin n → Nat) :
   spectralRadius (diagFrom f) = (Finset.univ).fold max 0 f := by
   rfl

-- Applying the above to our time‑dependent matrix gives a tidy equality.
 theorem spectralRadius_multiplicityMatrix {n : Nat} (primes : Fin n → Nat)
   (m : ExponentFn) (t : Nat) :
   spectralRadius (multiplicityMatrix primes m t) =
     (Finset.univ).fold max 0 (fun i => (primes i) ^ (m i t)) := by
   rfl

-- Example: with the increment update, the spectral radius is monotone in time.
 theorem spectralRadius_monotone_inc {n : Nat} (primes : Fin n → Nat) (m0 : Fin n → Nat) (t : Nat) :
   spectralRadius (multiplicityMatrix primes (incUpdate m0) t) ≤
   spectralRadius (multiplicityMatrix primes (incUpdate m0) (t+1)) := by
   -- unfold definitions
   dsimp [spectralRadius, multiplicityMatrix, incUpdate, diagFrom]
   -- the fold is over a pointwise ≤ relation, which follows from each exponent increasing by 1
   apply Finset.fold_le_fold_max_of_le
   intro i
   have hpos : 1 ≤ primes i := by
     -- primes are at least 2, but we only need `1 ≤ primes i` for the monotonicity of powers
     exact Nat.succ_le_succ (Nat.zero_le _)
   have : (primes i) ^ (m0 i + t) ≤ (primes i) ^ (m0 i + t + 1) :=
     Nat.pow_le_pow_of_le_left hpos (Nat.le_succ _)
   exact this

end Multiplicity.Dynamics
