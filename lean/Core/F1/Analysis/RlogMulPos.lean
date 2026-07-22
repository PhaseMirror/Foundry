import Core.F1.Analysis.ArtanhAdd

/-!
# `RlogPos` multiplicativity (bounded modulus) — discharging the `Clog_add` modulus seam

`Clog_add` (`ComplexArgAdd.lean`) isolates one explicit hypothesis `hmod`, the `RlogPos`-multiplicativity
`log|zw|² = log|z|² + log|w|²`. This file discharges `hmod` in the **bounded-modulus** regime by
relating `RlogPos` (auto-derived radius) to the presented-radius `Rlog` and reusing `Rlog_mul`.

The two reusable bricks here:
* `reindex_Req` — a sequence reindexed past its tail presents the same real;
* `Rlog_congr` — `Rlog` is a congruence in its argument at small radius.

Both feed the `RlogPos → Rlog` bridge (`RlogPos_eq_Rlog`) and ultimately `RlogPos_mul`.
-/

namespace UOR.Bridge.F1Square.Analysis

/-- Reindexing a regular sequence by any `g` with `n ≤ g n` presents the **same real**. The drift
    `|x_{g n} − x_n| ≤ 1/(g n+1) + 1/(n+1) ≤ 2/(n+1)` (regularity + `g n ≥ n`). -/
theorem reindex_Req (x : Real) (g : Nat → Nat) (hg : ∀ n, n ≤ g n) :
    Req (⟨fun n => x.seq (g n), reindex_regular x g hg, fun _ => x.den_pos _⟩ : Real) x := by
  refine Req_of_lin_bound (C := 2) ?_
  intro n
  show Qle (Qabs (Qsub (x.seq (g n)) (x.seq n))) (⟨(2 : Int), n + 1⟩ : Q)
  refine Qle_trans (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)) (x.reg (g n) n) ?_
  refine Qle_trans (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _))
    (Qadd_le_add (Qbound_anti (hg n)) (Qle_refl _)) ?_
  apply Qeq_le; show Qeq (add (Qbound n) (Qbound n)) (⟨(2 : Int), n + 1⟩ : Q)
  simp only [Qeq, add, Qbound]; push_cast; ring_uor

set_option maxHeartbeats 1600000 in
/-- **`Rlog` congruence in its argument** (small radius): if `x ≈ y` and both present a `log` at a
    common modulus `M` (with the small-radius `ρ_M² ≤ 1/2`), then `Rlog x M ≈ Rlog y M`. The `t`-map
    arguments `tmap(x.seq ·) ≈ tmap(y.seq ·)` (`tmap_lip` + `x ≈ y`), lifted through `Rartanh_congr`. -/
theorem Rlog_congr (x y : Real) (M : Q) (hMd : 0 < M.den) (hMge : Qle (⟨1, 1⟩ : Q) M)
    (hxpos : ∀ n, 0 < (x.seq n).num) (hxhi : ∀ n, Qle (x.seq n) M)
    (hxlo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) M))
    (hypos : ∀ n, 0 < (y.seq n).num) (hyhi : ∀ n, Qle (y.seq n) M)
    (hylo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (y.seq n) M))
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨M.num - (M.den : Int), M.num.toNat + M.den⟩
              ⟨M.num - (M.den : Int), M.num.toNat + M.den⟩)))
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
  exact Rartanh_congr _ _ _ hρ0 hρd hρlt hρ2 (fun n => hbtρx (Rlog_R n)) (fun n => hbtρy (Rlog_R n)) hWeq

/-- `RlogPos` unfolds (definitionally) to a presented-radius `Rlog` of the **reindexed** argument at
    the auto-derived radius `Mx = |x₀|+2+1/L`. Proof-irrelevant in the `Prop` hyps, so the caller may
    supply its own. -/
