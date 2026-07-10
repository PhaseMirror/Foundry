import F1Square.Analysis.RlogMulSigned

/-!
# General-radius (`ρ < 1`) artanh continuity — toward fully general `Rlog`/`Clog`

The bounded/symmetric-band discharges (`RlogMulPos`, `RlogMulSigned`) are gated by the small-radius
constraint `ρ² ≤ 1/2` in the artanh continuity lemmas (`Rartanh_congr`, `Rartanh_radius_indep`),
inherited from `geoEvenSum_le_two` (the even geometric sum `Σρ^{2k} ≤ 2`). For large moduli the
radius `ρ_B = (B−1)/(B+1)` approaches 1, so `ρ² ≤ 1/2` fails.

Key observation: `geoEvenSum ρ N ≤ 1/(1−ρ²) ≤ d²/(2d−1) ~ d/2` (`d = ρ.den`), while the artanh
reindex factor is `ρ.den²+4ρ.den ~ d²`. So the **existing reindex already absorbs** the general
`1/(1−ρ²)` bound — `ρ²≤1/2` is needed only for the clean constant `2`, not for convergence. This file
generalizes the continuity lemmas to any `ρ < 1` with an explicit absorbable bound `K`.
-/

namespace UOR.Bridge.F1Square.Analysis

/-- **General even-geometric-sum bound** `Σ_{k≤N} ρ^{2k} ≤ K` for any `K ≥ 1/(1−ρ²)` (`K·(1−ρ²) ≥ 1`).
    Generalizes `geoEvenSum_le_two` (`K = 2`, `ρ² ≤ 1/2`) to arbitrary `ρ < 1` via `mul_div_gen`. -/
theorem geoEvenSum_le_gen {ρ K : Q} (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hKd : 0 < K.den) (hK0 : 0 ≤ K.num)
    (hKF : Qle (⟨1, 1⟩ : Q) (mul K (Qsub ⟨1, 1⟩ (mul ρ ρ)))) (N : Nat) :
    Qle (geoEvenSum ρ N) K := by
  have hsd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul ρ ρ)).den := Qsub_den_pos Nat.one_pos (Qmul_den_pos hρd hρd)
  have hab : Qle (mul (geoEvenSum ρ N) (Qsub ⟨1, 1⟩ (mul ρ ρ))) ⟨1, 1⟩ :=
    Qle_trans (add_den_pos (Qmul_den_pos (geoEvenSum_den_pos hρd N) hsd) (qpow_den_pos hρd _))
      (Qle_self_add (qpow_nonneg hρ0 (2 * N + 2)))
      (Qeq_le (geoEven_eq hρd N))
  exact Qle_trans (Qmul_den_pos hKd Nat.one_pos)
    (mul_div_gen (geoEvenSum_num_nonneg hρ0 N) (geoEvenSum_den_pos hρd N) hsd hKd hK0 hKF hab)
    (Qeq_le (mul_one K))

set_option maxHeartbeats 800000 in
/-- **General-radius `Rartanh` argument-congruence**: `Req t t' ⟹ Req (Rartanh t) (Rartanh t')` for any
    `ρ < 1` (no `ρ² ≤ 1/2`). The even-sum bound `geoEvenSum ≤ K` (`K·(1−ρ²) ≥ 1`, `K` a Nat) is absorbed
    by the artanh reindex provided `K ≤ 2(ρ.den²+4ρ.den)` (`hKr`) — which holds for every `ρ < 1`. The
    generalization of `Rartanh_congr` past the small-radius cap. -/
theorem Rartanh_congr_gen (t t' : Real) (ρ : Q) (K : Nat) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hlt : ρ.num.toNat < ρ.den)
    (hKF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K : Int), 1⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))))
    (hKr : K ≤ 2 * (ρ.den * ρ.den + 4 * ρ.den))
    (hbt : ∀ n, Qle (Qabs (t.seq n)) ρ) (hbt' : ∀ n, Qle (Qabs (t'.seq n)) ρ) (heq : Req t t') :
    Req (Rartanh t ρ hρ0 hρd hlt hbt) (Rartanh t' ρ hρ0 hρd hlt hbt') := by
  refine Req_of_lin_bound (C := 4) ?_
  intro n
  show Qle (Qabs (Qsub (artSum (t.seq (Rartanh_R ρ n)) (Rartanh_R ρ n))
      (artSum (t'.seq (Rartanh_R ρ n)) (Rartanh_R ρ n)))) (⟨(4 : Int), n + 1⟩ : Q)
  have hdiffd : 0 < (Qsub (t.seq (Rartanh_R ρ n)) (t'.seq (Rartanh_R ρ n))).den :=
    Qsub_den_pos (t.den_pos _) (t'.den_pos _)
  refine Qle_trans (Qmul_den_pos (geoEvenSum_den_pos hρd _) (Qabs_den_pos hdiffd))
    (artSum_Lip_le (t.den_pos _) (t'.den_pos _) hρd (hbt _) (hbt' _) (Rartanh_R ρ n)) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos hdiffd))
    (Qmul_le_mul_right (Qabs_num_nonneg _)
      (geoEvenSum_le_gen hρ0 hρd Nat.one_pos (by exact Int.ofNat_nonneg K) hKF (Rartanh_R ρ n))) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Nat.succ_pos _))
    (Qmul_le_mul_left (Int.ofNat_nonneg K) (heq (Rartanh_R ρ n))) ?_
  show ((K : Int) * 2) * ((n + 1 : Nat) : Int) ≤ (4 : Int) * ((1 * (Rartanh_R ρ n + 1) : Nat) : Int)
  unfold Rartanh_R
  push_cast
  have hk2 : (K : Int) * 2 ≤ 4 * ((ρ.den : Int) * ρ.den + 4 * ρ.den) := by
    have h := hKr; push_cast at h; omega
  have hmnn : (0 : Int) ≤ (n : Int) + 1 := by omega
  have hprod := Int.mul_le_mul_of_nonneg_right hk2 hmnn
  have e1 : (4 * ((ρ.den : Int) * ρ.den + 4 * ρ.den)) * ((n : Int) + 1)
      = 4 * (((ρ.den : Int) * ρ.den + 4 * ρ.den) * ((n : Int) + 1)) := by
    generalize ((ρ.den : Int) * ρ.den + 4 * ρ.den) = A; generalize ((n : Int) + 1) = m; ring_uor
  have e2 : (4 : Int) * (1 * (((ρ.den : Int) * ρ.den + 4 * ρ.den) * ((n : Int) + 1) + 1))
      = 4 * (((ρ.den : Int) * ρ.den + 4 * ρ.den) * ((n : Int) + 1)) + 4 := by
    generalize ((ρ.den : Int) * ρ.den + 4 * ρ.den) * ((n : Int) + 1) = P; ring_uor
  rw [e1] at hprod; rw [e2]; omega

/-- **General-radius depth-Cauchy bound** for `artSum`: `|artSum u b − artSum u a| ≤ K·σ.den/(n+1)` for
    `a ≤ b`, `n+1 ≤ 2a+3`, any `σ < 1` with the even-sum bound `K` (`K·(1−σ²) ≥ 1`). Generalizes
    `artSum_depth_recip` (`K = 2`, `σ²≤1/2`) by swapping `mul_div2 → mul_div_gen`. -/
theorem artSum_depth_recip_gen (u σ : Q) (K : Nat) (hud : 0 < u.den) (hσ0 : 0 ≤ σ.num) (hσd : 0 < σ.den)
    (hu : Qle (Qabs u) σ) (hKF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K : Int), 1⟩ : Q) (Qsub ⟨1, 1⟩ (mul σ σ))))
    (hσlt : σ.num.toNat < σ.den) {a b n : Nat} (hab : a ≤ b) (hn : n + 1 ≤ 2 * a + 3) :
    Qle (Qabs (Qsub (artSum u b) (artSum u a))) (⟨(K : Int) * (σ.den : Int), n + 1⟩ : Q) := by
  have hWd : 0 < (Qsub (⟨1, 1⟩ : Q) (mul σ σ)).den := Qsub_den_pos Nat.one_pos (Qmul_den_pos hσd hσd)
  have hW : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul σ σ)).num := by
    rcases Int.le_total 0 (Qsub (⟨1, 1⟩ : Q) (mul σ σ)).num with h | h
    · exact h
    · exfalso
      have hKnn : (0 : Int) ≤ (K : Int) := Int.ofNat_nonneg K
      have hkey : ((Qsub (⟨1, 1⟩ : Q) (mul σ σ)).den : Int)
          ≤ (K : Int) * (Qsub (⟨1, 1⟩ : Q) (mul σ σ)).num := by
        have hh := hKF; simp only [Qle, mul] at hh ⊢; push_cast at hh ⊢; omega
      have hmn : (K : Int) * (Qsub (⟨1, 1⟩ : Q) (mul σ σ)).num ≤ (K : Int) * 0 :=
        Int.mul_le_mul_of_nonneg_left h hKnn
      have hd1 : (1 : Int) ≤ ((Qsub (⟨1, 1⟩ : Q) (mul σ σ)).den : Int) := by exact_mod_cast hWd
      simp only [Int.mul_zero] at hmn; omega
  have htrunc := artSum_trunc hud hσ0 hσd hu hW hab
  have hd2 := mul_div_gen (Qabs_num_nonneg _)
    (Qabs_den_pos (Qsub_den_pos (artSum_den_pos hud b) (artSum_den_pos hud a)))
    (Qsub_den_pos Nat.one_pos (Qmul_den_pos hσd hσd)) Nat.one_pos (Int.ofNat_nonneg K) hKF htrunc
  refine Qle_trans (Qmul_den_pos Nat.one_pos (qpow_den_pos hσd _)) hd2 ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Nat.succ_pos n))
    (Qmul_le_mul_left (Int.ofNat_nonneg K) (qpow_le_recip hσ0 hσd hσlt hn)) ?_
  apply Qeq_le; simp only [Qeq, mul]; push_cast; ring_uor

set_option maxHeartbeats 1200000 in
/-- **General-radius `Rartanh` radius-independence**: `Rartanh t ρ ≈ Rartanh t ρ'` for any two radii
    `ρ, ρ'`, with `t` bounded by `τ < 1` carrying the even-sum bound `K` (`K·(1−τ²) ≥ 1`). The
    generalization of `Rartanh_radius_indep` past `τ²≤1/2`, via `artSum_depth_recip_gen` (`K·τ.den`
    legs) + `geoEvenSum_le_gen` (`2K` Lipschitz leg). Conclusion `Req` is `C`-agnostic. -/
