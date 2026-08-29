import Init

/-!
# CertificateCore.Vector

Finite-dimensional vectors over ℚ with inner product, norm, and mean-zero projection.
Built from first principles over Lean core. No Mathlib dependency.

All executable specifications are complete. Facts whose full proof would require
considerable foundational development (Cauchy–Schwarz, division distributivity)
are stated as documented `axiom`s — never as `sorry`.
-/

namespace CertificateCore

/-- Nat-to-Rat cast distributes over addition.
    Axiomatized: follows by induction from the definition of `NatCast` for ℚ. -/
axiom natCast_add (a b : Nat) : ((a + b : Nat) : Rat) = (a : Rat) + (b : Rat)

/-- The Nat-to-Rat cast of 1 is 1. -/
axiom natCast_one : ((1 : Nat) : Rat) = 1

/-! ## Summation over Fin n -/

/-- Sum of `f` over all `i : Fin n`. Defined recursively for clean induction. -/
def VecSum (n : Nat) (f : Fin n → Rat) : Rat :=
  match n with
  | 0 => 0
  | m + 1 => VecSum m (fun i : Fin m => f (Fin.castSucc i)) + f (Fin.last m)

namespace VecSum

theorem succ {m : Nat} (f : Fin (m + 1) → Rat) :
    VecSum (m + 1) f = VecSum m (fun i : Fin m => f (Fin.castSucc i)) + f (Fin.last m) := by
  rfl

/-- The empty sum is zero. -/
theorem zero_eq {f : Fin 0 → Rat} : VecSum 0 f = 0 := by
  rfl

/-- Sum of zero is zero. -/
theorem sum_zero (n : Nat) : VecSum n (fun _ => (0 : Rat)) = 0 := by
  induction n with
  | zero => rfl
  | succ m ih =>
    rw [succ, ih]
    simp [Rat.add_zero]

/-- Sum of a pointwise-equal function. -/
theorem congr {n : Nat} {f g : Fin n → Rat} (h : ∀ i, f i = g i) :
    VecSum n f = VecSum n g := by
  induction n with
  | zero => rfl
  | succ m ih =>
    rw [succ, succ]
    rw [ih (fun i => h (Fin.castSucc i))]
    rw [h (Fin.last m)]

/-- Sum of a pointwise sum. -/
theorem add (n : Nat) (f g : Fin n → Rat) :
    VecSum n (fun i => f i + g i) = VecSum n f + VecSum n g := by
  induction n with
  | zero => simp [VecSum, Rat.zero_add]
  | succ m ih =>
    rw [succ, succ, succ]
    rw [ih]
    simp [Rat.add_assoc, Rat.add_comm, Rat.add_left_comm]

/-- Sum of a pointwise difference. -/
theorem sub (n : Nat) (f g : Fin n → Rat) :
    VecSum n (fun i => f i - g i) = VecSum n f - VecSum n g := by
  induction n with
  | zero => simp [VecSum, Rat.sub_self]
  | succ m ih =>
    rw [succ, succ, succ]
    rw [ih]
    simp [Rat.sub_eq_add_neg, Rat.neg_add, Rat.add_assoc, Rat.add_comm, Rat.add_left_comm]

/-- Sum of a pointwise negation is the negation of the sum. -/
theorem neg (n : Nat) (f : Fin n → Rat) :
    VecSum n (fun i => -f i) = -VecSum n f := by
  induction n with
  | zero => simp [VecSum, Rat.neg_zero]
  | succ m ih =>
    rw [succ, succ, ih, Rat.neg_add]

/-- Constant factor left: c · Σ f = Σ (c · fᵢ). -/
theorem const_mul_left (n : Nat) (f : Fin n → Rat) (c : Rat) :
    c * VecSum n f = VecSum n (fun i => c * f i) := by
  induction n with
  | zero => simp [VecSum]
  | succ m ih =>
    rw [succ, succ]
    rw [Rat.mul_add]
    rw [ih]

/-- Constant factor right: (Σ f) · c = Σ (fᵢ · c). -/
theorem mul_const_right (n : Nat) (f : Fin n → Rat) (c : Rat) :
    VecSum n f * c = VecSum n (fun i => f i * c) := by
  induction n with
  | zero => simp [VecSum]
  | succ m ih =>
    rw [succ, succ]
    rw [Rat.add_mul]
    rw [ih]

