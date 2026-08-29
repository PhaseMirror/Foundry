/-
F1 square — **reconstruction of an ARBITRARY L² element** (`DurrmeyerReconstruct.lean`), closing the
last completion-level open of the step-3 Hilbert layer.

`L2Complete`/`L2ElementSpace` built the completed L² space of limit members (`L2Elt`) and its extended
pairing/moment map, and `PairingMomentInjective` proved the moment map INJECTIVE on the completion —
but reconstruction was available only for EMBEDDED tests (`durrOpMom` converges on the constant
sequence). This brick reconstructs an **arbitrary** (non-embedded) limit member as the L²-limit of the
**Bernstein–Durrmeyer polynomials of its own approximants**:

    `L2Elt.recon E`  :=  the limit member of  `m ↦ durrTest (E.seq (recA E m)) …`,

a genuine `L2Elt` (its defining sequence is L²-Cauchy, `reconSeq_cauchy`), and it is equal to `E` as a
pairing functional:

    `L2Elt_recon_eq :  (L2Elt.recon E).eq E`   (i.e. `∀ ψ, ⟨recon E, ψ⟩ ≈ ⟨E, ψ⟩`).

The route is: (A) generalize the reschedule rate to an arbitrary read schedule
(`pairingIU_reschedule_rate_gen`); (B) build `reconSeq` from the Durrmeyer image of `E`'s approximants,
prove its two per-index residual bounds (`durrTest_L2_converges` + `E.cauchy`) and, via a 2-term L²
triangle (`dist2I_triangle2`), its L²-Cauchyness; (C) show the reconstruction preserves every moment
(`L2Elt_recon_moment`) and close with the FREE completion-level injectivity
(`L2Elt_moment_eq_imp_eq`).

HONEST SCOPE. Reconstruction of an arbitrary L² element as the L²-limit of Bernstein–Durrmeyer
polynomials of its approximants, at the pairing-functional level (`.eq`). This is NOT positivity, NOT
surjectivity onto function space, NOT a pointwise limit function. Step 4 (band-coupling positivity) is
RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.DurrmeyerTest
import Foundations.F1.Square.PairingMomentInjective
import Foundations.F1.Square.PairingUnitCongr

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Local algebra helpers (private copies of imported privates).
-- ===========================================================================

/-- `|z|² ≈ z²` (local copy of `PairingIUReschedule.abs_sq_loc`). -/
private theorem abs_sq_loc (z : Real) : Req (Rmul (Rabs z) (Rabs z)) (Rmul z z) :=
  Req_trans (Req_symm (Rabs_Rmul z z)) (Rabs_of_nonneg (Rnonneg_Rmul_self z))

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

/-- Second-slot negation (local copy of `PairingIUReschedule.innerI_neg_right`). -/
private theorem innerI_neg_right (φ ψ : L2Test) :
    Req (innerI φ (L2Test.neg ψ)) (Rneg (innerI φ ψ)) :=
  Req_trans (innerI_symm φ (L2Test.neg ψ))
    (Req_trans (innerI_neg_left ψ φ) (Rneg_congr (innerI_symm ψ φ)))

/-- **Same-denominator `ofQ` addition**: `a/D + b/D ≈ (a+b)/D`. -/
private theorem add2_ofQ {a b : Int} {D : Nat} (hD : 0 < D) :
    Req (Radd (ofQ (⟨a, D⟩ : Q) hD) (ofQ (⟨b, D⟩ : Q) hD)) (ofQ (⟨a + b, D⟩ : Q) hD) := by
  refine Req_trans (Radd_ofQ_ofQ hD hD) ?_
  refine ofQ_congr (add_den_pos hD hD) hD ?_
  show (add (⟨a, D⟩ : Q) (⟨b, D⟩ : Q)).num * ((D : Nat) : Int)
      = (a + b) * (((D * D : Nat)) : Int)
  simp only [add]
  push_cast
  ring_uor

-- ===========================================================================
-- Copies of the bilinear-expansion privates from `PairingIUEnergy`.
-- ===========================================================================

private theorem add4_RsumL (A B C D : Real) :
    Req (Radd (Radd A B) (Radd C D)) (RsumL [A, B, C, D]) :=
  Req_trans (Radd_congr (Radd_eq_RsumL A B) (Radd_eq_RsumL C D))
    (Req_symm (RsumL_append [A, B] [C, D]))

private theorem flat4L (x y z w : Real) :
    Req (Radd (Radd (Radd x y) z) w) (RsumL [x, y, z, w]) :=
  Req_trans (Radd_congr (Radd_eq_RsumL3 x y z) (RsumL_singleton w))
    (Req_symm (RsumL_append [x, y, z] [w]))

private theorem flatDexp (a b c : Real) :
    Req (Radd (Rsub a (Radd b b)) c) (RsumL [a, Rneg b, Rneg b, c]) :=
  Req_trans
    (Radd_congr
      (Req_trans (Radd_congr (Req_refl a) (Rneg_Radd b b))
        (Req_symm (Radd_assoc a (Rneg b) (Rneg b))))
      (Req_refl c))
    (flat4L a (Rneg b) (Rneg b) c)

private theorem sub_sub_id (a b c : Real) :
    Req (Rsub (Rsub a b) (Rsub b c)) (Radd (Rsub a (Radd b b)) c) :=
  Req_trans
    (Req_trans
      (Radd_congr (Req_refl (Rsub a b))
        (Req_trans (Rneg_Radd b (Rneg c)) (Radd_congr (Req_refl (Rneg b)) (Rneg_neg c))))
      (add4_RsumL a (Rneg b) (Rneg b) c))
    (Req_symm (flatDexp a b c))

private theorem innerI_sub_right' (φ χ ψ : L2Test) :
    Req (innerI φ (L2Test.sub χ ψ)) (Rsub (innerI φ χ) (innerI φ ψ)) :=
  Req_trans (innerI_symm φ (L2Test.sub χ ψ))
    (Req_trans (innerI_sub_left χ ψ φ)
      (Rsub_congr (innerI_symm χ φ) (innerI_symm ψ φ)))

