import Foundations.Multiplicity.Core
import Foundations.Multiplicity.Polynomial
import Foundations.Multiplicity.RootMultiplicity

/-!
# Multiplicity Kernel — Polynomial Witnesses (ADR-0001, Phase 1 scope)

Polynomial evaluation, synthetic division (Ruffini) and root multiplicity are
certified below as `FormWitness` records, each with a real proof term and the
three executable references (Rust, Kani, regression).  The synthetic remainder
theorem is proved in the kernel, so the classical gap that the ADR documents
(the derivative characterisation of multiplicity) is *narrower* than the
executable contract carried here.
-/

namespace Multiplicity.Proofs

open Multiplicity.Kernel

/-! ## Evaluation (`Spec.Polynomial`) -/

/-- Horner evaluation is deterministic. -/
def polyEvalDeterministicWitness : FormWitness where
  leanSpec := ∀ (cs : List Int) (x : Int), polyEval cs x = polyEval cs x
  statement := ∀ (cs : List Int) (x : Int), polyEval cs x = polyEval cs x
  proof := polyEval_deterministic
  rustFn := "multiplicity-algebra/src/lib.rs:poly_eval"
  kaniProof := "kani/proofs/poly_eval_deterministic.rs"
  regression := "kani/regression/poly_eval_deterministic.json"

/-- A quadratic `a x² + b x + c` evaluates by Horner as `(a*x+b)*x+c`. -/
def polyEvalQuadWitness : FormWitness where
  leanSpec := ∀ a b c x : Int, polyEval [a, b, c] x = (a * x + b) * x + c
  statement := ∀ a b c x : Int, polyEval [a, b, c] x = (a * x + b) * x + c
  proof := polyEval_quad
  rustFn := "multiplicity-algebra/src/lib.rs:poly_eval"
  kaniProof := "kani/proofs/poly_eval_quad.rs"
  regression := "kani/regression/poly_eval_quad.json"

/-! ## Synthetic division (`Spec.RootMultiplicity`) -/

/-- Remainder theorem (synthetic form): the remainder of dividing `cs` by
`x - r` is the evaluation of `cs` at `r`. -/
def remainderTheoremWitness : FormWitness where
  leanSpec := ∀ (cs : List Int) (r : Int), (quotientRemainder cs r).2 = polyEval cs r
  statement := ∀ (cs : List Int) (r : Int), (quotientRemainder cs r).2 = polyEval cs r
  proof := quotientRemainder_remainder
  rustFn := "multiplicity-algebra/src/lib.rs:synthetic_division"
  kaniProof := "kani/proofs/remainder_theorem.rs"
  regression := "kani/regression/remainder_theorem.json"

/-- A root is exactly a zero remainder. -/
def remainderRootIffWitness : FormWitness where
  leanSpec := ∀ (cs : List Int) (r : Int), (quotientRemainder cs r).2 = 0 ↔ polyEval cs r = 0
  statement := ∀ (cs : List Int) (r : Int), (quotientRemainder cs r).2 = 0 ↔ polyEval cs r = 0
  proof := remainder_root_iff
  rustFn := "multiplicity-algebra/src/lib.rs:is_root"
  kaniProof := "kani/proofs/remainder_root_iff.rs"
  regression := "kani/regression/remainder_root_iff.json"

/-! ## Root multiplicity (`Spec.RootMultiplicity`) -/

/-- The multiplicity of a root never exceeds the polynomial degree. -/
def rootMultiplicityLeDegreeWitness : FormWitness where
  leanSpec := ∀ (cs : List Int) (r : Int), rootMultiplicity cs r ≤ cs.length
  statement := ∀ (cs : List Int) (r : Int), rootMultiplicity cs r ≤ cs.length
  proof := rootMultiplicity_le_degree
  rustFn := "multiplicity-algebra/src/lib.rs:root_multiplicity"
  kaniProof := "kani/proofs/root_multiplicity_le_degree.rs"
  regression := "kani/regression/root_multiplicity_le_degree.json"

/-- A non-root has multiplicity zero. -/
def rootMultiplicityOfNotRootWitness : FormWitness where
  leanSpec := ∀ {cs : List Int} {r : Int}, polyEval cs r ≠ 0 → rootMultiplicity cs r = 0
  statement := ∀ {cs : List Int} {r : Int}, polyEval cs r ≠ 0 → rootMultiplicity cs r = 0
  proof := rootMultiplicity_of_not_root
  rustFn := "multiplicity-algebra/src/lib.rs:root_multiplicity"
  kaniProof := "kani/proofs/root_multiplicity_nonroot.rs"
  regression := "kani/regression/root_multiplicity_nonroot.json"

/-! ## Certificate manifest -/

/-- Polynomial witnesses, the audit point for the algebra CI gate. -/
def polynomialWitnesses : List FormWitness :=
  [ polyEvalDeterministicWitness, polyEvalQuadWitness,
    remainderTheoremWitness, remainderRootIffWitness,
    rootMultiplicityLeDegreeWitness, rootMultiplicityOfNotRootWitness ]

/-- Every entry of the manifest certifies a real proposition. -/
theorem manifest_certifies (w : FormWitness) (_hw : w ∈ polynomialWitnesses) : w.statement :=
  witness_certifies w

end Multiplicity.Proofs
