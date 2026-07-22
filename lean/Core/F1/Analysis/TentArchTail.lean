/-
F1 square — **the tent's improper archimedean tail, CONSTRUCTED and EVALUATED**
(`TentArchTail.lean`):

    `∫₁^∞ (1/w − 1/(w+2)) dw  ≈  log 3`      (`improperTail_eq`)

— the substituted form (`x = w+1`) of the tail past the tent's support,
`∫₂^∞ 2/(x²−1) dx = log 3` (partial fractions `2/(x²−1) = 1/(x−1) − 1/(x+1)`). With
`tent_arch12` this completes the tail value `−1 − 6·log 2 + 4·log 3 − log 3 = −1 − 6·log 2 +
3·log 3` — the tent's last `WeilSlot` field reduced in the kernel.

HOW. `improperIntegral1` sums unit blocks `T m = ∫_{m+1}^{m+2}(1/w − 1/(w+2))`; each block is
TWO instances of the general-base bridge (`riemannIntegral_recipC`):

    `T m ≈ [log(m+2) − log(m+1)] − [log(m+4) − log(m+3)]`,

the decay hypothesis (`K = 3`) comes from the per-step logarithm bracket
(`T m ≤ 1/(m+1) − 1/(m+4) = 3/((m+1)(m+4))`, and `T m ≥ 1/(m+2) − 1/(m+3) ≥ 0`), the partial
sums TELESCOPE (`genSum T N ≈ (log(N+1) − log 1) − (log(N+3) − log 3)`, a three-line additive
rearrangement per step), the defect is `log(N+3) − log(N+1) ≤ 2/(N+1)` (the bracket twice),
and `Rlim_eval_real` evaluates the limit.

HONEST SCOPE. Substrate for the crux route's steps 1–2; no positivity, no crux claim. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.HarmonicLogC
import Core.F1.Analysis.TentArchPiece
import Core.F1.Analysis.ImproperIntegral

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small algebra helpers.
-- ===========================================================================

/-- The difference shape `(P−Q) − (P'−Q') ≈ (P−P') + (Q'−Q)` (local copy). -/
private theorem tail_sub_pair (P Q P' Q' : Real) :
    Req (Rsub (Rsub P Q) (Rsub P' Q')) (Radd (Rsub P P') (Rsub Q' Q)) :=
  Req_trans (Rsub_Radd_Radd P (Rneg Q) P' (Rneg Q'))
    (Radd_congr (Req_refl (Rsub P P')) (Rsub_Rneg_pair Q Q'))

/-- The telescoping step: `((A−C) − (B−D)) + ((A'−A) − (B'−B)) ≈ (A'−C) − (B'−D)`. -/
theorem tail_step_alg (A A' B B' C D : Real) :
    Req (Radd (Rsub (Rsub A C) (Rsub B D)) (Rsub (Rsub A' A) (Rsub B' B)))
      (Rsub (Rsub A' C) (Rsub B' D)) :=
  Req_trans (Req_symm (Rsub_Radd_Radd (Rsub A C) (Rsub A' A) (Rsub B D) (Rsub B' B)))
    (Rsub_congr (Radd_Rsub_Rsub A C A') (Radd_Rsub_Rsub B D B'))

-- ===========================================================================
-- The tail integrand `1/w − 1/(w+2)` (total via the floor-1 clamp).
-- ===========================================================================

/-- The tail integrand `hTail w = 1/max(w,1) − 1/max(w+2,1)` — on `[1, ∞)` this is
    `1/w − 1/(w+2)`, the substituted `2/(x²−1)`. -/
def hTail : Real → Real :=
  fun w => Rsub (clampedInv ⟨1, 1⟩ (by decide) (by decide) w)
    (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) w))

/-- The single-clamp cores are `1`-Lipschitz (with the `≈ |x−y|` collapse). -/
private theorem cI_lip1 (x y : Real) :
    Rle (Rabs (Rsub (clampedInv ⟨1, 1⟩ (by decide) (by decide) x)
      (clampedInv ⟨1, 1⟩ (by decide) (by decide) y))) (Rabs (Rsub x y)) :=
  Rle_trans (clampedInv_lipschitz ⟨1, 1⟩ (by decide) (by decide) x y)
    (Rle_of_Req (Rone_mul (Rabs (Rsub x y))))

