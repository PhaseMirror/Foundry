/-
F1 square — v0.22.0 Track 1, brick (argument axis): **cross-sector argument additivity**
`CargUpper(zw) = Carg z + CargUpper w` (principal `z` × upper `w`, product upper).

The principal-sector additivity `Carg_add` (`arg(zw) = arg z + arg w`, `ComplexArgAdd.lean`) and the
upper-sector argument `CargUpper` (`ComplexArgUpper.lean`) combine here. The clean reduction: with the
coordinate swap `swapC z = ⟨z.im, z.re⟩`,
  • `CargUpper z = π/2 − Carg(swapC z)`  (structural: `Carg(swapC z) = arctan(Re z/Im z)`),
  • `swapC(zw) = swapC w · z̄`  (EXACT, component algebra — `swapC_Cmul_Cconj`),
so `CargUpper(zw) = π/2 − Carg(swapC w · z̄) = π/2 − Carg(swapC w) − Carg(z̄) = CargUpper w + Carg z`,
using the *done* `Carg_add` (all three of `swapC w, z̄, swapC w·z̄` lie in the principal sector when
`z` is principal and `w, zw` are upper) and `Carg_conj` (`arg(z̄) = −arg z`).

Reusable congruence gaps filled along the way: `Rdiv_congr` (division respects `≈`, via denominator
cancellation `Rdiv_mul_cancel`/`Rmul_right_cancel` — no `Rinv_congr` needed) and `Carg_congr`
(the argument respects `≈`).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import F1Square.Analysis.ComplexArgUpper
import F1Square.Analysis.ComplexArgAdd

namespace UOR.Bridge.F1Square.Analysis

/-- **Division respects `≈`**: `a ≈ a'`, `b ≈ b'` (both apart from `0`) ⟹ `a/b ≈ a'/b'`. Proved by
    cancelling the denominator (`(a/b)·b ≈ a ≈ a' ≈ (a'/b')·b' ≈ (a'/b')·b`, then `Rmul_right_cancel`)
    — so it needs no `Rinv`-congruence (which the witness-dependent reindex would make awkward). -/
theorem Rdiv_congr {a a' b b' : Real} {k k' : Nat} (hk : Qlt (Qbound k) (b.seq k))
    (hk' : Qlt (Qbound k') (b'.seq k')) (ha : Req a a') (hb : Req b b') :
    Req (Rdiv a b k hk) (Rdiv a' b' k' hk') :=
  Rmul_right_cancel hk
    (Req_trans (Rdiv_mul_cancel hk)
      (Req_trans ha
        (Req_trans (Req_symm (Rdiv_mul_cancel hk'))
          (Rmul_congr (Req_refl (Rdiv a' b' k' hk')) (Req_symm hb)))))

/-- **The argument respects `≈`**: `z ≈ w` ⟹ `Carg z = Carg w`. The ratio `Im/Re` is congruent
    (`Rdiv_congr`) and `arctan` is congruent (`RarctanR_congr`). -/
theorem Carg_congr {z w : Complex} {kz kw : Nat} (hkz : Qlt (Qbound kz) (z.re.seq kz))
    (hkw : Qlt (Qbound kw) (w.re.seq kw)) (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den)
    (hρlt : ρ.num.toNat < ρ.den) (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ)))
    (hbz : ∀ n, Qle (Qabs ((Rdiv z.im z.re kz hkz).seq n)) ρ)
    (hbw : ∀ n, Qle (Qabs ((Rdiv w.im w.re kw hkw).seq n)) ρ)
    (hzw : Ceq z w) :
    Req (Carg z kz hkz ρ hρ0 hρd hρlt hbz) (Carg w kw hkw ρ hρ0 hρd hρlt hbw) :=
  RarctanR_congr (Rdiv z.im z.re kz hkz) (Rdiv w.im w.re kw hkw) ρ hρ0 hρd hρlt hρ2 hbz hbw
    (Rdiv_congr hkz hkw hzw.2 hzw.1)

/-- **Coordinate swap** `swapC z = ⟨Im z, Re z⟩` — swaps real and imaginary parts. Carries the
    upper sector to the principal sector: `Re(swapC z) = Im z`, `Im(swapC z)/Re(swapC z) = Re z/Im z`. -/
def swapC (z : Complex) : Complex := ⟨z.im, z.re⟩

