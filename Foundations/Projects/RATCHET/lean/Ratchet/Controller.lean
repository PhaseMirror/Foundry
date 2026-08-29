import Ratchet.Types
import Ratchet.Conjectures

/-!
# Ratchet.Controller — External Controller C_ext & Mode Transition State Machine

Formalizes deterministic mode transitions for C_ext:
- BURST -> CAPTURE / HALT on T_pred / max dwell / invariant breach
- CAPTURE -> GROUND on C3 pass & valid snapshot, else retry or rollback
- GROUND -> IDLE on V threshold pass, else rollback & HALT
- HALT -> Frozen writes, non-bypassable fail-closed state
-/

namespace Ratchet

/-- Controller state context. -/
structure ControllerContext where
  mode         : Mode
  dwell_time   : Nat
  retries      : Nat
  max_retries  : Nat
  max_burst    : Nat
  ground_dwell : Nat
  v_min        : Nat
  deriving Repr, DecidableEq

/-- Deterministic mode transition step for C_ext. -/
def step_controller (ctx : ControllerContext) (exit_burst : Bool)
    (c3_pass : Bool) (snap_valid : Bool) (v_score : Nat) : ControllerContext × Mode :=
  match ctx.mode with
  | Mode.IDLE =>
    ({ ctx with mode := Mode.BURST, dwell_time := 0 }, Mode.BURST)

  | Mode.BURST =>
    if exit_burst || ctx.dwell_time >= ctx.max_burst then
      if snap_valid then
        ({ ctx with mode := Mode.CAPTURE, dwell_time := 0 }, Mode.CAPTURE)
      else
        ({ ctx with mode := Mode.HALT, dwell_time := 0 }, Mode.HALT)
    else
      ({ ctx with dwell_time := ctx.dwell_time + 1 }, Mode.BURST)

  | Mode.CAPTURE =>
    if c3_pass && snap_valid then
      ({ ctx with mode := Mode.GROUND, dwell_time := 0, retries := 0 }, Mode.GROUND)
    else if ctx.retries + 1 >= ctx.max_retries then
      ({ ctx with mode := Mode.HALT, dwell_time := 0 }, Mode.HALT)
    else
      ({ ctx with mode := Mode.BURST, dwell_time := 0, retries := ctx.retries + 1 }, Mode.BURST)

  | Mode.GROUND =>
    if ctx.dwell_time >= ctx.ground_dwell then
      if v_score >= ctx.v_min then
        ({ ctx with mode := Mode.IDLE, dwell_time := 0 }, Mode.IDLE)
      else
        ({ ctx with mode := Mode.HALT, dwell_time := 0 }, Mode.HALT)
    else
      ({ ctx with dwell_time := ctx.dwell_time + 1 }, Mode.GROUND)

  | Mode.HALT =>
    (ctx, Mode.HALT)

/-- Theorem: HALT is absorbing (learner cannot clear HALT without external intervention). -/
theorem halt_is_absorbing (ctx : ControllerContext) (h_halt : ctx.mode = Mode.HALT)
    (exit_burst c3 snap : Bool) (v : Nat) :
    (step_controller ctx exit_burst c3 snap v).2 = Mode.HALT := by
  dsimp [step_controller]
  rw [h_halt]

/-- Theorem: Exceeding max retries in CAPTURE forces HALT. -/
theorem capture_exhaustion_forces_halt (ctx : ControllerContext)
    (h_mode : ctx.mode = Mode.CAPTURE)
    (h_retries : ctx.retries + 1 >= ctx.max_retries)
    (exit_burst snap : Bool) (v : Nat) :
    (step_controller ctx exit_burst false snap v).2 = Mode.HALT := by
  dsimp [step_controller]
  rw [h_mode]
  simp [h_retries]

/-- Theorem: Ground dwell timeout with insufficient score forces HALT. -/
theorem ground_low_score_forces_halt (ctx : ControllerContext)
    (h_mode : ctx.mode = Mode.GROUND)
    (h_dwell : ctx.dwell_time >= ctx.ground_dwell)
    (v : Nat) (h_v : v < ctx.v_min)
    (exit_burst c3 snap : Bool) :
    (step_controller ctx exit_burst c3 snap v).2 = Mode.HALT := by
  dsimp [step_controller]
  rw [h_mode]
  have h_not : ¬ ctx.v_min ≤ v := Nat.not_le.mpr h_v
  simp [h_dwell, h_not]

end Ratchet
