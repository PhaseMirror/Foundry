/-
F1 square — **critical-strip ζ via the Dirichlet η quotient** `ζ(s) = η(s) / (1 − 2^{1−s})`.

`Ceta` (EtaVariation) gives the Dirichlet eta `η(s) = Σ (−1)^{n−1} n⁻ˢ` as a genuine constructive
complex number on the whole open right half `Re s > 0` (the integration-free route — η converges by
bounded variation where the raw ζ series diverges). The functional relation `(1 − 2^{1−s})·ζ(s) = η(s)`
then yields ζ on the critical strip `0 < Re s < 1`: there `1 − 2^{1−s}` is non-vanishing (proved below
as `|1 − 2^{1−s}|² ≥ (2^{1−σ} − 1)² > 0` for `Re s < 1`), so the quotient is everywhere defined.
(The zeros of `1 − 2^{1−s}` — which all lie on `Re s = 1` — are thus outside the open strip; this file
proves the `Re s < 1` non-vanishing it needs, not the full zero-locus characterization.)

This file builds the denominator `1 − 2^{1−s} = 1 − 2·2⁻ˢ = 1 − 2·cpowNeg s 2` (reusing the committed
`cpowNeg`, no new `Cexp`), its non-vanishing `|1 − 2^{1−s}|² ≥ (2^{1−σ} − 1)² > 0` for `σ < 1` (via the
`Cexp`/`ncpow` modulus identity and `Re ≤ |·|`), and the constructive inverse `Cinv`.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.EtaVariation
import F1Square.Analysis.ComplexInv

namespace UOR.Bridge.F1Square.Analysis

/-- **The `n⁻ˢ` squared modulus**: `|n⁻ˢ|² = (exp(−Re s · log n))²`. Specialises `ncpow_normSq` to the
    negated exponent (`cpowNeg s n = ncpow n _ (−s)`, and `(−s).re = −Re s`). -/
theorem cpowNeg_normSq (s : Complex) (n : Nat) (hn : 2 ≤ n) :
    Req (CnormSq (cpowNeg s n))
      (Rmul (RexpReal (Rmul (Rneg s.re) (RlogNat n hn)))
            (RexpReal (Rmul (Rneg s.re) (RlogNat n hn)))) := by
  unfold cpowNeg
  rw [dif_pos hn]
  exact ncpow_normSq n hn (Cneg s)

/-- **`2^{1−s}` factor**: `2·2⁻ˢ = 2·cpowNeg s 2`. -/
def etaTwoPow (s : Complex) : Complex := Cmul (ofReal (RofNat 2)) (cpowNeg s 2)

/-- **The η→ζ denominator** `1 − 2^{1−s}`. -/
def etaDenom (s : Complex) : Complex := Csub Cone (etaTwoPow s)

/-- **Squared modulus of a real scaling**: `|a·z|² = a²·|z|²`. -/
theorem CnormSq_Cmul_ofReal (a : Real) (z : Complex) :
    Req (CnormSq (Cmul (ofReal a) z)) (Rmul (Rmul a a) (CnormSq z)) := by
  -- `(Cmul (ofReal a) z).re = Rsub (Rmul a z.re) (Rmul zero z.im)`,
  -- `.im = Radd (Rmul a z.im) (Rmul zero z.re)`.
  have hre : Req (Cmul (ofReal a) z).re (Rmul a z.re) := by
    show Req (Rsub (Rmul a z.re) (Rmul zero z.im)) (Rmul a z.re)
    refine Req_trans (Rsub_congr (Req_refl _)
      (Req_trans (Rmul_comm zero z.im) (Rmul_zero z.im))) ?_
    exact Rsub_zero (Rmul a z.re)
  have him : Req (Cmul (ofReal a) z).im (Rmul a z.im) := by
    show Req (Radd (Rmul a z.im) (Rmul zero z.re)) (Rmul a z.im)
    refine Req_trans (Radd_congr (Req_refl _)
      (Req_trans (Rmul_comm zero z.re) (Rmul_zero z.re))) ?_
    exact Radd_zero (Rmul a z.im)
  -- CnormSq = re·re + im·im ≈ (a·zr)·(a·zr) + (a·zi)·(a·zi)
  show Req (Radd (Rmul (Cmul (ofReal a) z).re (Cmul (ofReal a) z).re)
                 (Rmul (Cmul (ofReal a) z).im (Cmul (ofReal a) z).im))
           (Rmul (Rmul a a) (Radd (Rmul z.re z.re) (Rmul z.im z.im)))
  refine Req_trans (Radd_congr (Rmul_congr hre hre) (Rmul_congr him him)) ?_
  -- (a·zr)·(a·zr) + (a·zi)·(a·zi) ≈ (a·a)·(zr·zr) + (a·a)·(zi·zi) ≈ (a·a)·(zr·zr + zi·zi)
  have hsq : ∀ x : Real, Req (Rmul (Rmul a x) (Rmul a x)) (Rmul (Rmul a a) (Rmul x x)) := by
    intro x
    -- (a·x)·(a·x) ≈ a·(x·(a·x)) ≈ a·((x·a)·x) ≈ a·((a·x)·x) ≈ a·(a·(x·x)) ≈ (a·a)·(x·x)
    refine Req_trans (Rmul_assoc a x (Rmul a x)) ?_
    refine Req_trans (Rmul_congr (Req_refl a)
      (Req_trans (Req_symm (Rmul_assoc x a x)) (Rmul_congr (Rmul_comm x a) (Req_refl x)))) ?_
    -- a·((a·x)·x) ≈ a·(a·(x·x)) ≈ (a·a)·(x·x)
    refine Req_trans (Rmul_congr (Req_refl a) (Rmul_assoc a x x)) ?_
    exact Req_symm (Rmul_assoc a a (Rmul x x))
  refine Req_trans (Radd_congr (hsq z.re) (hsq z.im)) ?_
  exact Req_symm (Rmul_distrib (Rmul a a) (Rmul z.re z.re) (Rmul z.im z.im))

