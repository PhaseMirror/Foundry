/-
F1 square — **reconstruction from moment data alone** (`MomentInversionRaw.lean`), the Mellin-inversion
front. The Bernstein–Durrmeyer operator `durrOp φ` already reads `φ` only through its moment sequence
(`durrOp_eq_momData`). This brick makes that explicit as an operator on a *raw* moment sequence
`μ : Nat → Real`, decoupled from any test:

  `durrOpMom μ n x = (n+1)·Σ_k b_{n,k}(x)·C(n,k)·(Δⁿ⁻ᵏμ)_k`,

with `durrOpMom (mellinMoment φ) = durrOp φ` (`durrOpMom_eq_durrOp`) and the reconstruction rate
`|durrOpMom (mellinMoment φ) ((k+3)²−2) x − φ(x)| ≤ φ.L/(k+3)` on `[0,1]` (`durrOpMom_converges`). So a
bounded-Lipschitz test is recovered **from its moment sequence alone** — the transform pair's inversion
stated purely on the moment data, the direction the surjectivity question asks about. The convergence is
delivered as a first-class limit object (`durrOpMom_tendsTo`: `RTendsTo (fun m => durrOpMom … ) (φ.f x)`
on `[0,1]`), the moment-side companion of `durrOp_tendsTo`.

HONEST SCOPE. The reconstruction operator on raw moment sequences, and its convergence on the moment
sequences that arise from the bounded-Lipschitz class (`μ = mellinMoment φ`). It does NOT characterise
which raw sequences are moment sequences (the Hausdorff/complete-monotonicity question), NOT a completed
L² space, NOT positivity. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.DurrmeyerTendsTo

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Raw forward finite differences** of an abstract moment sequence `μ`, the same Pascal recursion as
    `momDiff` but reading `μ` directly rather than a test's moments. -/
def momDiffRaw (μ : Nat → Real) (k : Nat) : Nat → Real
  | 0 => μ k
  | m + 1 => Rsub (momDiffRaw μ k m) (momDiffRaw μ (k + 1) m)

/-- `natScaleR` respects `Req` in its real argument. -/
private theorem natScaleR_congr_raw {a b : Real} (hab : Req a b) :
    ∀ k, Req (natScaleR k a) (natScaleR k b)
  | 0 => Req_refl _
  | k + 1 => Radd_congr hab (natScaleR_congr_raw hab k)

/-- **`momDiff` is the raw difference of the moment sequence**: `momDiff φ k m = (Δᵐ(mellinMoment φ))_k`.
    Both are the identical Pascal recursion, and `momDiff φ k 0 = mellinMoment φ k` definitionally. -/
theorem momDiff_eq_raw (φ : L2Test) (k : Nat) :
    ∀ m, Req (momDiff φ k m) (momDiffRaw (mellinMoment φ) k m)
  | 0 => Req_refl _
  | m + 1 => Rsub_congr (momDiff_eq_raw φ k m) (momDiff_eq_raw φ (k + 1) m)

/-- **THE DURRMEYER RECONSTRUCTION OPERATOR ON A RAW MOMENT SEQUENCE**: reads only `μ`, no test. -/
def durrOpMom (μ : Nat → Real) (n : Nat) (x : Real) : Real :=
  Rmul (RofNat (n + 1))
    (RsumN (fun k => Rmul (bernR x n k) (natScaleR (choose n k) (momDiffRaw μ k (n - k)))) (n + 1))

/-- Raw finite differences respect `Req` of the moment sequence. -/
theorem momDiffRaw_congr {μ ν : Nat → Real} (h : ∀ n, Req (μ n) (ν n)) (k : Nat) :
    ∀ m, Req (momDiffRaw μ k m) (momDiffRaw ν k m)
  | 0 => h k
  | m + 1 => Rsub_congr (momDiffRaw_congr h k m) (momDiffRaw_congr h (k + 1) m)

/-- **The reconstruction depends only on the moment sequence's values**: `Req`-equal moment sequences
    give `Req` reconstructions. -/
theorem durrOpMom_congr {μ ν : Nat → Real} (h : ∀ n, Req (μ n) (ν n)) (n : Nat) (x : Real) :
    Req (durrOpMom μ n x) (durrOpMom ν n x) :=
  Rmul_congr (Req_refl _) (RsumN_congr (n + 1) (fun k _ =>
    Rmul_congr (Req_refl _) (natScaleR_congr_raw (momDiffRaw_congr h k (n - k)) (choose n k))))

/-- **THE OPERATOR READS ONLY THE MOMENTS**: `durrOpMom (mellinMoment φ) = durrOp φ`, so the whole
    Durrmeyer reconstruction is a function of the moment sequence alone. -/
