/-
F1 square — **THE FIRST CONE-SHAPED TEST DATUM WITH A LIVE PRIME SIDE** (`ConeTent.lean`):
the square-scale symmetric log-tent

    `t4F(x) = 2·log 2 − |log x|` on `[1/4, 4]`, `0` outside

realized as a genuine `WeilTest` (`X = 4`), with its finite-place side EVALUATED in closed
form (`t4PrimePart_eq`): the primes `2` and `3` and the prime power `4` all sit inside the
support, and

    `primes(t4) ≈ log 2·(log 2 + ½·log 2) + log 3·((2·log 2 − log 3) + ⅓·(2·log 2 − log 3))`
    (`= (3/2)·(log 2)² + (4/3)·log 3·(2·log 2 − log 3) ≈ 1.1421`;
     the `Λ(4) = log 2` term dies on the knot `f(4) = 0`).

WHY THIS SHAPE. In the logarithmic variable `u = log x` the test is the tent
`max(0, 2·log 2 − |u|)` — the AUTOCORRELATION of the box on `[−log 2, log 2]`, i.e. of the
box with RATIONAL knots `[1/2, 2]` in `x`. This kills the `√2` obstruction recorded against
the scale-2 tent (whose generating box has knots `2^{∓1/2}`): at SQUARE scales `X = c²` the
generating box `[1/c, c]` is rational-knot. So `t4F` is the first realized test datum of
autocorrelation SHAPE — the cone `g ⋆ g^τ` is where the Weil criterion demands positivity
(`W(bump) < 0` certified that off-cone tests can be negative), and `f(1) = 2·log 2 > 0`
(`t4F_one`) is the on-cone marker `∫|g|² > 0` that the off-cone bump lacked. The datum is
log-VALUED at rational points (`f(a/b) = 2·log 2 ∓ (log a − log b)`), which `WeilTest`
carries natively (`f : Q → Real`).

HONEST SCOPE. This realizes the test DATUM and its finite-place side. The slot integrals
(poles, archimedean tail) need the certified `∫ log` layer — not yet built; and the exact
Connes–Consani weight normalization of the cone element (whether the pairing's `g ⋆ g^τ`
carries an additional multiplicative weight in `x`) is deliberately NOT asserted here —
`t4F` is claimed as the log-coordinate autocorrelation shape only. No positivity claim; the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Square.Pairing
import Core.F1.Analysis.HarmonicLog32

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- The test datum.
-- ===========================================================================

/-- **The square-scale log-tent** (knots `1/4, 1, 4`), as rational-point evaluations:
    `f(a/b) = 2·log 2 − (log b − log a)` on `(1/4, 1]`, `2·log 2 − (log a − log b)` on
    `(1, 4]`, `0` outside (and on junk denominators / non-positive numerators). -/
def t4F : Q → Real := fun q =>
  if hd : 0 < q.den then
    if hn : 0 < q.num then
      if Qle q ⟨1, 4⟩ then zero
      else if Qle q ⟨1, 1⟩ then
        Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
          (Rsub (logN q.den hd) (logN q.num.toNat (by omega)))
      else if Qle q ⟨4, 1⟩ then
        Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
          (Rsub (logN q.num.toNat (by omega)) (logN q.den hd))
      else zero
    else zero
  else zero

/-- Vanishing above the support: `t4F(n) ≈ 0` for `n > 4`. -/
theorem t4F_supp_high : ∀ n : Nat, 4 < n → Req (t4F ⟨(n : Int), 1⟩) zero := by
  intro n hn
  have h1 : ¬ Qle (⟨(n : Int), 1⟩ : Q) ⟨1, 4⟩ := by
    intro h; simp only [Qle] at h; push_cast at h; omega
  have h2 : ¬ Qle (⟨(n : Int), 1⟩ : Q) ⟨1, 1⟩ := by
    intro h; simp only [Qle] at h; push_cast at h; omega
  have h3 : ¬ Qle (⟨(n : Int), 1⟩ : Q) ⟨4, 1⟩ := by
    intro h; simp only [Qle] at h; push_cast at h; omega
  show Req (t4F ⟨(n : Int), 1⟩) zero
  simp only [t4F]
  rw [dif_pos (show 0 < (⟨(n : Int), 1⟩ : Q).den from Nat.one_pos),
    dif_pos (show 0 < (⟨(n : Int), 1⟩ : Q).num from (show (0 : Int) < (n : Int) by omega)),
    if_neg h1, if_neg h2, if_neg h3]
  exact Req_refl zero

