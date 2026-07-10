/-
F1 square — v0.22.0 Track 1: **real-part conjugation invariance of the complex digamma**
`Re ψ(s̄) = Re ψ(s)` (`CDigamma_re_conj`), a genuine *property* of the constructed `CDigamma`.

The real part of `1/(s+n)` is `(Re s + n)/|s+n|²`, and both `Re(s+n)` and `|s+n|² = (Re s+n)² +
(Im s)²` are invariant under `s ↦ s̄` (the `Im` enters only squared). So every term's real part — hence
the whole real series — is conjugation-invariant. This is the digamma face of ξ's conjugate-pair zero
symmetry, and it is exactly the part Track 2's `Re ψ(1/4 + iτ/2)` (`BurnolAlpha`/`PsiLine`) lives on.

Demonstrates the reusable limit/reciprocal congruences `Rlim_congr` and `Rinv_congr` (`RlimProps.lean`):
the two real-part partial-sum sequences are pointwise `≈` (each term `≈` via `Rinv_congr` on
`|s̄+n|² ≈ |s+n|²`), so their diagonal limits agree.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import F1Square.Analysis.ComplexDigamma
import F1Square.Analysis.RlimProps
import F1Square.Analysis.Reflection

namespace UOR.Bridge.F1Square.Analysis

/-- **`exp` commutes with conjugation** `exp(z̄) = conj(exp z)`. From `cos` even and `sin` odd:
    `exp(z̄) = ⟨e^{Re z}·cos(−Im z), e^{Re z}·sin(−Im z)⟩ = ⟨e^{Re z}·cos(Im z), −e^{Re z}·sin(Im z)⟩
    = conj(exp z)`. Reusable for conjugation of any `exp`-built object (the conductor `π^{−s/2}`, and the
    eventual `Γ`/`Cpow` conjugation). -/
theorem Cexp_conj (z : Complex) : Ceq (Cexp (Cconj z)) (Cconj (Cexp z)) :=
  ⟨Rmul_congr (Req_refl _) (Rcos_neg z.im),
   Req_trans (Rmul_congr (Req_refl _) (Rsin_neg z.im)) (Rmul_neg_right (RexpReal z.re) (Rsin z.im))⟩

/-- **`|z̄|² = |z|²`** generically (the modulus-squared is conjugation-invariant; `Im` enters only as
    `(±Im z)²`). -/
theorem CnormSq_conj (z : Complex) : Req (CnormSq (Cconj z)) (CnormSq z) := by
  show Req (Radd (Rmul z.re z.re) (Rmul (Rneg z.im) (Rneg z.im)))
    (Radd (Rmul z.re z.re) (Rmul z.im z.im))
  refine Radd_congr (Req_refl _) ?_
  exact Req_trans (Rmul_neg_left z.im (Rneg z.im))
    (Req_trans (Rneg_congr (Rmul_neg_right z.im z.im)) (Rneg_neg (Rmul z.im z.im)))

/-- **`Cinv` commutes with conjugation** `1/z̄ = conj(1/z)`. From `1/z = z̄/|z|²`: the real part
    `Re z/|z̄|² ≈ Re z/|z|²` (`Rinv_congr` on `|z̄|² ≈ |z|²`) and the imaginary part flips
    (`(−Im z)/|z̄|² ≈ −(Im z/|z|²)`). Reusable for the conjugation of any `Cinv`-built object (the
    ζ-strip denominator `etaDenomInv`, the Spouge bracket `1/(s+k)`). -/