private theorem innerI_sub_self_expand (A B : L2Test) :
    Req (innerI (L2Test.sub A B) (L2Test.sub A B))
        (Radd (Rsub (innerI A A) (Radd (innerI A B) (innerI A B))) (innerI B B)) :=
  Req_trans
    (Req_trans (innerI_sub_left A B (L2Test.sub A B))
      (Rsub_congr (innerI_sub_right' A A B)
        (Req_trans (innerI_sub_right' B A B)
          (Rsub_congr (innerI_symm B A) (Req_refl (innerI B B))))))
    (sub_sub_id (innerI A A) (innerI A B) (innerI B B))

-- ===========================================================================
-- The 2-term AM-GM / L² triangle.
-- ===========================================================================

/-- The pure additive residual identity behind `⟨u+v,u+v⟩ ≤ 2⟨u,u⟩+2⟨v,v⟩`:
    `(2a+2c) − [a,b,b,c] ≈ [a,−b,−b,c]`. -/
private theorem amgm_residual (a b c : Real) :
    Req (Rsub (Radd (Radd a a) (Radd c c)) (RsumL [a, b, b, c]))
        (RsumL [a, Rneg b, Rneg b, c]) := by
  have hRHS : Req (Radd (Radd a a) (Radd c c)) (RsumL [a, a, c, c]) := add4_RsumL a a c c
  have hNeg : Req (Rneg (RsumL [a, b, b, c])) (RsumL [Rneg a, Rneg b, Rneg b, Rneg c]) :=
    RsumL_map_Rneg [a, b, b, c]
  have hsub : Req (Rsub (Radd (Radd a a) (Radd c c)) (RsumL [a, b, b, c]))
      (Radd (RsumL [a, a, c, c]) (RsumL [Rneg a, Rneg b, Rneg b, Rneg c])) :=
    Radd_congr hRHS hNeg
  have happend : Req (Radd (RsumL [a, a, c, c]) (RsumL [Rneg a, Rneg b, Rneg b, Rneg c]))
      (RsumL [a, a, c, c, Rneg a, Rneg b, Rneg b, Rneg c]) :=
    Req_symm (RsumL_append [a, a, c, c] [Rneg a, Rneg b, Rneg b, Rneg c])
  have hcancel1 : Req (RsumL [a, a, c, c, Rneg a, Rneg b, Rneg b, Rneg c])
      (RsumL [a, c, c, Rneg b, Rneg b, Rneg c]) :=
    RsumL_cancel_anywhere a [] [a, c, c] [Rneg b, Rneg b, Rneg c]
  have hcancel2 : Req (RsumL [a, c, c, Rneg b, Rneg b, Rneg c]) (RsumL [a, c, Rneg b, Rneg b]) :=
    RsumL_cancel_anywhere c [a] [c, Rneg b, Rneg b] []
  have hperm : Req (RsumL [a, c, Rneg b, Rneg b]) (RsumL [a, Rneg b, Rneg b, c]) :=
    RsumL_perm
      (List.Perm.cons a
        ((List.Perm.swap (Rneg b) c [Rneg b]).trans
          (List.Perm.cons (Rneg b) (List.Perm.swap (Rneg b) c []))))
  exact Req_trans hsub (Req_trans happend (Req_trans hcancel1 (Req_trans hcancel2 hperm)))

/-- **THE 2-TERM AM-GM**: `⟨u+v, u+v⟩ ≤ 2⟨u,u⟩ + 2⟨v,v⟩`. The residual is `⟨u−v,u−v⟩ ≥ 0`. -/
private theorem energy_add_le_2_2 (u v : L2Test) :
    Rle (innerI (L2Test.add u v) (L2Test.add u v))
        (Radd (Radd (innerI u u) (innerI u u)) (Radd (innerI v v) (innerI v v))) := by
  have hLHS : Req (innerI (L2Test.add u v) (L2Test.add u v))
      (RsumL [innerI u u, innerI u v, innerI u v, innerI v v]) :=
    Req_trans
      (Req_trans (innerI_add_left u v (L2Test.add u v))
        (Radd_congr (innerI_add_right u u v)
          (Req_trans (innerI_add_right v u v)
            (Radd_congr (innerI_symm v u) (Req_refl (innerI v v))))))
      (add4_RsumL (innerI u u) (innerI u v) (innerI u v) (innerI v v))
  have hV : Req (innerI (L2Test.sub u v) (L2Test.sub u v))
      (RsumL [innerI u u, Rneg (innerI u v), Rneg (innerI u v), innerI v v]) :=
    Req_trans (innerI_sub_self_expand u v)
      (flatDexp (innerI u u) (innerI u v) (innerI v v))
  have hres : Req
      (Rsub (Radd (Radd (innerI u u) (innerI u u)) (Radd (innerI v v) (innerI v v)))
            (innerI (L2Test.add u v) (L2Test.add u v)))
      (innerI (L2Test.sub u v) (L2Test.sub u v)) :=
    Req_trans (Rsub_congr (Req_refl _) hLHS)
      (Req_trans (amgm_residual (innerI u u) (innerI u v) (innerI v v)) (Req_symm hV))
  exact Rle_of_Rnonneg_Rsub
    (Rnonneg_congr (Req_symm hres) (innerI_self_nonneg (L2Test.sub u v)))

/-- **THE 2-TERM L² TRIANGLE**: `d²(A,C) ≤ 2·d²(A,B) + 2·d²(B,C)` (doubling by addition). -/
theorem dist2I_triangle2 (A B C : L2Test) :
    Rle (dist2I A C)
        (Radd (Radd (dist2I A B) (dist2I A B)) (Radd (dist2I B C) (dist2I B C))) := by
  have hpt : ∀ x, Rle zero x → Rle x one →
      Req ((L2Test.sub A C).f x)
          ((L2Test.add (L2Test.sub A B) (L2Test.sub B C)).f x) := by
    intro x _ _
    show Req (Radd (A.f x) (Rneg (C.f x)))
             (Radd (Radd (A.f x) (Rneg (B.f x))) (Radd (B.f x) (Rneg (C.f x))))
    exact Req_symm (Rsub_split (A.f x) (B.f x) (C.f x))
  have hcong : Req (dist2I A C)
      (innerI (L2Test.add (L2Test.sub A B) (L2Test.sub B C))
              (L2Test.add (L2Test.sub A B) (L2Test.sub B C))) :=
    Req_trans
      (innerI_left_congr_on_unit (L2Test.sub A C)
        (L2Test.add (L2Test.sub A B) (L2Test.sub B C)) (L2Test.sub A C) hpt)
      (innerI_right_congr_on_unit (L2Test.add (L2Test.sub A B) (L2Test.sub B C))
        (L2Test.sub A C) (L2Test.add (L2Test.sub A B) (L2Test.sub B C)) hpt)
  exact Rle_trans (Rle_of_Req hcong)
    (energy_add_le_2_2 (L2Test.sub A B) (L2Test.sub B C))

/-- **SYMMETRY OF THE L² SQUARED DISTANCE**: `d²(A,B) ≈ d²(B,A)`. -/
theorem dist2I_symm (A B : L2Test) : Req (dist2I A B) (dist2I B A) := by
  have hpt : ∀ x, Rle zero x → Rle x one →
      Req ((L2Test.sub B A).f x) ((L2Test.neg (L2Test.sub A B)).f x) := by
    intro x _ _
    show Req (Radd (B.f x) (Rneg (A.f x))) (Rneg (Radd (A.f x) (Rneg (B.f x))))
    refine Req_symm (Req_trans (Rneg_Radd (A.f x) (Rneg (B.f x))) ?_)
    exact Req_trans (Radd_congr (Req_refl (Rneg (A.f x))) (Rneg_neg (B.f x)))
      (Radd_comm (Rneg (A.f x)) (B.f x))
  have hcong : Req (dist2I B A)
      (innerI (L2Test.neg (L2Test.sub A B)) (L2Test.neg (L2Test.sub A B))) :=
    Req_trans
      (innerI_left_congr_on_unit (L2Test.sub B A) (L2Test.neg (L2Test.sub A B))
        (L2Test.sub B A) hpt)
      (innerI_right_congr_on_unit (L2Test.neg (L2Test.sub A B)) (L2Test.sub B A)
        (L2Test.neg (L2Test.sub A B)) hpt)
  have hneg : Req (innerI (L2Test.neg (L2Test.sub A B)) (L2Test.neg (L2Test.sub A B)))
      (innerI (L2Test.sub A B) (L2Test.sub A B)) :=
    Req_trans (innerI_neg_left (L2Test.sub A B) (L2Test.neg (L2Test.sub A B)))
      (Req_trans (Rneg_congr (innerI_neg_right (L2Test.sub A B) (L2Test.sub A B)))
        (Rneg_neg (innerI (L2Test.sub A B) (L2Test.sub A B))))
  exact Req_symm (Req_trans hcong hneg)

-- ===========================================================================
-- PART A — the reschedule rate at an ARBITRARY read schedule.
-- ===========================================================================

/-- The generalized reschedule rational core: with `1 ≤ S` and `S·(k+1) ≤ Tm`, the squared
    cross-schedule modulus times the energy bound `S` stays below `(2/(k+1))²`. The `Tm`-slot only
    helps; after monotonicity the estimate collapses to the symmetric `S`-step. -/
private theorem reschedule_Q_gen (S k Tm : Nat) (hS : 1 ≤ S) (hT : S * (k + 1) ≤ Tm) :
    Qle (mul (mul (add (⟨1, Tm + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))
                  (add (⟨1, Tm + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)))
             (⟨((S : Nat) : Int), 1⟩ : Q))
        (mul (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
             (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q))) := by
  have hFd : 0 < (add (⟨1, Tm + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)).den :=
    add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)
  have hFn : 0 ≤ (add (⟨1, Tm + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)).num :=
    Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide)
  have hGd : 0 < (add (⟨1, S * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)).den :=
    add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)
  have hinv : Qle (⟨1, Tm + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q) := by
    show (1 : Int) * ((S * (k + 1) + 1 : Nat) : Int) ≤ (1 : Int) * ((Tm + 1 : Nat) : Int)
    omega
  have hFG : Qle (add (⟨1, Tm + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))
                 (add (⟨1, S * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)) :=
    Qadd_le_add hinv (Qle_refl _)
  have hFsq : Qle (mul (add (⟨1, Tm + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))
                       (add (⟨1, Tm + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)))
                  (mul (add (⟨1, S * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))
                       (add (⟨1, S * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))) :=
    Qmul_le_mul hFd hGd hFd hFn hFn hFG hFG
  have hSnn : (0 : Int) ≤ ((S : Nat) : Int) := Int.ofNat_nonneg _
  have hFsqS := Qmul_le_mul_right (c := (⟨((S : Nat) : Int), 1⟩ : Q)) hSnn hFsq
  have hlast : Qle (mul (mul (add (⟨1, S * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q))
                             (add (⟨1, S * (k + 1) + 1⟩ : Q) (⟨1, S * (k + 1) + 1⟩ : Q)))
                        (⟨((S : Nat) : Int), 1⟩ : Q))
                   (mul (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q))
                        (add (⟨1, k + 1⟩ : Q) (⟨1, k + 1⟩ : Q))) := by
    have hs1 : (1 : Int) ≤ (S : Int) := by omega
    have hs0 : (0 : Int) ≤ (S : Int) := by omega
    have hsm : (0 : Int) ≤ (S : Int) - 1 := by omega
    have hw0 : (0 : Int) ≤ (k : Int) + 1 := by omega
    have hsw0 : (0 : Int) ≤ (S : Int) * ((k : Int) + 1) + 1 := by
      have := Int.mul_nonneg hs0 hw0; omega
    have hfac : (0 : Int) ≤ (S : Int) * ((k : Int) + 1) * ((k : Int) + 1) * ((S : Int) - 1)
        + 2 * (S : Int) * ((k : Int) + 1) + 1 := by
      have h1 : (0 : Int) ≤ (S : Int) * ((k : Int) + 1) * ((k : Int) + 1) * ((S : Int) - 1) :=
        Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg hs0 hw0) hw0) hsm
      have h2 : (0 : Int) ≤ 2 * (S : Int) * ((k : Int) + 1) :=
        Int.mul_nonneg (Int.mul_nonneg (by decide) hs0) hw0
      omega
    have hprod : (0 : Int) ≤ 4 * ((S : Int) * ((k : Int) + 1) + 1) * ((S : Int) * ((k : Int) + 1) + 1)
        * ((k : Int) + 1) * ((k : Int) + 1)
        * ((S : Int) * ((k : Int) + 1) * ((k : Int) + 1) * ((S : Int) - 1)
           + 2 * (S : Int) * ((k : Int) + 1) + 1) :=
      Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg (Int.mul_nonneg
        (Int.mul_nonneg (by decide) hsw0) hsw0) hw0) hw0) hfac
    simp only [Qle, mul, add]
    push_cast
    refine Int.le_of_sub_nonneg ?_
    have heq : (1 * ((k : Int) + 1) + 1 * ((k : Int) + 1)) * (1 * ((k : Int) + 1) + 1 * ((k : Int) + 1)) *
          (((S : Int) * ((k : Int) + 1) + 1) * ((S : Int) * ((k : Int) + 1) + 1)
            * (((S : Int) * ((k : Int) + 1) + 1) * ((S : Int) * ((k : Int) + 1) + 1)) * 1) -
        (1 * ((S : Int) * ((k : Int) + 1) + 1) + 1 * ((S : Int) * ((k : Int) + 1) + 1))
          * (1 * ((S : Int) * ((k : Int) + 1) + 1) + 1 * ((S : Int) * ((k : Int) + 1) + 1)) * (S : Int) *
            (((k : Int) + 1) * ((k : Int) + 1) * (((k : Int) + 1) * ((k : Int) + 1)))
        = 4 * ((S : Int) * ((k : Int) + 1) + 1) * ((S : Int) * ((k : Int) + 1) + 1)
          * ((k : Int) + 1) * ((k : Int) + 1)
          * ((S : Int) * ((k : Int) + 1) * ((k : Int) + 1) * ((S : Int) - 1)
             + 2 * (S : Int) * ((k : Int) + 1) + 1) := by ring_uor
    rw [heq]
    exact hprod
  exact Qle_trans (Qmul_den_pos (Qmul_den_pos hGd hGd) Nat.one_pos) hFsqS hlast

