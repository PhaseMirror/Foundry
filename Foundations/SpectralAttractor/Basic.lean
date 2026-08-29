/-
Copyright (c) 2026 Citizen Gardens / Multiplicity Foundation.
Released under Apache 2.0 license.

! ADR-0034-F1-Geometry Scaffolding — Basic locked constants
-/
import Init.Omega
import Multiplicity.SpectralAttractor.Tags

/-!
# ComplexKappa.SpectralAttractor.Basic

Locked numerical data of the spectral attractor (ADR-0034 §2.6, Appendix A),
plus the governance tag attributes `@[adr]` / `@[proof]`.

## Carrier abstraction

Stock Lean core provides no `Real`.  All analytic statements are made over an
*abstract spectral carrier* `R` (classes `SpectralOrderedCarrier`,
`SpectralExpCarrier`).  Each class law is a classical theorem about `ℝ`;
instantiating at ℝ discharges them wholesale.  Until then every theorem holds
for *every* instance — no `-- TODO: replace sorry`, no unproved constant.

## Locked data convention

Certified constants are integers scaled by `certScale = 10^10`, matching the
Appendix-A certificate table verbatim.  Division is performed at the integer
layer only (`Int.fdiv` by constants), so every numeric fact is decidable by
`omega`.
-/

namespace ComplexKappa.SpectralAttractor

set_option autoImplicit false

/-! ## Dimensions -/

/-- Local Hilbert-space dimension: one ground state plus eight zero modes. -/
@[adr] def dim : Nat := 9

/-- Number of zero ordinates carried by the attractor. -/
@[adr] def numOrdinates : Nat := 8

/-- Index of a zero mode (n = 1,…,8 encoded 0-based). -/
abbrev ZeroMode : Type := Fin numOrdinates

/-- Full mode index: `0` = ground state, `i+1` = i-th zero mode. -/
abbrev Mode : Type := Fin dim

/-- Common denominator of all certified constants: values are rationals
`k / certScale` with `certScale = 10^10`. -/
@[adr] def certScale : Nat := 10 ^ 10

/-! ## Carrier signatures -/

/-- Minimal signature of a linearly ordered commutative ring with an integer
embedding.  Every field law below is a classical theorem about `ℝ`. -/
class SpectralOrderedCarrier (R : Type) extends Zero R, One R, Add R, Mul R,
    Neg R where
  /-- The multiplicative unit, carried explicitly so that downstream
  statements never depend on numeral elaboration. -/
  carOne : R
  /-- The carrier's linear order. -/
  carLe : R → R → Prop
  le_refl : ∀ a : R, carLe a a
  le_trans : ∀ a b c : R, carLe a b → carLe b c → carLe a c
  le_antisymm : ∀ a b : R, carLe a b → carLe b a → a = b
  le_total : ∀ a b : R, carLe a b ∨ carLe b a
  add_le_add_left : ∀ a b : R, carLe a b → ∀ t : R, carLe (t + a) (t + b)
  mul_le_mul_right_of_nonneg :
    ∀ a b s : R, carLe a b → carLe 0 s → carLe (a * s) (b * s)
  sq_nonneg : ∀ a : R, carLe 0 (a * a)
  /-- Left unit law, carried explicitly so downstream statements never
  depend on numeral elaboration. -/
  carOne_mul : ∀ a : R, carOne * a = a
  /-- Products of strictly positive elements are strictly positive
  (decomposed order form, for elaboration robustness). -/
  mul_pos :
    ∀ a b : R,
      carLe 0 a ∧ ¬ carLe a 0 →
        carLe 0 b ∧ ¬ carLe b 0 →
          carLe 0 (a * b) ∧ ¬ carLe (a * b) 0
  /-- Embedding of the integers. -/
  fromInt : Int → R
  fromInt_zero : fromInt 0 = 0
  fromInt_one : fromInt 1 = carOne
  fromInt_add : ∀ a b : Int, fromInt (a + b) = fromInt a + fromInt b
  fromInt_neg : ∀ a : Int, fromInt (-a) = -(fromInt a)
  fromInt_nonneg : ∀ a : Int, 0 ≤ a → carLe 0 (fromInt a)
  add_comm : ∀ a b : R, a + b = b + a
  add_assoc : ∀ a b c : R, (a + b) + c = a + (b + c)
  zero_add : ∀ a : R, 0 + a = a
  add_left_neg : ∀ a : R, a + (-a) = 0
  mul_comm : ∀ a b : R, a * b = b * a
  mul_assoc : ∀ a b c : R, (a * b) * c = a * (b * c)
  left_distrib : ∀ a b c : R, (a + b) * c = a * c + b * c
  zero_mul : ∀ a : R, 0 * a = 0

