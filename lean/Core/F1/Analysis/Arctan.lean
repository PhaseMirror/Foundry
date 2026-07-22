/-
arctan at a rational argument — the alternating sibling of artanh.

`arctan t = Σ (−1)ⁿ t^{2n+1}/(2n+1)`. Since `|(−1)ⁿ t^{2n+1}/(2n+1)| = |t^{2n+1}/(2n+1)|`, the
per-term geometric domination, the truncation tail, and the diagonal regularity are exactly the
artanh ones (Log.lean): we reuse `geoTerm`/`geo_diff_bound`, `artTerm_abs_le`, the reindex
`Rartanh_R`, `artanh_reindex`, and `qpow_geom_bound`. The argument here is a fixed **rational**, so
the diagonal is truncation-only (no Lipschitz term) — strictly simpler than `Rartanh`.

This is the engine for `π` via Machin's formula (Pi.lean). Pure Lean 4, no Mathlib, no `sorry`.
-/
import Core.F1.Analysis.Log

namespace UOR.Bridge.F1Square.Analysis

/-- `1ⁿ = 1`. -/
theorem qpow_one : ∀ n : Nat, Qeq (qpow (⟨1, 1⟩ : Q) n) ⟨1, 1⟩
  | 0 => Qeq_refl _
  | (k + 1) => by
      rw [qpow_succ]
      exact Qeq_trans (qpow_den_pos (by decide) k) (Qone_mul (qpow ⟨1, 1⟩ k)) (qpow_one k)

/-- The `n`-th arctan term `(−1)ⁿ t^{2n+1}/(2n+1)`, as `(−1)ⁿ · artTerm t n`. -/
def arctanTerm (t : Q) (n : Nat) : Q := mul (qpow (⟨-1, 1⟩ : Q) n) (artTerm t n)

theorem arctanTerm_den_pos {t : Q} (htd : 0 < t.den) (n : Nat) : 0 < (arctanTerm t n).den :=
  Qmul_den_pos (qpow_den_pos (by decide) n) (artTerm_den_pos htd n)

/-- The arctan partial sum `Σ_{n=0}^N (−1)ⁿ t^{2n+1}/(2n+1)`. -/
def arctanSum (t : Q) : Nat → Q
  | 0 => arctanTerm t 0
  | (n + 1) => add (arctanSum t n) (arctanTerm t (n + 1))

theorem arctanSum_den_pos {t : Q} (htd : 0 < t.den) : ∀ N, 0 < (arctanSum t N).den
  | 0 => arctanTerm_den_pos htd 0
  | (n + 1) => add_den_pos (arctanSum_den_pos htd n) (arctanTerm_den_pos htd (n + 1))

/-- **Per-term domination**: `|arctanTerm t n| ≤ ρ^{2n+1}` when `|t| ≤ ρ` (the sign vanishes). -/
theorem arctanTerm_abs_le {t ρ : Q} (htd : 0 < t.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (htρ : Qle (Qabs t) ρ) (n : Nat) : Qle (Qabs (arctanTerm t n)) (geoTerm ρ n) := by
  have habs1 : Qeq (Qabs (qpow (⟨-1, 1⟩ : Q) n)) ⟨1, 1⟩ :=
    Qeq_trans (qpow_den_pos (by decide) n) (qpow_abs (⟨-1, 1⟩ : Q) n) (qpow_one n)
  have hEq : Qeq (Qabs (arctanTerm t n)) (Qabs (artTerm t n)) := by
    unfold arctanTerm
    rw [Qabs_mul]
    exact Qeq_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (artTerm_den_pos htd n)))
      (Qmul_congr habs1 (Qeq_refl (Qabs (artTerm t n)))) (Qone_mul (Qabs (artTerm t n)))
  exact Qle_trans (Qabs_den_pos (artTerm_den_pos htd n)) (Qeq_le hEq)
    (artTerm_abs_le htd hρ0 hρd htρ n)

