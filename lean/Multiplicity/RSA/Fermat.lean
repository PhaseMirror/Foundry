import Multiplicity.RSA.ModEq
import Multiplicity.RSA.Prime
import Multiplicity.RSA.CRT

/-!
# Fermat's little theorem

We prove, from first principles and without any axioms:

  `fermat_little : Prime p → ¬ p ∣ a → a ^ (p - 1) ≡ 1 [MOD p]`

The classical proof is formalized here in its product form.  Let `p` be prime
and `p ∤ a`.  Write `up p` for the list `[1, 2, …, p - 1]`.  The map

  `x ↦ (a * x) % p`

sends `up p` into itself (every `(a * x) % p` is a nonzero residue) and is
injective on it (because `p | a * (x - y)` forces `p | x - y`, and
`0 ≤ x - y < p`), so it permutes `up p`.  Hence the product of the list is
unchanged:

  `product (up p) ≡ product (map (fun x => a * x) (up p)) [MOD p]`

The right hand side equals `a ^ (p - 1) * product (up p)` modulo `p`.  Since
`p` is prime and does not divide any factor of `product (up p)`, it does not
divide the product, so Euclid's lemma (also developed here) cancels it:

  `a ^ (p - 1) ≡ 1 [MOD p]`.

The list facts we need — product, `Nodup.map`, and the "nodup + subset +
equal length implies permutation" completeness lemma — are developed below
from `List.Perm`, which ships with core Lean.
-/

namespace Multiplicity.RSA

/-! ## Products of `Nat` lists -/

/-- The product of a list of natural numbers. -/
def product (l : List Nat) : Nat := l.foldr (fun x acc => x * acc) 1

@[simp] theorem product_nil : product [] = 1 := rfl

@[simp] theorem product_cons (x : Nat) (l : List Nat) : product (x :: l) = x * product l := rfl

theorem product_append (l₁ l₂ : List Nat) : product (l₁ ++ l₂) = product l₁ * product l₂ := by
  induction l₁ with
  | nil => simp
  | cons x l₁ ih =>
      simp [ih, Nat.mul_assoc]

/-- Multiplication distributes over a product as a power of the multiplier. -/
theorem product_map_mul_left (a : Nat) (l : List Nat) :
    product (List.map (fun x => a * x) l) = a ^ l.length * product l := by
  induction l with
  | nil => simp
  | cons x l ih =>
      calc
        product (List.map (fun y => a * y) (x :: l))
            = (a * x) * product (List.map (fun y => a * y) l) := rfl
        _ = (a * x) * (a ^ l.length * product l) := by rw [ih]
        _ = (a ^ l.length * a) * (x * product l) := by
          simp [Nat.mul_assoc, Nat.mul_comm, Nat.mul_left_comm]
        _ = a ^ (l.length + 1) * (x * product l) := by
          rw [show l.length + 1 = l.length.succ by rfl, Nat.pow_succ]

/-- A product is invariant under permutation of its factors. -/
theorem product_perm {l₁ l₂ : List Nat} (h : l₁.Perm l₂) : product l₁ = product l₂ := by
  induction h using List.Perm.rec with
  | nil => rfl
  | cons x _ ih => simp [ih]
  | swap x y l =>
      simp [Nat.mul_left_comm]
  | trans _ _ ih₁ ih₂ => exact ih₁.trans ih₂

/-- Products of pointwise congruent factors are congruent. -/
theorem product_map_modEq {n : Nat} {f g : Nat → Nat} (l : List Nat)
    (h : ∀ x ∈ l, f x ≡ g x [MOD n]) :
    product (List.map f l) ≡ product (List.map g l) [MOD n] := by
  induction l with
  | nil => simp [ModEq]
  | cons x l ih =>
      have hih : product (List.map f l) ≡ product (List.map g l) [MOD n] :=
        ih (fun y hy => h y (by simp [hy]))
      exact modEq_mul (h x (by simp)) hih

/-! ## Nodup of a list and its image under an injective map -/

/-- An injective function preserves `Nodup`. -/
theorem nodup_map {α β : Type} (f : α → β) {l : List α} (hl : l.Nodup)
    (hf : ∀ x ∈ l, ∀ y ∈ l, f x = f y → x = y) : (List.map f l).Nodup := by
  induction l with
  | nil => simp
  | cons a t ih =>
      change (f a :: List.map f t).Nodup
      rw [List.nodup_cons]
      have hrest := List.nodup_cons.mp hl
      constructor
      · intro hmem
        rcases (List.mem_map.mp hmem) with ⟨x, hxt, hfx⟩
        have hxa : a = x := hf a (by simp) x (by simp [hxt]) hfx.symm
        have : a ∈ t := by simpa [hxa] using hxt
        exact hrest.1 this
      · exact ih hrest.2 (fun x hxt y hyt => hf x (by simp [hxt]) y (by simp [hyt]))

