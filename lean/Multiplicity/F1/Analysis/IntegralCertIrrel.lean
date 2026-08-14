/-
F1 square — **the pre-Hilbert layer, brick 6** (`IntegralCertIrrel.lean`): **certificate
independence of the certified integral** — `riemannIntegral` depends only on the integrand, not
on which Lipschitz certificate constructed it — and the L² pairing's honest symmetry.

The integral at modulus `L` is `D₀ + lim_j Σ(dyadicTerm f)` along the schedule `digammaMidx L`;
two certificates give two schedules over the SAME dyadic increments. The comparison:

- `genSum_gap` — the telescoping tail bound: with `|T m| ≤ K/((m+1)m)` and `1/((m+1)m) =
  1/m − 1/(m+1)`, the increment sum between levels `M ≤ M'` telescopes EXACTLY to
  `K·(1/M − 1/M')`, so `|Σ_{<M'} − Σ_{<M}| ≤ K/M` — the explicit Cauchy modulus of the dyadic
  sums (no geometric estimate needed).
- `Rabs_dist_Rlim` — the two-sided distance to a Bishop limit: `|X m − lim X| ≤ 2/(m+1)`.
- `Rlim_eval_real_rate` — `Rlim_eval_real` generalized to an arbitrary rational rate
  `C/(j+1)`: a sequence converging to a real target at any linear rate has that target as its
  Bishop limit.
- **`riemannIntegral_certif_irrel`** — both schedules reach level `≥ j+1` at index `j`, so the
  `L'`-scheduled sums converge to the `L`-scheduled limit at rate `(⌈L⌉+2)/(j+1)`; the limits
  agree, and the integrals differ only by the shared anchor `D₀`.
- **`innerI_symm`** — the L² pairing is symmetric, honestly: `⟨φ,ψ⟩ = ∫₀¹ φ·ψ ≈ ∫₀¹ ψ·φ =
  ⟨ψ,φ⟩`, combining the shared-certificate symmetry of brick 5 with certificate independence.

HONEST SCOPE. Certificate independence for the base integral `riemannIntegral` on `[0,1]`;
nothing is claimed for the improper or complex layers (their congruences remain per-certificate).
The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.SqrtRealSq
import Multiplicity.F1Square.Analysis.MonotoneIntegral
import Multiplicity.F1Square.Analysis.ThetaLipschitz
import Multiplicity.F1Square.Analysis.IntegralInner

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The two-sided distance to a Bishop limit.
-- ===========================================================================

/-- Mirror of `RTendsTo_Rsub_le`: from convergence, `L − X m ≤ 2/(m+1)`. -/
theorem RTendsTo_le_Rsub {X : Nat → Real} {L : Real} (h : RTendsTo X L) (m : Nat) :
    Rle (Rsub L (X m)) (ofQ (⟨2, m + 1⟩ : Q) (Nat.succ_pos m)) := by
  intro n
  show Qle (add (L.seq (2 * n + 1)) (neg ((X m).seq (2 * n + 1))))
        (add (⟨2, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q))
  refine Qle_trans (Qabs_den_pos (Qsub_den_pos (L.den_pos _) ((X m).den_pos _)))
    (Qle_self_Qabs (Qsub (L.seq (2 * n + 1)) ((X m).seq (2 * n + 1)))) ?_
  rw [Qabs_Qsub_comm]
  refine Qle_trans (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) (h m (2 * n + 1)) ?_
  exact Qadd_le_add (Qle_refl _)
    (by show Qle (⟨2, (2 * n + 1) + 1⟩ : Q) (⟨2, n + 1⟩ : Q); simp only [Qle]; push_cast; omega)

/-- **The two-sided distance to the limit**: `|X m − lim X| ≤ 2/(m+1)`. -/
theorem Rabs_dist_Rlim {X : Nat → Real} (hX : RReg X) (m : Nat) :
    Rle (Rabs (Rsub (X m) (Rlim X hX))) (ofQ (⟨2, m + 1⟩ : Q) (Nat.succ_pos m)) := by
  refine Rabs_le_of_both (RTendsTo_Rsub_le (Rlim_tendsTo X hX) m) ?_
  refine Rle_trans (Rle_of_Req (Rneg_Rsub_flip (X m) (Rlim X hX))) ?_
  exact RTendsTo_le_Rsub (Rlim_tendsTo X hX) m

