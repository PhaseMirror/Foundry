/-
F1 square — **the exponential functional equation on all of ℝ**: `exp(x+y) ≈ exp x · exp y`
(`RexpReal_add`), lifting the `[0,1]` rational case to general constructive reals. The Cauchy-product
corner is bounded for *arbitrary* arguments (`expSum_corner_le_gen`, via `expSum_mul_le` +
`expSum_trunc_bound`), and the diagonal gap is closed at the `RexpReal` reindex depth.

This is the first brick of the `ζ` analytic stack: it upgrades `exp` to a homomorphism, the prerequisite
for `exp(c·log n) = nᶜ` (real powers) and hence the `ζ(s)` tail bound at `Re s > 1`.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.ExpReal
import F1Square.Analysis.Binomial
import F1Square.Analysis.ROrder
import F1Square.Analysis.ExpAdd

namespace UOR.Bridge.F1Square.Analysis

/-- `|exp-term aⁱ/i!| = |a|ⁱ/i!`: the absolute value of an exp term is the exp term of `|a|`. -/
theorem expTerm_abs (a : Q) (i : Nat) : Qeq (Qabs (expTerm a i)) (expTerm (Qabs a) i) := by
  show Qeq (Qabs (mul (qpow a i) ⟨1, fct i⟩)) (mul (qpow (Qabs a) i) ⟨1, fct i⟩)
  rw [Qabs_mul]
  exact Qmul_congr (qpow_abs a i) (Qeq_refl _)

/-- **Tail triangle inequality**: if `|g i| ≤ h i` termwise (`h` with positive denominators), then the
    absolute value of any tail `Σ_{a<k≤b} g` is bounded by the corresponding tail `Σ_{a<k≤b} h`. -/
