/-
F1 square — **the pre-Hilbert layer, brick 27** (`CubicMember.lean`): **THE NONZERO CO-SUPPORT
SUBSPACE MEMBER** — a genuine nonzero `[0,1]`-supported test INSIDE `HatVanishes · 1`: the
co-support subspace is inhabited beyond zero.

The member is the cubic bump `cubeBump = bumpU·(1 − 2·clamp)` (`x(1−x)(1−2x)` on `[0,1]`,
vanishing beyond), realized by the test-algebra combinators alone. Its zeroth moment is
`∫₀¹ x(1−x)(1−2x) = (1/2 − 1/3) − (2/3 − 1/2) = 0`, delivered by the three engine values
(bricks 23/24/26) through the integral's additive-group structure at one shared modulus. The
integrand expands pointwise to the certified test's EXACT shape
`(c − c²) − ((c² + c²) − (c³ + c³))` — the expansion tree is chosen to match the derivation,
so no add/neg reshuffle (which the reindexing Bishop `Radd` does not admit at the seq level)
is ever needed.

- `cubeBump_supp` — unit support (the `bumpU` factor kills every window point).
- `mellinMoment_cubeBump` — the zeroth moment vanishes EXACTLY.
- **`cubeBump_hatVanishes`** — through the brick-22 moment bridge, `cubeBump` IS in the
  co-support class at `K = 1`.
- **`cubeBump_value_quarter`/`cubeBump_apart`** — `f(1/4) ≈ 3/32` and `Pos (f(1/4))`: the
  member is APART from the zero function at a witnessed point.

With brick 25 (`bumpU ∉ HatVanishes · 1`) the picture is complete: the transform-side
vanishing condition cuts out a subspace that is proper AND contains a certified nonzero
member — the co-support geometry is genuinely realized on constructed objects.

HONEST SCOPE. One nonzero member at `K = 1` (one vanishing transform value); deeper `K`
(more vanishing moments) needs higher-degree evaluations; no continuous parameter, no
band-indexed tie to `bandProj`, no coupling — positivity on the co-support class is step 4
and is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.CoSupportMember
import Foundations.F1.Square.MomentCube

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The member and the expansion scaffold.
-- ===========================================================================

/-- **The cubic bump**: `x(1−x)(1−2x)` on `[0,1]`, vanishing beyond. -/
def cubeBump : L2Test :=
  L2Test.mul bumpU (L2Test.sub oneTest (L2Test.add clampTest clampTest))

/-- The square test `clamp²` (the brick-24 integrand as a test). -/
def sqT : L2Test := L2Test.mul clampTest clampTest

/-- The cube test `clamp³` (the brick-26 integrand as a test). -/
def cubeT : L2Test := L2Test.mul sqT clampTest

/-- The head block `c − c²` of the expansion. -/
def gHead : L2Test := L2Test.add clampTest (L2Test.neg sqT)

/-- The inner block `(c² + c²) − (c³ + c³)` of the expansion. -/
def gIn : L2Test :=
  L2Test.add (L2Test.add sqT sqT) (L2Test.neg (L2Test.add cubeT cubeT))

/-- The expanded integrand `(c − c²) − ((c² + c²) − (c³ + c³)) = c − 3c² + 2c³` as a test —
    the tree shape EXACTLY matching the pointwise derivation. -/
def gTot : L2Test := L2Test.add gHead (L2Test.neg gIn)

/-- **The cubic bump is `[0,1]`-supported** — the `bumpU` factor vanishes at every window
    point. -/
theorem cubeBump_supp : UnitSupported cubeBump := by
  intro m x h0 h1
  refine Req_trans (Rmul_congr (bumpU_supp m x h0 h1) (Req_refl _)) ?_
  exact Req_trans (Rmul_comm zero _) (Rmul_zero _)

-- ===========================================================================
-- Certificates at the shared modulus `gTot.L`.
-- ===========================================================================

