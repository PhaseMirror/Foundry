import MOC.Ramanujan.Core

namespace MOC.Ramanujan

/-- 
  Theorem: The `compute_coeff` sequence unconditionally satisfies the `hecke_recurrence`.
  This allows us to bypass the `sorry` found in the original Ramanujan model.
-/
theorem coeff_satisfies_recurrence (blk : PrimeBlock) (r : Nat) :
  hecke_recurrence_seq (fun r_val => compute_coeff blk r_val) blk.k blk.p r := by
  unfold hecke_recurrence_seq
  -- compute_coeff blk (r + 2) expands identically to the recurrence relation
  rfl

/--
  Validator check for the Deligne bound on a single block.
-/
def check_deligne_block (blk : PrimeBlock) : Bool :=
  decide (blk.a_p * blk.a_p ≤ 4 * ((blk.p : Int) ^ (blk.k - 1)))

/--
  Theorem: If the validator check passes, the mathematical Deligne bound is proven.
-/
theorem validator_soundness (blk : PrimeBlock) (h : check_deligne_block blk = true) :
  deligne_bound blk.a_p blk.p blk.k := by
  unfold check_deligne_block at h
  unfold deligne_bound
  exact of_decide_eq_true h

end MOC.Ramanujan
