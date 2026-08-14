/-
F1 square — **Lipschitz-in-`x` continuity of the real-parameter convolution** (`MulConvRLip.lean`):
`|mulConvR f g x − mulConvR f g x'| ≤ ofQ(w·f.L·M_g·(1/a)²)·|x − x'|` — continuity under the integral
sign, the last ingredient (with the uniform bound `mulConvR_abs_le`) that makes `x ↦ mulConvR f g x`
a bounded-Lipschitz test the Mellin transform of `⋆` can consume.

The engine is a general estimate: `riemannIntegralI_dist_le_window` — two integrals at a shared
modulus whose integrands differ by at most `K` on the window have `|∫f − ∫h| ≤ w·K` (upper:
`∫f ≤ ∫(h+K) = ∫h + w·K`; lower symmetric). `mulConvR_lipschitz` weakens the two convolution
integrands to a common modulus (`certif_irrel`) and feeds the pointwise `x`-difference bound
`mulConvR_integrand_diff`.

HONEST SCOPE. The Lipschitz-in-`x` continuity only. It completes the data for `x ↦ mulConvR f g x`
to be a test, but the Mellin transform of `⋆`, and the convolution theorem `M[f⋆g]=M[f]·M[g]`
(Wall 3), are still unbuilt — that theorem is what would identify `mulConv` values at prime powers
with `weilPrimeGram (vFrom g)`, i.e. step 4 = RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.MulConvRDiff
import Multiplicity.F1Square.Square.MellinLinear

set_option maxHeartbeats 1000000

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The integral-distance window estimate**: two integrands `f, h` at a shared modulus `L`, differing
    by at most a real `K ≥ 0` on the window, have `|∫_a^{a+w} f − ∫_a^{a+w} h| ≤ w·K`. Proof by two
    monotone comparisons `∫f ≤ ∫(h+K) = ∫h + w·K` and its mirror. -/