/-- Carrier strict order derived from the non-strict one. -/
def carLt {R : Type} [SpectralOrderedCarrier R] (a b : R) : Prop :=
  SpectralOrderedCarrier.carLe a b ∧ ¬ SpectralOrderedCarrier.carLe b a

instance instLECar {R : Type} [SpectralOrderedCarrier R] : LE R :=
  ⟨SpectralOrderedCarrier.carLe⟩

instance instLTCar {R : Type} [SpectralOrderedCarrier R] : LT R := ⟨carLt⟩

/-- Exponential layer over an ordered carrier. -/
class SpectralExpCarrier (R : Type) [inst : SpectralOrderedCarrier R] where
  /-- The exponential function. -/
  expF : R → R
  exp_pos : ∀ x : R, (0 : R) < expF x
  exp_zero : expF 0 = inst.carOne
  exp_mono : ∀ x y : R, inst.carLe x y → inst.carLe (expF x) (expF y)
  /-- Classical: the exponential of a strictly negative integer lies
  strictly below 1 (decomposed order facts, for elaboration robustness). -/
  exp_lt_one_of_neg :
    ∀ k : Int, k < 0 →
      inst.carLe (expF (inst.fromInt k)) inst.carOne ∧
        ¬ inst.carLe inst.carOne (expF (inst.fromInt k))

/-! ## Envelope width -/

/-- Numerator of the locked envelope width σ = 1/1000. -/
@[adr] def sigmaNum : Int := 1

/-- Denominator of the locked envelope width. -/
@[adr] def sigmaDen : Nat := 1000

@[proof] theorem sigmaDen_pos : 0 < sigmaDen := by decide
@[proof] theorem one_lt_sigmaDen : 1 < sigmaDen := by decide
@[proof] theorem sigmaNum_nonneg : 0 ≤ sigmaNum := by decide

/-! ## Locked ordinates -/

/-- Value table for the locked ordinates of ζ (upper half-plane), carried as
integers scaled by `certScale = 10^10`; each entry is the lower endpoint of
its Appendix-A certificate interval `[γ_n, γ_n + 10^{-10})`.

Full-precision reference values (Odlyzko; Platt–Trudgian 2021):
14.134725141734693, 21.022039638771556, 25.010857580145689,
30.424876125859513, 32.935061587739190, 37.586178158825672,
40.918719012147495, 43.327073280914999.

Keeping the match at the natural-number layer lets every concrete fact close
by kernel `decide` without carrying `Fin` side conditions into the goal. -/
def gammaScaledV : Nat → Int
  | 0 => 141347251417
  | 1 => 210220396387
  | 2 => 250108575801
  | 3 => 304248761258
  | 4 => 329350615877
  | 5 => 375861781588
  | 6 => 409187190121
  | 7 => 433270732809
  | _ => 0

@[adr] def gammaScaled (n : ZeroMode) : Int := gammaScaledV n.val

/-- Step fact: consecutive table entries increase.  The seven in-range
cases close by kernel evaluation; the catch-all is killed by the literal
bound hypothesis. -/
@[proof] theorem gammaScaledV_step : ∀ k : Nat, k < 7 →
    gammaScaledV k < gammaScaledV (k + 1) := by
  intro k hk
  revert hk
  match k with
  | 0 => intro _; decide
  | 1 => intro _; decide
  | 2 => intro _; decide
  | 3 => intro _; decide
  | 4 => intro _; decide
  | 5 => intro _; decide
  | 6 => intro _; decide
  | Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ _)))))) =>
    intro h; omega

/-- Chain fact: the table is strictly increasing on `[0,8)` — proved by
induction on the upper index, pasting `gammaScaledV_step` onto `ih`. -/
@[proof] theorem gammaScaledV_lt : ∀ a b : Nat, a < b → b < 8 →
    gammaScaledV a < gammaScaledV b := by
  intro a b
  induction b with
  | zero =>
    intro hab _
    exact False.elim (by omega)
  | succ b ih =>
    intro hab hb
    match Nat.decEq a b with
    | isTrue heq =>
      rw [heq]
      exact gammaScaledV_step b (by omega)
    | isFalse hne =>
      exact Int.lt_trans (ih (by omega) (by omega))
        (gammaScaledV_step b (by omega))

