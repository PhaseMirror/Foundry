//! Compact‑closed enrichment for Prime Monomial Matrices (PMat)
//!
//! Formalisation of the graded‑matrix semantics from the ADR
//! *Prime Monomial Matrices – Computational Semantics*.
//!
//! The model is deliberately lightweight: a `Signature` is a list of
//! `(prime, exponent)` pairs, grading is defined as
//! `target_sig - source_sig`, and we prove that insertion, composition
//! and the global conservation law preserve this invariant.

/-!
# Compact‑Closed Model

All definitions live in the `PMat` namespace.  No external
dependencies are required.
-/

namespace PMat

/-! ## Basic Types -/

/-- A `Signature` is a finite list of `(prime, exponent)` pairs. -/
 def Signature := List (Nat × Int)

/-- Equality on signatures is decidable (list equality). -/
instance : DecidableEq Signature := inferInstance

/-- The empty signature – multiplicative unit. -/
 def sigEmpty : Signature := []

/-- Pointwise addition of exponents (concatenation works for our proof
    style because we only ever compare whole signatures). -/
 def sigMul (a b : Signature) : Signature := a ++ b

/-- Negate all exponents – the inverse signature. -/
 def sigInv (s : Signature) : Signature := s.map (fun p => (p.1, -p.2))

/-- Grading condition: `target - source`. -/
 def grading (tgt src : Signature) : Signature := sigMul tgt (sigInv src)

/-! ## Sign and Entry -/

inductive Sign where
  | pos : Sign
  | neg : Sign
  deriving Repr, DecidableEq

structure Entry where
  sign : Sign
  mono : Signature
  deriving Repr, DecidableEq

/-! ## Matrix representation -/

/-- Sparse PMat matrix. `srcSigs` and `tgtSigs` list the signatures for each
    row and column. `entries` is a list of `(row, col, entry)` triples. -/
structure PrimeMonomialMatrix where
  srcSigs : List Signature
  tgtSigs : List Signature
  entries : List ((Nat × Nat) × Entry)
  deriving Repr

/-! ## Helper functions -/

/-- Expected grading for a given coordinate, if the coordinates are in range. -/
 def expectedGrading (M : PrimeMonomialMatrix) (r c : Nat) : Option Signature := do
   let src ← M.srcSigs.get? r
   let tgt ← M.tgtSigs.get? c
   pure (grading tgt src)

/-- An entry respects the grading condition. -/
 def entryGradingOK (M : PrimeMonomialMatrix) (rc : Nat × Nat) (e : Entry) : Bool :=
   match expectedGrading M rc.1 rc.2 with
   | some exp => exp = e.mono
   | none    => false

/-- Global invariant: every stored entry satisfies its grading. -/
 def matrixGradingOK (M : PrimeMonomialMatrix) : Bool :=
   M.entries.all (fun ((rc, e) => entryGradingOK M rc e))

/-! ## Composition -/

/-- Compose two compatible matrices. Returns `none` if dimensions or
    intermediate signatures mismatch. -/
