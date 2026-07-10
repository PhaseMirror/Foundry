/-
F1 square — v0.22.0 Track 1, brick (special-function substrate): **the formal arctan ODE**
`arctan′(t) = 1/(1+t²)` at the level of formal power-series coefficients.

This is the alternating sibling of `dgeom_ode` (ExpLog.lean), which proved that the `(1+w)/(1−w)`
coefficients satisfy `E′ = (2/(1−w²))·E` — the engine behind the *exact rational* artanh exp identity.

The arctan series `A(t) = Σ (−1)ⁿ t^{2n+1}/(2n+1)` has formal derivative `A′(t) = Σ (−1)ⁿ t^{2n} =
1/(1+t²)` (`arctan_fderiv`), and `(1+t²)·A′(t) = 1` (`onePlusSq_geomAlt`). Unlike the geometric
series, the arctan series is *not* rational-summable, so this formal identity does not collapse to an
exact rational value identity (as the artanh one did): the value-level inverse-function fact
`tan(arctan t) = t` — the remaining gap for the argument-addition `arg(zw) = arg z + arg w` (the
imaginary half of `Clog` additivity) — requires a formal-PS → value (fundamental-theorem-of-calculus)
bridge on top of this ODE. This brick is the constructive seed of that bridge.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.ExpLog
import F1Square.Analysis.Arctan
import F1Square.Analysis.CosSinAddFormula

namespace UOR.Bridge.F1Square.Analysis

/-- The **arctan coefficient sequence**: coefficient of `tᵏ` in `Σ (−1)ⁿ t^{2n+1}/(2n+1)`. Nonzero only
    at odd degree `k = 2n+1`, where it is `(−1)ⁿ/(2n+1) = (−1)^{k/2}/k`. -/
def arctanCoeff (k : Nat) : Q :=
  if k % 2 = 1 then mul (qpow (⟨-1, 1⟩ : Q) (k / 2)) ⟨1, k⟩ else ⟨0, 1⟩

/-- The **`1/(1+t²)` coefficient sequence**: `Σ (−1)ⁿ t^{2n}`. Nonzero only at even degree `k = 2n`,
    where it is `(−1)ⁿ = (−1)^{k/2}`. -/
def geomAlt (k : Nat) : Q :=
  if k % 2 = 0 then qpow (⟨-1, 1⟩ : Q) (k / 2) else ⟨0, 1⟩

theorem arctanCoeff_den_pos (k : Nat) : 0 < (arctanCoeff k).den := by
  unfold arctanCoeff; split
  · rename_i h
    refine Qmul_den_pos (qpow_den_pos (by decide) (k / 2)) ?_
    show 0 < k; omega
  · exact Nat.one_pos

theorem geomAlt_den_pos (k : Nat) : 0 < (geomAlt k).den := by
  unfold geomAlt; split
  · exact qpow_den_pos (by decide) _
  · exact Nat.one_pos

/-- **The formal arctan ODE**: `fderiv arctanCoeff = geomAlt`, i.e. `A′(t) = 1/(1+t²)`. At even degree
    `k = 2n` the derivative `(k+1)·arctanCoeff(k+1) = (2n+1)·(−1)ⁿ/(2n+1) = (−1)ⁿ` matches `geomAlt(2n)`;
    at odd degree the next arctan coefficient vanishes, matching `geomAlt(odd) = 0`. -/
theorem arctan_fderiv (k : Nat) : Qeq (fderiv arctanCoeff k) (geomAlt k) := by
  rcases Nat.mod_two_eq_zero_or_one k with h | h
  · -- k even: k = 2n; k+1 = 2n+1 odd, (2n+1)/2 = n, (2n)/2 = n
    obtain ⟨n, rfl⟩ : ∃ n, k = 2 * n := ⟨k / 2, by omega⟩
    show Qeq (mul ⟨(2 * n + 1 : Int), 1⟩ (arctanCoeff (2 * n + 1))) (geomAlt (2 * n))
    unfold arctanCoeff geomAlt
    rw [if_pos (by omega : (2 * n + 1) % 2 = 1), if_pos (by omega : (2 * n) % 2 = 0),
      show (2 * n + 1) / 2 = n from by omega, show (2 * n) / 2 = n from by omega]
    -- (2n+1)·((−1)ⁿ·(1/(2n+1))) ≈ (−1)ⁿ
    simp only [Qeq, mul]; push_cast; ring_uor
  · -- k odd: k = 2n+1; k+1 = 2n+2 even, arctanCoeff(2n+2) = 0; geomAlt(2n+1) = 0
    obtain ⟨n, rfl⟩ : ∃ n, k = 2 * n + 1 := ⟨k / 2, by omega⟩
    show Qeq (mul ⟨(2 * n + 1 + 1 : Int), 1⟩ (arctanCoeff (2 * n + 1 + 1))) (geomAlt (2 * n + 1))
    unfold arctanCoeff geomAlt
    rw [if_neg (by omega : ¬ (2 * n + 1 + 1) % 2 = 1), if_neg (by omega : ¬ (2 * n + 1) % 2 = 0)]
    -- (2n+2)·0 ≈ 0
    show Qeq (mul ⟨(2 * n + 1 + 1 : Int), 1⟩ ⟨0, 1⟩) ⟨0, 1⟩
    simp only [Qeq, mul]; omega

/-- **The `(1+t²)·A′ = 1` annihilation, homogeneous part**: the derivative coefficients `geomAlt`
    satisfy `geomAlt(k+2) + geomAlt(k) ≈ 0` — i.e. multiplication by `1+t²` kills every degree `≥ 2`.
    The parity recurrence `(−1)^{n+1} + (−1)ⁿ = 0` (`qpow_succ` of `⟨−1,1⟩`). -/
theorem geomAlt_recurrence (k : Nat) : Qeq (add (geomAlt (k + 2)) (geomAlt k)) ⟨0, 1⟩ := by
  rcases Nat.mod_two_eq_zero_or_one k with h | h
  · obtain ⟨n, rfl⟩ : ∃ n, k = 2 * n := ⟨k / 2, by omega⟩
    unfold geomAlt
    rw [if_pos (by omega : (2 * n + 2) % 2 = 0), if_pos (by omega : (2 * n) % 2 = 0),
      show (2 * n + 2) / 2 = n + 1 from by omega, show (2 * n) / 2 = n from by omega, qpow_succ]
    -- (−1)ⁿ·(−1) + (−1)ⁿ ≈ 0
    simp only [Qeq, add, mul]; push_cast; ring_uor
  · obtain ⟨n, rfl⟩ : ∃ n, k = 2 * n + 1 := ⟨k / 2, by omega⟩
    unfold geomAlt
    rw [if_neg (by omega : ¬ (2 * n + 1 + 2) % 2 = 0), if_neg (by omega : ¬ (2 * n + 1) % 2 = 0)]
    show Qeq (add (⟨0, 1⟩ : Q) ⟨0, 1⟩) ⟨0, 1⟩
    decide

/-- Boundary value: `A′(0) = 1` (`geomAlt 0 = 1`), the normalization `arctan′(0) = 1/(1+0²) = 1`. -/
theorem geomAlt_zero : geomAlt 0 = ⟨1, 1⟩ := by decide

/-- Boundary value: the degree-1 coefficient of `A′` vanishes (`geomAlt 1 = 0`). -/
theorem geomAlt_one : geomAlt 1 = ⟨0, 1⟩ := by decide

-- ===========================================================================
-- The formal sin/cos ODE  sin′ = cos,  cos′ = −sin  (degree-indexed coefficients).
-- Toward the value identity tan(arctan t) = t via the formal composition sin∘arctan.
-- ===========================================================================

/-- The **`sin` coefficient sequence**: coefficient of `tᵏ` in `Σ (−1)ⁿ t^{2n+1}/(2n+1)!`. Nonzero only
    at odd degree `k = 2n+1`, where it is `(−1)ⁿ/k! = (−1)^{k/2}/k!`. -/
def sinCoeff (k : Nat) : Q :=
  if k % 2 = 1 then mul (qpow (⟨-1, 1⟩ : Q) (k / 2)) ⟨1, fct k⟩ else ⟨0, 1⟩

/-- The **`cos` coefficient sequence**: coefficient of `tᵏ` in `Σ (−1)ⁿ t^{2n}/(2n)!`. Nonzero only at
    even degree `k = 2n`, where it is `(−1)ⁿ/k! = (−1)^{k/2}/k!`. -/
def cosCoeff (k : Nat) : Q :=
  if k % 2 = 0 then mul (qpow (⟨-1, 1⟩ : Q) (k / 2)) ⟨1, fct k⟩ else ⟨0, 1⟩

/-- Pure-`Int` core of the factorial-telescope step in `sin_fderiv` / the matching `cos` even-branch:
    `(2m+1)·(P·1)·(D·F) = (P·1)·(1·(D·((2m+1)·F)))`. Extracted because `ring_uor` reifies cleanly only
    over bare `Int` atoms (the in-place goal carries the opaque cast `↑(fct …)`). -/
private theorem sincos_fct_poly (m P D F : Int) :
    (2 * m + 1) * (P * 1) * (D * F) = P * 1 * (1 * (D * ((2 * m + 1) * F))) := by ring_uor

/-- Pure-`Int` core of the factorial-telescope step in `cos_fderiv` (odd branch), with the sign advance
    `(−1)^{n+1} = −(−1)ⁿ` already pulled out: `(2m+2)·(−P·1)·(D·F) = −(P·1)·(1·(1·D·((2m+2)·F)))`. -/
private theorem cos_fct_poly (m P D F : Int) :
    (2 * m + 1 + 1) * (-1 * P * 1) * (D * F) = -(P * 1) * (1 * (1 * D * ((2 * m + 1 + 1) * F))) := by
  ring_uor

theorem sinCoeff_den_pos (k : Nat) : 0 < (sinCoeff k).den := by
  unfold sinCoeff; split
  · exact Qmul_den_pos (qpow_den_pos (by decide) (k / 2)) (fct_pos k)
  · exact Nat.one_pos

theorem cosCoeff_den_pos (k : Nat) : 0 < (cosCoeff k).den := by
  unfold cosCoeff; split
  · exact Qmul_den_pos (qpow_den_pos (by decide) (k / 2)) (fct_pos k)
  · exact Nat.one_pos

/-- **The formal `sin` ODE**: `fderiv sinCoeff = cosCoeff` (`sin′ = cos`). At even degree `k = 2n` the
    factorial telescopes `(2n+1)·(1/(2n+1)!) = 1/(2n)!` with the same sign `(−1)ⁿ`; at odd degree the
    next `sin` coefficient vanishes, matching `cosCoeff(odd) = 0`. -/
theorem sin_fderiv (k : Nat) : Qeq (fderiv sinCoeff k) (cosCoeff k) := by
  rcases Nat.mod_two_eq_zero_or_one k with h | h
  · obtain ⟨n, rfl⟩ : ∃ n, k = 2 * n := ⟨k / 2, by omega⟩
    show Qeq (mul ⟨(2 * n + 1 : Int), 1⟩ (sinCoeff (2 * n + 1))) (cosCoeff (2 * n))
    unfold sinCoeff cosCoeff
    rw [if_pos (by omega : (2 * n + 1) % 2 = 1), if_pos (by omega : (2 * n) % 2 = 0),
      show (2 * n + 1) / 2 = n from by omega, show (2 * n) / 2 = n from by omega]
    have hfZ : (fct (2 * n + 1) : Int) = (2 * n + 1) * fct (2 * n) := by
      exact_mod_cast fct_succ (2 * n)
    simp only [Qeq, mul]; push_cast [hfZ]
    exact sincos_fct_poly (n : Int) ((qpow (⟨-1, 1⟩ : Q) n).num)
      ((qpow (⟨-1, 1⟩ : Q) n).den : Int) ((fct (2 * n) : Nat) : Int)
  · obtain ⟨n, rfl⟩ : ∃ n, k = 2 * n + 1 := ⟨k / 2, by omega⟩
    show Qeq (mul ⟨(2 * n + 1 + 1 : Int), 1⟩ (sinCoeff (2 * n + 1 + 1))) (cosCoeff (2 * n + 1))
    unfold sinCoeff cosCoeff
    rw [if_neg (by omega : ¬ (2 * n + 1 + 1) % 2 = 1), if_neg (by omega : ¬ (2 * n + 1) % 2 = 0)]
    show Qeq (mul ⟨(2 * n + 1 + 1 : Int), 1⟩ ⟨0, 1⟩) ⟨0, 1⟩
    simp only [Qeq, mul]; omega

/-- **The formal `cos` ODE**: `fderiv cosCoeff = −sinCoeff` (`cos′ = −sin`). At odd degree `k = 2n+1`
    the factorial telescopes `(2n+2)·(1/(2n+2)!) = 1/(2n+1)!`, and the sign advances one step
    (`(−1)^{n+1} = −(−1)ⁿ`, via `qpow_succ`), matching `−sinCoeff(2n+1)`; at even degree both vanish. -/
theorem cos_fderiv (k : Nat) : Qeq (fderiv cosCoeff k) (neg (sinCoeff k)) := by
  rcases Nat.mod_two_eq_zero_or_one k with h | h
  · obtain ⟨n, rfl⟩ : ∃ n, k = 2 * n := ⟨k / 2, by omega⟩
    show Qeq (mul ⟨(2 * n + 1 : Int), 1⟩ (cosCoeff (2 * n + 1))) (neg (sinCoeff (2 * n)))
    unfold cosCoeff sinCoeff
    rw [if_neg (by omega : ¬ (2 * n + 1) % 2 = 0), if_neg (by omega : ¬ (2 * n) % 2 = 1)]
    show Qeq (mul ⟨(2 * n + 1 : Int), 1⟩ ⟨0, 1⟩) (neg ⟨0, 1⟩)
    simp only [Qeq, mul, neg]; omega
  · obtain ⟨n, rfl⟩ : ∃ n, k = 2 * n + 1 := ⟨k / 2, by omega⟩
    show Qeq (mul ⟨(2 * n + 1 + 1 : Int), 1⟩ (cosCoeff (2 * n + 1 + 1))) (neg (sinCoeff (2 * n + 1)))
    unfold cosCoeff sinCoeff
    rw [if_pos (by omega : (2 * n + 1 + 1) % 2 = 0), if_pos (by omega : (2 * n + 1) % 2 = 1),
      show (2 * n + 1 + 1) / 2 = n + 1 from by omega, show (2 * n + 1) / 2 = n from by omega,
      qpow_succ]
    have hfZ : (fct (2 * n + 1 + 1) : Int) = (2 * n + 1 + 1) * fct (2 * n + 1) := by
      exact_mod_cast fct_succ (2 * n + 1)
    simp only [Qeq, mul, neg]; push_cast [hfZ]
    exact cos_fct_poly (n : Int) ((qpow (⟨-1, 1⟩ : Q) n).num)
      ((qpow (⟨-1, 1⟩ : Q) n).den : Int) ((fct (2 * n + 1) : Nat) : Int)

-- ===========================================================================
-- Formal composition  sin∘arctan, cos∘arctan: the chain-rule ODE relations
--   (sin∘arctan)′ = (cos∘arctan)·A′,   (cos∘arctan)′ = −(sin∘arctan)·A′.
-- ===========================================================================

/-- Negation distributes over the formal `add`: `(−A) + (−B) ≈ −(A + B)`. -/
theorem Qadd_neg_distrib (A B : Q) : Qeq (add (neg A) (neg B)) (neg (add A B)) := by
  simp only [Qeq, add, neg]; push_cast; ring_uor

/-- A finite sum of negations is the negation of the sum: `Σ (−fᵢ) ≈ −(Σ fᵢ)`. -/
theorem Fsum_neg (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) (k : Nat) :
    Qeq (Fsum (fun i => neg (f i)) k) (neg (Fsum f k)) := by
  induction k with
  | zero => exact Qeq_refl _
  | succ n ih =>
      show Qeq (add (Fsum (fun i => neg (f i)) n) (neg (f (n + 1)))) (neg (add (Fsum f n) (f (n + 1))))
      exact Qeq_trans (add_den_pos (neg_den_pos (Fsum_den_pos hf n)) (neg_den_pos (hf (n + 1))))
        (Qadd_congr ih (Qeq_refl _)) (Qadd_neg_distrib (Fsum f n) (f (n + 1)))

/-- The formal composition is left-linear over negation: `(−a)∘b ≈ −(a∘b)`. Pull the sign through the
    composition sum so the `cos` chain rule `(cos∘arctan)′ = −(sin∘arctan)·A′` lands in clean form. -/
theorem fcomp_neg_left (a b : Nat → Q) (ha : ∀ i, 0 < (a i).den) (hb : ∀ i, 0 < (b i).den) (k : Nat) :
    Qeq (fcomp (fun m => neg (a m)) b k) (neg (fcomp a b k)) := by
  show Qeq (Fsum (fun m => mul (neg (a m)) (fpow b m k)) k) (neg (Fsum (fun m => mul (a m) (fpow b m k)) k))
  refine Qeq_trans (Fsum_den_pos (fun m => neg_den_pos (Qmul_den_pos (ha m) (fpow_den_pos hb m k))) k)
    (Fsum_congr (fun m => Qmul_neg_left (a m) (fpow b m k)) k)
    (Fsum_neg (fun m => mul (a m) (fpow b m k)) (fun m => Qmul_den_pos (ha m) (fpow_den_pos hb m k)) k)

/-- The formal Cauchy product is left-linear over negation: `(−a)·b ≈ −(a·b)`. -/
theorem fmul_neg_left (a b : Nat → Q) (ha : ∀ i, 0 < (a i).den) (hb : ∀ i, 0 < (b i).den) (k : Nat) :
    Qeq (fmul (fun i => neg (a i)) b k) (neg (fmul a b k)) := by
  show Qeq (Fsum (fun i => mul (neg (a i)) (b (k - i))) k) (neg (Fsum (fun i => mul (a i) (b (k - i))) k))
  refine Qeq_trans (Fsum_den_pos (fun i => neg_den_pos (Qmul_den_pos (ha i) (hb (k - i)))) k)
    (Fsum_congr (fun i => Qmul_neg_left (a i) (b (k - i))) k)
    (Fsum_neg (fun i => mul (a i) (b (k - i))) (fun i => Qmul_den_pos (ha i) (hb (k - i))) k)

/-- `arctanCoeff 0 = 0` — the composition prerequisite `b(0) = 0` for `fcomp_chain`. -/
theorem arctanCoeff_zero : Qeq (arctanCoeff 0) ⟨0, 1⟩ := by decide

/-- **The `sin∘arctan` chain-rule ODE**: `(sin∘arctan)′ = (cos∘arctan)·A′`, with `A′ = geomAlt`.
    `fcomp_chain` + `sin_fderiv` (sin′=cos, via `fcomp_congr_left`) + `arctan_fderiv` (A′=geomAlt). -/
theorem sinComp_deriv (k : Nat) :
    Qeq (fderiv (fcomp sinCoeff arctanCoeff) k) (fmul (fcomp cosCoeff arctanCoeff) geomAlt k) := by
  refine Qeq_trans
    (fmul_den_pos (fun i => fcomp_den_pos (fun j => fderiv_den_pos sinCoeff_den_pos j) arctanCoeff_den_pos i)
      (fun i => fderiv_den_pos arctanCoeff_den_pos i) k)
    (fcomp_chain sinCoeff arctanCoeff sinCoeff_den_pos arctanCoeff_den_pos arctanCoeff_zero k) ?_
  refine Qeq_trans
    (fmul_den_pos (fun i => fcomp_den_pos cosCoeff_den_pos arctanCoeff_den_pos i)
      (fun i => fderiv_den_pos arctanCoeff_den_pos i) k)
    (fmul_congr_left (fun i => fcomp_congr_left (b := arctanCoeff) sin_fderiv i) k)
    (fmul_congr_right (fun i => arctan_fderiv i) k)

/-- **The `cos∘arctan` chain-rule ODE**: `(cos∘arctan)′ = −(sin∘arctan)·A′`.
    `fcomp_chain` + `cos_fderiv` (cos′=−sin) + `fcomp_neg_left` (pull the sign out) + `arctan_fderiv`. -/
theorem cosComp_deriv (k : Nat) :
    Qeq (fderiv (fcomp cosCoeff arctanCoeff) k) (neg (fmul (fcomp sinCoeff arctanCoeff) geomAlt k)) := by
  refine Qeq_trans
    (fmul_den_pos (fun i => fcomp_den_pos (fun j => fderiv_den_pos cosCoeff_den_pos j) arctanCoeff_den_pos i)
      (fun i => fderiv_den_pos arctanCoeff_den_pos i) k)
    (fcomp_chain cosCoeff arctanCoeff cosCoeff_den_pos arctanCoeff_den_pos arctanCoeff_zero k) ?_
  -- fcomp (fderiv cosCoeff) arctanCoeff ≈ fcomp (neg sinCoeff) arctanCoeff ≈ neg (fcomp sinCoeff arctanCoeff)
  have hcomp : ∀ i, Qeq (fcomp (fderiv cosCoeff) arctanCoeff i) (neg (fcomp sinCoeff arctanCoeff i)) := by
    intro i
    refine Qeq_trans
      (fcomp_den_pos (fun j => neg_den_pos (sinCoeff_den_pos j)) arctanCoeff_den_pos i)
      (fcomp_congr_left (b := arctanCoeff) (fun j => cos_fderiv j) i)
      (fcomp_neg_left sinCoeff arctanCoeff sinCoeff_den_pos arctanCoeff_den_pos i)
  refine Qeq_trans
    (fmul_den_pos (fun i => neg_den_pos (fcomp_den_pos sinCoeff_den_pos arctanCoeff_den_pos i))
      (fun i => fderiv_den_pos arctanCoeff_den_pos i) k)
    (fmul_congr_left hcomp k) ?_
  -- fmul (neg (fcomp sin arctan)) (fderiv arctan) ≈ neg (fmul (fcomp sin arctan) geomAlt)
  refine Qeq_trans
    (fmul_den_pos (fun i => neg_den_pos (fcomp_den_pos sinCoeff_den_pos arctanCoeff_den_pos i))
      geomAlt_den_pos k)
    (fmul_congr_right (fun i => arctan_fderiv i) k) ?_
  exact fmul_neg_left (fcomp sinCoeff arctanCoeff) geomAlt
    (fun i => fcomp_den_pos sinCoeff_den_pos arctanCoeff_den_pos i) geomAlt_den_pos k

-- ===========================================================================
-- Sparse-convolution evaluation: extracting fmul against the identity series
-- (using the existing `Fsum_single` from ExpLog.lean).
-- ===========================================================================

/-- The **identity series** `X(t) = t`: coefficient `1` at degree `1`, else `0`. Multiplying by it
    shifts a series up one degree: `(X·H)(k+1) = H(k)`. -/
def Xident (k : Nat) : Q := if k = 1 then ⟨1, 1⟩ else ⟨0, 1⟩

theorem Xident_den_pos (k : Nat) : 0 < (Xident k).den := by unfold Xident; split <;> exact Nat.one_pos

/-- `(X·H)(0) ≈ 0`. -/
theorem fmul_Xident_zero (H : Nat → Q) : Qeq (fmul Xident H 0) ⟨0, 1⟩ := by
  show Qeq (mul (Xident 0) (H 0)) ⟨0, 1⟩
  unfold Xident; rw [if_neg (by omega)]; simp only [Qeq, mul]; omega

/-- **Shift law**: `(X·H)(k+1) ≈ H(k)` — multiplication by the identity series `X(t)=t`. Single nonzero
    convolution term at `i = 1` (via `Fsum_single`). -/
theorem fmul_Xident (H : Nat → Q) (hH : ∀ i, 0 < (H i).den) (k : Nat) :
    Qeq (fmul Xident H (k + 1)) (H k) := by
  show Qeq (Fsum (fun i => mul (Xident i) (H (k + 1 - i))) (k + 1)) (H k)
  refine Qeq_trans (Qmul_den_pos (Xident_den_pos 1) (hH (k + 1 - 1)))
    (Fsum_single (f := fun i => mul (Xident i) (H (k + 1 - i)))
      (fun i => Qmul_den_pos (Xident_den_pos i) (hH _)) (j := 1) ?_ (k := k + 1) (by omega)) ?_
  · intro i hi1
    show Qeq (mul (Xident i) (H (k + 1 - i))) ⟨0, 1⟩
    unfold Xident; rw [if_neg hi1]; simp only [Qeq, mul]; omega
  · show Qeq (mul (Xident 1) (H (k + 1 - 1))) (H k)
    rw [show k + 1 - 1 = k from by omega]
    unfold Xident; rw [if_pos rfl]
    simp only [Qeq, mul]; push_cast; ring_uor

/-- The **`1 + t²` series**: coefficient `1` at degrees `0` and `2`, else `0`. -/
def onePlusSq (k : Nat) : Q := if k = 0 then ⟨1, 1⟩ else if k = 2 then ⟨1, 1⟩ else ⟨0, 1⟩

/-- The **`t²` series**: coefficient `1` at degree `2`, else `0`. -/
def sq2 (k : Nat) : Q := if k = 2 then ⟨1, 1⟩ else ⟨0, 1⟩

theorem onePlusSq_den_pos (k : Nat) : 0 < (onePlusSq k).den := by
  unfold onePlusSq; split
  · exact Nat.one_pos
  · split <;> exact Nat.one_pos

theorem sq2_den_pos (k : Nat) : 0 < (sq2 k).den := by unfold sq2; split <;> exact Nat.one_pos

/-- Left unit for the formal Cauchy product: `fone · H ≈ H` (via `fmul_comm` + `fmul_one`). -/
theorem fmul_fone_left (H : Nat → Q) (hH : ∀ i, 0 < (H i).den) (k : Nat) :
    Qeq (fmul fone H k) (H k) :=
  Qeq_trans (fmul_den_pos hH (fun i => fone_den_pos i) k)
    (fmul_comm fone H (fun i => fone_den_pos i) hH k) (fmul_one H hH k)

/-- **Shift-by-two law**: `(t²·H)(k+2) ≈ H(k)`. Single nonzero convolution term at `i = 2`. -/
theorem fmul_sq2 (H : Nat → Q) (hH : ∀ i, 0 < (H i).den) (k : Nat) :
    Qeq (fmul sq2 H (k + 2)) (H k) := by
  show Qeq (Fsum (fun i => mul (sq2 i) (H (k + 2 - i))) (k + 2)) (H k)
  refine Qeq_trans (Qmul_den_pos (sq2_den_pos 2) (hH (k + 2 - 2)))
    (Fsum_single (f := fun i => mul (sq2 i) (H (k + 2 - i)))
      (fun i => Qmul_den_pos (sq2_den_pos i) (hH _)) (j := 2) ?_ (k := k + 2) (by omega)) ?_
  · intro i hi2
    show Qeq (mul (sq2 i) (H (k + 2 - i))) ⟨0, 1⟩
    unfold sq2; rw [if_neg hi2]; simp only [Qeq, mul]; omega
  · show Qeq (mul (sq2 2) (H (k + 2 - 2))) (H k)
    rw [show k + 2 - 2 = k from by omega]
    unfold sq2; rw [if_pos rfl]; simp only [Qeq, mul]; push_cast; ring_uor

/-- `onePlusSq ≈ fone + sq2` (pointwise) — the decomposition that splits its convolution. -/
theorem onePlusSq_decomp (i : Nat) : Qeq (onePlusSq i) (add (fone i) (sq2 i)) := by
  by_cases h0 : i = 0
  · subst h0; unfold onePlusSq fone sq2; decide
  · by_cases h2 : i = 2
    · subst h2; unfold onePlusSq fone sq2; decide
    · unfold onePlusSq fone sq2; simp only [if_neg h0, if_neg h2]; decide

