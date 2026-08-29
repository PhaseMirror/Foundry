/-
F1 square — **dimension-independence of the Riesz coefficient on the fixed family** (`RieszDimInv.lean`),
brick 6a of the moment-realization sub-arc. The `L²`-limit reads Riesz projections of *growing* degree,
each naturally computed at its own dimension; the Bessel-tail identity (`pVec_diff_normSq`, brick 5.5)
only applies when two projections share the *same* dimension and hence the *same* coefficients. This
brick removes that obstruction on the fixed orthogonal family `gsFam`: its Riesz coefficient does not
depend on the truncation dimension past the minimal one.

  `Lam_trunc`      :  `c` supported on `[0,D)`, `D ≤ d`  ⟹  `Λ_μ(c)_d = Λ_μ(c)_D`   (moment functional);
  `aCoef_dim_inv`  :  `k < d, k < d'`  ⟹  `aCoef μ d gsFam k = aCoef μ d' gsFam k`;
  `pVec_dim_inv`   :  `N < d, N < d'`  ⟹  `p_N` at dimension `d` equals `p_N` at dimension `d'`.

The moment functional truncates like `qHil` (a `qsumL` past the support), and the guarded Riesz
coefficient `Λ_μ(q_k)/⟨q_k,q_k⟩` is a ratio of two truncation-stable rationals (`Lam_trunc` and
`qHil_trunc_eq`, brick 3.5a) with a positive-numerator denominator preserved by `Qinv` — so the whole
coefficient is dimension-free, and the projection follows by combination congruence.

HONEST SCOPE. Dimension-independence of the *finite* Riesz coefficient/projection on the fixed family —
pure ℚ arithmetic, unconditional. This is NOT the Riesz convergence / L²-limit (which additionally needs
a supplied Bessel convergence modulus — the next brick), NOT positivity. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.GramSchmidtConcrete
import Foundations.F1.Square.RieszCoeff

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small ℚ / list helpers (private).
-- ===========================================================================

/-- `a ≈ 0 ⟹ a·b ≈ 0`. -/
private theorem Qmul_zero_of_left {a b : Q} (ha : Qeq a (⟨0, 1⟩ : Q)) :
    Qeq (mul a b) (⟨0, 1⟩ : Q) := by
  have han : a.num = 0 := by simp only [Qeq] at ha; push_cast at ha; omega
  show a.num * b.num * ((1 : Nat) : Int) = 0 * ((a.den * b.den : Nat) : Int)
  rw [han]; push_cast; ring_uor

/-- The reciprocal respects `Qeq` on positive-numerator rationals. -/
private theorem Qinv_congr {a b : Q} (ha : 0 < a.num) (hb : 0 < b.num) (hab : Qeq a b) :
    Qeq (Qinv a) (Qinv b) := by
  have hta : (a.num.toNat : Int) = a.num := by omega
  have htb : (b.num.toNat : Int) = b.num := by omega
  simp only [Qeq, Qinv] at hab ⊢
  push_cast [hta, htb]
  rw [Int.mul_comm (a.den : Int) b.num, Int.mul_comm (b.den : Int) a.num]
  exact hab.symm

/-- Split the last element off a `range (d+1)` sum. -/
private theorem qsumL_range_succ (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) (d : Nat) :
    Qeq (qsumL f (List.range (d + 1))) (add (qsumL f (List.range d)) (f d)) := by
  rw [List.range_succ]
  refine Qeq_trans (b := add (qsumL f (List.range d)) (qsumL f [d]))
    (add_den_pos (qsumL_den f hf (List.range d)) (qsumL_den f hf [d]))
    (qsumL_append f hf (List.range d) [d]) ?_
  refine Qadd_congr (Qeq_refl _) ?_
  show Qeq (add (f d) (⟨0, 1⟩ : Q)) (f d)
  exact Qadd_zero_right (f d)

/-- A `qsumL` over `range` is inert past support. -/
private theorem qsumL_trunc (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) (D : Nat)
    (hz : ∀ i, D ≤ i → Qeq (f i) (⟨0, 1⟩ : Q)) :
    ∀ n, Qeq (qsumL f (List.range (D + n))) (qsumL f (List.range D)) := by
  intro n
  induction n with
  | zero => exact Qeq_refl _
  | succ n ih =>
    have hstep : Qeq (qsumL f (List.range (D + (n + 1)))) (qsumL f (List.range (D + n))) := by
      refine Qeq_trans (b := add (qsumL f (List.range (D + n))) (f (D + n)))
        (add_den_pos (qsumL_den f hf (List.range (D + n))) (hf (D + n)))
        (qsumL_range_succ f hf (D + n)) ?_
      refine Qeq_trans (b := add (qsumL f (List.range (D + n))) (⟨0, 1⟩ : Q))
        (add_den_pos (qsumL_den f hf (List.range (D + n))) (by decide))
        (Qadd_congr (Qeq_refl _) (hz (D + n) (Nat.le_add_right D n)))
        (Qadd_zero_right _)
    exact Qeq_trans (qsumL_den f hf (List.range (D + n))) hstep ih

