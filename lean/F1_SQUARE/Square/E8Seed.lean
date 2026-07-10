/-
F1 square — v0.21.0 stage G, brick **G2a (the E₈ seed)**: the finite positive-definite anchor of
the atlas tower, choice-free in the F1 idiom.

ROADMAP §8 (Stage 2a) and §10 (Gate B). The atlas base is the E₈ root lattice (rank 8); Gate B's
infinite definite limit (G2b) is anchored at this finite seed. The falsifier is "the seed is not
positive-definite without `native_decide` / Mathlib". This brick refutes it: E₈'s Gram is exhibited
as the embedding Gram `gramOf` of the explicit (2×-scaled, integer) Bourbaki simple roots, so its
positive-SEMIdefiniteness is FREE (`e8_weilPSD = WeilPSD_gramOf`) — a manifest sum of squares — and
the seed is verified to be E₈ by a single `decide`: its Gram equals `4 ×` the standard E₈ Cartan
matrix (`e8_is_cartan`), with strictly positive diagonal (`e8_diag_pos`).

The enabling lemma `gramOf_ofQ` reduces an `ofQ`-valued embedding Gram to `ofQ` of the rational
dot-product `dotQ`, so the 8×8 identification is a decidable rational-matrix equality (no
`native_decide`).

HONEST SCOPE. The choice-free result is positive-SEMIdefiniteness (a Gram is `≥ 0`); the strict
positive-definiteness of E₈ (the Gram is `> 0` for every nonzero vector) is the classical
finite-type Cartan fact (the roots are linearly independent / the lattice is unimodular). What this
brick certifies choice-free is the seed and its semidefinite anchor; nothing about the INFINITE
limit (G2b), where definiteness is the make-or-break and may fail. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import F1Square.Square.WeilPSD

namespace UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Rational dot-product and the reduction of an `ofQ`-embedding Gram.
-- ===========================================================================

/-- The rational dot-product `Σ_{k<D} q i k · q j k`, structured to mirror `RsumN`. -/
def dotQ (q : Nat → Nat → Q) (i j : Nat) : Nat → Q
  | 0 => ⟨0, 1⟩
  | D + 1 => add (dotQ q i j D) (mul (q i D) (q j D))

theorem dotQ_den_pos (q : Nat → Nat → Q) (hq : ∀ a k, 0 < (q a k).den) (i j D : Nat) :
    0 < (dotQ q i j D).den := by
  induction D with
  | zero => exact Nat.one_pos
  | succ d ih => exact add_den_pos ih (Qmul_den_pos (hq i d) (hq j d))

/-- **The reduction**: the Gram of an `ofQ`-valued embedding is `ofQ` of the rational dot-product.
    Turns an 8×8 Gram identification into a decidable rational-matrix equality. -/
theorem gramOf_ofQ (q : Nat → Nat → Q) (hq : ∀ a k, 0 < (q a k).den) (i j D : Nat) :
    Req (gramOf (fun a k => ofQ (q a k) (hq a k)) D i j)
        (ofQ (dotQ q i j D) (dotQ_den_pos q hq i j D)) := by
  induction D with
  | zero => exact Req_refl _
  | succ d ih =>
    refine Req_trans (Radd_congr ih (Rmul_ofQ_ofQ (hq i d) (hq j d))) ?_
    exact Radd_ofQ_ofQ (dotQ_den_pos q hq i j d) (Qmul_den_pos (hq i d) (hq j d))

-- ===========================================================================
-- The E₈ simple roots (Bourbaki, ×2 so all coordinates are integers) and the
-- standard E₈ Cartan matrix (×4, matching the 2-scaling).
-- ===========================================================================

/-- The eight E₈ simple roots (Bourbaki order), scaled by `2` to clear the half-integers in `α₁`,
    as rows of an 8×8 integer matrix. Their Gram is `4 ×` the E₈ Cartan matrix. -/
def e8Mat : List (List Int) :=
  [[ 1, -1, -1, -1, -1, -1, -1,  1],
   [ 2,  2,  0,  0,  0,  0,  0,  0],
   [-2,  2,  0,  0,  0,  0,  0,  0],
   [ 0, -2,  2,  0,  0,  0,  0,  0],
   [ 0,  0, -2,  2,  0,  0,  0,  0],
   [ 0,  0,  0, -2,  2,  0,  0,  0],
   [ 0,  0,  0,  0, -2,  2,  0,  0],
   [ 0,  0,  0,  0,  0, -2,  2,  0]]

