import Foundations.RSA.Fermat
import Foundations.RSA.Prime

/-!
# Euler's totient function and Euler's theorem

Following the Fermat proof in `Fermat.lean`, we prove Euler's theorem for an
arbitrary modulus `n`: if `a` is coprime to `n` then `a ^ phi n ≡ 1 [MOD n]`,
where `phi n` counts the residues coprime to `n`.

The proof is the same product/permutation argument as Fermat's little theorem,
run on the list `residues_coprime n` (the units modulo `n`) instead of `up p`
(all nonzero residues): multiplication by `a` permutes the units, so the
product `P` of the units satisfies `P ≡ a ^ (phi n) * P [MOD n]`, and `P`
is coprime to `n` (a product of units), so it cancels.

We also prove the classical totient formula for prime powers,
`phi (p ^ m) = (p - 1) * p ^ (m - 1)`, by counting the residues not divisible
by `p`.
-/

namespace Multiplicity.RSA

/-- The residues `0 ≤ k < n` that are coprime to `n`, as a list. -/
def residues_coprime (n : Nat) : List Nat :=
  (List.range n).filter (fun k => decide (k.gcd n = 1))

/-- Euler's totient function: the number of residues coprime to `n`. -/
def phi (n : Nat) : Nat := (residues_coprime n).length

theorem mem_residues_coprime_iff {n k : Nat} :
    k ∈ residues_coprime n ↔ k < n ∧ k.gcd n = 1 := by
  unfold residues_coprime
  rw [List.mem_filter]
  constructor
  · rintro ⟨hk, hg⟩
    constructor
    · exact List.mem_range.mp hk
    · exact of_decide_eq_true hg
  · intro h
    constructor
    · exact List.mem_range.mpr h.1
    · exact decide_eq_true h.2

/-- Filtering a `Nodup` list keeps it `Nodup`. -/
theorem nodup_filter {α : Type} (p : α → Bool) {l : List α} (hl : l.Nodup) :
    (List.filter p l).Nodup := by
  induction l with
  | nil => simp
  | cons a t ih =>
      rw [List.filter_cons]
      by_cases hpa : p a = true
      · simp [hpa]
        constructor
        · exact (List.nodup_cons.mp hl).1
        · exact ih (List.nodup_cons.mp hl).2
      · rw [if_neg hpa]
        exact ih (List.nodup_cons.mp hl).2

theorem residues_coprime_nodup (n : Nat) : (residues_coprime n).Nodup := by
  unfold residues_coprime
  exact nodup_filter _ List.nodup_range

/-! ## Euclid's step for the gcd -/

/-- The gcd is unchanged by reducing the first argument modulo the second. -/
theorem gcd_mod {a n : Nat} : (a % n).gcd n = a.gcd n := by
  apply Nat.dvd_antisymm
  · apply Nat.dvd_gcd
    · have h1 : (a % n).gcd n ∣ a % n := Nat.gcd_dvd_left (a % n) n
      have h2 : (a % n).gcd n ∣ (a / n) * n :=
        Nat.dvd_trans (Nat.gcd_dvd_right (a % n) n) (Nat.dvd_mul_left n (a / n))
      have h3 : (a % n).gcd n ∣ (a / n) * n + a % n := Nat.dvd_add h2 h1
      have hsum : (a / n) * n + a % n = a := by
        rw [Nat.add_comm, Nat.mul_comm]
        exact Nat.mod_add_div a n
      rw [hsum] at h3
      exact h3
    · exact Nat.gcd_dvd_right (a % n) n
  · apply Nat.dvd_gcd
    · have h1 : a.gcd n ∣ a := Nat.gcd_dvd_left a n
      have h2 : a.gcd n ∣ (a / n) * n :=
        Nat.dvd_trans (Nat.gcd_dvd_right a n) (Nat.dvd_mul_left n (a / n))
      have h3 : a.gcd n ∣ a - (a / n) * n := Nat.dvd_sub h1 h2
      have heq : a % n = a - (a / n) * n := by
        have hsum : (a / n) * n + a % n = a := by
          rw [Nat.add_comm, Nat.mul_comm]
          exact Nat.mod_add_div a n
        omega
      simpa [heq] using h3
    · exact Nat.gcd_dvd_right a n

/-- Coprimality is unchanged by reducing the first argument modulo the second. -/
theorem coprime_mod_left {a n : Nat} : Nat.Coprime (a % n) n ↔ Nat.Coprime a n := by
  unfold Nat.Coprime
  rw [gcd_mod]

/-! ## Multiplication permutes the units modulo `n` -/

/-- Multiplying a unit by `a` (coprime to `n`) and reducing keeps it a unit. -/
theorem residues_coprime_mul_mem {n a : Nat} (hc : Nat.Coprime a n) (hn : 0 < n) :
    ∀ x ∈ residues_coprime n, (a * x) % n ∈ residues_coprime n := by
  intro x hx
  rw [mem_residues_coprime_iff]
  constructor
  · exact Nat.mod_lt (a * x) hn
  · have hx₂ : Nat.Coprime x n := (mem_residues_coprime_iff.mp hx).2
    have hcop' : Nat.Coprime (a * x) n := Nat.Coprime.mul_left hc hx₂
    exact (coprime_mod_left (a := a * x) (n := n)).mpr hcop'

