/-
F1 square — **dimension-invariance of the rational polynomial test** (`QPolyDimInv.lean`), a brick-6
substrate lemma of the Hausdorff *sufficiency* arc. The polynomial test `qPolyTest c hc d = Σ_{i<d} c_i·xⁱ`
carries a truncation dimension `d`. As an `L²` object it only sees the coefficients `c_0,…,c_{d-1}`, so
if `c` *vanishes* from index `D` on, every dimension `d ≥ D` gives the *same* pairing against any test:

  `innerI_qPolyTest_dim_inv` :  `c` supported on `[0,D)`, `D ≤ d`  ⟹  `⟨ψ, qPolyTest c d⟩ = ⟨ψ, qPolyTest c D⟩`.

Distribute the pairing over the finite sum (`innerI_L2sumN`); the extra monomials `c_i·xⁱ` for `i ≥ D`
pair to zero (their rational coefficient `c_i` is `0`, so `innerI_constMul` scales the monomial pairing
by `ofQ c_i ≈ 0`), so the `RsumN` past `D` is inert — a clean induction on the gap `d − D`.

This is exactly what lets a *fixed*, finitely-supported coefficient vector (the Riesz projection `p_N`,
supported on `[0,N]`) be read as an `L²` test at *any* dimension `d ≥ N+1` and give the same value — the
test-level companion of `qHil_trunc_eq` (brick 3.5a), and the tool that brings two Riesz projections of
different degree to a common dimension in the convergence brick.

HONEST SCOPE. Dimension-stability of the *finite* polynomial test's pairing under support — pure
`L²`-linearity over `ℚ`-coefficient monomials. This is NOT the Riesz convergence / L²-limit (which
additionally needs a supplied Bessel convergence modulus — the next brick), NOT positivity. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.QPolyMember
import Multiplicity.F1Square.Square.ConstScale
import Multiplicity.F1Square.Square.MomentReconSum

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small real / embedding helpers (private).
-- ===========================================================================

/-- `0 · x ≈ 0`. -/
private theorem Rzero_mul (x : Real) : Req (Rmul zero x) zero :=
  Req_trans (Rmul_comm zero x) (Rmul_zero x)

/-- An embedded rational `ℚ`-equal to `0` is the real `zero`. -/
private theorem ofQ_zero {q : Q} (hq : 0 < q.den) (h : Qeq q (⟨0, 1⟩ : Q)) :
    Req (ofQ q hq) zero :=
  Req_of_seq_Qeq (fun _ => h)

/-- A monomial with a zero coefficient pairs to zero: `c ≈ 0 ⟹ ⟨ψ, c·xⁱ⟩ ≈ 0`. -/
private theorem innerI_qMono_zero (ψ : L2Test) (q : Q) (hq : 0 < q.den) (i : Nat)
    (hq0 : Qeq q (⟨0, 1⟩ : Q)) : Req (innerI ψ (qMonoTest q hq i)) zero := by
  refine Req_trans (innerI_constMul ψ (powTest i) (ofQ q hq) (Qabs_den_pos hq)
    (Qabs_num_nonneg q) (Rle_of_Req (Rabs_ofQ hq))) ?_
  refine Req_trans (Rmul_congr (ofQ_zero hq hq0) (Req_refl _)) ?_
  exact Rzero_mul (innerI ψ (powTest i))

/-- A finite real sum is inert past the support: `f i ≈ 0` for `i ≥ D` ⟹ `Σ_{i<D+n} f = Σ_{i<D} f`. -/
private theorem RsumN_trunc (f : Nat → Real) (D : Nat) (hz : ∀ i, D ≤ i → Req (f i) zero) :
    ∀ n, Req (RsumN f (D + n)) (RsumN f D) := by
  intro n
  induction n with
  | zero => exact Req_refl _
  | succ n ih =>
    refine Req_trans ?_ ih
    show Req (Radd (RsumN f (D + n)) (f (D + n))) (RsumN f (D + n))
    exact Req_trans (Radd_congr (Req_refl _) (hz (D + n) (Nat.le_add_right D n)))
      (Radd_zero (RsumN f (D + n)))

-- ===========================================================================
-- ★ Dimension-invariance of the polynomial test's pairing.
-- ===========================================================================

/-- **★ DIMENSION-INVARIANCE**: if the coefficient vector `c` vanishes at every index `≥ D`, the
    polynomial test pairs to the same value at any truncation dimension `d ≥ D`. -/
theorem innerI_qPolyTest_dim_inv (ψ : L2Test) (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (D : Nat)
    (hsupp : ∀ i, D ≤ i → Qeq (c i) (⟨0, 1⟩ : Q)) (d : Nat) (hd : D ≤ d) :
    Req (innerI ψ (qPolyTest c hc d)) (innerI ψ (qPolyTest c hc D)) := by
  obtain ⟨n, rfl⟩ := Nat.le.dest hd
  refine Req_trans (innerI_L2sumN ψ (fun i => qMonoTest (c i) (hc i) i) (D + n)) ?_
  refine Req_trans ?_ (Req_symm (innerI_L2sumN ψ (fun i => qMonoTest (c i) (hc i) i) D))
  exact RsumN_trunc (fun i => innerI ψ (qMonoTest (c i) (hc i) i)) D
    (fun i hi => innerI_qMono_zero ψ (c i) (hc i) i (hsupp i hi)) n

end Multiplicity.UOR.Bridge.F1Square.Square
