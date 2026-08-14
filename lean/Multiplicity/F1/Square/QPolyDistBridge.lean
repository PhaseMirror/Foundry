/-
F1 square — **the L²-distance of two polynomial tests is the rational Hilbert form of their difference**
(`QPolyDistBridge.lean`), a brick-6 substrate lemma of the Hausdorff *sufficiency* arc. At a common
truncation dimension `D` the squared `L²`-distance of two `ℚ`-coefficient polynomial tests is the
embedded rational Hilbert form of their coefficient difference:

  `qPolyTest_dist2I` :  `d²(qPolyTest cN D, qPolyTest cM D) = ofQ (qHil (cN − cM) (cN − cM) D)`.

Expand `d² = ⟨φ−ψ, φ−ψ⟩` into the four Gram pairings by `L²`-bilinearity (`innerI_sub_left`,
`innerI_sub_right`), read each as the embedded rational Hilbert form (`innerI_qPolyTest_qPolyTest`,
the bridge), combine the four embedded rationals (`Rsub_ofQ_ofQ`), and recognise the resulting rational
four-term as `qHil` of the pointwise difference by `qHil`-bilinearity. Unconditional — no orthogonality,
no `M ≤ N`, pure algebra.

Composed with the Bessel-tail identity (`pVec_diff_normSq`, brick 5.5) this reads the squared increment
of the Riesz projections as `ofQ (‖p_N‖² − ‖p_M‖²)`, which is what the convergence brick bounds by a
supplied rational modulus.

HONEST SCOPE. The identification of the *finite* test's squared `L²`-distance with the rational Hilbert
form of the coefficient difference at a *fixed* dimension — unconditional bilinearity. This is NOT the
Riesz convergence / L²-limit (needs the dimension-independent family, dimension-invariance, and a
supplied Bessel convergence modulus), NOT positivity. Step 4 (band-coupling positivity) is RH; the crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.QHilbertForm
import Multiplicity.F1Square.Square.QHilbertBilinear
import Multiplicity.F1Square.Square.ContinuousMomentTailBound

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- `qHil` over a pointwise difference (private bilinearity helpers).
-- ===========================================================================