private theorem cI_shift2_lip (x y : Real) :
    Rle (Rabs (Rsub
      (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) x))
      (clampedInv ⟨1, 1⟩ (by decide) (by decide) (Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) y))))
      (Rabs (Rsub x y)) := by
  refine Rle_trans (cI_lip1 _ _) ?_
  refine Rle_of_Req (Rabs_congr ?_)
  refine Req_trans (Rsub_Radd_Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) x
    (ofQ (⟨2, 1⟩ : Q) (by decide)) y) ?_
  refine Req_trans (Radd_congr (Radd_neg (ofQ (⟨2, 1⟩ : Q) (by decide)))
    (Req_refl (Rsub x y))) ?_
  exact Req_trans (Radd_comm zero (Rsub x y)) (Radd_zero (Rsub x y))

/-- `hTail` is `2`-Lipschitz. -/
theorem hTail_lip : ∀ x y : Real,
    Rle (Rabs (Rsub (hTail x) (hTail y)))
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (tail_sub_pair _ _ _ _))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add (cI_lip1 x y)
    (Rle_trans (cI_shift2_lip y x) (Rle_of_Req (Rabs_Rsub_swap x y)))) ?_
  exact Rle_of_Req (Req_symm (Rmul_two_eq (Rabs (Rsub x y))))

/-- `hTail` respects `≈`. -/
theorem hTail_congr : ∀ x y : Real, Req x y → Req (hTail x) (hTail y) :=
  fun _ _ h => Rsub_congr
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) h)
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) (Radd_congr (Req_refl _) h))

-- ===========================================================================
-- The block pullback and evaluation:
-- `T m = ∫_{m+1}^{m+2} hTail ≈ [log(m+2)−log(m+1)] − [log(m+4)−log(m+3)]`.
-- ===========================================================================

/-- The single general-base core drops its shift: `|gRecipC c x − gRecipC c y| ≤ |x−y|`. -/
private theorem gC_lip1 (c : Nat) (x y : Real) :
    Rle (Rabs (Rsub (gRecipC c x) (gRecipC c y))) (Rabs (Rsub x y)) := by
  refine Rle_trans (cI_lip1 _ _) ?_
  refine Rle_of_Req (Rabs_congr ?_)
  refine Req_trans (Rsub_Radd_Radd (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) x
    (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos) y) ?_
  refine Req_trans (Radd_congr (Radd_neg (ofQ (⟨(c : Int), 1⟩ : Q) Nat.one_pos))
    (Req_refl (Rsub x y))) ?_
  exact Req_trans (Radd_comm zero (Rsub x y)) (Radd_zero (Rsub x y))

/-- The difference of two general-base reciprocals is `L`-Lipschitz for `L ≥ 2`
    (general in both bases). -/
theorem diffC_lip (a b : Nat) {L : Q} (hLd : 0 < L.den) (h2L : Qle ⟨2, 1⟩ L) :
    ∀ x y : Real,
    Rle (Rabs (Rsub (Rsub (gRecipC a x) (gRecipC b x)) (Rsub (gRecipC a y) (gRecipC b y))))
      (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (tail_sub_pair _ _ _ _))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add (gC_lip1 a x y)
    (Rle_trans (gC_lip1 b y x) (Rle_of_Req (Rabs_Rsub_swap x y)))) ?_
  refine Rle_trans (Rle_of_Req (Req_symm (Rmul_two_eq (Rabs (Rsub x y))))) ?_
  exact Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_ofQ_ofQ (by decide) hLd h2L)

theorem diffC_congr (a b : Nat) : ∀ x y : Real, Req x y →
    Req (Rsub (gRecipC a x) (gRecipC b x)) (Rsub (gRecipC a y) (gRecipC b y)) :=
  fun x y h => Rsub_congr (gRecipC_congr a x y h) (gRecipC_congr b x y h)

