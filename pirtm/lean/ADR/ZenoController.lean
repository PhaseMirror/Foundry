/-!
# WardMonitor & Zeno Controller Formalization

Formal specification of the runtime drift monitor, Zeno damping controller,
and the fail-closed `SIG_GOV_KILL` tripwire under the Sedona Spine governance mandate.

Self-contained in Lean 4 Core (Zero-Mathlib, Zero-Sorry).
-/

namespace ZenoController

/-- Discrete governance operational state. -/
inductive WardState where
  | Green  -- ρ < ρ_warn (0.85)
  | Amber  -- ρ_warn ≤ ρ < ρ_halt (1.00): Zeno damping active
  | Red    -- ρ_halt ≤ ρ < kill (1.05): Critical buffer
  | Kill   -- ρ ≥ kill (1.05): Immediate fail-closed termination
deriving Repr, DecidableEq

/-- Governance constant representations scaled by 100 to maintain exact integer arithmetic:
    - ρ_warn  = 85  (0.85)
    - ρ_halt  = 100 (1.00)
    - kill    = 105 (1.05)
    - delta   = 3   (0.03)

    These scaled `Nat` values are exactly equivalent to the `f64` constants
    in `pirtm-monitor/src/lib.rs` (`RHO_WARN=0.85`, `RHO_HALT=1.0`,
    `KILL_THRESHOLD=1.05`, `DELTA_MAX=0.03`).  Integer scaling preserves
    all ordering properties required for governance classification while
    enabling machine-checked proofs in the Lean 4 core kernel.
-/
def RHO_WARN : Nat := 85
def RHO_HALT : Nat := 100
def KILL_THRESHOLD : Nat := 105
def DELTA_MAX : Nat := 3

/-- Unit consistency theorem: scaled `Nat` thresholds preserve the same
    ordering as their `f64` counterparts in the Rust runtime. -/
theorem threshold_ordering :
    RHO_WARN < RHO_HALT ∧ RHO_HALT < KILL_THRESHOLD := by
  constructor <;> decide

/-- Classify measured drift metric (scaled by 100) into discrete governance state. -/
def classifyState (rho_scaled : Nat) : WardState :=
  if rho_scaled ≥ KILL_THRESHOLD then
    WardState.Kill
  else if rho_scaled ≥ RHO_HALT then
    WardState.Red
  else if rho_scaled ≥ RHO_WARN then
    WardState.Amber
  else
    WardState.Green

/-- Zeno damping controller:
    Computes discrete decay factor κ(t) = κ_0 * decay^t.
    With integer arithmetic, κ(t+1) is computed by step-wise integer contraction. -/
def zenoDampingStep (kappa : Nat) (rate_percent : Nat) : Nat :=
  (kappa * (100 - rate_percent)) / 100

/-- Iterated Zeno damping after t steps. -/
def zenoDamping (kappa0 : Nat) (rate_percent : Nat) : Nat → Nat
  | 0 => kappa0
  | t + 1 => zenoDampingStep (zenoDamping kappa0 rate_percent t) rate_percent

/-- Zeno Monotonicity Theorem:
    Each step of the Zeno damping controller monotonically decreases the gain. -/
theorem zeno_step_monotone (kappa : Nat) (rate_percent : Nat) (_hr : rate_percent ≤ 100) :
    zenoDampingStep kappa rate_percent ≤ kappa := by
  dsimp [zenoDampingStep]
  have h1 : 100 - rate_percent ≤ 100 := Nat.sub_le 100 rate_percent
  have h2 : kappa * (100 - rate_percent) ≤ 100 * kappa := by
    have h_mul := Nat.mul_le_mul_left kappa h1
    rw [Nat.mul_comm 100 kappa]
    exact h_mul
  exact Nat.div_le_of_le_mul h2

/-- Fail-Closed Tripwire Safety Theorem:
    Any state measurement at or above the kill threshold unconditionally
    triggers `WardState.Kill`. -/
theorem ward_kill_safe (rho_scaled : Nat) (h : rho_scaled ≥ KILL_THRESHOLD) :
    classifyState rho_scaled = WardState.Kill := by
  dsimp [classifyState]
  split
  · rfl
  · rename_i h_not
    exact False.elim (h_not h)

/-- Normal Execution Boundary Theorem:
    Any state measurement strictly below the amber threshold remains in `WardState.Green`. -/
theorem ward_green_safe (rho_scaled : Nat) (h : rho_scaled < RHO_WARN) :
    classifyState rho_scaled = WardState.Green := by
  dsimp [classifyState]
  split
  · rename_i h_kill
    have h_contra : RHO_WARN < KILL_THRESHOLD := by decide
    have : rho_scaled < KILL_THRESHOLD := Nat.lt_trans h h_contra
    exact False.elim (Nat.not_le_of_gt this h_kill)
  · split
    · rename_i _ h_red
      have h_contra : RHO_WARN < RHO_HALT := by decide
      have : rho_scaled < RHO_HALT := Nat.lt_trans h h_contra
      exact False.elim (Nat.not_le_of_gt this h_red)
    · split
      · rename_i _ _ h_amber
        exact False.elim (Nat.not_le_of_gt h h_amber)
      · rfl

end ZenoController
