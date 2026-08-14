/-
F1 square — Track 1, item 6 (a **structural** shape-match): the constructive **moment-expansion** form
of a finite witness sum (`ComplexBinomial.lean`, `witnessSum_moment_order`) and the constructive
**arithmetic `η`-form** (`GenuineLi.lean`, `genuineArithSeq`) carry the *same* binomial-weighted shape,
so they are equal term-by-term under one per-order coefficient-matching hypothesis.

`witnessSum_moment_order` rewrote the finite witness sum over Cayley factors `w = 1 − u` as
`−Σ_{k=1}^{n} Re(M_k)`, `M_k = Σ_{u∈us} C(n,k)·(−u)ᵏ`. The arithmetic side is
`genuineArithSeq = −Σ_{j=1}^{n} C(n,j)·η_{j−1}` (`GenuineLi.lean`). Both are `−Σ` of binomial-weighted
terms, so they coincide as soon as each order's coefficients agree: `Re(M_k) = C(n,k)·η_{k−1}`, entered
as an explicit, audit-visible hypothesis (`seam`), never an axiom and never discharged.

**Honesty scope — what this is NOT.** The `seam` is a *structural* hypothesis matching two constructed
sequences term-by-term; it is **not** asserted to be the classical explicit formula, and this is **not** a
discharge or faithful relocation of the `bl` interface. Two reasons the genuine objects do not satisfy it
as stated: (i) `genuineArithSeq` is only the *arithmetic* piece of `λₙ` — the full Li coefficient is
`λₙ = genuineArithSeq + genuineArchSeq` (e.g. `λ₁^{arith} = γ ≈ 0.577` vs the full `λ₁ ≈ 0.023`), whereas
the genuine Bombieri–Lagarias zero-sum limit equals the *full* `λₙ`, not the arithmetic piece; (ii) the
true explicit formula relates the zero moments `Σ_ρ ρ^{−k}` to the `−ζ′/ζ` Taylor data **plus** the
archimedean/trivial-zero place, which this per-order `seam` omits. So this lemma is a shape-level bridge
between two representations, not the arithmetic identity behind `bl`; closing `bl` constructively is the
open Track-1 work (the explicit formula with its archimedean term, and the Hadamard convergence).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
The crux fields stay `none`; RH is open.
-/

import Multiplicity.F1Square.Analysis.ComplexBinomial
import Multiplicity.F1Square.Analysis.GenuineLi

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The order sum matches the arithmetic tail**: under the per-order seam `Re(M_k) = C(n,k)·η_{k−1}`,
    the real part of the partial moment sum `Σ_{k<N} M_k` equals the arithmetic tail `Σ_{j=1}^{N} C(n,j)·η_{j−1}`
    (`arithTail`), for every `N ≤ n`. A clean induction — both sides append the same `k`-th term (`(CsumN …).re`
    unfolds to `Radd` of the real parts; `arithTail` appends `nsmulR (C(n,k+1)) (η k)`), matched by `seam`. -/
theorem moment_re_eq_arithTail (E : StieltjesEta) (us : List Complex) (n : Nat)
    (seam : ∀ k, k < n → Req (momentList us n k).re (nsmulR (choose n (k + 1)) (E.eta k))) :
    ∀ N, N ≤ n → Req (CsumN (fun k => momentList us n k) N).re (arithTail E.eta n N)
  | 0, _ => Req_refl zero
  | (N + 1), hle =>
      Radd_congr (moment_re_eq_arithTail E us n seam N (Nat.le_of_succ_le hle))
        (seam N (Nat.lt_of_succ_le hle))

/-- **A structural shape-match** — under the per-order coefficient hypothesis `seam`, the finite witness
    sum over Cayley factors `w = 1 − u` equals the arithmetic closed form
    `genuineArithSeq = −Σ_{j=1}^{n} C(n,j)·η_{j−1}`:

      `Σ_w (1 − Re(wⁿ)) = −Σ_{j=1}^{n} C(n,j)·η_{j−1}`.

    Both sides are `−Σ` of the *same* binomial-weighted terms (`witnessSum_moment_order` gives the left as
    `−Σ_k Re(M_k)`), so they coincide as soon as each order's coefficients agree:
    `Re(M_k) = C(n,k)·η_{k−1}` (`seam`, a hypothesis, never discharged).

    **This is a shape-level identity between two constructed representations, not a discharge of `bl`.**
    `genuineArithSeq` is only the *arithmetic* piece of `λₙ` (`λₙ = genuineArithSeq + genuineArchSeq`),
    while the genuine Bombieri–Lagarias zero-sum limit is the *full* `λₙ`; and the true explicit formula
    relates the zero moments to the `−ζ′/ζ` data **plus** the archimedean place, which this per-order
    `seam` omits. So the `seam` is not asserted to hold for the genuine zeros, and this does not relocate
    or shrink the `bl` interface. The crux stays `none`; RH is open. -/
theorem witnessSum_eq_genuineArith (E : StieltjesEta) (us : List Complex) (n : Nat)
    (seam : ∀ k, k < n → Req (momentList us n k).re (nsmulR (choose n (k + 1)) (E.eta k))) :
    Req (witnessSum (us.map (fun u => Cadd Cone (Cneg u))) n) (genuineArithSeq E.eta n) :=
  Req_trans (witnessSum_moment_order n us)
    (Rneg_congr (moment_re_eq_arithTail E us n seam n (Nat.le_refl n)))

end Multiplicity.UOR.Bridge.F1Square.Analysis
