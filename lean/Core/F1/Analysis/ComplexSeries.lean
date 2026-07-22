/-
F1 square — **complex finite sums and products** (`CsumN`, `CprodN`) and the bridge to the real
completeness, the algebraic substrate for the Track-1 Hadamard product `ξ(s) = ξ(0)·∏_ρ(1 − s/ρ)`
and its log-derivative series.

`CsumN F N = Σ_{k<N} F k` and `CprodN F N = ∏_{k<N} F k` are the partial sum / partial product, built
from `Cadd`/`Cmul`. Two facts make them usable:
  * the **congruences** `CsumN_congr`/`CprodN_congr` (pointwise `≈` ⟹ `≈` partials), needed to
    transport across `≈`-equal reindexings of the zero enumeration; and
  * the **component projection** `(CsumN F N).re = RsumN (re∘F) N` (and `.im`), which reduces the
    regularity / limit of a complex series to the real completeness (`ComplexLimit.lean`,
    `Complete.lean`) — a complex series converges iff both real-component partial-sum sequences do.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.ComplexLimit
import Core.F1.Analysis.EtaVariation
import Core.F1.Analysis.RSum

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- (A) Complex finite sums `CsumN F N = Σ_{k<N} F k`.
-- ===========================================================================

/-- The **complex partial sum** `Σ_{k<N} F k`. -/
def CsumN (F : Nat → Complex) : Nat → Complex
  | 0 => Czero
  | (n + 1) => Cadd (CsumN F n) (F n)

/-- The real part of a complex partial sum is the real partial sum of the real parts (`= RsumN`). -/
theorem CsumN_re (F : Nat → Complex) : ∀ N, (CsumN F N).re = RsumN (fun n => (F n).re) N
  | 0 => rfl
  | (n + 1) => by
      show Radd (CsumN F n).re (F n).re = Radd (RsumN (fun n => (F n).re) n) (F n).re
      rw [CsumN_re F n]

/-- The imaginary part of a complex partial sum is the real partial sum of the imaginary parts. -/
theorem CsumN_im (F : Nat → Complex) : ∀ N, (CsumN F N).im = RsumN (fun n => (F n).im) N
  | 0 => rfl
  | (n + 1) => by
      show Radd (CsumN F n).im (F n).im = Radd (RsumN (fun n => (F n).im) n) (F n).im
      rw [CsumN_im F n]

/-- **Partial-sum congruence**: pointwise-`≈` summands give `≈` partial sums. -/
theorem CsumN_congr {F G : Nat → Complex} (h : ∀ n, Ceq (F n) (G n)) :
    ∀ N, Ceq (CsumN F N) (CsumN G N)
  | 0 => Ceq_refl _
  | (n + 1) => Cadd_congr (CsumN_congr h n) (h n)

/-- **Four-term addition interchange** `(a+b)+(c+d) ≈ (a+c)+(b+d)` — the complex middle-four swap,
    from `Cadd_assoc`/`Cadd_comm`. The inductive heart of `CsumN_add` (regroup the appended summands
    against the appended partial sums). -/
private theorem Cadd_add_add_comm (a b c d : Complex) :
    Ceq (Cadd (Cadd a b) (Cadd c d)) (Cadd (Cadd a c) (Cadd b d)) :=
  Ceq_trans (Cadd_assoc a b (Cadd c d))
    (Ceq_trans (Cadd_congr (Ceq_refl a) (Ceq_symm (Cadd_assoc b c d)))
      (Ceq_trans (Cadd_congr (Ceq_refl a) (Cadd_congr (Cadd_comm b c) (Ceq_refl d)))
        (Ceq_trans (Cadd_congr (Ceq_refl a) (Cadd_assoc c b d))
          (Ceq_symm (Cadd_assoc a c (Cadd b d))))))

/-- **Negation distributes over a complex sum** `−(a + b) ≈ (−a) + (−b)` — componentwise `Rneg_Radd`.
    The inductive step of `CsumN_neg`. -/
private theorem Cneg_Cadd (a b : Complex) : Ceq (Cneg (Cadd a b)) (Cadd (Cneg a) (Cneg b)) :=
  ⟨Rneg_Radd a.re b.re, Rneg_Radd a.im b.im⟩

