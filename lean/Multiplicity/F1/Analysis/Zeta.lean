/-
F1 square — the `ζ` partial-sum approximant (reconstructed module).

Historical content of this brick: the rational partial sums
`zetaSum s N = Σ_{k=0}^{N} 1/(k+1)^s` together with their elementary order facts,
consumed by the `γ`-term estimates (`Euler`, `GammaOne`, …), the numeric brackets
(`ZetaTwo`), and the completeness layer (`Complete`, `Pi`).

Pure Lean 4 core, no Mathlib, no `sorry`; built on exact `Q` (brick one),
the restored `npow` helper (core-compat), and the order layer (`QOrder`).
-/

import Multiplicity.F1.Analysis.QOrder
import Multiplicity.F1.Analysis.Rat
import Multiplicity.F1.Analysis.Real
import Multiplicity.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- Partial sums of the Riemann–ζ series at integer exponent `s`:
    `zetaSum s N = Σ_{k=0}^{N} 1 / (k+1)^s`, kept as exact rationals with
    denominator `(k+1)^s` at each step. -/
def zetaSum (s : Nat) : Nat → Q
  | 0 => ⟨1, npow 1 s⟩
  | (n + 1) => add (zetaSum s n) ⟨1, npow (n + 2) s⟩

/-- The partial sums have positive denominators (products of positive factors). -/
theorem zetaSum_den_pos (s : Nat) : ∀ N, 0 < (zetaSum s N).den
  | 0 => npow_pos (b := 1) (k := s) (by omega)
  | (n + 1) =>
      add_den_pos (zetaSum_den_pos s n)
        (npow_pos (b := n + 2) (k := s) (by show (0:Nat) < n + 2; omega))

/-- The partial sums increase (each step appends a positive term). -/
theorem zetaSum_step_le (s N : Nat) : Qle (zetaSum s N) (zetaSum s (N + 1)) :=
  Qle_self_add (show (0 : Int) ≤ 1 by decide)

/-- The partial sums are antitone in depth. -/
theorem zetaSum_le (s : Nat) {N M : Nat} (hNM : N ≤ M) : Qle (zetaSum s N) (zetaSum s M) := by
  obtain ⟨d, hd⟩ : ∃ d, M = N + d := ⟨M - N, by omega⟩
  subst hd
  clear hNM
  induction d with
  | zero => exact Qle_refl _
  | succ e ih => exact Qle_trans (zetaSum_den_pos s _) ih (zetaSum_step_le s (N + e))

/-! ### The key one-step inequality -/

/-- Reduced-fraction comparison against `1/(a+1)` (local copy of the brick-one lemma,
    which lives in `Complete`, downstream of this module). -/
private theorem zQfrac_le {p d a : Nat} (h : p * (a + 1) ≤ d) :
    Qle (⟨(p : Int), d⟩ : Q) ⟨1, a + 1⟩ := by
  show (p : Int) * (((a + 1 : Nat) : Int)) ≤ 1 * ((d : Nat) : Int)
  have hc : (((p * (a + 1) : Nat) : Int)) ≤ ((d : Nat) : Int) := by exact_mod_cast h
  push_cast at hc ⊢
  omega

/-- Power growth: for `s ≥ 2`, `(n+2)(n+1) ≤ (n+2)^s`. -/
private theorem prod_le_pow (s n : Nat) (hs : 2 ≤ s) : (n + 2) * (n + 1) ≤ npow (n + 2) s := by
  obtain ⟨d, hd⟩ : ∃ d, s = d + 2 := ⟨s - 2, by omega⟩
  subst hd
  have h1 : npow (n + 2) (d + 2) = (n + 2) * ((n + 2) * npow (n + 2) d) := by
    rw [npow_succ, npow_succ]
  rw [h1]
  have hge : ((n:Nat) + 1) ≤ n + 2 := by omega
  have hP : (0:Nat) < npow (n + 2) d :=
    npow_pos (b := n + 2) (k := d) (by show (0:Nat) < n + 2; omega)
  have k1 : ((n:Nat) + 2) ≤ (n + 2) * npow (n + 2) d := Nat.le_mul_of_pos_right _ hP
  exact Nat.le_trans (Nat.mul_le_mul_left _ hge) (Nat.mul_le_mul_left _ k1)

/-- Load-bearing one-step bound `1/(n+2)^s + 1/(n+2) ≤ 1/(n+1)` for `s ≥ 2`
    (cross-multiplies to `(n+1)(n+2) ≤ (n+2)^s`). -/
