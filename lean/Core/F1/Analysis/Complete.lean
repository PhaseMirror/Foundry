/-
F1 square — completeness of the constructive reals (the v0.7.0 analysis brick).

v0.6.0 made ℝ (and ℂ) commutative rings up to `≈`. This brick proves **Cauchy completeness**: every
*regular sequence of reals* converges, with an explicit rate — the constructive analogue of "ℝ is
complete", and the substrate the transcendentals will stand on (a power series is exactly a regular
sequence of its partial sums).

The construction is Bishop's diagonal (cf. Bishop–Bridges, *Constructive Analysis*, Ch. 2). A sequence
of reals `X : ℕ → Real` is **regular** when `X j` and `X k` agree within `1/(j+1) + 1/(k+1)` *as reals*
— i.e. at every index `n`, `|(X j)ₙ − (X k)ₙ| ≤ 1/(j+1) + 1/(k+1) + 2/(n+1)` (the `2/(n+1)` is the
modulus of the real comparison; without it the condition would be false for genuine Cauchy data such
as partial sums, where the coarse low-index approximants carry their own error). The limit is the
diagonal `n ↦ (X(4n+3))_{4n+3}`: the `4n+3` reindex is chosen so that the modulus is read at a large
index and the limit sequence is itself regular (`|·| ≤ 1/(m+1)+1/(n+1)`). Convergence then holds with
rate `1/(k+1)`.

Pure Lean 4, no Mathlib, no `sorry`.
-/

import Core.F1.Analysis.Real

namespace UOR.Bridge.F1Square.Analysis

/-- A fraction with a scaled denominator is bounded by the unit-denominator fraction it dominates:
    `p·(a+1) ≤ d ⟹ p/d ≤ 1/(a+1)`. The leaf bound for collapsing the diagonal's error tree. -/
theorem Qfrac_le {p d a : Nat} (h : p * (a + 1) ≤ d) : Qle (⟨(p : Int), d⟩ : Q) ⟨1, a + 1⟩ := by
  show (p : Int) * ((a + 1 : Nat) : Int) ≤ 1 * ((d : Nat) : Int)
  have hc : ((p * (a + 1) : Nat) : Int) ≤ ((d : Nat) : Int) := by exact_mod_cast h
  push_cast at hc ⊢
  omega

/-- A same-denominator sum (given as a `Qeq` to `p/d`) collapses and is bounded by `1/(a+1)`:
    `g = p/d` (value) and `p·(a+1) ≤ d ⟹ g ≤ 1/(a+1)`. -/
theorem Qcollapse_le {g : Q} {p d a : Nat} (hd : 0 < d) (he : Qeq g ⟨(p : Int), d⟩)
    (h : p * (a + 1) ≤ d) : Qle g ⟨1, a + 1⟩ :=
  Qle_congr_left hd (Qeq_symm he) (Qfrac_le h)

/-- **A regular sequence of reals** (a Cauchy sequence with the canonical modulus): `X j` and `X k`
    agree within `1/(j+1) + 1/(k+1)` as reals, i.e. at every index `n` the rational gap is
    `≤ 1/(j+1) + 1/(k+1) + 2/(n+1)`. -/
def RReg (X : Nat → Real) : Prop :=
  ∀ j k n : Nat, Qle (Qabs (Qsub ((X j).seq n) ((X k).seq n)))
    (add (add ⟨1, j + 1⟩ ⟨1, k + 1⟩) ⟨2, n + 1⟩)

/-- The diagonal sequence underlying the limit: `n ↦ (X(4n+3))_{4n+3}`. -/
def RlimSeq (X : Nat → Real) (n : Nat) : Q := (X (4 * n + 3)).seq (4 * n + 3)

/-- The diagonal sequence is regular — so it is a genuine constructive real. The `4n+3` reindex reads
    each real far enough out (where its modulus is small) that `|·| ≤ 1/(m+1)+1/(n+1)`. (Kept as a named
    lemma, not inlined in `Rlim`, so projecting `(Rlim X h).seq` stays cheap.) -/
