/-
F1 square — **the pre-Hilbert layer, brick 81** (`L2DefiniteIff.lean`): **`⟨φ,φ⟩` IS A DEFINITE
INNER PRODUCT ON `[0,1]`** — the reverse of brick 79, closing the definiteness to an iff:

    `∫₀¹ φ² ≈ 0`   ⟺   `∀ x ∈ [0,1], φ(x) ≈ 0`   (`innerI_self_zero_iff_unit_zero`).

Brick 79 gave the forward direction (energy zero forces the function to vanish everywhere on
`[0,1]`). This adds the converse — a function that vanishes at every point of `[0,1]` has zero `L²`
energy — via a `[0,1]`-restricted integral argument: the certified Riemann sums sample only the
rational partition points `i/(N+1) ∈ [0,1)`, so an integrand that vanishes at every such point has
every Riemann sum zero, hence dyadic sum zero (`riemannSum_congr` + `RsumN_const`), hence the
telescoping limit zero (`genSum_telescope` + `Rlim_zero`), hence the integral zero
(`riemannIntegral_zero_of_partition_zero`). The generic congruence lemmas quantify over *all* reals
and would be unusable here (the converse is false off `[0,1]`, where the integral is blind), so the
partition-restricted version is the load-bearing new lemma.

Together the two directions say the `L²` seminorm `√⟨φ,φ⟩` is a genuine *norm* on the
bounded-Lipschitz class modulo pointwise equality on `[0,1]` — the pairing is positive-**definite**,
which is what makes the completion axis a Hilbert (not merely pre-Hilbert-semi-normed) structure.

HONEST SCOPE. Definiteness on `[0,1]` at the *point/function* level, both directions. Still NOT the
moment problem: a nonzero bounded-Lipschitz test with every *moment* vanishing is a different
question (it would need Bernstein, absent). The iff is about the value at every point, not the
moments. Nothing here touches the Weil form. Step 4 is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.DyadicDenseReal

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The certified integral of a function vanishing at every rational partition point is zero.**
    The Riemann sums sample only `i/(N+1)`, so pointwise vanishing there kills every sum, hence the
    dyadic sums, hence the telescoping limit, hence the integral. -/
theorem riemannIntegral_zero_of_partition_zero {f : Real → Real} {L : Q} (hLd : 0 < L.den)
    (hLn : 0 ≤ L.num)
    (hlip : ∀ x y, Rle (Rabs (Rsub (f x) (f y))) (Rmul (ofQ L hLd) (Rabs (Rsub x y))))
    (hfc : ∀ x y, Req x y → Req (f x) (f y))
    (hz : ∀ N i : Nat, i < N + 1 →
      Req (f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) zero) :
    Req (riemannIntegral hLd hLn hlip hfc) zero := by
  -- every Riemann sum vanishes
  have hrs : ∀ N : Nat, Req (riemannSum f N) zero := by
    intro N
    have h1 : Req (RsumN (fun i => f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))
                  (RsumN (fun _ : Nat => zero) (N + 1)) :=
      RsumN_congr (N + 1) (fun i hi => hz N i hi)
    have h2 : Req (RsumN (fun _ : Nat => zero) (N + 1)) zero :=
      Req_trans (RsumN_const zero (N + 1)) (Rmul_zero (RofNat (N + 1)))
    have h3 : Req (RsumN (fun i => f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1)) zero :=
      Req_trans h1 h2
    show Req (Rmul (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
      (RsumN (fun i => f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) (N + 1))) zero
    exact Req_trans (Rmul_congr (Req_refl _) h3) (Rmul_zero _)
  -- hence every dyadic sum
  have hdy : ∀ M : Nat, Req (dyadicR f M) zero := fun M => hrs (2 ^ M - 1)
  -- hence the telescoping increments' partial sums
  have hgs : ∀ j : Nat, Req (genSum (dyadicTerm f) (digammaMidx L j)) zero := by
    intro j
    exact Req_trans (genSum_telescope f (digammaMidx L j))
      (Req_trans (Rsub_congr (hdy _) (hdy 0)) (Radd_neg zero))
  -- assemble: riemannIntegral = D₀ + lim (Σ increments), both ≈ 0
  refine Req_trans (Radd_congr (hdy 0) (Rlim_zero _ _ hgs)) (Radd_zero zero)

/-- **THE REVERSE DIRECTION**: a test vanishing at every point of `[0,1]` has zero `L²` energy. -/
theorem innerI_self_zero_of_unit_zero (φ : L2Test)
    (hφ : ∀ x, Rle zero x → Rle x one → Req (φ.f x) zero) :
    Req (innerI φ φ) zero := by
  refine riemannIntegral_zero_of_partition_zero (l2L_den φ φ) (l2L_num φ φ)
    (l2lip φ φ) (l2fc φ φ) ?_
  intro N i hi
  have hpt : Req (φ.f (ofQ (⟨(i : Int), N + 1⟩ : Q) (Nat.succ_pos N))) zero := by
    refine hφ _ ?_ ?_
    · exact Rle_ofQ_ofQ (by decide) (Nat.succ_pos N) (by simp only [Qle]; omega)
    · exact Rle_ofQ_ofQ (Nat.succ_pos N) (by decide) (by simp only [Qle]; omega)
  exact Req_trans (Rmul_congr hpt hpt) (Rmul_zero zero)

/-- **`⟨φ,φ⟩` IS DEFINITE ON `[0,1]`**: `∫₀¹ φ² ≈ 0` iff `φ` vanishes at every point of `[0,1]` —
    brick 79 forward, this brick's reverse. -/
theorem innerI_self_zero_iff_unit_zero (φ : L2Test) :
    Req (innerI φ φ) zero ↔ ∀ x, Rle zero x → Rle x one → Req (φ.f x) zero :=
  ⟨fun h x h0 h1 => innerI_self_zero_imp_zero φ h x h0 h1, innerI_self_zero_of_unit_zero φ⟩

end Multiplicity.UOR.Bridge.F1Square.Square