/-- Strict spectral ordering of the locked ordinates. -/
@[proof] theorem gammaScaled_strictMono {m n : ZeroMode} (h : m.val < n.val) :
    gammaScaled m < gammaScaled n :=
  gammaScaledV_lt m.val n.val h n.isLt

theorem Vpos_aux : ∀ v : Nat, v < 8 → 0 < gammaScaledV v := by
  intro v hv
  revert hv
  match v with
  | 0 => intro _; decide
  | 1 => intro _; decide
  | 2 => intro _; decide
  | 3 => intro _; decide
  | 4 => intro _; decide
  | 5 => intro _; decide
  | 6 => intro _; decide
  | 7 => intro _; decide
  | Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ _))))))) =>
    intro h; omega

/-- Every locked ordinate is positive. -/
@[proof] theorem gammaScaled_pos (n : ZeroMode) : 0 < gammaScaled n :=
  Vpos_aux n.val n.isLt

theorem Vbound_aux : ∀ v : Nat, v < 8 →
    gammaScaledV v < 44 * (10 ^ 10 : Int) := by
  intro v hv
  revert hv
  match v with
  | 0 => intro _; decide
  | 1 => intro _; decide
  | 2 => intro _; decide
  | 3 => intro _; decide
  | 4 => intro _; decide
  | 5 => intro _; decide
  | 6 => intro _; decide
  | 7 => intro _; decide
  | Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ _))))))) =>
    intro h; omega

/-- Ordinates are bounded: every entry is below `44 × certScale`. -/
@[proof] theorem gammaScaled_lt_bound (n : ZeroMode) :
    gammaScaled n < 44 * (10 ^ 10 : Int) :=
  Vbound_aux n.val n.isLt

/-! ## Amplitude weights -/

/-- Integer exponent attached to an ordinate value `g`:
`E(g) = -(σ_num · g²) / σ_den`, computed at the integer layer with floor
division. -/
@[adr] def weightExpScaledV (g : Int) : Int :=
  Int.fdiv (-(sigmaNum * g * g)) (sigmaDen : Int)

/-- Integer exponent attached to mode `n`.  Since every locked ordinate is
positive, `E(n) < 0`; this is what makes every weight strictly below 1. -/
@[adr] def weightExpScaled (n : ZeroMode) : Int :=
  weightExpScaledV (gammaScaled n)

@[proof] theorem weightExpScaledV_neg : ∀ g : Int, 0 < g → weightExpScaledV g < 0 := by
  intro g hg
  have hone : (0 : Int) < 1 := by omega
  have hsn : (0 : Int) < sigmaNum := by decide
  have hp : (0 : Int) < sigmaNum * g * g :=
    Int.mul_pos (Int.mul_pos hsn hg) hg
  have hneg : (-(sigmaNum * g * g) : Int) < 0 := by omega
  have hd : (0 : Int) < sigmaDen := by decide
  exact Int.fdiv_neg_of_neg_of_pos hneg hd

@[proof] theorem weightExpScaled_neg (n : ZeroMode) :
    weightExpScaled n < 0 :=
  weightExpScaledV_neg _ (gammaScaled_pos n)

/-- Carrier-level weight of a zero mode:
`c n = expF (fromInt (weightExpScaled n))`.  The scaling convention folds
the factor σ into the integer layer; see `Certificates` for how the
Appendix-A enclosures transfer through it. -/
@[adr] def c {R : Type} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (n : ZeroMode) : R :=
  se.expF (so.fromInt (weightExpScaled n))

/-- Every amplitude weight is strictly positive. -/
@[proof] theorem c_pos {R : Type} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (n : ZeroMode) : (0 : R) < c n :=
  se.exp_pos (so.fromInt (weightExpScaled n))

/-- Every amplitude weight is strictly smaller than 1: its integer exponent
is negative, and the exponential layer transfers that to the carrier. -/
@[proof] theorem c_lt_one {R : Type} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (n : ZeroMode) : c n < so.carOne :=
  se.exp_lt_one_of_neg (weightExpScaled n) (weightExpScaled_neg n)


end ComplexKappa.SpectralAttractor