theorem RlimSeq_regular (X : Nat → Real) (h : RReg X) : IsRegular (RlimSeq X) := by
    intro m n
    simp only [RlimSeq]
    have htri := Qabs_sub_triangle
      (a := (X (4 * m + 3)).seq (4 * m + 3)) (b := (X (4 * m + 3)).seq (4 * n + 3))
      (c := (X (4 * n + 3)).seq (4 * n + 3))
      ((X (4 * m + 3)).den_pos _) ((X (4 * m + 3)).den_pos _) ((X (4 * n + 3)).den_pos _)
    have hsum := Qadd_le_add ((X (4 * m + 3)).reg (4 * m + 3) (4 * n + 3))
      (h (4 * m + 3) (4 * n + 3) (4 * n + 3))
    -- collapse the m-group `2·1/(4m+4)` and the n-group `4·1/(4n+4)` to `1/(m+1)` and `1/(n+1)`
    have hmg : Qle (add (Qbound (4 * m + 3)) (Qbound (4 * m + 3))) (⟨1, m + 1⟩ : Q) :=
      Qcollapse_le (p := 2) (d := 4 * m + 3 + 1) (by omega)
        (by simp only [Qeq, add, Qbound]; push_cast; ring_uor) (by omega)
    have hng : Qle (add (add (Qbound (4 * n + 3)) (Qbound (4 * n + 3))) ⟨2, 4 * n + 3 + 1⟩)
        (⟨1, n + 1⟩ : Q) :=
      Qcollapse_le (p := 4) (d := 4 * n + 3 + 1) (by omega)
        (by simp only [Qeq, add, Qbound]; push_cast; ring_uor) (by omega)
    have hreg : Qeq
        (add (add (Qbound (4 * m + 3)) (Qbound (4 * n + 3)))
             (add (add (Qbound (4 * m + 3)) (Qbound (4 * n + 3))) ⟨2, 4 * n + 3 + 1⟩))
        (add (add (Qbound (4 * m + 3)) (Qbound (4 * m + 3)))
             (add (add (Qbound (4 * n + 3)) (Qbound (4 * n + 3))) ⟨2, 4 * n + 3 + 1⟩)) := by
      simp only [Qeq, add, Qbound]; push_cast; ring_uor
    have htree : Qle
        (add (add (Qbound (4 * m + 3)) (Qbound (4 * n + 3)))
             (add (add (Qbound (4 * m + 3)) (Qbound (4 * n + 3))) ⟨2, 4 * n + 3 + 1⟩))
        (add (Qbound m) (Qbound n)) :=
      Qle_congr_left
        (add_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
          (add_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (Nat.succ_pos _)))
        (Qeq_symm hreg) (Qadd_le_add hmg hng)
    refine Qle_trans ?_ htri (Qle_trans ?_ hsum htree)
    · exact add_den_pos
        (Qabs_den_pos (Qsub_den_pos ((X (4 * m + 3)).den_pos _) ((X (4 * m + 3)).den_pos _)))
        (Qabs_den_pos (Qsub_den_pos ((X (4 * m + 3)).den_pos _) ((X (4 * n + 3)).den_pos _)))
    · exact add_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
        (add_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (Nat.succ_pos _))

/-- **The limit of a regular sequence of reals** — Bishop's diagonal `(lim X)ₙ := (X(4n+3))_{4n+3}`,
    a genuine constructive real (regularity is `RlimSeq_regular`). -/
def Rlim (X : Nat → Real) (h : RReg X) : Real :=
  ⟨RlimSeq X, RlimSeq_regular X h, fun n => (X (4 * n + 3)).den_pos (4 * n + 3)⟩

/-- The limit's `n`-th rational approximant is the diagonal entry (definitional). -/
theorem Rlim_seq (X : Nat → Real) (h : RReg X) (n : Nat) :
    (Rlim X h).seq n = (X (4 * n + 3)).seq (4 * n + 3) := rfl

/-- **Convergence with a rate**: `X k → L` means each `X k` agrees with `L` within `2/(k+1)`, with the
    canonical index modulus `2/(n+1)`. -/
def RTendsTo (X : Nat → Real) (L : Real) : Prop :=
  ∀ k n : Nat, Qle (Qabs (Qsub ((X k).seq n) (L.seq n))) (add ⟨2, k + 1⟩ ⟨2, n + 1⟩)

-- `maxHeartbeats` raised only so the single 5-fraction regrouping identity (a `Qeq` discharged by the
-- verified `ring_uor`) fits the elaboration budget; the kernel-checked proof is unchanged.
set_option maxHeartbeats 1000000 in
/-- **Completeness of ℝ**: every regular sequence of reals converges to its diagonal limit, with rate
    `1/(k+1)` (the gap `|(X k)ₙ − (lim X)ₙ|` is `≤ 1/(k+1) + 2/(n+1) ≤ 2/(k+1) + 2/(n+1)`). Routing
    through the large index `4n+3` keeps the modulus small; regularity and the regular-sequence bound
    then close it. -/