/-- **`log 2 > 0`** (`= log 2 ≥ ½ > 0`, via the `RlogNat ↔ logN` bridge and `logN_2_ge_half`). -/
theorem Pos_RlogNat_two : Pos (RlogNat 2 (by omega)) :=
  Pos_congr (Req_symm (RlogNat_eq_logN 2 (by omega)))
    (Pos_of_Rle_ofQ (c := (⟨1, 2⟩ : Q)) (by decide) (by decide) logN_2_ge_half)

/-- The real part of `etaTwoPow s` simplifies to `2 · Re(2⁻ˢ)`. -/
theorem etaTwoPow_re (s : Complex) :
    Req (etaTwoPow s).re (Rmul (RofNat 2) (cpowNeg s 2).re) := by
  show Req (Rsub (Rmul (RofNat 2) (cpowNeg s 2).re) (Rmul zero (cpowNeg s 2).im))
           (Rmul (RofNat 2) (cpowNeg s 2).re)
  refine Req_trans (Rsub_congr (Req_refl _)
    (Req_trans (Rmul_comm zero (cpowNeg s 2).im) (Rmul_zero (cpowNeg s 2).im))) ?_
  exact Rsub_zero _

-- Pure additive (atom-level) rearrangements for the `(1−r)²` / `(2u−1)²` expansions and the final
-- difference collapse. These are real-level `Req` regroupings, proved by hand-rolled `Req_trans`
-- chains over the additive ring lemmas (`Radd_assoc`/`Radd_comm`/`Rneg_Radd`/`Radd_neg`): a pointwise
-- `Req_of_seq_Qeq` + `ring_uor` discharge is NOT available here, because `Radd`/`Rsub` reindex their
-- operands (`2n+1`), so the two groupings have different sequence-nesting and are not equal pointwise.

/-- `(o−r) − (r − rr) ≈ (o − (r+r)) + rr`. Composed from the proven additive ring lemmas
    (`Radd_assoc`/`Rneg_Radd`/`Rneg_neg`) — a pointwise `Req_of_seq_Qeq` proof is impossible here
    because `Radd`/`Rsub` reindex (`2n+1`) and the two groupings have different nesting depth. -/
private theorem sub_sub_to_add (o r rr : Real) :
    Req (Rsub (Rsub o r) (Rsub r rr)) (Radd (Rsub o (Radd r r)) rr) := by
  have h1 : Req (Rsub (Rsub o r) (Rsub r rr))
      (Radd (Radd o (Rneg r)) (Radd (Rneg r) rr)) := by
    show Req (Radd (Radd o (Rneg r)) (Rneg (Radd r (Rneg rr))))
             (Radd (Radd o (Rneg r)) (Radd (Rneg r) rr))
    exact Radd_congr (Req_refl _)
      (Req_trans (Rneg_Radd r (Rneg rr)) (Radd_congr (Req_refl _) (Rneg_neg rr)))
  have h2 : Req (Radd (Rsub o (Radd r r)) rr)
      (Radd (Radd o (Radd (Rneg r) (Rneg r))) rr) := by
    show Req (Radd (Radd o (Rneg (Radd r r))) rr)
             (Radd (Radd o (Radd (Rneg r) (Rneg r))) rr)
    exact Radd_congr (Radd_congr (Req_refl _) (Rneg_Radd r r)) (Req_refl _)
  refine Req_trans h1 (Req_trans ?_ (Req_symm h2))
  refine Req_trans (Radd_assoc o (Rneg r) (Radd (Rneg r) rr)) ?_
  refine Req_trans (Radd_congr (Req_refl o) (Req_symm (Radd_assoc (Rneg r) (Rneg r) rr))) ?_
  exact Req_symm (Radd_assoc o (Radd (Rneg r) (Rneg r)) rr)