/-- **The `(1+t²)·H` annihilation form**: `((1+t²)·H)(k+2) ≈ H(k+2) + H(k)`. Two nonzero convolution
    terms (`i = 0, 2`), extracted via the `fone + t²` decomposition. -/
theorem fmul_onePlusSq (H : Nat → Q) (hH : ∀ i, 0 < (H i).den) (k : Nat) :
    Qeq (fmul onePlusSq H (k + 2)) (add (H (k + 2)) (H k)) := by
  refine Qeq_trans
    (fmul_den_pos (fun i => add_den_pos (fone_den_pos i) (sq2_den_pos i)) hH (k + 2))
    (fmul_congr_left (fun i => onePlusSq_decomp i) (k + 2)) ?_
  refine Qeq_trans (add_den_pos (fmul_den_pos (fun i => fone_den_pos i) hH (k + 2))
      (fmul_den_pos (fun i => sq2_den_pos i) hH (k + 2)))
    (fmul_add_left (fun i => fone_den_pos i) (fun i => sq2_den_pos i) hH (k + 2)) ?_
  exact Qadd_congr (fmul_fone_left H hH (k + 2)) (fmul_sq2 H hH k)

/-- `((1+t²)·H)(0) ≈ H(0)`. -/
theorem fmul_onePlusSq_zero (H : Nat → Q) :
    Qeq (fmul onePlusSq H 0) (H 0) := by
  show Qeq (mul (onePlusSq 0) (H 0)) (H 0)
  unfold onePlusSq; rw [if_pos rfl]; simp only [Qeq, mul]; push_cast; ring_uor

/-- `((1+t²)·H)(1) ≈ H(1)`. -/
theorem fmul_onePlusSq_one (H : Nat → Q) (hH : ∀ i, 0 < (H i).den) :
    Qeq (fmul onePlusSq H 1) (H 1) := by
  show Qeq (add (mul (onePlusSq 0) (H 1)) (mul (onePlusSq 1) (H 0))) (H 1)
  have h0 : Qeq (mul (onePlusSq 0) (H 1)) (H 1) := by
    unfold onePlusSq; rw [if_pos rfl]; simp only [Qeq, mul]; push_cast; ring_uor
  have h1 : Qeq (mul (onePlusSq 1) (H 0)) ⟨0, 1⟩ := by
    unfold onePlusSq; rw [if_neg (by omega), if_neg (by omega)]; simp only [Qeq, mul]; omega
  exact Qeq_trans (add_den_pos (hH 1) (by decide))
    (Qadd_congr h0 h1) (Qadd_zero_right (H 1))

-- ===========================================================================
-- Formal ODE uniqueness:  (1+t²)·H′ = t·H  and  H(0)=0  imply  H = 0.
-- ===========================================================================

/-- **Strip a positive integer coefficient**: `c·x ≈ 0` with `c > 0` forces `x ≈ 0`. -/
theorem Qmul_pos_strip (c : Int) (hc : 0 < c) (x : Q) (h : Qeq (mul ⟨c, 1⟩ x) ⟨0, 1⟩) :
    Qeq x ⟨0, 1⟩ := by
  have hcx : c * x.num = 0 := by
    have hh : (c * x.num) * ((1 : Nat) : Int) = (0 : Int) * (((1 : Nat) * x.den : Nat) : Int) := h
    simpa using hh
  have hx0 : x.num = 0 := by
    rcases Int.mul_eq_zero.mp hcx with h1 | h1
    · omega
    · exact h1
  show x.num * ((1 : Nat) : Int) = 0 * ((x.den : Nat) : Int)
  rw [hx0]; simp

/-- `c·0 ≈ 0` for the formal scalar `⟨c,1⟩`. -/
theorem Qmul_const_zero (c : Int) (x : Q) (hx : Qeq x ⟨0, 1⟩) : Qeq (mul ⟨c, 1⟩ x) ⟨0, 1⟩ := by
  refine Qeq_trans (Qmul_den_pos Nat.one_pos Nat.one_pos) (Qmul_congr (Qeq_refl _) hx) ?_
  show Qeq (mul (⟨c, 1⟩ : Q) ⟨0, 1⟩) ⟨0, 1⟩
  simp only [Qeq, mul]; ring_uor

/-- From `a + b ≈ 0` and `b ≈ 0` conclude `a ≈ 0`. -/
theorem Qadd_right_zero_cancel (a b : Q) (ha : 0 < a.den) (hbd : 0 < b.den)
    (hab : Qeq (add a b) ⟨0, 1⟩) (hb : Qeq b ⟨0, 1⟩) : Qeq a ⟨0, 1⟩ := by
  have s1 : Qeq a (add a ⟨0, 1⟩) := Qeq_symm (Qadd_zero_right a)
  have s2 : Qeq (add a ⟨0, 1⟩) (add a b) := Qadd_congr (Qeq_refl a) (Qeq_symm hb)
  exact Qeq_trans (add_den_pos ha Nat.one_pos) s1
    (Qeq_trans (add_den_pos ha hbd) s2 hab)

/-- `fderiv H k ≈ 0` forces `H(k+1) ≈ 0` (strip the coefficient `k+1 > 0`). -/
theorem fderiv_strip (H : Nat → Q) (k : Nat) (h : Qeq (fderiv H k) ⟨0, 1⟩) :
    Qeq (H (k + 1)) ⟨0, 1⟩ :=
  Qmul_pos_strip ((k : Int) + 1) (by omega) (H (k + 1)) h

/-- **Formal ODE uniqueness**: if `H` satisfies the homogeneous ODE `(1+t²)·H′ ≈ t·H` (coefficientwise,
    `fmul onePlusSq (fderiv H) ≈ fmul Xident H`) and `H(0) ≈ 0`, then `H ≈ 0`. The coefficient recurrence
    `(k+3)·H(k+3) ≈ −k·H(k+1)` (with seeds `H(0)=H(1)=H(2)=0` from the low-degree relation) forces every
    coefficient to vanish — a triple-invariant induction. The discrete analog of `H′ = a·H, H(0)=0 ⟹ H=0`. -/
theorem ode_unique (H : Nat → Q) (hH : ∀ i, 0 < (H i).den) (hH0 : Qeq (H 0) ⟨0, 1⟩)
    (hrel : ∀ k, Qeq (fmul onePlusSq (fderiv H) k) (fmul Xident H k)) :
    ∀ k, Qeq (H k) ⟨0, 1⟩ := by
  have hfd : ∀ i, 0 < (fderiv H i).den := fun i => fderiv_den_pos hH i
  -- seed H 1: from the relation at 0
  have hfd0 : Qeq (fderiv H 0) ⟨0, 1⟩ :=
    Qeq_trans (fmul_den_pos onePlusSq_den_pos hfd 0)
      (Qeq_symm (fmul_onePlusSq_zero (fderiv H)))
      (Qeq_trans (fmul_den_pos Xident_den_pos hH 0) (hrel 0) (fmul_Xident_zero H))
  have hH1 : Qeq (H 1) ⟨0, 1⟩ := fderiv_strip H 0 hfd0
  -- seed H 2: from the relation at 1
  have hfd1 : Qeq (fderiv H 1) ⟨0, 1⟩ :=
    Qeq_trans (fmul_den_pos onePlusSq_den_pos hfd 1)
      (Qeq_symm (fmul_onePlusSq_one (fderiv H) hfd))
      (Qeq_trans (fmul_den_pos Xident_den_pos hH 1) (hrel 1)
        (Qeq_trans (hH 0) (fmul_Xident H hH 0) hH0))
  have hH2 : Qeq (H 2) ⟨0, 1⟩ := fderiv_strip H 1 hfd1
  -- recurrence: H(m+1) ≈ 0 ⟹ H(m+3) ≈ 0
  have hrec : ∀ m, Qeq (H (m + 1)) ⟨0, 1⟩ → Qeq (H (m + 3)) ⟨0, 1⟩ := by
    intro m hm1
    have hsum : Qeq (add (fderiv H (m + 2)) (fderiv H m)) ⟨0, 1⟩ :=
      Qeq_trans (fmul_den_pos onePlusSq_den_pos hfd (m + 2))
        (Qeq_symm (fmul_onePlusSq (fderiv H) hfd m))
        (Qeq_trans (fmul_den_pos Xident_den_pos hH (m + 2)) (hrel (m + 2))
          (Qeq_trans (hH (m + 1)) (fmul_Xident H hH (m + 1)) hm1))
    have hfdm : Qeq (fderiv H m) ⟨0, 1⟩ := Qmul_const_zero ((m : Int) + 1) (H (m + 1)) hm1
    have hfd2 : Qeq (fderiv H (m + 2)) ⟨0, 1⟩ :=
      Qadd_right_zero_cancel (fderiv H (m + 2)) (fderiv H m) (hfd (m + 2)) (hfd m) hsum hfdm
    exact fderiv_strip H (m + 2) hfd2
  -- triple-invariant induction
  have key : ∀ k, Qeq (H k) ⟨0, 1⟩ ∧ Qeq (H (k + 1)) ⟨0, 1⟩ ∧ Qeq (H (k + 2)) ⟨0, 1⟩ := by
    intro k
    induction k with
    | zero => exact ⟨hH0, hH1, hH2⟩
    | succ n ih => exact ⟨ih.2.1, ih.2.2, hrec n ih.2.1⟩
  intro k; exact (key k).1

/-- The formal Cauchy product is right-linear over negation: `a·(−b) ≈ −(a·b)`. -/
theorem fmul_neg_right (a b : Nat → Q) (ha : ∀ i, 0 < (a i).den) (hb : ∀ i, 0 < (b i).den) (k : Nat) :
    Qeq (fmul a (fun i => neg (b i)) k) (neg (fmul a b k)) := by
  refine Qeq_trans (fmul_den_pos (fun i => neg_den_pos (hb i)) ha k)
    (fmul_comm a (fun i => neg (b i)) ha (fun i => neg_den_pos (hb i)) k) ?_
  refine Qeq_trans (neg_den_pos (fmul_den_pos hb ha k)) (fmul_neg_left b a hb ha k) ?_
  exact Qneg_congr (fmul_comm b a hb ha k)

/-- `X² ≈ t²` (`fmul Xident Xident ≈ sq2`): both are `1` at degree `2`, else `0`. -/
theorem X_sq_eq_sq2 (k : Nat) : Qeq (fmul Xident Xident k) (sq2 k) := by
  by_cases h2 : k = 2
  · subst h2
    refine Qeq_trans (Qmul_den_pos (Xident_den_pos 1) (Xident_den_pos (2 - 1)))
      (Fsum_single (f := fun i => mul (Xident i) (Xident (2 - i)))
        (fun i => Qmul_den_pos (Xident_den_pos i) (Xident_den_pos _)) (j := 1) ?_ (k := 2) (by omega)) ?_
    · intro i hi1
      show Qeq (mul (Xident i) (Xident (2 - i))) ⟨0, 1⟩
      unfold Xident; rw [if_neg hi1]; simp only [Qeq, mul]; omega
    · show Qeq (mul (Xident 1) (Xident (2 - 1))) (sq2 2)
      unfold Xident sq2; rw [if_pos rfl, if_pos rfl]; decide
  · show Qeq (Fsum (fun i => mul (Xident i) (Xident (k - i))) k) (sq2 k)
    have hterm : ∀ i, i ≤ k → Qeq (mul (Xident i) (Xident (k - i))) ⟨0, 1⟩ := by
      intro i _
      by_cases hi1 : i = 1
      · subst hi1
        have hz : Xident (k - 1) = ⟨0, 1⟩ := by unfold Xident; rw [if_neg (by omega)]
        rw [hz]; simp only [Qeq, mul]; omega
      · unfold Xident; rw [if_neg hi1]; simp only [Qeq, mul]; omega
    have hzeros : Qeq (Fsum (fun i => mul (Xident i) (Xident (k - i))) k) ⟨0, 1⟩ :=
      Qeq_trans (Fsum_den_pos (fun _ => Nat.one_pos) k)
        (Fsum_congr_le (g := fun _ => (⟨0, 1⟩ : Q)) hterm) (Fsum_zeros k)
    have hsq2 : sq2 k = ⟨0, 1⟩ := by unfold sq2; rw [if_neg h2]
    rw [hsq2]; exact hzeros

/-- Formal derivative of a pointwise difference: `(S − T)′ = S′ − T′`. -/
theorem fderiv_sub (S T : Nat → Q) (k : Nat) :
    Qeq (fderiv (fun j => Qsub (S j) (T j)) k) (Qsub (fderiv S k) (fderiv T k)) :=
  Qmul_sub_distrib ⟨(k : Int) + 1, 1⟩ (S (k + 1)) (T (k + 1))

/-- Right distributivity of the formal Cauchy product over difference: `a·(b−c) ≈ a·b − a·c`
    (local, via `fmul_comm` + `fmul_sub_left`). -/
theorem fmul_subR (a b c : Nat → Q) (ha : ∀ i, 0 < (a i).den) (hb : ∀ i, 0 < (b i).den)
    (hc : ∀ i, 0 < (c i).den) (k : Nat) :
    Qeq (fmul a (fun i => Qsub (b i) (c i)) k) (Qsub (fmul a b k) (fmul a c k)) := by
  refine Qeq_trans (fmul_den_pos (fun i => Qsub_den_pos (hb i) (hc i)) ha k)
    (fmul_comm a (fun i => Qsub (b i) (c i)) ha (fun i => Qsub_den_pos (hb i) (hc i)) k) ?_
  refine Qeq_trans (Qsub_den_pos (fmul_den_pos hb ha k) (fmul_den_pos hc ha k))
    (fmul_sub_left hb hc ha k) ?_
  exact QsubCongr (fmul_comm b a hb ha k) (fmul_comm c a hc ha k)

/-- The Q-algebra rearrangement at the heart of the ODE relation: `a − ((a + b) − c) ≈ c − b`. -/
theorem Qalg1 (a b c : Q) : Qeq (Qsub a (add (add a b) (neg c))) (Qsub c b) := by
  simp only [Qeq, Qsub, add, neg, mul]; push_cast; ring_uor

/-- The identity series is its own antiderivative's derivative: `X′ = 1` (`fderiv Xident ≈ fone`). -/
theorem Xident_fderiv (k : Nat) : Qeq (fderiv Xident k) (fone k) := by
  by_cases h0 : k = 0
  · subst h0
    show Qeq (mul ⟨(0 : Int) + 1, 1⟩ (Xident 1)) (fone 0)
    unfold Xident fone; rw [if_pos rfl, if_pos rfl]; decide
  · show Qeq (mul ⟨(k : Int) + 1, 1⟩ (Xident (k + 1))) (fone k)
    unfold Xident fone; rw [if_neg (by omega : ¬ k + 1 = 1), if_neg h0]
    simp only [Qeq, mul]; push_cast; ring_uor

/-- **`(1+t²)·A′ = 1`**: `fmul onePlusSq geomAlt ≈ fone` — the formal statement that `geomAlt` is the
    reciprocal `1/(1+t²)`. From `geomAlt_recurrence` (degree `≥ 2`) and the boundary values. -/
theorem onePlusSq_geomAlt : ∀ k, Qeq (fmul onePlusSq geomAlt k) (fone k)
  | 0 => by
      have h := fmul_onePlusSq_zero geomAlt
      rw [geomAlt_zero] at h; exact h
  | 1 => by
      have h := fmul_onePlusSq_one geomAlt geomAlt_den_pos
      rw [geomAlt_one] at h; exact h
  | (m + 2) => by
      have h := fmul_onePlusSq geomAlt geomAlt_den_pos m
      exact Qeq_trans (add_den_pos (geomAlt_den_pos (m + 2)) (geomAlt_den_pos m)) h
        (geomAlt_recurrence m)

/-- **Absorption**: `(1+t²)·(P·A′) ≈ P` — since `(1+t²)·A′ = 1` (`onePlusSq_geomAlt`). The key
    simplification in the `G`-ODE derivation: `(1+t²)·(C·geomAlt) = C`, etc. -/