/-- **★ Partial-sum negation** `Σ_{n<N} (−Fₙ) ≈ −(Σ_{n<N} Fₙ)` — the negation half of complex
    finite-sum linearity (with `CsumN_add`, the full additive group). Modulus-safe (negation does not
    inflate the index). By induction: the appended `−Fₙ` and the negated inductive sum regroup via
    `Cneg_Cadd`. The forced substrate for the subtractions in the log-derivative `bl` expansion. -/
theorem CsumN_neg (F : Nat → Complex) :
    ∀ N, Ceq (CsumN (fun n => Cneg (F n)) N) (Cneg (CsumN F N))
  | 0 => ⟨Req_symm Rneg_zero, Req_symm Rneg_zero⟩
  | (N + 1) =>
      Ceq_trans (Cadd_congr (CsumN_neg F N) (Ceq_refl (Cneg (F N))))
        (Ceq_symm (Cneg_Cadd (CsumN F N) (F N)))

/-- **★ Partial-sum additivity** `Σ_{n<N} (Fₙ + Gₙ) ≈ (Σ_{n<N} Fₙ) + (Σ_{n<N} Gₙ)` — linearity of
    the complex finite sum. By induction: the appended summand `Fₙ + Gₙ` and the inductive split
    regroup via the four-term interchange `Cadd_add_add_comm`. The forced algebraic substrate for
    splitting a witness/log-derivative series by its two component series (toward the Hadamard `bl`
    expansion); the complex lift of finite-sum linearity (no real `RsumN_add` is needed — the swap is
    done directly over `Cadd`). -/
theorem CsumN_add (F G : Nat → Complex) :
    ∀ N, Ceq (CsumN (fun n => Cadd (F n) (G n)) N) (Cadd (CsumN F N) (CsumN G N))
  | 0 => ⟨Req_symm (Radd_zero zero), Req_symm (Radd_zero zero)⟩
  | (N + 1) =>
      Ceq_trans (Cadd_congr (CsumN_add F G N) (Ceq_refl (Cadd (F N) (G N))))
        (Cadd_add_add_comm (CsumN F N) (CsumN G N) (F N) (G N))

-- ===========================================================================
-- (B) Complex finite products `CprodN F N = ∏_{k<N} F k`.
-- ===========================================================================

/-- The **complex partial product** `∏_{k<N} F k` (empty product `= 1`). -/
def CprodN (F : Nat → Complex) : Nat → Complex
  | 0 => Cone
  | (n + 1) => Cmul (CprodN F n) (F n)

/-- **Partial-product congruence**: pointwise-`≈` factors give `≈` partial products. -/
theorem CprodN_congr {F G : Nat → Complex} (h : ∀ n, Ceq (F n) (G n)) :
    ∀ N, Ceq (CprodN F N) (CprodN G N)
  | 0 => Ceq_refl _
  | (n + 1) => Cmul_congr (CprodN_congr h n) (h n)

/-- A partial product with a unit factor appended is `≈` the shorter product (`∏·1 ≈ ∏`). -/
theorem CprodN_succ_one {F : Nat → Complex} {N : Nat} (h : Ceq (F N) Cone) :
    Ceq (CprodN F (N + 1)) (CprodN F N) :=
  Ceq_trans (Cmul_congr (Ceq_refl (CprodN F N)) h) (Cmul_one (CprodN F N))

/-- **Four-term product interchange** `(a·b)·(c·d) ≈ (a·c)·(b·d)` — the complex middle-four swap,
    from `Cmul_assoc`/`Cmul_comm`. The inductive heart of `CprodN_mul` (the multiplicative mirror of
    `Cadd_add_add_comm`). -/
private theorem Cmul_mul_mul_comm (a b c d : Complex) :
    Ceq (Cmul (Cmul a b) (Cmul c d)) (Cmul (Cmul a c) (Cmul b d)) :=
  Ceq_trans (Cmul_assoc a b (Cmul c d))
    (Ceq_trans (Cmul_congr (Ceq_refl a) (Ceq_symm (Cmul_assoc b c d)))
      (Ceq_trans (Cmul_congr (Ceq_refl a) (Cmul_congr (Cmul_comm b c) (Ceq_refl d)))
        (Ceq_trans (Cmul_congr (Ceq_refl a) (Cmul_assoc c b d))
          (Ceq_symm (Cmul_assoc a c (Cmul b d))))))

