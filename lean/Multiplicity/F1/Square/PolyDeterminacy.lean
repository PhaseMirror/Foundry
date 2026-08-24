/-
F1 square — **the pre-Hilbert layer, brick 64** (`PolyDeterminacy.lean`): **DETERMINACY ON THE
POLYNOMIAL CLASS, AND A DEGREE FLOOR FOR CO-SUPPORT MEMBERS** — the first determinacy result the
layer has, and the structural reason the constructed members `deep3 … deep6` have to grow in
degree with their level.

For an integer-coefficient polynomial test with `d` coefficients (`polyPN a b d`, the repo's own
positive/negative-part idiom, `Σ_{i<d} a_i x^i − Σ_{i<d} b_i x^i`):

    first `d` moments vanish  ⟹  `⟨p,p⟩ ≈ 0`  ⟹  **every** moment vanishes
      (`innerI_polyPN_self_zero`, `polyPN_all_moments_zero`).

Read forwards, that is determinacy on the polynomial class: `d` conditions already exhaust the
moment sequence, so the co-support filtration cannot cut a polynomial test any finer than its own
coefficient count. Read backwards, it is a **degree floor**: a polynomial test that is not
L²-null cannot sit in level `d` unless it carries more than `d` coefficients. The built members
obey it exactly — `deep3` is in level `3` and runs to `x⁴`, `deep6` is in level `6` and runs to
`x⁸` — and it says that growth is forced, not an artifact of how the members were solved.

The proof needs no approximation theory. Expanding `p` in the FIRST slot against `p` in the
second, bilinearity turns `⟨p,p⟩` into a `ℕ`-scaled sum of `⟨xⁱ, p⟩ = ⟨p, xⁱ⟩` over `i < d`
(`innerI_symm`), each of which is a hypothesis. The scaling transfer is brick 43's `pv_scale` at
the rational value `0`, so the sealed (`@[irreducible]`) `natScale` never has to be unfolded. The
step from `⟨p,p⟩ ≈ 0` to *every* moment is brick 63.

HONEST SCOPE — READ THIS BEFORE PARAPHRASING THE RESULT. What THIS FILE proves is determinacy at
the **moment / energy** level: `d` vanishing moments force `⟨p,p⟩ ≈ 0` and force *every* moment to
vanish. It does **not** prove here that `p` is the zero function; "a polynomial with all moments
zero is zero" is a **stronger statement than this file proves**, and the correct summary of this
file is "a polynomial test with `d` coefficients and `d` vanishing moments is moment-null and
L²-energy-null".

(Historical note, corrected: this scope note previously said the pointwise step was unreachable
because the integral API lacked interval splitting. That is **no longer true** — bricks 68–73
supply the splitting law and the whole locality chain, and `L2Definite.lean` uses them to close
the pointwise step at dyadic points. The bound stated in this file is still the moment/energy
one; the upgrade is a separate theorem in a separate file, and this file's own statements have
not changed.)

