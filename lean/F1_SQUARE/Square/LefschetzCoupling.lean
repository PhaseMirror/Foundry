/-
F1 square — v0.21.0 stage G, brick **Lefschetz coupling**: the primitive-part / Lefschetz
refinement of the crux, and the archimedean coupling whose sign is the tail bound.

Understanding the Atlas (its definite norm beside its indefinite spectral form, §9/§5) showed the
crux is NOT whole-form positive-definiteness but the **Hodge-index signature**: a polarization `H`
with `H² > 0`, and negative-semidefiniteness on the primitive complement `H^⊥` — exactly the shape
`BridgeFF.ff_hodge_iff_hasse` proves for the curve (`∀-neg on the primitive {Δ,Γ}-span ⟺ a² ≤ 4q`).
This brick makes that explicit over ℤ:

- **The Lefschetz signature.** The polarization `H = F_h + F_v = (1,1,0,0)` has `H² = 2 > 0`
  (`eH_sq_pos`), and the vanishing cycle `Cₙ = Δ−Γ` is PRIMITIVE — orthogonal to `H`
  (`vanCyc_perp_H`, from `vanCyc_perp_Fh/Fv` and bilinearity). So the spectral classes live in
  `H^⊥`, and the crux `⟨Cₙ,Cₙ⟩ ≤ 0 ∀n` is exactly Hodge-index negativity on the primitive part —
  the `ff_hodge_iff_hasse` shape.

- **The archimedean coupling (the slack).** Over a curve the primitive negativity's slack is
  `(4q − a²) ≥ 0`, supplied by `q`. Over ℤ there is no `q`: the slack is `λₙ`, and `λₙ` splits as
  the prime/finite-place side plus the archimedean side (`genuineLamSeq = genuineArithSeq +
  genuineArchSeq`, the BL/explicit-formula decomposition). So **the crux is exactly the sign of the
  prime–archimedean coupling** (`genuine_crux_arch_coupling`): `⟨Cₙ,Cₙ⟩ ≤ 0 ⟺ arith(n)+arch(n) ≥ 0`.
  That sign — the coupling of the built prime side (`Mangoldt`/the addressing skeleton) to the built
  archimedean place (`Pairing`/`ArchTrend`) — is the uniform tail bound, governed by the zeros. It
  is the one open content; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.Forced

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis
open UOR.Bridge.F1Square.Li

-- ===========================================================================
-- The Lefschetz signature: polarization H² > 0, vanishing cycle primitive (in H^⊥).
-- ===========================================================================

/-- The polarization `H = F_h + F_v = (1,1,0,0)` (the ample class). -/
def eH : HCls := (1, 1, 0, 0)

/-- **The vanishing cycle is PRIMITIVE — orthogonal to the polarization `H`**: `⟨Δ−Γ, H⟩ = 0`, for
    every spectral datum (from `vanCyc_perp_Fh/Fv` and bilinearity). So the spectral classes lie in
    `H^⊥`, and the crux is Hodge-index negativity on the primitive part. -/
theorem vanCyc_perp_H (dd gg dg : Real) : Req (hPair dd gg dg vanCyc eH) zero := by
  simp only [hPair]
  rw [zmulR_congr_coeff (show hRuling vanCyc eH = 0 by decide) one,
      zmulR_congr_coeff (show vanCyc.2.2.1 * eH.2.2.1 = 0 by decide) dd,
      zmulR_congr_coeff (show vanCyc.2.2.2 * eH.2.2.2 = 0 by decide) gg,
      zmulR_congr_coeff (show vanCyc.2.2.1 * eH.2.2.2 + vanCyc.2.2.2 * eH.2.2.1 = 0 by decide) dg,
      zmulR_zero, zmulR_zero, zmulR_zero, zmulR_zero]
  exact Req_trans (Radd_zero _) (Req_trans (Radd_zero _) (Radd_zero zero))

/-- **The polarization self-pairing `H² = 2`** (the rulings only; independent of the spectral data):
    `⟨F_h+F_v, F_h+F_v⟩ = 2`. -/
theorem eH_sq (dd gg dg : Real) : Req (hPair dd gg dg eH eH) (zmulR 2 one) := by
  simp only [hPair]
  rw [zmulR_congr_coeff (show hRuling eH eH = 2 by decide) one,
      zmulR_congr_coeff (show eH.2.2.1 * eH.2.2.1 = 0 by decide) dd,
      zmulR_congr_coeff (show eH.2.2.2 * eH.2.2.2 = 0 by decide) gg,
      zmulR_congr_coeff (show eH.2.2.1 * eH.2.2.2 + eH.2.2.2 * eH.2.2.1 = 0 by decide) dg,
      zmulR_zero, zmulR_zero, zmulR_zero]
  exact Req_trans (Radd_zero _) (Req_trans (Radd_zero _) (Radd_zero _))

/-- **`H² > 0`** — the polarization is positive (`2 = 1 + 1 > 0`), the `(1, ·)` part of the
    Lefschetz signature. -/
theorem eH_sq_pos (dd gg dg : Real) : Pos (hPair dd gg dg eH eH) :=
  Pos_congr (Req_symm (eH_sq dd gg dg)) (Pos_Radd_self Pos_one)

-- ===========================================================================
-- The archimedean coupling: the crux is the sign of arith + arch.
-- ===========================================================================

/-- **THE CRUX IS THE PRIME–ARCHIMEDEAN COUPLING SIGN.** Through the dictionary `⟨Cₙ,Cₙ⟩ = −2λₙ` and
    the explicit-formula split `λₙ = arith(n) + arch(n)`, the crux is exactly: the coupling of the
    built prime/finite-place side and the built archimedean side is nonnegative for all `n`. This is
    the arithmetic analog of `ff_hodge_iff_hasse`'s `(4q − a²) ≥ 0` — the slack, here supplied by the
    coupling rather than by `q`. Its sign is the uniform tail bound, governed by the zeros; never
    asserted. -/
theorem genuine_crux_arch_coupling (E : StieltjesEta) :
    SpectralCrux (genuineSpectralSquare E) ↔
      ∀ n, 0 < n → Pos (Radd (genuineArithSeq E.eta n) (genuineArchSeq n)) :=
  genuine_crux_frontier E

/-- **THE CRUX AS THE ARITHMETIC HODGE-INDEX STATEMENT** (the refinement, bundled): the polarization
    is positive (`H² > 0`, `eH_sq_pos`), the spectral classes are primitive (`vanCyc_perp_H`), and
    the primitive-part negativity ⟺ the prime–archimedean coupling sign
    (`genuine_crux_arch_coupling`). This is `BridgeFF.ff_hodge_iff_hasse`'s Lefschetz shape over ℤ,
    with the slack relocated from `q` to the coupling. The coupling's sign is the open content; the
    crux fields stay `none`. -/
theorem crux_is_arithmetic_hodge :
    (∀ dd gg dg : Real, Req (hPair dd gg dg vanCyc eH) zero)
    ∧ (∀ dd gg dg : Real, Pos (hPair dd gg dg eH eH))
    ∧ (∀ E : StieltjesEta, SpectralCrux (genuineSpectralSquare E) ↔
        ∀ n, 0 < n → Pos (Radd (genuineArithSeq E.eta n) (genuineArchSeq n))) :=
  ⟨vanCyc_perp_H, eH_sq_pos, genuine_crux_arch_coupling⟩

end UOR.Bridge.F1Square.Square