/-- The negated general-base core's Lipschitz datum at the block modulus. -/
private theorem negC_lip (b : Nat) : ∀ x y : Real,
    Rle (Rabs (Rsub (Rneg (gRecipC b x)) (Rneg (gRecipC b y))))
      (Rmul (ofQ (mul (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q)) (Qmul_den_pos (by decide) (by decide)))
        (Rabs (Rsub x y))) := by
  intro x y
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Rneg_pair _ _))) ?_
  refine Rle_trans (gRecipC_lip_at b (L := mul (⟨2, 1⟩ : Q) (⟨1, 1⟩ : Q))
    (Qmul_den_pos (by decide) (by decide)) (by decide) y x) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) (Rabs_Rsub_swap x y))

private theorem negC_congr (b : Nat) : ∀ x y : Real, Req x y →
    Req (Rneg (gRecipC b x)) (Rneg (gRecipC b y)) :=
  fun x y h => Rneg_congr (gRecipC_congr b x y h)

/-- **The block pullback, pointwise**: `hTail((m+1) + t) ≈ gRecipC (m+1) t − gRecipC (m+3) t`. -/
theorem hTail_pull (m : Nat) (t : Real) :
    Req (hTail (affineMap ⟨(m : Int) + 1, 1⟩ ⟨1, 1⟩ Nat.one_pos (by decide) t))
      (Rsub (gRecipC (m + 1) t) (gRecipC (m + 3) t)) := by
  refine Rsub_congr
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide)
      (Radd_congr (Req_refl _) (Rone_mul t)))
    (clampedInv_congr ⟨1, 1⟩ (by decide) (by decide) ?_)
  -- `2 + ((m+1) + 1·t) ≈ (m+3) + t`
  refine Req_trans (Radd_congr (Req_refl _)
    (Radd_congr (Req_refl _) (Rone_mul t))) ?_
  refine Req_trans (Req_symm (Radd_assoc (ofQ (⟨2, 1⟩ : Q) (by decide))
    (ofQ (⟨(m : Int) + 1, 1⟩ : Q) Nat.one_pos) t)) ?_
  refine Radd_congr ?_ (Req_refl t)
  refine Req_trans (Radd_ofQ_ofQ (a := (⟨2, 1⟩ : Q)) (b := (⟨(m : Int) + 1, 1⟩ : Q))
    (by decide) Nat.one_pos) ?_
  refine ofQ_congr (add_den_pos (by decide) Nat.one_pos) Nat.one_pos ?_
  show Qeq (add (⟨2, 1⟩ : Q) (⟨(m : Int) + 1, 1⟩ : Q)) (⟨((m + 3 : Nat) : Int), 1⟩ : Q)
  simp only [Qeq, add]; push_cast; ring_uor

/-- The block value `[log(m+2) − log(m+1)] − [log(m+4) − log(m+3)]`. -/
def blockVal (m : Nat) : Real :=
  Rsub (Rsub (logN (m + 1 + 1) (by omega)) (logN (m + 1) (by omega)))
    (Rsub (logN (m + 3 + 1) (by omega)) (logN (m + 3) (by omega)))

/-- **The block evaluation**: `∫_{m+1}^{m+2} hTail ≈ blockVal m`. -/
theorem integralTerm_hTail (m : Nat) :
    Req (integralTerm (f := hTail) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
      hTail_lip hTail_congr m) (blockVal m) := by
  show Req (Rmul (ofQ (⟨1, 1⟩ : Q) (by decide)) _) _
  refine Req_trans (Rone_mul _) ?_
  refine Req_trans (riemannIntegral_congr
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide)) _ _
    (diffC_lip (m + 1) (m + 3) (Qmul_den_pos (by decide) (by decide)) (by decide))
    (diffC_congr (m + 1) (m + 3))
    (fun t => hTail_pull m t)) ?_
  refine Req_trans (riemannIntegral_add
    (f := gRecipC (m + 1))
    (g := fun t => Rneg (gRecipC (m + 3) t))
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecipC_lip_at (m + 1) (Qmul_den_pos (by decide) (by decide)) (by decide))
    (gRecipC_congr (m + 1))
    (negC_lip (m + 3)) (negC_congr (m + 3))
    (diffC_lip (m + 1) (m + 3) (Qmul_den_pos (by decide) (by decide)) (by decide))
    (diffC_congr (m + 1) (m + 3))) ?_
  refine Radd_congr
    (riemannIntegral_recipC_gen (m + 1) (by omega)
      (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
      (gRecipC_lip_at (m + 1) (Qmul_den_pos (by decide) (by decide)) (by decide))
      (gRecipC_congr (m + 1))) ?_
  refine Req_trans (riemannIntegral_neg
    (f := gRecipC (m + 3))
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecipC_lip_at (m + 3) (Qmul_den_pos (by decide) (by decide)) (by decide))
    (gRecipC_congr (m + 3))
    (negC_lip (m + 3)) (negC_congr (m + 3))) ?_
  exact Rneg_congr (riemannIntegral_recipC_gen (m + 3) (by omega)
    (Qmul_den_pos (by decide) (by decide)) (Int.mul_nonneg (by decide) (by decide))
    (gRecipC_lip_at (m + 3) (Qmul_den_pos (by decide) (by decide)) (by decide))
    (gRecipC_congr (m + 3)))