theorem Rartanh_radius_indep_gen (t X X' : Real) (ρ ρ' τ : Q) (K : Nat) (hρd : 0 < ρ.den)
    (hρ'd : 0 < ρ'.den) (hτ0 : 0 ≤ τ.num) (hτd : 0 < τ.den) (hτlt : τ.num.toNat < τ.den)
    (hKF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K : Int), 1⟩ : Q) (Qsub ⟨1, 1⟩ (mul τ τ))))
    (hbt : ∀ m, Qle (Qabs (t.seq m)) τ)
    (hXseq : ∀ j, X.seq j = artSum (t.seq (Rartanh_R ρ j)) (Rartanh_R ρ j))
    (hX'seq : ∀ j, X'.seq j = artSum (t.seq (Rartanh_R ρ' j)) (Rartanh_R ρ' j)) :
    Req X X' := by
  have htd : ∀ m, 0 < (t.seq m).den := fun m => t.den_pos m
  have hRge : ∀ (r : Q), 0 < r.den → ∀ j, j + 1 ≤ Rartanh_R r j := by
    intro r hrd j; unfold Rartanh_R
    have hk : 1 ≤ r.den * r.den + 4 * r.den := Nat.le_trans (by omega : 1 ≤ 4 * r.den) (Nat.le_add_left _ _)
    calc j + 1 = 1 * (j + 1) := by omega
      _ ≤ (r.den * r.den + 4 * r.den) * (j + 1) := Nat.mul_le_mul_right _ hk
  refine Req_of_lin_bound (C := 2 * K * τ.den + 2 * K) ?_
  intro n
  rw [hXseq, hX'seq]
  have hage := hRge ρ hρd n
  have hbge := hRge ρ' hρ'd n
  have haM : Rartanh_R ρ n ≤ max (Rartanh_R ρ n) (Rartanh_R ρ' n) := Nat.le_max_left _ _
  have hbM : Rartanh_R ρ' n ≤ max (Rartanh_R ρ n) (Rartanh_R ρ' n) := Nat.le_max_right _ _
  have hna : n + 1 ≤ 2 * Rartanh_R ρ n + 3 := by omega
  have hnb : n + 1 ≤ 2 * Rartanh_R ρ' n + 3 := by omega
  have hT1 : Qle (Qabs (Qsub (artSum (t.seq (Rartanh_R ρ n)) (Rartanh_R ρ n))
        (artSum (t.seq (Rartanh_R ρ n)) (max (Rartanh_R ρ n) (Rartanh_R ρ' n)))))
      (⟨(K : Int) * (τ.den : Int), n + 1⟩ : Q) := by
    rw [Qabs_Qsub_comm]
    exact artSum_depth_recip_gen (t.seq (Rartanh_R ρ n)) τ K (htd _) hτ0 hτd (hbt _) hKF hτlt haM hna
  have hT3 : Qle (Qabs (Qsub (artSum (t.seq (Rartanh_R ρ' n)) (max (Rartanh_R ρ n) (Rartanh_R ρ' n)))
        (artSum (t.seq (Rartanh_R ρ' n)) (Rartanh_R ρ' n)))) (⟨(K : Int) * (τ.den : Int), n + 1⟩ : Q) :=
    artSum_depth_recip_gen (t.seq (Rartanh_R ρ' n)) τ K (htd _) hτ0 hτd (hbt _) hKF hτlt hbM hnb
  have hT2 : Qle (Qabs (Qsub (artSum (t.seq (Rartanh_R ρ n)) (max (Rartanh_R ρ n) (Rartanh_R ρ' n)))
        (artSum (t.seq (Rartanh_R ρ' n)) (max (Rartanh_R ρ n) (Rartanh_R ρ' n)))))
      (⟨2 * (K : Int), n + 1⟩ : Q) := by
    refine Qle_trans (Qmul_den_pos (geoEvenSum_den_pos hτd _)
        (Qabs_den_pos (Qsub_den_pos (htd _) (htd _))))
      (artSum_Lip_le (htd _) (htd _) hτd (hbt _) (hbt _) _) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos (htd _) (htd _))))
      (Qmul_le_mul_right (Qabs_num_nonneg _)
        (geoEvenSum_le_gen hτ0 hτd Nat.one_pos (Int.ofNat_nonneg K) hKF _)) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)))
      (Qmul_le_mul_left (Int.ofNat_nonneg K) (t.reg (Rartanh_R ρ n) (Rartanh_R ρ' n))) ?_
    have hRa : Qle (Qbound (Rartanh_R ρ n)) (Qbound n) := by
      show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((Rartanh_R ρ n + 1 : Nat) : Int)
      rw [Int.one_mul, Int.one_mul]; exact_mod_cast (show n + 1 ≤ Rartanh_R ρ n + 1 by omega)
    have hRb : Qle (Qbound (Rartanh_R ρ' n)) (Qbound n) := by
      show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((Rartanh_R ρ' n + 1 : Nat) : Int)
      rw [Int.one_mul, Int.one_mul]; exact_mod_cast (show n + 1 ≤ Rartanh_R ρ' n + 1 by omega)
    refine Qle_trans (Qmul_den_pos Nat.one_pos (add_den_pos (Qbound_den_pos n) (Qbound_den_pos n)))
      (Qmul_le_mul_left (Int.ofNat_nonneg K) (Qadd_le_add hRa hRb)) ?_
    apply Qeq_le
    show Qeq (mul (⟨(K : Int), 1⟩ : Q) (add (Qbound n) (Qbound n))) (⟨2 * (K : Int), n + 1⟩ : Q)
    simp only [Qeq, mul, add, Qbound]; push_cast; ring_uor
  have hP0d : 0 < (artSum (t.seq (Rartanh_R ρ n)) (Rartanh_R ρ n)).den := artSum_den_pos (htd _) _
  have hP1d : 0 < (artSum (t.seq (Rartanh_R ρ n)) (max (Rartanh_R ρ n) (Rartanh_R ρ' n))).den :=
    artSum_den_pos (htd _) _
  have hP2d : 0 < (artSum (t.seq (Rartanh_R ρ' n)) (max (Rartanh_R ρ n) (Rartanh_R ρ' n))).den :=
    artSum_den_pos (htd _) _
  have hP3d : 0 < (artSum (t.seq (Rartanh_R ρ' n)) (Rartanh_R ρ' n)).den := artSum_den_pos (htd _) _
  have hpc : Qle (Qabs (Qsub (artSum (t.seq (Rartanh_R ρ n)) (max (Rartanh_R ρ n) (Rartanh_R ρ' n)))
        (artSum (t.seq (Rartanh_R ρ' n)) (Rartanh_R ρ' n))))
      (add (⟨2 * (K : Int), n + 1⟩ : Q) (⟨(K : Int) * (τ.den : Int), n + 1⟩ : Q)) :=
    Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hP1d hP2d))
        (Qabs_den_pos (Qsub_den_pos hP2d hP3d)))
      (Qabs_sub_triangle hP1d hP2d hP3d) (Qadd_le_add hT2 hT3)
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hP0d hP1d))
      (Qabs_den_pos (Qsub_den_pos hP1d hP3d)))
    (Qabs_sub_triangle hP0d hP1d hP3d) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)))
    (Qadd_le_add hT1 hpc) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n))
    (Qadd_le_add (Qle_refl _) (Qeq_le (Qadd_same_den_loc (2 * (K : Int)) ((K : Int) * (τ.den : Int)) (n + 1)))) ?_
  refine Qle_trans (Nat.succ_pos n)
    (Qeq_le (Qadd_same_den_loc ((K : Int) * (τ.den : Int)) (2 * (K : Int) + (K : Int) * (τ.den : Int)) (n + 1))) ?_
  apply Qeq_le; simp only [Qeq]; push_cast; ring_uor

set_option maxHeartbeats 1600000 in
/-- **General-radius `Rlog` congruence**: `x ≈ y` (both presented at modulus `M`) ⟹ `Rlog x M ≈ Rlog y M`
    for **any** `M ≥ 1` (no small-radius cap), with `K` the even-sum bound for `ρ_M` (`K = ρ_M.den`
    works). Generalizes `Rlog_congr` via `Rartanh_congr_gen`. -/
theorem Rlog_congr_gen (x y : Real) (M : Q) (K : Nat) (hMd : 0 < M.den) (hMge : Qle (⟨1, 1⟩ : Q) M)
    (hxpos : ∀ n, 0 < (x.seq n).num) (hxhi : ∀ n, Qle (x.seq n) M)
    (hxlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) M))
    (hypos : ∀ n, 0 < (y.seq n).num) (hyhi : ∀ n, Qle (y.seq n) M)
    (hylo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (y.seq n) M))
    (hKF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨M.num - (M.den : Int), M.num.toNat + M.den⟩
        ⟨M.num - (M.den : Int), M.num.toNat + M.den⟩))))
    (hKr : K ≤ 2 * ((M.num.toNat + M.den) * (M.num.toNat + M.den) + 4 * (M.num.toNat + M.den)))
    (heq : Req x y) :
    Req (Rlog x M hMd hMge hxpos hxhi hxlo) (Rlog y M hMd hMge hypos hyhi hylo) := by
  obtain ⟨hMn, hM1, hρ0, hρd, hρlt, hρ1⟩ := Rlog_radius_facts M hMd hMge
  have hden_x : ∀ n, 0 < (Rlog_seq x n).den := fun n => Qmul_den_pos
    (Qsub_den_pos (x.den_pos _) Nat.one_pos) (Qinv_den_pos (by
      have := hxpos (Rlog_R n); have h := Int.ofNat_nonneg (x.seq (Rlog_R n)).den
      show 0 < (x.seq (Rlog_R n)).num * 1 + 1 * ((x.seq (Rlog_R n)).den : Int); omega))
  have hden_y : ∀ n, 0 < (Rlog_seq y n).den := fun n => Qmul_den_pos
    (Qsub_den_pos (y.den_pos _) Nat.one_pos) (Qinv_den_pos (by
      have := hypos (Rlog_R n); have h := Int.ofNat_nonneg (y.seq (Rlog_R n)).den
      show 0 < (y.seq (Rlog_R n)).num * 1 + 1 * ((y.seq (Rlog_R n)).den : Int); omega))
  have hbtρx := Rlog_tbound x M hMd hMn hM1 hxhi hxlo hxpos
  have hbtρy := Rlog_tbound y M hMd hMn hM1 hyhi hylo hypos
  rw [Rlog_eq_Rmul x M hMd hMge hxpos hxhi hxlo hden_x hρ0 hρd hρlt (fun n => hbtρx (Rlog_R n)),
    Rlog_eq_Rmul y M hMd hMge hypos hyhi hylo hden_y hρ0 hρd hρlt (fun n => hbtρy (Rlog_R n))]
  refine Rmul_congr (Req_refl _) ?_
  have hWeq : Req (⟨Rlog_seq x, Rlog_regular x hxpos, hden_x⟩ : Real)
      ⟨Rlog_seq y, Rlog_regular y hypos, hden_y⟩ := by
    refine Req_of_lin_bound (C := 4) ?_
    intro n
    show Qle (Qabs (Qsub (tmap (x.seq (Rlog_R n))) (tmap (y.seq (Rlog_R n))))) (⟨(4 : Int), n + 1⟩ : Q)
    have ha1 : 0 < (add (x.seq (Rlog_R n)) ⟨1, 1⟩).num := by
      have := hxpos (Rlog_R n); have h := Int.ofNat_nonneg (x.seq (Rlog_R n)).den
      show 0 < (x.seq (Rlog_R n)).num * 1 + 1 * ((x.seq (Rlog_R n)).den : Int); omega
    have hb1 : 0 < (add (y.seq (Rlog_R n)) ⟨1, 1⟩).num := by
      have := hypos (Rlog_R n); have h := Int.ofNat_nonneg (y.seq (Rlog_R n)).den
      show 0 < (y.seq (Rlog_R n)).num * 1 + 1 * ((y.seq (Rlog_R n)).den : Int); omega
    have hage : Qle (⟨1, 1⟩ : Q) (add (x.seq (Rlog_R n)) ⟨1, 1⟩) := by
      have := hxpos (Rlog_R n); have h := Int.ofNat_nonneg (x.seq (Rlog_R n)).den
      simp only [Qle, add]; push_cast; omega
    have hbge : Qle (⟨1, 1⟩ : Q) (add (y.seq (Rlog_R n)) ⟨1, 1⟩) := by
      have := hypos (Rlog_R n); have h := Int.ofNat_nonneg (y.seq (Rlog_R n)).den
      simp only [Qle, add]; push_cast; omega
    refine Qle_trans (Qmul_den_pos (by decide) (Qabs_den_pos (Qsub_den_pos (x.den_pos _) (y.den_pos _))))
      (tmap_lip (x.seq (Rlog_R n)) (y.seq (Rlog_R n)) (x.den_pos _) (y.den_pos _) ha1 hb1 hage hbge) ?_
    refine Qle_trans (Qmul_den_pos (by decide) (Nat.succ_pos _))
      (Qmul_le_mul_left (by decide) (heq (Rlog_R n))) ?_
    show Qle (mul (⟨2, 1⟩ : Q) ⟨2, Rlog_R n + 1⟩) (⟨(4 : Int), n + 1⟩ : Q)
    simp only [Qle, mul, Rlog_R]; push_cast; omega
  exact Rartanh_congr_gen _ _ _ K hρ0 hρd hρlt hKF hKr
    (fun n => hbtρx (Rlog_R n)) (fun n => hbtρy (Rlog_R n)) hWeq

set_option maxHeartbeats 1600000 in
/-- **General-radius `RlogPos → Rlog` bridge**: `RlogPos x k = Rlog x B` for `x ∈ [1/B, B]` at **any**
    `B ≥ 1` (no small-radius cap), with `K` the even-sum bound for `ρ_B` (`K = ρ_B.den` works).
    Generalizes `RlogPos_eq_Rlog` via `Rartanh_radius_indep_gen` (`Mx→B`) + `Rlog_congr_gen`
    (`reindex x ≈ x`). -/
theorem RlogPos_eq_Rlog_gen (x : Real) (k : Nat) (hk : Qlt (Qbound k) (x.seq k))
    (B : Q) (K : Nat) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxposB : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B)
    (hxloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) B))
    (hKF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩))))
    (hKr : K ≤ 2 * ((B.num.toNat + B.den) * (B.num.toNat + B.den) + 4 * (B.num.toNat + B.den))) :
    Req (RlogPos x k hk) (Rlog x B hBd hBge hxposB hxhiB hxloB) := by
  have hLn := RL_num_pos hk
  have hLd := @RL_den_pos x k
  have hLinvn := Qinv_num_pos hLd
  have hLinvd := Qinv_den_pos hLn
  have hAd : 0 < (add (Qabs (x.seq 0)) ⟨2, 1⟩).den :=
    add_den_pos (Qabs_den_pos (x.den_pos 0)) Nat.one_pos
  have hAn : 0 ≤ (add (Qabs (x.seq 0)) ⟨2, 1⟩).num := by
    simp only [add, Qabs]
    have h1 := Int.ofNat_nonneg (x.seq 0).num.natAbs
    have h2 := Int.ofNat_nonneg (x.seq 0).den; push_cast; omega
  have h1A : Qle (⟨1, 1⟩ : Q) (add (Qabs (x.seq 0)) ⟨2, 1⟩) := by
    simp only [Qle, add, Qabs]
    have h1 := Int.ofNat_nonneg (x.seq 0).num.natAbs
    have h2 := Int.ofNat_nonneg (x.seq 0).den; push_cast; omega
  have hMxd : 0 < (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))).den := add_den_pos hAd hLinvd
  have hMxge : Qle (⟨1, 1⟩ : Q) (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))) :=
    Qle_trans hAd h1A (Qle_add_right_nonneg (Int.le_of_lt hLinvn))
  have hposrix : ∀ n, 0 < ((⟨fun n => x.seq (RlogPosR x k n),
      reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩ : Real).seq n).num :=
    fun n => Rinv_num_pos hk (RlogPosR_tail x k n)
  have hhirix : ∀ n, Qle ((⟨fun n => x.seq (RlogPosR x k n),
      reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩ : Real).seq n)
      (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))) := by
    intro n
    exact Qle_trans (add_den_pos (x.den_pos 0) Nat.one_pos)
      (Rlog_ub x (RlogPosR x k n))
      (Qle_trans hAd (Qadd_le_add (Qle_self_Qabs (x.seq 0)) (Qle_refl _))
        (Qle_add_right_nonneg (Int.le_of_lt hLinvn)))
  have hlorix : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((⟨fun n => x.seq (RlogPosR x k n),
      reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩ : Real).seq n)
      (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k)))) := by
    intro n
    have hqn : 0 < (x.seq (RlogPosR x k n)).num := Rinv_num_pos hk (RlogPosR_tail x k n)
    have hqd : 0 < (x.seq (RlogPosR x k n)).den := x.den_pos _
    have hqL : Qle (RL x k) (x.seq (RlogPosR x k n)) := Rinv_lb hk (RlogPosR_tail x k n)
    exact Qle_trans (Qmul_den_pos hLd hLinvd)
      (Qeq_le (Qeq_symm (Qmul_Qinv hLn)))
      (Qle_trans (Qmul_den_pos hqd hLinvd)
        (Qmul_le_mul hLd hqd hLinvd (Int.le_of_lt hLn) (Int.le_of_lt hLinvn) hqL (Qle_refl _))
        (Qmul_le_mul_left (Int.le_of_lt hqn) (Qle_add_left_nonneg hAn)))
  rw [RlogPos_unfold x k hk hMxd hMxge hposrix hhirix hlorix]
  have hhirixB : ∀ n, Qle ((⟨fun n => x.seq (RlogPosR x k n),
      reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩ : Real).seq n) B :=
    fun n => hxhiB (RlogPosR x k n)
  have hlorixB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((⟨fun n => x.seq (RlogPosR x k n),
      reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩ : Real).seq n) B) :=
    fun n => hxloB (RlogPosR x k n)
  refine Req_trans ?_
    (Rlog_congr_gen _ x B K hBd hBge hposrix hhirixB hlorixB hxposB hxhiB hxloB hKF hKr
      (reindex_Req x (RlogPosR x k) (RlogPosR_self x k)))
  obtain ⟨hMxn, hMx1, hρMx0, hρMxd, hρMxlt, hρMx1⟩ :=
    Rlog_radius_facts (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))) hMxd hMxge
  obtain ⟨hBn, hB1, hρB0, hρBd, hρBlt, hρB1⟩ := Rlog_radius_facts B hBd hBge
  have hden_rix : ∀ n, 0 < (Rlog_seq ⟨fun n => x.seq (RlogPosR x k n),
      reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩ n).den := fun n =>
    Qmul_den_pos (Qsub_den_pos (x.den_pos _) Nat.one_pos) (Qinv_den_pos (by
      have hpp : 0 < (x.seq (RlogPosR x k (Rlog_R n))).num := hposrix (Rlog_R n)
      have h := Int.ofNat_nonneg (x.seq (RlogPosR x k (Rlog_R n))).den
      show 0 < (x.seq (RlogPosR x k (Rlog_R n))).num * 1 + 1 * ((x.seq (RlogPosR x k (Rlog_R n))).den : Int)
      omega))
  have hbtMx := Rlog_tbound _ (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))) hMxd hMxn hMx1
    hhirix hlorix hposrix
  have hbtB := Rlog_tbound _ B hBd hBn hB1 hhirixB hlorixB hposrix
  rw [Rlog_eq_Rmul _ (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))) hMxd hMxge hposrix hhirix hlorix
        hden_rix hρMx0 hρMxd hρMxlt (fun n => hbtMx (Rlog_R n)),
    Rlog_eq_Rmul _ B hBd hBge hposrix hhirixB hlorixB hden_rix hρB0 hρBd hρBlt (fun n => hbtB (Rlog_R n))]
  refine Rmul_congr (Req_refl _) ?_
  exact Rartanh_radius_indep_gen ⟨Rlog_seq ⟨fun n => x.seq (RlogPosR x k n),
      reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩,
      Rlog_regular _ hposrix, hden_rix⟩ _ _
    ⟨(add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))).num
        - ((add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))).den : Int),
      (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))).num.toNat
        + (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))).den⟩
    ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
    ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ K
    hρMxd hρBd hρB0 hρBd hρBlt hKF (fun n => hbtB (Rlog_R n)) (fun _ => rfl) (fun _ => rfl)

