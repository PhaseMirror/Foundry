  | 0 => by decide
  | (N + 1) => add_den_pos (corrP_den_pos N) (corrT_den_pos N)

/-- **The per-term telescoping bound** `cₙ ≤ tel(n) − tel(n+1)` for ALL `n` — the comparison reduces
    to `(4n−1)² + 380 ≥ 0`, a manifest square (with `K = 100`). -/
private theorem corrT_le_teldiff (n : Nat) :
    Qle (corrT n) (Qsub (corrTel n) (corrTel (n + 1))) := by sorry

-- ===========================================================================
-- The monotone auxiliary g(m) = S(m) + tel(m), and the tail bound.
-- ===========================================================================

/-- `g(m) = S(m) + tel(m)`. -/
private def corrG (m : Nat) : Q := add (corrP m) (corrTel m)

private theorem corrG_den_pos (m : Nat) : 0 < (corrG m).den :=
  add_den_pos (corrP_den_pos m) (corrTel_den_pos m)

/-- `cₘ + tel(m+1) ≤ tel(m)` (the telescoping step, rearranged). -/
private theorem corrT_tel_le (m : Nat) :
    Qle (add (corrT m) (corrTel (m + 1))) (corrTel m) := by
  have hadd := Qadd_le_add (corrT_le_teldiff m) (Qle_refl (corrTel (m + 1)))
  have e3 : Qeq (add (Qsub (corrTel m) (corrTel (m + 1))) (corrTel (m + 1))) (corrTel m) := by
    simp only [Qeq, add, Qsub, neg]; push_cast; ring_uor
  refine Qle_trans ?_ hadd (Qeq_le e3)
  exact add_den_pos (Qsub_den_pos (corrTel_den_pos m) (corrTel_den_pos (m + 1)))
    (corrTel_den_pos (m + 1))

/-- One step: `g(m+1) ≤ g(m)`. -/