Determinacy for **polynomial** tests, in that sense, only. The
general question — a nonzero bounded-Lipschitz test on `[0,1]` with every moment vanishing — is
untouched; it needs a constructive approximation theorem (Bernstein) the repo does not have. The support side is also
untouched: `polyPN a b d` is `[0,1]`-supported exactly when `Σ a_i = Σ b_i` (the "both parts sum
to the same value" condition the built members satisfy), which is not needed here because the
statement is at the moment level. Nothing touches the Weil form. Step 4 is RH. The crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.L2MomentBridge
import Multiplicity.F1.Square.CoSupportSubspace

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `zero` read as a rational constant (local: the copies in bricks 55/57 are private). -/
private theorem zeroQ_val : Req zero (ofQ (⟨0, 1⟩ : Q) (by decide)) :=
  Req_of_seq_Qeq (fun _ => Qeq_refl _)

-- ===========================================================================
-- Integer-coefficient polynomial tests.
-- ===========================================================================

/-- **The `ℕ`-coefficient polynomial test** `Σ_{i<d} a_i · xⁱ`, built from the additive structure
    and `natScale` alone. -/
def polyN (a : Nat → Nat) : Nat → L2Test
  | 0 => zeroL2
  | d + 1 => L2Test.add (polyN a d) (natScale (a d) (powTest d))

/-- **The `ℤ`-coefficient polynomial test**, in the repo's positive/negative-part idiom:
    `Σ_{i<d} a_i xⁱ − Σ_{i<d} b_i xⁱ`. -/
def polyPN (a b : Nat → Nat) (d : Nat) : L2Test :=
  L2Test.sub (polyN a d) (polyN b d)

-- ===========================================================================
-- Expanding in the first slot.
-- ===========================================================================

/-- Scaling a test that already pairs to zero keeps it pairing to zero — through brick 43's
    rational-value transfer, so the sealed `natScale` is never unfolded. -/
theorem innerI_natScale_zero (φ ψ : L2Test) (h : Req (innerI φ ψ) zero) (k : Nat) :
    Req (innerI (natScale k φ) ψ) zero := by
  refine Req_trans (pv_scale k (v := (⟨0, 1⟩ : Q)) (by decide) (by decide)
    (Req_trans h zeroQ_val) ?_) (Req_symm zeroQ_val)
  show Qeq (mul (⟨(k : Int), 1⟩ : Q) (⟨0, 1⟩ : Q)) (⟨0, 1⟩ : Q)
  simp only [Qeq, mul]
  ring_uor

/-- **A polynomial test pairs to zero with anything the monomials do**: if `⟨xⁱ, ψ⟩ ≈ 0` for
    every `i < d`, then `⟨Σ_{i<d} a_i xⁱ, ψ⟩ ≈ 0`. -/
theorem innerI_polyN_zero (a : Nat → Nat) (ψ : L2Test) :
    ∀ d : Nat, (∀ i : Nat, i < d → Req (innerI (powTest i) ψ) zero) →
      Req (innerI (polyN a d) ψ) zero
  | 0, _ => innerI_zeroL2 ψ
  | d + 1, h => by
    refine Req_trans (innerI_add_left (polyN a d) (natScale (a d) (powTest d)) ψ) ?_
    refine Req_trans (Radd_congr
      (innerI_polyN_zero a ψ d (fun i hi => h i (Nat.lt_succ_of_lt hi)))
      (innerI_natScale_zero (powTest d) ψ (h d (Nat.lt_succ_self d)) (a d))) ?_
    exact Req_trans (Radd_zero zero) (Req_refl zero)

/-- The same for the signed test. -/
theorem innerI_polyPN_zero (a b : Nat → Nat) (d : Nat) (ψ : L2Test)
    (h : ∀ i : Nat, i < d → Req (innerI (powTest i) ψ) zero) :
    Req (innerI (polyPN a b d) ψ) zero := by
  refine Req_trans (innerI_sub_left (polyN a d) (polyN b d) ψ) ?_
  refine Req_trans (Rsub_congr (innerI_polyN_zero a ψ d h) (innerI_polyN_zero b ψ d h)) ?_
  exact Radd_neg zero

-- ===========================================================================
-- Determinacy on the polynomial class.
-- ===========================================================================

/-- **`d` COEFFICIENTS, `d` MOMENTS, ZERO ENERGY**: a polynomial test with `d` coefficients whose
    first `d` moments vanish has zero L² energy. The `d` hypotheses already saturate the form:
    expanding the first slot, `⟨p,p⟩` is a `ℕ`-scaled sum of `⟨xⁱ, p⟩ = ⟨p, xⁱ⟩`, `i < d`. -/
theorem innerI_polyPN_self_zero (a b : Nat → Nat) (d : Nat)
    (h : ∀ i : Nat, i < d → Req (mellinMoment (polyPN a b d) i) zero) :
    Req (innerI (polyPN a b d) (polyPN a b d)) zero :=
  innerI_polyPN_zero a b d (polyPN a b d)
    (fun i hi => Req_trans (innerI_symm (powTest i) (polyPN a b d)) (h i hi))

/-- **DETERMINACY ON THE POLYNOMIAL CLASS**: the first `d` moments already determine all of them
    — `d` vanishing moments force **every** moment of a `d`-coefficient polynomial test to
    vanish. (Through brick 63: zero L² energy kills the whole moment sequence.) -/
theorem polyPN_all_moments_zero (a b : Nat → Nat) (d : Nat)
    (h : ∀ i : Nat, i < d → Req (mellinMoment (polyPN a b d) i) zero) (n : Nat) :
    Req (mellinMoment (polyPN a b d) n) zero :=
  moments_zero_of_innerI_self_zero (polyPN a b d) (innerI_polyPN_self_zero a b d h) n

/-- **THE `ℓ²` MOMENT ENERGY VANISHES TOO** — the polynomial class meets brick 61's null-space
    characterization. -/
theorem momentL2Sq_polyPN_zero (a b : Nat → Nat) (d : Nat)
    (h : ∀ i : Nat, i < d → Req (mellinMoment (polyPN a b d) i) zero) :
    Req (momentL2Sq (polyPN a b d)) zero :=
  momentL2Sq_zero_of_innerI_self_zero (polyPN a b d) (innerI_polyPN_self_zero a b d h)

/-- **THE DEGREE FLOOR**, contrapositive form: a `d`-coefficient polynomial test with *any*
    nonzero moment must already have a nonzero moment **below** `d`. So a nonzero member of
    co-support level `K` needs more than `K` coefficients — which is exactly what the built
    members do (`deep3` in level `3` runs to `x⁴`; `deep6` in level `6` runs to `x⁸`). -/
theorem polyPN_degree_floor (a b : Nat → Nat) (d n : Nat)
    (hn : ¬ Req (mellinMoment (polyPN a b d) n) zero) :
    ¬ (∀ i : Nat, i < d → Req (mellinMoment (polyPN a b d) i) zero) :=
  fun h => hn (polyPN_all_moments_zero a b d h n)

/-- **THE FILTRATION IS TRIVIAL ON A FIXED COEFFICIENT COUNT**: a `d`-coefficient polynomial test
    in co-support level `d` is L²-null. -/
theorem polyPN_level_null (a b : Nat → Nat) (d : Nat) (hsupp : UnitSupported (polyPN a b d))
    (hK : HatVanishes (polyPN a b d) d (C := (⟨0, 1⟩ : Q)) (by decide)
      (by show (0 : Int) ≤ 0; decide) (allDecay_of_supp (polyPN a b d) hsupp)) :
    Req (innerI (polyPN a b d) (polyPN a b d)) zero :=
  innerI_polyPN_self_zero a b d ((hatVanishes_iff_orthogonal (polyPN a b d) d hsupp).mp hK)

end Multiplicity.UOR.Bridge.F1Square.Square
