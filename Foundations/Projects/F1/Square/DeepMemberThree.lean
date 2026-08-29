/-
F1 square — **the pre-Hilbert layer, brick 35** (`DeepMemberThree.lean`): **THE `K = 3`
CO-SUPPORT MEMBER, READ OFF THE HILBERT MATRIX** — and the reusable integer-scaling helper
that makes every further `K` mechanical.

With brick 34's Gram closed form `⟨xⁱ, xʲ⟩ = 1/(i+j+1)`, a co-support member at depth `K` is
no longer a construction problem: it is a nonzero rational solution of `K` linear equations
plus the support condition `p(1) = 0`. At `K = 3` that system

    Σᵢ aᵢ/(i+n+1) = 0  (n = 0,1,2),   Σᵢ aᵢ = 0

is solved by `a = (1, −10, 30, −35, 14)`:

    `deep3 = x − 10x² + 30x³ − 35x⁴ + 14x⁵`.

The brick's reusable half is `natScale k φ` (the `k`-fold sum of a test) with its three
transfer laws — support (`natScale_supp`), pointwise values (`natScale_val`), and pairing
values (`innerI_natScale_val`) — so an integer-coefficient combination of monomials is
assembled and evaluated without hand-built addition trees. `innerI_zeroL2` is the base case.

Delivered: `deep3_supp` (coefficients sum to `45 − 45 = 0`, so the saturated clamp kills every
window point), `deep3_moment_zero/_one/_two` (each a `decide`-able rational identity over the
Hilbert entries), **`deep3_hatVanishes`** (`HatVanishes deep3 3`), `deep3_value_tenth`
(`p(1/10) = 333/12500`) with `deep3_apart`, and **`weil_psd_deep3`** — the skeleton's
unconditional positivity on a member whose transform vanishes at THREE integer points.

HONEST SCOPE. One member at `K = 3`; the positivity delivered is still the skeleton's diagonal
multiplier form on moment data, not the Weil functional on the test space, and not positivity
beyond the complement (step 4, = RH). The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.HilbertGram
import Foundations.F1.Square.DeepMember

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxRecDepth 8000

-- ===========================================================================
-- The integer-scaling helper.
-- ===========================================================================

/-- **The `k`-fold sum of a test** — integer scaling from the additive structure alone. -/
def natScale : Nat → L2Test → L2Test
  | 0, _ => zeroL2
  | k + 1, φ => L2Test.add φ (natScale k φ)

/-- The `ℚ` step law behind every scaling induction: `q + k·q = (k+1)·q`. -/
private theorem qscale_step (k : Nat) (q : Q) :
    Qeq (add q (mul (⟨(k : Int), 1⟩ : Q) q)) (mul (⟨((k + 1 : Nat) : Int), 1⟩ : Q) q) := by
  simp only [Qeq, add, mul]
  push_cast
  ring_uor

/-- Scaling preserves `[0,1]` support. -/
theorem natScale_supp (φ : L2Test) (hsupp : UnitSupported φ) :
    ∀ k, UnitSupported (natScale k φ)
  | 0 => zeroL2_supp
  | k + 1 => by
    intro m x h0 h1
    exact Req_trans (Radd_congr (hsupp m x h0 h1) (natScale_supp φ hsupp k m x h0 h1))
      (Radd_zero zero)

/-- **Pointwise values scale**: `(k·φ)(x) = k·φ(x)`. -/
theorem natScale_val (φ : L2Test) (x : Real) {v : Q} (hvd : 0 < v.den)
    (hv : Req (φ.f x) (ofQ v hvd)) :
    ∀ k, Req ((natScale k φ).f x) (ofQ (mul (⟨(k : Int), 1⟩ : Q) v) (Qmul_den_pos Nat.one_pos hvd))
  | 0 => Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨0, 1⟩ : Q) (mul (⟨(0 : Int), 1⟩ : Q) v)
      simp only [Qeq, mul]; push_cast; ring_uor)
  | k + 1 => by
    refine Req_trans (Radd_congr hv (natScale_val φ x hvd hv k)) ?_
    refine Req_trans (Radd_ofQ_ofQ hvd (Qmul_den_pos Nat.one_pos hvd)) ?_
    exact Req_of_seq_Qeq (fun _ => qscale_step k v)

