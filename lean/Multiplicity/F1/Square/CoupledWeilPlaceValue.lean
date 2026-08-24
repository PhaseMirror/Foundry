/-
F1 square — **grounding the coupled kernel's `v` in genuine test place-values** (`CoupledWeilPlaceValue.lean`):
the coupled Weil kernel's prime side `primeGram w v M` takes interface data `v m i`. This file supplies,
for that slot, the genuine per-place data of real `WeilTest` functions — DEFINITIONALLY — so the prime
weight and the per-place ingredient are the ACTUAL built objects, not abstract placeholders.

The built finite-place term (`Analysis.Weil`) is `weilPrimeTerm T n = Λ(n+1)·(f(n+1) + (n+1)⁻¹f(1/(n+1)))`.
Its second factor is the genuine PER-PLACE POINT VALUE of the test; extracting it as `placeVal T n`
gives, by definition, `weilPrimeTerm T n = Λ(n+1)·placeVal T n` (`weilPrimeTerm_eq_placeVal`, `rfl`) and
`weilPrimePart T = Σ_m Λ(m+1)·placeVal T m` (`weilPrimePart_eq_placeVal_sum`). Feeding these real
place-values into the coupled kernel — `vFrom g m i = placeVal (g i) m` — makes the prime Gram a
CONCRETE bilinear form with the genuine von Mangoldt weight and real per-place values throughout:
    `weilPrimeGram (vFrom g) M (i,j) = Σ_m Λ(m+1)·placeVal(g i, m)·placeVal(g j, m)`,
UNCONDITIONALLY PSD (`weilPrimeGram_vFrom_psd`) and symmetric in `i, j` (`primeGram_vFrom_sym`).

HONEST SCOPE — read carefully, the semantics are only PARTIALLY grounded. What IS definitional: the
weight is the built `vonMangoldt`, and `placeVal` IS the factor of the built `weilPrimeTerm` (a genuine
per-place POINT value of the test). What is NOT justified here: that this point-value data `placeVal` is
the correct `v` for the coupled kernel. The coupled kernel intends `v m i = ĝ_i(m)`, a MELLIN-TRANSFORM
value, because only for the transform does convolution factor as a product, giving
`W_prime(g_i ⋆ g_j^τ) = Σ_m Λ(m)·ĝ_i(m)·ĝ_j(m)`; the Weil prime side sums POINT values `f(m)`, and the
point value of an autocorrelation `(g ⋆ g^τ)(m)` is NOT `placeVal(g,m)²`. So `weilPrimeGram (vFrom g) M`
is a concrete, real-data instance of the prime-Gram STRUCTURE — NOT proven equal to the autocorrelation
prime side `weilPrimePart (g_i ⋆ g_j^τ)`. Bridging that (identifying `v` with the transform, via the
convolution/Mellin theorem and the test convolution `⋆`) is the unbuilt link, honestly open. NOTHING
asserts positivity of the coupled form; the crux stays `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1.Square.CoupledWeilKernel
import Multiplicity.F1.Analysis.Weil

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The **genuine per-place value** of a Weil test: `placeVal T n = f(n+1) + (n+1)⁻¹·f(1/(n+1))` — the
    second factor of the built `weilPrimeTerm` (the `Λ`-free part of the finite-place term). -/
def placeVal (T : WeilTest) (n : Nat) : Real :=
  Radd (T.f ⟨((n + 1 : Nat) : Int), 1⟩)
    (Rmul (ofQ ⟨1, n + 1⟩ (Nat.succ_pos n)) (T.f ⟨1, n + 1⟩))

/-- **The built term factors through `placeVal`** (definitional): `weilPrimeTerm T n = Λ(n+1)·placeVal T n`
    — so `placeVal` is exactly the genuine per-place value carried by the Weil prime side. -/
theorem weilPrimeTerm_eq_placeVal (T : WeilTest) (n : Nat) :
    weilPrimeTerm T n = Rmul (vonMangoldt (n + 1)) (placeVal T n) := rfl

/-- **The built prime side in place-value form**: `weilPrimePart T = Σ_{m<X} Λ(m+1)·placeVal T m`. -/
theorem weilPrimePart_eq_placeVal_sum (T : WeilTest) :
    weilPrimePart T = RsumN (fun m => Rmul (vonMangoldt (m + 1)) (placeVal T m)) T.X := rfl

/-- The coupled kernel's interface `v`, **fed genuine test place-values**: `vFrom g m i = placeVal (g i) m`. -/
def vFrom (g : Nat → WeilTest) : Nat → Nat → Real :=
  fun m i => placeVal (g i) m

/-- **The prime Gram on a genuine test family, explicitly**: `primeGram (Λ∘succ) (vFrom g) M (i,j) =
    Σ_{m<M} Λ(m+1)·placeVal(g i, m)·placeVal(g j, m)` — the concrete prime Gram with the real von
    Mangoldt weight and real place-values (a real-data instance of the prime-Gram structure). -/
theorem primeGram_vFrom_apply (g : Nat → WeilTest) (M i j : Nat) :
    primeGram (fun m => vonMangoldt (m + 1)) (vFrom g) M i j
      = RsumN (fun m => Rmul (vonMangoldt (m + 1))
          (Rmul (placeVal (g i) m) (placeVal (g j) m))) M := rfl

/-- **The genuine prime Gram on real tests is UNCONDITIONALLY PSD** — the von Mangoldt instance
    (`WeilPSD_weilPrimeGram`) at real place-value data. -/
theorem weilPrimeGram_vFrom_psd (g : Nat → WeilTest) (M : Nat) :
    WeilPSD (weilPrimeGram (vFrom g) M) :=
  WeilPSD_weilPrimeGram (vFrom g) M

/-- **Symmetry of the prime Gram at real place-value data**: `weilPrimeGram (vFrom g) M (i,j) ≈
    weilPrimeGram (vFrom g) M (j,i)` — symmetric in the two test indices (`primeGram_sym`). -/
theorem primeGram_vFrom_sym (g : Nat → WeilTest) (M i j : Nat) :
    Req (weilPrimeGram (vFrom g) M i j) (weilPrimeGram (vFrom g) M j i) :=
  primeGram_sym (fun m => vonMangoldt (m + 1)) (vFrom g) M i j

end Multiplicity.UOR.Bridge.F1Square.Square
