/-
F1 square — the **Bernoulli polynomials** `Bₙ(x) = Σ_{k=0}^{n} C(n,k)·B_k·x^{n−k}` as exact rationals
(the v0.16.0 prerequisite for the *periodic* Bernoulli functions `P_{2K}({x})` that carry the
Euler–Maclaurin remainder `R_K(s,N)`). Built on the Bernoulli numbers `bernoulli` and `Binomial.choose`.

`Bₙ(0) = Bₙ` (only the `k = n` term survives, `x⁰ = 1`), and `B₁(x) = x − ½`, `B₂(x) = x² − x + 1/6`,
… — all exact, by reduction.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.Bernoulli
import F1Square.Analysis.ExpGen

namespace UOR.Bridge.F1Square.Analysis

/-- **The `n`-th Bernoulli polynomial** `Bₙ(x) = Σ_{k=0}^{n} C(n,k)·B_k·x^{n−k}` (exact rational eval). -/
def bernPoly (n : Nat) (x : Q) : Q :=
  Fsum (fun k => mul (mul (⟨(choose n k : Int), 1⟩ : Q) (bernoulli k)) (qpow x (n - k))) n

/-- `Bₙ(x)` has positive denominator (for `x.den > 0`), so it is a genuine rational. -/
theorem bernPoly_den_pos (n : Nat) {x : Q} (hx : 0 < x.den) : 0 < (bernPoly n x).den :=
  Fsum_den_pos (fun k => Qmul_den_pos (Qmul_den_pos Nat.one_pos (bernoulli_den_pos k))
    (qpow_den_pos hx _)) n

-- The defining values (exact, by reduction).

/-- `B₀(x) = 1`. -/
theorem bernPoly_zero (x : Q) : Qeq (bernPoly 0 x) ⟨1, 1⟩ := by
  show Qeq (mul (mul (⟨1, 1⟩ : Q) (bernoulli 0)) (qpow x 0)) ⟨1, 1⟩
  simp only [bernoulli, bernTable, qpow, Qeq, mul]; decide

/-- `B₁(0) = B₁ = −1/2`. -/
theorem bernPoly_one_at_zero : Qeq (bernPoly 1 ⟨0, 1⟩) ⟨-1, 2⟩ := by decide

/-- `B₂(0) = B₂ = 1/6`. -/
theorem bernPoly_two_at_zero : Qeq (bernPoly 2 ⟨0, 1⟩) ⟨1, 6⟩ := by decide

/-- `B₁(1) = 1/2` (`= x − ½` at `x = 1`). -/
theorem bernPoly_one_at_one : Qeq (bernPoly 1 ⟨1, 1⟩) ⟨1, 2⟩ := by decide

/-- `B₂(1) = 1/6 = B₂` (the `Bₙ(1) = Bₙ` symmetry for `n ≠ 1`). -/
theorem bernPoly_two_at_one : Qeq (bernPoly 2 ⟨1, 1⟩) ⟨1, 6⟩ := by decide

-- ===========================================================================
-- The **boundedness `|B₂(x)| ≤ 1/6` on `[0,1]`** — the `K = 1` periodic-Bernoulli bound that controls
-- the Euler–Maclaurin remainder on the critical strip (`Re s > −1`).
-- ===========================================================================

/-- `B₂(x) = x² − x + 1/6` (the closed form). -/
theorem bernPoly_two_form (x : Q) : Qeq (bernPoly 2 x) (add (add (mul x x) (neg x)) ⟨1, 6⟩) := by
  simp only [bernPoly, Fsum, qpow, bernoulli, bernTable, choose, Qeq, mul, add, neg]
  push_cast
  generalize x.num = p
  generalize (x.den : Int) = q
  ring_uor


/-- `0 ≤ a²` over `ℤ` (no `Mathlib` `sq_nonneg`). -/
private theorem sq_nonneg_int (a : Int) : 0 ≤ a * a := by
  rcases Int.le_total 0 a with h | h
  · exact Int.mul_nonneg h h
  · have := Int.mul_nonneg (by omega : (0 : Int) ≤ -a) (by omega : (0 : Int) ≤ -a)
    have he : (-a) * (-a) = a * a := by ring_uor
    omega

