/-
F1 square — **the pre-Hilbert layer, brick 62** (`L2Complete.lean`): **THE UNIFORM L²
COMPLETENESS CRITERION** — brick 14 built the extended L² pairing `pairingILim` along a sequence
of tests, but behind a hypothesis that mentions the *second slot*: the product
`d²(Φⱼ,Φₖ)·⟨ψ,ψ⟩` had to be small, so the condition had to be re-verified for every `ψ` and was
never instantiated. This brick removes that:

    `L2CauchyU Φ  :=  ∀ j k,  d²(Φⱼ, Φₖ)  ≤  (1/(j+1) + 1/(k+1))²`

is a condition on the sequence ALONE, and it yields the extended pairing against **every** test
(`pairingIU`), with the effective rate `2/(j+1)`.

The bridge is the same move that carried bricks 40 and 43: an index rescale turns a rate into a
Bishop modulus. Each test carries a *rational* bound on its own energy, `⟨ψ,ψ⟩ ≤ S` for the
natural number `S = selfBnd ψ` read off brick 10's uniform pairing bound; reading `Φ` along
`j ↦ S·(j+1)` divides the modulus by `S`, hence divides the squared modulus by `S²`, and one
factor of `S` is exactly what the energy costs. So the condition on `Φ` never mentions `ψ`, and
the rescale absorbs it. Concretely `1/(S(j+1)+1) ≤ 1/(S(j+1))` and
`1/(S(j+1)) + 1/(S(k+1)) = (1/S)·(1/(j+1) + 1/(k+1))` **exactly**, so the estimate is a rational
identity plus `S ≤ S²`, not an approximation.

The payoff is structural: **the co-support levels are closed under L² limits of functions**
(`pairingIU_zero_of_moments`, `pairingIU_cosupport_closed`). Bricks 48 and 57 closed the
co-support under the test algebra and under completion of *coefficient vectors*; this closes it
under limits in the function space itself — the topology the genuine Sonine condition lives in.

HONEST SCOPE. This constructs the extended pairing VALUES `lim_j ⟨Φⱼ, ψ⟩` on the completion, not
a limit *function*: there is no completed L² space of functions here, no limit member, and no
inversion. Nothing touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.PairingLimitI

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Each test carries a natural-number bound on its own energy.
-- ===========================================================================

/-- The rational bound on `⟨ψ,ψ⟩` supplied by brick 10's uniform pairing bound. -/
def selfQ (ψ : L2Test) : Q :=
  add (mul ψ.M ψ.M) (⟨(((l2L ψ ψ).num.toNat + 2 : Nat) : Int), 1⟩ : Q)

theorem selfQ_den (ψ : L2Test) : 0 < (selfQ ψ).den :=
  add_den_pos (Qmul_den_pos ψ.hMd ψ.hMd) Nat.one_pos

/-- **The rescale factor**: a natural number, at least `1`, bounding the test's own energy. -/
def selfBnd (ψ : L2Test) : Nat := (selfQ ψ).num.natAbs + 1

theorem selfBnd_pos (ψ : L2Test) : 1 ≤ selfBnd ψ := Nat.le_add_left 1 _

theorem selfQ_le (ψ : L2Test) : Qle (selfQ ψ) (⟨((selfBnd ψ : Nat) : Int), 1⟩ : Q) := by
  show (selfQ ψ).num * ((1 : Nat) : Int)
      ≤ ((selfBnd ψ : Nat) : Int) * (((selfQ ψ).den : Nat) : Int)
  have hS : ((selfBnd ψ : Nat) : Int) = (((selfQ ψ).num.natAbs : Nat) : Int) + 1 := by
    show (((selfQ ψ).num.natAbs + 1 : Nat) : Int) = _
    push_cast
    ring_uor
  rw [hS]
  have hd : (1 : Int) ≤ (((selfQ ψ).den : Nat) : Int) := by
    have := selfQ_den ψ; omega
  have hb : (0 : Int) ≤ (((selfQ ψ).num.natAbs : Nat) : Int) := Int.ofNat_nonneg _
  have hab : (selfQ ψ).num ≤ (((selfQ ψ).num.natAbs : Nat) : Int) := Int.le_natAbs
  have hmul : (((selfQ ψ).num.natAbs : Nat) : Int) * 1
      ≤ (((selfQ ψ).num.natAbs : Nat) : Int) * (((selfQ ψ).den : Nat) : Int) :=
    Int.mul_le_mul_of_nonneg_left hd hb
  have e : ((((selfQ ψ).num.natAbs : Nat) : Int) + 1) * (((selfQ ψ).den : Nat) : Int)
      = (((selfQ ψ).num.natAbs : Nat) : Int) * (((selfQ ψ).den : Nat) : Int)
        + (((selfQ ψ).den : Nat) : Int) := by ring_uor
  rw [e]
  omega