/-- Multiplication by a unit is injective on the units modulo `n`. -/
theorem residues_coprime_mul_injective {n a : Nat} (hc : Nat.Coprime n a) :
    ∀ x ∈ residues_coprime n, ∀ y ∈ residues_coprime n,
      (a * x) % n = (a * y) % n → x = y := by
  intro x hx y hy hxy
  have hxn : x < n := (mem_residues_coprime_iff.mp hx).1
  have hyn : y < n := (mem_residues_coprime_iff.mp hy).1
  have hcong : a * x ≡ a * y [MOD n] := hxy
  cases Nat.le_total y x with
  | inl hyx =>
      have hge : a * y ≤ a * x := Nat.mul_le_mul_left a hyx
      have hdvd : n ∣ a * x - a * y := dvd_sub_of_modEq hcong hge
      have hstep : a * x - a * y = a * (x - y) := by
        calc
          a * x - a * y = x * a - y * a := by rw [Nat.mul_comm a, Nat.mul_comm a]
          _ = (x - y) * a := by rw [Nat.mul_sub_right_distrib]
          _ = a * (x - y) := by rw [Nat.mul_comm]
      have hdvd' : n ∣ a * (x - y) := by simpa [hstep] using hdvd
      have hdiv : n ∣ x - y := coprime_dvd_of_dvd_mul hc hdvd'
      have hlt : x - y < n := by omega
      have h0 : x - y = 0 := eq_zero_of_dvd_lt hdiv hlt
      omega
  | inr hxy =>
      have hge : a * x ≤ a * y := Nat.mul_le_mul_left a hxy
      have hdvd : n ∣ a * y - a * x := dvd_sub_of_modEq hcong.symm hge
      have hstep : a * y - a * x = a * (y - x) := by
        calc
          a * y - a * x = y * a - x * a := by rw [Nat.mul_comm a, Nat.mul_comm a]
          _ = (y - x) * a := by rw [Nat.mul_sub_right_distrib]
          _ = a * (y - x) := by rw [Nat.mul_comm]
      have hdvd' : n ∣ a * (y - x) := by simpa [hstep] using hdvd
      have hdiv : n ∣ y - x := coprime_dvd_of_dvd_mul hc hdvd'
      have hlt : y - x < n := by omega
      have h0 : y - x = 0 := eq_zero_of_dvd_lt hdiv hlt
      omega

/-- Multiplication by a unit permutes the units modulo `n`. -/
theorem residues_coprime_perm_mul {n a : Nat} (hc : Nat.Coprime n a) (hn : 0 < n) :
    ((residues_coprime n).map (fun x => (a * x) % n)).Perm (residues_coprime n) := by
  apply perm_of_nodup_subset_length
  · exact nodup_map (fun x => (a * x) % n) (residues_coprime_nodup n)
      (residues_coprime_mul_injective hc)
  · exact residues_coprime_nodup n
  · rw [List.length_map]
  · intro x hx
    rcases (List.mem_map.mp hx) with ⟨y, hy, hfx⟩
    have hmem : (a * y) % n ∈ residues_coprime n :=
      residues_coprime_mul_mem (Nat.Coprime.symm hc) hn y hy
    simpa [hfx] using hmem

/-! ## Cancelling a factor coprime to the modulus -/

/-- A product of numbers each coprime to `n` is coprime to `n`. -/
theorem coprime_product {n : Nat} {l : List Nat} (h : ∀ x ∈ l, Nat.Coprime x n) :
    Nat.Coprime (product l) n := by
  induction l with
  | nil =>
      rw [product_nil]
      simp [Nat.Coprime, Nat.gcd_one_left]
  | cons x l ih =>
      rw [product_cons]
      exact Nat.Coprime.mul_left (h x (by simp))
        (ih (fun y hy => h y (by simp [hy])))

/-- A factor coprime to the modulus can be cancelled in a congruence. -/
theorem modEq_mul_left_cancel {a b c n : Nat} (h : c * a ≡ c * b [MOD n])
    (hc : Nat.Coprime c n) : a ≡ b [MOD n] := by
  cases Nat.le_total a b with
  | inl hab =>
      have hge : c * a ≤ c * b := Nat.mul_le_mul_left c hab
      have hdvd : n ∣ c * b - c * a := dvd_sub_of_modEq h.symm hge
      have hstep : c * b - c * a = c * (b - a) := by
        calc
          c * b - c * a = b * c - a * c := by rw [Nat.mul_comm c, Nat.mul_comm c]
          _ = (b - a) * c := by rw [Nat.mul_sub_right_distrib]
          _ = c * (b - a) := by rw [Nat.mul_comm]
      have hdvd' : n ∣ c * (b - a) := by simpa [hstep] using hdvd
      have hdiv : n ∣ b - a := coprime_dvd_of_dvd_mul (Nat.Coprime.symm hc) hdvd'
      exact (modEq_of_dvd_sub hab hdiv).symm
  | inr hba =>
      have hge : c * b ≤ c * a := Nat.mul_le_mul_left c hba
      have hdvd : n ∣ c * a - c * b := dvd_sub_of_modEq h hge
      have hstep : c * a - c * b = c * (a - b) := by
        calc
          c * a - c * b = a * c - b * c := by rw [Nat.mul_comm c, Nat.mul_comm c]
          _ = (a - b) * c := by rw [Nat.mul_sub_right_distrib]
          _ = c * (a - b) := by rw [Nat.mul_comm]
      have hdvd' : n ∣ c * (a - b) := by simpa [hstep] using hdvd
      have hdiv : n ∣ a - b := coprime_dvd_of_dvd_mul (Nat.Coprime.symm hc) hdvd'
      exact modEq_of_dvd_sub hba hdiv

/-! ## Euler's theorem -/

/-- **Euler's theorem**: if `a` is coprime to `n`, then `a ^ phi n ≡ 1 [MOD n]`. -/
theorem euler_theorem {n a : Nat} (hc : Nat.Coprime a n) (hn : 0 < n) :
    a ^ phi n ≡ 1 [MOD n] := by
  let R := residues_coprime n
  let P := product R
  have hperm : (R.map (fun x => (a * x) % n)).Perm R :=
    residues_coprime_perm_mul (Nat.Coprime.symm hc) hn
  have hprod_eq : product (R.map (fun x => (a * x) % n)) = P :=
    product_perm hperm
  have hcong1 : product (R.map (fun x => (a * x) % n)) ≡
      product (R.map (fun x => a * x)) [MOD n] := by
    apply product_map_modEq
    intro x hx
    exact Nat.mod_mod (a * x) n
  have hcong2 : product (R.map (fun x => a * x)) ≡ a ^ phi n * P [MOD n] := by
    rw [product_map_mul_left]
    simp [R, P, phi, ModEq]
  have hprod_cong : P ≡ a ^ phi n * P [MOD n] := by
    have h1 : P ≡ product (R.map (fun x => (a * x) % n)) [MOD n] :=
      modEq_of_eq hprod_eq.symm
    have h2 : P ≡ product (R.map (fun x => a * x)) [MOD n] := modEq_trans h1 hcong1
    exact modEq_trans h2 hcong2
  have hcopP : Nat.Coprime P n := by
    unfold P
    apply coprime_product
    intro x hx
    exact (mem_residues_coprime_iff.mp hx).2
  have hcanc' : P * a ^ phi n ≡ P * 1 [MOD n] := by
    have h1 : P * a ^ phi n ≡ a ^ phi n * P [MOD n] := modEq_of_eq (by rw [Nat.mul_comm])
    have h2 : a ^ phi n * P ≡ P [MOD n] := hprod_cong.symm
    have h3 : P ≡ P * 1 [MOD n] := (modEq_of_eq (Nat.mul_one P)).symm
    exact modEq_trans (modEq_trans h1 h2) h3
  exact modEq_mul_left_cancel hcanc' hcopP

