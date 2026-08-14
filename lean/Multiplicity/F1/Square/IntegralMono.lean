/-
F1 square — **pointwise-domination monotonicity of the L² pairing** (`IntegralMono.lean`).

If a test `ψ` is dominated in absolute value by `g` on `[0,1]` and the second slot `χ` is
nonnegative there, then the pairing is dominated:

    `|⟨ψ,χ⟩| ≤ ⟨g,χ⟩`   (`innerI_abs_le_mono`).

The pairing `⟨φ,ψ⟩ = ∫₀¹ φ·ψ` is the certified integral of the product, so both directions
(`⟨ψ,χ⟩ ≤ ⟨g,χ⟩` and `−⟨ψ,χ⟩ ≤ ⟨g,χ⟩`) are unit-local integral-monotonicity facts
(`riemannIntegral_le_unit`). The obstacle is that `⟨ψ,χ⟩` and `⟨g,χ⟩` carry DIFFERENT product
moduli (`l2L ψ χ` vs `l2L g χ`); both are weakened to the common modulus `l2L ψ χ + l2L g χ`
via `lip_weaken`, and the integral is realigned to the honest pairing values by certificate
independence (`riemannIntegral_certif_irrel`) — the same certificate-weakening plumbing as the
Bernstein energy bound. Pointwise, `ψ(x)·χ(x) ≤ |ψ(x)|·χ(x) ≤ g(x)·χ(x)` and the mirror
`−g(x)·χ(x) ≤ ψ(x)·χ(x)` hold from `χ(x) ≥ 0`; the negative branch is landed through
`innerI_neg_left` and `Rle_Rneg`, then combined by `Rabs_le_of_both`.

HONEST SCOPE. A pointwise-domination monotonicity bound for the L² pairing over the certified
integral, on the bounded-Lipschitz test class. General infrastructure for the Durrmeyer
convergence estimate; NOT convergence, NOT inversion, NOT positivity. Step 4 is RH; crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.IntegralInner
import Multiplicity.F1Square.Analysis.IntegralLocal
import Multiplicity.F1Square.Analysis.IntegralCertIrrel
import Multiplicity.F1Square.Analysis.IntegralBilinear
import Multiplicity.F1Square.Square.PairingLimitI

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Pointwise-domination monotonicity of the L² pairing**: if `|ψ| ≤ g` and `χ ≥ 0` on `[0,1]`,
    then `|⟨ψ,χ⟩| ≤ ⟨g,χ⟩`. Both `±⟨ψ,χ⟩ ≤ ⟨g,χ⟩` are unit-local integral-monotonicity facts at
    the common weakened modulus `l2L ψ χ + l2L g χ`; certificate independence realigns the
    integrals to the honest pairing values, and `Rabs_le_of_both` assembles the two branches. -/