/-- The cleared upper bound `B₂(x) ≤ 1/6` (pure `Int`, `p = x.num`, `q = x.den`, `0 ≤ p ≤ q`):
    `6q³ − 6·num = 36·q·p·(q − p) ≥ 0` (`x² ≤ x` on `[0,1]`). -/
private theorem bp2_ub_int (p q : Int) (hp : 0 ≤ p) (hpq : p ≤ q) (hq : 0 ≤ q) :
    ((p * p * q + -p * (q * q)) * 6 + 1 * (q * q * q)) * 6 ≤ 1 * (q * q * q * 6) := by
  have key : 1 * (q * q * q * 6) - ((p * p * q + -p * (q * q)) * 6 + 1 * (q * q * q)) * 6
      = 36 * (q * (p * (q - p))) := by ring_uor
  have h1 : 0 ≤ q * (p * (q - p)) := Int.mul_nonneg hq (Int.mul_nonneg hp (by omega))
  have := Int.mul_nonneg (by omega : (0 : Int) ≤ 36) h1
  omega

/-- The cleared lower bound `B₂(x) ≥ −1/6` (pure `Int`): `6·num + 6q³ = 9q(2p − q)² + 3q³ ≥ 0`. -/
private theorem bp2_lb_int (p q : Int) (hq : 0 ≤ q) :
    (-1) * (q * q * q * 6) ≤ ((p * p * q + -p * (q * q)) * 6 + 1 * (q * q * q)) * 6 := by
  have key : ((p * p * q + -p * (q * q)) * 6 + 1 * (q * q * q)) * 6 - (-1) * (q * q * q * 6)
      = 9 * (q * ((2 * p - q) * (2 * p - q))) + 3 * (q * (q * q)) := by ring_uor
  have h1 : 0 ≤ 9 * (q * ((2 * p - q) * (2 * p - q))) :=
    Int.mul_nonneg (by omega) (Int.mul_nonneg hq (sq_nonneg_int _))
  have h2 : 0 ≤ 3 * (q * (q * q)) :=
    Int.mul_nonneg (by omega) (Int.mul_nonneg hq (Int.mul_nonneg hq hq))
  omega

/-- **`|B₂(x)| ≤ 1/6` for `x ∈ [0,1]`** — the `K = 1` periodic-Bernoulli bound that controls the
    Euler–Maclaurin remainder on the critical strip (`Re s > −1`). -/
theorem bernPoly_two_abs_le {x : Q} (hxd : 0 < x.den) (h0 : Qle (⟨0, 1⟩ : Q) x)
    (h1 : Qle x (⟨1, 1⟩ : Q)) : Qle (Qabs (bernPoly 2 x)) (⟨1, 6⟩ : Q) := by
  have hp : 0 ≤ x.num := by have := h0; simp only [Qle] at this; push_cast at this; omega
  have hpq : x.num ≤ (x.den : Int) := by have := h1; simp only [Qle] at this; push_cast at this; omega
  have hqnn : (0 : Int) ≤ (x.den : Int) := Int.ofNat_nonneg _
  have hcd : 0 < (add (add (mul x x) (neg x)) (⟨1, 6⟩ : Q)).den :=
    add_den_pos (add_den_pos (Qmul_den_pos hxd hxd) hxd) (by decide)
  have hub : Qle (bernPoly 2 x) (⟨1, 6⟩ : Q) := by
    refine Qle_congr_left hcd (Qeq_symm (bernPoly_two_form x)) ?_
    simp only [Qle, mul, neg, add]; push_cast
    exact bp2_ub_int x.num (x.den : Int) hp hpq hqnn
  have hlb : Qle (⟨-1, 6⟩ : Q) (bernPoly 2 x) := by
    refine Qle_congr_right hcd (Qeq_symm (bernPoly_two_form x)) ?_
    simp only [Qle, mul, neg, add]; push_cast
    exact bp2_lb_int x.num (x.den : Int) hqnn
  simp only [Qle, Qabs] at hub hlb ⊢
  push_cast at hub hlb ⊢
  omega

end UOR.Bridge.F1Square.Analysis