theorem Fsum_tail_abs_le {g h : Nat → Q} (hgd : ∀ i, 0 < (g i).den) (hhd : ∀ i, 0 < (h i).den)
    (hgh : ∀ i, Qle (Qabs (g i)) (h i)) {a b : Nat} (hab : a ≤ b) :
    Qle (Qabs (Qsub (Fsum g b) (Fsum g a))) (Qsub (Fsum h b) (Fsum h a)) := by
  induction hab with
  | refl =>
      have eg : Qeq (Qsub (Fsum g a) (Fsum g a)) ⟨0, 1⟩ := by
        simp only [Qeq, Qsub, neg, add]; push_cast; ring_uor
      have eh : Qeq (Qsub (Fsum h a) (Fsum h a)) ⟨0, 1⟩ := by
        simp only [Qeq, Qsub, neg, add]; push_cast; ring_uor
      refine Qle_trans (b := ⟨0, 1⟩) Nat.one_pos ?_ (Qeq_le (Qeq_symm eh))
      exact Qeq_le (Qeq_trans (b := Qabs ⟨0, 1⟩) Nat.one_pos (Qabs_Qeq eg) (by decide))
  | @step b' hab' ih =>
      have eg : Qeq (Qsub (Fsum g (b' + 1)) (Fsum g a))
          (add (Qsub (Fsum g b') (Fsum g a)) (g (b' + 1))) := by
        show Qeq (Qsub (add (Fsum g b') (g (b' + 1))) (Fsum g a)) _
        simp only [Qeq, Qsub, neg, add]; push_cast; ring_uor
      have eh : Qeq (add (Qsub (Fsum h b') (Fsum h a)) (h (b' + 1)))
          (Qsub (Fsum h (b' + 1)) (Fsum h a)) := by
        show Qeq _ (Qsub (add (Fsum h b') (h (b' + 1))) (Fsum h a))
        simp only [Qeq, Qsub, neg, add]; push_cast; ring_uor
      refine Qle_congr_left (Qabs_den_pos (add_den_pos
          (Qsub_den_pos (Fsum_den_pos hgd b') (Fsum_den_pos hgd a)) (hgd (b' + 1))))
        (Qeq_symm (Qabs_Qeq eg)) ?_
      refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (Fsum_den_pos hgd b') (Fsum_den_pos hgd a)))
          (Qabs_den_pos (hgd (b' + 1)))) (Qabs_add_le _ _) ?_
      refine Qle_trans (add_den_pos (Qsub_den_pos (Fsum_den_pos hhd b') (Fsum_den_pos hhd a)) (hhd (b' + 1)))
        (Qadd_le_add ih (hgh (b' + 1))) (Qeq_le eh)

/-- **The Cauchy-product corner for arbitrary arguments**: with `|a| ≤ Ma`, `|b| ≤ Mb` and `2(Ma+Mb) ≤ M+2`,
    the corner `Σᵢ (Σⱼ≤M − Σⱼ≤M−i)` is bounded by the `exp(a+b)` tail `2(Ma+Mb)^{M+1}/(M+1)!`. Since
    `corner = expSum a M·expSum b M − expSum(a+b) M` (`expSum_mul_eq`) and the product `≤ expSum(a+b)(2M)`
    (`expSum_mul_le`), the corner `≤ expSum(a+b)(2M) − expSum(a+b) M ≤` the truncation tail. -/
theorem expSum_corner_le_gen {a b : Q} {Ma Mb : Nat} (ha0 : 0 ≤ a.num) (had : 0 < a.den)
    (hb0 : 0 ≤ b.num) (hbd : 0 < b.den) (hqa : Qle (Qabs a) ⟨(Ma : Int), 1⟩) (hqb : Qle (Qabs b) ⟨(Mb : Int), 1⟩)
    (M : Nat) (hM : 2 * (Ma + Mb) ≤ M + 2) :
    Qle (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm a i) (expTerm b j)) M)
          (Fsum (fun j => mul (expTerm a i) (expTerm b j)) (M - i))) M)
      ⟨(2 * npow (Ma + Mb) (M + 1) : Int), fct (M + 1)⟩ := by
  have hpqd : 0 < (add a b).den := add_den_pos had hbd
  have hPM : 0 < (expSum (add a b) M).den := expSum_den_pos hpqd M
  have hP2M : 0 < (expSum (add a b) (2 * M)).den := expSum_den_pos hpqd (2 * M)
  have hprodd : 0 < (mul (expSum a M) (expSum b M)).den :=
    Qmul_den_pos (expSum_den_pos had M) (expSum_den_pos hbd M)
  -- |a+b| ≤ Ma+Mb
  have hsum_bd : Qle (Qabs (add a b)) ⟨((Ma + Mb : Nat) : Int), 1⟩ := by
    refine Qle_trans (add_den_pos Nat.one_pos Nat.one_pos)
      (Qle_trans (add_den_pos (Qabs_den_pos had) (Qabs_den_pos hbd)) (Qabs_add_le a b)
        (Qadd_le_add hqa hqb)) (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))
  -- corner ≈ product − expSum(a+b) M
  have hcorner_eq : Qeq (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm a i) (expTerm b j)) M)
          (Fsum (fun j => mul (expTerm a i) (expTerm b j)) (M - i))) M)
      (Qsub (mul (expSum a M) (expSum b M)) (expSum (add a b) M)) := by
    refine Qeq_symm (Qeq_trans (Qsub_den_pos (add_den_pos hPM ?_) hPM)
      (QsubCongr (expSum_mul_eq had hbd M) (Qeq_refl _)) (Qsub_add_left_cancel (expSum (add a b) M) _))
    exact Fsum_den_pos (fun i => Qsub_den_pos
      (Fsum_den_pos (fun j => Qmul_den_pos (expTerm_den_pos had i) (expTerm_den_pos hbd j)) M)
      (Fsum_den_pos (fun j => Qmul_den_pos (expTerm_den_pos had i) (expTerm_den_pos hbd j)) (M - i))) M
  refine Qle_trans (Qsub_den_pos hprodd hPM) (Qeq_le hcorner_eq) ?_
  refine Qle_trans (Qsub_den_pos hP2M hPM) (Qsub_le_sub (expSum_mul_le ha0 had hb0 hbd M)) ?_
  exact Qle_trans (Qabs_den_pos (Qsub_den_pos hP2M hPM)) (Qle_self_Qabs _)
    (expSum_trunc_bound hpqd hsum_bd (a := M) (b := 2 * M) hM (by omega))

/-- **The rational exp functional equation with explicit error**: for arbitrary `|a| ≤ Ma`, `|b| ≤ Mb`
    and `2(Ma+Mb) ≤ N+2`, `|expSum(a+b) N − expSum a N·expSum b N| ≤ 2(Ma+Mb)^{N+1}/(N+1)!` — the corner
    `expSum_corner_le_gen`, bridged by `expSum_mul_eq`. -/
theorem expSum_add_le {a b : Q} {Ma Mb : Nat} (ha0 : 0 ≤ a.num) (had : 0 < a.den)
    (hb0 : 0 ≤ b.num) (hbd : 0 < b.den) (hqa : Qle (Qabs a) ⟨(Ma : Int), 1⟩) (hqb : Qle (Qabs b) ⟨(Mb : Int), 1⟩)
    (N : Nat) (hN : 2 * (Ma + Mb) ≤ N + 2) :
    Qle (Qabs (Qsub (expSum (add a b) N) (mul (expSum a N) (expSum b N))))
      ⟨(2 * npow (Ma + Mb) (N + 1) : Int), fct (N + 1)⟩ := by
  have hg : ∀ i j, 0 < (mul (expTerm a i) (expTerm b j)).den :=
    fun i j => Qmul_den_pos (expTerm_den_pos had i) (expTerm_den_pos hbd j)
  have hgnn : ∀ i j, 0 ≤ (mul (expTerm a i) (expTerm b j)).num :=
    fun i j => Int.mul_nonneg (expTerm_num_nonneg ha0 i) (expTerm_num_nonneg hb0 j)
  have hPN : 0 < (expSum (add a b) N).den := expSum_den_pos (add_den_pos had hbd) N
  have hprodd : 0 < (mul (expSum a N) (expSum b N)).den :=
    Qmul_den_pos (expSum_den_pos had N) (expSum_den_pos hbd N)
  have hcornerd : 0 < (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm a i) (expTerm b j)) N)
      (Fsum (fun j => mul (expTerm a i) (expTerm b j)) (N - i))) N).den :=
    Fsum_den_pos (fun i => Qsub_den_pos (Fsum_den_pos (fun j => hg i j) N)
      (Fsum_den_pos (fun j => hg i j) (N - i))) N
  -- |expSum(a+b)N − product| ≈ |corner|, and corner ≥ 0 is ≤ the corner bound
  have hcorner_nn : 0 ≤ (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm a i) (expTerm b j)) N)
      (Fsum (fun j => mul (expTerm a i) (expTerm b j)) (N - i))) N).num :=
    Fsum_num_nonneg (fun i => Qsub_num_nonneg
      (Fsum_mono_len (fun j => hgnn i j) (fun j => hg i j) (Nat.sub_le N i))) N
  have heq : Qeq (Qsub (expSum (add a b) N) (mul (expSum a N) (expSum b N)))
      (neg (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm a i) (expTerm b j)) N)
        (Fsum (fun j => mul (expTerm a i) (expTerm b j)) (N - i))) N)) :=
    Qeq_trans (Qsub_den_pos hPN (add_den_pos hPN hcornerd))
      (QsubCongr (Qeq_refl (expSum (add a b) N)) (expSum_mul_eq had hbd N))
      (Qsub_add_self_left (expSum (add a b) N) _)
  refine Qle_congr_left (Qabs_den_pos (neg_den_pos hcornerd)) (Qeq_symm (Qabs_Qeq heq)) ?_
  rw [Qabs_neg]
  exact Qabs_le_of_nonneg hcorner_nn (expSum_corner_le_gen ha0 had hb0 hbd hqa hqb N hN)

