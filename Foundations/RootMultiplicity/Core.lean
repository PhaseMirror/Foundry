import Foundations.Polynomial.Core

/-!
# Foundations.RootMultiplicity.Core — Synthetic Division & Root Multiplicity

Formalizes Ruffini / synthetic division of integer polynomials, the remainder theorem,
exact root multiplicity computation, and degree bounding theorems.
-/

namespace Foundations.RootMultiplicity

open Foundations.Polynomial

/-- One Ruffini step for coefficient `c` at root candidate `r`. -/
def syntheticStep (c r : Int) (prev : Int) : Int :=
  prev * r + c

/-- The synthetic fold producing quotients and intermediate remainders. -/
def syntheticFold (v r : Int) (rest : List Int) : List Int × Int :=
  rest.foldl (fun (st : List Int × Int) c =>
    let b := syntheticStep c r st.2
    (st.1 ++ [b], b)) ([v], v)

/-- Synthetic division: `(quotient, remainder)` of `cs` by `x - r`. -/
def quotientRemainder (cs : List Int) (r : Int) : List Int × Int :=
  match cs with
  | [] => ([], 0)
  | c0 :: rest =>
      let sf := syntheticFold c0 r rest
      (sf.1.dropLast, sf.2)

/-- Quotient of the empty polynomial is empty. -/
theorem quotientRemainder_nil (r : Int) : quotientRemainder [] r = ([], 0) := rfl

/-- The `.2` coordinate of the synthetic fold matches the Horner fold. -/
theorem foldl_pair_snd (a : List Int) (b r : Int) (rest : List Int) :
    (rest.foldl (fun (st : List Int × Int) c =>
        let d := syntheticStep c r st.2
        (st.1 ++ [d], d)) (a, b)).2 =
    rest.foldl (fun acc c => acc * r + c) b := by
  induction rest generalizing a b with
  | nil => rfl
  | cons c cs ih =>
      dsimp [syntheticStep]
      exact ih (a ++ [b * r + c]) (b * r + c)

/-- Remainder theorem: the remainder after synthetic division by `x - r` is the polynomial evaluation at `r`. -/
theorem quotientRemainder_remainder (cs : List Int) (r : Int) :
    (quotientRemainder cs r).2 = polyEval cs r := by
  cases cs with
  | nil => rfl
  | cons c0 rest =>
      dsimp [quotientRemainder, syntheticFold, polyEval]
      have h0 : 0 * r + c0 = c0 := by omega
      rw [h0]
      exact foldl_pair_snd [c0] c0 r rest

/-- Vanishing remainder is equivalent to being an algebraic root. -/
theorem remainder_root_iff (cs : List Int) (r : Int) :
    (quotientRemainder cs r).2 = 0 ↔ polyEval cs r = 0 := by
  rw [quotientRemainder_remainder]

/-- Bounded root multiplicity by repeated synthetic division. -/
def rootMultiplicityAux (cs : List Int) (r : Int) : Nat → Nat
  | 0 => 0
  | bound + 1 =>
      let (q, rem) := quotientRemainder cs r
      if rem = 0 then 1 + rootMultiplicityAux q r bound else 0

/-- The exact multiplicity of root `r` in polynomial `cs`, bounded by degree `cs.length`. -/
def rootMultiplicity (cs : List Int) (r : Int) : Nat :=
  rootMultiplicityAux cs r cs.length

/-- Theorem: Root multiplicity is at most the degree (length) of the polynomial. -/
theorem rootMultiplicity_le_degree (cs : List Int) (r : Int) :
    rootMultiplicity cs r ≤ cs.length := by
  dsimp [rootMultiplicity]
  induction cs.length generalizing cs with
  | zero =>
    dsimp [rootMultiplicityAux]
    omega
  | succ n ih =>
    dsimp [rootMultiplicityAux]
    split
    · have hi := ih (quotientRemainder cs r).fst
      omega
    · omega

/-- Theorem: The multiplicity of a non-root is strictly zero. -/
theorem rootMultiplicity_of_not_root {cs : List Int} {r : Int} (h : polyEval cs r ≠ 0) :
    rootMultiplicity cs r = 0 := by
  dsimp [rootMultiplicity]
  cases cs.length with
  | zero =>
    dsimp [rootMultiplicityAux]
  | succ n =>
    have hrem : (quotientRemainder cs r).2 ≠ 0 := by
      rw [quotientRemainder_remainder]
      exact h
    dsimp [rootMultiplicityAux]
    have hcond : ¬((quotientRemainder cs r).2 = 0) := hrem
    rw [if_neg hcond]

end Foundations.RootMultiplicity