/-- **General-radius `RlogPos` congruence**: `x ≈ y` (both in `[1/B,B]`) ⟹ `RlogPos x ≈ RlogPos y` at
    any `B ≥ 1`. Generalizes `RlogPos_congr` via the general-radius bridge + `Rlog_congr_gen`. -/
theorem RlogPos_congr_gen (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
    (ky : Nat) (hy : Qlt (Qbound ky) (y.seq ky))
    (B : Q) (K : Nat) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxposB : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B)
    (hxloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) B))
    (hyposB : ∀ n, 0 < (y.seq n).num) (hyhiB : ∀ n, Qle (y.seq n) B)
    (hyloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (y.seq n) B))
    (hKF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩))))
    (hKr : K ≤ 2 * ((B.num.toNat + B.den) * (B.num.toNat + B.den) + 4 * (B.num.toNat + B.den)))
    (heq : Req x y) :
    Req (RlogPos x kx hx) (RlogPos y ky hy) :=
  Req_trans (RlogPos_eq_Rlog_gen x kx hx B K hBd hBge hxposB hxhiB hxloB hKF hKr)
    (Req_trans (Rlog_congr_gen x y B K hBd hBge hxposB hxhiB hxloB hyposB hyhiB hyloB hKF hKr heq)
      (Req_symm (RlogPos_eq_Rlog_gen y ky hy B K hBd hBge hyposB hyhiB hyloB hKF hKr)))

/-- **`|c| < 1` from the radius** (general): `pc² ≤ qc²` for `|c| ≤ ρ` with `ρ < 1` (`ρ.num.toNat < ρ.den`).
    The general-radius analog of `wval_csq_le` (no `ρ²≤1/2`). -/
theorem wval_csq_le_gen (ρ c : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num) (hcd : 0 < c.den)
    (hc : Qle (Qabs c) ρ) (hρlt : ρ.num.toNat < ρ.den) :
    c.num * c.num ≤ (c.den : Int) * c.den := by
  simp only [Qle, Qabs] at hc
  have hrd : (0 : Int) < ρ.den := by exact_mod_cast hρd
  have hqc : (0 : Int) < c.den := by exact_mod_cast hcd
  have hρlt1 : ρ.num ≤ (ρ.den : Int) := by omega
  have habs : (c.num.natAbs : Int) * ρ.den ≤ ρ.num * c.den := hc
  have hpcle : (c.num.natAbs : Int) ≤ (c.den : Int) := by
    have e : ρ.num * (c.den : Int) ≤ (c.den : Int) * ρ.den := by
      have e2 : (ρ.den : Int) * c.den = (c.den : Int) * ρ.den := by ring_uor
      rw [← e2]; exact Int.mul_le_mul_of_nonneg_right hρlt1 (Int.le_of_lt hqc)
    have h1 : (c.num.natAbs : Int) * ρ.den ≤ (c.den : Int) * ρ.den := Int.le_trans habs e
    exact Int.le_of_mul_le_mul_right h1 hrd
  have hpc2 : c.num * c.num = (c.num.natAbs : Int) * c.num.natAbs := (Int.natAbs_mul_self' c.num).symm
  rw [hpc2]
  exact Int.mul_le_mul hpcle hpcle (Int.ofNat_nonneg _) (Int.le_of_lt hqc)

/-- **The denominator bound from the radius** (general): for `|a|, |c| ≤ ρ < 1`, the shifted denominator
    clears with factor `ρ.den`: `qa·qc ≤ ρ.den·(qa·qc + pa·pc)` (since `1+ac ≥ 1−ρ² ≥ 1/ρ.den`). The
    general-radius analog of `wval_halfbound` (`K = ρ.den` replaces the `≤2` of `ρ²≤1/2`). -/
theorem wval_halfbound_gen (ρ a c : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num)
    (had : 0 < a.den) (hcd : 0 < c.den)
    (ha : Qle (Qabs a) ρ) (hc : Qle (Qabs c) ρ) (hρlt : ρ.num.toNat < ρ.den) :
    (a.den : Int) * c.den ≤ (ρ.den : Int) * ((a.den : Int) * c.den + a.num * c.num) := by
  simp only [Qle, Qabs] at ha hc
  have hrd : (0 : Int) < ρ.den := by exact_mod_cast hρd
  have hqa : (0 : Int) < a.den := by exact_mod_cast had
  have hqc : (0 : Int) < c.den := by exact_mod_cast hcd
  have hplt : ρ.num < (ρ.den : Int) := by omega
  have hqac : (0 : Int) < (a.den : Int) * c.den := Int.mul_pos hqa hqc
  -- d²·|pa·pc| ≤ p²·(qa·qc)
  have hppd2 : ((a.num * c.num).natAbs : Int) * ((ρ.den : Int) * ρ.den)
      ≤ (ρ.num * ρ.num) * ((a.den : Int) * c.den) := by
    have hm := Int.mul_le_mul ha hc (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.le_of_lt hrd))
      (Int.mul_nonneg hρ0 (Int.le_of_lt hqa))
    have eL : ((a.num.natAbs : Int) * ρ.den) * ((c.num.natAbs : Int) * ρ.den)
        = ((a.num * c.num).natAbs : Int) * ((ρ.den : Int) * ρ.den) := by
      rw [Int.natAbs_mul]; push_cast; ring_uor
    have eR : (ρ.num * (a.den : Int)) * (ρ.num * c.den)
        = (ρ.num * ρ.num) * ((a.den : Int) * c.den) := by ring_uor
    rw [eL, eR] at hm; exact hm
  -- p² ≤ d² − d
  have hdp : ρ.num * ρ.num ≤ (ρ.den : Int) * ρ.den - (ρ.den : Int) := by
    have h1 : ρ.num * ρ.num ≤ ((ρ.den : Int) - 1) * ((ρ.den : Int) - 1) :=
      Int.mul_le_mul (by omega) (by omega) hρ0 (by omega)
    have h2 : ((ρ.den : Int) - 1) * ((ρ.den : Int) - 1) = (ρ.den : Int) * ρ.den - 2 * ρ.den + 1 := by
      ring_uor
    omega
  -- −|pa pc| ≤ pa pc
  have hpc_ge : -(((a.num * c.num).natAbs : Int)) ≤ a.num * c.num := by
    rcases Int.natAbs_eq (a.num * c.num) with h | h <;> omega
  -- prove d-multiplied goal then divide
  have hmain : (ρ.den : Int) * ((a.den : Int) * c.den)
      ≤ (ρ.den : Int) * ((ρ.den : Int) * ((a.den : Int) * c.den + a.num * c.num)) := by
    have hD2nn : (0 : Int) ≤ (ρ.den : Int) * ρ.den := Int.le_of_lt (Int.mul_pos hrd hrd)
    have hs1 : ((ρ.den : Int) * ρ.den) * (-(((a.num * c.num).natAbs : Int)))
        ≤ ((ρ.den : Int) * ρ.den) * (a.num * c.num) := Int.mul_le_mul_of_nonneg_left hpc_ge hD2nn
    have hs2 : ((a.num * c.num).natAbs : Int) * ((ρ.den : Int) * ρ.den)
        ≤ ((ρ.den : Int) * ρ.den - (ρ.den : Int)) * ((a.den : Int) * c.den) :=
      Int.le_trans hppd2 (Int.mul_le_mul_of_nonneg_right hdp (Int.le_of_lt hqac))
    have e1 : ((ρ.den : Int) * ρ.den) * (-(((a.num * c.num).natAbs : Int)))
        = -(((a.num * c.num).natAbs : Int) * ((ρ.den : Int) * ρ.den)) := by ring_uor
    have key : (ρ.den : Int) * ((ρ.den : Int) * ((a.den : Int) * c.den + a.num * c.num))
        - (ρ.den : Int) * ((a.den : Int) * c.den)
        = ((ρ.den : Int) * ρ.den) * (a.num * c.num)
          + ((ρ.den : Int) * ρ.den - (ρ.den : Int)) * ((a.den : Int) * c.den) := by ring_uor
    omega
  exact Int.le_of_mul_le_mul_left hmain hrd

/-- General `K²` denominator estimate (the `wval_lip1_den` analog): `(qc²−pc²)(qa·qb) ≤ K²·(D_ac·D_bc)`
    from the two `K`-half-bounds. -/
