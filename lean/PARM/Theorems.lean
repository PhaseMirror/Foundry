import PARM.Core

namespace PARM

/--
  Theorem: Sealed state is strictly positive for non-empty lists of positive integers.
  This represents the fundamental non-degeneracy of the PARM encoding.
--/

theorem sealed_state_loop_pos (v : Nat) (ps : List Nat) (hv : 0 < v) (hps : ∀ p ∈ ps, 0 < p) :
  0 < sealed_state_loop v ps := by
  induction ps generalizing v with
  | nil =>
    unfold sealed_state_loop
    exact hv
  | cons p ps ih =>
    have hp : 0 < p := hps p (List.Mem.head _)
    cases ps with
    | nil =>
      unfold sealed_state_loop
      have h_sum : 0 < v + p := Nat.add_pos_right v hp
      have h_p2 : 0 < p * p := Nat.mul_pos hp hp
      exact Nat.mul_pos h_p2 h_sum
    | cons p' ps' =>
      unfold sealed_state_loop
      have h_sum : 0 < v + p := Nat.add_pos_right v hp
      have h_prod : 0 < p * (v + p) := Nat.mul_pos hp h_sum
      apply ih (p * (v + p)) h_prod
      intro x hx
      exact hps x (List.Mem.tail _ hx)

theorem sealed_state_pos (primes : List Nat) (h_not_empty : primes ≠ []) (hps : ∀ p ∈ primes, 0 < p) :
  0 < sealed_state primes := by
  cases primes with
  | nil => contradiction
  | cons p ps =>
    have hp : 0 < p := hps p (List.Mem.head _)
    have hp2 : 0 < p * p := Nat.mul_pos hp hp
    cases ps with
    | nil =>
      unfold sealed_state
      exact hp2
    | cons p' ps' =>
      unfold sealed_state
      apply sealed_state_loop_pos
      · exact hp2
      · intro x hx
        exact hps x (List.Mem.tail _ hx)

end PARM
