/-
F1 square — **the pre-Hilbert layer, brick 85** (`CoSupportPairwise.lean`): **THE THREE FLAGSHIP
LEVEL-3 MEMBERS ARE PAIRWISE-DISTINCT FUNCTIONS ON `[0,1]`** — completing brick 84's technique
across all three pairs, so the moment-table independence (`deep345_independent`) is fully upgraded
to a function-level statement for the realized members.

Each pair differs in an explicit moment, which brick 84's bridge (`distinct_on_unit_of_moment_ne`)
turns into function-level distinctness:

    `deep3` vs `deep4` : `⟨·, x³⟩` is `−1/2520` vs `0`    (`deep3_deep4_distinct_on_unit`, brick 84)
    `deep3` vs `deep5` : `⟨·, x³⟩` is `−1/2520` vs `0`    (`deep3_deep5_distinct_on_unit`)
    `deep4` vs `deep5` : `⟨·, x⁴⟩` is `1/13860` vs `0`   (`deep4_deep5_distinct_on_unit`)

bundled as `deep345_pairwise_distinct_on_unit`. `deep5` (co-support level 5) vanishes through the
fourth moment, so it is separated from `deep3` (level 3, first nonzero moment at index 3) already at
index 3, and from `deep4` (level 4, first nonzero at index 4) at index 4.

HONEST SCOPE. Pairwise distinctness — each pair does **not** agree everywhere on `[0,1]` (the
constructive negation, not a constructed point of disagreement). This is weaker than function-level
linear independence of the triple (which would rule out every nontrivial `ℕ`-combination vanishing,
and for the `a = 0` combinations is not covered here). Realized members only. Nothing here touches
the Weil form; the co-support skeleton's positivity is still diagonal-multiplier level. Step 4 is RH.
The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.CoSupportDistinct
import Multiplicity.F1.Square.DeepMemberFive

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **`deep3` AND `deep5` ARE DISTINCT FUNCTIONS ON `[0,1]`** — they differ in the third moment
    (`−1/2520` vs `0`). -/
theorem deep3_deep5_distinct_on_unit :
    ¬ (∀ x, Rle zero x → Rle x one → Req (deep3.f x) (deep5.f x)) := by
  refine distinct_on_unit_of_moment_ne deep3 deep5 3 ?_
  intro hm
  have hval : Req (mellinMoment (L2Test.sub deep3 deep5) 3) (ofQ (⟨-1, 2520⟩ : Q) (by decide)) :=
    Req_trans (innerI_sub_left deep3 deep5 (powTest 3))
      (Req_trans (Rsub_congr deep3_moment_three deep5_moment_three) (Rsub_zero _))
  exact absurd ((Req_trans (Req_symm hval) hm) 5040) (by decide)

/-- **`deep4` AND `deep5` ARE DISTINCT FUNCTIONS ON `[0,1]`** — they differ in the fourth moment
    (`1/13860` vs `0`). -/
theorem deep4_deep5_distinct_on_unit :
    ¬ (∀ x, Rle zero x → Rle x one → Req (deep4.f x) (deep5.f x)) := by
  refine distinct_on_unit_of_moment_ne deep4 deep5 4 ?_
  intro hm
  have hval : Req (mellinMoment (L2Test.sub deep4 deep5) 4) (ofQ (⟨1, 13860⟩ : Q) (by decide)) :=
    Req_trans (innerI_sub_left deep4 deep5 (powTest 4))
      (Req_trans (Rsub_congr deep4_moment_four deep5_moment_four) (Rsub_zero _))
  exact absurd ((Req_trans (Req_symm hval) hm) 27720) (by decide)

/-- **THE THREE FLAGSHIP LEVEL-3 MEMBERS ARE PAIRWISE-DISTINCT FUNCTIONS ON `[0,1]`** — the
    moment-table independence upgraded to function level, for the realized triple. -/
theorem deep345_pairwise_distinct_on_unit :
    (¬ (∀ x, Rle zero x → Rle x one → Req (deep3.f x) (deep4.f x))) ∧
    (¬ (∀ x, Rle zero x → Rle x one → Req (deep3.f x) (deep5.f x))) ∧
    (¬ (∀ x, Rle zero x → Rle x one → Req (deep4.f x) (deep5.f x))) :=
  ⟨deep3_deep4_distinct_on_unit, deep3_deep5_distinct_on_unit, deep4_deep5_distinct_on_unit⟩

end Multiplicity.UOR.Bridge.F1Square.Square