/-- `qHil (a − b) c' d = qHil a c' d − qHil b c' d`. -/
private theorem qHil_sub_left (a b c' : Nat → Q) (ha : ∀ i, 0 < (a i).den) (hb : ∀ i, 0 < (b i).den)
    (hc' : ∀ i, 0 < (c' i).den) (d : Nat) :
    Qeq (qHil (fun i => Qsub (a i) (b i)) c' d) (Qsub (qHil a c' d) (qHil b c' d)) := by
  show Qeq (qHil (fun i => add (a i) (neg (b i))) c' d) (Qsub (qHil a c' d) (qHil b c' d))
  refine Qeq_trans (b := add (qHil a c' d) (qHil (fun i => neg (b i)) c' d))
    (add_den_pos (qHil_den_pos a c' ha hc' d)
      (qHil_den_pos (fun i => neg (b i)) c' (fun i => neg_den_pos (hb i)) hc' d))
    (qHil_add_left a (fun i => neg (b i)) c' ha (fun i => neg_den_pos (hb i)) hc' d) ?_
  exact Qadd_congr (Qeq_refl _) (qHil_neg_left b c' hb hc' d)

/-- `qHil c (a − b) d = qHil c a d − qHil c b d`. -/
private theorem qHil_sub_right (c a b : Nat → Q) (hc : ∀ i, 0 < (c i).den) (ha : ∀ i, 0 < (a i).den)
    (hb : ∀ i, 0 < (b i).den) (d : Nat) :
    Qeq (qHil c (fun j => Qsub (a j) (b j)) d) (Qsub (qHil c a d) (qHil c b d)) := by
  show Qeq (qHil c (fun j => add (a j) (neg (b j))) d) (Qsub (qHil c a d) (qHil c b d))
  refine Qeq_trans (b := add (qHil c a d) (qHil c (fun j => neg (b j)) d))
    (add_den_pos (qHil_den_pos c a hc ha d)
      (qHil_den_pos c (fun j => neg (b j)) hc (fun j => neg_den_pos (hb j)) d))
    (qHil_add_right c a (fun j => neg (b j)) hc ha (fun j => neg_den_pos (hb j)) d) ?_
  exact Qadd_congr (Qeq_refl _) (qHil_neg_right c b hc hb d)

/-- The four-term expansion of `qHil` on a pointwise difference: `⟨cN−cM, cN−cM⟩ =
    (⟨cN,cN⟩ − ⟨cN,cM⟩) − (⟨cM,cN⟩ − ⟨cM,cM⟩)`. -/
private theorem qHil_diff_four (cN cM : Nat → Q) (hcN : ∀ i, 0 < (cN i).den)
    (hcM : ∀ i, 0 < (cM i).den) (D : Nat) :
    Qeq (qHil (fun i => Qsub (cN i) (cM i)) (fun i => Qsub (cN i) (cM i)) D)
      (Qsub (Qsub (qHil cN cN D) (qHil cN cM D)) (Qsub (qHil cM cN D) (qHil cM cM D))) := by
  have hdiff : ∀ i, 0 < ((fun i => Qsub (cN i) (cM i)) i).den :=
    fun i => add_den_pos (hcN i) (neg_den_pos (hcM i))
  refine Qeq_trans
    (b := Qsub (qHil cN (fun i => Qsub (cN i) (cM i)) D) (qHil cM (fun i => Qsub (cN i) (cM i)) D))
    (add_den_pos (qHil_den_pos cN _ hcN hdiff D) (neg_den_pos (qHil_den_pos cM _ hcM hdiff D)))
    (qHil_sub_left cN cM (fun i => Qsub (cN i) (cM i)) hcN hcM hdiff D) ?_
  exact Qsub_congr (qHil_sub_right cN cN cM hcN hcN hcM D) (qHil_sub_right cM cN cM hcM hcN hcM D)

-- ===========================================================================
-- ★ The L²-distance ↔ rational Hilbert form of the difference.
-- ===========================================================================

/-- **★ THE DISTANCE BRIDGE**: `d²(qPolyTest cN D, qPolyTest cM D) = ofQ (qHil (cN − cM) (cN − cM) D)`.
    Expand the squared distance into the four Gram pairings, read each off the bridge, combine the
    embedded rationals, and recognise the four-term as `qHil` of the pointwise difference. -/
theorem qPolyTest_dist2I (cN cM : Nat → Q) (hcN : ∀ i, 0 < (cN i).den) (hcM : ∀ i, 0 < (cM i).den)
    (D : Nat) :
    Req (dist2I (qPolyTest cN hcN D) (qPolyTest cM hcM D))
      (ofQ (qHil (fun i => Qsub (cN i) (cM i)) (fun i => Qsub (cN i) (cM i)) D)
        (qHil_den_pos _ _ (fun i => add_den_pos (hcN i) (neg_den_pos (hcM i)))
          (fun i => add_den_pos (hcN i) (neg_den_pos (hcM i))) D)) := by
  have dA : 0 < (qHil cN cN D).den := qHil_den_pos cN cN hcN hcN D
  have dB : 0 < (qHil cN cM D).den := qHil_den_pos cN cM hcN hcM D
  have dC : 0 < (qHil cM cN D).den := qHil_den_pos cM cN hcM hcN D
  have dE : 0 < (qHil cM cM D).den := qHil_den_pos cM cM hcM hcM D
  -- Step 1+2: bilinearity of innerI into the four Gram pairings
  refine Req_trans (innerI_sub_left (qPolyTest cN hcN D) (qPolyTest cM hcM D)
    (L2Test.sub (qPolyTest cN hcN D) (qPolyTest cM hcM D))) ?_
  refine Req_trans (Rsub_congr
    (innerI_sub_right (qPolyTest cN hcN D) (qPolyTest cN hcN D) (qPolyTest cM hcM D))
    (innerI_sub_right (qPolyTest cM hcM D) (qPolyTest cN hcN D) (qPolyTest cM hcM D))) ?_
  -- Step 3: read each pairing off the bridge
  refine Req_trans (Rsub_congr
    (Rsub_congr (innerI_qPolyTest_qPolyTest cN cN hcN hcN D)
      (innerI_qPolyTest_qPolyTest cN cM hcN hcM D))
    (Rsub_congr (innerI_qPolyTest_qPolyTest cM cN hcM hcN D)
      (innerI_qPolyTest_qPolyTest cM cM hcM hcM D))) ?_
  -- Step 4: combine the four embedded rationals into one ofQ
  refine Req_trans (Rsub_congr (Rsub_ofQ_ofQ dA dB) (Rsub_ofQ_ofQ dC dE)) ?_
  refine Req_trans (Rsub_ofQ_ofQ (add_den_pos dA (neg_den_pos dB)) (add_den_pos dC (neg_den_pos dE))) ?_
  -- Step 5: the rational four-term is qHil of the pointwise difference
  exact Req_of_seq_Qeq (fun _ => Qeq_symm (qHil_diff_four cN cM hcN hcM D))

end Multiplicity.UOR.Bridge.F1Square.Square