/-- **SCHEDULE-INDEPENDENCE AT AN ARBITRARY SCHEDULE**: reading `Φ` at ANY index `T m` with
    `T m ≥ selfBnd ψ · (m+1)` converges to `pairingIU Φ ψ h` at rate `4/(m+1)`. The generalization of
    `pairingIU_reschedule_rate` (which fixes `T m = B·(m+1)`). -/
theorem pairingIU_reschedule_rate_gen (Φ : Nat → L2Test) (ψ : L2Test) (h : L2CauchyU Φ)
    (T : Nat → Nat) (hT : ∀ m, selfBnd ψ * (m + 1) ≤ T m) (m : Nat) :
    Rle (Rabs (Rsub (innerI (Φ (T m)) ψ) (pairingIU Φ ψ h)))
        (ofQ (⟨4, m + 1⟩ : Q) (Nat.succ_pos m)) := by
  have hE : 0 < (add (⟨1, m + 1⟩ : Q) (⟨1, m + 1⟩ : Q)).den :=
    add_den_pos (Nat.succ_pos m) (Nat.succ_pos m)
  have hEn : 0 ≤ (add (⟨1, m + 1⟩ : Q) (⟨1, m + 1⟩ : Q)).num :=
    Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide)
  have hMd : 0 < (mul (add (⟨1, T m + 1⟩ : Q) (⟨1, selfBnd ψ * (m + 1) + 1⟩ : Q))
                      (add (⟨1, T m + 1⟩ : Q) (⟨1, selfBnd ψ * (m + 1) + 1⟩ : Q))).den :=
    Qmul_den_pos (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
                 (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
  have hDsq : Rle (Rmul (Rabs (Rsub (innerI (Φ (T m)) ψ)
                                    (innerI (Φ (selfBnd ψ * (m + 1))) ψ)))
                        (Rabs (Rsub (innerI (Φ (T m)) ψ)
                                    (innerI (Φ (selfBnd ψ * (m + 1))) ψ))))
                  (Rmul (ofQ (add (⟨1, m + 1⟩ : Q) (⟨1, m + 1⟩ : Q)) hE)
                        (ofQ (add (⟨1, m + 1⟩ : Q) (⟨1, m + 1⟩ : Q)) hE)) := by
    refine Rle_trans (Rle_of_Req (abs_sq_loc _)) ?_
    refine Rle_trans (innerI_sub_sq_le (Φ (T m)) (Φ (selfBnd ψ * (m + 1))) ψ) ?_
    refine Rle_trans (Rmul_le_Rmul_both
      (dist2I_nonneg (Φ (T m)) (Φ (selfBnd ψ * (m + 1))))
      (Rnonneg_ofQ Nat.one_pos (Int.ofNat_nonneg _))
      (h (T m) (selfBnd ψ * (m + 1)))
      (innerI_self_le_selfBnd ψ)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ hMd Nat.one_pos)) ?_
    refine Rle_trans (Rle_ofQ_ofQ (Qmul_den_pos hMd Nat.one_pos) (Qmul_den_pos hE hE)
      (reschedule_Q_gen (selfBnd ψ) m (T m) (selfBnd_pos ψ) (hT m))) ?_
    exact Rle_of_Req (Req_symm (Rmul_ofQ_ofQ hE hE))
  have hDbound : Rle (Rabs (Rsub (innerI (Φ (T m)) ψ)
                                 (innerI (Φ (selfBnd ψ * (m + 1))) ψ)))
                     (ofQ (add (⟨1, m + 1⟩ : Q) (⟨1, m + 1⟩ : Q)) hE) :=
    Rle_of_Rsq_le (Rnonneg_Rabs _) (Rnonneg_ofQ hE hEn) hDsq
  have hsplit : Req (Rsub (innerI (Φ (T m)) ψ) (pairingIU Φ ψ h))
      (Radd (Rsub (innerI (Φ (T m)) ψ) (innerI (Φ (selfBnd ψ * (m + 1))) ψ))
            (Rsub (innerI (Φ (selfBnd ψ * (m + 1))) ψ) (pairingIU Φ ψ h))) :=
    Req_symm (Rsub_split (innerI (Φ (T m)) ψ)
      (innerI (Φ (selfBnd ψ * (m + 1))) ψ) (pairingIU Φ ψ h))
  have hQ4 : Qle (add (add (⟨1, m + 1⟩ : Q) (⟨1, m + 1⟩ : Q)) (⟨2, m + 1⟩ : Q)) (⟨4, m + 1⟩ : Q) :=
    Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)
  refine Rle_trans (Rle_of_Req (Rabs_congr hsplit)) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add hDbound (pairingIU_dist Φ ψ h m)) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ hE (Nat.succ_pos m))) ?_
  exact Rle_ofQ_ofQ (add_den_pos hE (Nat.succ_pos m)) (Nat.succ_pos m) hQ4