-- ===========================================================================
-- The telescoping partial sums.
-- ===========================================================================

/-- The closed telescoped form `(log(N+1) − log 1) − (log(N+3) − log 3)`. -/
def tailF (N : Nat) : Real :=
  Rsub (Rsub (logN (N + 1) (by omega)) (logN 1 (by omega)))
    (Rsub (logN (N + 3) (by omega)) (logN 3 (by omega)))

/-- **The partial sums telescope**: `genSum T N ≈ tailF N`. -/
theorem genSum_hTail (N : Nat) :
    Req (genSum (integralTerm (f := hTail) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
      hTail_lip hTail_congr) N) (tailF N) := by
  induction N with
  | zero =>
      refine Req_symm (Req_trans (Rsub_congr (Radd_neg _) (Radd_neg _)) ?_)
      exact Rsub_zero zero
  | succ N ih =>
      refine Req_trans (Radd_congr ih (integralTerm_hTail N)) ?_
      exact tail_step_alg (logN (N + 1) (by omega)) (logN (N + 1 + 1) (by omega))
        (logN (N + 3) (by omega)) (logN (N + 3 + 1) (by omega))
        (logN 1 (by omega)) (logN 3 (by omega))

end UOR.Bridge.F1Square.Analysis

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The decay bound (K = 3), from the per-step logarithm bracket.
-- ===========================================================================

private theorem Rneg_zero' : Req (Rneg zero) zero :=
  Req_of_seq_Qeq (fun _ => by
    show Qeq (neg (⟨0, 1⟩ : Q)) (⟨0, 1⟩ : Q)
    decide)