-- ===========================================================================
-- The rate-generalized limit evaluation.
-- ===========================================================================

/-- **`Rlim_eval_real` at an arbitrary linear rate**: if every `X j` is within `C/(j+1)` of the
    real target `Lt`, then `Rlim X ≈ Lt`. -/
theorem Rlim_eval_real_rate {X : Nat → Real} (hX : RReg X) (Lt : Real) {C : Nat}
    (hrate : ∀ j, Rle (Rabs (Rsub (X j) Lt))
      (ofQ (⟨(C : Int), j + 1⟩ : Q) (Nat.succ_pos j))) :
    Req (Rlim X hX) Lt := by
  refine Req_of_lin_bound (C := C + 3) (fun n => ?_)
  have h := hrate (4 * n + 3) (2 * n + 1)
  have hshape : Qle (Qabs (Qsub ((X (4 * n + 3)).seq (2 * (2 * n + 1) + 1))
      (Lt.seq (2 * (2 * n + 1) + 1))))
      (add (⟨(C : Int), 4 * n + 3 + 1⟩ : Q) (⟨2, 2 * n + 1 + 1⟩ : Q)) := h
  have hidx : 2 * (2 * n + 1) + 1 = 4 * n + 3 := by omega
  rw [hidx] at hshape
  show Qle (Qabs (Qsub ((X (4 * n + 3)).seq (4 * n + 3)) (Lt.seq n)))
    (⟨((C + 3 : Nat) : Int), n + 1⟩ : Q)
  have htri := Qabs_sub_triangle (a := (X (4 * n + 3)).seq (4 * n + 3))
    (b := Lt.seq (4 * n + 3)) (c := Lt.seq n)
    ((X (4 * n + 3)).den_pos _) (Lt.den_pos _) (Lt.den_pos n)
  have hreg := Lt.reg (4 * n + 3) n
  refine Qle_trans (add_den_pos
    (Qabs_den_pos (Qsub_den_pos ((X (4 * n + 3)).den_pos _) (Lt.den_pos _)))
    (Qabs_den_pos (Qsub_den_pos (Lt.den_pos _) (Lt.den_pos n)))) htri ?_
  refine Qle_trans (add_den_pos (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
    (add_den_pos (Qbound_den_pos _) (Qbound_den_pos _)))
    (Qadd_le_add hshape hreg) ?_
  have hcol : Qeq (add (add (⟨(C : Int), 4 * n + 3 + 1⟩ : Q) (⟨2, 2 * n + 1 + 1⟩ : Q))
      (add (Qbound (4 * n + 3)) (Qbound n))) (⟨(C : Int) + 9, 4 * n + 4⟩ : Q) := by
    simp only [Qeq, add, Qbound]; push_cast; ring_uor
  refine Qle_congr_left (show 0 < 4 * n + 4 by omega) (Qeq_symm hcol) ?_
  show ((C : Int) + 9) * ((n + 1 : Nat) : Int) ≤ ((C + 3 : Nat) : Int) * ((4 * n + 4 : Nat) : Int)
  push_cast
  have e1 : ((C : Int) + 9) * ((n : Int) + 1) = (C : Int) * ((n : Int) + 1) + 9 * ((n : Int) + 1) :=
    Int.add_mul _ _ _
  have e2 : ((C : Int) + 3) * (4 * (n : Int) + 4)
      = (C : Int) * (4 * (n : Int) + 4) + 3 * (4 * (n : Int) + 4) := Int.add_mul _ _ _
  rw [e1, e2]
  refine Int.add_le_add ?_ (by omega)
  exact Int.mul_le_mul_of_nonneg_left (by omega) (Int.ofNat_nonneg C)

-- ===========================================================================
-- The telescoping Cauchy modulus of the dyadic increment sums.
-- ===========================================================================

/-- The increment `|dyadicTerm f m|` in absolute-value form (from the two-sided bound). -/
theorem dyadicTerm_abs_bound {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (m : Nat) (hm : 1 ≤ m) :
    Rle (Rabs (dyadicTerm f m))
      (ofQ (mul L (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hLd (digamma_succ_mul_pos hm))) := by
  obtain ⟨hlo, hhi⟩ := dyadicTerm_bound hLd hLn hlip hfc m hm
  refine Rabs_le_of_both hhi ?_
  refine Rle_trans (Rle_Rneg hlo) (Rle_of_Req (Rneg_neg _))

/-- The sharp telescoping gap: `|Σ_{<M+d} T − Σ_{<M} T| ≤ K·d/(M(M+d))` — the partial fractions
    `1/((m+1)m) = 1/m − 1/(m+1)` accumulate exactly. -/
private theorem genSum_gap_sharp {T : Nat → Real} {K : Q} (hKd : 0 < K.den) (hKn : 0 ≤ K.num)
    (hT : ∀ m (hm : 1 ≤ m), Rle (Rabs (T m))
      (ofQ (mul K (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKd (digamma_succ_mul_pos hm))))
    {M : Nat} (hM : 1 ≤ M) :
    ∀ d, Rle (Rabs (Rsub (genSum T (M + d)) (genSum T M)))
      (ofQ (mul K (⟨((d : Nat) : Int), M * (M + d)⟩ : Q))
        (Qmul_den_pos hKd (Nat.mul_pos hM (Nat.le_trans hM (Nat.le_add_right M d)))))
  | 0 => by
      refine Rle_trans (Rle_of_Req (Req_trans (Rabs_congr (Radd_neg _)) Rabs_zero)) ?_
      refine Rle_zero_of_Rnonneg (Rnonneg_ofQ _ ?_)
      show (0 : Int) ≤ K.num * 0
      omega
  | (d + 1) => by
      have ih := genSum_gap_sharp hKd hKn hT hM d
      have hstep : Req (Rsub (genSum T (M + (d + 1))) (genSum T M))
          (Radd (Rsub (genSum T (M + d)) (genSum T M)) (T (M + d))) :=
        digamma_Rsub_Radd_left (genSum T (M + d)) (T (M + d)) (genSum T M)
      refine Rle_trans (Rle_of_Req (Rabs_congr hstep)) ?_
      refine Rle_trans (Rabs_Radd _ _) ?_
      refine Rle_trans (Radd_le_add ih
        (hT (M + d) (Nat.le_trans hM (Nat.le_add_right M d)))) ?_
      refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ _ _)) ?_
      refine Rle_of_Req (ofQ_congr _ _ ?_)
      simp only [Qeq, add, mul]; push_cast; ring_uor

/-- **The Cauchy modulus of the dyadic sums**: with termwise bound `K/((m+1)m)`, the increment
    sum between levels `M` and `M + d` is bounded by `K/M`, uniformly in `d` — the telescoping
    tail, no geometric estimate. -/
theorem genSum_gap {T : Nat → Real} {K : Q} (hKd : 0 < K.den) (hKn : 0 ≤ K.num)
    (hT : ∀ m (hm : 1 ≤ m), Rle (Rabs (T m))
      (ofQ (mul K (⟨1, (m + 1) * m⟩ : Q)) (Qmul_den_pos hKd (digamma_succ_mul_pos hm))))
    {M : Nat} (hM : 1 ≤ M) (d : Nat) :
    Rle (Rabs (Rsub (genSum T (M + d)) (genSum T M)))
      (ofQ (mul K (⟨1, M⟩ : Q)) (Qmul_den_pos hKd hM)) := by
  refine Rle_trans (genSum_gap_sharp hKd hKn hT hM d) ?_
  refine Rle_ofQ_ofQ _ _ ?_
  show (K.num * ((d : Nat) : Int)) * ((K.den * M : Nat) : Int)
      ≤ (K.num * 1) * ((K.den * (M * (M + d)) : Nat) : Int)
  push_cast
  have hcore : ((d : Int)) * ((M : Int)) ≤ ((M : Int)) * ((M : Int) + (d : Int)) := by
    rw [Int.mul_comm, Int.mul_add]
    exact Int.le_add_of_nonneg_left (Int.mul_nonneg (Int.ofNat_nonneg M) (Int.ofNat_nonneg M))
  have e1 : K.num * (d : Int) * ((K.den : Int) * (M : Int))
      = K.num * (K.den : Int) * ((d : Int) * (M : Int)) := by ring_uor
  have e2 : K.num * 1 * ((K.den : Int) * ((M : Int) * ((M : Int) + (d : Int))))
      = K.num * (K.den : Int) * ((M : Int) * ((M : Int) + (d : Int))) := by ring_uor
  rw [e1, e2]
  exact Int.mul_le_mul_of_nonneg_left hcore (Int.mul_nonneg hKn (Int.ofNat_nonneg K.den))

-- ===========================================================================
-- The schedule gap and certificate independence.
-- ===========================================================================

/-- `|x − y| ≈ |y − x|`. -/
theorem Rabs_Rsub_symm (x y : Real) : Req (Rabs (Rsub x y)) (Rabs (Rsub y x)) :=
  Req_trans (Rabs_congr (Req_symm (Rneg_Rsub_flip y x))) (Rabs_Rneg (Rsub y x))

/-- Every digamma schedule is at least the index: `j + 1 ≤ digammaMidx B j`. -/
theorem digammaMidx_ge (B : Q) (j : Nat) : j + 1 ≤ digammaMidx B j := by
  show j + 1 ≤ (B.num.toNat + 1) * (j + 1)
  have h : 1 * (j + 1) ≤ (B.num.toNat + 1) * (j + 1) :=
    Nat.mul_le_mul_right (j + 1) (Nat.succ_le_succ (Nat.zero_le _))
  omega

/-- **The schedule gap**: at index `j` the `L`- and `L'`-scheduled dyadic sums differ by at most
    `L/(j+1)` — both schedules have reached level `≥ j+1`, and the tail telescopes. -/
private theorem schedGap {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y)) (L' : Q) (j : Nat) :
    Rle (Rabs (Rsub (genSum (dyadicTerm f) (digammaMidx L' j))
                    (genSum (dyadicTerm f) (digammaMidx L j))))
        (ofQ (mul L (⟨1, j + 1⟩ : Q)) (Qmul_den_pos hLd (Nat.succ_pos j))) := by
  have hT := fun m hm => dyadicTerm_abs_bound hLd hLn hlip hfc m hm
  have h1 : 1 ≤ digammaMidx L j := digammaMidx_ge_one L j
  have h1' : 1 ≤ digammaMidx L' j := digammaMidx_ge_one L' j
  rcases Nat.le_total (digammaMidx L j) (digammaMidx L' j) with hle | hle
  · obtain ⟨d, hd⟩ : ∃ d, digammaMidx L' j = digammaMidx L j + d :=
      ⟨digammaMidx L' j - digammaMidx L j, by omega⟩
    rw [hd]
    refine Rle_trans (genSum_gap hLd hLn hT h1 d) ?_
    exact Rle_ofQ_ofQ _ _ (qmul_den_anti hLn (digammaMidx_ge L j))
  · obtain ⟨d, hd⟩ : ∃ d, digammaMidx L j = digammaMidx L' j + d :=
      ⟨digammaMidx L j - digammaMidx L' j, by omega⟩
    refine Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) ?_
    rw [hd]
    refine Rle_trans (genSum_gap hLd hLn hT h1' d) ?_
    exact Rle_ofQ_ofQ _ _ (qmul_den_anti hLn (digammaMidx_ge L' j))

/-- **CERTIFICATE INDEPENDENCE OF THE CERTIFIED INTEGRAL**: two Lipschitz certificates for the
    same integrand give `≈`-equal integrals — the value depends only on `f`. The `L'`-scheduled
    sums converge to the `L`-scheduled limit at rate `(⌈L⌉+2)/(j+1)` (schedule gap `≤ L/(j+1)`
    plus distance-to-limit `≤ 2/(j+1)`), so the two Bishop limits agree. -/
theorem riemannIntegral_certif_irrel {f : Real → Real} {L L' : Q}
    (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (hL'd : 0 < L'.den) (hL'n : 0 ≤ L'.num)
    (hlip' : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L' hL'd) (Rabs (Rsub x y))))
    (hfc' : ∀ x y, Req x y → Req (f x) (f y)) :
    Req (riemannIntegral hLd hLn hlip hfc) (riemannIntegral hL'd hL'n hlip' hfc') := by
  refine Radd_congr (Req_refl (dyadicR f 0)) ?_
  refine Req_symm (Rlim_eval_real_rate (dyadicSum_RReg hL'd hL'n hlip' hfc')
    (Rlim _ (dyadicSum_RReg hLd hLn hlip hfc)) (C := L.num.toNat + 2) (fun j => ?_))
  have htele : Req (Radd
      (Rsub (genSum (dyadicTerm f) (digammaMidx L' j)) (genSum (dyadicTerm f) (digammaMidx L j)))
      (Rsub (genSum (dyadicTerm f) (digammaMidx L j))
            (Rlim _ (dyadicSum_RReg hLd hLn hlip hfc))))
      (Rsub (genSum (dyadicTerm f) (digammaMidx L' j))
            (Rlim _ (dyadicSum_RReg hLd hLn hlip hfc))) :=
    Req_trans (Radd_comm _ _) (Radd_Rsub_Rsub _ _ _)
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_symm htele))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add (schedGap hLd hLn hlip hfc L' j)
    (Rabs_dist_Rlim (dyadicSum_RReg hLd hLn hlip hfc) j)) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ _ _)) ?_
  refine Rle_ofQ_ofQ _ _ ?_
  -- `L/(j+1) + 2/(j+1) ≤ (⌈L⌉+2)/(j+1)`
  show ((L.num * 1) * ((j + 1 : Nat) : Int) + 2 * ((L.den * (j + 1) : Nat) : Int))
        * ((j + 1 : Nat) : Int)
      ≤ ((L.num.toNat + 2 : Nat) : Int) * (((L.den * (j + 1)) * (j + 1) : Nat) : Int)
  push_cast
  have hden1 : (1 : Int) ≤ (L.den : Int) := by exact_mod_cast hLd
  have hnum_eq : L.num = (L.num.toNat : Int) := (Int.toNat_of_nonneg hLn).symm
  have ht : (L.num.toNat : Int) ≤ (L.num.toNat : Int) * (L.den : Int) := by
    have h := Int.mul_le_mul_of_nonneg_left hden1 (Int.ofNat_nonneg L.num.toNat)
    rwa [Int.mul_one] at h
  have hcore : L.num + 2 * (L.den : Int) ≤ ((L.num.toNat : Int) + 2) * (L.den : Int) := by
    rw [Int.add_mul, hnum_eq]
    exact Int.add_le_add_right ht _
  have e1 : (L.num * 1 * ((j : Int) + 1) + 2 * ((L.den : Int) * ((j : Int) + 1))) * ((j : Int) + 1)
      = (L.num + 2 * (L.den : Int)) * (((j : Int) + 1) * ((j : Int) + 1)) := by ring_uor
  have e2 : ((L.num.toNat : Int) + 2) * ((L.den : Int) * ((j : Int) + 1) * ((j : Int) + 1))
      = (((L.num.toNat : Int) + 2) * (L.den : Int)) * (((j : Int) + 1) * ((j : Int) + 1)) := by
    ring_uor
  rw [e1, e2]
  refine Int.mul_le_mul_of_nonneg_right hcore ?_
  exact Int.mul_nonneg (by omega) (by omega)

-- ===========================================================================
-- The L² pairing's honest symmetry.
-- ===========================================================================

/-- **SYMMETRY OF THE L² PAIRING**: `⟨φ,ψ⟩ ≈ ⟨ψ,φ⟩` — brick 5's shared-certificate symmetry
    composed with certificate independence. The pairing is now a genuine symmetric bilinear
    pairing on the bounded-Lipschitz test class. -/
theorem innerI_symm (φ ψ : L2Test) : Req (innerI φ ψ) (innerI ψ φ) := by
  refine Req_trans (innerI_symm_certif φ ψ) ?_
  exact riemannIntegral_certif_irrel (l2L_den φ ψ) (l2L_num φ ψ) (l2lip_swap φ ψ)
    (l2fc_swap φ ψ) (l2L_den ψ φ) (l2L_num ψ φ) (l2lip ψ φ) (l2fc ψ φ)

end Multiplicity.UOR.Bridge.F1Square.Analysis
