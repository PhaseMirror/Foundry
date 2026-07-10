/-
F1 square — v0.21.0 stage G, brick **Atlas conservation** (§4 the zero-state, §5 scale-invariance):
the no-loss conservation law and the round-trip identity — the Atlas's coherence condition.

From `uor-atlas.md`:

- **§4 no-loss / conservation** — "every well-typed closed term satisfies no-loss… nothing is
  created or destroyed, only moved." Concretely, the class addressing is information-preserving: the
  mixed-radix `classIndex` is a bijection, so the coordinates `(h₂, d, ℓ)` are recovered exactly
  (`class_no_loss`).
- **§4/§7 round-trip closure** — the pipeline's round-trip `roundTrip(P(Π(G(s)))) = s`. On the
  addressing residue component this is `π_k ∘ ι_k = id`: projecting an included representative
  recovers it (`atlas_roundtrip`), the §6.7 scale-consistency.
- **§5 scale-invariance** — "an address minted at one scale stays valid at every larger one": the
  inverse system commutes, `(r mod m_{k+1}) mod m_k = r mod m_k` (`atlas_scale_consistent`), because
  `m_k | m_{k+1}` (`atlasModulus_dvd_succ`).

These are the coherence/closure guarantees §7 says are inherited by anything expressed in the Atlas.
The crux fields stay `none` (conservation is structure, not the RH positivity).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.AtlasClasses

namespace UOR.Bridge.F1Square.Square

-- ===========================================================================
-- §4 — no-loss: the class addressing is information-preserving.
-- ===========================================================================

/-- Decode a class index back to its `(h₂, d, ℓ)` coordinates (the inverse mixed radix). -/
def classDecode (c : Nat) : Nat × Nat × Nat := (c / 24, (c % 24) / 8, c % 8)

/-- **NO-LOSS** (Atlas §4): the addressing loses no information — decoding the class index recovers
    the coordinates exactly, for every valid `(h₂ < q, d < T, ℓ < O)`. "Nothing is created or
    destroyed, only moved." -/
theorem class_no_loss :
    ∀ h2, h2 < 4 → ∀ d, d < 3 → ∀ l, l < 8 →
      classDecode (classIndex h2 d l) = (h2, d, l) := by decide

-- ===========================================================================
-- §4/§7 — round-trip closure: π ∘ ι = id on representatives.
-- ===========================================================================

/-- Projection to addressing level `k`: `r ↦ r mod m_k` (the structure map `π_k`). -/
def atlasProject (k r : Nat) : Nat := r % atlasModulus k

/-- **ROUND-TRIP IDENTITY** (Atlas §4/§7, `π_k ∘ ι_k = id`): projecting an included representative
    (one already in range at level `k`) recovers it — `roundTrip` is the identity. -/
theorem atlas_roundtrip (k r : Nat) (h : r < atlasModulus k) : atlasProject k r = r :=
  Nat.mod_eq_of_lt h

-- ===========================================================================
-- §5 — scale-invariance: the inverse system commutes.
-- ===========================================================================

/-- **SCALE-INVARIANCE** (Atlas §5): an address minted at level `k+1` and projected to level `k`
    agrees with the direct level-`k` address — `(r mod m_{k+1}) mod m_k = r mod m_k` — because
    `m_k | m_{k+1}`. So "an address minted at one scale stays valid at every larger one". -/
theorem atlas_scale_consistent (k r : Nat) :
    atlasProject k (atlasProject (k + 1) r) = atlasProject k r :=
  Nat.mod_mod_of_dvd r (atlasModulus_dvd_succ k)

end UOR.Bridge.F1Square.Square
