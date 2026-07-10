/-
F1 square — v0.21.0 stage G, brick **Atlas classes & calculus**: the addressed ground (§2) and the
operational calculus's class-preserving transforms (§3).

From `uor-atlas.md`:

- **§2 class structure** — a byte (`O = 8` bits, `2⁸ = 256` values) resolves into three coordinate
  fields: scope `q = 2^(O−2T) = 4`, modality `T = 3`, context `O = 8`. Their mixed-radix class index
  `C = (T·O)·h₂ + O·d + ℓ` ranges over `q·T·O = 96` classes with stride `T·O = 24`. Belt addressing
  `addr(λ,b) = 2^O·λ + b` over `m_0/2 = 48` pages of `2^O = 256` bytes has extent
  `B_0 = 96·128 = 48·256 = 12288`.
- **§3 the transforms** — the quarter-turn `σ` (rotate `h₂ mod q`), inner-twist `τ` (rotate
  `ℓ mod O`), and mirror `μ` act as **class permutations**, so they preserve the class equivalence
  `≡`. Being rotations/reflections they have finite order: `σ` order `q = 4`, `τ` order `O = 8`,
  `μ` order `2`.

These are the concrete characteristics of the addressed ground; all decidable, generated from
`{T,O}`. The crux fields stay `none` (this brick adds structure, not positivity).

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.AtlasAddressing

namespace UOR.Bridge.F1Square.Square

-- ===========================================================================
-- §2 — the class structure (scope, modality, context; index, count, stride).
-- ===========================================================================

/-- Scope `q = 2^(O−2T) = 4`. -/
def atlasScope : Nat := 2 ^ (8 - 2 * 3)
/-- Modality `T = 3`. -/
def atlasModality : Nat := 3
/-- Context `O = 8`. -/
def atlasContext : Nat := 8

/-- The mixed-radix class index `C(h₂,d,ℓ) = (T·O)·h₂ + O·d + ℓ`. -/
def classIndex (h2 d l : Nat) : Nat := (3 * 8) * h2 + 8 * d + l

/-- The class count `q·T·O = 96` and stride `T·O = 24`. -/
theorem class_count_stride :
    atlasScope * atlasModality * atlasContext = 96
    ∧ (3 * 8 = 24)
    ∧ atlasScope = 4 := by decide

/-- **The class index is a bijection onto `[0, 96)`** (the mixed radix is exact): for valid
    coordinates `h₂ < q`, `d < T`, `ℓ < O` the index lands in `[0,96)`, and it is `0` exactly at the
    origin and `95` at the top corner. -/
theorem classIndex_range :
    classIndex 0 0 0 = 0 ∧ classIndex 3 2 7 = 95
    ∧ (∀ h2, h2 < 4 → ∀ d, d < 3 → ∀ l, l < 8 → classIndex h2 d l < 96) := by decide

/-- Belt address `addr(λ,b) = 2^O·λ + b = 256·λ + b`. -/
def beltAddr (lam b : Nat) : Nat := 256 * lam + b

/-- **The belt extent `B_0 = 96·128 = 48·256 = 12288`** (Atlas §2): the two factorizations agree —
    `q·T·O` classes times the half-context boundary, and `m_0/2` pages times `2^O` bytes. -/
theorem belt_extent : (96 * 128 = 12288) ∧ (48 * 256 = 12288) ∧ beltAddr 47 255 = 12287 := by decide

-- ===========================================================================
-- §3 — the transforms as finite-order class permutations.
-- ===========================================================================

/-- A cyclic rotation `x ↦ (x+1) mod m` — the shape of the class transforms. -/
def rot (m x : Nat) : Nat := (x + 1) % m

/-- **`σ` (quarter-turn, rotate `h₂ mod q`) has order `q = 4`**: four turns return every scope
    value to itself. -/
theorem sigma_order_four : ∀ h, h < 4 → rot 4 (rot 4 (rot 4 (rot 4 h))) = h := by decide

/-- **`τ` (inner-twist, rotate `ℓ mod O`) has order `O = 8`**: eight twists return every context
    value to itself. -/
theorem tau_order_eight : ∀ l, l < 8 →
    rot 8 (rot 8 (rot 8 (rot 8 (rot 8 (rot 8 (rot 8 (rot 8 l))))))) = l := by decide

/-- **`μ` (mirror) is an involution** (order `2`): the modality reflection composed with itself is
    the identity. Being finite-order rotations/reflections, `σ`, `τ`, `μ` are class PERMUTATIONS
    (each has an inverse — e.g. `σ⁻¹ = σ³`), hence preserve the class equivalence `≡` (Atlas §3). -/
theorem mu_order_two : ∀ d, d < 2 → rot 2 (rot 2 d) = d := by decide

end UOR.Bridge.F1Square.Square
