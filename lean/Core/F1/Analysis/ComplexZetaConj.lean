/-
F1 square — Track 1: **conjugation of the ζ-strip denominator** `1 − 2^{1−s}` — the toolbox-based
ζ-side pieces of `Cxi_conj`'s `hz` (`ζ(s̄) = conj ζ(s)`).

`CzetaStrip s = Ceta s · etaDenomInv s` with `etaDenom s = 1 − 2·2^{−s}` (`CriticalZeta.lean`). The
denominator factor conjugates cleanly through the toolbox: the natural-base power `ncpow` is
`Cexp`-built on a real `RlogNat`, so `ncpow_conj` is `Cexp_conj` + `Rmul_neg_left`; this lifts to
`cpowNeg_conj`, `etaTwoPow_conj` (`2·2^{−s}`), and `etaDenom_conj` (`1 − ·`). (The numerator
`Ceta_conj` lives in the `etaReSeq`/`etaImSeq` internals of `EtaVariation` — a separate brick.)

`ncpow_conj` is independently useful: it is the conjugation of every Dirichlet term `n^{−s}`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.CriticalZeta
import Core.F1.Analysis.ComplexConjAlgebra
import Core.F1.Analysis.ComplexDigammaConj
import Core.F1.Analysis.ComplexArgLower

namespace UOR.Bridge.F1Square.Analysis

/-- `Cone` is conjugation-fixed (`conj 1 = 1`). -/
theorem Cconj_Cone : Ceq (Cconj Cone) Cone :=
  ⟨Req_refl one, Rneg_zero⟩

/-- **Conjugation of the natural-base power**: `(conj z)` raised to base `n` is the conjugate —
    `ncpow n (z̄) = conj(ncpow n z)`.  `ncpow n z = exp⟨Re z·log n, Im z·log n⟩` with `log n` real, so
    `Cexp_conj` carries the conjugation once the imaginary part `(−Im z)·log n = −(Im z·log n)`
    (`Rmul_neg_left`). This is the conjugation of every Dirichlet term `n^{−s}`. -/
theorem ncpow_conj (n : Nat) (hn : 2 ≤ n) (z : Complex) :
    Ceq (ncpow n hn (Cconj z)) (Cconj (ncpow n hn z)) := by
  refine Ceq_trans (Cexp_congr (z := ⟨Rmul (Cconj z).re (RlogNat n hn), Rmul (Cconj z).im (RlogNat n hn)⟩)
    (w := Cconj ⟨Rmul z.re (RlogNat n hn), Rmul z.im (RlogNat n hn)⟩)
    ⟨Req_refl _, Rmul_neg_left z.im (RlogNat n hn)⟩)
    (Cexp_conj ⟨Rmul z.re (RlogNat n hn), Rmul z.im (RlogNat n hn)⟩)