/-- **The block decay** (`K = 3`): `−3/((m+1)m) ≤ T m ≤ 3/((m+1)m)` for `m ≥ 1`. -/
theorem tail_decay : ∀ m, ∀ hm : 1 ≤ m,
    Rle (Rneg (ofQ (mul (⟨3, 1⟩ : Q) (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm))))
      (integralTerm (f := hTail) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
        hTail_lip hTail_congr m)
    ∧ Rle (integralTerm (f := hTail) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
        hTail_lip hTail_congr m)
      (ofQ (mul (⟨3, 1⟩ : Q) (⟨1, (m + 1) * m⟩ : Q))
        (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm))) := by
  intro m hm
  have hPhi : Rle (Rsub (logN (m + 1 + 1) (by omega)) (logN (m + 1) (by omega)))
      (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)) :=
    Rsub_le_of_le_Radd (Rle_trans (logN_step_upper (m + 1) (by omega))
      (Rle_of_Req (Radd_comm _ _)))
  have hPlo : Rle (ofQ (⟨1, m + 1 + 1⟩ : Q) (Nat.succ_pos _))
      (Rsub (logN (m + 1 + 1) (by omega)) (logN (m + 1) (by omega))) :=
    Rle_Rsub_of_Radd_le (logN_step_lower (m + 1) (by omega))
  have hQhi : Rle (Rsub (logN (m + 3 + 1) (by omega)) (logN (m + 3) (by omega)))
      (ofQ (⟨1, m + 3⟩ : Q) (show 0 < m + 3 by omega)) :=
    Rsub_le_of_le_Radd (Rle_trans (logN_step_upper (m + 3) (by omega))
      (Rle_of_Req (Radd_comm _ _)))
  have hQlo : Rle (ofQ (⟨1, m + 3 + 1⟩ : Q) (Nat.succ_pos _))
      (Rsub (logN (m + 3 + 1) (by omega)) (logN (m + 3) (by omega))) :=
    Rle_Rsub_of_Radd_le (logN_step_lower (m + 3) (by omega))
  constructor
  · -- lower: `−K ≤ 0 ≤ (1/(m+2) − 1/(m+3)) ≤ blockVal ≈ T m`
    refine Rle_trans (Rle_trans (Rneg_le (Rle_zero_of_Rnonneg
      (Rnonneg_ofQ (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm))
        (show (0 : Int) ≤ 3 * 1 by decide)))) (Rle_of_Req Rneg_zero')) ?_
    refine Rle_trans ?_ (Rle_of_Req (Req_symm (integralTerm_hTail m)))
    refine Rle_trans ?_ (Radd_le_add hPlo (Rneg_le hQhi))
    refine Rle_trans (Rle_zero_of_Rnonneg (Rnonneg_ofQ
      (add_den_pos (Nat.succ_pos _) (show 0 < m + 3 by omega))
      (show (0 : Int) ≤ (add (⟨1, m + 1 + 1⟩ : Q) (neg (⟨1, m + 3⟩ : Q))).num from by
        show (0 : Int) ≤ 1 * ((m + 3 : Nat) : Int) + (-1) * ((m + 1 + 1 : Nat) : Int)
        omega))) ?_
    refine Rle_of_Req (Req_symm ?_)
    exact Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ (⟨1, m + 3⟩ : Q)
      (show 0 < m + 3 by omega)))
      (Radd_ofQ_ofQ (Nat.succ_pos _) (show 0 < m + 3 by omega))
  · -- upper: `T m ≈ blockVal ≤ 1/(m+1) − 1/(m+4) ≤ 3/((m+1)m)`
    refine Rle_trans (Rle_of_Req (integralTerm_hTail m)) ?_
    refine Rle_trans (Radd_le_add hPhi (Rneg_le hQlo)) ?_
    refine Rle_trans (Rle_of_Req (Req_trans (Radd_congr (Req_refl _)
      (Rneg_ofQ (⟨1, m + 3 + 1⟩ : Q) (Nat.succ_pos _)))
      (Radd_ofQ_ofQ (Nat.succ_pos m) (Nat.succ_pos _)))) ?_
    refine Rle_ofQ_ofQ (add_den_pos (Nat.succ_pos m) (Nat.succ_pos _))
      (Qmul_den_pos (by decide) (digamma_succ_mul_pos hm)) ?_
    show (add (⟨1, m + 1⟩ : Q) (neg (⟨1, m + 3 + 1⟩ : Q))).num
        * ((mul (⟨3, 1⟩ : Q) (⟨1, (m + 1) * m⟩ : Q)).den : Int)
      ≤ (mul (⟨3, 1⟩ : Q) (⟨1, (m + 1) * m⟩ : Q)).num
        * ((add (⟨1, m + 1⟩ : Q) (neg (⟨1, m + 3 + 1⟩ : Q))).den : Int)
    show ((1 : Int) * ((m + 3 + 1 : Nat) : Int) + (-1) * ((m + 1 : Nat) : Int))
        * ((1 * ((m + 1) * m) : Nat) : Int)
      ≤ ((3 : Int) * 1) * (((m + 1) * (m + 3 + 1) : Nat) : Int)
    have hA : (1 : Int) * ((m + 3 + 1 : Nat) : Int) + (-1) * ((m + 1 : Nat) : Int)
        = (3 : Int) := by push_cast; ring_uor
    rw [hA]
    have hden : (1 * ((m + 1) * m) : Nat) ≤ ((m + 1) * (m + 3 + 1) : Nat) := by
      rw [Nat.one_mul]
      exact Nat.mul_le_mul_left _ (by omega)
    have hcast : ((1 * ((m + 1) * m) : Nat) : Int) ≤ (((m + 1) * (m + 3 + 1) : Nat) : Int) :=
      Int.ofNat_le.mpr hden
    have h3 : (3 : Int) * ((1 * ((m + 1) * m) : Nat) : Int)
        ≤ (3 : Int) * (((m + 1) * (m + 3 + 1) : Nat) : Int) :=
      Int.mul_le_mul_of_nonneg_left hcast (by decide)
    omega

