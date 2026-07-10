/-
F1 square — v0.19.0 (the genuine-pairing arc), substrate brick P1: **`|x|` and `max(0, ·)`
on the constructive reals** — the test-function substrate for the Weil quadratic functional.

THE OBJECTS. `Rabs x` is pointwise (`|·|` preserves Bishop regularity with NO reindex, via
the reverse triangle inequality `||a| − |b|| ≤ |a − b|`); `RmaxZero t = max(0, t)` is the
algebraic identity `max(0,t) = ½(t + |t|)` — a pure composition of already-regular
operations (`Rhalf`, `Radd`, `Rabs`), so no new regularity proof is owed.

THE PURPOSE. Compactly-supported piecewise-linear test functions (tents
`u ↦ max(0, w − |u − c|)`) are total `Real → Real` functions built from these — exactly
what the explicit-formula prime side (`Mangoldt.primeSide`) consumes and what the Weil
functional's test class needs. The three evaluation lemmas are the tent calculus:
  • `Rnonneg_RmaxZero`   — tents are non-negative everywhere;
  • `RmaxZero_of_nonpos` — a tent vanishes off its support (`max(0,s) ≈ 0` for `s ≤ 0`);
  • `RmaxZero_of_nonneg` — on-support a tent IS its linear part (`max(0,t) ≈ t` for `t ≥ 0`).

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.RealPow

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The reverse triangle inequality on ℚ, and `Rabs`.
-- ===========================================================================

/-- The cast-mult bridge: `(|z| : ℤ) · (d : ℤ) = |z · d|` for `z : ℤ`, `d : ℕ`. -/
private theorem natAbs_mul_cast (z : Int) (d : Nat) :
    (z.natAbs : Int) * (d : Int) = (((z * (d : Int)).natAbs : Nat) : Int) := by
  rw [Int.natAbs_mul, Int.natAbs_ofNat]
  push_cast
  rfl

/-- **The reverse triangle inequality on ℚ**: `||a| − |b|| ≤ |a − b|`. -/
theorem Qabs_abs_sub (a b : Q) : Qle (Qabs (Qsub (Qabs a) (Qabs b))) (Qabs (Qsub a b)) := by
  show Qle (Qabs (add (Qabs a) (neg (Qabs b)))) (Qabs (add a (neg b)))
  simp only [Qle, Qabs, add, neg]
  have e1 : (a.num.natAbs : Int) * (b.den : Int) = (((a.num * (b.den : Int)).natAbs : Nat) : Int) :=
    natAbs_mul_cast a.num b.den
  have e2 : -(b.num.natAbs : Int) * (a.den : Int) = -(((b.num * (a.den : Int)).natAbs : Nat) : Int) := by
    rw [Int.neg_mul, natAbs_mul_cast]
  rw [e1, e2]
  have key : ((((((a.num * (b.den : Int)).natAbs : Nat) : Int) + -(((b.num * (a.den : Int)).natAbs : Nat) : Int)).natAbs : Nat) : Int)
      ≤ (((a.num * (b.den : Int) + -b.num * (a.den : Int)).natAbs : Nat) : Int) := by
    have e3 : -b.num * (a.den : Int) = -(b.num * (a.den : Int)) := by rw [Int.neg_mul]
    rw [e3]
    omega
  have hd : (0 : Int) ≤ ((a.den * b.den : Nat) : Int) := Int.ofNat_nonneg _
  exact Int.mul_le_mul_of_nonneg_right key hd

/-- **`|x|` on the constructive reals** — pointwise; regular with NO reindex (the reverse
    triangle inequality transfers the regularity bound). -/
def Rabs (x : Real) : Real where
  seq := fun n => Qabs (x.seq n)
  reg := by
    intro m n
    show Qle (Qabs (Qsub (Qabs (x.seq m)) (Qabs (x.seq n)))) (add (Qbound m) (Qbound n))
    exact Qle_trans
      (Qabs_den_pos (Qsub_den_pos (x.den_pos m) (x.den_pos n)))
      (Qabs_abs_sub (x.seq m) (x.seq n)) (x.reg m n)
  den_pos := fun n => Qabs_den_pos (x.den_pos n)

/-- `|·|` respects `≈`. -/
theorem Rabs_congr {x y : Real} (h : Req x y) : Req (Rabs x) (Rabs y) := by
  intro n
  show Qle (Qabs (Qsub (Qabs (x.seq n)) (Qabs (y.seq n)))) ⟨2, n + 1⟩
  exact Qle_trans
    (Qabs_den_pos (Qsub_den_pos (x.den_pos n) (y.den_pos n)))
    (Qabs_abs_sub (x.seq n) (y.seq n)) (h n)