/-- **THE ENERGY IS BOUNDED BY A NATURAL NUMBER**: `⟨ψ,ψ⟩ ≤ selfBnd ψ`. -/
theorem innerI_self_le_selfBnd (ψ : L2Test) :
    Rle (innerI ψ ψ) (ofQ (⟨((selfBnd ψ : Nat) : Int), 1⟩ : Q) Nat.one_pos) :=
  Rle_trans (Rle_of_Rabs_le (innerI_abs_le ψ ψ))
    (Rle_ofQ_ofQ (selfQ_den ψ) Nat.one_pos (selfQ_le ψ))

-- ===========================================================================
-- The rational core of the rescale.
-- ===========================================================================

/-- The half-step: dropping the `+1` in the rescaled denominator. -/
private theorem inv_succ_le (S j : Nat) :
    Qle (⟨1, S * (j + 1) + 1⟩ : Q) (⟨1, S * (j + 1)⟩ : Q) := by
  show (1 : Int) * ((S * (j + 1) : Nat) : Int) ≤ 1 * ((S * (j + 1) + 1 : Nat) : Int)
  push_cast
  omega

/-- The exact identity: the rescaled modulus IS `1/S` times the original. -/
private theorem inv_scale_eq (S j k : Nat) :
    Qeq (add (⟨1, S * (j + 1)⟩ : Q) (⟨1, S * (k + 1)⟩ : Q))
      (mul (⟨1, S⟩ : Q) (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))) := by
  simp only [Qeq, add, mul]
  push_cast
  ring_uor

/-- Squares are non-negative in `Int` (the `natAbs` route; `Int.mul_self_nonneg` is absent). -/
private theorem int_sq_nonneg (a : Int) : 0 ≤ a * a := by
  rw [← Int.natAbs_mul_self']
  exact Int.mul_nonneg (Int.ofNat_nonneg _) (Int.ofNat_nonneg _)

/-- Squaring a `1/S`-scaled modulus and paying one factor of `S` back stays below the original.
    Written as an exact rational identity — the left side simply *is* `(E·E)·(1/S)` — so all that
    remains is `1/S ≤ 1`. -/
private theorem scale_sq_pay (E : Q) (hEd : 0 < E.den) (S : Nat) (hS : 1 ≤ S) :
    Qle (mul (mul (mul (⟨1, S⟩ : Q) E) (mul (⟨1, S⟩ : Q) E)) (⟨((S : Nat) : Int), 1⟩ : Q))
      (mul E E) := by
  have hSd : 0 < S := Nat.lt_of_lt_of_le Nat.one_pos hS
  have heq : Qeq (mul (mul E E) (⟨1, S⟩ : Q))
      (mul (mul (mul (⟨1, S⟩ : Q) E) (mul (⟨1, S⟩ : Q) E)) (⟨((S : Nat) : Int), 1⟩ : Q)) := by
    simp only [Qeq, mul]
    push_cast
    ring_uor
  refine Qle_congr_left (a := mul (mul E E) (⟨1, S⟩ : Q))
    (Qmul_den_pos (Qmul_den_pos hEd hEd) hSd) heq ?_
  have h1S : Qle (⟨1, S⟩ : Q) (⟨1, 1⟩ : Q) := by
    show (1 : Int) * ((1 : Nat) : Int) ≤ (1 : Int) * ((S : Nat) : Int)
    omega
  have hstep : Qle (mul (mul E E) (⟨1, S⟩ : Q)) (mul (mul E E) (⟨1, 1⟩ : Q)) :=
    Qmul_le_mul_left (int_sq_nonneg E.num) h1S
  refine Qle_trans (Qmul_den_pos (Qmul_den_pos hEd hEd) Nat.one_pos) hstep (Qeq_le ?_)
  simp only [Qeq, mul]
  push_cast
  ring_uor

/-- The numerator of the canonical modulus is non-negative. -/
private theorem modQ_num (j k : Nat) :
    0 ≤ (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)).num :=
  Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide)

