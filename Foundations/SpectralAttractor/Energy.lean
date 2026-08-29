/-
Copyright (c) 2026 Multiplicity. All rights reserved.
Released under Apache 2.0 license.
Authors: Multiplicity Foundry
-/
import Init.Omega
import Foundations.SpectralAttractor.Tags
import Foundations.SpectralAttractor.Basic
import Foundations.SpectralAttractor.Certificates

/-!
# The γ-weighted Lyapunov layer

Integer-layer energy accounting for the spectral attractor (ADR-0034-F1
prime-move #3).  Everything here lives at the locked integer scale
(`certScale = 10^10`, `σ = 1/1000`) and closes by kernel arithmetic —
no carrier class, no analytic obligation.

Machine-checked content:

* **Dissipation quanta**: every mode carries an integral damping quantum
  `dissipation n = -weightExpScaled n ≥ 1`;
* **Division balance**: the quadratic numerator splits exactly,
  `σden · w_n + ρ_n = -σ γ_n²` with certified remainder `0 ≤ ρ_n < σden`
  (`Int.mul_fdiv_add_fmod` at the integer layer);
* **Envelope anti-monotonicity**: larger locked ordinates carry strictly
  more negative envelope exponents (per-entry kernel decisions);
* **Squaring-orbit exponents** `orbitExp n k` (the integer exponent of the
  k-th iterate of the contraction layer's `rateSqPow` orbit):
  doubling balance `e_{k+1} = e_k + e_k` and the strict Lyapunov step
  `e_{k+1} + 1 ≤ e_k`;
* **Configuration energy descent**: for every nonnegative amplitude family
  the total orbit energy strictly decreases by at least its total mass per
  squaring step — the discrete attractor gauge.
-/

namespace ComplexKappa.SpectralAttractor

/-! ## Dissipation quanta -/

/-- Integer damping quantum attached to a raw ordinate value. -/
@[adr] def dissipationV (g : Int) : Int := -weightExpScaledV g

/-- Integer damping quantum of mode `n`: the negated envelope exponent. -/
@[adr] def dissipation (n : ZeroMode) : Int := -weightExpScaled n

/-- Auxiliary: the quantum evaluated exactly on each locked entry. -/
theorem dissipationV_ge_one_aux : ∀ v : Nat, v < 8 →
    1 ≤ dissipationV (gammaScaledV v) := by
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

/-- Every mode dissipates by at least one unit quantum. -/
@[proof] theorem dissipation_ge_one (n : ZeroMode) :
    1 ≤ dissipation n :=
  dissipationV_ge_one_aux n.val n.isLt

/-- Every damping quantum is positive. -/
@[proof] theorem dissipation_pos (n : ZeroMode) : 0 < dissipation n := by
  have h := dissipation_ge_one n
  omega

/-! ## Division balance at the integer layer -/

/-- **Balance identity**: the quadratic numerator splits exactly into the
denominator times the envelope exponent plus a remainder —
`(γ²/1000) = w_n + ρ_n/1000` realized as an integer identity via
`Int.mul_fdiv_add_fmod`. -/
@[proof] theorem weightExpScaled_balance (n : ZeroMode) :
    (sigmaDen : Int) * weightExpScaled n
      + Int.fmod (-(sigmaNum * gammaScaled n * gammaScaled n))
          (sigmaDen : Int)
        = -(sigmaNum * gammaScaled n * gammaScaled n) :=
  Int.mul_fdiv_add_fmod _ _

/-- Auxiliary: the balance remainder, bounded below and above, evaluated
exactly on each locked entry. -/
theorem rem_bound_aux : ∀ v : Nat, v < 8 →
    0 ≤ Int.fmod (-(sigmaNum * gammaScaledV v * gammaScaledV v))
          (sigmaDen : Int) ∧
    Int.fmod (-(sigmaNum * gammaScaledV v * gammaScaledV v))
          (sigmaDen : Int) < (sigmaDen : Int) := by
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

/-- Certified balance remainder of mode `n`: `0 ≤ ρ_n < σ = 1/1000`. -/
@[proof] theorem weightExpScaled_rem_bound (n : ZeroMode) :
    0 ≤ Int.fmod (-(sigmaNum * gammaScaled n * gammaScaled n))
          (sigmaDen : Int) ∧
    Int.fmod (-(sigmaNum * gammaScaled n * gammaScaled n))
          (sigmaDen : Int) < (sigmaDen : Int) :=
  rem_bound_aux n.val n.isLt

/-! ## Envelope anti-monotonicity -/

/-- Larger locked ordinates carry more negative envelope exponents:
for `a < b` both in range, the exponent of entry `b` does not exceed that
of entry `a`.  Kernel decisions on all ordered pairs of the locked table;
this is what makes attractor selection well-defined at the integer layer. -/
theorem wexp_anti_aux : ∀ a b : Nat, a < b → b < 8 →
    weightExpScaledV (gammaScaledV b) ≤ weightExpScaledV (gammaScaledV a) := by
  intro a b hab hb
  revert hab hb
  match a, b with
  | 0, 0 => intro hab _; omega
  | 0, 1 => intro _ _; decide
  | 0, 2 => intro _ _; decide
  | 0, 3 => intro _ _; decide
  | 0, 4 => intro _ _; decide
  | 0, 5 => intro _ _; decide
  | 0, 6 => intro _ _; decide
  | 0, 7 => intro _ _; decide
  | 0, Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (_)))))))) => intro _ hb; omega
  | 1, 0 => intro hab _; omega
  | 1, 1 => intro hab _; omega
  | 1, 2 => intro _ _; decide
  | 1, 3 => intro _ _; decide
  | 1, 4 => intro _ _; decide
  | 1, 5 => intro _ _; decide
  | 1, 6 => intro _ _; decide
  | 1, 7 => intro _ _; decide
  | 1, Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (_)))))))) => intro _ hb; omega
  | 2, 0 => intro hab _; omega
  | 2, 1 => intro hab _; omega
  | 2, 2 => intro hab _; omega
  | 2, 3 => intro _ _; decide
  | 2, 4 => intro _ _; decide
  | 2, 5 => intro _ _; decide
  | 2, 6 => intro _ _; decide
  | 2, 7 => intro _ _; decide
  | 2, Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (_)))))))) => intro _ hb; omega
  | 3, 0 => intro hab _; omega
  | 3, 1 => intro hab _; omega
  | 3, 2 => intro hab _; omega
  | 3, 3 => intro hab _; omega
  | 3, 4 => intro _ _; decide
  | 3, 5 => intro _ _; decide
  | 3, 6 => intro _ _; decide
  | 3, 7 => intro _ _; decide
  | 3, Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (_)))))))) => intro _ hb; omega
  | 4, 0 => intro hab _; omega
  | 4, 1 => intro hab _; omega
  | 4, 2 => intro hab _; omega
  | 4, 3 => intro hab _; omega
  | 4, 4 => intro hab _; omega
  | 4, 5 => intro _ _; decide
  | 4, 6 => intro _ _; decide
  | 4, 7 => intro _ _; decide
  | 4, Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (_)))))))) => intro _ hb; omega
  | 5, 0 => intro hab _; omega
  | 5, 1 => intro hab _; omega
  | 5, 2 => intro hab _; omega
  | 5, 3 => intro hab _; omega
  | 5, 4 => intro hab _; omega
  | 5, 5 => intro hab _; omega
  | 5, 6 => intro _ _; decide
  | 5, 7 => intro _ _; decide
  | 5, Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (_)))))))) => intro _ hb; omega
  | 6, 0 => intro hab _; omega
  | 6, 1 => intro hab _; omega
  | 6, 2 => intro hab _; omega
  | 6, 3 => intro hab _; omega
  | 6, 4 => intro hab _; omega
  | 6, 5 => intro hab _; omega
  | 6, 6 => intro hab _; omega
  | 6, 7 => intro _ _; decide
  | 6, Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (_)))))))) => intro _ hb; omega
  | 7, 0 => intro hab _; omega
  | 7, 1 => intro hab _; omega
  | 7, 2 => intro hab _; omega
  | 7, 3 => intro hab _; omega
  | 7, 4 => intro hab _; omega
  | 7, 5 => intro hab _; omega
  | 7, 6 => intro hab _; omega
  | 7, 7 => intro hab _; omega
  | 7, Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (_)))))))) => intro _ hb; omega
  | Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (Nat.succ (_)))))))), _ => intro hab _; omega
  -- Strict form on distinct modes.