/-- `|x| ≥ 0`. -/
theorem Rnonneg_Rabs (x : Real) : Rnonneg (Rabs x) := by
  intro n
  show (-1 : Int) * ((x.seq n).den : Int) ≤ ((x.seq n).num.natAbs : Int) * (((n + 1 : Nat)) : Int)
  have h1 : (0 : Int) ≤ ((x.seq n).num.natAbs : Int) * (((n + 1 : Nat)) : Int) :=
    Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _)
  have h2 : (0 : Int) ≤ ((x.seq n).den : Int) := Int.ofNat_nonneg _
  omega

-- ===========================================================================
-- `max(0, ·)` via `½(t + |t|)`, and the tent calculus.
-- ===========================================================================

/-- **`max(0, t)`** on the constructive reals: `½(t + |t|)` — a composition of regular
    operations (no new regularity proof owed). -/
def RmaxZero (t : Real) : Real := Rhalf (Radd t (Rabs t))

/-- `max(0, ·)` respects `≈`. -/
theorem RmaxZero_congr {s t : Real} (h : Req s t) : Req (RmaxZero s) (RmaxZero t) :=
  Rhalf_congr (Radd_congr h (Rabs_congr h))

/-- The pure-`ℤ` core of `Rnonneg_RmaxZero`. -/
private theorem max0_nonneg_int (N A D M : Int) (hNA : -N ≤ A) (hD : 0 ≤ D) (hM : 0 ≤ M) :
    (-1) * (2 * (D * D)) ≤ 1 * (N * D + A * D) * M := by
  have e1 : 1 * (N * D + A * D) * M = ((N + A) * D) * M := by ring_uor
  rw [e1]
  have h1 : 0 ≤ (N + A) * D := Int.mul_nonneg (by omega) hD
  have h2 : 0 ≤ ((N + A) * D) * M := Int.mul_nonneg h1 hM
  have h3 : 0 ≤ D * D := Int.mul_nonneg hD hD
  omega

/-- **Tents are non-negative**: `max(0, t) ≥ 0` for every `t`. -/
theorem Rnonneg_RmaxZero (t : Real) : Rnonneg (RmaxZero t) := by
  intro n
  show (-1 : Int) * (((2 * ((t.seq (2 * n + 1)).den * (t.seq (2 * n + 1)).den)) : Nat) : Int)
      ≤ (1 * ((t.seq (2 * n + 1)).num * ((t.seq (2 * n + 1)).den : Int)
            + ((t.seq (2 * n + 1)).num.natAbs : Int) * ((t.seq (2 * n + 1)).den : Int)))
        * (((n + 1 : Nat)) : Int)
  push_cast
  exact max0_nonneg_int _ _ _ _ (by omega) (Int.ofNat_nonneg _) (by omega)

/-- The pure-`ℤ` core of `RmaxZero_of_nonpos`: with `q = ⟨N, D⟩` the `(2n+1)`-th term of
    `s ≤ 0` (so `N·(2M+2) ≤ 2D` with `M = n`), the value `½(q + |q|)` is within `2/(n+1)`
    of `0` in cross-multiplied form. -/
private theorem max0_vanish_int (N A D M : Int) (hA : 0 ≤ A) (hcase : A = N ∨ A = -N)
    (hD : 0 ≤ D) (_hM : 0 ≤ M) (hs : N * (2 * M + 2) ≤ 2 * D) :
    (((1 * (N * D + A * D) * 1 + -0 * ((2 : Int) * (D * D))).natAbs : Nat) : Int) * (M + 1)
      ≤ 2 * (2 * (D * D) * 1) := by
  have h0 : (-0 : Int) = 0 := rfl
  rw [h0]
  have e1 : 1 * (N * D + A * D) * 1 + 0 * ((2 : Int) * (D * D)) = (N + A) * D := by ring_uor
  rw [e1]
  have hVnn : 0 ≤ (N + A) * D := Int.mul_nonneg (by omega) hD
  rw [Int.natAbs_of_nonneg hVnn]
  rcases hcase with hc | hc
  · -- `A = N ≥ 0`: value `2ND`; from `N(2M+2) ≤ 2D`, multiply by `D ≥ 0`
    rw [hc]
    have h1 : (N * (2 * M + 2)) * D ≤ (2 * D) * D := Int.mul_le_mul_of_nonneg_right hs hD
    have e2 : (N + N) * D * (M + 1) = (N * (2 * M + 2)) * D := by ring_uor
    have e3 : 2 * (2 * (D * D) * 1) = (2 * D) * D + (2 * D) * D := by ring_uor
    have h2 : 0 ≤ (2 * D) * D := Int.mul_nonneg (by omega) hD
    rw [e2, e3]
    omega
  · -- `A = −N` (`N ≤ 0`): the value is `0`
    have e2 : (N + A) * D * (M + 1) = (N + A) * (D * (M + 1)) := by ring_uor
    rw [e2, hc]
    have e3 : (N + -N) * (D * (M + 1)) = 0 := by ring_uor
    rw [e3]
    have h3 : 0 ≤ D * D := Int.mul_nonneg hD hD
    omega