theorem durrOpMom_eq_durrOp (φ : L2Test) (n : Nat) (x : Real) :
    Req (durrOpMom (mellinMoment φ) n x) (durrOp φ n x) := by
  refine Req_trans ?_ (Req_symm (durrOp_eq_momData φ n x))
  refine Rmul_congr (Req_refl _) (RsumN_congr (n + 1) (fun k _ => ?_))
  exact Rmul_congr (Req_refl _)
    (natScaleR_congr_raw (Req_symm (momDiff_eq_raw φ k (n - k))) (choose n k))

/-- **★ RECONSTRUCTION FROM MOMENT DATA ALONE**: a bounded-Lipschitz test is recovered from its moment
    sequence at the certified rate `|durrOpMom (mellinMoment φ) ((k+3)²−2) x − φ(x)| ≤ φ.L/(k+3)` on
    `[0,1]` — the transform pair's inversion stated purely on the moments. -/
theorem durrOpMom_converges (φ : L2Test) (x : Real) (h0 : Rle zero x) (h1 : Rle x one) (k : Nat) :
    Rle (Rabs (Rsub (durrOpMom (mellinMoment φ) ((k + 3) * (k + 3) - 2) x) (φ.f x)))
        (ofQ (mul φ.L (⟨1, k + 3⟩ : Q)) (Qmul_den_pos φ.hLd (Nat.succ_pos (k + 2)))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr
    (durrOpMom_eq_durrOp φ ((k + 3) * (k + 3) - 2) x) (Req_refl _)))) ?_
  exact durrOp_converges φ x h0 h1 k

-- ===========================================================================
-- The reconstruction as a first-class `RTendsTo` limit object.
-- ===========================================================================

/-- **RATE ⟹ `RTendsTo` MODULUS** (abstract, moment-side copy of `DurrmeyerTendsTo`'s private helper,
    which is not importable): a single real bound `|Y − L| ≤ 1/(m+1)` delivers the `RTendsTo`-style
    `.seq`-level bound `|Yₙ − Lₙ| ≤ 2/(m+1) + 2/(n+1)`. Push the real bound down to the two one-sided
    `.seq` bounds (`seq_diff_le`), recombine through `Qabs` (`Qabs_le_of_both`), relax `1/(m+1)` to
    `2/(m+1)`. -/