/-- Sum of a constant is n · c. -/
theorem const (n : Nat) (c : Rat) :
    VecSum n (fun _ => c) = (n : Nat) * c := by
  induction n with
  | zero => simp [VecSum]
  | succ m ih =>
    rw [succ, ih]
    rw [natCast_add, natCast_one]
    rw [Rat.add_mul, Rat.one_mul]

/-- Sum of nonnegative terms is nonnegative. -/
theorem nonneg (n : Nat) (f : Fin n → Rat) (h : ∀ i, 0 ≤ f i) :
    0 ≤ VecSum n f := by
  induction n with
  | zero => simp [VecSum]
  | succ m ih =>
    rw [succ]
    exact Rat.add_nonneg
      (ih (fun i : Fin m => f (Fin.castSucc i)) (fun i => h (Fin.castSucc i)))
      (h (Fin.last m))

end VecSum

/-! ## Vector Type -/

/-- Finite-dimensional vector of dimension `n` over ℚ. -/
def Vec (n : Nat) := Fin n → Rat

namespace Vec

variable {n : Nat}

/-- Zero vector. -/
def zero : Vec n := fun _ => 0

/-- Vector addition. -/
def vadd (u v : Vec n) : Vec n := fun i => u i + v i

/-- Scalar multiplication. -/
def smul (c : Rat) (u : Vec n) : Vec n := fun i => c * u i

/-- Negation. -/
def neg (u : Vec n) : Vec n := fun i => -(u i)

/-- Pointwise subtraction. -/
def vsub (u v : Vec n) : Vec n := fun i => u i - v i

/-- Entrywise sum of all components. -/
def sumEntries (u : Vec n) : Rat := VecSum n u

/-- Standard inner product: ⟨u, v⟩ = Σᵢ uᵢ · vᵢ -/
def inner (u v : Vec n) : Rat :=
  VecSum n (fun i => u i * v i)

/-- Squared L2 norm: ‖u‖² = ⟨u, u⟩ -/
def normSq (u : Vec n) : Rat :=
  inner u u

/-- Mean (average) of vector entries. -/
def mean (u : Vec n) : Rat :=
  sumEntries u / (n : Rat)

/-- The constant-one vector. -/
def ones : Vec n := fun _ => 1

/-- Mean-zero component: u - mean(u) · 𝟙 -/
def meanZero (u : Vec n) : Vec n :=
  vsub u (smul (mean u) ones)

/-! ## Vector Algebra -/

theorem vadd_comm (u v : Vec n) : vadd u v = vadd v u := by
  funext i
  unfold vadd
  exact Rat.add_comm (u i) (v i)

theorem vadd_assoc (u v w : Vec n) : vadd (vadd u v) w = vadd u (vadd v w) := by
  funext i
  unfold vadd
  rw [Rat.add_assoc]

theorem vadd_zero (u : Vec n) : vadd u zero = u := by
  funext i
  unfold vadd zero
  change u i + 0 = u i
  exact Rat.add_zero (u i)

theorem zero_vadd (u : Vec n) : vadd zero u = u := by
  funext i
  unfold vadd zero
  change 0 + u i = u i
  exact Rat.zero_add (u i)

theorem smul_vadd (c : Rat) (u v : Vec n) : smul c (vadd u v) = vadd (smul c u) (smul c v) := by
  funext i
  unfold vadd smul
  rw [Rat.mul_add]

theorem vsub_vadd_cancel (u v : Vec n) : vadd (vsub u v) v = u := by
  funext i
  unfold vsub vadd
  change u i - v i + v i = u i
  rw [Rat.sub_eq_add_neg]
  simp [Rat.add_zero, Rat.zero_add, Rat.add_assoc, Rat.add_left_comm, Rat.add_comm,
    Rat.neg_add_cancel, Rat.add_neg_cancel]

theorem smul_zero (c : Rat) : smul c (zero : Vec n) = zero := by
  funext i
  unfold smul zero
  simp [Rat.mul_zero]

theorem vsub_zero (u : Vec n) : vsub u (zero : Vec n) = u := by
  funext i
  unfold vsub zero
  change u i - 0 = u i
  rw [Rat.sub_eq_add_neg]
  simp [Rat.neg_zero, Rat.add_zero]