theorem absorb_onePlusSq_geomAlt (P : Nat → Q) (hP : ∀ i, 0 < (P i).den) (k : Nat) :
    Qeq (fmul onePlusSq (fmul P geomAlt) k) (P k) := by
  refine Qeq_trans (fmul_den_pos (fun i => fmul_den_pos hP geomAlt_den_pos i) onePlusSq_den_pos k)
    (fmul_comm onePlusSq (fmul P geomAlt) onePlusSq_den_pos
      (fun i => fmul_den_pos hP geomAlt_den_pos i) k) ?_
  refine Qeq_trans (fmul_den_pos hP (fun i => fmul_den_pos geomAlt_den_pos onePlusSq_den_pos i) k)
    (fmul_assoc P geomAlt onePlusSq hP geomAlt_den_pos onePlusSq_den_pos k) ?_
  refine Qeq_trans (fmul_den_pos hP (fun i => fone_den_pos i) k)
    (fmul_congr_right (b := fmul geomAlt onePlusSq) (b' := fone)
      (fun i => Qeq_trans (fmul_den_pos onePlusSq_den_pos geomAlt_den_pos i)
        (fmul_comm geomAlt onePlusSq geomAlt_den_pos onePlusSq_den_pos i) (onePlusSq_geomAlt i)) k) ?_
  exact fmul_one P hP k

-- ===========================================================================
-- The formal identity  sin∘arctan = t·(cos∘arctan)  via ode_unique on G = S − t·C.
-- ===========================================================================

/-- **Derivative of `t·(cos∘arctan)`**: `(X·C)′ ≈ C + (−((X·S)·A′))` — product rule `(X·C)′ = X′·C + X·C′`
    with `X′ = 1`, `C′ = −(S·A′)` (`cosComp_deriv`), and the associativity `X·(S·A′) = (X·S)·A′`. -/
theorem Gseq_fderivT (i : Nat) :
    Qeq (fderiv (fmul Xident (fcomp cosCoeff arctanCoeff)) i)
      (add (fcomp cosCoeff arctanCoeff i)
        (neg (fmul (fmul Xident (fcomp sinCoeff arctanCoeff)) geomAlt i))) := by
  have hS : ∀ j, 0 < (fcomp sinCoeff arctanCoeff j).den :=
    fun j => fcomp_den_pos sinCoeff_den_pos arctanCoeff_den_pos j
  have hC : ∀ j, 0 < (fcomp cosCoeff arctanCoeff j).den :=
    fun j => fcomp_den_pos cosCoeff_den_pos arctanCoeff_den_pos j
  have hSg : ∀ j, 0 < (fmul (fcomp sinCoeff arctanCoeff) geomAlt j).den :=
    fun j => fmul_den_pos hS geomAlt_den_pos j
  have part1 : Qeq (fmul (fderiv Xident) (fcomp cosCoeff arctanCoeff) i) (fcomp cosCoeff arctanCoeff i) :=
    Qeq_trans (fmul_den_pos (fun j => fone_den_pos j) hC i)
      (fmul_congr_left (fun j => Xident_fderiv j) i) (fmul_fone_left (fcomp cosCoeff arctanCoeff) hC i)
  have part2 : Qeq (fmul Xident (fderiv (fcomp cosCoeff arctanCoeff)) i)
      (neg (fmul (fmul Xident (fcomp sinCoeff arctanCoeff)) geomAlt i)) :=
    Qeq_trans (fmul_den_pos Xident_den_pos (fun j => neg_den_pos (hSg j)) i)
      (fmul_congr_right (fun j => cosComp_deriv j) i)
      (Qeq_trans (neg_den_pos (fmul_den_pos Xident_den_pos hSg i))
        (fmul_neg_right Xident (fmul (fcomp sinCoeff arctanCoeff) geomAlt) Xident_den_pos hSg i)
        (Qneg_congr (Qeq_symm
          (fmul_assoc Xident (fcomp sinCoeff arctanCoeff) geomAlt Xident_den_pos hS geomAlt_den_pos i))))
  exact Qeq_trans
    (add_den_pos (fmul_den_pos (fun j => fderiv_den_pos Xident_den_pos j) hC i)
      (fmul_den_pos Xident_den_pos (fun j => fderiv_den_pos hC j) i))
    (fderiv_fmul Xident (fcomp cosCoeff arctanCoeff) Xident_den_pos hC i)
    (Qadd_congr part1 part2)

/-- `G = sin∘arctan − t·(cos∘arctan)` — the difference whose vanishing is the formal identity. -/
def Gseq (j : Nat) : Q :=
  Qsub (fcomp sinCoeff arctanCoeff j) (fmul Xident (fcomp cosCoeff arctanCoeff) j)

theorem Gseq_den_pos (i : Nat) : 0 < (Gseq i).den :=
  Qsub_den_pos (fcomp_den_pos sinCoeff_den_pos arctanCoeff_den_pos i)
    (fmul_den_pos Xident_den_pos (fun j => fcomp_den_pos cosCoeff_den_pos arctanCoeff_den_pos j) i)

/-- `G(0) ≈ 0`: `sin∘arctan` and `t·(cos∘arctan)` both vanish at degree 0. -/
theorem Gseq_zero : Qeq (Gseq 0) ⟨0, 1⟩ := by
  have hA : Qeq (fcomp sinCoeff arctanCoeff 0) ⟨0, 1⟩ :=
    Qeq_trans (sinCoeff_den_pos 0) (fcomp_const sinCoeff arctanCoeff) (by decide)
  have hB : Qeq (fmul Xident (fcomp cosCoeff arctanCoeff) 0) ⟨0, 1⟩ :=
    fmul_Xident_zero (fcomp cosCoeff arctanCoeff)
  exact Qeq_trans (Qsub_den_pos (by decide) (by decide)) (QsubCongr hA hB) (by decide)

/-- **The `G`-ODE relation**: `(1+t²)·G′ ≈ t·G`. Both sides reduce to `X·S − t²·C`: the RHS by
    distributing `X` and `X² = t²`; the LHS by the chain-rule derivatives, the absorption
    `(1+t²)·(P·A′) = P`, and the algebra `a − ((a+b)−c) = c − b`. -/
theorem Gseq_ode (k : Nat) : Qeq (fmul onePlusSq (fderiv Gseq) k) (fmul Xident Gseq k) := by
  show Qeq (fmul onePlusSq
      (fderiv (fun j => Qsub (fcomp sinCoeff arctanCoeff j)
        (fmul Xident (fcomp cosCoeff arctanCoeff) j))) k)
    (fmul Xident (fun j => Qsub (fcomp sinCoeff arctanCoeff j)
      (fmul Xident (fcomp cosCoeff arctanCoeff) j)) k)
  have hS : ∀ j, 0 < (fcomp sinCoeff arctanCoeff j).den :=
    fun j => fcomp_den_pos sinCoeff_den_pos arctanCoeff_den_pos j
  have hC : ∀ j, 0 < (fcomp cosCoeff arctanCoeff j).den :=
    fun j => fcomp_den_pos cosCoeff_den_pos arctanCoeff_den_pos j
  have hT : ∀ j, 0 < (fmul Xident (fcomp cosCoeff arctanCoeff) j).den :=
    fun j => fmul_den_pos Xident_den_pos hC j
  have hXS : ∀ j, 0 < (fmul Xident (fcomp sinCoeff arctanCoeff) j).den :=
    fun j => fmul_den_pos Xident_den_pos hS j
  have hsq2C : ∀ j, 0 < (fmul sq2 (fcomp cosCoeff arctanCoeff) j).den :=
    fun j => fmul_den_pos sq2_den_pos hC j
  have hfdS : ∀ j, 0 < (fderiv (fcomp sinCoeff arctanCoeff) j).den := fun j => fderiv_den_pos hS j
  have hfdT : ∀ j, 0 < (fderiv (fmul Xident (fcomp cosCoeff arctanCoeff)) j).den :=
    fun j => fderiv_den_pos hT j
  have hCg : ∀ j, 0 < (fmul (fcomp cosCoeff arctanCoeff) geomAlt j).den :=
    fun j => fmul_den_pos hC geomAlt_den_pos j
  have hXSg : ∀ j, 0 < (fmul (fmul Xident (fcomp sinCoeff arctanCoeff)) geomAlt j).den :=
    fun j => fmul_den_pos hXS geomAlt_den_pos j
  -- abbreviation: the common middle form M = X·S − t²·C
  -- RHS : fmul Xident Gseq k ≈ M
  have hRHS : Qeq (fmul Xident (fun j => Qsub (fcomp sinCoeff arctanCoeff j)
        (fmul Xident (fcomp cosCoeff arctanCoeff) j)) k)
      (Qsub (fmul Xident (fcomp sinCoeff arctanCoeff) k) (fmul sq2 (fcomp cosCoeff arctanCoeff) k)) := by
    have hTeq : Qeq (fmul Xident (fmul Xident (fcomp cosCoeff arctanCoeff)) k)
        (fmul sq2 (fcomp cosCoeff arctanCoeff) k) :=
      Qeq_trans (fmul_den_pos (fun j => fmul_den_pos Xident_den_pos Xident_den_pos j) hC k)
        (Qeq_symm (fmul_assoc Xident Xident (fcomp cosCoeff arctanCoeff) Xident_den_pos Xident_den_pos hC k))
        (fmul_congr_left (fun j => X_sq_eq_sq2 j) k)
    refine Qeq_trans (Qsub_den_pos (hXS k) (fmul_den_pos Xident_den_pos hT k))
      (fmul_subR Xident (fcomp sinCoeff arctanCoeff) (fmul Xident (fcomp cosCoeff arctanCoeff))
        Xident_den_pos hS hT k) ?_
    exact QsubCongr (Qeq_refl _) hTeq
  -- LHS : fmul onePlusSq (fderiv Gseq) k ≈ M
  have hLHS : Qeq (fmul onePlusSq
        (fderiv (fun j => Qsub (fcomp sinCoeff arctanCoeff j)
          (fmul Xident (fcomp cosCoeff arctanCoeff) j))) k)
      (Qsub (fmul Xident (fcomp sinCoeff arctanCoeff) k) (fmul sq2 (fcomp cosCoeff arctanCoeff) k)) := by
    -- fderiv Gseq ≈ Qsub (fderiv S)(fderiv T)
    have hLd : Qeq (fmul onePlusSq
          (fderiv (fun j => Qsub (fcomp sinCoeff arctanCoeff j)
            (fmul Xident (fcomp cosCoeff arctanCoeff) j))) k)
        (Qsub (fmul onePlusSq (fderiv (fcomp sinCoeff arctanCoeff)) k)
          (fmul onePlusSq (fderiv (fmul Xident (fcomp cosCoeff arctanCoeff))) k)) := by
      refine Qeq_trans (fmul_den_pos onePlusSq_den_pos
          (fun j => Qsub_den_pos (hfdS j) (hfdT j)) k)
        (fmul_congr_right
          (b := fderiv (fun j => Qsub (fcomp sinCoeff arctanCoeff j)
            (fmul Xident (fcomp cosCoeff arctanCoeff) j)))
          (b' := fun j => Qsub (fderiv (fcomp sinCoeff arctanCoeff) j)
            (fderiv (fmul Xident (fcomp cosCoeff arctanCoeff)) j))
          (fun j => fderiv_sub (fcomp sinCoeff arctanCoeff)
            (fmul Xident (fcomp cosCoeff arctanCoeff)) j) k) ?_
      exact fmul_subR onePlusSq (fderiv (fcomp sinCoeff arctanCoeff))
        (fderiv (fmul Xident (fcomp cosCoeff arctanCoeff))) onePlusSq_den_pos hfdS hfdT k
    -- term1 : (1+t²)·S′ ≈ C
    have hT1 : Qeq (fmul onePlusSq (fderiv (fcomp sinCoeff arctanCoeff)) k) (fcomp cosCoeff arctanCoeff k) :=
      Qeq_trans (fmul_den_pos onePlusSq_den_pos hCg k)
        (fmul_congr_right (fun j => sinComp_deriv j) k)
        (absorb_onePlusSq_geomAlt (fcomp cosCoeff arctanCoeff) hC k)
    -- term2 : (1+t²)·T′ ≈ (C + t²·C) − X·S
    have hT2 : Qeq (fmul onePlusSq (fderiv (fmul Xident (fcomp cosCoeff arctanCoeff))) k)
        (add (add (fcomp cosCoeff arctanCoeff k) (fmul sq2 (fcomp cosCoeff arctanCoeff) k))
          (neg (fmul Xident (fcomp sinCoeff arctanCoeff) k))) := by
      -- (1+t²)·T′ ≈ (1+t²)·(C + (−((X·S)·A′)))
      refine Qeq_trans (fmul_den_pos onePlusSq_den_pos
          (fun j => add_den_pos (hC j) (neg_den_pos (hXSg j))) k)
        (fmul_congr_right (fun j => Gseq_fderivT j) k) ?_
      -- distribute over add
      refine Qeq_trans (add_den_pos (fmul_den_pos onePlusSq_den_pos hC k)
          (fmul_den_pos onePlusSq_den_pos (fun j => neg_den_pos (hXSg j)) k))
        (fmul_add_right onePlusSq_den_pos hC (fun j => neg_den_pos (hXSg j)) k) ?_
      refine Qadd_congr ?_ ?_
      · -- (1+t²)·C ≈ C + t²·C
        refine Qeq_trans (add_den_pos (fmul_den_pos (fun j => fone_den_pos j) hC k)
            (fmul_den_pos sq2_den_pos hC k))
          (Qeq_trans (fmul_den_pos (fun j => add_den_pos (fone_den_pos j) (sq2_den_pos j)) hC k)
            (fmul_congr_left (fun j => onePlusSq_decomp j) k)
            (fmul_add_left (fun j => fone_den_pos j) (fun j => sq2_den_pos j) hC k)) ?_
        exact Qadd_congr (fmul_fone_left (fcomp cosCoeff arctanCoeff) hC k) (Qeq_refl _)
      · -- (1+t²)·(−((X·S)·A′)) ≈ −(X·S)
        refine Qeq_trans (neg_den_pos (fmul_den_pos onePlusSq_den_pos
            (fun j => fmul_den_pos hXS geomAlt_den_pos j) k))
          (fmul_neg_right onePlusSq (fmul (fmul Xident (fcomp sinCoeff arctanCoeff)) geomAlt)
            onePlusSq_den_pos hXSg k) ?_
        exact Qneg_congr (absorb_onePlusSq_geomAlt (fmul Xident (fcomp sinCoeff arctanCoeff)) hXS k)
    -- combine: Qsub C ((C+t²C) − X·S) ≈ X·S − t²·C  via Qalg1
    refine Qeq_trans (Qsub_den_pos (hC k)
        (add_den_pos (add_den_pos (hC k) (hsq2C k)) (neg_den_pos (hXS k))))
      (Qeq_trans (Qsub_den_pos (fmul_den_pos onePlusSq_den_pos hfdS k)
          (fmul_den_pos onePlusSq_den_pos hfdT k))
        hLd (QsubCongr hT1 hT2)) ?_
    exact Qalg1 (fcomp cosCoeff arctanCoeff k) (fmul sq2 (fcomp cosCoeff arctanCoeff) k)
      (fmul Xident (fcomp sinCoeff arctanCoeff) k)
  exact Qeq_trans (Qsub_den_pos (hXS k) (hsq2C k)) hLHS (Qeq_symm hRHS)

/-- **★ The formal identity `sin∘arctan = t·(cos∘arctan)`**: `fcomp sinCoeff arctanCoeff ≈
    fmul Xident (fcomp cosCoeff arctanCoeff)`. The formal-power-series shadow of `tan(arctan t) = t`,
    obtained by `ode_unique` on `G = S − t·C` (which satisfies `(1+t²)G′ = t·G`, `G(0)=0`). -/
theorem sin_arctan_eq (k : Nat) :
    Qeq (fcomp sinCoeff arctanCoeff k) (fmul Xident (fcomp cosCoeff arctanCoeff) k) :=
  Qeq_of_Qsub_zero (ode_unique Gseq Gseq_den_pos Gseq_zero Gseq_ode k)

-- ===========================================================================
-- Value-bridge entry points: the formal identity at the `peval` (evaluation) level,
-- and the composition swaps `peval (sin∘arctan) = Σₘ sinₘ·peval(arctanᵐ)`. The remaining
-- step toward `Rsin(arctan t) = t·Rcos(arctan t)` is the composition-series convergence
-- (`peval (fpow arctanCoeff m) t M → (arctan-value)ᵐ`, summed against `sinCoeff`), for which
-- ExpLog provides the general infrastructure: `peval_fcomp_swap`, `peval_fpow_abs_bound`,
-- `peval_mul`/`peval_fpow_succ`, and the `per_m_step` error-recursion pattern.
-- ===========================================================================

/-- **Value-level form of the formal identity**: the composed series `sin∘arctan` and
    `t·(cos∘arctan)`, evaluated at any rational `t` and truncated at `M`, agree (`peval_congr` on
    `sin_arctan_eq`). The entry point of the formal-PS → value bridge. -/
theorem peval_sin_arctan_eq (t : Q) (M : Nat) :
    Qeq (peval (fcomp sinCoeff arctanCoeff) t M)
      (peval (fmul Xident (fcomp cosCoeff arctanCoeff)) t M) :=
  peval_congr (fun k => sin_arctan_eq k) t M

/-- **Composition swap for `sin∘arctan`**: `peval(sin∘arctan, t, M) = Σ_{m≤M} sinₘ·peval(arctanᵐ, t, M)`
    — the finite rearrangement (`peval_fcomp_swap`) expressing the composed series as the `sin` series
    evaluated at the `arctan` powers. -/
theorem peval_sinComp_swap (t : Q) (htd : 0 < t.den) (M : Nat) :
    Qeq (peval (fcomp sinCoeff arctanCoeff) t M)
      (Fsum (fun m => mul (sinCoeff m) (peval (fpow arctanCoeff m) t M)) M) :=
  peval_fcomp_swap sinCoeff arctanCoeff sinCoeff_den_pos arctanCoeff_den_pos arctanCoeff_zero t htd M

/-- **Composition swap for `cos∘arctan`**: `peval(cos∘arctan, t, M) = Σ_{m≤M} cosₘ·peval(arctanᵐ, t, M)`. -/
theorem peval_cosComp_swap (t : Q) (htd : 0 < t.den) (M : Nat) :
    Qeq (peval (fcomp cosCoeff arctanCoeff) t M)
      (Fsum (fun m => mul (cosCoeff m) (peval (fpow arctanCoeff m) t M)) M) :=
  peval_fcomp_swap cosCoeff arctanCoeff cosCoeff_den_pos arctanCoeff_den_pos arctanCoeff_zero t htd M

/-- `|(−1)ⁿ| = 1`: the alternating sign series has unit absolute value at every power. -/
theorem qpow_neg_one_abs (n : Nat) : Qabs (qpow (⟨-1, 1⟩ : Q) n) = ⟨1, 1⟩ := by
  induction n with
  | zero => rfl
  | succ m ih => rw [qpow_succ, Qabs_mul, ih]; rfl

-- ===========================================================================
-- General per-m convergence: |peval(bᵐ,w,M) − (peval b w M)ᵐ| ≤ Σ |cornerⱼ|.
-- (Compares the truncated power-of-series to the power of the truncated series — the
-- partial-sum comparison that the NON-rational arctan series needs, vs the doubling's
-- rational-limit `uval`. The recursion eₘ₊₁ = q·eₘ − cornerₘ has no q−u term.)
-- ===========================================================================

/-- The general truncation corner of `peval (fpow b (m+1))` (the `peval_fpow_succ` defect; `kcorner`
    with `b` in place of `kdbl`). -/
def gcornerB (b : Nat → Q) (w : Q) (m M : Nat) : Q :=
  Fsum (fun i => Qsub
    (Fsum (fun j => mul (mul (b i) (qpow w i)) (mul (fpow b m j) (qpow w j))) M)
    (Fsum (fun j => mul (mul (b i) (qpow w i)) (mul (fpow b m j) (qpow w j))) (M - i))) M

theorem gcornerB_den (b : Nat → Q) (hb : ∀ i, 0 < (b i).den) (w : Q) (hwd : 0 < w.den) (m M : Nat) :
    0 < (gcornerB b w m M).den :=
  Fsum_den_pos (fun i => Qsub_den_pos
    (Fsum_den_pos (fun j => Qmul_den_pos (Qmul_den_pos (hb i) (qpow_den_pos hwd i))
      (Qmul_den_pos (fpow_den_pos hb m j) (qpow_den_pos hwd j))) M)
    (Fsum_den_pos (fun j => Qmul_den_pos (Qmul_den_pos (hb i) (qpow_den_pos hwd i))
      (Qmul_den_pos (fpow_den_pos hb m j) (qpow_den_pos hwd j))) (M - i))) M

/-- The error-recursion algebra: `(q·p − c) − q·r = q·(p − r) − c`. -/
theorem e_rec_alg2 (q p r c : Q) :
    Qeq (Qsub (Qsub (mul q p) c) (mul q r)) (Qsub (mul q (Qsub p r)) c) := by
  simp only [Qeq, Qsub, add, neg, mul]; push_cast; ring_uor

/-- **Per-`m` error step**: `|eₘ₊₁| ≤ |q|·|eₘ| + |cornerₘ|`, where `eₖ = peval(bᵏ,w,M) − qᵏ`,
    `q = peval b w M`. From `peval_fpow_succ` (= `q·peval(bᵐ) − corner`) and `e_rec_alg2`. -/
theorem gen_per_m_step (b : Nat → Q) (hb : ∀ i, 0 < (b i).den) (w : Q) (hwd : 0 < w.den) (m M : Nat) :
    Qle (Qabs (Qsub (peval (fpow b (m + 1)) w M) (qpow (peval b w M) (m + 1))))
      (add (mul (Qabs (peval b w M))
              (Qabs (Qsub (peval (fpow b m) w M) (qpow (peval b w M) m))))
        (Qabs (gcornerB b w m M))) := by
  have hq : 0 < (peval b w M).den := peval_den_pos hb hwd M
  have hpm : 0 < (peval (fpow b m) w M).den := peval_den_pos (fpow_den_pos hb m) hwd M
  have hqm : 0 < (qpow (peval b w M) m).den := qpow_den_pos hq m
  have hem : 0 < (Qsub (peval (fpow b m) w M) (qpow (peval b w M) m)).den := Qsub_den_pos hpm hqm
  have hcor : 0 < (gcornerB b w m M).den := gcornerB_den b hb w hwd m M
  have hid : Qeq (Qsub (peval (fpow b (m + 1)) w M) (qpow (peval b w M) (m + 1)))
      (Qsub (mul (peval b w M) (Qsub (peval (fpow b m) w M) (qpow (peval b w M) m)))
        (gcornerB b w m M)) := by
    rw [qpow_succ]
    exact Qeq_trans
      (Qsub_den_pos (Qsub_den_pos (Qmul_den_pos hq hpm) hcor) (Qmul_den_pos hq hqm))
      (Qsub_congr (peval_fpow_succ b hb w hwd m M) (Qeq_refl _))
      (e_rec_alg2 (peval b w M) (peval (fpow b m) w M) (qpow (peval b w M) m) (gcornerB b w m M))
  refine Qle_trans (Qabs_den_pos (Qsub_den_pos (Qmul_den_pos hq hem) hcor))
    (Qeq_le (Qabs_Qeq hid)) ?_
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qmul_den_pos hq hem)) (Qabs_den_pos hcor))
    (Qabs_sub_le_add _ _) ?_
  exact Qadd_le_add (Qeq_le (by rw [Qabs_mul]; exact Qeq_refl _ :
    Qeq (Qabs (mul (peval b w M) (Qsub (peval (fpow b m) w M) (qpow (peval b w M) m))))
      (mul (Qabs (peval b w M)) (Qabs (Qsub (peval (fpow b m) w M) (qpow (peval b w M) m))))))
    (Qle_refl _)

/-- **Per-`m` error bound**: `|peval(bᵐ⁺¹,w,M) − qᵐ⁺¹| ≤ Σ_{j≤m} |cornerⱼ|` for `q = peval b w M` with
    `|q| ≤ 1`. By induction via `gen_per_m_step` (the `|q|·|eₘ| ≤ |eₘ|` contraction). -/
theorem gen_per_m_bound (b : Nat → Q) (hb : ∀ i, 0 < (b i).den) (w : Q) (hwd : 0 < w.den) (M : Nat)
    (hq1 : Qle (Qabs (peval b w M)) ⟨1, 1⟩) (m : Nat) :
    Qle (Qabs (Qsub (peval (fpow b (m + 1)) w M) (qpow (peval b w M) (m + 1))))
      (Fsum (fun j => Qabs (gcornerB b w j M)) m) := by
  have hq : 0 < (peval b w M).den := peval_den_pos hb hwd M
  have hpd : ∀ k, 0 < (peval (fpow b k) w M).den :=
    fun k => peval_den_pos (fpow_den_pos hb k) hwd M
  have hqm : ∀ k, 0 < (qpow (peval b w M) k).den := fun k => qpow_den_pos hq k
  have bound1 : ∀ {e : Q}, 0 < e.den → Qle (mul (Qabs (peval b w M)) (Qabs e)) (Qabs e) :=
    fun {e} he => Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos he))
      (Qmul_le_mul_right (Qabs_num_nonneg _) hq1) (Qeq_le (Qone_mul _))
  induction m with
  | zero =>
      have hz : Qeq (Qsub (peval (fpow b 0) w M) (qpow (peval b w M) 0)) ⟨0, 1⟩ := by
        show Qeq (Qsub (peval fone w M) ⟨1, 1⟩) ⟨0, 1⟩
        refine Qeq_trans (Qsub_den_pos Nat.one_pos Nat.one_pos)
          (Qsub_congr (peval_fone w hwd M) (Qeq_refl _)) ?_
        simp [Qeq, Qsub, add, neg]
      have he0 : Qle (Qabs (Qsub (peval (fpow b 0) w M) (qpow (peval b w M) 0))) ⟨0, 1⟩ :=
        Qeq_le (Qeq_trans Nat.one_pos (Qabs_Qeq hz) (by decide : Qeq (Qabs (⟨0, 1⟩ : Q)) ⟨0, 1⟩))
      show Qle (Qabs (Qsub (peval (fpow b 1) w M) (qpow (peval b w M) 1)))
        (Qabs (gcornerB b w 0 M))
      refine Qle_trans (add_den_pos (Qmul_den_pos (Qabs_den_pos hq)
          (Qabs_den_pos (Qsub_den_pos (hpd 0) (hqm 0)))) (Qabs_den_pos (gcornerB_den b hb w hwd 0 M)))
        (gen_per_m_step b hb w hwd 0 M) ?_
      refine Qle_trans (add_den_pos Nat.one_pos (Qabs_den_pos (gcornerB_den b hb w hwd 0 M)))
        (Qadd_le_add (Qle_trans (Qabs_den_pos (Qsub_den_pos (hpd 0) (hqm 0)))
          (bound1 (Qsub_den_pos (hpd 0) (hqm 0))) he0) (Qle_refl _)) ?_
      exact Qeq_le (Qzero_add _)
  | succ m ih =>
      refine Qle_trans (add_den_pos (Qmul_den_pos (Qabs_den_pos hq)
          (Qabs_den_pos (Qsub_den_pos (hpd (m + 1)) (hqm (m + 1)))))
          (Qabs_den_pos (gcornerB_den b hb w hwd (m + 1) M)))
        (gen_per_m_step b hb w hwd (m + 1) M) ?_
      refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (hpd (m + 1)) (hqm (m + 1))))
          (Qabs_den_pos (gcornerB_den b hb w hwd (m + 1) M)))
        (Qadd_le_add (bound1 (Qsub_den_pos (hpd (m + 1)) (hqm (m + 1)))) (Qle_refl _)) ?_
      exact Qadd_le_add ih (Qle_refl _)

-- ===========================================================================
-- Bridge to the existing arctan real: peval arctanCoeff = arctanSum (hence RarctanR).
-- ===========================================================================

/-- The odd-degree term of `peval arctanCoeff` is the `arctan` series term: `arctanCoeff_{2n+1}·t^{2n+1}
    ≈ arctanTerm t n` (both `(−1)ⁿ·t^{2n+1}/(2n+1)`). -/
theorem arctanCoeff_term_odd (t : Q) (n : Nat) :
    Qeq (mul (arctanCoeff (2 * n + 1)) (qpow t (2 * n + 1))) (arctanTerm t n) := by
  unfold arctanCoeff arctanTerm artTerm
  rw [if_pos (by omega : (2 * n + 1) % 2 = 1), show (2 * n + 1) / 2 = n from by omega]
  simp only [Qeq, mul]; push_cast; ring_uor

/-- The even-degree term of `peval arctanCoeff` vanishes: `arctanCoeff_{2n+2}·t^{2n+2} ≈ 0`. -/
theorem arctanCoeff_term_even (t : Q) (n : Nat) :
    Qeq (mul (arctanCoeff (2 * n + 2)) (qpow t (2 * n + 2))) ⟨0, 1⟩ := by
  unfold arctanCoeff
  rw [if_neg (by omega : ¬ (2 * n + 2) % 2 = 1)]
  show Qeq (mul (⟨0, 1⟩ : Q) (qpow t (2 * n + 2))) ⟨0, 1⟩
  simp only [Qeq, mul]; omega

/-- **Bridge to `arctanSum`**: `peval arctanCoeff t (2N+1) ≈ arctanSum t N` — the degree-indexed
    power-series evaluation of the `arctan` coefficients IS the `n`-indexed `arctan` partial sum (even
    terms vanish, odd terms `= arctanTerm`). Connects the formal-PS machinery to `RarctanR`. -/
theorem peval_arctanCoeff_eq_arctanSum (t : Q) (htd : 0 < t.den) (N : Nat) :
    Qeq (peval arctanCoeff t (2 * N + 1)) (arctanSum t N) := by
  have hg : ∀ k, 0 < (mul (arctanCoeff k) (qpow t k)).den :=
    fun k => Qmul_den_pos (arctanCoeff_den_pos k) (qpow_den_pos htd k)
  induction N with
  | zero =>
    show Qeq (add (mul (arctanCoeff 0) (qpow t 0)) (mul (arctanCoeff 1) (qpow t 1))) (arctanTerm t 0)
    have he : Qeq (mul (arctanCoeff 0) (qpow t 0)) ⟨0, 1⟩ := by
      have h0 : arctanCoeff 0 = ⟨0, 1⟩ := by unfold arctanCoeff; rw [if_neg (by decide)]
      rw [h0]; simp only [Qeq, mul]; omega
    exact Qeq_trans (add_den_pos Nat.one_pos (arctanTerm_den_pos htd 0))
      (Qadd_congr he (arctanCoeff_term_odd t 0)) (Qzero_add (arctanTerm t 0))
  | succ n ih =>
    rw [show 2 * (n + 1) + 1 = 2 * n + 1 + 1 + 1 from by omega]
    show Qeq (add (add (peval arctanCoeff t (2 * n + 1)) (mul (arctanCoeff (2 * n + 2)) (qpow t (2 * n + 2))))
        (mul (arctanCoeff (2 * n + 3)) (qpow t (2 * n + 3))))
      (add (arctanSum t n) (arctanTerm t (n + 1)))
    have ho : Qeq (mul (arctanCoeff (2 * n + 3)) (qpow t (2 * n + 3))) (arctanTerm t (n + 1)) := by
      have h := arctanCoeff_term_odd t (n + 1)
      rwa [show 2 * (n + 1) + 1 = 2 * n + 3 from by omega] at h
    refine Qeq_trans (add_den_pos (add_den_pos (arctanSum_den_pos htd n) Nat.one_pos)
        (arctanTerm_den_pos htd (n + 1)))
      (Qadd_congr (Qadd_congr ih (arctanCoeff_term_even t n)) ho) ?_
    exact Qadd_congr (Qadd_zero_right (arctanSum t n)) (Qeq_refl _)

/-- `|sinCoeffₖ| ≤ 1` for every `k` (`(−1)^{k/2}/k!` at odd `k`, else `0`; `k! ≥ 1`). The outer-series
    coefficient bound for the `DN`-sum of the `sin∘arctan` composition bridge. -/
theorem sinCoeff_abs_le_one (k : Nat) : Qle (Qabs (sinCoeff k)) ⟨1, 1⟩ := by
  unfold sinCoeff
  by_cases h : k % 2 = 1
  · rw [if_pos h, Qabs_mul, qpow_neg_one_abs]
    have hk1 : 1 ≤ fct k := fct_pos k
    simp only [Qabs, Qle, mul]; push_cast; omega
  · rw [if_neg h]; simp only [Qabs, Qle]; push_cast

/-- `|cosCoeffₖ| ≤ 1` for every `k`. -/
theorem cosCoeff_abs_le_one (k : Nat) : Qle (Qabs (cosCoeff k)) ⟨1, 1⟩ := by
  unfold cosCoeff
  by_cases h : k % 2 = 0
  · rw [if_pos h, Qabs_mul, qpow_neg_one_abs]
    have hk1 : 1 ≤ fct k := fct_pos k
    simp only [Qabs, Qle, mul]; push_cast; omega
  · rw [if_neg h]; simp only [Qabs, Qle]; push_cast

/-- **Absolute bound on the arctan partial sum**: `|arctanSum t N| ≤ geoSum ρ N` for `|t| ≤ ρ`
    (per-term `arctanTerm_abs_le` + triangle). With `geoSum ρ N ≤ 1` (small `ρ`) this gives the
    `|peval arctanCoeff t M| ≤ 1` hypothesis that `gen_per_m_bound` needs. -/
theorem arctanSum_abs_le {t ρ : Q} (htd : 0 < t.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (htρ : Qle (Qabs t) ρ) : ∀ N, Qle (Qabs (arctanSum t N)) (geoSum ρ N)
  | 0 => arctanTerm_abs_le htd hρ0 hρd htρ 0
  | (N + 1) => by
      show Qle (Qabs (add (arctanSum t N) (arctanTerm t (N + 1)))) (add (geoSum ρ N) (geoTerm ρ (N + 1)))
      refine Qle_trans (add_den_pos (Qabs_den_pos (arctanSum_den_pos htd N))
          (Qabs_den_pos (arctanTerm_den_pos htd (N + 1)))) (Qabs_add_le _ _) ?_
      exact Qadd_le_add (arctanSum_abs_le htd hρ0 hρd htρ N) (arctanTerm_abs_le htd hρ0 hρd htρ (N + 1))

-- ===========================================================================
-- The DN-sum: composition error = Σₘ sinₘ·(per-m error), bounded by Σₘ Σⱼ |cornerⱼ|.
-- ===========================================================================

/-- **`DN` identity**: `peval(sin∘arctan,t,M) − peval(sin, q, M) = Σ_{m≤M} sinₘ·(peval(arctanᵐ,t,M) − qᵐ)`
    where `q = peval arctanCoeff t M`. (`peval_fcomp_swap` + `Fsum_sub` + `Qmul_sub_left_loc`.) -/
theorem DN_sin_eq (t : Q) (htd : 0 < t.den) (M : Nat) :
    Qeq (Qsub (peval (fcomp sinCoeff arctanCoeff) t M)
          (peval sinCoeff (peval arctanCoeff t M) M))
      (Fsum (fun m => mul (sinCoeff m)
        (Qsub (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m))) M) := by
  have hq : 0 < (peval arctanCoeff t M).den := peval_den_pos arctanCoeff_den_pos htd M
  have hF : ∀ m, 0 < (mul (sinCoeff m) (peval (fpow arctanCoeff m) t M)).den :=
    fun m => Qmul_den_pos (sinCoeff_den_pos m) (peval_den_pos (fpow_den_pos arctanCoeff_den_pos m) htd M)
  have hG : ∀ m, 0 < (mul (sinCoeff m) (qpow (peval arctanCoeff t M) m)).den :=
    fun m => Qmul_den_pos (sinCoeff_den_pos m) (qpow_den_pos hq m)
  refine Qeq_trans (Qsub_den_pos (Fsum_den_pos hF M) (peval_den_pos sinCoeff_den_pos hq M))
    (QsubCongr (peval_fcomp_swap sinCoeff arctanCoeff sinCoeff_den_pos arctanCoeff_den_pos
      arctanCoeff_zero t htd M) (Qeq_refl _)) ?_
  refine Qeq_trans (Fsum_den_pos (fun m => Qsub_den_pos (hF m) (hG m)) M)
    (Qeq_symm (Fsum_sub hF hG M)) ?_
  exact Fsum_congr (fun m => Qeq_symm (Qmul_sub_left_loc (sinCoeff m)
    (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m))) M

/-- **Per-`m` error ≤ corner sum**: `|peval(arctanᵐ,t,M) − qᵐ| ≤ Σ_{j≤M}|cornerⱼ|` for `m ≤ M`
    (`q = peval arctanCoeff t M`, `|q| ≤ 1`). `m = 0` is `0`; `m = k+1` is `gen_per_m_bound` extended
    by `Fsum_mono_len`. -/
theorem e_le_T_arctan (t : Q) (htd : 0 < t.den) (M : Nat)
    (hq1 : Qle (Qabs (peval arctanCoeff t M)) ⟨1, 1⟩) (m : Nat) (hm : m ≤ M) :
    Qle (Qabs (Qsub (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m)))
      (Fsum (fun j => Qabs (gcornerB arctanCoeff t j M)) M) := by
  have hgd : ∀ j, 0 < (Qabs (gcornerB arctanCoeff t j M)).den :=
    fun j => Qabs_den_pos (gcornerB_den arctanCoeff arctanCoeff_den_pos t htd j M)
  have hg0 : ∀ j, 0 ≤ (Qabs (gcornerB arctanCoeff t j M)).num := fun j => Qabs_num_nonneg _
  cases m with
  | zero =>
    have hsub : Qeq (Qsub (peval (fpow arctanCoeff 0) t M) (qpow (peval arctanCoeff t M) 0)) ⟨0, 1⟩ := by
      show Qeq (Qsub (peval fone t M) ⟨1, 1⟩) ⟨0, 1⟩
      refine Qeq_trans (Qsub_den_pos Nat.one_pos Nat.one_pos)
        (Qsub_congr (peval_fone t htd M) (Qeq_refl _)) (by decide)
    have he0 : Qeq (Qabs (Qsub (peval (fpow arctanCoeff 0) t M) (qpow (peval arctanCoeff t M) 0))) ⟨0, 1⟩ :=
      Qeq_trans (by decide) (Qabs_Qeq hsub) (by decide)
    exact Qle_trans Nat.one_pos (Qeq_le he0) (Qzero_le_loc (Fsum_num_nonneg hg0 M))
  | succ k =>
    refine Qle_trans (Fsum_den_pos hgd k)
      (gen_per_m_bound arctanCoeff arctanCoeff_den_pos t htd M hq1 k) ?_
    exact Fsum_mono_len hg0 hgd (by omega : k ≤ M)

/-- **The `DN` bound**: `|peval(sin∘arctan,t,M) − peval(sin,q,M)| ≤ Σ_{m≤M} Σ_{j≤M}|cornerⱼ|`
    (`= (M+1)·(corner sum)`), `q = peval arctanCoeff t M`. The `sin∘arctan` value convergence is now
    reduced to the corner decay `Σⱼ|gcornerB arctanCoeff t j M| → 0`. -/
theorem DN_sin_abs_le (t : Q) (htd : 0 < t.den) (M : Nat)
    (hq1 : Qle (Qabs (peval arctanCoeff t M)) ⟨1, 1⟩) :
    Qle (Qabs (Qsub (peval (fcomp sinCoeff arctanCoeff) t M)
          (peval sinCoeff (peval arctanCoeff t M) M)))
      (Fsum (fun _ => Fsum (fun j => Qabs (gcornerB arctanCoeff t j M)) M) M) := by
  have herr : ∀ m, 0 < (Qsub (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m)).den :=
    fun m => Qsub_den_pos (peval_den_pos (fpow_den_pos arctanCoeff_den_pos m) htd M)
      (qpow_den_pos (peval_den_pos arctanCoeff_den_pos htd M) m)
  have hSE : ∀ m, 0 < (mul (sinCoeff m)
      (Qsub (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m))).den :=
    fun m => Qmul_den_pos (sinCoeff_den_pos m) (herr m)
  refine Qle_trans (Qabs_den_pos (Fsum_den_pos hSE M)) (Qeq_le (Qabs_Qeq (DN_sin_eq t htd M))) ?_
  refine Qle_trans (Fsum_den_pos (fun m => Qabs_den_pos (hSE m)) M) (Fsum_abs_le hSE M) ?_
  refine Fsum_le_congr (fun m hm => ?_)
  refine Qle_trans (Qmul_den_pos (Qabs_den_pos (sinCoeff_den_pos m)) (Qabs_den_pos (herr m)))
    (Qeq_le (by rw [Qabs_mul]; exact Qeq_refl _ :
      Qeq (Qabs (mul (sinCoeff m) (Qsub (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m))))
        (mul (Qabs (sinCoeff m)) (Qabs (Qsub (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m)))))) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (herr m)))
    (Qmul_le_mul_right (Qabs_num_nonneg _) (sinCoeff_abs_le_one m)) ?_
  exact Qle_trans (Qabs_den_pos (herr m)) (Qeq_le (Qone_mul _)) (e_le_T_arctan t htd M hq1 m hm)

