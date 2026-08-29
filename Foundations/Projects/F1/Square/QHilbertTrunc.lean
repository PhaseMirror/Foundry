/-
F1 square — **truncation-stability of the rational Hilbert form** (`QHilbertTrunc.lean`), brick 3.5a of
the Hausdorff *sufficiency* arc. The finite Hilbert form `qHil c c' d` sums over the box `[0,d)²`; if
both coefficient vectors *vanish* from index `D` on, then every term the enlarged box adds is zero, so
the value is independent of the truncation dimension past `D`:

  `qHil_trunc_eq_of_ge` :  `c,c'` supported on `[0,D)`, `D ≤ d`  ⟹  `qHil c c' d ≈ qHil c c' D`
  `qHil_trunc_eq`       :  `c,c'` supported on `[0,D)`, `D ≤ d`, `D ≤ d'`  ⟹  `qHil c c' d ≈ qHil c c' d'`

Two single-step extensions do the work — `innerHil c (d+1) j ≈ innerHil c d j` (the extra inner term
`c_d/(d+j+1)` vanishes) and `qHil c c' (d+1) ≈ qHil c c' d` (that plus the extra outer term
`c'_d·innerHil` vanishing) — chained by induction on the gap `d − D`, both peeling the top element via
`List.range_succ` (avoiding the choice-tainted `List.nodup_range`).

This is the tool that lets a *fixed* coefficient vector (the Riesz projection `p_N`, supported on
`[0,N]`) be paired at *any* dimension `d ≥ N` and get the same rational value — the prerequisite for a
dimension-independent orthogonal family and hence the `L²`-limit (later bricks).

HONEST SCOPE. Dimension-stability of the *finite rational* Hilbert form under support, pure finite ℚ
arithmetic. This is NOT the dimension-independent Gram–Schmidt family (next brick), NOT the Riesz
convergence / L²-limit, NOT positivity. Step 4 (band-coupling positivity) is RH; the crux fields stay
`none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/
import Foundations.F1.Square.QHilbertBilinear

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- ===========================================================================
-- Small ℚ / list helpers (private).
-- ===========================================================================

/-- `a ≈ 0 ⟹ a·b ≈ 0` — no denominator hypothesis on `b`. -/
private theorem Qmul_zero_of_left {a b : Q} (ha : Qeq a (⟨0, 1⟩ : Q)) :
    Qeq (mul a b) (⟨0, 1⟩ : Q) := by
  have han : a.num = 0 := by simp only [Qeq] at ha; push_cast at ha; omega
  show a.num * b.num * ((1 : Nat) : Int) = 0 * ((a.den * b.den : Nat) : Int)
  rw [han]; push_cast; ring_uor

/-- Split the last element off a `range (d+1)` sum: `Σ_{i<d+1} f i ≈ (Σ_{i<d} f i) + f d`. -/
private theorem qsumL_range_succ (f : Nat → Q) (hf : ∀ i, 0 < (f i).den) (d : Nat) :
    Qeq (qsumL f (List.range (d + 1))) (add (qsumL f (List.range d)) (f d)) := by
  rw [List.range_succ]
  refine Qeq_trans (b := add (qsumL f (List.range d)) (qsumL f [d]))
    (add_den_pos (qsumL_den f hf (List.range d)) (qsumL_den f hf [d]))
    (qsumL_append f hf (List.range d) [d]) ?_
  refine Qadd_congr (Qeq_refl _) ?_
  show Qeq (add (f d) (⟨0, 1⟩ : Q)) (f d)
  exact Qadd_zero_right (f d)

-- ===========================================================================
-- Single-step dimension extension (private).
-- ===========================================================================

/-- **Inner-sum extension is inert past support**: if `c_d ≈ 0` then `innerHil c (d+1) j ≈ innerHil c d j`
    — the only term the wider inner box adds is `c_d/(d+j+1)`, which vanishes. -/
private theorem innerHil_trunc_step (c : Nat → Q) (hc : ∀ i, 0 < (c i).den) (d j : Nat)
    (hcd : Qeq (c d) (⟨0, 1⟩ : Q)) :
    Qeq (innerHil c (d + 1) j) (innerHil c d j) := by
  show Qeq (qsumL (fun i => mul (c i) (⟨1, i + j + 1⟩ : Q)) (List.range (d + 1))) (innerHil c d j)
  refine Qeq_trans (b := add (qsumL (fun i => mul (c i) (⟨1, i + j + 1⟩ : Q)) (List.range d))
      (mul (c d) (⟨1, d + j + 1⟩ : Q)))
    (add_den_pos (innerHil_den c hc d j) (Qmul_den_pos (hc d) (Nat.succ_pos (d + j))))
    (qsumL_range_succ (fun i => mul (c i) (⟨1, i + j + 1⟩ : Q))
      (fun i => Qmul_den_pos (hc i) (Nat.succ_pos (i + j))) d) ?_
  refine Qeq_trans (b := add (innerHil c d j) (⟨0, 1⟩ : Q))
    (add_den_pos (innerHil_den c hc d j) (by decide))
    (Qadd_congr (Qeq_refl _) (Qmul_zero_of_left hcd)) (Qadd_zero_right (innerHil c d j))

/-- **The form's single-dimension extension is inert past support**: if `c_d ≈ 0` and `c'_d ≈ 0` then
    `qHil c c' (d+1) ≈ qHil c c' d`. Split off the outer index `d` (its term `c'_d·… ≈ 0`) and replace
    the residual inner sums via `innerHil_trunc_step`. -/