theorem Rlim_tendsTo (X : Nat → Real) (h : RReg X) : RTendsTo X (Rlim X h) := by
  intro k n
  simp only [Rlim_seq]
  have htri := Qabs_sub_triangle
    (a := (X k).seq n) (b := (X k).seq (4 * n + 3)) (c := (X (4 * n + 3)).seq (4 * n + 3))
    ((X k).den_pos _) ((X k).den_pos _) ((X (4 * n + 3)).den_pos _)
  have hsum := Qadd_le_add ((X k).reg n (4 * n + 3)) (h k (4 * n + 3) (4 * n + 3))
  have hkg : Qle (Qbound k) (⟨2, k + 1⟩ : Q) := Qscale_le (by omega) (by omega) (Nat.le_refl k)
  -- collapse the `(4n+4)`-group to `1/(n+1)` first (a small, single-denominator identity), then add
  have hpart : Qle (add (add (Qbound (4 * n + 3)) (Qbound (4 * n + 3))) ⟨2, 4 * n + 3 + 1⟩)
      (⟨1, n + 1⟩ : Q) :=
    Qcollapse_le (p := 4) (d := 4 * n + 3 + 1) (by omega)
      (by simp only [Qeq, add, Qbound]; push_cast; ring_uor) (by omega)
  have hng : Qle (add (Qbound n) (add (add (Qbound (4 * n + 3)) (Qbound (4 * n + 3)))
        ⟨2, 4 * n + 3 + 1⟩)) (⟨2, n + 1⟩ : Q) :=
    Qle_trans (add_den_pos (Qbound_den_pos _) (Nat.succ_pos _))
      (Qadd_le_add (Qle_refl (Qbound n)) hpart)
      (by apply Qeq_le; simp only [Qeq, add, Qbound]; push_cast; ring_uor)
  have hreg : Qeq
      (add (add (Qbound n) (Qbound (4 * n + 3)))
           (add (add (Qbound k) (Qbound (4 * n + 3))) ⟨2, 4 * n + 3 + 1⟩))
      (add (Qbound k)
           (add (Qbound n) (add (add (Qbound (4 * n + 3)) (Qbound (4 * n + 3))) ⟨2, 4 * n + 3 + 1⟩))) := by
    simp only [Qeq, add, Qbound]; push_cast; ring_uor
  have htree : Qle
      (add (add (Qbound n) (Qbound (4 * n + 3)))
           (add (add (Qbound k) (Qbound (4 * n + 3))) ⟨2, 4 * n + 3 + 1⟩))
      (add (⟨2, k + 1⟩ : Q) ⟨2, n + 1⟩) :=
    Qle_congr_left
      (add_den_pos (Qbound_den_pos _)
        (add_den_pos (Qbound_den_pos _)
          (add_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (Nat.succ_pos _))))
      (Qeq_symm hreg) (Qadd_le_add hkg hng)
  refine Qle_trans ?_ htri (Qle_trans ?_ hsum htree)
  · exact add_den_pos
      (Qabs_den_pos (Qsub_den_pos ((X k).den_pos _) ((X k).den_pos _)))
      (Qabs_den_pos (Qsub_den_pos ((X k).den_pos _) ((X (4 * n + 3)).den_pos _)))
  · exact add_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
      (add_den_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (Nat.succ_pos _))

/-- `|a − b|` is symmetric (same value as `|b − a|`): the numerator negates, the denominator and the
    absolute value are unchanged. -/
theorem Qabs_Qsub_comm (a b : Q) : Qabs (Qsub a b) = Qabs (Qsub b a) := by
  unfold Qabs
  rw [Qsub_swap_num a b, Qsub_swap_den a b, Int.natAbs_neg]

/-- **Limits are unique up to `≈`**: if `X → L` and `X → L'` then `L ≈ L'`. For each index `n`, the
    gap `|Lₙ − L'ₙ| ≤ 4/(k+1) + 4/(n+1)` for every `k` (triangle through `(X k)ₙ`); the Archimedean
    lemma kills the `k`-tail, and the linear-bound criterion turns the residual `4/(n+1)` into `≈`. -/
theorem RTendsTo_unique {X : Nat → Real} {L L' : Real}
    (hL : RTendsTo X L) (hL' : RTendsTo X L') : Req L L' := by
  apply Req_of_lin_bound (C := 4)
  intro n
  apply Qarch_gen (C := 4)
    (Qabs_den_pos (Qsub_den_pos (L.den_pos n) (L'.den_pos n))) (Nat.succ_pos n)
  intro k
  have htri := Qabs_sub_triangle (a := L.seq n) (b := (X k).seq n) (c := L'.seq n)
    (L.den_pos n) ((X k).den_pos n) (L'.den_pos n)
  have hb1 : Qle (Qabs (Qsub (L.seq n) ((X k).seq n))) (add (⟨2, k + 1⟩ : Q) ⟨2, n + 1⟩) := by
    rw [Qabs_Qsub_comm]; exact hL k n
  have hfin : Qle (add (add (⟨2, k + 1⟩ : Q) ⟨2, n + 1⟩) (add ⟨2, k + 1⟩ ⟨2, n + 1⟩))
      (add (⟨4, n + 1⟩ : Q) ⟨4, k + 1⟩) := by
    apply Qeq_le; simp only [Qeq, add]; push_cast; ring_uor
  exact Qle_trans
    (add_den_pos (Qabs_den_pos (Qsub_den_pos (L.den_pos n) ((X k).den_pos n)))
      (Qabs_den_pos (Qsub_den_pos ((X k).den_pos n) (L'.den_pos n)))) htri
    (Qle_trans (add_den_pos (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
        (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)))
      (Qadd_le_add hb1 (hL' k n)) hfin)

end UOR.Bridge.F1Square.Analysis
