import LeanPrimeGapDynamics.Definitions
import Mathlib.Data.Nat.Prime
import Mathlib.Data.Nat.Factorization.Basic
import Mathlib.Data.Nat.PrimeFin

open Nat

theorem multiplicative_eq_of_prime_powers {R : Type} [CommSemiring R] {f g : ℕ → R}
    (hf : IsMultiplicative f) (hg : IsMultiplicative g)
    (h : ∀ p k : ℕ, Prime p → f (p ^ k) = g (p ^ k)) : f = g := by
  funext n
  induction n using Nat.strong_induction_on with
  | h n ih =>
      cases n with
      | zero => rw [hf.1, hg.1]
      | succ n' =>
          let n := n'.succ
          if hn1 : n = 1 then
            rw [hn1, hf.2.1, hg.2.1]
          else
            have hpos : n > 0 := succ_pos n'
            let p := minFac n
            have hp : Prime p := minFac_prime (ne_of_gt (Nat.lt_of_le_of_ne (succ_le_succ (zero_le n')) hn1))
            let k := factorisation n p
            let m := n / (p ^ k)
            have hm : m < n := by
                sorry
            have hcoprime : Coprime (p ^ k) m := by
                sorry
            rw [← Nat.pow_factorisation_mul_div n hp]
            rw [hf.2.2 (p ^ k) m (pow_pos (Prime.one_lt hp) k) (Nat.div_pos (Nat.pow_le_pow_of_le_right (Prime.one_le hp) (factorisation_le_pow n hp)) (pow_pos (Prime.one_lt hp) k)) hcoprime]
            rw [hg.2.2 (p ^ k) m (pow_pos (Prime.one_lt hp) k) (Nat.div_pos (Nat.pow_le_pow_of_le_right (Prime.one_le hp) (factorisation_le_pow n hp)) (pow_pos (Prime.one_lt hp) k)) hcoprime]
            rw [h p k hp]
            rw [ih m hm]
            sorry