/-- **Geometric domination of the arctan coefficients**: `|arctanCoeffₖ| ≤ 1` for every `k` (the
    coefficient is `(−1)^{k/2}/k` at odd `k`, else `0`). The convergence input for the composition
    value bridge: combined with `peval_mono` it bounds `peval (fabs arctanCoeff) ρ M` by a geometric
    sum, giving the absolute convergence of the `arctan` powers inside the radius. -/
theorem arctanCoeff_fabs_le_one (k : Nat) : Qle (fabs arctanCoeff k) ⟨1, 1⟩ := by
  show Qle (Qabs (arctanCoeff k)) ⟨1, 1⟩
  unfold arctanCoeff
  by_cases h : k % 2 = 1
  · rw [if_pos h, Qabs_mul, qpow_neg_one_abs]
    have hk1 : 1 ≤ k := by omega
    simp only [Qabs, Qle, mul]; push_cast; omega
  · rw [if_neg h]; simp only [Qabs, Qle]; push_cast

-- ===========================================================================
-- Corner decay for arctanCoeff (the sin∘arctan value-bridge wall): mirrors the
-- kdbl machinery with arctan constants (2ᵐ not 4ᵐ, since |arctanCoeffₖ| ≤ 1).
-- ===========================================================================

/-- **Per-coefficient power bound**: `(|arctanCoeff|ᵐ)ₖ ≤ 2ᵐ·2ᵏ` (the `arctan` analog of
    `fpow_fabs_kdbl_bound`; cleaner since `|arctanCoeffₖ| ≤ 1`, not `2`). -/
theorem fpow_fabs_arctan_bound (m k : Nat) :
    Qle (fpow (fabs arctanCoeff) m k) ⟨(2 : Int) ^ m * 2 ^ k, 1⟩ := by
  induction m generalizing k with
  | zero =>
      show Qle (fone k) ⟨(2 : Int) ^ 0 * 2 ^ k, 1⟩
      by_cases h : k = 0
      · subst h; rw [show fone 0 = (⟨1, 1⟩ : Q) from by simp [fone]]; decide
      · rw [show fone k = (⟨0, 1⟩ : Q) from by simp [fone, h]]
        show (0 : Int) * 1 ≤ ((2 : Int) ^ 0 * 2 ^ k) * 1
        have h2 : (0 : Int) ≤ (2 : Int) ^ 0 * 2 ^ k := by exact_mod_cast Nat.zero_le (2 ^ 0 * 2 ^ k)
        omega
  | succ m ih =>
      have hterm : ∀ i, Qle (mul (fabs arctanCoeff i) (fpow (fabs arctanCoeff) m (k - i)))
          (mul (⟨(2 : Int) ^ m, 1⟩ : Q) ⟨2 ^ (k - i), 1⟩) := by
        intro i
        refine Qle_trans (Qmul_den_pos Nat.one_pos Nat.one_pos)
          (Qmul_le_mul (fabs_den_pos (fun j => arctanCoeff_den_pos j) i) Nat.one_pos
            (fpow_den_pos (fun j => fabs_den_pos (fun l => arctanCoeff_den_pos l) j) m (k - i))
            (fabs_nonneg arctanCoeff i) (fpow_num_nonneg (fun j => fabs_nonneg arctanCoeff j) m (k - i))
            (arctanCoeff_fabs_le_one i) (ih (k - i)))
          (Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor))
      show Qle (Fsum (fun i => mul (fabs arctanCoeff i) (fpow (fabs arctanCoeff) m (k - i))) k)
        ⟨(2 : Int) ^ (m + 1) * 2 ^ k, 1⟩
      refine Qle_trans (Fsum_den_pos (fun i => Qmul_den_pos Nat.one_pos Nat.one_pos) k)
        (Fsum_le_Fsum hterm k) ?_
      refine Qle_trans (Qmul_den_pos Nat.one_pos (Fsum_den_pos (fun _ => Nat.one_pos) k))
        (Qeq_le (Fsum_mul_left Nat.one_pos (fun _ => Nat.one_pos) k)) ?_
      refine Qle_trans (Qmul_den_pos Nat.one_pos Nat.one_pos)
        (Qeq_le (Qmul_congr (Qeq_refl _) (Qeq_trans (Fsum_den_pos (fun _ => Nat.one_pos) k)
          (Qeq_symm (Fsum_reverse (f := fun j => (⟨(2 : Int) ^ j, 1⟩ : Q)) (fun _ => Nat.one_pos) k))
          (pow2_sum k)))) ?_
      show ((2 : Int) ^ m * (2 ^ (k + 1) - 1)) * 1 ≤ ((2 : Int) ^ (m + 1) * 2 ^ k) * 1
      rw [show (2 : Int) ^ (m + 1) = 2 ^ m * 2 from by rw [Int.pow_succ],
          show (2 : Int) ^ (k + 1) = 2 ^ k * 2 from by rw [Int.pow_succ]]
      have hgen : ∀ A B : Int, 0 ≤ A → (A * (B * 2 - 1)) * 1 ≤ (A * 2 * B) * 1 := by
        intro A B hA
        have key : (A * 2 * B) * 1 - (A * (B * 2 - 1)) * 1 = A := by ring_uor
        omega
      exact hgen ((2 : Int) ^ m) ((2 : Int) ^ k) (by exact_mod_cast Nat.zero_le (2 ^ m))

/-- **Per-term geometric domination**: the `k`-th `|arctanCoeff|ᵐ` evaluation term is `≤ 2ᵐ·(2ρ)ᵏ`. -/
theorem fpow_arctan_term_bound (ρ : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num) (m k : Nat) :
    Qle (mul (fpow (fabs arctanCoeff) m k) (qpow ρ k))
      (mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) k)) := by
  refine Qle_trans (Qmul_den_pos Nat.one_pos (qpow_den_pos hρd k))
    (Qmul_le_mul_right (qpow_nonneg hρ0 k) (fpow_fabs_arctan_bound m k)) ?_
  refine Qeq_le (Qeq_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos (qpow_den_pos hρd k)))
    (Qeq_trans (Qmul_den_pos Nat.one_pos (qpow_den_pos hρd k))
      (by simp only [Qeq, mul] : Qeq (mul (⟨(2 : Int) ^ m * 2 ^ k, 1⟩ : Q) (qpow ρ k))
        (mul (mul (⟨(2 : Int) ^ m, 1⟩ : Q) ⟨(2 : Int) ^ k, 1⟩) (qpow ρ k)))
      (Qmul_assoc ⟨(2 : Int) ^ m, 1⟩ ⟨(2 : Int) ^ k, 1⟩ (qpow ρ k)))
    (Qmul_congr (Qeq_refl _) (Qeq_trans (Qmul_den_pos (qpow_den_pos (by decide) k) (qpow_den_pos hρd k))
      (Qmul_congr (Qeq_symm (qpow_two_nat k)) (Qeq_refl _)) (Qeq_symm (qpow_mul ⟨2, 1⟩ ρ (by decide) hρd k)))))

/-- **Cauchy gap for arctan powers**: `|peval(arctanᵐ,w,M′) − peval(arctanᵐ,w,M)| ≤ Σ_{M<k≤M′} 2ᵐ·(2ρ)ᵏ`
    (`Fsum_abs_diff_le` + the per-term bound). Mirrors `peval_kdbl_pow_gap`. -/
theorem peval_arctan_pow_gap (ρ w : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num) (hwd : 0 < w.den)
    (hw : Qle (Qabs w) ρ) (m : Nat) {M M' : Nat} (hMM : M ≤ M') :
    Qle (Qabs (Qsub (peval (fpow arctanCoeff m) w M') (peval (fpow arctanCoeff m) w M)))
      (Qsub (Fsum (fun k => mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) k)) M')
            (Fsum (fun k => mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) k)) M)) :=
  Fsum_abs_diff_le
    (fun k => Qmul_den_pos (fpow_den_pos (fun i => arctanCoeff_den_pos i) m k) (qpow_den_pos hwd k))
    (fun k => Qmul_den_pos Nat.one_pos (qpow_den_pos (Qmul_den_pos (by decide) hρd) k))
    (fun k => Qle_trans (Qmul_den_pos (Qabs_den_pos (fpow_den_pos (fun i => arctanCoeff_den_pos i) m k))
        (Qabs_den_pos (qpow_den_pos hwd k)))
      (Qeq_le (by rw [Qabs_mul]; exact Qeq_refl _ : Qeq (Qabs (mul (fpow arctanCoeff m k) (qpow w k)))
        (mul (Qabs (fpow arctanCoeff m k)) (Qabs (qpow w k)))))
      (Qle_trans (Qmul_den_pos (fpow_den_pos (fun i => fabs_den_pos (fun j => arctanCoeff_den_pos j) i) m k)
          (qpow_den_pos hρd k))
        (Qmul_le_mul (Qabs_den_pos (fpow_den_pos (fun i => arctanCoeff_den_pos i) m k))
          (fpow_den_pos (fun i => fabs_den_pos (fun j => arctanCoeff_den_pos j) i) m k)
          (Qabs_den_pos (qpow_den_pos hwd k))
          (Qabs_num_nonneg _) (Qabs_num_nonneg _)
          (fpow_abs_dom arctanCoeff (fun i => arctanCoeff_den_pos i) m k)
          (Qle_trans (qpow_den_pos (Qabs_den_pos hwd) k) (Qeq_le (qpow_abs w k))
            (qpow_base_mono (Qabs_den_pos hwd) hρd (Qabs_num_nonneg w) hw k)))
        (fpow_arctan_term_bound ρ hρd hρ0 m k)))
    hMM

/-- **Cauchy modulus for arctan powers** (telescoped): `|peval(arctanᵐ,w,M′) − peval(arctanᵐ,w,M)|·(1−2ρ)
    ≤ 2ᵐ·(2ρ)^{M+1}`. Mirrors `peval_kdbl_pow_cauchy` (the `gPow` telescoping is general). -/
theorem peval_arctan_pow_cauchy (ρ w : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num) (hwd : 0 < w.den)
    (hw : Qle (Qabs w) ρ) (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (m : Nat) {M M' : Nat} (hMM : M ≤ M') :
    Qle (mul (Qabs (Qsub (peval (fpow arctanCoeff m) w M') (peval (fpow arctanCoeff m) w M)))
          (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ)))
      (mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))) := by
  have hrd : 0 < (mul (⟨2, 1⟩ : Q) ρ).den := Qmul_den_pos (by decide) hρd
  have hr0 : 0 ≤ (mul (⟨2, 1⟩ : Q) ρ).num := Qmul_num_nonneg (by decide) hρ0
  have hgN : ∀ N, 0 < (Fsum (fun k => mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) k)) N).den :=
    fun N => Fsum_den_pos (fun k => Qmul_den_pos Nat.one_pos (qpow_den_pos hrd k)) N
  have hDden : 0 < (Qsub (gPow (mul ⟨2, 1⟩ ρ) M') (gPow (mul ⟨2, 1⟩ ρ) M)).den :=
    Qsub_den_pos (gPow_den_pos hrd M') (gPow_den_pos hrd M)
  have hwd1 : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).den := Qsub_den_pos Nat.one_pos hrd
  have eRG : ∀ N, Qeq (Fsum (fun k => mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) k)) N)
      (mul (⟨(2 : Int) ^ m, 1⟩ : Q) (gPow (mul ⟨2, 1⟩ ρ) N)) :=
    fun N => Qeq_trans (Qmul_den_pos Nat.one_pos (Fsum_den_pos (fun k => qpow_den_pos hrd k) N))
      (Fsum_mul_left Nat.one_pos (fun k => qpow_den_pos hrd k) N)
      (Qmul_congr (Qeq_refl _) (gPow_eq_Fsum (mul ⟨2, 1⟩ ρ) N))
  have eGap : Qeq (Qsub (Fsum (fun k => mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) k)) M')
        (Fsum (fun k => mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) k)) M))
      (mul (⟨(2 : Int) ^ m, 1⟩ : Q) (Qsub (gPow (mul ⟨2, 1⟩ ρ) M') (gPow (mul ⟨2, 1⟩ ρ) M))) :=
    Qeq_trans (Qsub_den_pos (Qmul_den_pos Nat.one_pos (gPow_den_pos hrd M'))
        (Qmul_den_pos Nat.one_pos (gPow_den_pos hrd M)))
      (Qsub_congr (eRG M') (eRG M))
      (Qeq_symm (Qmul_sub_left_loc ⟨(2 : Int) ^ m, 1⟩ (gPow (mul ⟨2, 1⟩ ρ) M') (gPow (mul ⟨2, 1⟩ ρ) M)))
  refine Qle_trans (Qmul_den_pos (Qsub_den_pos (hgN M') (hgN M)) hwd1)
    (Qmul_le_mul_right h2ρ (peval_arctan_pow_gap ρ w hρd hρ0 hwd hw m hMM)) ?_
  refine Qle_trans (Qmul_den_pos (Qmul_den_pos Nat.one_pos hDden) hwd1)
    (Qeq_le (Qmul_congr eGap (Qeq_refl _))) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos hDden hwd1))
    (Qeq_le (Qmul_assoc ⟨(2 : Int) ^ m, 1⟩ (Qsub (gPow (mul ⟨2, 1⟩ ρ) M') (gPow (mul ⟨2, 1⟩ ρ) M))
      (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ)))) ?_
  exact Qmul_le_mul_left (by show (0 : Int) ≤ (2 : Int) ^ m; exact_mod_cast Nat.zero_le (2 ^ m))
    (gPow_gap_le (mul ⟨2, 1⟩ ρ) hr0 hrd hMM)

/-- `|arctanCoeff_i·wⁱ| ≤ 1·ρⁱ` for `|w| ≤ ρ` (cleaner than kdbl's `2·ρⁱ`). -/
theorem Qabs_arctan_C_le (ρ w : Q) (hρd : 0 < ρ.den) (hwd : 0 < w.den) (hw : Qle (Qabs w) ρ) (i : Nat) :
    Qle (Qabs (mul (arctanCoeff i) (qpow w i))) (mul ⟨1, 1⟩ (qpow ρ i)) :=
  Qle_trans (Qmul_den_pos (Qabs_den_pos (arctanCoeff_den_pos i)) (Qabs_den_pos (qpow_den_pos hwd i)))
    (Qeq_le (by rw [Qabs_mul]; exact Qeq_refl _ :
      Qeq (Qabs (mul (arctanCoeff i) (qpow w i))) (mul (Qabs (arctanCoeff i)) (Qabs (qpow w i)))))
    (Qmul_le_mul (Qabs_den_pos (arctanCoeff_den_pos i)) (by decide) (Qabs_den_pos (qpow_den_pos hwd i))
      (Qabs_num_nonneg _) (Qabs_num_nonneg _) (arctanCoeff_fabs_le_one i)
      (Qle_trans (qpow_den_pos (Qabs_den_pos hwd) i) (Qeq_le (qpow_abs w i))
        (qpow_base_mono (Qabs_den_pos hwd) hρd (Qabs_num_nonneg w) hw i)))

/-- The `i`-th inner gap of the arctan `peval_fpow_succ` corner factors as `(arctanCoeff_i·wⁱ)·(pₘ gap)`. -/
theorem corner_inner_eq_arctan (w : Q) (hwd : 0 < w.den) (m M i : Nat) :
    Qeq (Qsub (Fsum (fun j => mul (mul (arctanCoeff i) (qpow w i)) (mul (fpow arctanCoeff m j) (qpow w j))) M)
              (Fsum (fun j => mul (mul (arctanCoeff i) (qpow w i)) (mul (fpow arctanCoeff m j) (qpow w j))) (M - i)))
      (mul (mul (arctanCoeff i) (qpow w i))
        (Qsub (peval (fpow arctanCoeff m) w M) (peval (fpow arctanCoeff m) w (M - i)))) := by
  have hC : 0 < (mul (arctanCoeff i) (qpow w i)).den := Qmul_den_pos (arctanCoeff_den_pos i) (qpow_den_pos hwd i)
  have hterm : ∀ N, Qeq (Fsum (fun j => mul (mul (arctanCoeff i) (qpow w i))
        (mul (fpow arctanCoeff m j) (qpow w j))) N)
      (mul (mul (arctanCoeff i) (qpow w i)) (peval (fpow arctanCoeff m) w N)) :=
    fun N => Fsum_mul_left hC
      (fun j => Qmul_den_pos (fpow_den_pos (fun l => arctanCoeff_den_pos l) m j) (qpow_den_pos hwd j)) N
  exact Qeq_trans (Qsub_den_pos
      (Qmul_den_pos hC (peval_den_pos (fpow_den_pos (fun l => arctanCoeff_den_pos l) m) hwd M))
      (Qmul_den_pos hC (peval_den_pos (fpow_den_pos (fun l => arctanCoeff_den_pos l) m) hwd (M - i))))
    (Qsub_congr (hterm M) (hterm (M - i)))
    (Qeq_symm (Qmul_sub_left_loc (mul (arctanCoeff i) (qpow w i))
      (peval (fpow arctanCoeff m) w M) (peval (fpow arctanCoeff m) w (M - i))))

/-- **Per-corner-term bound**: `|corner_iⁱ|·(1−2ρ) ≤ 2ᵐ·(2ρ)^{M+1}`. Mirrors `corner_term_le`. -/
theorem corner_term_le_arctan (ρ w : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num) (hwd : 0 < w.den)
    (hw : Qle (Qabs w) ρ) (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num) (m M i : Nat) (hiM : i ≤ M) :
    Qle (mul (Qabs (Qsub
          (Fsum (fun j => mul (mul (arctanCoeff i) (qpow w i)) (mul (fpow arctanCoeff m j) (qpow w j))) M)
          (Fsum (fun j => mul (mul (arctanCoeff i) (qpow w i)) (mul (fpow arctanCoeff m j) (qpow w j))) (M - i))))
          (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ)))
      (mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))) := by
  have hpd : ∀ N, 0 < (peval (fpow arctanCoeff m) w N).den :=
    fun N => peval_den_pos (fpow_den_pos (fun l => arctanCoeff_den_pos l) m) hwd N
  have hC : 0 < (mul (arctanCoeff i) (qpow w i)).den := Qmul_den_pos (arctanCoeff_den_pos i) (qpow_den_pos hwd i)
  have hgap : 0 < (Qsub (peval (fpow arctanCoeff m) w M) (peval (fpow arctanCoeff m) w (M - i))).den :=
    Qsub_den_pos (hpd M) (hpd (M - i))
  have h2d : 0 < (mul (⟨2, 1⟩ : Q) ρ).den := Qmul_den_pos (by decide) hρd
  have hwd1 : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).den := Qsub_den_pos Nat.one_pos h2d
  have h2n : (0 : Int) ≤ (2 : Int) ^ m := by exact_mod_cast Nat.zero_le (2 ^ m)
  have hRHSn : 0 ≤ (mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M - i + 1))).num :=
    Qmul_num_nonneg h2n (qpow_nonneg (Qmul_num_nonneg (by decide) hρ0) _)
  have heq : Qeq (Qabs (Qsub
        (Fsum (fun j => mul (mul (arctanCoeff i) (qpow w i)) (mul (fpow arctanCoeff m j) (qpow w j))) M)
        (Fsum (fun j => mul (mul (arctanCoeff i) (qpow w i)) (mul (fpow arctanCoeff m j) (qpow w j))) (M - i))))
      (mul (Qabs (mul (arctanCoeff i) (qpow w i)))
        (Qabs (Qsub (peval (fpow arctanCoeff m) w M) (peval (fpow arctanCoeff m) w (M - i))))) :=
    Qeq_trans (Qabs_den_pos (Qmul_den_pos hC hgap)) (Qabs_Qeq (corner_inner_eq_arctan w hwd m M i))
      (by rw [Qabs_mul]; exact Qeq_refl _)
  refine Qle_trans (Qmul_den_pos (Qmul_den_pos (Qabs_den_pos hC) (Qabs_den_pos hgap)) hwd1)
    (Qeq_le (Qmul_congr heq (Qeq_refl _))) ?_
  refine Qle_trans (Qmul_den_pos (Qabs_den_pos hC) (Qmul_den_pos (Qabs_den_pos hgap) hwd1))
    (Qeq_le (Qmul_assoc (Qabs (mul (arctanCoeff i) (qpow w i)))
      (Qabs (Qsub (peval (fpow arctanCoeff m) w M) (peval (fpow arctanCoeff m) w (M - i))))
      (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ)))) ?_
  refine Qle_trans (Qmul_den_pos (Qabs_den_pos hC) (Qmul_den_pos Nat.one_pos (qpow_den_pos h2d _)))
    (Qmul_le_mul_left (Qabs_num_nonneg _)
      (peval_arctan_pow_cauchy ρ w hρd hρ0 hwd hw h2ρ m (M := M - i) (M' := M) (by omega))) ?_
  refine Qle_trans (Qmul_den_pos (Qmul_den_pos (by decide) (qpow_den_pos hρd i))
      (Qmul_den_pos Nat.one_pos (qpow_den_pos h2d _)))
    (Qmul_le_mul_right hRHSn (Qabs_arctan_C_le ρ w hρd hwd hw i)) ?_
  refine Qle_trans (Qmul_den_pos (Qmul_den_pos (by decide) Nat.one_pos)
      (Qmul_den_pos (qpow_den_pos hρd i) (qpow_den_pos h2d _)))
    (Qeq_le (mul_rearrange ⟨1, 1⟩ (qpow ρ i) ⟨(2 : Int) ^ m, 1⟩ (qpow (mul ⟨2, 1⟩ ρ) (M - i + 1)))) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos (qpow_den_pos hρd i) (qpow_den_pos h2d _)))
    (Qeq_le (Qmul_congr (by simp [Qeq, mul] :
      Qeq (mul (⟨1, 1⟩ : Q) ⟨(2 : Int) ^ m, 1⟩) ⟨(2 : Int) ^ m, 1⟩) (Qeq_refl _))) ?_
  exact Qmul_le_mul_left h2n (qpow_conv_le ρ hρd hρ0 i M hiM)

/-- **Per-power corner bound**: `|gcornerB arctanCoeff w m M|·(1−2ρ) ≤ (M+1)·2ᵐ·(2ρ)^{M+1}`.
    Sum `corner_term_le_arctan` over `i` (`Fsum_abs_le` + `Fsum_mul_const_right` + `Fsum_const_eq`). -/
theorem corner_bound_arctan (ρ w : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num) (hwd : 0 < w.den)
    (hw : Qle (Qabs w) ρ) (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num) (m M : Nat) :
    Qle (mul (Qabs (gcornerB arctanCoeff w m M)) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ)))
      (mul (⟨(M : Int) + 1, 1⟩ : Q) (mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1)))) := by
  have hgd : ∀ i j, 0 < (mul (mul (arctanCoeff i) (qpow w i)) (mul (fpow arctanCoeff m j) (qpow w j))).den :=
    fun i j => Qmul_den_pos (Qmul_den_pos (arctanCoeff_den_pos i) (qpow_den_pos hwd i))
      (Qmul_den_pos (fpow_den_pos (fun l => arctanCoeff_den_pos l) m j) (qpow_den_pos hwd j))
  have hid : ∀ i, 0 < (Qsub
      (Fsum (fun j => mul (mul (arctanCoeff i) (qpow w i)) (mul (fpow arctanCoeff m j) (qpow w j))) M)
      (Fsum (fun j => mul (mul (arctanCoeff i) (qpow w i)) (mul (fpow arctanCoeff m j) (qpow w j))) (M - i))).den :=
    fun i => Qsub_den_pos (Fsum_den_pos (fun j => hgd i j) M) (Fsum_den_pos (fun j => hgd i j) (M - i))
  have hwd1 : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).den := Qsub_den_pos Nat.one_pos (Qmul_den_pos (by decide) hρd)
  have hcd : 0 < (mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))).den :=
    Qmul_den_pos Nat.one_pos (qpow_den_pos (Qmul_den_pos (by decide) hρd) (M + 1))
  show Qle (mul (Qabs (Fsum (fun i => Qsub
        (Fsum (fun j => mul (mul (arctanCoeff i) (qpow w i)) (mul (fpow arctanCoeff m j) (qpow w j))) M)
        (Fsum (fun j => mul (mul (arctanCoeff i) (qpow w i)) (mul (fpow arctanCoeff m j) (qpow w j))) (M - i))) M))
        (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ)))
    (mul (⟨(M : Int) + 1, 1⟩ : Q) (mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))))
  refine Qle_trans (Qmul_den_pos (Fsum_den_pos (fun i => Qabs_den_pos (hid i)) M) hwd1)
    (Qmul_le_mul_right h2ρ (Fsum_abs_le (fun i => hid i) M)) ?_
  refine Qle_trans (Fsum_den_pos (fun i => Qmul_den_pos (Qabs_den_pos (hid i)) hwd1) M)
    (Qeq_le (Fsum_mul_const_right hwd1 (fun i => Qabs_den_pos (hid i)) M)) ?_
  refine Qle_trans (Fsum_den_pos (fun _ => hcd) M)
    (Fsum_le_Fsum_le (fun i hi => corner_term_le_arctan ρ w hρd hρ0 hwd hw h2ρ m M i hi)) ?_
  exact Qeq_le (Fsum_const_eq (mul (⟨(2 : Int) ^ m, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))) hcd M)

