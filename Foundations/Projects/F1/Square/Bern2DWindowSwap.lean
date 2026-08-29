/-
F1 square — **the WINDOWED general Fubini swap** (`Bern2DWindowSwap.lean`), the transform bridge,
Wall 3. Generalizes `bern2D_general_swap` from the unit square `[0,1]²` to ARBITRARY rational windows
`[a, a+w] × [c, c+v]`: for a jointly-Lipschitz `F`,

    `∫_{x∈[a,a+w]} ∫_{y∈[c,c+v]} F(x,y)  =  ∫_{y∈[c,c+v]} ∫_{x∈[a,a+w]} F(x,y)`.

The proof is a pure AFFINE REPARAMETRIZATION reducing to the already-proven `[0,1]²` swap. The pulled-back
integrand `G x' y' := F(a+w·x', c+v·y')` is jointly-Lipschitz on `[0,1]²` with moduli `w·Lx`, `v·Ly`;
`riemannIntegralI_reparam` turns each windowed interval integral into a width-scaled unit-window integral,
and the outer/inner scalings collect into the common factor `w·v` on both sides. `bern2D_general_swap`
at `G` supplies the unit-square equality, and the shared `w·v` factor is stripped.

The reusable analysis bricks — `affineMap_comp` (composition of two affine pullbacks is one affine
pullback) and `riemannIntegralI_reparam` (`∫_a^{a+w} f = w·∫₀¹ f(a+w··)`) — are broadly useful and are
made public here.

WHY (the transform bridge, Wall 3). The Mellin convolution theorem's Fubini swap must hold on the
half-line window geometry, not only the unit square; this brick lifts the swap to any rational window by
change of variables, inheriting everything from `bern2D_general_swap`. No new limit is taken.

HONEST SCOPE. The windowed generalization of the general Fubini swap to arbitrary rational windows via
affine reparametrization — an analysis theorem inheriting from `bern2D_general_swap`. No new limit, no
positivity, no determinacy, no crux. Step 4 (band-coupling positivity) is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.Bern2DGeneralSwap
import Foundations.F1.Square.IntervalMinorant
import Foundations.F1.Square.ParamIntegral

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Composition of two affine pullbacks is one affine pullback**:
    `a + w·(c + v·x) = (a + w·c) + (w·v)·x`. Distribute `w` over `c + v·x`, fold the constant part into
    `a + w·c` and the linear part into `(w·v)·x`. Pure `Radd`/`Rmul` distribution + `ofQ` arithmetic. -/
theorem affineMap_comp (a w c v : Q) (ha : 0 < a.den) (hw : 0 < w.den)
    (hc : 0 < c.den) (hv : 0 < v.den) (x : Real) :
    Req (affineMap a w ha hw (affineMap c v hc hv x))
        (affineMap (add a (mul w c)) (mul w v)
          (add_den_pos ha (Qmul_den_pos hw hc)) (Qmul_den_pos hw hv) x) := by
  show Req (Radd (ofQ a ha) (Rmul (ofQ w hw) (Radd (ofQ c hc) (Rmul (ofQ v hv) x))))
       (Radd (ofQ (add a (mul w c)) (add_den_pos ha (Qmul_den_pos hw hc)))
         (Rmul (ofQ (mul w v) (Qmul_den_pos hw hv)) x))
  refine Req_trans (Radd_congr (Req_refl _)
    (Rmul_distrib (ofQ w hw) (ofQ c hc) (Rmul (ofQ v hv) x))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Rmul_ofQ_ofQ hw hc)
    (Req_trans (Req_symm (Rmul_assoc (ofQ w hw) (ofQ v hv) x))
      (Rmul_congr (Rmul_ofQ_ofQ hw hv) (Req_refl x))))) ?_
  refine Req_trans (Req_symm (Radd_assoc (ofQ a ha)
    (ofQ (mul w c) (Qmul_den_pos hw hc)) (Rmul (ofQ (mul w v) (Qmul_den_pos hw hv)) x))) ?_
  exact Radd_congr (Radd_ofQ_ofQ ha (Qmul_den_pos hw hc)) (Req_refl _)

