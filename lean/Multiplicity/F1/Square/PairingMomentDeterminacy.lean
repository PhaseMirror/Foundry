/-
F1 square — **completion-level moment determinacy** (`PairingMomentDeterminacy.lean`), the
culmination of the extended-pairing / L²-completion arc. Final theorem:

  `pairingIU_moment_zero_imp_zero` :  an L²-Cauchy sequence `Φ` (a *limit member* of the completed
  L² space) whose extended moments `pairingIU Φ (xⁱ) h` **all** vanish pairs to **zero** against
  **every** test `ψ`:  `pairingIU Φ ψ h ≈ 0`.

Equivalently: the moment map is **injective on the completion** — a limit member is determined (as a
pairing functional) by its moment sequence.  The `L2Elt`-level corollary
`L2Elt_moment_zero_imp_eq_zero` reads this as `E.eq (L2Elt.of zeroL2)` for any moment-null member `E`.

## Proof (sqrt-free)
Fix `ψ`.  For each `k`, put `N := (k+1)²`, `χ := ψ − B_N(ψ)` the Bernstein residual.  Three ingredients:

  (1) `pairingIU Φ ψ h ≈ pairingIU Φ χ h`, because the extended pairing of the operator test
      `B_N(ψ)` vanishes under the moment hypothesis (`pairingIU_bernOpCTest_zero`);

  (2) every honest read is small: by the integral Cauchy–Schwarz, the uniform self-energy bound
      `⟨Φₘ,Φₘ⟩ ≤ E := 2·selfBnd(Φ₀)+8`, and the L²-density energy bound `⟨χ,χ⟩ ≤ (5·L_ψ/(8(k+1)))²`,
      one gets `|⟨Φₘ,χ⟩| ≤ 5·E·L_ψ.num / (8·L_ψ.den·(k+1))` for **every** `m` (the key `Qle` is
      `E ≤ E²`, valid since `E ≥ 1`);

  (3) the limit `pairingIU Φ χ h` inherits that bound (`Rabs_Rlim_le`), which after a denominator
      drop is `≤ 5·E·L_ψ.num / (k+1)`.  A linear-in-`1/(k+1)` bound forces `pairingIU Φ ψ h ≈ 0`.