theorem riemannIntegralI_dist_le_window {f h : Real → Real} {L : Q} (hLd : 0 < L.den) (hLn : 0 ≤ L.num)
    (hlipf : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfcf : ∀ x y, Req x y → Req (f x) (f y))
    (hliph : ∀ x y, Rle (Rabs (Rsub (h x) (h y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfch : ∀ x y, Req x y → Req (h x) (h y))
    (a w : Q) (K : Real) (ha : 0 < a.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) (hKnn : Rnonneg K)
    (hdiff : ∀ x, Rle zero x → Rle x one →
      Rle (Rabs (Rsub (f (affineMap a w ha hw x)) (h (affineMap a w ha hw x)))) K) :
    Rle (Rabs (Rsub (riemannIntegralI hLd hLn hlipf hfcf a w ha hw hwn)
                    (riemannIntegralI hLd hLn hliph hfch a w ha hw hwn)))
        (Rmul (ofQ w hw) K) := by
  have hzL : Qle (⟨0, 1⟩ : Q) L := by
    show (0 : Int) * (L.den : Int) ≤ L.num * 1
    rw [Int.zero_mul, Int.mul_one]; exact hLn
  have hlipK : ∀ x y, Rle (Rabs (Rsub K K)) (Rmul (ofQ L hLd) (Rabs (Rsub x y))) :=
    lip_weaken (L := (⟨0, 1⟩ : Q)) (by decide) hLd hzL (const_lip0 K)
  -- `∫(const K) = w·K`.
  have hconstK : Req (riemannIntegralI hLd hLn hlipK (fun _ _ _ => Req_refl K) a w ha hw hwn)
      (Rmul (ofQ w hw) K) :=
    Req_trans (riemannIntegralI_certif_irrel hLd hLn hlipK (fun _ _ _ => Req_refl K)
      (by decide) (by decide) (const_lip0 K) (fun _ _ _ => Req_refl K) a w ha hw hwn)
      (riemannIntegralI_const K a w ha hw hwn)
  -- A generic one-directional comparison `∫p ≤ ∫q + w·K` when `p ≤ q + K` on the window.
  have oneway : ∀ (p q : Real → Real)
      (hlipp : ∀ x y, Rle (Rabs (Rsub (p x) (p y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
      (hfcp : ∀ x y, Req x y → Req (p x) (p y))
      (hlipq : ∀ x y, Rle (Rabs (Rsub (q x) (q y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
      (hfcq : ∀ x y, Req x y → Req (q x) (q y)),
      (∀ x, Rle zero x → Rle x one →
        Rle (p (affineMap a w ha hw x)) (Radd (q (affineMap a w ha hw x)) K)) →
      Rle (Rsub (riemannIntegralI hLd hLn hlipp hfcp a w ha hw hwn)
                (riemannIntegralI hLd hLn hlipq hfcq a w ha hw hwn)) (Rmul (ofQ w hw) K) := by
    intro p q hlipp hfcp hlipq hfcq hpq
    -- `q + K` integrand and its cert.
    have hlipqK : ∀ x y, Rle (Rabs (Rsub (Radd (q x) K) (Radd (q y) K)))
        (Rmul (ofQ L hLd) (Rabs (Rsub x y))) := by
      intro x y
      refine Rle_trans (Rle_of_Req (Rabs_congr (Req_trans (Rsub_Radd_Radd (q x) K (q y) K)
        (Req_trans (Radd_congr (Req_refl (Rsub (q x) (q y))) (Radd_neg K))
          (Radd_zero (Rsub (q x) (q y))))))) (hlipq x y)
    have hfcqK : ∀ x y, Req x y → Req (Radd (q x) K) (Radd (q y) K) :=
      fun x y hxy => Radd_congr (hfcq x y hxy) (Req_refl K)
    -- `∫(q+K) = ∫q + w·K`.
    have hadd : Req (riemannIntegralI hLd hLn hlipqK hfcqK a w ha hw hwn)
        (Radd (riemannIntegralI hLd hLn hlipq hfcq a w ha hw hwn)
              (riemannIntegralI hLd hLn hlipK (fun _ _ _ => Req_refl K) a w ha hw hwn)) :=
      riemannIntegralI_add hLd hLn hlipq hfcq hlipK (fun _ _ _ => Req_refl K) hlipqK hfcqK
        a w ha hw hwn
    have hle : Rle (riemannIntegralI hLd hLn hlipp hfcp a w ha hw hwn)
        (riemannIntegralI hLd hLn hlipqK hfcqK a w ha hw hwn) :=
      riemannIntegralI_le_unit hLd hLn hlipp hfcp hlipqK hfcqK a w ha hw hwn hpq
    refine Rsub_le_of_le_Radd (Rle_trans hle (Rle_of_Req ?_))
    exact Req_trans hadd (Radd_congr (Req_refl _) hconstK)
  -- The pointwise `p ≤ q + K` from `|p − q| ≤ K` (both directions).
  have hpqf : ∀ x, Rle zero x → Rle x one →
      Rle (f (affineMap a w ha hw x)) (Radd (h (affineMap a w ha hw x)) K) :=
    fun x h0 h1 => Rle_Radd_of_Rsub_le (Rle_trans (Rle_Rabs_self _) (hdiff x h0 h1))
  have hpqh : ∀ x, Rle zero x → Rle x one →
      Rle (h (affineMap a w ha hw x)) (Radd (f (affineMap a w ha hw x)) K) :=
    fun x h0 h1 => Rle_Radd_of_Rsub_le (Rle_trans
      (Rle_of_Req (Req_symm (Rneg_Rsub_flip (f (affineMap a w ha hw x))
        (h (affineMap a w ha hw x)))))
      (Rle_trans (Rle_Rabs_self _) (Rle_trans (Rle_of_Req (Rabs_Rneg _)) (hdiff x h0 h1))))
  refine Rabs_le_of_both (oneway f h hlipf hfcf hliph hfch hpqf) ?_
  exact Rle_trans (Rle_of_Req (Rneg_Rsub_flip _ _)) (oneway h f hliph hfch hlipf hfcf hpqh)


/-- **Lipschitz-in-`x` continuity of the real-parameter convolution** —
    `|mulConvR f g x − mulConvR f g x'| ≤ ofQ(w·f.L·M_g·(1/a)²)·|x − x'|`. The two convolution
    integrands share the (`x`-independent) modulus of `Q_x = productTest (reflectTest a (dilateTestR x S f)) g`;
    weaken both to the common modulus `L_x + L_{x'}` (`certif_irrel`) and feed the pointwise difference
    bound `mulConvR_integrand_diff` to the integral-distance window estimate. -/
theorem mulConvR_lipschitz (f g : L2Test) (x x' : Real) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (hxS : Rle (Rabs x) (ofQ S hSd)) (hx'S : Rle (Rabs x') (ofQ S hSd))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Rle (Rabs (Rsub (mulConvR f g x S hSd hSn hxS a han had lo w hlo hw hwn)
                    (mulConvR f g x' S hSd hSn hx'S a han had lo w hlo hw hwn)))
        (Rmul (ofQ (mul w (mul (mul f.L (Qinv a)) (mul g.M (Qinv a))))
              (Qmul_den_pos hw (Qmul_den_pos (Qmul_den_pos f.hLd (Qinv_den_pos han))
                (Qmul_den_pos g.hMd (Qinv_den_pos han)))))
          (Rabs (Rsub x x'))) := by
  -- Weaken both integrands to the common modulus `Lc = L_x + L_{x'}`.
  have hCIx := riemannIntegralI_certif_irrel
    (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2L_num (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2lip (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2fc (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (add_den_pos
      (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
        (recipTest a han had))
      (l2L_den (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
        (recipTest a han had)))
    (Qadd_num_nonneg_loc
      (l2L_num (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
        (recipTest a han had))
      (l2L_num (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
        (recipTest a han had)))
    (fun s t => lip_mono
      (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
        (recipTest a han had))
      (add_den_pos
        (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
          (recipTest a han had))
        (l2L_den (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
          (recipTest a han had)))
      (Qle_self_add
        (l2L_num (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
          (recipTest a han had)))
      (Rnonneg_Rabs (Rsub s t))
      (l2lip (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
        (recipTest a han had) s t))
    (l2fc (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    lo w hlo hw hwn
  have hCIx' := riemannIntegralI_certif_irrel
    (l2L_den (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
      (recipTest a han had))
    (l2L_num (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
      (recipTest a han had))
    (l2lip (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
      (recipTest a han had))
    (l2fc (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
      (recipTest a han had))
    (add_den_pos
      (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
        (recipTest a han had))
      (l2L_den (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
        (recipTest a han had)))
    (Qadd_num_nonneg_loc
      (l2L_num (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
        (recipTest a han had))
      (l2L_num (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
        (recipTest a han had)))
    (fun s t => lip_mono
      (l2L_den (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
        (recipTest a han had))
      (add_den_pos
        (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
          (recipTest a han had))
        (l2L_den (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
          (recipTest a han had)))
      (Qle_add_self
        (l2L_num (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
          (recipTest a han had)))
      (Rnonneg_Rabs (Rsub s t))
      (l2lip (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
        (recipTest a han had) s t))
    (l2fc (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
      (recipTest a han had))
    lo w hlo hw hwn
  -- The integral-distance estimate at the common modulus.
  have hdist := riemannIntegralI_dist_le_window
    (add_den_pos
      (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
        (recipTest a han had))
      (l2L_den (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
        (recipTest a han had)))
    (Qadd_num_nonneg_loc
      (l2L_num (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
        (recipTest a han had))
      (l2L_num (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
        (recipTest a han had)))
    (fun s t => lip_mono
      (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
        (recipTest a han had))
      (add_den_pos
        (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
          (recipTest a han had))
        (l2L_den (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
          (recipTest a han had)))
      (Qle_self_add
        (l2L_num (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
          (recipTest a han had)))
      (Rnonneg_Rabs (Rsub s t))
      (l2lip (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
        (recipTest a han had) s t))
    (l2fc (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (fun s t => lip_mono
      (l2L_den (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
        (recipTest a han had))
      (add_den_pos
        (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
          (recipTest a han had))
        (l2L_den (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
          (recipTest a han had)))
      (Qle_add_self
        (l2L_num (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
          (recipTest a han had)))
      (Rnonneg_Rabs (Rsub s t))
      (l2lip (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
        (recipTest a han had) s t))
    (l2fc (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
      (recipTest a han had))
    lo w
    (Rmul (ofQ (mul (mul f.L (Qinv a)) (mul g.M (Qinv a)))
        (Qmul_den_pos (Qmul_den_pos f.hLd (Qinv_den_pos han))
          (Qmul_den_pos g.hMd (Qinv_den_pos han)))) (Rabs (Rsub x x')))
    hlo hw hwn
    (Rnonneg_Rmul (Rnonneg_ofQ (Qmul_den_pos (Qmul_den_pos f.hLd (Qinv_den_pos han))
        (Qmul_den_pos g.hMd (Qinv_den_pos han)))
        (Int.mul_nonneg (Int.mul_nonneg f.hLn (Int.le_of_lt (Qinv_num_pos had)))
          (Int.mul_nonneg g.hMn (Int.le_of_lt (Qinv_num_pos had)))))
      (Rnonneg_Rabs (Rsub x x')))
    (fun z h0 h1 => mulConvR_integrand_diff f g x x' S hSd hSn hxS hx'S a han had
      (affineMap lo w hlo hw z))
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr hCIx hCIx'))) ?_
  refine Rle_trans hdist (Rle_of_Req ?_)
  exact Req_trans (Req_symm (Rmul_assoc (ofQ w hw)
      (ofQ (mul (mul f.L (Qinv a)) (mul g.M (Qinv a)))
        (Qmul_den_pos (Qmul_den_pos f.hLd (Qinv_den_pos han))
          (Qmul_den_pos g.hMd (Qinv_den_pos han)))) (Rabs (Rsub x x'))))
    (Rmul_congr (Rmul_ofQ_ofQ hw (Qmul_den_pos (Qmul_den_pos f.hLd (Qinv_den_pos han))
      (Qmul_den_pos g.hMd (Qinv_den_pos han)))) (Req_refl _))

end Multiplicity.UOR.Bridge.F1Square.Square