private theorem hcl_T : ∀ x y, Rle (Rabs (Rsub (clamp01 x) (clamp01 y)))
    (Rmul (ofQ gTot.L gTot.hLd) (Rabs (Rsub x y))) :=
  lip_weaken clampTest.hLd gTot.hLd (by decide) clampTest.hlip

private theorem hfc_cl : ∀ x y : Real, Req x y → Req (clamp01 x) (clamp01 y) :=
  fun _ _ h => clamp01_congr h

private theorem hsq_T : ∀ x y, Rle (Rabs (Rsub (clampSq x) (clampSq y)))
    (Rmul (ofQ gTot.L gTot.hLd) (Rabs (Rsub x y))) :=
  lip_weaken sqT.hLd gTot.hLd (by decide) sqT.hlip

private theorem hfc_sq : ∀ x y : Real, Req x y → Req (clampSq x) (clampSq y) :=
  fun _ _ h => Rmul_congr (clamp01_congr h) (clamp01_congr h)

private theorem hnsq_T : ∀ x y, Rle (Rabs (Rsub (Rneg (clampSq x)) (Rneg (clampSq y))))
    (Rmul (ofQ gTot.L gTot.hLd) (Rabs (Rsub x y))) :=
  lip_neg hsq_T

private theorem hfc_nsq : ∀ x y : Real, Req x y →
    Req (Rneg (clampSq x)) (Rneg (clampSq y)) :=
  congr_neg hfc_sq

private theorem hcube_T : ∀ x y, Rle (Rabs (Rsub (clampCube x) (clampCube y)))
    (Rmul (ofQ gTot.L gTot.hLd) (Rabs (Rsub x y))) :=
  lip_weaken cubeT.hLd gTot.hLd (by decide) cubeT.hlip

private theorem hfc_cube : ∀ x y : Real, Req x y → Req (clampCube x) (clampCube y) :=
  fun x y h => Rmul_congr (hfc_sq x y h) (clamp01_congr h)

private theorem hsq2_T : ∀ x y, Rle (Rabs (Rsub
      (Radd (clampSq x) (clampSq x)) (Radd (clampSq y) (clampSq y))))
    (Rmul (ofQ gTot.L gTot.hLd) (Rabs (Rsub x y))) :=
  lip_weaken (L2Test.add sqT sqT).hLd gTot.hLd (by decide) (L2Test.add sqT sqT).hlip

private theorem hfc_sq2 : ∀ x y : Real, Req x y →
    Req (Radd (clampSq x) (clampSq x)) (Radd (clampSq y) (clampSq y)) :=
  fun x y h => Radd_congr (hfc_sq x y h) (hfc_sq x y h)

private theorem hcube2_T : ∀ x y, Rle (Rabs (Rsub
      (Radd (clampCube x) (clampCube x)) (Radd (clampCube y) (clampCube y))))
    (Rmul (ofQ gTot.L gTot.hLd) (Rabs (Rsub x y))) :=
  lip_weaken (L2Test.add cubeT cubeT).hLd gTot.hLd (by decide) (L2Test.add cubeT cubeT).hlip

private theorem hfc_cube2 : ∀ x y : Real, Req x y →
    Req (Radd (clampCube x) (clampCube x)) (Radd (clampCube y) (clampCube y)) :=
  fun x y h => Radd_congr (hfc_cube x y h) (hfc_cube x y h)

private theorem hncube2_T : ∀ x y, Rle (Rabs (Rsub
      (Rneg (Radd (clampCube x) (clampCube x))) (Rneg (Radd (clampCube y) (clampCube y)))))
    (Rmul (ofQ gTot.L gTot.hLd) (Rabs (Rsub x y))) :=
  lip_neg hcube2_T

private theorem hfc_ncube2 : ∀ x y : Real, Req x y →
    Req (Rneg (Radd (clampCube x) (clampCube x)))
      (Rneg (Radd (clampCube y) (clampCube y))) :=
  congr_neg hfc_cube2