-- ===========================================================================
-- PART B — the reconstruction sequence and its L²-Cauchyness.
-- ===========================================================================

/-- The Durrmeyer degree `(n+3)²−2` is positive. -/
private theorem recN_pos (n : Nat) : 0 < (n + 3) * (n + 3) - 2 := by
  have h9 := Nat.mul_le_mul (show 3 ≤ n + 3 by omega) (show 3 ≤ n + 3 by omega)
  omega

/-- `0 < 3·(n+1)`. -/
private theorem h3pos (n : Nat) : 0 < 3 * (n + 1) := Nat.mul_pos (by decide) (Nat.succ_pos n)

/-- The approximant index schedule: `E.seq (3(m+1))`. -/
def recA (E : L2Elt) (m : Nat) : Nat := 3 * (m + 1)

/-- The Durrmeyer degree schedule, tuned so the residual `‖E.seq(recA) − durrTest …‖² ≤ (1/(3(m+1)))²`. -/
def recK (E : L2Elt) (m : Nat) : Nat :=
  3 * (m + 1) * ((E.seq (recA E m)).L.num.toNat + 1)

/-- **THE RECONSTRUCTION SEQUENCE**: the Bernstein–Durrmeyer polynomial of `E`'s `m`-th approximant. -/
def reconSeq (E : L2Elt) (m : Nat) : L2Test :=
  durrTest (E.seq (recA E m)) ((recK E m + 3) * (recK E m + 3) - 2) (recN_pos (recK E m))

