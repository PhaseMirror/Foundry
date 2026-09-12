import EchoBraid.Core

/-!
# EchoBraid.BraidFormalism

Formalism of the Prime-Indexed Spectral Weave:
$$\text{EchoBraid}(t) = \bigoplus_{n=1}^{K} \psi_{p_n}(t) \otimes e^{i \theta_{p_n}(t)}$$
-/

namespace EchoBraid

/-- Braid Generator Move: positive crossing $\sigma_i$ or negative crossing $\sigma_i^{-1}$ -/
inductive BraidMove where
  | crossPos (index : Nat) : BraidMove  -- \sigma_i
  | crossNeg (index : Nat) : BraidMove  -- \sigma_i^{-1}
  deriving Repr, DecidableEq, Inhabited

/-- Apply positive crossing $\sigma_i$ swapping strand $i$ and $i+1$ with phase entanglement -/
def applyCrossing (strands : List Strand) (i : Nat) (isPositive : Bool) : List Strand :=
  let phaseShift := if isPositive then 30 else 330
  let rec swapAt (l : List Strand) (curr : Nat) : List Strand :=
    match l with
    | [] => []
    | [s] => [s]
    | s1 :: s2 :: rest =>
      if curr == i then
        let s1' := { s1 with
          position := s2.position,
          tint := { s1.tint with phaseDeg := normPhase (s1.tint.phaseDeg + phaseShift) }
        }
        let s2' := { s2 with
          position := s1.position,
          tint := { s2.tint with phaseDeg := normPhase (s2.tint.phaseDeg + (360 - phaseShift)) }
        }
        s2' :: s1' :: rest
      else
        s1 :: swapAt (s2 :: rest) (curr + 1)
  swapAt strands 0

/-- Apply a BraidMove to an EchoBraidState -/
def applyBraidMove (st : EchoBraidState) (m : BraidMove) : EchoBraidState :=
  match m with
  | BraidMove.crossPos i =>
    { st with strands := applyCrossing st.strands i true }
  | BraidMove.crossNeg i =>
    { st with strands := applyCrossing st.strands i false }

/-- Apply a sequence of braid moves (a braid word) -/
def applyBraidWord (st : EchoBraidState) (word : List BraidMove) : EchoBraidState :=
  word.foldl applyBraidMove st

/-- Extract the prime sequence from the current strand order -/
def currentPrimeSequence (st : EchoBraidState) : List Nat :=
  st.strands.map (·.prime)

/-- Check if all strands have distinct prime indices -/
def distinctPrimes (st : EchoBraidState) : Bool :=
  let primes := currentPrimeSequence st
  let rec checkDistinct (l : List Nat) : Bool :=
    match l with
    | [] => true
    | x :: xs => (!xs.contains x) && checkDistinct xs
  checkDistinct primes

end EchoBraid