private theorem wval_lip1_den_gen (qa pa qb pb qc pc K : Int)
    (hqa : 0 < qa) (hqb : 0 < qb) (hqc : 0 < qc)
    (hDac : qa * qc ≤ K * (qa * qc + pa * pc)) (hDbc : qb * qc ≤ K * (qb * qc + pb * pc)) :
    (qc * qc - pc * pc) * (qa * qb) ≤ (K * K) * ((qa * qc + pa * pc) * (qb * qc + pb * pc)) := by
  have hacp : 0 < qa * qc := Int.mul_pos hqa hqc
  have hbcp : 0 < qb * qc := Int.mul_pos hqb hqc
  have hb_nn : 0 ≤ K * (qa * qc + pa * pc) := by omega
  have hprod : (qa * qc) * (qb * qc) ≤ (K * (qa * qc + pa * pc)) * (K * (qb * qc + pb * pc)) :=
    Int.mul_le_mul hDac hDbc (Int.le_of_lt hbcp) hb_nn
  have hpc2 : (0 : Int) ≤ pc * pc := by rw [← Int.natAbs_mul_self]; exact Int.ofNat_nonneg _
  have hP : (0 : Int) ≤ (pc * pc) * (qa * qb) :=
    Int.mul_nonneg hpc2 (Int.le_of_lt (Int.mul_pos hqa hqb))
  have key1 : (qc * qc) * (qa * qb) - (qc * qc - pc * pc) * (qa * qb) = (pc * pc) * (qa * qb) := by ring_uor
  have key2 : (qc * qc) * (qa * qb) = (qa * qc) * (qb * qc) := by ring_uor
  have key3 : (K * (qa * qc + pa * pc)) * (K * (qb * qc + pb * pc))
      = (K * K) * ((qa * qc + pa * pc) * (qb * qc + pb * pc)) := by ring_uor
  omega

/-- **`1 + ac > 0` from the radius** (general): `0 < qa·qc + pa·pc` for `|a|, |c| ≤ ρ < 1`. The
    general-radius analog of `wval_inner_pos` (no `ρ²≤1/2`): `|pa·pc| ≤ (qa−1)(qc−1)` so
    `qa·qc + pa·pc ≥ qa + qc − 1 ≥ 1`. -/
theorem wval_inner_pos_gen (ρ a c : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num)
    (had : 0 < a.den) (hcd : 0 < c.den) (ha : Qle (Qabs a) ρ) (hc : Qle (Qabs c) ρ)
    (hρlt : ρ.num.toNat < ρ.den) :
    0 < (a.den : Int) * c.den + a.num * c.num := by
  simp only [Qle, Qabs] at ha hc
  have hrd : (0 : Int) < ρ.den := by exact_mod_cast hρd
  have hqa : (0 : Int) < a.den := by exact_mod_cast had
  have hqc : (0 : Int) < c.den := by exact_mod_cast hcd
  have hplt : ρ.num < (ρ.den : Int) := by omega
  have hpa : (a.num.natAbs : Int) < a.den := by
    have h1 : (a.num.natAbs : Int) * ρ.den ≤ ρ.num * a.den := ha
    have h2 : ρ.num * (a.den : Int) ≤ ((ρ.den : Int) - 1) * a.den :=
      Int.mul_le_mul_of_nonneg_right (by omega) (Int.le_of_lt hqa)
    have h3 : (a.num.natAbs : Int) * ρ.den < a.den * ρ.den := by
      have e : ((ρ.den : Int) - 1) * a.den < a.den * ρ.den := by
        have := Int.mul_pos hqa hrd; have e2 : ((ρ.den : Int) - 1) * a.den = a.den * ρ.den - a.den := by ring_uor
        omega
      omega
    exact Int.lt_of_mul_lt_mul_right h3 (Int.le_of_lt hrd)
  have hpc : (c.num.natAbs : Int) < c.den := by
    have h1 : (c.num.natAbs : Int) * ρ.den ≤ ρ.num * c.den := hc
    have h2 : ρ.num * (c.den : Int) ≤ ((ρ.den : Int) - 1) * c.den :=
      Int.mul_le_mul_of_nonneg_right (by omega) (Int.le_of_lt hqc)
    have h3 : (c.num.natAbs : Int) * ρ.den < c.den * ρ.den := by
      have e : ((ρ.den : Int) - 1) * c.den < c.den * ρ.den := by
        have := Int.mul_pos hqc hrd; have e2 : ((ρ.den : Int) - 1) * c.den = c.den * ρ.den - c.den := by ring_uor
        omega
      omega
    exact Int.lt_of_mul_lt_mul_right h3 (Int.le_of_lt hrd)
  have habs : ((a.num * c.num).natAbs : Int) ≤ ((a.den : Int) - 1) * ((c.den : Int) - 1) := by
    rw [Int.natAbs_mul]; push_cast
    exact Int.mul_le_mul (by omega) (by omega) (Int.ofNat_nonneg _) (by omega)
  have hge : -(((a.den : Int) - 1) * ((c.den : Int) - 1)) ≤ a.num * c.num := by
    rcases Int.natAbs_eq (a.num * c.num) with h | h <;> omega
  have hexp : (a.den : Int) * c.den - ((a.den : Int) - 1) * ((c.den : Int) - 1)
      = (a.den : Int) + c.den - 1 := by ring_uor
  omega

/-- **General-radius binary Lipschitz, first argument**: `|wvalR a c − wvalR b c| ≤ ρ.den²·|a − b|` for
    `|a|,|b|,|c| ≤ ρ < 1`. The general analog of `wval_lip1` (constant `ρ.den²` replaces `4`), via
    `wval_halfbound_gen` (`K = ρ.den`) + `wval_lip1_den_gen` (`K²`). -/
theorem wval_lip1_gen (ρ a b c : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num)
    (had : 0 < a.den) (hbd : 0 < b.den) (hcd : 0 < c.den)
    (ha : Qle (Qabs a) ρ) (hb : Qle (Qabs b) ρ) (hc : Qle (Qabs c) ρ)
    (hρlt : ρ.num.toNat < ρ.den) :
    Qle (Qabs (Qsub (wvalR a c) (wvalR b c))) (mul (⟨(ρ.den : Int) * ρ.den, 1⟩ : Q) (Qabs (Qsub a b))) := by
  have hqa : (0 : Int) < a.den := by exact_mod_cast had
  have hqb : (0 : Int) < b.den := by exact_mod_cast hbd
  have hqc : (0 : Int) < c.den := by exact_mod_cast hcd
  have hHac := wval_halfbound_gen ρ a c hρd hρ0 had hcd ha hc hρlt
  have hHbc := wval_halfbound_gen ρ b c hρd hρ0 hbd hcd hb hc hρlt
  have hac : 0 < (a.den : Int) * c.den + a.num * c.num := wval_inner_pos_gen ρ a c hρd hρ0 had hcd ha hc hρlt
  have hbc : 0 < (b.den : Int) * c.den + b.num * c.num := wval_inner_pos_gen ρ b c hρd hρ0 hbd hcd hb hc hρlt
  have hND := wvalR_argdiff1 a b c hac hbc
  have hcsq := wval_csq_le_gen ρ c hρd hρ0 hcd hc hρlt
  have hden := wval_lip1_den_gen (a.den : Int) a.num (b.den : Int) b.num (c.den : Int) c.num (ρ.den : Int)
    hqa hqb hqc hHac hHbc
  have hqcpc : (0 : Int) ≤ (c.den : Int) * c.den - c.num * c.num := by omega
  have hn : (0 : Int) ≤ ((Qsub a b).num.natAbs : Int) := Int.ofNat_nonneg _
  have hSabs : ((Qsub (wvalR a c) (wvalR b c)).num.natAbs : Int)
      = ((Qsub a b).num.natAbs : Int) * ((c.den : Int) * c.den - c.num * c.num) := by
    rw [hND, Int.natAbs_mul]; push_cast; rw [Int.natAbs_of_nonneg hqcpc]
  have hSden : ((Qsub (wvalR a c) (wvalR b c)).den : Int)
      = ((a.den : Int) * c.den + a.num * c.num) * ((b.den : Int) * c.den + b.num * c.num) := by
    have e : (Qsub (wvalR a c) (wvalR b c)).den = (wvalR a c).den * (wvalR b c).den := rfl
    rw [e, Int.natCast_mul, wvalR_den, wvalR_den,
      Int.toNat_of_nonneg (Int.le_of_lt hac), Int.toNat_of_nonneg (Int.le_of_lt hbc)]
  have hTd : (Qsub a b).den = a.den * b.den := rfl
  simp only [Qle, Qabs, mul]
  rw [hSabs, hSden, hTd]
  push_cast
  have eL : ((Qsub a b).num.natAbs : Int) * ((c.den : Int) * c.den - c.num * c.num)
        * (1 * ((a.den : Int) * b.den))
      = ((Qsub a b).num.natAbs : Int)
          * (((c.den : Int) * c.den - c.num * c.num) * ((a.den : Int) * b.den)) := by ring_uor
  have eR : (ρ.den : Int) * ρ.den * ((Qsub a b).num.natAbs : Int)
        * (((a.den : Int) * c.den + a.num * c.num) * ((b.den : Int) * c.den + b.num * c.num))
      = ((Qsub a b).num.natAbs : Int)
          * (((ρ.den : Int) * ρ.den) * (((a.den : Int) * c.den + a.num * c.num)
            * ((b.den : Int) * c.den + b.num * c.num))) := by ring_uor
  rw [eL, eR]
  exact Int.mul_le_mul_of_nonneg_left hden hn

/-- **General-radius binary Lipschitz, second argument** (via `wvalR_comm`). -/
theorem wval_lip2_gen (ρ a c d : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num)
    (had : 0 < a.den) (hcd : 0 < c.den) (hdd : 0 < d.den)
    (ha : Qle (Qabs a) ρ) (hc : Qle (Qabs c) ρ) (hd : Qle (Qabs d) ρ)
    (hρlt : ρ.num.toNat < ρ.den) :
    Qle (Qabs (Qsub (wvalR a c) (wvalR a d))) (mul (⟨(ρ.den : Int) * ρ.den, 1⟩ : Q) (Qabs (Qsub c d))) := by
  rw [wvalR_comm a c, wvalR_comm a d]
  exact wval_lip1_gen ρ c d a hρd hρ0 hcd hdd had hc hd ha hρlt

set_option maxHeartbeats 1200000 in
/-- **General-radius `artSum` arg-variation via `wvalR`**: `|artSum(wvalR a b) M − artSum(wvalR a' b') M|
    ≤ Kσ·ρ.den²·(|a−a'| + |b−b'|)` for args `≤ ρ < 1` and `wvalR`s `≤ σ < 1` (`Kσ` the σ even-sum
    bound). General analog of `artSum_wval_argdiff` (constant `Kσ·ρ.den²` replaces `8`). -/
