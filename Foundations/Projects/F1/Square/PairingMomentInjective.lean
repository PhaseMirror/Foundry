/-
F1 square — **completion-level moment INJECTIVITY** (`PairingMomentInjective.lean`), the two-member
generalization of `PairingMomentDeterminacy.lean`.  Where the determinacy brick showed a single
L²-Cauchy limit member with all-vanishing moments pairs to **zero** against every test, this brick
shows the FULL injectivity statement:

  `pairingIU_moment_eq_imp_eq` :  two L²-Cauchy limit members `Φ`, `Ψ` whose extended moments AGREE
  (`pairingIU Φ (xⁱ) hΦ ≈ pairingIU Ψ (xⁱ) hΨ` for every `i`) pair **equally** against **every**
  test `ψ`.  The `L2Elt`-level reading `L2Elt_moment_eq_imp_eq` says two completed members with the
  same moment sequence are `L2Elt`-equal (`E.eq F`).

The moment map is therefore **injective on the completion**: a limit member is determined, as a
pairing functional, by its moment sequence.  The proof mirrors the zero-brick arc with `≈` (equality
between the two members) in place of `≈ 0` throughout:

  • `pairingIU_clampProd_eq` / `pairingIU_bernBasis_eq` — the relative Pascal recursion;
  • `pairingIU_L2sumN_eq` / `pairingIU_bernOpCTest_eq` — the relative Bernstein-operator assembly;
  • `pairingIU_bernResidual_bound` — the (moment-independent) per-member residual bound, re-derived
    here as a PUBLIC helper (it was inline `hstep2`/`hstep3` in the determinacy brick);
  • the main split of `Φ`/`Ψ`-pairings through the common `B_N(ψ)`: the two OUTER differences are the
    per-member residual bounds, the MIDDLE difference vanishes by `pairingIU_bernOpCTest_eq`.