/-- The zero test pairs to zero against anything. -/
theorem innerI_zeroL2 (ψ : L2Test) : Req (innerI zeroL2 ψ) zero := by
  have hlipg : ∀ x y : Real, Rle (Rabs (Rsub zero zero))
      (Rmul (ofQ (l2L zeroL2 ψ) (l2L_den zeroL2 ψ)) (Rabs (Rsub x y))) := by
    intro x y
    refine Rle_trans (Rle_of_Req (Req_trans (Rabs_congr (Radd_neg zero)) Rabs_zero)) ?_
    exact Rle_zero_of_Rnonneg (Rnonneg_Rmul
      (Rnonneg_ofQ (l2L_den zeroL2 ψ) (l2L_num zeroL2 ψ)) (Rnonneg_Rabs _))
  have hfcg : ∀ x y : Real, Req x y → Req zero zero := fun _ _ _ => Req_refl zero
  have hfg : ∀ x, Req (Rmul (zeroL2.f x) (ψ.f x)) zero := fun x =>
    Req_trans (Rmul_comm zero (ψ.f x)) (Rmul_zero (ψ.f x))
  refine Req_trans (riemannIntegral_congr (g := fun _ => zero)
    (l2L_den zeroL2 ψ) (l2L_num zeroL2 ψ) (l2lip zeroL2 ψ) (l2fc zeroL2 ψ)
    hlipg hfcg hfg) ?_
  exact riemannIntegral_const_gen zero (l2L_den zeroL2 ψ) (l2L_num zeroL2 ψ) hlipg hfcg

/-- **Pairing values scale**: `⟨k·φ, ψ⟩ = k·⟨φ, ψ⟩`. -/
theorem innerI_natScale_val (φ ψ : L2Test) {a : Q} (had : 0 < a.den)
    (hA : Req (innerI φ ψ) (ofQ a had)) :
    ∀ k, Req (innerI (natScale k φ) ψ)
      (ofQ (mul (⟨(k : Int), 1⟩ : Q) a) (Qmul_den_pos Nat.one_pos had))
  | 0 => by
    refine Req_trans (innerI_zeroL2 ψ) ?_
    exact Req_of_seq_Qeq (fun _ => by
      show Qeq (⟨0, 1⟩ : Q) (mul (⟨(0 : Int), 1⟩ : Q) a)
      simp only [Qeq, mul]; push_cast; ring_uor)
  | k + 1 => by
    refine Req_trans (innerI_add_left φ (natScale k φ) ψ) ?_
    refine Req_trans (Radd_congr hA (innerI_natScale_val φ ψ had hA k)) ?_
    refine Req_trans (Radd_ofQ_ofQ had (Qmul_den_pos Nat.one_pos had)) ?_
    exact Req_of_seq_Qeq (fun _ => qscale_step k a)

-- Seal the scaling recursion: its three transfer laws are proven above, and leaving it
-- reducible lets the unifier expand `natScale 30 φ` into a 30-deep structure tree (whnf
-- blowup on any structural mismatch).
attribute [irreducible] natScale

-- ===========================================================================
-- Value-chaining helpers (public: the reusable half of this brick — an
-- integer-coefficient combination's value, pointwise and in the pairing, is assembled by
-- chaining these against certified component values).
-- ===========================================================================

theorem pv_add {A B ψ : L2Test} {a b v : Q} (had : 0 < a.den) (hbd : 0 < b.den)
    (hvd : 0 < v.den) (hA : Req (innerI A ψ) (ofQ a had)) (hB : Req (innerI B ψ) (ofQ b hbd))
    (hq : Qeq (add a b) v) : Req (innerI (L2Test.add A B) ψ) (ofQ v hvd) :=
  Req_trans (innerI_add_left A B ψ)
    (Req_trans (Radd_congr hA hB)
      (Req_trans (Radd_ofQ_ofQ had hbd) (Req_of_seq_Qeq (fun _ => hq))))

