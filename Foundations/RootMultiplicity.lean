import Multiplicity.Multiplicity.Polynomial

/-!
# Multiplicity Kernel — Root Multiplicity (ADR-0001 Phase 1 scope)

Root multiplicity is computed by repeated Ruffini (synthetic) division by
`x - r`: every time the remainder is zero the multiplicity increases by one.
The recursion is bounded by the number of coefficients, since the
multiplicity of a non-zero polynomial cannot exceed its degree.
-/

namespace Multiplicity.Kernel

/-- One Ruffini step for coefficients `cs` at root `r`; returns
`(quotient, remainder)`. -/
def syntheticStep (c r : Int) (prev : Int) : Int :=
  prev * r + c

/-- The synthetic fold: starting from the leading coefficient, each further
coefficient produces the next quotient entry and next remainder. -/
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

/-- The `.2` coordinate of the synthetic fold matches the Horner fold: the
pair fold `(st.1 ++ [b], b)` carries exactly the Horner accumulator, and the
first coordinate never influences it. -/
theorem foldl_pair_snd (a : List Int) (b r : Int) (rest : List Int) :
    (rest.foldl (fun (st : List Int × Int) c =>
        let d := syntheticStep c r st.2
        (st.1 ++ [d], d)) (a, b)).2 =
    rest.foldl (fun acc c => acc * r + c) b := by
  induction rest generalizing a b with
  | nil => rfl
  | cons c cs ih =>
      simp [List.foldl_cons, syntheticStep]
      exact ih (a ++ [b * r + c]) (b * r + c)

/-- Remainder theorem (synthetic form): the remainder after synthetic
division by `x - r` is the evaluation at `r`. -/
theorem quotientRemainder_remainder (cs : List Int) (r : Int) :
    (quotientRemainder cs r).2 = polyEval cs r := by
  cases cs with
  | nil => rfl
  | cons c0 rest =>
      simp [quotientRemainder, syntheticFold, polyEval, List.foldl_cons]
      exact foldl_pair_snd [c0] c0 r rest

/-- The remainder after synthetic division by `x - r` is the evaluation at
`r`, which is a root exactly when it vanishes. -/
theorem remainder_root_iff (cs : List Int) (r : Int) :
    (quotientRemainder cs r).2 = 0 ↔ polyEval cs r = 0 := by
  rw [quotientRemainder_remainder]

/-- Bounded multiplicity by repeated synthetic division. -/
def rootMultiplicityAux (cs : List Int) (r : Int) : Nat → Nat
  | 0 => 0
  | bound + 1 =>
      let (q, rem) := quotientRemainder cs r
      if rem = 0 then 1 + rootMultiplicityAux q r bound else 0

/-- The multiplicity of root `r` in polynomial `cs`.  Bounded by the degree
`cs.length`. -/
def rootMultiplicity (cs : List Int) (r : Int) : Nat :=
  rootMultiplicityAux cs r cs.length

/-- The multiplicity of a root is at most the degree. -/
theorem rootMultiplicity_le_degree (cs : List Int) (r : Int) :
    rootMultiplicity cs r ≤ cs.length := by
  unfold rootMultiplicity
  induction cs.length generalizing cs with
  | zero => simp [rootMultiplicityAux]
  | succ n ih =>
      simp [rootMultiplicityAux]
      split
      · have hi := ih (quotientRemainder cs r).fst
        omega
      · omega

/-- The multiplicity of a non-root is zero. -/
theorem rootMultiplicity_of_not_root {cs : List Int} {r : Int} (h : polyEval cs r ≠ 0) :
    rootMultiplicity cs r = 0 := by
  unfold rootMultiplicity
  cases cs.length with
  | zero => simp [rootMultiplicityAux]
  | succ n =>
      have hrem : (quotientRemainder cs r).2 ≠ 0 := by
        rw [quotientRemainder_remainder]
        exact h
      simp [rootMultiplicityAux, hrem]

/-- Executable multiplicity witnesses mirroring the Rust `root_multiplicity`. -/
example : rootMultiplicity [1, -2, 1] 1 = 2 := by native_decide
example : rootMultiplicity [1, -2, 1] 0 = 0 := by native_decide
example : rootMultiplicity [-1, 0, 1] 1 = 1 := by native_decide

end Multiplicity.Kernel
