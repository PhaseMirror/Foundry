/-
F1 square — **the atlas smooth facet reproduces the `n log n` growth class, quantitatively**
(`AtlasGrowth.lean`). `AtlasGenerator.lean` invented the zero-free, atlas-intrinsic candidate diagonal
`atlasShiftDiag n = Σ_{k<n} log(k+2)` from the Frobenius-orbit shift lengths, and showed each step past
`n = 2` adds `≥ 1` (`atlasShiftDiag_step_ge_one`) — hence merely UNBOUNDED (a *linear* lower bound). The
growth filter the certificate route needs is sharper: `2λₙ ~ n log n` (cited in the program, load-bearing
for the finite-rank fence and the angle-density obligation, but not proven in-repo). This file supplies
the atlas facet's matching SUPER-LINEAR growth.

`atlasShiftDiag_double_ge`: over a doubling window `[n, 2n)`, the candidate grows by at least `n·log(n+2)`,

    `atlasShiftDiag (n + n) ≥ atlasShiftDiag n + n · log(n+2)`.

The window has `n` terms `log(n+i+2)` (`i < n`), each `≥ log(n+2)` by monotonicity of `log`, so the
increment is `≥ n·log(n+2)` — an increment that grows FASTER than any constant multiple of `n`. That is
the `n log n` growth CLASS (not the mere `step ≥ 1` unboundedness), reproduced by the atlas-intrinsic
smooth facet with no zeros and no `λ`.

HONEST SCOPE. This is a zero-free, atlas-intrinsic GROWTH-CLASS calibration of the candidate diagonal —
the necessary-condition side (§7/§8, Stage 0) that the candidate survives quantitatively, not just
qualitatively. It does NOT connect `atlasShiftDiag` to the genuine `2λₙ` (that exact identity is Gate A /
RH, and is not asserted — the candidate is a growing SMOOTH sum, while `2λₙ` also carries the arithmetic
prime side), and it establishes NO positivity. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.AtlasGenerator
import Multiplicity.F1.Square.MomentNorm

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The atlas candidate grows by `≥ n·log(n+2)` over each doubling window** — the `n log n` growth
    class, quantitatively. `atlasShiftDiag (n+n) = atlasShiftDiag n + Σ_{i<n} log(n+i+2)`
    (`RsumN_split_at`), and each of the `n` window terms `log(n+i+2) ≥ log(n+2)` (`logN_mono`), so the
    window sum `≥ n·log(n+2)` (`RsumN_const` + `RsumN_le`). Super-linear: the per-doubling increment
    `n·log(n+2)` outgrows every `c·n`, matching the `2λₙ ~ n log n` class — atlas-intrinsically,
    zero-free. This is the necessary growth-filter side; the exact `= 2λₙ` identity is RH, not asserted. -/
theorem atlasShiftDiag_double_ge (n : Nat) :
    Rle (Radd (atlasShiftDiag n) (Rmul (RofNat n) (logN (n + 2) (by omega))))
        (atlasShiftDiag (n + n)) := by
  have hsplit : Req (atlasShiftDiag (n + n))
      (Radd (atlasShiftDiag n) (RsumN (fun i => shiftLen (n + i)) n)) :=
    RsumN_split_at shiftLen n n
  have hwin : Rle (Rmul (RofNat n) (logN (n + 2) (by omega)))
      (RsumN (fun i => shiftLen (n + i)) n) := by
    refine Rle_trans (Rle_of_Req (Req_symm (RsumN_const (logN (n + 2) (by omega)) n))) ?_
    refine RsumN_le n (fun i _ => ?_)
    show Rle (logN (n + 2) (by omega)) (logN (n + i + 2) (by omega))
    exact logN_mono (by omega) (by omega)
  exact Rle_trans (Radd_le_add (Rle_refl (atlasShiftDiag n)) hwin)
    (Rle_of_Req (Req_symm hsplit))

end Multiplicity.UOR.Bridge.F1Square.Square