/-- **A tent vanishes off its support**: `s ≤ 0 ⟹ max(0, s) ≈ 0`. -/
theorem RmaxZero_of_nonpos {s : Real} (h : Rle s zero) : Req (RmaxZero s) zero := by
  intro n
  have hs := h (2 * n + 1)
  -- `hs : s_{2n+1} ≤ 0 + 2/(2n+2)`, cross-multiplied below
  show (((1 * ((s.seq (2 * n + 1)).num * ((s.seq (2 * n + 1)).den : Int)
          + ((s.seq (2 * n + 1)).num.natAbs : Int) * ((s.seq (2 * n + 1)).den : Int)) * 1
        + -0 * (((2 * ((s.seq (2 * n + 1)).den * (s.seq (2 * n + 1)).den)) : Nat) : Int)).natAbs : Nat) : Int)
      * (((n + 1 : Nat)) : Int)
      ≤ 2 * ((((2 * ((s.seq (2 * n + 1)).den * (s.seq (2 * n + 1)).den)) * 1 : Nat)) : Int)
  have hsI : (s.seq (2 * n + 1)).num * (((1 * (2 * n + 1 + 1) : Nat)) : Int)
      ≤ (0 * (((2 * n + 1 + 1) : Nat) : Int) + 2 * 1) * ((s.seq (2 * n + 1)).den : Int) := hs
  push_cast at hsI ⊢
  have efac : (1 : Int) * (2 * (n : Int) + 1 + 1) = 2 * (n : Int) + 2 := by omega
  rw [efac] at hsI
  have efac2 : (0 : Int) * (2 * (n : Int) + 1 + 1) + 2 = 2 := by omega
  rw [efac2] at hsI
  exact max0_vanish_int _ _ _ ((n : Int)) (by omega) (by omega) (Int.ofNat_nonneg _) (by omega) hsI

/-- The pure-`ℤ` core of the on-support half of `RmaxZero_of_nonneg`: `|½(q+|q|) − q|`
    is within `1/(2n+2)` when `−D ≤ N·(2M+2)` (`q ≥ −1/(2M+2)`), cross-multiplied. -/
private theorem max0_id_int (N A D M : Int) (hA : 0 ≤ A) (hcase : A = N ∨ A = -N)
    (hD : 0 ≤ D) (_hM : 0 ≤ M) (hnn : -D ≤ N * (2 * M + 2)) :
    (((1 * (N * D + A * D) * D + -N * ((2 : Int) * (D * D))).natAbs : Nat) : Int) * (2 * M + 2)
      ≤ 1 * (2 * (D * D) * D) := by
  have e1 : 1 * (N * D + A * D) * D + -N * ((2 : Int) * (D * D)) = (A - N) * (D * D) := by
    ring_uor
  rw [e1]
  have hDD : 0 ≤ D * D := Int.mul_nonneg hD hD
  rcases hcase with hc | hc
  · -- `A = N`: the difference is `0`
    rw [hc]
    have e2 : (N - N) * (D * D) = 0 := by ring_uor
    rw [e2, Int.natAbs_zero]
    have h1 : 0 ≤ 2 * (D * D) * D := Int.mul_nonneg (by omega) hD
    omega
  · -- `A = −N` (`N ≤ 0`): difference `−2N·D²`; from `−D ≤ N(2M+2)`, multiply by `D² ≥ 0`
    rw [hc]
    have hVnn : 0 ≤ (-N - N) * (D * D) := Int.mul_nonneg (by omega) hDD
    rw [Int.natAbs_of_nonneg hVnn]
    have h2 : (-D) * (D * D) ≤ (N * (2 * M + 2)) * (D * D) :=
      Int.mul_le_mul_of_nonneg_right hnn hDD
    have e2 : (-N - N) * (D * D) * (2 * M + 2)
        = -((N * (2 * M + 2)) * (D * D) + (N * (2 * M + 2)) * (D * D)) := by ring_uor
    have e3 : 1 * (2 * (D * D) * D) = -((-D) * (D * D) + (-D) * (D * D)) := by ring_uor
    rw [e2, e3]
    omega

