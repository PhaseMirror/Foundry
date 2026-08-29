import Init

/-! # Godelian Truth — Core Types and Constants

Formalizes the valuation space, sentence enumeration, and fixed-point
parameters for the Godelian Truth framework.

All discrete arithmetic uses `Nat` / `Int` / `Bool` / `List`.
Continuous / IEEE-754 mathematics are delegated to Rust + Kani.
-/

namespace GodelianTruth

/-- Fixed-point denominator for [0,1] valuations. -/
def FP_DEN : Nat := 100

/-- Check if a Nat is a valid fixed-point value in 0..FP_DEN. -/
def validFP (x : Nat) : Prop :=
  0 <= x ∧ x <= FP_DEN

/-- Sentence enumeration for the demo theory F.
    In a full implementation, these would be Gödel-coded sentences. -/
inductive Sentence where
  | atomP      -- Provability atom P
  | atomQ      -- Provability atom Q
  | atomG      -- Gödel sentence G
  | notG       -- ¬G
  | pAndQ      -- P ∧ Q
  | other      -- Placeholder for other sentences
deriving Repr, DecidableEq

/-- A valuation assigns a fixed-point value to each sentence. -/
def Valuation := Sentence → Nat

/-- The zero valuation (all zeros). -/
def zeroValuation : Valuation :=
  fun _ => 0

/-- The uniform 1/2 valuation. -/
def halfValuation : Valuation :=
  fun _ => FP_DEN / 2

/-- Bias valuation c (default: uniform 1/2). -/
def defaultBias : Valuation :=
  halfValuation

/-- Contraction parameter λ (default: 60 representing 0.6). -/
def lambda : Nat := 60

/-- Smoothing parameter α (default: 30 representing 0.3). -/
def alpha : Nat := 30

/-- Derived contraction factor: 1 - λα = 1 - 0.18 = 0.82 → 82. -/
def contractionFactor : Nat :=
  FP_DEN - (lambda * alpha) / FP_DEN

/-- Verify λ is in (0, FP_DEN). -/
theorem lambda_valid : 0 < lambda ∧ lambda < FP_DEN := by native_decide

/-- Verify α is in (0, FP_DEN). -/
theorem alpha_valid : 0 < alpha ∧ alpha < FP_DEN := by native_decide

/-- Verify contraction factor is in (0, FP_DEN). -/
theorem contraction_factor_valid : 0 < contractionFactor ∧ contractionFactor < FP_DEN := by native_decide

/-- Verify contraction factor < FP_DEN (strict contraction). -/
theorem contraction_strict : contractionFactor < FP_DEN := by native_decide

/-- Verify λ * α > 0 (non-trivial contraction). -/
theorem lambda_alpha_positive : lambda * alpha > 0 := by native_decide

/-- Sup-norm distance between two valuations (discrete). -/
def supNorm (v w : Valuation) : Nat :=
  let diffs := [
    (if v Sentence.atomP >= w Sentence.atomP then v Sentence.atomP - w Sentence.atomP else w Sentence.atomP - v Sentence.atomP),
    (if v Sentence.atomQ >= w Sentence.atomQ then v Sentence.atomQ - w Sentence.atomQ else w Sentence.atomQ - v Sentence.atomQ),
    (if v Sentence.atomG >= w Sentence.atomG then v Sentence.atomG - w Sentence.atomG else w Sentence.atomG - v Sentence.atomG),
    (if v Sentence.notG >= w Sentence.notG then v Sentence.notG - w Sentence.notG else w Sentence.notG - v Sentence.notG),
    (if v Sentence.pAndQ >= w Sentence.pAndQ then v Sentence.pAndQ - w Sentence.pAndQ else w Sentence.pAndQ - v Sentence.pAndQ),
    0
  ]
  diffs.foldl (fun acc d => if d > acc then d else acc) 0

/-- Discrepancy between two valuations at a specific sentence. -/
def disc (v w : Valuation) (φ : Sentence) : Nat :=
  let x := v φ
  let y := w φ
  if x >= y then x - y else y - x

end GodelianTruth