/-- **THE RESCALE INEQUALITY**: the rescaled squared modulus, times the energy bound `S`, is
    below the plain squared modulus. -/
private theorem rescale_Q (S j k : Nat) (hS : 1 ≤ S) :
    Qle (mul (mul (add (⟨1, S * (j + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))
                  (add (⟨1, S * (j + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)))
             (⟨((S : Nat) : Int), 1⟩ : Q))
      (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
           (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))) := by
  have hSj : 0 < S * (j + 1) := Nat.mul_pos hS (Nat.succ_pos j)
  have hSk : 0 < S * (k + 1) := Nat.mul_pos hS (Nat.succ_pos k)
  have hFd : 0 < (add (⟨1, S * (j + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)).den :=
    add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)
  have hFn : 0 ≤ (add (⟨1, S * (j + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)).num :=
    Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide)
  have hGd : 0 < (mul (⟨1, S⟩ : Q) (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))).den :=
    Qmul_den_pos (Nat.lt_of_lt_of_le Nat.one_pos hS)
      (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
  -- F ≤ (1/S)·E
  have hFG : Qle (add (⟨1, S * (j + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))
      (mul (⟨1, S⟩ : Q) (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))) :=
    Qle_trans (add_den_pos hSj hSk)
      (Qadd_le_add (inv_succ_le S j) (inv_succ_le S k))
      (Qeq_le (inv_scale_eq S j k))
  -- square both sides, then pay the factor S
  have hsq := Qmul_le_mul hFd hGd hFd hFn hFn hFG hFG
  refine Qle_trans (Qmul_den_pos (Qmul_den_pos hGd hGd) Nat.one_pos)
    (Qmul_le_mul_right (by show (0 : Int) ≤ ((S : Nat) : Int); exact Int.ofNat_nonneg _) hsq) ?_
  exact scale_sq_pay (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
    (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k)) S hS

-- ===========================================================================
-- The uniform criterion and the extended pairing.
-- ===========================================================================

/-- **THE UNIFORM (ψ-FREE) SQUARED-CAUCHY CONDITION** on a sequence of tests:
    `d²(Φⱼ, Φₖ) ≤ (1/(j+1) + 1/(k+1))²`. -/
def L2CauchyU (Φ : Nat → L2Test) : Prop :=
  ∀ j k : Nat, Rle (dist2I (Φ j) (Φ k))
    (ofQ (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
              (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
      (Qmul_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
                    (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))))

/-- **THE RESCALE ABSORBS THE SECOND SLOT**: reading a uniformly-Cauchy sequence along
    `j ↦ selfBnd ψ · (j+1)` produces exactly brick 14's `ψ`-dependent hypothesis. -/
theorem dist2I_scaled_le {Φ : Nat → L2Test} (h : L2CauchyU Φ) (ψ : L2Test) (j k : Nat) :
    Rle (Rmul (dist2I (Φ (selfBnd ψ * (j + 1))) (Φ (selfBnd ψ * (k + 1)))) (innerI ψ ψ))
      (ofQ (mul (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
                (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
        (Qmul_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
                      (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k)))) := by
  refine Rle_trans (Rmul_le_Rmul_both
    (dist2I_nonneg (Φ (selfBnd ψ * (j + 1))) (Φ (selfBnd ψ * (k + 1))))
    (Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg _))
    (h (selfBnd ψ * (j + 1)) (selfBnd ψ * (k + 1)))
    (innerI_self_le_selfBnd ψ)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ
    (Qmul_den_pos (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
                  (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))) Nat.one_pos)) ?_
  exact Rle_ofQ_ofQ _ _ (rescale_Q (selfBnd ψ) j k (selfBnd_pos ψ))

/-- The rescaled pairings are regular, for EVERY second slot. -/
theorem pairingIU_RReg {Φ : Nat → L2Test} (h : L2CauchyU Φ) (ψ : L2Test) :
    RReg (fun j => innerI (Φ (selfBnd ψ * (j + 1))) ψ) :=
  pairingI_RReg (Φ := fun j => Φ (selfBnd ψ * (j + 1))) (ψ := ψ) (dist2I_scaled_le h ψ)

/-- **THE EXTENDED L² PAIRING, UNIFORMLY**: for a uniformly squared-Cauchy sequence of tests the
    limit `lim_j ⟨Φⱼ, ψ⟩` exists against **every** test `ψ`. -/
def pairingIU (Φ : Nat → L2Test) (ψ : L2Test) (h : L2CauchyU Φ) : Real :=
  Rlim (fun j => innerI (Φ (selfBnd ψ * (j + 1))) ψ) (pairingIU_RReg h ψ)

/-- The effective rate: the rescaled reads converge at `2/(j+1)`. -/
theorem pairingIU_dist (Φ : Nat → L2Test) (ψ : L2Test) (h : L2CauchyU Φ) (j : Nat) :
    Rle (Rabs (Rsub (innerI (Φ (selfBnd ψ * (j + 1))) ψ) (pairingIU Φ ψ h)))
      (ofQ (⟨2, j + 1⟩ : Q) (Nat.succ_pos j)) :=
  Rabs_dist_Rlim (pairingIU_RReg h ψ) j

-- ===========================================================================
-- Non-vacuity: the constant sequences, and what the limit gives back.
-- ===========================================================================

/-- The L² squared distance of a test to itself vanishes. -/
theorem dist2I_self (φ : L2Test) : Req (dist2I φ φ) zero :=
  Req_trans (innerI_sub_left φ φ (L2Test.sub φ φ)) (Radd_neg (innerI φ (L2Test.sub φ φ)))

/-- **THE CRITERION IS NOT VACUOUS**: constant sequences satisfy it. -/
theorem L2CauchyU_const (φ : L2Test) : L2CauchyU (fun _ => φ) := by
  intro j k
  refine Rle_trans (Rle_of_Req (dist2I_self φ)) ?_
  refine Rle_zero_of_Rnonneg (Rnonneg_ofQ _ ?_)
  show (0 : Int) ≤ (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)).num
      * (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)).num
  exact Int.mul_nonneg (modQ_num j k) (modQ_num j k)

