/-
F1 square — **the pre-Hilbert layer, brick 3** (`Projection.lean`): orthogonal projection and
Bessel's inequality — the PROJECTION MECHANISM of the Sonine route in genuine Hilbert-space form.

For an orthonormal family `e₀ … e_{K−1}` (in the truncated inner product), the Fourier
coefficients `cₖ = ⟨f, eₖ⟩_N` and the projection `Pf = Σ_{k<K} cₖ·eₖ` satisfy:

- `proj_coeff` — `⟨Pf, eₗ⟩_N ≈ cₗ`: the projection reproduces the coefficients (sifting through
  orthonormality).
- `inner_proj` / `proj_self_inner` — `⟨f, Pf⟩_N ≈ Σ cₖ² ≈ ⟨Pf, Pf⟩_N`: the projection identity.
- **`bessel`** — `Σ_{k<K} ⟨f,eₖ⟩² ≤ ⟨f,f⟩_N`: from `⟨f−Pf, f−Pf⟩ ≥ 0` and the expansion
  `⟨f−Pf, f−Pf⟩ ≈ ⟨f,f⟩ − Σ cₖ²` — constructive, sqrt-free, no division.
- `indic_ortho` — the coordinate indicators are orthonormal: the concrete basis the discrete
  skeleton lives on.

THE SONINE INSTANCE. The skeleton's "test family vanishing on the negative band" is now a genuine
PROJECTION OPERATOR: `bandProj` (zeroing the band index) is idempotent (`bandProj_idem`) and
self-adjoint (`bandProj_self_adjoint`) — an orthogonal projection on the pre-Hilbert space — and
the unconditional complement-positivity reads `weilQuad (multForm burnolMult) (bandProj c) N ≥ 0`
for EVERY test family (`bandProj_pairing_nonneg`): pairing ∘ projection ≥ 0, no support hypothesis
left to the caller. This is `SonineProjection`'s dichotomy restated in the operator language the
band-coupling (step 4) has to be phrased in.

HONEST SCOPE. Finite orthonormal families at a fixed truncation; Bessel, not Parseval — no
completeness, no infinite-dimensional projection, no claim the band projection is the genuine
`f, f̂` co-support coupling (it is the skeleton, now in operator form). The crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.SelfAdjoint

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Signed bilinearity plumbing for `innerN`.
-- ===========================================================================

/-- `−0 ≈ 0` (local copy; the global one lives in `ComplexZeta`). -/
private theorem Rneg_zero' : Req (Rneg zero) zero :=
  Req_trans (Req_symm (Req_trans (Radd_comm zero (Rneg zero)) (Radd_zero (Rneg zero))))
    (Radd_neg zero)