-- ===========================================================================
-- The rate and the evaluation.
-- ===========================================================================

/-- The rate at an arbitrary depth `N` with `2(j+1) ≤ N+1`. -/
private theorem tail_rate_aux (N j : Nat) (hjN : 2 * (j + 1) ≤ N + 1) :
    Rle (Rabs (Rsub (genSum (integralTerm (f := hTail) (L := (⟨2, 1⟩ : Q))
        (by decide) (by decide) hTail_lip hTail_congr) N) (logN 3 (by omega))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  have halg : Req (Rsub (tailF N) (logN 3 (by omega)))
      (Rsub (logN (N + 1) (by omega)) (logN (N + 3) (by omega))) := by
    refine Req_trans (Rsub_congr (Rsub_congr
      (Req_trans (Rsub_congr (Req_refl (logN (N + 1) (by omega))) logN_one)
        (Rsub_zero (logN (N + 1) (by omega))))
      (Req_refl (Rsub (logN (N + 3) (by omega)) (logN 3 (by omega)))))
      (Req_refl (logN 3 (by omega)))) ?_
    -- `(a − (b − 3̂)) − 3̂ ≈ a − b`
    refine Req_trans (Radd_congr (Radd_congr (Req_refl (logN (N + 1) (by omega)))
      (Req_trans (Rneg_Radd (logN (N + 3) (by omega)) (Rneg (logN 3 (by omega))))
        (Radd_congr (Req_refl _) (Rneg_involutive (logN 3 (by omega))))))
      (Req_refl (Rneg (logN 3 (by omega))))) ?_
    refine Req_trans (Radd_assoc (logN (N + 1) (by omega)) _ _) ?_
    refine Radd_congr (Req_refl (logN (N + 1) (by omega))) ?_
    refine Req_trans (Radd_assoc (Rneg (logN (N + 3) (by omega)))
      (logN 3 (by omega)) (Rneg (logN 3 (by omega)))) ?_
    refine Req_trans (Radd_congr (Req_refl (Rneg (logN (N + 3) (by omega))))
      (Radd_neg (logN 3 (by omega)))) ?_
    exact Radd_zero (Rneg (logN (N + 3) (by omega)))
  refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans
    (Rsub_congr (genSum_hTail N) (Req_refl (logN 3 (by omega)))) halg))) ?_
  refine Rabs_le_of_both ?_ ?_
  · refine Rle_trans (Rsub_nonpos_of_Rle
      (logN_mono (by omega) (show N + 1 ≤ N + 3 by omega))) ?_
    exact Rle_zero_of_Rnonneg (Rnonneg_ofQ (Nat.succ_pos j)
      (show (0 : Int) ≤ 1 by decide))
  · refine Rle_trans (Rle_of_Req (Rneg_Rsub _ _)) ?_
    have hb2 : Rle (logN (N + 3) (by omega))
        (Radd (logN (N + 1) (by omega))
          (ofQ (add (⟨1, N + 2⟩ : Q) (⟨1, N + 1⟩ : Q))
            (add_den_pos (show 0 < N + 2 by omega) (Nat.succ_pos N)))) := by
      refine Rle_trans (logN_step_upper (N + 2) (by omega)) ?_
      refine Rle_trans (Radd_le_add
        (Rle_refl (ofQ (⟨1, N + 2⟩ : Q) (show 0 < N + 2 by omega)))
        (logN_step_upper (N + 1) (by omega))) ?_
      refine Rle_of_Req ?_
      refine Req_trans (Req_symm (Radd_assoc (ofQ (⟨1, N + 2⟩ : Q) (show 0 < N + 2 by omega))
        (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)) (logN (N + 1) (by omega)))) ?_
      refine Req_trans (Radd_congr (Radd_ofQ_ofQ (show 0 < N + 2 by omega) (Nat.succ_pos N))
        (Req_refl (logN (N + 1) (by omega)))) ?_
      exact Radd_comm _ _
    refine Rle_trans (Rsub_le_of_le_Radd hb2) ?_
    refine Rle_ofQ_ofQ (add_den_pos (show 0 < N + 2 by omega) (Nat.succ_pos N))
      (Nat.succ_pos j) ?_
    show (add (⟨1, N + 2⟩ : Q) (⟨1, N + 1⟩ : Q)).num * ((j + 1 : Nat) : Int)
      ≤ (1 : Int) * (((N + 2) * (N + 1) : Nat) : Int)
    show ((1 : Int) * ((N + 1 : Nat) : Int) + (1 : Int) * ((N + 2 : Nat) : Int))
        * ((j + 1 : Nat) : Int)
      ≤ (1 : Int) * (((N + 2) * (N + 1) : Nat) : Int)
    have hA : (1 : Int) * ((N + 1 : Nat) : Int) + (1 : Int) * ((N + 2 : Nat) : Int)
        = ((2 * N + 3 : Nat) : Int) := by push_cast; ring_uor
    rw [hA, Int.one_mul, ← Int.natCast_mul]
    refine Int.ofNat_le.mpr ?_
    calc (2 * N + 3) * (j + 1) ≤ (2 * (N + 2)) * (j + 1) :=
          Nat.mul_le_mul_right _ (by omega)
      _ = (N + 2) * (2 * (j + 1)) := by
          rw [Nat.mul_assoc, Nat.mul_left_comm]
      _ ≤ (N + 2) * (N + 1) := Nat.mul_le_mul_left _ hjN

