/-
F1 square — **the coupled Weil form is antitone in the prime band** (`CoupledWeilMono.lean`): the
structural reason the dominance cannot be certified by any finite prime truncation. The coupled kernel
`coupledWeil arch w v M = multForm arch − primeGram w v M` subtracts the prime Gram; since (for
nonnegative weights) each added prime-power contributes a **weighted square**, enlarging the band `M`
only **increases** the subtracted prime energy and hence **decreases** the coupled quadratic form. So a
dominance that holds against a finite prime cutoff can fail against the full prime side — the dominance
must be established against ALL prime-powers at once. This is the prime-side analogue of the
infinite-rank fence (`AngleEmbeddingBound.lean`): just as the `Σ_ρ` over zeros cannot be truncated, the
`Σ_m` over prime-powers cannot be truncated.

THE LAWS (all genuine, kernel-checked):
  • `coupledWeil_quad_split` — the form-level split `weilQuad (coupledWeil) = weilQuad (multForm arch) −
    weilQuad (primeGram)` (arch spectral energy minus prime energy), at each test.
  • `coupledWeil_quad_nonneg_iff` — the **per-test** dominance atom: `Rnonneg (weilQuad (coupledWeil …)
    c N) ⟺ weilQuad (primeGram …) c N ≤ weilQuad (multForm arch) c N` (the `∀`-quantification is the
    capstone `coupledWeil_psd_iff_dominates`; this is what any finite certificate would discharge).
  • `weilQuad_primeGram_mono` — for `w ≥ 0`, the prime energy is **monotone** in the band: `M ≤ M' ⟹
    weilQuad (primeGram w v M) c N ≤ weilQuad (primeGram w v M') c N` (added terms are weighted squares,
    `RsumN_le_prefix`).
  • `coupledWeil_quad_antitone_M` — hence the coupled form is **antitone** in the band: `M ≤ M' ⟹
    weilQuad (coupledWeil arch w v M') c N ≤ weilQuad (coupledWeil arch w v M) c N`.

HONEST SCOPE. Pure monotonicity algebra on the assembled object; abstract over interface data
`arch, w, v` (no `λ`, no zeros), for `w ≥ 0` (the genuine `vonMangoldt` case is unconditional). NOTHING
asserts the dominance holds at any `M` — these laws say only how the form MOVES as the band grows,
sharpening why the dominance (= RH) cannot be reached by truncating the prime side. Crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.CoupledWeilKernel

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The form-level split**: `weilQuad (coupledWeil arch w v M) c N = weilQuad (multForm arch) c N −
    weilQuad (primeGram w v M) c N` — arch spectral energy minus prime energy, at each test. -/
theorem coupledWeil_quad_split (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (c : Nat → Real) (N : Nat) :
    Req (weilQuad (coupledWeil arch w v M) c N)
        (Rsub (weilQuad (multForm arch) c N) (weilQuad (primeGram w v M) c N)) :=
  weilQuad_sub (multForm arch) (primeGram w v M) c N

/-- **The per-test dominance atom**: the coupled form is `≥ 0` at a given test IFF the prime energy is
    dominated by the arch spectral energy there — `Rnonneg (weilQuad (coupledWeil …) c N) ⟺
    weilQuad (primeGram …) c N ≤ weilQuad (multForm arch) c N`. -/
theorem coupledWeil_quad_nonneg_iff (arch w : Nat → Real) (v : Nat → Nat → Real) (M : Nat)
    (c : Nat → Real) (N : Nat) :
    Rnonneg (weilQuad (coupledWeil arch w v M) c N)
      ↔ Rle (weilQuad (primeGram w v M) c N) (weilQuad (multForm arch) c N) := by
  constructor
  · intro h
    exact Rle_of_Rnonneg_Rsub (Rnonneg_congr (coupledWeil_quad_split arch w v M c N) h)
  · intro h
    exact Rnonneg_congr (Req_symm (coupledWeil_quad_split arch w v M c N)) (Rnonneg_Rsub_of_Rle h)

/-- **The prime energy is monotone in the band** (for `w ≥ 0`): enlarging `M` only adds weighted
    squares, so `M ≤ M' ⟹ weilQuad (primeGram w v M) c N ≤ weilQuad (primeGram w v M') c N`. -/
theorem weilQuad_primeGram_mono (w : Nat → Real) (v : Nat → Nat → Real) (c : Nat → Real) (N : Nat)
    (hw : ∀ m, Rnonneg (w m)) {M M' : Nat} (hM : M ≤ M') :
    Rle (weilQuad (primeGram w v M) c N) (weilQuad (primeGram w v M') c N) := by
  refine Rle_trans (Rle_of_Req (weilQuad_primeGram_split w v c N M)) ?_
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (weilQuad_primeGram_split w v c N M')))
  exact RsumN_le_prefix
    (fun m => Rnonneg_Rmul (hw m) (Rnonneg_Rmul_self (RsumN (fun i => Rmul (c i) (v m i)) N))) hM

/-- **★ THE COUPLED FORM IS ANTITONE IN THE PRIME BAND** (for `w ≥ 0`): `M ≤ M' ⟹ weilQuad (coupledWeil
    arch w v M') c N ≤ weilQuad (coupledWeil arch w v M) c N` — more prime-powers, smaller form. So no
    finite prime truncation can certify the dominance; it must hold against the full prime side. -/
theorem coupledWeil_quad_antitone_M (arch w : Nat → Real) (v : Nat → Nat → Real)
    (c : Nat → Real) (N : Nat) (hw : ∀ m, Rnonneg (w m)) {M M' : Nat} (hM : M ≤ M') :
    Rle (weilQuad (coupledWeil arch w v M') c N) (weilQuad (coupledWeil arch w v M) c N) := by
  refine Rle_trans (Rle_of_Req (coupledWeil_quad_split arch w v M' c N)) ?_
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (coupledWeil_quad_split arch w v M c N)))
  -- Rsub A (P M') ≤ Rsub A (P M) since P M ≤ P M'  (subtraction antitone in the subtrahend)
  exact Radd_le_add (Rle_refl (weilQuad (multForm arch) c N))
    (Rle_Rneg (weilQuad_primeGram_mono w v c N hw hM))

end Multiplicity.UOR.Bridge.F1Square.Square
