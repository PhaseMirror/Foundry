import Lean
open Nat

theorem div_dvd_self {n d : Nat} (hn : 0 < n) (h : n % (d + 1) = 0) :
    n % (n / (d + 1)) = 0 := by
  have hdvd : (d + 1) ∣ n := dvd_of_mod_eq_zero h
  have h1 : (n / (d + 1)) * (d + 1) = n := Nat.div_mul_cancel hdvd
  omega

theorem div_double_div {n d : Nat} (hn : 0 < n) (h : n % (d + 1) = 0) :
    n / (n / (d + 1)) = d + 1 := by
  have hdvd : (d + 1) ∣ n := dvd_of_mod_eq_zero h
  have h1 : (n / (d + 1)) * (d + 1) = n := Nat.div_mul_cancel hdvd
  omega
