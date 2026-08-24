/-
F1 square — **the diagonal-dominance lever for the coupled kernel** (`CoupledWeilDiagDominant.lean`):
applies the general Gershgorin certificate (`DiagDominant.lean`) to the coupled Weil kernel, giving a
CONCRETE per-`n` sufficient condition for the coupled positivity — the prime off-diagonal row sum
dominated by the archimedean diagonal excess.

The coupled kernel is `coupledWeil arch w v M (i,j) = arch·δ − primeGram`, so its off-diagonal entries
are `−primeGram(i,j)` (`|·| = |primeGram(i,j)|`) and its diagonal is `arch(n) − primeGram(n,n)`. Diagonal
dominance therefore reads: `Σ_{j<N, j≠n} |primeGram(n,j)| ≤ arch(n) − primeGram(n,n)` for every `n`.
Under it the coupled kernel is `WeilPSD` (Gershgorin, `coupledWeil_sym`), hence `LiNonneg`
(`coupledWeil_psd_imp_liNonneg`).

  • `coupledWeil_diagDominant_of_primeRowSum` — the concrete prime-row-sum condition ⟹ `DiagDominant`.
  • `coupledWeil_psd_of_diagDominant` / `coupledWeil_liNonneg_of_primeRowSum` — hence `WeilPSD` / `LiNonneg`.

HONEST SCOPE. This is a SUFFICIENT CONDITION on the prime off-diagonal mass, never asserted to hold; it
is STRICTLY STRONGER than the exact dominance (= RH). Two facts sharpen why it is a fence, not a route to
the genuine data: (1) diagonal dominance implies PSD but PSD does not imply diagonal dominance, so the
genuine coupled kernel may be PSD (RH) without being diagonally dominant. (2) The genuine archimedean
multiplier is ITSELF INDEFINITE (`α(2) < 0`, `burnol_pairing_indefinite`), so the raw `ArchDominatesPrime`
over ALL tests is FALSE (a test on the arch-negative band makes the nonneg prime energy exceed the
negative arch energy) — the abstract capstone's "= RH" holds only under the UNBUILT Sonine-space test
restriction. Diagonal dominance requires the diagonal `arch(n) − primeGram(n,n)` to be nonneg AND to beat
the full absolute prime off-diagonal row mass, which against the classical growth (`2λₙ ~ n log n` vs the
prime mass) is far stronger than mere positivity; its satisfiability at the genuine data is not claimed
and is not expected. A concrete general-infrastructure lever, NOT a discharge. Crux stays `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1.Square.DiagDominant
import Multiplicity.F1.Square.CoupledWeilCrux
import Multiplicity.F1.Square.CoupledWeilOperator

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

/-- Off the diagonal the coupled kernel is `−primeGram`, so `|coupledWeil(i,j)| ≈ |primeGram(i,j)|`. -/
theorem coupledWeil_offAbs_eq (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    {i j : Nat} (h : ¬ i = j) :
    Req (Rabs (coupledWeil arch w v M i j)) (Rabs (primeGram w v M i j)) := by
  refine Req_trans (Rabs_congr ?_) (Rabs_Rneg (primeGram w v M i j))
  show Req (Rsub (multForm arch i j) (primeGram w v M i j)) (Rneg (primeGram w v M i j))
  have hm : multForm arch i j = zero := if_neg h
  rw [hm]
  exact Req_trans (Radd_comm zero (Rneg (primeGram w v M i j))) (Radd_zero _)

/-- **The concrete diagonal-dominance condition for the coupled kernel**: if the prime off-diagonal
    absolute row sum is dominated by the archimedean diagonal excess `arch(n) − primeGram(n,n)` at every
    `n`, the coupled kernel is `DiagDominant`. -/
theorem coupledWeil_diagDominant_of_primeRowSum (arch w : Nat → Real) (v : Nat → Nat → Real) (M N : Nat)
    (h : ∀ i, i < N → Rle (RsumN (fun j => if i = j then zero else Rabs (primeGram w v M i j)) N)
                          (Rsub (arch i) (primeGram w v M i i))) :
    DiagDominant (coupledWeil arch w v M) N := by
  intro i hi
  -- diagonal is arch − prime; off-diagonal abs is |prime|
  have hdiag : coupledWeil arch w v M i i = Rsub (arch i) (primeGram w v M i i) := by
    show Rsub (multForm arch i i) (primeGram w v M i i) = Rsub (arch i) (primeGram w v M i i)
    rw [multForm_diag]
  have hrow : Req (RsumN (fun j => if i = j then zero else Rabs (coupledWeil arch w v M i j)) N)
      (RsumN (fun j => if i = j then zero else Rabs (primeGram w v M i j)) N) := by
    refine RsumN_congr N (fun j _ => ?_)
    by_cases hj : i = j
    · rw [if_pos hj, if_pos hj]; exact Req_refl _
    · rw [if_neg hj, if_neg hj]; exact coupledWeil_offAbs_eq arch w v M hj
  rw [hdiag]
  exact Rle_trans (Rle_of_Req hrow) (h i hi)

/-- Under diagonal dominance the coupled kernel is `WeilPSD` (Gershgorin + `coupledWeil_sym`). -/
theorem coupledWeil_psd_of_diagDominant (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (hdd : ∀ N, DiagDominant (coupledWeil arch w v M) N) : WeilPSD (coupledWeil arch w v M) :=
  WeilPSD_of_diagDominant (coupledWeil arch w v M) (coupledWeil_sym arch w v M) hdd

/-- **★ THE LEVER**: the concrete prime-row-sum domination at every `N` ⟹ `LiNonneg` of the induced
    square — a per-`n`, bracket-checkable SUFFICIENT condition for the (non-strict) crux. Never asserted. -/
theorem coupledWeil_liNonneg_of_primeRowSum (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (h : ∀ N i, i < N → Rle (RsumN (fun j => if i = j then zero else Rabs (primeGram w v M i j)) N)
                            (Rsub (arch i) (primeGram w v M i i))) :
    LiNonneg (weilSpectralSquare (coupledPairing arch w v M)).lam :=
  coupledWeil_psd_imp_liNonneg arch w v M
    (coupledWeil_psd_of_diagDominant arch w v M
      (fun N => coupledWeil_diagDominant_of_primeRowSum arch w v M N (h N)))

end Multiplicity.UOR.Bridge.F1Square.Square
