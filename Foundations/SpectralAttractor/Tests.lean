/-
Copyright (c) 2026 Multiplicity. All rights reserved.
Released under Apache 2.0 license.
Authors: Multiplicity Foundry
-/
import Init.Omega
import Foundations.SpectralAttractor.Tags
import Foundations.SpectralAttractor.Basic
import Foundations.SpectralAttractor.Certificates
import Foundations.SpectralAttractor.Matrices
import Foundations.SpectralAttractor.CPTP
import Foundations.SpectralAttractor.Contraction
import Foundations.SpectralAttractor.Energy
import Foundations.SpectralAttractor.Atlas

/-!
# Test harness

Self-contained checks for the ADR-0034-F1 scaffolding:

* a concrete carrier instance (`Int`);
* positive checks against the locked data;
* a *negative* check: an indefinite matrix is proved **not** PSD - the
  type system rejects it as an atlas entry;
* property-style `forall` re-instantiations of the library theorems;
* an `IO` runner printing PASS lines (`lake build && lake test`).

Scope note: there is deliberately no `SpectralExpCarrier Int` instance.
The class laws (positivity, strict sub-unit decay for negative arguments,
monotonicity) are jointly unsatisfiable on the discrete integers, which is
itself evidence that the laws carry content.  All matrix-level machinery
is exponential-free and fully checkable here.
-/

namespace ComplexKappa.SpectralAttractor.Tests

open ComplexKappa.SpectralAttractor

/-! ## A concrete carrier instance -/

instance intCarrier : SpectralOrderedCarrier Int where
  carOne := 1
  carLe := (· ≤ ·)
  le_refl := fun _ => Int.le_refl _
  le_trans := fun _ _ _ hab hbc => Int.le_trans hab hbc
  le_antisymm := fun _ _ hab hba => Int.le_antisymm hab hba
  le_total := fun a b => Int.le_total a b
  add_le_add_left := fun _ _ hab t => Int.add_le_add_left hab t
  mul_le_mul_right_of_nonneg := fun _ _ s hab hs =>
    Int.mul_le_mul_of_nonneg_right hab hs
  sq_nonneg := fun a => by
    rcases Int.lt_trichotomy 0 a with h | h | h
    · exact Int.mul_nonneg (by omega) (by omega)
    · subst h; omega
    · have h2 : 0 ≤ (-a) * (-a) := Int.mul_nonneg (by omega) (by omega)
      rw [Int.neg_mul_neg] at h2
      exact h2
  carOne_mul := fun a => Int.one_mul a
  mul_pos := fun a b ha hb => by
    rcases Int.lt_trichotomy 0 a with hx | hx | hx
    · rcases Int.lt_trichotomy 0 b with hy | hy | hy
      · have hp : 0 < a * b := Int.mul_pos hx hy
        exact ⟨by omega, by omega⟩
      · exact absurd (show b ≤ (0:Int) from by omega) hb.2
      · exact absurd (show b ≤ (0:Int) from by omega) hb.2
    · exact absurd (show a ≤ (0:Int) from by omega) ha.2
    · exact absurd (show a ≤ (0:Int) from by omega) ha.2
  fromInt := fun x => x
  fromInt_zero := rfl
  fromInt_one := rfl
  fromInt_add := fun _ _ => rfl
  fromInt_neg := fun _ => rfl
  fromInt_nonneg := fun _ ha => ha
  add_comm := fun a b => Int.add_comm a b
  add_assoc := fun a b c => Int.add_assoc a b c
  zero_add := fun a => Int.zero_add a
  add_left_neg := fun a => by omega
  mul_comm := fun a b => Int.mul_comm a b
  mul_assoc := fun a b c => Int.mul_assoc a b c
  left_distrib := fun a b c => by
    rw [Int.mul_comm (a + b) c, Int.mul_add, Int.mul_comm c a, Int.mul_comm c b]
  zero_mul := fun a => Int.zero_mul a

/-! ## Positive checks against the locked data -/

/-- Dimensions are as locked. -/
@[proof] theorem check_dims : dim = 9 ∧ numOrdinates = 8 := by decide

/-- Locked ordinates strictly increase (spot pair, modes 3 < 4). -/
@[proof] theorem check_gamma_spot :
    gammaScaled ⟨3, by decide⟩ < gammaScaled ⟨4, by decide⟩ := by decide

/-- Spot value: width of certificate 4 is exactly `10^10`. -/
@[proof] theorem check_width_spot :
    (ordinateCert ⟨4, by decide⟩).hi - (ordinateCert ⟨4, by decide⟩).lo
      = 1 := by decide

/-- Spot value: certificates 4 and 5 are disjoint. -/
@[proof] theorem check_disjoint_spot :
    (ordinateCert ⟨4, by decide⟩).hi ≤ (ordinateCert ⟨5, by decide⟩).lo :=
  ordinateCert_disjoint ⟨4, by decide⟩ ⟨5, by decide⟩ (by decide)

/-- Dephasing channel: trace preservation instantiates on `Int`. -/
@[proof] theorem check_dephasing_tp :
    TracePreserving (nch := 2) (R := Int) ⟨dephasingOps⟩ :=
  dephasing_tracePreserving

/-- Dephasing channel: complete positivity instantiates on `Int`. -/
@[proof] theorem check_dephasing_kp :
    KrausPositive (nch := 2) (R := Int) ⟨dephasingOps⟩ :=
  dephasing_KrausPositive