private theorem qHil_trunc_step (c c' : Nat → Q) (hc : ∀ i, 0 < (c i).den) (hc' : ∀ i, 0 < (c' i).den)
    (d : Nat) (hcd : Qeq (c d) (⟨0, 1⟩ : Q)) (hc'd : Qeq (c' d) (⟨0, 1⟩ : Q)) :
    Qeq (qHil c c' (d + 1)) (qHil c c' d) := by
  show Qeq (qsumL (fun j => mul (c' j) (innerHil c (d + 1) j)) (List.range (d + 1))) (qHil c c' d)
  refine Qeq_trans (b := add (qsumL (fun j => mul (c' j) (innerHil c (d + 1) j)) (List.range d))
      (mul (c' d) (innerHil c (d + 1) d)))
    (add_den_pos
      (qsumL_den _ (fun j => Qmul_den_pos (hc' j) (innerHil_den c hc (d + 1) j)) (List.range d))
      (Qmul_den_pos (hc' d) (innerHil_den c hc (d + 1) d)))
    (qsumL_range_succ (fun j => mul (c' j) (innerHil c (d + 1) j))
      (fun j => Qmul_den_pos (hc' j) (innerHil_den c hc (d + 1) j)) d) ?_
  refine Qeq_trans (b := add (qsumL (fun j => mul (c' j) (innerHil c d j)) (List.range d))
      (⟨0, 1⟩ : Q))
    (add_den_pos
      (qsumL_den _ (fun j => Qmul_den_pos (hc' j) (innerHil_den c hc d j)) (List.range d)) (by decide))
    (Qadd_congr
      (qsumL_congr (fun j => Qmul_congr (Qeq_refl _) (innerHil_trunc_step c hc d j hcd)) (List.range d))
      (Qmul_zero_of_left hc'd))
    (Qadd_zero_right (qsumL (fun j => mul (c' j) (innerHil c d j)) (List.range d)))

-- ===========================================================================
-- ★ Truncation-stability past support.
-- ===========================================================================

/-- The `∀ n` engine: chaining the single-step extension along `d = D + n`. -/
private theorem qHil_trunc_stable (c c' : Nat → Q) (hc : ∀ i, 0 < (c i).den)
    (hc' : ∀ i, 0 < (c' i).den) (D : Nat)
    (hcsupp : ∀ idx, D ≤ idx → Qeq (c idx) (⟨0, 1⟩ : Q))
    (hc'supp : ∀ idx, D ≤ idx → Qeq (c' idx) (⟨0, 1⟩ : Q)) :
    ∀ n, Qeq (qHil c c' (D + n)) (qHil c c' D) := by
  intro n
  induction n with
  | zero => exact Qeq_refl _
  | succ n ih =>
    exact Qeq_trans (qHil_den_pos c c' hc hc' (D + n))
      (qHil_trunc_step c c' hc hc' (D + n)
        (hcsupp (D + n) (Nat.le_add_right D n)) (hc'supp (D + n) (Nat.le_add_right D n)))
      ih

/-- **★ TRUNCATION-STABILITY**: if `c,c'` both vanish at every index `≥ D`, then the Hilbert form at any
    dimension `d ≥ D` equals the value at `D`. -/
theorem qHil_trunc_eq_of_ge (c c' : Nat → Q) (hc : ∀ i, 0 < (c i).den) (hc' : ∀ i, 0 < (c' i).den)
    (D : Nat) (hcsupp : ∀ idx, D ≤ idx → Qeq (c idx) (⟨0, 1⟩ : Q))
    (hc'supp : ∀ idx, D ≤ idx → Qeq (c' idx) (⟨0, 1⟩ : Q))
    (d : Nat) (hd : D ≤ d) :
    Qeq (qHil c c' d) (qHil c c' D) := by
  obtain ⟨k, rfl⟩ := Nat.le.dest hd
  exact qHil_trunc_stable c c' hc hc' D hcsupp hc'supp k

/-- **★ DIMENSION-INDEPENDENCE**: for support-`[0,D)` vectors the Hilbert form agrees at any two
    dimensions `d, d' ≥ D` — the form is well-defined independent of the truncation, on the constructed
    range. -/
theorem qHil_trunc_eq (c c' : Nat → Q) (hc : ∀ i, 0 < (c i).den) (hc' : ∀ i, 0 < (c' i).den)
    (D : Nat) (hcsupp : ∀ idx, D ≤ idx → Qeq (c idx) (⟨0, 1⟩ : Q))
    (hc'supp : ∀ idx, D ≤ idx → Qeq (c' idx) (⟨0, 1⟩ : Q))
    (d d' : Nat) (hd : D ≤ d) (hd' : D ≤ d') :
    Qeq (qHil c c' d) (qHil c c' d') :=
  Qeq_trans (qHil_den_pos c c' hc hc' D)
    (qHil_trunc_eq_of_ge c c' hc hc' D hcsupp hc'supp d hd)
    (Qeq_symm (qHil_trunc_eq_of_ge c c' hc hc' D hcsupp hc'supp d' hd'))

end Multiplicity.UOR.Bridge.F1Square.Square
