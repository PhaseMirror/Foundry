/-
F1 square — **the pre-Hilbert layer, brick 34** (`HilbertGram.lean`): **THE HILBERT MATRIX IS
THE GRAM MATRIX OF THE MONOMIAL BAND** — on constructed objects,

    `⟨xⁱ, xʲ⟩ = 1/(i+j+1)`   (`innerI_powTest_hilbert`).

The band the co-support condition is orthogonality *to* (brick 28's weld) now has its Gram
matrix in closed form, every entry at once. Two ingredients:

- `powTest_mul` — the monomial tests multiply: `xⁱ·xʲ = x^{i+j}` pointwise (induction on the
  second exponent through `Rmul_assoc`), so the pairing's integrand IS a single monomial;
- `riemannIntegral_powTest_all` — `∫₀¹ clamp01ᵐ = 1/(m+1)` for EVERY `m` including `m = 0`
  (brick 33's law plus the constant case), reached at the pairing's own modulus by transport
  and certificate independence.

Corollaries: `mellinMoment_powTest` (`⟨xⁱ, xⁿ⟩` as the moment map on the monomials) and
`mellinMoment_clamp_via_hilbert` — brick 33's headline `mellinMoment clampTest n = 1/(n+2)`
recovered as the `i = 1` row, so the Hausdorff law is the Hilbert matrix's first row.
`hilbertGram_symm` records the symmetry the Gram matrix of any pairing must have.

HONEST SCOPE. The Gram matrix of the monomial band on `[0,1]`; no positive-definiteness
claim, no inverse, no conditioning statement — and nothing about the Weil form. Positivity of
the Weil form on the band's orthogonal complement is step 4 and is RH. The crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MomentLaw

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The monomial tests multiply**: `xⁱ·xʲ = x^{i+j}` pointwise. -/
theorem powTest_mul (i : Nat) : ∀ (n : Nat) (x : Real),
    Req (Rmul ((powTest i).f x) ((powTest n).f x)) ((powTest (i + n)).f x)
  | 0, x => Rmul_one ((powTest i).f x)
  | n + 1, x => by
    show Req (Rmul ((powTest i).f x) (Rmul ((powTest n).f x) (clamp01 x)))
      ((powTest (i + n + 1)).f x)
    show Req (Rmul ((powTest i).f x) (Rmul ((powTest n).f x) (clamp01 x)))
      (Rmul ((powTest (i + n)).f x) (clamp01 x))
    refine Req_trans (Req_symm (Rmul_assoc ((powTest i).f x) ((powTest n).f x) (clamp01 x))) ?_
    exact Rmul_congr (powTest_mul i n x) (Req_refl (clamp01 x))

/-- **`∫₀¹ clamp01(x)ᵐ dx = 1/(m+1)` for EVERY `m`** — brick 33's law together with the
    constant case `m = 0`. -/
theorem riemannIntegral_powTest_all (m : Nat) :
    Req (riemannIntegral (powTest m).hLd (powTest m).hLn (powTest m).hlip (powTest m).hfc)
      (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)) := by
  cases m with
  | zero => exact riemannIntegral_const_gen one (powTest 0).hLd (powTest 0).hLn _ _
  | succ k => exact riemannIntegral_powTest_succ k

/-- **THE HILBERT MATRIX**: `⟨xⁱ, xʲ⟩ = 1/(i+j+1)` — the Gram matrix of the monomial band,
    in closed form at every entry. -/
theorem innerI_powTest_hilbert (i n : Nat) :
    Req (innerI (powTest i) (powTest n)) (ofQ (⟨1, i + n + 1⟩ : Q) (Nat.succ_pos (i + n))) := by
  have hdist : ∀ x, Req (Rmul ((powTest i).f x) ((powTest n).f x)) ((powTest (i + n)).f x) :=
    fun x => powTest_mul i n x
  have hlipS : ∀ x y, Rle (Rabs (Rsub ((powTest (i + n)).f x) ((powTest (i + n)).f y)))
      (Rmul (ofQ (l2L (powTest i) (powTest n)) (l2L_den (powTest i) (powTest n)))
        (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x)) (Req_symm (hdist y)))))
      (l2lip (powTest i) (powTest n) x y)
  have hfcS : ∀ x y, Req x y → Req ((powTest (i + n)).f x) ((powTest (i + n)).f y) :=
    fun x y h => (powTest (i + n)).hfc x y h
  refine Req_trans (riemannIntegral_congr (g := (powTest (i + n)).f)
    (l2L_den (powTest i) (powTest n)) (l2L_num (powTest i) (powTest n))
    (l2lip (powTest i) (powTest n)) (l2fc (powTest i) (powTest n)) hlipS hfcS hdist) ?_
  refine Req_trans (riemannIntegral_certif_irrel
    (l2L_den (powTest i) (powTest n)) (l2L_num (powTest i) (powTest n)) hlipS hfcS
    (powTest (i + n)).hLd (powTest (i + n)).hLn (powTest (i + n)).hlip
    (powTest (i + n)).hfc) ?_
  exact riemannIntegral_powTest_all (i + n)