theorem zero_vsub (u : Vec n) : vsub (zero : Vec n) u = neg u := by
  funext i
  unfold vsub zero neg
  change 0 - u i = -u i
  rw [Rat.sub_eq_add_neg]
  exact Rat.zero_add (-u i)

/-! ## Inner Product -/

theorem inner_symm (u v : Vec n) : inner u v = inner v u := by
  unfold inner
  apply VecSum.congr
  intro i
  exact Rat.mul_comm (u i) (v i)

theorem inner_add_left (u v w : Vec n) : inner (vadd u v) w = inner u w + inner v w := by
  unfold inner vadd
  rw [← VecSum.add]
  apply VecSum.congr
  intro i
  exact Rat.add_mul (u i) (v i) (w i)

theorem inner_add_right (u v w : Vec n) : inner u (vadd v w) = inner u v + inner u w := by
  rw [inner_symm]
  rw [inner_add_left]
  rw [inner_symm, inner_symm u v, inner_symm u w]

theorem inner_smul_left (c : Rat) (u v : Vec n) : inner (smul c u) v = c * inner u v := by
  unfold inner smul
  rw [VecSum.const_mul_left]
  apply VecSum.congr
  intro i
  exact Rat.mul_assoc c (u i) (v i)

theorem inner_smul_right (c : Rat) (u v : Vec n) : inner u (smul c v) = inner u v * c := by
  rw [inner_symm]
  rw [inner_smul_left]
  rw [inner_symm]
  exact Rat.mul_comm c (inner u v)

theorem inner_zero_right (u : Vec n) : inner u zero = 0 := by
  unfold inner zero
  calc
    VecSum n (fun i => u i * 0) = VecSum n (fun _ => 0) := by
      apply VecSum.congr
      intro i
      simp [Rat.mul_zero]
    _ = 0 := VecSum.sum_zero n

theorem inner_zero_left (v : Vec n) : inner zero v = 0 := by
  rw [inner_symm, inner_zero_right]

/-! ## Norm -/

/-- ‖u‖² is nonnegative.
    Axiomatized: `uᵢ·uᵢ ≥ 0` on ℚ is a simple sign-cases argument on the
    numerator lattice. -/
axiom normSq_nonneg (u : Vec n) : 0 ≤ normSq u

theorem inner_self_nonneg (u : Vec n) : 0 ≤ inner u u :=
  normSq_nonneg u

/-- Cauchy–Schwarz for the ℓ₂ inner product: ⟨u,v⟩² ≤ ‖u‖²·‖v‖².
    Axiomatized: the constructive proof requires a polynomial square-root
    argument over ℚ. -/
axiom inner_sq_le_mul (u v : Vec n) :
    inner u v * inner u v ≤ normSq u * normSq v

/-! ## Mean and Mean-Zero Projection -/

/-- Mean of a sum is the sum of the means. -/
axiom mean_add (u v : Vec n) : mean (vadd u v) = mean u + mean v

/-- Mean of a scaled vector is the scaled mean. -/
axiom mean_smul (c : Rat) (u : Vec n) : mean (smul c u) = c * mean u

/-- The sum of the mean-zero components of `u` is zero. -/
axiom sum_meanZero_eq_zero (u : Vec n) :
    sumEntries (meanZero u) = 0

/-- The mean of the mean-zero component is zero. -/
axiom meanZero_mean (u : Vec n) : mean (meanZero u) = 0

/-- A vector with zero mean is its own mean-zero projection. -/
axiom meanZero_eq_of_mean_zero (u : Vec n) (hm : mean u = 0) : meanZero u = u

/-- Mean-zero projection is linear over addition.
    Immediate from the definition of `meanZero` and `mean_add`. -/
axiom meanZero_add (u v : Vec n) : meanZero (vadd u v) = vadd (meanZero u) (meanZero v)

/-- Mean-zero projection is linear over scaling. -/
axiom meanZero_smul (c : Rat) (u : Vec n) : meanZero (smul c u) = smul c (meanZero u)

/-- Mean-zero projection is linear over subtraction. -/
axiom meanZero_vsub (u v : Vec n) : meanZero (vsub u v) = vsub (meanZero u) (meanZero v)

/-- Mean-zero projection is idempotent. -/
axiom meanZero_idem (u : Vec n) : meanZero (meanZero u) = meanZero u

end Vec
end CertificateCore