theorem artSum_wval_argdiff_gen (ρ σ a b a' b' : Q) (Kσ : Nat) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num)
    (hρlt : ρ.num.toNat < ρ.den) (hσ0 : 0 ≤ σ.num) (hσd : 0 < σ.den)
    (hKσF : Qle (⟨1, 1⟩ : Q) (mul (⟨(Kσ : Int), 1⟩ : Q) (Qsub ⟨1, 1⟩ (mul σ σ))))
    (had : 0 < a.den) (hbd : 0 < b.den) (ha'd : 0 < a'.den) (hb'd : 0 < b'.den)
    (ha : Qle (Qabs a) ρ) (hb : Qle (Qabs b) ρ) (ha' : Qle (Qabs a') ρ) (hb' : Qle (Qabs b') ρ)
    (hwσ : Qle (Qabs (wvalR a b)) σ) (hw'σ : Qle (Qabs (wvalR a' b')) σ) (M : Nat) :
    Qle (Qabs (Qsub (artSum (wvalR a b) M) (artSum (wvalR a' b') M)))
        (mul (⟨(Kσ : Int) * ((ρ.den : Int) * ρ.den), 1⟩ : Q) (add (Qabs (Qsub a a')) (Qabs (Qsub b b')))) := by
  have hwd : 0 < (wvalR a b).den := wvalR_den_pos a b (wval_inner_pos_gen ρ a b hρd hρ0 had hbd ha hb hρlt)
  have hw'd : 0 < (wvalR a' b').den :=
    wvalR_den_pos a' b' (wval_inner_pos_gen ρ a' b' hρd hρ0 ha'd hb'd ha' hb' hρlt)
  have hw2d : 0 < (wvalR a' b).den :=
    wvalR_den_pos a' b (wval_inner_pos_gen ρ a' b hρd hρ0 ha'd hbd ha' hb hρlt)
  refine Qle_trans (Qmul_den_pos (geoEvenSum_den_pos hσd M) (Qabs_den_pos (Qsub_den_pos hwd hw'd)))
    (artSum_Lip_le hwd hw'd hσd hwσ hw'σ M) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos hwd hw'd)))
    (Qmul_le_mul_right (Qabs_num_nonneg _)
      (geoEvenSum_le_gen hσ0 hσd Nat.one_pos (Int.ofNat_nonneg Kσ) hKσF M)) ?_
  have hleg1 : Qle (Qabs (Qsub (wvalR a b) (wvalR a' b)))
      (mul (⟨(ρ.den : Int) * ρ.den, 1⟩ : Q) (Qabs (Qsub a a'))) :=
    wval_lip1_gen ρ a a' b hρd hρ0 had ha'd hbd ha ha' hb hρlt
  have hleg2 : Qle (Qabs (Qsub (wvalR a' b) (wvalR a' b')))
      (mul (⟨(ρ.den : Int) * ρ.den, 1⟩ : Q) (Qabs (Qsub b b'))) :=
    wval_lip2_gen ρ a' b b' hρd hρ0 ha'd hbd hb'd ha' hb hb' hρlt
  refine Qle_trans (Qmul_den_pos Nat.one_pos (add_den_pos
      (Qabs_den_pos (Qsub_den_pos hwd hw2d)) (Qabs_den_pos (Qsub_den_pos hw2d hw'd))))
    (Qmul_le_mul_left (Int.ofNat_nonneg Kσ) (Qabs_sub_triangle hwd hw2d hw'd)) ?_
  refine Qle_trans (Qmul_den_pos Nat.one_pos (add_den_pos
      (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos had ha'd)))
      (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos hbd hb'd)))))
    (Qmul_le_mul_left (Int.ofNat_nonneg Kσ) (Qadd_le_add hleg1 hleg2)) ?_
  apply Qeq_le
  show Qeq (mul (⟨(Kσ : Int), 1⟩ : Q) (add (mul (⟨(ρ.den : Int) * ρ.den, 1⟩ : Q) (Qabs (Qsub a a')))
      (mul (⟨(ρ.den : Int) * ρ.den, 1⟩ : Q) (Qabs (Qsub b b')))))
    (mul (⟨(Kσ : Int) * ((ρ.den : Int) * ρ.den), 1⟩ : Q) (add (Qabs (Qsub a a')) (Qabs (Qsub b b'))))
  simp only [Qeq, mul, add]; push_cast; ring_uor

set_option maxHeartbeats 1600000 in
/-- **★ general-radius real artanh addition diagonal** `artanh s + artanh t = artanh(wvalReal s t)` for
    signed real `s, t` (`|s.seq|,|t.seq| < 1`) at **any** radius `σ < 1` (no `σ²≤1/2`). The general
    analog of `Rartanh_add_real_via_signed`: the combination leg `RartanhConst_add_wvalR_rho` is already
    radius-agnostic; the arg-variation leg uses `artSum_wval_argdiff_gen` (constant `Kσ·σ.den²`). -/
theorem Rartanh_add_real_via_gen (s t X1 X2 Y : Real) (σ : Q) (Kσ : Nat) (R_Y : Nat → Nat)
    (hσ0 : 0 ≤ σ.num) (hσd : 0 < σ.den) (hσlt : σ.num.toNat < σ.den)
    (hKσF : Qle (⟨1, 1⟩ : Q) (mul (⟨(Kσ : Int), 1⟩ : Q) (Qsub ⟨1, 1⟩ (mul σ σ)))) (hRY : ∀ n, n ≤ R_Y n)
    (hslt : ∀ m, (s.seq m).num.toNat < (s.seq m).den) (htlt : ∀ m, (t.seq m).num.toNat < (t.seq m).den)
    (hslt' : ∀ m, (neg (s.seq m)).num.toNat < (s.seq m).den)
    (htlt' : ∀ m, (neg (t.seq m)).num.toNat < (t.seq m).den)
    (hbs : ∀ m, Qle (Qabs (s.seq m)) σ) (hbt : ∀ m, Qle (Qabs (t.seq m)) σ)
    (hbw : ∀ i, Qle (Qabs (wvalR (s.seq i) (t.seq i))) σ)
    (hX1seq : ∀ j, X1.seq j = artSum (s.seq (Rartanh_R σ j)) (Rartanh_R σ j))
    (hX2seq : ∀ j, X2.seq j = artSum (t.seq (Rartanh_R σ j)) (Rartanh_R σ j))
    (hYseq : ∀ n, Y.seq n = artSum (wvalR (s.seq (R_Y n)) (t.seq (R_Y n))) (Rartanh_R σ n)) :
    Req (Radd X1 X2) Y := by
  have hsd : ∀ m, 0 < (s.seq m).den := fun m => s.den_pos m
  have htd : ∀ m, 0 < (t.seq m).den := fun m => t.den_pos m
  have hRge : ∀ k, k ≤ Rartanh_R σ k := by
    intro k; unfold Rartanh_R
    have hk : 1 ≤ σ.den * σ.den + 4 * σ.den := Nat.le_trans (by omega) (Nat.le_add_left _ _)
    calc k ≤ 1 * (k + 1) := by omega
      _ ≤ (σ.den * σ.den + 4 * σ.den) * (k + 1) := Nat.mul_le_mul_right _ hk
  have hKσσ : (0 : Int) ≤ (Kσ : Int) * ((σ.den : Int) * σ.den) :=
    Int.mul_nonneg (Int.ofNat_nonneg _) (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _))
  refine Req_of_lin_bound (C := 2 + 4 * Kσ * (σ.den * σ.den)) ?_
  intro n
  have hae : (Radd X1 X2).seq n
      = add (artSum (s.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1)))
          (artSum (t.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1))) := by
    show add (X1.seq (2 * n + 1)) (X2.seq (2 * n + 1)) = _; rw [hX1seq, hX2seq]
  rw [hae, hYseq n]
  have hWd : 0 < (artSum (wvalR (s.seq (Rartanh_R σ (2 * n + 1))) (t.seq (Rartanh_R σ (2 * n + 1))))
      (Rartanh_R σ n)).den :=
    artSum_den_pos (wvalR_den_pos _ _ (wval_inner_pos_gen σ _ _ hσd hσ0 (hsd _) (htd _) (hbs _) (hbt _) hσlt)) _
  have hYd : 0 < (artSum (wvalR (s.seq (R_Y n)) (t.seq (R_Y n))) (Rartanh_R σ n)).den :=
    artSum_den_pos (wvalR_den_pos _ _ (wval_inner_pos_gen σ _ _ hσd hσ0 (hsd _) (htd _) (hbs _) (hbt _) hσlt)) _
  have hRd : 0 < (add (artSum (s.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1)))
      (artSum (t.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1)))).den :=
    add_den_pos (artSum_den_pos (hsd _) _) (artSum_den_pos (htd _) _)
  have hcomb : Qle (Qabs (Qsub
        (artSum (wvalR (s.seq (Rartanh_R σ (2 * n + 1))) (t.seq (Rartanh_R σ (2 * n + 1)))) (Rartanh_R σ n))
        (add (artSum (s.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1)))
          (artSum (t.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1)))))) (⟨2, n + 1⟩ : Q) :=
    RartanhConst_add_wvalR_rho (s.seq (Rartanh_R σ (2 * n + 1)))
      (t.seq (Rartanh_R σ (2 * n + 1))) σ (hsd _) (hslt _) (hslt' _) (htd _) (htlt _) (htlt' _)
      hσ0 hσd hσlt (wval_inner_pos_gen σ _ _ hσd hσ0 (hsd _) (htd _) (hbs _) (hbt _) hσlt)
      (hbs _) (hbt _) (hbw _) n
  have hvar := artSum_wval_argdiff_gen σ σ (s.seq (Rartanh_R σ (2 * n + 1)))
    (t.seq (Rartanh_R σ (2 * n + 1))) (s.seq (R_Y n)) (t.seq (R_Y n)) Kσ
    hσd hσ0 hσlt hσ0 hσd hKσF (hsd _) (htd _) (hsd _) (htd _)
    (hbs _) (hbt _) (hbs _) (hbt _) (hbw _) (hbw _) (Rartanh_R σ n)
  have hQbP : Qle (Qbound (Rartanh_R σ (2 * n + 1))) (Qbound n) := by
    show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((Rartanh_R σ (2 * n + 1) + 1 : Nat) : Int)
    have := hRge (2 * n + 1); rw [Int.one_mul, Int.one_mul]
    exact_mod_cast (show n + 1 ≤ Rartanh_R σ (2 * n + 1) + 1 by omega)
  have hQbM : Qle (Qbound (R_Y n)) (Qbound n) := by
    show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((R_Y n + 1 : Nat) : Int)
    have := hRY n; rw [Int.one_mul, Int.one_mul]
    exact_mod_cast (show n + 1 ≤ R_Y n + 1 by omega)
  have hlegB : Qle (Qabs (Qsub
        (artSum (wvalR (s.seq (Rartanh_R σ (2 * n + 1))) (t.seq (Rartanh_R σ (2 * n + 1)))) (Rartanh_R σ n))
        (artSum (wvalR (s.seq (R_Y n)) (t.seq (R_Y n))) (Rartanh_R σ n))))
      (⟨4 * ((Kσ : Int) * ((σ.den : Int) * σ.den)), n + 1⟩ : Q) := by
    refine Qle_trans (Qmul_den_pos Nat.one_pos (add_den_pos
        (Qabs_den_pos (Qsub_den_pos (hsd _) (hsd _))) (Qabs_den_pos (Qsub_den_pos (htd _) (htd _)))))
      hvar ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (add_den_pos
        (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
        (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))))
      (Qmul_le_mul_left hKσσ (Qadd_le_add (s.reg _ _) (t.reg _ _))) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (add_den_pos
        (add_den_pos (Qbound_den_pos n) (Qbound_den_pos n))
        (add_den_pos (Qbound_den_pos n) (Qbound_den_pos n))))
      (Qmul_le_mul_left hKσσ
        (Qadd_le_add (Qadd_le_add hQbP hQbM) (Qadd_le_add hQbP hQbM))) ?_
    apply Qeq_le
    show Qeq (mul (⟨(Kσ : Int) * ((σ.den : Int) * σ.den), 1⟩ : Q)
        (add (add (Qbound n) (Qbound n)) (add (Qbound n) (Qbound n))))
      (⟨4 * ((Kσ : Int) * ((σ.den : Int) * σ.den)), n + 1⟩ : Q)
    simp only [Qeq, mul, add, Qbound]; push_cast; ring_uor
  have hlegA : Qle (Qabs (Qsub
        (add (artSum (s.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1)))
          (artSum (t.seq (Rartanh_R σ (2 * n + 1))) (Rartanh_R σ (2 * n + 1))))
        (artSum (wvalR (s.seq (Rartanh_R σ (2 * n + 1))) (t.seq (Rartanh_R σ (2 * n + 1)))) (Rartanh_R σ n))))
      (⟨2, n + 1⟩ : Q) := by
    rw [Qabs_Qsub_comm]; exact hcomb
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hRd hWd))
      (Qabs_den_pos (Qsub_den_pos hWd hYd)))
    (Qabs_sub_triangle hRd hWd hYd) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)) (Qadd_le_add hlegA hlegB) ?_
  apply Qeq_le
  show Qeq (add (⟨2, n + 1⟩ : Q) (⟨4 * ((Kσ : Int) * ((σ.den : Int) * σ.den)), n + 1⟩ : Q))
    (⟨((2 + 4 * Kσ * (σ.den * σ.den) : Nat) : Int), n + 1⟩ : Q)
  simp only [Qeq, add]; push_cast; ring_uor

/-- **The real binary addition map at general radius** `wvalReal_gen s t ρ = (s+t)/(1+s·t)`, for reals
    `s, t` with `|s|,|t| ≤ ρ < 1` (no `ρ²≤1/2`). The reindex `2·ρ.den²·(n+1)` absorbs the
    general-radius Lipschitz constant `ρ.den²` (vs `wvalReal`'s `8n+7` absorbing `4`). -/
def wvalReal_gen (s t : Real) (ρ : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num)
    (hρlt : ρ.num.toNat < ρ.den)
    (hbs : ∀ n, Qle (Qabs (s.seq n)) ρ) (hbt : ∀ n, Qle (Qabs (t.seq n)) ρ) : Real where
  seq := fun n => wvalR (s.seq (2 * ρ.den * ρ.den * (n + 1))) (t.seq (2 * ρ.den * ρ.den * (n + 1)))
  den_pos := fun n => wvalR_den_pos _ _
    (wval_inner_pos_gen ρ _ _ hρd hρ0 (s.den_pos _) (t.den_pos _) (hbs _) (hbt _) hρlt)
  reg := by
    intro m n
    have hDsv : ∀ k, 0 < (wvalR (s.seq k) (t.seq k)).den := fun k => wvalR_den_pos _ _
      (wval_inner_pos_gen ρ _ _ hρd hρ0 (s.den_pos _) (t.den_pos _) (hbs k) (hbt k) hρlt)
    have hDmid : 0 < (wvalR (s.seq (2 * ρ.den * ρ.den * (n + 1))) (t.seq (2 * ρ.den * ρ.den * (m + 1)))).den :=
      wvalR_den_pos _ _ (wval_inner_pos_gen ρ _ _ hρd hρ0 (s.den_pos _) (t.den_pos _) (hbs _) (hbt _) hρlt)
    show Qle (Qabs (Qsub (wvalR (s.seq (2 * ρ.den * ρ.den * (m + 1))) (t.seq (2 * ρ.den * ρ.den * (m + 1))))
        (wvalR (s.seq (2 * ρ.den * ρ.den * (n + 1))) (t.seq (2 * ρ.den * ρ.den * (n + 1))))))
      (add (Qbound m) (Qbound n))
    have hT1 : Qle (Qabs (Qsub (wvalR (s.seq (2 * ρ.den * ρ.den * (m + 1))) (t.seq (2 * ρ.den * ρ.den * (m + 1))))
          (wvalR (s.seq (2 * ρ.den * ρ.den * (n + 1))) (t.seq (2 * ρ.den * ρ.den * (m + 1))))))
        (mul (⟨(ρ.den : Int) * ρ.den, 1⟩ : Q)
          (add (Qbound (2 * ρ.den * ρ.den * (m + 1))) (Qbound (2 * ρ.den * ρ.den * (n + 1))))) :=
      Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos (s.den_pos _) (s.den_pos _))))
        (wval_lip1_gen ρ (s.seq (2 * ρ.den * ρ.den * (m + 1))) (s.seq (2 * ρ.den * ρ.den * (n + 1)))
          (t.seq (2 * ρ.den * ρ.den * (m + 1))) hρd hρ0 (s.den_pos _) (s.den_pos _) (t.den_pos _)
          (hbs _) (hbs _) (hbt _) hρlt)
        (Qmul_le_mul_left (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _))
          (s.reg (2 * ρ.den * ρ.den * (m + 1)) (2 * ρ.den * ρ.den * (n + 1))))
    have hT2 : Qle (Qabs (Qsub (wvalR (s.seq (2 * ρ.den * ρ.den * (n + 1))) (t.seq (2 * ρ.den * ρ.den * (m + 1))))
          (wvalR (s.seq (2 * ρ.den * ρ.den * (n + 1))) (t.seq (2 * ρ.den * ρ.den * (n + 1))))))
        (mul (⟨(ρ.den : Int) * ρ.den, 1⟩ : Q)
          (add (Qbound (2 * ρ.den * ρ.den * (m + 1))) (Qbound (2 * ρ.den * ρ.den * (n + 1))))) :=
      Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos (t.den_pos _) (t.den_pos _))))
        (wval_lip2_gen ρ (s.seq (2 * ρ.den * ρ.den * (n + 1))) (t.seq (2 * ρ.den * ρ.den * (m + 1)))
          (t.seq (2 * ρ.den * ρ.den * (n + 1))) hρd hρ0 (s.den_pos _) (t.den_pos _) (t.den_pos _)
          (hbs _) (hbt _) (hbt _) hρlt)
        (Qmul_le_mul_left (Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _))
          (t.reg (2 * ρ.den * ρ.den * (m + 1)) (2 * ρ.den * ρ.den * (n + 1))))
    refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (hDsv _) hDmid))
        (Qabs_den_pos (Qsub_den_pos hDmid (hDsv _))))
      (Qabs_sub_triangle (hDsv _) hDmid (hDsv _)) ?_
    refine Qle_trans (add_den_pos
        (Qmul_den_pos Nat.one_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)))
        (Qmul_den_pos Nat.one_pos (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))))
      (Qadd_le_add hT1 hT2) ?_
    -- 2·ρ.den²·(Qbound(gm)+Qbound(gn)) ≤ Qbound m + Qbound n, exact per-leg
    have hleg : ∀ k, Qle (mul (⟨2 * (ρ.den : Int) * ρ.den, 1⟩ : Q)
        (Qbound (2 * ρ.den * ρ.den * (k + 1)))) (Qbound k) := by
      intro k
      simp only [Qle, mul, Qbound]; push_cast; simp only [Int.mul_one, Int.one_mul]; omega
    refine Qle_trans (add_den_pos (Qmul_den_pos Nat.one_pos (Qbound_den_pos _))
        (Qmul_den_pos Nat.one_pos (Qbound_den_pos _)))
      (Qeq_le ?_) (Qadd_le_add (hleg m) (hleg n))
    show Qeq (add (mul (⟨(ρ.den : Int) * ρ.den, 1⟩ : Q)
          (add (Qbound (2 * ρ.den * ρ.den * (m + 1))) (Qbound (2 * ρ.den * ρ.den * (n + 1)))))
        (mul (⟨(ρ.den : Int) * ρ.den, 1⟩ : Q)
          (add (Qbound (2 * ρ.den * ρ.den * (m + 1))) (Qbound (2 * ρ.den * ρ.den * (n + 1))))))
      (add (mul (⟨2 * (ρ.den : Int) * ρ.den, 1⟩ : Q) (Qbound (2 * ρ.den * ρ.den * (m + 1))))
        (mul (⟨2 * (ρ.den : Int) * ρ.den, 1⟩ : Q) (Qbound (2 * ρ.den * ρ.den * (n + 1)))))
    simp only [Qeq, mul, add, Qbound]; push_cast; ring_uor

set_option maxHeartbeats 1600000 in
/-- **General-radius `tmap(xy) ≈ wvalR(tmap x, tmap y)` diagonal** — the gen analog of `tmul_wvalReal_via`
    matching `wvalReal_gen`'s `2ρ.den²(n+1)` reindex, via `wval_lip1/2_gen` (constant `ρ.den²`). -/
theorem tmul_wvalReal_via_gen (x y txy wxy : Real) (ρ : Q) (hρd : 0 < ρ.den) (hρ0 : 0 ≤ ρ.num)
    (hρlt : ρ.num.toNat < ρ.den) (hxpos : ∀ n, 0 < (x.seq n).num) (hypos : ∀ n, 0 < (y.seq n).num)
    (hbx : ∀ m, Qle (Qabs (tmap (x.seq m))) ρ) (hby : ∀ m, Qle (Qabs (tmap (y.seq m))) ρ)
    (htxyseq : ∀ n, txy.seq n = tmap ((Rmul x y).seq (Rlog_R n)))
    (hwxyseq : ∀ n, wxy.seq n = wvalR (tmap (x.seq (Rlog_R (2 * ρ.den * ρ.den * (n + 1)))))
      (tmap (y.seq (Rlog_R (2 * ρ.den * ρ.den * (n + 1)))))) :
    Req txy wxy := by
  have hxd : ∀ m, 0 < (x.seq m).den := fun m => x.den_pos m
  have hyd : ∀ m, 0 < (y.seq m).den := fun m => y.den_pos m
  have hcax : ∀ m, 0 < (add (x.seq m) ⟨1, 1⟩).num := by
    intro m; have h := hxpos m; have h2 := Int.ofNat_nonneg (x.seq m).den
    show 0 < (x.seq m).num * 1 + 1 * ((x.seq m).den : Int); omega
  have hcay : ∀ m, 0 < (add (y.seq m) ⟨1, 1⟩).num := by
    intro m; have h := hypos m; have h2 := Int.ofNat_nonneg (y.seq m).den
    show 0 < (y.seq m).num * 1 + 1 * ((y.seq m).den : Int); omega
  have hcgex : ∀ m, Qle (⟨1, 1⟩ : Q) (add (x.seq m) ⟨1, 1⟩) := by
    intro m; have h := hxpos m; have h2 := Int.ofNat_nonneg (x.seq m).den
    simp only [Qle, add, mul]; push_cast; omega
  have hcgey : ∀ m, Qle (⟨1, 1⟩ : Q) (add (y.seq m) ⟨1, 1⟩) := by
    intro m; have h := hypos m; have h2 := Int.ofNat_nonneg (y.seq m).den
    simp only [Qle, add, mul]; push_cast; omega
  have htmdx : ∀ m, 0 < (tmap (x.seq m)).den := fun m =>
    Qmul_den_pos (Qsub_den_pos (hxd m) Nat.one_pos) (Qinv_den_pos (hcax m))
  have htmdy : ∀ m, 0 < (tmap (y.seq m)).den := fun m =>
    Qmul_den_pos (Qsub_den_pos (hyd m) Nat.one_pos) (Qinv_den_pos (hcay m))
  have hcaxy : ∀ a, 0 < (add (mul (x.seq a) (y.seq a)) ⟨1, 1⟩).num := by
    intro a
    have hprodn : 0 < (x.seq a).num * (y.seq a).num := Int.mul_pos (hxpos a) (hypos a)
    have hd : 0 < (((x.seq a).den * (y.seq a).den : Nat) : Int) := by exact_mod_cast Nat.mul_pos (hxd a) (hyd a)
    show 0 < (x.seq a).num * (y.seq a).num * 1 + 1 * (((x.seq a).den * (y.seq a).den : Nat) : Int); omega
  have hDpos : ∀ i j, 0 < ((tmap (x.seq i)).den : Int) * (tmap (y.seq j)).den
      + (tmap (x.seq i)).num * (tmap (y.seq j)).num := fun i j =>
    wval_inner_pos_gen ρ (tmap (x.seq i)) (tmap (y.seq j)) hρd hρ0 (htmdx i) (htmdy j) (hbx i) (hby j) hρlt
  have hd2nn : (0 : Int) ≤ (ρ.den : Int) * ρ.den :=
    Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _)
  refine Req_of_lin_bound (C := 8 * ρ.den * ρ.den) ?_
  intro n
  rw [htxyseq n, hwxyseq n]
  let A := Ridx x y (Rlog_R n)
  let B := Rlog_R (2 * ρ.den * ρ.den * (n + 1))
  show Qle (Qabs (Qsub (tmap (mul (x.seq A) (y.seq A)))
      (wvalR (tmap (x.seq B)) (tmap (y.seq B))))) (⟨(8 * ρ.den * ρ.den : Nat), n + 1⟩ : Q)
  have hQbA : Qle (Qbound A) (Qbound n) := by
    show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((A + 1 : Nat) : Int)
    have hge := Ridx_ge x y (Rlog_R n); have hr : n ≤ Rlog_R n := by unfold Rlog_R; omega
    rw [Int.one_mul, Int.one_mul]
    exact_mod_cast (show n + 1 ≤ A + 1 by show n + 1 ≤ Ridx x y (Rlog_R n) + 1; omega)
  have hQbB : Qle (Qbound B) (Qbound n) := by
    show (1 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((B + 1 : Nat) : Int)
    have hpos : 0 < 2 * ρ.den * ρ.den := Nat.mul_pos (Nat.mul_pos (by omega) hρd) hρd
    have hKge : n + 1 ≤ 2 * ρ.den * ρ.den * (n + 1) := by
      calc n + 1 = 1 * (n + 1) := (Nat.one_mul _).symm
        _ ≤ 2 * ρ.den * ρ.den * (n + 1) := Nat.mul_le_mul_right _ (by omega)
    have hr : n ≤ B := by show n ≤ Rlog_R (2 * ρ.den * ρ.den * (n + 1)); unfold Rlog_R; omega
    rw [Int.one_mul, Int.one_mul]; exact_mod_cast (show n + 1 ≤ B + 1 by omega)
  have leg1 : Qle (Qabs (Qsub (wvalR (tmap (x.seq A)) (tmap (y.seq A)))
      (wvalR (tmap (x.seq B)) (tmap (y.seq A))))) (⟨4 * ((ρ.den : Int) * ρ.den), n + 1⟩ : Q) := by
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos (htmdx A) (htmdx B))))
      (wval_lip1_gen ρ (tmap (x.seq A)) (tmap (x.seq B)) (tmap (y.seq A)) hρd hρ0
        (htmdx A) (htmdx B) (htmdy A) (hbx A) (hbx B) (hby A) hρlt) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos
        (Qabs_den_pos (Qsub_den_pos (hxd A) (hxd B)))))
      (Qmul_le_mul_left hd2nn (tmap_lip (x.seq A) (x.seq B) (hxd A) (hxd B)
        (hcax A) (hcax B) (hcgex A) (hcgex B))) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos
        (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))))
      (Qmul_le_mul_left hd2nn (Qmul_le_mul_left (by decide) (x.reg A B))) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos
        (add_den_pos (Qbound_den_pos n) (Qbound_den_pos n))))
      (Qmul_le_mul_left hd2nn (Qmul_le_mul_left (by decide) (Qadd_le_add hQbA hQbB))) ?_
    apply Qeq_le
    show Qeq (mul (⟨(ρ.den : Int) * ρ.den, 1⟩ : Q) (mul ⟨2, 1⟩ (add (Qbound n) (Qbound n))))
      (⟨4 * ((ρ.den : Int) * ρ.den), n + 1⟩ : Q)
    simp only [Qeq, mul, add, Qbound]; push_cast; generalize (ρ.den : Int) = d; ring_uor
  have leg2 : Qle (Qabs (Qsub (wvalR (tmap (x.seq B)) (tmap (y.seq A)))
      (wvalR (tmap (x.seq B)) (tmap (y.seq B))))) (⟨4 * ((ρ.den : Int) * ρ.den), n + 1⟩ : Q) := by
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos (htmdy A) (htmdy B))))
      (wval_lip2_gen ρ (tmap (x.seq B)) (tmap (y.seq A)) (tmap (y.seq B)) hρd hρ0
        (htmdx B) (htmdy A) (htmdy B) (hbx B) (hby A) (hby B) hρlt) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos
        (Qabs_den_pos (Qsub_den_pos (hyd A) (hyd B)))))
      (Qmul_le_mul_left hd2nn (tmap_lip (y.seq A) (y.seq B) (hyd A) (hyd B)
        (hcay A) (hcay B) (hcgey A) (hcgey B))) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos
        (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))))
      (Qmul_le_mul_left hd2nn (Qmul_le_mul_left (by decide) (y.reg A B))) ?_
    refine Qle_trans (Qmul_den_pos Nat.one_pos (Qmul_den_pos Nat.one_pos
        (add_den_pos (Qbound_den_pos n) (Qbound_den_pos n))))
      (Qmul_le_mul_left hd2nn (Qmul_le_mul_left (by decide) (Qadd_le_add hQbA hQbB))) ?_
    apply Qeq_le
    show Qeq (mul (⟨(ρ.den : Int) * ρ.den, 1⟩ : Q) (mul ⟨2, 1⟩ (add (Qbound n) (Qbound n))))
      (⟨4 * ((ρ.den : Int) * ρ.den), n + 1⟩ : Q)
    simp only [Qeq, mul, add, Qbound]; push_cast; generalize (ρ.den : Int) = d; ring_uor
  refine Qle_trans (Qabs_den_pos (Qsub_den_pos (wvalR_den_pos _ _ (hDpos A A))
      (wvalR_den_pos _ _ (hDpos B B))))
    (Qeq_le (Qabs_Qeq (Qsub_congr (tmap_mul_wvalR (x.seq A) (y.seq A) (hxd A) (hyd A)
      (hcax A) (hcay A) (hcaxy A) (hDpos A A)) (Qeq_refl _)))) ?_
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (wvalR_den_pos _ _ (hDpos A A))
        (wvalR_den_pos _ _ (hDpos B A))))
      (Qabs_den_pos (Qsub_den_pos (wvalR_den_pos _ _ (hDpos B A)) (wvalR_den_pos _ _ (hDpos B B)))))
    (Qabs_sub_triangle (wvalR_den_pos _ _ (hDpos A A)) (wvalR_den_pos _ _ (hDpos B A))
      (wvalR_den_pos _ _ (hDpos B B))) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Nat.succ_pos n)) (Qadd_le_add leg1 leg2) ?_
  apply Qeq_le
  show Qeq (add (⟨4 * ((ρ.den : Int) * ρ.den), n + 1⟩ : Q) (⟨4 * ((ρ.den : Int) * ρ.den), n + 1⟩ : Q))
    (⟨(8 * ρ.den * ρ.den : Nat), n + 1⟩ : Q)
  simp only [Qeq, add]; push_cast; generalize (ρ.den : Int) = d; ring_uor

