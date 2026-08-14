import Multiplicity.RSA.ModEq
import Multiplicity.RSA.Prime

/-!
# Chinese remainder: lifting congruences to products

The piece of the CRT that RSA actually needs: if two numbers are congruent
modulo coprime moduli, they are congruent modulo the product.

We go through the divisibility form `n ∣ a - b`: a congruence `a ≡ b [MOD n]`
is translated into a divisibility statement (choosing the order of `a` and
`b` so that the subtraction is not saturated), the divisibility statements
are combined by `Nat.Coprime.mul_dvd_of_dvd_of_dvd`, and the result is
translated back into a congruence by `modEq_of_dvd_sub`.

This gives `modEq_of_modEq_mul`, the lemma used to lift the RSA decryption
congruence from the primes `p` and `q` to their product `p * q`.
-/

namespace Multiplicity.RSA

/-- From `b ≤ a` and `n ∣ (a - b)` we recover `a ≡ b [MOD n]`. -/
theorem modEq_of_dvd_sub {a b n : Nat} (hge : b ≤ a) (h : n ∣ a - b) : a ≡ b [MOD n] := by
  unfold ModEq
  rw [show a = (a - b) + b by omega, Nat.add_mod, (Nat.dvd_iff_mod_eq_zero.mp h)]
  simp

/-- Congruences modulo coprime moduli combine to a congruence modulo their
product. -/
theorem modEq_of_modEq_mul {a b m n : Nat} (hm : a ≡ b [MOD m]) (hn : a ≡ b [MOD n])
    (hmn : Nat.Coprime m n) : a ≡ b [MOD m * n] := by
  cases Nat.le_total b a with
  | inl hba =>
      have hdvd1 : m ∣ a - b := dvd_sub_of_modEq hm hba
      have hdvd2 : n ∣ a - b := dvd_sub_of_modEq hn hba
      have hdvd : m * n ∣ a - b := Nat.Coprime.mul_dvd_of_dvd_of_dvd hmn hdvd1 hdvd2
      exact modEq_of_dvd_sub hba hdvd
  | inr hab =>
      have hdvd1 : m ∣ b - a := dvd_sub_of_modEq hm.symm hab
      have hdvd2 : n ∣ b - a := dvd_sub_of_modEq hn.symm hab
      have hdvd : m * n ∣ b - a := Nat.Coprime.mul_dvd_of_dvd_of_dvd hmn hdvd1 hdvd2
      exact (modEq_of_dvd_sub hab hdvd).symm

end Multiplicity.RSA
