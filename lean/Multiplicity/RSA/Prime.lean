import Multiplicity.RSA.ModEq

/-!
# Primality and coprimality over `Nat`

A minimal, axiom-free development of the prime and coprime facts needed by the
RSA correctness proof. Core Lean does not ship a prime predicate, so `Prime`
is defined here as the classical property: `p > 1` and every divisor of `p` is
either `1` or `p`.

The main deliverables of this file are

* `coprime_of_prime_ne` : distinct primes are coprime;
* `prime_dvd_of_dvd_mul` : a prime dividing a product divides a factor
  (Euclid's lemma), derived from `Nat.Coprime.dvd_of_dvd_mul_left`.
-/
namespace Multiplicity.RSA

/-- Nondivisibility notation, `a` does not divide `b`. -/
notation:40 a " ∤ " b => ¬ a ∣ b

/-- `p` is a (natural) prime. -/
def Prime (p : Nat) : Prop := 1 < p ∧ ∀ d : Nat, d ∣ p → d = 1 ∨ d = p

theorem prime_one_lt {p : Nat} (hp : Prime p) : 1 < p := hp.1

theorem prime_pos {p : Nat} (hp : Prime p) : 0 < p := by
  have hp' : 1 < p := hp.1
  omega

theorem prime_divisor {p d : Nat} (hp : Prime p) (hd : d ∣ p) : d = 1 ∨ d = p := hp.2 d hd

/-- A positive multiple of `p` smaller than `p` is a contradiction, so a
positive `a < p` is not divisible by the prime `p`. -/
theorem prime_not_dvd_lt {p a : Nat} (_hp : Prime p) (ha : a < p) (h0 : 0 < a) : ¬ p ∣ a := by
  intro h
  have hle : p ≤ a := Nat.le_of_dvd h0 h
  omega

/-- If `p` is prime and `p` divides a product but not the first factor, it
divides the second. -/
theorem prime_dvd_of_dvd_mul {p a b : Nat} (hp : Prime p) (h : p ∣ a * b) (hpa : ¬ p ∣ a) :
    p ∣ b := by
  have hcop : Nat.Coprime p a := by
    unfold Nat.Coprime
    by_cases hg : p.gcd a = 1
    · exact hg
    · have hg1 : p.gcd a ∣ p := Nat.gcd_dvd_left p a
      have hdiv : p.gcd a = 1 ∨ p.gcd a = p := hp.2 (p.gcd a) hg1
      rcases hdiv with h1 | h2
      · exact False.elim (hg h1)
      · have hpd : p ∣ a := by
          have hg2 : p.gcd a ∣ a := Nat.gcd_dvd_right p a
          simpa [h2] using hg2
        exact False.elim (hpa hpd)
  exact Nat.Coprime.dvd_of_dvd_mul_left hcop h

/-- A prime dividing a product divides one of the factors. -/
theorem prime_dvd_or_dvd {p a b : Nat} (hp : Prime p) (h : p ∣ a * b) : p ∣ a ∨ p ∣ b := by
  by_cases hpa : p ∣ a
  · exact Or.inl hpa
  · exact Or.inr (prime_dvd_of_dvd_mul hp h hpa)

/-- Euclid's lemma for coprime numbers: if `n` is coprime to `a` and divides
`a * b`, then it divides `b`. This is the `Nat.Coprime` version of
`prime_dvd_of_dvd_mul`. -/
theorem coprime_dvd_of_dvd_mul {n a b : Nat} (hc : Nat.Coprime n a) (h : n ∣ a * b) : n ∣ b :=
  Nat.Coprime.dvd_of_dvd_mul_left hc h

/-- Distinct primes are coprime. -/
theorem coprime_of_prime_ne {p q : Nat} (hp : Prime p) (hq : Prime q) (hneq : p ≠ q) :
    Nat.Coprime p q := by
  unfold Nat.Coprime
  by_cases h : p.gcd q = 1
  · exact h
  · have hg1 : p.gcd q ∣ p := Nat.gcd_dvd_left p q
    have hg2 : p.gcd q ∣ q := Nat.gcd_dvd_right p q
    rcases hp.2 (p.gcd q) hg1 with h1 | h2
    · exact False.elim (h h1)
    · have hpq : p ∣ q := by
        simpa [h2] using hg2
      rcases hq.2 p hpq with h1' | h2'
      · omega
      · exact False.elim (hneq h2')

/-- `z < n` divisible by `n` must be zero. -/
theorem eq_zero_of_dvd_lt {n z : Nat} (h1 : n ∣ z) (h2 : z < n) : z = 0 := by
  by_cases hn0 : n = 0
  · subst n
    omega
  · have hn : 0 < n := Nat.pos_of_ne_zero hn0
    by_cases hz : z = 0
    · exact hz
    · have hzpos : 0 < z := by omega
      have hle : n ≤ z := Nat.le_of_dvd hzpos h1
      omega

/-- `p` is prime provided `1 < p` and no divisor lies strictly between `1`
and `p`. This is the finite check used to establish `Prime` for concrete
values in the test harness. -/
theorem prime_of_no_divisor {p : Nat} (h1 : 1 < p)
    (h : ∀ d : Nat, 1 < d → d < p → ¬ d ∣ p) : Prime p := by
  constructor
  · exact h1
  · intro d hd
    by_cases hd0 : d = 0
    · subst d
      rcases hd with ⟨c, hc⟩
      have : p = 0 := by simpa using hc
      omega
    · by_cases hd1 : d = 1
      · exact Or.inl hd1
      · by_cases hdp : d = p
        · exact Or.inr hdp
        · have hdlt : 1 < d := by omega
          have hdvd : d < p := by
            have hpos : 0 < p := by omega
            have hle : d ≤ p := Nat.le_of_dvd hpos hd
            omega
          exact False.elim (h d hdlt hdvd hd)

end Multiplicity.RSA
