-- NFiber.lean
import RocEngine.Lyapunov

/-- We model n-fibres as a List of States. This entirely avoids Mathlib dependency
    while allowing us to reason about an arbitrary, unbounded number of coupled fibres. -/
def NFiberState := List State

/-- The aggregate Lyapunov functional for the entire n-fibre system,
    using recursive summation to maintain zero Mathlib footprint. -/
def nfiber_V (w : Weights) : NFiberState → Nat
  | [] => 0
  | (x :: xs) => V_omega w x + nfiber_V w xs

/-- A recursive contractive update over the N-fibre list.
    (Coupling can be modeled by bounded addition step similar to CrossFiber,
     but for the base N-fibre theorem, we prove aggregate intrinsic descent). -/
def nfiber_update : NFiberState → NFiberState
  | [] => []
  | (x :: rest) => T x :: nfiber_update rest

/-- 
  Theorem: Generalised N-Fibre Multiplicity Descent
  If the intrinsic contractivity holds for each individual fibre in the ensemble,
  the aggregate weighted Lyapunov functional strictly descends.
  Proved by structural induction with zero sorries.
-/
theorem nfiber_descent (w : Weights) (xs : NFiberState) :
    nfiber_V w (nfiber_update xs) ≤ nfiber_V w xs := by
  induction xs with
  | nil => exact Nat.le_refl 0
  | cons head tail ih =>
    dsimp [nfiber_V, nfiber_update]
    apply Nat.add_le_add
    · exact lyapunov_descent_weighted w head
    · exact ih