/-- Vanishing below the support: `t4F(1/n) ≈ 0` for `n > 4`. -/
theorem t4F_supp_low : ∀ n : Nat, 4 < n → Req (t4F ⟨1, n⟩) zero := by
  intro n hn
  have h1 : Qle (⟨1, n⟩ : Q) ⟨1, 4⟩ := by
    show (1 : Int) * ((4 : Nat) : Int) ≤ (1 : Int) * ((n : Nat) : Int)
    omega
  show Req (t4F ⟨1, n⟩) zero
  simp only [t4F]
  rw [dif_pos (show 0 < (⟨1, n⟩ : Q).den from (show 0 < n by omega)),
    dif_pos (show 0 < (⟨1, n⟩ : Q).num from (show (0 : Int) < 1 by decide)),
    if_pos h1]
  exact Req_refl zero

/-- **The log-tent as a Weil test datum** (`X = 4` — the primes `2`, `3` and the prime
    power `4` all sit inside the support). -/
def t4Test : WeilTest where
  f := t4F
  X := 4
  hX := by decide
  supp_high := t4F_supp_high
  supp_low := t4F_supp_low

-- ===========================================================================
-- The consumed evaluations.
-- ===========================================================================

/-- `(a + b) − b ≈ a`. -/
private theorem t4_add_sub_self (a b : Real) : Req (Rsub (Radd a b) b) a :=
  Req_trans (Radd_assoc a b (Rneg b))
    (Req_trans (Radd_congr (Req_refl a) (Radd_neg b)) (Radd_zero a))

/-- Kill the `log 1` in a branch value: `A − (B − log 1) ≈ A − B`. -/
private theorem t4_drop_log1 (A B : Real) :
    Req (Rsub A (Rsub B (logN 1 (by omega)))) (Rsub A B) :=
  Rsub_congr (Req_refl A)
    (Req_trans (Rsub_congr (Req_refl B) logN_one) (Rsub_zero B))

/-- **`t4F(1) ≈ 2·log 2 > 0` — the on-cone marker** (`f(1) = ∫|g|²` for the generating
    box; the off-cone bump had `f(1) = 0`). -/
theorem t4F_one : Req (t4F ⟨1, 1⟩)
    (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega))) := by
  show Req (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
    (Rsub (logN 1 (by omega)) (logN 1 (by omega)))) _
  refine Req_trans (Rsub_congr (Req_refl _) (Radd_neg (logN 1 (by omega)))) ?_
  exact Rsub_zero _

/-- `t4F(2) ≈ log 2` (the prime `2` sees weight `log 2` from the test itself). -/
theorem t4F_two : Req (t4F ⟨(2 : Int), 1⟩) (logN 2 (by omega)) := by
  show Req (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
    (Rsub (logN 2 (by omega)) (logN 1 (by omega)))) _
  refine Req_trans (t4_drop_log1 _ _) ?_
  refine Req_trans (Rsub_congr (Rmul_two_eq_add (logN 2 (by omega)))
    (Req_refl (logN 2 (by omega)))) ?_
  exact t4_add_sub_self (logN 2 (by omega)) (logN 2 (by omega))

/-- `t4F(1/2) ≈ log 2` (the symmetry `f(1/x) = f(x)`, realized at the point). -/
theorem t4F_half : Req (t4F ⟨1, 2⟩) (logN 2 (by omega)) := by
  show Req (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
    (Rsub (logN 2 (by omega)) (logN 1 (by omega)))) _
  refine Req_trans (t4_drop_log1 _ _) ?_
  refine Req_trans (Rsub_congr (Rmul_two_eq_add (logN 2 (by omega)))
    (Req_refl (logN 2 (by omega)))) ?_
  exact t4_add_sub_self (logN 2 (by omega)) (logN 2 (by omega))

/-- `t4F(3) ≈ 2·log 2 − log 3`. -/
theorem t4F_three : Req (t4F ⟨(3 : Int), 1⟩)
    (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
      (logN 3 (by omega))) := by
  show Req (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
    (Rsub (logN 3 (by omega)) (logN 1 (by omega)))) _
  exact t4_drop_log1 _ _