/-- **Exp diagonal reconciliation**: two exp partial sums at different arguments and depths differ by a
    depth tail plus an argument-Lipschitz term — `|expSum a R − expSum b R'| ≤ 2M^{R'+1}/(R'+1)! +
    LipS(M,R')·|a − b|` (for `R' ≤ R`, `2M ≤ R'+2`, `|a|,|b| ≤ M`). Triangle through `expSum a R'`. -/
theorem expSum_reconcile {a b : Q} {M : Nat} (had : 0 < a.den) (hbd : 0 < b.den)
    (ha : Qle (Qabs a) ⟨(M : Int), 1⟩) (hb : Qle (Qabs b) ⟨(M : Int), 1⟩)
    {R R' : Nat} (hR'2 : 2 * M ≤ R' + 2) (hRR' : R' ≤ R) :
    Qle (Qabs (Qsub (expSum a R) (expSum b R')))
      (add ⟨(2 * npow M (R' + 1) : Int), fct (R' + 1)⟩ (mul (LipS M R') (Qabs (Qsub a b)))) := by
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (expSum_den_pos had R) (expSum_den_pos had R')))
      (Qabs_den_pos (Qsub_den_pos (expSum_den_pos had R') (expSum_den_pos hbd R'))))
    (Qabs_sub_triangle (expSum_den_pos had R) (expSum_den_pos had R') (expSum_den_pos hbd R')) ?_
  exact Qadd_le_add (expSum_trunc_bound had ha hR'2 hRR') (expSum_Lip_le had hbd ha hb R')

/-- **Product difference**: `|A·B − A'·B'| ≤ |B|·|A−A'| + |A'|·|B−B'|`, via `AB−A'B' = B(A−A')+A'(B−B')`. -/
theorem Qprod_diff_le (A A' B B' : Q) (hAd : 0 < A.den) (hA'd : 0 < A'.den) (hBd : 0 < B.den) (hB'd : 0 < B'.den) :
    Qle (Qabs (Qsub (mul A B) (mul A' B')))
      (add (mul (Qabs B) (Qabs (Qsub A A'))) (mul (Qabs A') (Qabs (Qsub B B')))) := by
  have hid : Qeq (Qsub (mul A B) (mul A' B'))
      (add (mul B (Qsub A A')) (mul A' (Qsub B B'))) := by
    simp only [Qeq, Qsub, add, mul, neg]; push_cast; ring_uor
  refine Qle_congr_left (Qabs_den_pos (add_den_pos (Qmul_den_pos hBd (Qsub_den_pos hAd hA'd))
      (Qmul_den_pos hA'd (Qsub_den_pos hBd hB'd)))) (Qeq_symm (Qabs_Qeq hid)) ?_
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qmul_den_pos hBd (Qsub_den_pos hAd hA'd)))
      (Qabs_den_pos (Qmul_den_pos hA'd (Qsub_den_pos hBd hB'd))))
    (Qabs_add_le _ _) ?_
  rw [Qabs_mul B (Qsub A A'), Qabs_mul A' (Qsub B B')]
  exact Qle_refl _

/-- **Factorial decay at the exp diagonal depth**: `2·(xBound x)^{R+1}·2(j+1) ≤ (R+1)!` at `R = RexpReal_R x j`. -/
theorem RexpReal_trunc_decay (x : Real) (j : Nat) :
    2 * npow (xBound x) (RexpReal_R x j + 1) * (2 * (j + 1)) ≤ fct (RexpReal_R x j + 1) := by
  have hM : 0 < xBound x := xBound_pos x
  have hK : npow (xBound x) (2 * xBound x + 1) ≤ RexpReal_K x := by unfold RexpReal_K; omega
  have htr := trunc_reindex (xBound x) (2 * (j + 1)) (4 * (j + 1) * RexpReal_K x) hM (by
    have h4 : 4 * (j + 1) * npow (xBound x) (2 * xBound x + 1) ≤ 4 * (j + 1) * RexpReal_K x :=
      Nat.mul_le_mul (Nat.le_refl _) hK
    rw [show 2 * (2 * (j + 1)) = 4 * (j + 1) from by omega]; omega)
  have hd : 2 * xBound x + 1 + 4 * (j + 1) * RexpReal_K x = RexpReal_R x j + 1 := by unfold RexpReal_R; omega
  rw [hd] at htr; exact htr

/-- The exp diagonal truncation term as a rational bound: `2(xBound x)^{R+1}/(R+1)! ≤ 1/(2(j+1))`. -/
theorem RexpReal_trunc_le (x : Real) (j : Nat) :
    Qle (⟨(2 * npow (xBound x) (RexpReal_R x j + 1) : Int), fct (RexpReal_R x j + 1)⟩ : Q) ⟨1, 2 * (j + 1)⟩ := by
  show (2 * npow (xBound x) (RexpReal_R x j + 1) : Int) * ((2 * (j + 1) : Nat) : Int)
      ≤ (1 : Int) * ((fct (RexpReal_R x j + 1) : Nat) : Int)
  have h := RexpReal_trunc_decay x j
  have hI : ((2 * npow (xBound x) (RexpReal_R x j + 1) * (2 * (j + 1)) : Nat) : Int)
      ≤ ((fct (RexpReal_R x j + 1) : Nat) : Int) := by exact_mod_cast h
  push_cast at hI ⊢; omega

/-- Uniform bound `|expSum q N| ≤ Un = (expM_U M (2M)).num.toNat` for `|q| ≤ M` (any `N`). Via the
    absolute-difference domination `|expSum q N − expSum q 0| ≤ expSumM M N − expSumM M 0`, then
    `expSumM M N = LipS M (N+1) ≤ expM_U M (2M) ≤ Un`. -/
theorem expSum_abs_le_Un {q : Q} {M : Nat} (hqd : 0 < q.den) (hq : Qle (Qabs q) ⟨(M : Int), 1⟩) (N : Nat) :
    Qle (Qabs (expSum q N)) ⟨((expM_U M (2 * M)).num.toNat : Int), 1⟩ := by
  have hstep : Qle (Qabs (expSum q N)) (expSumM M N) := by
    have hdiff := expSum_abs_diff_le_M hqd hq (a := 0) (b := N) (Nat.zero_le N)
    have hreg : Qeq (expSum q N) (add (Qsub (expSum q N) (expSum q 0)) (expSum q 0)) := by
      simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
    have h1 : Qle (Qabs (expSum q N))
        (add (Qabs (Qsub (expSum q N) (expSum q 0))) (Qabs (expSum q 0))) :=
      Qle_congr_left (Qabs_den_pos (add_den_pos (Qsub_den_pos (expSum_den_pos hqd N) (expSum_den_pos hqd 0))
          (expSum_den_pos hqd 0))) (Qeq_symm (Qabs_Qeq hreg))
        (Qabs_add_le (Qsub (expSum q N) (expSum q 0)) (expSum q 0))
    refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos (expSum_den_pos hqd N) (expSum_den_pos hqd 0)))
        (Qabs_den_pos (expSum_den_pos hqd 0))) h1 ?_
    refine Qle_trans (add_den_pos (Qsub_den_pos (expSumM_den_pos M N) (expSumM_den_pos M 0)) Nat.one_pos)
      (Qadd_le_add hdiff (Qeq_le (show Qeq (Qabs (expSum q 0)) ⟨1, 1⟩ by rfl))) (Qeq_le ?_)
    show Qeq (add (Qsub (expSumM M N) ⟨1, 1⟩) ⟨1, 1⟩) (expSumM M N)
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  refine Qle_trans (expSumM_den_pos M N) hstep ?_
  refine Qle_trans (expM_U_den_pos M (2 * M))
    (Qle_congr_left (LipS_den_pos M (N + 1)) (LipS_shift M N) (LipS_le_U M (N + 1)))
    (Qle_toNat (expM_U_num_nonneg _ _) (expM_U_den_pos _ _))

/-- **The exp functional-equation corner decays to `1/(n+1)` at a deep depth `D`**: combining the rational
    FE `expSum_add_le` with the truncation `truncCoef_QE`, once `D` exceeds the explicit threshold. -/
theorem expSum_add_decay {a b : Q} {Mx My : Nat} (ha0 : 0 ≤ a.num) (had : 0 < a.den)
    (hb0 : 0 ≤ b.num) (hbd : 0 < b.den) (hqa : Qle (Qabs a) ⟨(Mx : Int), 1⟩) (hqb : Qle (Qabs b) ⟨(My : Int), 1⟩)
    (hMxy : 0 < Mx + My) (n D : Nat)
    (hD : 2 * (n + 1) * npow (Mx + My) (2 * (Mx + My) + 1) + 2 * (Mx + My) ≤ D) :
    Qle (Qabs (Qsub (expSum (add a b) D) (mul (expSum a D) (expSum b D)))) ⟨1, n + 1⟩ :=
  Qle_trans (fct_pos _) (expSum_add_le ha0 had hb0 hbd hqa hqb D (by omega))
    (truncCoef_QE (Mx + My) 2 (n + 1) (D + 1) hMxy (by omega) (by omega))

/-- **The Cauchy-product corner for SIGNED arguments**: `|corner(a,b)| ≤ corner(|a|,|b|) ≤ 2(Ma+Mb)^{M+1}/(M+1)!`.
    Each row's tail is dominated (`Fsum_tail_abs_le` + `expTerm_abs`) by the same row for `|a|, |b|`, and the
    fully non-negative `|a|,|b|` corner is bounded by `expSum_corner_le_gen`. Removes the `0 ≤ a.num` hypothesis. -/
theorem expSum_corner_le_gen_signed {a b : Q} {Ma Mb : Nat} (had : 0 < a.den) (hbd : 0 < b.den)
    (hqa : Qle (Qabs a) ⟨(Ma : Int), 1⟩) (hqb : Qle (Qabs b) ⟨(Mb : Int), 1⟩)
    (M : Nat) (hM : 2 * (Ma + Mb) ≤ M + 2) :
    Qle (Qabs (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm a i) (expTerm b j)) M)
          (Fsum (fun j => mul (expTerm a i) (expTerm b j)) (M - i))) M))
      ⟨(2 * npow (Ma + Mb) (M + 1) : Int), fct (M + 1)⟩ := by
  have hax : ∀ i, 0 < (expTerm a i).den := fun i => expTerm_den_pos had i
  have hby : ∀ j, 0 < (expTerm b j).den := fun j => expTerm_den_pos hbd j
  have haax : ∀ i, 0 < (expTerm (Qabs a) i).den := fun i => expTerm_den_pos (Qabs_den_pos had) i
  have hbby : ∀ j, 0 < (expTerm (Qabs b) j).den := fun j => expTerm_den_pos (Qabs_den_pos hbd) j
  have hterm : ∀ i j, Qle (Qabs (mul (expTerm a i) (expTerm b j)))
      (mul (expTerm (Qabs a) i) (expTerm (Qabs b) j)) := fun i j => by
    refine Qeq_le ?_
    rw [Qabs_mul]
    exact Qmul_congr (expTerm_abs a i) (expTerm_abs b j)
  have hrow : ∀ i, Qle (Qabs (Qsub (Fsum (fun j => mul (expTerm a i) (expTerm b j)) M)
        (Fsum (fun j => mul (expTerm a i) (expTerm b j)) (M - i))))
      (Qsub (Fsum (fun j => mul (expTerm (Qabs a) i) (expTerm (Qabs b) j)) M)
        (Fsum (fun j => mul (expTerm (Qabs a) i) (expTerm (Qabs b) j)) (M - i))) := fun i =>
    Fsum_tail_abs_le (fun j => Qmul_den_pos (hax i) (hby j)) (fun j => Qmul_den_pos (haax i) (hbby j))
      (fun j => hterm i j) (Nat.sub_le M i)
  refine Qle_trans (Fsum_den_pos (fun i => Qabs_den_pos (Qsub_den_pos
      (Fsum_den_pos (fun j => Qmul_den_pos (hax i) (hby j)) M)
      (Fsum_den_pos (fun j => Qmul_den_pos (hax i) (hby j)) (M - i)))) M)
    (Fsum_abs_le (fun i => Qsub_den_pos (Fsum_den_pos (fun j => Qmul_den_pos (hax i) (hby j)) M)
      (Fsum_den_pos (fun j => Qmul_den_pos (hax i) (hby j)) (M - i))) M) ?_
  refine Qle_trans (Fsum_den_pos (fun i => Qsub_den_pos
      (Fsum_den_pos (fun j => Qmul_den_pos (haax i) (hbby j)) M)
      (Fsum_den_pos (fun j => Qmul_den_pos (haax i) (hbby j)) (M - i))) M)
    (Fsum_le_congr (fun i _ => hrow i)) ?_
  exact expSum_corner_le_gen (Qabs_num_nonneg a) had (Qabs_num_nonneg b) hbd hqa hqb M hM

/-- **The rational exp functional equation for SIGNED arguments** (no `0 ≤ a.num` hypothesis):
    `|expSum(a+b) N − expSum a N·expSum b N| ≤ 2(Ma+Mb)^{N+1}/(N+1)!`, via `expSum_corner_le_gen_signed`. -/
theorem expSum_add_le_signed {a b : Q} {Ma Mb : Nat} (had : 0 < a.den) (hbd : 0 < b.den)
    (hqa : Qle (Qabs a) ⟨(Ma : Int), 1⟩) (hqb : Qle (Qabs b) ⟨(Mb : Int), 1⟩)
    (N : Nat) (hN : 2 * (Ma + Mb) ≤ N + 2) :
    Qle (Qabs (Qsub (expSum (add a b) N) (mul (expSum a N) (expSum b N))))
      ⟨(2 * npow (Ma + Mb) (N + 1) : Int), fct (N + 1)⟩ := by
  have hg : ∀ i j, 0 < (mul (expTerm a i) (expTerm b j)).den :=
    fun i j => Qmul_den_pos (expTerm_den_pos had i) (expTerm_den_pos hbd j)
  have hPN : 0 < (expSum (add a b) N).den := expSum_den_pos (add_den_pos had hbd) N
  have hcornerd : 0 < (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm a i) (expTerm b j)) N)
      (Fsum (fun j => mul (expTerm a i) (expTerm b j)) (N - i))) N).den :=
    Fsum_den_pos (fun i => Qsub_den_pos (Fsum_den_pos (fun j => hg i j) N)
      (Fsum_den_pos (fun j => hg i j) (N - i))) N
  have heq : Qeq (Qsub (expSum (add a b) N) (mul (expSum a N) (expSum b N)))
      (neg (Fsum (fun i => Qsub (Fsum (fun j => mul (expTerm a i) (expTerm b j)) N)
        (Fsum (fun j => mul (expTerm a i) (expTerm b j)) (N - i))) N)) :=
    Qeq_trans (Qsub_den_pos hPN (add_den_pos hPN hcornerd))
      (QsubCongr (Qeq_refl (expSum (add a b) N)) (expSum_mul_eq had hbd N))
      (Qsub_add_self_left (expSum (add a b) N) _)
  refine Qle_congr_left (Qabs_den_pos (neg_den_pos hcornerd)) (Qeq_symm (Qabs_Qeq heq)) ?_
  rw [Qabs_neg]
  exact expSum_corner_le_gen_signed had hbd hqa hqb N hN

/-- **The exp FE corner decays to `1/(n+1)` for SIGNED arguments** at a deep depth `D` (signed `expSum_add_decay`). -/
theorem expSum_add_decay_signed {a b : Q} {Mx My : Nat} (had : 0 < a.den) (hbd : 0 < b.den)
    (hqa : Qle (Qabs a) ⟨(Mx : Int), 1⟩) (hqb : Qle (Qabs b) ⟨(My : Int), 1⟩)
    (hMxy : 0 < Mx + My) (n D : Nat)
    (hD : 2 * (n + 1) * npow (Mx + My) (2 * (Mx + My) + 1) + 2 * (Mx + My) ≤ D) :
    Qle (Qabs (Qsub (expSum (add a b) D) (mul (expSum a D) (expSum b D)))) ⟨1, n + 1⟩ :=
  Qle_trans (fct_pos _) (expSum_add_le_signed had hbd hqa hqb D (by omega))
    (truncCoef_QE (Mx + My) 2 (n + 1) (D + 1) hMxy (by omega) (by omega))

/-- The exp diagonal depth dominates its index: `j ≤ RexpReal_R x j`. -/
theorem n_le_RexpReal_R (x : Real) (j : Nat) : j ≤ RexpReal_R x j := by
  have hK : 1 ≤ RexpReal_K x := by unfold RexpReal_K; omega
  have h : 4 * (j + 1) * 1 ≤ 4 * (j + 1) * RexpReal_K x := Nat.mul_le_mul (Nat.le_refl _) hK
  unfold RexpReal_R; omega

/-- **Single-factor reconciliation** for `RexpReal_add`: the exp partial sum at a floor index `p ≥ n` and
    deep depth `D` differs from the `x`-diagonal at the common reindex `J ≥ n` by `≤ (1 + 2Uₓ)/(n+1)`,
    where `Uₓ = (expM_U (xBound x) (2·xBound x)).num.toNat`. Depth tail (`RexpReal_trunc_le`) + Lipschitz
    (`expSum_reconcile`, `LipS ≤ Uₓ`, regularity `xreg_n_le`). Used for both the `x`- and `y`-factors. -/
theorem rexp_factor_reconcile (x : Real) (n p J D : Nat) (hpn : n ≤ p) (hJn : n ≤ J)
    (hD : RexpReal_R x J ≤ D) :
    Qle (Qabs (Qsub (expSum (x.seq p) D) (expSum (x.seq (RexpReal_R x J)) (RexpReal_R x J))))
      ⟨(1 + 2 * (expM_U (xBound x) (2 * xBound x)).num.toNat : Int), n + 1⟩ := by
  have hR1n : n ≤ RexpReal_R x J := Nat.le_trans hJn (n_le_RexpReal_R x J)
  have h2M : 2 * xBound x ≤ RexpReal_R x J + 2 := by unfold RexpReal_R; omega
  have hrec := expSum_reconcile (a := x.seq p) (b := x.seq (RexpReal_R x J)) (M := xBound x)
    (x.den_pos p) (x.den_pos (RexpReal_R x J)) (canon_bound x p) (canon_bound x (RexpReal_R x J))
    (R := D) (R' := RexpReal_R x J) h2M hD
  refine Qle_trans (add_den_pos (fct_pos (RexpReal_R x J + 1))
      (Qmul_den_pos (LipS_den_pos _ _) (Qabs_den_pos (Qsub_den_pos (x.den_pos p) (x.den_pos _))))) hrec ?_
  have hmono : Qle (⟨1, 2 * (J + 1)⟩ : Q) ⟨1, n + 1⟩ := by simp only [Qle]; push_cast; omega
  have hterm1 : Qle (⟨(2 * npow (xBound x) (RexpReal_R x J + 1) : Int), fct (RexpReal_R x J + 1)⟩ : Q) ⟨1, n + 1⟩ :=
    Qle_trans (a := (⟨(2 * npow (xBound x) (RexpReal_R x J + 1) : Int), fct (RexpReal_R x J + 1)⟩ : Q))
      (b := (⟨1, 2 * (J + 1)⟩ : Q)) (by omega : (0:Nat) < 2 * (J + 1)) (RexpReal_trunc_le x J) hmono
  have hLip : Qle (LipS (xBound x) (RexpReal_R x J))
      ⟨((expM_U (xBound x) (2 * xBound x)).num.toNat : Int), 1⟩ :=
    Qle_trans (expM_U_den_pos _ _) (LipS_le_U (xBound x) (RexpReal_R x J))
      (Qle_toNat (expM_U_num_nonneg _ _) (expM_U_den_pos _ _))
  have hterm2 : Qle (mul (LipS (xBound x) (RexpReal_R x J)) (Qabs (Qsub (x.seq p) (x.seq (RexpReal_R x J)))))
      (mul ⟨((expM_U (xBound x) (2 * xBound x)).num.toNat : Int), 1⟩ ⟨2, n + 1⟩) :=
    Qle_trans (Qmul_den_pos Nat.one_pos (Qabs_den_pos (Qsub_den_pos (x.den_pos p) (x.den_pos _))))
      (Qmul_le_mul_right (Qabs_num_nonneg _) hLip)
      (Qmul_le_mul_left (Int.ofNat_nonneg _) (xreg_n_le x hpn hR1n))
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (Qmul_den_pos Nat.one_pos (Nat.succ_pos n)))
    (Qadd_le_add hterm1 hterm2) (Qeq_le ?_)
  simp only [Qeq, add, mul]; push_cast; ring_uor

/-- **The exp-add diagonal gap** (abstract): given the three reconciliation bounds (LHS depth `hLP`, FE
    corner `hPQ`, and the two single-factor reconciliations `hAA`/`hBB`) plus the uniform factor bounds
    `hB1`/`hA2`, the gap between the `exp(a₁+b₁)` diagonal at depth `R0` and the product of the `a₂`/`b₂`
    diagonals is `≤ C/(n+1)` with `C = 2 + Uy(1+2Uₓ) + Uₓ(1+2Uy)`. The triangle `L → P → Q → RHS` plus
    `Qprod_diff_le`. Wiring only — all analytic content is in the hypotheses. -/
theorem rexp_add_gap {a1 b1 a2 b2 : Q} (Ux Uy : Nat) {R0 R1 R2 D n : Nat}
    (ha1d : 0 < a1.den) (hb1d : 0 < b1.den) (ha2d : 0 < a2.den) (hb2d : 0 < b2.den)
    (hLP : Qle (Qabs (Qsub (expSum (add a1 b1) R0) (expSum (add a1 b1) D))) ⟨1, n + 1⟩)
    (hPQ : Qle (Qabs (Qsub (expSum (add a1 b1) D) (mul (expSum a1 D) (expSum b1 D)))) ⟨1, n + 1⟩)
    (hAA : Qle (Qabs (Qsub (expSum a1 D) (expSum a2 R1))) ⟨(1 + 2 * Ux : Int), n + 1⟩)
    (hBB : Qle (Qabs (Qsub (expSum b1 D) (expSum b2 R2))) ⟨(1 + 2 * Uy : Int), n + 1⟩)
    (hB1 : Qle (Qabs (expSum b1 D)) ⟨(Uy : Int), 1⟩)
    (hA2 : Qle (Qabs (expSum a2 R1)) ⟨(Ux : Int), 1⟩) :
    Qle (Qabs (Qsub (expSum (add a1 b1) R0) (mul (expSum a2 R1) (expSum b2 R2))))
      ⟨(2 + Uy * (1 + 2 * Ux) + Ux * (1 + 2 * Uy) : Int), n + 1⟩ := by
  have hLd := expSum_den_pos (add_den_pos ha1d hb1d) R0
  have hPd := expSum_den_pos (add_den_pos ha1d hb1d) D
  have hA1d := expSum_den_pos ha1d D
  have hB1d := expSum_den_pos hb1d D
  have hA2d := expSum_den_pos ha2d R1
  have hB2d := expSum_den_pos hb2d R2
  have hQd := Qmul_den_pos hA1d hB1d
  have hRHSd := Qmul_den_pos hA2d hB2d
  -- |Q − RHS| ≤ Uy·(1+2Uₓ)/(n+1) + Uₓ·(1+2Uy)/(n+1)
  have hQR : Qle (Qabs (Qsub (mul (expSum a1 D) (expSum b1 D)) (mul (expSum a2 R1) (expSum b2 R2))))
      (add (mul ⟨(Uy : Int), 1⟩ ⟨(1 + 2 * Ux : Int), n + 1⟩) (mul ⟨(Ux : Int), 1⟩ ⟨(1 + 2 * Uy : Int), n + 1⟩)) := by
    refine Qle_trans (add_den_pos (Qmul_den_pos (Qabs_den_pos hB1d) (Qabs_den_pos (Qsub_den_pos hA1d hA2d)))
        (Qmul_den_pos (Qabs_den_pos hA2d) (Qabs_den_pos (Qsub_den_pos hB1d hB2d))))
      (Qprod_diff_le (expSum a1 D) (expSum a2 R1) (expSum b1 D) (expSum b2 R2) hA1d hA2d hB1d hB2d) ?_
    exact Qadd_le_add
      (Qmul_le_mul (Qabs_den_pos hB1d) Nat.one_pos (Qabs_den_pos (Qsub_den_pos hA1d hA2d))
        (Qabs_num_nonneg _) (Qabs_num_nonneg _) hB1 hAA)
      (Qmul_le_mul (Qabs_den_pos hA2d) Nat.one_pos (Qabs_den_pos (Qsub_den_pos hB1d hB2d))
        (Qabs_num_nonneg _) (Qabs_num_nonneg _) hA2 hBB)
  -- |P − RHS| ≤ |P − Q| + |Q − RHS|
  have hPRHS : Qle (Qabs (Qsub (expSum (add a1 b1) D) (mul (expSum a2 R1) (expSum b2 R2))))
      (add ⟨1, n + 1⟩ (add (mul ⟨(Uy : Int), 1⟩ ⟨(1 + 2 * Ux : Int), n + 1⟩)
        (mul ⟨(Ux : Int), 1⟩ ⟨(1 + 2 * Uy : Int), n + 1⟩))) :=
    Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hPd hQd)) (Qabs_den_pos (Qsub_den_pos hQd hRHSd)))
      (Qabs_sub_triangle hPd hQd hRHSd) (Qadd_le_add hPQ hQR)
  -- |L − RHS| ≤ |L − P| + |P − RHS|, then collapse to C/(n+1)
  refine Qle_trans (add_den_pos (Qabs_den_pos (Qsub_den_pos hLd hPd))
      (Qabs_den_pos (Qsub_den_pos hPd hRHSd)))
    (Qabs_sub_triangle hLd hPd hRHSd) ?_
  refine Qle_trans (add_den_pos (Nat.succ_pos n) (add_den_pos (Nat.succ_pos n)
      (add_den_pos (Qmul_den_pos Nat.one_pos (Nat.succ_pos n)) (Qmul_den_pos Nat.one_pos (Nat.succ_pos n)))))
    (Qadd_le_add hLP hPRHS) (Qeq_le ?_)
  simp only [Qeq, add, mul]; push_cast; ring_uor

/-- **The exp functional equation, fixed deep depth** (the technical core of `RexpReal_add`): at any common
    reference depth `D` past the three diagonal depths and the FE threshold, the `exp(x+y)` diagonal at `n`
    equals the product of the `exp x`, `exp y` diagonals (at the common reindex), up to `C/(n+1)`. The six
    reconciliations: LHS depth (`expSum_trunc_bound`+`RexpReal_trunc_le`), FE corner (`expSum_add_decay_signed`),
    two single-factor (`rexp_factor_reconcile`), two uniform bounds (`expSum_abs_le_Un`); assembled by `rexp_add_gap`. -/
theorem RexpReal_add_aux (x y : Real) (n D : Nat)
    (hR0D : RexpReal_R (Radd x y) n ≤ D)
    (hR1D : RexpReal_R x (Ridx (RexpReal x) (RexpReal y) n) ≤ D)
    (hR2D : RexpReal_R y (Ridx (RexpReal x) (RexpReal y) n) ≤ D)
    (hThr : 2 * (n + 1) * npow (xBound x + xBound y) (2 * (xBound x + xBound y) + 1)
        + 2 * (xBound x + xBound y) ≤ D) :
    Qle (Qabs (Qsub
        (expSum (add (x.seq (2 * RexpReal_R (Radd x y) n + 1)) (y.seq (2 * RexpReal_R (Radd x y) n + 1)))
          (RexpReal_R (Radd x y) n))
        (mul (expSum (x.seq (RexpReal_R x (Ridx (RexpReal x) (RexpReal y) n)))
                (RexpReal_R x (Ridx (RexpReal x) (RexpReal y) n)))
             (expSum (y.seq (RexpReal_R y (Ridx (RexpReal x) (RexpReal y) n)))
                (RexpReal_R y (Ridx (RexpReal x) (RexpReal y) n))))))
      ⟨(2 + (expM_U (xBound y) (2 * xBound y)).num.toNat
            * (1 + 2 * (expM_U (xBound x) (2 * xBound x)).num.toNat)
          + (expM_U (xBound x) (2 * xBound x)).num.toNat
            * (1 + 2 * (expM_U (xBound y) (2 * xBound y)).num.toNat) : Int), n + 1⟩ := by
  have hLP : Qle (Qabs (Qsub
      (expSum (add (x.seq (2 * RexpReal_R (Radd x y) n + 1)) (y.seq (2 * RexpReal_R (Radd x y) n + 1)))
        (RexpReal_R (Radd x y) n))
      (expSum (add (x.seq (2 * RexpReal_R (Radd x y) n + 1)) (y.seq (2 * RexpReal_R (Radd x y) n + 1))) D)))
      ⟨1, n + 1⟩ := by
    rw [Qabs_Qsub_comm]
    refine Qle_trans (fct_pos _)
      (expSum_trunc_bound (M := xBound (Radd x y)) (add_den_pos (x.den_pos _) (y.den_pos _))
        (canon_bound (Radd x y) (RexpReal_R (Radd x y) n))
        (a := RexpReal_R (Radd x y) n) (b := D) (by unfold RexpReal_R; omega) hR0D) ?_
    refine Qle_trans (b := (⟨1, 2 * (n + 1)⟩ : Q)) (by omega : (0:Nat) < 2 * (n + 1))
      (RexpReal_trunc_le (Radd x y) n) (by simp only [Qle]; push_cast; omega)
  have hPQ := expSum_add_decay_signed (x.den_pos (2 * RexpReal_R (Radd x y) n + 1))
    (y.den_pos (2 * RexpReal_R (Radd x y) n + 1))
    (canon_bound x (2 * RexpReal_R (Radd x y) n + 1)) (canon_bound y (2 * RexpReal_R (Radd x y) n + 1))
    (by have := xBound_pos x; omega) n D hThr
  have hAA := rexp_factor_reconcile x n (2 * RexpReal_R (Radd x y) n + 1)
    (Ridx (RexpReal x) (RexpReal y) n) D (by have := n_le_RexpReal_R (Radd x y) n; omega)
    (Ridx_ge (RexpReal x) (RexpReal y) n) hR1D
  have hBB := rexp_factor_reconcile y n (2 * RexpReal_R (Radd x y) n + 1)
    (Ridx (RexpReal x) (RexpReal y) n) D (by have := n_le_RexpReal_R (Radd x y) n; omega)
    (Ridx_ge (RexpReal x) (RexpReal y) n) hR2D
  have hB1 := expSum_abs_le_Un (y.den_pos (2 * RexpReal_R (Radd x y) n + 1))
    (canon_bound y (2 * RexpReal_R (Radd x y) n + 1)) D
  have hA2 := expSum_abs_le_Un (x.den_pos (RexpReal_R x (Ridx (RexpReal x) (RexpReal y) n)))
    (canon_bound x (RexpReal_R x (Ridx (RexpReal x) (RexpReal y) n)))
    (RexpReal_R x (Ridx (RexpReal x) (RexpReal y) n))
  exact rexp_add_gap (expM_U (xBound x) (2 * xBound x)).num.toNat
    (expM_U (xBound y) (2 * xBound y)).num.toNat (x.den_pos _) (y.den_pos _) (x.den_pos _) (y.den_pos _)
    hLP hPQ hAA hBB hB1 hA2

/-- **The exponential functional equation on all of ℝ**: `exp(x+y) ≈ exp x · exp y` (`RexpReal_add`). The
    diagonal lift of the rational Cauchy-product functional equation, reconciled through a deep reference
    depth — the keystone that makes `exp` a homomorphism, prerequisite for `exp(c·log n) = nᶜ`. -/
theorem RexpReal_add (x y : Real) :
    Req (RexpReal (Radd x y)) (Rmul (RexpReal x) (RexpReal y)) := by
  refine Req_of_lin_bound (C := 2 + (expM_U (xBound y) (2 * xBound y)).num.toNat
        * (1 + 2 * (expM_U (xBound x) (2 * xBound x)).num.toNat)
      + (expM_U (xBound x) (2 * xBound x)).num.toNat
        * (1 + 2 * (expM_U (xBound y) (2 * xBound y)).num.toNat)) ?_
  intro n
  refine Qle_trans (Nat.succ_pos n)
    (RexpReal_add_aux x y n
      (RexpReal_R (Radd x y) n + RexpReal_R x (Ridx (RexpReal x) (RexpReal y) n)
        + RexpReal_R y (Ridx (RexpReal x) (RexpReal y) n)
        + (2 * (n + 1) * npow (xBound x + xBound y) (2 * (xBound x + xBound y) + 1)
          + 2 * (xBound x + xBound y)))
      (by omega) (by omega) (by omega) (by omega))
    (Qeq_le (by simp only [Qeq]; push_cast; ring_uor))

end UOR.Bridge.F1Square.Analysis
