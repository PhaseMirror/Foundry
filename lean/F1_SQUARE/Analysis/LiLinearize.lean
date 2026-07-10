/-
F1 square — **the per-zero Li contribution, linearized**: the geometric factorization that exhibits
the moment factor `1/ρ` inside each Li term — the algebraic core of the Bombieri–Lagarias /
explicit-formula framework (the per-zero side, made explicit).

Each Riemann zero contributes `1 − (1−1/ρ)ⁿ` to `λₙ = Σ_ρ (1 − (1−1/ρ)ⁿ)`. With `w = 1−1/ρ` the
Cayley factor (`CayleyMap.lean`), the telescoping/geometric factorization

    1 − wⁿ  =  (1 − w) · Σ_{k=0}^{n−1} wᵏ        (`cone_sub_npow_factor`)

is an exact constructive complex identity (proved by induction, no `sqrt`). Since `1 − w = 1/ρ`, it
exhibits the FIRST MOMENT `1/ρ` as an explicit factor of every per-zero Li contribution:
`1 − (1−1/ρ)ⁿ = (1/ρ) · Σ_{k<n} (1−1/ρ)ᵏ`. Taking real parts, the witness term of `RHWitness` is

    1 − Re(wⁿ)  =  Re( (1−w) · Σ_{k<n} wᵏ )        (`witnessTerm_eq_linear`).

WHAT THIS DOES AND DOES NOT DO. It is the per-zero (left-hand) side of the explicit formula, made an
explicit constructive object: the structure that, summed over zeros, expresses `λₙ` through the power
moments `Σ_ρ ρ^{−k}`. The CLASSICAL content — that those moments equal the `−ζ′/ζ` Taylor data `ηⱼ`
plus the archimedean place (the explicit formula / Hadamard factorization of ξ), and that the
sum-over-zeros converges — stays interface (it is where RH-grade analysis enters). This file builds
the algebra that the classical input attaches to; it places no zeros and asserts no positivity. The
crux fields stay `none`.

Also: the small **complex commutative-ring lemmas** the substrate had not yet needed (`cmul_czero`,
`cadd_zero`, `cmul_cneg`, the local congruences) — reusable for any future complex algebra.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.LiGrowth
import F1Square.Analysis.RHWitness

namespace UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small complex commutative-ring lemmas (componentwise from the `Real` lemmas).
-- ===========================================================================

/-- `Cadd` respects `Ceq` in both arguments. -/
theorem cadd_congr {a a' b b' : Complex} (ha : Ceq a a') (hb : Ceq b b') :
    Ceq (Cadd a b) (Cadd a' b') :=
  ⟨Radd_congr ha.1 hb.1, Radd_congr ha.2 hb.2⟩