/-- The Gram matrix is symmetric — `⟨xⁱ, xʲ⟩ = ⟨xʲ, xⁱ⟩`, as the closed form makes visible. -/
theorem hilbertGram_symm (i n : Nat) :
    Req (innerI (powTest i) (powTest n)) (innerI (powTest n) (powTest i)) := by
  refine Req_trans (innerI_powTest_hilbert i n) ?_
  refine Req_trans ?_ (Req_symm (innerI_powTest_hilbert n i))
  exact Req_of_seq_Qeq (fun _ => by
    show Qeq (⟨1, i + n + 1⟩ : Q) (⟨1, n + i + 1⟩ : Q)
    show (1 : Int) * ((n + i + 1 : Nat) : Int) = (1 : Int) * ((i + n + 1 : Nat) : Int)
    have h : i + n = n + i := Nat.add_comm i n
    rw [h])

/-- **The moment map on the monomials**: `mellinMoment (xⁱ) n = 1/(i+n+1)`. -/
theorem mellinMoment_powTest (i n : Nat) :
    Req (mellinMoment (powTest i) n) (ofQ (⟨1, i + n + 1⟩ : Q) (Nat.succ_pos (i + n))) :=
  innerI_powTest_hilbert i n

/-- **Brick 33's Hausdorff law is the Hilbert matrix's `i = 1` row**:
    `mellinMoment clampTest n = 1/(n+2)`, recovered from the Gram closed form. -/
theorem mellinMoment_clamp_via_hilbert (n : Nat) :
    Req (mellinMoment clampTest n) (ofQ (⟨1, n + 2⟩ : Q) (Nat.succ_pos (n + 1))) := by
  have hone : ∀ x, Req (clampTest.f x) ((powTest 1).f x) := fun x =>
    Req_symm (Req_trans (Rmul_comm one (clamp01 x)) (Rmul_one (clamp01 x)))
  have hdist : ∀ x, Req (Rmul (clampTest.f x) ((powTest n).f x))
      (Rmul ((powTest 1).f x) ((powTest n).f x)) := fun x =>
    Rmul_congr (hone x) (Req_refl _)
  have hlipS : ∀ x y, Rle (Rabs (Rsub (Rmul ((powTest 1).f x) ((powTest n).f x))
        (Rmul ((powTest 1).f y) ((powTest n).f y))))
      (Rmul (ofQ (l2L clampTest (powTest n)) (l2L_den clampTest (powTest n)))
        (Rabs (Rsub x y))) := fun x y =>
    Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr (Req_symm (hdist x)) (Req_symm (hdist y)))))
      (l2lip clampTest (powTest n) x y)
  refine Req_trans (riemannIntegral_congr
    (g := fun x => Rmul ((powTest 1).f x) ((powTest n).f x))
    (l2L_den clampTest (powTest n)) (l2L_num clampTest (powTest n))
    (l2lip clampTest (powTest n)) (l2fc clampTest (powTest n)) hlipS
    (l2fc (powTest 1) (powTest n)) hdist) ?_
  refine Req_trans (riemannIntegral_certif_irrel
    (l2L_den clampTest (powTest n)) (l2L_num clampTest (powTest n)) hlipS
    (l2fc (powTest 1) (powTest n))
    (l2L_den (powTest 1) (powTest n)) (l2L_num (powTest 1) (powTest n))
    (l2lip (powTest 1) (powTest n)) (l2fc (powTest 1) (powTest n))) ?_
  refine Req_trans (mellinMoment_powTest 1 n) ?_
  exact Req_of_seq_Qeq (fun _ => by
    show Qeq (⟨1, 1 + n + 1⟩ : Q) (⟨1, n + 2⟩ : Q)
    show (1 : Int) * ((n + 2 : Nat) : Int) = (1 : Int) * ((1 + n + 1 : Nat) : Int)
    have h1 : 1 + n + 1 = n + 2 := by omega
    rw [h1])

end Multiplicity.UOR.Bridge.F1Square.Square
