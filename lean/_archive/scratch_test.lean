import Lean
open Nat

theorem div_dvd_self {n d : Nat} (hn : 0 < n) (h : n % (d + 1) = 0) :
    n % (n / (d + 1)) = 0 := by
  have h1 : (n / (d + 1)) * (d + 1) = n := Nat.div_mul_cancel (by exact dvd_of_mod_eq_zero h)
  have h2 : n = (d + 1) * (n / (d + 1)) := by
    rw [Nat.mul_comm, h1]
  exact mod_eq_zero_of_dvd (Dvd.intro (d + 1) h2.symm)

theorem div_double_div {n d : Nat} (hn : 0 < n) (h : n % (d + 1) = 0) :
    n / (n / (d + 1)) = d + 1 := by
  have hdvd : (d + 1) ∣ n := dvd_of_mod_eq_zero h
  have h1 : (n / (d + 1)) * (d + 1) = n := Nat.div_mul_cancel hdvd
  have hpos : 0 < n / (d + 1) := by
    apply Nat.div_pos
    · exact Nat.le_of_dvd hn hdvd
    · exact Nat.zero_lt_succ d
  rw [← h1]
  exact Nat.mul_div_cancel_left (d + 1) hpos

theorem divInvolution_lt {n d : Nat} (hd : d < n) (hdvd : n % (d + 1) = 0) :
    (n / (d + 1) - 1) < n := by
  have hpos : 0 < n := Nat.zero_lt_of_lt hd
  have h_div_lt : n / (d + 1) ≤ n := Nat.div_le_self n (d + 1)
  have h_div_pos : 0 < n / (d + 1) := by
    apply Nat.div_pos
    · exact Nat.le_of_dvd hpos (dvd_of_mod_eq_zero hdvd)
    · exact Nat.zero_lt_succ d
  omega

theorem divInvolution_inv (n d : Nat) (hd : d < n) (hdvd : n % (d + 1) = 0) :
    n / (n / (d + 1) - 1 + 1) - 1 = d := by
  have h1 : n / (d + 1) - 1 + 1 = n / (d + 1) := by
    have h_div_pos : 0 < n / (d + 1) := by
      apply Nat.div_pos
      · exact Nat.le_of_dvd (Nat.zero_lt_of_lt hd) (dvd_of_mod_eq_zero hdvd)
      · exact Nat.zero_lt_succ d
    omega
  rw [h1]
  have h2 : n / (n / (d + 1)) = d + 1 := div_double_div (Nat.zero_lt_of_lt hd) hdvd
  rw [h2]
  omega