/-- **THE EXTENSION IS FAITHFUL**: on a constant sequence the extended pairing is the pairing. -/
theorem pairingIU_const (φ ψ : L2Test) :
    Req (pairingIU (fun _ => φ) ψ (L2CauchyU_const φ)) (innerI φ ψ) :=
  Rle_antisymm
    (Rlim_le_const (pairingIU_RReg (L2CauchyU_const φ) ψ) (fun _ => Rle_refl _))
    (const_le_Rlim (pairingIU_RReg (L2CauchyU_const φ) ψ) (fun _ => Rle_refl _))

-- ===========================================================================
-- The payoff: co-support is closed under L² limits of functions.
-- ===========================================================================

/-- **A VANISHING MOMENT SURVIVES THE L² LIMIT**: if every member of a uniformly squared-Cauchy
    sequence has vanishing `n`-th moment, the extended pairing against `xⁿ` vanishes. -/
theorem pairingIU_zero_of_moments (Φ : Nat → L2Test) (h : L2CauchyU Φ) (n : Nat)
    (hz : ∀ j : Nat, Req (mellinMoment (Φ j) n) zero) :
    Req (pairingIU Φ (powTest n) h) zero :=
  Rlim_zero _ (pairingIU_RReg h (powTest n)) (fun j => hz (selfBnd (powTest n) * (j + 1)))

/-- **THE CO-SUPPORT LEVELS ARE CLOSED UNDER L² LIMITS OF FUNCTIONS** — the topology the genuine
    Sonine condition lives in, as opposed to bricks 48/57's algebraic and coefficient-vector
    closures. -/
theorem pairingIU_cosupport_closed (Φ : Nat → L2Test) (h : L2CauchyU Φ) (K : Nat)
    (hz : ∀ j : Nat, ∀ n : Nat, n < K → Req (mellinMoment (Φ j) n) zero) :
    ∀ n : Nat, n < K → Req (pairingIU Φ (powTest n) h) zero :=
  fun n hn => pairingIU_zero_of_moments Φ h n (fun j => hz j n hn)

end Multiplicity.UOR.Bridge.F1Square.Square