@[proof] theorem wexp_anti {m n : ZeroMode} (h : m.val < n.val) :
    weightExpScaled n ≤ weightExpScaled m :=
  wexp_anti_aux m.val n.val h n.isLt

/-! ## Squaring-orbit exponents -/

/-- Integer exponent carried by the `k`-th squaring iterate of mode `n`
(the exponent twin of `Contraction.rateSqPow`):
`orbitExp n 0 = 2 * weightExpScaled n`,
`orbitExp n (k+1) = orbitExp n k + orbitExp n k`. -/
@[adr] def orbitExp (n : ZeroMode) : Nat → Int
  | 0 => 2 * weightExpScaled n
  | Nat.succ k => orbitExp n k + orbitExp n k

/-- Every orbit exponent is negative. -/
@[proof] theorem orbitExp_neg (n : ZeroMode) :
    ∀ k : Nat, orbitExp n k < 0 := by
  intro k
  induction k with
  | zero =>
    show 2 * weightExpScaled n < 0
    have hw := weightExpScaled_neg n
    omega
  | succ k ih =>
    show orbitExp n k + orbitExp n k < 0
    omega

/-- **Strict Lyapunov step**: each squaring deepens the exponent deficit by
more than one unit quantum — `orbitExp n (k+1) + 1 ≤ orbitExp n k`.
One induction; the base closes against the quantum bound
`weightExpScaled n ≤ -1`, the step pastes the doubled deficit onto the
hypothesis. -/
@[proof] theorem orbitExp_strict_step (n : ZeroMode) :
    ∀ k : Nat, orbitExp n (Nat.succ k) + 1 ≤ orbitExp n k := by
  intro k
  induction k with
  | zero =>
    show 2 * weightExpScaled n + (2 * weightExpScaled n) + 1
      ≤ 2 * weightExpScaled n
    have hw := weightExpScaled_neg n
    have hd := dissipation_ge_one n
    omega
  | succ k ih =>
    have ih' : orbitExp n k + orbitExp n k + 1 ≤ orbitExp n k :=
      show orbitExp n (Nat.succ k) + 1 ≤ orbitExp n k from ih
    show orbitExp n k + orbitExp n k + (orbitExp n k + orbitExp n k) + 1
      ≤ orbitExp n k + orbitExp n k
    omega

