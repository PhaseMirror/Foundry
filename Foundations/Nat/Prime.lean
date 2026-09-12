import Foundations.Peano.Peano
import Foundations.Nat.Order
import Foundations.Nat.Arith
import Foundations.Nat.GCD

namespace Foundations.NatPrime

open Foundations.Peano
open Foundations.NatOrder
open Foundations.NatArith
open Foundations.NatGCD

def IsPrime (p : Nat) : Prop :=
  1 < p ∧ ∀ d, d ∣ p → d = 1 ∨ d = p

private theorem divisors_of_eq_two (d k : Nat) (h : 2 = d * k) : d = 1 ∨ d = 2 := by
  cases k with
  | zero => omega
  | succ k => rw [Nat.mul_succ] at h; cases d with
    | zero => omega
    | succ d => cases d with
      | zero => omega
      | succ d => cases d with
        | zero => omega
        | succ d => omega

private theorem divisors_of_eq_three (d k : Nat) (h : 3 = d * k) : d = 1 ∨ d = 3 := by
  cases k with
  | zero => omega
  | succ k => rw [Nat.mul_succ] at h; cases d with
    | zero => omega
    | succ d => cases d with
      | zero => omega
      | succ d => cases d with
        | zero => omega
        | succ d => cases d with
          | zero => omega
          | succ d => omega

private theorem divisors_of_eq_five (d k : Nat) (h : 5 = d * k) : d = 1 ∨ d = 5 := by
  cases k with
  | zero => omega
  | succ k => rw [Nat.mul_succ] at h; cases d with
    | zero => omega
    | succ d => cases d with
      | zero => omega
      | succ d => cases d with
        | zero => omega
        | succ d => cases d with
          | zero => omega
          | succ d => cases d with
            | zero => omega
            | succ d => omega

theorem two_prime : IsPrime 2 :=
  ⟨by omega, fun d hd => by
    obtain ⟨k, hk⟩ := hd
    exact divisors_of_eq_two d k hk⟩

theorem three_prime : IsPrime 3 :=
  ⟨by omega, fun d hd => by
    obtain ⟨k, hk⟩ := hd
    exact divisors_of_eq_three d k hk⟩

theorem five_prime : IsPrime 5 :=
  ⟨by omega, fun d hd => by
    obtain ⟨k, hk⟩ := hd
    exact divisors_of_eq_five d k hk⟩

theorem prime_gt_one {p : Nat} (hp : IsPrime p) : 1 < p := hp.1
theorem prime_ge_two {p : Nat} (hp : IsPrime p) : 2 ≤ p := Nat.succ_le_of_lt hp.1
theorem not_prime_one : ¬ IsPrime 1 := fun h => by have := h.1; omega
theorem not_prime_zero : ¬ IsPrime 0 := fun h => by have := h.1; omega

theorem prime_dvd_eq_one_or_self {p d : Nat} (hp : IsPrime p) (h : d ∣ p) : d = 1 ∨ d = p :=
  hp.2 d h

theorem prime_only_proper_divisor {p d : Nat} (hp : IsPrime p) (hd : 0 < d) (hdlt : d < p) (h : d ∣ p) : d = 1 := by
  have h2 := hp.2 d h
  cases h2 with
  | inl h => exact h
  | inr h => omega

theorem prime_dvd_mul {p a b : Nat} (hp : IsPrime p) (h : p ∣ a * b) : p ∣ a ∨ p ∣ b := by
  cases Classical.em (p ∣ a) with
  | inl ha => exact Or.inl ha
  | inr hna =>
    right
    have hgcd : Nat.gcd p a = 1 := by
      have hdiv := Nat.gcd_dvd_left p a
      cases hp.2 (Nat.gcd p a) hdiv with
      | inl h1 => exact h1
      | inr h2 =>
        have h_dvd_a : Nat.gcd p a ∣ a := Nat.gcd_dvd_right p a
        rw [h2] at h_dvd_a
        exact absurd h_dvd_a hna
    have hgcdmul : Nat.gcd (a * b) (p * b) = (Nat.gcd p a) * b := by
      have := Nat.gcd_mul_left b a p
      rw [Nat.mul_comm b a, Nat.mul_comm b p, Nat.mul_comm b, Nat.gcd_comm a p] at this
      exact this
    rw [hgcd] at hgcdmul
    have h2 : p ∣ p * b := by exact ⟨b, by rw [Nat.mul_comm p b]⟩
    have hp_dvd_gcd : p ∣ Nat.gcd (a * b) (p * b) := Nat.dvd_gcd h h2
    rw [hgcdmul] at hp_dvd_gcd
    simpa using hp_dvd_gcd

