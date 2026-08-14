/-
F1 square — **co-support members exist at every depth** (`QCoSupportExists.lean`), sub-brick N₄. The
kernel lemma (N₂) and the ℚ-coefficient member (N₃) are welded on the Hilbert system: for every `K`,
the homogeneous system

  `Σᵢ cᵢ = 0`  (unit support)   and   `Σᵢ cᵢ/(i+n+1) = 0`  (`n < K`, the moments)

has `K+1` equations in `K+2` unknowns, so `qkernel_exists` supplies a coefficient vector `c` with a
nonzero coordinate solving it; `qPolyTest_hatVanishes` (N₃) turns `c` into a certified co-support member
`qPolyTest c hc (K+2)` in `HatVanishes·K`. This is the general-`K` inhabitation the layer previously had
only for `K = 1..7` (each found by an off-kernel `ℚ`-linear solve) — the "hypergeometric identity the
layer cannot reach", reached by row reduction instead.

HONEST SCOPE. The member is built from a coefficient vector that is nonzero as a VECTOR (`∃ v, cᵥ ≉ 0`).
That the member is nonzero as a FUNCTION on `[0,1]` — i.e. the monomials are linearly independent there —
is the factor-theorem apartness, a separate brick; it is NOT proved here. NOT positivity beyond the
skeleton. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.QLinearKernel
import Multiplicity.F1Square.Square.QPolyMember

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The unit-support row: coefficient `1` on every variable (`Σᵢ cᵢ`). -/
def sumRow : Nat → Q := fun _ => (⟨1, 1⟩ : Q)

/-- The `n`-th Hilbert moment row: coefficient `1/(i+n+1)` on variable `i` (`Σᵢ cᵢ/(i+n+1)`). -/
def momRow (n : Nat) : Nat → Q := fun i => (⟨1, i + n + 1⟩ : Q)

/-- The depth-`K` co-support system: the support row, then the moment rows `n = 0 … K−1`. -/
def hilbertEqns (K : Nat) : List (Nat → Q) := sumRow :: (List.range K).map momRow

theorem hilbertEqns_den (K : Nat) : ∀ e ∈ hilbertEqns K, ∀ i, 0 < (e i).den := by
  intro e he i
  rcases List.mem_cons.mp he with rfl | he'
  · exact Nat.one_pos
  · rcases List.mem_map.mp he' with ⟨n, _, rfl⟩
    exact Nat.succ_pos (i + n)

theorem hilbertEqns_length (K : Nat) : (hilbertEqns K).length = K + 1 := by
  simp only [hilbertEqns, List.length_cons, List.length_map, List.length_range]

/-- `map Nat.succ` preserves `Nodup` (a choice-free replacement for the classical `List.Nodup.map`). -/
theorem nodup_map_succ : ∀ (l : List Nat), l.Nodup → (l.map Nat.succ).Nodup
  | [], _ => by simp
  | a :: rest, hnd => by
    rw [List.map_cons, List.nodup_cons]
    have hnda := List.nodup_cons.mp hnd
    refine ⟨?_, nodup_map_succ rest hnda.2⟩
    intro hmem
    rw [List.mem_map] at hmem
    obtain ⟨b, hb, hab⟩ := hmem
    have hab2 : b = a := Nat.succ.inj hab
    subst hab2
    exact hnda.1 hb

/-- `List.range n` has no duplicates — a choice-free proof (`List.nodup_range` in core pulls
    `Classical.choice`). Via `range_succ_eq_map` (`range (n+1) = 0 :: (range n).map succ`) and
    `nodup_map_succ`. -/
theorem nodup_range_cf : ∀ n : Nat, (List.range n).Nodup
  | 0 => by rw [List.range_zero]; exact List.nodup_nil
  | n + 1 => by
    rw [List.range_succ_eq_map, List.nodup_cons]
    refine ⟨?_, nodup_map_succ (List.range n) (nodup_range_cf n)⟩
    intro hmem
    rw [List.mem_map] at hmem
    obtain ⟨b, _, hb⟩ := hmem
    exact Nat.succ_ne_zero b hb

/-- **CO-SUPPORT MEMBERS EXIST AT EVERY DEPTH**: for every `K` there is a rational coefficient vector `c`
    with a nonzero coordinate whose `ℚ`-coefficient polynomial test `qPolyTest c hc (K+2)` is unit-supported
    and lies in the co-support level `K`. The member comes from `qkernel_exists` on the Hilbert system
    (`K+1` equations, `K+2` unknowns) and `qPolyTest_hatVanishes`. -/
theorem coSupport_member_exists (K : Nat) :
    ∃ (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (hsupp : UnitSupported (qPolyTest c hc (K + 2))),
      (∃ v ∈ List.range (K + 2), ¬ Qeq (c v) (⟨0, 1⟩ : Q)) ∧
      HatVanishes (qPolyTest c hc (K + 2)) K (C := (⟨0, 1⟩ : Q)) (by decide)
        (by show (0 : Int) ≤ 0; decide)
        (allDecay_of_supp (qPolyTest c hc (K + 2)) hsupp) := by
  have hlt : (hilbertEqns K).length < (List.range (K + 2)).length := by
    rw [hilbertEqns_length, List.length_range]; omega
  rcases qkernel_exists (hilbertEqns K) (hilbertEqns_den K) (List.range (K + 2))
      (nodup_range_cf (K + 2)) hlt with ⟨c, hcden, ⟨v, hv, hvnz⟩, hsat⟩
  -- support: `Σᵢ cᵢ ≈ 0`
  have hsum : Qeq (qsumL c (List.range (K + 2))) (⟨0, 1⟩ : Q) := by
    have hterm : ∀ i, Qeq (c i) (mul (sumRow i) (c i)) := by
      intro i
      show Qeq (c i) (mul (⟨1, 1⟩ : Q) (c i))
      simp only [Qeq, mul]; push_cast; ring_uor
    exact Qeq_trans (qsumL_den _ (fun i => Qmul_den_pos Nat.one_pos (hcden i)) (List.range (K + 2)))
      (qsumL_congr hterm (List.range (K + 2))) (hsat sumRow (List.mem_cons_self sumRow _))
  -- moments: `Σᵢ cᵢ/(i+n+1) ≈ 0` for `n < K`
  have hmom : ∀ n : Nat, n < K →
      Qeq (qsumL (fun i => mul (c i) (⟨1, i + n + 1⟩ : Q)) (List.range (K + 2))) (⟨0, 1⟩ : Q) := by
    intro n hn
    have hmem : momRow n ∈ hilbertEqns K :=
      List.mem_cons_of_mem sumRow (List.mem_map_of_mem momRow (List.mem_range.mpr hn))
    have hterm : ∀ i, Qeq (mul (c i) (⟨1, i + n + 1⟩ : Q)) (mul (momRow n i) (c i)) := by
      intro i
      show Qeq (mul (c i) (⟨1, i + n + 1⟩ : Q)) (mul (⟨1, i + n + 1⟩ : Q) (c i))
      simp only [Qeq, mul]; push_cast; ring_uor
    exact Qeq_trans
      (qsumL_den _ (fun i => Qmul_den_pos (Nat.succ_pos (i + n)) (hcden i)) (List.range (K + 2)))
      (qsumL_congr hterm (List.range (K + 2))) (hsat (momRow n) hmem)
  exact ⟨c, hcden, qPolyTest_supp c hcden (K + 2) hsum,
    ⟨v, hv, hvnz⟩, qPolyTest_hatVanishes c hcden (K + 2) K hsum hmom⟩

end Multiplicity.UOR.Bridge.F1Square.Square