private theorem tendsTo_of_rate_mom {Y L : Real} {m : Nat}
    (hrate : Rle (Rabs (Rsub Y L)) (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m))) (n : Nat) :
    Qle (Qabs (Qsub (Y.seq n) (L.seq n))) (add (⟨2, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) := by
  have hd1 : Qle (Qsub (Y.seq n) (L.seq n)) (add (⟨1, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) :=
    seq_diff_le Y L (⟨1, m + 1⟩ : Q) (Nat.succ_pos m) (Rle_of_Rabs_le hrate) n
  have hcomm : Req (Rabs (Rsub L Y)) (Rabs (Rsub Y L)) :=
    Req_trans (Rabs_congr (Req_symm (Rneg_Rsub Y L))) (Rabs_Rneg (Rsub Y L))
  have hrate' : Rle (Rabs (Rsub L Y)) (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)) :=
    Rle_trans (Rle_of_Req hcomm) hrate
  have hd2 : Qle (Qsub (L.seq n) (Y.seq n)) (add (⟨1, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) :=
    seq_diff_le L Y (⟨1, m + 1⟩ : Q) (Nat.succ_pos m) (Rle_of_Rabs_le hrate') n
  have he : Qeq (Qsub (L.seq n) (Y.seq n)) (neg (Qsub (Y.seq n) (L.seq n))) := by
    simp only [Qeq, Qsub, neg, add]; push_cast; ring_uor
  have h2 : Qle (neg (Qsub (Y.seq n) (L.seq n))) (add (⟨1, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) :=
    Qle_congr_left (Qsub_den_pos (L.den_pos n) (Y.den_pos n)) he hd2
  have hcombined : Qle (Qabs (Qsub (Y.seq n) (L.seq n))) (add (⟨1, m + 1⟩ : Q) (⟨2, n + 1⟩ : Q)) :=
    Qabs_le_of_both hd1 h2
  have hm12 : Qle (⟨1, m + 1⟩ : Q) (⟨2, m + 1⟩ : Q) := by simp only [Qle]; push_cast; omega
  exact Qle_trans (add_den_pos (Nat.succ_pos m) (Nat.succ_pos n)) hcombined
    (Qadd_le_add hm12 (Qle_refl (⟨2, n + 1⟩ : Q)))

/-- **THE REINDEXED RECONSTRUCTION RATE**: with `k := (φ.L.num.toNat + 1)·(m+1)` the estimate
    `durrOpMom_converges` gives `φ.L/(k+3) ≤ 1/(m+1)` (`Kₘ = (φ.L.num.toNat+1)·(m+1)+3`). The scaled
    denominator swallows `φ.L`: since `φ.L.num·(m+1) ≤ φ.L.den·((φ.L.num+1)(m+1)+3)`. Identical
    denominator arithmetic to `durrOp`'s `durrRate`, now on the raw-moment operator. -/
private theorem durrRateMom (φ : L2Test) (x : Real) (h0 : Rle zero x) (h1 : Rle x one) (m : Nat) :
    Rle (Rabs (Rsub (durrOpMom (mellinMoment φ)
        (((φ.L.num.toNat + 1) * (m + 1) + 3) * ((φ.L.num.toNat + 1) * (m + 1) + 3) - 2) x)
      (φ.f x)))
      (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)) := by
  refine Rle_trans (durrOpMom_converges φ x h0 h1 ((φ.L.num.toNat + 1) * (m + 1))) ?_
  refine Rle_ofQ_ofQ _ (Nat.succ_pos m) ?_
  simp only [Qle, mul]
  push_cast
  have hBtoNat : (φ.L.num.toNat : Int) = φ.L.num := Int.toNat_of_nonneg φ.hLn
  have hBden1 : (1 : Int) ≤ (φ.L.den : Int) := by exact_mod_cast φ.hLd
  rw [hBtoNat]
  have hj1 : (0 : Int) ≤ (m : Int) + 1 := by omega
  have hfac : φ.L.num * ((m : Int) + 1) ≤ (φ.L.num + 1) * ((m : Int) + 1) :=
    Int.mul_le_mul_of_nonneg_right (by omega) hj1
  have hplus3 : (φ.L.num + 1) * ((m : Int) + 1) ≤ (φ.L.num + 1) * ((m : Int) + 1) + 3 := by omega
  have hPpos : (0 : Int) ≤ (φ.L.num + 1) * ((m : Int) + 1) + 3 := by
    have hp : (0 : Int) ≤ (φ.L.num + 1) * ((m : Int) + 1) := Int.mul_nonneg (by omega) hj1
    omega
  have hDmul : (φ.L.num + 1) * ((m : Int) + 1) + 3
      ≤ (φ.L.den : Int) * ((φ.L.num + 1) * ((m : Int) + 1) + 3) := by
    have := Int.mul_le_mul_of_nonneg_right hBden1 hPpos
    rw [Int.one_mul] at this; exact this
  have hchain : φ.L.num * ((m : Int) + 1)
      ≤ (φ.L.den : Int) * ((φ.L.num + 1) * ((m : Int) + 1) + 3) :=
    Int.le_trans hfac (Int.le_trans hplus3 hDmul)
  have e1 : φ.L.num * 1 * ((m : Int) + 1) = φ.L.num * ((m : Int) + 1) := by ring_uor
  have e2 : (1 : Int) * ((φ.L.den : Int) * ((φ.L.num + 1) * ((m : Int) + 1) + 3))
      = (φ.L.den : Int) * ((φ.L.num + 1) * ((m : Int) + 1) + 3) := by ring_uor
  rw [e1, e2]; exact hchain

/-- **★ THE RECONSTRUCTION TENDS TO `φ(x)`** (packaged as an `RTendsTo` limit object): for `x ∈ [0,1]`
    the reindexed reconstruction sequence

        `m ↦ durrOpMom (mellinMoment φ) (Kₘ·Kₘ − 2) x`,   `Kₘ = (φ.L.num.toNat + 1)·(m+1) + 3`,

    converges to `φ(x)` in the codebase's canonical limit predicate `RTendsTo` (Bishop modulus
    `2/(m+1) + 2/(n+1)`). The reindex turns `durrOpMom_converges`' rate `φ.L/(k+3)` into `≤ 1/(m+1)`
    (`durrRateMom`), which `tendsTo_of_rate_mom` packages into the modulus. This is the reconstruction
    **from moment data alone** delivered as a first-class limit, the moment-side companion of
    `durrOp_tendsTo`; NOT surjectivity onto function space, NOT positivity. Step 4 is RH. -/
theorem durrOpMom_tendsTo (φ : L2Test) (x : Real) (h0 : Rle zero x) (h1 : Rle x one) :
    RTendsTo (fun m => durrOpMom (mellinMoment φ)
        (((φ.L.num.toNat + 1) * (m + 1) + 3) * ((φ.L.num.toNat + 1) * (m + 1) + 3) - 2) x)
      (φ.f x) := by
  intro m n
  exact tendsTo_of_rate_mom (durrRateMom φ x h0 h1 m) n

end Multiplicity.UOR.Bridge.F1Square.Square
