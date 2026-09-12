/-
F1 square — **the constructed `t4` dilog** (`DilogPieces.lean`): the three unit pieces of
`∫₁⁴ log x/(x−1) dx` as genuine certified integrals of the kernel `Φ`,

    `dilogPiece c' = ∫₀¹ Φ(c' + t) dt`   (`c' = 0, 1, 2`),   `t4Dilog = Σ dilogPiece c'`,

and the **rational lower bound** `t4Dilog ≥ 1.909` (true value `−Li₂(−3) ≈ 1.93939`): the outer
monotone dyadic bracket (level `M = 4`) over per-sample kernel brackets (level `m = 7`) collapses
the whole bound to ONE rational inequality — no logs, no wedges, pure `decide`.

HONEST SCOPE. The dilog is CONSTRUCTED (kernel form) and BOUNDED BELOW; no closed form exists and
none is claimed. The sign `W(t4) > 0` is a later assembly; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.DilogPhiVal
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The outer integrands `t ↦ Φ(c' + t)` and the pieces.
-- ===========================================================================

/-- The shifted kernel `t ↦ Φ(c' + t)` — the `[c'+1, c'+2]`-piece integrand of the dilog. -/
def dgPiece (c' : Nat) (t : Real) : Real :=
  Phi (Radd (ofQ (⟨(c' : Int), 1⟩ : Q) Nat.one_pos) t)

/-- The shifted kernel respects `≈`. -/
theorem dgPiece_congr (c' : Nat) : ∀ x y : Real, Req x y → Req (dgPiece c' x) (dgPiece c' y) :=
  fun _ _ h => Phi_congr _ _ (Radd_congr (Req_refl _) h)

/-- The shifted kernel is `16`-Lipschitz (the shift drops out of the difference). -/
theorem dgPiece_lip (c' : Nat) : ∀ x y : Real,
    Rle (Rabs (Rsub (dgPiece c' x) (dgPiece c' y)))
        (Rmul (ofQ (⟨16, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Phi_lip _ _) ?_
  refine Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_congr ?_))
  refine Req_trans (Rsub_Radd_Radd _ _ _ _) ?_
  refine Req_trans (Radd_congr (Radd_neg _) (Req_refl _)) ?_
  exact Req_trans (Radd_comm zero _) (Radd_zero _)

/-- **The constructed dilog piece** `∫₀¹ Φ(c'+t) dt = ∫_{c'+1}^{c'+2} log x/(x−1) dx`. -/
def dilogPiece (c' : Nat) : Real :=
  riemannIntegral (f := dgPiece c') (L := (⟨16, 1⟩ : Q)) (by decide) (by decide)
    (dgPiece_lip c') (dgPiece_congr c')

/-- **The constructed `t4` dilog** `∫₁⁴ log x/(x−1) dx` (kernel form). -/
def t4Dilog : Real := Radd (Radd (dilogPiece 0) (dilogPiece 1)) (dilogPiece 2)

-- ===========================================================================
-- Side conditions for the shifted rationals `c' + s`.
-- ===========================================================================

private theorem dg_u_nonneg {c' : Nat} {s : Q} (hsn : 0 ≤ s.num) :
    0 ≤ (add (⟨(c' : Int), 1⟩ : Q) s).num := by
  show 0 ≤ (c' : Int) * ((s.den : Nat) : Int) + s.num * ((1 : Nat) : Int)
  have h := Int.mul_nonneg (Int.ofNat_nonneg c') (Int.ofNat_nonneg s.den)
  push_cast
  push_cast at h
  omega

private theorem dg_u_ge0 {c' : Nat} {s : Q} (hsn : 0 ≤ s.num) :
    Qle (⟨0, 1⟩ : Q) (add (⟨(c' : Int), 1⟩ : Q) s) := by
  show (0 : Int) * ((1 * s.den : Nat) : Int)
      ≤ ((c' : Int) * ((s.den : Nat) : Int) + s.num * ((1 : Nat) : Int)) * ((1 : Nat) : Int)
  have h := Int.mul_nonneg (Int.ofNat_nonneg c') (Int.ofNat_nonneg s.den)
  push_cast
  push_cast at h
  omega

private theorem dg_u_le3 {c' : Nat} (hc : c' ≤ 2) {s : Q} (hs1 : Qle s (⟨1, 1⟩ : Q)) :
    Qle (add (⟨(c' : Int), 1⟩ : Q) s) (⟨3, 1⟩ : Q) := by
  have h1 := hs1
  simp only [Qle] at h1
  push_cast at h1
  have hc' : ((c' : Nat) : Int) * ((s.den : Nat) : Int) ≤ 2 * ((s.den : Nat) : Int) :=
    Int.mul_le_mul_of_nonneg_right (by exact_mod_cast hc) (Int.ofNat_nonneg _)
  show ((c' : Int) * ((s.den : Nat) : Int) + s.num * ((1 : Nat) : Int)) * ((1 : Nat) : Int)
      ≤ (3 : Int) * ((1 * s.den : Nat) : Int)
  push_cast
  push_cast at hc'
  omega

/-- **The shifted kernel is sample-antitone** on `[0,1]` (`c' ≤ 2`). -/
theorem dgPiece_sampleAnti (c' : Nat) (hc : c' ≤ 2) : SampleAnti (dgPiece c') := by
  intro a b had hbd h0a hab hb1
  have han : 0 ≤ a.num := by
    have h := h0a; simp only [Qle] at h; push_cast at h; omega
  have hbn : 0 ≤ b.num := by
    have h := Qle_trans had h0a hab; simp only [Qle] at h; push_cast at h; omega
  refine Rle_trans (Rle_of_Req (Phi_congr _ _ (Radd_ofQ_ofQ Nat.one_pos hbd))) ?_
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (Phi_congr _ _ (Radd_ofQ_ofQ Nat.one_pos had))))
  refine Phi_ofQ_anti (add_den_pos Nat.one_pos had) (add_den_pos Nat.one_pos hbd)
    (dg_u_ge0 han) ?_ (dg_u_le3 hc hb1) (dg_u_nonneg han) (dg_u_nonneg hbn)
  exact Qadd_le_add (Qle_refl (⟨(c' : Int), 1⟩ : Q)) hab

-- ===========================================================================
-- The rational lower fold over the outer samples.
-- ===========================================================================

/-- The per-sample kernel cap `(3/4)/2^m`. -/
def qCapIn (m : Nat) : Q := mul (⟨1, 2 ^ m⟩ : Q) (⟨3, 4⟩ : Q)

/-- **The lower fold**: `Σ_{j<n} (phiRat(c' + j/D, 2^m−1) − (3/4)/2^m)` — a rational under-sum
    of the outer samples `Φ(c' + j/D)`. -/
def qFoldLo (c' D m : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | (n + 1) => add (qFoldLo c' D m n)
      (Qsub (phiRat (add (⟨(c' : Int), 1⟩ : Q) (⟨(n : Int), D⟩ : Q)) (2 ^ m - 1)) (qCapIn m))

theorem qFoldLo_den_pos (c' D m : Nat) (hD : 0 < D) : ∀ n, 0 < (qFoldLo c' D m n).den
  | 0 => Nat.one_pos
  | (n + 1) => add_den_pos (qFoldLo_den_pos c' D m hD n)
      (Qsub_den_pos
        (phiRat_den_pos _ (add_den_pos Nat.one_pos hD) (dg_u_nonneg (Int.ofNat_nonneg n)) _)
        (Qmul_den_pos (Nat.pos_pow_of_pos m (by decide)) (by decide)))

/-- Each outer-sample sum dominates the lower fold (`m ≤ 17`, samples in `[0,1]`). -/
theorem RsumN_dg_ge (c' : Nat) (hc : c' ≤ 2) (N : Nat) (m : Nat) (hm : m ≤ 17) :
    ∀ n, n ≤ N + 1 →
    Rle (ofQ (qFoldLo c' (N + 1) m n) (qFoldLo_den_pos c' (N + 1) m (Nat.succ_pos N) n))
        (RsumN (fun i => dgPiece c' (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) n)
  | 0, _ => Rle_of_Req (Req_refl _)
  | (n + 1), hn => by
      have hsn : (0 : Int) ≤ ((⟨(n : Int), N + 1⟩ : Q)).num := Int.ofNat_nonneg n
      have hs1 : Qle (⟨(n : Int), N + 1⟩ : Q) (⟨1, 1⟩ : Q) := by
        simp only [Qle]; push_cast; omega
      have hterm : 0 < (Qsub (phiRat (add (⟨(c' : Int), 1⟩ : Q) (⟨(n : Int), N + 1⟩ : Q))
          (2 ^ m - 1)) (qCapIn m)).den :=
        Qsub_den_pos (phiRat_den_pos _ (add_den_pos Nat.one_pos (Nat.succ_pos N))
            (dg_u_nonneg (Int.ofNat_nonneg n)) _)
          (Qmul_den_pos (Nat.pos_pow_of_pos m (by decide)) (by decide))
      refine Rle_trans (Rle_of_Req (Req_symm (Radd_ofQ_ofQ
        (qFoldLo_den_pos c' (N + 1) m (Nat.succ_pos N) n) hterm))) ?_
      refine Radd_le_add (RsumN_dg_ge c' hc N m hm n (by omega)) ?_
      refine Rle_trans (Phi_ofQ_ge (add (⟨(c' : Int), 1⟩ : Q) (⟨(n : Int), N + 1⟩ : Q))
        (add_den_pos Nat.one_pos (Nat.succ_pos N)) (dg_u_ge0 hsn) (dg_u_le3 hc hs1)
        (dg_u_nonneg hsn) m hm) ?_
      exact Rle_of_Req (Req_symm (Phi_congr _ _ (Radd_ofQ_ofQ Nat.one_pos (Nat.succ_pos N))))

/-- The dyadic sum of the shifted kernel dominates the scaled lower fold. -/
theorem dyadicR_dg_ge (c' : Nat) (hc : c' ≤ 2) (M m : Nat) (hm : m ≤ 17) :
    Rle (ofQ (mul (⟨1, 2 ^ M - 1 + 1⟩ : Q)
          (qFoldLo c' (2 ^ M - 1 + 1) m (2 ^ M - 1 + 1)))
          (Qmul_den_pos (Nat.succ_pos _) (qFoldLo_den_pos c' (2 ^ M - 1 + 1) m
            (Nat.succ_pos _) (2 ^ M - 1 + 1))))
        (dyadicR (dgPiece c') M) := by
  show Rle _ (riemannSum (dgPiece c') (2 ^ M - 1))
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (Nat.succ_pos (2 ^ M - 1))
    (qFoldLo_den_pos c' (2 ^ M - 1 + 1) m (Nat.succ_pos _) (2 ^ M - 1 + 1))))) ?_
  refine Rmul_le_Rmul_left (Rnonneg_ofQ (Nat.succ_pos (2 ^ M - 1))
    (show (0 : Int) ≤ 1 by decide)) ?_
  exact RsumN_dg_ge c' hc (2 ^ M - 1) m hm (2 ^ M - 1 + 1) (Nat.le_refl _)

-- ===========================================================================
-- The outer variation bound and the piece lower bounds.
-- ===========================================================================

/-- The exact rational outer-variation witness
    `phiRat(c'+0) − (phiRat(c'+1) − cap) ≥ Φ(c') − Φ(c'+1)`. -/
def qVc (c' m : Nat) : Q :=
  Qsub (phiRat (add (⟨(c' : Int), 1⟩ : Q) (⟨0, 1⟩ : Q)) (2 ^ m - 1))
       (Qsub (phiRat (add (⟨(c' : Int), 1⟩ : Q) (⟨1, 1⟩ : Q)) (2 ^ m - 1)) (qCapIn m))

/-- The shifted kernel's endpoint variation is below any rational above `qVc` (`m ≤ 17`). -/
theorem dg_var (c' : Nat) (hc : c' ≤ 2) (m : Nat) (hm : m ≤ 17)
    {V : Q} (hVd : 0 < V.den) (hQV : Qle (qVc c' m) V) :
    Rle (Rsub (dgPiece c' (ofQ (⟨0, 1⟩ : Q) Nat.one_pos))
              (dgPiece c' (ofQ (⟨1, 1⟩ : Q) Nat.one_pos))) (ofQ V hVd) := by
  have h0n : (0 : Int) ≤ ((⟨0, 1⟩ : Q)).num := by decide
  have h1n : (0 : Int) ≤ ((⟨1, 1⟩ : Q)).num := by decide
  have h01 : Qle (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) := by decide
  have h11 : Qle (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) := Qle_refl _
  have hup : Rle (dgPiece c' (ofQ (⟨0, 1⟩ : Q) Nat.one_pos))
      (ofQ (phiRat (add (⟨(c' : Int), 1⟩ : Q) (⟨0, 1⟩ : Q)) (2 ^ m - 1))
        (phiRat_den_pos _ (add_den_pos Nat.one_pos Nat.one_pos) (dg_u_nonneg h0n) _)) := by
    refine Rle_trans (Rle_of_Req (Phi_congr _ _ (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos))) ?_
    exact Phi_ofQ_le _ (add_den_pos Nat.one_pos Nat.one_pos) (dg_u_ge0 h0n)
      (dg_u_le3 hc h01) (dg_u_nonneg h0n) m hm
  have hlo : Rle (ofQ (Qsub (phiRat (add (⟨(c' : Int), 1⟩ : Q) (⟨1, 1⟩ : Q)) (2 ^ m - 1))
        (qCapIn m))
        (Qsub_den_pos (phiRat_den_pos _ (add_den_pos Nat.one_pos Nat.one_pos)
          (dg_u_nonneg h1n) _) (Qmul_den_pos (Nat.pos_pow_of_pos m (by decide)) (by decide))))
      (dgPiece c' (ofQ (⟨1, 1⟩ : Q) Nat.one_pos)) := by
    refine Rle_trans (Phi_ofQ_ge _ (add_den_pos Nat.one_pos Nat.one_pos) (dg_u_ge0 h1n)
      (dg_u_le3 hc h11) (dg_u_nonneg h1n) m hm) ?_
    exact Rle_of_Req (Req_symm (Phi_congr _ _ (Radd_ofQ_ofQ Nat.one_pos Nat.one_pos)))
  refine Rle_trans (Radd_le_add hup (Rle_Rneg hlo)) ?_
  refine Rle_trans (Rle_of_Req (Rsub_ofQ_ofQ
    (phiRat_den_pos _ (add_den_pos Nat.one_pos Nat.one_pos) (dg_u_nonneg h0n) _)
    (Qsub_den_pos (phiRat_den_pos _ (add_den_pos Nat.one_pos Nat.one_pos)
      (dg_u_nonneg h1n) _)
      (Qmul_den_pos (Nat.pos_pow_of_pos m (by decide)) (by decide))))) ?_
  exact Rle_ofQ_ofQ _ _ hQV

/-- **The generic piece lower bound**: for `c' ≤ 2` and any rational `V ≥ qVc c' 7`,
    `dilogPiece c' ≥ (1/16)·qFoldLo(c', 16, 7) − V/16` — all data rational. -/
theorem dilogPiece_ge (c' : Nat) (hc : c' ≤ 2) {V : Q} (hVd : 0 < V.den) (hVn : 0 ≤ V.num)
    (hQV : Qle (qVc c' 7) V) :
    Rle (ofQ (Qsub (mul (⟨1, 2 ^ 4 - 1 + 1⟩ : Q)
          (qFoldLo c' (2 ^ 4 - 1 + 1) 7 (2 ^ 4 - 1 + 1)))
          (mul (⟨1, 2 ^ 4⟩ : Q) V))
          (Qsub_den_pos (Qmul_den_pos (Nat.succ_pos _) (qFoldLo_den_pos c' (2 ^ 4 - 1 + 1) 7
            (Nat.succ_pos _) (2 ^ 4 - 1 + 1)))
            (Qmul_den_pos (Nat.pos_pow_of_pos 4 (by decide)) hVd)))
        (dilogPiece c') := by
  have hlow := riemannIntegral_anti_lower (by decide) (by decide) (dgPiece_lip c')
    (dgPiece_congr c') (dgPiece_sampleAnti c' hc) (V := V) hVd hVn
    (dg_var c' hc 7 (by omega) hVd hQV) 4 (phi_sched (by omega))
  -- `foldLo ≤ D_4 ≤ dilogPiece + V/16`, then shuffle the cap across.
  have hchain : Rle (ofQ (mul (⟨1, 2 ^ 4 - 1 + 1⟩ : Q)
        (qFoldLo c' (2 ^ 4 - 1 + 1) 7 (2 ^ 4 - 1 + 1)))
        (Qmul_den_pos (Nat.succ_pos _) (qFoldLo_den_pos c' (2 ^ 4 - 1 + 1) 7
          (Nat.succ_pos _) (2 ^ 4 - 1 + 1))))
      (Radd (dilogPiece c')
        (ofQ (mul (⟨1, 2 ^ 4⟩ : Q) V)
          (Qmul_den_pos (Nat.pos_pow_of_pos 4 (by decide)) hVd))) :=
    Rle_trans (dyadicR_dg_ge c' hc 4 7 (by omega)) hlow
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ
    (Qmul_den_pos (Nat.succ_pos _) (qFoldLo_den_pos c' (2 ^ 4 - 1 + 1) 7
      (Nat.succ_pos _) (2 ^ 4 - 1 + 1)))
    (Qmul_den_pos (Nat.pos_pow_of_pos 4 (by decide)) hVd)))) ?_
  exact Rsub_le_of_le_Radd (Rle_trans hchain (Rle_of_Req (Radd_comm _ _)))

end Multiplicity.UOR.Bridge.F1Square.Analysis