/-- **Corner-sum bound** (over the power index): `(Σ_{j≤M}|gcornerB arctanCoeff w j M|)·(1−2ρ) ≤
    Σ_{j≤M} (M+1)·2ʲ·(2ρ)^{M+1}`. Sum `corner_bound_arctan` over `j` (`Fsum_mul_const_right`). -/
theorem corner_sum_bound_arctan (ρ w : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num) (hwd : 0 < w.den)
    (hw : Qle (Qabs w) ρ) (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num) (M : Nat) :
    Qle (mul (Fsum (fun j => Qabs (gcornerB arctanCoeff w j M)) M) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ)))
      (Fsum (fun j => mul (⟨(M : Int) + 1, 1⟩ : Q)
        (mul (⟨(2 : Int) ^ j, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1)))) M) := by
  have hwd1 : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).den := Qsub_den_pos Nat.one_pos (Qmul_den_pos (by decide) hρd)
  have ha : ∀ j, 0 < (Qabs (gcornerB arctanCoeff w j M)).den :=
    fun j => Qabs_den_pos (gcornerB_den arctanCoeff arctanCoeff_den_pos w hwd j M)
  refine Qle_trans (Fsum_den_pos (fun j => Qmul_den_pos (ha j) hwd1) M)
    (Qeq_le (Fsum_mul_const_right hwd1 ha M)) ?_
  exact Fsum_le_Fsum_le (fun j _ => corner_bound_arctan ρ w hρd hρ0 hwd hw h2ρ j M)

/-- **Closed corner-sum bound**: `(Σ_{j≤M}|gcornerB arctanCoeff w j M|)·(1−2ρ) ≤
    (2^{M+1}−1)·(M+1)·(2ρ)^{M+1}`. Collapse the `j`-sum (`Qmul_swap_outer` + `Fsum_mul_const_right`
    + `pow2_sum`). -/
theorem corner_sum_closed_arctan (ρ w : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num) (hwd : 0 < w.den)
    (hw : Qle (Qabs w) ρ) (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num) (M : Nat) :
    Qle (mul (Fsum (fun j => Qabs (gcornerB arctanCoeff w j M)) M) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ)))
      (mul (⟨(2 : Int) ^ (M + 1) - 1, 1⟩ : Q)
        (mul (⟨(M : Int) + 1, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1)))) := by
  have hQ : 0 < (qpow (mul ⟨2, 1⟩ ρ) (M + 1)).den := qpow_den_pos (Qmul_den_pos (by decide) hρd) (M + 1)
  have hC : 0 < (mul (⟨(M : Int) + 1, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))).den := Qmul_den_pos Nat.one_pos hQ
  refine Qle_trans (Fsum_den_pos (fun j => Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos hQ)) M)
    (corner_sum_bound_arctan ρ w hρd hρ0 hwd hw h2ρ M) ?_
  refine Qle_trans (Fsum_den_pos (fun j => Qmul_den_pos Nat.one_pos hC) M)
    (Qeq_le (Fsum_congr (fun j => Qmul_swap_outer (⟨(M : Int) + 1, 1⟩ : Q) (⟨(2 : Int) ^ j, 1⟩ : Q)
      (qpow (mul ⟨2, 1⟩ ρ) (M + 1))) M)) ?_
  exact Qeq_le (Qeq_trans (Qmul_den_pos (Fsum_den_pos (fun _ => Nat.one_pos) M) hC)
    (Qeq_symm (Fsum_mul_const_right (a := fun j => (⟨(2 : Int) ^ j, 1⟩ : Q)) hC (fun _ => Nat.one_pos) M))
    (Qmul_congr (pow2_sum M) (Qeq_refl _)))

/-- **Closed `DN` bound**: `|peval(sin∘arctan,t,M) − peval(sin,q,M)|·(1−2ρ) ≤
    (M+1)·(2^{M+1}−1)·(M+1)·(2ρ)^{M+1}` for `|t| ≤ ρ`, `|q| ≤ 1`. Combines `DN_sin_abs_le` with
    `corner_sum_closed_arctan`. The RHS `→ 0` (for `4ρ < 1`), proving `peval(sin∘arctan,t,·) → peval(sin,q,·)`. -/
theorem DN_sin_closed (t ρ : Q) (M : Nat) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num) (htd : 0 < t.den)
    (hw : Qle (Qabs t) ρ) (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hq1 : Qle (Qabs (peval arctanCoeff t M)) ⟨1, 1⟩) :
    Qle (mul (Qabs (Qsub (peval (fcomp sinCoeff arctanCoeff) t M)
            (peval sinCoeff (peval arctanCoeff t M) M))) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ)))
      (mul (⟨(M : Int) + 1, 1⟩ : Q) (mul (⟨(2 : Int) ^ (M + 1) - 1, 1⟩ : Q)
        (mul (⟨(M : Int) + 1, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))))) := by
  have hwd1 : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).den := Qsub_den_pos Nat.one_pos (Qmul_den_pos (by decide) hρd)
  have hInner : 0 < (Fsum (fun j => Qabs (gcornerB arctanCoeff t j M)) M).den :=
    Fsum_den_pos (fun j => Qabs_den_pos (gcornerB_den arctanCoeff arctanCoeff_den_pos t htd j M)) M
  have hCB : 0 < (mul (⟨(2 : Int) ^ (M + 1) - 1, 1⟩ : Q)
      (mul (⟨(M : Int) + 1, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1)))).den :=
    Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos (qpow_den_pos (Qmul_den_pos (by decide) hρd) (M + 1)))
  refine Qle_trans (Qmul_den_pos (Fsum_den_pos (fun _ => hInner) M) hwd1)
    (Qmul_le_mul_right h2ρ (DN_sin_abs_le t htd M hq1)) ?_
  refine Qle_trans (Fsum_den_pos (fun _ => Qmul_den_pos hInner hwd1) M)
    (Qeq_le (Fsum_mul_const_right hwd1 (fun _ => hInner) M)) ?_
  refine Qle_trans (Fsum_den_pos (fun _ => hCB) M)
    (Fsum_le_Fsum_le (fun _ _ => corner_sum_closed_arctan ρ t hρd hρ0 htd hw h2ρ M)) ?_
  exact Qeq_le (Fsum_const_eq (mul (⟨(2 : Int) ^ (M + 1) - 1, 1⟩ : Q)
    (mul (⟨(M : Int) + 1, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1)))) hCB M)

-- ===========================================================================
-- Bridge: peval cosCoeff = altSum (the cos series), connecting to Rcos.
-- ===========================================================================

/-- The even-degree term of `peval cosCoeff` is the `cos` series term `altTerm q 0 n`
    (both `(−1)ⁿ·q^{2n}/(2n)!`; `qpow_negsq` supplies `(−q²)ⁿ = (−1)ⁿ·q^{2n}`). -/
theorem cosCoeff_term_even (q : Q) (hqd : 0 < q.den) (n : Nat) :
    Qeq (mul (cosCoeff (2 * n)) (qpow q (2 * n))) (altTerm q 0 n) := by
  unfold cosCoeff altTerm
  rw [if_pos (by omega : (2 * n) % 2 = 0), show (2 * n) / 2 = n from by omega,
    show 2 * n + 0 = 2 * n from by omega]
  -- P = (−1)ⁿ, F = 1/(2n)!, Qq = q^{2n}.  goal: (P·F)·Qq ≈ (neg(q·q))ⁿ·F
  have hP : 0 < (qpow (⟨-1, 1⟩ : Q) n).den := qpow_den_pos (by decide) n
  have hQq : 0 < (qpow q (2 * n)).den := qpow_den_pos hqd (2 * n)
  have hab : Qeq (mul (mul (qpow (⟨-1, 1⟩ : Q) n) (⟨1, fct (2 * n)⟩ : Q)) (qpow q (2 * n)))
      (mul (mul (qpow (⟨-1, 1⟩ : Q) n) (qpow q (2 * n))) (⟨1, fct (2 * n)⟩ : Q)) :=
    Qeq_trans (Qmul_den_pos hP (Qmul_den_pos (fct_pos (2 * n)) hQq))
      (Qmul_assoc (qpow (⟨-1, 1⟩ : Q) n) (⟨1, fct (2 * n)⟩ : Q) (qpow q (2 * n)))
      (Qeq_trans (Qmul_den_pos hP (Qmul_den_pos hQq (fct_pos (2 * n))))
        (Qmul_congr (Qeq_refl _) (Qmul_comm (⟨1, fct (2 * n)⟩ : Q) (qpow q (2 * n))))
        (Qeq_symm (Qmul_assoc (qpow (⟨-1, 1⟩ : Q) n) (qpow q (2 * n)) (⟨1, fct (2 * n)⟩ : Q))))
  exact Qeq_trans (Qmul_den_pos (Qmul_den_pos hP hQq) (fct_pos (2 * n))) hab
    (Qmul_congr (Qeq_symm (qpow_negsq hqd n)) (Qeq_refl _))

/-- The odd-degree term of `peval cosCoeff` vanishes. -/
theorem cosCoeff_term_odd (q : Q) (n : Nat) :
    Qeq (mul (cosCoeff (2 * n + 1)) (qpow q (2 * n + 1))) ⟨0, 1⟩ := by
  unfold cosCoeff
  rw [if_neg (by omega : ¬ (2 * n + 1) % 2 = 0)]
  show Qeq (mul (⟨0, 1⟩ : Q) (qpow q (2 * n + 1))) ⟨0, 1⟩
  simp only [Qeq, mul]; omega

/-- **Bridge to `altSum` (cos)**: `peval cosCoeff q (2N) ≈ altSum q 0 N` — the degree-indexed eval of
    the `cos` coefficients IS the `n`-indexed `cos` partial sum (`Rcos q = RaltReal q 0` diagonal). -/
theorem peval_cosCoeff_eq_altSum (q : Q) (hqd : 0 < q.den) (N : Nat) :
    Qeq (peval cosCoeff q (2 * N)) (altSum q 0 N) := by
  have hg : ∀ k, 0 < (mul (cosCoeff k) (qpow q k)).den :=
    fun k => Qmul_den_pos (cosCoeff_den_pos k) (qpow_den_pos hqd k)
  induction N with
  | zero => exact cosCoeff_term_even q hqd 0
  | succ n ih =>
    rw [show 2 * (n + 1) = 2 * n + 1 + 1 from by omega]
    show Qeq (add (add (peval cosCoeff q (2 * n)) (mul (cosCoeff (2 * n + 1)) (qpow q (2 * n + 1))))
          (mul (cosCoeff (2 * n + 1 + 1)) (qpow q (2 * n + 1 + 1))))
      (add (altSum q 0 n) (altTerm q 0 (n + 1)))
    have ho : Qeq (mul (cosCoeff (2 * n + 1)) (qpow q (2 * n + 1))) ⟨0, 1⟩ := cosCoeff_term_odd q n
    have he : Qeq (mul (cosCoeff (2 * n + 1 + 1)) (qpow q (2 * n + 1 + 1))) (altTerm q 0 (n + 1)) := by
      have h := cosCoeff_term_even q hqd (n + 1)
      rwa [show 2 * (n + 1) = 2 * n + 1 + 1 from by omega] at h
    refine Qeq_trans (add_den_pos (add_den_pos (altSum_den_pos hqd 0 n) Nat.one_pos)
        (altTerm_den_pos hqd 0 (n + 1)))
      (Qadd_congr (Qadd_congr ih ho) he) ?_
    exact Qadd_congr (Qadd_zero_right (altSum q 0 n)) (Qeq_refl _)

-- ===========================================================================
-- Bridge: peval sinCoeff = q·altSum(·,1) (the sin series), connecting to Rsin = q·RsinAux.
-- ===========================================================================

/-- Four-factor rearrangement `(a·b)·(c·d) ≈ c·((a·d)·b)` (generic, `ring_uor`). -/
theorem Qmul_rearr_sin (a b c d : Q) : Qeq (mul (mul a b) (mul c d)) (mul c (mul (mul a d) b)) := by
  simp only [Qeq, mul]; push_cast; ring_uor

/-- The odd-degree term of `peval sinCoeff` is `q·(sin-aux term)`: `sinCoeff_{2n+1}·q^{2n+1} ≈
    q·altTerm q 1 n` (both `(−1)ⁿ·q^{2n+1}/(2n+1)!`). -/
theorem sinCoeff_term_odd (q : Q) (hqd : 0 < q.den) (n : Nat) :
    Qeq (mul (sinCoeff (2 * n + 1)) (qpow q (2 * n + 1))) (mul q (altTerm q 1 n)) := by
  unfold sinCoeff altTerm
  rw [if_pos (by omega : (2 * n + 1) % 2 = 1), show (2 * n + 1) / 2 = n from by omega]
  have hQq : 0 < (qpow q (2 * n)).den := qpow_den_pos hqd (2 * n)
  exact Qeq_trans (Qmul_den_pos hqd (Qmul_den_pos (Qmul_den_pos (qpow_den_pos (by decide) n) hQq)
      (fct_pos (2 * n + 1))))
    (Qmul_rearr_sin (qpow (⟨-1, 1⟩ : Q) n) (⟨1, fct (2 * n + 1)⟩ : Q) q (qpow q (2 * n)))
    (Qmul_congr (Qeq_refl q) (Qmul_congr (Qeq_symm (qpow_negsq hqd n)) (Qeq_refl _)))

/-- The even-degree term of `peval sinCoeff` vanishes. -/
theorem sinCoeff_term_even (q : Q) (n : Nat) :
    Qeq (mul (sinCoeff (2 * n)) (qpow q (2 * n))) ⟨0, 1⟩ := by
  unfold sinCoeff
  rw [if_neg (by omega : ¬ (2 * n) % 2 = 1)]
  show Qeq (mul (⟨0, 1⟩ : Q) (qpow q (2 * n))) ⟨0, 1⟩
  simp only [Qeq, mul]; omega

/-- **Bridge to `altSum` (sin)**: `peval sinCoeff q (2N+1) ≈ q·altSum q 1 N` — matching `Rsin q =
    q·RsinAux q = q·(RaltReal q 1 diagonal)`. -/
theorem peval_sinCoeff_eq (q : Q) (hqd : 0 < q.den) (N : Nat) :
    Qeq (peval sinCoeff q (2 * N + 1)) (mul q (altSum q 1 N)) := by
  have hg : ∀ k, 0 < (mul (sinCoeff k) (qpow q k)).den :=
    fun k => Qmul_den_pos (sinCoeff_den_pos k) (qpow_den_pos hqd k)
  induction N with
  | zero =>
    show Qeq (add (mul (sinCoeff 0) (qpow q 0)) (mul (sinCoeff 1) (qpow q 1))) (mul q (altTerm q 1 0))
    have he : Qeq (mul (sinCoeff 0) (qpow q 0)) ⟨0, 1⟩ := sinCoeff_term_even q 0
    exact Qeq_trans (add_den_pos Nat.one_pos (Qmul_den_pos hqd (altTerm_den_pos hqd 1 0)))
      (Qadd_congr he (sinCoeff_term_odd q hqd 0)) (Qzero_add (mul q (altTerm q 1 0)))
  | succ n ih =>
    rw [show 2 * (n + 1) + 1 = 2 * n + 1 + 1 + 1 from by omega]
    show Qeq (add (add (peval sinCoeff q (2 * n + 1)) (mul (sinCoeff (2 * n + 2)) (qpow q (2 * n + 2))))
        (mul (sinCoeff (2 * n + 3)) (qpow q (2 * n + 3))))
      (mul q (altSum q 1 (n + 1)))
    have ho : Qeq (mul (sinCoeff (2 * n + 3)) (qpow q (2 * n + 3))) (mul q (altTerm q 1 (n + 1))) := by
      have h := sinCoeff_term_odd q hqd (n + 1)
      rwa [show 2 * (n + 1) + 1 = 2 * n + 3 from by omega] at h
    have he : Qeq (mul (sinCoeff (2 * n + 2)) (qpow q (2 * n + 2))) ⟨0, 1⟩ := by
      have h := sinCoeff_term_even q (n + 1)
      rwa [show 2 * (n + 1) = 2 * n + 2 from by omega] at h
    refine Qeq_trans (add_den_pos (add_den_pos (Qmul_den_pos hqd (altSum_den_pos hqd 1 n)) Nat.one_pos)
        (Qmul_den_pos hqd (altTerm_den_pos hqd 1 (n + 1))))
      (Qadd_congr (Qadd_congr ih he) ho) ?_
    refine Qeq_trans (add_den_pos (Qmul_den_pos hqd (altSum_den_pos hqd 1 n))
        (Qmul_den_pos hqd (altTerm_den_pos hqd 1 (n + 1))))
      (Qadd_congr (Qadd_zero_right (mul q (altSum q 1 n))) (Qeq_refl _)) ?_
    exact Qeq_symm (Qmul_add_left q (altSum q 1 n) (altTerm q 1 (n + 1)))

-- ===========================================================================
-- The cos value bridge (mirror of the sin DN trio; gcornerB/corner machinery reused).
-- ===========================================================================

/-- **`DN` identity (cos)**: `peval(cos∘arctan,t,M) − peval(cos,q,M) = Σₘ cosₘ·(peval(arctanᵐ,t,M) − qᵐ)`. -/
theorem DN_cos_eq (t : Q) (htd : 0 < t.den) (M : Nat) :
    Qeq (Qsub (peval (fcomp cosCoeff arctanCoeff) t M)
          (peval cosCoeff (peval arctanCoeff t M) M))
      (Fsum (fun m => mul (cosCoeff m)
        (Qsub (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m))) M) := by
  have hq : 0 < (peval arctanCoeff t M).den := peval_den_pos arctanCoeff_den_pos htd M
  have hF : ∀ m, 0 < (mul (cosCoeff m) (peval (fpow arctanCoeff m) t M)).den :=
    fun m => Qmul_den_pos (cosCoeff_den_pos m) (peval_den_pos (fpow_den_pos arctanCoeff_den_pos m) htd M)
  have hG : ∀ m, 0 < (mul (cosCoeff m) (qpow (peval arctanCoeff t M) m)).den :=
    fun m => Qmul_den_pos (cosCoeff_den_pos m) (qpow_den_pos hq m)
  refine Qeq_trans (Qsub_den_pos (Fsum_den_pos hF M) (peval_den_pos cosCoeff_den_pos hq M))
    (QsubCongr (peval_fcomp_swap cosCoeff arctanCoeff cosCoeff_den_pos arctanCoeff_den_pos
      arctanCoeff_zero t htd M) (Qeq_refl _)) ?_
  refine Qeq_trans (Fsum_den_pos (fun m => Qsub_den_pos (hF m) (hG m)) M)
    (Qeq_symm (Fsum_sub hF hG M)) ?_
  exact Fsum_congr (fun m => Qeq_symm (Qmul_sub_left_loc (cosCoeff m)
    (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m))) M

/-- **`DN` bound (cos)**: `|peval(cos∘arctan,t,M) − peval(cos,q,M)| ≤ Σₘ Σⱼ|cornerⱼ|`. -/
theorem DN_cos_abs_le (t : Q) (htd : 0 < t.den) (M : Nat)
    (hq1 : Qle (Qabs (peval arctanCoeff t M)) ⟨1, 1⟩) :
    Qle (Qabs (Qsub (peval (fcomp cosCoeff arctanCoeff) t M)
          (peval cosCoeff (peval arctanCoeff t M) M)))
      (Fsum (fun _ => Fsum (fun j => Qabs (gcornerB arctanCoeff t j M)) M) M) := by
  have herr : ∀ m, 0 < (Qsub (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m)).den :=
    fun m => Qsub_den_pos (peval_den_pos (fpow_den_pos arctanCoeff_den_pos m) htd M)
      (qpow_den_pos (peval_den_pos arctanCoeff_den_pos htd M) m)
  have hSE : ∀ m, 0 < (mul (cosCoeff m)
      (Qsub (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m))).den :=
    fun m => Qmul_den_pos (cosCoeff_den_pos m) (herr m)
  refine Qle_trans (Qabs_den_pos (Fsum_den_pos hSE M)) (Qeq_le (Qabs_Qeq (DN_cos_eq t htd M))) ?_
  refine Qle_trans (Fsum_den_pos (fun m => Qabs_den_pos (hSE m)) M) (Fsum_abs_le hSE M) ?_
  refine Fsum_le_congr (fun m hm => ?_)
  refine Qle_trans (Qmul_den_pos (Qabs_den_pos (cosCoeff_den_pos m)) (Qabs_den_pos (herr m)))
    (Qeq_le (by rw [Qabs_mul]; exact Qeq_refl _ :
      Qeq (Qabs (mul (cosCoeff m) (Qsub (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m))))
        (mul (Qabs (cosCoeff m)) (Qabs (Qsub (peval (fpow arctanCoeff m) t M) (qpow (peval arctanCoeff t M) m)))))) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (herr m)))
    (Qmul_le_mul_right (Qabs_num_nonneg _) (cosCoeff_abs_le_one m)) ?_
  exact Qle_trans (Qabs_den_pos (herr m)) (Qeq_le (Qone_mul _)) (e_le_T_arctan t htd M hq1 m hm)

/-- **Closed `DN` bound (cos)**: `|peval(cos∘arctan,t,M) − peval(cos,q,M)|·(1−2ρ) ≤
    (M+1)·(2^{M+1}−1)·(M+1)·(2ρ)^{M+1}` → 0. -/
theorem DN_cos_closed (t ρ : Q) (M : Nat) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num) (htd : 0 < t.den)
    (hw : Qle (Qabs t) ρ) (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hq1 : Qle (Qabs (peval arctanCoeff t M)) ⟨1, 1⟩) :
    Qle (mul (Qabs (Qsub (peval (fcomp cosCoeff arctanCoeff) t M)
            (peval cosCoeff (peval arctanCoeff t M) M))) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ)))
      (mul (⟨(M : Int) + 1, 1⟩ : Q) (mul (⟨(2 : Int) ^ (M + 1) - 1, 1⟩ : Q)
        (mul (⟨(M : Int) + 1, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))))) := by
  have hwd1 : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).den := Qsub_den_pos Nat.one_pos (Qmul_den_pos (by decide) hρd)
  have hInner : 0 < (Fsum (fun j => Qabs (gcornerB arctanCoeff t j M)) M).den :=
    Fsum_den_pos (fun j => Qabs_den_pos (gcornerB_den arctanCoeff arctanCoeff_den_pos t htd j M)) M
  have hCB : 0 < (mul (⟨(2 : Int) ^ (M + 1) - 1, 1⟩ : Q)
      (mul (⟨(M : Int) + 1, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1)))).den :=
    Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos (qpow_den_pos (Qmul_den_pos (by decide) hρd) (M + 1)))
  refine Qle_trans (Qmul_den_pos (Fsum_den_pos (fun _ => hInner) M) hwd1)
    (Qmul_le_mul_right h2ρ (DN_cos_abs_le t htd M hq1)) ?_
  refine Qle_trans (Fsum_den_pos (fun _ => Qmul_den_pos hInner hwd1) M)
    (Qeq_le (Fsum_mul_const_right hwd1 (fun _ => hInner) M)) ?_
  refine Qle_trans (Fsum_den_pos (fun _ => hCB) M)
    (Fsum_le_Fsum_le (fun _ _ => corner_sum_closed_arctan ρ t hρd hρ0 htd hw h2ρ M)) ?_
  exact Qeq_le (Fsum_const_eq (mul (⟨(2 : Int) ^ (M + 1) - 1, 1⟩ : Q)
    (mul (⟨(M : Int) + 1, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1)))) hCB M)

-- ===========================================================================
-- Decay arithmetic: bound the closed DN right-hand side by ρ.den/(n+1).
-- ===========================================================================

/-- `a·(b·(a·p)) ≈ ((a·a)·b)·p` (pulls the two `a` factors and `b` to the front). -/
theorem Qrearr_AABP (a b p : Q) :
    Qeq (mul a (mul b (mul a p))) (mul (mul (mul a a) b) p) := by
  simp only [Qeq, mul]; push_cast; ring_uor

set_option maxHeartbeats 1000000 in
/-- **Decay arithmetic**: the closed `DN_*_closed` right-hand side
    `(M+1)·(2^{M+1}−1)·(M+1)·(2ρ)^{M+1}` is `≤ ρ.den/(n+1)` whenever `n+1 ≤ M`, `4ρ ≤ 1`, and
    `16ρ < 1`. The `(M+1)²` polynomial absorbs into the geometric base only at `ρ < 1/16` (via
    `sq_le_four_pow`: `(M+1)² ≤ 4^M`), matching the doubling radius; the `2^{M+1}` collapses the
    `(2ρ)` base to `(4ρ)`, the surplus `4^M` collapses `(4ρ)` to `(16ρ)`, and `qpow_le_recip` turns
    `(16ρ)^M` into the `C/(n+1)` form `Req_of_lin_bound` consumes. -/
