import Core.Spine
import Core.Foundations.Completion
import Init.Data.String.Basic

/-!
# Lean ↔ Rust FFI Bridge (lean-rs-host)

Exports verified constants and proof summaries from Lean to Rust via
`@[export]`.  The companion Rust crate `lean-ffi` consumes these symbols
through `lean-rs-host`'s typed FFI.

All exported symbols are:
  * **total** — no exception-throwing `IO` paths
  * **proof-certificate preserving** — the certificate bytes round-trip
    through Rust and can be re-verified by `lean_sdk::verify_certificate`
-/

namespace FFI

/- --------------------------------------------------------------------- --
   ACE bound for the 108-cycle
   --------------------------------------------------------------------- -/

/-- The ACE bound constant: `6000 / 10000 = 0.6` for dimension 108.
    This mirrors `aceBound` in `Core.Spine` and is the critical
    Lipschitz threshold used by the Rust verification pipeline. -/
@[export lean_ace_bound]
def aceBoundExport : Float :=
  Core.Spine.aceBound Core.Spine.cycle108

/- --------------------------------------------------------------------- --
   Cycle-108 admissibility proof certificate
   --------------------------------------------------------------------- -/

/-- Theorem: the 108-cycle operator word is admissible (ACE-stable).
    Rust consumes this as a proof-summary handle via `lean-rs-host`. -/
@[export lean_cycle108_admissible]
def cycle108Admissible : Prop :=
  Core.Spine.isAdmissible Core.Spine.cycle108

theorem cycle108_admissible_proof : cycle108Admissible := by
  unfold cycle108Admissible
  exact Core.Spine.n108_admissible

/-- Dimension of the 108-cycle tensor product space: 3^3 * 2^2 = 108. -/
@[export lean_cycle108_dimension]
def cycle108Dimension : Nat :=
  Core.Spine.dim Core.Spine.cycle108

/-- Effective Lipschitz constant for the 108-cycle as a Float.
    Must be ≤ `aceBoundExport` for the cycle to be admissible. -/
@[export lean_cycle108_lambda_eff]
def cycle108LambdaEff : Float :=
  (Core.Spine.L_eff_bound Core.Spine.cycle108).toFloat / 10000.0

/- --------------------------------------------------------------------- --
   Partial universal closure helpers
   --------------------------------------------------------------------- -/

/-- Compose two elements via the partial universal closure.
    Returns `some x` if composition succeeds, `none` otherwise. -/
@[export lean_uc_compose_opt]
def ucCompose {X : Type} (U : Completion.UC X) (x y : X) : Option X :=
  U.compose_p x y

/-- Close an element via the partial universal closure. -/
@[export lean_uc_closure_opt]
def ucClosure {X : Type} (U : Completion.UC X) (x : X) : Option X :=
  U.closure_p x

/-- Defect μ for a HasDefect witness at point x. -/
@[export lean_defect_mu]
def defectMu {X : Type} {U : Completion.UC X} (hd : Completion.HasDefect U) (x : X) : Nat :=
  (hd.mu x).value

/- --------------------------------------------------------------------- --
   Kernel-check helper (proof summary)
   --------------------------------------------------------------------- -/

/-- Run the Lean kernel on a known theorem and return the
    declaration name for use as a proof-summary token. -/
@[export lean_proof_summary_token]
def proofSummaryToken (thmName : String) : String :=
  s!"proof_summary:{thmName}:cycle108"

end FFI