theorem Cinv_conj (z : Complex) (k : Nat) (hk : Qlt (Qbound k) ((CnormSq z).seq k))
    (k' : Nat) (hk' : Qlt (Qbound k') ((CnormSq (Cconj z)).seq k')) :
    Ceq (Cinv (Cconj z) k' hk') (Cconj (Cinv z k hk)) := by
  refine ⟨?_, ?_⟩
  · show Req (Rmul z.re (Rinv (CnormSq (Cconj z)) k' hk')) (Rmul z.re (Rinv (CnormSq z) k hk))
    exact Rmul_congr (Req_refl _) (Rinv_congr hk' hk (CnormSq_conj z))
  · show Req (Rneg (Rmul (Rneg z.im) (Rinv (CnormSq (Cconj z)) k' hk')))
      (Rneg (Rneg (Rmul z.im (Rinv (CnormSq z) k hk))))
    refine Rneg_congr (Req_trans (Rmul_neg_left z.im (Rinv (CnormSq (Cconj z)) k' hk')) ?_)
    exact Rneg_congr (Rmul_congr (Req_refl _) (Rinv_congr hk' hk (CnormSq_conj z)))

/-- **`genSum` respects pointwise `≈`** (termwise congruence of the finite partial sum). -/
theorem genSum_congr (T T' : Nat → Real) (h : ∀ n, Req (T n) (T' n)) :
    ∀ N, Req (genSum T N) (genSum T' N)
  | 0 => Req_refl _
  | (N + 1) => Radd_congr (genSum_congr T T' h N) (h N)

/-- **`genSum` of a negated sequence is the negated sum** `Σ(−T) ≈ −ΣT`. -/
theorem genSum_neg (T : Nat → Real) (N : Nat) :
    Req (genSum (fun n => Rneg (T n)) N) (Rneg (genSum T N)) := by
  induction N with
  | zero =>
      show Req zero (Rneg zero)
      exact Req_symm (Req_of_seq_Qeq (fun _ => by simp only [Rneg, zero, ofQ, Qeq, neg] <;> decide))
  | succ N ih =>
      exact Req_trans (Radd_congr ih (Req_refl _)) (Req_symm (Rneg_Radd (genSum T N) (T N)))

/-- **`RReg` is preserved under negation** (`|−Xⱼ − (−Xₖ)| = |Xⱼ − Xₖ|`). -/
theorem RReg_neg (X : Nat → Real) (h : RReg X) : RReg (fun j => Rneg (X j)) := by
  intro j k n
  have he : Qeq (Qsub ((X k).seq n) ((X j).seq n))
      (Qsub ((Rneg (X j)).seq n) ((Rneg (X k)).seq n)) := by
    show Qeq (Qsub ((X k).seq n) ((X j).seq n)) (Qsub (neg ((X j).seq n)) (neg ((X k).seq n)))
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  refine Qle_congr_left (Qabs_den_pos (Qsub_den_pos ((X k).den_pos n) ((X j).den_pos n)))
    (Qabs_Qeq he) ?_
  rw [Qabs_Qsub_comm]
  exact h j k n

/-- **`|s̄+n|² ≈ |s+n|²`**: the modulus-squared is conjugation-invariant (`Im` enters only as
    `(±Im s)²`). -/
theorem CnormSq_CdigammaArg_conj (s : Complex) (n : Nat) :
    Req (CnormSq (CdigammaArg (Cconj s) n)) (CnormSq (CdigammaArg s n)) := by
  show Req (Radd (Rmul (Radd s.re (RofNat n)) (Radd s.re (RofNat n))) (Rmul (Rneg s.im) (Rneg s.im)))
    (Radd (Rmul (Radd s.re (RofNat n)) (Radd s.re (RofNat n))) (Rmul s.im s.im))
  refine Radd_congr (Req_refl _) ?_
  exact Req_trans (Rmul_neg_left s.im (Rneg s.im))
    (Req_trans (Rneg_congr (Rmul_neg_right s.im s.im)) (Rneg_neg (Rmul s.im s.im)))

set_option maxHeartbeats 400000 in
/-- **The `n`-th term's real part is conjugation-invariant**: `Re Cterm(s̄,n) ≈ Re Cterm(s,n)`. The
    `1/(n+1)` and `Re(s+n) = Re(s̄+n)` parts are identical; the reciprocal `1/|s̄+n|² ≈ 1/|s+n|²` is
    `Rinv_congr` of `CnormSq_CdigammaArg_conj`. -/
theorem CdigammaTerm_re_conj (s : Complex) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcs : Rle (ofQ c hcd) s.re) (n : Nat) :
    Req (CdigammaTerm (Cconj s) hcn hcd hcs n).re (CdigammaTerm s hcn hcd hcs n).re := by
  simp only [CdigammaTerm_re]
  refine Radd_congr (Req_refl _) (Rneg_congr (Rmul_congr (Req_refl _) ?_))
  exact Rinv_congr (CdigammaArg_witness (s := Cconj s) hcn hcd hcs n)
    (CdigammaArg_witness (s := s) hcn hcd hcs n) (CnormSq_CdigammaArg_conj s n)

/-- Simplification of the raw imaginary-part form `0 + −(−(x·I)) ≈ x·I`. -/
private theorem cdig_im_simp (x I : Real) : Req (Radd zero (Rneg (Rneg (Rmul x I)))) (Rmul x I) :=
  Req_trans (Radd_congr (Req_refl _) (Rneg_neg _)) (Req_trans (Radd_comm _ _) (Radd_zero _))

set_option maxHeartbeats 400000 in
/-- **The `n`-th term's imaginary part flips under conjugation**: `Im Cterm(s̄,n) ≈ −Im Cterm(s,n)`.
    `Im(1/(s+n)) = −Im s/|s+n|²`, so conjugation (`Im s ↦ −Im s`) negates it; `|s+n|²` itself is
    invariant (`Rinv_congr` of `CnormSq_CdigammaArg_conj`). -/
theorem CdigammaTerm_im_conj (s : Complex) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcs : Rle (ofQ c hcd) s.re) (n : Nat) :
    Req (CdigammaTerm (Cconj s) hcn hcd hcs n).im (Rneg (CdigammaTerm s hcn hcd hcs n).im) := by
  simp only [CdigammaTerm_im]
  refine Req_trans (cdig_im_simp _ _) (Req_trans ?_ (Req_symm (Rneg_congr (cdig_im_simp _ _))))
  show Req (Rmul (Rneg s.im) (Rinv (CnormSq (CdigammaArg (Cconj s) n)) (CdigK c)
      (CdigammaArg_witness (s := Cconj s) hcn hcd hcs n)))
    (Rneg (Rmul s.im (Rinv (CnormSq (CdigammaArg s n)) (CdigK c)
      (CdigammaArg_witness (s := s) hcn hcd hcs n))))
  exact Req_trans (Rmul_neg_left s.im _) (Rneg_congr (Rmul_congr (Req_refl _)
    (Rinv_congr (CdigammaArg_witness (s := Cconj s) hcn hcd hcs n)
      (CdigammaArg_witness (s := s) hcn hcd hcs n) (CnormSq_CdigammaArg_conj s n))))

/-- **The complex digamma core's real part is conjugation-invariant**: `Re (Σ-core)(s̄) ≈ Re
    (Σ-core)(s)`. The two `Re`-partial-sum sequences share the same reindex `Midx` (same `B1, B2`) and
    are pointwise `≈` (`genSum_congr` + `CdigammaTerm_re_conj`), so `Rlim_congr` equates their limits. -/
theorem CDigammaCore_re_conj (s : Complex) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcs : Rle (ofQ c hcd) s.re) {B1 B2 : Q} (hB1d : 0 < B1.den) (hB2d : 0 < B2.den)
    (hB10 : 0 ≤ B1.num) (hB20 : 0 ≤ B2.num)
    (hB1lo : Rle (Rneg (ofQ B1 hB1d)) (Rsub s.re one)) (hB1hi : Rle (Rsub s.re one) (ofQ B1 hB1d))
    (hB2lo : Rle (Rneg (ofQ B2 hB2d)) s.im) (hB2hi : Rle s.im (ofQ B2 hB2d)) :
    Req (CDigammaCore (Cconj s) hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi
          (Rle_Rneg hB2hi) (Rle_trans (Rle_Rneg hB2lo) (Rle_of_Req (Rneg_neg (ofQ B2 hB2d))))).re
        (CDigammaCore s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi).re :=
  Rlim_congr
    (fun j => genSum (fun n => (CdigammaTerm (Cconj s) hcn hcd hcs n).re)
      (digammaMidx (add B1 (mul B2 B2)) j))
    (fun j => genSum (fun n => (CdigammaTerm s hcn hcd hcs n).re)
      (digammaMidx (add B1 (mul B2 B2)) j))
    (CdigammaReSum_RReg (Cconj s) hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi
      (Rle_Rneg hB2hi) (Rle_trans (Rle_Rneg hB2lo) (Rle_of_Req (Rneg_neg (ofQ B2 hB2d)))))
    (CdigammaReSum_RReg s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi)
    (fun _j => genSum_congr _ _ (fun n => CdigammaTerm_re_conj s hcn hcd hcs n) _)

/-- **The complex digamma core's imaginary part flips under conjugation**: `Im (Σ-core)(s̄) ≈ −Im
    (Σ-core)(s)`. The `Im`-partial sums share the reindex; each is the negation of the other
    (`genSum_congr` + `genSum_neg` via `CdigammaTerm_im_conj`), so `Rlim_congr` then `Rlim_neg` flip the
    limit. -/
theorem CDigammaCore_im_conj (s : Complex) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcs : Rle (ofQ c hcd) s.re) {B1 B2 : Q} (hB1d : 0 < B1.den) (hB2d : 0 < B2.den)
    (hB10 : 0 ≤ B1.num) (hB20 : 0 ≤ B2.num)
    (hB1lo : Rle (Rneg (ofQ B1 hB1d)) (Rsub s.re one)) (hB1hi : Rle (Rsub s.re one) (ofQ B1 hB1d))
    (hB2lo : Rle (Rneg (ofQ B2 hB2d)) s.im) (hB2hi : Rle s.im (ofQ B2 hB2d)) :
    Req (CDigammaCore (Cconj s) hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi
          (Rle_Rneg hB2hi) (Rle_trans (Rle_Rneg hB2lo) (Rle_of_Req (Rneg_neg (ofQ B2 hB2d))))).im
        (Rneg (CDigammaCore s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi).im) :=
  Req_trans
    (Rlim_congr
      (fun j => genSum (fun n => (CdigammaTerm (Cconj s) hcn hcd hcs n).im)
        (digammaMidx (add (mul B1 B2) B2) j))
      (fun j => Rneg (genSum (fun n => (CdigammaTerm s hcn hcd hcs n).im)
        (digammaMidx (add (mul B1 B2) B2) j)))
      (CdigammaImSum_RReg (Cconj s) hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi
        (Rle_Rneg hB2hi) (Rle_trans (Rle_Rneg hB2lo) (Rle_of_Req (Rneg_neg (ofQ B2 hB2d)))))
      (RReg_neg _ (CdigammaImSum_RReg s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi))
      (fun _j => Req_trans
        (genSum_congr _ _ (fun n => CdigammaTerm_im_conj s hcn hcd hcs n) _)
        (genSum_neg _ _)))
    (Rlim_neg _ (CdigammaImSum_RReg s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi)
      (RReg_neg _ (CdigammaImSum_RReg s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi)))

/-- **★ real-part conjugation invariance of `ψ`** `Re ψ(s̄) = Re ψ(s)`: with `ψ(s) = −γ + core(s)`, the
    `−γ` (real) contributes the same real part, and `Re core(s̄) ≈ Re core(s)` by `CDigammaCore_re_conj`.
    The archimedean face of ξ's conjugate-pair symmetry; the line `Re ψ(1/4 + iτ/2)` of Track 2 is its
    instance. -/
theorem CDigamma_re_conj (s : Complex) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcs : Rle (ofQ c hcd) s.re) {B1 B2 : Q} (hB1d : 0 < B1.den) (hB2d : 0 < B2.den)
    (hB10 : 0 ≤ B1.num) (hB20 : 0 ≤ B2.num)
    (hB1lo : Rle (Rneg (ofQ B1 hB1d)) (Rsub s.re one)) (hB1hi : Rle (Rsub s.re one) (ofQ B1 hB1d))
    (hB2lo : Rle (Rneg (ofQ B2 hB2d)) s.im) (hB2hi : Rle s.im (ofQ B2 hB2d)) :
    Req (CDigamma (Cconj s) hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi
          (Rle_Rneg hB2hi) (Rle_trans (Rle_Rneg hB2lo) (Rle_of_Req (Rneg_neg (ofQ B2 hB2d))))).re
        (CDigamma s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi).re :=
  Radd_congr (Req_refl _)
    (CDigammaCore_re_conj s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi)

/-- **imaginary-part conjugation flip of `ψ`** `Im ψ(s̄) = −Im ψ(s)`: the `−γ` is real (`Im = 0`), and
    `Im core(s̄) ≈ −Im core(s)` by `CDigammaCore_im_conj`; the outer `0 + ·` and `−(0 + ·)` reconcile via
    `Rneg_Radd`. -/
theorem CDigamma_im_conj (s : Complex) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcs : Rle (ofQ c hcd) s.re) {B1 B2 : Q} (hB1d : 0 < B1.den) (hB2d : 0 < B2.den)
    (hB10 : 0 ≤ B1.num) (hB20 : 0 ≤ B2.num)
    (hB1lo : Rle (Rneg (ofQ B1 hB1d)) (Rsub s.re one)) (hB1hi : Rle (Rsub s.re one) (ofQ B1 hB1d))
    (hB2lo : Rle (Rneg (ofQ B2 hB2d)) s.im) (hB2hi : Rle s.im (ofQ B2 hB2d)) :
    Req (CDigamma (Cconj s) hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi
          (Rle_Rneg hB2hi) (Rle_trans (Rle_Rneg hB2lo) (Rle_of_Req (Rneg_neg (ofQ B2 hB2d))))).im
        (Rneg (CDigamma s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi).im) := by
  show Req (Radd zero (CDigammaCore (Cconj s) hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi
        (Rle_Rneg hB2hi) (Rle_trans (Rle_Rneg hB2lo) (Rle_of_Req (Rneg_neg (ofQ B2 hB2d))))).im)
    (Rneg (Radd zero (CDigammaCore s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi).im))
  refine Req_trans (Radd_congr (Req_refl _)
    (CDigammaCore_im_conj s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi)) ?_
  refine Req_symm (Req_trans (Rneg_Radd zero _) (Radd_congr ?_ (Req_refl _)))
  exact Req_of_seq_Qeq (fun _ => by simp only [Rneg, zero, ofQ, Qeq, neg] <;> decide)

/-- **★ conjugation symmetry of the complex digamma** `ψ(s̄) = conj ψ(s)` (`Ceq`), assembled from the
    real-part invariance (`CDigamma_re_conj`) and the imaginary-part flip (`CDigamma_im_conj`). The
    archimedean place's reflection symmetry — the digamma face of ξ's conjugate-pair zero structure. -/
theorem CDigamma_conj (s : Complex) {c : Q} (hcn : 0 < c.num) (hcd : 0 < c.den)
    (hcs : Rle (ofQ c hcd) s.re) {B1 B2 : Q} (hB1d : 0 < B1.den) (hB2d : 0 < B2.den)
    (hB10 : 0 ≤ B1.num) (hB20 : 0 ≤ B2.num)
    (hB1lo : Rle (Rneg (ofQ B1 hB1d)) (Rsub s.re one)) (hB1hi : Rle (Rsub s.re one) (ofQ B1 hB1d))
    (hB2lo : Rle (Rneg (ofQ B2 hB2d)) s.im) (hB2hi : Rle s.im (ofQ B2 hB2d)) :
    Ceq (CDigamma (Cconj s) hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi
          (Rle_Rneg hB2hi) (Rle_trans (Rle_Rneg hB2lo) (Rle_of_Req (Rneg_neg (ofQ B2 hB2d)))))
        (Cconj (CDigamma s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi)) :=
  ⟨CDigamma_re_conj s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi,
   CDigamma_im_conj s hcn hcd hcs hB1d hB2d hB10 hB20 hB1lo hB1hi hB2lo hB2hi⟩

end UOR.Bridge.F1Square.Analysis