/-- Atlas core: compressed traces of the locked Hamiltonian are
nonnegative on `Int`. -/
@[proof] theorem check_atlas_core (D : Fin dim → Vec Int) :
    (0:Int) ≤ compressedTrace (R := Int) D (diagOf (R := Int) hamiltonianDiag) :=
  compressedTrace_nonneg D (IsPSD_hamiltonianDiag (R := Int))

/-! ## Negative check: the type system rejects indefinite entries -/

/-- An indefinite diagonal matrix: `+1` on the ground mode, `-1` on mode
one, zero elsewhere. -/
@[adr] def badMat : Mat Int :=
  fun i j =>
    if i.val = 0 ∧ j.val = 0 then 1
    else if i.val = 1 ∧ j.val = 1 then -(1 : Int) else 0

/-- Witness vector: excitation of mode one. -/
def badVec : Fin dim → Int := fun i => if i.val = 1 then 1 else 0

private theorem quad_bad : quadMat badMat badVec = -(1 : Int) := by decide

/-- The indefinite matrix is **not** PSD: any claim `IsPSD badMat`
produces `0 ≤ -1`, which is decidable-false. -/
@[proof] theorem bad_not_psd : ¬ IsPSD (R := Int) badMat :=
  fun h => by
    have q := h badVec
    rw [quad_bad] at q
    have q' : (0:Int) ≤ -1 := q
    exact absurd q' (by omega)

/-! ## Property-style checks (forall statements) -/

/-- Property: every certificate interval has positive width. -/
@[proof] theorem prop_widths_pos (n : ZeroMode) :
    (ordinateCert n).lo < (ordinateCert n).hi := by
  have h1 := ordinateCert_lo_pos n
  have h2 := ordinateCert_width n
  omega

/-- Property: distinct certificate intervals are disjoint. -/
@[proof] theorem prop_disjoint (m n : ZeroMode) (h : m.val < n.val) :
    (ordinateCert m).hi ≤ (ordinateCert n).lo :=
  ordinateCert_disjoint m n h

/-- Property: every locked weight exponent is negative. -/
@[proof] theorem prop_weights_neg (n : ZeroMode) :
    weightExpScaled n < 0 := weightExpScaled_neg n

/-- Property: contraction rates are bounded by one (decomposed form). -/
@[proof] theorem prop_rate_bounds {R} [so : SpectralOrderedCarrier R]
    [se : SpectralExpCarrier R] (n : ZeroMode) :
    so.carLe czero (rateSq n) ∧ ¬ so.carLe so.carOne (rateSq n) :=
  rateSq_lt_carOne n

/-- Property-style re-instantiation of the Lyapunov descent theorem. -/
@[proof] theorem prop_lyapunov_descent (A : ZeroMode → Int)
    (hA : ∀ n, 0 ≤ A n) (k : Nat) :
    orbitEnergy A (Nat.succ k) + amplitudeMass A ≤ orbitEnergy A k :=
  orbitEnergy_step A hA k

/-- Balance identity holds concretely at mode 0. -/
example : (sigmaDen : Int) * weightExpScaled ⟨0, by decide⟩
      + Int.fmod (-(sigmaNum * gammaScaled ⟨0, by decide⟩ *
        gammaScaled ⟨0, by decide⟩)) (sigmaDen : Int)
    = -(sigmaNum * gammaScaled ⟨0, by decide⟩ *
        gammaScaled ⟨0, by decide⟩) :=
  weightExpScaled_balance ⟨0, by decide⟩

end ComplexKappa.SpectralAttractor.Tests

/-! ## IO runner (top-level entry point) -/

open ComplexKappa.SpectralAttractor in
def checkLabel (b : Bool) (label : String) : IO Bool := do
  if b then IO.println s!"PASS {label}" else IO.println s!"FAIL {label}"
  return b

open ComplexKappa.SpectralAttractor ComplexKappa.SpectralAttractor.Tests in
def main : IO Unit := do
  let mut ok := true
  ok := (← checkLabel (dim == 9 && numOrdinates == 8) "dims") && ok
  ok := (← checkLabel
    (gammaScaled ⟨3, by decide⟩ < gammaScaled ⟨4, by decide⟩) "gamma-spot") && ok
  ok := (← checkLabel
    ((ordinateCert ⟨4, by decide⟩).hi - (ordinateCert ⟨4, by decide⟩).lo
      == 1) "width-spot") && ok
  ok := (← checkLabel
    ((ordinateCert ⟨4, by decide⟩).hi ≤ (ordinateCert ⟨5, by decide⟩).lo)
    "disjoint-spot") && ok
  ok := (← checkLabel
    (quadMat badMat badVec == -(1 : Int)) "negative-psd-witness") && ok
  ok := (← checkLabel
    (decide (orbitExp ⟨2, by decide⟩ 6 + 1 ≤ orbitExp ⟨2, by decide⟩ 5))
      "lyap-step") && ok
  ok := (← checkLabel
    (decide (let A : ZeroMode → Int := fun _ => 3;
      orbitEnergy A 4 + amplitudeMass A ≤ orbitEnergy A 3))
      "energy-descend") && ok
  unless ok do throw <| IO.userError "some checks FAILED"
  IO.println "ALL CHECKS PASSED"