## Honest scope
The moment map is injective on the completion — two limit members with the same moment sequence pair
equally against every test, hence are `L2Elt`-equal.  This is NOT positivity, NOT surjectivity onto
function space.  Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core (no Mathlib), choice-free.  The only ring tactic is `ring_uor` (ℚ/ℤ equalities); all
abstract-`Real` algebra is manual `Req`/`Rle` rearrangement.  Axiom-audited to `{propext, Quot.sound}`
by `scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.PairingMomentDeterminacy
import Foundations.F1.Square.L2ElementSpace

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Private helpers (re-copies of the privates in the imported bricks).
-- ===========================================================================

/-- `natScaleR` respects `Req` (copy of the `PairingBernBasisZero` private). -/
private theorem natScaleR_congr {a b : Real} (hab : Req a b) :
    ∀ c, Req (natScaleR c a) (natScaleR c b)
  | 0 => Req_refl _
  | c + 1 => Radd_congr hab (natScaleR_congr hab c)

/-- `|a − b| ≈ |b − a|` (local copy). -/
private theorem abs_sub_comm (a b : Real) : Req (Rabs (Rsub a b)) (Rabs (Rsub b a)) :=
  Req_trans (Req_symm (Rabs_Rneg (Rsub a b))) (Rabs_congr (Rneg_Rsub a b))

/-- Turn a two-sided `|a − b| ≤ C/(k+1)` bound into `a ≈ b` (local copy). -/
private theorem Req_of_Rabs_sub_le {a b : Real} {C : Nat}
    (hk : ∀ k, Rle (Rabs (Rsub a b)) (ofQ (⟨(C : Int), k + 1⟩ : Q) (Nat.succ_pos k))) :
    Req a b :=
  Req_of_Rle_ofQ_all
    (fun k => Rle_of_Rabs_le (hk k))
    (fun k => Rle_trans (Rle_Rabs_self (Rsub b a))
      (Rle_trans (Rle_of_Req (abs_sub_comm b a)) (hk k)))

/-- **The extended pairing of the zero test vanishes** (re-derived local copy). -/
private theorem pairingIU_zeroL2 (Φ : Nat → L2Test) (h : L2CauchyU Φ) :
    Req (pairingIU Φ zeroL2 h) zero :=
  Rlim_zero _ (pairingIU_RReg h zeroL2)
    (fun _j => Req_trans (innerI_symm _ zeroL2) (innerI_zeroL2 _))

/-- **The key `Qle`, `E ≤ E²`** (copy of the `PairingMomentDeterminacy` private). -/
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

/-- Negation reverses `≤` (copy). -/
private theorem Rneg_le_Rneg {a b : Real} (h : Rle a b) : Rle (Rneg b) (Rneg a) :=
  Rle_of_Rnonneg_Rsub
    (Rnonneg_congr
      (Req_symm (Req_trans (Radd_congr (Req_refl (Rneg a)) (Rneg_Rneg b)) (Radd_comm (Rneg a) b)))
      (Rnonneg_Rsub_of_Rle h))

/-- **A uniform bound on the terms bounds `|·|` of the limit** (copy). -/
private theorem Rabs_Rlim_le {X : Nat → Real} (hX : RReg X) {B : Real}
    (hb : ∀ m, Rle (Rabs (X m)) B) : Rle (Rabs (Rlim X hX)) B := by
  apply Rabs_le_of_both
  · exact Rlim_le_const hX (fun m => Rle_of_Rabs_le (hb m))
  · exact Rle_trans (Rneg_le_Rneg (const_le_Rlim hX (fun m => Rneg_le_of_Rabs_le (hb m))))
      (Rle_of_Req (Rneg_Rneg B))

-- ===========================================================================
-- (A) Relative clamp-product / Bernstein-basis equality.
-- ===========================================================================

/-- **THE CLAMP-PRODUCT FACTORS PAIR EQUALLY** when the two members' extended moments agree: for every
    `k, m`, `pairingIU Φ (clamp01ᵏ·(1−clamp01)ᵐ) hΦ ≈ pairingIU Ψ (…) hΨ`. The relative Pascal
    recursion — the two-member mirror of `pairingIU_clampProd_zero`. -/
theorem pairingIU_clampProd_eq (Φ Ψ : Nat → L2Test) (hΦ : L2CauchyU Φ) (hΨ : L2CauchyU Ψ)
    (hmom : ∀ i, Req (pairingIU Φ (powTest i) hΦ) (pairingIU Ψ (powTest i) hΨ)) :
    ∀ m k, Req (pairingIU Φ (clampProdTest k m) hΦ) (pairingIU Ψ (clampProdTest k m) hΨ)
  | 0, k => by
    have hΦred : Req (pairingIU Φ (clampProdTest k 0) hΦ) (pairingIU Φ (powTest k) hΦ) :=
      pairingIU_unit_congr Φ (clampProdTest k 0) (powTest k) hΦ
        (fun x _ _ => by show Req (Rmul ((powTest k).f x) one) ((powTest k).f x); exact Rmul_one _)
    have hΨred : Req (pairingIU Ψ (clampProdTest k 0) hΨ) (pairingIU Ψ (powTest k) hΨ) :=
      pairingIU_unit_congr Ψ (clampProdTest k 0) (powTest k) hΨ
        (fun x _ _ => by show Req (Rmul ((powTest k).f x) one) ((powTest k).f x); exact Rmul_one _)
    exact Req_trans hΦred (Req_trans (hmom k) (Req_symm hΨred))
  | m + 1, k => by
    have hΦred : Req (pairingIU Φ (clampProdTest k (m + 1)) hΦ)
        (Rsub (pairingIU Φ (clampProdTest k m) hΦ) (pairingIU Φ (clampProdTest (k + 1) m) hΦ)) :=
      Req_trans (pairingIU_unit_congr Φ (clampProdTest k (m + 1))
        (L2Test.sub (clampProdTest k m) (clampProdTest (k + 1) m)) hΦ
        (fun x _ _ => clampProd_step_pt k m x))
        (pairingIU_sub_right Φ (clampProdTest k m) (clampProdTest (k + 1) m) hΦ)
    have hΨred : Req (pairingIU Ψ (clampProdTest k (m + 1)) hΨ)
        (Rsub (pairingIU Ψ (clampProdTest k m) hΨ) (pairingIU Ψ (clampProdTest (k + 1) m) hΨ)) :=
      Req_trans (pairingIU_unit_congr Ψ (clampProdTest k (m + 1))
        (L2Test.sub (clampProdTest k m) (clampProdTest (k + 1) m)) hΨ
        (fun x _ _ => clampProd_step_pt k m x))
        (pairingIU_sub_right Ψ (clampProdTest k m) (clampProdTest (k + 1) m) hΨ)
    exact Req_trans hΦred (Req_trans
      (Rsub_congr (pairingIU_clampProd_eq Φ Ψ hΦ hΨ hmom m k)
                  (pairingIU_clampProd_eq Φ Ψ hΦ hΨ hmom m (k + 1)))
      (Req_symm hΨred))

/-- **THE BERNSTEIN BASIS PAIRS EQUALLY** when the two members' moments agree — through the
    `ℕ`-homogeneity of the extended pairing (`pairingIU_natScale`). Mirror of
    `pairingIU_bernBasis_zero`. -/
theorem pairingIU_bernBasis_eq (Φ Ψ : Nat → L2Test) (hΦ : L2CauchyU Φ) (hΨ : L2CauchyU Ψ)
    (hmom : ∀ i, Req (pairingIU Φ (powTest i) hΦ) (pairingIU Ψ (powTest i) hΨ)) (n k : Nat) :
    Req (pairingIU Φ (bernBasisTest n k) hΦ) (pairingIU Ψ (bernBasisTest n k) hΨ) := by
  show Req (pairingIU Φ (natScale (choose n k) (clampProdTest k (n - k))) hΦ)
           (pairingIU Ψ (natScale (choose n k) (clampProdTest k (n - k))) hΨ)
  refine Req_trans (pairingIU_natScale Φ (choose n k) (clampProdTest k (n - k)) hΦ) ?_
  refine Req_trans
    (natScaleR_congr (pairingIU_clampProd_eq Φ Ψ hΦ hΨ hmom (n - k) k) (choose n k)) ?_
  exact Req_symm (pairingIU_natScale Ψ (choose n k) (clampProdTest k (n - k)) hΨ)

-- ===========================================================================
-- (B) Relative L2sumN + Bernstein-operator equality.
-- ===========================================================================

/-- **A FINITE SUM OF TESTS PAIRS EQUALLY** if every summand does — the two-member mirror of
    `pairingIU_L2sumN_zero`, via right-additivity (`pairingIU_add_right`). -/
theorem pairingIU_L2sumN_eq (Φ Ψ : Nat → L2Test) (hΦ : L2CauchyU Φ) (hΨ : L2CauchyU Ψ)
    (g : Nat → L2Test)
    (heach : ∀ k, Req (pairingIU Φ (g k) hΦ) (pairingIU Ψ (g k) hΨ)) :
    ∀ N, Req (pairingIU Φ (L2sumN g N) hΦ) (pairingIU Ψ (L2sumN g N) hΨ)
  | 0 => by
    exact Req_trans (pairingIU_zeroL2 Φ hΦ) (Req_symm (pairingIU_zeroL2 Ψ hΨ))
  | N + 1 => by
    refine Req_trans (pairingIU_add_right Φ (L2sumN g N) (g N) hΦ) ?_
    refine Req_trans (Radd_congr (pairingIU_L2sumN_eq Φ Ψ hΦ hΨ g heach N) (heach N)) ?_
    exact Req_symm (pairingIU_add_right Ψ (L2sumN g N) (g N) hΨ)

/-- **THE BERNSTEIN OPERATOR TEST PAIRS EQUALLY** when the two members' moments agree, for ANY
    approximated test `χ` — the two-member mirror of `pairingIU_bernOpCTest_zero`: each operator
    summand is a real coefficient times a single basis pairing whose two-member difference already
    vanishes (`pairingIU_constMul` on both members ∘ `pairingIU_clampProd_eq`). -/
theorem pairingIU_bernOpCTest_eq (Φ Ψ : Nat → L2Test) (hΦ : L2CauchyU Φ) (hΨ : L2CauchyU Ψ)
    (hmom : ∀ i, Req (pairingIU Φ (powTest i) hΦ) (pairingIU Ψ (powTest i) hΨ))
    (χ : L2Test) (n : Nat) (hn : 0 < n) :
    Req (pairingIU Φ (bernOpCTest χ n hn) hΦ) (pairingIU Ψ (bernOpCTest χ n hn) hΨ) := by
  exact pairingIU_L2sumN_eq Φ Ψ hΦ hΨ (bernTermCTest χ n hn)
    (fun k =>
      Req_trans
        (pairingIU_constMul Φ (clampProdTest k (n - k)) (bernCoef χ n hn k)
          (Qmul_den_pos χ.hMd Nat.one_pos)
          (Int.mul_nonneg χ.hMn (Int.ofNat_nonneg (choose n k))) (bernCoef_bound χ n hn k) hΦ)
        (Req_trans
          (Rmul_congr (Req_refl (bernCoef χ n hn k))
            (pairingIU_clampProd_eq Φ Ψ hΦ hΨ hmom (n - k) k))
          (Req_symm (pairingIU_constMul Ψ (clampProdTest k (n - k)) (bernCoef χ n hn k)
            (Qmul_den_pos χ.hMd Nat.one_pos)
            (Int.mul_nonneg χ.hMn (Int.ofNat_nonneg (choose n k))) (bernCoef_bound χ n hn k) hΨ))))
    (n + 1)

-- ===========================================================================
-- (C) The per-member residual bound (moment-independent), as a public helper.
-- ===========================================================================

/-- **THE BERNSTEIN RESIDUAL PAIRS SMALL** (re-derivation, as a public helper, of the inline
    `hstep2`/`hstep3` in `pairingIU_moment_zero_imp_zero`): the extended pairing of any member `Φ`
    against the residual `ψ − B_N(ψ)` (`N = (k+1)²`) is bounded by `5·E_Φ·L_ψ / (L_ψ.den·8(k+1))`,
    with `E_Φ = 2·selfBnd(Φ₀)+8`. Per honest read: integral Cauchy–Schwarz + uniform self-energy
    (`innerI_self_le_uniform`) + the L²-density energy bound (`bernOp_L2_converges`), inherited
    through the limit by `Rabs_Rlim_le`. This is moment-INDEPENDENT. -/
theorem pairingIU_bernResidual_bound (Φ : Nat → L2Test) (hΦ : L2CauchyU Φ) (ψ : L2Test) (k : Nat) :
    Rle (Rabs (pairingIU Φ
        (L2Test.sub ψ (bernOpCTest ψ ((k + 1) * (k + 1))
          (Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k)))) hΦ))
        (ofQ (⟨5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num,
              ψ.L.den * (8 * (k + 1))⟩ : Q)
             (Nat.mul_pos ψ.hLd (Nat.mul_pos (by decide) (Nat.succ_pos k)))) := by
  have hRqd : 0 < (⟨5, 8 * (k + 1)⟩ : Q).den := Nat.mul_pos (by decide) (Nat.succ_pos k)
  have hβd : 0 < (mul ψ.L (⟨5, 8 * (k + 1)⟩ : Q)).den := Qmul_den_pos ψ.hLd hRqd
  have hbernBd : 0 <
      (mul (mul ψ.L (⟨5, 8 * (k + 1)⟩ : Q)) (mul ψ.L (⟨5, 8 * (k + 1)⟩ : Q))).den :=
    Qmul_den_pos hβd hβd
  have hDqd : 0 < (⟨5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num,
      ψ.L.den * (8 * (k + 1))⟩ : Q).den := Nat.mul_pos ψ.hLd hRqd
  have hEQn : (0 : Int) ≤ 2 * ((selfBnd (Φ 0) : Nat) : Int) + 8 := by omega
  have hE : (1 : Int) ≤ 2 * ((selfBnd (Φ 0) : Nat) : Int) + 8 := by omega
  have hVnn : (0 : Int) ≤ 5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num :=
    Int.mul_nonneg (Int.mul_nonneg (by decide) hEQn) ψ.hLn
  let χ : L2Test := L2Test.sub ψ
    (bernOpCTest ψ ((k + 1) * (k + 1)) (Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k)))
  have hbern : Rle (innerI χ χ)
      (ofQ (mul (mul ψ.L (⟨5, 8 * (k + 1)⟩ : Q)) (mul ψ.L (⟨5, 8 * (k + 1)⟩ : Q))) hbernBd) :=
    bernOp_L2_converges ψ k
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
      (innerI_self_le_uniform Φ hΦ m)) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ Nat.one_pos hEQn) hbern) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ Nat.one_pos hbernBd)) ?_
    refine Rle_trans (Rle_ofQ_ofQ (Qmul_den_pos Nat.one_pos hbernBd) (Qmul_den_pos hDqd hDqd)
      (energy_bern_Qle (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) ψ.L k hE ψ.hLn)) ?_
    exact Rle_of_Req (Req_symm (Rmul_ofQ_ofQ hDqd hDqd))
  exact Rabs_Rlim_le (pairingIU_RReg hΦ χ) (fun j => hstep2 (selfBnd χ * (j + 1)))

-- ===========================================================================
-- (D) The main injectivity theorems.
-- ===========================================================================

/-- **★ COMPLETION-LEVEL MOMENT INJECTIVITY**: two L²-Cauchy limit members `Φ`, `Ψ` whose extended
    moments `pairingIU · (xⁱ)` AGREE for all `i` pair EQUALLY against every test `ψ`. The moment map
    is injective on the completion. Proof: for each `k`, split
    `pairingIU Φ ψ − pairingIU Ψ ψ` through the common `B_N(ψ)` (`N = (k+1)²`): the middle
    `pairingIU Φ (B_Nψ) − pairingIU Ψ (B_Nψ)` vanishes by `pairingIU_bernOpCTest_eq`, and the two
    outer differences are the per-member residual bounds `pairingIU_bernResidual_bound`, each
    `≤ 5·E/(8·L.den·(k+1))`; summed and dropped to `≤ C/(k+1)`, forcing equality. -/
theorem pairingIU_moment_eq_imp_eq (Φ Ψ : Nat → L2Test) (hΦ : L2CauchyU Φ) (hΨ : L2CauchyU Ψ)
    (hmom : ∀ i, Req (pairingIU Φ (powTest i) hΦ) (pairingIU Ψ (powTest i) hΨ)) (ψ : L2Test) :
    Req (pairingIU Φ ψ hΦ) (pairingIU Ψ ψ hΨ) := by
  refine Req_of_Rabs_sub_le
    (C := 5 * (2 * selfBnd (Φ 0) + 8) * ψ.L.num.toNat
        + 5 * (2 * selfBnd (Ψ 0) + 8) * ψ.L.num.toNat) (fun k => ?_)
  have hn : 0 < (k + 1) * (k + 1) := Nat.mul_pos (Nat.succ_pos k) (Nat.succ_pos k)
  -- Middle difference vanishes: `pairingIU Φ (B_Nψ) ≈ pairingIU Ψ (B_Nψ)`.
  have hbc : Req (pairingIU Φ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΦ)
                 (pairingIU Ψ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΨ) :=
    pairingIU_bernOpCTest_eq Φ Ψ hΦ hΨ hmom ψ ((k + 1) * (k + 1)) hn
  -- Regroup `(a − d) ≈ (a − b) + (c − d)` (folding the vanished middle via `b ≈ c`).
  have hregroup : Req
      (Rsub (pairingIU Φ ψ hΦ) (pairingIU Ψ ψ hΨ))
      (Radd (Rsub (pairingIU Φ ψ hΦ) (pairingIU Φ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΦ))
            (Rsub (pairingIU Ψ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΨ) (pairingIU Ψ ψ hΨ))) :=
    Req_trans
      (Req_symm (Rsub_split (pairingIU Φ ψ hΦ)
        (pairingIU Ψ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΨ) (pairingIU Ψ ψ hΨ)))
      (Radd_congr
        (Rsub_congr (Req_refl (pairingIU Φ ψ hΦ)) (Req_symm hbc))
        (Req_refl (Rsub (pairingIU Ψ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΨ)
                        (pairingIU Ψ ψ hΨ))))
  -- Φ residual: `|a − b| ≤ ofQ Pq_Φ`, then drop the denominator to `⟨A_Φ, k+1⟩`.
  have hab_eq : Req
      (Rsub (pairingIU Φ ψ hΦ) (pairingIU Φ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΦ))
      (pairingIU Φ (L2Test.sub ψ (bernOpCTest ψ ((k + 1) * (k + 1)) hn)) hΦ) :=
    Req_symm (pairingIU_sub_right Φ ψ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΦ)
  have hab_res : Rle
      (Rabs (Rsub (pairingIU Φ ψ hΦ) (pairingIU Φ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΦ)))
      (ofQ (⟨5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num,
            ψ.L.den * (8 * (k + 1))⟩ : Q)
           (Nat.mul_pos ψ.hLd (Nat.mul_pos (by decide) (Nat.succ_pos k)))) :=
    Rle_trans (Rle_of_Req (Rabs_congr hab_eq)) (pairingIU_bernResidual_bound Φ hΦ ψ k)
  have hVnnΦ : (0 : Int) ≤ 5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num :=
    Int.mul_nonneg (Int.mul_nonneg (by decide) (by omega)) ψ.hLn
  have hCeqΦ : ((5 * (2 * selfBnd (Φ 0) + 8) * ψ.L.num.toNat : Nat) : Int)
            = 5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num := by
    have ha : ((ψ.L.num.toNat : Nat) : Int) = ψ.L.num := Int.toNat_of_nonneg ψ.hLn
    push_cast [ha]; rfl
  have hDropΦ : Rle
      (ofQ (⟨5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num,
            ψ.L.den * (8 * (k + 1))⟩ : Q)
           (Nat.mul_pos ψ.hLd (Nat.mul_pos (by decide) (Nat.succ_pos k))))
      (ofQ (⟨((5 * (2 * selfBnd (Φ 0) + 8) * ψ.L.num.toNat : Nat) : Int), k + 1⟩ : Q)
           (Nat.succ_pos k)) := by
    apply Rle_ofQ_ofQ
    show (5 * (2 * ((selfBnd (Φ 0) : Nat) : Int) + 8) * ψ.L.num) * ((k + 1 : Nat) : Int)
        ≤ ((5 * (2 * selfBnd (Φ 0) + 8) * ψ.L.num.toNat : Nat) : Int)
            * ((ψ.L.den * (8 * (k + 1)) : Nat) : Int)
    rw [hCeqΦ]
    refine Int.mul_le_mul_of_nonneg_left ?_ hVnnΦ
    have hnat : (k + 1) ≤ ψ.L.den * (8 * (k + 1)) := by
      rw [← Nat.mul_assoc]
      exact Nat.le_mul_of_pos_left (k + 1) (Nat.mul_pos ψ.hLd (by decide))
    exact_mod_cast hnat
  have hab_drop : Rle
      (Rabs (Rsub (pairingIU Φ ψ hΦ) (pairingIU Φ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΦ)))
      (ofQ (⟨((5 * (2 * selfBnd (Φ 0) + 8) * ψ.L.num.toNat : Nat) : Int), k + 1⟩ : Q)
           (Nat.succ_pos k)) :=
    Rle_trans hab_res hDropΦ
  -- Ψ residual: `|c − d| = |d − c| ≤ ofQ Pq_Ψ`, then drop to `⟨A_Ψ, k+1⟩`.
  have hcd_eq : Req
      (Rsub (pairingIU Ψ ψ hΨ) (pairingIU Ψ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΨ))
      (pairingIU Ψ (L2Test.sub ψ (bernOpCTest ψ ((k + 1) * (k + 1)) hn)) hΨ) :=
    Req_symm (pairingIU_sub_right Ψ ψ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΨ)
  have hcd_res : Rle
      (Rabs (Rsub (pairingIU Ψ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΨ) (pairingIU Ψ ψ hΨ)))
      (ofQ (⟨5 * (2 * ((selfBnd (Ψ 0) : Nat) : Int) + 8) * ψ.L.num,
            ψ.L.den * (8 * (k + 1))⟩ : Q)
           (Nat.mul_pos ψ.hLd (Nat.mul_pos (by decide) (Nat.succ_pos k)))) := by
    refine Rle_trans (Rle_of_Req (abs_sub_comm
      (pairingIU Ψ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΨ) (pairingIU Ψ ψ hΨ))) ?_
    exact Rle_trans (Rle_of_Req (Rabs_congr hcd_eq)) (pairingIU_bernResidual_bound Ψ hΨ ψ k)
  have hVnnΨ : (0 : Int) ≤ 5 * (2 * ((selfBnd (Ψ 0) : Nat) : Int) + 8) * ψ.L.num :=
    Int.mul_nonneg (Int.mul_nonneg (by decide) (by omega)) ψ.hLn
  have hCeqΨ : ((5 * (2 * selfBnd (Ψ 0) + 8) * ψ.L.num.toNat : Nat) : Int)
            = 5 * (2 * ((selfBnd (Ψ 0) : Nat) : Int) + 8) * ψ.L.num := by
    have ha : ((ψ.L.num.toNat : Nat) : Int) = ψ.L.num := Int.toNat_of_nonneg ψ.hLn
    push_cast [ha]; rfl
  have hDropΨ : Rle
      (ofQ (⟨5 * (2 * ((selfBnd (Ψ 0) : Nat) : Int) + 8) * ψ.L.num,
            ψ.L.den * (8 * (k + 1))⟩ : Q)
           (Nat.mul_pos ψ.hLd (Nat.mul_pos (by decide) (Nat.succ_pos k))))
      (ofQ (⟨((5 * (2 * selfBnd (Ψ 0) + 8) * ψ.L.num.toNat : Nat) : Int), k + 1⟩ : Q)
           (Nat.succ_pos k)) := by
    apply Rle_ofQ_ofQ
    show (5 * (2 * ((selfBnd (Ψ 0) : Nat) : Int) + 8) * ψ.L.num) * ((k + 1 : Nat) : Int)
        ≤ ((5 * (2 * selfBnd (Ψ 0) + 8) * ψ.L.num.toNat : Nat) : Int)
            * ((ψ.L.den * (8 * (k + 1)) : Nat) : Int)
    rw [hCeqΨ]
    refine Int.mul_le_mul_of_nonneg_left ?_ hVnnΨ
    have hnat : (k + 1) ≤ ψ.L.den * (8 * (k + 1)) := by
      rw [← Nat.mul_assoc]
      exact Nat.le_mul_of_pos_left (k + 1) (Nat.mul_pos ψ.hLd (by decide))
    exact_mod_cast hnat
  have hcd_drop : Rle
      (Rabs (Rsub (pairingIU Ψ (bernOpCTest ψ ((k + 1) * (k + 1)) hn) hΨ) (pairingIU Ψ ψ hΨ)))
      (ofQ (⟨((5 * (2 * selfBnd (Ψ 0) + 8) * ψ.L.num.toNat : Nat) : Int), k + 1⟩ : Q)
           (Nat.succ_pos k)) :=
    Rle_trans hcd_res hDropΨ
  -- Sum the two residual bounds and collapse the denominators to `⟨C, k+1⟩`.
  have hQC : Qle
      (add (⟨((5 * (2 * selfBnd (Φ 0) + 8) * ψ.L.num.toNat : Nat) : Int), k + 1⟩ : Q)
           (⟨((5 * (2 * selfBnd (Ψ 0) + 8) * ψ.L.num.toNat : Nat) : Int), k + 1⟩ : Q))
      (⟨((5 * (2 * selfBnd (Φ 0) + 8) * ψ.L.num.toNat
          + 5 * (2 * selfBnd (Ψ 0) + 8) * ψ.L.num.toNat : Nat) : Int), k + 1⟩ : Q) :=
    Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)
  refine Rle_trans (Rle_of_Req (Rabs_congr hregroup)) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add hab_drop hcd_drop) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k))) ?_
  exact Rle_ofQ_ofQ (add_den_pos (Nat.succ_pos k) (Nat.succ_pos k)) (Nat.succ_pos k) hQC

/-- **The `L2Elt` reading**: two completed L² members with the SAME moment sequence are `L2Elt`-equal
    (`E.eq F`, i.e. they pair identically against every test). Directly from
    `pairingIU_moment_eq_imp_eq`. -/
theorem L2Elt_moment_eq_imp_eq (E F : L2Elt) (hmom : ∀ i, Req (E.moment i) (F.moment i)) : E.eq F := by
  intro ψ
  exact pairingIU_moment_eq_imp_eq E.seq F.seq E.cauchy F.cauchy hmom ψ

end Multiplicity.UOR.Bridge.F1Square.Square