theorem length_eq_zero {α : Type} {l : List α} (h : l.length = 0) : l = [] := by
  cases l with
  | nil => rfl
  | cons a l => simp at h

/-- `(a :: l)` permutes with `l ++ [a]`. -/
theorem cons_append_perm {α : Type} (a : α) (l : List α) : (a :: l).Perm (l ++ [a]) := by
  induction l with
  | nil => simp
  | cons b l ih =>
      have h1 : (a :: b :: l).Perm (b :: a :: l) := (List.Perm.swap a b l).symm
      have h2 : (b :: a :: l).Perm (b :: (l ++ [a])) :=
        List.Perm.append_cons b (List.Perm.refl []) ih
      exact h1.trans h2

/-- Removing the element `a` from a list and appending it back permutes. -/
theorem perm_erase_append {α : Type} [BEq α] [LawfulBEq α] (l : List α) (a : α)
    (ha : a ∈ l) : (l.erase a ++ [a]).Perm l := by
  induction l with
  | nil => simp at ha
  | cons b l ih =>
      by_cases hab : a == b
      · have hab' : a = b := LawfulBEq.eq_of_beq hab
        subst a
        rw [List.erase_cons_head b l]
        exact (cons_append_perm b l).symm
      · have hba : ¬ (b == a) = true := by
          intro hba'
          have hba2 : b = a := LawfulBEq.eq_of_beq hba'
          have : (a == b) = true := by simp [hba2]
          exact hab this
        rw [List.erase_cons_tail hba]
        have hmem : a ∈ l := by
          rcases (List.mem_cons.mp ha) with h1 | h2
          · have : (a == b) = true := by simp [h1]
            exact (hab this).elim
          · exact h2
        have hih := ih hmem
        have hlift : (b :: (l.erase a ++ [a])).Perm (b :: l) :=
          List.Perm.append_cons b (List.Perm.refl []) hih
        simpa using hlift

/-- Erasing a member shortens the list by one. -/
theorem length_erase {α : Type} [BEq α] [LawfulBEq α] (l : List α) (a : α) (ha : a ∈ l) :
    (l.erase a).length = l.length - 1 := by
  induction l with
  | nil => simp at ha
  | cons b l ih =>
      by_cases hab : a == b
      · have hab' : a = b := LawfulBEq.eq_of_beq hab
        subst a
        rw [List.erase_cons_head b l]
        simp
      · have hba : ¬ (b == a) = true := by
          intro hba'
          have hba2 : b = a := LawfulBEq.eq_of_beq hba'
          have : (a == b) = true := by simp [hba2]
          exact hab this
        rw [List.erase_cons_tail hba]
        have hmem : a ∈ l := by
          rcases (List.mem_cons.mp ha) with h1 | h2
          · have : (a == b) = true := by simp [h1]
            exact (hab this).elim
          · exact h2
        have hlen := ih hmem
        have hpos : 1 ≤ l.length := by
          cases l with
          | nil => simp at hmem
          | cons c l => simp
        rw [List.length_cons, List.length_cons]
        rw [hlen]
        omega

