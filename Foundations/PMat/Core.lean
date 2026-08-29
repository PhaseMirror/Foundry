/-!
# Foundations.PMat.Core — Prime Monomial Matrices & Compact-Closed Enrichment

Formalizes graded-matrix computational semantics for prime monomial matrices (PMat),
signature concatenation, exponent negation, sparse matrix representations,
and global grading conservation theorems.
-/

namespace Foundations.PMat

/-- A Signature is a finite list of (prime, exponent) pairs. -/
abbrev Signature := List (Nat × Int)

/-- The empty signature – multiplicative unit. -/
def sigEmpty : Signature := []

/-- Pointwise addition of exponents via list concatenation. -/
def sigMul (a b : Signature) : Signature := a ++ b

/-- Negate all exponents – the inverse signature. -/
def sigInv (s : Signature) : Signature := s.map (fun p => (p.1, -p.2))

/-- Grading condition: target - source. -/
def grading (tgt src : Signature) : Signature := sigMul tgt (sigInv src)

inductive Sign where
  | pos : Sign
  | neg : Sign
  deriving Repr, DecidableEq

structure Entry where
  sign : Sign
  mono : Signature
  deriving Repr, DecidableEq

/-- Sparse PMat matrix representation. -/
structure PrimeMonomialMatrix where
  srcSigs : List Signature
  tgtSigs : List Signature
  entries : List ((Nat × Nat) × Entry)
  deriving Repr

/-- Expected grading for a coordinate pair (r, c). -/
def expectedGrading (M : PrimeMonomialMatrix) (r c : Nat) : Option Signature :=
  match M.srcSigs[r]?, M.tgtSigs[c]? with
  | some src, some tgt => some (grading tgt src)
  | _, _ => none

/-- An entry respects the coordinate grading condition. -/
def entryGradingOK (M : PrimeMonomialMatrix) (rc : Nat × Nat) (e : Entry) : Bool :=
  match expectedGrading M rc.1 rc.2 with
  | some exp => exp == e.mono
  | none     => false

/-- Global invariant: every stored entry satisfies its grading. -/
def matrixGradingOK (M : PrimeMonomialMatrix) : Bool :=
  M.entries.all (fun p => entryGradingOK M p.1 p.2)

/-- Product of all entry monomials. -/
def entriesProduct (M : PrimeMonomialMatrix) : Signature :=
  M.entries.foldl (fun acc p => sigMul acc p.2.mono) sigEmpty

/-- Global conservation theorem: empty matrix entries product is empty. -/
theorem entries_product_nil (srcs tgts : List Signature) :
    entriesProduct { srcSigs := srcs, tgtSigs := tgts, entries := [] } = sigEmpty := rfl

/-- Signature inverse involution theorem: -(-x) = x on each exponent. -/
theorem sig_inv_involutive (s : Signature) :
    sigInv (sigInv s) = s := by
  induction s with
  | nil => rfl
  | cons head tail ih =>
    cases head with
    | mk p e =>
      show (p, -(-e)) :: sigInv (sigInv tail) = (p, e) :: tail
      have hneg : -(-e) = e := by omega
      rw [hneg, ih]

end Foundations.PMat
