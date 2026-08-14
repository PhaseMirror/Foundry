/-
F1 square — **the completed L² space, with limit members** (`L2ElementSpace.lean`), the completion axis.
`L2Complete.lean` extended the pairing along an L²-Cauchy sequence of tests (`pairingIU`) but produced only
pairing *values* — "no limit member". This brick packages the Cauchy sequence itself as a first-class
**limit member** object:

  `structure L2Elt where seq : Nat → L2Test; cauchy : L2CauchyU seq`

with the extended pairing as a method (`L2Elt.pairing`), the limit **moment sequence** (`L2Elt.moment`), a
faithful embedding of every test (`L2Elt.of`, the constant sequence), the convergence of the sequence to
its limit member (`L2Elt_converges`, weak/pairing), and the equivalence of members (`L2Elt.eq` = same
pairing against every test, a genuine equivalence). For an embedded test the reconstruction closes the
loop: `durrOpMom (L2Elt.of φ).moment` recovers `φ` (`L2Elt_of_reconstruct`).

A Bishop-style completion — a setoid, NOT a `Quotient`: the pairing value is a `Real` that is only
`Req`-well-defined (not `Eq`), so `Quotient.liftOn` cannot carry it; the equivalence `L2Elt.eq` lives
alongside the carrier instead, and every operation is proved to respect it.

HONEST SCOPE. The limit member as an object, its pairing/moment methods, the test embedding, and weak
(pairing) convergence to it. It is NOT a norm-limit *function* (L² convergence is not pointwise), and the
reconstruction of an ARBITRARY L² element (a non-Lipschitz limit) is NOT provided — only of embedded tests,
where `durrOpMom` converges. NOT positivity. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.L2Complete
import Multiplicity.F1Square.Square.MomentInversionRaw

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **A COMPLETED L² ELEMENT**: an L²-Cauchy sequence of tests, bundled with its Cauchy certificate —
    the limit member `L2Complete` left implicit. -/
structure L2Elt where
  seq : Nat → L2Test
  cauchy : L2CauchyU seq

/-- The extended pairing of a limit member against a test (`= lim_j ⟨seqⱼ, ψ⟩`). -/
def L2Elt.pairing (E : L2Elt) (ψ : L2Test) : Real := pairingIU E.seq ψ E.cauchy

/-- The limit member's moment sequence, `n ↦ ⟨E, xⁿ⟩` — its transform-side data. -/
def L2Elt.moment (E : L2Elt) (n : Nat) : Real := E.pairing (powTest n)

/-- **The embedding of a test** as the constant sequence's limit member. -/
def L2Elt.of (φ : L2Test) : L2Elt := ⟨fun _ => φ, L2CauchyU_const φ⟩

/-- **THE EMBEDDING IS FAITHFUL**: the embedded test's pairing is the honest `L²` pairing. -/
theorem L2Elt_of_pairing (φ ψ : L2Test) : Req ((L2Elt.of φ).pairing ψ) (innerI φ ψ) :=
  pairingIU_const φ ψ

/-- The embedded test's limit moments are its actual moments. -/
theorem L2Elt_of_moment (φ : L2Test) (n : Nat) : Req ((L2Elt.of φ).moment n) (mellinMoment φ n) :=
  L2Elt_of_pairing φ (powTest n)

/-- **THE SEQUENCE CONVERGES TO ITS LIMIT MEMBER** (weak/pairing): reading `E.seq` along the
    `ψ`-rescale, `⟨E.seqⱼ, ψ⟩ → E.pairing ψ` at rate `2/(j+1)`. This is the sense in which the limit
    member is the limit of the sequence — `L2Complete`'s pairing values, now convergence to an object. -/
theorem L2Elt_converges (E : L2Elt) (ψ : L2Test) (j : Nat) :
    Rle (Rabs (Rsub (innerI (E.seq (selfBnd ψ * (j + 1))) ψ) (E.pairing ψ)))
      (ofQ (⟨2, j + 1⟩ : Q) (Nat.succ_pos j)) :=
  pairingIU_dist E.seq ψ E.cauchy j

/-- **RECONSTRUCTION OF AN EMBEDDED TEST FROM ITS LIMIT MOMENTS**: `durrOpMom` applied to the limit
    member's moment sequence recovers the test on `[0,1]`, at the certified rate `φ.L/(k+3)`. -/
theorem L2Elt_of_reconstruct (φ : L2Test) (x : Real) (h0 : Rle zero x) (h1 : Rle x one) (k : Nat) :
    Rle (Rabs (Rsub (durrOpMom (L2Elt.of φ).moment ((k + 3) * (k + 3) - 2) x) (φ.f x)))
        (ofQ (mul φ.L (⟨1, k + 3⟩ : Q)) (Qmul_den_pos φ.hLd (Nat.succ_pos (k + 2)))) := by
  have hcongr : Req (durrOpMom (L2Elt.of φ).moment ((k + 3) * (k + 3) - 2) x)
      (durrOpMom (mellinMoment φ) ((k + 3) * (k + 3) - 2) x) :=
    durrOpMom_congr (fun n => L2Elt_of_moment φ n) ((k + 3) * (k + 3) - 2) x
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr hcongr (Req_refl _)))) ?_
  exact durrOpMom_converges φ x h0 h1 k

/-- **EQUALITY OF LIMIT MEMBERS**: two are equal iff they pair identically against every test —
    the constructive `L²` identification (the null relation is agreement of the pairing functional). -/
def L2Elt.eq (E F : L2Elt) : Prop := ∀ ψ : L2Test, Req (E.pairing ψ) (F.pairing ψ)

theorem L2Elt_eq_refl (E : L2Elt) : E.eq E := fun _ => Req_refl _

theorem L2Elt_eq_symm {E F : L2Elt} (h : E.eq F) : F.eq E := fun ψ => Req_symm (h ψ)

theorem L2Elt_eq_trans {E F G : L2Elt} (h₁ : E.eq F) (h₂ : F.eq G) : E.eq G :=
  fun ψ => Req_trans (h₁ ψ) (h₂ ψ)

end Multiplicity.UOR.Bridge.F1Square.Square