private theorem hHead_T : ∀ x y, Rle (Rabs (Rsub
      (Radd (clamp01 x) (Rneg (clampSq x))) (Radd (clamp01 y) (Rneg (clampSq y)))))
    (Rmul (ofQ gTot.L gTot.hLd) (Rabs (Rsub x y))) :=
  lip_weaken gHead.hLd gTot.hLd (by decide) gHead.hlip

private theorem hfc_Head : ∀ x y : Real, Req x y →
    Req (Radd (clamp01 x) (Rneg (clampSq x))) (Radd (clamp01 y) (Rneg (clampSq y))) :=
  fun x y h => Radd_congr (clamp01_congr h) (hfc_nsq x y h)

private theorem hIn_T : ∀ x y, Rle (Rabs (Rsub
      (Radd (Radd (clampSq x) (clampSq x)) (Rneg (Radd (clampCube x) (clampCube x))))
      (Radd (Radd (clampSq y) (clampSq y)) (Rneg (Radd (clampCube y) (clampCube y))))))
    (Rmul (ofQ gTot.L gTot.hLd) (Rabs (Rsub x y))) :=
  lip_weaken gIn.hLd gTot.hLd (by decide) gIn.hlip

private theorem hfc_In : ∀ x y : Real, Req x y →
    Req (Radd (Radd (clampSq x) (clampSq x)) (Rneg (Radd (clampCube x) (clampCube x))))
      (Radd (Radd (clampSq y) (clampSq y)) (Rneg (Radd (clampCube y) (clampCube y)))) :=
  fun x y h => Radd_congr (hfc_sq2 x y h) (hfc_ncube2 x y h)

private theorem hnIn_T : ∀ x y, Rle (Rabs (Rsub
      (Rneg (Radd (Radd (clampSq x) (clampSq x)) (Rneg (Radd (clampCube x) (clampCube x)))))
      (Rneg (Radd (Radd (clampSq y) (clampSq y))
        (Rneg (Radd (clampCube y) (clampCube y)))))))
    (Rmul (ofQ gTot.L gTot.hLd) (Rabs (Rsub x y))) :=
  lip_neg hIn_T

private theorem hfc_nIn : ∀ x y : Real, Req x y →
    Req (Rneg (Radd (Radd (clampSq x) (clampSq x))
        (Rneg (Radd (clampCube x) (clampCube x)))))
      (Rneg (Radd (Radd (clampSq y) (clampSq y))
        (Rneg (Radd (clampCube y) (clampCube y))))) :=
  congr_neg hfc_In

private theorem hTot_T : ∀ x y, Rle (Rabs (Rsub
      (Radd (Radd (clamp01 x) (Rneg (clampSq x)))
        (Rneg (Radd (Radd (clampSq x) (clampSq x))
          (Rneg (Radd (clampCube x) (clampCube x))))))
      (Radd (Radd (clamp01 y) (Rneg (clampSq y)))
        (Rneg (Radd (Radd (clampSq y) (clampSq y))
          (Rneg (Radd (clampCube y) (clampCube y))))))))
    (Rmul (ofQ gTot.L gTot.hLd) (Rabs (Rsub x y))) :=
  gTot.hlip

private theorem hfc_Tot : ∀ x y : Real, Req x y →
    Req (Radd (Radd (clamp01 x) (Rneg (clampSq x)))
        (Rneg (Radd (Radd (clampSq x) (clampSq x))
          (Rneg (Radd (clampCube x) (clampCube x))))))
      (Radd (Radd (clamp01 y) (Rneg (clampSq y)))
        (Rneg (Radd (Radd (clampSq y) (clampSq y))
          (Rneg (Radd (clampCube y) (clampCube y)))))) :=
  fun x y h => Radd_congr (hfc_Head x y h) (hfc_nIn x y h)

-- ===========================================================================
-- The component values at the shared modulus.
-- ===========================================================================