/-- **Conjugation of `cpowNeg`** (`n^{−s}` with the program's branch convention): `cpowNeg (s̄) n =
    conj(cpowNeg s n)`.  For `n ≥ 2` it is `ncpow_conj` (`Cneg(Cconj s) = Cconj(Cneg s)` definitionally);
    for `n < 2` both sides are `1`. -/
theorem cpowNeg_conj (s : Complex) (n : Nat) :
    Ceq (cpowNeg (Cconj s) n) (Cconj (cpowNeg s n)) := by
  unfold cpowNeg
  by_cases h : 2 ≤ n
  · simp only [dif_pos h]
    exact ncpow_conj n h (Cneg s)
  · simp only [dif_neg h]
    exact Cconj_Cone

/-- **Conjugation of `etaTwoPow`** `2·2^{−s}`: `etaTwoPow (s̄) = conj(etaTwoPow s)`. -/
theorem etaTwoPow_conj (s : Complex) : Ceq (etaTwoPow (Cconj s)) (Cconj (etaTwoPow s)) := by
  unfold etaTwoPow
  exact Ceq_trans (Cmul_congr (Ceq_symm (Cconj_ofReal (RofNat 2))) (cpowNeg_conj s 2))
    (Ceq_symm (Cconj_Cmul (ofReal (RofNat 2)) (cpowNeg s 2)))

/-- **Conjugation of the ζ-strip denominator** `etaDenom s = 1 − 2·2^{−s}`:
    `etaDenom (s̄) = conj(etaDenom s)`.  The constant `1` and the subtraction conjugate trivially;
    `etaTwoPow_conj` does the rest. -/
theorem etaDenom_conj (s : Complex) : Ceq (etaDenom (Cconj s)) (Cconj (etaDenom s)) := by
  unfold etaDenom Csub
  refine Ceq_trans (Cadd_congr (Ceq_refl Cone) (Cneg_congr (etaTwoPow_conj s))) ?_
  refine Ceq_symm (Ceq_trans (Cconj_Cadd Cone (Cneg (etaTwoPow s))) ?_)
  exact Cadd_congr Cconj_Cone (Cconj_Cneg (etaTwoPow s))

/-- **`Cinv` respects `≈`**: `z ≈ w ⟹ 1/z ≈ 1/w` (with their own positivity witnesses). From
    `cnormSq` congruence + `Rinv_congr`, componentwise. -/
theorem Cinv_congr {z w : Complex} (k : Nat) (hk : Qlt (Qbound k) ((CnormSq z).seq k))
    (k' : Nat) (hk' : Qlt (Qbound k') ((CnormSq w).seq k')) (h : Ceq z w) :
    Ceq (Cinv z k hk) (Cinv w k' hk') := by
  have hnorm : Req (CnormSq z) (CnormSq w) := Radd_congr (Rmul_congr h.1 h.1) (Rmul_congr h.2 h.2)
  have hinv : Req (Rinv (CnormSq z) k hk) (Rinv (CnormSq w) k' hk') := Rinv_congr hk hk' hnorm
  exact ⟨Rmul_congr h.1 hinv, Rneg_congr (Rmul_congr h.2 hinv)⟩

/-- **Conjugation of the inverted ζ-strip denominator** `etaDenomInv (s̄) = conj(etaDenomInv s)` —
    `etaDenomInv = 1/etaDenom`, so `etaDenom_conj` (`Cinv_congr`) + `Cinv_conj` give it. (The shared
    witness `hk` serves `Cconj(etaDenom s)` too: `|conj x|² = |x|²` holds at every index.) -/
theorem etaDenomInv_conj (s : Complex)
    (k : Nat) (hk : Qlt (Qbound k) ((CnormSq (etaDenom s)).seq k))
    (k' : Nat) (hk' : Qlt (Qbound k') ((CnormSq (etaDenom (Cconj s))).seq k')) :
    Ceq (etaDenomInv (Cconj s) k' hk') (Cconj (etaDenomInv s k hk)) := by
  have hde := etaDenom_conj s
  -- |etaDenom(s̄)|² ≈ |etaDenom s|²  (via etaDenom_conj then CnormSq_conj), so the reciprocals agree
  have hnormeq : Req (CnormSq (etaDenom (Cconj s))) (CnormSq (etaDenom s)) :=
    Req_trans (Radd_congr (Rmul_congr hde.1 hde.1) (Rmul_congr hde.2 hde.2)) (CnormSq_conj (etaDenom s))
  have hinv : Req (Rinv (CnormSq (etaDenom (Cconj s))) k' hk') (Rinv (CnormSq (etaDenom s)) k hk) :=
    Rinv_congr hk' hk hnormeq
  refine ⟨?_, ?_⟩
  · show Req (Rmul (etaDenom (Cconj s)).re (Rinv (CnormSq (etaDenom (Cconj s))) k' hk'))
            (Rmul (etaDenom s).re (Rinv (CnormSq (etaDenom s)) k hk))
    exact Rmul_congr hde.1 hinv
  · show Req (Rneg (Rmul (etaDenom (Cconj s)).im (Rinv (CnormSq (etaDenom (Cconj s))) k' hk')))
            (Rneg (Rneg (Rmul (etaDenom s).im (Rinv (CnormSq (etaDenom s)) k hk))))
    exact Rneg_congr (Req_trans (Rmul_congr hde.2 hinv)
      (Rmul_neg_left (etaDenom s).im (Rinv (CnormSq (etaDenom s)) k hk)))

-- ===========================================================================
-- (C) The η numerator: the paired partial sums conjugate (the core of `Ceta_conj`).
-- ===========================================================================

/-- **Conjugation of the term difference** `cpowNegDiff (s̄) n = conj(cpowNegDiff s n)`
    (`cpowNegDiff = n^{−s} − (n+1)^{−s}`): `Cconj` distributes over the subtraction, `cpowNeg_conj`
    does each term. -/
theorem cpowNegDiff_conj (s : Complex) (n : Nat) :
    Ceq (cpowNegDiff (Cconj s) n) (Cconj (cpowNegDiff s n)) := by
  unfold cpowNegDiff Csub
  exact Ceq_trans (Cadd_congr (cpowNeg_conj s n) (Cneg_congr (cpowNeg_conj s (n + 1))))
    (Ceq_symm (Ceq_trans (Cconj_Cadd (cpowNeg s n) (Cneg (cpowNeg s (n + 1))))
      (Cadd_congr (Ceq_refl _) (Cconj_Cneg (cpowNeg s (n + 1))))))

/-- **Conjugation of the η paired partial sum** `czEtaPaired (s̄) K = conj(czEtaPaired s K)` — by
    induction: each block is a `Cadd` of `cpowNegDiff`s, both of which conjugate (`Cconj_Cadd`,
    `cpowNegDiff_conj`).  This is the numerator core of the ζ-strip conjugation `Ceta_conj`/`hz`:
    `Re/Im (Ceta) = Rlim ((czEtaPaired …).re/.im)`. -/
theorem czEtaPaired_conj (s : Complex) : ∀ K,
    Ceq (czEtaPaired (Cconj s) K) (Cconj (czEtaPaired s K))
  | 0 => Ceq_symm Cconj_Czero
  | (K + 1) =>
      Ceq_trans (Cadd_congr (czEtaPaired_conj s K) (cpowNegDiff_conj s (2 * K + 1)))
        (Ceq_symm (Cconj_Cadd (czEtaPaired s K) (cpowNegDiff s (2 * K + 1))))

/-- **Conjugation of η** `Ceta (s̄) = conj(Ceta s)`.  `Re/Im (Ceta) = Rlim` of the `re`/`im` of the
    paired partial sums, which conjugate (`czEtaPaired_conj`); so the real-part limits agree
    (`Rlim_congr`) and the imaginary-part limit negates (`Rlim_congr` + `Rlim_neg`). The `s̄`-side
    bounds/blocks are passed in (`(Cconj s).re = s.re`, so `hσ`/`hsb` are reused). -/
theorem Ceta_conj (s : Complex) {sb T : Q} (hsbd : 0 < sb.den) (hsb0 : 0 ≤ sb.num)
    (hTd : 0 < T.den) (hT0 : 0 ≤ T.num) (hσ : Rnonneg s.re) (hsb : Rle s.re (ofQ sb hsbd))
    (hT1 : Rle (Rneg (ofQ T hTd)) s.im) (hT2 : Rle s.im (ofQ T hTd))
    {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hblk : ∀ k, 1 ≤ k → Rle (Rsub (EtaVSum s T hTd (2 ^ (k + 1))) (EtaVSum s T hTd (2 ^ k)))
        (ofQ (mul (Vconst sb T) (qpow (Qinv (add ⟨1, 1⟩ τ)) k))
          (Qmul_den_pos (Vconst_den_pos hsbd hTd)
            (qpow_den_pos (Qinv_den_pos (by simp only [add]; push_cast; omega)) k))))
    (hT1c : Rle (Rneg (ofQ T hTd)) (Cconj s).im) (hT2c : Rle (Cconj s).im (ofQ T hTd))
    (hblkc : ∀ k, 1 ≤ k → Rle (Rsub (EtaVSum (Cconj s) T hTd (2 ^ (k + 1))) (EtaVSum (Cconj s) T hTd (2 ^ k)))
        (ofQ (mul (Vconst sb T) (qpow (Qinv (add ⟨1, 1⟩ τ)) k))
          (Qmul_den_pos (Vconst_den_pos hsbd hTd)
            (qpow_den_pos (Qinv_den_pos (by simp only [add]; push_cast; omega)) k)))) :
    Ceq (Ceta (Cconj s) hsbd hsb0 hTd hT0 hσ hsb hT1c hT2c hτn hτd hblkc)
        (Cconj (Ceta s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 hτn hτd hblk)) := by
  have hnegreg : RReg (fun j => Rneg (etaImSeq s τ sb T j)) :=
    RReg_neg (fun j => etaImSeq s τ sb T j)
      (etaIm_RReg s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 hτn hτd hblk)
  refine ⟨?_, ?_⟩
  · exact Rlim_congr (fun j => etaReSeq (Cconj s) τ sb T j) (fun j => etaReSeq s τ sb T j)
      (etaRe_RReg (Cconj s) hsbd hsb0 hTd hT0 hσ hsb hT1c hT2c hτn hτd hblkc)
      (etaRe_RReg s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 hτn hτd hblk)
      (fun j => (czEtaPaired_conj s (2 ^ (etaMidx τ sb T j - 1))).1)
  · refine Req_trans (Rlim_congr (fun j => etaImSeq (Cconj s) τ sb T j)
      (fun j => Rneg (etaImSeq s τ sb T j))
      (etaIm_RReg (Cconj s) hsbd hsb0 hTd hT0 hσ hsb hT1c hT2c hτn hτd hblkc) hnegreg
      (fun j => (czEtaPaired_conj s (2 ^ (etaMidx τ sb T j - 1))).2)) ?_
    exact Rlim_neg (fun j => etaImSeq s τ sb T j)
      (etaIm_RReg s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 hτn hτd hblk) hnegreg

/-- **Conjugation of the ζ-strip** `ζ(s̄) = conj ζ(s)` — `CzetaStrip = Ceta · etaDenomInv`, so
    `Cconj_Cmul` distributes and the two factors conjugate (`Ceta_conj`, `etaDenomInv_conj`). This is
    the ζ-side discharge of `Cxi_conj`'s `hz` (the `s̄`-side bounds/blocks and inverse-witness are
    supplied; `(Cconj s).re = s.re`, so `hσ`/`hsb` are reused). -/
theorem CzetaStrip_conj (s : Complex) {sb T : Q} (hsbd : 0 < sb.den) (hsb0 : 0 ≤ sb.num)
    (hTd : 0 < T.den) (hT0 : 0 ≤ T.num) (hσ : Rnonneg s.re) (hsb : Rle s.re (ofQ sb hsbd))
    (hT1 : Rle (Rneg (ofQ T hTd)) s.im) (hT2 : Rle s.im (ofQ T hTd))
    {τ : Q} (hτn : 0 < τ.num) (hτd : 0 < τ.den)
    (hblk : ∀ k, 1 ≤ k → Rle (Rsub (EtaVSum s T hTd (2 ^ (k + 1))) (EtaVSum s T hTd (2 ^ k)))
        (ofQ (mul (Vconst sb T) (qpow (Qinv (add ⟨1, 1⟩ τ)) k))
          (Qmul_den_pos (Vconst_den_pos hsbd hTd)
            (qpow_den_pos (Qinv_den_pos (by simp only [add]; push_cast; omega)) k))))
    (hT1c : Rle (Rneg (ofQ T hTd)) (Cconj s).im) (hT2c : Rle (Cconj s).im (ofQ T hTd))
    (hblkc : ∀ k, 1 ≤ k → Rle (Rsub (EtaVSum (Cconj s) T hTd (2 ^ (k + 1))) (EtaVSum (Cconj s) T hTd (2 ^ k)))
        (ofQ (mul (Vconst sb T) (qpow (Qinv (add ⟨1, 1⟩ τ)) k))
          (Qmul_den_pos (Vconst_den_pos hsbd hTd)
            (qpow_den_pos (Qinv_den_pos (by simp only [add]; push_cast; omega)) k))))
    (k : Nat) (hk : Qlt (Qbound k) ((CnormSq (etaDenom s)).seq k))
    (k' : Nat) (hk' : Qlt (Qbound k') ((CnormSq (etaDenom (Cconj s))).seq k')) :
    Ceq (CzetaStrip (Cconj s) hsbd hsb0 hTd hT0 hσ hsb hT1c hT2c hτn hτd hblkc k' hk')
        (Cconj (CzetaStrip s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 hτn hτd hblk k hk)) :=
  Ceq_trans
    (Cmul_congr (Ceta_conj s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 hτn hτd hblk hT1c hT2c hblkc)
      (etaDenomInv_conj s k hk k' hk'))
    (Ceq_symm (Cconj_Cmul (Ceta s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 hτn hτd hblk) (etaDenomInv s k hk)))

end UOR.Bridge.F1Square.Analysis
