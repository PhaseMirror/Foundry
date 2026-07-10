/-
F1 square — v0.22.0 Track 1, brick 1: **arctan at a general REAL argument** `|t| ≤ ρ < 1`.

The rational-argument `Rarctan` (`Arctan.lean`) is truncation-only (fixed `t`). The complex logarithm
`Clog` on the right half-plane needs the ARGUMENT `arg(z) = arctan(Im z / Re z)` at a general real
ratio — so this lifts arctan to a real argument, mirroring the real-argument `Rartanh` (`Log.lean`):
the diagonal carries the Lipschitz term for the varying argument as well as the truncation term.

Because `arctanTerm t n = (−1)ⁿ · artTerm t n`, the sign has `|·| = 1` and vanishes under `Qabs`, so
every ABSOLUTE bound is identical to the artanh one: the per-term Lipschitz bound
(`arctanTerm_diff_bound`), the partial-sum Lipschitz bound (`arctanSum_Lip_le`), and the diagonal
regularity (`RarctanR_diag_le`) all reuse the artanh truncation (`arctanSum_trunc`, `Arctan.lean`),
the geometric reindex (`Rartanh_R`, `geoEvenSum`, `geoEven_bound`, `artanh_reindex`, `qpow_geom_bound`,
all shared and sign-independent). This is the forced first brick of the `Γ → ξ → Hadamard` stack.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.Arctan

namespace UOR.Bridge.F1Square.Analysis

/-- **Per-term Lipschitz bound** `|arctanTerm t n − arctanTerm t' n| ≤ ρ^{2n}·|t−t'|` — the artanh
    bound (`artTerm_diff_bound`), with the `(−1)ⁿ` sign factored out under `Qabs`. -/