theorem pv_neg {A ψ : L2Test} {a v : Q} (had : 0 < a.den) (hvd : 0 < v.den)
    (hA : Req (innerI A ψ) (ofQ a had)) (hq : Qeq (neg a) v) :
    Req (innerI (L2Test.neg A) ψ) (ofQ v hvd) :=
  Req_trans (innerI_neg_left A ψ)
    (Req_trans (Rneg_congr hA)
      (Req_trans (Rneg_ofQ a had) (Req_of_seq_Qeq (fun _ => hq))))

theorem pv_scale (k : Nat) {A ψ : L2Test} {a v : Q} (had : 0 < a.den)
    (hvd : 0 < v.den) (hA : Req (innerI A ψ) (ofQ a had))
    (hq : Qeq (mul (⟨(k : Int), 1⟩ : Q) a) v) :
    Req (innerI (natScale k A) ψ) (ofQ v hvd) :=
  Req_trans (innerI_natScale_val A ψ had hA k) (Req_of_seq_Qeq (fun _ => hq))

theorem fv_add {A B : L2Test} {x : Real} {a b v : Q} (had : 0 < a.den)
    (hbd : 0 < b.den) (hvd : 0 < v.den) (hA : Req (A.f x) (ofQ a had))
    (hB : Req (B.f x) (ofQ b hbd)) (hq : Qeq (add a b) v) :
    Req ((L2Test.add A B).f x) (ofQ v hvd) :=
  Req_trans (Radd_congr hA hB)
    (Req_trans (Radd_ofQ_ofQ had hbd) (Req_of_seq_Qeq (fun _ => hq)))

theorem fv_neg {A : L2Test} {x : Real} {a v : Q} (had : 0 < a.den) (hvd : 0 < v.den)
    (hA : Req (A.f x) (ofQ a had)) (hq : Qeq (neg a) v) :
    Req ((L2Test.neg A).f x) (ofQ v hvd) :=
  Req_trans (Rneg_congr hA)
    (Req_trans (Rneg_ofQ a had) (Req_of_seq_Qeq (fun _ => hq)))

theorem fv_scale (k : Nat) {A : L2Test} {x : Real} {a v : Q} (had : 0 < a.den)
    (hvd : 0 < v.den) (hA : Req (A.f x) (ofQ a had))
    (hq : Qeq (mul (⟨(k : Int), 1⟩ : Q) a) v) :
    Req ((natScale k A).f x) (ofQ v hvd) :=
  Req_trans (natScale_val A x had hA k) (Req_of_seq_Qeq (fun _ => hq))

-- ===========================================================================
-- The member.
-- ===========================================================================

/-- The positive part `x + 30x³ + 14x⁵`. -/
def deep3P : L2Test :=
  L2Test.add (L2Test.add (powTest 1) (natScale 30 (powTest 3))) (natScale 14 (powTest 5))

/-- The negative part `10x² + 35x⁴`. -/
def deep3N : L2Test := L2Test.add (natScale 10 (powTest 2)) (natScale 35 (powTest 4))

/-- **The `K = 3` member**: `x − 10x² + 30x³ − 35x⁴ + 14x⁵`, as `P − N`. Routing the sign
    through `L2Test.sub` (and so through `innerI_sub_left`) rather than through a
    `neg`-wrapped summand keeps the unifier off a `L2Test.neg` at the head of a deep tree,
    which otherwise sends `innerI` matching into a whnf blowup. -/
def deep3 : L2Test := L2Test.sub deep3P deep3N

/-- The monomial tests saturate to `1` at every half-line window point. -/
theorem powTest_window_one (m : Nat) {x : Real} (h0 : Rle zero x) :
    ∀ i, Req ((powTest i).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) one
  | 0 => Req_refl one
  | i + 1 =>
    Req_trans (Rmul_congr (powTest_window_one m h0 i) (clamp01_sat (affine_window_ge_one m h0)))
      (Rmul_one one)