/-- The rate at the improper integral's own schedule (`K = 3`). -/
theorem tail_rate (j : Nat) :
    Rle (Rabs (Rsub (genSum (integralTerm (f := hTail) (L := (⟨2, 1⟩ : Q))
        (by decide) (by decide) hTail_lip hTail_congr)
        (digammaMidx (⟨3, 1⟩ : Q) j)) (logN 3 (by omega))))
      (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)) := by
  refine tail_rate_aux (digammaMidx (⟨3, 1⟩ : Q) j) j ?_
  have hN : digammaMidx (⟨3, 1⟩ : Q) j = 4 * (j + 1) := rfl
  omega

/-- **The improper tail, CONSTRUCTED**: `∫₁^∞ (1/w − 1/(w+2)) dw` as a certified
    half-line integral (`= ∫₂^∞ 2/(x²−1) dx`). -/
def improperTail : Real :=
  improperIntegral1 (L := (⟨2, 1⟩ : Q)) (K := (⟨3, 1⟩ : Q)) (by decide) (by decide)
    hTail_lip hTail_congr (by decide) (by decide) tail_decay

/-- **THE IMPROPER TAIL EVALUATES**: `improperTail ≈ log 3` — the tent's last
    `WeilSlot` ingredient reduced in the kernel. -/
theorem improperTail_eq : Req improperTail (logN 3 (by omega)) :=
  Rlim_eval_real
    (genSum_RReg (integralTerm (f := hTail) (L := (⟨2, 1⟩ : Q)) (by decide) (by decide)
      hTail_lip hTail_congr) (by decide) (by decide) tail_decay)
    (logN 3 (by omega)) (fun j => tail_rate j)

end UOR.Bridge.F1Square.Analysis

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- THE FULL ARCHIMEDEAN TAIL, ASSEMBLED.
-- ===========================================================================

/-- **The tent's full archimedean tail, CONSTRUCTED**: the compact `[1,2]` piece plus the
    (negated) improper part past the support. -/
def tentArchTail : Real :=
  Radd
    (riemannIntegralI (f := tentArch1) (L := (⟨6, 1⟩ : Q)) (by decide) (by decide)
      tentArch1_lip tentArch1_congr (⟨1, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide)
      (by decide))
    (Rneg improperTail)

/-- **THE THIRD EVALUATED WEIL-SLOT COMPONENT**: the tent's archimedean tail equals
    `−(1 + 2·log 2 − 4·(log 3 − log 2)) − log 3` — that is, `−1 − 6·log 2 + 3·log 3`. -/
theorem tentArchTail_eq :
    Req tentArchTail
      (Rsub (Rneg (Radd one (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
        (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
          (Rsub (logN 3 (by omega)) (logN 2 (by omega)))))))
        (logN 3 (by omega))) :=
  Radd_congr tent_arch12 (Rneg_congr improperTail_eq)

end UOR.Bridge.F1Square.Analysis