/-- `4 ×` the standard E₈ Cartan matrix (diagonal `8`, the Dynkin edges `−4`, else `0`) — the
    target the `2`-scaled roots' Gram must equal. The Dynkin diagram is the E₈ tree: branch node
    (root `α₄`, index 3) with legs of lengths 1, 2, 4. -/
def e8TargetMat : List (List Int) :=
  [[ 8,  0, -4,  0,  0,  0,  0,  0],
   [ 0,  8,  0, -4,  0,  0,  0,  0],
   [-4,  0,  8, -4,  0,  0,  0,  0],
   [ 0, -4, -4,  8, -4,  0,  0,  0],
   [ 0,  0,  0, -4,  8, -4,  0,  0],
   [ 0,  0,  0,  0, -4,  8, -4,  0],
   [ 0,  0,  0,  0,  0, -4,  8, -4],
   [ 0,  0,  0,  0,  0,  0, -4,  8]]

/-- Integer entry of the E₈ root matrix (`0` outside the 8×8 block). -/
def e8Int (a k : Nat) : Int := (e8Mat.getD a []).getD k 0

/-- Rational E₈ root coordinate (denominator `1`). -/
def e8RootsQ (a k : Nat) : Q := ⟨e8Int a k, 1⟩

/-- Rational E₈ Cartan target entry (denominator `1`). -/
def e8TargetQ (i j : Nat) : Q := ⟨(e8TargetMat.getD i []).getD j 0, 1⟩

/-- The E₈ embedding into `ℝ⁸` (the `2`-scaled simple roots). -/
def e8Roots (a k : Nat) : Real := ofQ (e8RootsQ a k) Nat.one_pos

/-- **The E₈ Gram** — the embedding Gram of the simple roots. -/
def e8Gram : Nat → Nat → Real := gramOf e8Roots 8

-- ===========================================================================
-- The anchor: PSD free, identification with E₈ Cartan, positive diagonal.
-- ===========================================================================

/-- **Gate B at the seed, FREE**: the E₈ Gram is a sum of squares, hence `WeilPSD` — the
    choice-free finite definite anchor (positive-SEMIdefinite). -/
theorem e8_weilPSD : WeilPSD e8Gram :=
  WeilPSD_gramOf e8Roots 8

/-- The `2`-scaled roots' Gram equals `4 ×` the E₈ Cartan matrix — a decidable rational check. -/
theorem e8_dot_check : ∀ i, i < 8 → ∀ j, j < 8 → Qeq (dotQ e8RootsQ i j 8) (e8TargetQ i j) := by
  decide

/-- **The seed IS E₈**: its Gram equals `4 ×` the standard E₈ Cartan matrix on the 8×8 block. -/
theorem e8_is_cartan (i j : Nat) (hi : i < 8) (hj : j < 8) :
    Req (e8Gram i j) (ofQ (e8TargetQ i j) Nat.one_pos) :=
  Req_trans (gramOf_ofQ e8RootsQ (fun _ _ => Nat.one_pos) i j 8)
    (ofQ_congr (dotQ_den_pos e8RootsQ (fun _ _ => Nat.one_pos) i j 8) Nat.one_pos
      (e8_dot_check i hi j hj))

/-- The E₈ Cartan diagonal is strictly positive (root norm² `= 2`, here `4·2 = 8 > 0`). -/
theorem e8_target_diag_pos : ∀ i, i < 8 → Qlt (Qbound 0) (e8TargetQ i i) := by decide

/-- **The seed has strictly positive diagonal** `⟨αᵢ,αᵢ⟩ > 0` for every `i < 8`. -/
theorem e8_diag_pos (i : Nat) (hi : i < 8) : Pos (e8Gram i i) :=
  Pos_congr (Req_symm (e8_is_cartan i i hi hi)) ⟨0, e8_target_diag_pos i hi⟩

end UOR.Bridge.F1Square.Square
