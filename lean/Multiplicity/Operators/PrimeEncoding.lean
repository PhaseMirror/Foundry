/-
Copyright (c) 2024 Multiplicity / Citizen Gardens. All rights reserved.
Licensed under Prime Materia Open Commons and Bound Works License v1.0.

Prime Encoding Operator for Multiplicity Theory.
Formalizes the prime encoding map from Operators.md S2.

Defines IsPrime from scratch (Nat.Prime requires Mathlib), proves basic
primality properties, defines Godel-style encoding, and proves injectivity
for single-element and two-element encodings.

Pure core Lean 4, axiom-clean, no sorry.
-/
namespace Multiplicity.Core.Operators.PrimeEncoding

/-! ## Primality Predicate -/

def IsPrime (p : Nat) : Prop :=
  p >= 2 /\ forall d, d ∣ p -> d = 1 \/ d = p

/-! ## Proved Primes -/

theorem isPrime_two : IsPrime 2 :=
  ⟨by omega, fun d hd => by
    have hdle : d ≤ 2 := Nat.le_of_dvd (by omega) hd
    have h_or : d = 0 ∨ d = 1 ∨ d = 2 := by omega
    cases h_or with
    | inl h0 =>
      subst h0; cases hd with | intro k hk => omega
    | inr h => cases h with
      | inl h1 => exact Or.inl h1
      | inr h2 => exact Or.inr h2⟩

theorem isPrime_three : IsPrime 3 :=
  ⟨by omega, fun d hd => by
    have hdle : d ≤ 3 := Nat.le_of_dvd (by omega) hd
    have h_or : d = 0 ∨ d = 1 ∨ d = 2 ∨ d = 3 := by omega
    cases h_or with
    | inl h0 =>
      subst h0; cases hd with | intro k hk => omega
    | inr h => cases h with
      | inl h1 => exact Or.inl h1
      | inr h => cases h with
        | inl h2 =>
          subst h2; cases hd with | intro k hk => omega
        | inr h3 => exact Or.inr h3⟩

theorem isPrime_five : IsPrime 5 :=
  ⟨by omega, fun d hd => by
    have hdle : d ≤ 5 := Nat.le_of_dvd (by omega) hd
    have h_or : d = 0 ∨ d = 1 ∨ d = 2 ∨ d = 3 ∨ d = 4 ∨ d = 5 := by omega
    cases h_or with
    | inl h0 =>
      subst h0; cases hd with | intro k hk => omega
    | inr h => cases h with
      | inl h1 => exact Or.inl h1
      | inr h => cases h with
        | inl h2 =>
          subst h2; cases hd with | intro k hk => omega
        | inr h => cases h with
          | inl h3 =>
            subst h3; cases hd with | intro k hk => omega
          | inr h => cases h with
            | inl h4 =>
              subst h4; cases hd with | intro k hk => omega
            | inr h5 => exact Or.inr h5⟩

theorem isPrime_seven : IsPrime 7 :=
  ⟨by omega, fun d hd => by
    have hdle : d ≤ 7 := Nat.le_of_dvd (by omega) hd
    have h_or : d = 0 ∨ d = 1 ∨ d = 2 ∨ d = 3 ∨ d = 4 ∨ d = 5 ∨ d = 6 ∨ d = 7 := by omega
    cases h_or with
    | inl h0 =>
      subst h0; cases hd with | intro k hk => omega
    | inr h => cases h with
      | inl h1 => exact Or.inl h1
      | inr h => cases h with
        | inl h2 =>
          subst h2; cases hd with | intro k hk => omega
        | inr h => cases h with
          | inl h3 =>
            subst h3; cases hd with | intro k hk => omega
          | inr h => cases h with
            | inl h4 =>
              subst h4; cases hd with | intro k hk => omega
            | inr h => cases h with
              | inl h5 =>
                subst h5; cases hd with | intro k hk => omega
              | inr h => cases h with
                | inl h6 =>
                  subst h6; cases hd with | intro k hk => omega
                | inr h7 => exact Or.inr h7⟩