/-- **Truncation domination**: `|arctanSum gap| ≤ S_b − S_a` (geometric). -/
theorem arctanSum_abs_diff_le {t ρ : Q} (htd : 0 < t.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (htρ : Qle (Qabs t) ρ) {a b : Nat} (hab : a ≤ b) :
    Qle (Qabs (Qsub (arctanSum t b) (arctanSum t a))) (Qsub (geoSum ρ b) (geoSum ρ a)) := by
  induction hab with
  | refl =>
      have h := Qsub_self_num (arctanSum t a)
      have h' := Qsub_self_num (geoSum ρ a)
      unfold Qle Qabs; rw [h, h']; simp
  | @step k _ ih =>
      have hstep : Qle (Qabs (Qsub (arctanSum t (k + 1)) (arctanSum t a)))
          (add (Qabs (Qsub (arctanSum t k) (arctanSum t a))) (Qabs (arctanTerm t (k + 1)))) := by
        have heqabs := Qabs_Qeq (Qsub_add_right (arctanSum t k) (arctanTerm t (k + 1)) (arctanSum t a))
        refine Qle_congr_left (Qabs_den_pos (add_den_pos (Qsub_den_pos (arctanSum_den_pos htd k)
          (arctanSum_den_pos htd a)) (arctanTerm_den_pos htd (k + 1)))) (Qeq_symm heqabs)
          (Qabs_add_le _ _)
      have hbound : Qle (add (Qabs (Qsub (arctanSum t k) (arctanSum t a))) (Qabs (arctanTerm t (k + 1))))
          (add (Qsub (geoSum ρ k) (geoSum ρ a)) (geoTerm ρ (k + 1))) :=
        Qadd_le_add ih (arctanTerm_abs_le htd hρ0 hρd htρ (k + 1))
      have hregroup : Qeq (add (Qsub (geoSum ρ k) (geoSum ρ a)) (geoTerm ρ (k + 1)))
          (Qsub (geoSum ρ (k + 1)) (geoSum ρ a)) :=
        Qeq_symm (Qsub_add_right (geoSum ρ k) (geoTerm ρ (k + 1)) (geoSum ρ a))
      refine Qle_trans
        (add_den_pos (Qabs_den_pos (Qsub_den_pos (arctanSum_den_pos htd k) (arctanSum_den_pos htd a)))
          (Qabs_den_pos (arctanTerm_den_pos htd (k + 1))))
        hstep
        (Qle_trans (add_den_pos (Qsub_den_pos (geoSum_den_pos hρd k) (geoSum_den_pos hρd a))
          (qpow_den_pos hρd _)) hbound (Qeq_le hregroup))

/-- **The arctan truncation tail**: `|arctanSum gap|·(1−ρ²) ≤ ρ^{2a+3}` for `|t| ≤ ρ`, `a ≤ b`. -/
theorem arctanSum_trunc {t ρ : Q} (htd : 0 < t.den) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (htρ : Qle (Qabs t) ρ) (hW : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).num) {a b : Nat} (hab : a ≤ b) :
    Qle (mul (Qabs (Qsub (arctanSum t b) (arctanSum t a))) (Qsub ⟨1, 1⟩ (mul ρ ρ)))
      (qpow ρ (2 * a + 3)) :=
  Qle_trans (Qmul_den_pos (Qsub_den_pos (geoSum_den_pos hρd b) (geoSum_den_pos hρd a))
      (Qsub_den_pos Nat.one_pos (Nat.mul_pos hρd hρd)))
    (Qmul_le_mul_right hW (arctanSum_abs_diff_le htd hρ0 hρd htρ hab))
    (geo_diff_bound hρ0 hρd hab)

-- ===========================================================================
-- The arctan diagonal at a fixed rational t (|t| ≤ ρ < 1): truncation-only.
-- ===========================================================================

/-- The `j`-th arctan diagonal approximant at the rational `t` (reusing the artanh reindex). -/
def Rarctan_seq (t : Q) (ρ : Q) (j : Nat) : Q := arctanSum t (Rartanh_R ρ j)

/-- The arctan diagonal gap is `≤ 1/(j+1)` (truncation-only — fixed rational argument). -/
theorem Rarctan_diag_le (t : Q) (htd : 0 < t.den) {ρ : Q} (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (htρ : Qle (Qabs t) ρ) {j k : Nat} (hjk : j ≤ k) :
    Qle (Qabs (Qsub (Rarctan_seq t ρ j) (Rarctan_seq t ρ k))) (Qbound j) := by
  have hWd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).den :=
    Qsub_den_pos Nat.one_pos (Nat.mul_pos hρd hρd)
  have hWn : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).num := by
    show 0 < 1 * ((ρ.den * ρ.den : Nat) : Int) + -(ρ.num * ρ.num) * ((1 : Nat) : Int)
    have hp2 : ρ.num * ρ.num ≤ ((ρ.den : Int) - 1) * ((ρ.den : Int) - 1) :=
      Int.mul_le_mul (by
        have : ρ.num.toNat < ρ.den := hlt
        have h1 : (ρ.num.toNat : Int) < (ρ.den : Int) := by exact_mod_cast this
        have h2 : (ρ.num.toNat : Int) = ρ.num := Int.toNat_of_nonneg hρ0
        omega) (by
        have : ρ.num.toNat < ρ.den := hlt
        have h1 : (ρ.num.toNat : Int) < (ρ.den : Int) := by exact_mod_cast this
        have h2 : (ρ.num.toNat : Int) = ρ.num := Int.toNat_of_nonneg hρ0
        omega) hρ0 (by
        have : (1 : Int) ≤ (ρ.den : Int) := by exact_mod_cast hρd
        omega)
    have he2 : ((ρ.den : Int) - 1) * ((ρ.den : Int) - 1)
        = (ρ.den : Int) * (ρ.den : Int) - 2 * (ρ.den : Int) + 1 := by ring_uor
    have hd1 : (1 : Int) ≤ (ρ.den : Int) := by exact_mod_cast hρd
    push_cast; omega
  have hWnn : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).num := Int.le_of_lt hWn
  have hRle : Rartanh_R ρ j ≤ Rartanh_R ρ k := by
    unfold Rartanh_R; exact Nat.mul_le_mul (Nat.le_refl _) (Nat.succ_le_succ hjk)
  refine Qmul_le_cancel_right hWn hWd ?_
  rw [Qabs_Qsub_comm]
  refine Qle_trans (qpow_den_pos hρd _)
    (arctanSum_trunc htd hρ0 hρd htρ hWnn hRle)
    (Qle_trans (Nat.lt_of_lt_of_le hρd (Nat.le_add_right _ _))
      (qpow_geom_bound hρ0 hρd (Nat.le_of_lt hlt) (2 * Rartanh_R ρ j + 3))
      (Qle_trans (add_den_pos (Nat.succ_pos _) (Nat.lt_of_lt_of_le hρd (Nat.le_add_right _ _)))
        (Qle_add_self (show (0 : Int) ≤ 2 by decide))
        (artanh_reindex hρ0 hρd hlt j)))

