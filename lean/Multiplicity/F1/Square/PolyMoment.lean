/-
F1 square — **the pre-Hilbert layer, brick 65** (`PolyMoment.lean`): **EVERY POLYNOMIAL TEST'S
MOMENT, IN CLOSED FORM** — one theorem replacing every per-member moment computation the layer has
done by hand:

    `⟨Σ_{i<d} a_i xⁱ, xⁿ⟩  =  Σ_{i<d} a_i/(i+n+1)`   (`mellinMoment_polyN`)
    `⟨polyPN a b d, xⁿ⟩     =  polyMomQ a n d − polyMomQ b n d`   (`mellinMoment_polyPN`),

an explicit **rational**, read straight off brick 34's Hilbert matrix `⟨xⁱ,xⁿ⟩ = 1/(i+n+1)`. Every
constructed member so far — `cubeBump`, the quartic, `deep3 … deep6`, `lin1`, `lin2` — had its
moments evaluated by a hand-built `pv_add`/`pv_scale` chain, one theorem per degree per member.
This is the general law those chains were instances of, proved once by induction on the
coefficient count.

The consequence is that the polynomial co-support theory is **finite rational linear algebra**:
`polyPN a b d` lies in co-support level `K` exactly when the `K` rational equations
`polyMomQ a n d = polyMomQ b n d` (`n < K`) hold (`polyPN_moments_zero_of_rational`), and with
brick 64 the case `K = d` already forces the *whole* moment sequence to vanish
(`polyPN_all_moments_zero_of_rational`). Constructing a member at any depth is now a `ℚ`-linear
solve against the Hilbert matrix, with no new integration and no new per-degree engine.

The formula is cross-checked against an independently hand-computed value: the same coefficient
data as brick 36's `lin1 = x − 3x² + 2x³`, run through `polyMomQ`, reproduces
`⟨lin1, x⁰⟩ = 0` and `⟨lin1, x¹⟩ = −1/60` (`polyMoment_lin1_zero`, `polyMoment_lin1_one`).

HONEST SCOPE. A closed form for the moments of `ℤ`-coefficient polynomial tests on `[0,1]`.
It says nothing about which coefficient vectors solve the system (existence at general `K` is
still the hypergeometric identity the layer cannot reach), nothing about the support side
(`polyPN a b d` is `[0,1]`-supported exactly when the two coefficient sums agree — not needed
here, since the statement is at the moment level), and nothing about the Weil form. Step 4 is RH.
The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.PolyDeterminacy
import Multiplicity.F1.Square.HilbertGram
import Multiplicity.F1.Square.CoSupportStrict

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `zero` read as a rational constant (local: the copies in bricks 55/57/64 are private). -/
private theorem zeroQval : Req zero (ofQ (⟨0, 1⟩ : Q) (by decide)) :=
  Req_of_seq_Qeq (fun _ => Qeq_refl _)

-- ===========================================================================
-- The closed form.
-- ===========================================================================

/-- **The rational `n`-th moment of `Σ_{i<d} a_i xⁱ`**: `Σ_{i<d} a_i/(i+n+1)`, the `n`-th row of
    brick 34's Hilbert matrix contracted against the coefficient vector. -/
def polyMomQ (a : Nat → Nat) (n : Nat) : Nat → Q
  | 0 => (⟨0, 1⟩ : Q)
  | d + 1 => add (polyMomQ a n d) (mul (⟨((a d : Nat) : Int), 1⟩ : Q) (⟨1, d + n + 1⟩ : Q))

theorem polyMomQ_den (a : Nat → Nat) (n : Nat) : ∀ d : Nat, 0 < (polyMomQ a n d).den
  | 0 => Nat.one_pos
  | d + 1 => add_den_pos (polyMomQ_den a n d) (Qmul_den_pos Nat.one_pos (Nat.succ_pos (d + n)))

/-- **THE MOMENT OF A `ℕ`-COEFFICIENT POLYNOMIAL TEST IS AN EXPLICIT RATIONAL.** -/
theorem mellinMoment_polyN (a : Nat → Nat) (n : Nat) : ∀ d : Nat,
    Req (mellinMoment (polyN a d) n) (ofQ (polyMomQ a n d) (polyMomQ_den a n d))
  | 0 => Req_trans (innerI_zeroL2 (powTest n)) zeroQval
  | d + 1 =>
      pv_add (polyMomQ_den a n d) (Qmul_den_pos Nat.one_pos (Nat.succ_pos (d + n)))
        (polyMomQ_den a n (d + 1))
        (mellinMoment_polyN a n d)
        (pv_scale (a d) (Nat.succ_pos (d + n))
          (Qmul_den_pos Nat.one_pos (Nat.succ_pos (d + n)))
          (innerI_powTest_hilbert d n) (Qeq_refl _))
        (Qeq_refl _)