theorem isPrime_eleven : IsPrime 11 :=
  ⟨by omega, fun d hd => by
    have hdle : d ≤ 11 := Nat.le_of_dvd (by omega) hd
    have h_or : d = 0 ∨ d = 1 ∨ d = 2 ∨ d = 3 ∨ d = 4 ∨ d = 5 ∨
        d = 6 ∨ d = 7 ∨ d = 8 ∨ d = 9 ∨ d = 10 ∨ d = 11 := by omega
    cases h_or with
    | inl h0 =>
      subst h0; cases hd with | intro k hk => omega
    | inr h => cases h with
      | inl h1 => exact Or.inl h1
      | inr h => cases h with
        | inl h2 =>
          subst h2; cases hd with | intro k hk => omega
        | inr h => cases h with
          | inl h3 =>
            subst h3; cases hd with | intro k hk => omega
          | inr h => cases h with
            | inl h4 =>
              subst h4; cases hd with | intro k hk => omega
            | inr h => cases h with
              | inl h5 =>
                subst h5; cases hd with | intro k hk => omega
              | inr h => cases h with
                | inl h6 =>
                  subst h6; cases hd with | intro k hk => omega
                | inr h => cases h with
                  | inl h7 =>
                    subst h7; cases hd with | intro k hk => omega
                  | inr h => cases h with
                    | inl h8 =>
                      subst h8; cases hd with | intro k hk => omega
                    | inr h => cases h with
                      | inl h9 =>
                        subst h9; cases hd with | intro k hk => omega
                      | inr h => cases h with
                        | inl h10 =>
                          subst h10; cases hd with | intro k hk => omega
                        | inr h11 => exact Or.inr h11⟩

theorem isPrime_thirteen : IsPrime 13 :=
  ⟨by omega, fun d hd => by
    have hdle : d ≤ 13 := Nat.le_of_dvd (by omega) hd
    have h_or : d = 0 ∨ d = 1 ∨ d = 2 ∨ d = 3 ∨ d = 4 ∨ d = 5 ∨
        d = 6 ∨ d = 7 ∨ d = 8 ∨ d = 9 ∨ d = 10 ∨ d = 11 ∨ d = 12 ∨ d = 13 := by omega
    cases h_or with
    | inl h0 =>
      subst h0; cases hd with | intro k hk => omega
    | inr h => cases h with
      | inl h1 => exact Or.inl h1
      | inr h => cases h with
        | inl h2 =>
          subst h2; cases hd with | intro k hk => omega
        | inr h => cases h with
          | inl h3 =>
            subst h3; cases hd with | intro k hk => omega
          | inr h => cases h with
            | inl h4 =>
              subst h4; cases hd with | intro k hk => omega
            | inr h => cases h with
              | inl h5 =>
                subst h5; cases hd with | intro k hk => omega
              | inr h => cases h with
                | inl h6 =>
                  subst h6; cases hd with | intro k hk => omega
                | inr h => cases h with
                  | inl h7 =>
                    subst h7; cases hd with | intro k hk => omega
                  | inr h => cases h with
                    | inl h8 =>
                      subst h8; cases hd with | intro k hk => omega
                    | inr h => cases h with
                      | inl h9 =>
                        subst h9; cases hd with | intro k hk => omega
                      | inr h => cases h with
                        | inl h10 =>
                          subst h10; cases hd with | intro k hk => omega
                        | inr h => cases h with
                          | inl h11 =>
                            subst h11; cases hd with | intro k hk => omega
                          | inr h => cases h with
                            | inl h12 =>
                              subst h12; cases hd with | intro k hk => omega
                            | inr h13 => exact Or.inr h13⟩

/-! ## Not Prime -/

theorem not_prime_one : ¬ IsPrime 1 := by
  intro h; exact absurd h.1 (by omega)

theorem not_prime_zero : ¬ IsPrime 0 := by
  intro h; exact absurd h.1 (by omega)

theorem not_prime_four : ¬ IsPrime 4 := by
  intro h; have := h.2 2 (by omega); omega

theorem not_prime_six : ¬ IsPrime 6 := by
  intro h; have := h.2 2 (by omega); omega

theorem not_prime_eight : ¬ IsPrime 8 := by
  intro h; have := h.2 2 (by omega); omega

theorem not_prime_nine : ¬ IsPrime 9 := by
  intro h; have := h.2 3 (by omega); omega

theorem not_prime_ten : ¬ IsPrime 10 := by
  intro h; have := h.2 2 (by omega); omega

/-! ## Power Monotonicity and Injectivity -/