@[simp] theorem swapC_re (z : Complex) : (swapC z).re = z.im := rfl
@[simp] theorem swapC_im (z : Complex) : (swapC z).im = z.re := rfl

/-- **`swapC(zw) = swapC w · z̄`** (EXACT, up to `≈`): the algebraic identity behind cross-sector
    additivity. `swapC(zw) = ⟨Im(zw), Re(zw)⟩` and `(swapC w)·(z̄) = ⟨Im w·Re z + Re w·Im z,
    Re w·Re z − Im w·Im z⟩ = ⟨Im(zw), Re(zw)⟩` by the `Cmul`/`Cconj` component formulas and `Rmul`
    commutativity. Certified componentwise. -/
theorem swapC_Cmul_Cconj (z w : Complex) :
    Ceq (swapC (Cmul z w)) (Cmul (swapC w) (Cconj z)) := by
  constructor
  · -- Re:  Im(zw) = Re w·Re z − Im w·(−Im z)
    show Req (Radd (Rmul z.re w.im) (Rmul z.im w.re))
      (Rsub (Rmul w.im z.re) (Rmul w.re (Rneg z.im)))
    refine Req_trans (Radd_congr (Rmul_comm z.re w.im) (Rmul_comm z.im w.re)) ?_
    refine Req_symm (Req_trans (Rsub_congr (Req_refl (Rmul w.im z.re)) (Rmul_neg_right w.re z.im)) ?_)
    exact Radd_congr (Req_refl (Rmul w.im z.re)) (Rneg_neg (Rmul w.re z.im))
  · -- Im:  Re(zw) = Im w·(−Im z) + Re w·Re z
    show Req (Rsub (Rmul z.re w.re) (Rmul z.im w.im))
      (Radd (Rmul w.im (Rneg z.im)) (Rmul w.re z.re))
    refine Req_symm (Req_trans (Radd_congr (Rmul_neg_right w.im z.im) (Rmul_comm w.re z.re)) ?_)
    refine Req_trans (Radd_comm (Rneg (Rmul w.im z.im)) (Rmul z.re w.re)) ?_
    exact Rsub_congr (Req_refl (Rmul z.re w.re)) (Rmul_comm w.im z.im)

/-- `π/2 − (A + (−B)) = (π/2 − A) + B` (additive regroup, real algebra). -/
theorem Rsub_radd_neg_regroup (p A B : Real) :
    Req (Rsub p (Radd A (Rneg B))) (Radd (Rsub p A) B) := by
  have hrn : Req (Rneg (Radd A (Rneg B))) (Radd (Rneg A) B) :=
    Req_trans (Rneg_Radd A (Rneg B)) (Radd_congr (Req_refl _) (Rneg_neg B))
  show Req (Radd p (Rneg (Radd A (Rneg B)))) (Radd (Radd p (Rneg A)) B)
  exact Req_trans (Radd_congr (Req_refl p) hrn) (Req_symm (Radd_assoc p (Rneg A) B))

set_option maxHeartbeats 4000000 in
/-- **★ cross-sector argument additivity** `CargUpper(zw) = Carg z + CargUpper w` — principal `z`
    (`Re z > 0`) times upper `w` (`Im w > 0`), product upper (`Im(zw) > 0`), all ratios `< 1/16`.
    Via the swap reduction `swapC(zw) = swapC w · z̄` (`swapC_Cmul_Cconj`): `Carg(swapC(zw)) =
    Carg(swapC w · z̄) = Carg(swapC w) + Carg(z̄) = Carg(swapC w) − Carg z` (`Carg_add` + `Carg_conj`),
    so `CargUpper(zw) = π/2 − Carg(swapC(zw)) = (π/2 − Carg(swapC w)) + Carg z = CargUpper w + Carg z`.
    The genuine second-sector additivity — `arg` is additive across the principal/upper boundary. -/
