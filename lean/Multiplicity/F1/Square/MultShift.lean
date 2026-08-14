/-
F1 square — **the multiplicative group action on tests** (`MultShift.lean`): the first structural
prerequisite of the step-3→4 transform bridge — the dilation `x ↦ a·x` that the `{n, 1/n}` point
representation (`WeilTest`) provably cannot carry, now built on the function-space `L2Test`. The Weil
`f ⋆ g^τ` co-support coupling — the genuine content of step 4 — is phrased in the multiplicative group
of `(0,∞)`, whose action on tests is exactly this dilation; the point lattice `{n, 1/n}` is not closed
under it (`a·(1/n) = a/n` leaves the lattice), which is why the coupled kernel's `v` could only ever be
grounded at the point-value level. On the genuine `L2Test` (a bounded-Lipschitz `Real → Real` with
integration certificates) the dilation IS well-defined, with its Lipschitz/bound certificates, and it
forms a group (`dilateTest_comp`, `dilateTest_one`).

  • `dilateTest a φ` — the pullback `(dilateTest a φ).f x = φ.f (a·x)`, a genuine `L2Test` (Lipschitz
    modulus `L·a`, same bound `M`).
  • `dilateTest_comp` — the GROUP LAW: `dilateTest a (dilateTest b φ) ≈ dilateTest (a·b) φ` (pointwise).
  • `dilateTest_one` — the identity `dilateTest 1 φ ≈ φ`.