private theorem two_pow_succ_gt_one (a : Nat) : 2 ^ (a + 1) > 1 := by
  rw [Nat.pow_succ]
  have h2a : 0 < 2 ^ a := Nat.pow_pos (by omega)
  omega

theorem pow_two_strict_mono : forall a b, a > b -> 2 ^ a > 2 ^ b := by
  intro a b hab
  induction b generalizing a with
  | zero =>
    cases a with
    | zero => omega
    | succ a => exact two_pow_succ_gt_one a
  | succ b ih =>
    cases a with
    | zero => omega
    | succ a =>
      rw [Nat.pow_succ, Nat.pow_succ]
      exact (Nat.mul_lt_mul_right (by omega)).mpr (ih a (by omega))

theorem pow_two_injective : forall a b, 2 ^ a = 2 ^ b -> a = b := by
  intro a b h
  by_cases hlt : a < b
  · exfalso; have := pow_two_strict_mono b a hlt; omega
  · by_cases hgt : b < a
    · exfalso; have := pow_two_strict_mono a b hgt; omega
    · omega

private theorem three_pow_succ_gt_one (a : Nat) : 3 ^ (a + 1) > 1 := by
  rw [Nat.pow_succ]
  have h3a : 0 < 3 ^ a := Nat.pow_pos (by omega)
  omega

theorem pow_three_strict_mono : forall a b, a > b -> 3 ^ a > 3 ^ b := by
  intro a b hab
  induction b generalizing a with
  | zero =>
    cases a with
    | zero => omega
    | succ a => exact three_pow_succ_gt_one a
  | succ b ih =>
    cases a with
    | zero => omega
    | succ a =>
      rw [Nat.pow_succ, Nat.pow_succ]
      exact (Nat.mul_lt_mul_right (by omega)).mpr (ih a (by omega))

theorem pow_three_injective : forall a b, 3 ^ a = 3 ^ b -> a = b := by
  intro a b h
  by_cases hlt : a < b
  · exfalso; have := pow_three_strict_mono b a hlt; omega
  · by_cases hgt : b < a
    · exfalso; have := pow_three_strict_mono a b hgt; omega
    · omega

/-! ## 2^x = 3^y Only at Origin -/

theorem pow_three_odd : forall k, 3 ^ k % 2 = 1 := by
  intro k; induction k with
  | zero => simp [Nat.pow_zero]
  | succ k ih => simp only [Nat.pow_succ]; omega

private theorem two_pow_even (x : Nat) (hx : x > 0) : 2 ^ x % 2 = 0 := by
  cases x with
  | zero => omega
  | succ x => simp only [Nat.pow_succ]; omega

private theorem three_pow_div3 (y : Nat) (hy : y > 0) : 3 ^ y % 3 = 0 := by
  cases y with
  | zero => omega
  | succ y => simp only [Nat.pow_succ]; omega

private theorem two_pow_mod3 : forall x, 2 ^ x % 3 = 1 \/ 2 ^ x % 3 = 2 := by
  intro x
  induction x with
  | zero => left; omega
  | succ x ih =>
    simp only [Nat.pow_succ]
    cases ih with
    | inl h => right; omega
    | inr h => left; omega

theorem two_pow_eq_three_pow : forall x y, 2 ^ x = 3 ^ y -> x = 0 /\ y = 0 := by
  intro x y h
  constructor
  · by_cases hx : x = 0
    · exact hx
    · exfalso
      have hxpos : x > 0 := by omega
      have heven : 2 ^ x % 2 = 0 := two_pow_even x hxpos
      have hodd : 3 ^ y % 2 = 1 := pow_three_odd y
      omega
  · by_cases hy : y = 0
    · exact hy
    · exfalso
      have hypos : y > 0 := by omega
      have hdiv3 : 3 ^ y % 3 = 0 := three_pow_div3 y hypos
      have hnotdiv3 : 2 ^ x % 3 = 1 \/ 2 ^ x % 3 = 2 := two_pow_mod3 x
      omega

/-! ## Godel Encoding -/

def primes : List Nat := [2, 3, 5, 7, 11, 13]

def encodeAux : List Nat -> List Nat -> Nat
  | _, [] => 1
  | [], _ => 1
  | p :: ps, e :: es => p ^ e * encodeAux ps es

def godelEncode (exps : List Nat) : Nat := encodeAux primes exps

