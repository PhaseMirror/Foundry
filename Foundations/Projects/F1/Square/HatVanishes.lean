/-
F1 square — **the pre-Hilbert layer, brick 22** (`HatVanishes.lean`): **THE CO-SUPPORT
PREDICATE** — "`f̂` vanishes below `K`" is a stated, subspace-shaped condition on constructed
transforms, and it is inhabited.

The decay data is bundled: `WindowDecay φ n C` is the exponent-`(n+2)` window bound `mellinHat`
consumes, and `AllDecay φ C` demands it at every order — the superpolynomial-decay class on
which every integer point of the transform exists at one constant. The bundle has the two laws
that make shared constants reachable: monotonicity in `C` (`windowDecay_weaken`/
`allDecay_weaken`) and closure under addition at the summed constant (`windowDecay_add`/
`allDecay_add`, the triangle inequality against the distributed bound).

On that class, **`HatVanishes φ K`**: `f̂(n) ≈ 0` for every `n < K`. The three theorems:

- `hatVanishes_mono` — the conditions filter downward in `K`.
- **`hatVanishes_add`** — THE SUBSPACE THEOREM: at a shared decay constant, the co-support
  condition is closed under addition (brick 21's `mellinHat_add` against `0 + 0 ≈ 0`). The
  transform-side vanishing conditions genuinely cut out subspaces of the test class.
- `hatVanishes_of_moments` — the compact bridge: for a `[0,1]`-supported test
  (`UnitSupported`), vanishing moments below `K` give `HatVanishes` (brick 20's
  `mellinHat_compact`), welding the predicate to the brick-10 moment skeleton.

Nonvacuity: `zeroL2` is the constructed zero test, `mellinMoment_zeroL2` evaluates all its
moments to `0` (integrand pointwise `≈ 0`, congruence to the constant integrand, the constant
integral), and `hatVanishes_zeroL2` places it in the co-support class at every `K`.

HONEST SCOPE. The predicate, its subspace closure, and the zero member. Integer points only —
no continuous parameter, no band-indexed vanishing set tied to the skeleton's `bandProj`, no
NONZERO member yet (a nonzero `[0,1]`-supported test with vanishing low moments is the banked
next construction), and no coupling: positivity of the Weil form on a co-support class is step
4 and is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MellinLinear
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The bundled decay data.
-- ===========================================================================

/-- **Exponent-`(n+2)` window decay at constant `C`** — the decay datum `mellinHat` consumes:
    on window `[m+1, m+2]` the test is bounded by `C/(m+1)^{n+2}`. -/
abbrev WindowDecay (φ : L2Test) (n : Nat) (C : Q) (hCd : 0 < C.den) : Prop :=
  ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
    Rle (Rabs (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
          Nat.one_pos (by decide) x)))
      (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))

/-- **All-order window decay at constant `C`** — the superpolynomial-decay class: every
    integer point of the transform exists on it at the single constant `C`. -/
abbrev AllDecay (φ : L2Test) (C : Q) (hCd : 0 < C.den) : Prop :=
  ∀ n : Nat, WindowDecay φ n C hCd

/-- **Decay weakening**: a window-decay certificate at `C` is one at any `C' ≥ C`. -/
theorem windowDecay_weaken {C C' : Q} (hCd : 0 < C.den) (hC'd : 0 < C'.den) (h : Qle C C')
    {φ : L2Test} {n : Nat} (hd : WindowDecay φ n C hCd) : WindowDecay φ n C' hC'd := by
  intro m x h0 h1
  refine Rle_trans (hd m x h0 h1) ?_
  exact Rle_ofQ_ofQ _ _ (qmul_le_right_mono h (by show (0 : Int) ≤ 1; decide))

/-- All-order decay weakens the same way. -/
theorem allDecay_weaken {C C' : Q} (hCd : 0 < C.den) (hC'd : 0 < C'.den) (h : Qle C C')
    {φ : L2Test} (hd : AllDecay φ C hCd) : AllDecay φ C' hC'd :=
  fun n => windowDecay_weaken hCd hC'd h (hd n)

/-- **Decay adds**: the sum test decays at the summed constant (triangle inequality against
    the distributed bound `C₁/p + C₂/p ≈ (C₁+C₂)/p`). -/