/-- The closing rational comparison of `RmaxZero_of_nonneg`:
    `1/(2n+2) + (1/(2n+2) + 1/(n+1)) ≤ 2/(n+1)` (in fact equality), cross-multiplied. -/
private theorem max0_id_close (x : Int) :
    (1 * ((2 * x + 1 + 1) * (x + 1)) + (1 * (x + 1) + 1 * (2 * x + 1 + 1)) * (2 * x + 1 + 1)) * (x + 1)
      ≤ 2 * ((2 * x + 1 + 1) * ((2 * x + 1 + 1) * (x + 1))) := by
  have e : (1 * ((2 * x + 1 + 1) * (x + 1)) + (1 * (x + 1) + 1 * (2 * x + 1 + 1)) * (2 * x + 1 + 1)) * (x + 1)
      = 2 * ((2 * x + 1 + 1) * ((2 * x + 1 + 1) * (x + 1))) := by ring_uor
  omega

/-- **On-support a tent is its linear part**: `t ≥ 0 ⟹ max(0, t) ≈ t`. -/
theorem RmaxZero_of_nonneg {t : Real} (h : Rnonneg t) : Req (RmaxZero t) t := by
  intro n
  -- triangle through `q = t.seq (2n+1)`: `|max0ₙ − tₙ| ≤ |max0ₙ − q| + |q − tₙ|`
  have htri := Qabs_sub_triangle
    (a := (RmaxZero t).seq n) (b := t.seq (2 * n + 1)) (c := t.seq n)
    ((RmaxZero t).den_pos n) (t.den_pos (2 * n + 1)) (t.den_pos n)
  refine Qle_trans (add_den_pos
    (Qabs_den_pos (Qsub_den_pos ((RmaxZero t).den_pos n) (t.den_pos (2 * n + 1))))
    (Qabs_den_pos (Qsub_den_pos (t.den_pos (2 * n + 1)) (t.den_pos n)))) htri ?_
  -- piece 1: `|½(q+|q|) − q| ≤ 1/(2n+2)`; piece 2: regularity `|t_{2n+1} − t_n| ≤ 1/(2n+2) + 1/(n+1)`
  have hp1 : Qle (Qabs (Qsub ((RmaxZero t).seq n) (t.seq (2 * n + 1)))) (Qbound (2 * n + 1)) := by
    have hnn := h (2 * n + 1)
    show (((1 * ((t.seq (2 * n + 1)).num * ((t.seq (2 * n + 1)).den : Int)
            + ((t.seq (2 * n + 1)).num.natAbs : Int) * ((t.seq (2 * n + 1)).den : Int))
              * ((t.seq (2 * n + 1)).den : Int)
          + -(t.seq (2 * n + 1)).num
              * (((2 * ((t.seq (2 * n + 1)).den * (t.seq (2 * n + 1)).den)) : Nat) : Int)).natAbs : Nat) : Int)
        * (((2 * n + 1 + 1 : Nat)) : Int)
        ≤ 1 * ((((2 * ((t.seq (2 * n + 1)).den * (t.seq (2 * n + 1)).den)) * (t.seq (2 * n + 1)).den : Nat)) : Int)
    have hnnI : (-1 : Int) * ((t.seq (2 * n + 1)).den : Int)
        ≤ (t.seq (2 * n + 1)).num * (((2 * n + 1 + 1 : Nat)) : Int) := hnn
    push_cast at hnnI ⊢
    have efac : (2 * (n : Int) + 1 + 1) = 2 * (n : Int) + 2 := by omega
    rw [efac] at hnnI ⊢
    refine max0_id_int _ _ _ ((n : Int)) (by omega) (by omega) (Int.ofNat_nonneg _) (by omega) ?_
    omega
  have hp2 := t.reg (2 * n + 1) n
  have hsum := Qadd_le_add hp1 hp2
  refine Qle_trans (add_den_pos (by show 0 < 2 * n + 1 + 1; omega)
    (add_den_pos (by show 0 < 2 * n + 1 + 1; omega) (by show 0 < n + 1; omega))) hsum ?_
  -- `1/(2n+2) + (1/(2n+2) + 1/(n+1)) ≤ 2/(n+1)`
  show (1 * (((2 * n + 1 + 1) * (n + 1) : Nat) : Int)
        + (1 * ((n + 1 : Nat) : Int) + 1 * (((2 * n + 1 + 1) : Nat) : Int))
          * (((2 * n + 1 + 1) : Nat) : Int))
      * (((n + 1 : Nat)) : Int)
      ≤ 2 * ((((2 * n + 1 + 1) * ((2 * n + 1 + 1) * (n + 1)) : Nat)) : Int)
  push_cast
  exact max0_id_close ((n : Int))

end UOR.Bridge.F1Square.Analysis