/-- **PER-INDEX RESIDUAL BOUND**: `d²(E.seq(recA E m), reconSeq E m) ≤ (1/(3(m+1)))²`. From
    `durrTest_L2_converges` (the residual energy `≤ (L·/(recK+3))²`), then the numerator inequality
    `3(m+1)·L ≤ recK+3`. -/
private theorem T1 (E : L2Elt) (m : Nat) :
    Rle (dist2I (E.seq (recA E m)) (reconSeq E m))
        (ofQ (mul (⟨1, 3 * (m + 1)⟩ : Q) (⟨1, 3 * (m + 1)⟩ : Q))
             (Qmul_den_pos (h3pos m) (h3pos m))) := by
  have hLr : Qle (mul (E.seq (recA E m)).L (⟨1, recK E m + 3⟩ : Q)) (⟨1, 3 * (m + 1)⟩ : Q) := by
    have ht : (((E.seq (recA E m)).L.num.toNat : Nat) : Int) = (E.seq (recA E m)).L.num :=
      Int.toNat_of_nonneg (E.seq (recA E m)).hLn
    have hDpos : 0 < (E.seq (recA E m)).L.den := (E.seq (recA E m)).hLd
    have hnat : (E.seq (recA E m)).L.num.toNat * (3 * (m + 1))
        ≤ (E.seq (recA E m)).L.den * (recK E m + 3) := by
      have h1 : (E.seq (recA E m)).L.num.toNat * (3 * (m + 1))
          ≤ 3 * (m + 1) * ((E.seq (recA E m)).L.num.toNat + 1) :=
        Nat.le_trans (Nat.mul_le_mul (Nat.le_succ _) (Nat.le_refl _))
          (Nat.le_of_eq (Nat.mul_comm _ _))
      have h2 : 3 * (m + 1) * ((E.seq (recA E m)).L.num.toNat + 1)
          ≤ (E.seq (recA E m)).L.den * (recK E m + 3) := by
        show 3 * (m + 1) * ((E.seq (recA E m)).L.num.toNat + 1)
            ≤ (E.seq (recA E m)).L.den
              * (3 * (m + 1) * ((E.seq (recA E m)).L.num.toNat + 1) + 3)
        exact Nat.le_trans (Nat.le_add_right _ 3) (Nat.le_mul_of_pos_left _ hDpos)
      exact Nat.le_trans h1 h2
    have hcast : (E.seq (recA E m)).L.num * 1 = ((E.seq (recA E m)).L.num.toNat : Int) := by
      rw [ht]; ring_uor
    show ((E.seq (recA E m)).L.num * 1) * ((3 * (m + 1) : Nat) : Int)
        ≤ (1 : Int) * (((E.seq (recA E m)).L.den * (recK E m + 3) : Nat) : Int)
    rw [hcast, Int.one_mul]
    exact_mod_cast hnat
  refine Rle_trans (durrTest_L2_converges (E.seq (recA E m)) (recK E m)) ?_
  refine Rle_ofQ_ofQ
    (Qmul_den_pos (Qmul_den_pos (E.seq (recA E m)).hLd (Nat.succ_pos (recK E m + 2)))
                  (Qmul_den_pos (E.seq (recA E m)).hLd (Nat.succ_pos (recK E m + 2))))
    (Qmul_den_pos (h3pos m) (h3pos m)) ?_
  refine Qmul_le_mul
    (Qmul_den_pos (E.seq (recA E m)).hLd (Nat.succ_pos (recK E m + 2)))
    (h3pos m)
    (Qmul_den_pos (E.seq (recA E m)).hLd (Nat.succ_pos (recK E m + 2)))
    (Int.mul_nonneg (E.seq (recA E m)).hLn (by show (0 : Int) ≤ 1; decide))
    (Int.mul_nonneg (E.seq (recA E m)).hLn (by show (0 : Int) ≤ 1; decide))
    hLr hLr

-- The common denominator `D = (3(j+1))²·(3(k+1))²` and the three numerators.
private def reconD (j k : Nat) : Nat :=
  (3 * (j + 1)) * (3 * (j + 1)) * ((3 * (k + 1)) * (3 * (k + 1)))

private theorem reconD_pos (j k : Nat) : 0 < reconD j k :=
  Nat.mul_pos (Nat.mul_pos (h3pos j) (h3pos j)) (Nat.mul_pos (h3pos k) (h3pos k))

private def nJ (j k : Nat) : Int := (((3 * (k + 1)) * (3 * (k + 1)) : Nat) : Int)
private def nK (j k : Nat) : Int := (((3 * (j + 1)) * (3 * (j + 1)) : Nat) : Int)
private def nM (j k : Nat) : Int :=
  (((3 * (j + 1) + 3 * (k + 1)) * (3 * (j + 1) + 3 * (k + 1)) : Nat) : Int)

/-- **THE RECONSTRUCTION SEQUENCE IS L²-CAUCHY**. Through the 2-term triangle
    (`dist2I_triangle2`) applied twice via the approximants `E.seq(recA E j)`, `E.seq(recA E k)`:
    `d²(reconSeqⱼ, reconSeqₖ) ≤ 2·(1/(3(j+1)))² + 4·(1/(3(j+1))+1/(3(k+1)))² + 4·(1/(3(k+1)))²
    ≤ (1/(j+1)+1/(k+1))²`. -/