theorem RlogPos_unfold (x : Real) (k : Nat) (hk : Qlt (Qbound k) (x.seq k))
    (hMxd : 0 < (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))).den)
    (hMxge : Qle (⟨1, 1⟩ : Q) (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))))
    (hp : ∀ n, 0 < ((⟨fun n => x.seq (RlogPosR x k n),
        reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩ : Real).seq n).num)
    (hh : ∀ n, Qle ((⟨fun n => x.seq (RlogPosR x k n),
        reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩ : Real).seq n)
      (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))))
    (hl : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((⟨fun n => x.seq (RlogPosR x k n),
        reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩ : Real).seq n)
      (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))))) :
    RlogPos x k hk
      = Rlog ⟨fun n => x.seq (RlogPosR x k n),
          reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩
        (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))) hMxd hMxge hp hh hl := rfl

set_option maxHeartbeats 1600000 in
/-- **`RlogPos → Rlog` bridge** (bounded modulus): for `x` presented in `[1,B]` at a small radius
    (`ρ_B² ≤ 1/2`), the auto-radius `RlogPos x k` agrees with the presented-radius `Rlog x B`. Routes
    `RlogPos x = Rlog rix Mx` (`RlogPos_unfold`) → `Rlog rix B` (radius independence, `Rartanh_radius_indep`)
    → `Rlog x B` (`Rlog_congr` along `reindex_Req`). -/
theorem RlogPos_eq_Rlog (x : Real) (k : Nat) (hk : Qlt (Qbound k) (x.seq k))
    (B : Q) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxposB : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B)
    (hxloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) B))
    (hρB2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
              ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩))) :
    Req (RlogPos x k hk) (Rlog x B hBd hBge hxposB hxhiB hxloB) := by
  -- RlogPos internals (mirroring its def)
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
  -- rix hyps at Mx (the RlogPos-internal bounds)
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
  -- rix hyps at B
  have hhirixB : ∀ n, Qle ((⟨fun n => x.seq (RlogPosR x k n),
      reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩ : Real).seq n) B :=
    fun n => hxhiB (RlogPosR x k n)
  have hlorixB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((⟨fun n => x.seq (RlogPosR x k n),
      reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩ : Real).seq n) B) :=
    fun n => hxloB (RlogPosR x k n)
  -- (B) congr leg: Rlog rix B ≈ Rlog x B
  refine Req_trans ?_
    (Rlog_congr _ x B hBd hBge hposrix hhirixB hlorixB hxposB hxhiB hxloB hρB2
      (reindex_Req x (RlogPosR x k) (RlogPosR_self x k)))
  -- (A) radius leg: Rlog rix Mx ≈ Rlog rix B
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
  exact Rartanh_radius_indep ⟨Rlog_seq ⟨fun n => x.seq (RlogPosR x k n),
      reindex_regular x (RlogPosR x k) (RlogPosR_self x k), fun _ => x.den_pos _⟩,
      Rlog_regular _ hposrix, hden_rix⟩ _ _
    ⟨(add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))).num
        - ((add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))).den : Int),
      (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))).num.toNat
        + (add (add (Qabs (x.seq 0)) ⟨2, 1⟩) (Qinv (RL x k))).den⟩
    ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
    ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
    hρMxd hρBd hρB0 hρBd hρBlt hρB2 (fun n => hbtB (Rlog_R n)) (fun _ => rfl) (fun _ => rfl)

set_option maxHeartbeats 1600000 in
/-- **★ `RlogPos` multiplicativity** (bounded modulus): `log(xy) = log x + log y` for positive reals
    `x, y` presented in `[1,B]` at small radius. Each `RlogPos` is bridged to its presented-radius
    `Rlog` (`RlogPos_eq_Rlog`) and combined by `Rlog_mul`. Discharges the `Clog_add` `hmod` seam for
    bounded moduli. -/