-- ===========================================================================
-- Truncation of the moment functional.
-- ===========================================================================

/-- **★ MOMENT-FUNCTIONAL TRUNCATION**: `Λ_μ(c)` is independent of the dimension past the support of
    `c`: `c` supported on `[0,D)`, `D ≤ d` ⟹ `Λ_μ(c)_d = Λ_μ(c)_D`. -/
theorem Lam_trunc (μ c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (hμ : ∀ i, 0 < (μ i).den) (D : Nat)
    (hsupp : ∀ i, D ≤ i → Qeq (c i) (⟨0, 1⟩ : Q)) (d : Nat) (hd : D ≤ d) :
    Qeq (Lam μ c d) (Lam μ c D) := by
  obtain ⟨n, rfl⟩ := Nat.le.dest hd
  exact qsumL_trunc (fun i => mul (c i) (μ i)) (fun i => Qmul_den_pos (hc i) (hμ i)) D
    (fun i hi => Qmul_zero_of_left (hsupp i hi)) n

-- ===========================================================================
-- ★ Dimension-independence of the Riesz coefficient and projection on `gsFam`.
-- ===========================================================================

/-- The Riesz coefficient at any dimension `> k` equals its value at the minimal dimension `k+1`. -/
private theorem aCoef_dim_inv_min (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (k d : Nat) (hkd : k < d) :
    Qeq (aCoef μ d gsFam k) (aCoef μ (k + 1) gsFam k) := by
  have hHd : 0 < (qHil (gsFam k) (gsFam k) d).num :=
    qHil_self_num_pos gsFam gsFam_den d k hkd (gsFam_monic k)
  have hHk : 0 < (qHil (gsFam k) (gsFam k) (k + 1)).num :=
    qHil_self_num_pos gsFam gsFam_den (k + 1) k (Nat.lt_succ_self k) (gsFam_monic k)
  unfold aCoef
  rw [if_pos hHd, if_pos hHk]
  have hLam : Qeq (Lam μ (gsFam k) d) (Lam μ (gsFam k) (k + 1)) :=
    Lam_trunc μ (gsFam k) (gsFam_den k) hμ (k + 1)
      (fun i hi => gsFam_support k i (by omega)) d hkd
  have hHeq : Qeq (qHil (gsFam k) (gsFam k) d) (qHil (gsFam k) (gsFam k) (k + 1)) :=
    qHil_trunc_eq (gsFam k) (gsFam k) (gsFam_den k) (gsFam_den k) (k + 1)
      (fun idx hidx => gsFam_support k idx (by omega))
      (fun idx hidx => gsFam_support k idx (by omega)) d (k + 1) hkd (Nat.le_refl (k + 1))
  exact Qmul_congr hLam (Qinv_congr hHd hHk hHeq)

/-- **★ RIESZ-COEFFICIENT DIMENSION-INDEPENDENCE**: on the fixed family, the Riesz coefficient `aCoef`
    is independent of the truncation dimension past `k`. -/
theorem aCoef_dim_inv (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (k d d' : Nat)
    (hkd : k < d) (hkd' : k < d') :
    Qeq (aCoef μ d gsFam k) (aCoef μ d' gsFam k) :=
  Qeq_trans (aCoef_den μ (k + 1) gsFam gsFam_den hμ k)
    (aCoef_dim_inv_min μ hμ k d hkd) (Qeq_symm (aCoef_dim_inv_min μ hμ k d' hkd'))

/-- **★ RIESZ-PROJECTION DIMENSION-INDEPENDENCE**: on the fixed family, the degree-`N` Riesz projection
    is independent of the truncation dimension past `N`. -/
theorem pVec_dim_inv (μ : Nat → Q) (hμ : ∀ i, 0 < (μ i).den) (N d d' : Nat)
    (hNd : N < d) (hNd' : N < d') (idx : Nat) :
    Qeq (pVec μ d gsFam N idx) (pVec μ d' gsFam N idx) := by
  show Qeq (qsumL (fun k => mul (aCoef μ d gsFam k) (gsFam k idx)) (List.range (N + 1)))
    (qsumL (fun k => mul (aCoef μ d' gsFam k) (gsFam k idx)) (List.range (N + 1)))
  refine qsumL_congr_mem (List.range (N + 1)) (fun k hk => ?_)
  have hkN : k ≤ N := by have := List.mem_range.mp hk; omega
  exact Qmul_congr (aCoef_dim_inv μ hμ k d d' (by omega) (by omega)) (Qeq_refl _)

end Multiplicity.UOR.Bridge.F1Square.Square