theorem reconSeq_cauchy (E : L2Elt) : L2CauchyU (reconSeq E) := by
  intro j k
  -- three atom bounds over the common denominator `reconD j k`
  have hJ : Rle (dist2I (reconSeq E j) (E.seq (recA E j)))
      (ofQ (⟨nJ j k, reconD j k⟩ : Q) (reconD_pos j k)) := by
    refine Rle_trans (Rle_of_Req (dist2I_symm (reconSeq E j) (E.seq (recA E j)))) ?_
    refine Rle_trans (T1 E j) ?_
    refine Rle_of_Req (ofQ_congr (Qmul_den_pos (h3pos j) (h3pos j)) (reconD_pos j k) ?_)
    simp only [Qeq, mul, reconD, nJ]
    push_cast
    ring_uor
  have hK : Rle (dist2I (E.seq (recA E k)) (reconSeq E k))
      (ofQ (⟨nK j k, reconD j k⟩ : Q) (reconD_pos j k)) := by
    refine Rle_trans (T1 E k) ?_
    refine Rle_of_Req (ofQ_congr (Qmul_den_pos (h3pos k) (h3pos k)) (reconD_pos j k) ?_)
    simp only [Qeq, mul, reconD, nK]
    push_cast
    ring_uor
  have hMdrop : Qle (mul (add (⟨1, recA E j + 1⟩ : Q) (⟨1, recA E k + 1⟩ : Q))
                         (add (⟨1, recA E j + 1⟩ : Q) (⟨1, recA E k + 1⟩ : Q)))
                    (mul (add (⟨1, 3 * (j + 1)⟩ : Q) (⟨1, 3 * (k + 1)⟩ : Q))
                         (add (⟨1, 3 * (j + 1)⟩ : Q) (⟨1, 3 * (k + 1)⟩ : Q))) := by
    have hInvJ : Qle (⟨1, recA E j + 1⟩ : Q) (⟨1, 3 * (j + 1)⟩ : Q) := by
      show (1 : Int) * ((3 * (j + 1) : Nat) : Int) ≤ (1 : Int) * ((3 * (j + 1) + 1 : Nat) : Int)
      omega
    have hInvK : Qle (⟨1, recA E k + 1⟩ : Q) (⟨1, 3 * (k + 1)⟩ : Q) := by
      show (1 : Int) * ((3 * (k + 1) : Nat) : Int) ≤ (1 : Int) * ((3 * (k + 1) + 1 : Nat) : Int)
      omega
    have hsum : Qle (add (⟨1, recA E j + 1⟩ : Q) (⟨1, recA E k + 1⟩ : Q))
                    (add (⟨1, 3 * (j + 1)⟩ : Q) (⟨1, 3 * (k + 1)⟩ : Q)) :=
      Qadd_le_add hInvJ hInvK
    exact Qmul_le_mul (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
      (add_den_pos (h3pos j) (h3pos k))
      (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
      (Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide))
      (Qadd_num_nonneg_loc (by show (0 : Int) ≤ 1; decide) (by show (0 : Int) ≤ 1; decide))
      hsum hsum
  have hM : Rle (dist2I (E.seq (recA E j)) (E.seq (recA E k)))
      (ofQ (⟨nM j k, reconD j k⟩ : Q) (reconD_pos j k)) := by
    refine Rle_trans (E.cauchy (recA E j) (recA E k)) ?_
    refine Rle_trans (Rle_ofQ_ofQ
      (Qmul_den_pos (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _))
                    (add_den_pos (Nat.succ_pos _) (Nat.succ_pos _)))
      (Qmul_den_pos (add_den_pos (h3pos j) (h3pos k)) (add_den_pos (h3pos j) (h3pos k)))
      hMdrop) ?_
    refine Rle_of_Req (ofQ_congr
      (Qmul_den_pos (add_den_pos (h3pos j) (h3pos k)) (add_den_pos (h3pos j) (h3pos k)))
      (reconD_pos j k) ?_)
    simp only [Qeq, mul, add, reconD, nM]
    push_cast
    ring_uor
  -- combine the second hop: d²(Pj, Rk) ≤ ofQ ((nM+nM)+(nK+nK))
  have hPjRk : Rle (dist2I (E.seq (recA E j)) (reconSeq E k))
      (ofQ (⟨(nM j k + nM j k) + (nK j k + nK j k), reconD j k⟩ : Q) (reconD_pos j k)) := by
    refine Rle_trans (dist2I_triangle2 (E.seq (recA E j)) (E.seq (recA E k)) (reconSeq E k)) ?_
    refine Rle_trans (Radd_le_add (Radd_le_add hM hM) (Radd_le_add hK hK)) ?_
    exact Rle_of_Req (Req_trans
      (Radd_congr (add2_ofQ (reconD_pos j k)) (add2_ofQ (reconD_pos j k)))
      (add2_ofQ (reconD_pos j k)))
  -- combine the first hop and finish
  refine Rle_trans (dist2I_triangle2 (reconSeq E j) (E.seq (recA E j)) (reconSeq E k)) ?_
  refine Rle_trans (Radd_le_add (Radd_le_add hJ hJ) (Radd_le_add hPjRk hPjRk)) ?_
  refine Rle_trans (Rle_of_Req (Req_trans
    (Radd_congr (add2_ofQ (reconD_pos j k)) (add2_ofQ (reconD_pos j k)))
    (add2_ofQ (reconD_pos j k)))) ?_
  refine Rle_ofQ_ofQ (reconD_pos j k)
    (Qmul_den_pos (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))
                  (add_den_pos (Nat.succ_pos j) (Nat.succ_pos k))) ?_
  simp only [Qle, mul, add, reconD, nJ, nK, nM]
  push_cast
  refine Int.le_of_sub_nonneg ?_
  have hnn : (0 : Int) ≤ 9 * (((j : Int) + 1) * ((j : Int) + 1) * (((k : Int) + 1) * ((k : Int) + 1)))
      * (((j : Int) + 1) * ((j : Int) + 1) + 10 * (((j : Int) + 1) * ((k : Int) + 1))
         + 3 * (((k : Int) + 1) * ((k : Int) + 1))) := by
    have ha : (0 : Int) ≤ (j : Int) + 1 := by omega
    have hb : (0 : Int) ≤ (k : Int) + 1 := by omega
    refine Int.mul_nonneg (Int.mul_nonneg (by decide)
      (Int.mul_nonneg (Int.mul_nonneg ha ha) (Int.mul_nonneg hb hb))) ?_
    have t1 : (0 : Int) ≤ ((j : Int) + 1) * ((j : Int) + 1) := Int.mul_nonneg ha ha
    have t2 : (0 : Int) ≤ 10 * (((j : Int) + 1) * ((k : Int) + 1)) :=
      Int.mul_nonneg (by decide) (Int.mul_nonneg ha hb)
    have t3 : (0 : Int) ≤ 3 * (((k : Int) + 1) * ((k : Int) + 1)) :=
      Int.mul_nonneg (by decide) (Int.mul_nonneg hb hb)
    omega
  have hid : ((1 * ((k : Int) + 1) + 1 * ((j : Int) + 1))
        * (1 * ((k : Int) + 1) + 1 * ((j : Int) + 1)))
        * ((3 * ((j : Int) + 1)) * (3 * ((j : Int) + 1)) * ((3 * ((k : Int) + 1)) * (3 * ((k : Int) + 1))))
      - ((((3 * ((k : Int) + 1)) * (3 * ((k : Int) + 1))) + ((3 * ((k : Int) + 1)) * (3 * ((k : Int) + 1))))
          + ((((3 * ((j : Int) + 1) + 3 * ((k : Int) + 1)) * (3 * ((j : Int) + 1) + 3 * ((k : Int) + 1)))
                + ((3 * ((j : Int) + 1) + 3 * ((k : Int) + 1)) * (3 * ((j : Int) + 1) + 3 * ((k : Int) + 1))))
              + (((3 * ((j : Int) + 1)) * (3 * ((j : Int) + 1))) + ((3 * ((j : Int) + 1)) * (3 * ((j : Int) + 1))))
              + ((((3 * ((j : Int) + 1) + 3 * ((k : Int) + 1)) * (3 * ((j : Int) + 1) + 3 * ((k : Int) + 1)))
                    + ((3 * ((j : Int) + 1) + 3 * ((k : Int) + 1)) * (3 * ((j : Int) + 1) + 3 * ((k : Int) + 1))))
                  + (((3 * ((j : Int) + 1)) * (3 * ((j : Int) + 1))) + ((3 * ((j : Int) + 1)) * (3 * ((j : Int) + 1)))))))
          * (((j : Int) + 1) * ((k : Int) + 1) * (((j : Int) + 1) * ((k : Int) + 1)))
      = 9 * (((j : Int) + 1) * ((j : Int) + 1) * (((k : Int) + 1) * ((k : Int) + 1)))
        * (((j : Int) + 1) * ((j : Int) + 1) + 10 * (((j : Int) + 1) * ((k : Int) + 1))
           + 3 * (((k : Int) + 1) * ((k : Int) + 1))) := by ring_uor
  rw [hid]
  exact hnn