set_option maxHeartbeats 1600000 in
/-- **General-radius log-mult wiring** (gen analog of `Rlog_mul_via_signed`): routes the real addition
    through `Rartanh_add_real_via_gen` + `Rartanh_congr_gen`, with `wvalReal_gen` (gen reindex). -/
theorem Rlog_mul_via_gen (c tx ty txy : Real) (σ : Q) (Kσ : Nat)
    (hσ0 : 0 ≤ σ.num) (hσd : 0 < σ.den) (hσlt : σ.num.toNat < σ.den)
    (hKσF : Qle (⟨1, 1⟩ : Q) (mul (⟨(Kσ : Int), 1⟩ : Q) (Qsub ⟨1, 1⟩ (mul σ σ))))
    (hKr : Kσ ≤ 2 * (σ.den * σ.den + 4 * σ.den))
    (hslt : ∀ m, (tx.seq m).num.toNat < (tx.seq m).den)
    (htlt : ∀ m, (ty.seq m).num.toNat < (ty.seq m).den)
    (hslt' : ∀ m, (neg (tx.seq m)).num.toNat < (tx.seq m).den)
    (htlt' : ∀ m, (neg (ty.seq m)).num.toNat < (ty.seq m).den)
    (hbx : ∀ m, Qle (Qabs (tx.seq m)) σ) (hby : ∀ m, Qle (Qabs (ty.seq m)) σ)
    (hbw : ∀ i, Qle (Qabs (wvalR (tx.seq i) (ty.seq i))) σ) (hbtxy : ∀ m, Qle (Qabs (txy.seq m)) σ)
    (htmul : Req txy (wvalReal_gen tx ty σ hσd hσ0 hσlt hbx hby)) :
    Req (Radd (Rmul c (Rartanh tx σ hσ0 hσd hσlt hbx)) (Rmul c (Rartanh ty σ hσ0 hσd hσlt hby)))
        (Rmul c (Rartanh txy σ hσ0 hσd hσlt hbtxy)) := by
  have hbW : ∀ n, Qle (Qabs ((wvalReal_gen tx ty σ hσd hσ0 hσlt hbx hby).seq n)) σ :=
    fun n => hbw (2 * σ.den * σ.den * (n + 1))
  have hRY : ∀ n, n ≤ 2 * σ.den * σ.den * (Rartanh_R σ n + 1) := by
    intro n
    have hpos : 0 < 2 * σ.den * σ.den := Nat.mul_pos (Nat.mul_pos (by omega) hσd) hσd
    have h1 : Rartanh_R σ n + 1 ≤ 2 * σ.den * σ.den * (Rartanh_R σ n + 1) := by
      calc Rartanh_R σ n + 1 = 1 * (Rartanh_R σ n + 1) := (Nat.one_mul _).symm
        _ ≤ 2 * σ.den * σ.den * (Rartanh_R σ n + 1) := Nat.mul_le_mul_right _ (by omega)
    have hRR : n ≤ Rartanh_R σ n := by
      unfold Rartanh_R
      have hk : 1 ≤ σ.den * σ.den + 4 * σ.den := Nat.le_trans (by omega) (Nat.le_add_left _ _)
      calc n ≤ 1 * (n + 1) := by omega
        _ ≤ (σ.den * σ.den + 4 * σ.den) * (n + 1) := Nat.mul_le_mul_right _ hk
    omega
  have hadd : Req (Radd (Rartanh tx σ hσ0 hσd hσlt hbx) (Rartanh ty σ hσ0 hσd hσlt hby))
      (Rartanh (wvalReal_gen tx ty σ hσd hσ0 hσlt hbx hby) σ hσ0 hσd hσlt hbW) :=
    Rartanh_add_real_via_gen tx ty (Rartanh tx σ hσ0 hσd hσlt hbx) (Rartanh ty σ hσ0 hσd hσlt hby)
      (Rartanh (wvalReal_gen tx ty σ hσd hσ0 hσlt hbx hby) σ hσ0 hσd hσlt hbW)
      σ Kσ (fun n => 2 * σ.den * σ.den * (Rartanh_R σ n + 1)) hσ0 hσd hσlt hKσF hRY
      hslt htlt hslt' htlt' hbx hby hbw (fun _ => rfl) (fun _ => rfl) (fun _ => rfl)
  have hcong : Req (Rartanh (wvalReal_gen tx ty σ hσd hσ0 hσlt hbx hby) σ hσ0 hσd hσlt hbW)
      (Rartanh txy σ hσ0 hσd hσlt hbtxy) :=
    Rartanh_congr_gen (wvalReal_gen tx ty σ hσd hσ0 hσlt hbx hby) txy σ Kσ hσ0 hσd hσlt hKσF hKr
      hbW hbtxy (Req_symm htmul)
  exact Rlog_mul_algebra c (Rartanh tx σ hσ0 hσd hσlt hbx) (Rartanh ty σ hσ0 hσd hσlt hby)
    (Rartanh (wvalReal_gen tx ty σ hσd hσ0 hσlt hbx hby) σ hσ0 hσd hσlt hbW)
    (Rartanh txy σ hσ0 hσd hσlt hbtxy) hadd hcong

set_option maxHeartbeats 1600000 in
/-- **★★ general-radius real log-multiplicativity** `Rlog(x·y) = Rlog x + Rlog y` for `x, y ∈ [1/B, B]`
    at **any** `B ≥ 1` (no small-radius cap). The fully general analog of `Rlog_mul_signed`: radius
    alignment via `Rartanh_radius_indep_gen` (`K_B` for `ρ_B`), combination via `Rlog_mul_via_gen` +
    `tmul_wvalReal_via_gen` + `wvalReal_gen` (`Kσ` for `ρ_{B²}`). `K = den` is the canonical bound. -/
theorem Rlog_mul_gen (x y : Real) (B : Q) (K_B Kσ : Nat) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxpos : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B)
    (hxloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) B))
    (hypos : ∀ n, 0 < (y.seq n).num) (hyhiB : ∀ n, Qle (y.seq n) B)
    (hyloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (y.seq n) B))
    (hB2d : 0 < (mul B B).den) (hB2ge : Qle (⟨1, 1⟩ : Q) (mul B B))
    (hxypos : ∀ n, 0 < ((Rmul x y).seq n).num) (hxyhi : ∀ n, Qle ((Rmul x y).seq n) (mul B B))
    (hxylo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rmul x y).seq n) (mul B B)))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hKBF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K_B : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩))))
    (hKσF : Qle (⟨1, 1⟩ : Q) (mul (⟨(Kσ : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩))))
    (hKσr : Kσ ≤ 2 * (((mul B B).num.toNat + (mul B B).den) * ((mul B B).num.toNat + (mul B B).den)
      + 4 * ((mul B B).num.toNat + (mul B B).den))) :
    Req (Radd (Rlog x B hBd hBge hxpos hxhiB hxloB) (Rlog y B hBd hBge hypos hyhiB hyloB))
        (Rlog (Rmul x y) (mul B B) hB2d hB2ge hxypos hxyhi hxylo) := by
  obtain ⟨hBn, hB1, hρ0, hρd, hρlt, hρ1⟩ := Rlog_radius_facts B hBd hBge
  obtain ⟨hB2n, hB21, hσ0, hσd, hσlt, hσ1⟩ := Rlog_radius_facts (mul B B) hB2d hB2ge
  have hden_x : ∀ n, 0 < (Rlog_seq x n).den := fun n => Qmul_den_pos
    (Qsub_den_pos (x.den_pos _) Nat.one_pos) (Qinv_den_pos (by
      have := hxpos (Rlog_R n); have h := Int.ofNat_nonneg (x.seq (Rlog_R n)).den
      show 0 < (x.seq (Rlog_R n)).num * 1 + 1 * ((x.seq (Rlog_R n)).den : Int); omega))
  have hden_y : ∀ n, 0 < (Rlog_seq y n).den := fun n => Qmul_den_pos
    (Qsub_den_pos (y.den_pos _) Nat.one_pos) (Qinv_den_pos (by
      have := hypos (Rlog_R n); have h := Int.ofNat_nonneg (y.seq (Rlog_R n)).den
      show 0 < (y.seq (Rlog_R n)).num * 1 + 1 * ((y.seq (Rlog_R n)).den : Int); omega))
  have hden_xy : ∀ n, 0 < (Rlog_seq (Rmul x y) n).den := fun n => Qmul_den_pos
    (Qsub_den_pos ((Rmul x y).den_pos _) Nat.one_pos) (Qinv_den_pos (by
      have := hxypos (Rlog_R n); have h := Int.ofNat_nonneg ((Rmul x y).seq (Rlog_R n)).den
      show 0 < ((Rmul x y).seq (Rlog_R n)).num * 1 + 1 * (((Rmul x y).seq (Rlog_R n)).den : Int); omega))
  have hbtρx := Rlog_tbound x B hBd hBn hB1 hxhiB hxloB hxpos
  have hbtρy := Rlog_tbound y B hBd hBn hB1 hyhiB hyloB hypos
  have hbtσxy := Rlog_tbound (Rmul x y) (mul B B) hB2d hB2n hB21 hxyhi hxylo hxypos
  have hbxσ : ∀ k, Qle (Qabs (tmap (x.seq k))) (⟨(mul B B).num - ((mul B B).den : Int),
      (mul B B).num.toNat + (mul B B).den⟩ : Q) := fun k => Qle_trans hρd (hbtρx k) hρσ
  have hbyσ : ∀ k, Qle (Qabs (tmap (y.seq k))) (⟨(mul B B).num - ((mul B B).den : Int),
      (mul B B).num.toNat + (mul B B).den⟩ : Q) := fun k => Qle_trans hρd (hbtρy k) hρσ
  rw [Rlog_eq_Rmul x B hBd hBge hxpos hxhiB hxloB hden_x hρ0 hρd hρlt (fun n => hbtρx (Rlog_R n)),
    Rlog_eq_Rmul y B hBd hBge hypos hyhiB hyloB hden_y hρ0 hρd hρlt (fun n => hbtρy (Rlog_R n)),
    Rlog_eq_Rmul (Rmul x y) (mul B B) hB2d hB2ge hxypos hxyhi hxylo hden_xy hσ0 hσd hσlt
      (fun n => hbtσxy (Rlog_R n))]
  have hradx : Req (Rartanh ⟨Rlog_seq x, Rlog_regular x hxpos, hden_x⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ hρ0 hρd hρlt (fun n => hbtρx (Rlog_R n)))
      (Rartanh ⟨Rlog_seq x, Rlog_regular x hxpos, hden_x⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        hσ0 hσd hσlt (fun n => hbxσ (Rlog_R n))) :=
    Rartanh_radius_indep_gen ⟨Rlog_seq x, Rlog_regular x hxpos, hden_x⟩ _ _
      ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
      ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
      ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ K_B hρd hσd hρ0 hρd hρlt hKBF
      (fun n => hbtρx (Rlog_R n)) (fun _ => rfl) (fun _ => rfl)
  have hrady : Req (Rartanh ⟨Rlog_seq y, Rlog_regular y hypos, hden_y⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ hρ0 hρd hρlt (fun n => hbtρy (Rlog_R n)))
      (Rartanh ⟨Rlog_seq y, Rlog_regular y hypos, hden_y⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        hσ0 hσd hσlt (fun n => hbyσ (Rlog_R n))) :=
    Rartanh_radius_indep_gen ⟨Rlog_seq y, Rlog_regular y hypos, hden_y⟩ _ _
      ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
      ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
      ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ K_B hρd hσd hρ0 hρd hρlt hKBF
      (fun n => hbtρy (Rlog_R n)) (fun _ => rfl) (fun _ => rfl)
  have hvia := Rlog_mul_via_gen (ofQ (⟨2, 1⟩ : Q) (by decide))
    ⟨Rlog_seq x, Rlog_regular x hxpos, hden_x⟩ ⟨Rlog_seq y, Rlog_regular y hypos, hden_y⟩
    ⟨Rlog_seq (Rmul x y), Rlog_regular (Rmul x y) hxypos, hden_xy⟩
    ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ Kσ
    hσ0 hσd hσlt hKσF hKσr
    (fun m => (tmap_abs_lt_one (x.seq (Rlog_R m)) (x.den_pos _) (hxpos (Rlog_R m))).1)
    (fun m => (tmap_abs_lt_one (y.seq (Rlog_R m)) (y.den_pos _) (hypos (Rlog_R m))).1)
    (fun m => (tmap_abs_lt_one (x.seq (Rlog_R m)) (x.den_pos _) (hxpos (Rlog_R m))).2)
    (fun m => (tmap_abs_lt_one (y.seq (Rlog_R m)) (y.den_pos _) (hypos (Rlog_R m))).2)
    (fun m => hbxσ (Rlog_R m)) (fun m => hbyσ (Rlog_R m))
    (fun i => wvalR_tmap_seq_bound_signed (x.seq (Rlog_R i)) (y.seq (Rlog_R i)) B (x.den_pos _)
      (y.den_pos _) hBd (hxpos (Rlog_R i)) (hypos (Rlog_R i)) (hxhiB (Rlog_R i)) (hyhiB (Rlog_R i))
      (hxloB (Rlog_R i)) (hyloB (Rlog_R i)) hBge)
    (fun m => hbtσxy (Rlog_R m))
    (tmul_wvalReal_via_gen x y ⟨Rlog_seq (Rmul x y), Rlog_regular (Rmul x y) hxypos, hden_xy⟩
      (wvalReal_gen ⟨Rlog_seq x, Rlog_regular x hxpos, hden_x⟩ ⟨Rlog_seq y, Rlog_regular y hypos, hden_y⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        hσd hσ0 hσlt (fun m => hbxσ (Rlog_R m)) (fun m => hbyσ (Rlog_R m)))
      ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
      hσd hσ0 hσlt hxpos hypos hbxσ hbyσ (fun _ => rfl) (fun _ => rfl))
  exact Req_trans
    (Radd_congr (Rmul_congr (Req_refl _) hradx) (Rmul_congr (Req_refl _) hrady)) hvia