private theorem vcl : Req (riemannIntegral gTot.hLd gTot.hLn hcl_T hfc_cl) half :=
  Req_trans (riemannIntegral_congr_unit (g := fun x => x) gTot.hLd gTot.hLn
      hcl_T hfc_cl (lip_id_ge gTot.hLd (by decide)) congr_id
      (fun _ h0 h1 => clamp01_inert h0 h1))
    (riemannIntegral_id_gen gTot.hLd gTot.hLn (lip_id_ge gTot.hLd (by decide)) congr_id)

private theorem vsq : Req (riemannIntegral gTot.hLd gTot.hLn hsq_T hfc_sq)
    (ofQ (⟨1, 3⟩ : Q) (by decide)) :=
  riemannIntegral_clampSq_gen gTot.hLd gTot.hLn hsq_T hfc_sq

private theorem vnsq : Req (riemannIntegral gTot.hLd gTot.hLn hnsq_T hfc_nsq)
    (Rneg (ofQ (⟨1, 3⟩ : Q) (by decide))) :=
  Req_trans (riemannIntegral_neg gTot.hLd gTot.hLn hsq_T hfc_sq hnsq_T hfc_nsq)
    (Rneg_congr vsq)

private theorem vcube : Req (riemannIntegral gTot.hLd gTot.hLn hcube_T hfc_cube)
    (ofQ (⟨1, 4⟩ : Q) (by decide)) :=
  riemannIntegral_clampCube_gen gTot.hLd gTot.hLn hcube_T hfc_cube

private theorem vsq2 : Req (riemannIntegral gTot.hLd gTot.hLn hsq2_T hfc_sq2)
    (Radd (ofQ (⟨1, 3⟩ : Q) (by decide)) (ofQ (⟨1, 3⟩ : Q) (by decide))) :=
  Req_trans (riemannIntegral_add gTot.hLd gTot.hLn hsq_T hfc_sq hsq_T hfc_sq
    hsq2_T hfc_sq2) (Radd_congr vsq vsq)

private theorem vcube2 : Req (riemannIntegral gTot.hLd gTot.hLn hcube2_T hfc_cube2)
    (Radd (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide))) :=
  Req_trans (riemannIntegral_add gTot.hLd gTot.hLn hcube_T hfc_cube hcube_T hfc_cube
    hcube2_T hfc_cube2) (Radd_congr vcube vcube)

private theorem vncube2 : Req (riemannIntegral gTot.hLd gTot.hLn hncube2_T hfc_ncube2)
    (Rneg (Radd (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide)))) :=
  Req_trans (riemannIntegral_neg gTot.hLd gTot.hLn hcube2_T hfc_cube2 hncube2_T hfc_ncube2)
    (Rneg_congr vcube2)

private theorem vHead : Req (riemannIntegral gTot.hLd gTot.hLn hHead_T hfc_Head)
    (Radd half (Rneg (ofQ (⟨1, 3⟩ : Q) (by decide)))) :=
  Req_trans (riemannIntegral_add gTot.hLd gTot.hLn hcl_T hfc_cl hnsq_T hfc_nsq
    hHead_T hfc_Head) (Radd_congr vcl vnsq)

private theorem vIn : Req (riemannIntegral gTot.hLd gTot.hLn hIn_T hfc_In)
    (Radd (Radd (ofQ (⟨1, 3⟩ : Q) (by decide)) (ofQ (⟨1, 3⟩ : Q) (by decide)))
      (Rneg (Radd (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide))))) :=
  Req_trans (riemannIntegral_add gTot.hLd gTot.hLn hsq2_T hfc_sq2 hncube2_T hfc_ncube2
    hIn_T hfc_In) (Radd_congr vsq2 vncube2)