/-- **THE RECONSTRUCTED L² MEMBER**: the limit member of the Bernstein–Durrmeyer polynomials of `E`'s
    approximants. A genuine `L2Elt` (its defining sequence is L²-Cauchy). -/
def L2Elt.recon (E : L2Elt) : L2Elt := ⟨reconSeq E, reconSeq_cauchy E⟩

-- ===========================================================================
-- PART C — moments are preserved, then inject.
-- ===========================================================================

/-- **THE RECONSTRUCTION PRESERVES EVERY MOMENT**: `(L2Elt.recon E).moment i ≈ E.moment i`. Triangle,
    for each `m`, through `⟨reconSeq E (S(m+1)), xⁱ⟩` and `⟨E.seq(recA E (S(m+1))), xⁱ⟩`
    (`S = selfBnd (xⁱ)`): the outer gaps are `2/(m+1)` (`pairingIU_dist`) and `4/(m+1)`
    (`pairingIU_reschedule_rate_gen`), the middle gap is `≤ 1/(3(m+1))` (Cauchy–Schwarz + `T1`). -/
theorem L2Elt_recon_moment (E : L2Elt) (i : Nat) :
    Req ((L2Elt.recon E).moment i) (E.moment i) := by
  show Req (pairingIU (reconSeq E) (powTest i) (reconSeq_cauchy E))
           (pairingIU E.seq (powTest i) E.cauchy)
  refine Req_of_Rabs_sub_le (C := 7) (fun m => ?_)
  have h3m : 0 < 3 * (m + 1) := h3pos m
  have hSpos : (0 : Int) ≤ ((selfBnd (powTest i) : Nat) : Int) := Int.ofNat_nonneg _
  -- the middle-gap rational inequality: `S·(3(m+1))² ≤ (3(S(m+1)+1))²`.
  have hQbc : Qle
      (mul (mul (⟨1, 3 * (selfBnd (powTest i) * (m + 1) + 1)⟩ : Q)
                (⟨1, 3 * (selfBnd (powTest i) * (m + 1) + 1)⟩ : Q))
           (⟨((selfBnd (powTest i) : Nat) : Int), 1⟩ : Q))
      (mul (⟨1, 3 * (m + 1)⟩ : Q) (⟨1, 3 * (m + 1)⟩ : Q)) := by
    simp only [Qle, mul]
    push_cast
    refine Int.le_of_sub_nonneg ?_
    have hs0 : (0 : Int) ≤ ((selfBnd (powTest i) : Nat) : Int) := hSpos
    have hsm : (0 : Int) ≤ ((selfBnd (powTest i) : Nat) : Int) - 1 := by
      have := selfBnd_pos (powTest i); omega
    have hm0 : (0 : Int) ≤ (m : Int) + 1 := by omega
    have hnn : (0 : Int) ≤ 9 * (((m : Int) + 1) * ((m : Int) + 1)
          * (((selfBnd (powTest i) : Nat) : Int) * (((selfBnd (powTest i) : Nat) : Int) - 1)))
        + 9 * (2 * ((selfBnd (powTest i) : Nat) : Int) * ((m : Int) + 1) + 1) := by
      have p1 : (0 : Int) ≤ 9 * (((m : Int) + 1) * ((m : Int) + 1)
          * (((selfBnd (powTest i) : Nat) : Int) * (((selfBnd (powTest i) : Nat) : Int) - 1))) :=
        Int.mul_nonneg (by decide)
          (Int.mul_nonneg (Int.mul_nonneg hm0 hm0) (Int.mul_nonneg hs0 hsm))
      have p2 : (0 : Int) ≤ 9 * (2 * ((selfBnd (powTest i) : Nat) : Int) * ((m : Int) + 1) + 1) := by
        have : (0 : Int) ≤ 2 * ((selfBnd (powTest i) : Nat) : Int) * ((m : Int) + 1) :=
          Int.mul_nonneg (Int.mul_nonneg (by decide) hs0) hm0
        omega
      omega
    have hid : 1 * (3 * (((selfBnd (powTest i) : Nat) : Int) * ((m : Int) + 1) + 1)
              * (3 * (((selfBnd (powTest i) : Nat) : Int) * ((m : Int) + 1) + 1)) * 1)
          - 1 * ((selfBnd (powTest i) : Nat) : Int) * (3 * ((m : Int) + 1) * (3 * ((m : Int) + 1)))
        = 9 * (((m : Int) + 1) * ((m : Int) + 1)
              * (((selfBnd (powTest i) : Nat) : Int) * (((selfBnd (powTest i) : Nat) : Int) - 1)))
          + 9 * (2 * ((selfBnd (powTest i) : Nat) : Int) * ((m : Int) + 1) + 1) := by ring_uor
    rw [hid]
    exact hnn
  -- outer gaps and middle gap
  have hAB : Rle (Rabs (Rsub (pairingIU (reconSeq E) (powTest i) (reconSeq_cauchy E))
                             (innerI (reconSeq E (selfBnd (powTest i) * (m + 1))) (powTest i))))
      (ofQ (⟨2, m + 1⟩ : Q) (Nat.succ_pos m)) :=
    Rle_trans (Rle_of_Req (abs_sub_comm _ _))
      (pairingIU_dist (reconSeq E) (powTest i) (reconSeq_cauchy E) m)
  have hBC : Rle (Rabs (Rsub (innerI (reconSeq E (selfBnd (powTest i) * (m + 1))) (powTest i))
                             (innerI (E.seq (recA E (selfBnd (powTest i) * (m + 1)))) (powTest i))))
      (ofQ (⟨1, m + 1⟩ : Q) (Nat.succ_pos m)) := by
    have hsq : Rle
        (Rmul (Rabs (Rsub (innerI (reconSeq E (selfBnd (powTest i) * (m + 1))) (powTest i))
                          (innerI (E.seq (recA E (selfBnd (powTest i) * (m + 1)))) (powTest i))))
              (Rabs (Rsub (innerI (reconSeq E (selfBnd (powTest i) * (m + 1))) (powTest i))
                          (innerI (E.seq (recA E (selfBnd (powTest i) * (m + 1)))) (powTest i)))))
        (Rmul (ofQ (⟨1, 3 * (m + 1)⟩ : Q) h3m) (ofQ (⟨1, 3 * (m + 1)⟩ : Q) h3m)) := by
      refine Rle_trans (Rle_of_Req (abs_sq_loc _)) ?_
      refine Rle_trans (innerI_sub_sq_le (reconSeq E (selfBnd (powTest i) * (m + 1)))
        (E.seq (recA E (selfBnd (powTest i) * (m + 1)))) (powTest i)) ?_
      refine Rle_trans (Rmul_le_Rmul_both (dist2I_nonneg _ _)
        (Rnonneg_ofQ Nat.one_pos hSpos)
        (Rle_trans (Rle_of_Req (dist2I_symm (reconSeq E (selfBnd (powTest i) * (m + 1)))
          (E.seq (recA E (selfBnd (powTest i) * (m + 1)))))) (T1 E (selfBnd (powTest i) * (m + 1))))
        (innerI_self_le_selfBnd (powTest i))) ?_
      refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ
        (Qmul_den_pos (h3pos (selfBnd (powTest i) * (m + 1)))
                      (h3pos (selfBnd (powTest i) * (m + 1)))) Nat.one_pos)) ?_
      refine Rle_trans (Rle_ofQ_ofQ
        (Qmul_den_pos (Qmul_den_pos (h3pos (selfBnd (powTest i) * (m + 1)))
                                    (h3pos (selfBnd (powTest i) * (m + 1)))) Nat.one_pos)
        (Qmul_den_pos h3m h3m) hQbc) ?_
      exact Rle_of_Req (Req_symm (Rmul_ofQ_ofQ h3m h3m))
    refine Rle_trans (Rle_of_Rsq_le (Rnonneg_Rabs _)
      (Rnonneg_ofQ h3m (by show (0 : Int) ≤ 1; decide)) hsq) ?_
    refine Rle_ofQ_ofQ h3m (Nat.succ_pos m) ?_
    show (1 : Int) * ((m + 1 : Nat) : Int) ≤ (1 : Int) * ((3 * (m + 1) : Nat) : Int)
    push_cast; omega
  have hT : ∀ m', selfBnd (powTest i) * (m' + 1)
      ≤ recA E (selfBnd (powTest i) * (m' + 1)) := by
    intro m'
    show selfBnd (powTest i) * (m' + 1) ≤ 3 * (selfBnd (powTest i) * (m' + 1) + 1)
    omega
  have hCDd : Rle (Rabs (Rsub
        (innerI (E.seq (recA E (selfBnd (powTest i) * (m + 1)))) (powTest i))
        (pairingIU E.seq (powTest i) E.cauchy)))
      (ofQ (⟨4, m + 1⟩ : Q) (Nat.succ_pos m)) :=
    pairingIU_reschedule_rate_gen E.seq (powTest i) E.cauchy
      (fun m' => recA E (selfBnd (powTest i) * (m' + 1))) hT m
  -- assemble the triangle
  have hsplit : Req
      (Rsub (pairingIU (reconSeq E) (powTest i) (reconSeq_cauchy E))
            (pairingIU E.seq (powTest i) E.cauchy))
      (Radd (Rsub (pairingIU (reconSeq E) (powTest i) (reconSeq_cauchy E))
                  (innerI (reconSeq E (selfBnd (powTest i) * (m + 1))) (powTest i)))
            (Radd (Rsub (innerI (reconSeq E (selfBnd (powTest i) * (m + 1))) (powTest i))
                        (innerI (E.seq (recA E (selfBnd (powTest i) * (m + 1)))) (powTest i)))
                  (Rsub (innerI (E.seq (recA E (selfBnd (powTest i) * (m + 1)))) (powTest i))
                        (pairingIU E.seq (powTest i) E.cauchy)))) :=
    Req_trans
      (Req_symm (Rsub_split (pairingIU (reconSeq E) (powTest i) (reconSeq_cauchy E))
        (innerI (reconSeq E (selfBnd (powTest i) * (m + 1))) (powTest i))
        (pairingIU E.seq (powTest i) E.cauchy)))
      (Radd_congr (Req_refl _)
        (Req_symm (Rsub_split (innerI (reconSeq E (selfBnd (powTest i) * (m + 1))) (powTest i))
          (innerI (E.seq (recA E (selfBnd (powTest i) * (m + 1)))) (powTest i))
          (pairingIU E.seq (powTest i) E.cauchy))))
  have hQ7 : Qle (add (⟨2, m + 1⟩ : Q) (add (⟨1, m + 1⟩ : Q) (⟨4, m + 1⟩ : Q)))
      (⟨7, m + 1⟩ : Q) :=
    Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)
  refine Rle_trans (Rle_of_Req (Rabs_congr hsplit)) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add hAB
    (Rle_trans (Rabs_Radd _ _) (Radd_le_add hBC hCDd))) ?_
  refine Rle_trans (Rle_of_Req (Radd_congr (Req_refl _)
    (Radd_ofQ_ofQ (Nat.succ_pos m) (Nat.succ_pos m)))) ?_
  refine Rle_trans (Rle_of_Req
    (Radd_ofQ_ofQ (Nat.succ_pos m) (add_den_pos (Nat.succ_pos m) (Nat.succ_pos m)))) ?_
  exact Rle_ofQ_ofQ (add_den_pos (Nat.succ_pos m) (add_den_pos (Nat.succ_pos m) (Nat.succ_pos m)))
    (Nat.succ_pos m) hQ7

/-- **★ THE RECONSTRUCTION EQUALS THE ORIGINAL**: an arbitrary completed L² member `E` is the
    L²-limit of the Bernstein–Durrmeyer polynomials of its own approximants — `L2Elt.recon E` pairs
    identically with `E` against every test. Directly from moment-preservation
    (`L2Elt_recon_moment`) and the FREE completion-level moment injectivity
    (`L2Elt_moment_eq_imp_eq`). This closes the completion-bullet "reconstruction of an arbitrary L²
    element". -/
theorem L2Elt_recon_eq (E : L2Elt) : (L2Elt.recon E).eq E :=
  L2Elt_moment_eq_imp_eq (L2Elt.recon E) E (fun i => L2Elt_recon_moment E i)

end Multiplicity.UOR.Bridge.F1Square.Square