set_option maxHeartbeats 1600000 in
/-- **★ general-radius `RlogPos` multiplicativity**: `log(xy) = log x + log y` for positive reals in
    `[1/B, B]` at any `B ≥ 1`. The fully general analog of `RlogPos_mul_signed`. -/
theorem RlogPos_mul_gen (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
    (ky : Nat) (hy : Qlt (Qbound ky) (y.seq ky))
    (kxy : Nat) (hxy : Qlt (Qbound kxy) ((Rmul x y).seq kxy))
    (B : Q) (K_B Kσ : Nat) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxposB : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B)
    (hxloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) B))
    (hyposB : ∀ n, 0 < (y.seq n).num) (hyhiB : ∀ n, Qle (y.seq n) B)
    (hyloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (y.seq n) B))
    (hB2d : 0 < (mul B B).den) (hB2ge : Qle (⟨1, 1⟩ : Q) (mul B B))
    (hxypos : ∀ n, 0 < ((Rmul x y).seq n).num) (hxyhi : ∀ n, Qle ((Rmul x y).seq n) (mul B B))
    (hxylo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rmul x y).seq n) (mul B B)))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hKBF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K_B : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩))))
    (hKBr : K_B ≤ 2 * ((B.num.toNat + B.den) * (B.num.toNat + B.den) + 4 * (B.num.toNat + B.den)))
    (hKσF : Qle (⟨1, 1⟩ : Q) (mul (⟨(Kσ : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩))))
    (hKσr : Kσ ≤ 2 * (((mul B B).num.toNat + (mul B B).den) * ((mul B B).num.toNat + (mul B B).den)
      + 4 * ((mul B B).num.toNat + (mul B B).den))) :
    Req (RlogPos (Rmul x y) kxy hxy) (Radd (RlogPos x kx hx) (RlogPos y ky hy)) := by
  have bx := RlogPos_eq_Rlog_gen x kx hx B K_B hBd hBge hxposB hxhiB hxloB hKBF hKBr
  have by' := RlogPos_eq_Rlog_gen y ky hy B K_B hBd hBge hyposB hyhiB hyloB hKBF hKBr
  have bxy := RlogPos_eq_Rlog_gen (Rmul x y) kxy hxy (mul B B) Kσ hB2d hB2ge hxypos hxyhi hxylo hKσF hKσr
  have hmul := Rlog_mul_gen x y B K_B Kσ hBd hBge hxposB hxhiB hxloB hyposB hyhiB hyloB
    hB2d hB2ge hxypos hxyhi hxylo hρσ hKBF hKσF hKσr
  exact Req_trans bxy (Req_trans (Req_symm hmul) (Radd_congr (Req_symm bx) (Req_symm by')))

set_option maxHeartbeats 1600000 in
/-- **The `Clog_add` modulus seam, discharged (general modulus)**: `log|zw|² = log|z|² + log|w|²` for
    squared moduli in `[1/B, B]`, any `B ≥ 1`. The general analog of `RlogPos_cnormSq_mul_signed`. -/
theorem RlogPos_cnormSq_mul_gen (z w : Complex)
    (knz : Nat) (hknz : Qlt (Qbound knz) ((cnormSq z).seq knz))
    (knw : Nat) (hknw : Qlt (Qbound knw) ((cnormSq w).seq knw))
    (knzw : Nat) (hknzw : Qlt (Qbound knzw) ((cnormSq (Cmul z w)).seq knzw))
    (B : Q) (K_B Kσ : Nat) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hXpos : ∀ n, 0 < ((cnormSq z).seq n).num) (hXhi : ∀ n, Qle ((cnormSq z).seq n) B)
    (hXlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq z).seq n) B))
    (hYpos : ∀ n, 0 < ((cnormSq w).seq n).num) (hYhi : ∀ n, Qle ((cnormSq w).seq n) B)
    (hYlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq w).seq n) B))
    (hB2d : 0 < (mul B B).den) (hB2ge : Qle (⟨1, 1⟩ : Q) (mul B B))
    (hXYpos : ∀ n, 0 < ((Rmul (cnormSq z) (cnormSq w)).seq n).num)
    (hXYhi : ∀ n, Qle ((Rmul (cnormSq z) (cnormSq w)).seq n) (mul B B))
    (hXYlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rmul (cnormSq z) (cnormSq w)).seq n) (mul B B)))
    (hZWpos : ∀ n, 0 < ((cnormSq (Cmul z w)).seq n).num)
    (hZWhi : ∀ n, Qle ((cnormSq (Cmul z w)).seq n) (mul B B))
    (hZWlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq (Cmul z w)).seq n) (mul B B)))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hKBF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K_B : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩))))
    (hKBr : K_B ≤ 2 * ((B.num.toNat + B.den) * (B.num.toNat + B.den) + 4 * (B.num.toNat + B.den)))
    (hKσF : Qle (⟨1, 1⟩ : Q) (mul (⟨(Kσ : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩))))
    (hKσr : Kσ ≤ 2 * (((mul B B).num.toNat + (mul B B).den) * ((mul B B).num.toNat + (mul B B).den)
      + 4 * ((mul B B).num.toNat + (mul B B).den))) :
    Req (RlogPos (cnormSq (Cmul z w)) knzw hknzw)
        (Radd (RlogPos (cnormSq z) knz hknz) (RlogPos (cnormSq w) knw hknw)) := by
  have hM2pos : 0 < (mul B B).num := by have := hB2ge; simp only [Qle] at this; omega
  have hxy' : Qlt (Qbound (mul B B).num.toNat)
      ((Rmul (cnormSq z) (cnormSq w)).seq (mul B B).num.toNat) :=
    pos_witness_of_mulM_ge (Rmul (cnormSq z) (cnormSq w)) (mul B B) hM2pos hB2d hXYlo
  refine Req_trans ?_ (RlogPos_mul_gen (cnormSq z) (cnormSq w) knz hknz knw hknw _ hxy'
    B K_B Kσ hBd hBge hXpos hXhi hXlo hYpos hYhi hYlo hB2d hB2ge hXYpos hXYhi hXYlo hρσ
    hKBF hKBr hKσF hKσr)
  exact RlogPos_congr_gen (cnormSq (Cmul z w)) (Rmul (cnormSq z) (cnormSq w)) knzw hknzw _ hxy'
    (mul B B) Kσ hB2d hB2ge hZWpos hZWhi hZWlo hXYpos hXYhi hXYlo hKσF hKσr (cnormSq_mul z w)

