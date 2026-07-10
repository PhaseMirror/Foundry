/-
F1 square — v0.22.0 Track 1, brick (argument axis): **left-sector argument additivity**
`CargLeft(zw) = CargLeft z + Carg w` — left-half-plane `z` (`Re z < 0`) times principal `w`
(`Re w > 0`), the product again left.

This completes the cross-sector argument additivity over the whole punctured plane: the principal
(`Carg_add`), upper (`CargUpper_add`), lower (`CargLower_add`), and now left sectors all satisfy
`arg(zw) = arg z + arg w`. The left case reflects the principal one through the `+π` shift: since
`−(zw) = (−z)·w` (`Cneg_Cmul_left`), and `−z` and `w` are both principal (right half-plane),
`CargLeft(zw) = arg(−(zw)) + π = arg((−z)w) + π = (arg(−z) + arg w) + π = (arg(−z) + π) + arg w
= CargLeft z + Carg w`, using `Carg_add` on the two principal factors and an `Radd` regroup.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import F1Square.Analysis.ComplexArgLeft
import F1Square.Analysis.ComplexArgAdd
import F1Square.Analysis.ComplexArgUpperAdd

namespace UOR.Bridge.F1Square.Analysis

/-- **Negation distributes over the left factor** `−(zw) = (−z)·w` (up to `≈`):
    `Ceq (Cneg (Cmul z w)) (Cmul (Cneg z) w)`. Componentwise from `Rneg_Radd`, `Rmul_neg_left`, and
    `Rneg_congr` — the algebraic identity behind reflecting the principal sector into the left sector
    via the `+π` shift. -/
theorem Cneg_Cmul_left (z w : Complex) : Ceq (Cneg (Cmul z w)) (Cmul (Cneg z) w) := by
  refine ⟨?_, ?_⟩
  · -- Re: −(z.re·w.re − z.im·w.im) = (−z.re)·w.re − (−z.im)·w.im
    show Req (Rneg (Rsub (Rmul z.re w.re) (Rmul z.im w.im)))
      (Rsub (Rmul (Rneg z.re) w.re) (Rmul (Rneg z.im) w.im))
    refine Req_trans (Rneg_Radd (Rmul z.re w.re) (Rneg (Rmul z.im w.im))) ?_
    exact Radd_congr (Req_symm (Rmul_neg_left z.re w.re))
      (Req_symm (Rneg_congr (Rmul_neg_left z.im w.im)))
  · -- Im: −(z.re·w.im + z.im·w.re) = (−z.re)·w.im + (−z.im)·w.re
    show Req (Rneg (Radd (Rmul z.re w.im) (Rmul z.im w.re)))
      (Radd (Rmul (Rneg z.re) w.im) (Rmul (Rneg z.im) w.re))
    refine Req_trans (Rneg_Radd (Rmul z.re w.im) (Rmul z.im w.re)) ?_
    exact Radd_congr (Req_symm (Rmul_neg_left z.re w.im)) (Req_symm (Rmul_neg_left z.im w.re))

set_option maxHeartbeats 4000000 in
/-- **★ left-sector argument additivity** `CargLeft(zw) = CargLeft z + Carg w` — left `z` times
    principal `w` (product left). `CargLeft(zw) = Carg(−(zw)) + π = Carg((−z)w) + π` (`Cneg_Cmul_left`
    + `Carg_congr`) `= (Carg(−z) + Carg w) + π` (`Carg_add`, both `−z` and `w` principal)
    `= (Carg(−z) + π) + Carg w = CargLeft z + Carg w` (`Radd` regroup). -/
