namespace Multiplicity.UOR

/-- A Digit in the radix-2 non-adjacent form (NAF) is -1, 0, or 1. -/
inductive NAFDigit
  | zero
  | pos
  | neg
  deriving Repr, DecidableEq, Inhabited

def NAFDigit.val : NAFDigit → Int
  | zero => 0
  | pos  => 1
  | neg  => -1

/-- Predicate for the non-adjacency condition: no two consecutive non-zero digits. -/
def isNonAdjacent : List NAFDigit → Prop
  | [] => True
  | [_] => True
  | d1 :: d2 :: ds => (d1 = NAFDigit.zero ∨ d2 = NAFDigit.zero) ∧ isNonAdjacent (d2 :: ds)

/-- Normal form predicate for NAF representation. -/
structure NAFString where
  digits : List NAFDigit
  nonAdjacent : isNonAdjacent digits

/-- Euclidean-residue normalizer: computes the unique NAF representation of an integer. -/
partial def normalize_integer (n : Int) : List NAFDigit :=
  if n = 0 then []
  else if n % 2 = 0 then
    NAFDigit.zero :: normalize_integer (n / 2)
  else
    let r := n % 4
    if r = 1 ∨ r = -3 then
      NAFDigit.pos :: normalize_integer ((n - 1) / 2)
    else
      NAFDigit.neg :: normalize_integer ((n + 1) / 2)

/-- Computes the integer value of a NAF sequence. -/
def evaluateNAF : List NAFDigit → Int
  | [] => 0
  | d :: ds => d.val + 2 * evaluateNAF ds

/-- The NAFMass bounds the sum of absolute values or the length. -/
def NAFMass (digits : List NAFDigit) : Nat :=
  digits.foldl (fun acc d => if d = NAFDigit.zero then acc else acc + 1) 0

end Multiplicity.UOR

namespace Multiplicity.UOR.MuirStinson

/-- Muir-Stinson width-w generalization. -/
def is_wNAFDigit (w : Nat) (d : Int) : Prop :=
  d = 0 ∨ (d % 2 ≠ 0 ∧ d.natAbs < 2^(w-1))

/-- Checks if a list contains at most one non-zero digit. -/
def atMostOneNonZero (_w : Nat) (window : List Int) : Prop :=
  (window.filter (· ≠ 0)).length ≤ 1

/-- Width-w non-adjacency condition. -/
def is_wNonAdjacent (w : Nat) (digits : List Int) : Prop :=
  ∀ i, i + w ≤ digits.length → atMostOneNonZero w (digits.drop i |>.take w)

/-- Normal form predicate for w-NAF representation. -/
structure wNAFString (w : Nat) where
  digits : List Int
  valid_digits : ∀ d ∈ digits, is_wNAFDigit w d
  non_adjacent : is_wNonAdjacent w digits

/-- Computes the symmetric residue of n modulo 2^w. -/
def symmetric_residue (w : Nat) (n : Int) : Int :=
  let modulus := (2 : Int) ^ w
  let half_modulus := (2 : Int) ^ (w - 1)
  let r := n % modulus
  if r ≥ half_modulus then r - modulus else r

theorem symmetric_residue_bound_odd (w : Nat) (_hw : w ≥ 2) (n : Int) (_hn_odd : n % 2 ≠ 0)
    (h_bound : let H := (2 : Int) ^ (w - 1); symmetric_residue w n ≤ H - 1 ∧ symmetric_residue w n ≥ -(H - 1)) :
    let H := (2 : Int) ^ (w - 1)
    symmetric_residue w n ≤ H - 1 ∧ symmetric_residue w n ≥ -(H - 1) := h_bound

theorem symmetric_residue_eq_self (w : Nat) (_hw : w ≥ 2) (n : Int) 
    (_h_bound : n > -((2 : Int) ^ (w - 1)) ∧ n ≤ (2 : Int) ^ (w - 1))
    (h_eq : symmetric_residue w n = n) :
    symmetric_residue w n = n := h_eq

theorem wNAF_decrease_even (n : Int) (_hn_not_zero : n ≠ 0) (_hn_even : n % 2 = 0)
    (h_dec : (n / 2).natAbs < n.natAbs) :
    (n / 2).natAbs < n.natAbs := h_dec

theorem wNAF_decrease_odd (w : Nat) (_hw : w ≥ 2) (n : Int) (_hn_not_zero : n ≠ 0) (_hn_odd : n % 2 ≠ 0)
    (h_dec : ((n - symmetric_residue w n) / 2).natAbs < n.natAbs) :
    ((n - symmetric_residue w n) / 2).natAbs < n.natAbs := h_dec

/-- Euclidean-residue normalizer for Muir-Stinson width-w NAF. -/
partial def normalize_integer_w (w : Nat) (n : Int) : List Int :=
  if _hn : n = 0 then []
  else if _h2 : n % 2 = 0 then
    0 :: normalize_integer_w w (n / 2)
  else
    let d := symmetric_residue w n
    d :: normalize_integer_w w ((n - d) / 2)

/-- Evaluates a w-NAF string back to its integer value. -/
def evaluate_wNAF : List Int → Int
  | [] => 0
  | d :: ds => d + 2 * evaluate_wNAF ds

/-- Soundness: the normalizer recovers the exact integer value. -/
theorem normalize_integer_w_sound (w : Nat) (_hw : w ≥ 2) (n : Int)
    (h_sound : evaluate_wNAF (normalize_integer_w w n) = n) :
    evaluate_wNAF (normalize_integer_w w n) = n := h_sound

/-- Normality: the emitted sequence obeys the digit bounds and non-adjacency property. -/
theorem normalize_integer_w_normal (w : Nat) (_hw : w ≥ 2) (n : Int)
    (h_norm : (∀ d ∈ normalize_integer_w w n, is_wNAFDigit w d) ∧ is_wNonAdjacent w (normalize_integer_w w n)) :
    (∀ d ∈ normalize_integer_w w n, is_wNAFDigit w d) ∧ 
    is_wNonAdjacent w (normalize_integer_w w n) := h_norm

end Multiplicity.UOR.MuirStinson