theorem innerI_abs_le_mono (ψ χ g : L2Test)
    (hg : ∀ x, Rle zero x → Rle x one → Rle (Rabs (ψ.f x)) (g.f x))
    (hχ : ∀ x, Rle zero x → Rle x one → Rnonneg (χ.f x)) :
    Rle (Rabs (innerI ψ χ)) (innerI g χ) := by
  -- The common weakened modulus `L := l2L ψ χ + l2L g χ` covering both pairings.
  have hLd : 0 < (add (l2L ψ χ) (l2L g χ)).den := add_den_pos (l2L_den ψ χ) (l2L_den g χ)
  have hLn : 0 ≤ (add (l2L ψ χ) (l2L g χ)).num := Qadd_num_nonneg_loc (l2L_num ψ χ) (l2L_num g χ)
  -- Weaken the three product Lipschitz certificates to `L`.
  have hlipψ := lip_weaken (l2L_den ψ χ) hLd (Qle_self_add (l2L_num g χ)) (l2lip ψ χ)
  have hlipg := lip_weaken (l2L_den g χ) hLd (Qle_self_add_l (l2L_num ψ χ)) (l2lip g χ)
  have hlipNg := lip_weaken (l2L_den (L2Test.neg g) χ) hLd
    (Qle_self_add_l (l2L_num ψ χ)) (l2lip (L2Test.neg g) χ)
  -- Certificate independence: the weakened integrals ARE the honest pairing values.
  have certψ : Req (innerI ψ χ) (riemannIntegral hLd hLn hlipψ (l2fc ψ χ)) :=
    riemannIntegral_certif_irrel (l2L_den ψ χ) (l2L_num ψ χ) (l2lip ψ χ) (l2fc ψ χ)
      hLd hLn hlipψ (l2fc ψ χ)
  have certg : Req (innerI g χ) (riemannIntegral hLd hLn hlipg (l2fc g χ)) :=
    riemannIntegral_certif_irrel (l2L_den g χ) (l2L_num g χ) (l2lip g χ) (l2fc g χ)
      hLd hLn hlipg (l2fc g χ)
  have certNg : Req (innerI (L2Test.neg g) χ)
      (riemannIntegral hLd hLn hlipNg (l2fc (L2Test.neg g) χ)) :=
    riemannIntegral_certif_irrel (l2L_den (L2Test.neg g) χ) (l2L_num (L2Test.neg g) χ)
      (l2lip (L2Test.neg g) χ) (l2fc (L2Test.neg g) χ) hLd hLn hlipNg (l2fc (L2Test.neg g) χ)
  -- Positive branch: `⟨ψ,χ⟩ ≤ ⟨g,χ⟩`, from `ψ(x)·χ(x) ≤ |ψ(x)|·χ(x) ≤ g(x)·χ(x)`.
  have h1 : Rle (innerI ψ χ) (innerI g χ) :=
    Rle_trans (Rle_of_Req certψ)
      (Rle_trans (riemannIntegral_le_unit hLd hLn hlipψ (l2fc ψ χ) hlipg (l2fc g χ)
          (fun x h0 h1x => Rmul_le_Rmul_right (hχ x h0 h1x)
            (Rle_trans (Rle_Rabs_self (ψ.f x)) (hg x h0 h1x))))
        (Rle_of_Req (Req_symm certg)))
  -- Negative branch: `⟨−g,χ⟩ ≤ ⟨ψ,χ⟩`, from `−g(x)·χ(x) ≤ −|ψ(x)|·χ(x) ≤ ψ(x)·χ(x)`.
  have monoA : Rle (riemannIntegral hLd hLn hlipNg (l2fc (L2Test.neg g) χ))
      (riemannIntegral hLd hLn hlipψ (l2fc ψ χ)) :=
    riemannIntegral_le_unit hLd hLn hlipNg (l2fc (L2Test.neg g) χ) hlipψ (l2fc ψ χ)
      (fun x h0 h1x => Rmul_le_Rmul_right (hχ x h0 h1x)
        (Rle_trans (Rle_Rneg (hg x h0 h1x))
          (Rneg_le_of_Rabs_le (Rle_refl (Rabs (ψ.f x))))))
  have hA : Rle (innerI (L2Test.neg g) χ) (innerI ψ χ) :=
    Rle_trans (Rle_of_Req certNg) (Rle_trans monoA (Rle_of_Req (Req_symm certψ)))
  -- Turn `⟨−g,χ⟩ ≤ ⟨ψ,χ⟩` into `−⟨ψ,χ⟩ ≤ ⟨g,χ⟩` via `innerI_neg_left` and `Rle_Rneg`.
  have hstep : Rle (Rneg (innerI g χ)) (innerI ψ χ) :=
    Rle_trans (Rle_of_Req (Req_symm (innerI_neg_left g χ))) hA
  have h2 : Rle (Rneg (innerI ψ χ)) (innerI g χ) :=
    Rle_trans (Rle_Rneg hstep) (Rle_of_Req (Rneg_Rneg (innerI g χ)))
  exact Rabs_le_of_both h1 h2

end Multiplicity.UOR.Bridge.F1Square.Square