/-- `(o − (r+r)) − (o − (M+M)) ≈ (M−r) + (M−r)` (the `1 − 2r` minus `1 − 2M` step). -/
private theorem one_two_diff (o r M : Real) :
    Req (Rsub (Rsub o (Radd r r)) (Rsub o (Radd M M)))
        (Radd (Rsub M r) (Rsub M r)) := by
  refine Req_trans (Rsub_Radd_Radd o (Rneg (Radd r r)) o (Rneg (Radd M M))) ?_
  refine Req_trans (Radd_congr (Radd_neg o) (Req_refl _)) ?_
  refine Req_trans (Radd_comm zero _) (Req_trans (Radd_zero _) ?_)
  show Req (Radd (Rneg (Radd r r)) (Rneg (Rneg (Radd M M)))) (Radd (Rsub M r) (Rsub M r))
  refine Req_trans (Radd_congr (Rneg_Radd r r) (Rneg_neg (Radd M M))) ?_
  refine Req_trans (Radd_assoc (Rneg r) (Rneg r) (Radd M M)) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Req_symm (Radd_assoc (Rneg r) M M))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Radd_comm (Rneg r) M) (Req_refl _))) ?_
  refine Req_trans (Req_symm (Radd_assoc (Rneg r) (Radd M (Rneg r)) M)) ?_
  refine Req_trans (Radd_congr (Req_symm (Radd_assoc (Rneg r) M (Rneg r))) (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_congr (Radd_comm (Rneg r) M) (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Radd_assoc (Radd M (Rneg r)) (Rneg r) M) ?_
  exact Radd_congr (Req_refl _) (Radd_comm (Rneg r) M)

/-- Final collapse `(P + (o−2r)) − (P + (o−2M)) ≈ (M−r) + (M−r)` (`P = |w|²` cancels). -/
private theorem diff_collapse2 (P o r M : Real) :
    Req (Rsub (Radd P (Rsub o (Radd r r))) (Radd P (Rsub o (Radd M M))))
        (Radd (Rsub M r) (Rsub M r)) := by
  refine Req_trans (Rsub_Radd_Radd P (Rsub o (Radd r r)) P (Rsub o (Radd M M))) ?_
  refine Req_trans (Radd_congr (Radd_neg P) (Req_refl _)) ?_
  refine Req_trans (Radd_comm zero _) (Req_trans (Radd_zero _) ?_)
  exact one_two_diff o r M

/-- **Non-vanishing of the η→ζ denominator on the critical strip** (squared-modulus form):
    for `Re s ≤ σ₁ < 1`, `|1 − 2^{1−s}|² ≥ (2^{1−σ} − 1)² > 0`. -/
theorem etaDenom_Pos_normSq (s : Complex) {σ₁ : Q} (hσ₁d : 0 < σ₁.den)
    (hσ₁ : Qlt σ₁ (⟨1, 1⟩ : Q)) (hσ : Rle s.re (ofQ σ₁ hσ₁d)) :
    Pos (CnormSq (etaDenom s)) := by
  let two : Real := RofNat 2
  have htwo : two = RofNat 2 := rfl
  let u : Real := RexpReal (Rmul (Rneg s.re) (RlogNat 2 (by omega)))
  have hu : u = RexpReal (Rmul (Rneg s.re) (RlogNat 2 (by omega))) := rfl
  let r : Real := (etaTwoPow s).re
  have hr : r = (etaTwoPow s).re := rfl
  let i : Real := (etaTwoPow s).im
  have hi : i = (etaTwoPow s).im := rfl
  let A : Real := Rsub (Rmul two u) one
  have hA : A = Rsub (Rmul two u) one := rfl
  have htwo_nonneg : Rnonneg two := by
    rw [htwo]; show Rnonneg (ofQ (⟨2, 1⟩ : Q) Nat.one_pos); exact Rnonneg_ofQ (by decide) (by decide)
  -- ===== (iii) Pos A, i.e. 2u − 1 > 0 =====
  -- E := log 2 + (−σ)·log 2 = (1−σ)·log 2  is positive, and A ≈ exp E − exp 0.
  have hlog2pos : Pos (RlogNat 2 (by omega)) := Pos_RlogNat_two
  -- Pos (Rsub one s.re):  s.re ≤ σ₁ < 1.
  have hσ₁d' : 0 < (Qsub (⟨1, 1⟩ : Q) σ₁).den := Qsub_den_pos (by decide) hσ₁d
  have hσ₁lt1 : Pos (Rsub one (ofQ σ₁ hσ₁d)) := by
    -- `one − ofQ σ₁` has constant ℚ-seq `1 − σ₁`, so it equals `ofQ (1−σ₁)`, which is positive.
    have heq : Req (Rsub one (ofQ σ₁ hσ₁d)) (ofQ (Qsub (⟨1, 1⟩ : Q) σ₁) hσ₁d') :=
      Req_of_seq_Qeq (fun _ => by
        show Qeq (add (⟨1, 1⟩ : Q) (neg σ₁)) (Qsub (⟨1, 1⟩ : Q) σ₁); exact Qeq_refl _)
    refine Pos_congr (Req_symm heq) ?_
    refine Pos_of_Rle_ofQ (c := Qsub (⟨1, 1⟩ : Q) σ₁) ?_ hσ₁d' (Rle_refl _)
    -- 0 < (1 − σ₁).num
    have := hσ₁
    simp only [Qlt, Qsub, add, neg, mul] at this ⊢
    push_cast at this ⊢; omega
  -- s.re ≤ σ₁  ⟹  one − σ₁ ≤ one − s.re, monotone.
  have hone_sub_re : Pos (Rsub one s.re) :=
    Pos_mono (Rsub_le_sub (Rle_refl one) hσ) hσ₁lt1
  -- E ≈ (1 − σ) · log 2, so Pos E.
  have hPosE : Pos (Radd (RlogNat 2 (by omega))
      (Rmul (Rneg s.re) (RlogNat 2 (by omega)))) := by
    have hE : Req (Radd (RlogNat 2 (by omega)) (Rmul (Rneg s.re) (RlogNat 2 (by omega))))
        (Rmul (Rsub one s.re) (RlogNat 2 (by omega))) := by
      -- (1−σ)·L = 1·L + (−σ)·L = L + (−σ)·L
      refine Req_symm (Req_trans (Rmul_distrib_right one (Rneg s.re) (RlogNat 2 (by omega))) ?_)
      exact Radd_congr (Rone_mul (RlogNat 2 (by omega))) (Req_refl _)
    exact Pos_congr (Req_symm hE) (Pos_Rmul hone_sub_re hlog2pos)
  -- A ≈ exp E − exp 0 = exp E − 1, positive by strict monotonicity.
  have hPosA : Pos A := by
    -- two·u ≈ exp(log 2)·exp(E') = exp(log 2 + E')  where E' = (−σ)·log 2
    have hExpE : Req (Rmul two u)
        (RexpReal (Radd (RlogNat 2 (by omega)) (Rmul (Rneg s.re) (RlogNat 2 (by omega))))) := by
      have h1 : Req two (RexpReal (RlogNat 2 (by omega))) := by
        rw [htwo]
        refine Req_symm (Req_trans (Rexp_RlogNat 2 (by omega)) ?_)
        show Req (ofQ (⟨(2 : Int), 1⟩ : Q) Nat.one_pos) (RofNat 2); exact Req_refl _
      refine Req_trans (Rmul_congr h1
        (show Req u (RexpReal (Rmul (Rneg s.re) (RlogNat 2 (by omega)))) from Req_refl _)) ?_
      exact Req_symm (RexpReal_add (RlogNat 2 (by omega)) (Rmul (Rneg s.re) (RlogNat 2 (by omega))))
    have hAeq : Req A (Rsub (RexpReal (Radd (RlogNat 2 (by omega))
        (Rmul (Rneg s.re) (RlogNat 2 (by omega))))) (RexpReal zero)) := by
      rw [hA]
      refine Rsub_congr hExpE ?_
      exact Req_symm RexpReal_zero
    refine Pos_congr (Req_symm hAeq) ?_
    refine RexpReal_strictmono Rnonneg_zero ?_
    exact Pos_congr (Req_symm (Rsub_zero _)) hPosE
  -- ===== (ii) Pos (A·A) =====
  have hPosA2 : Pos (Rmul A A) := Pos_Rmul hPosA hPosA
  -- ===== (i) Rle (A·A) (CnormSq (etaDenom s)) =====
  -- hwre : Re w ≤ 2u
  have hwre : Rle r (Rmul two u) := by
    rw [hr]
    refine Rle_trans (Rle_of_Req (etaTwoPow_re s)) ?_
    rw [htwo, hu]
    exact Rmul_le_Rmul_left htwo_nonneg (cpowNeg_re_le s 2 (by omega))
  -- hCNw : |w|² = (2·2)·(u·u)
  have hCNw : Req (CnormSq (etaTwoPow s)) (Rmul (Rmul two two) (Rmul u u)) := by
    rw [show etaTwoPow s = Cmul (ofReal (RofNat 2)) (cpowNeg s 2) from rfl]
    refine Req_trans (CnormSq_Cmul_ofReal (RofNat 2) (cpowNeg s 2)) ?_
    rw [htwo, hu]
    exact Rmul_congr (Req_refl _) (cpowNeg_normSq s 2 (by omega))
  -- |w|² = r·r + i·i  (CnormSq def)
  have hCNw' : Req (Radd (Rmul r r) (Rmul i i)) (Rmul (Rmul two two) (Rmul u u)) := by
    rw [hr, hi]; exact hCNw
  -- CnormSq (etaDenom s) ≈ (1−r)·(1−r) + (−i)·(−i)
  have hden_re : Req (etaDenom s).re (Rsub one r) := by
    rw [hr]; show Req (Radd one (Rneg (etaTwoPow s).re)) (Rsub one (etaTwoPow s).re); exact Req_refl _
  have hden_im : Req (etaDenom s).im (Rneg i) := by
    rw [hi]; show Req (Radd zero (Rneg (etaTwoPow s).im)) (Rneg (etaTwoPow s).im)
    exact Req_trans (Radd_comm zero (Rneg (etaTwoPow s).im)) (Radd_zero _)
  have hCNden : Req (CnormSq (etaDenom s))
      (Radd (Rmul (Rsub one r) (Rsub one r)) (Rmul (Rneg i) (Rneg i))) := by
    show Req (Radd (Rmul (etaDenom s).re (etaDenom s).re) (Rmul (etaDenom s).im (etaDenom s).im))
             (Radd (Rmul (Rsub one r) (Rsub one r)) (Rmul (Rneg i) (Rneg i)))
    exact Radd_congr (Rmul_congr hden_re hden_re) (Rmul_congr hden_im hden_im)
  -- abbreviations:  M := 2u,  P := (2u)·(2u) = |w|².
  let M : Real := Rmul two u
  have hM : M = Rmul two u := rfl
  let P : Real := Rmul M M
  have hP : P = Rmul M M := rfl
  -- (1−r)(1−r) ≈ r·r + (1 − (r+r));  (−i)(−i) ≈ i·i.
  -- So CnormSq(etaDenom) ≈ (r·r + i·i) + (1 − (r+r)) ≈ P + (1 − (r+r)).
  have hExpand : Req (Radd (Rmul (Rsub one r) (Rsub one r)) (Rmul (Rneg i) (Rneg i)))
      (Radd (Radd (Rmul r r) (Rmul i i)) (Rsub one (Radd r r))) := by
    -- left: (1−r)(1−r) ≈ r·r + (1 − (r+r))
    have hsq1 : Req (Rmul (Rsub one r) (Rsub one r))
        (Radd (Rmul r r) (Rsub one (Radd r r))) := by
      -- (1−r)(1−r) = (1−r) − (r·1 − r·r) = (1−r) − (r − r·r) ≈ (1−(r+r)) + r·r
      refine Req_trans (Rmul_sub_distrib_right one r (Rsub one r)) ?_
      refine Req_trans (Rsub_congr (Rone_mul (Rsub one r)) (Rmul_sub_distrib r one r)) ?_
      refine Req_trans (Rsub_congr (Req_refl _)
        (Rsub_congr (Rmul_one r) (Req_refl _))) ?_
      -- (1−r) − (r − r·r) ≈ (1 − (r+r)) + r·r
      refine Req_trans (sub_sub_to_add one r (Rmul r r)) ?_
      exact Radd_comm (Rsub one (Radd r r)) (Rmul r r)
    -- right: (−i)(−i) ≈ i·i
    have hsq2 : Req (Rmul (Rneg i) (Rneg i)) (Rmul i i) :=
      Req_trans (Rmul_neg_left i (Rneg i))
        (Req_trans (Rneg_congr (Rmul_neg_right i i)) (Rneg_neg (Rmul i i)))
    -- (r·r + (1−(r+r))) + i·i ≈ (r·r + i·i) + (1−(r+r))
    refine Req_trans (Radd_congr hsq1 hsq2) ?_
    refine Req_trans (Radd_assoc (Rmul r r) (Rsub one (Radd r r)) (Rmul i i)) ?_
    refine Req_trans (Radd_congr (Req_refl _) (Radd_comm (Rsub one (Radd r r)) (Rmul i i))) ?_
    exact Req_symm (Radd_assoc (Rmul r r) (Rmul i i) (Rsub one (Radd r r)))
  -- CnormSq(etaDenom) ≈ P + (1 − (r+r)).
  have hCNden2 : Req (CnormSq (etaDenom s)) (Radd P (Rsub one (Radd r r))) := by
    refine Req_trans hCNden (Req_trans hExpand ?_)
    refine Radd_congr ?_ (Req_refl _)
    -- r·r + i·i ≈ (2·2)·(u·u) ≈ (2u)·(2u) = P
    refine Req_trans hCNw' ?_
    rw [hP, hM]; exact Rmul4_rearrange two two u u
  -- A·A = (2u−1)² ≈ P + (1 − (2u+2u)).
  have hAA : Req (Rmul A A) (Radd P (Rsub one (Radd M M))) := by
    rw [hA, ← hM]
    -- (M−1)(M−1) = M·(M−1) − 1·(M−1) = (M·M − M) − (M − 1)
    refine Req_trans (Rmul_sub_distrib_right M one (Rsub M one)) ?_
    refine Req_trans (Rsub_congr (Rmul_sub_distrib M M one)
      (Rone_mul (Rsub M one))) ?_
    refine Req_trans (Rsub_congr (Rsub_congr (Req_refl _) (Rmul_one M)) (Req_refl _)) ?_
    -- (M·M − M) − (M − 1) ≈ (M·M − (M+M)) + 1, then commute & shift
    refine Req_trans (sub_sub_to_add (Rmul M M) M one) ?_
    -- (M·M − (M+M)) + 1 ≈ P + (1 − (M+M))
    rw [← hP]
    -- (P − (M+M)) + 1 ≈ P + (1 − (M+M))
    refine Req_trans (Radd_comm (Rsub P (Radd M M)) one) ?_
    refine Req_trans (Req_symm (Radd_assoc one P (Rneg (Radd M M)))) ?_
    refine Req_trans (Radd_congr (Radd_comm one P) (Req_refl _)) ?_
    exact Radd_assoc P one (Rneg (Radd M M))
  -- Difference CnormSq − A·A ≈ (2u − r) + (2u − r) ≥ 0.
  have hdiff : Req (Rsub (CnormSq (etaDenom s)) (Rmul A A))
      (Radd (Rsub M r) (Rsub M r)) := by
    refine Req_trans (Rsub_congr hCNden2 hAA) ?_
    exact diff_collapse2 P one r M
  have hnonneg : Rnonneg (Rsub (CnormSq (etaDenom s)) (Rmul A A)) :=
    Rnonneg_congr (Req_symm hdiff)
      (Rnonneg_Radd (Rnonneg_Rsub_of_Rle hwre) (Rnonneg_Rsub_of_Rle hwre))
  have hle : Rle (Rmul A A) (CnormSq (etaDenom s)) := Rle_of_Rnonneg_Rsub hnonneg
  exact Pos_mono hle hPosA2

-- ===========================================================================
-- ζ on the critical strip via the η quotient.  `etaDenom_Pos_normSq` GUARANTEES a witness `k` with
-- `Qlt (Qbound k) ((CnormSq (etaDenom s)).seq k)` exists (non-vacuity); the constructive inverse takes that
-- witness explicitly — exactly as `Cinv` is designed and as `EulerMaclaurin` builds `1/(s−1)`.
-- ζ(s) := η(s) · (1 − 2^{1−s})⁻¹, certified by the functional relation `(1 − 2^{1−s}) · ζ = η`.
-- ===========================================================================

/-- **The complex inverse `(1 − 2^{1−s})⁻¹`** on the critical strip, given a non-vanishing witness `k`
    (whose existence is `etaDenom_Pos_normSq`). -/
def etaDenomInv (s : Complex) (k : Nat) (hk : Qlt (Qbound k) ((CnormSq (etaDenom s)).seq k)) : Complex :=
  Cinv (etaDenom s) k hk

/-- **The Riemann ζ on the critical strip** `0 < Re s < 1`: `ζ(s) = η(s) / (1 − 2^{1−s})`, a genuine
    constructive complex number (η via `Ceta`; the inverse via a non-vanishing witness `k`, which
    `etaDenom_Pos_normSq` proves exists for `Re s ≤ σ₁ < 1`). -/
def CzetaStrip (s : Complex) {sb T : Q} (hsbd : 0 < sb.den) (hsb0 : 0 ≤ sb.num) (hTd : 0 < T.den)
    (hT0 : 0 ≤ T.num) (hσ : Rnonneg s.re) (hsb : Rle s.re (ofQ sb hsbd))
    (hT1 : Rle (Rneg (ofQ T hTd)) s.im) (hT2 : Rle s.im (ofQ T hTd)) {τ : Q} (hτn : 0 < τ.num)
    (hτd : 0 < τ.den)
    (hblk : ∀ k, 1 ≤ k → Rle (Rsub (EtaVSum s T hTd (2 ^ (k + 1))) (EtaVSum s T hTd (2 ^ k)))
        (ofQ (mul (Vconst sb T) (qpow (Qinv (add ⟨1, 1⟩ τ)) k))
          (Qmul_den_pos (Vconst_den_pos hsbd hTd)
            (qpow_den_pos (Qinv_den_pos (by simp only [add]; push_cast; omega)) k))))
    (k : Nat) (hk : Qlt (Qbound k) ((CnormSq (etaDenom s)).seq k)) : Complex :=
  Cmul (Ceta s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 hτn hτd hblk) (etaDenomInv s k hk)

/-- **The functional relation** `(1 − 2^{1−s}) · ζ_strip(s) = η(s)` — the certificate that `CzetaStrip`
    satisfies the η-quotient defining relation. Combined with the non-vanishing `etaDenom_Pos_normSq`
    (denominator `≠ 0` for `Re s < 1`) this pins the value uniquely; it is the algebraic relation, not a
    formalization of analyticity (no analyticity/continuation is formalized in this development). -/
theorem CzetaStrip_functional (s : Complex) {sb T : Q} (hsbd : 0 < sb.den) (hsb0 : 0 ≤ sb.num)
    (hTd : 0 < T.den) (hT0 : 0 ≤ T.num) (hσ : Rnonneg s.re) (hsb : Rle s.re (ofQ sb hsbd))
    (hT1 : Rle (Rneg (ofQ T hTd)) s.im) (hT2 : Rle s.im (ofQ T hTd)) {τ : Q} (hτn : 0 < τ.num)
    (hτd : 0 < τ.den)
    (hblk : ∀ k, 1 ≤ k → Rle (Rsub (EtaVSum s T hTd (2 ^ (k + 1))) (EtaVSum s T hTd (2 ^ k)))
        (ofQ (mul (Vconst sb T) (qpow (Qinv (add ⟨1, 1⟩ τ)) k))
          (Qmul_den_pos (Vconst_den_pos hsbd hTd)
            (qpow_den_pos (Qinv_den_pos (by simp only [add]; push_cast; omega)) k))))
    (k : Nat) (hk : Qlt (Qbound k) ((CnormSq (etaDenom s)).seq k)) :
    Ceq (Cmul (etaDenom s)
          (CzetaStrip s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 hτn hτd hblk k hk))
        (Ceta s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 hτn hτd hblk) := by
  let D := etaDenom s
  let η := Ceta s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 hτn hτd hblk
  let Dinv := etaDenomInv s k hk
  -- `D · (η · Dinv) ≈ (η · D) · Dinv ≈ η · (D · Dinv) ≈ η · 1 ≈ η`.
  show Ceq (Cmul D (Cmul η Dinv)) η
  refine Ceq_trans (Ceq_symm (Cmul_assoc D η Dinv)) ?_
  refine Ceq_trans (Cmul_congr (Cmul_comm D η) (Ceq_refl Dinv)) ?_
  refine Ceq_trans (Cmul_assoc η D Dinv) ?_
  refine Ceq_trans (Cmul_congr (Ceq_refl η) (Cmul_Cinv (etaDenom s) k hk)) ?_
  exact Cmul_one η

-- ===========================================================================
-- The CONCRETELY-CONSTRUCTIBLE critical-strip ζ (no `∃`/choice in the η factor), via `CetaW`; plus its
-- non-vacuity at `s = ½` and the uniqueness of the quotient (the denominator being non-vanishing).
-- ===========================================================================

/-- **`ζ(s)` on the critical strip, concretely constructible**: `CzetaStripW = CetaW(s) / (1 − 2^{1−s})`,
    taking an explicit `Re s`-positivity witness `(kσ,hkσ)` for the η factor (`CetaW`, no `∃`/choice) and
    the non-vanishing witness `(k,hk)` for the inverse. The strip membership `Re s < 1` is what makes the
    `(k,hk)` bundle inhabitable — `etaDenom_Pos_normSq` derives it from `Re s ≤ σ₁ < 1`. -/
def CzetaStripW (s : Complex) {sb T : Q} (hsbd : 0 < sb.den) (hsb0 : 0 ≤ sb.num) (hTd : 0 < T.den)
    (hT0 : 0 ≤ T.num) (hσ : Rnonneg s.re) (hsb : Rle s.re (ofQ sb hsbd))
    (hT1 : Rle (Rneg (ofQ T hTd)) s.im) (hT2 : Rle s.im (ofQ T hTd))
    (kσ : Nat) (hkσ : Qlt (Qbound kσ) (s.re.seq kσ))
    (k : Nat) (hk : Qlt (Qbound k) ((CnormSq (etaDenom s)).seq k)) : Complex :=
  Cmul (CetaW s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 kσ hkσ) (etaDenomInv s k hk)

/-- **The functional relation for `CzetaStripW`**: `(1 − 2^{1−s}) · ζ_strip(s) ≈ η(s)` (with `η = CetaW`). -/
theorem CzetaStripW_functional (s : Complex) {sb T : Q} (hsbd : 0 < sb.den) (hsb0 : 0 ≤ sb.num)
    (hTd : 0 < T.den) (hT0 : 0 ≤ T.num) (hσ : Rnonneg s.re) (hsb : Rle s.re (ofQ sb hsbd))
    (hT1 : Rle (Rneg (ofQ T hTd)) s.im) (hT2 : Rle s.im (ofQ T hTd))
    (kσ : Nat) (hkσ : Qlt (Qbound kσ) (s.re.seq kσ))
    (k : Nat) (hk : Qlt (Qbound k) ((CnormSq (etaDenom s)).seq k)) :
    Ceq (Cmul (etaDenom s) (CzetaStripW s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 kσ hkσ k hk))
        (CetaW s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 kσ hkσ) := by
  let D := etaDenom s
  let η := CetaW s hsbd hsb0 hTd hT0 hσ hsb hT1 hT2 kσ hkσ
  let Dinv := etaDenomInv s k hk
  show Ceq (Cmul D (Cmul η Dinv)) η
  refine Ceq_trans (Ceq_symm (Cmul_assoc D η Dinv)) ?_
  refine Ceq_trans (Cmul_congr (Cmul_comm D η) (Ceq_refl Dinv)) ?_
  refine Ceq_trans (Cmul_assoc η D Dinv) ?_
  refine Ceq_trans (Cmul_congr (Ceq_refl η) (Cmul_Cinv (etaDenom s) k hk)) ?_
  exact Cmul_one η

/-- **Uniqueness of the quotient**: with the denominator non-vanishing (witness `k,hk`), any two solutions
    of `(1 − 2^{1−s})·z ≈ w` are `≈`-equal. So `CzetaStripW` is *the* value pinned by the functional
    relation, not merely *a* solution — `x ≈ (1−2^{1−s})⁻¹·D·x ≈ (1−2^{1−s})⁻¹·w ≈ y`. -/
theorem etaDenom_cancel (s : Complex) (k : Nat) (hk : Qlt (Qbound k) ((CnormSq (etaDenom s)).seq k))
    (x y w : Complex) (hx : Ceq (Cmul (etaDenom s) x) w) (hy : Ceq (Cmul (etaDenom s) y) w) :
    Ceq x y := by
  -- left inverse: `Cinv D · D ≈ 1` (from `D · Cinv D ≈ 1` by commutativity)
  have hLinv : Ceq (Cmul (Cinv (etaDenom s) k hk) (etaDenom s)) Cone :=
    Ceq_trans (Cmul_comm (Cinv (etaDenom s) k hk) (etaDenom s)) (Cmul_Cinv (etaDenom s) k hk)
  have hrecover : ∀ z, Ceq (Cmul (Cinv (etaDenom s) k hk) (Cmul (etaDenom s) z)) z := by
    intro z
    refine Ceq_trans (Ceq_symm (Cmul_assoc (Cinv (etaDenom s) k hk) (etaDenom s) z)) ?_
    exact Ceq_trans (Cmul_congr hLinv (Ceq_refl z)) (Ceq_trans (Cmul_comm Cone z) (Cmul_one z))
  exact Ceq_trans (Ceq_symm (hrecover x))
    (Ceq_trans (Cmul_congr (Ceq_refl _) hx)
      (Ceq_trans (Cmul_congr (Ceq_refl _) (Ceq_symm hy)) (hrecover y)))

/-- **Non-vacuity of the critical-strip ζ at `s = ½`**: the non-vanishing witness `(k,hk)` for the
    denominator `1 − 2^{1−s}` provably EXISTS at `s = ½` (derived from `Re s = ½ ≤ ¾ < 1` via
    `etaDenom_Pos_normSq`), and the η factor `CetaW sHalf … 2 …` is already a concrete value
    (`CetaW_half_wellTyped`). So `CzetaStripW sHalf … 2 … k hk` is a genuine constructive `ζ(½)` — the
    critical-strip ζ is not vacuous. (`sHalf` is on the critical line, where RH lives.) -/
theorem CzetaStrip_half_nonvacuous :
    ∃ k : Nat, Qlt (Qbound k) ((CnormSq (etaDenom sHalf)).seq k) := by
  have hσs : Rle sHalf.re (ofQ (⟨3, 4⟩ : Q) (by decide)) := by
    show Rle (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨3, 4⟩ : Q) (by decide))
    exact Rle_ofQ_ofQ (by decide) (by decide) (by decide)
  exact etaDenom_Pos_normSq sHalf (σ₁ := ⟨3, 4⟩) (by decide) (by decide) hσs

end UOR.Bridge.F1Square.Analysis