theorem keyQ (s n : Nat) (hs : 2 ≤ s) :
    Qle (add ⟨1, npow (n + 2) s⟩ ⟨1, n + 2⟩) ⟨1, n + 1⟩ := by
  have hpow : (0:Nat) < npow (n + 2) s := npow_pos (b := n + 2) (k := s) (by omega)
  have hred : Qeq (add ⟨1, npow (n + 2) s⟩ ⟨1, n + 2⟩)
      (⟨((npow (n + 2) s + (n + 2)) : Nat), npow (n + 2) s * (n + 2)⟩ : Q) := by
    simp only [Qeq, add]; push_cast; ring_uor
  have t1 : ((n:Nat) + 2) * (n + 1) ≤ npow (n + 2) s := prod_le_pow s n hs
  have hcert : ((npow (n + 2) s + (n + 2)) : Nat) * (n + 1)
      ≤ npow (n + 2) s * (n + 2) := by
    calc (npow (n + 2) s + (n + 2)) * (n + 1)
        = npow (n + 2) s * (n + 1) + (n + 2) * (n + 1) := Nat.add_mul _ _ _
      _ ≤ npow (n + 2) s * (n + 1) + npow (n + 2) s :=
          Nat.add_le_add (Nat.le_refl _) t1
      _ = npow (n + 2) s * (n + 2) := (Nat.mul_succ _ _).symm
  have hden : (0:Nat) < npow (n + 2) s * (n + 2) :=
    Nat.mul_pos hpow (Nat.succ_pos _)
  exact Qle_trans hden (Qeq_le hred) (zQfrac_le hcert)

/-! ### The ζ majorant `U(N) = S(N) + 1/(N+1)` -/

/-- The bounding majorant `U(N) := S(N) + 1/(N+1)`: dominates every partial sum,
    equals `2` at depth zero, antitone in depth for `s ≥ 2`. -/
def zetaU (s N : Nat) : Q := add (zetaSum s N) ⟨1, N + 1⟩

theorem zetaU_den_pos (s N : Nat) : 0 < (zetaU s N).den :=
  add_den_pos (zetaSum_den_pos s N) (Nat.succ_pos N)

/-- One-step antitone: `U(N+1) ≤ U(N)` for `s ≥ 2`. -/
theorem zetaU_step_le (s n : Nat) (hs : 2 ≤ s) : Qle (zetaU s (n + 1)) (zetaU s n) := by
  have hkey := keyQ s n hs
  show Qle (add (zetaSum s (n + 1)) ⟨1, n + 1 + 1⟩) (add (zetaSum s n) ⟨1, n + 1⟩)
  rw [show zetaSum s (n + 1) = add (zetaSum s n) ⟨1, npow (n + 2) s⟩ from rfl]
  have hpow : (0:Nat) < npow (n + 2) s := npow_pos (b := n + 2) (k := s) (by omega)
  have hdP : 0 < (add (zetaSum s n)
      (add ⟨1, npow (n + 2) s⟩ ⟨1, n + 2⟩)).den :=
    add_den_pos (zetaSum_den_pos s n)
      (add_den_pos (npow_pos (b := n + 2) (k := s) (by omega)) (Nat.succ_pos _))
  have hdK : 0 < (add (zetaSum s n) ⟨1, n + 1⟩).den :=
    add_den_pos (zetaSum_den_pos s n) (Nat.succ_pos _)
  exact Qle_trans hdP (Qeq_le (add_assoc (zetaSum s n) ⟨1, npow (n + 2) s⟩ ⟨1, n + 2⟩))
    (Qle_trans hdK (Qadd_le_add (Qle_refl (zetaSum s n)) hkey) (Qle_refl _))

/-- Antitone over distance: `N ≤ M` implies `U(M) ≤ U(N)` (`s ≥ 2`). -/
theorem zetaU_le (s : Nat) (hs : 2 ≤ s) {N M : Nat} (hNM : N ≤ M) :
    Qle (zetaU s M) (zetaU s N) := by
  induction hNM with
  | refl => exact Qle_refl _
  | step _ ih => exact Qle_trans (zetaU_den_pos s _) (zetaU_step_le s _ hs) ih

/-! ### Depth-stability: |S(Dk) − S(Dj)| ≤ 1/(Dj+1) -/

/-- Sharp telescoping: the depth-`d` difference is bounded by the harmonic
    telescope `1/(j+1) − 1/(j+d+1)`. -/