set_option maxHeartbeats 1600000 in
/-- **★★★ unconditional complex logarithm additivity (general modulus)** `Clog(zw) = Clog z + Clog w`,
    with the modulus seam `hmod` discharged for squared moduli in `[1/B, B]` at **any** `B ≥ 1` — no
    small-radius cap. The completion of substrate item 0's modulus seam. -/
theorem Clog_add_gen (z w : Complex)
    (knz : Nat) (hknz : Qlt (Qbound knz) ((cnormSq z).seq knz))
    (knw : Nat) (hknw : Qlt (Qbound knw) ((cnormSq w).seq knw))
    (knzw : Nat) (hknzw : Qlt (Qbound knzw) ((cnormSq (Cmul z w)).seq knzw))
    (kz : Nat) (hkz : Qlt (Qbound kz) (z.re.seq kz))
    (kw : Nat) (hkw : Qlt (Qbound kw) (w.re.seq kw))
    (kzw : Nat) (hzw : Qlt (Qbound kzw) ((Cmul z w).re.seq kzw))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2arg : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩)
    (hbs : ∀ n, Qle (Qabs ((Rdiv z.im z.re kz hkz).seq n)) ρ)
    (hbt : ∀ n, Qle (Qabs ((Rdiv w.im w.re kw hkw).seq n)) ρ)
    (hbzw : ∀ n, Qle (Qabs ((Rdiv (Cmul z w).im (Cmul z w).re kzw hzw).seq n)) ρ)
    (hbw : ∀ n, Qle (Qabs (vval ((Rdiv z.im z.re kz hkz).seq n)
      ((Rdiv w.im w.re kw hkw).seq n))) ρ)
    (B : Q) (K_B Kσ : Nat) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hXpos : ∀ n, 0 < ((cnormSq z).seq n).num) (hXhi : ∀ n, Qle ((cnormSq z).seq n) B)
    (hXlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq z).seq n) B))
    (hYpos : ∀ n, 0 < ((cnormSq w).seq n).num) (hYhi : ∀ n, Qle ((cnormSq w).seq n) B)
    (hYlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq w).seq n) B))
    (hB2d : 0 < (mul B B).den) (hB2ge : Qle (⟨1, 1⟩ : Q) (mul B B))
    (hXYpos : ∀ n, 0 < ((Rmul (cnormSq z) (cnormSq w)).seq n).num)
    (hXYhi : ∀ n, Qle ((Rmul (cnormSq z) (cnormSq w)).seq n) (mul B B))
    (hXYlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rmul (cnormSq z) (cnormSq w)).seq n) (mul B B)))
    (hZWpos : ∀ n, 0 < ((cnormSq (Cmul z w)).seq n).num)
    (hZWhi : ∀ n, Qle ((cnormSq (Cmul z w)).seq n) (mul B B))
    (hZWlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((cnormSq (Cmul z w)).seq n) (mul B B)))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hKBF : Qle (⟨1, 1⟩ : Q) (mul (⟨(K_B : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
        ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩))))
    (hKBr : K_B ≤ 2 * ((B.num.toNat + B.den) * (B.num.toNat + B.den) + 4 * (B.num.toNat + B.den)))
    (hKσF : Qle (⟨1, 1⟩ : Q) (mul (⟨(Kσ : Int), 1⟩ : Q)
      (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
        ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩))))
    (hKσr : Kσ ≤ 2 * (((mul B B).num.toNat + (mul B B).den) * ((mul B B).num.toNat + (mul B B).den)
      + 4 * ((mul B B).num.toNat + (mul B B).den))) :
    Ceq (Clog (Cmul z w) knzw hknzw kzw hzw ρ hρ0 hρd hlt hbzw)
        (Cadd (Clog z knz hknz kz hkz ρ hρ0 hρd hlt hbs)
              (Clog w knw hknw kw hkw ρ hρ0 hρd hlt hbt)) :=
  Clog_add z w knz hknz knw hknw knzw hknzw kz hkz kw hkw kzw hzw ρ hρ0 hρd hlt hlt16 h2ρ hhalf hρ4
    hρ2arg hρ8 hρ1 hbs hbt hbzw hbw
    (RlogPos_cnormSq_mul_gen z w knz hknz knw hknw knzw hknzw B K_B Kσ hBd hBge
      hXpos hXhi hXlo hYpos hYhi hYlo hB2d hB2ge
      hXYpos hXYhi hXYlo hZWpos hZWhi hZWlo hρσ hKBF hKBr hKσF hKσr)

end UOR.Bridge.F1Square.Analysis