/-- `x − 0 ≈ x`. -/
private theorem Rsub_zero' (x : Real) : Req (Rsub x zero) x :=
  Req_trans (Radd_congr (Req_refl x) Rneg_zero') (Radd_zero x)

/-- **Negation in the first slot**: `⟨−f, g⟩_N ≈ −⟨f,g⟩_N`. -/
theorem innerN_neg_left (f g : Nat → Real) (N : Nat) :
    Req (innerN (fun i => Rneg (f i)) g N) (Rneg (innerN f g N)) :=
  Req_trans (RsumN_congr N (fun i _ => Rmul_neg_left (f i) (g i)))
    (RsumN_neg (fun i => Rmul (f i) (g i)) N)

/-- **Subtraction in the first slot**: `⟨f − f', g⟩_N ≈ ⟨f,g⟩_N − ⟨f',g⟩_N`. -/
theorem innerN_sub_left (f f' g : Nat → Real) (N : Nat) :
    Req (innerN (fun i => Rsub (f i) (f' i)) g N) (Rsub (innerN f g N) (innerN f' g N)) :=
  Req_trans (innerN_add_left f (fun i => Rneg (f' i)) g N)
    (Radd_congr (Req_refl _) (innerN_neg_left f' g N))

-- ===========================================================================
-- Orthonormal families, Fourier coefficients, and the projection.
-- ===========================================================================

/-- **Orthonormality** of the family `e` (first `K` members) in the truncated inner product:
    `⟨eₖ, eₗ⟩_N ≈ δₖₗ`. -/
def OrthoFam (e : Nat → Nat → Real) (K N : Nat) : Prop :=
  ∀ k l, k < K → l < K → Req (innerN (e k) (e l) N) (if k = l then one else zero)

/-- The **Fourier coefficient** `cₖ = ⟨f, eₖ⟩_N`. -/
def fourierC (f : Nat → Real) (e : Nat → Nat → Real) (N k : Nat) : Real :=
  innerN f (e k) N

/-- The **projection** onto the span of `e₀ … e_{K−1}`: `(Pf)(i) = Σ_{k<K} cₖ·eₖ(i)`. -/
def projF (e : Nat → Nat → Real) (f : Nat → Real) (K N : Nat) : Nat → Real :=
  fun i => RsumN (fun k => Rmul (fourierC f e N k) (e k i)) K

/-- The projection paired from the right: `⟨g, Pf⟩_N ≈ Σ_{k<K} cₖ·⟨g,eₖ⟩_N` — Fubini plus the
    scalar pulls; no orthonormality needed. -/
theorem inner_proj (e : Nat → Nat → Real) (f g : Nat → Real) (K N : Nat) :
    Req (innerN g (projF e f K N) N)
        (RsumN (fun k => Rmul (fourierC f e N k) (fourierC g e N k)) K) := by
  have hrow : ∀ k, k < K →
      Req (RsumN (fun i => Rmul (g i) (Rmul (fourierC f e N k) (e k i))) N)
          (Rmul (fourierC f e N k) (fourierC g e N k)) := by
    intro k _
    have hterm : ∀ i, i < N → Req (Rmul (g i) (Rmul (fourierC f e N k) (e k i)))
        (Rmul (fourierC f e N k) (Rmul (g i) (e k i))) := by
      intro i _
      refine Req_trans (Req_symm (Rmul_assoc (g i) (fourierC f e N k) (e k i))) ?_
      refine Req_trans (Rmul_congr (Rmul_comm (g i) (fourierC f e N k)) (Req_refl _)) ?_
      exact Rmul_assoc (fourierC f e N k) (g i) (e k i)
    refine Req_trans (RsumN_congr N hterm) ?_
    exact Req_symm (Rmul_RsumN_left (fourierC f e N k) (fun i => Rmul (g i) (e k i)) N)
  refine Req_trans (RsumN_congr N (fun i _ =>
    Rmul_RsumN_left (g i) (fun k => Rmul (fourierC f e N k) (e k i)) K)) ?_
  refine Req_trans (RsumN_swap (fun i k => Rmul (g i) (Rmul (fourierC f e N k) (e k i))) N K) ?_
  exact RsumN_congr K hrow

/-- **The projection reproduces the Fourier coefficients**: `⟨Pf, eₗ⟩_N ≈ cₗ` for `l < K`
    (orthonormality + sifting). -/
theorem proj_coeff {e : Nat → Nat → Real} {K N : Nat} (hE : OrthoFam e K N)
    (f : Nat → Real) {l : Nat} (hl : l < K) :
    Req (innerN (projF e f K N) (e l) N) (fourierC f e N l) := by
  refine Req_trans (innerN_symm (projF e f K N) (e l) N) ?_
  refine Req_trans (inner_proj e f (e l) K N) ?_
  have hrow : ∀ k, k < K → Req (Rmul (fourierC f e N k) (fourierC (e l) e N k))
      (Rmul (fourierC f e N k) (if l = k then one else zero)) :=
    fun k hk => Rmul_congr (Req_refl _) (hE l k hl hk)
  refine Req_trans (RsumN_congr K hrow) ?_
  exact Req_trans (RsumN_sift l (fun k => fourierC f e N k) one K hl)
    (Rmul_one (fourierC f e N l))

/-- The projection's self-inner-product is the coefficient square sum:
    `⟨Pf, Pf⟩_N ≈ Σ_{k<K} cₖ²` (orthonormality). -/
theorem proj_self_inner {e : Nat → Nat → Real} {K N : Nat} (hE : OrthoFam e K N)
    (f : Nat → Real) :
    Req (innerN (projF e f K N) (projF e f K N) N)
        (RsumN (fun k => Rmul (fourierC f e N k) (fourierC f e N k)) K) := by
  refine Req_trans (inner_proj e f (projF e f K N) K N) ?_
  exact RsumN_congr K (fun k hk => Rmul_congr (Req_refl _) (proj_coeff hE f hk))

/-- **BESSEL'S INEQUALITY**: `Σ_{k<K} ⟨f,eₖ⟩_N² ≤ ⟨f,f⟩_N` — the defect is
    `⟨f−Pf, f−Pf⟩_N ≥ 0`, expanded bilinearly; constructive, sqrt-free, no division. The
    finite-rank projection bound every Hilbert-space argument rests on. -/
theorem bessel {e : Nat → Nat → Real} {K N : Nat} (hE : OrthoFam e K N) (f : Nat → Real) :
    Rle (RsumN (fun k => Rmul (fourierC f e N k) (fourierC f e N k)) K) (innerN f f N) := by
  have hS : Req (innerN f (projF e f K N) N)
      (RsumN (fun k => Rmul (fourierC f e N k) (fourierC f e N k)) K) :=
    inner_proj e f f K N
  have hPP : Req (innerN (projF e f K N) (projF e f K N) N)
      (RsumN (fun k => Rmul (fourierC f e N k) (fourierC f e N k)) K) :=
    proj_self_inner hE f
  have hPf : Req (innerN (projF e f K N) f N)
      (RsumN (fun k => Rmul (fourierC f e N k) (fourierC f e N k)) K) :=
    Req_trans (innerN_symm (projF e f K N) f N) hS
  have hX : Req (innerN (fun i => Rsub (f i) (projF e f K N i)) f N)
      (Rsub (innerN f f N)
        (RsumN (fun k => Rmul (fourierC f e N k) (fourierC f e N k)) K)) :=
    Req_trans (innerN_sub_left f (projF e f K N) f N)
      (Rsub_congr (Req_refl _) hPf)
  have hY : Req (innerN (fun i => Rsub (f i) (projF e f K N i)) (projF e f K N) N) zero := by
    refine Req_trans (innerN_sub_left f (projF e f K N) (projF e f K N) N) ?_
    refine Req_trans (Rsub_congr hS hPP) ?_
    exact Radd_neg _
  have h4 : Req (innerN (fun i => Rsub (f i) (projF e f K N i))
      (fun i => Rsub (f i) (projF e f K N i)) N)
      (Rsub (innerN f f N)
        (RsumN (fun k => Rmul (fourierC f e N k) (fourierC f e N k)) K)) := by
    refine Req_trans (innerN_sub_left f (projF e f K N)
      (fun i => Rsub (f i) (projF e f K N i)) N) ?_
    refine Req_trans (Rsub_congr
      (Req_trans (innerN_symm f (fun i => Rsub (f i) (projF e f K N i)) N) hX)
      (Req_trans (innerN_symm (projF e f K N)
        (fun i => Rsub (f i) (projF e f K N i)) N) hY)) ?_
    exact Rsub_zero' _
  exact Rle_of_Rnonneg_Rsub (Rnonneg_congr h4
    (innerN_self_nonneg (fun i => Rsub (f i) (projF e f K N i)) N))

/-- The coordinate indicators are orthonormal: `⟨δₖ, δₗ⟩_N ≈ δₖₗ` for `k, l < K ≤ N` — the
    concrete basis the discrete Sonine skeleton lives on. -/
theorem indic_ortho {K N : Nat} (hKN : K ≤ N) : OrthoFam indic K N :=
  fun k l hk _ => RsumN_indic_mul k (indic l) N (Nat.lt_of_lt_of_le hk hKN)

-- ===========================================================================
-- The Sonine instance: the band restriction as a genuine projection operator.
-- ===========================================================================

/-- The **band projection**: zero out the negative-band index (`1`, where `α(2) < 0` sits),
    keep everything else — the skeleton's support restriction as an OPERATOR. -/
def bandProj (c : Nat → Real) : Nat → Real :=
  fun i => if i = 1 then zero else c i

/-- The band projection vanishes on the band index. -/
theorem bandProj_band (c : Nat → Real) : Req (bandProj c 1) zero :=
  Req_refl zero

/-- The band projection is **idempotent**: `P(Pc) ≈ Pc` pointwise. -/
theorem bandProj_idem (c : Nat → Real) (i : Nat) :
    Req (bandProj (bandProj c) i) (bandProj c i) := by
  by_cases h : i = 1
  · subst h; exact Req_refl zero
  · show Req (if i = 1 then zero else bandProj c i) (bandProj c i)
    rw [if_neg h]
    exact Req_refl _

/-- The band projection is **self-adjoint**: `⟨Pc, d⟩_N ≈ ⟨c, Pd⟩_N` — with idempotence, a
    genuine orthogonal projection on the pre-Hilbert space. -/
theorem bandProj_self_adjoint (c d : Nat → Real) (N : Nat) :
    Req (innerN (bandProj c) d N) (innerN c (bandProj d) N) := by
  refine RsumN_congr N (fun i _ => ?_)
  by_cases h : i = 1
  · subst h
    show Req (Rmul zero (d 1)) (Rmul (c 1) zero)
    exact Req_trans (Req_trans (Rmul_comm zero (d 1)) (Rmul_zero (d 1)))
      (Req_symm (Rmul_zero (c 1)))
  · show Req (Rmul (if i = 1 then zero else c i) (d i))
        (Rmul (c i) (if i = 1 then zero else d i))
    rw [if_neg h, if_neg h]
    exact Req_refl _

/-- **THE SKELETON POSITIVITY, IN PROJECTION-OPERATOR FORM** (unconditional): for EVERY test
    family `c` and truncation `N`, `weilQuad (multForm burnolMult) (bandProj c) N ≥ 0` — the
    Weil pairing composed with the band projection is nonnegative, no support hypothesis left to
    the caller. The projection (idempotent + self-adjoint) is the mechanism; extending the
    positivity past the projected range (the band coupling) is step 4 and is RH — crux `none`. -/
theorem bandProj_pairing_nonneg (c : Nat → Real) (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult) (bandProj c) N) :=
  burnol_pairing_psd_on_sonine (bandProj c) N (bandProj_band c)

end Multiplicity.UOR.Bridge.F1Square.Square