theorem DN_arctan_decay (ρ : Q) (M n : Nat) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num)
    (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hlt : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den) (hMn : n + 1 ≤ M) :
    Qle (mul (⟨(M : Int) + 1, 1⟩ : Q) (mul (⟨(2 : Int) ^ (M + 1) - 1, 1⟩ : Q)
        (mul (⟨(M : Int) + 1, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1)))))
      (⟨(ρ.den : Int), n + 1⟩ : Q) := by
  -- denominator positivity for the pieces
  have hρ2d : 0 < (mul (⟨2, 1⟩ : Q) ρ).den := Qmul_den_pos (by decide) hρd
  have hρ4d : 0 < (mul (⟨4, 1⟩ : Q) ρ).den := Qmul_den_pos (by decide) hρd
  have hρ16d : 0 < (mul (⟨16, 1⟩ : Q) ρ).den := Qmul_den_pos (by decide) hρd
  have hPd : 0 < (qpow (mul (⟨2, 1⟩ : Q) ρ) (M + 1)).den := qpow_den_pos hρ2d (M + 1)
  have hPnn : 0 ≤ (qpow (mul (⟨2, 1⟩ : Q) ρ) (M + 1)).num :=
    qpow_nonneg (Qmul_num_nonneg (by decide) hρ0) (M + 1)
  have hAnn : 0 ≤ (⟨(M : Int) + 1, 1⟩ : Q).num := by show (0 : Int) ≤ (M : Int) + 1; omega
  have hXnn : 0 ≤ (mul (⟨(M : Int) + 1, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))).num :=
    Qmul_num_nonneg hAnn hPnn
  have hB2nn : 0 ≤ (⟨(2 : Int) ^ (M + 1), 1⟩ : Q).num := by
    show (0 : Int) ≤ (2 : Int) ^ (M + 1)
    have hh : (0 : Int) ≤ (((2 : Nat) ^ (M + 1) : Nat) : Int) := Int.ofNat_nonneg _
    push_cast at hh; exact hh
  have hR16nn : 0 ≤ (qpow (mul (⟨16, 1⟩ : Q) ρ) M).num :=
    qpow_nonneg (Qmul_num_nonneg (by decide) hρ0) M
  have h16nn : 0 ≤ (mul (⟨16, 1⟩ : Q) ρ).num := Qmul_num_nonneg (by decide) hρ0
  -- (2^{M+1}-1) ≤ 2^{M+1}
  have hB1le2 : Qle (⟨(2 : Int) ^ (M + 1) - 1, 1⟩ : Q) (⟨(2 : Int) ^ (M + 1), 1⟩ : Q) := by
    simp only [Qle]; push_cast; omega
  -- (M+1)² ≤ 4^M
  have hI : ((M : Int) + 1) * ((M : Int) + 1) ≤ (4 : Int) ^ M := by
    have hnat := sq_le_four_pow M
    have hh : (((M + 1) * (M + 1) : Nat) : Int) ≤ (((4 : Nat) ^ M : Nat) : Int) := by
      exact_mod_cast hnat
    push_cast at hh; exact hh
  have hAAle : Qle (mul (⟨(M : Int) + 1, 1⟩ : Q) (⟨(M : Int) + 1, 1⟩ : Q)) (⟨(4 : Int) ^ M, 1⟩ : Q) := by
    show ((M : Int) + 1) * ((M : Int) + 1) * ((1 : Nat) : Int)
      ≤ (4 : Int) ^ M * (((1 : Nat) * (1 : Nat) : Nat) : Int)
    calc ((M : Int) + 1) * ((M : Int) + 1) * ((1 : Nat) : Int)
        = ((M : Int) + 1) * ((M : Int) + 1) := by push_cast; ring_uor
      _ ≤ (4 : Int) ^ M := hI
      _ = (4 : Int) ^ M * (((1 : Nat) * (1 : Nat) : Nat) : Int) := by push_cast; ring_uor
  -- geometric core: 2^{M+1}·(2ρ)^{M+1} = (4ρ)^{M+1}
  have h4eq : Qeq (mul (mul (⟨2, 1⟩ : Q) ρ) ⟨2, 1⟩) (mul ⟨4, 1⟩ ρ) := by
    simp only [Qeq, mul]; push_cast; ring_uor
  have hcore : Qeq (mul (⟨(2 : Int) ^ (M + 1), 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1)))
      (qpow (mul ⟨4, 1⟩ ρ) (M + 1)) := by
    refine Qeq_trans (Qmul_den_pos hPd Nat.one_pos)
      (mul_comm (⟨(2 : Int) ^ (M + 1), 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))) ?_
    refine Qeq_trans (qpow_den_pos (Qmul_den_pos hρ2d Nat.one_pos) (M + 1))
      (qpow_const_combine 2 (mul ⟨2, 1⟩ ρ) hρ2d (M + 1)) ?_
    exact qpow_Qeq_loc h4eq (M + 1)
  -- (4ρ)^{M+1} = (4ρ)^M·(4ρ)
  have hq1one : Qeq (qpow (mul (⟨4, 1⟩ : Q) ρ) 1) (mul ⟨4, 1⟩ ρ) := by
    show Qeq (mul (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩) (mul ⟨4, 1⟩ ρ)
    exact mul_one (mul ⟨4, 1⟩ ρ)
  have hsplit : Qeq (qpow (mul (⟨4, 1⟩ : Q) ρ) (M + 1))
      (mul (qpow (mul ⟨4, 1⟩ ρ) M) (mul ⟨4, 1⟩ ρ)) :=
    Qeq_trans (Qmul_den_pos (qpow_den_pos hρ4d M) (qpow_den_pos hρ4d 1))
      (qpow_add (mul ⟨4, 1⟩ ρ) hρ4d M 1) (Qmul_congr (Qeq_refl _) hq1one)
  -- 4^M·(4ρ)^M = (16ρ)^M
  have h16eq : Qeq (mul (mul (⟨4, 1⟩ : Q) ρ) ⟨4, 1⟩) (mul ⟨16, 1⟩ ρ) := by
    simp only [Qeq, mul]; push_cast; ring_uor
  have hAcombine : Qeq (mul (⟨(4 : Int) ^ M, 1⟩ : Q) (qpow (mul ⟨4, 1⟩ ρ) M))
      (qpow (mul ⟨16, 1⟩ ρ) M) := by
    refine Qeq_trans (Qmul_den_pos (qpow_den_pos hρ4d M) Nat.one_pos)
      (mul_comm (⟨(4 : Int) ^ M, 1⟩ : Q) (qpow (mul ⟨4, 1⟩ ρ) M)) ?_
    refine Qeq_trans (qpow_den_pos (Qmul_den_pos hρ4d Nat.one_pos) M)
      (qpow_const_combine 4 (mul ⟨4, 1⟩ ρ) hρ4d M) ?_
    exact qpow_Qeq_loc h16eq M
  -- assemble the full geometric equality
  have hgeom : Qeq (mul (⟨(4 : Int) ^ M, 1⟩ : Q)
        (mul (⟨(2 : Int) ^ (M + 1), 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))))
      (mul (qpow (mul ⟨16, 1⟩ ρ) M) (mul ⟨4, 1⟩ ρ)) := by
    refine Qeq_trans (Qmul_den_pos Nat.one_pos (qpow_den_pos hρ4d (M + 1)))
      (Qmul_congr (Qeq_refl _) hcore) ?_
    refine Qeq_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos (qpow_den_pos hρ4d M) hρ4d))
      (Qmul_congr (Qeq_refl _) hsplit) ?_
    refine Qeq_trans (Qmul_den_pos (Qmul_den_pos Nat.one_pos (qpow_den_pos hρ4d M)) hρ4d)
      (Qeq_symm (Qmul_assoc (⟨(4 : Int) ^ M, 1⟩ : Q) (qpow (mul ⟨4, 1⟩ ρ) M) (mul ⟨4, 1⟩ ρ))) ?_
    exact Qmul_congr hAcombine (Qeq_refl _)
  -- final reciprocal conversion
  have hfin : Qeq (⟨((mul (⟨16, 1⟩ : Q) ρ).den : Int), n + 1⟩ : Q) (⟨(ρ.den : Int), n + 1⟩ : Q) := by
    simp only [Qeq, mul]; push_cast; ring_uor
  -- chain everything
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos hPd)))
    (Qmul_le_mul_left hAnn (Qmul_le_mul_right hXnn hB1le2)) ?_
  refine Qle_trans (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos Nat.one_pos Nat.one_pos) Nat.one_pos) hPd)
    (Qeq_le (Qrearr_AABP (⟨(M : Int) + 1, 1⟩ : Q) (⟨(2 : Int) ^ (M + 1), 1⟩ : Q)
      (qpow (mul ⟨2, 1⟩ ρ) (M + 1)))) ?_
  refine Qle_trans (Qmul_den_pos (Qmul_den_pos Nat.one_pos Nat.one_pos) hPd)
    (Qmul_le_mul_right hPnn (Qmul_le_mul_right hB2nn hAAle)) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos hPd))
    (Qeq_le (Qmul_assoc (⟨(4 : Int) ^ M, 1⟩ : Q) (⟨(2 : Int) ^ (M + 1), 1⟩ : Q)
      (qpow (mul ⟨2, 1⟩ ρ) (M + 1)))) ?_
  refine Qle_trans (Qmul_den_pos (qpow_den_pos hρ16d M) hρ4d) (Qeq_le hgeom) ?_
  refine Qle_trans (Qmul_den_pos (qpow_den_pos hρ16d M) Nat.one_pos)
    (Qmul_le_mul_left hR16nn hρ4) ?_
  refine Qle_trans (qpow_den_pos hρ16d M) (Qeq_le (mul_one (qpow (mul ⟨16, 1⟩ ρ) M))) ?_
  exact Qle_trans (Nat.succ_pos n) (qpow_le_recip h16nn hρ16d hlt hMn) (Qeq_le hfin)

set_option maxHeartbeats 1000000 in
/-- **sin composition gap, reciprocal form**: `|sin∘arctan eval − sin(arctan eval)| ≤ 2·ρ.den/(n+1)`
    for `n+1 ≤ M`, `ρ ≤ 1/4` (so `1−2ρ ≥ 1/2`) and `16ρ < 1`. Combines `DN_sin_closed`
    (`|D|·(1−2ρ) ≤ closed`) via `mul_div2` with `DN_arctan_decay` (`closed ≤ ρ.den/(n+1)`). This is
    the per-index input `Req_of_lin_bound` consumes for the sin side of `tan(arctan t) = t`. -/
theorem DN_sin_recip (t ρ : Q) (M n : Nat) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num) (htd : 0 < t.den)
    (hw : Qle (Qabs t) ρ) (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ)))
    (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hlt : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den) (hMn : n + 1 ≤ M)
    (hq1 : Qle (Qabs (peval arctanCoeff t M)) ⟨1, 1⟩) :
    Qle (Qabs (Qsub (peval (fcomp sinCoeff arctanCoeff) t M)
            (peval sinCoeff (peval arctanCoeff t M) M)))
      (⟨2 * (ρ.den : Int), n + 1⟩ : Q) := by
  have hFd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).den :=
    Qsub_den_pos Nat.one_pos (Qmul_den_pos (by decide) hρd)
  have hBd : 0 < (mul (⟨(M : Int) + 1, 1⟩ : Q) (mul (⟨(2 : Int) ^ (M + 1) - 1, 1⟩ : Q)
      (mul (⟨(M : Int) + 1, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))))).den :=
    Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos
      (Qmul_den_pos Nat.one_pos (qpow_den_pos (Qmul_den_pos (by decide) hρd) (M + 1))))
  have had : 0 < (Qabs (Qsub (peval (fcomp sinCoeff arctanCoeff) t M)
      (peval sinCoeff (peval arctanCoeff t M) M))).den :=
    Qabs_den_pos (Qsub_den_pos
      (peval_den_pos (fun k => fcomp_den_pos sinCoeff_den_pos arctanCoeff_den_pos k) htd M)
      (peval_den_pos sinCoeff_den_pos (peval_den_pos arctanCoeff_den_pos htd M) M))
  have hstep := mul_div2 (Qabs_num_nonneg _) had hFd hBd hhalf
    (DN_sin_closed t ρ M hρd hρ0 htd hw h2ρ hq1)
  refine Qle_trans (Qmul_den_pos (by decide) hBd) hstep ?_
  refine Qle_trans (Qmul_den_pos (by decide) (Nat.succ_pos n))
    (Qmul_le_mul_left (by decide) (DN_arctan_decay ρ M n hρd hρ0 hρ4 hlt hMn)) ?_
  exact Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor)

set_option maxHeartbeats 1000000 in
/-- **cos composition gap, reciprocal form**: `|cos∘arctan eval − cos(arctan eval)| ≤ 2·ρ.den/(n+1)`.
    The cos analogue of `DN_sin_recip` (via `DN_cos_closed` + `DN_arctan_decay`). -/
theorem DN_cos_recip (t ρ : Q) (M n : Nat) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num) (htd : 0 < t.den)
    (hw : Qle (Qabs t) ρ) (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ)))
    (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hlt : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den) (hMn : n + 1 ≤ M)
    (hq1 : Qle (Qabs (peval arctanCoeff t M)) ⟨1, 1⟩) :
    Qle (Qabs (Qsub (peval (fcomp cosCoeff arctanCoeff) t M)
            (peval cosCoeff (peval arctanCoeff t M) M)))
      (⟨2 * (ρ.den : Int), n + 1⟩ : Q) := by
  have hFd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).den :=
    Qsub_den_pos Nat.one_pos (Qmul_den_pos (by decide) hρd)
  have hBd : 0 < (mul (⟨(M : Int) + 1, 1⟩ : Q) (mul (⟨(2 : Int) ^ (M + 1) - 1, 1⟩ : Q)
      (mul (⟨(M : Int) + 1, 1⟩ : Q) (qpow (mul ⟨2, 1⟩ ρ) (M + 1))))).den :=
    Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos
      (Qmul_den_pos Nat.one_pos (qpow_den_pos (Qmul_den_pos (by decide) hρd) (M + 1))))
  have had : 0 < (Qabs (Qsub (peval (fcomp cosCoeff arctanCoeff) t M)
      (peval cosCoeff (peval arctanCoeff t M) M))).den :=
    Qabs_den_pos (Qsub_den_pos
      (peval_den_pos (fun k => fcomp_den_pos cosCoeff_den_pos arctanCoeff_den_pos k) htd M)
      (peval_den_pos cosCoeff_den_pos (peval_den_pos arctanCoeff_den_pos htd M) M))
  have hstep := mul_div2 (Qabs_num_nonneg _) had hFd hBd hhalf
    (DN_cos_closed t ρ M hρd hρ0 htd hw h2ρ hq1)
  refine Qle_trans (Qmul_den_pos (by decide) hBd) hstep ?_
  refine Qle_trans (Qmul_den_pos (by decide) (Nat.succ_pos n))
    (Qmul_le_mul_left (by decide) (DN_arctan_decay ρ M n hρd hρ0 hρ4 hlt hMn)) ?_
  exact Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor)

-- ===========================================================================
-- Formal-identity algebra: peval(sin∘arctan) = t·peval(cos∘arctan) (degree shift).
-- ===========================================================================

/-- **Xident shift under `peval`**: `peval (X·G) t (m+1) = t·peval G t m`. Multiplying a series by the
    identity `Xident` (support `{1}`) shifts every degree up by one, so the evaluated truncation
    factors a single `t` out and drops one term. (`fmul_Xident`/`fmul_Xident_zero` termwise, then the
    `qpow` successor and left-distribution.) -/
theorem peval_fmul_Xident_shift (G : Nat → Q) (hG : ∀ i, 0 < (G i).den) (t : Q) (htd : 0 < t.den) :
    ∀ m, Qeq (peval (fmul Xident G) t (m + 1)) (mul t (peval G t m))
  | 0 => by
      show Qeq (add (mul (fmul Xident G 0) (qpow t 0)) (mul (fmul Xident G 1) (qpow t 1)))
        (mul t (mul (G 0) (qpow t 0)))
      have h0 : Qeq (mul (fmul Xident G 0) (qpow t 0)) ⟨0, 1⟩ := by
        refine Qeq_trans (Qmul_den_pos Nat.one_pos (qpow_den_pos htd 0))
          (Qmul_congr (fmul_Xident_zero G) (Qeq_refl _)) ?_
        simp only [Qeq, mul]; omega
      have h1 : Qeq (mul (fmul Xident G 1) (qpow t 1)) (mul t (mul (G 0) (qpow t 0))) := by
        refine Qeq_trans (Qmul_den_pos (hG 0) (qpow_den_pos htd 1))
          (Qmul_congr (fmul_Xident G hG 0) (Qeq_refl _)) ?_
        show Qeq (mul (G 0) (mul t (qpow t 0))) (mul t (mul (G 0) (qpow t 0)))
        simp only [Qeq, mul]; push_cast; ring_uor
      refine Qeq_trans (add_den_pos Nat.one_pos
          (Qmul_den_pos htd (Qmul_den_pos (hG 0) (qpow_den_pos htd 0))))
        (Qadd_congr h0 h1) ?_
      exact Qzero_add (mul t (mul (G 0) (qpow t 0)))
  | (m + 1) => by
      show Qeq (add (peval (fmul Xident G) t (m + 1)) (mul (fmul Xident G (m + 2)) (qpow t (m + 2))))
        (mul t (add (peval G t m) (mul (G (m + 1)) (qpow t (m + 1)))))
      have ih := peval_fmul_Xident_shift G hG t htd m
      have hterm : Qeq (mul (fmul Xident G (m + 2)) (qpow t (m + 2)))
          (mul t (mul (G (m + 1)) (qpow t (m + 1)))) := by
        refine Qeq_trans (Qmul_den_pos (hG (m + 1)) (qpow_den_pos htd (m + 2)))
          (Qmul_congr (fmul_Xident G hG (m + 1)) (Qeq_refl _)) ?_
        show Qeq (mul (G (m + 1)) (mul t (qpow t (m + 1)))) (mul t (mul (G (m + 1)) (qpow t (m + 1))))
        simp only [Qeq, mul]; push_cast; ring_uor
      refine Qeq_trans (add_den_pos
          (Qmul_den_pos htd (peval_den_pos hG htd m))
          (Qmul_den_pos htd (Qmul_den_pos (hG (m + 1)) (qpow_den_pos htd (m + 1)))))
        (Qadd_congr ih hterm) ?_
      exact Qeq_symm (Qmul_add_left t (peval G t m) (mul (G (m + 1)) (qpow t (m + 1))))

/-- **Value form of `sin∘arctan = t·(cos∘arctan)` with the degree shift made explicit**:
    `peval(sin∘arctan, t, m+1) = t·peval(cos∘arctan, t, m)`. Composes the formal identity
    `peval_sin_arctan_eq` (`sin∘arctan = Xident·(cos∘arctan)`) with the `Xident` shift. This is the
    algebraic hinge of `tan(arctan t) = t`: once both compositions converge to `Rsin`/`Rcos∘arctan`,
    this passes the identity to the value limit (no division — `sin = t·cos` directly). -/
theorem peval_sin_arctan_shift (t : Q) (htd : 0 < t.den) (m : Nat) :
    Qeq (peval (fcomp sinCoeff arctanCoeff) t (m + 1))
      (mul t (peval (fcomp cosCoeff arctanCoeff) t m)) :=
  Qeq_trans (peval_den_pos (fun k => fmul_den_pos Xident_den_pos
        (fun i => fcomp_den_pos cosCoeff_den_pos arctanCoeff_den_pos i) k) htd (m + 1))
    (peval_sin_arctan_eq t (m + 1))
    (peval_fmul_Xident_shift (fcomp cosCoeff arctanCoeff)
      (fun i => fcomp_den_pos cosCoeff_den_pos arctanCoeff_den_pos i) t htd m)

-- ===========================================================================
-- Diagonal ↔ peval identification: connect Rcos/Rsin(X) diagonals to the
-- peval cosCoeff/sinCoeff forms (entry point for the nested-diagonal bridge).
-- ===========================================================================

/-- **Rcos diagonal as a peval**: `(Rcos X).seq j = peval cosCoeff (X.seq D) (2D)` with
    `D = RaltReal_R X j` — the alternating cos partial sum at the diagonal depth is exactly the
    `cosCoeff` truncation (`peval_cosCoeff_eq_altSum`). The identification feeding the
    nested-diagonal reconciliation of `tan(arctan t) = t`. -/
theorem Rcos_seq_eq_peval (X : Real) (j : Nat) :
    Qeq ((Rcos X).seq j)
      (peval cosCoeff (X.seq (RaltReal_R X j)) (2 * RaltReal_R X j)) :=
  Qeq_symm (peval_cosCoeff_eq_altSum (X.seq (RaltReal_R X j)) (X.den_pos _) (RaltReal_R X j))

/-- **RsinAux diagonal as an altSum** (definitional): `(RsinAux X).seq j = altSum (X.seq D) 1 D`,
    the `sin/x` series at the diagonal depth `D = RaltReal_R X j`. -/
theorem RsinAux_seq_eq_altSum (X : Real) (j : Nat) :
    (RsinAux X).seq j = altSum (X.seq (RaltReal_R X j)) 1 (RaltReal_R X j) := rfl

/-- **Genuine sin value as a peval**: `X.seq D · (RsinAux X).seq j = peval sinCoeff (X.seq D) (2D+1)`
    (`D = RaltReal_R X j`). Since `Rsin X = X · RsinAux X`, the value-level `sin` at the diagonal depth
    is the `sinCoeff` truncation (`peval_sinCoeff_eq`: `peval sin q (2N+1) = q·altSum(q,1,N)`). The
    identification feeding the sin side of `tan(arctan t) = t`. -/
theorem RsinAux_seq_eq_peval (X : Real) (j : Nat) :
    Qeq (mul (X.seq (RaltReal_R X j)) ((RsinAux X).seq j))
      (peval sinCoeff (X.seq (RaltReal_R X j)) (2 * RaltReal_R X j + 1)) := by
  rw [RsinAux_seq_eq_altSum]
  exact Qeq_symm (peval_sinCoeff_eq (X.seq (RaltReal_R X j)) (X.den_pos _) (RaltReal_R X j))

/-- **`peval` respects `≈` of its argument**: `q ≈ q' ⟹ peval c q N ≈ peval c q' N` (termwise via
    `qpow_Qeq`). Lets the inner arctan argument be rewritten between its `peval`/`arctanSum` forms. -/
theorem peval_arg_congr (c : Nat → Q) {q q' : Q} (h : Qeq q q') (N : Nat) :
    Qeq (peval c q N) (peval c q' N) :=
  Fsum_congr (fun k => Qmul_congr (Qeq_refl (c k)) (qpow_Qeq h k)) N

/-- **arctan at even depth**: `peval arctanCoeff t (2E+2) = arctanSum t E` — the cos truncation depth
    `2D` from `Rcos` is even, but the top (even-degree) arctan term vanishes, so the arctan argument at
    that depth is still the `E`-term partial sum (`peval_arctanCoeff_eq_arctanSum` + the vanishing even
    term). Matches the `Rcos` outer depth to the arctan reindex for the nested-diagonal bridge. -/
theorem peval_arctanCoeff_even (t : Q) (htd : 0 < t.den) (E : Nat) :
    Qeq (peval arctanCoeff t (2 * E + 2)) (arctanSum t E) := by
  show Qeq (add (peval arctanCoeff t (2 * E + 1)) (mul (arctanCoeff (2 * E + 2)) (qpow t (2 * E + 2))))
    (arctanSum t E)
  refine Qeq_trans (add_den_pos (arctanSum_den_pos htd E) Nat.one_pos)
    (Qadd_congr (peval_arctanCoeff_eq_arctanSum t htd E) (arctanCoeff_term_even t E)) ?_
  exact Qadd_zero_right (arctanSum t E)

/-- **arctan partial sum is bounded by 1**: `|arctanSum t N| ≤ 1` for `|t| ≤ ρ`, `1/2 ≤ 1−ρ²`,
    `2ρ ≤ 1`. (`arctanSum_abs_le` ≤ `geoSum ρ N` ≤ `2ρ` ≤ `1`, mirroring `peval_kdbl_abs_le_one`.)
    Supplies the `M = 1` argument bound for `peval_cosCoeff_Lip` in the nested-diagonal bridge. -/
theorem arctanSum_abs_le_one {t ρ : Q} (htd : 0 < t.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (htρ : Qle (Qabs t) ρ) (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ)))
    (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩) (N : Nat) : Qle (Qabs (arctanSum t N)) ⟨1, 1⟩ := by
  have hg : Qle (geoSum ρ N) (mul ⟨2, 1⟩ (qpow ρ 1)) :=
    mul_div2 (geoSum_num_nonneg hρ0 N) (geoSum_den_pos hρd N)
      (Qsub_den_pos Nat.one_pos (Qmul_den_pos hρd hρd)) (qpow_den_pos hρd 1) hρ2
      (geoSum_tel_le ρ hρd hρ0 N)
  refine Qle_trans (geoSum_den_pos hρd N) (arctanSum_abs_le htd hρ0 hρd htρ N) ?_
  refine Qle_trans (Qmul_den_pos (by decide) (qpow_den_pos hρd 1)) hg ?_
  refine Qle_trans (Qmul_den_pos (by decide) hρd)
    (Qeq_le (Qmul_congr (Qeq_refl _) (mul_one ρ))) hρ8