## Honest scope
The moment map is injective on the completion: a limit member with all extended moments zero pairs to
zero against every test — completion-level moment determinacy, the reachable core of "reconstruction of
an arbitrary L² element".  This is NOT positivity, NOT surjectivity onto function space.  Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core (no Mathlib), choice-free.  The only ring tactic is `ring_uor` (ℚ/ℤ equalities); all
abstract-`Real` algebra is manual `Req`/`Rle` rearrangement.  Axiom-audited to `{propext, Quot.sound}`
by `scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.PairingBernOpZero
import Multiplicity.F1Square.Square.PairingIUEnergy
import Multiplicity.F1Square.Square.BernsteinL2Density
import Multiplicity.F1Square.Square.IntegralCSFull
import Multiplicity.F1Square.Square.L2ElementSpace

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Two rational helpers (the whole nonlinear content, isolated).
-- ===========================================================================

/-- **The key `Qle`, `E ≤ E²`**: for `E ≥ 1` and `L.num ≥ 0`,
    `E · (L · 5/(8(k+1)))² ≤ (5·E·L.num / (L.den·8(k+1)))²`.  Both sides share the denominator
    square; on the numerators it is `25·E·L.num² ≤ 25·E²·L.num²`, i.e. `E ≤ E²` (`E ≥ 1`), discharged
    by the sub-nonneg factoring `25·L.num²·E·(E−1) ≥ 0`. -/
private theorem energy_bern_Qle (E : Int) (L : Q) (k : Nat) (hE : 1 ≤ E) (hLn : 0 ≤ L.num) :
    Qle (mul (⟨E, 1⟩ : Q)
             (mul (mul L (⟨5, 8 * (k + 1)⟩ : Q)) (mul L (⟨5, 8 * (k + 1)⟩ : Q))))
        (mul (⟨5 * E * L.num, L.den * (8 * (k + 1))⟩ : Q)
             (⟨5 * E * L.num, L.den * (8 * (k + 1))⟩ : Q)) := by
  simp only [Qle, mul, Nat.one_mul]
  refine Int.mul_le_mul_of_nonneg_right ?_ (Int.ofNat_nonneg _)
  apply Int.le_of_sub_nonneg
  have hid : (5 * E * L.num) * (5 * E * L.num) - E * ((L.num * 5) * (L.num * 5))
           = 25 * (L.num * L.num) * (E * (E - 1)) := by ring_uor
  rw [hid]
  exact Int.mul_nonneg (Int.mul_nonneg (by decide) (Int.mul_nonneg hLn hLn))
    (Int.mul_nonneg (by omega) (by omega))

-- ===========================================================================
-- Three small `Real` helpers.
-- ===========================================================================

/-- Negation reverses `≤`: `a ≤ b ⟹ −b ≤ −a`. -/
private theorem Rneg_le_Rneg {a b : Real} (h : Rle a b) : Rle (Rneg b) (Rneg a) :=
  Rle_of_Rnonneg_Rsub
    (Rnonneg_congr
      (Req_symm (Req_trans (Radd_congr (Req_refl (Rneg a)) (Rneg_Rneg b)) (Radd_comm (Rneg a) b)))
      (Rnonneg_Rsub_of_Rle h))

/-- **A uniform bound on the terms bounds `|·|` of the limit**: `(∀m, |X m| ≤ B) ⟹ |lim X| ≤ B`. -/
private theorem Rabs_Rlim_le {X : Nat → Real} (hX : RReg X) {B : Real}
    (hb : ∀ m, Rle (Rabs (X m)) B) : Rle (Rabs (Rlim X hX)) B := by
  apply Rabs_le_of_both
  · exact Rlim_le_const hX (fun m => Rle_of_Rabs_le (hb m))
  · exact Rle_trans (Rneg_le_Rneg (const_le_Rlim hX (fun m => Rneg_le_of_Rabs_le (hb m))))
      (Rle_of_Req (Rneg_Rneg B))

/-- **A linear-in-`1/(k+1)` bound forces `≈ 0`**: `(∀k, |X| ≤ C/(k+1)) ⟹ X ≈ 0`. -/
private theorem Req_of_Rabs_le_lin {X : Real} {C : Nat}
    (hk : ∀ k, Rle (Rabs X) (ofQ (⟨(C : Int), k + 1⟩ : Q) (Nat.succ_pos k))) : Req X zero := by
  apply Req_of_Rle_ofQ_all (C := C)
  · intro k
    exact Rle_trans (Rle_of_Req (Rsub_zero X)) (Rle_trans (Rle_Rabs_self X) (hk k))
  · intro k
    refine Rle_trans (Rle_of_Req (Req_trans (Radd_comm zero (Rneg X)) (Radd_zero (Rneg X)))) ?_
    exact Rle_trans (Rle_Rabs_self (Rneg X)) (Rle_trans (Rle_of_Req (Rabs_Rneg X)) (hk k))

-- ===========================================================================
-- The main theorem.
-- ===========================================================================

/-- **★ COMPLETION-LEVEL MOMENT DETERMINACY**: an L²-Cauchy limit member `Φ` whose extended moments
    `pairingIU Φ (xⁱ) h` **all** vanish pairs to zero against **every** test `ψ`. The moment map is
    injective on the completion. -/
theorem pairingIU_moment_zero_imp_zero (Φ : Nat → L2Test) (h : L2CauchyU Φ)
    (hmom : ∀ i, Req (pairingIU Φ (powTest i) h) zero) (ψ : L2Test) :
    Req (pairingIU Φ ψ h) zero := by
  apply Req_of_Rabs_le_lin (C := 5 * (2 * selfBnd (Φ 0) + 8) * ψ.L.num.toNat)
  intro k
  -- Denominator-positivity bookkeeping.
  have hRqd : 0 < (⟨5, 8 * (k + 1)⟩ : Q).den := Nat.mul_pos (by decide) (Nat.succ_pos k)
  have hβd : 0 < (mul ψ.L (⟨5, 8 * (k + 1)⟩ : Q)).den := Qmul_den_pos ψ.hLd hRqd
  have hbernBd : 0 <
      (mul (mul ψ.L (⟨5, 8 * (k + 1)⟩ : Q)) (mul ψ.L (⟨5, 8 * (k + 1)⟩ : Q))).den :=
    Qmul_den_pos hβd hβd
  have hDqd : 0 < (⟨5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num,
      ψ.L.den * (8 * (k + 1))⟩ : Q).den := Nat.mul_pos ψ.hLd hRqd
  -- Numeric side conditions on `E = 2·selfBnd(Φ₀)+8`.
  have hEQn : (0 : Int) ≤ 2 * ((selfBnd (Φ 0) : Nat) : Int) + 8 := by omega
  have hE : (1 : Int) ≤ 2 * ((selfBnd (Φ 0) : Nat) : Int) + 8 := by omega
  have hVnn : (0 : Int) ≤ 5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num :=
    Int.mul_nonneg (Int.mul_nonneg (by decide) hEQn) ψ.hLn
  have hCeq : ((5 * (2 * selfBnd (Φ 0) + 8) * ψ.L.num.toNat : Nat) : Int)
            = 5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num := by
    have ha : ((ψ.L.num.toNat : Nat) : Int) = ψ.L.num := Int.toNat_of_nonneg ψ.hLn
    push_cast [ha]; rfl
  -- The Bernstein residual `χ = ψ − B_N(ψ)`, `N = (k+1)²`.
  let χ : L2Test := L2Test.sub ψ
    (bernOpCTest ψ ((k + 1) * (k + 1)) (Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k)))
  -- The L²-density energy bound reads `⟨χ,χ⟩ ≤ (5·L_ψ/(8(k+1)))²`.
  have hbern : Rle (innerI χ χ)
      (ofQ (mul (mul ψ.L (⟨5, 8 * (k + 1)⟩ : Q)) (mul ψ.L (⟨5, 8 * (k + 1)⟩ : Q))) hbernBd) :=
    bernOp_L2_converges ψ k
  -- (1) `pairingIU Φ ψ h ≈ pairingIU Φ χ h`.
  have hzeroB : Req (pairingIU Φ
      (bernOpCTest ψ ((k + 1) * (k + 1)) (Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k))) h) zero :=
    pairingIU_bernOpCTest_zero Φ h hmom ψ ((k + 1) * (k + 1))
      (Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k))
  have hchi : Req (pairingIU Φ χ h) (pairingIU Φ ψ h) := by
    refine Req_trans (pairingIU_sub_right Φ ψ
      (bernOpCTest ψ ((k + 1) * (k + 1)) (Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k))) h) ?_
    exact Req_trans (Rsub_congr (Req_refl (pairingIU Φ ψ h)) hzeroB) (Rsub_zero (pairingIU Φ ψ h))
  have hstep1 : Req (Rabs (pairingIU Φ ψ h)) (Rabs (pairingIU Φ χ h)) :=
    Rabs_congr (Req_symm hchi)
  -- (2) Every honest read is bounded by `ofQ Dq`.
  have hstep2 : ∀ m, Rle (Rabs (innerI (Φ m) χ))
      (ofQ (⟨5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num,
        ψ.L.den * (8 * (k + 1))⟩ : Q) hDqd) := by
    intro m
    have hAbsSq : Req (Rmul (Rabs (innerI (Φ m) χ)) (Rabs (innerI (Φ m) χ)))
        (Rmul (innerI (Φ m) χ) (innerI (Φ m) χ)) :=
      Req_trans (Req_symm (Rabs_Rmul (innerI (Φ m) χ) (innerI (Φ m) χ)))
        (Rabs_of_nonneg (Rnonneg_Rmul_self (innerI (Φ m) χ)))
    refine Rle_of_Rsq_le (Rnonneg_Rabs _) (Rnonneg_ofQ hDqd hVnn) ?_
    refine Rle_trans (Rle_of_Req hAbsSq) ?_
    refine Rle_trans (innerI_cauchy_schwarz (Φ m) χ) ?_
    refine Rle_trans (Rmul_le_Rmul_right (innerI_self_nonneg χ)
      (innerI_self_le_uniform Φ h m)) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ Nat.one_pos hEQn) hbern) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ Nat.one_pos hbernBd)) ?_
    refine Rle_trans (Rle_ofQ_ofQ (Qmul_den_pos Nat.one_pos hbernBd) (Qmul_den_pos hDqd hDqd)
      (energy_bern_Qle (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) ψ.L k hE ψ.hLn)) ?_
    exact Rle_of_Req (Req_symm (Rmul_ofQ_ofQ hDqd hDqd))
  -- (3) The limit inherits the bound, then the denominator drop.
  have hstep3 : Rle (Rabs (pairingIU Φ χ h))
      (ofQ (⟨5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num,
        ψ.L.den * (8 * (k + 1))⟩ : Q) hDqd) :=
    Rabs_Rlim_le (pairingIU_RReg h χ) (fun j => hstep2 (selfBnd χ * (j + 1)))
  have hDrop : Rle
      (ofQ (⟨5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num,
        ψ.L.den * (8 * (k + 1))⟩ : Q) hDqd)
      (ofQ (⟨((5 * (2 * selfBnd (Φ 0) + 8) * ψ.L.num.toNat : Nat) : Int), k + 1⟩ : Q)
        (Nat.succ_pos k)) := by
    apply Rle_ofQ_ofQ
    show (5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num) * ((k + 1 : Nat) : Int)
        ≤ ((5 * (2 * selfBnd (Φ 0) + 8) * ψ.L.num.toNat : Nat) : Int)
            * ((ψ.L.den * (8 * (k + 1)) : Nat) : Int)
    rw [hCeq]
    refine Int.mul_le_mul_of_nonneg_left ?_ hVnn
    have hnat : (k + 1) ≤ ψ.L.den * (8 * (k + 1)) := by
      rw [← Nat.mul_assoc]
      exact Nat.le_mul_of_pos_left (k + 1) (Nat.mul_pos ψ.hLd (by decide))
    exact_mod_cast hnat
  -- Assemble.
  exact Rle_trans (Rle_of_Req hstep1) (Rle_trans hstep3 hDrop)

/-- **The `L2Elt` reading**: a completed L² member `E` all of whose moments vanish is equivalent (as a
    pairing functional) to the embedded zero test — `E.eq (L2Elt.of zeroL2)`. Directly from
    `pairingIU_moment_zero_imp_zero` (`E.pairing ψ ≈ 0`) and `(L2Elt.of zeroL2).pairing ψ ≈ 0`. -/
theorem L2Elt_moment_zero_imp_eq_zero (E : L2Elt) (hmom : ∀ i, Req (E.moment i) zero) :
    E.eq (L2Elt.of zeroL2) := by
  intro ψ
  refine Req_trans (pairingIU_moment_zero_imp_zero E.seq E.cauchy hmom ψ) ?_
  exact Req_symm (Req_trans (L2Elt_of_pairing zeroL2 ψ) (innerI_zeroL2 ψ))

end Multiplicity.UOR.Bridge.F1Square.Square
