/-
F1 square — **the pre-Hilbert layer, brick 17** (`UniformCompletion.lean`): **THE
TRUNCATION-UNIFORM COMPLETION** — one constructed limit member converging at every truncation
simultaneously.

Brick 15 built the limit member at a FIXED truncation. The key structural fact making the
infinite-dimensional statement possible is COHERENCE: the limit coordinates do not depend on
the truncation they were built at —

- `limMember_coherent` — for `i < N` and `i < N'`, `limMember F N i ≈ limMember F N' i`: both
  are Bishop limits of sequences pointwise `≈ F j i` (the coefficient IS the coordinate at
  every truncation containing `i`), and `Rlim` respects pointwise `≈`.
- `limMemberU` — the DIAGONAL member: coordinate `i` is built at truncation `i+1`. By
  coherence it agrees with every fixed-truncation member on its range (`limMemberU_eq`).
- **`limMemberU_converges`** — for a truncation-UNIFORM squared-Cauchy sequence (`SqCauchyU`,
  the same canonical modulus at every `N`), the ONE member `limMemberU` satisfies
  `d²(F j, limMemberU) ≤ N·(2/(j+1))²` at EVERY truncation `N` — strong convergence of a
  single infinite object, uniformly constructed, choice-free.

WHY (the Sonine route, step 3). This removes the "fixed truncation" fence from brick 15: the
completed object is genuinely infinite-dimensional (one member, all truncations), assembled
from the coherent coordinate system — the direct-limit structure the layer has used since
`WeilPSD`'s `∀ N` now carries its completion. What remains on the completeness axis is only
the `L²` (function-space) strong completeness.

HONEST SCOPE. The rate `N·(2/(j+1))²` grows with the truncation — convergence is per-`N` with
a uniform CONSTRUCTION, not a truncation-uniform RATE (that would need summable coordinate
weights, i.e. genuine ℓ² data; fenced open). The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.Completion

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Truncation-uniform squared-Cauchy**: the canonical modulus at every truncation. -/
def SqCauchyU (F : Nat → Nat → Real) : Prop := ∀ N, SqCauchy F N

/-- **The limit coordinates are truncation-coherent**: for `i` inside both truncations, the
    members built at `N` and `N'` agree at `i` — both are Bishop limits of sequences pointwise
    `≈ F j i`. -/
theorem limMember_coherent {F : Nat → Nat → Real} {N N' : Nat}
    (hFN : SqCauchy F N) (hFN' : SqCauchy F N') {i : Nat} (hi : i < N) (hi' : i < N') :
    Req (limMember F N hFN i) (limMember F N' hFN' i) :=
  Rlim_congr _ _ (pairing_RReg (sqCauchy_pairing hFN i))
    (pairing_RReg (sqCauchy_pairing hFN' i))
    (fun j => Req_trans (fourierC_indic (F j) hi) (Req_symm (fourierC_indic (F j) hi')))

/-- **The diagonal member**: coordinate `i` built at truncation `i+1` — one infinite object. -/
def limMemberU (F : Nat → Nat → Real) (hF : SqCauchyU F) : Nat → Real :=
  fun i => limMember F (i + 1) (hF (i + 1)) i

/-- The diagonal member agrees with every fixed-truncation member on its range. -/
theorem limMemberU_eq {F : Nat → Nat → Real} (hF : SqCauchyU F) {N i : Nat} (hi : i < N) :
    Req (limMemberU F hF i) (limMember F N (hF N) i) :=
  limMember_coherent (hF (i + 1)) (hF N) (Nat.lt_succ_self i) hi

/-- **THE TRUNCATION-UNIFORM STRONG COMPLETENESS**: the single constructed member `limMemberU`
    converges to the Cauchy sequence in `dist2` at EVERY truncation:
    `d²(F j, limMemberU) ≤ N·(2/(j+1))²` for all `N, j`. -/
theorem limMemberU_converges {F : Nat → Nat → Real} (hF : SqCauchyU F) (N j : Nat) :
    Rle (dist2 (F j) (limMemberU F hF) N)
        (ofQ (mul (⟨(N : Int), 1⟩ : Q) (mul (⟨2, j + 1⟩ : Q) (⟨2, j + 1⟩ : Q)))
          (Qmul_den_pos Nat.one_pos (Qmul_den_pos (Nat.succ_pos j) (Nat.succ_pos j)))) := by
  refine Rle_trans (Rle_of_Req (innerN_congr N
    (fun i hi => Rsub_congr (Req_refl (F j i)) (limMemberU_eq hF hi))
    (fun i hi => Rsub_congr (Req_refl (F j i)) (limMemberU_eq hF hi)))) ?_
  exact limMember_converges (hF N) j

end Multiplicity.UOR.Bridge.F1Square.Square
