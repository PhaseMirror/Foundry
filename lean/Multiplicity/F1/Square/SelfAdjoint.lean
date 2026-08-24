/-
F1 square — **the pre-Hilbert layer, brick 2** (`SelfAdjoint.lean`): kernels as OPERATORS on the
truncated inner-product space, and finite self-adjointness.

`applyN B c N = (Σ_{j<N} B(i,j)·cⱼ)ᵢ` is the truncated action of a kernel on a test family, and:

- `weilQuad_eq_inner` — the Weil quadratic form IS the inner product against the operator action,
  `weilQuad B c N ≈ ⟨c, B·c⟩_N`: the form-positivity language of `WeilPSD` and the operator
  language of the Hilbert layer are the same thing at every truncation.
- `applyN_self_adjoint` — a SYMMETRIC kernel is self-adjoint: `⟨B·c, d⟩_N ≈ ⟨c, B·d⟩_N`, by the
  finite Fubini exchange (`RsumN_swap`, built here for the constructive reals) plus monomial
  reassociation.
- The Sonine skeleton instance: the Weil multiplier form `multForm α` is symmetric
  (`multForm_sym`), acts DIAGONALLY (`applyN_multForm`: `(multForm α)·c ≈ (α·c)` at each index),
  and is self-adjoint (`multForm_self_adjoint`); Gate B's Euclidean Grams are symmetric too
  (`gramOf_sym`). So the discrete Weil pairing of `SonineProjection` is now literally a
  self-adjoint operator's quadratic form on the pre-Hilbert space — the language step 4 (the
  band-coupling positivity) has to be phrased in.

WHY (the Sonine route, step 3). The missing Hilbert layer named by the route is "no L², no
completeness, no self-adjoint operators". Brick 1 (`PreHilbert.lean`) built the inner product and
Cauchy–Schwarz; this brick supplies the operator/self-adjointness piece at the same
finite-truncation substrate. What remains of the layer is the completion axis (L²) and the genuine
`f, f̂` transform pair over the certified integral.

HONEST SCOPE. Finite-truncation operator algebra only; no completeness, no spectral theorem, no
unbounded operators. Self-adjointness here is the finite symmetric-kernel fact, not an
infinite-dimensional extension theory. Nothing touches the crux fields; they stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.PreHilbert
import Multiplicity.F1.Square.SonineProjection

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The finite Fubini exchange for the constructive reals.
-- ===========================================================================

/-- **Fubini for finite real sums**: `Σ_{i<N} Σ_{j<M} F(i,j) ≈ Σ_{j<M} Σ_{i<N} F(i,j)`. -/
theorem RsumN_swap (F : Nat → Nat → Real) (N M : Nat) :
    Req (RsumN (fun i => RsumN (fun j => F i j) M) N)
        (RsumN (fun j => RsumN (fun i => F i j) N) M) := by
  induction N with
  | zero => exact Req_symm (RsumN_zero M (fun j _ => Req_refl zero))
  | succ n ih =>
    refine Req_trans (Radd_congr ih (Req_refl _)) ?_
    exact Req_symm (RsumN_add (fun j => RsumN (fun i => F i j) n) (fun j => F n j) M)

-- ===========================================================================
-- Kernels as operators; the quadratic form as an inner product.
-- ===========================================================================

/-- The **truncated operator action** of a kernel on a test family:
    `(applyN B c N)(i) = Σ_{j<N} B(i,j)·cⱼ`. -/
def applyN (B : Nat → Nat → Real) (c : Nat → Real) (N : Nat) : Nat → Real :=
  fun i => RsumN (fun j => Rmul (B i j) (c j)) N

/-- **The Weil quadratic form is the inner product against the operator action**:
    `weilQuad B c N ≈ ⟨c, B·c⟩_N`. The `WeilPSD` form language and the operator language of
    the Hilbert layer coincide at every truncation. -/
theorem weilQuad_eq_inner (B : Nat → Nat → Real) (c : Nat → Real) (N : Nat) :
    Req (weilQuad B c N) (innerN c (applyN B c N) N) := by
  refine RsumN_congr N (fun i _ => ?_)
  refine Req_symm (Req_trans (Rmul_RsumN_left (c i) (fun j => Rmul (B i j) (c j)) N) ?_)
  exact RsumN_congr N (fun j _ => Rmul_congr (Req_refl _) (Rmul_comm (B i j) (c j)))

-- ===========================================================================
-- Symmetric kernels and finite self-adjointness.
-- ===========================================================================