HONEST SCOPE — fenced hard. This is ONLY the multiplicative group ACTION and its algebraic (group) law
on the ADDITIVE-measure `L2Test`. It is NOT Haar-invariant — `innerI φ ψ = ∫₀¹ φ·ψ` is the additive
Lebesgue measure `dt`, which is NOT dilation-invariant (the multiplicative Haar `dx/x` is unbuilt); it
is NOT the convolution `⋆`, and NOT the Mellin convolution theorem. It supplies the group action that
was the missing prerequisite — one structural notch of the deep transform bridge; Walls 1 (Haar
measure) and 2 (convolution) remain, and the whole-space positivity they would carry is step 4 = RH.
The crux stays `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Analysis.IntegralInner
import Multiplicity.F1Square.Analysis.RabsLemmas
import Multiplicity.F1Square.Analysis.RealPow
import Multiplicity.F1Square.Analysis.ExpRealAdd

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The multiplicative dilation of a test**: `(dilateTest a φ).f x = φ.f (a·x)` — the group action of
    `(0,∞)` on tests, a genuine `L2Test` (Lipschitz modulus `L·a`, bound `M`). -/
def dilateTest (a : Q) (han : 0 < a.num) (had : 0 < a.den) (φ : L2Test) : L2Test where
  f := fun x => φ.f (Rmul (ofQ a had) x)
  L := mul φ.L a
  M := φ.M
  hLd := Qmul_den_pos φ.hLd had
  hLn := Qmul_num_nonneg φ.hLn (Int.le_of_lt han)
  hMd := φ.hMd
  hMn := φ.hMn
  hbd := fun x => φ.hbd (Rmul (ofQ a had) x)
  hfc := fun x y h => φ.hfc _ _ (Rmul_congr (Req_refl (ofQ a had)) h)
  hlip := fun x y => by
    refine Rle_trans (φ.hlip (Rmul (ofQ a had) x) (Rmul (ofQ a had) y)) (Rle_of_Req ?_)
    have hdiff : Req (Rabs (Rsub (Rmul (ofQ a had) x) (Rmul (ofQ a had) y)))
        (Rmul (ofQ a had) (Rabs (Rsub x y))) :=
      Req_trans (Rabs_congr (Req_symm (Rmul_sub_distrib (ofQ a had) x y)))
        (Req_trans (Rabs_Rmul (ofQ a had) (Rsub x y))
          (Rmul_congr (Rabs_ofQ_nonneg had (Int.le_of_lt han)) (Req_refl _)))
    refine Req_trans (Rmul_congr (Req_refl (ofQ φ.L φ.hLd)) hdiff) ?_
    exact Req_trans (Req_symm (Rmul_assoc (ofQ φ.L φ.hLd) (ofQ a had) (Rabs (Rsub x y))))
      (Rmul_congr (Rmul_ofQ_ofQ φ.hLd had) (Req_refl _))

/-- **The group law**: dilating by `b` then by `a` is dilating by `a·b` —
    `dilateTest a (dilateTest b φ) ≈ dilateTest (a·b) φ` pointwise. -/
theorem dilateTest_comp (a b : Q) (han : 0 < a.num) (had : 0 < a.den)
    (hbn : 0 < b.num) (hbd : 0 < b.den) (φ : L2Test) (x : Real) :
    Req ((dilateTest a han had (dilateTest b hbn hbd φ)).f x)
        ((dilateTest (mul a b) (Int.mul_pos han hbn) (Qmul_den_pos had hbd) φ).f x) := by
  -- φ.f (b·(a·x)) ≈ φ.f ((a·b)·x)
  refine φ.hfc _ _ ?_
  refine Req_trans (Req_symm (Rmul_assoc (ofQ b hbd) (ofQ a had) x)) ?_
  refine Req_trans (Rmul_congr (Rmul_comm (ofQ b hbd) (ofQ a had)) (Req_refl x)) ?_
  exact Rmul_congr (Rmul_ofQ_ofQ had hbd) (Req_refl x)

/-- **The identity**: `dilateTest 1 φ ≈ φ` pointwise (`1·x = x`). -/
theorem dilateTest_one (φ : L2Test) (x : Real) :
    Req ((dilateTest (⟨1, 1⟩ : Q) (by decide) (by decide) φ).f x) (φ.f x) :=
  φ.hfc _ _ (Req_trans (Rmul_comm (ofQ (⟨1, 1⟩ : Q) (by decide)) x) (Rmul_one x))


/-- **The log-line pullback** `φ̃(u) = φ(eᵘ)`: sends the multiplicative half-line `(0,∞)` to the additive
    line, where the group action `x ↦ a·x` becomes the shift `u ↦ u + log a`. A plain `Real → Real`
    (NOT an `L2Test`: `RexpReal` is not globally Lipschitz), the additive-side view of a test. -/
def logPull (φ : L2Test) : Real → Real := fun u => φ.f (RexpReal u)

/-- **★ DILATION ↔ SHIFT** (integer scale): on the log line the multiplicative dilation by `n` becomes
    the additive shift by `log n` — `logPull (dilateTest n φ) u ≈ logPull φ (log n + u)`. The defining
    covariance of the multiplicative↔additive (Wall 1) bridge, tying the built group action `dilateTest`
    to the additive shift; proved from `Rexp_logN` (`eˡᵒᵍ ⁿ = n`) and `RexpReal_add` (`eˣ⁺ʸ = eˣ·eʸ`). -/
theorem logPull_dilate_shift (n : Nat) (hn : 1 ≤ n) (φ : L2Test) (u : Real) :
    Req (logPull (dilateTest (⟨(n : Int), 1⟩ : Q) (by show (0:Int) < (n:Int); omega)
          Nat.one_pos φ) u)
        (logPull φ (Radd (logN n hn) u)) :=
  φ.hfc _ _ (Req_symm (Req_trans (RexpReal_add (logN n hn) u)
    (Rmul_congr (Rexp_logN n hn) (Req_refl (RexpReal u)))))


/-- **The bridge is a homomorphism**: composing two dilations = summing two shifts — `logPull (dilateTest
    m (dilateTest n φ)) u ≈ logPull φ ((log n + log m) + u)` (two applications of `logPull_dilate_shift`
    + associativity). The multiplicative group of dilations maps to the additive group of shifts. -/
theorem logPull_dilate_shift_comp (m n : Nat) (hm : 1 ≤ m) (hn : 1 ≤ n) (φ : L2Test) (u : Real) :
    Req (logPull (dilateTest (⟨(m : Int), 1⟩ : Q) (by show (0:Int) < (m:Int); omega) Nat.one_pos
          (dilateTest (⟨(n : Int), 1⟩ : Q) (by show (0:Int) < (n:Int); omega) Nat.one_pos φ)) u)
        (logPull φ (Radd (Radd (logN n hn) (logN m hm)) u)) := by
  refine Req_trans (logPull_dilate_shift m hm
    (dilateTest (⟨(n : Int), 1⟩ : Q) (by show (0:Int) < (n:Int); omega) Nat.one_pos φ) u) ?_
  refine Req_trans (logPull_dilate_shift n hn φ (Radd (logN m hm) u)) ?_
  exact φ.hfc _ _ (RexpReal_congr (Req_symm (Radd_assoc (logN n hn) (logN m hm) u)))

end Multiplicity.UOR.Bridge.F1Square.Square