theorem CargLeft_add (z w : Complex)
    (knz : Nat) (hknz : Qlt (Qbound knz) ((Cneg z).re.seq knz))
    (kw : Nat) (hkw : Qlt (Qbound kw) (w.re.seq kw))
    (kzw : Nat) (hkzw : Qlt (Qbound kzw) ((Cneg (Cmul z w)).re.seq kzw))
    (kp : Nat) (hkp : Qlt (Qbound kp) ((Cmul (Cneg z) w).re.seq kp))
    (ρ : Q) (hρ0 : 0 ≤ ρ.num) (hρd : 0 < ρ.den) (hlt : ρ.num.toNat < ρ.den)
    (hlt16 : (mul (⟨16, 1⟩ : Q) ρ).num.toNat < (mul (⟨16, 1⟩ : Q) ρ).den)
    (h2ρ : 0 ≤ (Qsub (⟨1, 1⟩ : Q) (mul ⟨2, 1⟩ ρ)).num)
    (hhalf : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ⟨2, 1⟩ ρ))) (hρ4 : Qle (mul ⟨4, 1⟩ ρ) ⟨1, 1⟩)
    (hρ2 : Qle (⟨1, 2⟩ : Q) (Qsub ⟨1, 1⟩ (mul ρ ρ))) (hρ8 : Qle (mul ⟨2, 1⟩ ρ) ⟨1, 1⟩)
    (hρ1 : Qle ρ ⟨1, 1⟩)
    (hbnz : ∀ n, Qle (Qabs ((Rdiv (Cneg z).im (Cneg z).re knz hknz).seq n)) ρ)
    (hbw : ∀ n, Qle (Qabs ((Rdiv w.im w.re kw hkw).seq n)) ρ)
    (hbzw : ∀ n, Qle (Qabs ((Rdiv (Cneg (Cmul z w)).im (Cneg (Cmul z w)).re kzw hkzw).seq n)) ρ)
    (hbp : ∀ n, Qle (Qabs ((Rdiv (Cmul (Cneg z) w).im (Cmul (Cneg z) w).re kp hkp).seq n)) ρ)
    (hbvv : ∀ n, Qle (Qabs (vval ((Rdiv (Cneg z).im (Cneg z).re knz hknz).seq n)
      ((Rdiv w.im w.re kw hkw).seq n))) ρ) :
    Req (CargLeft (Cmul z w) kzw hkzw ρ hρ0 hρd hlt hbzw)
      (Radd (CargLeft z knz hknz ρ hρ0 hρd hlt hbnz) (Carg w kw hkw ρ hρ0 hρd hlt hbw)) := by
  -- Carg(−(zw)) ≈ Carg((−z)w)   (congruence + Cneg_Cmul_left)
  have hcong : Req (Carg (Cneg (Cmul z w)) kzw hkzw ρ hρ0 hρd hlt hbzw)
      (Carg (Cmul (Cneg z) w) kp hkp ρ hρ0 hρd hlt hbp) :=
    Carg_congr hkzw hkp ρ hρ0 hρd hlt hρ2 hbzw hbp (Cneg_Cmul_left z w)
  -- Carg((−z)w) ≈ Carg(−z) + Carg w   (principal additivity, both factors right half-plane)
  have hadd := Carg_add (Cneg z) w knz hknz kw hkw kp hkp ρ
    hρ0 hρd hlt hlt16 h2ρ hhalf hρ4 hρ2 hρ8 hρ1 hbnz hbw hbp hbvv
  -- CargLeft(zw) = Carg(−(zw)) + π ≈ (Carg(−z) + Carg w) + π
  show Req (Radd (Carg (Cneg (Cmul z w)) kzw hkzw ρ hρ0 hρd hlt hbzw) Rpi_full)
    (Radd (Radd (Carg (Cneg z) knz hknz ρ hρ0 hρd hlt hbnz) Rpi_full)
      (Carg w kw hkw ρ hρ0 hρd hlt hbw))
  refine Req_trans (Radd_congr (Req_trans hcong hadd) (Req_refl Rpi_full)) ?_
  -- (A + B) + π ≈ (A + π) + B   (regroup: A = Carg(−z), B = Carg w, C = π)
  refine Req_trans (Radd_assoc (Carg (Cneg z) knz hknz ρ hρ0 hρd hlt hbnz)
    (Carg w kw hkw ρ hρ0 hρd hlt hbw) Rpi_full) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (Radd_comm (Carg w kw hkw ρ hρ0 hρd hlt hbw) Rpi_full)) ?_
  exact Req_symm (Radd_assoc (Carg (Cneg z) knz hknz ρ hρ0 hρd hlt hbnz) Rpi_full
    (Carg w kw hkw ρ hρ0 hρd hlt hbw))

end UOR.Bridge.F1Square.Analysis