/-- A list that has no duplicates, has the same length as, and is contained in
a duplicate-free list, is a permutation of it. -/
theorem perm_of_nodup_subset_length {α : Type} [BEq α] [LawfulBEq α] {l₁ l₂ : List α}
    (h₁ : l₁.Nodup) (h₂ : l₂.Nodup) (hl : l₁.length = l₂.length)
    (hsub : ∀ x, x ∈ l₁ → x ∈ l₂) : l₁.Perm l₂ := by
  revert h₁ h₂ hl hsub
  revert l₂
  induction l₁ with
  | nil =>
      intro l₂ h₁ h₂ hl hsub
      have : l₂ = [] := by
        have : l₂.length = 0 := by simpa using hl.symm
        exact length_eq_zero this
      simp [this]
  | cons a t ih =>
      intro l₂ h₁ h₂ hl hsub
      have ha : a ∈ l₂ := hsub a (by simp)
      have ht : t.Nodup := (List.nodup_cons.mp h₁).2
      have h₂e : (l₂.erase a).Nodup := List.Nodup.erase a h₂
      have hte : t.length = (l₂.erase a).length := by
        have hll : t.length + 1 = l₂.length := by
          rw [List.length_cons] at hl
          exact hl
        rw [length_erase l₂ a ha]
        omega
      have hsube : ∀ x, x ∈ t → x ∈ l₂.erase a := by
        intro x hx
        have hxa : x ≠ a := by
          intro hxa'
          have : a ∈ t := by simpa [hxa'] using hx
          exact (List.nodup_cons.mp h₁).1 this
        rw [List.mem_erase_of_ne hxa]
        exact hsub x (by simp [hx])
      have hih : t.Perm (l₂.erase a) := ih ht h₂e hte hsube
      have hp1 : (l₂.erase a ++ [a]).Perm l₂ := perm_erase_append l₂ a ha
      have hp0 : (a :: t).Perm (t ++ [a]) := cons_append_perm a t
      have hp2 : (t ++ [a]).Perm ((l₂.erase a) ++ [a]) := List.Perm.append_right [a] hih
      exact hp0.trans (hp2.trans hp1)

/-! ## Fermat's little theorem -/

/-- The list `[1, 2, …, p - 1]`. -/
def up (p : Nat) : List Nat := (List.range (p - 1)).map (fun x => x + 1)

/-- Membership in `up p` means `1 ≤ x < p`. -/
theorem mem_up {p x : Nat} : x ∈ up p ↔ 1 ≤ x ∧ x < p := by
  unfold up
  simp [List.mem_map, List.mem_range]
  constructor
  · intro h
    rcases h with ⟨y, hy, hyx⟩
    constructor <;> omega
  · intro h
    rcases h with ⟨hx1, hxp⟩
    refine ⟨x - 1, ?_, ?_⟩ <;> omega

theorem up_nodup (p : Nat) : (up p).Nodup := by
  unfold up
  exact nodup_map (fun x => x + 1) List.nodup_range (by intro x _ y _ h; omega)

theorem up_length (p : Nat) : (up p).length = p - 1 := by
  unfold up
  rw [List.length_map, List.length_range]

/-- The map `x ↦ (a * x) % p` sends `up p` into itself when `p ∤ a`. -/
theorem up_mul_mem {p a : Nat} (hp : Prime p) (hpa : ¬ p ∣ a) :
    ∀ x ∈ up p, (a * x) % p ∈ up p := by
  intro x hx
  have hx1 : 1 ≤ x := (mem_up.mp hx).1
  have hxp : x < p := (mem_up.mp hx).2
  have hlt : (a * x) % p < p := Nat.mod_lt (a * x) (prime_pos hp)
  have hne0 : (a * x) % p ≠ 0 := by
    intro h0
    have hdvd : p ∣ a * x := by
      rw [Nat.dvd_iff_mod_eq_zero]
      exact h0
    rcases prime_dvd_or_dvd hp hdvd with hpa' | hpx
    · exact hpa hpa'
    · exact prime_not_dvd_lt hp hxp hx1 hpx
  rw [mem_up]
  constructor
  · omega
  · exact hlt

/-- The map `x ↦ (a * x) % p` is injective on `up p` when `p ∤ a`. -/
theorem up_mul_injective {p a : Nat} (hp : Prime p) (hpa : ¬ p ∣ a) :
    ∀ x ∈ up p, ∀ y ∈ up p, (a * x) % p = (a * y) % p → x = y := by
  intro x hx y hy hxy
  have hx1 : 1 ≤ x := (mem_up.mp hx).1
  have hxp : x < p := (mem_up.mp hx).2
  have hyp : y < p := (mem_up.mp hy).2
  have hcong : a * x ≡ a * y [MOD p] := hxy
  cases Nat.le_total y x with
  | inl hyx =>
      have hge : a * y ≤ a * x := Nat.mul_le_mul_left a hyx
      have hdvd : p ∣ a * x - a * y := dvd_sub_of_modEq hcong hge
      have hstep : a * x - a * y = a * (x - y) := by
        calc
          a * x - a * y = x * a - y * a := by rw [Nat.mul_comm a, Nat.mul_comm a]
          _ = (x - y) * a := by rw [Nat.mul_sub_right_distrib]
          _ = a * (x - y) := by rw [Nat.mul_comm]
      have hdvd' : p ∣ a * (x - y) := by simpa [hstep] using hdvd
      have hdiv : p ∣ x - y := prime_dvd_of_dvd_mul hp hdvd' hpa
      have hlt : x - y < p := by omega
      have h0 : x - y = 0 := eq_zero_of_dvd_lt hdiv hlt
      omega
  | inr hxy =>
      have hge : a * x ≤ a * y := Nat.mul_le_mul_left a hxy
      have hdvd : p ∣ a * y - a * x := dvd_sub_of_modEq hcong.symm hge
      have hstep : a * y - a * x = a * (y - x) := by
        calc
          a * y - a * x = y * a - x * a := by rw [Nat.mul_comm a, Nat.mul_comm a]
          _ = (y - x) * a := by rw [Nat.mul_sub_right_distrib]
          _ = a * (y - x) := by rw [Nat.mul_comm]
      have hdvd' : p ∣ a * (y - x) := by simpa [hstep] using hdvd
      have hdiv : p ∣ y - x := prime_dvd_of_dvd_mul hp hdvd' hpa
      have hlt : y - x < p := by omega
      have h0 : y - x = 0 := eq_zero_of_dvd_lt hdiv hlt
      omega

/-- Multiplication by a permutes the nonzero residues modulo `p`. -/
theorem up_perm_mul {p a : Nat} (hp : Prime p) (hpa : ¬ p ∣ a) :
    (List.map (fun x => (a * x) % p) (up p)).Perm (up p) := by
  apply perm_of_nodup_subset_length
  · exact nodup_map (fun x => (a * x) % p) (up_nodup p) (up_mul_injective hp hpa)
  · exact up_nodup p
  · rw [List.length_map, up_length]
  · intro x hx
    rcases (List.mem_map.mp hx) with ⟨y, hy, hfx⟩
    have hmem : (a * y) % p ∈ up p := up_mul_mem hp hpa y hy
    simpa [hfx] using hmem

/-! ## Coprime analogue and modular inverses -/

/-- The map `x ↦ (a * x) % n` sends `up n` into itself when `n` is coprime to
`a`. -/
theorem up_mul_mem_coprime {n a : Nat} (hc : Nat.Coprime n a) (hn : 0 < n) :
    ∀ x ∈ up n, (a * x) % n ∈ up n := by
  intro x hx
  have hx1 : 1 ≤ x := (mem_up.mp hx).1
  have hxn : x < n := (mem_up.mp hx).2
  have hlt : (a * x) % n < n := Nat.mod_lt (a * x) hn
  have hne0 : (a * x) % n ≠ 0 := by
    intro h0
    have hdvd : n ∣ a * x := by
      rw [Nat.dvd_iff_mod_eq_zero]
      exact h0
    have hdiv : n ∣ x := coprime_dvd_of_dvd_mul hc hdvd
    have hx0 : x = 0 := eq_zero_of_dvd_lt hdiv hxn
    omega
  rw [mem_up]
  constructor
  · omega
  · exact hlt

/-- The map `x ↦ (a * x) % n` is injective on `up n` when `n` is coprime to
`a`. -/
theorem up_mul_injective_coprime {n a : Nat} (hc : Nat.Coprime n a) :
    ∀ x ∈ up n, ∀ y ∈ up n, (a * x) % n = (a * y) % n → x = y := by
  intro x hx y hy hxy
  have hx1 : 1 ≤ x := (mem_up.mp hx).1
  have hxn : x < n := (mem_up.mp hx).2
  have hyn : y < n := (mem_up.mp hy).2
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

/-- Multiplication by `a` permutes the nonzero residues modulo `n` when `n`
is coprime to `a`. -/
theorem up_perm_mul_coprime {n a : Nat} (hc : Nat.Coprime n a) (hn : 0 < n) :
    (List.map (fun x => (a * x) % n) (up n)).Perm (up n) := by
  apply perm_of_nodup_subset_length
  · exact nodup_map (fun x => (a * x) % n) (up_nodup n) (up_mul_injective_coprime hc)
  · exact up_nodup n
  · rw [List.length_map, up_length]
  · intro x hx
    rcases (List.mem_map.mp hx) with ⟨y, hy, hfx⟩
    have hmem : (a * y) % n ∈ up n := up_mul_mem_coprime hc hn y hy
    simpa [hfx] using hmem

/-- **Modular inverse existence.** If `n` is coprime to `a` then `a` has a
multiplicative inverse modulo `n`: some `b` with `a * b ≡ 1 [MOD n]`. This is
the existence half of Bezout's identity, obtained by counting: multiplication
by `a` permutes the nonzero residues, so it is surjective and some residue
maps to `1`. -/
theorem cop_mod_inv_exists {a n : Nat} (hc : Nat.Coprime n a) (hn1 : 1 < n) :
    ∃ b, a * b ≡ 1 [MOD n] := by
  have hn0 : 0 < n := by omega
  have hperm := up_perm_mul_coprime hc hn0
  have h1mem : 1 ∈ up n := by
    rw [mem_up]
    constructor <;> omega
  have h1map : 1 ∈ List.map (fun x => (a * x) % n) (up n) :=
    (List.Perm.mem_iff hperm).mpr h1mem
  rcases List.mem_map.mp h1map with ⟨b, hb, hfb⟩
  refine ⟨b, ?_⟩
  unfold ModEq
  rw [hfb]
  symm
  exact Nat.mod_eq_of_lt hn1

/-- A prime cannot divide the product of a list of numbers it divides none of. -/
theorem prime_not_dvd_product {p : Nat} (hp : Prime p) (l : List Nat)
    (h : ∀ x ∈ l, p ∤ x) : p ∤ product l := by
  induction l with
  | nil =>
      intro hd
      have hle : p ≤ 1 := Nat.le_of_dvd (by decide : 0 < 1) (by simpa using hd)
      have hp' : 1 < p := hp.1
      omega
  | cons x l ih =>
      intro hd
      have hdiv := prime_dvd_or_dvd hp (by simpa using hd)
      rcases hdiv with hx | hl
      · exact (h x (by simp)) hx
      · exact (ih (fun y hy => h y (by simp [hy]))) hl

/-- **Fermat's little theorem.** If `p` is prime and `p ∤ a` then
`a ^ (p - 1) ≡ 1 [MOD p]`. -/
theorem fermat_little {p a : Nat} (hp : Prime p) (hpa : ¬ p ∣ a) : a ^ (p - 1) ≡ 1 [MOD p] := by
  have hperm := up_perm_mul hp hpa
  have hprod : product (up p) = product (List.map (fun x => (a * x) % p) (up p)) :=
    (product_perm hperm).symm
  have hprod' : product (List.map (fun x => (a * x) % p) (up p)) ≡
      product (List.map (fun x => a * x) (up p)) [MOD p] := by
    exact product_map_modEq (up p) (fun x _ => (modEq_mod_self (a * x) p).symm)
  have hprod'' : product (List.map (fun x => a * x) (up p)) = a ^ (p - 1) * product (up p) := by
    rw [product_map_mul_left, up_length]
  have hF : product (up p) ≡ a ^ (p - 1) * product (up p) [MOD p] := by
    exact modEq_trans (modEq_of_eq hprod) (modEq_trans hprod' (modEq_of_eq hprod''))
  have ha0 : 0 < a := by
    by_cases ha' : 0 < a
    · exact ha'
    · have : a = 0 := by omega
      subst a
      exact False.elim (hpa ⟨0, rfl⟩)
  have ha1 : 1 ≤ a ^ (p - 1) := by
    have : 0 < a ^ (p - 1) := Nat.pow_pos ha0
    omega
  have hge : product (up p) ≤ a ^ (p - 1) * product (up p) :=
    Nat.le_mul_of_pos_left (product (up p)) (Nat.pow_pos ha0)
  have hdvdF : p ∣ a ^ (p - 1) * product (up p) - product (up p) :=
    dvd_sub_of_modEq hF.symm hge
  have hstep : a ^ (p - 1) * product (up p) - product (up p) =
      (a ^ (p - 1) - 1) * product (up p) := by
    calc
      a ^ (p - 1) * product (up p) - product (up p)
          = a ^ (p - 1) * product (up p) - 1 * product (up p) := by simp
      _ = (a ^ (p - 1) - 1) * product (up p) := by
        rw [Nat.mul_sub_right_distrib]
  have hdvd' : p ∣ (a ^ (p - 1) - 1) * product (up p) := by simpa [hstep] using hdvdF
  have hnotF : ¬ p ∣ product (up p) := by
    exact prime_not_dvd_product hp (up p) (by
      intro x hx
      exact prime_not_dvd_lt hp (mem_up.mp hx).2 (mem_up.mp hx).1)
  have hdvd : p ∣ a ^ (p - 1) - 1 :=
    prime_dvd_of_dvd_mul hp (by simpa [Nat.mul_comm] using hdvd') hnotF
  exact modEq_of_dvd_sub ha1 hdvd

end Multiplicity.RSA