/-- A kernel is **symmetric** when `B(i,j) ≈ B(j,i)` — the hypothesis under which the operator
    action is self-adjoint. -/
def SymKernel (B : Nat → Nat → Real) : Prop :=
  ∀ i j, Req (B i j) (B j i)

/-- **FINITE SELF-ADJOINTNESS**: a symmetric kernel's action satisfies
    `⟨B·c, d⟩_N ≈ ⟨c, B·d⟩_N` — the Fubini exchange moves the sum through, symmetry flips the
    kernel, and monomial reassociation closes. The self-adjointness piece of the step-3 layer,
    at the truncated level. -/
theorem applyN_self_adjoint {B : Nat → Nat → Real} (hB : SymKernel B)
    (c d : Nat → Real) (N : Nat) :
    Req (innerN (applyN B c N) d N) (innerN c (applyN B d N) N) := by
  refine Req_trans (RsumN_congr N (fun i _ => Req_symm
    (RsumN_mul_const (fun j => Rmul (B i j) (c j)) (d i) N))) ?_
  refine Req_trans (RsumN_swap (fun i j => Rmul (Rmul (B i j) (c j)) (d i)) N N) ?_
  refine RsumN_congr N (fun i _ => ?_)
  refine Req_symm (Req_trans (Rmul_RsumN_left (c i) (fun j => Rmul (B i j) (d j)) N) ?_)
  refine RsumN_congr N (fun j _ => ?_)
  -- `cᵢ·(B(i,j)·dⱼ) ≈ (B(j,i)·cᵢ)·dⱼ`
  refine Req_symm ?_
  refine Req_trans (Rmul_congr (Rmul_congr (hB j i) (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Rmul_congr (Rmul_comm (B i j) (c i)) (Req_refl _)) ?_
  exact Rmul_assoc (c i) (B i j) (d j)

/-- Every Euclidean Gram (`Gate B`'s object) is a symmetric kernel. -/
theorem gramOf_sym (ι : Nat → Nat → Real) (D : Nat) : SymKernel (gramOf ι D) :=
  fun i j => RsumN_congr D (fun k _ => Rmul_comm (ι i k) (ι j k))

-- ===========================================================================
-- The Sonine skeleton instance: the multiplier form as a self-adjoint diagonal operator.
-- ===========================================================================

/-- The Weil multiplier form is a symmetric kernel. -/
theorem multForm_sym (α : Nat → Real) : SymKernel (multForm α) := by
  intro i j
  by_cases h : i = j
  · subst h; exact Req_refl _
  · show Req (if i = j then α i else zero) (if j = i then α j else zero)
    rw [if_neg h, if_neg (fun hh => h hh.symm)]
    exact Req_refl zero

/-- **The multiplier acts diagonally**: `((multForm α)·c)(i) ≈ α(i)·cᵢ` for `i < N` — the
    spectral-multiplier reading of the Weil pairing, now as an operator statement (sifting). -/
theorem applyN_multForm (α c : Nat → Real) {i N : Nat} (h : i < N) :
    Req (applyN (multForm α) c N i) (Rmul (α i) (c i)) := by
  refine Req_trans (RsumN_congr N (fun j _ => Rmul_comm (multForm α i j) (c j))) ?_
  exact Req_trans (RsumN_sift i c (α i) N h) (Rmul_comm (c i) (α i))

/-- **The discrete Weil pairing is a self-adjoint operator's form**: `multForm α` is
    self-adjoint on the pre-Hilbert space, `⟨(multForm α)·c, d⟩_N ≈ ⟨c, (multForm α)·d⟩_N` —
    the language the band-coupling positivity (step 4) has to be phrased in, now available. -/
theorem multForm_self_adjoint (α : Nat → Real) (c d : Nat → Real) (N : Nat) :
    Req (innerN (applyN (multForm α) c N) d N) (innerN c (applyN (multForm α) d N) N) :=
  applyN_self_adjoint (multForm_sym α) c d N

/-- The Burnol pairing (`SonineProjection`'s object) as `⟨c, (multForm α)·c⟩_N` — the skeleton's
    quadratic form, in operator form. -/
theorem burnol_pairing_eq_inner (α : Nat → Real) (c : Nat → Real) (N : Nat) :
    Req (weilQuad (multForm α) c N) (innerN c (applyN (multForm α) c N) N) :=
  weilQuad_eq_inner (multForm α) c N

end Multiplicity.UOR.Bridge.F1Square.Square
