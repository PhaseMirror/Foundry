/-
F1 square — **the Gram–Schmidt family exists** (`GramSchmidtFamily.lean`), completing brick 3 of the
Hausdorff *sufficiency* arc. The orthogonality *step* (`nextVec_ortho`) is assembled by induction into
the full orthogonal family:

  `gramSchmidt_exists d` :  for every `m ≤ d` there is a coefficient family `q` with
    • positive denominators everywhere;
    • each `q_k` (`k < m`) supported on `[0,k]`;
    • each `q_k` (`k < m`) monic (leading coefficient `1` at index `k`);
    • mutual orthogonality `⟨q_i, q_j⟩_d = 0` for `i ≠ j` (`i,j < m`).

Induction on `m`; the step extends the family by `q_m = nextVec` and discharges the four invariants —
den/support/monic from the `nextVec_*` foundations, and orthogonality from `nextVec_ortho` (with
`qHil_comm` for the mirrored ordering), the self-norm positivity coming from `qHil_self_pos` applied to
the monic `q_i`. This is the orthogonal basis the moment-problem construction (bricks 4–6: Riesz
projection, Parseval, convergence) runs on.

HONEST SCOPE. The *existence* of the finite orthogonal family for the rational Hilbert form. This is
NOT the Riesz projection / Parseval / convergence that build the L² element from a valid moment
sequence (bricks 4–6), NOT the moment-range surjectivity result, NOT positivity. Step 4
(band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Multiplicity.F1Square.Square.GramSchmidtOrtho
import Multiplicity.F1Square.Square.QHilbertPos
import Multiplicity.F1Square.Square.QHilbertSymm

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `⟨0,1⟩ < x` (as rationals) forces a positive numerator. -/
private theorem num_pos_of_Qlt_zero {x : Q} (h : Qlt (⟨0, 1⟩ : Q) x) : 0 < x.num := by
  have h' : (0 : Int) * (x.den : Int) < x.num * (1 : Int) := h
  omega

set_option maxHeartbeats 1000000 in
/-- **★ THE ORTHOGONAL FAMILY EXISTS**: for every `m ≤ d` there is a coefficient family that is
    denominator-valid, supported/monic on `[0,m)`, and mutually orthogonal in the rational Hilbert
    form at dimension `d`. Induction on `m`, extending by the next Gram–Schmidt vector. -/
theorem gramSchmidt_exists (d : Nat) :
    ∀ m, m ≤ d → ∃ q : Nat → (Nat → Q),
      (∀ k idx, 0 < (q k idx).den) ∧
      (∀ k, k < m → ∀ idx, k < idx → Qeq (q k idx) (⟨0, 1⟩ : Q)) ∧
      (∀ k, k < m → ¬ Qeq (q k k) (⟨0, 1⟩ : Q)) ∧
      (∀ i j, i < m → j < m → i ≠ j → Qeq (qHil (q i) (q j) d) (⟨0, 1⟩ : Q)) := by
  intro m
  induction m with
  | zero =>
    intro _
    exact ⟨fun _ _ => (⟨0, 1⟩ : Q), fun _ _ => Nat.one_pos,
      fun k hk => absurd hk (Nat.not_lt_zero k), fun k hk => absurd hk (Nat.not_lt_zero k),
      fun i j hi _ _ => absurd hi (Nat.not_lt_zero i)⟩
  | succ m ih =>
    intro hm1
    have hmd : m < d := by omega
    obtain ⟨q, hqd, hqsupp, hqmonic, hqorth⟩ := ih (by omega)
    -- self-norm positivity on the constructed range (monic ⟹ `⟨q_i,q_i⟩ > 0`)
    have hpos : ∀ i, i < m → 0 < (qHil (q i) (q i) d).num := fun i hi =>
      num_pos_of_Qlt_zero (qHil_self_pos (q i) (hqd i) d ⟨i, by omega, hqmonic i hi⟩)
    -- extend the family by `q_m = nextVec`
    refine ⟨fun k => if k = m then nextVec d m q else q k, ?_, ?_, ?_, ?_⟩
    · -- denominators
      intro k idx
      by_cases hk : k = m
      · simp only [if_pos hk]; exact nextVec_den d m q hqd idx
      · simp only [if_neg hk]; exact hqd k idx
    · -- support on `[0,k]`
      intro k hk idx hidx
      by_cases hkm : k = m
      · simp only [if_pos hkm]; exact nextVec_support d m q hqsupp idx (hkm ▸ hidx)
      · simp only [if_neg hkm]; exact hqsupp k (by omega) idx hidx
    · -- monic at `k`
      intro k hk
      by_cases hkm : k = m
      · simp only [if_pos hkm]; rw [hkm]; exact nextVec_monic d m q hqd hqsupp
      · simp only [if_neg hkm]; exact hqmonic k (by omega)
    · -- mutual orthogonality
      intro i j hi hj hij
      by_cases him : i = m
      · -- `i = m`, so `j < m`; flip with symmetry onto `nextVec_ortho`
        have hjlt : j < m := by omega
        simp only [if_pos him, if_neg (Nat.ne_of_lt hjlt)]
        exact Qeq_trans (qHil_den_pos (q j) (nextVec d m q) (hqd j) (nextVec_den d m q hqd) d)
          (qHil_comm (nextVec d m q) (q j) (nextVec_den d m q hqd) (hqd j) d)
          (nextVec_ortho d m j q hqd hqorth hjlt (hpos j hjlt))
      · by_cases hjm : j = m
        · -- `j = m`, `i < m`: `nextVec_ortho` directly
          have hilt : i < m := by omega
          simp only [if_pos hjm, if_neg (Nat.ne_of_lt hilt)]
          exact nextVec_ortho d m i q hqd hqorth hilt (hpos i hilt)
        · -- both `< m`: the induction hypothesis
          simp only [if_neg him, if_neg hjm]
          exact hqorth i j (by omega) (by omega) hij

end Multiplicity.UOR.Bridge.F1Square.Square