/-! ## Counting: the totient of a prime power -/

/-- A `Bool`-filter and its negation partition a list. -/
theorem length_filter_add {α : Type} (p : α → Bool) (l : List α) :
    (List.filter p l).length + (List.filter (fun x => !p x) l).length = l.length := by
  induction l with
  | nil => simp
  | cons a t ih =>
      rw [List.filter_cons]
      rw [List.filter_cons]
      by_cases hpa : p a = true
      · simp [hpa]
        omega
      · rw [if_neg hpa]
        have hna : (!p a) = true := by
          have hpa' : p a = false := by
            cases h : p a with
            | false => rfl
            | true => exact False.elim (hpa h)
          rw [hpa']
          rfl
        simp [hna]
        omega

/-- Removing the first occurrence of `a` from a `Nodup` list drops `a`. -/
theorem not_mem_erase_self {α : Type} [BEq α] [LawfulBEq α] {a : α} {l : List α}
    (hn : l.Nodup) : a ∉ l.erase a := by
  induction l with
  | nil => simp
  | cons b t ih =>
      by_cases hba : (b == a) = true
      · have hb' : b = a := LawfulBEq.eq_of_beq hba
        subst b
        rw [List.erase_cons_head a t]
        exact (List.nodup_cons.mp hn).1
      · rw [List.erase_cons_tail hba]
        have hne : a ≠ b := by
          intro hab
          have hb : (b == a) = true := by rw [hab]; simp
          exact hba hb
        intro hmem
        rw [List.mem_cons] at hmem
        rcases hmem with hba' | hmemt
        · exact False.elim (hne hba')
        · exact ih (List.nodup_cons.mp hn).2 hmemt

/-- Lists with the same elements, both without duplicates, are permutations. -/
theorem perm_of_nodup_iff {α : Type} [BEq α] [LawfulBEq α] {l₁ l₂ : List α}
    (hnod₁ : l₁.Nodup) (hnod₂ : l₂.Nodup)
    (hsub₁ : ∀ x, x ∈ l₁ → x ∈ l₂) (hsub₂ : ∀ x, x ∈ l₂ → x ∈ l₁) : l₁.Perm l₂ := by
  induction l₁ generalizing l₂ with
  | nil =>
      cases l₂ with
      | nil => simp
      | cons a t =>
          have : a ∈ ([] : List α) := hsub₂ a (by simp)
          simp at this
  | cons a t ih =>
      have hal : a ∈ l₂ := hsub₁ a (by simp)
      have hperm₂ : (l₂.erase a ++ [a]).Perm l₂ := perm_erase_append l₂ a hal
      have hnod₂' : (l₂.erase a).Nodup := List.Nodup.erase a hnod₂
      have hsub₁' : ∀ x, x ∈ t → x ∈ l₂.erase a := by
        intro x hx
        have hx₂ : x ∈ l₂ := hsub₁ x (by simp [hx])
        have hne : x ≠ a := by
          intro hxa
          exact (List.nodup_cons.mp hnod₁).1 (by simpa [hxa] using hx)
        rw [List.mem_erase_of_ne hne]
        exact hx₂
      have hsub₂' : ∀ x, x ∈ l₂.erase a → x ∈ t := by
        intro x hx
        have hx₂ : x ∈ l₂ := List.mem_of_mem_erase hx
        have hx₁ : x ∈ a :: t := hsub₂ x hx₂
        have hne : x ≠ a := by
          intro hxa
          exact not_mem_erase_self hnod₂ (by simpa [hxa] using hx)
        rw [List.mem_cons] at hx₁
        rcases hx₁ with hba' | hxt
        · exact False.elim (hne hba')
        · exact hxt
      have hih : t.Perm (l₂.erase a) := ih (List.nodup_cons.mp hnod₁).2 hnod₂' hsub₁' hsub₂'
      exact (cons_append_perm a t).trans
        ((List.Perm.append_right [a] hih).trans hperm₂)

/-! ## Coprimality to a prime power -/

/-- A prime power is divisible by its prime, for exponent at least one. -/
theorem prime_dvd_pow_self {p m : Nat} (hm : 1 ≤ m) : p ∣ p ^ m := by
  obtain ⟨s, hs⟩ : ∃ s, m = s + 1 := ⟨m - 1, by omega⟩
  subst m
  refine ⟨p ^ s, ?_⟩
  rw [Nat.pow_succ, Nat.mul_comm]

/-- A number not divisible by the prime `p` is coprime to `p`. -/
theorem coprime_prime_of_not_dvd {p a : Nat} (hp : Prime p) (hpa : ¬ p ∣ a) :
    Nat.Coprime a p := by
  unfold Nat.Coprime
  by_cases hg : a.gcd p = 1
  · exact hg
  · have hgp : a.gcd p ∣ p := Nat.gcd_dvd_right a p
    have hdiv : a.gcd p = 1 ∨ a.gcd p = p := hp.2 (a.gcd p) hgp
    have hg' : a.gcd p = p := by
      rcases hdiv with h1 | hp'
      · exact False.elim (hg h1)
      · exact hp'
    have hga : a.gcd p ∣ a := Nat.gcd_dvd_left a p
    have hpa' : p ∣ a := by simpa [hg'] using hga
    exact False.elim (hpa hpa')

/-- Coprimality to `p` extends to all powers of `p`. -/
theorem coprime_pow_right {p m a : Nat} (hcop : Nat.Coprime a p) :
    Nat.Coprime a (p ^ m) := by
  induction m with
  | zero => simp [Nat.Coprime, Nat.gcd_one_right]
  | succ m ih =>
      have hs : p ^ (m + 1) = p ^ m * p := by rw [Nat.pow_succ]
      have hfinal : Nat.Coprime a (p ^ m * p) := Nat.Coprime.mul_right ih hcop
      simpa [hs] using hfinal

/-- Coprimality to a prime power is equivalent to non-divisibility by the prime. -/
theorem coprime_of_prime_power_not_dvd {p m a : Nat} (hp : Prime p) (hm : 1 ≤ m) :
    Nat.Coprime a (p ^ m) ↔ ¬ p ∣ a := by
  constructor
  · intro hc hpa
    have hpd : p ∣ p ^ m := prime_dvd_pow_self hm
    have hpg : p ∣ a.gcd (p ^ m) := Nat.dvd_gcd hpa hpd
    have hg1 : a.gcd (p ^ m) = 1 := hc
    have hp1 : p ∣ 1 := by simpa [hg1] using hpg
    have hple : p ≤ 1 := Nat.le_of_dvd (by omega : 0 < 1) hp1
    have hpgt : 1 < p := hp.1
    omega
  · intro hpa
    exact coprime_pow_right (coprime_prime_of_not_dvd hp hpa)

/-- For `k` below a prime power, `gcd k (p ^ m) = 1` is the negation of `p ∣ k`. -/
theorem gcd_pow_filter_eq {p m k : Nat} (hp : Prime p) (hm : 1 ≤ m) :
    decide (k.gcd (p ^ m) = 1) = !(k % p == 0) := by
  by_cases hcop : k.gcd (p ^ m) = 1
  · have hleft : decide (k.gcd (p ^ m) = 1) = true := decide_eq_true hcop
    have hndvd : ¬ p ∣ k := (coprime_of_prime_power_not_dvd hp hm).mp hcop
    have hmod : ¬ k % p = 0 := by
      intro hz
      exact hndvd (Nat.dvd_iff_mod_eq_zero.mpr hz)
    have hright : Bool.not (k % p == 0) = true := by
      cases hb : k % p == 0 with
      | false => rfl
      | true => exact False.elim (hmod (LawfulBEq.eq_of_beq hb))
    rw [hleft]
    simp [hright]
  · have hleft : decide (k.gcd (p ^ m) = 1) = false := by
      cases hb : decide (k.gcd (p ^ m) = 1) with
      | false => rfl
      | true => exact False.elim (hcop (of_decide_eq_true hb))
    have hmod : k % p = 0 := by
      by_cases hz : k % p = 0
      · exact hz
      · have hndvd : ¬ p ∣ k := by
          intro hd
          exact hz (Nat.dvd_iff_mod_eq_zero.mp hd)
        have hc : k.gcd (p ^ m) = 1 := (coprime_of_prime_power_not_dvd hp hm).mpr hndvd
        exact False.elim (hcop hc)
    have hright : Bool.not (k % p == 0) = false := by
      have hbeq : (k % p == 0) = true := by simp [hmod]
      simp [hbeq]
    rw [hleft]
    simp [hright]

/-- The residues below `p ^ m` divisible by `p` are exactly the multiples `p · t`. -/
theorem phi_prime_power {p m : Nat} (hp : Prime p) (hm : 1 ≤ m) :
    phi (p ^ m) = (p - 1) * p ^ (m - 1) := by
  have hfilter :
      (List.range (p ^ m)).filter (fun k => decide (k.gcd (p ^ m) = 1)) =
        (List.range (p ^ m)).filter (fun k => !(k % p == 0)) := by
    apply List.filter_congr
    intro k hk
    exact gcd_pow_filter_eq hp hm
  have hperm : (List.filter (fun k => k % p == 0) (List.range (p ^ m))).Perm
      (List.map (fun t => t * p) (List.range (p ^ (m - 1)))) := by
    apply perm_of_nodup_iff
    · exact nodup_filter (fun k => k % p == 0) List.nodup_range
    · apply nodup_map (fun t => t * p)
      · exact List.nodup_range
      · intro t₁ ht₁ t₂ ht₂ h
        exact Nat.eq_of_mul_eq_mul_right (prime_pos hp) h
    · intro x hx
      have hfx : x ∈ List.filter (fun k => k % p == 0) (List.range (p ^ m)) := hx
      have hxr : x < p ^ m := List.mem_range.mp (List.mem_filter.mp hfx).1
      have hxd : p ∣ x :=
        Nat.dvd_iff_mod_eq_zero.mpr (LawfulBEq.eq_of_beq (List.mem_filter.mp hfx).2)
      rcases hxd with ⟨c, hc⟩
      have hxdiv : x / p < p ^ (m - 1) := by
        have hle : x / p * p ≤ x := Nat.div_mul_le_self x p
        have hlt : x / p * p < p ^ m := Nat.lt_of_le_of_lt hle hxr
        have hpw : p ^ m = p * p ^ (m - 1) := by
          have hm' : m = (m - 1) + 1 := by omega
          rw [hm', Nat.pow_add]
          simp [Nat.mul_comm]
        have hlt' : x / p * p < p * p ^ (m - 1) := by simpa [hpw] using hlt
        have hlt'' : p * (x / p) < p * p ^ (m - 1) := by simpa [Nat.mul_comm] using hlt'
        exact Nat.lt_of_mul_lt_mul_left hlt''
      rw [List.mem_map]
      refine ⟨x / p, List.mem_range.mpr hxdiv, ?_⟩
      have hdiv : x / p = c := by
        rw [hc, Nat.mul_div_right c (prime_pos hp)]
      rw [Nat.mul_comm, hdiv, hc]
    · intro x hx
      rcases (List.mem_map.mp hx) with ⟨t, ht, hfx⟩
      have hxr : x < p ^ m := by
        have ht' : t < p ^ (m - 1) := List.mem_range.mp ht
        have hlt : t * p < p ^ (m - 1) * p := (Nat.mul_lt_mul_right (prime_pos hp)).mpr ht'
        have hpw : p ^ (m - 1) * p = p ^ m := by
          calc
            p ^ (m - 1) * p = p ^ (m - 1) * p ^ 1 := by rw [Nat.pow_one]
            _ = p ^ ((m - 1) + 1) := by rw [Nat.pow_add]
            _ = p ^ m := by congr 1; omega
        simpa [hpw, hfx] using hlt
      rw [List.mem_filter]
      constructor
      · exact List.mem_range.mpr hxr
      · have hmod : x % p = 0 := by
          rw [hfx.symm, Nat.mul_mod]
          simp
        have hb : (x % p == 0) = true := by simp [hmod]
        exact hb
  have hlen1 : (List.filter (fun k => k % p == 0) (List.range (p ^ m))).length =
      p ^ (m - 1) := by
    calc
      (List.filter (fun k => k % p == 0) (List.range (p ^ m))).length
          = (List.map (fun t => t * p) (List.range (p ^ (m - 1)))).length :=
        List.Perm.length_eq hperm
      _ = p ^ (m - 1) := by rw [List.length_map, List.length_range]
  have hlen2 : (List.filter (fun k => !(k % p == 0)) (List.range (p ^ m))).length =
      p ^ m - p ^ (m - 1) := by
    have hpart := length_filter_add (fun k => k % p == 0) (List.range (p ^ m))
    have hrange : (List.range (p ^ m)).length = p ^ m := List.length_range
    have hsum : p ^ (m - 1) + (List.filter (fun k => !(k % p == 0)) (List.range (p ^ m))).length =
        p ^ m := by
      simpa [hlen1, hrange, Nat.add_comm] using hpart
    omega
  have htarget : p ^ m - p ^ (m - 1) = (p - 1) * p ^ (m - 1) := by
    have hpw : p ^ m = p * p ^ (m - 1) := by
      have hm' : m = (m - 1) + 1 := by omega
      rw [hm', Nat.pow_add]
      simp [Nat.mul_comm]
    rw [hpw]
    calc
      p * p ^ (m - 1) - p ^ (m - 1) = p * p ^ (m - 1) - 1 * p ^ (m - 1) := by
        rw [Nat.one_mul]
      _ = (p - 1) * p ^ (m - 1) := by rw [Nat.mul_sub_right_distrib]
  unfold phi
  unfold residues_coprime
  rw [hfilter]
  rw [hlen2]
  rw [htarget]

/-! ## Totient multiplicativity -/

/-- `decide` respects logical equivalence. -/
theorem decide_congr {P Q : Prop} [Decidable P] [Decidable Q] (h : P ↔ Q) :
    decide P = decide Q := by
  by_cases hp : P
  · have hq : Q := h.mp hp
    rw [decide_eq_true hp, decide_eq_true hq]
  · have hnq : ¬ Q := fun hq => hp (h.mpr hq)
    rw [decide_eq_false hp, decide_eq_false hnq]

theorem map_congr {α β : Type} {l : List α} {f g : α → β} (h : ∀ x ∈ l, f x = g x) :
    l.map f = l.map g := by
  induction l with
  | nil => simp
  | cons a t ih =>
      have h₁ : f a = g a := h a (by simp)
      have h₂ : t.map f = t.map g := ih (fun x hx => h x (by simp [hx]))
      simp [h₁, h₂]

theorem sum_map_congr {α : Type} {l : List α} {f g : α → Nat} (h : ∀ x ∈ l, f x = g x) :
    (l.map f).sum = (l.map g).sum := by
  rw [map_congr h]

/-- `sum` of `(p x).toNat` over a list is the length of the filtered list. -/
theorem sum_toNat_filter {α : Type} (p : α → Bool) (l : List α) :
    (l.map (fun x => (p x).toNat)).sum = (l.filter p).length := by
  induction l with
  | nil => simp
  | cons a t ih =>
      cases hp : p a with
      | false =>
          have hz : (p a).toNat = 0 := by simp [hp]
          simp [ih, hp]
      | true =>
          have ho : (p a).toNat = 1 := by simp [hp]
          simp [ih, hp, Nat.add_comm]

/-- The sum of `c x * m` over a list is the sum of `c x` times `m`. -/
theorem sum_map_mul_right {α : Type} (l : List α) (c : α → Nat) (m : Nat) :
    (l.map (fun x => c x * m)).sum = (l.map c).sum * m := by
  induction l with
  | nil => simp
  | cons a t ih =>
      rw [List.map_cons, List.map_cons, List.sum_cons, List.sum_cons]
      rw [ih]
      rw [Nat.add_mul]

/-- `sum` over a range of a constant is `a * m`. -/
theorem sum_range_const (a m : Nat) : ((List.range a).map (fun _ => m)).sum = a * m := by
  induction a with
  | zero => simp [List.range_zero]
  | succ a ih =>
      rw [List.range_succ]
      rw [List.map_append, List.sum_append]
      rw [ih]
      rw [Nat.add_mul]
      simp [Nat.one_mul]

/-- A filter over the constant-false predicate is empty. -/
theorem length_filter_false {α : Type} (l : List α) :
    (l.filter (fun _ => false)).length = 0 := by
  induction l with
  | nil => simp
  | cons a t ih =>
      rw [List.filter_cons]
      simp [ih]

/-- `gcd x (a * b) = 1` iff `x` is coprime to both `a` and `b`. -/
theorem gcd_mul_right_eq_one_iff {x a b : Nat} :
    x.gcd (a * b) = 1 ↔ x.gcd a = 1 ∧ x.gcd b = 1 := by
  constructor
  · intro h
    constructor
    · have hd : x.gcd a ∣ x.gcd (a * b) := by
        apply Nat.dvd_gcd
        · exact Nat.gcd_dvd_left x a
        · exact Nat.dvd_trans (Nat.gcd_dvd_right x a) (Nat.dvd_mul_right a b)
      exact Nat.eq_one_of_dvd_one (by simpa [h] using hd)
    · have hd : x.gcd b ∣ x.gcd (a * b) := by
        apply Nat.dvd_gcd
        · exact Nat.gcd_dvd_left x b
        · exact Nat.dvd_trans (Nat.gcd_dvd_right x b) (Nat.dvd_mul_left b a)
      exact Nat.eq_one_of_dvd_one (by simpa [h] using hd)
  · rintro ⟨ha, hb⟩
    exact Nat.Coprime.mul_right ha hb

/-- The gcd is unchanged by adding a multiple of the modulus. -/
theorem gcd_add_mul_left {i a t : Nat} : (i + a * t).gcd a = i.gcd a := by
  have hmod : (i + a * t) % a = i % a := by
    rw [Nat.add_mod, Nat.mul_mod]
    simp
  calc
    (i + a * t).gcd a = ((i + a * t) % a).gcd a := (gcd_mod (a := i + a * t) (n := a)).symm
    _ = (i % a).gcd a := by rw [hmod]
    _ = i.gcd a := gcd_mod (a := i) (n := a)

/-- For fixed `a`, `b` coprime, the map `t ↦ (i + a * t) % b` is injective on
the range `0..b-1`. -/
theorem slice_map_injective {a b i : Nat} (hcop : Nat.Coprime b a) :
    ∀ t₁ ∈ List.range b, ∀ t₂ ∈ List.range b,
      (i + a * t₁) % b = (i + a * t₂) % b → t₁ = t₂ := by
  intro t₁ ht₁ t₂ ht₂ hft
  have ht₁b : t₁ < b := List.mem_range.mp ht₁
  have ht₂b : t₂ < b := List.mem_range.mp ht₂
  have hcong : i + a * t₁ ≡ i + a * t₂ [MOD b] := hft
  cases Nat.le_total t₂ t₁ with
  | inl h21 =>
      have hge : i + a * t₂ ≤ i + a * t₁ :=
        Nat.add_le_add_left (Nat.mul_le_mul_left a h21) i
      have hdvd : b ∣ (i + a * t₁) - (i + a * t₂) := dvd_sub_of_modEq hcong hge
      have hstep : (i + a * t₁) - (i + a * t₂) = a * (t₁ - t₂) := by
        calc
          (i + a * t₁) - (i + a * t₂) = a * t₁ - a * t₂ :=
            Nat.add_sub_add_left i (a * t₁) (a * t₂)
          _ = a * (t₁ - t₂) := (Nat.mul_sub_left_distrib a t₁ t₂).symm
      have hdvd' : b ∣ a * (t₁ - t₂) := by simpa [hstep] using hdvd
      have hdiv : b ∣ t₁ - t₂ := coprime_dvd_of_dvd_mul hcop hdvd'
      have hlt : t₁ - t₂ < b := Nat.lt_of_le_of_lt (Nat.sub_le t₁ t₂) ht₁b
      have h0 : t₁ - t₂ = 0 := eq_zero_of_dvd_lt hdiv hlt
      omega
  | inr h12 =>
      have hge : i + a * t₁ ≤ i + a * t₂ :=
        Nat.add_le_add_left (Nat.mul_le_mul_left a h12) i
      have hdvd : b ∣ (i + a * t₂) - (i + a * t₁) := dvd_sub_of_modEq hcong.symm hge
      have hstep : (i + a * t₂) - (i + a * t₁) = a * (t₂ - t₁) := by
        calc
          (i + a * t₂) - (i + a * t₁) = a * t₂ - a * t₁ :=
            Nat.add_sub_add_left i (a * t₂) (a * t₁)
          _ = a * (t₂ - t₁) := (Nat.mul_sub_left_distrib a t₂ t₁).symm
      have hdvd' : b ∣ a * (t₂ - t₁) := by simpa [hstep] using hdvd
      have hdiv : b ∣ t₂ - t₁ := coprime_dvd_of_dvd_mul hcop hdvd'
      have hlt : t₂ - t₁ < b := Nat.lt_of_le_of_lt (Nat.sub_le t₂ t₁) ht₂b
      have h0 : t₂ - t₁ = 0 := eq_zero_of_dvd_lt hdiv hlt
      omega

/-- The slice of residues `t < b` with `gcd (i + a * t) b = 1` has exactly
`phi b` elements: multiplication by `a` (a unit mod `b`) permutes the
residues, so the count of `b`-coprime values is independent of `i`. -/
theorem slice_phi_length {a b i : Nat} (hcop : Nat.Coprime b a) (hb : 0 < b) :
    ((List.range b).filter (fun t => decide ((i + a * t).gcd b = 1))).length = phi b := by
  have hperm : (List.map (fun t => (i + a * t) % b) (List.range b)).Perm (List.range b) := by
    apply perm_of_nodup_subset_length
    · exact nodup_map (fun t => (i + a * t) % b) List.nodup_range
        (slice_map_injective hcop)
    · exact List.nodup_range
    · rw [List.length_map, List.length_range]
    · intro x hx
      rcases (List.mem_map.mp hx) with ⟨t, ht, hfx⟩
      have hlt : (i + a * t) % b < b := Nat.mod_lt (i + a * t) hb
      simpa [hfx] using hlt
  have hlen : (List.filter (fun y => decide (y.gcd b = 1))
        (List.map (fun t => (i + a * t) % b) (List.range b))).length = phi b := by
    have hperm' := List.Perm.filter (fun y => decide (y.gcd b = 1)) hperm
    calc
      (List.filter (fun y => decide (y.gcd b = 1))
          (List.map (fun t => (i + a * t) % b) (List.range b))).length
          = (List.filter (fun y => decide (y.gcd b = 1)) (List.range b)).length :=
            List.Perm.length_eq hperm'
      _ = phi b := by
        unfold phi residues_coprime
        rfl
  have hlen1 : (List.filter (fun t => decide (((i + a * t) % b).gcd b = 1))
        (List.range b)).length = phi b := by
    have hmap : List.filter (fun y => decide (y.gcd b = 1))
          (List.map (fun t => (i + a * t) % b) (List.range b))
        = List.map (fun t => (i + a * t) % b)
            (List.filter (fun t => decide (((i + a * t) % b).gcd b = 1)) (List.range b)) := by
      exact List.filter_map (f := fun t => (i + a * t) % b)
        (p := fun y => decide (y.gcd b = 1)) (l := List.range b)
    calc
      (List.filter (fun t => decide (((i + a * t) % b).gcd b = 1)) (List.range b)).length
          = (List.filter (fun y => decide (y.gcd b = 1))
              (List.map (fun t => (i + a * t) % b) (List.range b))).length := by
            rw [hmap]
            simp
      _ = phi b := hlen
  have hfc : (List.range b).filter (fun t => decide ((i + a * t).gcd b = 1))
      = (List.range b).filter (fun t => decide (((i + a * t) % b).gcd b = 1)) := by
    apply List.filter_congr
    intro t ht
    apply decide_congr
    constructor
    · intro h
      rw [gcd_mod]
      exact h
    · intro h
      rw [← gcd_mod]
      exact h
  calc
    ((List.range b).filter (fun t => decide ((i + a * t).gcd b = 1))).length
        = ((List.range b).filter (fun t => decide (((i + a * t) % b).gcd b = 1))).length := by
          rw [hfc]
    _ = phi b := hlen1

/-- The flattened slices `i + c * t` (`i < a`, `t < b`) have no duplicates,
provided the modulus `c` exceeds the index bound `a`. -/
theorem nodup_flatMap_decomp {a c b : Nat} (hac : a ≤ c) :
    ((List.range a).flatMap (fun i => (List.range b).map (fun t => i + c * t))).Nodup := by
  induction a with
  | zero => simp [List.range_zero, List.flatMap_nil]
  | succ a' ih =>
      have hrec : (List.range (a' + 1)).flatMap (fun i => (List.range b).map (fun t => i + c * t))
          = (List.range a').flatMap (fun i => (List.range b).map (fun t => i + c * t))
            ++ (List.range b).map (fun t => a' + c * t) := by
        rw [List.range_succ]
        rw [List.flatMap_append]
        simp [List.flatMap]
      rw [hrec]
      rw [List.nodup_append]
      constructor
      · exact ih (Nat.le_trans (Nat.le_succ a') hac)
      · constructor
        · have hcpos : 0 < c := by omega
          apply nodup_map (fun t => a' + c * t) List.nodup_range
          intro t₁ ht₁ t₂ ht₂ h
          have hc : c * t₁ = c * t₂ := Nat.add_left_cancel h
          exact Nat.eq_of_mul_eq_mul_left hcpos hc
        · intro x hx₁ b hx₂
          rcases (List.mem_map.mp hx₂) with ⟨t₂, ht₂, hfx₂⟩
          rcases (List.mem_flatMap.mp hx₁) with ⟨i, hi, hxi⟩
          rcases (List.mem_map.mp hxi) with ⟨t₁, ht₁, hfx₁⟩
          have hi' : i < a' := List.mem_range.mp hi
          have hac' : a' < c := Nat.lt_of_succ_le hac
          have hic : i < c := Nat.lt_trans hi' hac'
          have hmod₁ : x % c = i := by
            have hmod : (i + c * t₁) % c = i := by
              rw [Nat.add_mod, Nat.mul_mod]
              simp [Nat.mod_eq_of_lt hic]
            calc
              x % c = (i + c * t₁) % c := by rw [hfx₁]
              _ = i := hmod
          have hmod₂ : b % c = a' := by
            have hmod : (a' + c * t₂) % c = a' := by
              rw [Nat.add_mod, Nat.mul_mod]
              simp [Nat.mod_eq_of_lt hac']
            calc
              b % c = (a' + c * t₂) % c := by rw [hfx₂]
              _ = a' := hmod
          intro hxb
          have hmod₃ : x % c = b % c := by rw [hxb]
          have hia' : i = a' := by
            calc
              i = x % c := hmod₁.symm
              _ = b % c := hmod₃
              _ = a' := hmod₂
          omega

/-- Euclidean decomposition: the flat map `(i, t) ↦ i + a * t` is a
permutation of the residues below `a * b`. -/
theorem perm_range_flatMap_decomp (a b : Nat) :
    (List.range (a * b)).Perm
      ((List.range a).flatMap (fun i => (List.range b).map (fun t => i + a * t))) := by
  by_cases hb : b = 0
  · simp [hb, List.range_zero, List.flatMap]
  · have hbpos : 0 < b := Nat.pos_of_ne_zero hb
    apply perm_of_nodup_subset_length
    · exact List.nodup_range
    · exact nodup_flatMap_decomp (a := a) (c := a) (b := b) (hac := Nat.le_refl a)
    · rw [List.length_range]
      rw [List.length_flatMap]
      have hinner : ∀ i, i ∈ List.range a →
          ((List.range b).map (fun t => i + a * t)).length = b := by
        intro i hi
        rw [List.length_map, List.length_range]
      rw [sum_map_congr hinner]
      exact (sum_range_const a b).symm
    · intro x hx
      have hxlt : x < a * b := List.mem_range.mp hx
      have hapos : 0 < a := by
        by_cases ha0 : a = 0
        · simp [ha0, Nat.zero_mul] at hx
        · exact Nat.pos_of_ne_zero ha0
      have ht : x / a < b := by
        exact Nat.div_lt_of_lt_mul hxlt
      have hxeq : x = x % a + a * (x / a) := by
        exact (Nat.mod_add_div x a).symm
      rw [List.mem_flatMap]
      refine ⟨x % a, List.mem_range.mpr (Nat.mod_lt x hapos), ?_⟩
      rw [List.mem_map]
      refine ⟨x / a, List.mem_range.mpr ht, ?_⟩
      exact hxeq.symm

/-- Pulling the `gcd (a * b)` filter through the Euclidean decomposition. -/
theorem length_filter_flatMap_decomp (a b : Nat) :
    ((List.range (a * b)).filter (fun x => decide (x.gcd (a * b) = 1))).length =
      ((List.range a).flatMap (fun i =>
        ((List.range b).filter (fun t => decide ((i + a * t).gcd (a * b) = 1))).map
          (fun t => i + a * t))).length := by
  have hdecomp : (List.range (a * b)).Perm
      ((List.range a).flatMap (fun i => (List.range b).map (fun t => i + a * t))) :=
    perm_range_flatMap_decomp a b
  have hperm' := List.Perm.filter (fun x => decide (x.gcd (a * b) = 1)) hdecomp
  rw [hperm'.length_eq]
  rw [List.filter_flatMap]
  congr 1
  apply congrArg (f := fun h : Nat → List Nat => List.flatMap h (List.range a))
  funext i
  rw [List.filter_map]
  rfl

/-- The length of a coprime slice of the modulus `a * b`: for fixed `i < a`,
the slice has `phi b` elements exactly when `i` is coprime to `a`, and is
empty otherwise. -/
theorem slice_len_product {a b i : Nat} (hcop : Nat.Coprime a b) (hb : 0 < b) :
    ((List.range b).filter (fun t => decide ((i + a * t).gcd (a * b) = 1))).length
      = (decide (i.gcd a = 1)).toNat * phi b := by
  by_cases hc : i.gcd a = 1
  · have hdec : decide (i.gcd a = 1) = true := decide_eq_true hc
    have hf : (List.range b).filter (fun t => decide ((i + a * t).gcd (a * b) = 1))
        = (List.range b).filter (fun t => decide ((i + a * t).gcd b = 1)) := by
      apply List.filter_congr
      intro t ht
      have h1 : (i + a * t).gcd a = 1 := by
        rw [gcd_add_mul_left]
        exact hc
      have hiff : (i + a * t).gcd (a * b) = 1 ↔ (i + a * t).gcd b = 1 := by
        constructor
        · intro h
          exact (gcd_mul_right_eq_one_iff.mp h).2
        · intro h
          exact gcd_mul_right_eq_one_iff.mpr ⟨h1, h⟩
      exact decide_congr hiff
    rw [hf]
    rw [slice_phi_length (Nat.Coprime.symm hcop) hb]
    rw [hdec]
    simp
  · have hdec : decide (i.gcd a = 1) = false := decide_eq_false hc
    have hf : (List.range b).filter (fun t => decide ((i + a * t).gcd (a * b) = 1))
        = (List.range b).filter (fun _ => false) := by
      apply List.filter_congr
      intro t ht
      have hiff : ¬ (i + a * t).gcd (a * b) = 1 := by
        intro h
        have h1 : (i + a * t).gcd a = 1 := (gcd_mul_right_eq_one_iff.mp h).1
        rw [gcd_add_mul_left] at h1
        exact hc h1
      have hd : decide ((i + a * t).gcd (a * b) = 1) = false := decide_eq_false hiff
      rw [hd]
    rw [hf]
    rw [length_filter_false]
    rw [hdec]
    simp

/-- **The totient is multiplicative**: for coprime `a` and `b`,
`phi (a * b) = phi a * phi b`. -/
theorem phi_mul_coprime {a b : Nat} (hcop : Nat.Coprime a b) : phi (a * b) = phi a * phi b := by
  by_cases ha : a = 0
  · subst a
    simp [phi, residues_coprime]
  by_cases hb : b = 0
  · subst b
    simp [phi, residues_coprime]
  have hbpos : 0 < b := Nat.pos_of_ne_zero hb
  change ((List.range (a * b)).filter (fun x => decide (x.gcd (a * b) = 1))).length =
    phi a * phi b
  rw [length_filter_flatMap_decomp a b]
  rw [List.length_flatMap]
  have hslice : ∀ i, i < a →
      (((List.range b).filter (fun t => decide ((i + a * t).gcd (a * b) = 1))).map
          (fun t => i + a * t)).length = (decide (i.gcd a = 1)).toNat * phi b := by
    intro i hi
    rw [List.length_map]
    exact slice_len_product hcop hbpos
  have hsum : ((List.range a).map (fun i =>
        (((List.range b).filter (fun t => decide ((i + a * t).gcd (a * b) = 1))).map
            (fun t => i + a * t)).length)).sum
      = ((List.range a).map (fun i => (decide (i.gcd a = 1)).toNat * phi b)).sum := by
    apply sum_map_congr
    intro i hi
    exact hslice i (List.mem_range.mp hi)
  rw [hsum]
  rw [sum_map_mul_right (List.range a) (fun i => (decide (i.gcd a = 1)).toNat) (phi b)]
  rw [sum_toNat_filter (fun i => decide (i.gcd a = 1)) (List.range a)]
  have hpa : ((List.range a).filter (fun i => decide (i.gcd a = 1))).length = phi a := by
    unfold phi residues_coprime
    rfl
  rw [hpa]

/-- **Totient of a product of distinct primes.** For distinct primes `p` and
`q`, the counted totient of `p * q` is the closed form `(p - 1) * (q - 1)`. -/
theorem phi_prime_mul {p q : Nat} (hp : Prime p) (hq : Prime q) (hneq : p ≠ q) :
    phi (p * q) = (p - 1) * (q - 1) := by
  have hcop : Nat.Coprime p q := coprime_of_prime_ne hp hq hneq
  have hpp : phi p = p - 1 := by
    have h := phi_prime_power hp (by omega : 1 ≤ 1)
    simpa using h
  have hqq : phi q = q - 1 := by
    have h := phi_prime_power hq (by omega : 1 ≤ 1)
    simpa using h
  rw [phi_mul_coprime hcop, hpp, hqq]

/-- Smoke test: `phi (3 * 4) = phi 3 * phi 4` through `phi_mul_coprime`. -/
example : phi (3 * 4) = phi 3 * phi 4 := by
  exact phi_mul_coprime (a := 3) (b := 4) (by decide)

end Multiplicity.RSA
