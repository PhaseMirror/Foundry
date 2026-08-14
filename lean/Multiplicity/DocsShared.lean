import Std

/-! # Shared lemmas for the formal mirror of `multiplicity_substrate/docs/`

The LaTeX documents under `multiplicity_substrate/docs/` state claims over real
and complex analysis (operator norms, Lyapunov convergence, golden-ratio
suppression, prime-indexed entropy).  Those objects are not expressible in
std-only Lean, so each claim is mirrored here by a *finite, decidable model*
over `Nat`/`Int`/`List` whose lemmas are provable with `Std` alone, following
the established `PRMS` pattern (`Core.lean`, `Contractor.lean`, ...).

The numeric and combinatorial sweeps that are too large for `native_decide`
are certified by the Rust/Kani harnesses in
`multiplicity_substrate/rust/` (mirror of
`Prime/packages/rust/kani_harnesses` and `F1/Multiplicity/KaniCertificates.lean`).

Every result in this file is a theorem: there are no `axiom`s and no `sorry`s.
-/

namespace Multiplicity.PMDocs

/-! ## FTA-lite: injectivity of powers on the exponent

The docs rely on unique prime factorisation in two places: recovery of an
error-correction factor `gcd(φ, E)`, and injectivity of prime-indexed
transcript encodings.  The single-prime form below is provable in std;
multi-prime forms for bounded domains are certified by Kani / `native_decide`. -/

theorem pow_right_injective {a m n : Nat} (ha : 2 ≤ a) (h : a ^ m = a ^ n) : m = n := by
  have h1 : 1 < a := by omega
  by_cases hmn : m < n
  · have hlt := Nat.pow_lt_pow_right h1 hmn
    exfalso
    exact (Nat.ne_of_lt hlt) h
  · by_cases hnm : n < m
    · have hlt := Nat.pow_lt_pow_right h1 hnm
      exfalso
      exact (Nat.ne_of_lt hlt) h.symm
    · omega

/-! ## List summation facts used by the norm bounds -/

theorem sum_map_const_mul (l : List Nat) (k : Nat) :
    (l.map (fun x => k * x)).sum = k * l.sum := by
  induction l with
  | nil => simp
  | cons a as ih =>
      simp [List.sum_cons]
      calc
        k * a + (as.map (fun x => k * x)).sum = k * a + k * as.sum := by rw [ih]
        _ = k * (a + as.sum) := by rw [Nat.mul_add]

theorem sum_map_mul_right (l : List Nat) (k : Nat) :
    (l.map (fun x => x * k)).sum = l.sum * k := by
  induction l with
  | nil => simp
  | cons a as ih =>
      simp [List.sum_cons]
      calc
        a * k + (as.map (fun x => x * k)).sum = a * k + as.sum * k := by rw [ih]
        _ = (a + as.sum) * k := by rw [Nat.add_mul]

theorem sum_map_mul_left {l : List Nat} (k : Nat) (p : Nat → Nat) :
    (l.map (fun x => k * p x)).sum = k * (l.map p).sum := by
  induction l with
  | nil => simp
  | cons a as ih =>
      simp [List.sum_cons]
      calc
        k * p a + (as.map (fun x => k * p x)).sum = k * p a + k * (as.map p).sum := by rw [ih]
        _ = k * (p a + (as.map p).sum) := by rw [Nat.mul_add]

theorem sum_map_le {f g : Nat → Nat} {l : List Nat} (h : ∀ x ∈ l, f x ≤ g x) :
    (l.map f).sum ≤ (l.map g).sum := by
  induction l with
  | nil => simp
  | cons a as ih =>
      simp [List.sum_cons]
      exact Nat.add_le_add (h a (by simp)) (ih (by intro x hx; exact h x (by simp [hx])))

theorem le_sum_of_mem {l : List Nat} {x : Nat} (h : x ∈ l) : x ≤ l.sum := by
  induction l with
  | nil => simp at h
  | cons a as ih =>
      simp [List.sum_cons] at *
      rcases h with rfl | hx
      · omega
      · have h1 := ih hx
        omega