/-- The arctan diagonal at a fixed rational is Bishop-regular. -/
theorem Rarctan_regular (t : Q) (htd : 0 < t.den) {ρ : Q} (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (htρ : Qle (Qabs t) ρ) : IsRegular (Rarctan_seq t ρ) := by
  intro j k
  rcases Nat.le_total j k with h | h
  · exact Qle_trans (Qbound_den_pos j) (Rarctan_diag_le t htd hρ0 hρd hlt htρ h)
      (Qle_self_add (by show (0 : Int) ≤ 1; decide))
  · have hswap := Rarctan_diag_le t htd hρ0 hρd hlt htρ h
    rw [Qabs_Qsub_comm] at hswap
    exact Qle_trans (Qbound_den_pos k) hswap (Qle_add_self (by show (0 : Int) ≤ 1; decide))

/-- **`arctan` at a rational `t` with `|t| ≤ ρ < 1`** — a constructive real. -/
def Rarctan (t : Q) (htd : 0 < t.den) {ρ : Q} (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den) (htρ : Qle (Qabs t) ρ) : Real :=
  ⟨Rarctan_seq t ρ, Rarctan_regular t htd hρ0 hρd hlt htρ,
    fun j => arctanSum_den_pos htd (Rartanh_R ρ j)⟩

end UOR.Bridge.F1Square.Analysis
