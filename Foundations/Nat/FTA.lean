import Foundations.Peano.Peano
import Foundations.Nat.Order
import Foundations.Nat.Arith
import Foundations.Nat.Div
import Foundations.Nat.Prime
import Foundations.Nat.GCD

namespace Foundations.NatFTA

open Foundations.Peano
open Foundations.NatOrder
open Foundations.NatArith
open Foundations.NatDiv
open Foundations.NatPrime
open Foundations.NatGCD

private theorem not_implies {A B : Prop} (h : ¬ (A → B)) : A ∧ ¬ B :=
  ⟨Classical.byContradiction (fun hna => h (fun ha => absurd ha hna)),
   fun hb => h (fun _ => hb)⟩

private theorem not_prime_has_divisor {n : Nat} (hn : 1 < n) (hnp : ¬ IsPrime n) :
    ∃ d, 1 < d ∧ d < n ∧ d ∣ n := by
  have h1 : ¬ (∀ d, d ∣ n → d = 1 ∨ d = n) := fun h => hnp ⟨hn, h⟩
  let ⟨d, hd⟩ := Classical.not_forall.mp h1
  let ⟨hddvd, hdn⟩ := not_implies hd
  have hdle : d ≤ n := Nat.le_of_dvd (by omega) hddvd
  have hd1' : ¬(1 = d) := fun h => hdn (Or.inl h.symm)
  have hdlt : d < n := Nat.lt_of_le_of_ne hdle (fun h => hdn (Or.inr h))
  have hdgt : 1 < d := by
    have hdp : 0 < d := Nat.pos_of_dvd_of_pos hddvd (by omega)
    exact Nat.lt_of_le_of_ne (Nat.succ_le_of_lt hdp) hd1'
  exact ⟨d, hdgt, hdlt, hddvd⟩

/-! ## Fundamental Theorem of Arithmetic -/

/-- Any `n > 1` has a prime factor. -/
theorem exists_prime_dvd {n : Nat} (h : 1 < n) : ∃ p, IsPrime p ∧ p ∣ n := by
  exact Nat.strongRecOn n (fun n ih hn => by
    cases Classical.em (IsPrime n) with
    | inl hp => exact ⟨n, hp, Nat.dvd_refl n⟩
    | inr hnp =>
      exact by
        have h := not_prime_has_divisor hn hnp
        revert h
        intro ⟨d, hd1, hdlt, hddvd⟩
        have ⟨p, hp_pr, hp_dvd⟩ := ih d hdlt hd1
        exact ⟨p, hp_pr, Nat.dvd_trans hp_dvd hddvd⟩) h

/-- Existence of prime factorization: every `n > 1` is the product of primes. -/
theorem prime_factorization_exists (n : Nat) (h : 1 < n) :
    ∃ factors : List Nat, (∀ p ∈ factors, IsPrime p) ∧ factors.prod = n := by
  have hrec := Nat.strongRecOn n
    (motive := fun k => 1 < k → ∃ factors : List Nat, (∀ p ∈ factors, IsPrime p) ∧ factors.prod = k)
    (fun n ih => by
      intro h1n
      have ⟨p, hp_prime, hp_dvd⟩ := exists_prime_dvd h1n
      obtain ⟨k, hk⟩ := hp_dvd
      by_cases hk0 : k = 0
      · have : n = 0 := by rw [hk, hk0, Nat.mul_zero]
        omega
      · have hk_gt : 0 < k := Nat.pos_of_ne_zero hk0
        by_cases hk1 : k = 1
        · have hn_eq : n = p := by rw [hk, hk1, Nat.mul_one]
          refine ⟨[p], ?_, ?_⟩
          · intro q hq; rw [List.mem_singleton] at hq; rw [hq]; exact hp_prime
          · rw [List.prod_singleton, hn_eq]
        · have hk_gt' : 1 < k := by omega
          have hk_lt_n : k < n := by
            rw [hk]
            have hpos : 0 < k := by omega
            have hk_lt : k * 1 < k * p := (Nat.mul_lt_mul_left hpos).2 hp_prime.1
            rwa [Nat.mul_one, Nat.mul_comm k p] at hk_lt
          have ⟨factors, hfk, hprodk⟩ := ih k hk_lt_n hk_gt'
          refine ⟨p :: factors, ?_, ?_⟩
          · intro q hq
            cases List.mem_cons.mp hq with
            | inl hq_eq => rw [hq_eq]; exact hp_prime
            | inr hq_tail => exact hfk q hq_tail
          · rw [List.prod_cons, hprodk, hk]
    )
  exact hrec h

/-- Unique factorization: if two lists of primes have the same product, then
    every element of the first is an element of the second (set-membership uniqueness). -/
theorem fta_unique {n : Nat} {l1 l2 : List Nat}
    (hl1 : ∀ p ∈ l1, IsPrime p) (hl2 : ∀ p ∈ l2, IsPrime p)
    (hprod1 : l1.prod = n) (hprod2 : l2.prod = n) :
    ∀ p, p ∈ l1 → p ∈ l2 := by
  intros p hp_in1
  have hp_dvd_l1 : p ∣ l1.prod := prime_mem_dvd_prod hp_in1
  have hp_dvd_l2 : p ∣ l2.prod := by
    rw [hprod1] at hp_dvd_l1
    exact hprod2 ▸ hp_dvd_l1
  exact prime_dvd_prod_of_prime_mem (hl1 p hp_in1) hp_dvd_l2 hl2

end Foundations.NatFTA