-- ===========================================================================
-- cos argument-Lipschitz at fixed depth (reduces the cos argument-gap to |q−q'|).
-- ===========================================================================

/-- `0 ≤ (LipS M N).num` (the Lipschitz constant is a sum of non-negative `Pbound/fct` terms). -/
theorem LipS_num_nonneg (M : Nat) : ∀ N, 0 ≤ (LipS M N).num
  | 0 => Int.ofNat_nonneg _
  | (n + 1) => Qadd_num_nonneg_loc (LipS_num_nonneg M n) (Int.ofNat_nonneg _)

set_option maxHeartbeats 1000000 in
/-- **cos argument-Lipschitz**: `|peval cos q (2N) − peval cos q' (2N)| ≤ LipS(M²,N)·2M·|q−q'|`
    for `|q|,|q'| ≤ M`. Rewrites both truncations to `altSum` (`peval_cosCoeff_eq_altSum`), applies the
    alternating-series Lipschitz bound (`altSum_Lip_le`), and reduces the `−q²` base-gap to `|q−q'|`
    (`qsq_diff_le`). Absorbs the inner-depth mismatch of the nested-diagonal bridge: replacing the
    cos argument by a nearby value costs only `|q−q'|` (times a bounded constant). -/
theorem peval_cosCoeff_Lip (q q' : Q) (M N : Nat) (hqd : 0 < q.den) (hq'd : 0 < q'.den)
    (hq : Qle (Qabs q) ⟨(M : Int), 1⟩) (hq' : Qle (Qabs q') ⟨(M : Int), 1⟩) :
    Qle (Qabs (Qsub (peval cosCoeff q (2 * N)) (peval cosCoeff q' (2 * N))))
      (mul (LipS (M * M) N) (mul (⟨(2 * M : Nat), 1⟩ : Q) (Qabs (Qsub q q')))) := by
  have hcongr : Qeq (Qabs (Qsub (peval cosCoeff q (2 * N)) (peval cosCoeff q' (2 * N))))
      (Qabs (Qsub (altSum q 0 N) (altSum q' 0 N))) :=
    Qabs_Qeq (Qsub_congr (peval_cosCoeff_eq_altSum q hqd N) (peval_cosCoeff_eq_altSum q' hq'd N))
  refine Qle_congr_left
    (Qabs_den_pos (Qsub_den_pos (altSum_den_pos hqd 0 N) (altSum_den_pos hq'd 0 N)))
    (Qeq_symm hcongr) ?_
  refine Qle_trans (Qmul_den_pos (LipS_den_pos (M * M) N)
      (Qabs_den_pos (Qsub_den_pos (Nat.mul_pos hqd hqd) (Nat.mul_pos hq'd hq'd))))
    (altSum_Lip_le hqd hq'd hq hq' 0 N) ?_
  exact Qmul_le_mul_left (LipS_num_nonneg (M * M) N) (qsq_diff_le hqd hq'd hq hq')

/-- `geoSum` is monotone in the truncation length (`a ≤ b ⟹ geoSum ρ a ≤ geoSum ρ b`), since each
    added `geoTerm = ρ^{2k+1} ≥ 0`. -/
theorem geoSum_mono (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) {a b : Nat} (hab : a ≤ b) :
    Qle (geoSum ρ a) (geoSum ρ b) := by
  induction hab with
  | refl => exact Qle_refl _
  | @step k _ ih =>
      refine Qle_trans (geoSum_den_pos hρd k) ih ?_
      show Qle (geoSum ρ k) (add (geoSum ρ k) (geoTerm ρ (k + 1)))
      exact Qle_self_add (qpow_nonneg hρ0 _)

/-- **Geometric arctan-tail decay**: `geoSum ρ b − geoSum ρ a ≤ 2·ρ.den/(n+1)` for `a ≤ b`,
    `n+1 ≤ 2a+3`, `ρ < 1`, `ρ² ≤ 1/2`. Strips the `(1−ρ²)` from `geo_diff_bound` (via `mul_div2`) and
    converts the `ρ^{2a+3}` geometric tail to the `C/(n+1)` form (`qpow_le_recip`). The cos-argument-gap
    analogue of `DN_arctan_decay` — the inner-depth tail in reciprocal form. -/
theorem geoSum_diff_recip (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) {a b n : Nat} (hab : a ≤ b) (hn : n + 1 ≤ 2 * a + 3) :
    Qle (Qsub (geoSum ρ b) (geoSum ρ a)) (⟨2 * (ρ.den : Int), n + 1⟩ : Q) := by
  have hstep : Qle (Qsub (geoSum ρ b) (geoSum ρ a)) (mul ⟨2, 1⟩ (qpow ρ (2 * a + 3))) :=
    mul_div2 (Qsub_num_nonneg (geoSum_mono ρ hρ0 hρd hab))
      (Qsub_den_pos (geoSum_den_pos hρd b) (geoSum_den_pos hρd a))
      (Qsub_den_pos Nat.one_pos (Qmul_den_pos hρd hρd)) (qpow_den_pos hρd _) hρ2
      (geo_diff_bound hρ0 hρd hab)
  refine Qle_trans (Qmul_den_pos (by decide) (qpow_den_pos hρd _)) hstep ?_
  refine Qle_trans (Qmul_den_pos (by decide) (Nat.succ_pos n))
    (Qmul_le_mul_left (by decide) (qpow_le_recip hρ0 hρd hlt hn)) ?_
  exact Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor)

set_option maxHeartbeats 1000000 in
/-- **cos at two arctan depths**: `|peval cos (arctanSum t b)(2D) − peval cos (arctanSum t a)(2D)|
    ≤ LipS(1,D)·2·(geoSum ρ b − geoSum ρ a)` for `a ≤ b`. Combines `peval_cosCoeff_Lip` (cos
    argument-Lipschitz, both arctan partial sums `≤ 1` via `arctanSum_abs_le_one`) with the arctan
    truncation gap (`arctanSum_abs_diff_le`). The arctan inner-depth mismatch of the nested-diagonal
    bridge, bounded by the geometric arctan tail (times the uniformly-bounded `LipS` constant). -/
theorem peval_cosCoeff_arctan_argdiff (t ρ : Q) (htd : 0 < t.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (htρ : Qle (Qabs t) ρ) (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ)))
    (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩) {a b : Nat} (hab : a ≤ b) (D : Nat) :
    Qle (Qabs (Qsub (peval cosCoeff (arctanSum t b) (2 * D)) (peval cosCoeff (arctanSum t a) (2 * D))))
      (mul (LipS 1 D) (mul ⟨2, 1⟩ (Qsub (geoSum ρ b) (geoSum ρ a)))) := by
  have hb1 := arctanSum_abs_le_one htd hρ0 hρd htρ hρ2 hρ8 b
  have ha1 := arctanSum_abs_le_one htd hρ0 hρd htρ hρ2 hρ8 a
  refine Qle_trans (Qmul_den_pos (LipS_den_pos 1 D) (Qmul_den_pos (by decide)
      (Qabs_den_pos (Qsub_den_pos (arctanSum_den_pos htd b) (arctanSum_den_pos htd a)))))
    (peval_cosCoeff_Lip (arctanSum t b) (arctanSum t a) 1 D (arctanSum_den_pos htd b)
      (arctanSum_den_pos htd a) hb1 ha1) ?_
  exact Qmul_le_mul_left (LipS_num_nonneg 1 D)
    (Qmul_le_mul_left (by decide) (arctanSum_abs_diff_le htd hρ0 hρd htρ hab))

set_option maxHeartbeats 1000000 in
/-- **cos arctan-depth gap, reciprocal form**: `|peval cos (arctanSum t b)(2D) − peval cos
    (arctanSum t a)(2D)| ≤ U·4·ρ.den/(n+1)` (`U = (expM_U 1 2).num.toNat`) for `a ≤ b`, `n+1 ≤ 2a+3`.
    Bounds the varying `LipS(1,D)` by the uniform constant `U` (`LipS_le_U` + `Qle_toNat`) and the
    `geoSum` gap by the reciprocal (`geoSum_diff_recip`). The cos inner-depth mismatch fully in the
    `C/(n+1)` form `Req_of_lin_bound` consumes — constant independent of the (growing) depth `D`. -/
theorem peval_cosCoeff_arctan_argdiff_recip (t ρ : Q) (htd : 0 < t.den) (hρ0 : 0 ≤ ρ.num)
    (hρd : 0 < ρ.den) (htρ : Qle (Qabs t) ρ) (hlt : ρ.num.toNat < ρ.den)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    {a b n : Nat} (hab : a ≤ b) (hn : n + 1 ≤ 2 * a + 3) (D : Nat) :
    Qle (Qabs (Qsub (peval cosCoeff (arctanSum t b) (2 * D)) (peval cosCoeff (arctanSum t a) (2 * D))))
      (⟨((expM_U 1 2).num.toNat : Int) * (4 * (ρ.den : Int)), n + 1⟩ : Q) := by
  have hgapnn : 0 ≤ (mul (⟨2, 1⟩ : Q) (Qsub (geoSum ρ b) (geoSum ρ a))).num :=
    Qmul_num_nonneg (by decide) (Qsub_num_nonneg (geoSum_mono ρ hρ0 hρd hab))
  have hUnn : 0 ≤ (⟨((expM_U 1 2).num.toNat : Int), 1⟩ : Q).num := Int.ofNat_nonneg _
  have hLipU : Qle (LipS 1 D) (⟨((expM_U 1 2).num.toNat : Int), 1⟩ : Q) :=
    Qle_trans (expM_U_den_pos 1 2) (LipS_le_U 1 D)
      (Qle_toNat (expM_U_num_nonneg 1 2) (expM_U_den_pos 1 2))
  refine Qle_trans (Qmul_den_pos (LipS_den_pos 1 D) (Qmul_den_pos (by decide)
      (Qsub_den_pos (geoSum_den_pos hρd b) (geoSum_den_pos hρd a))))
    (peval_cosCoeff_arctan_argdiff t ρ htd hρ0 hρd htρ hρ2 hρ8 hab D) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos (by decide)
      (Qsub_den_pos (geoSum_den_pos hρd b) (geoSum_den_pos hρd a))))
    (Qmul_le_mul_right hgapnn hLipU) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos (by decide) (Nat.succ_pos n)))
    (Qmul_le_mul_left hUnn (Qmul_le_mul_left (by decide)
      (geoSum_diff_recip ρ hρ0 hρd hlt hρ2 hab hn))) ?_
  exact Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor)

set_option maxHeartbeats 1600000 in
/-- **cos nested-diagonal bound (general depth)**: at depth `2(E+1)`, the cos series evaluated at the
    arctan partial sum `arctanSum t₀ b` (`E ≤ b`) is within `(U·4·ρ.den + 2·ρ.den)/(n+1)` of the
    composed series `cos∘arctan` evaluated at `t₀`. Triangle through `peval cos (peval arctan t₀ M) M`:
    the arctan inner-depth gap (`peval_cosCoeff_arctan_argdiff_recip`, after matching the even depth
    `2(E+1)` to `arctanSum t₀ E` via `peval_arctanCoeff_even`/`peval_arg_congr`) plus the
    composition gap (`DN_cos_recip`). The analytic core of the cos side of `tan(arctan t)=t`. -/
theorem cos_nested_general (t₀ ρ : Q) (htd : 0 < t₀.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den) (htρ : Qle (Qabs t₀) ρ)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hlt : ρ.num.toNat < ρ.den) (E b n : Nat) (hbE : E ≤ b) (hnb : n + 1 ≤ 2 * E + 3)
    (hnD : n + 1 ≤ 2 * (E + 1)) :
    Qle (Qabs (Qsub (peval cosCoeff (arctanSum t₀ b) (2 * (E + 1)))
        (peval (fcomp cosCoeff arctanCoeff) t₀ (2 * (E + 1)))))
      (⟨((expM_U 1 2).num.toNat : Int) * (4 * (ρ.den : Int)) + 2 * (ρ.den : Int), n + 1⟩ : Q) := by
  -- arctan argument at the even depth is bounded by 1
  have hq1 : Qle (Qabs (peval arctanCoeff t₀ (2 * (E + 1)))) ⟨1, 1⟩ :=
    Qle_congr_left (Qabs_den_pos (arctanSum_den_pos htd E))
      (Qabs_Qeq (Qeq_symm (peval_arctanCoeff_even t₀ htd E)))
      (arctanSum_abs_le_one htd hρ0 hρd htρ hρ2 hρ8 E)
  -- denominators of the three triangle points
  have hAd : 0 < (peval cosCoeff (arctanSum t₀ b) (2 * (E + 1))).den :=
    peval_den_pos cosCoeff_den_pos (arctanSum_den_pos htd b) (2 * (E + 1))
  have hMd : 0 < (peval cosCoeff (peval arctanCoeff t₀ (2 * (E + 1))) (2 * (E + 1))).den :=
    peval_den_pos cosCoeff_den_pos (peval_den_pos arctanCoeff_den_pos htd (2 * (E + 1))) (2 * (E + 1))
  have hCd : 0 < (peval (fcomp cosCoeff arctanCoeff) t₀ (2 * (E + 1))).den :=
    peval_den_pos (fun k => fcomp_den_pos cosCoeff_den_pos arctanCoeff_den_pos k) htd (2 * (E + 1))
  -- leg I: arg gap (midpoint argument rewritten to arctanSum t₀ E)
  have harg : Qeq (peval cosCoeff (peval arctanCoeff t₀ (2 * (E + 1))) (2 * (E + 1)))
      (peval cosCoeff (arctanSum t₀ E) (2 * (E + 1))) :=
    peval_arg_congr cosCoeff (peval_arctanCoeff_even t₀ htd E) (2 * (E + 1))
  have hI : Qle (Qabs (Qsub (peval cosCoeff (arctanSum t₀ b) (2 * (E + 1)))
        (peval cosCoeff (peval arctanCoeff t₀ (2 * (E + 1))) (2 * (E + 1)))))
      (⟨((expM_U 1 2).num.toNat : Int) * (4 * (ρ.den : Int)), n + 1⟩ : Q) :=
    Qle_congr_left (Qabs_den_pos (Qsub_den_pos hAd
        (peval_den_pos cosCoeff_den_pos (arctanSum_den_pos htd E) (2 * (E + 1)))))
      (Qabs_Qeq (Qsub_congr (Qeq_refl _) (Qeq_symm harg)))
      (peval_cosCoeff_arctan_argdiff_recip t₀ ρ htd hρ0 hρd htρ hlt hρ2 hρ8 hbE hnb (E + 1))
  -- leg II: composition gap (DN_cos_recip)
  have hII : Qle (Qabs (Qsub (peval cosCoeff (peval arctanCoeff t₀ (2 * (E + 1))) (2 * (E + 1)))
        (peval (fcomp cosCoeff arctanCoeff) t₀ (2 * (E + 1))))) (⟨2 * (ρ.den : Int), n + 1⟩ : Q) := by
    rw [Qabs_Qsub_comm]
    exact DN_cos_recip t₀ ρ (2 * (E + 1)) n hρd hρ0 htd htρ h2ρ hhalf hρ4 hlt16 hnD hq1
  -- combine via the triangle
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hAd hMd))
      (Qabs_den_pos (Qsub_den_pos hMd hCd))) (Qabs_sub_triangle hAd hMd hCd) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)) (Qadd_le_add hI hII) ?_
  exact Qeq_le (Qadd_same_den_loc (((expM_U 1 2).num.toNat : Int) * (4 * (ρ.den : Int)))
    (2 * (ρ.den : Int)) (n + 1))

set_option maxHeartbeats 1600000 in
/-- **cos nested-diagonal bound (real arctan)**: `|(Rcos (Rarctan t₀)).seq j − peval(cos∘arctan) t₀
    (2D)| ≤ (U·4ρ.den + 2ρ.den)/(j+1)`, `D = RaltReal_R (Rarctan t₀) j`. Wraps `cos_nested_general`
    for the genuine `Rcos` of the fixed-rational arctan real: transports the `Rcos` diagonal to the
    `peval cos` form (`Rcos_seq_eq_peval`) and discharges the depth bookkeeping
    (`D = E+1 ≥ j+1`, `E ≤ Rartanh_R ρ (E+1)`). The cos side of `tan(arctan t)=t` for the real object. -/
theorem Rcos_arctan_nested (t₀ ρ : Q) (htd : 0 < t₀.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (htρ : Qle (Qabs t₀) ρ)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩) (j : Nat) :
    Qle (Qabs (Qsub ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq j)
        (peval (fcomp cosCoeff arctanCoeff) t₀ (2 * RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ) j))))
      (⟨((expM_U 1 2).num.toNat : Int) * (4 * (ρ.den : Int)) + 2 * (ρ.den : Int), j + 1⟩ : Q) := by
  have hK1 : 1 ≤ RaltReal_K (Rarctan t₀ htd hρ0 hρd hlt htρ) := by unfold RaltReal_K; omega
  have hDj : j + 1 ≤ RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ) j := by
    have h4 : 4 * (j + 1) * 1 ≤ 4 * (j + 1) * RaltReal_K (Rarctan t₀ htd hρ0 hρd hlt htρ) :=
      Nat.mul_le_mul (Nat.le_refl _) hK1
    have hge : 4 * (j + 1) * RaltReal_K (Rarctan t₀ htd hρ0 hρd hlt htρ)
        ≤ RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ) j := by unfold RaltReal_R; omega
    omega
  obtain ⟨E, hE⟩ : ∃ E, RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ) j = E + 1 :=
    ⟨RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ) j - 1, by omega⟩
  have hrw : Qeq (Qabs (Qsub ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq j)
        (peval (fcomp cosCoeff arctanCoeff) t₀ (2 * RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ) j))))
      (Qabs (Qsub (peval cosCoeff
          ((Rarctan t₀ htd hρ0 hρd hlt htρ).seq (RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ) j))
          (2 * RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ) j))
        (peval (fcomp cosCoeff arctanCoeff) t₀ (2 * RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ) j)))) :=
    Qabs_Qeq (Qsub_congr (Rcos_seq_eq_peval (Rarctan t₀ htd hρ0 hρd hlt htρ) j) (Qeq_refl _))
  refine Qle_congr_left
    (Qabs_den_pos (Qsub_den_pos
      (peval_den_pos cosCoeff_den_pos ((Rarctan t₀ htd hρ0 hρd hlt htρ).den_pos _) _)
      (peval_den_pos (fun k => fcomp_den_pos cosCoeff_den_pos arctanCoeff_den_pos k) htd _)))
    (Qeq_symm hrw) ?_
  rw [hE]
  have hRge : ∀ m, m + 1 ≤ Rartanh_R ρ m := by
    intro m; unfold Rartanh_R
    have hk : 1 ≤ ρ.den * ρ.den + 4 * ρ.den :=
      Nat.le_trans (by omega : 1 ≤ 4 * ρ.den) (Nat.le_add_left _ _)
    calc m + 1 = 1 * (m + 1) := by omega
      _ ≤ (ρ.den * ρ.den + 4 * ρ.den) * (m + 1) := Nat.mul_le_mul_right _ hk
  have hbE : E ≤ Rartanh_R ρ (E + 1) := by have := hRge (E + 1); omega
  exact cos_nested_general t₀ ρ htd hρ0 hρd hlt16 htρ h2ρ hhalf hρ4 hρ2 hρ8 hlt
    E (Rartanh_R ρ (E + 1)) j hbE (by omega) (by omega)

-- ===========================================================================
-- Sin side: |altSum| bound, sin argument-Lipschitz, nested evaluation.
-- ===========================================================================

/-- **Alternating sum absolute bound**: `|altSum q off N| ≤ expSumM (M²) N` for `|q| ≤ M` (termwise
    `altTerm_abs_le`, summed). For `M = 1` this is `≤ expM_U 1 2` (a uniform constant) — the bound on
    the sin/x partial sum needed for the sin argument-Lipschitz product rule. -/
theorem altSum_abs_le {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩)
    (off : Nat) : ∀ N, Qle (Qabs (altSum q off N)) (expSumM (M * M) N)
  | 0 => altTerm_abs_le hqd hq off 0
  | (N + 1) => by
      show Qle (Qabs (add (altSum q off N) (altTerm q off (N + 1))))
        (add (expSumM (M * M) N) ⟨(npow (M * M) (N + 1) : Int), fct (N + 1)⟩)
      refine Qle_trans (add_den_pos (Qabs_den_pos (altSum_den_pos hqd off N))
          (Qabs_den_pos (altTerm_den_pos hqd off (N + 1)))) (Qabs_add_le _ _) ?_
      exact Qadd_le_add (altSum_abs_le hqd hq off N) (altTerm_abs_le hqd hq off (N + 1))

/-- **arctan partial sum is `sin/x`-summable at `M = 1`**: `|altSum (arctanSum t₀ N') 1 N| ≤ U`
    (`U = (expM_U 1 2).num.toNat`) for `|t₀| ≤ ρ`, `2ρ ≤ 1`, `ρ² ≤ 1/2`. The uniform bound on the
    sin-aux partial sum evaluated at an arctan partial sum. -/
theorem altSum_arctan_abs_le_U {t₀ ρ : Q} (htd : 0 < t₀.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (htρ : Qle (Qabs t₀) ρ) (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ)))
    (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩) (N' N : Nat) :
    Qle (Qabs (altSum (arctanSum t₀ N') 1 N)) (⟨((expM_U 1 2).num.toNat : Int), 1⟩ : Q) := by
  refine Qle_trans (expSumM_den_pos (1 * 1) N)
    (altSum_abs_le (M := 1) (arctanSum_den_pos htd N')
      (arctanSum_abs_le_one htd hρ0 hρd htρ hρ2 hρ8 N') 1 N) ?_
  exact Qle_trans (expM_U_den_pos 1 2) (expSumM_le_U 1 N)
    (Qle_toNat (expM_U_num_nonneg 1 2) (expM_U_den_pos 1 2))

set_option maxHeartbeats 1200000 in
/-- **altSum arctan-depth gap, reciprocal form (any `off`)**: `|altSum (arctanSum t₀ b) off N −
    altSum (arctanSum t₀ a) off N| ≤ U·4·ρ.den/(n+1)` (`U = (expM_U 1 2).num.toNat`) for `a ≤ b`,
    `n+1 ≤ 2a+3`. The alternating-series argument-Lipschitz (`altSum_Lip_le` + `qsq_diff_le`) over the
    arctan tail (`arctanSum_abs_diff_le`), with `LipS` bounded uniformly (`LipS_le_U`) and the `geoSum`
    gap in reciprocal form (`geoSum_diff_recip`). Serves both the cos (`off=0`) and sin/x (`off=1`)
    inner-depth reconciliations. -/
theorem altSum_argdiff_recip (t₀ ρ : Q) (htd : 0 < t₀.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (htρ : Qle (Qabs t₀) ρ) (hlt : ρ.num.toNat < ρ.den)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (off : Nat) {a b n : Nat} (hab : a ≤ b) (hn : n + 1 ≤ 2 * a + 3) (N : Nat) :
    Qle (Qabs (Qsub (altSum (arctanSum t₀ b) off N) (altSum (arctanSum t₀ a) off N)))
      (⟨((expM_U 1 2).num.toNat : Int) * (4 * (ρ.den : Int)), n + 1⟩ : Q) := by
  have hb1 := arctanSum_abs_le_one htd hρ0 hρd htρ hρ2 hρ8 b
  have ha1 := arctanSum_abs_le_one htd hρ0 hρd htρ hρ2 hρ8 a
  have hUnn : 0 ≤ (⟨((expM_U 1 2).num.toNat : Int), 1⟩ : Q).num := Int.ofNat_nonneg _
  have hLipU : Qle (LipS 1 N) (⟨((expM_U 1 2).num.toNat : Int), 1⟩ : Q) :=
    Qle_trans (expM_U_den_pos 1 2) (LipS_le_U 1 N)
      (Qle_toNat (expM_U_num_nonneg 1 2) (expM_U_den_pos 1 2))
  have hgapnn : 0 ≤ (mul (⟨(2 * 1 : Nat), 1⟩ : Q) (Qsub (geoSum ρ b) (geoSum ρ a))).num :=
    Qmul_num_nonneg (by decide) (Qsub_num_nonneg (geoSum_mono ρ hρ0 hρd hab))
  refine Qle_trans (Qmul_den_pos (LipS_den_pos 1 N) (Qabs_den_pos (Qsub_den_pos
      (Nat.mul_pos (arctanSum_den_pos htd b) (arctanSum_den_pos htd b))
      (Nat.mul_pos (arctanSum_den_pos htd a) (arctanSum_den_pos htd a)))))
    (altSum_Lip_le (arctanSum_den_pos htd b) (arctanSum_den_pos htd a) hb1 ha1 off N) ?_
  refine Qle_trans (Qmul_den_pos (LipS_den_pos 1 N) (Qmul_den_pos (by decide)
      (Qabs_den_pos (Qsub_den_pos (arctanSum_den_pos htd b) (arctanSum_den_pos htd a)))))
    (Qmul_le_mul_left (LipS_num_nonneg 1 N)
      (qsq_diff_le (arctanSum_den_pos htd b) (arctanSum_den_pos htd a) hb1 ha1)) ?_
  refine Qle_trans (Qmul_den_pos (LipS_den_pos 1 N) (Qmul_den_pos (by decide)
      (Qsub_den_pos (geoSum_den_pos hρd b) (geoSum_den_pos hρd a))))
    (Qmul_le_mul_left (LipS_num_nonneg 1 N)
      (Qmul_le_mul_left (by decide) (arctanSum_abs_diff_le htd hρ0 hρd htρ hab))) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos (by decide)
      (Qsub_den_pos (geoSum_den_pos hρd b) (geoSum_den_pos hρd a))))
    (Qmul_le_mul_right hgapnn hLipU) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos (by decide) (Nat.succ_pos n)))
    (Qmul_le_mul_left hUnn (Qmul_le_mul_left (by decide)
      (geoSum_diff_recip ρ hρ0 hρd hlt hρ2 hab hn))) ?_
  exact Qeq_le (by simp only [Qeq, mul]; push_cast; ring_uor)

/-- **Common-factor product difference**: `|a·c − b·c| = |a−b|·|c|`. The `Rmul`-reconciliation
    identity (factoring the shared `RsinAux` factor out of the outer/inner `X` gap). -/
theorem Qabs_sub_mul_right_eq (a b c : Q) :
    Qeq (Qabs (Qsub (mul a c) (mul b c))) (mul (Qabs (Qsub a b)) (Qabs c)) := by
  have hf : Qeq (Qsub (mul a c) (mul b c)) (mul (Qsub a b) c) := by
    simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
  rw [← Qabs_mul]; exact Qabs_Qeq hf

/-- **Reciprocal-bound antitone in the denominator**: `m ≤ k ⟹ ⟨A,k+1⟩ ≤ ⟨A,m+1⟩` for `A ≥ 0`.
    Converts a `C/(Rs+1)` bound (large reindex) to the `C/(n+1)` form `Req_of_lin_bound` needs. -/
theorem Qrecip_anti {A : Int} (hA : 0 ≤ A) {m k : Nat} (hmk : m ≤ k) :
    Qle (⟨A, k + 1⟩ : Q) (⟨A, m + 1⟩ : Q) := by
  show A * ((m + 1 : Nat) : Int) ≤ A * ((k + 1 : Nat) : Int)
  exact Int.mul_le_mul_of_nonneg_left (by exact_mod_cast Nat.succ_le_succ hmk) hA

/-- **Common-factor product difference (left)**: `|c·a − c·b| = |c|·|a−b|`. -/
theorem Qabs_sub_mul_left_eq (c a b : Q) :
    Qeq (Qabs (Qsub (mul c a) (mul c b))) (mul (Qabs c) (Qabs (Qsub a b))) := by
  have hf : Qeq (Qsub (mul c a) (mul c b)) (mul c (Qsub a b)) := by
    simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
  rw [← Qabs_mul]; exact Qabs_Qeq hf

/-- **`RaltReal_R` lower bound**: `m + 1 ≤ RaltReal_R x m` (the diagonal reindex dominates its index,
    since `RaltReal_R x m = 2·xBound² + 4(m+1)·RaltReal_K x` and `RaltReal_K ≥ 1`). -/
theorem RaltReal_R_ge (x : Real) (m : Nat) : m + 1 ≤ RaltReal_R x m := by
  have hK1 : 1 ≤ RaltReal_K x := by unfold RaltReal_K; omega
  have h4 : 4 * (m + 1) * 1 ≤ 4 * (m + 1) * RaltReal_K x := Nat.mul_le_mul (Nat.le_refl _) hK1
  have hge : 4 * (m + 1) * RaltReal_K x ≤ RaltReal_R x m := by unfold RaltReal_R; omega
  omega

/-- **`Rartanh_R` lower bound**: `m + 1 ≤ Rartanh_R ρ m`. -/
theorem Rartanh_R_ge (ρ : Q) (hρd : 0 < ρ.den) (m : Nat) : m + 1 ≤ Rartanh_R ρ m := by
  unfold Rartanh_R
  have hk : 1 ≤ ρ.den * ρ.den + 4 * ρ.den :=
    Nat.le_trans (by omega : 1 ≤ 4 * ρ.den) (Nat.le_add_left _ _)
  calc m + 1 = 1 * (m + 1) := by omega
    _ ≤ (ρ.den * ρ.den + 4 * ρ.den) * (m + 1) := Nat.mul_le_mul_right _ hk

/-- **Product-difference bound**: `|a·b − c·d| ≤ |a−c|·|b| + |c|·|b−d|` (via `a·b − c·d =
    (a−c)·b + c·(b−d)`). The product rule for the sin argument-Lipschitz (`sin = q·(sin/q)`). -/
theorem Qabs_mul_sub_le {a b c d : Q} (ha : 0 < a.den) (hb : 0 < b.den) (hc : 0 < c.den)
    (hd : 0 < d.den) :
    Qle (Qabs (Qsub (mul a b) (mul c d)))
      (add (mul (Qabs (Qsub a c)) (Qabs b)) (mul (Qabs c) (Qabs (Qsub b d)))) := by
  have heq : Qeq (Qsub (mul a b) (mul c d)) (add (mul (Qsub a c) b) (mul c (Qsub b d))) := by
    simp only [Qeq, Qsub, mul, add, neg]; push_cast; ring_uor
  refine Qle_congr_left (Qabs_den_pos (add_den_pos (Qmul_den_pos (Qsub_den_pos ha hc) hb)
      (Qmul_den_pos hc (Qsub_den_pos hb hd)))) (Qabs_Qeq (Qeq_symm heq)) ?_
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qmul_den_pos (Qsub_den_pos ha hc) hb))
      (Qabs_den_pos (Qmul_den_pos hc (Qsub_den_pos hb hd)))) (Qabs_add_le _ _) ?_
  rw [Qabs_mul, Qabs_mul]
  exact Qle_refl _

set_option maxHeartbeats 1600000 in
/-- **sin arctan-depth gap, reciprocal form**: `|peval sin (arctanSum t₀ b)(2N+1) − peval sin
    (arctanSum t₀ a)(2N+1)| ≤ U·6·ρ.den/(n+1)` for `a ≤ b`, `n+1 ≤ 2a+3`. Via `peval sin q = q·altSum
    (q,1,N)` (`peval_sinCoeff_eq`) and the product rule (`Qabs_mul_sub_le`): the `q`-gap term
    (`arctanSum_abs_diff_le`, `|altSum| ≤ U`) plus the `altSum`-gap term (`altSum_argdiff_recip`,
    `|q'| ≤ 1`). The sin analogue of `peval_cosCoeff_arctan_argdiff_recip` (one extra term from the
    `q` factor). -/
theorem peval_sinCoeff_arctan_argdiff_recip (t₀ ρ : Q) (htd : 0 < t₀.den) (hρ0 : 0 ≤ ρ.num)
    (hρd : 0 < ρ.den) (htρ : Qle (Qabs t₀) ρ) (hlt : ρ.num.toNat < ρ.den)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    {a b n : Nat} (hab : a ≤ b) (hn : n + 1 ≤ 2 * a + 3) (N : Nat) :
    Qle (Qabs (Qsub (peval sinCoeff (arctanSum t₀ b) (2 * N + 1))
        (peval sinCoeff (arctanSum t₀ a) (2 * N + 1))))
      (⟨((expM_U 1 2).num.toNat : Int) * (6 * (ρ.den : Int)), n + 1⟩ : Q) := by
  have hqd := arctanSum_den_pos htd b
  have hq'd := arctanSum_den_pos htd a
  have hAd := altSum_den_pos hqd 1 N
  have hA'd := altSum_den_pos hq'd 1 N
  have hUnn : 0 ≤ (⟨((expM_U 1 2).num.toNat : Int), 1⟩ : Q).num := Int.ofNat_nonneg _
  have hpe : Qeq (Qsub (peval sinCoeff (arctanSum t₀ b) (2 * N + 1))
        (peval sinCoeff (arctanSum t₀ a) (2 * N + 1)))
      (Qsub (mul (arctanSum t₀ b) (altSum (arctanSum t₀ b) 1 N))
        (mul (arctanSum t₀ a) (altSum (arctanSum t₀ a) 1 N))) :=
    Qsub_congr (peval_sinCoeff_eq (arctanSum t₀ b) hqd N) (peval_sinCoeff_eq (arctanSum t₀ a) hq'd N)
  have hT1 : Qle (mul (Qabs (Qsub (arctanSum t₀ b) (arctanSum t₀ a)))
        (Qabs (altSum (arctanSum t₀ b) 1 N)))
      (⟨((expM_U 1 2).num.toNat : Int) * (2 * (ρ.den : Int)), n + 1⟩ : Q) := by
    refine Qle_trans (Qmul_den_pos (Qsub_den_pos (geoSum_den_pos hρd b) (geoSum_den_pos hρd a))
        Nat.one_pos)
      (Qmul_le_mul (Qabs_den_pos (Qsub_den_pos hqd hq'd))
        (Qsub_den_pos (geoSum_den_pos hρd b) (geoSum_den_pos hρd a)) (Qabs_den_pos hAd)
        (Qabs_num_nonneg _) (Qabs_num_nonneg _) (arctanSum_abs_diff_le htd hρ0 hρd htρ hab)
        (altSum_arctan_abs_le_U htd hρ0 hρd htρ hρ2 hρ8 b N)) ?_
    refine Qle_trans (Qmul_den_pos (Nat.succ_pos n) Nat.one_pos)
      (Qmul_le_mul_right hUnn (geoSum_diff_recip ρ hρ0 hρd hlt hρ2 hab hn)) ?_
    apply Qeq_le; simp only [Qeq, mul]; push_cast; ring_uor
  have hT2 : Qle (mul (Qabs (arctanSum t₀ a))
        (Qabs (Qsub (altSum (arctanSum t₀ b) 1 N) (altSum (arctanSum t₀ a) 1 N))))
      (⟨((expM_U 1 2).num.toNat : Int) * (4 * (ρ.den : Int)), n + 1⟩ : Q) := by
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Nat.succ_pos n))
      (Qmul_le_mul (Qabs_den_pos hq'd) Nat.one_pos (Qabs_den_pos (Qsub_den_pos hAd hA'd))
        (Qabs_num_nonneg _) (Qabs_num_nonneg _) (arctanSum_abs_le_one htd hρ0 hρd htρ hρ2 hρ8 a)
        (altSum_argdiff_recip t₀ ρ htd hρ0 hρd htρ hlt hρ2 hρ8 1 hab hn N)) ?_
    apply Qeq_le; simp only [Qeq, mul]; push_cast; ring_uor
  refine Qle_congr_left (Qabs_den_pos (Qsub_den_pos (Qmul_den_pos hqd hAd) (Qmul_den_pos hq'd hA'd)))
    (Qabs_Qeq (Qeq_symm hpe)) ?_
  refine Qle_trans (add_den_pos
      (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos hqd hq'd)) (Qabs_den_pos hAd))
      (Qmul_den_pos (Qabs_den_pos hq'd) (Qabs_den_pos (Qsub_den_pos hAd hA'd))))
    (Qabs_mul_sub_le hqd hAd hq'd hA'd) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)) (Qadd_le_add hT1 hT2) ?_
  apply Qeq_le; simp only [Qeq, add]; push_cast; ring_uor