/-- **The member is `[0,1]`-supported**: the coefficients sum to `(1+30+14) − (10+35) = 0`. -/
theorem deep3_supp : UnitSupported deep3 := by
  intro m x h0 h1
  have hp : ∀ i, Req ((powTest i).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
    fun i => powTest_window_one m h0 i
  have h30 := fv_scale 30 (a := (⟨1, 1⟩ : Q)) (v := (⟨30, 1⟩ : Q)) (by decide) (by decide)
    (hp 3) (by decide)
  have h14 := fv_scale 14 (a := (⟨1, 1⟩ : Q)) (v := (⟨14, 1⟩ : Q)) (by decide) (by decide)
    (hp 5) (by decide)
  have h10 := fv_scale 10 (a := (⟨1, 1⟩ : Q)) (v := (⟨10, 1⟩ : Q)) (by decide) (by decide)
    (hp 2) (by decide)
  have h35 := fv_scale 35 (a := (⟨1, 1⟩ : Q)) (v := (⟨35, 1⟩ : Q)) (by decide) (by decide)
    (hp 4) (by decide)
  have hA := fv_add (v := (⟨31, 1⟩ : Q)) (by decide) (by decide) (by decide) (hp 1) h30 (by decide)
  have hP := fv_add (v := (⟨45, 1⟩ : Q)) (by decide) (by decide) (by decide) hA h14 (by decide)
  have hN := fv_add (v := (⟨45, 1⟩ : Q)) (by decide) (by decide) (by decide) h10 h35 (by decide)
  show Req (Rsub (deep3P.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))
    (deep3N.f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
      Nat.one_pos (by decide) x))) zero
  exact Req_trans (Rsub_congr hP hN) (Radd_neg _)

-- ===========================================================================
-- The three vanishing moments.
-- ===========================================================================

set_option maxHeartbeats 2000000 in
/-- The member's `n`-th moment, for `n < 3`, vanishes — each a rational identity over the
    Hilbert entries `1/(i+n+1)`. -/
private theorem deep3_moment_gen (n : Nat) {q1 q2 q3 q4 q5 w : Q}
    (h1d : 0 < q1.den) (h2d : 0 < q2.den) (h3d : 0 < q3.den) (h4d : 0 < q4.den)
    (h5d : 0 < q5.den) (hwd : 0 < w.den)
    (e1 : Req (innerI (powTest 1) (powTest n)) (ofQ q1 h1d))
    (e2 : Req (innerI (powTest 2) (powTest n)) (ofQ q2 h2d))
    (e3 : Req (innerI (powTest 3) (powTest n)) (ofQ q3 h3d))
    (e4 : Req (innerI (powTest 4) (powTest n)) (ofQ q4 h4d))
    (e5 : Req (innerI (powTest 5) (powTest n)) (ofQ q5 h5d))
    (hqP : Qeq (add (add q1 (mul (⟨30, 1⟩ : Q) q3)) (mul (⟨14, 1⟩ : Q) q5)) w)
    (hqN : Qeq (add (mul (⟨10, 1⟩ : Q) q2) (mul (⟨35, 1⟩ : Q) q4)) w) :
    Req (innerI deep3 (powTest n)) zero := by
  have h30 := pv_scale 30 (v := mul (⟨30, 1⟩ : Q) q3) h3d
    (Qmul_den_pos (by decide) h3d) e3 (Qeq_refl _)
  have h14 := pv_scale 14 (v := mul (⟨14, 1⟩ : Q) q5) h5d
    (Qmul_den_pos (by decide) h5d) e5 (Qeq_refl _)
  have h10 := pv_scale 10 (v := mul (⟨10, 1⟩ : Q) q2) h2d
    (Qmul_den_pos (by decide) h2d) e2 (Qeq_refl _)
  have h35 := pv_scale 35 (v := mul (⟨35, 1⟩ : Q) q4) h4d
    (Qmul_den_pos (by decide) h4d) e4 (Qeq_refl _)
  have hA := pv_add (v := add q1 (mul (⟨30, 1⟩ : Q) q3)) h1d
    (Qmul_den_pos (by decide) h3d) (add_den_pos h1d (Qmul_den_pos (by decide) h3d))
    e1 h30 (Qeq_refl _)
  have hP := pv_add (v := w) (add_den_pos h1d (Qmul_den_pos (by decide) h3d))
    (Qmul_den_pos (by decide) h5d) hwd hA h14 hqP
  have hN := pv_add (v := w) (Qmul_den_pos (by decide) h2d)
    (Qmul_den_pos (by decide) h4d) hwd h10 h35 hqN
  exact Req_trans (innerI_sub_left deep3P deep3N (powTest n))
    (Req_trans (Rsub_congr hP hN) (Radd_neg _))

