/-
F1 square — Track 1, item 6 (landing the moment expansion on the genuine object): the reciprocal-moment
form of the Li witness term, instantiated at the *actual* Bombieri–Lagarias Cayley factor
`liRatio ρ = 1 − 1/ρ` (`CayleyMap.lean`), not an abstract `w`.

The binomial moment machinery (`ComplexBinomial.lean`) proved `1 − Re(wⁿ) = −Re(Σ_{k=1}^{n} C(n,k)(−u)ᵏ)`
for any `w = 1 − u`. Here `w = liRatio ρ` and `u = 1/ρ = Cinv ρ`, so the abstract result becomes a
statement about the genuine per-zero Li contribution: `1 − Re((1 − 1/ρ)ⁿ) = −Re(Σ_{k=1}^{n} C(n,k)(−1/ρ)ᵏ)`,
the per-zero summand of `RHWitness.witnessSum` written over the explicit-formula reciprocal moments
`(1/ρ)ᵏ`. This closes the loop: the moment-expansion arc is consumed by the real Cayley/Li object that
drives the `bl` witness sum.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
The crux fields stay `none`; RH is open.
-/

import Core.F1.Analysis.ComplexBinomial
import Core.F1.Analysis.ComplexXiHadamard

namespace UOR.Bridge.F1Square.Analysis

/-- `1·z ≈ z` (left unit; local). -/
private theorem Cone_Cmul_loc (z : Complex) : Ceq (Cmul Cone z) z :=
  Ceq_trans (Cmul_comm Cone z) (Cmul_one z)

/-- **The Cayley/Li factor is `1 − 1/ρ` in the `1 + (−u)` form the moment expansion consumes**:
    `liRatio ρ ≈ Cadd Cone (Cneg (Cinv ρ))`. Via `hadFactor_one_eq_liRatio` (`liRatio ≈ hadFactor 1 ρ`)
    and `hadFactor 1 ρ = 1 − 1·(1/ρ) ≈ 1 − 1/ρ` (`Cone_Cmul_loc`). -/
theorem liRatio_eq_one_sub_inv (ρ : Complex) (k : Nat) (hk : Qlt (Qbound k) ((CnormSq ρ).seq k)) :
    Ceq (liRatio ρ k hk) (Cadd Cone (Cneg (Cinv ρ k hk))) :=
  Ceq_trans (Ceq_symm (hadFactor_one_eq_liRatio ρ k hk))
    (Cadd_congr (Ceq_refl Cone) (Cneg_congr (Cone_Cmul_loc (Cinv ρ k hk))))

/-- **The genuine Cayley factor's powers, in reciprocal moments**: `(1 − 1/ρ)ⁿ ≈ Σ_{k=0}^{n} C(n,k)(−1/ρ)ᵏ`
    — the binomial moment expansion (`Cnpow_one_sub_eq`) on the actual `liRatio ρ`. -/
theorem liRatio_npow_moment (ρ : Complex) (k : Nat) (hk : Qlt (Qbound k) ((CnormSq ρ).seq k))
    (n : Nat) :
    Ceq (Cnpow (liRatio ρ k hk) n)
        (CsumN (binTermC (Cneg (Cinv ρ k hk)) n) (n + 1)) :=
  Cnpow_one_sub_eq (liRatio_eq_one_sub_inv ρ k hk) n

/-- **The Cayley/Li factor's per-zero witness term in reciprocal moments** — the headline: for the
    genuine Cayley factor `liRatio ρ = 1 − 1/ρ`, the Li witness term `1 − Re((liRatio ρ)ⁿ)` equals
    `−Re(Σ_{k=1}^{n} C(n,k)(−1/ρ)ᵏ)`, the per-zero summand of `RHWitness.witnessSum` written over the
    explicit-formula reciprocal moments `(1/ρ)ᵏ`. This lands the entire `ComplexBinomial` moment arc on
    the real Cayley/Li object behind `bl` (no abstract `w`); the remaining classical content (the moments
    `Σ_ρ ρ^{−k}` as the `ζ`-data with its archimedean place) is unchanged. Crux `none`. -/
theorem liRatio_witnessTerm_moment (ρ : Complex) (k : Nat) (hk : Qlt (Qbound k) ((CnormSq ρ).seq k))
    (n : Nat) :
    Req (Rsub one (Cnpow (liRatio ρ k hk) n).re)
        (Rneg (reciprocalMomentPoly (Cinv ρ k hk) n).re) :=
  witnessTerm_moment (liRatio_eq_one_sub_inv ρ k hk) n

/-- **The Hadamard/`bl` witness sum in reciprocal-moment-order form** — the item-6 object, fully
    assembled on the genuine zeros. For a `HadamardXi` enumeration of the nontrivial zeros, the `bl`
    witness sum over its `s = 1` factors equals the negated real part of the per-order reciprocal-moment
    sum over the reciprocals `1/ρⱼ = Cinv ρⱼ`:

      `Σ_j (1 − Re((1 − 1/ρⱼ)ⁿ)) = −Σ_{k=1}^{n} Re(M_k)`,  `M_k = Σ_j C(n,k)(−1/ρⱼ)ᵏ`.

    Chains `witnessSum_hadFactor_eq_liRatio` (Hadamard `s=1` factors are the Cayley factors), the
    per-zero `liRatio_eq_one_sub_inv` lifted across the list (`witnessSum_mapidx_congr`), and the moment
    decomposition `witnessSum_moment_order`. This is `λₙ`'s zero-sum decomposed by moment order, over the
    *actual* Hadamard zero enumeration. The remaining classical content (the moments `Σ_ρ ρ^{−k}` as the
    `ζ`-data with its archimedean place, and the `HadamardXi` convergence seam) is unchanged; crux `none`. -/
theorem hadamard_witnessSum_moment {gs zs : Complex} (H : HadamardXi Cone gs zs) (M n : Nat) :
    Req (witnessSum ((List.range M).map
            (fun j => hadFactor Cone (H.ρ j) (H.kwit j) (H.hwit j))) n)
        (Rneg (CsumN (fun k => momentList
            ((List.range M).map (fun j => Cinv (H.ρ j) (H.kwit j) (H.hwit j))) n k) n).re) := by
  refine Req_trans (witnessSum_hadFactor_eq_liRatio H M n) ?_
  refine Req_trans (witnessSum_mapidx_congr _ _
    (fun j => liRatio_eq_one_sub_inv (H.ρ j) (H.kwit j) (H.hwit j)) n (List.range M)) ?_
  have hlist : ((List.range M).map (fun j => Cinv (H.ρ j) (H.kwit j) (H.hwit j))).map
        (fun u => Cadd Cone (Cneg u))
      = (List.range M).map (fun j => Cadd Cone (Cneg (Cinv (H.ρ j) (H.kwit j) (H.hwit j)))) := by
    rw [List.map_map]; rfl
  rw [← hlist]
  exact witnessSum_moment_order n
    ((List.range M).map (fun j => Cinv (H.ρ j) (H.kwit j) (H.hwit j)))

end UOR.Bridge.F1Square.Analysis
