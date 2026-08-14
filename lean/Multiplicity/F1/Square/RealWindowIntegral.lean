/-
F1 square — **the real-upper-limit window integral** (`RealWindowIntegral.lean`): the partial integral
`∫_0^c φ` to a REAL upper limit `c`, built as the `Rlim` of the rational partials `∫_0^{qk k} φ` along a
supplied positive rational sequence `qk → c` fast enough that the Lipschitz-in-upper-limit continuity
(`riemannIntegralI_upper_lip`) makes the sequence regular.

- `riwSeq φ qk … k = ∫_0^{qk k} φ` — the rational partials (each `qk k > 0`).
- `riwSeq_RReg` — the partials are regular: `RReg_of_real_bound` fed the per-pair bound
  `|∫_0^{qk j} − ∫_0^{qk k}| ≤ φ.M·|qk j − qk k| ≤ 1/(j+1)+1/(k+1)` (upper-limit Lipschitz, both
  orderings by an ordering case split), where the last step is the supplied fast condition `hqk_fast`.
- `riwI φ qk … = Rlim (riwSeq …)` — the real-window integral itself.

WHY. Evaluating the factorization's inner moment `mellinMoment (dilateTestR c f) n = c^{-(n+1)}·∫_0^c
(f·xⁿ)` at a REAL scale `c` needs exactly this real-window integral — the wall-breaker for the
real-scale dilation covariance (the rational-scale covariance `mellinMoment_dilate` /
`general_window_dilate` is already built; the real upper limit is what was missing). `hqk_fast` is a
supplied fast-approximation input; for `c` a real it is discharged by a fast positive diagonal
`qk k = c.seq(idx k)` (as in the covariance's `covComb_hbound_of_fast`).

HONEST SCOPE. The real-window integral OBJECT and its regularity. It builds NO change-of-variables
covariance (`mellinMoment(dilateTestR c f) = c^{-(n+1)}·riwI …`, the next brick), NO half-line
assembly, NO factorization `M[f⋆g]=M[f]·M[g]`, NO positivity, NO crux. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.IntervalUpperLip
import Multiplicity.F1Square.Analysis.ComplexZeta

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `Qlt b a → Qle b a`. -/
private theorem Qle_of_Qlt {a b : Q} (h : Qlt b a) : Qle b a := by
  unfold Qle Qlt at *; omega

/-- `|a − b| ≈ |b − a|` at the rational level. -/
private theorem Qabs_Qsub_comm (a b : Q) : Qeq (Qabs (Qsub a b)) (Qabs (Qsub b a)) := by
  have hneg : Qeq (Qsub a b) (neg (Qsub b a)) := by
    simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor
  have h1 : Qeq (Qabs (Qsub a b)) (Qabs (neg (Qsub b a))) := Qabs_Qeq hneg
  rw [Qabs_neg] at h1
  exact h1

/-- The rational partial integrals `∫_0^{qk k} φ`. -/
def riwSeq (φ : L2Test) (qk : Nat → Q) (hqk_pos : ∀ k, 0 < (qk k).num)
    (hqk_den : ∀ k, 0 < (qk k).den) : Nat → Real :=
  fun k => riemannIntegralI φ.hLd φ.hLn φ.hlip φ.hfc (⟨0, 1⟩ : Q) (qk k)
    (by decide) (hqk_den k) (Int.le_of_lt (hqk_pos k))

/-- **The rational partials are regular.** With `hqk_fast : φ.M·|qk j − qk k| ≤ 1/(j+1)+1/(k+1)`, the
    upper-limit Lipschitz continuity makes `k ↦ ∫_0^{qk k} φ` a regular sequence. -/
theorem riwSeq_RReg (φ : L2Test) (qk : Nat → Q) (hqk_pos : ∀ k, 0 < (qk k).num)
    (hqk_den : ∀ k, 0 < (qk k).den)
    (hqk_fast : ∀ j k, Qle (mul (Qabs (Qsub (qk j) (qk k))) φ.M)
      (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))) :
    RReg (riwSeq φ qk hqk_pos hqk_den) := by
  refine RReg_of_real_bound _ (fun j k => add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
    (fun j k => add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
    (fun j k => Qle_refl _) ?_
  intro j k
  refine Rle_trans (Rle_Rabs_self _) ?_
  rcases Qle_or_Qlt (qk k) (qk j) with hkj | hjk
  · -- qk k ≤ qk j
    refine Rle_trans (riemannIntegralI_upper_lip φ (qk j) (qk k)
      (hqk_den j) (Int.le_of_lt (hqk_pos j)) (hqk_den k) (hqk_pos k) hkj) ?_
    refine Rle_ofQ_ofQ (Qmul_den_pos (Qsub_den_pos (hqk_den j) (hqk_den k)) φ.hMd)
      (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) ?_
    exact Qle_congr_left
      (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos (hqk_den j) (hqk_den k))) φ.hMd)
      (Qmul_congr (Qabs_of_nonneg (Qsub_num_nonneg hkj)) (Qeq_refl _)) (hqk_fast j k)
  · -- qk j < qk k
    refine Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) ?_
    refine Rle_trans (riemannIntegralI_upper_lip φ (qk k) (qk j)
      (hqk_den k) (Int.le_of_lt (hqk_pos k)) (hqk_den j) (hqk_pos j) (Qle_of_Qlt hjk)) ?_
    refine Rle_ofQ_ofQ (Qmul_den_pos (Qsub_den_pos (hqk_den k) (hqk_den j)) φ.hMd)
      (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)) ?_
    have h2 : Qeq (Qabs (Qsub (qk j) (qk k))) (Qsub (qk k) (qk j)) :=
      Qeq_trans (Qabs_den_pos (Qsub_den_pos (hqk_den k) (hqk_den j)))
        (Qabs_Qsub_comm (qk j) (qk k))
        (Qabs_of_nonneg (Qsub_num_nonneg (Qle_of_Qlt hjk)))
    exact Qle_congr_left
      (Qmul_den_pos (Qabs_den_pos (Qsub_den_pos (hqk_den j) (hqk_den k))) φ.hMd)
      (Qmul_congr h2 (Qeq_refl _)) (hqk_fast j k)

/-- **The real-upper-limit window integral** `∫_0^c φ` — the `Rlim` of the rational partials
    `∫_0^{qk k} φ` along a positive fast-approximating sequence `qk → c`. -/
def riwI (φ : L2Test) (qk : Nat → Q) (hqk_pos : ∀ k, 0 < (qk k).num)
    (hqk_den : ∀ k, 0 < (qk k).den)
    (hqk_fast : ∀ j k, Qle (mul (Qabs (Qsub (qk j) (qk k))) φ.M)
      (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))) : Real :=
  Rlim (riwSeq φ qk hqk_pos hqk_den) (riwSeq_RReg φ qk hqk_pos hqk_den hqk_fast)

end Multiplicity.UOR.Bridge.F1Square.Square