private theorem vnIn : Req (riemannIntegral gTot.hLd gTot.hLn hnIn_T hfc_nIn)
    (Rneg (Radd (Radd (ofQ (⟨1, 3⟩ : Q) (by decide)) (ofQ (⟨1, 3⟩ : Q) (by decide)))
      (Rneg (Radd (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide)))))) :=
  Req_trans (riemannIntegral_neg gTot.hLd gTot.hLn hIn_T hfc_In hnIn_T hfc_nIn)
    (Rneg_congr vIn)


/-- The expanded integrand's integral vanishes: `(1/2 − 1/3) − (2/3 − 1/2) ≈ 0`. -/
private theorem vTot : Req (riemannIntegral gTot.hLd gTot.hLn hTot_T hfc_Tot) zero := by
  refine Req_trans (riemannIntegral_add gTot.hLd gTot.hLn hHead_T hfc_Head hnIn_T hfc_nIn
    hTot_T hfc_Tot) ?_
  refine Req_trans (Radd_congr vHead vnIn) ?_
  -- collapse the rational tree to `0`
  have h33 : Req (Radd (ofQ (⟨1, 3⟩ : Q) (by decide)) (ofQ (⟨1, 3⟩ : Q) (by decide)))
      (ofQ (add (⟨1, 3⟩ : Q) (⟨1, 3⟩ : Q)) (add_den_pos (by decide) (by decide))) :=
    Radd_ofQ_ofQ (by decide) (by decide)
  have h44 : Req (Radd (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide)))
      (ofQ (add (⟨1, 4⟩ : Q) (⟨1, 4⟩ : Q)) (add_den_pos (by decide) (by decide))) :=
    Radd_ofQ_ofQ (by decide) (by decide)
  have hHv : Req (Radd half (Rneg (ofQ (⟨1, 3⟩ : Q) (by decide))))
      (ofQ (add (⟨1, 2⟩ : Q) (neg (⟨1, 3⟩ : Q))) (add_den_pos (by decide) (by decide))) := by
    refine Req_trans (Radd_congr (Req_refl half) (Rneg_ofQ (⟨1, 3⟩ : Q) (by decide))) ?_
    exact Radd_ofQ_ofQ (by decide) (by decide)
  have hIv : Req (Rneg (Radd (Radd (ofQ (⟨1, 3⟩ : Q) (by decide))
      (ofQ (⟨1, 3⟩ : Q) (by decide)))
      (Rneg (Radd (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨1, 4⟩ : Q) (by decide))))))
      (ofQ (neg (add (add (⟨1, 3⟩ : Q) (⟨1, 3⟩ : Q)) (neg (add (⟨1, 4⟩ : Q) (⟨1, 4⟩ : Q)))))
        (add_den_pos (add_den_pos (by decide) (by decide))
          (add_den_pos (by decide) (by decide)))) := by
    refine Req_trans (Rneg_congr (Radd_congr h33
      (Req_trans (Rneg_congr h44) (Rneg_ofQ (add (⟨1, 4⟩ : Q) (⟨1, 4⟩ : Q))
        (add_den_pos (by decide) (by decide)))))) ?_
    refine Req_trans (Rneg_congr (Radd_ofQ_ofQ (add_den_pos (by decide) (by decide))
      (by decide))) ?_
    exact Rneg_ofQ (add (add (⟨1, 3⟩ : Q) (⟨1, 3⟩ : Q)) (neg (add (⟨1, 4⟩ : Q) (⟨1, 4⟩ : Q))))
      (add_den_pos (add_den_pos (by decide) (by decide))
        (add_den_pos (by decide) (by decide)))
  refine Req_trans (Radd_congr hHv hIv) ?_
  refine Req_trans (Radd_ofQ_ofQ (add_den_pos (by decide) (by decide)) (by decide)) ?_
  exact Req_of_seq_Qeq (fun _ => by
    show Qeq (add (add (⟨1, 2⟩ : Q) (neg (⟨1, 3⟩ : Q)))
      (neg (add (add (⟨1, 3⟩ : Q) (⟨1, 3⟩ : Q)) (neg (add (⟨1, 4⟩ : Q) (⟨1, 4⟩ : Q))))))
      (⟨0, 1⟩ : Q)
    decide)

