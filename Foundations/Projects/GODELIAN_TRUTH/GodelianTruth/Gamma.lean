import Init
import GodelianTruth.Core

/-! # The Grounded Operator Γ

Formalizes the grounded, non-expansive operator Γ on valuations.
Clauses: arithmetic atoms, provability atoms, truth/quotation, strong Kleene connectives.
-/

namespace GodelianTruth.Gamma

open GodelianTruth

/-- Strong Kleene negation on fixed-point values: ¬x = 1 - x. -/
def skNeg (x : Nat) : Nat :=
  FP_DEN - x

/-- Strong Kleene conjunction: min(x, y). -/
def skAnd (x y : Nat) : Nat :=
  if x <= y then x else y

/-- Strong Kleene disjunction: max(x, y). -/
def skOr (x y : Nat) : Nat :=
  if x >= y then x else y

/-- Strong Kleene implication: ¬x ∨ y = 1 - x + y (clipped to [0, FP_DEN]). -/
def skImpl (x y : Nat) : Nat :=
  let z := FP_DEN - x + y
  if z < 0 then 0 else if z > FP_DEN then FP_DEN else z

/-- Strong Kleene biconditional: (x ⇒ y) ∧ (y ⇒ x). -/
def skIff (x y : Nat) : Nat :=
  skAnd (skImpl x y) (skImpl y x)

/-- Meta-level provability oracle (demo).
    In a full implementation, this would interface with a verified Rust prover.
    Here we use a deterministic lookup for the demo sentences. -/
def provOracle (φ : Sentence) : Nat :=
  match φ with
  | Sentence.atomP => FP_DEN      -- P is provable
  | Sentence.atomQ => 0           -- Q is not provable
  | Sentence.atomG => 0           -- G is not provable (soundness)
  | Sentence.notG => FP_DEN       -- ¬G is provable iff G is not
  | Sentence.pAndQ => 0           -- P ∧ Q is not provable (Q fails)
  | Sentence.other => 0

/-- The grounded operator Γ: Valuation → Valuation.
    Applies meta-level evaluation and strong Kleene connectives. -/
def Gamma (v : Valuation) : Valuation :=
  fun φ =>
    match φ with
    | Sentence.atomP => provOracle φ
    | Sentence.atomQ => provOracle φ
    | Sentence.atomG => skNeg (provOracle φ)  -- G ↔ ¬Prov_F(G)
    | Sentence.notG => skNeg (v φ)            -- grounded truth quotation
    | Sentence.pAndQ => skAnd (v Sentence.atomP) (v Sentence.atomQ)
    | Sentence.other => 0

/-- Γ is well-defined: all output values are valid fixed-point values. -/
theorem gamma_valid (v : Valuation) (h_v : ∀ φ, validFP (v φ)) (φ : Sentence) :
  validFP ((Gamma v) φ) := by
  cases φ <;> simp [Gamma, validFP, provOracle, skNeg, skAnd]
  case pAndQ =>
    have h1 : 0 <= v Sentence.atomP := by exact (h_v Sentence.atomP).1
    have h2 : v Sentence.atomP <= FP_DEN := by exact (h_v Sentence.atomP).2
    have h3 : 0 <= v Sentence.atomQ := by exact (h_v Sentence.atomQ).1
    have h4 : v Sentence.atomQ <= FP_DEN := by exact (h_v Sentence.atomQ).2
    by_cases h : v Sentence.atomP <= v Sentence.atomQ <;> simp [h]
    · omega
    · omega

end GodelianTruth.Gamma