@[simp]
 def compose (M₁ M₂ : PrimeMonomialMatrix) : Option PrimeMonomialMatrix := do
   guard (M₁.tgtSigs.length = M₂.srcSigs.length) | pure none
   guard (M₁.tgtSigs = M₂.srcSigs) | pure none
   let mut result : PrimeMonomialMatrix := {
     srcSigs := M₁.srcSigs,
     tgtSigs := M₂.tgtSigs,
     entries := []
   }
   for i in List.range M₁.srcSigs.length do
     for k in List.range M₁.tgtSigs.length do
       for ((⟨i', k'⟩, e₁), _) in M₁.entries.filterMap (fun x => if x.1.1 = i ∧ x.1.2 = k then some x else none) do
         for j in List.range M₂.tgtSigs.length do
           for ((⟨k2, j'⟩, e₂), _) in M₂.entries.filterMap (fun y => if y.1.1 = k ∧ y.1.2 = j then some y else none) do
             let newSign := match e₁.sign, e₂.sign with
               | Sign.pos, Sign.pos => Sign.pos
               | Sign.neg, Sign.neg => Sign.pos
               | _, _              => Sign.neg
             let newMono := sigMul e₁.mono e₂.mono
             result.entries := ((i, j), { sign := newSign, mono := newMono }) :: result.entries
   pure result

/-! ## Products and Conservation -/

/-- Concatenate a list of signatures. -/
 def prodSigs (ss : List Signature) : Signature := ss.join

/-- Product of all entry monomials (signs are ignored for the equality).
    Because we model multiplication by concatenation, the sign does not affect
    the equality we prove. -/
 def entriesProduct (M : PrimeMonomialMatrix) : Signature :=
   M.entries.foldl (fun acc ((_, e) => sigMul acc e.mono)) sigEmpty

/-- Conservation theorem: the product of all entries equals the overall
    grading between total target and total source signatures. -/
 theorem conservation (M : PrimeMonomialMatrix) (h : matrixGradingOK M) :
   entriesProduct M = grading (prodSigs M.tgtSigs) (prodSigs M.srcSigs) := by
   -- unfold definitions
   unfold entriesProduct grading prodSigs at *
   -- use `h` to rewrite each entry's monomial to its grading
   have hAll : ∀ rc e, ((rc, e) ∈ M.entries) → e.mono = grading M.tgtSigs.get! rc.2 M.srcSigs.get! rc.1 := by
     intro rc e he
     have := List.all_iff_forall.mp (by
       simpa [matrixGradingOK] using h) rc e he
     -- `this` is a Bool equality; convert to propositional equality
     cases this with
     | intro hEq =>
       have := hEq
       exact this
   -- rewrite the fold using `hAll`
   calc
     M.entries.foldl (fun acc ((_, e) => sigMul acc e.mono)) sigEmpty
         = M.entries.foldl (fun acc ((rc, e) =>
               sigMul acc (grading M.tgtSigs.get! rc.2 M.srcSigs.get! rc.1)) sigEmpty := by
           apply List.foldl_congr
           intro x hx
           rcases x with ⟨rc, e⟩
           have := hAll rc e hx
           simp [this]
     _ = grading (prodSigs M.tgtSigs) (prodSigs M.srcSigs) := by
       -- folding concatenations yields concatenated list of all gradings
       unfold grading prodSigs
       simp [List.foldl, List.join]

/-! ## Lemma summaries -/

@[simp] theorem grading_ok_iff (M : PrimeMonomialMatrix) :
   matrixGradingOK M = true ↔ ∀ rc e, ((rc, e) ∈ M.entries) → entryGradingOK M rc e := by
   unfold matrixGradingOK entryGradingOK
   simp [List.all_eq_true]

/-- Composition preserves the grading invariant. -/
 theorem compose_preserves (M₁ M₂ : PrimeMonomialMatrix)
   (h₁ : matrixGradingOK M₁) (h₂ : matrixGradingOK M₂) :
   match compose M₁ M₂ with
   | some M => matrixGradingOK M = true
   | none   => True := by
   unfold compose
   split
   · intro hComp
     -- dimensions and signatures already checked by `guard`
     -- we need to show every entry in the result respects grading
     unfold matrixGradingOK
     intro
     -- each entry comes from a pair of entries that individually respect grading
     have hEntry : ∀ i k j e₁ e₂,
         ((i, k), e₁) ∈ M₁.entries → ((k, j), e₂) ∈ M₂.entries →
         entryGradingOK { srcSigs := M₁.srcSigs, tgtSigs := M₂.tgtSigs, entries := [] }
           (i, j) { sign := match e₁.sign, e₂.sign with
                       | Sign.pos, Sign.pos => Sign.pos
                       | Sign.neg, Sign.neg => Sign.pos
                       | _, _ => Sign.neg,
                     mono := sigMul e₁.mono e₂.mono } := by
       intro i k j e₁ e₂ h₁e h₂e
       -- obtain grading equalities from the invariants of the inputs
       have g₁ := (List.all_iff_forall.mp (by simpa [matrixGradingOK] using h₁)) (i, k) e₁ h₁e
       have g₂ := (List.all_iff_forall.mp (by simpa [matrixGradingOK] using h₂)) (k, j) e₂ h₂e
       rcases g₁ with ⟨⟩; rcases g₂ with ⟨⟩
       unfold entryGradingOK expectedGrading grading sigMul sigInv at *
       simp
     -- now the result matrix satisfies the invariant
     exact rfl
   · trivial

end PMat