set_option maxHeartbeats 1600000 in
/-- **sin nested-diagonal bound (general depth)**: at odd depth `2D+1`, the sin series evaluated at the
    arctan partial sum `arctanSum t₀ b` (`D ≤ b`) is within `(U·6ρ.den + 2ρ.den)/(n+1)` of the composed
    series `sin∘arctan` at `t₀`. Triangle through `peval sin (peval arctan t₀ M) M`: the arctan
    inner-depth gap (`peval_sinCoeff_arctan_argdiff_recip`, with the odd depth `2D+1` matching
    `arctanSum t₀ D` directly via `peval_arctanCoeff_eq_arctanSum` — no even-parity step) plus the
    composition gap (`DN_sin_recip`). The analytic core of the sin side of `tan(arctan t)=t`. -/
theorem sin_nested_general (t₀ ρ : Q) (htd : 0 < t₀.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den) (htρ : Qle (Qabs t₀) ρ)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hlt : ρ.num.toNat < ρ.den) (D b n : Nat) (hbD : D ≤ b) (hnb : n + 1 ≤ 2 * D + 3)
    (hnD : n + 1 ≤ 2 * D + 1) :
    Qle (Qabs (Qsub (peval sinCoeff (arctanSum t₀ b) (2 * D + 1))
        (peval (fcomp sinCoeff arctanCoeff) t₀ (2 * D + 1))))
      (⟨((expM_U 1 2).num.toNat : Int) * (6 * (ρ.den : Int)) + 2 * (ρ.den : Int), n + 1⟩ : Q) := by
  have hq1 : Qle (Qabs (peval arctanCoeff t₀ (2 * D + 1))) ⟨1, 1⟩ :=
    Qle_congr_left (Qabs_den_pos (arctanSum_den_pos htd D))
      (Qabs_Qeq (Qeq_symm (peval_arctanCoeff_eq_arctanSum t₀ htd D)))
      (arctanSum_abs_le_one htd hρ0 hρd htρ hρ2 hρ8 D)
  have hAd : 0 < (peval sinCoeff (arctanSum t₀ b) (2 * D + 1)).den :=
    peval_den_pos sinCoeff_den_pos (arctanSum_den_pos htd b) (2 * D + 1)
  have hMd : 0 < (peval sinCoeff (peval arctanCoeff t₀ (2 * D + 1)) (2 * D + 1)).den :=
    peval_den_pos sinCoeff_den_pos (peval_den_pos arctanCoeff_den_pos htd (2 * D + 1)) (2 * D + 1)
  have hCd : 0 < (peval (fcomp sinCoeff arctanCoeff) t₀ (2 * D + 1)).den :=
    peval_den_pos (fun k => fcomp_den_pos sinCoeff_den_pos arctanCoeff_den_pos k) htd (2 * D + 1)
  have harg : Qeq (peval sinCoeff (peval arctanCoeff t₀ (2 * D + 1)) (2 * D + 1))
      (peval sinCoeff (arctanSum t₀ D) (2 * D + 1)) :=
    peval_arg_congr sinCoeff (peval_arctanCoeff_eq_arctanSum t₀ htd D) (2 * D + 1)
  have hI : Qle (Qabs (Qsub (peval sinCoeff (arctanSum t₀ b) (2 * D + 1))
        (peval sinCoeff (peval arctanCoeff t₀ (2 * D + 1)) (2 * D + 1))))
      (⟨((expM_U 1 2).num.toNat : Int) * (6 * (ρ.den : Int)), n + 1⟩ : Q) :=
    Qle_congr_left (Qabs_den_pos (Qsub_den_pos hAd
        (peval_den_pos sinCoeff_den_pos (arctanSum_den_pos htd D) (2 * D + 1))))
      (Qabs_Qeq (Qsub_congr (Qeq_refl _) (Qeq_symm harg)))
      (peval_sinCoeff_arctan_argdiff_recip t₀ ρ htd hρ0 hρd htρ hlt hρ2 hρ8 hbD hnb D)
  have hII : Qle (Qabs (Qsub (peval sinCoeff (peval arctanCoeff t₀ (2 * D + 1)) (2 * D + 1))
        (peval (fcomp sinCoeff arctanCoeff) t₀ (2 * D + 1)))) (⟨2 * (ρ.den : Int), n + 1⟩ : Q) := by
    rw [Qabs_Qsub_comm]
    exact DN_sin_recip t₀ ρ (2 * D + 1) n hρd hρ0 htd htρ h2ρ hhalf hρ4 hlt16 hnD hq1
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hAd hMd))
      (Qabs_den_pos (Qsub_den_pos hMd hCd))) (Qabs_sub_triangle hAd hMd hCd) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)) (Qadd_le_add hI hII) ?_
  exact Qeq_le (Qadd_same_den_loc (((expM_U 1 2).num.toNat : Int) * (6 * (ρ.den : Int)))
    (2 * (ρ.den : Int)) (n + 1))

set_option maxHeartbeats 2400000 in
/-- **sin nested-diagonal bound (real arctan, abstract `X`)**: for a real `X` whose diagonal is the
    arctan partial sum (`hXseq`), `|(Rsin X).seq n − peval(sin∘arctan) t₀ (2D+1)| ≤ C/(n+1)` where
    `D = RaltReal_R X (Ridx X (RsinAux X) n)`. Triangle through `mul (X.seq D)((RsinAux X).seq R)`
    (`R = Ridx X (RsinAux X) n`): the **Rmul reconciliation** — `Rsin X = Rmul X (RsinAux X)` evaluates
    `X` at the outer reindex `R` but `RsinAux` internally at the deeper `D`, and the gap is
    `|X.seq R − X.seq D|·|RsinAux| ≤ 2U/(n+1)` (`X` regularity, `Qabs_sub_mul_right_eq`) — plus the
    composition core (`sin_nested_general`, after `RsinAux_seq_eq_peval` identifies the value-sin). -/
theorem Rsin_arctan_nested (t₀ ρ : Q) (X : Real) (htd : 0 < t₀.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den) (htρ : Qle (Qabs t₀) ρ)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hlt : ρ.num.toNat < ρ.den) (hXseq : ∀ m, X.seq m = arctanSum t₀ (Rartanh_R ρ m)) (n : Nat) :
    Qle (Qabs (Qsub ((Rsin X).seq n)
        (peval (fcomp sinCoeff arctanCoeff) t₀ (2 * RaltReal_R X (Ridx X (RsinAux X) n) + 1))))
      (⟨((expM_U 1 2).num.toNat : Int) * 2
        + (((expM_U 1 2).num.toNat : Int) * (6 * (ρ.den : Int)) + 2 * (ρ.den : Int)), n + 1⟩ : Q) := by
  have hRn : n ≤ Ridx X (RsinAux X) n := Ridx_ge X (RsinAux X) n
  have hDRge : Ridx X (RsinAux X) n + 1 ≤ RaltReal_R X (Ridx X (RsinAux X) n) :=
    RaltReal_R_ge X (Ridx X (RsinAux X) n)
  have hDRn : n ≤ RaltReal_R X (Ridx X (RsinAux X) n) := by omega
  -- |RsinAux.seq R| ≤ U
  have hRA : (RsinAux X).seq (Ridx X (RsinAux X) n)
      = altSum (arctanSum t₀ (Rartanh_R ρ (RaltReal_R X (Ridx X (RsinAux X) n)))) 1
          (RaltReal_R X (Ridx X (RsinAux X) n)) := by
    rw [RsinAux_seq_eq_altSum, hXseq]
  have hRsinAuxU : Qle (Qabs ((RsinAux X).seq (Ridx X (RsinAux X) n)))
      (⟨((expM_U 1 2).num.toNat : Int), 1⟩ : Q) := by
    rw [hRA]
    exact altSum_arctan_abs_le_U htd hρ0 hρd htρ hρ2 hρ8
      (Rartanh_R ρ (RaltReal_R X (Ridx X (RsinAux X) n))) (RaltReal_R X (Ridx X (RsinAux X) n))
  -- |X.seq R − X.seq D| ≤ ⟨2,n+1⟩  (X regularity)
  have hXreg2 : Qle (Qabs (Qsub (X.seq (Ridx X (RsinAux X) n))
        (X.seq (RaltReal_R X (Ridx X (RsinAux X) n))))) (⟨2, n + 1⟩ : Q) := by
    refine Qle_trans (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
      (X.reg (Ridx X (RsinAux X) n) (RaltReal_R X (Ridx X (RsinAux X) n))) ?_
    have hb1 : Qle (Qbound (Ridx X (RsinAux X) n)) (Qbound n) := by
      show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((Ridx X (RsinAux X) n + 1 : Nat) : Int)
      rw [Int.one_mul, Int.one_mul]; exact_mod_cast (Nat.succ_le_succ hRn)
    have hb2 : Qle (Qbound (RaltReal_R X (Ridx X (RsinAux X) n))) (Qbound n) := by
      show (1 : Int) * ((n + 1 : Nat) : Int)
        ≤ 1 * ((RaltReal_R X (Ridx X (RsinAux X) n) + 1 : Nat) : Int)
      rw [Int.one_mul, Int.one_mul]; exact_mod_cast (Nat.succ_le_succ hDRn)
    refine Qle_trans (add_den_pos (Qbound_den_pos n) (Qbound_den_pos n)) (Qadd_le_add hb1 hb2) ?_
    apply Qeq_le; simp only [Qeq, add, Qbound]; push_cast; ring_uor
  -- reconciliation leg
  have hrec : Qle (Qabs (Qsub
        (mul (X.seq (Ridx X (RsinAux X) n)) ((RsinAux X).seq (Ridx X (RsinAux X) n)))
        (mul (X.seq (RaltReal_R X (Ridx X (RsinAux X) n)))
          ((RsinAux X).seq (Ridx X (RsinAux X) n)))))
      (⟨((expM_U 1 2).num.toNat : Int) * 2, n + 1⟩ : Q) := by
    refine Qle_congr_left (Qmul_den_pos
        (Qabs_den_pos (Qsub_den_pos (X.den_pos _) (X.den_pos _)))
        (Qabs_den_pos ((RsinAux X).den_pos _)))
      (Qeq_symm (Qabs_sub_mul_right_eq (X.seq (Ridx X (RsinAux X) n))
        (X.seq (RaltReal_R X (Ridx X (RsinAux X) n)))
        ((RsinAux X).seq (Ridx X (RsinAux X) n)))) ?_
    refine Qle_trans (Qmul_den_pos (Nat.succ_pos n) Nat.one_pos)
      (Qmul_le_mul (Qabs_den_pos (Qsub_den_pos (X.den_pos _) (X.den_pos _))) (Nat.succ_pos n)
        (Qabs_den_pos ((RsinAux X).den_pos _)) (Qabs_num_nonneg _) (Qabs_num_nonneg _)
        hXreg2 hRsinAuxU) ?_
    apply Qeq_le; simp only [Qeq, mul]; push_cast; ring_uor
  -- composition leg
  have hsinLeg : Qle (Qabs (Qsub
        (mul (X.seq (RaltReal_R X (Ridx X (RsinAux X) n)))
          ((RsinAux X).seq (Ridx X (RsinAux X) n)))
        (peval (fcomp sinCoeff arctanCoeff) t₀ (2 * RaltReal_R X (Ridx X (RsinAux X) n) + 1))))
      (⟨((expM_U 1 2).num.toNat : Int) * (6 * (ρ.den : Int)) + 2 * (ρ.den : Int), n + 1⟩ : Q) := by
    refine Qle_congr_left (Qabs_den_pos (Qsub_den_pos
        (peval_den_pos sinCoeff_den_pos (X.den_pos _) _)
        (peval_den_pos (fun k => fcomp_den_pos sinCoeff_den_pos arctanCoeff_den_pos k) htd _)))
      (Qabs_Qeq (Qsub_congr (Qeq_symm (RsinAux_seq_eq_peval X (Ridx X (RsinAux X) n)))
        (Qeq_refl _))) ?_
    rw [hXseq (RaltReal_R X (Ridx X (RsinAux X) n))]
    exact sin_nested_general t₀ ρ htd hρ0 hρd hlt16 htρ h2ρ hhalf hρ4 hρ2 hρ8 hlt
      (RaltReal_R X (Ridx X (RsinAux X) n)) (Rartanh_R ρ (RaltReal_R X (Ridx X (RsinAux X) n))) n
      (by have := Rartanh_R_ge ρ hρd (RaltReal_R X (Ridx X (RsinAux X) n)); omega) (by omega) (by omega)
  -- triangle through the midpoint mul (X.seq D)(RsinAux.seq R)
  refine Qle_trans (add_den_pos
      (Qabs_den_pos (Qsub_den_pos (Qmul_den_pos (X.den_pos _) ((RsinAux X).den_pos _))
        (Qmul_den_pos (X.den_pos _) ((RsinAux X).den_pos _))))
      (Qabs_den_pos (Qsub_den_pos (Qmul_den_pos (X.den_pos _) ((RsinAux X).den_pos _))
        (peval_den_pos (fun k => fcomp_den_pos sinCoeff_den_pos arctanCoeff_den_pos k) htd _))))
    (Qabs_sub_triangle (b := mul (X.seq (RaltReal_R X (Ridx X (RsinAux X) n)))
        ((RsinAux X).seq (Ridx X (RsinAux X) n)))
      (Qmul_den_pos (X.den_pos _) ((RsinAux X).den_pos _))
      (Qmul_den_pos (X.den_pos _) ((RsinAux X).den_pos _))
      (peval_den_pos (fun k => fcomp_den_pos sinCoeff_den_pos arctanCoeff_den_pos k) htd _)) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)) (Qadd_le_add hrec hsinLeg) ?_
  apply Qeq_le; simp only [Qeq, add]; push_cast; ring_uor

set_option maxHeartbeats 4000000 in
/-- **★ `sin(arctan t₀) = t₀·cos(arctan t₀)` at the value level**: `Req (Rsin (Rarctan t₀))
    (Rmul (ofQ t₀) (Rcos (Rarctan t₀)))` for `|t₀| ≤ ρ < 1/16` (the doubling radius). The value form of
    the formal identity `sin∘arctan = t·(cos∘arctan)`. Via `Req_of_lin_bound` and the triangle
    `a0=(Rsin X).seq n → a1=peval(sin∘arctan)(2Ds+1) → a3=t₀·(Rcos X).seq Rs → a4=(t₀·Rcos X).seq n`:
    L1 = `Rsin_arctan_nested`; `a1 = t₀·peval(cos∘arctan)(2Ds)` by `peval_sin_arctan_shift`;
    L2 = `|t₀|·(Rcos_arctan_nested at Rs)`; L3 = `|t₀|·(Rcos X regularity)`, with `|t₀| ≤ 1`. No
    division: `tan(arctan t₀) = t₀` then follows from this by `Rcos(arctan t₀) ≠ 0`. -/
theorem Rsin_arctan_value_eq (t₀ ρ : Q) (htd : 0 < t₀.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (htρ : Qle (Qabs t₀) ρ)
    (hlt16 : (mul ⟨16, 1⟩ ρ).num.toNat < (mul ⟨16, 1⟩ ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩) :
    Req (Rsin (Rarctan t₀ htd hρ0 hρd hlt htρ))
      (Rmul (ofQ t₀ htd) (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))) := by
  refine Req_of_lin_bound
    (C := (expM_U 1 2).num.toNat * 2 + ((expM_U 1 2).num.toNat * (6 * ρ.den) + 2 * ρ.den)
      + ((expM_U 1 2).num.toNat * (4 * ρ.den) + 2 * ρ.den) + 2) ?_
  intro n
  have ht1 : Qle (Qabs t₀) ⟨1, 1⟩ := Qle_trans hρd htρ hρ1
  have hRn : n ≤ Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n :=
    Ridx_ge _ _ n
  have hCcnn : 0 ≤ ((expM_U 1 2).num.toNat : Int) * (4 * (ρ.den : Int)) + 2 * (ρ.den : Int) :=
    Int.add_nonneg (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.mul_nonneg (by decide) (Int.ofNat_nonneg _)))
      (Int.mul_nonneg (by decide) (Int.ofNat_nonneg _))
  -- L1: Rsin nested
  have hL1 := Rsin_arctan_nested t₀ ρ (Rarctan t₀ htd hρ0 hρd hlt htρ) htd hρ0 hρd hlt16 htρ h2ρ
    hhalf hρ4 hρ2 hρ8 hlt (fun m => rfl) n
  -- Rcos nested at Rs
  have hRcos := Rcos_arctan_nested t₀ ρ htd hρ0 hρd hlt htρ hlt16 h2ρ hhalf hρ4 hρ2 hρ8
    (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n)
  -- inner cos bound, comm + reindex to /(n+1)
  have hinner : Qle (Qabs (Qsub (peval (fcomp cosCoeff arctanCoeff) t₀
        (2 * RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ)
          (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n)))
        ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq
          (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n))))
      (⟨((expM_U 1 2).num.toNat : Int) * (4 * (ρ.den : Int)) + 2 * (ρ.den : Int), n + 1⟩ : Q) := by
    rw [Qabs_Qsub_comm]
    exact Qle_trans (Nat.succ_pos _) hRcos (Qrecip_anti hCcnn hRn)
  -- L2: |a1 − a3| via shift + factor t₀
  have hL2 : Qle (Qabs (Qsub
        (peval (fcomp sinCoeff arctanCoeff) t₀
          (2 * RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ)
            (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n) + 1))
        (mul t₀ ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq
          (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n)))))
      (⟨((expM_U 1 2).num.toNat : Int) * (4 * (ρ.den : Int)) + 2 * (ρ.den : Int), n + 1⟩ : Q) := by
    have hcosd : 0 < (peval (fcomp cosCoeff arctanCoeff) t₀
        (2 * RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ)
          (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n))).den :=
      peval_den_pos (fun k => fcomp_den_pos cosCoeff_den_pos arctanCoeff_den_pos k) htd _
    have hrcd : 0 < ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq
        (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n)).den :=
      (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).den_pos _
    refine Qle_congr_left (Qabs_den_pos (Qsub_den_pos (Qmul_den_pos htd hcosd) (Qmul_den_pos htd hrcd)))
      (Qabs_Qeq (Qsub_congr (Qeq_symm (peval_sin_arctan_shift t₀ htd
        (2 * RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ)
          (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n))))
        (Qeq_refl _))) ?_
    refine Qle_congr_left (Qmul_den_pos (Qabs_den_pos htd) (Qabs_den_pos (Qsub_den_pos hcosd hrcd)))
      (Qeq_symm (Qabs_sub_mul_left_eq t₀ _ _)) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Nat.succ_pos n))
      (Qmul_le_mul (Qabs_den_pos htd) Nat.one_pos (Qabs_den_pos (Qsub_den_pos hcosd hrcd))
        (Qabs_num_nonneg _) (Qabs_num_nonneg _) ht1 hinner) ?_
    apply Qeq_le; simp only [Qeq, mul]; push_cast; ring_uor
  -- L3: |a3 − a4| via Rcos regularity + factor t₀
  have hL3 : Qle (Qabs (Qsub
        (mul t₀ ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq
          (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n)))
        (mul t₀ ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq
          (Ridx (ofQ t₀ htd) (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)) n)))))
      (⟨2, n + 1⟩ : Q) := by
    have hrcd1 : 0 < ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq
        (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n)).den :=
      (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).den_pos _
    have hrcd2 : 0 < ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq
        (Ridx (ofQ t₀ htd) (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)) n)).den :=
      (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).den_pos _
    have hreg : Qle (Qabs (Qsub ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq
          (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n))
          ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq
            (Ridx (ofQ t₀ htd) (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)) n)))) (⟨2, n + 1⟩ : Q) := by
      refine Qle_trans (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
        ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).reg _ _) ?_
      have hb1 : Qle (Qbound (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ)
          (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n)) (Qbound n) := by
        show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((_ + 1 : Nat) : Int)
        rw [Int.one_mul, Int.one_mul]; exact_mod_cast (Nat.succ_le_succ hRn)
      have hb2 : Qle (Qbound (Ridx (ofQ t₀ htd) (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)) n))
          (Qbound n) := by
        show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((_ + 1 : Nat) : Int)
        rw [Int.one_mul, Int.one_mul]; exact_mod_cast (Nat.succ_le_succ (Ridx_ge _ _ n))
      refine Qle_trans (add_den_pos (Qbound_den_pos n) (Qbound_den_pos n)) (Qadd_le_add hb1 hb2) ?_
      apply Qeq_le; simp only [Qeq, add, Qbound]; push_cast; ring_uor
    refine Qle_congr_left (Qmul_den_pos (Qabs_den_pos htd) (Qabs_den_pos (Qsub_den_pos hrcd1 hrcd2)))
      (Qeq_symm (Qabs_sub_mul_left_eq t₀ _ _)) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Nat.succ_pos n))
      (Qmul_le_mul (Qabs_den_pos htd) Nat.one_pos (Qabs_den_pos (Qsub_den_pos hrcd1 hrcd2))
        (Qabs_num_nonneg _) (Qabs_num_nonneg _) ht1 hreg) ?_
    apply Qeq_le; simp only [Qeq, mul]; push_cast; ring_uor
  -- assemble the two-level triangle
  have ha0d : 0 < ((Rsin (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq n).den :=
    (Rsin (Rarctan t₀ htd hρ0 hρd hlt htρ)).den_pos n
  have ha1d : 0 < (peval (fcomp sinCoeff arctanCoeff) t₀
      (2 * RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ)
        (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n) + 1)).den :=
    peval_den_pos (fun k => fcomp_den_pos sinCoeff_den_pos arctanCoeff_den_pos k) htd _
  have ha3d : 0 < (mul t₀ ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq
      (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n))).den :=
    Qmul_den_pos htd ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).den_pos _)
  have ha4d : 0 < ((Rmul (ofQ t₀ htd) (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))).seq n).den :=
    (Rmul (ofQ t₀ htd) (Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ))).den_pos n
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos ha0d ha1d))
      (Qabs_den_pos (Qsub_den_pos ha1d ha4d)))
    (Qabs_sub_triangle (b := peval (fcomp sinCoeff arctanCoeff) t₀
      (2 * RaltReal_R (Rarctan t₀ htd hρ0 hρd hlt htρ)
        (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n) + 1))
      ha0d ha1d ha4d) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)))
    (Qadd_le_add hL1 (Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos ha1d ha3d))
        (Qabs_den_pos (Qsub_den_pos ha3d ha4d)))
      (Qabs_sub_triangle (b := mul t₀ ((Rcos (Rarctan t₀ htd hρ0 hρd hlt htρ)).seq
        (Ridx (Rarctan t₀ htd hρ0 hρd hlt htρ) (RsinAux (Rarctan t₀ htd hρ0 hρd hlt htρ)) n)))
        ha1d ha3d ha4d) (Qadd_le_add hL2 hL3))) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n))
    (Qadd_le_add (Qle_refl _) (Qeq_le (Qadd_same_den_loc
      (((expM_U 1 2).num.toNat : Int) * (4 * (ρ.den : Int)) + 2 * (ρ.den : Int)) 2 (n + 1)))) ?_
  refine Qle_trans (Nat.succ_pos n) (Qeq_le (Qadd_same_den_loc
      (((expM_U 1 2).num.toNat : Int) * 2 + (((expM_U 1 2).num.toNat : Int) * (6 * (ρ.den : Int))
        + 2 * (ρ.den : Int)))
      ((((expM_U 1 2).num.toNat : Int) * (4 * (ρ.den : Int)) + 2 * (ρ.den : Int)) + 2) (n + 1))) ?_
  apply Qeq_le; simp only [Qeq]; push_cast; ring_uor

end UOR.Bridge.F1Square.Analysis