theorem arctanTerm_diff_bound {t t' ρ : Q} (htd : 0 < t.den) (ht'd : 0 < t'.den) (hρd : 0 < ρ.den)
    (htρ : Qle (Qabs t) ρ) (ht'ρ : Qle (Qabs t') ρ) (n : Nat) :
    Qle (Qabs (Qsub (arctanTerm t n) (arctanTerm t' n))) (mul (qpow ρ (2 * n)) (Qabs (Qsub t t'))) := by
  have habs1 : Qeq (Qabs (qpow (⟨-1, 1⟩ : Q) n)) ⟨1, 1⟩ :=
    Qeq_trans (qpow_den_pos (by decide) n) (qpow_abs (⟨-1, 1⟩ : Q) n) (qpow_one n)
  have hartd : 0 < (Qsub (artTerm t n) (artTerm t' n)).den :=
    Qsub_den_pos (artTerm_den_pos htd n) (artTerm_den_pos ht'd n)
  -- arctanTerm t n − arctanTerm t' n = (−1)ⁿ·(artTerm t n − artTerm t' n)
  have hfac : Qeq (Qsub (arctanTerm t n) (arctanTerm t' n))
      (mul (qpow (⟨-1, 1⟩ : Q) n) (Qsub (artTerm t n) (artTerm t' n))) := by
    unfold arctanTerm Qsub
    simp only [Qeq, mul, add, neg]; push_cast; ring_uor
  have h1 : Qeq (Qabs (Qsub (arctanTerm t n) (arctanTerm t' n)))
      (mul (Qabs (qpow (⟨-1, 1⟩ : Q) n)) (Qabs (Qsub (artTerm t n) (artTerm t' n)))) := by
    rw [← Qabs_mul]; exact Qabs_Qeq hfac
  have h2 : Qeq (mul (Qabs (qpow (⟨-1, 1⟩ : Q) n)) (Qabs (Qsub (artTerm t n) (artTerm t' n))))
      (Qabs (Qsub (artTerm t n) (artTerm t' n))) :=
    Qeq_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos hartd))
      (Qmul_congr habs1 (Qeq_refl _)) (Qone_mul _)
  have hEq : Qeq (Qabs (Qsub (arctanTerm t n) (arctanTerm t' n)))
      (Qabs (Qsub (artTerm t n) (artTerm t' n))) :=
    Qeq_trans (Qmul_den_pos (Qabs_den_pos (qpow_den_pos (by decide) n)) (Qabs_den_pos hartd)) h1 h2
  exact Qle_trans (Qabs_den_pos hartd) (Qeq_le hEq) (artTerm_diff_bound htd ht'd hρd htρ ht'ρ n)

/-- **Partial-sum Lipschitz bound** `|arctanSum t N − arctanSum t' N| ≤ geoEvenSum ρ N · |t−t'|`
    (mirror of `artSum_Lip_le`, summing `arctanTerm_diff_bound`). -/
theorem arctanSum_Lip_le {t t' ρ : Q} (htd : 0 < t.den) (ht'd : 0 < t'.den) (hρd : 0 < ρ.den)
    (htρ : Qle (Qabs t) ρ) (ht'ρ : Qle (Qabs t') ρ) :
    ∀ N, Qle (Qabs (Qsub (arctanSum t N) (arctanSum t' N))) (mul (geoEvenSum ρ N) (Qabs (Qsub t t')))
  | 0 => arctanTerm_diff_bound htd ht'd hρd htρ ht'ρ 0
  | (N + 1) => by
      have ih := arctanSum_Lip_le htd ht'd hρd htρ ht'ρ N
      have hAd : 0 < (arctanSum t N).den := arctanSum_den_pos htd N
      have hCd : 0 < (arctanSum t' N).den := arctanSum_den_pos ht'd N
      have hBd : 0 < (arctanTerm t (N + 1)).den := arctanTerm_den_pos htd (N + 1)
      have hDd : 0 < (arctanTerm t' (N + 1)).den := arctanTerm_den_pos ht'd (N + 1)
      refine Qle_trans
        (add_den_pos (Qabs_den_pos (Qsub_den_pos hAd hCd)) (Qabs_den_pos (Qsub_den_pos hBd hDd)))
        (Qabs_sub_add4 hAd hBd hCd hDd)
        (Qle_trans
          (add_den_pos (Qmul_den_pos (geoEvenSum_den_pos hρd N)
            (Qabs_den_pos (Qsub_den_pos htd ht'd)))
            (Qmul_den_pos (qpow_den_pos hρd _) (Qabs_den_pos (Qsub_den_pos htd ht'd))))
          (Qadd_le_add ih (arctanTerm_diff_bound htd ht'd hρd htρ ht'ρ (N + 1)))
          (Qeq_le (Qeq_symm (Qmul_add_right (geoEvenSum ρ N) (qpow ρ (2 * (N + 1)))
            (Qabs (Qsub t t'))))))

-- ===========================================================================
-- The real-argument diagonal (truncation + Lipschitz), mirroring `Rartanh_diag_le`.
-- ===========================================================================

/-- The `j`-th arctan diagonal approximant at a REAL argument `t` (reusing the artanh depth
    schedule `Rartanh_R`). -/
def RarctanR_seq (t : Real) (ρ : Q) (j : Nat) : Q := arctanSum (t.seq (Rartanh_R ρ j)) (Rartanh_R ρ j)

/-- The real-argument arctan diagonal gap is `≤ 1/(j+1)` — truncation (`arctanSum_trunc`) plus
    Lipschitz (`arctanSum_Lip_le`), combined and `W = 1−ρ²` cancelled, exactly as `Rartanh_diag_le`. -/
theorem RarctanR_diag_le (t : Real) {ρ : Q} (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (hb : ∀ n, Qle (Qabs (t.seq n)) ρ) {j k : Nat} (hjk : j ≤ k) :
    Qle (Qabs (Qsub (RarctanR_seq t ρ j) (RarctanR_seq t ρ k))) (Qbound j) := by
  have hltI : ρ.num < (ρ.den : Int) := by rw [← Int.toNat_of_nonneg hρ0]; exact_mod_cast hlt
  have hd1 : (1 : Int) ≤ (ρ.den : Int) := by exact_mod_cast hρd
  have hWd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).den :=
    Qsub_den_pos Nat.one_pos (Nat.mul_pos hρd hρd)
  have hWn : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).num := by
    show 0 < 1 * ((ρ.den * ρ.den : Nat) : Int) + -(ρ.num * ρ.num) * ((1 : Nat) : Int)
    have hp2 : ρ.num * ρ.num ≤ ((ρ.den : Int) - 1) * ((ρ.den : Int) - 1) :=
      Int.mul_le_mul (by omega) (by omega) hρ0 (by omega)
    have he2 : ((ρ.den : Int) - 1) * ((ρ.den : Int) - 1)
        = (ρ.den : Int) * (ρ.den : Int) - 2 * (ρ.den : Int) + 1 := by ring_uor
    push_cast; omega
  have hWnn : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).num := Int.le_of_lt hWn
  have hRle : Rartanh_R ρ j ≤ Rartanh_R ρ k := by
    unfold Rartanh_R; exact Nat.mul_le_mul (Nat.le_refl _) (Nat.succ_le_succ hjk)
  have hDbound : Qle (Qabs (Qsub (t.seq (Rartanh_R ρ j)) (t.seq (Rartanh_R ρ k))))
      ⟨2, Rartanh_R ρ j + 1⟩ := by
    have hanti : Qle (Qbound (Rartanh_R ρ k)) (Qbound (Rartanh_R ρ j)) := by
      show (1 : Int) * ((Rartanh_R ρ j + 1 : Nat) : Int) ≤ 1 * ((Rartanh_R ρ k + 1 : Nat) : Int)
      rw [Int.one_mul, Int.one_mul]; exact_mod_cast (show Rartanh_R ρ j + 1 ≤ Rartanh_R ρ k + 1 by omega)
    have hsum : Qeq (add (Qbound (Rartanh_R ρ j)) (Qbound (Rartanh_R ρ j))) ⟨2, Rartanh_R ρ j + 1⟩ := by
      simp only [Qeq, add, Qbound]; push_cast; ring_uor
    exact Qle_trans (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (t.reg _ _)
      (Qle_trans (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
        (Qadd_le_add (Qle_refl _) hanti) (Qeq_le hsum))
  have htri := Qabs_sub_triangle (a := RarctanR_seq t ρ j)
    (b := arctanSum (t.seq (Rartanh_R ρ k)) (Rartanh_R ρ j)) (c := RarctanR_seq t ρ k)
    (arctanSum_den_pos (t.den_pos _) _) (arctanSum_den_pos (t.den_pos _) _)
    (arctanSum_den_pos (t.den_pos _) _)
  have hLipW : Qle (mul (Qabs (Qsub (RarctanR_seq t ρ j)
        (arctanSum (t.seq (Rartanh_R ρ k)) (Rartanh_R ρ j)))) (Qsub ⟨1, 1⟩ (mul ρ ρ)))
      (Qabs (Qsub (t.seq (Rartanh_R ρ j)) (t.seq (Rartanh_R ρ k)))) := by
    have hLS := arctanSum_Lip_le (t.den_pos (Rartanh_R ρ j)) (t.den_pos (Rartanh_R ρ k))
      hρd (hb _) (hb _) (Rartanh_R ρ j)
    refine Qle_trans (Qmul_den_pos (Qmul_den_pos (geoEvenSum_den_pos hρd _)
        (Qabs_den_pos (Qsub_den_pos (t.den_pos _) (t.den_pos _)))) hWd)
      (Qmul_le_mul_right hWnn hLS) ?_
    refine Qle_trans (Qmul_den_pos (Qmul_den_pos (geoEvenSum_den_pos hρd _) hWd)
        (Qabs_den_pos (Qsub_den_pos (t.den_pos _) (t.den_pos _))))
      (Qeq_le (Qmul_swap_right _ _ _)) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos (t.den_pos _) (t.den_pos _))))
      (Qmul_le_mul_right (Qabs_num_nonneg _) (geoEven_bound hρ0 hρd _)) (Qeq_le (Qone_mul _))
  have hTrW : Qle (mul (Qabs (Qsub (arctanSum (t.seq (Rartanh_R ρ k)) (Rartanh_R ρ j))
        (RarctanR_seq t ρ k))) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (qpow ρ (2 * Rartanh_R ρ j + 3)) := by
    have hTB := arctanSum_trunc (t.den_pos (Rartanh_R ρ k)) hρ0 hρd (hb _) hWnn
      (a := Rartanh_R ρ j) hRle
    rw [Qabs_Qsub_comm]; exact hTB
  refine Qmul_le_cancel_right hWn hWd ?_
  refine Qle_trans (Qmul_den_pos (add_den_pos (Qabs_den_pos (Qsub_den_pos
      (arctanSum_den_pos (t.den_pos _) _) (arctanSum_den_pos (t.den_pos _) _)))
      (Qabs_den_pos (Qsub_den_pos (arctanSum_den_pos (t.den_pos _) _)
        (arctanSum_den_pos (t.den_pos _) _)))) hWd)
    (Qmul_le_mul_right hWnn htri) ?_
  refine Qle_trans (add_den_pos (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos
      (arctanSum_den_pos (t.den_pos _) _) (arctanSum_den_pos (t.den_pos _) _))) hWd)
      (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos (arctanSum_den_pos (t.den_pos _) _)
        (arctanSum_den_pos (t.den_pos _) _))) hWd))
    (Qeq_le (Qmul_add_right _ _ _))
    (Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (t.den_pos _) (t.den_pos _)))
      (qpow_den_pos hρd _)) (Qadd_le_add hLipW hTrW)
      (Qle_trans (add_den_pos (Nat.succ_pos _)
          (Nat.lt_of_lt_of_le hρd (Nat.le_add_right _ _)))
        (Qadd_le_add hDbound (qpow_geom_bound hρ0 hρd (Nat.le_of_lt hlt) _))
        (artanh_reindex hρ0 hρd hlt j)))

/-- The real-argument arctan diagonal is Bishop-regular. -/
theorem RarctanR_regular (t : Real) {ρ : Q} (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (hb : ∀ n, Qle (Qabs (t.seq n)) ρ) : IsRegular (RarctanR_seq t ρ) := by
  intro j k
  rcases Nat.le_total j k with h | h
  · exact Qle_trans (Qbound_den_pos j) (RarctanR_diag_le t hρ0 hρd hlt hb h)
      (Qle_self_add (by show (0 : Int) ≤ 1; decide))
  · have hswap := RarctanR_diag_le t hρ0 hρd hlt hb h
    rw [Qabs_Qsub_comm] at hswap
    exact Qle_trans (Qbound_den_pos k) hswap (Qle_add_self (by show (0 : Int) ≤ 1; decide))

/-- **`arctan` at a general REAL argument `t` with `|t| ≤ ρ < 1`** — a constructive real, the diagonal
    of the alternating arctan series. The prerequisite for `arg(z)` on the right half-plane (`Clog`). -/
def RarctanR (t : Real) (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs (t.seq n)) ρ) : Real :=
  ⟨RarctanR_seq t ρ, RarctanR_regular t hρ0 hρd hlt hb,
    fun j => arctanSum_den_pos (t.den_pos _) (Rartanh_R ρ j)⟩

-- ===========================================================================
-- `arctan 0 = 0` — the value at the origin (needed for `arg` of a positive real).
-- ===========================================================================

/-- The `n`-th arctan term at `0` has numerator `0`. -/
theorem arctanTerm_zero_num (n : Nat) : (arctanTerm (⟨0, 1⟩ : Q) n).num = 0 := by
  show (mul (qpow (⟨-1, 1⟩ : Q) n) (mul (qpow (⟨0, 1⟩ : Q) (2 * n + 1)) ⟨1, 2 * n + 1⟩)).num = 0
  have h : (qpow (⟨0, 1⟩ : Q) (2 * n + 1)).num = 0 := qpow_zero_succ_num (2 * n)
  simp only [mul]; rw [h]; simp

/-- The `n`-th arctan term at `0` is `0`. -/
theorem arctanTerm_zero (n : Nat) : Qeq (arctanTerm (⟨0, 1⟩ : Q) n) (⟨0, 1⟩ : Q) := by
  simp only [Qeq]; rw [arctanTerm_zero_num]; simp

/-- The arctan partial sum at `0` has numerator `0`. -/
theorem arctanSum_zero_num : ∀ N, (arctanSum (⟨0, 1⟩ : Q) N).num = 0
  | 0 => arctanTerm_zero_num 0
  | (n + 1) => by
      show (add (arctanSum (⟨0, 1⟩ : Q) n) (arctanTerm (⟨0, 1⟩ : Q) (n + 1))).num = 0
      simp only [add]; rw [arctanSum_zero_num n, arctanTerm_zero_num (n + 1)]; simp

/-- The arctan partial sum at `0` is `0`. -/
theorem arctanSum_zero (N : Nat) : Qeq (arctanSum (⟨0, 1⟩ : Q) N) (⟨0, 1⟩ : Q) := by
  simp only [Qeq]; rw [arctanSum_zero_num]; simp

/-- **`arctan 0 = 0`** — the real-argument arctan vanishes at the origin (every approximant is the
    partial sum at the constant `0`, which is `0`). -/
theorem RarctanR_zero (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs ((zero).seq n)) ρ) : Req (RarctanR zero ρ hρ0 hρd hlt hb) zero := by
  apply Req_of_seq_Qeq
  intro n
  show Qeq (arctanSum ((zero).seq (Rartanh_R ρ n)) (Rartanh_R ρ n)) ((zero).seq n)
  have hz : (zero : Real).seq (Rartanh_R ρ n) = (⟨0, 1⟩ : Q) := rfl
  have hz2 : (zero : Real).seq n = (⟨0, 1⟩ : Q) := rfl
  rw [hz, hz2]; exact arctanSum_zero (Rartanh_R ρ n)

-- ===========================================================================
-- `arctan` of any vanishing-numerator sequence is `0` (generalizes `RarctanR_zero`;
-- the case `arg(z) = arctan(Im z / Re z)` for `Im z = 0`, where the ratio has numerator `0`).
-- ===========================================================================

/-- A positive power of a numerator-`0` rational has numerator `0`. -/
theorem qpow_succ_num_eq_zero {q : Q} (hq : q.num = 0) (m : Nat) : (qpow q (m + 1)).num = 0 := by
  show (mul q (qpow q m)).num = 0
  simp only [mul]; rw [hq]; simp

/-- The `n`-th arctan term of a numerator-`0` argument has numerator `0`. -/
theorem arctanTerm_num_eq_zero {q : Q} (hq : q.num = 0) (n : Nat) : (arctanTerm q n).num = 0 := by
  show (mul (qpow (⟨-1, 1⟩ : Q) n) (mul (qpow q (2 * n + 1)) ⟨1, 2 * n + 1⟩)).num = 0
  have h : (qpow q (2 * n + 1)).num = 0 := qpow_succ_num_eq_zero hq (2 * n)
  simp only [mul]; rw [h]; simp

/-- The arctan partial sum of a numerator-`0` argument has numerator `0`. -/
theorem arctanSum_num_eq_zero {q : Q} (hq : q.num = 0) : ∀ N, (arctanSum q N).num = 0
  | 0 => arctanTerm_num_eq_zero hq 0
  | (n + 1) => by
      show (add (arctanSum q n) (arctanTerm q (n + 1))).num = 0
      simp only [add]; rw [arctanSum_num_eq_zero hq n, arctanTerm_num_eq_zero hq (n + 1)]; simp

/-- **`arctan` of a numerator-`0` real is `0`**: if every approximant of `t` has numerator `0`
    (e.g. `t = 0/x = Im z/Re z` when `Im z = 0`), then `RarctanR t = 0`. The general value-at-origin,
    the `arg`-of-a-positive-real fact behind the principal branch of `Clog`. -/
theorem RarctanR_of_num_zero (t : Real) (ht : ∀ n, (t.seq n).num = 0)
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hb : ∀ n, Qle (Qabs (t.seq n)) ρ) : Req (RarctanR t ρ hρ0 hρd hlt hb) zero := by
  apply Req_of_seq_Qeq
  intro n
  show Qeq (arctanSum (t.seq (Rartanh_R ρ n)) (Rartanh_R ρ n)) ((zero).seq n)
  rw [zero_seq]
  simp only [Qeq]; rw [arctanSum_num_eq_zero (ht (Rartanh_R ρ n)) (Rartanh_R ρ n)]; simp

end UOR.Bridge.F1Square.Analysis