-- ===========================================================================
-- The vanishing moment and subspace membership.
-- ===========================================================================


/-- **The cubic bump's zeroth moment vanishes**: `∫₀¹ x(1−x)(1−2x) dx ≈ 0` — the integrand
    expands pointwise into the certified tree and the engine values cancel. -/
theorem mellinMoment_cubeBump : Req (mellinMoment cubeBump 0) zero := by
  have hdist : ∀ x, Req (Rmul (cubeBump.f x) ((powTest 0).f x))
      (Radd (Radd (clamp01 x) (Rneg (clampSq x)))
        (Rneg (Radd (Radd (clampSq x) (clampSq x))
          (Rneg (Radd (clampCube x) (clampCube x)))))) := by
    intro x
    refine Req_trans (Rmul_one _) ?_
    have hin : Req (Rmul (clamp01 x) (Rsub one (clamp01 x)))
        (Radd (clamp01 x) (Rneg (clampSq x))) :=
      Req_trans (Rmul_sub_distrib (clamp01 x) one (clamp01 x))
        (Radd_congr (Rmul_one (clamp01 x)) (Req_refl _))
    refine Req_trans (Rmul_congr hin (Req_refl _)) ?_
    refine Req_trans (Rmul_sub_distrib (Radd (clamp01 x) (Rneg (clampSq x))) one
      (Radd (clamp01 x) (clamp01 x))) ?_
    refine Radd_congr (Rmul_one _) (Rneg_congr ?_)
    refine Req_trans (Rmul_distrib_right (clamp01 x) (Rneg (clampSq x))
      (Radd (clamp01 x) (clamp01 x))) ?_
    exact Radd_congr
      (Rmul_distrib (clamp01 x) (clamp01 x) (clamp01 x))
      (Req_trans (Rmul_neg_left (clampSq x) (Radd (clamp01 x) (clamp01 x)))
        (Rneg_congr (Rmul_distrib (clampSq x) (clamp01 x) (clamp01 x))))
  have hlipT : ∀ x y, Rle (Rabs (Rsub
        (Radd (Radd (clamp01 x) (Rneg (clampSq x)))
          (Rneg (Radd (Radd (clampSq x) (clampSq x))
            (Rneg (Radd (clampCube x) (clampCube x))))))
        (Radd (Radd (clamp01 y) (Rneg (clampSq y)))
          (Rneg (Radd (Radd (clampSq y) (clampSq y))
            (Rneg (Radd (clampCube y) (clampCube y))))))))
      (Rmul (ofQ (l2L cubeBump (powTest 0)) (l2L_den cubeBump (powTest 0)))
        (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x))
      (Req_symm (hdist y))))) (l2lip cubeBump (powTest 0) x y)
  refine Req_trans (riemannIntegral_congr
    (g := fun x => Radd (Radd (clamp01 x) (Rneg (clampSq x)))
      (Rneg (Radd (Radd (clampSq x) (clampSq x))
        (Rneg (Radd (clampCube x) (clampCube x))))))
    (l2L_den cubeBump (powTest 0)) (l2L_num cubeBump (powTest 0))
    (l2lip cubeBump (powTest 0)) (l2fc cubeBump (powTest 0)) hlipT hfc_Tot hdist) ?_
  refine Req_trans (riemannIntegral_certif_irrel (l2L_den cubeBump (powTest 0))
    (l2L_num cubeBump (powTest 0)) hlipT hfc_Tot gTot.hLd gTot.hLn hTot_T hfc_Tot) ?_
  exact vTot

/-- **THE NONZERO CO-SUPPORT SUBSPACE MEMBER**: the cubic bump is in `HatVanishes · 1` — its
    transform vanishes at the integer point `0`. -/