private theorem zetaTail_telescope (s : Nat) (hs : 2 ≤ s) :
    ∀ d j, Qle (Qsub (zetaSum s (j + d)) (zetaSum s j))
        (Qsub ⟨1, j + 1⟩ ⟨1, j + d + 1⟩)
  | 0, j => by
      rw [Nat.add_zero]
      refine Qeq_le ?_
      simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
  | (d + 1), j => by
      have ih := zetaTail_telescope s hs d j
      have hbrk : Qle (⟨1, npow (j + d + 2) s⟩ : Q)
          (Qsub ⟨1, j + d + 1⟩ ⟨1, j + d + 2⟩) := by
        have hg : (↑(j + d + 2) : Int) * ↑(j + d + 1) ≤ ↑(npow (j + d + 2) s) := by
          rw [← Int.natCast_mul]
          exact_mod_cast prod_le_pow s (j + d) hs
        unfold Qle Qsub add neg
        push_cast
        simp only [Int.one_mul]
        have hg2 : (((↑j + ↑d + 1 : Int)) * ((↑j + ↑d + 1 : Int) + 1))
            ≤ ↑(npow (j + d + 2) s) := by
          have h4 : ((↑(j + d + 2) : Int) * (↑(j + d + 1) : Int))
              ≤ ↑(npow (j + d + 2) s) := hg
          rw [show ((↑(j + d + 2) : Int) = ((↑j + ↑d + 1 : Int) + 1)) from by push_cast; omega,
              show ((↑(j + d + 1) : Int) = (↑j + ↑d + 1 : Int)) from by push_cast; omega,
              Int.mul_comm] at h4
          exact h4
        rw [show ((((↑j + ↑d + 1 : Int) + 1) + -1 * (↑j + ↑d + 1 : Int)) : Int) = 1
            from by push_cast; omega, Int.one_mul]
        exact hg2
      have hdV : 0 < (add (Qsub ⟨1, j + 1⟩ ⟨1, j + d + 1⟩)
          (Qsub ⟨1, j + d + 1⟩ ⟨1, j + d + 2⟩)).den :=
        add_den_pos (Qsub_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
          (Qsub_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
      have htele : Qeq (add (Qsub ⟨1, j + 1⟩ ⟨1, j + d + 1⟩)
            (Qsub ⟨1, j + d + 1⟩ ⟨1, j + d + 2⟩))
          (Qsub ⟨1, j + 1⟩ ⟨1, j + d + 2⟩) := by
        simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
      have hV : Qle (add (Qsub ⟨1, j + 1⟩ ⟨1, j + d + 1⟩)
            (⟨1, npow (j + d + 2) s⟩ : Q))
          (Qsub ⟨1, j + 1⟩ ⟨1, j + d + 2⟩) :=
        Qle_congr_right hdV htele (Qadd_le_add (Qle_refl _) hbrk)
      have hdpos : 0 < (add (Qsub (zetaSum s (j + d)) (zetaSum s j))
          ⟨1, npow (j + d + 2) s⟩).den :=
        add_den_pos (Qsub_den_pos (zetaSum_den_pos s (j + d)) (zetaSum_den_pos s j))
          (npow_pos (b := j + d + 2) (k := s) (by show (0:Nat) < j + d + 2; omega))
      have hspl : Qeq (Qsub (zetaSum s (j + (d + 1))) (zetaSum s j))
          (add (Qsub (zetaSum s (j + d)) (zetaSum s j)) ⟨1, npow (j + d + 2) s⟩) := by
        show Qeq (Qsub (add (zetaSum s (j + d)) ⟨1, npow (j + d + 2) s⟩) (zetaSum s j)) _
        simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
      refine Qle_trans hdpos (Qeq_le hspl) ?_
      exact Qle_congr_right hdV htele (Qadd_le_add ih hbrk)

/-- Adding two nonnegative rationals stays nonnegative. -/
private theorem Qzero_add_zero {a b : Q} (ha : Qle (⟨0, 1⟩ : Q) a) (hb : Qle (⟨0, 1⟩ : Q) b) :
    Qle (⟨0, 1⟩ : Q) (add a b) :=
  Qle_congr_left (by decide)
    (show Qeq (add (⟨0, 1⟩ : Q) (⟨0, 1⟩ : Q)) (⟨0, 1⟩ : Q) from by decide)
    (Qadd_le_add ha hb)

/-- Nonnegativity of depth-differences (sums increase). -/
private theorem zetaSub_nonneg (s : Nat) {N M : Nat} (h : N ≤ M) :
    Qle (⟨0, 1⟩ : Q) (Qsub (zetaSum s M) (zetaSum s N)) := by
  obtain ⟨d, hd⟩ : ∃ d, M = N + d := ⟨M - N, by omega⟩
  subst hd
  clear h
  induction d with
  | zero =>
      rw [Nat.add_zero]
      refine Qeq_le ?_
      simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ e ih =>
      have hspl : Qeq (Qsub (zetaSum s ((N + e) + 1)) (zetaSum s N))
          (add (Qsub (zetaSum s (N + e)) (zetaSum s N))
            ⟨1, npow (N + e + 2) s⟩) := by
        show Qeq (Qsub (add (zetaSum s (N + e)) ⟨1, npow (N + e + 2) s⟩)
          (zetaSum s N)) _
        simp only [Qsub, add, neg, Qeq]; push_cast; ring_uor
      have hpos : Qle (⟨0, 1⟩ : Q) ⟨1, npow (N + e + 2) s⟩ := by
        unfold Qle
        simp only [Int.zero_mul, Int.one_mul]
        decide
      refine Qle_congr_right
        (add_den_pos (Qsub_den_pos (zetaSum_den_pos s (N + e)) (zetaSum_den_pos s N))
          (npow_pos (b := N + e + 2) (k := s) (by omega)))
        (Qeq_symm hspl) (Qzero_add_zero ih hpos)

/-- `Qabs` is the identity on nonnegative rationals. -/
private theorem Qabs_of_nonneg {x : Q} (hx : Qle (⟨0, 1⟩ : Q) x) : Qeq (Qabs x) x := by
  have h00 : (0 : Int) ≤ x.num := by
    have h5 := hx
    unfold Qle at h5
    rw [show ((⟨0, 1⟩ : Q).num : Int) = 0 from rfl,
        show (((⟨0, 1⟩ : Q).den : Nat) : Int) = 1 from rfl,
        Int.zero_mul, Int.mul_one] at h5
    exact h5
  unfold Qabs
  rw [Int.natAbs_of_nonneg h00]
  rfl

/-- **Per-depth ζ-stability**: deepening from `Dj` to `Dk ≥ Dj` moves the partial sum
    by at most `1/(Dj+1)`. -/
theorem zetaabs_bound (s : Nat) (hs : 2 ≤ s) {Dj Dk : Nat} (hjk : Dj ≤ Dk) :
      Qle (Qabs (Qsub (zetaSum s Dk) (zetaSum s Dj))) (⟨1, Dj + 1⟩ : Q) := by
      have hnn := zetaSub_nonneg s hjk
      obtain ⟨d, hd⟩ : ∃ d, Dk = Dj + d := ⟨Dk - Dj, by omega⟩
      subst hd
      have ht := zetaTail_telescope s hs d Dj
      have hnq : Qle (neg ⟨1, Dj + d + 1⟩) (⟨0, 1⟩ : Q) := by
        show ((neg ⟨1, Dj + d + 1⟩).num : Int) * ((⟨0, 1⟩ : Q).den : Int)
            ≤ ((⟨0, 1⟩ : Q).num : Int) * ((neg ⟨1, Dj + d + 1⟩).den : Int)
        rw [show ((⟨0, 1⟩ : Q).den : Int) = 1 from rfl,
            show ((⟨0, 1⟩ : Q).num : Int) = 0 from rfl,
            show (neg ⟨1, Dj + d + 1⟩).num = -(1 : Int) from rfl,
            show (neg ⟨1, Dj + d + 1⟩).den = Dj + d + 1 from rfl]
        push_cast
        omega
      have e : Qeq (add ⟨1, Dj + 1⟩ (⟨0, 1⟩ : Q)) (⟨1, Dj + 1⟩ : Q) := by
        simp only [add, Qeq]; push_cast; ring_uor
      have hdrop : Qle (Qsub ⟨1, Dj + 1⟩ ⟨1, Dj + d + 1⟩) (⟨1, Dj + 1⟩ : Q) :=
        Qle_congr_right (Nat.mul_pos (Nat.succ_pos _) Nat.one_pos) e
          (Qadd_le_add (Qle_refl (⟨1, Dj + 1⟩ : Q)) hnq)
      have hmid : (0 : Nat) < (Qsub ⟨1, Dj + 1⟩ ⟨1, Dj + d + 1⟩).den :=
        Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)
      have hmain : Qle (Qsub (zetaSum s (Dj + d)) (zetaSum s Dj)) (⟨1, Dj + 1⟩ : Q) :=
        Qle_trans hmid ht hdrop
      exact Qle_trans
        (Qsub_den_pos (zetaSum_den_pos s (Dj + d)) (zetaSum_den_pos s Dj))
        (Qeq_le (Qabs_of_nonneg hnn))
        hmain

/-! ### The ζ constant as a constructive real -/

/-- `|a − b|` and `|b − a|` agree (local copy; the canonical one lives downstream in `Complete`). -/
private theorem zeta_abs_comm (a b : Q) : Qeq (Qabs (Qsub a b)) (Qabs (Qsub b a)) := by
  unfold Qeq Qabs
  rw [Qsub_swap_num a b, Qsub_swap_den a b, Int.natAbs_neg]

/-- **The ζ constant**: the constructive real represented by the regular sequence of partial sums
    `n ↦ Σ_{k≤n} 1/(k+1)^s`. Regularity is exactly `zetaabs_bound`; this is the phantom consumed
    throughout the bracket layer (`ZetaTwo`, `Lambda*`). -/
def zeta (s : Nat) (hs : 2 ≤ s) : Real where
  seq := fun n => zetaSum s n
  reg := by
    intro m n
    show Qle (Qabs (Qsub (zetaSum s m) (zetaSum s n))) (add (Qbound m) (Qbound n))
    rcases Nat.le_total m n with h | h
    · refine Qle_trans
        (Qabs_den_pos (Qsub_den_pos (zetaSum_den_pos s n) (zetaSum_den_pos s m)))
        (Qeq_le (zeta_abs_comm (zetaSum s m) (zetaSum s n))) ?_
      refine Qle_trans (Nat.succ_pos m) (zetaabs_bound s hs h) ?_
      exact Qle_self_add (x := ⟨1, m + 1⟩) (p := ⟨1, n + 1⟩)
        (by
          show (0 : Int) ≤ ((⟨1, n + 1⟩ : Q).num : Int)
          rw [show ((⟨1, n + 1⟩ : Q).num : Int) = 1 from rfl]
          decide)
    · refine Qle_trans (Nat.succ_pos n) (zetaabs_bound s hs h) ?_
      have e := add_comm (⟨1, n + 1⟩ : Q) (Qbound m)
      exact Qle_congr_right (Nat.mul_pos (Nat.succ_pos n) (Nat.succ_pos m)) e
        (Qle_self_add (x := ⟨1, n + 1⟩) (p := ⟨1, m + 1⟩)
          (by
            show (0 : Int) ≤ ((⟨1, m + 1⟩ : Q).num : Int)
            rw [show ((⟨1, m + 1⟩ : Q).num : Int) = 1 from rfl]
            decide))
  den_pos := zetaSum_den_pos s

/-- **Depth-difference bound** `S(M) − S(N) ≤ 1/(N+1)` for `N ≤ M` (`s ≥ 2`): the telescoped tail
    is dominated by its first term (the phantom `zetadiff_bound` of the bracket layer). -/
theorem zetadiff_bound (s : Nat) (hs : 2 ≤ s) {N M : Nat} (h : N ≤ M) :
    Qle (Qsub (zetaSum s M) (zetaSum s N)) (⟨1, N + 1⟩ : Q) := by
  obtain ⟨d, hd⟩ : ∃ d, M = N + d := ⟨M - N, by omega⟩
  subst hd
  have ht := zetaTail_telescope s hs d N
  have hnq : Qle (neg ⟨1, N + d + 1⟩) (⟨0, 1⟩ : Q) := by
    show ((neg ⟨1, N + d + 1⟩).num : Int) * ((⟨0, 1⟩ : Q).den : Int)
        ≤ ((⟨0, 1⟩ : Q).num : Int) * ((neg ⟨1, N + d + 1⟩).den : Int)
    rw [show ((⟨0, 1⟩ : Q).den : Int) = 1 from rfl,
        show ((⟨0, 1⟩ : Q).num : Int) = 0 from rfl,
        show (neg ⟨1, N + d + 1⟩).num = -(1 : Int) from rfl,
        show (neg ⟨1, N + d + 1⟩).den = N + d + 1 from rfl]
    push_cast
    omega
  have e : Qeq (add ⟨1, N + 1⟩ (⟨0, 1⟩ : Q)) (⟨1, N + 1⟩ : Q) := by
    simp only [add, Qeq]; push_cast; ring_uor
  refine Qle_trans (Qsub_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) ht ?_
  exact Qle_congr_right (Nat.mul_pos (Nat.succ_pos _) Nat.one_pos) e
    (Qadd_le_add (Qle_refl (⟨1, N + 1⟩ : Q)) hnq)

end Multiplicity.UOR.Bridge.F1Square.Analysis