/-- **★ Partial-product multiplicativity** `∏_{k<N} (Fₖ·Gₖ) ≈ (∏_{k<N} Fₖ)·(∏_{k<N} Gₖ)` —
    the complex finite product distributes over a factorwise product. By induction: the appended
    factor `Fₙ·Gₙ` and the inductive split regroup via the four-term interchange `Cmul_mul_mul_comm`.
    The forced algebraic substrate for factoring the Hadamard product `∏(1 − s/ρ)` (item 5) — e.g.
    splitting a factor `(1 − s/ρ) = a·b` across the product. The multiplicative mirror of `CsumN_add`. -/
theorem CprodN_mul (F G : Nat → Complex) :
    ∀ N, Ceq (CprodN (fun n => Cmul (F n) (G n)) N) (Cmul (CprodN F N) (CprodN G N))
  | 0 => Ceq_symm (Cmul_one Cone)
  | (N + 1) =>
      Ceq_trans (Cmul_congr (CprodN_mul F G N) (Ceq_refl (Cmul (F N) (G N))))
        (Cmul_mul_mul_comm (CprodN F N) (CprodN G N) (F N) (G N))

-- ===========================================================================
-- (C) The complex series / infinite product as the limit of partials (when regular).
-- ===========================================================================

/-- A complex series **converges** iff its partial sums form a regular complex sequence. -/
def CsumConv (F : Nat → Complex) : Prop := CReg (CsumN F)

/-- The **complex series** `Σ_k F k` — the limit of the partial sums, given convergence. -/
def Cseries (F : Nat → Complex) (h : CsumConv F) : Complex := Clim (CsumN F) h

/-- **★ Series additivity** `Σ_k (Fₖ + Gₖ) ≈ (Σ_k Fₖ) + (Σ_k Gₖ)` — linearity of the complex
    infinite sum. The `Cseries`-level lift of `CsumN_add`, via `Clim_add_of_approx`: the GIVEN
    convergence `hFG` of the combined series carries `W = CsumN (F+G)`, which is pointwise `≈`
    `CsumN F + CsumN G` (`CsumN_add`) — so no (non-derivable) combined regularity is needed. The
    forced linearity for splitting a log-derivative / witness series into its component series. -/
theorem Cseries_add (F G : Nat → Complex) (hF : CsumConv F) (hG : CsumConv G)
    (hFG : CsumConv (fun n => Cadd (F n) (G n))) :
    Ceq (Cseries (fun n => Cadd (F n) (G n)) hFG) (Cadd (Cseries F hF) (Cseries G hG)) :=
  Clim_add_of_approx (CsumN (fun n => Cadd (F n) (G n))) (CsumN F) (CsumN G)
    hF hG hFG (CsumN_add F G)

/-- A complex infinite product **converges** iff its partial products form a regular sequence. -/
def CprodConv (F : Nat → Complex) : Prop := CReg (CprodN F)

/-- The **complex infinite product** `∏_k F k` — the limit of the partial products, given convergence. -/
def CprodInf (F : Nat → Complex) (h : CprodConv F) : Complex := Clim (CprodN F) h

/-- The partial-sum real-part sequence **is** the real partial-sum of the real parts (as functions). -/
theorem CsumN_re_fun (F : Nat → Complex) :
    (fun N => (CsumN F N).re) = RsumN (fun n => (F n).re) := funext (CsumN_re F)

/-- The partial-sum imaginary-part sequence **is** the real partial-sum of the imaginary parts. -/
theorem CsumN_im_fun (F : Nat → Complex) :
    (fun N => (CsumN F N).im) = RsumN (fun n => (F n).im) := funext (CsumN_im F)

/-- **Complex-series convergence reduces to two real-series convergences**: `Σ F` converges iff both
    the real-part series `Σ Re(F)` and imaginary-part series `Σ Im(F)` are regular (`RReg`). This is
    the bridge that lets any concrete complex series be shown convergent via the real completeness —
    the workhorse for the Hadamard/log-derivative limits. -/
theorem CsumConv_iff (F : Nat → Complex) :
    CsumConv F ↔ RReg (RsumN (fun n => (F n).re)) ∧ RReg (RsumN (fun n => (F n).im)) := by
  unfold CsumConv CReg
  rw [CsumN_re_fun F, CsumN_im_fun F]

end UOR.Bridge.F1Square.Analysis