theorem cubeBump_hatVanishes :
    HatVanishes cubeBump 1 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp cubeBump cubeBump_supp) :=
  hatVanishes_of_moments cubeBump 1 cubeBump_supp (fun n hn => by
    cases n with
    | zero => exact mellinMoment_cubeBump
    | succ k => exact absurd hn (by omega))

-- ===========================================================================
-- Apartness from zero.
-- ===========================================================================



/-- **The member is not the zero function**: `cubeBump(1/4) ≈ 3/32`. -/
theorem cubeBump_value_quarter :
    Req (cubeBump.f (ofQ (⟨1, 4⟩ : Q) (by decide))) (ofQ (⟨3, 32⟩ : Q) (by decide)) := by
  have hc : Req (clamp01 (ofQ (⟨1, 4⟩ : Q) (by decide))) (ofQ (⟨1, 4⟩ : Q) (by decide)) :=
    clamp01_ofQ (by decide) (by decide) (by decide)
  have hA : Req (Radd one (Rneg (clamp01 (ofQ (⟨1, 4⟩ : Q) (by decide)))))
      (ofQ (add (⟨1, 1⟩ : Q) (neg (⟨1, 4⟩ : Q))) (add_den_pos (by decide) (by decide))) := by
    refine Req_trans (Radd_congr (Req_refl one)
      (Req_trans (Rneg_congr hc) (Rneg_ofQ (⟨1, 4⟩ : Q) (by decide)))) ?_
    exact Radd_ofQ_ofQ (by decide) (by decide)
  have hB : Req (Radd one (Rneg (Radd (clamp01 (ofQ (⟨1, 4⟩ : Q) (by decide)))
      (clamp01 (ofQ (⟨1, 4⟩ : Q) (by decide))))))
      (ofQ (add (⟨1, 1⟩ : Q) (neg (add (⟨1, 4⟩ : Q) (⟨1, 4⟩ : Q))))
        (add_den_pos (by decide) (add_den_pos (by decide) (by decide)))) := by
    refine Req_trans (Radd_congr (Req_refl one) (Req_trans (Rneg_congr
      (Req_trans (Radd_congr hc hc) (Radd_ofQ_ofQ (by decide) (by decide))))
      (Rneg_ofQ (add (⟨1, 4⟩ : Q) (⟨1, 4⟩ : Q)) (add_den_pos (by decide) (by decide))))) ?_
    exact Radd_ofQ_ofQ (by decide) (by decide)
  refine Req_trans (Rmul_congr (Rmul_congr hc hA) hB) ?_
  refine Req_trans (Rmul_congr (Rmul_ofQ_ofQ (by decide)
    (add_den_pos (by decide) (by decide))) (Req_refl _)) ?_
  refine Req_trans (Rmul_ofQ_ofQ (Qmul_den_pos (by decide)
    (add_den_pos (by decide) (by decide)))
    (add_den_pos (by decide) (by decide))) ?_
  exact Req_of_seq_Qeq (fun _ => by
    show Qeq (mul (mul (⟨1, 4⟩ : Q) (add (⟨1, 1⟩ : Q) (neg (⟨1, 4⟩ : Q))))
      (add (⟨1, 1⟩ : Q) (neg (add (⟨1, 4⟩ : Q) (⟨1, 4⟩ : Q))))) (⟨3, 32⟩ : Q)
    decide)

/-- **Apartness**: `Pos (cubeBump(1/4))` — the co-support member is strictly apart from the
    zero function at a witnessed point. With `cubeBump_hatVanishes`, the subspace
    `HatVanishes · 1` contains a genuine NONZERO element. -/
theorem cubeBump_apart : Pos (cubeBump.f (ofQ (⟨1, 4⟩ : Q) (by decide))) :=
  Pos_congr (Req_symm cubeBump_value_quarter) ⟨11, by decide⟩

end Multiplicity.UOR.Bridge.F1Square.Square