@[simp] theorem godelEncode_example_one : godelEncode [1, 0, 2] = 50 := rfl
@[simp] theorem godelEncode_example_zero : godelEncode [0, 0, 0, 0, 0, 0] = 1 := rfl
@[simp] theorem godelEncode_example_three : godelEncode [3, 0, 0, 0, 0, 0] = 8 := rfl
@[simp] theorem godelEncode_example_prime1 : godelEncode [0, 1, 0, 0, 0, 0] = 3 := rfl

/-! ## Single-Element Injection -/

theorem encode_one_eq_pow_two : forall a, godelEncode [a] = 2 ^ a := by
  intro a; simp [godelEncode, encodeAux, primes, Nat.mul_one]

theorem encode_one_injective : forall a b, godelEncode [a] = godelEncode [b] -> a = b := by
  intro a b h
  simp only [godelEncode, encodeAux, primes, Nat.mul_one] at h
  exact (Nat.pow_right_inj (by omega)).mp h

/-! ## Two-Element Injection -/

private theorem pow_two_le (a c : Nat) (hac : a <= c) : 2 ^ a <= 2 ^ c :=
  Nat.pow_le_pow_right (by omega) hac

private theorem pow_three_le (b d : Nat) (hbd : b <= d) : 3 ^ b <= 3 ^ d :=
  Nat.pow_le_pow_right (by omega) hbd

theorem encode_two_injective : forall a b c d,
    godelEncode [a, b] = godelEncode [c, d] -> a = c /\ b = d := by
  intro a b c d h
  simp only [godelEncode, encodeAux, primes] at h
  rw [Nat.mul_one, Nat.mul_one] at h
  have ha : a = c := by
    by_cases heq : a = c
    · exact heq
    · exfalso
      by_cases hlt : a < c
      · have h1 : 2 ^ a * 2 ^ (c - a) = 2 ^ c := by rw [← Nat.pow_add]; congr 1; omega
        have h2 : 2 ^ a * (2 ^ (c - a) * 3 ^ d) = 2 ^ c * 3 ^ d := by rw [← Nat.mul_assoc, h1]
        have h3 : 2 ^ a * (2 ^ (c - a) * 3 ^ d) = 2 ^ a * 3 ^ b := by rw [h2]; exact h.symm
        have h4 : 2 ^ (c - a) * 3 ^ d = 3 ^ b := Nat.mul_left_cancel (Nat.pow_pos (by omega)) h3
        have hodd : 3 ^ b % 2 = 1 := pow_three_odd b
        rw [← h4] at hodd
        have heven : (2 ^ (c - a) * 3 ^ d) % 2 = 0 := by
          cases hc : (c - a) with
          | zero => omega
          | succ x =>
            rw [Nat.pow_succ, Nat.mul_comm (2 ^ x) 2, Nat.mul_assoc]
            omega
        exact absurd hodd (by omega)
      · have hgt : c < a := by omega
        have h1 : 2 ^ c * 2 ^ (a - c) = 2 ^ a := by rw [← Nat.pow_add]; congr 1; omega
        have h2 : 2 ^ c * (2 ^ (a - c) * 3 ^ b) = 2 ^ a * 3 ^ b := by rw [← Nat.mul_assoc, h1]
        have h3 : 2 ^ c * (2 ^ (a - c) * 3 ^ b) = 2 ^ c * 3 ^ d := by rw [h2]; exact h
        have h4 : 2 ^ (a - c) * 3 ^ b = 3 ^ d := Nat.mul_left_cancel (Nat.pow_pos (by omega)) h3
        have hodd : 3 ^ d % 2 = 1 := pow_three_odd d
        rw [← h4] at hodd
        have heven : (2 ^ (a - c) * 3 ^ b) % 2 = 0 := by
          cases hc : (a - c) with
          | zero => omega
          | succ x =>
            rw [Nat.pow_succ, Nat.mul_comm (2 ^ x) 2, Nat.mul_assoc]
            omega
        exact absurd hodd (by omega)
  have hb : b = d := by
    subst ha
    have : 3 ^ b = 3 ^ d := Nat.mul_left_cancel (Nat.pow_pos (by omega)) h
    exact pow_three_injective b d this
  exact ⟨ha, hb⟩

end Multiplicity.Core.Operators.PrimeEncoding