/-- `t4F(1/3) ≈ 2·log 2 − log 3` (the symmetric point). -/
theorem t4F_third : Req (t4F ⟨1, 3⟩)
    (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
      (logN 3 (by omega))) := by
  show Req (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
    (Rsub (logN 3 (by omega)) (logN 1 (by omega)))) _
  exact t4_drop_log1 _ _

/-- `t4F(4) ≈ 0` (the right knot: `2·log 2 − log 4 = 0` by `log`-multiplicativity). -/
theorem t4F_four : Req (t4F ⟨(4 : Int), 1⟩) zero := by
  show Req (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
    (Rsub (logN 4 (by omega)) (logN 1 (by omega)))) _
  refine Req_trans (t4_drop_log1 _ _) ?_
  refine Req_trans (Rsub_congr (Rmul_two_eq_add (logN 2 (by omega)))
    (Req_symm (logN_mul_gen 2 2 (by omega) (by omega)))) ?_
  exact Radd_neg (Radd (logN 2 (by omega)) (logN 2 (by omega)))

/-- `t4F(1/4) ≈ 0` (the left knot, exactly on the support boundary). -/
theorem t4F_quarter : Req (t4F ⟨1, 4⟩) zero := Req_refl _

-- ===========================================================================
-- THE FINITE-PLACE SIDE, EVALUATED: the first cone-shaped test the primes see.
-- ===========================================================================

-- ===========================================================================
-- THE FINITE-PLACE SIDE, EVALUATED: the first cone-shaped test the primes see.
-- ===========================================================================

set_option maxHeartbeats 400000 in
/-- **The finite-place side of the log-tent, in closed form**:
    `primes(t4) ≈ log 2·(log 2 + ½·log 2) + log 3·((2·log 2 − log 3) + ⅓·(2·log 2 − log 3))`
    — the prime `2` enters with the test's own `log`-weight (`Λ(2)·f(2) = (log 2)²`), the
    prime `3` through the symmetric pair `f(3) = f(1/3) = 2·log 2 − log 3`, and the
    `Λ(4) = log 2` term dies on the knot `f(4) = 0`. Numerically `≈ 1.1421`. -/
theorem t4PrimePart_eq : Req (weilPrimePart t4Test)
    (Radd
      (Rmul (logN 2 (by omega))
        (Radd (logN 2 (by omega))
          (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (logN 2 (by omega)))))
      (Rmul (logN 3 (by omega))
        (Radd (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
            (logN 3 (by omega)))
          (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
            (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
              (logN 3 (by omega))))))) := by
  show Req (Radd (Radd (Radd (Radd zero (weilPrimeTerm t4Test 0))
    (weilPrimeTerm t4Test 1)) (weilPrimeTerm t4Test 2)) (weilPrimeTerm t4Test 3)) _
  have h0 : Req (weilPrimeTerm t4Test 0) zero := by
    refine Req_trans (Rmul_congr vonMangoldt_one (Req_refl _)) ?_
    exact Req_trans (Rmul_comm zero _) (Rmul_zero _)
  have h1 : Req (weilPrimeTerm t4Test 1)
      (Rmul (logN 2 (by omega))
        (Radd (logN 2 (by omega))
          (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (logN 2 (by omega))))) :=
    Rmul_congr vonMangoldt_two
      (Radd_congr t4F_two (Rmul_congr (Req_refl _) t4F_half))
  have h2 : Req (weilPrimeTerm t4Test 2)
      (Rmul (logN 3 (by omega))
        (Radd (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
            (logN 3 (by omega)))
          (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
            (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (logN 2 (by omega)))
              (logN 3 (by omega)))))) :=
    Rmul_congr vonMangoldt_three
      (Radd_congr t4F_three (Rmul_congr (Req_refl _) t4F_third))
  have h3 : Req (weilPrimeTerm t4Test 3) zero := by
    refine Req_trans (Rmul_congr (Req_refl (vonMangoldt 4))
      (Req_trans (Radd_congr t4F_four
        (Req_trans (Rmul_congr (Req_refl _) t4F_quarter) (Rmul_zero _)))
        (Radd_zero zero))) ?_
    exact Rmul_zero (vonMangoldt 4)
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr (Radd_congr (Req_refl zero) h0)
    h1) h2) h3) ?_
  refine Req_trans (Radd_zero _) ?_
  refine Radd_congr ?_ (Req_refl _)
  exact Req_trans (Radd_congr (Radd_zero zero) (Req_refl _))
    (Req_trans (Radd_comm zero _) (Radd_zero _))

end UOR.Bridge.F1Square.Square