theorem CargUpper_add (z w : Complex)
    (kz : Nat) (hkz : Qlt (Qbound kz) (z.re.seq kz))
    (kw : Nat) (hkw : Qlt (Qbound kw) (w.im.seq kw))
    (kzw : Nat) (hkzw : Qlt (Qbound kzw) ((Cmul z w).im.seq kzw))
    (kp : Nat) (hkp : Qlt (Qbound kp) ((Cmul (swapC w) (Cconj z)).re.seq kp))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩)
    (hbz : ∀ n, Qle (Qabs ((Rdiv z.im z.re kz hkz).seq n)) ρ)
    (hbcz : ∀ n, Qle (Qabs ((Rdiv (Cconj z).im (Cconj z).re kz hkz).seq n)) ρ)
    (hbw : ∀ n, Qle (Qabs ((Rdiv w.re w.im kw hkw).seq n)) ρ)
    (hbzw : ∀ n, Qle (Qabs ((Rdiv (Cmul z w).re (Cmul z w).im kzw hkzw).seq n)) ρ)
    (hbp : ∀ n, Qle (Qabs ((Rdiv (Cmul (swapC w) (Cconj z)).im
      (Cmul (swapC w) (Cconj z)).re kp hkp).seq n)) ρ)
    (hbvv : ∀ n, Qle (Qabs (vval ((Rdiv (swapC w).im (swapC w).re kw hkw).seq n)
      ((Rdiv (Cconj z).im (Cconj z).re kz hkz).seq n))) ρ) :
    Req (CargUpper (Cmul z w) kzw hkzw ρ hρ0 hρd hlt hbzw)
      (Radd (Carg z kz hkz ρ hρ0 hρd hlt hbz) (CargUpper w kw hkw ρ hρ0 hρd hlt hbw)) := by
  -- Carg(swapC(zw)) ≈ Carg(swapC w · z̄)   (congruence + the swap identity)
  have hcong : Req (Carg (swapC (Cmul z w)) kzw hkzw ρ hρ0 hρd hlt hbzw)
      (Carg (Cmul (swapC w) (Cconj z)) kp hkp ρ hρ0 hρd hlt hbp) :=
    Carg_congr hkzw hkp ρ hρ0 hρd hlt hρ2 hbzw hbp (swapC_Cmul_Cconj z w)
  -- Carg(swapC w · z̄) ≈ Carg(swapC w) + Carg(z̄)   (principal additivity)
  have hadd : Req (Carg (Cmul (swapC w) (Cconj z)) kp hkp ρ hρ0 hρd hlt hbp)
      (Radd (Carg (swapC w) kw hkw ρ hρ0 hρd hlt hbw)
        (Carg (Cconj z) kz hkz ρ hρ0 hρd hlt hbcz)) :=
    Carg_add (swapC w) (Cconj z) kw hkw kz hkz kp hkp ρ hρ0 hρd hlt hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1
      hbw hbcz hbp hbvv
  -- Carg(z̄) ≈ −Carg z   (conjugate symmetry)
  have hconj : Req (Carg (Cconj z) kz hkz ρ hρ0 hρd hlt hbcz)
      (Rneg (Carg z kz hkz ρ hρ0 hρd hlt hbz)) :=
    Carg_conj z kz hkz ρ hρ0 hρd hlt hρ2 hbz hbcz
  have hkey : Req (Carg (swapC (Cmul z w)) kzw hkzw ρ hρ0 hρd hlt hbzw)
      (Radd (Carg (swapC w) kw hkw ρ hρ0 hρd hlt hbw)
        (Rneg (Carg z kz hkz ρ hρ0 hρd hlt hbz))) :=
    Req_trans hcong (Req_trans hadd (Radd_congr (Req_refl _) hconj))
  -- CargUpper(zw) = π/2 − Carg(swapC(zw)); regroup; CargUpper w = π/2 − Carg(swapC w); commute
  show Req (Rsub Rpi_half (Carg (swapC (Cmul z w)) kzw hkzw ρ hρ0 hρd hlt hbzw))
    (Radd (Carg z kz hkz ρ hρ0 hρd hlt hbz) (CargUpper w kw hkw ρ hρ0 hρd hlt hbw))
  refine Req_trans (Rsub_congr (Req_refl Rpi_half) hkey) ?_
  refine Req_trans (Rsub_radd_neg_regroup Rpi_half (Carg (swapC w) kw hkw ρ hρ0 hρd hlt hbw)
    (Carg z kz hkz ρ hρ0 hρd hlt hbz)) ?_
  exact Radd_comm (CargUpper w kw hkw ρ hρ0 hρd hlt hbw) (Carg z kz hkz ρ hρ0 hρd hlt hbz)

end UOR.Bridge.F1Square.Analysis