/-- **THE MOMENT OF A `ℤ`-COEFFICIENT POLYNOMIAL TEST**, in the repo's value-chaining shape. -/
theorem mellinMoment_polyPN (a b : Nat → Nat) (n d : Nat) {v : Q} (hvd : 0 < v.den)
    (hq : Qeq (add (polyMomQ a n d) (neg (polyMomQ b n d))) v) :
    Req (mellinMoment (polyPN a b d) n) (ofQ v hvd) := by
  refine Req_trans (innerI_sub_left (polyN a d) (polyN b d) (powTest n)) ?_
  refine Req_trans (Rsub_congr (mellinMoment_polyN a n d) (mellinMoment_polyN b n d)) ?_
  exact sub_ofQ_val (polyMomQ_den a n d) (polyMomQ_den b n d) hvd hq

-- ===========================================================================
-- Co-support as a rational linear system.
-- ===========================================================================

/-- `A = B` as rationals gives `A − B = 0`. -/
private theorem Qsub_eq_zero {A B : Q} (h : Qeq A B) : Qeq (add A (neg B)) (⟨0, 1⟩ : Q) := by
  simp only [Qeq, add, neg] at h ⊢
  have e : (-B.num) * (A.den : Int) = -(B.num * (A.den : Int)) := by ring_uor
  rw [e]
  omega

/-- **CO-SUPPORT IS A RATIONAL LINEAR SYSTEM**: the `n`-th moment of `polyPN a b d` vanishes
    exactly when the two coefficient vectors have the same `n`-th Hilbert contraction. -/
theorem polyPN_moments_zero_of_rational (a b : Nat → Nat) (d K : Nat)
    (h : ∀ n : Nat, n < K → Qeq (polyMomQ a n d) (polyMomQ b n d)) :
    ∀ n : Nat, n < K → Req (mellinMoment (polyPN a b d) n) zero :=
  fun n hn =>
    Req_trans (mellinMoment_polyPN a b n d (v := (⟨0, 1⟩ : Q)) (by decide)
      (Qsub_eq_zero (h n hn))) (Req_symm zeroQval)

/-- **`d` RATIONAL EQUATIONS EXHAUST THE MOMENT SEQUENCE** — brick 64's determinacy, now stated
    entirely in terms of the coefficient data: solving the `d × d` Hilbert system kills *every*
    moment, not only the `d` that were imposed. -/
theorem polyPN_all_moments_zero_of_rational (a b : Nat → Nat) (d : Nat)
    (h : ∀ n : Nat, n < d → Qeq (polyMomQ a n d) (polyMomQ b n d)) (n : Nat) :
    Req (mellinMoment (polyPN a b d) n) zero :=
  polyPN_all_moments_zero a b d (polyPN_moments_zero_of_rational a b d d h) n

-- ===========================================================================
-- The cross-check against a hand-computed member.
-- ===========================================================================

/-- The positive part of brick 36's `lin1 = x − 3x² + 2x³`, as coefficient data. -/
private def lin1CoefP : Nat → Nat
  | 1 => 1
  | 3 => 2
  | _ => 0

/-- The negative part of `lin1`. -/
private def lin1CoefN : Nat → Nat
  | 2 => 3
  | _ => 0

/-- **THE FORMULA REPRODUCES THE HAND COMPUTATION (zeroth moment)**: `1/2 − 3/3 + 2/4 = 0`,
    matching brick 36's `lin1_moment_zero`. -/
theorem polyMoment_lin1_zero :
    Req (mellinMoment (polyPN lin1CoefP lin1CoefN 4) 0) zero :=
  Req_trans (mellinMoment_polyPN lin1CoefP lin1CoefN 0 4 (v := (⟨0, 1⟩ : Q))
    (by decide) (by decide)) (Req_symm zeroQval)

/-- **THE FORMULA REPRODUCES THE HAND COMPUTATION (first moment)**:
    `1/3 − 3/4 + 2/5 = −1/60`, matching brick 36's `lin1_moment_one`. -/
theorem polyMoment_lin1_one :
    Req (mellinMoment (polyPN lin1CoefP lin1CoefN 4) 1)
      (ofQ (⟨-1, 60⟩ : Q) (by decide)) :=
  mellinMoment_polyPN lin1CoefP lin1CoefN 1 4 (by decide) (by decide)

end Multiplicity.UOR.Bridge.F1Square.Square