/-- **The interval integral pulls back to a width-scaled unit-window integral**:
    `∫_a^{a+w} f = w · ∫₀¹ (f ∘ (a + w··))`. Immediate from the definition of `riemannIntegralI`
    (`= w · riemannIntegral(f∘affineMap a w)`) and `riemannIntegralI_unit` (the unit window of the
    pulled-back integrand is its plain `riemannIntegral`). The pulled-back integrand carries modulus
    `L·w` (slope-`w` chain rule, `affine_lip`). Reusable reparametrization brick. -/
theorem riemannIntegralI_reparam {f : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (a w : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Req (riemannIntegralI hLd hLn hlip hfc a w ha hw hwn)
        (Rmul (ofQ w hw)
          (riemannIntegralI (f := fun x => f (affineMap a w ha hw x)) (L := mul L w)
            (Qmul_den_pos hLd hw) (Int.mul_nonneg hLn hwn)
            (affine_lip hLd hLn hlip a w ha hw hwn)
            (fun x y h => hfc _ _ (affineMap_congr a w ha hw h))
            (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))) :=
  Req_symm (Rmul_congr (Req_refl (ofQ w hw))
    (riemannIntegralI_unit (Qmul_den_pos hLd hw) (Int.mul_nonneg hLn hwn)
      (affine_lip hLd hLn hlip a w ha hw hwn)
      (fun x y h => hfc _ _ (affineMap_congr a w ha hw h))))

/-- **A non-negative-`ℚ`-scalar multiple of a Lipschitz map is Lipschitz** at any modulus `L'` with
    `q·Lg ≤ L'`: `|q·g x − q·g y| = q·|g x − g y| ≤ q·Lg·|x−y| ≤ L'·|x−y|`. Reusable brick for the
    output-scaling step. -/
theorem smul_lip_ofQ {g : Real → Real} {Lg : Q} (hLgd : 0 < Lg.den)
    (hlipg : ∀ x y, Rle (Rabs (Rsub (g x) (g y))) (Rmul (ofQ Lg hLgd) (Rabs (Rsub x y))))
    (q : Q) (hq : 0 < q.den) (hqn : 0 ≤ q.num)
    {L' : Q} (hL'd : 0 < L'.den) (hle : Qle (mul q Lg) L') :
    ∀ x y, Rle (Rabs (Rsub (Rmul (ofQ q hq) (g x)) (Rmul (ofQ q hq) (g y))))
      (Rmul (ofQ L' hL'd) (Rabs (Rsub x y))) := by
  intro x y
  have e2 : Req (Rabs (Rsub (Rmul (ofQ q hq) (g x)) (Rmul (ofQ q hq) (g y))))
      (Rmul (ofQ q hq) (Rabs (Rsub (g x) (g y)))) :=
    Req_trans (Rabs_congr (Req_symm (Rmul_sub_distrib (ofQ q hq) (g x) (g y))))
      (Rabs_Rmul_ofQ_nonneg hq hqn (Rsub (g x) (g y)))
  have step : Rle (Rmul (ofQ q hq) (Rabs (Rsub (g x) (g y))))
      (Rmul (ofQ q hq) (Rmul (ofQ Lg hLgd) (Rabs (Rsub x y)))) :=
    Rmul_le_Rmul_left (Rnonneg_ofQ hq hqn) (hlipg x y)
  have e3 : Req (Rmul (ofQ q hq) (Rmul (ofQ Lg hLgd) (Rabs (Rsub x y))))
      (Rmul (ofQ (mul q Lg) (Qmul_den_pos hq hLgd)) (Rabs (Rsub x y))) :=
    Req_trans (Req_symm (Rmul_assoc _ _ _)) (Rmul_congr (Rmul_ofQ_ofQ hq hLgd) (Req_refl _))
  have e4 : Rle (Rmul (ofQ (mul q Lg) (Qmul_den_pos hq hLgd)) (Rabs (Rsub x y)))
      (Rmul (ofQ L' hL'd) (Rabs (Rsub x y))) :=
    Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rle_ofQ_ofQ (Qmul_den_pos hq hLgd) hL'd hle)
  exact Rle_trans (Rle_of_Req e2) (Rle_trans step (Rle_trans (Rle_of_Req e3) e4))

/-- **KEY REPARAM identity** — the value of the parametric window integral at an affinely-reparametrized
    outer point is `v` times the unit-window inner integral of the fully-pulled-back integrand:

        `(∫_{[c,c+v]} F(·, y) dy)|_{x = a+w·x'}  =  v · ∫₀¹ F(a+w·x', c+v·y') dy'`.

    Immediate from `riemannIntegralI_reparam` applied to the inner integral `F(a+w·x', ·)` over the
    window `[c, c+v]` (the outer `paramIntegralTest`'s `.f` unfolds definitionally to that interval
    integral). Reusable bridge between the windowed inner integral and the unit-square integrand
    `G x' y' := F(a+w·x', c+v·y')`. -/
theorem paramIntegralTest_reparam
    (F : Real → Real → Real) (Ly Lx B : Q)
    (hLyd : 0 < Ly.den) (hLyn : 0 ≤ Ly.num)
    (hLxd : 0 < Lx.den) (hLxn : 0 ≤ Lx.num)
    (hBd : 0 < B.den) (hBn : 0 ≤ B.num)
    (hlipY : ∀ x y y', Rle (Rabs (Rsub (F x y) (F x y'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub y y'))))
    (hfcY : ∀ x y y', Req y y' → Req (F x y) (F x y'))
    (hlipX : ∀ x x' y, Rle (Rabs (Rsub (F x y) (F x' y))) (Rmul (ofQ Lx hLxd) (Rabs (Rsub x x'))))
    (hfcX : ∀ x x' y, Req x x' → Req (F x y) (F x' y))
    (a w c v : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hc : 0 < c.den) (hv : 0 < v.den) (hvn : 0 ≤ v.num)
    (hbdF : ∀ x u, Rle zero u → Rle u one →
      Rle (Rabs (F x (affineMap c v hc hv u))) (ofQ B hBd)) (x' : Real) :
    Req
      ((paramIntegralTest F Ly Lx B hLyd hLyn hLxd hLxn hBd hBn hlipY hfcY hlipX hfcX
          c v hc hv hvn hbdF).f (affineMap a w ha hw x'))
      (Rmul (ofQ v hv)
        (riemannIntegralI
          (f := fun y' => F (affineMap a w ha hw x') (affineMap c v hc hv y')) (L := mul Ly v)
          (Qmul_den_pos hLyd hv) (Int.mul_nonneg hLyn hvn)
          (affine_lip hLyd hLyn (hlipY (affineMap a w ha hw x')) c v hc hv hvn)
          (fun p q h => hfcY (affineMap a w ha hw x') (affineMap c v hc hv p) (affineMap c v hc hv q)
            (affineMap_congr c v hc hv h))
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))) :=
  riemannIntegralI_reparam hLyd hLyn (hlipY (affineMap a w ha hw x'))
    (hfcY (affineMap a w ha hw x')) c v hc hv hvn

/-- **The fully-pulled-back unit-square parametric test** `G x' y' = F(a+w·x', c+v·y')`, packaged as a
    `paramIntegralTest` on the unit square with moduli `w·Lx` (parameter) and `v·Ly` (inner). Each
    Lipschitz/congruence field is the affine-chain-rule (`affine_lip`) of the corresponding field of
    `F`; the bound is inherited pointwise. This is the object the windowed swap reduces to. -/
def windowG (F : Real → Real → Real) (Ly Lx BF : Q)
    (hLyd : 0 < Ly.den) (hLyn : 0 ≤ Ly.num) (hLxd : 0 < Lx.den) (hLxn : 0 ≤ Lx.num)
    (hBFd : 0 < BF.den) (hBFn : 0 ≤ BF.num)
    (hlipY : ∀ x y y', Rle (Rabs (Rsub (F x y) (F x y'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub y y'))))
    (hfcY : ∀ x y y', Req y y' → Req (F x y) (F x y'))
    (hlipX : ∀ x x' y, Rle (Rabs (Rsub (F x y) (F x' y))) (Rmul (ofQ Lx hLxd) (Rabs (Rsub x x'))))
    (hfcX : ∀ x x' y, Req x x' → Req (F x y) (F x' y))
    (hFbd : ∀ a b, Rle (Rabs (F a b)) (ofQ BF hBFd))
    (a w c v : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hc : 0 < c.den) (hv : 0 < v.den) (hvn : 0 ≤ v.num) : L2Test :=
  paramIntegralTest (fun x' y' => F (affineMap a w ha hw x') (affineMap c v hc hv y'))
    (mul Ly v) (mul Lx w) BF (Qmul_den_pos hLyd hv) (Int.mul_nonneg hLyn hvn)
    (Qmul_den_pos hLxd hw) (Int.mul_nonneg hLxn hwn) hBFd hBFn
    (fun x => affine_lip hLyd hLyn (hlipY (affineMap a w ha hw x)) c v hc hv hvn)
    (fun x y y' h => hfcY (affineMap a w ha hw x) (affineMap c v hc hv y) (affineMap c v hc hv y')
      (affineMap_congr c v hc hv h))
    (fun x x' y => affine_lip hLxd hLxn (fun p q => hlipX p q (affineMap c v hc hv y)) a w ha hw hwn x x')
    (fun x x' y h => hfcX (affineMap a w ha hw x) (affineMap a w ha hw x') (affineMap c v hc hv y)
      (affineMap_congr a w ha hw h))
    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
    (fun x u _ _ => hFbd (affineMap a w ha hw x)
      (affineMap c v hc hv (affineMap (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) u)))

set_option maxHeartbeats 2000000 in
/-- **The windowed reparametrization collapse**: the iterated window integral
    `∫_{[a,a+w]} ∫_{[c,c+v]} F` equals `w·v` times the unit-square integral of the pulled-back test
    `windowG`. Outer `riemannIntegralI_reparam` extracts the width `w`; per outer point the KEY REPARAM
    extracts `v` and identifies the inner integrand with `windowG`; certificate-irrelevance, the
    congruence, and `riemannIntegralI_smul` reconcile the moduli and pull `v` out. Reusable for both the
    `F` and transpose orientations of the swap. -/
theorem windowed_reparam_collapse (F : Real → Real → Real) (Ly Lx BF : Q)
    (hLyd : 0 < Ly.den) (hLyn : 0 ≤ Ly.num) (hLxd : 0 < Lx.den) (hLxn : 0 ≤ Lx.num)
    (hBFd : 0 < BF.den) (hBFn : 0 ≤ BF.num)
    (hlipY : ∀ x y y', Rle (Rabs (Rsub (F x y) (F x y'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub y y'))))
    (hfcY : ∀ x y y', Req y y' → Req (F x y) (F x y'))
    (hlipX : ∀ x x' y, Rle (Rabs (Rsub (F x y) (F x' y))) (Rmul (ofQ Lx hLxd) (Rabs (Rsub x x'))))
    (hfcX : ∀ x x' y, Req x x' → Req (F x y) (F x' y))
    (hFbd : ∀ a b, Rle (Rabs (F a b)) (ofQ BF hBFd))
    (a w c v : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hc : 0 < c.den) (hv : 0 < v.den) (hvn : 0 ≤ v.num) :
    Req
      (riemannIntegralI
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          c v hc hv hvn (fun x u _ _ => hFbd x (affineMap c v hc hv u))).hLd
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          c v hc hv hvn (fun x u _ _ => hFbd x (affineMap c v hc hv u))).hLn
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          c v hc hv hvn (fun x u _ _ => hFbd x (affineMap c v hc hv u))).hlip
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          c v hc hv hvn (fun x u _ _ => hFbd x (affineMap c v hc hv u))).hfc
        a w ha hw hwn)
      (Rmul (ofQ w hw) (Rmul (ofQ v hv)
        (riemannIntegralI
          (windowG F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX hFbd
            a w c v ha hw hwn hc hv hvn).hLd
          (windowG F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX hFbd
            a w c v ha hw hwn hc hv hvn).hLn
          (windowG F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX hFbd
            a w c v ha hw hwn hc hv hvn).hlip
          (windowG F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX hFbd
            a w c v ha hw hwn hc hv hvn).hfc
          (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)))) := by
  let PF := paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
    c v hc hv hvn (fun x u _ _ => hFbd x (affineMap c v hc hv u))
  let PG := windowG F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX hFbd
    a w c v ha hw hwn hc hv hvn
  show Req (riemannIntegralI PF.hLd PF.hLn PF.hlip PF.hfc a w ha hw hwn)
    (Rmul (ofQ w hw) (Rmul (ofQ v hv)
      (riemannIntegralI PG.hLd PG.hLn PG.hlip PG.hfc
        (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide))))
  -- outer-integral witnesses (modulus `M1 = PF.L·w`)
  have M1d : 0 < (mul PF.L w).den := Qmul_den_pos PF.hLd hw
  have M1n : 0 ≤ (mul PF.L w).num := Int.mul_nonneg PF.hLn hwn
  have outerWit := affine_lip PF.hLd PF.hLn PF.hlip a w ha hw hwn
  have outerHfc : ∀ x y, Req x y → Req (PF.f (affineMap a w ha hw x)) (PF.f (affineMap a w ha hw y)) :=
    fun x y h => PF.hfc _ _ (affineMap_congr a w ha hw h)
  -- common weakening modulus `Lstar = M1 + PG.L`
  have Lstard : 0 < (add (mul PF.L w) PG.L).den := add_den_pos M1d PG.hLd
  have Lstarn : 0 ≤ (add (mul PF.L w) PG.L).num := by
    show (0 : Int) ≤ (mul PF.L w).num * ((PG.L.den : Nat) : Int)
      + PG.L.num * (((mul PF.L w).den : Nat) : Int)
    exact Int.add_nonneg (Int.mul_nonneg M1n (Int.ofNat_nonneg _))
      (Int.mul_nonneg PG.hLn (Int.ofNat_nonneg _))
  have hM1star : Qle (mul PF.L w) (add (mul PF.L w) PG.L) := Qle_self_add PG.hLn
  have hPGstar : Qle PG.L (add (mul PF.L w) PG.L) := Qle_self_add_l M1n
  have hqePG : Qeq (mul v PG.L) (mul PF.L w) := by
    show Qeq (mul v (mul (⟨1, 1⟩ : Q) (mul Lx w))) (mul (mul v Lx) w)
    simp only [Qeq, mul]; push_cast; ring_uor
  have hvPGstar : Qle (mul v PG.L) (add (mul PF.L w) PG.L) :=
    Qle_trans M1d (Qeq_le hqePG) hM1star
  -- the scaled test `h2 = v · PG.f`
  have h2wit := smul_lip_ofQ PG.hLd PG.hlip v hv hvn Lstard hvPGstar
  have h2fc : ∀ x y, Req x y → Req (Rmul (ofQ v hv) (PG.f x)) (Rmul (ofQ v hv) (PG.f y)) :=
    fun x y h => Rmul_congr (Req_refl (ofQ v hv)) (PG.hfc x y h)
  have outerWitStar := lip_weaken M1d Lstard hM1star outerWit
  have PGfStar := lip_weaken PG.hLd Lstard hPGstar PG.hlip
  -- the KEY REPARAM per outer point
  have hkey : ∀ x', Req (PF.f (affineMap a w ha hw x')) (Rmul (ofQ v hv) (PG.f x')) :=
    fun x' => riemannIntegralI_reparam hLyd hLyn (hlipY (affineMap a w ha hw x'))
      (hfcY (affineMap a w ha hw x')) c v hc hv hvn
  -- the reparametrization chain
  have hout := riemannIntegralI_reparam PF.hLd PF.hLn PF.hlip PF.hfc a w ha hw hwn
  have hcert1 := riemannIntegralI_certif_irrel M1d M1n outerWit outerHfc
    Lstard Lstarn outerWitStar outerHfc (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
  have hcongr := riemannIntegralI_congr Lstard Lstarn outerWitStar outerHfc h2wit h2fc
    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide) hkey
  have hsmul := riemannIntegralI_smul v hv Lstard Lstarn PGfStar PG.hfc h2wit h2fc
    (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
  have hcert2 := riemannIntegralI_certif_irrel Lstard Lstarn PGfStar PG.hfc
    PG.hLd PG.hLn PG.hlip PG.hfc (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q) (by decide) (by decide) (by decide)
  exact Req_trans hout
    (Req_trans (Rmul_congr (Req_refl _) hcert1)
      (Req_trans (Rmul_congr (Req_refl _) hcongr)
        (Req_trans (Rmul_congr (Req_refl _) hsmul)
          (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _) hcert2)))))

set_option maxHeartbeats 4000000 in
/-- **THE WINDOWED GENERAL FUBINI SWAP** — `bern2D_general_swap` lifted from the unit square to
    arbitrary rational windows `[a,a+w] × [c,c+v]`:

        `∫_{x∈[a,a+w]} ∫_{y∈[c,c+v]} F(x,y)  =  ∫_{y∈[c,c+v]} ∫_{x∈[a,a+w]} F(x,y)`.

    Pure affine reparametrization: `windowed_reparam_collapse` on `F` (outer `[a,a+w]`, inner `[c,c+v]`)
    turns the left side into `w·v` times the unit-square integral of `windowG F` (`= G x' y' :=
    F(a+w·x', c+v·y')`); the same on the transpose `Fᵀ p q := F q p` (outer `[c,c+v]`, inner `[a,a+w]`)
    turns the right side into `v·w` times the unit-square integral of `windowG Fᵀ`, whose integrand
    coincides with `Gᵀ`. `bern2D_general_swap` at `G` equates the two unit-square integrals, and the
    shared `w·v = v·w` factor closes the equality. No new limit, no positivity; inherits everything from
    `bern2D_general_swap`; the crux fields stay `none`. -/
theorem bern2D_general_swap_window (F : Real → Real → Real) (Lx Ly BF : Q)
    (hLxd : 0 < Lx.den) (hLxn : 0 ≤ Lx.num) (hLyd : 0 < Ly.den) (hLyn : 0 ≤ Ly.num)
    (hBFd : 0 < BF.den) (hBFn : 0 ≤ BF.num)
    (hlipY : ∀ x y y', Rle (Rabs (Rsub (F x y) (F x y'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub y y'))))
    (hfcY : ∀ x y y', Req y y' → Req (F x y) (F x y'))
    (hlipX : ∀ x x' y, Rle (Rabs (Rsub (F x y) (F x' y))) (Rmul (ofQ Lx hLxd) (Rabs (Rsub x x'))))
    (hfcX : ∀ x x' y, Req x x' → Req (F x y) (F x' y))
    (hLip : ∀ a a' b b', Rle (Rabs (Rsub (F a b) (F a' b')))
      (Radd (Rmul (ofQ Lx hLxd) (Rabs (Rsub a a'))) (Rmul (ofQ Ly hLyd) (Rabs (Rsub b b')))))
    (hFbd : ∀ a b, Rle (Rabs (F a b)) (ofQ BF hBFd))
    (a w c v : Q) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hc : 0 < c.den) (hv : 0 < v.den) (hvn : 0 ≤ v.num) :
    Req
      (riemannIntegralI
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          c v hc hv hvn (fun x u _ _ => hFbd x (affineMap c v hc hv u))).hLd
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          c v hc hv hvn (fun x u _ _ => hFbd x (affineMap c v hc hv u))).hLn
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          c v hc hv hvn (fun x u _ _ => hFbd x (affineMap c v hc hv u))).hlip
        (paramIntegralTest F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn hlipY hfcY hlipX hfcX
          c v hc hv hvn (fun x u _ _ => hFbd x (affineMap c v hc hv u))).hfc
        a w ha hw hwn)
      (riemannIntegralI
        (paramIntegralTest (fun p q => F q p) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
          (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
          (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h)
          a w ha hw hwn (fun x u _ _ => hFbd (affineMap a w ha hw u) x)).hLd
        (paramIntegralTest (fun p q => F q p) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
          (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
          (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h)
          a w ha hw hwn (fun x u _ _ => hFbd (affineMap a w ha hw u) x)).hLn
        (paramIntegralTest (fun p q => F q p) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
          (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
          (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h)
          a w ha hw hwn (fun x u _ _ => hFbd (affineMap a w ha hw u) x)).hlip
        (paramIntegralTest (fun p q => F q p) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
          (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
          (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h)
          a w ha hw hwn (fun x u _ _ => hFbd (affineMap a w ha hw u) x)).hfc
        c v hc hv hvn) := by
  -- collapse the two windowed iterated integrals to unit-square integrals scaled by `w·v` / `v·w`
  have hL := windowed_reparam_collapse F Ly Lx BF hLyd hLyn hLxd hLxn hBFd hBFn
    hlipY hfcY hlipX hfcX hFbd a w c v ha hw hwn hc hv hvn
  have hR := windowed_reparam_collapse (fun p q => F q p) Lx Ly BF hLxd hLxn hLyd hLyn hBFd hBFn
    (fun x y y' => hlipX y y' x) (fun x y y' h => hfcX y y' x h)
    (fun x x' y => hlipY y x x') (fun x x' y h => hfcY y x x' h) (fun p q => hFbd q p)
    c v a w hc hv hvn ha hw hwn
  -- the unit-square swap at `G x' y' := F(a+w·x', c+v·y')`
  have hlipY_G : ∀ x y y', Rle (Rabs (Rsub (F (affineMap a w ha hw x) (affineMap c v hc hv y))
        (F (affineMap a w ha hw x) (affineMap c v hc hv y'))))
      (Rmul (ofQ (mul Ly v) (Qmul_den_pos hLyd hv)) (Rabs (Rsub y y'))) :=
    fun x => affine_lip hLyd hLyn (hlipY (affineMap a w ha hw x)) c v hc hv hvn
  have hfcY_G : ∀ x y y', Req y y' → Req (F (affineMap a w ha hw x) (affineMap c v hc hv y))
      (F (affineMap a w ha hw x) (affineMap c v hc hv y')) :=
    fun x y y' h => hfcY (affineMap a w ha hw x) (affineMap c v hc hv y) (affineMap c v hc hv y')
      (affineMap_congr c v hc hv h)
  have hlipX_G : ∀ x x' y, Rle (Rabs (Rsub (F (affineMap a w ha hw x) (affineMap c v hc hv y))
        (F (affineMap a w ha hw x') (affineMap c v hc hv y))))
      (Rmul (ofQ (mul Lx w) (Qmul_den_pos hLxd hw)) (Rabs (Rsub x x'))) :=
    fun x x' y => affine_lip hLxd hLxn (fun p q => hlipX p q (affineMap c v hc hv y))
      a w ha hw hwn x x'
  have hfcX_G : ∀ x x' y, Req x x' → Req (F (affineMap a w ha hw x) (affineMap c v hc hv y))
      (F (affineMap a w ha hw x') (affineMap c v hc hv y)) :=
    fun x x' y h => hfcX (affineMap a w ha hw x) (affineMap a w ha hw x') (affineMap c v hc hv y)
      (affineMap_congr a w ha hw h)
  have hLip_G : ∀ p p' q q', Rle (Rabs (Rsub (F (affineMap a w ha hw p) (affineMap c v hc hv q))
        (F (affineMap a w ha hw p') (affineMap c v hc hv q'))))
      (Radd (Rmul (ofQ (mul Lx w) (Qmul_den_pos hLxd hw)) (Rabs (Rsub p p')))
        (Rmul (ofQ (mul Ly v) (Qmul_den_pos hLyd hv)) (Rabs (Rsub q q')))) :=
    fun p p' q q' => Rle_trans
      (Rle_trans (Rle_of_Req (Rabs_congr (Req_symm (Rsub_telescope
          (F (affineMap a w ha hw p) (affineMap c v hc hv q))
          (F (affineMap a w ha hw p') (affineMap c v hc hv q))
          (F (affineMap a w ha hw p') (affineMap c v hc hv q'))))))
        (Rabs_Radd _ _))
      (Radd_le_add (hlipX_G p p' q) (hlipY_G p' q q'))
  have hFbd_G : ∀ p q, Rle (Rabs (F (affineMap a w ha hw p) (affineMap c v hc hv q))) (ofQ BF hBFd) :=
    fun p q => hFbd (affineMap a w ha hw p) (affineMap c v hc hv q)
  have hbern := bern2D_general_swap (fun x' y' => F (affineMap a w ha hw x') (affineMap c v hc hv y'))
    (mul Lx w) (mul Ly v) BF (Qmul_den_pos hLxd hw) (Int.mul_nonneg hLxn hwn)
    (Qmul_den_pos hLyd hv) (Int.mul_nonneg hLyn hvn) hBFd hBFn
    hlipY_G hfcY_G hlipX_G hfcX_G hLip_G hFbd_G
  -- reorder the shared scalar factor
  have reorder : ∀ X : Real, Req (Rmul (ofQ w hw) (Rmul (ofQ v hv) X))
      (Rmul (ofQ v hv) (Rmul (ofQ w hw) X)) :=
    fun X => Req_trans (Req_symm (Rmul_assoc (ofQ w hw) (ofQ v hv) X))
      (Req_trans (Rmul_congr (Rmul_comm (ofQ w hw) (ofQ v hv)) (Req_refl X))
        (Rmul_assoc (ofQ v hv) (ofQ w hw) X))
  exact Req_trans hL
    (Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _) hbern))
      (Req_trans (reorder _) (Req_symm hR)))

end Multiplicity.UOR.Bridge.F1Square.Square