theorem RlogPos_mul (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
    (ky : Nat) (hy : Qlt (Qbound ky) (y.seq ky))
    (kxy : Nat) (hxy : Qlt (Qbound kxy) ((Rmul x y).seq kxy))
    (B : Q) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxposB : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B)
    (hxloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) B)) (hxge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (x.seq n))
    (hyposB : ∀ n, 0 < (y.seq n).num) (hyhiB : ∀ n, Qle (y.seq n) B)
    (hyloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (y.seq n) B)) (hyge1 : ∀ n, Qle (⟨1, 1⟩ : Q) (y.seq n))
    (hB2d : 0 < (mul B B).den) (hB2ge : Qle (⟨1, 1⟩ : Q) (mul B B))
    (hxypos : ∀ n, 0 < ((Rmul x y).seq n).num) (hxyhi : ∀ n, Qle ((Rmul x y).seq n) (mul B B))
    (hxylo : ∀ n, Qle (⟨1, 1⟩ : Q) (mul ((Rmul x y).seq n) (mul B B)))
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
              ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩)))
    (hρσ : Qle (⟨B.num - (B.den : Int), B.num.toNat + B.den⟩ : Q)
              (⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩ : Q))
    (hσhalf : Qle (mul ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩
              ⟨(mul B B).num - ((mul B B).den : Int), (mul B B).num.toNat + (mul B B).den⟩) ⟨1, 2⟩)
    (hσ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩ ⟨(mul B B).num - ((mul B B).den : Int),
              (mul B B).num.toNat + (mul B B).den⟩))) :
    Req (RlogPos (Rmul x y) kxy hxy) (Radd (RlogPos x kx hx) (RlogPos y ky hy)) := by
  have bx := RlogPos_eq_Rlog x kx hx B hBd hBge hxposB hxhiB hxloB hρ2
  have by' := RlogPos_eq_Rlog y ky hy B hBd hBge hyposB hyhiB hyloB hρ2
  have bxy := RlogPos_eq_Rlog (Rmul x y) kxy hxy (mul B B) hB2d hB2ge hxypos hxyhi hxylo hσ2
  have hmul := Rlog_mul x y B hBd hBge hxposB hxhiB hxloB hxge1 hyposB hyhiB hyloB hyge1
    hB2d hB2ge hxypos hxyhi hxylo hρ2 hρσ hσhalf
  exact Req_trans bxy (Req_trans (Req_symm hmul) (Radd_congr (Req_symm bx) (Req_symm by')))

/-- A value `≥ 1` at index 1 furnishes a `RlogPos` positivity witness there (`Qbound 1 = 1/2 < 1`). -/
theorem ge1_pos_witness (x : Real) (h1 : Qle (⟨1, 1⟩ : Q) (x.seq 1)) :
    Qlt (Qbound 1) (x.seq 1) := by
  have hd := x.den_pos 1
  simp only [Qlt, Qbound]; simp only [Qle] at h1; push_cast at h1 ⊢; omega

set_option maxHeartbeats 1600000 in
/-- **`RlogPos` congruence in its argument** (bounded modulus): `x ≈ y` both in `[1,B]` at small
    radius ⟹ `RlogPos x ≈ RlogPos y`. Both bridged to the presented-radius `Rlog ·B` and joined by
    `Rlog_congr`. -/
theorem RlogPos_congr (x y : Real) (kx : Nat) (hx : Qlt (Qbound kx) (x.seq kx))
    (ky : Nat) (hy : Qlt (Qbound ky) (y.seq ky))
    (B : Q) (hBd : 0 < B.den) (hBge : Qle (⟨1, 1⟩ : Q) B)
    (hxposB : ∀ n, 0 < (x.seq n).num) (hxhiB : ∀ n, Qle (x.seq n) B)
    (hxloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (x.seq n) B))
    (hyposB : ∀ n, 0 < (y.seq n).num) (hyhiB : ∀ n, Qle (y.seq n) B)
    (hyloB : ∀ n, Qle (⟨1, 1⟩ : Q) (mul (y.seq n) B))
    (hρB2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩
              ⟨B.num - (B.den : Int), B.num.toNat + B.den⟩)))
    (heq : Req x y) :
    Req (RlogPos x kx hx) (RlogPos y ky hy) :=
  Req_trans (RlogPos_eq_Rlog x kx hx B hBd hBge hxposB hxhiB hxloB hρB2)
    (Req_trans (Rlog_congr x y B hBd hBge hxposB hxhiB hxloB hyposB hyhiB hyloB hρB2 heq)
      (Req_symm (RlogPos_eq_Rlog y ky hy B hBd hBge hyposB hyhiB hyloB hρB2)))

end UOR.Bridge.F1Square.Analysis