/-- Doubling balance of the orbit: the successor exponent is the double of
the current one. -/
@[proof] theorem orbitExp_double (n : ZeroMode) (k : Nat) :
    orbitExp n (Nat.succ k) = orbitExp n k + orbitExp n k := rfl

/-! ## Configuration energy -/

/-- Guarded finite sum of a mode-family, mirroring the carrier-layer
`sumGo` at the integer scale. -/
private def esum (A : ZeroMode → Int) : (m : Nat) → m ≤ numOrdinates → Int
  | 0, _ => 0
  | Nat.succ m, h =>
      esum A m (Nat.le_trans (Nat.le_succ m) h)
        + A ⟨m, Nat.lt_of_lt_of_le (Nat.lt_succ_self m) h⟩

private theorem esum_succ (A : ZeroMode → Int) (m : Nat)
    (h : Nat.succ m ≤ numOrdinates) :
    esum A (Nat.succ m) h
      = esum A m (Nat.le_trans (Nat.le_succ m) h)
        + A ⟨m, Nat.lt_of_lt_of_le (Nat.lt_succ_self m) h⟩ := rfl

/-- Prefix sums are additive at the integer layer. -/
private theorem esum_add (A B : ZeroMode → Int) : ∀ (m : Nat) (h : m ≤ numOrdinates),
    esum A m h + esum B m h = esum (fun i => A i + B i) m h := by
  intro m
  induction m with
  | zero => intro _; rfl
  | succ k ih =>
    intro h
    have hkle : k ≤ numOrdinates := Nat.le_trans (Nat.le_succ k) h
    have hklt : k < numOrdinates := Nat.lt_of_lt_of_le (Nat.lt_succ_self k) h
    show esum A k hkle + A ⟨k, hklt⟩
      + (esum B k hkle + B ⟨k, hklt⟩)
      = esum (fun i => A i + B i) k hkle + (A ⟨k, hklt⟩ + B ⟨k, hklt⟩)
    have hsum := ih hkle
    omega

/-- Pointwise-dominant families have dominant prefix sums. -/
private theorem esum_le {F G : ZeroMode → Int} : ∀ (m : Nat) (h : m ≤ numOrdinates),
    (∀ i, F i ≤ G i) → esum F m h ≤ esum G m h := by
  intro m
  induction m with
  | zero => intro _ _; exact Int.le_refl _
  | succ k ih =>
    intro h hpt
    have hkle : k ≤ numOrdinates := Nat.le_trans (Nat.le_succ k) h
    have hklt : k < numOrdinates := Nat.lt_of_lt_of_le (Nat.lt_succ_self k) h
    exact Int.add_le_add (ih hkle hpt) (hpt ⟨k, hklt⟩)

/-- Total amplitude mass of a configuration. -/
@[adr] def amplitudeMass (A : ZeroMode → Int) : Int :=
  esum A numOrdinates (Nat.le_refl numOrdinates)

/-- Orbit energy of a configuration at squaring depth `k`: the
amplitude-weighted sum of the modes' orbit exponents. -/
@[adr] def orbitEnergy (A : ZeroMode → Int) (k : Nat) : Int :=
  esum (fun n => A n * orbitExp n k) numOrdinates (Nat.le_refl numOrdinates)

/-- **Lyapunov descent**: for every nonnegative amplitude family, one
squaring step strictly decreases the total orbit energy by at least the
configuration's total amplitude mass. -/
@[proof] theorem orbitEnergy_step (A : ZeroMode → Int) (hA : ∀ n, 0 ≤ A n)
    (k : Nat) :
    orbitEnergy A (Nat.succ k) + amplitudeMass A ≤ orbitEnergy A k := by
  have hsplit : orbitEnergy A (Nat.succ k) + amplitudeMass A
      = esum (fun i => A i * orbitExp i (Nat.succ k) + A i)
          numOrdinates (Nat.le_refl numOrdinates) :=
    esum_add (fun n => A n * orbitExp n (Nat.succ k)) A numOrdinates
      (Nat.le_refl numOrdinates)
  rw [hsplit]
  refine esum_le numOrdinates (Nat.le_refl numOrdinates) (fun i => ?_)
  have hstep := orbitExp_strict_step i k
  have hm := Int.mul_le_mul_of_nonneg_left hstep (hA i)
  rw [Int.mul_add, Int.mul_one] at hm
  exact hm

end ComplexKappa.SpectralAttractor
