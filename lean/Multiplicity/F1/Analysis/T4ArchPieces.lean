/-
F1 square — **the `t4` archimedean tail, part 1: the compact reciprocal half**
(`T4ArchPieces.lean`). The `t4` arch tail's compact piece integrand on `[1, 4]`
collapses to `2log2/(x+1) − log x/(x−1)`; this file realizes the reciprocal half as
three constructed unit-interval integrals

    `∫_c^{c+1} 2log2/(x+1) dx = ∫₀¹ t4H·(1/((c+1)+t)) dt ≈ t4H·(log(c+2) − log(c+1))`

(`c = 1, 2, 3`, so bases `2, 3, 4`), telescoping to `t4H·(log 5 − log 2)` — instances
of the real-scalar reciprocal engine (`riemannIntegral_recipC_smul`) at the weakened
modulus `L = 5` (the engine's `5(j+1) ≤ midx` schedule needs `L.num ≥ 4`; the natural
constant `2` is too small, so the certificates weaken it — `lip_mono`).

HONEST SCOPE. Three integral evaluations and their telescope; the `log x/(x−1)` half
(the dilog) and the improper remainder are the companion bricks. No slot field, no
positivity. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.T4PoleBPieces

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- The base-`b` reciprocal piece `∫₀¹ t4H/(b+t) dt`, constructed at modulus `5`. -/
def t4Trecip (b : Nat) : Real :=
  riemannIntegral (f := fun t => Rmul t4H (gRecipC b t)) (L := (⟨5, 1⟩ : Q))
    (by decide) (by decide)
    (fun x y => lip_mono (Qmul_den_pos Nat.one_pos Nat.one_pos) (by decide)
      (by decide) (Rnonneg_Rabs _)
      (smul_lip Nat.one_pos t4H_abs Nat.one_pos (by decide) (gRecipC_lip b) x y))
    (smul_congr t4H (gRecipC_congr b))

/-- `t4Trecip b ≈ t4H·(log(b+1) − log b)` for `1 ≤ b`. -/
theorem t4Trecip_eq (b : Nat) (hb : 1 ≤ b) :
    Req (t4Trecip b) (Rmul t4H (Rsub (logN (b + 1) (by omega)) (logN b hb))) :=
  riemannIntegral_recipC_smul b hb t4H (B := (⟨2, 1⟩ : Q)) (by decide) (by decide)
    t4H_abs (by decide) (by decide)
    (fun x y => lip_mono (Qmul_den_pos Nat.one_pos Nat.one_pos) (by decide)
      (by decide) (Rnonneg_Rabs _)
      (smul_lip Nat.one_pos t4H_abs Nat.one_pos (by decide) (gRecipC_lip b) x y))
    (smul_congr t4H (gRecipC_congr b))
    (fun j => by show 5 * (j + 1) ≤ 6 * (j + 1); omega)

/-- **The compact reciprocal half, telescoped**:
    `t4Trecip 2 + t4Trecip 3 + t4Trecip 4 ≈ t4H·(log 5 − log 2)`. -/
theorem t4Trecip_sum :
    Req (Radd (Radd (t4Trecip 2) (t4Trecip 3)) (t4Trecip 4))
      (Rmul t4H (Rsub (logN 5 (by omega)) (logN 2 (by omega)))) := by
  refine Req_trans (Radd_congr (Radd_congr (t4Trecip_eq 2 (by omega))
    (t4Trecip_eq 3 (by omega))) (t4Trecip_eq 4 (by omega))) ?_
  refine Req_trans (Radd_congr (Req_symm (Rmul_distrib t4H
    (Rsub (logN 3 (by omega)) (logN 2 (by omega)))
    (Rsub (logN 4 (by omega)) (logN 3 (by omega))))) (Req_refl _)) ?_
  refine Req_trans (Req_symm (Rmul_distrib t4H _ _)) ?_
  refine Rmul_congr (Req_refl t4H) ?_
  refine Req_trans (Radd_congr (Req_trans (Radd_comm _ _)
    (Rsub_telescope (logN 4 (by omega)) (logN 3 (by omega)) (logN 2 (by omega))))
    (Req_refl _)) ?_
  refine Req_trans (Radd_comm _ _) ?_
  exact Rsub_telescope (logN 5 (by omega)) (logN 4 (by omega)) (logN 2 (by omega))

end Multiplicity.UOR.Bridge.F1Square.Analysis