/-- `Cneg` respects `Ceq`. -/
theorem cneg_congr {a a' : Complex} (h : Ceq a a') : Ceq (Cneg a) (Cneg a') :=
  ⟨Rneg_congr h.1, Rneg_congr h.2⟩

/-- `Cmul` respects `Ceq` in both arguments. -/
theorem cmul_congr {a a' b b' : Complex} (ha : Ceq a a') (hb : Ceq b b') :
    Ceq (Cmul a b) (Cmul a' b') :=
  ⟨Rsub_congr (Rmul_congr ha.1 hb.1) (Rmul_congr ha.2 hb.2),
   Radd_congr (Rmul_congr ha.1 hb.2) (Rmul_congr ha.2 hb.1)⟩

/-- `z + 0 = z`. -/
theorem cadd_zero (z : Complex) : Ceq (Cadd z Czero) z :=
  ⟨Radd_zero z.re, Radd_zero z.im⟩

/-- `0 + z = z`. -/
theorem czero_cadd (z : Complex) : Ceq (Cadd Czero z) z :=
  Ceq_trans (Cadd_comm Czero z) (cadd_zero z)

/-- `z · 0 = 0`. -/
theorem cmul_czero (z : Complex) : Ceq (Cmul z Czero) Czero :=
  ⟨Req_trans (Rsub_congr (Rmul_zero z.re) (Rmul_zero z.im)) (Rsub_zero zero),
   Req_trans (Radd_congr (Rmul_zero z.re) (Rmul_zero z.im)) (Radd_zero zero)⟩

/-- `(−a) − (−b) = −(a − b)` on `Real` (a helper for `cmul_cneg`'s real part). -/
private theorem rsub_neg_neg (a b : Real) : Req (Rsub (Rneg a) (Rneg b)) (Rneg (Rsub a b)) :=
  Req_trans (Radd_congr (Req_refl (Rneg a)) (Rneg_neg b))
    (Req_trans (Radd_comm (Rneg a) b) (Req_symm (Rneg_Rsub a b)))

/-- `z · (−w) = −(z · w)`. -/
theorem cmul_cneg (z w : Complex) : Ceq (Cmul z (Cneg w)) (Cneg (Cmul z w)) :=
  ⟨Req_trans (Rsub_congr (Rmul_neg_right z.re w.re) (Rmul_neg_right z.im w.im))
     (rsub_neg_neg (Rmul z.re w.re) (Rmul z.im w.im)),
   Req_trans (Radd_congr (Rmul_neg_right z.re w.im) (Rmul_neg_right z.im w.re))
     (Req_symm (Rneg_Radd (Rmul z.re w.im) (Rmul z.im w.re)))⟩

-- ===========================================================================
-- The partial geometric sum and the factorization `1 − wⁿ = (1−w)·Σ_{k<n} wᵏ`.
-- ===========================================================================

/-- The partial geometric sum `Σ_{k=0}^{n−1} wᵏ`. -/
def cgeomSum (w : Complex) : Nat → Complex
  | 0 => Czero
  | (k + 1) => Cadd (cgeomSum w k) (Cnpow w k)

/-- **THE GEOMETRIC FACTORIZATION** `1 − wⁿ = (1 − w)·Σ_{k<n} wᵏ` — the telescoping identity, by
    induction. With `w = 1−1/ρ`, `1 − w = 1/ρ`, so each per-zero Li contribution carries the moment
    `1/ρ` as an explicit factor. -/
theorem cone_sub_npow_factor (w : Complex) : ∀ n,
    Ceq (Cadd Cone (Cneg (Cnpow w n))) (Cmul (Cadd Cone (Cneg w)) (cgeomSum w n))
  | 0 =>
      -- `1 − 1 = 0 = (1−w)·0`
      Ceq_trans (Cadd_neg Cone) (Ceq_symm (cmul_czero (Cadd Cone (Cneg w))))
  | (n + 1) => by
      -- RHS = (1−w)·(Σ_{k<n} + wⁿ) = (1−w)·Σ + (1−w)·wⁿ ≈ (1−wⁿ) + (wⁿ − w·wⁿ) = 1 − w·wⁿ
      have hIH := cone_sub_npow_factor w n
      -- the off-diagonal term T := (1−w)·wⁿ ≈ wⁿ − w·wⁿ
      have hT : Ceq (Cmul (Cadd Cone (Cneg w)) (Cnpow w n))
          (Cadd (Cnpow w n) (Cneg (Cmul w (Cnpow w n)))) :=
        Ceq_trans (Cmul_comm (Cadd Cone (Cneg w)) (Cnpow w n))
          (Ceq_trans (Cmul_distrib (Cnpow w n) Cone (Cneg w))
            (cadd_congr (Cmul_one (Cnpow w n))
              (Ceq_trans (cmul_cneg (Cnpow w n) w) (cneg_congr (Cmul_comm (Cnpow w n) w)))))
      -- distribute, rewrite first summand by IH and second by hT
      refine Ceq_symm (Ceq_trans (Cmul_distrib (Cadd Cone (Cneg w)) (cgeomSum w n) (Cnpow w n)) ?_)
      refine Ceq_trans (cadd_congr (Ceq_symm hIH) hT) ?_
      -- now: ((1) + (−wⁿ)) + (wⁿ + (−(w·wⁿ)))  ≈  1 + (−(w·wⁿ))
      -- group: A+(B+(C+D)) with B+C = 0
      refine Ceq_trans (Cadd_assoc Cone (Cneg (Cnpow w n))
        (Cadd (Cnpow w n) (Cneg (Cmul w (Cnpow w n))))) ?_
      refine cadd_congr (Ceq_refl Cone) ?_
      refine Ceq_trans (Ceq_symm (Cadd_assoc (Cneg (Cnpow w n)) (Cnpow w n)
        (Cneg (Cmul w (Cnpow w n))))) ?_
      refine Ceq_trans (cadd_congr
        (Ceq_trans (Cadd_comm (Cneg (Cnpow w n)) (Cnpow w n)) (Cadd_neg (Cnpow w n)))
        (Ceq_refl (Cneg (Cmul w (Cnpow w n))))) ?_
      exact czero_cadd (Cneg (Cmul w (Cnpow w n)))

/-- **THE WITNESS TERM, LINEARIZED**: `1 − Re(wⁿ) = Re((1−w)·Σ_{k<n} wᵏ)`. The real part of the
    geometric factorization — the `RHWitness` per-zero term written with the moment `1/ρ = 1−w`
    factored out. (Holds by reading the real component of `cone_sub_npow_factor`; the witness term
    `1 − Re(wⁿ)` is definitionally the real part of `1 − wⁿ = Cadd Cone (Cneg (Cnpow w n))`.) -/
theorem witnessTerm_eq_linear (w : Complex) (n : Nat) :
    Req (Rsub one (Cnpow w n).re) (Cmul (Cadd Cone (Cneg w)) (cgeomSum w n)).re :=
  (cone_sub_npow_factor w n).1

/-- The witness sum in **linearized form**: each summand is `Re((1−w)·Σ_{k<n} wᵏ)` — the per-zero
    contribution with the moment `1/ρ = 1−w` factored out. -/
def witnessSumLinear (ws : List Complex) (n : Nat) : Real :=
  match ws with
  | [] => zero
  | w :: rest =>
      Radd (Cmul (Cadd Cone (Cneg w)) (cgeomSum w n)).re (witnessSumLinear rest n)

/-- **THE WITNESS SUM, LINEARIZED** (the pipeline object): `witnessSum ws n = Σ_w Re((1−w)·Σ_{k<n} wᵏ)`.
    The Bombieri–Lagarias `bl` interface equates `λₙ` to the limit of `witnessSum` over the zeros; this
    rewrites that object with the moment `1/ρ` factored out of every term — the per-zero (left) side of
    the explicit formula, summed. The classical content (the moments `Σ_ρ ρ^{−k}` equal the `−ζ′/ζ`
    data `ηⱼ` plus the archimedean place) is untouched; crux fields stay `none`. -/
theorem witnessSum_eq_linear : ∀ (ws : List Complex) (n : Nat),
    Req (witnessSum ws n) (witnessSumLinear ws n)
  | [], _ => Req_refl _
  | (w :: rest), n =>
      Radd_congr (witnessTerm_eq_linear w n) (witnessSum_eq_linear rest n)

end UOR.Bridge.F1Square.Analysis