/-- `∫₀¹ p = 1/2 + 30/4 + 14/6 − 10/3 − 35/5 = 0`. -/
theorem deep3_moment_zero : Req (innerI deep3 (powTest 0)) zero :=
  deep3_moment_gen 0 (w := (⟨31, 3⟩ : Q)) (Nat.succ_pos 1) (Nat.succ_pos 2) (Nat.succ_pos 3)
    (Nat.succ_pos 4) (Nat.succ_pos 5) (by decide) (innerI_powTest_hilbert 1 0)
    (innerI_powTest_hilbert 2 0) (innerI_powTest_hilbert 3 0) (innerI_powTest_hilbert 4 0)
    (innerI_powTest_hilbert 5 0) (by decide) (by decide)

/-- `∫₀¹ x·p = 1/3 + 30/5 + 14/7 − 10/4 − 35/6 = 0`. -/
theorem deep3_moment_one : Req (innerI deep3 (powTest 1)) zero :=
  deep3_moment_gen 1 (w := (⟨25, 3⟩ : Q)) (Nat.succ_pos 2) (Nat.succ_pos 3) (Nat.succ_pos 4)
    (Nat.succ_pos 5) (Nat.succ_pos 6) (by decide) (innerI_powTest_hilbert 1 1)
    (innerI_powTest_hilbert 2 1) (innerI_powTest_hilbert 3 1) (innerI_powTest_hilbert 4 1)
    (innerI_powTest_hilbert 5 1) (by decide) (by decide)

/-- `∫₀¹ x²·p = 1/4 + 30/6 + 14/8 − 10/5 − 35/7 = 0`. -/
theorem deep3_moment_two : Req (innerI deep3 (powTest 2)) zero :=
  deep3_moment_gen 2 (w := (⟨7, 1⟩ : Q)) (Nat.succ_pos 3) (Nat.succ_pos 4) (Nat.succ_pos 5)
    (Nat.succ_pos 6) (Nat.succ_pos 7) (by decide) (innerI_powTest_hilbert 1 2)
    (innerI_powTest_hilbert 2 2) (innerI_powTest_hilbert 3 2) (innerI_powTest_hilbert 4 2)
    (innerI_powTest_hilbert 5 2) (by decide) (by decide)

/-- **THE `K = 3` CO-SUPPORT MEMBER**: the transform vanishes at the integer points `0, 1, 2`. -/
theorem deep3_hatVanishes :
    HatVanishes deep3 3 (C := (⟨0, 1⟩ : Q)) (by decide) (by show (0 : Int) ≤ 0; decide)
      (allDecay_of_supp deep3 deep3_supp) :=
  hatVanishes_of_moments deep3 3 deep3_supp (fun n hn => by
    match n with
    | 0 => exact deep3_moment_zero
    | 1 => exact deep3_moment_one
    | 2 => exact deep3_moment_two
    | (k + 3) => exact absurd hn (by omega))

-- ===========================================================================
-- Apartness and the capstone.
-- ===========================================================================