private theorem list_prod_ge_one (l : List Nat) (h : ∀ x ∈ l, 2 ≤ x) : 1 ≤ l.prod := by
  induction l with
  | nil => rw [List.prod_nil]; omega
  | cons a as ih =>
    rw [List.prod_cons]
    have ha : 2 ≤ a := h a (List.Mem.head as)
    have ihas : 1 ≤ as.prod := ih (fun x hx => h x (List.Mem.tail a hx))
    exact Nat.mul_pos (by omega) (by omega)

/-- If a prime is in a list of numbers, it divides the product. -/
theorem prime_mem_dvd_prod {p : Nat} {l : List Nat} (hp : p ∈ l) : p ∣ l.prod := by
  induction l with
  | nil => exact absurd hp List.not_mem_nil
  | cons a as ih =>
    rw [List.prod_cons]
    cases List.mem_cons.mp hp with
    | inl h_eq =>
      rw [h_eq]
      exact Nat.dvd_mul_right a as.prod
    | inr h_mem =>
      exact Nat.dvd_trans (ih h_mem) (Nat.dvd_mul_left as.prod a)

/-- If a prime divides the product of a list of primes, it is one of them. -/
theorem prime_dvd_prod_of_prime_mem {p : Nat} {l : List Nat}
    (hp : IsPrime p) (h : p ∣ l.prod) (hl : ∀ q ∈ l, IsPrime q) :
    p ∈ l := by
  induction l with
  | nil =>
    rw [List.prod_nil] at h
    have hp1 := Nat.dvd_one.mp h
    have : 1 < p := hp.1
    omega
  | cons a as ih =>
    rw [List.prod_cons] at h
    have h_case := prime_dvd_mul hp h
    cases h_case with
    | inl hpa =>
      have hia : IsPrime a := hl a (List.Mem.head as)
      have h_eq : a = p := by
        have hd := hia.2 p hpa
        cases hd with
        | inl hp1 => have : 1 < p := hp.1; omega
        | inr hpa_eq => exact hpa_eq.symm
      exact List.mem_cons.mpr (Or.inl h_eq.symm)
    | inr hpas =>
      have ih1 := ih hpas (fun q hq => hl q (List.Mem.tail a hq))
      exact List.mem_cons.mpr (Or.inr ih1)

private theorem exists_prime_factor : ∀ n, 1 < n → ∃ p, IsPrime p ∧ p ∣ n := by
  intro n hn
  have h := Nat.strongRecOn n
    (motive := fun k => 1 < k → ∃ p, IsPrime p ∧ p ∣ k)
    (fun n ih => by
      intro h1n
      have := Classical.em (∀ d, d ∣ n → d = 1 ∨ d = n)
      cases this with
      | inl h_prime =>
        exact ⟨n, ⟨h1n, h_prime⟩, Nat.dvd_refl n⟩
      | inr h_not_prime =>
        have ⟨d, hd⟩ := Classical.not_forall.mp h_not_prime
        have ⟨hd_dvd, hd_ne⟩ := not_imp.mp hd
        have ⟨hd_ne_one, hd_ne_n⟩ := not_or.mp hd_ne
        have hd_ne_zero : d ≠ 0 := by
          intro hd0
          subst hd0
          exact absurd (Nat.zero_dvd.mp hd_dvd) (by omega)
        have hd_ge : 2 ≤ d := by omega
        have hd_le : d ≤ n := Nat.le_of_dvd (by omega) hd_dvd
        have hd_lt : d < n := by omega
        have hd_gt : 1 < d := by omega
        have ⟨p, hp_prime, hp_dvd⟩ := ih d hd_lt hd_gt
        exact ⟨p, hp_prime, Nat.dvd_trans hp_dvd hd_dvd⟩
    )
  exact h hn

theorem infinitely_many_primes (primes : List Nat)
    (h : ∀ p ∈ primes, IsPrime p) :
    ∃ p, IsPrime p ∧ p ∉ primes := by
  have hn : 1 < primes.prod + 1 := by
    have := list_prod_ge_one primes (fun x hx => prime_ge_two (h x hx))
    omega
  have ⟨q, hq_prime, hq_dvd⟩ := exists_prime_factor (primes.prod + 1) hn
  exact ⟨q, hq_prime, by
    intro hq_in
    have hq_div_prod : q ∣ primes.prod := prime_mem_dvd_prod hq_in
    have hq_dvd_one : q ∣ 1 := by
      have h1 : q ∣ (primes.prod + 1) - primes.prod := Nat.dvd_sub hq_dvd hq_div_prod
      rw [Nat.add_sub_cancel_left] at h1
      exact h1
    have hq_eq_one : q = 1 := Nat.dvd_one.mp hq_dvd_one
    have hq_gt : 1 < q := hq_prime.1
    omega
  ⟩

end Foundations.NatPrime