theorem windowDecay_add {C₁ C₂ : Q} (hC₁d : 0 < C₁.den) (hC₂d : 0 < C₂.den)
    {φ ψ : L2Test} {n : Nat}
    (h₁ : WindowDecay φ n C₁ hC₁d) (h₂ : WindowDecay ψ n C₂ hC₂d) :
    WindowDecay (L2Test.add φ ψ) n (add C₁ C₂) (add_den_pos hC₁d hC₂d) := by
  intro m x h0 h1
  have hq : Qeq (add (mul C₁ (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
        (mul C₂ (⟨1, (m + 1) ^ (n + 2)⟩ : Q)))
      (mul (add C₁ C₂) (⟨1, (m + 1) ^ (n + 2)⟩ : Q)) := by
    generalize (m + 1) ^ (n + 2) = P
    simp only [Qeq, add, mul]
    push_cast
    ring_uor
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add (h₁ m x h0 h1) (h₂ m x h0 h1)) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ
    (Qmul_den_pos hC₁d (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))
    (Qmul_den_pos hC₂d (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) ?_
  exact Rle_of_Req (Req_of_seq_Qeq (fun _ => hq))

/-- All-order decay adds the same way. -/
theorem allDecay_add {C₁ C₂ : Q} (hC₁d : 0 < C₁.den) (hC₂d : 0 < C₂.den) {φ ψ : L2Test}
    (h₁ : AllDecay φ C₁ hC₁d) (h₂ : AllDecay ψ C₂ hC₂d) :
    AllDecay (L2Test.add φ ψ) (add C₁ C₂) (add_den_pos hC₁d hC₂d) :=
  fun n => windowDecay_add hC₁d hC₂d (h₁ n) (h₂ n)

-- ===========================================================================
-- Compact support and the predicate.
-- ===========================================================================

/-- **`[0,1]` support**: the test vanishes at every half-line window point. -/
abbrev UnitSupported (φ : L2Test) : Prop :=
  ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
    Req (φ.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) zero

/-- A `[0,1]`-supported test has all-order decay at `C = 0` (brick 20's `hdec_of_supp` at
    every order). -/
theorem allDecay_of_supp (φ : L2Test) (hsupp : UnitSupported φ) :
    AllDecay φ (⟨0, 1⟩ : Q) (by decide) :=
  fun n => hdec_of_supp φ n hsupp

/-- **THE CO-SUPPORT PREDICATE**: `f̂(n) ≈ 0` for every `n < K` — the transform-side vanishing
    condition, stated about the constructed `mellinHat` on the all-order decay class. -/
def HatVanishes (φ : L2Test) (K : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hall : AllDecay φ C hCd) : Prop :=
  ∀ n : Nat, n < K → Req (mellinHat φ n hCd hCn (hall n)) zero

/-- The co-support conditions filter downward: vanishing below `K` gives vanishing below any
    `K' ≤ K`. -/
theorem hatVanishes_mono {φ : L2Test} {K K' : Nat} (hKK : K' ≤ K) {C : Q}
    {hCd : 0 < C.den} {hCn : 0 ≤ C.num} {hall : AllDecay φ C hCd}
    (h : HatVanishes φ K hCd hCn hall) : HatVanishes φ K' hCd hCn hall :=
  fun n hn => h n (Nat.lt_of_lt_of_le hn hKK)

/-- **THE SUBSPACE THEOREM**: at a shared decay constant, the co-support condition is closed
    under addition — `(φ+ψ)^(n) ≈ φ̂(n) + ψ̂(n) ≈ 0 + 0 ≈ 0` (brick 21's linearity). The
    transform-side vanishing conditions cut out genuine subspaces of the test class. -/
theorem hatVanishes_add (φ ψ : L2Test) (K : Nat) {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hallφ : AllDecay φ C hCd) (hallψ : AllDecay ψ C hCd)
    (hallS : AllDecay (L2Test.add φ ψ) C hCd)
    (hφ : HatVanishes φ K hCd hCn hallφ) (hψ : HatVanishes ψ K hCd hCn hallψ) :
    HatVanishes (L2Test.add φ ψ) K hCd hCn hallS := by
  intro n hn
  refine Req_trans (mellinHat_add φ ψ n hCd hCn (hallφ n) (hallψ n) (hallS n)) ?_
  exact Req_trans (Radd_congr (hφ n hn) (hψ n hn)) (Radd_zero zero)

/-- **The compact bridge**: a `[0,1]`-supported test with vanishing moments below `K` is in
    the co-support class — `f̂` is the moment sequence there (brick 20's `mellinHat_compact`),
    so the predicate welds to the brick-10 moment skeleton. -/
theorem hatVanishes_of_moments (φ : L2Test) (K : Nat) (hsupp : UnitSupported φ)
    (hmom : ∀ n : Nat, n < K → Req (mellinMoment φ n) zero) :
    HatVanishes φ K (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp φ hsupp) :=
  fun n hn => Req_trans (mellinHat_compact φ n hsupp) (hmom n hn)

-- ===========================================================================
-- Nonvacuity: the zero member.
-- ===========================================================================

/-- The constructed zero test. -/
def zeroL2 : L2Test where
  f := fun _ => zero
  L := ⟨0, 1⟩
  M := ⟨0, 1⟩
  hLd := by decide
  hLn := by decide
  hMd := by decide
  hMn := by decide
  hlip := fun x y => by
    have hz : Req (Rabs (Rsub zero zero)) zero :=
      Req_trans (Rabs_congr (Radd_neg zero)) Rabs_zero
    have hz0 : Req (ofQ (⟨0, 1⟩ : Q) (by decide)) zero :=
      Req_of_seq_Qeq (fun _ => Qeq_refl _)
    have hR : Req (Rmul (ofQ (⟨0, 1⟩ : Q) (by decide)) (Rabs (Rsub x y))) zero :=
      Req_trans (Rmul_congr hz0 (Req_refl _))
        (Req_trans (Rmul_comm zero _) (Rmul_zero _))
    exact Rle_trans (Rle_of_Req hz) (Rle_of_Req (Req_symm hR))
  hfc := fun _ _ _ => Req_refl zero
  hbd := fun _ => by
    have hz0 : Req (ofQ (⟨0, 1⟩ : Q) (by decide)) zero :=
      Req_of_seq_Qeq (fun _ => Qeq_refl _)
    exact Rle_of_Req (Req_trans Rabs_zero (Req_symm hz0))

/-- The zero test is `[0,1]`-supported (it vanishes everywhere). -/
theorem zeroL2_supp : UnitSupported zeroL2 :=
  fun _ _ _ _ => Req_refl zero

/-- **Every moment of the zero test vanishes**: the integrand is pointwise `≈ 0`, so the
    pairing is the constant integral of `0`. -/
theorem mellinMoment_zeroL2 (n : Nat) : Req (mellinMoment zeroL2 n) zero := by
  have hlipg : ∀ x y : Real, Rle (Rabs (Rsub zero zero))
      (Rmul (ofQ (l2L zeroL2 (powTest n)) (l2L_den zeroL2 (powTest n)))
        (Rabs (Rsub x y))) := by
    intro x y
    have hz : Req (Rabs (Rsub zero zero)) zero :=
      Req_trans (Rabs_congr (Radd_neg zero)) Rabs_zero
    refine Rle_trans (Rle_of_Req hz) ?_
    exact Rle_zero_of_Rnonneg (Rnonneg_Rmul
      (Rnonneg_ofQ (l2L_den zeroL2 (powTest n)) (l2L_num zeroL2 (powTest n)))
      (Rnonneg_Rabs _))
  have hfcg : ∀ x y : Real, Req x y → Req zero zero := fun _ _ _ => Req_refl zero
  have hfg : ∀ x, Req (Rmul (zeroL2.f x) ((powTest n).f x)) zero := fun x =>
    Req_trans (Rmul_comm zero ((powTest n).f x)) (Rmul_zero ((powTest n).f x))
  refine Req_trans (riemannIntegral_congr (g := fun _ => zero)
    (l2L_den zeroL2 (powTest n)) (l2L_num zeroL2 (powTest n))
    (l2lip zeroL2 (powTest n)) (l2fc zeroL2 (powTest n)) hlipg hfcg hfg) ?_
  exact riemannIntegral_const_gen zero (l2L_den zeroL2 (powTest n))
    (l2L_num zeroL2 (powTest n)) hlipg hfcg

/-- **NONVACUITY**: the co-support class is inhabited at every `K` — the zero test is in it.
    (The honest limit of this member: it is zero; a NONZERO `[0,1]`-supported test with
    vanishing low moments is the banked next construction.) -/
theorem hatVanishes_zeroL2 (K : Nat) :
    HatVanishes zeroL2 K (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp zeroL2 zeroL2_supp) :=
  hatVanishes_of_moments zeroL2 K zeroL2_supp (fun n _ => mellinMoment_zeroL2 n)

end Multiplicity.UOR.Bridge.F1Square.Square