/-- **The member is not the zero function**: `p(1/10) = 333/12500`. -/
theorem deep3_value_tenth :
    Req (deep3.f (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ (⟨333, 12500⟩ : Q) (by decide)) := by
  have hc : Req (clamp01 (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ (⟨1, 10⟩ : Q) (by decide)) :=
    clamp01_ofQ (by decide) (by decide) (by decide)
  have p0 : Req ((powTest 0).f (ofQ (⟨1, 10⟩ : Q) (by decide)))
      (ofQ (⟨1, 1⟩ : Q) (by decide)) := Req_refl one
  have step : ∀ {i : Nat} {u : Q} (hud : 0 < u.den) {w : Q} (hwd : 0 < w.den),
      Req ((powTest i).f (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ u hud) →
      Qeq (mul u (⟨1, 10⟩ : Q)) w →
      Req ((powTest (i + 1)).f (ofQ (⟨1, 10⟩ : Q) (by decide))) (ofQ w hwd) := by
    intro i u hud w hwd hu hq
    refine Req_trans (Rmul_congr hu hc) ?_
    exact Req_trans (Rmul_ofQ_ofQ hud (by decide)) (Req_of_seq_Qeq (fun _ => hq))
  have p1 := step (i := 0) (by decide) (w := (⟨1, 10⟩ : Q)) (by decide) p0 (by decide)
  have p2 := step (i := 1) (by decide) (w := (⟨1, 100⟩ : Q)) (by decide) p1 (by decide)
  have p3 := step (i := 2) (by decide) (w := (⟨1, 1000⟩ : Q)) (by decide) p2 (by decide)
  have p4 := step (i := 3) (by decide) (w := (⟨1, 10000⟩ : Q)) (by decide) p3 (by decide)
  have p5 := step (i := 4) (by decide) (w := (⟨1, 100000⟩ : Q)) (by decide) p4 (by decide)
  have h30 := fv_scale 30 (v := (⟨30, 1000⟩ : Q)) (by decide) (by decide) p3 (by decide)
  have h14 := fv_scale 14 (v := (⟨14, 100000⟩ : Q)) (by decide) (by decide) p5 (by decide)
  have h10 := fv_scale 10 (v := (⟨10, 100⟩ : Q)) (by decide) (by decide) p2 (by decide)
  have h35 := fv_scale 35 (v := (⟨35, 10000⟩ : Q)) (by decide) (by decide) p4 (by decide)
  have hA := fv_add (v := (⟨13, 100⟩ : Q)) (by decide) (by decide) (by decide) p1 h30 (by decide)
  have hP := fv_add (v := (⟨13014, 100000⟩ : Q)) (by decide) (by decide) (by decide)
    hA h14 (by decide)
  have hN := fv_add (v := (⟨1035, 10000⟩ : Q)) (by decide) (by decide) (by decide)
    h10 h35 (by decide)
  show Req (Rsub (deep3P.f (ofQ (⟨1, 10⟩ : Q) (by decide)))
    (deep3N.f (ofQ (⟨1, 10⟩ : Q) (by decide)))) (ofQ (⟨333, 12500⟩ : Q) (by decide))
  refine Req_trans (Rsub_congr hP hN) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Rneg_ofQ (⟨1035, 10000⟩ : Q) (by decide))) ?_
  refine Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) ?_
  exact Req_of_seq_Qeq (fun _ => by
    show Qeq (add (⟨13014, 100000⟩ : Q) (neg (⟨1035, 10000⟩ : Q))) (⟨333, 12500⟩ : Q)
    decide)

/-- **Apartness**: `Pos (deep3(1/10))`. -/
theorem deep3_apart : Pos (deep3.f (ofQ (⟨1, 10⟩ : Q) (by decide))) :=
  Pos_congr (Req_symm deep3_value_tenth) ⟨40, by decide⟩

/-- **THE CAPSTONE AT DEPTH 3**: the skeleton's unconditional complement-positivity fires on
    the moment sequence of a certified NONZERO test whose constructed transform vanishes at
    THREE integer points (`HatVanishes · 3 ⊆ HatVanishes · 2`). No RH. -/
theorem weil_psd_deep3 (N : Nat) :
    Rnonneg (weilQuad (multForm burnolMult) (momSeq deep3) N) :=
  weil_psd_on_cosupport deep3 deep3_supp
    (hatVanishes_mono (by decide) deep3_hatVanishes) N

end Multiplicity.UOR.Bridge.F1Square.Square