/-! The Frobenius-style bound `‖M‖_2² ≤ N²` used in the Track B norm bounds:
`Σᵢ cᵢ² ≤ (Σᵢ cᵢ)²` for a non-negative vector of class counts. -/

theorem l2_le_sum_sq (l : List Nat) : (l.map (fun c => c * c)).sum ≤ (l.sum) ^ 2 := by
  induction l with
  | nil => simp
  | cons a as ih =>
      simp [List.sum_cons, Nat.pow_two]
      have ih' : (as.map (fun c => c * c)).sum ≤ as.sum * as.sum := by
        simpa [Nat.pow_two] using ih
      have hsq : a * a + as.sum * as.sum ≤ (a + as.sum) * (a + as.sum) := by
        have hprod : (a + as.sum) * (a + as.sum) =
            a * a + (a * as.sum + (as.sum * a + as.sum * as.sum)) := by
          rw [Nat.mul_add, Nat.add_mul, Nat.add_mul]
          omega
        rw [hprod]
        omega
      exact Nat.le_trans (Nat.add_le_add_left ih' (a * a)) hsq

/-! Product lower bound: each prime factor is at least `2`, so the encoding
product grows at least as fast as `2` raised to the number of symbols.  This is
the finite form of the "logarithmic scaling of the prime encoding". -/

theorem prod_ge_two_pow (l : List Nat) (h : ∀ x ∈ l, 2 ≤ x) :
    2 ^ l.length ≤ l.prod := by
  induction l with
  | nil => simp
  | cons a as ih =>
      simp [List.length_cons, List.prod_cons]
      have ha : 2 ≤ a := h a (by simp)
      have hi : 2 ^ as.length ≤ as.prod := ih (by intro x hx; exact h x (by simp [hx]))
      calc
        2 ^ (as.length + 1) = 2 ^ as.length * 2 := by rw [Nat.pow_succ]
        _ ≤ as.prod * a := Nat.mul_le_mul hi ha
        _ = a * as.prod := by rw [Nat.mul_comm]

/-! ## Cartesian product of class vectors (rank-one tensor flattening)

The coupling tensor `T_t = u vᵀ` flattens to the Cartesian product of the two
feature vectors.  `cart_sum` is the identity
`Σᵢ Σⱼ g(uᵢ) h(vⱼ) = (Σᵢ g(uᵢ)) (Σⱼ h(vⱼ))` which underlies both the rank-one
Frobenius norm and the dot-product decomposition. -/

def cart : List Nat → List Nat → List (Nat × Nat)
  | [], _ => []
  | a :: as, v => (v.map (fun b => (a, b))) ++ cart as v

theorem cart_sum (g h : Nat → Nat) (u v : List Nat) :
    ((cart u v).map (fun p : Nat × Nat => g p.1 * h p.2)).sum =
      (u.map g).sum * (v.map h).sum := by
  induction u with
  | nil => simp [cart]
  | cons a as ih =>
      simp [cart, List.sum_append, List.map_append]
      calc
        (v.map (fun b => g a * h b)).sum + ((cart as v).map (fun p => g p.1 * h p.2)).sum
            = g a * (v.map h).sum + (as.map g).sum * (v.map h).sum := by
              rw [sum_map_mul_left (g a) h, ih]
        _ = (g a + (as.map g).sum) * (v.map h).sum := by rw [Nat.add_mul]

/-! ## Diagonal (multiplicity) operator in the ℓ₁ model

The Track B multiplicity operator acts diagonally; the ℓ₁ bound
`‖M x‖₁ ≤ ‖M‖∞ · ‖x‖₁` is submultiplicativity for the diagonal model. -/

def diagMul (m x : List Nat) : List Nat := List.zipWith (fun a b => a * b) m x

private theorem zipWith_mul_sum_le_core (N : Nat) :
    ∀ (m x : List Nat), (∀ c ∈ m, c ≤ N) →
      (List.zipWith (fun a b => a * b) m x).sum ≤ N * x.sum := by
  intro m
  induction m with
  | nil => intro x h; simp
  | cons a as ih =>
      intro x h
      cases x with
      | nil => simp
      | cons b bs =>
          simp
          have ha : a ≤ N := h a (by simp)
          have hb : a * b ≤ N * b := Nat.mul_le_mul_right b ha
          have hi : (List.zipWith (fun a b => a * b) as bs).sum ≤ N * bs.sum :=
            ih bs (by intro c hc; exact h c (by simp [hc]))
          have hstep : a * b + (List.zipWith (fun a b => a * b) as bs).sum
              ≤ N * b + N * bs.sum := Nat.add_le_add hb hi
          calc
            a * b + (List.zipWith (fun a b => a * b) as bs).sum ≤ N * b + N * bs.sum := hstep
            _ = N * (b + bs.sum) := by rw [Nat.mul_add]

theorem zipWith_mul_sum_le {m x : List Nat} (N : Nat) (h : ∀ c ∈ m, c ≤ N) :
    (List.zipWith (fun a b => a * b) m x).sum ≤ N * x.sum :=
  zipWith_mul_sum_le_core N m x h

theorem dot_le (v S : List Nat) :
    (List.zipWith (fun a b => a * b) v S).sum ≤ v.sum * S.sum := by
  induction v generalizing S with
  | nil => simp
  | cons a as ih =>
      cases S with
      | nil => simp
      | cons b bs =>
          simp
          have hprod : (a + as.sum) * (b + bs.sum) =
              a * b + (a * bs.sum + (as.sum * b + as.sum * bs.sum)) := by
            rw [Nat.mul_add, Nat.add_mul, Nat.add_mul]
            omega
          rw [hprod]
          have hi : (List.zipWith (fun a b => a * b) as bs).sum ≤ as.sum * bs.sum := ih bs
          omega

/-! Rank-one multiplication `(T S)ᵢ = uᵢ · ⟨v, S⟩` for `T = u vᵀ`. -/

def rank1Mul (u v S : List Nat) : List Nat :=
  u.map (fun ui => ui * (List.zipWith (fun a b => a * b) v S).sum)

theorem rank1Mul_l1_le (u v S : List Nat) :
    (rank1Mul u v S).sum ≤ (u.sum * v.sum) * S.sum := by
  have hdot : (List.zipWith (fun a b => a * b) v S).sum ≤ v.sum * S.sum := dot_le v S
  calc
    (rank1Mul u v S).sum = u.sum * (List.zipWith (fun a b => a * b) v S).sum := by
      simp [rank1Mul]
      rw [← sum_map_mul_right]
    _ ≤ u.sum * (v.sum * S.sum) := Nat.mul_le_mul_left u.sum hdot
    _ = (u.sum * v.sum) * S.sum := by rw [Nat.mul_assoc]

/-! ## Function iteration (contraction / feedback loops) -/

def iter {α : Type} (f : α → α) : Nat → α → α
  | 0, z => z
  | n + 1, z => f (iter f n z)

theorem iter_zero {α : Type} (f : α → α) (z : α) : iter f 0 z = z := rfl

theorem iter_succ {α : Type} (f : α → α) (n : Nat) (z : α) :
    iter f (n + 1) z = f (iter f n z) := rfl

theorem iter_fixed {α : Type} (f : α → α) {z : α} (hf : f z = z) :
    ∀ n, iter f n z = z := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih => simp [iter, ih, hf]

/-! ## Distance in the Int model (contraction / Lyapunov stability) -/

def dist (x y : Int) : Nat := (x - y).natAbs

theorem dist_self (x : Int) : dist x x = 0 := by simp [dist]

theorem dist_eq_zero {x y : Int} (h : dist x y = 0) : x = y := by
  unfold dist at h
  have hne : x - y = 0 := Int.natAbs_eq_zero.mp h
  exact Int.eq_of_sub_eq_zero hne

/-! Geometric iterate bound: `‖f^t z - f^t z'‖ ≤ q^t ‖z - z'‖` whenever `f`
is Lipschitz with constant `q`.  This is the finite core of both the
Lyapunov geometric convergence theorem and the Track B Banach contraction
theorem. -/

theorem iterate_contraction {State : Type} {dist : State → State → Nat}
    {f : State → State} {q : Nat}
    (hf : ∀ z z', dist (f z) (f z') ≤ q * dist z z') :
    ∀ t (z0 z0' : State), dist (iter f t z0) (iter f t z0') ≤ q ^ t * dist z0 z0' := by
  intro t
  induction t with
  | zero =>
      intro z0 z0'
      simp [iter]
  | succ t ih =>
      intro z0 z0'
      have h1 := hf (iter f t z0) (iter f t z0')
      have h2 := ih z0 z0'
      calc
        dist (f (iter f t z0)) (f (iter f t z0')) ≤ q * dist (iter f t z0) (iter f t z0') := h1
        _ ≤ q * (q ^ t * dist z0 z0') := Nat.mul_le_mul_left q h2
        _ = q ^ (t + 1) * dist z0 z0' := by
          calc
            q * (q ^ t * dist z0 z0') = (q * q ^ t) * dist z0 z0' := by rw [Nat.mul_assoc]
            _ = (q ^ t * q) * dist z0 z0' := by rw [Nat.mul_comm q (q ^ t)]
            _ = q ^ (t + 1) * dist z0 z0' := by rw [Nat.pow_succ]

theorem iterate_tendsto {State : Type} {dist : State → State → Nat}
    {f : State → State} {q : Nat} {zstar : State} (hfz : f zstar = zstar)
    (hf : ∀ z z', dist (f z) (f z') ≤ q * dist z z') :
    ∀ t z0, dist (iter f t z0) zstar ≤ q ^ t * dist z0 zstar := by
  intro t z0
  have hfix : iter f t zstar = zstar := iter_fixed f hfz t
  calc
    dist (iter f t z0) zstar = dist (iter f t z0) (iter f t zstar) := by rw [hfix]
    _ ≤ q ^ t * dist z0 zstar := iterate_contraction hf t z0 zstar

/-! Uniqueness of the fixed point under contraction (`q = 0` in the Nat model,
i.e. `L < 1` collapses to the constant map on the finite model). -/

theorem fixed_point_unique {State : Type} {dist : State → State → Nat}
    (hdist0 : ∀ z z', dist z z' = 0 → z = z')
    {f : State → State} {z1 z2 : State} (hz1 : f z1 = z1) (hz2 : f z2 = z2)
    (hf : ∀ z z', dist (f z) (f z') ≤ 0 * dist z z') : z1 = z2 := by
  have h0 : dist (f z1) (f z2) ≤ 0 := by
    calc
      dist (f z1) (f z2) ≤ 0 * dist z1 z2 := hf z1 z2
      _ = 0 := by simp
  have hle : dist z1 z2 ≤ 0 := by rwa [hz1, hz2] at h0
  have hz : dist z1 z2 = 0 := Nat.le_antisymm hle (Nat.zero_le _)
  exact hdist0 z1 z2 hz

/-! ## Bounded projection onto `[0,1]` (the spectral clip in `Π_ℬ`) -/

def clip01 (x : Int) : Int := if x ≤ 0 then 0 else if x ≤ 1 then x else 1

theorem clip01_ge_zero (x : Int) : 0 ≤ clip01 x := by
  unfold clip01
  by_cases h1 : x ≤ 0
  · simp [h1]
  · by_cases h2 : x ≤ 1
    · simp [h1, h2]
      omega
    · simp [h1, h2]

theorem clip01_le_one (x : Int) : clip01 x ≤ 1 := by
  unfold clip01
  by_cases h1 : x ≤ 0
  · simp [h1]
  · by_cases h2 : x ≤ 1
    · simp [h1, h2]
    · simp [h1, h2]

theorem clip01_fixed {x : Int} (h : 0 ≤ x ∧ x ≤ 1) : clip01 x = x := by
  unfold clip01
  by_cases h1 : x ≤ 0
  · have hx : x = 0 := by omega
    subst x
    simp
  · by_cases h2 : x ≤ 1
    · simp [h1, h2]
    · omega

end Multiplicity.PMDocs
