-- PIRTM Init.lean - Core only imports, basic helpers (no mathlib)
import Init.Data.List.Basic
import Init.Data.Nat.Basic
import Init.Data.Prod

namespace PIRTM

/--
Rotate a list left by one position.
[init] Helper used in extremal ordering proof.
-/
def rotateLeft (l : List α) : List α :=
  match l with
  | [] => []
  | x :: xs => xs ++ [x]

/--
Normalized signature: sorted list of (prime, exponent) with exp > 0.
Used for multiplicity functor domain.
-/
def normalizeSig (s : List (Nat × Nat)) : List (Nat × Nat) :=
  (s.filter (fun p => p.2 > 0)).qsort (fun a b => a.1 ≤ b.1)

/--
Prime signatures as finite support lists.
Structure with invariant that data is normalized.
-/
structure PrimeSig where
  data : List (Nat × Nat)
  normalized : data = normalizeSig data

/--
Multiplicities as rational numbers (simplified).
Uses Nat for integral exponents; extend to rationals if needed.
-/
abbrev MultiplicityValue := Nat

/--
Multiplicity functor M(s) = ∏ p^e.
Simplified to Nat for core proofs.
-/
def multiplicity (s : PrimeSig) : MultiplicityValue :=
  (normalizeSig s.data).foldl (fun acc p => acc * (p.1 ^ p.2)) 1

/--
Positional weight w_i for extremal ordering.
Proof-relevant version: weight at index i in permutation.
-/
def positionalWeight (primes : List Nat) (idx : Nat) (val : Nat) : Nat :=
  primes.length * val - idx

/--
Theorem: rotateLeft is length-preserving.
By structural reasoning on lists.
-/
theorem rotateLeft_length (l : List α) : (rotateLeft l).length = l.length := by
  match l with
  | [] => rfl
  | x :: xs =>
    simp [rotateLeft, List.length]

/--
Theorem: normalizeSig preserves empty list.
-/
theorem normalizeSig_nil : normalizeSig ([]) = ([]) := by
  simp [normalizeSig]

/--
Theorem: Empty signature has multiplicity 1.
-/
theorem multiplicity_nil : multiplicity { data := [], normalized := by rfl } = 1 := by
  simp [multiplicity]

end PIRTM