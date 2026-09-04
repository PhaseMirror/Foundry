import Init
import SpiralCore.Core

/-! # Vertex-Guard Art Gallery Policy (ADR-0036)

Formalizes the geo-free neural policy for the vertex-guard Art Gallery
Problem:

1. **Feasibility line**: a polygon is covered exactly when every vertex
   is visible from some placed guard; per-polygon coverage must clear a
   feasibility threshold for a deployed solver.
2. **Coverage-aware reward**: the reward couples coverage and guard
   usage, so a policy is scored by covered fraction minus a guard-cost
   penalty.
3. **Geo-free inference**: at test time the policy sees only vertex
   coordinates — no visibility computation and no geometric oracle.
4. **Guarantee gap**: the reinforcement policy is *not*
   feasibility-guaranteed; residual under-coverage is a decoder
   calibration issue recoverable by a probe classifier, at an explicit
   guard-count cost.

Reference: ADR-0036 "Learning to Place Guards by Reinforcement:
A Geo-Free Neural Policy for the Vertex-Guard Art Gallery Problem".
-/

namespace SpiralCore.VertexGuard

/-- A polygon vertex with planar coordinates (scaled integers). -/
structure Vertex where
  id : Nat
  x : Int
  y : Int
deriving Repr

/-- A polygon is a list of vertices in boundary order. -/
def Polygon := List Vertex

/-- A guard placement: the set of chosen vertex ids. -/
def GuardSet := List Nat

/-- Coverage oracle (used for feasibility scoring only — never at
    geo-free inference): a guard placed at vertex g covers vertex r
    exactly when it observes it. In this discrete model a guard covers
    its own vertex (the standard convention that a guard observes its
    own location); additional visibility is a geometric oracle outside
    the discrete scope. -/
def covers (guard region : Nat) : Bool := guard = region

/-- Coverage of region r by a guard set: some guard covers r. -/
def coveredBy (guards : GuardSet) (r : Nat) : Bool :=
  guards.any (fun g => covers g r)

/-- Number of uncovered vertices among the first n. -/
def uncoveredCount (guards : GuardSet) (n : Nat) : Nat :=
  (List.range n).foldl (fun acc r => if coveredBy guards r then acc else acc + 1) 0

/-- Feasibility as a Bool: no vertex is uncovered. -/
def clearsFeasibility (guards : GuardSet) (n : Nat) : Bool :=
  uncoveredCount guards n = 0

/-- Under-covered as a Bool: at least one vertex lacks a covering guard. -/
def underCovered (guards : GuardSet) (n : Nat) : Bool :=
  uncoveredCount guards n >= 1

/-- Cleared and under-covered are exact complements (count = 0 vs ≥ 1). -/
theorem cleared_iff_not_undercovered (guards : GuardSet) (n : Nat) :
  (clearsFeasibility guards n = true) ↔ (underCovered guards n = false) := by
  constructor
  · intro h
    have hz : uncoveredCount guards n = 0 := by simpa [clearsFeasibility] using h
    simp [underCovered, hz]
  · intro h
    have hn : ¬ (uncoveredCount guards n >= 1) := by simpa [underCovered] using h
    have hz : uncoveredCount guards n = 0 := by omega
    simp [clearsFeasibility, hz]

/-- Per-vertex coverage fraction, scaled 0..100. -/
def coverageFraction (guards : GuardSet) (n : Nat) : Nat :=
  if n = 0 then 0 else (n - uncoveredCount guards n) * 100 / n

/-- Coverage is bounded by 100 percent. -/
theorem coverage_bounded (guards : GuardSet) (n : Nat) (hn : n >= 1) :
  coverageFraction guards n <= 100 := by
  unfold coverageFraction
  by_cases hn0 : n = 0
  · omega
  · have hnz : n ≠ 0 := hn0
    simp [hnz]
    have hle : n - uncoveredCount guards n <= n := by omega
    have hmul : (n - uncoveredCount guards n) * 100 <= n * 100 :=
      Nat.mul_le_mul_right 100 hle
    have hden : n * 100 / n = 100 := by
      rw [Nat.mul_comm]
      exact Nat.mul_div_cancel 100 (by omega : 0 < n)
    calc
      (n - uncoveredCount guards n) * 100 / n <= n * 100 / n :=
        Nat.div_le_div_right (c := n) hmul
      _ = 100 := hden
      _ <= 100 := by omega

/-- Guard-cost-aware reward (scaled): coverage minus cost per guard —
    the coverage-aware reward that couples coverage with guard usage. -/
def coverageReward (coverage guardCount costPerGuard : Nat) : Int :=
  Int.ofNat coverage - Int.ofNat (guardCount * costPerGuard)

/-- For equal coverage, fewer guards yield a no-smaller reward. -/
theorem fewer_guards_no_worse_reward (c g1 g2 p : Nat) (h : g1 <= g2) :
  coverageReward c g1 p >= coverageReward c g2 p := by
  unfold coverageReward
  have h1 : (g1 * p : Nat) <= g2 * p := Nat.mul_le_mul_right p h
  have h1i : ((g1 * p : Nat) : Int) <= ((g2 * p : Nat) : Int) := Int.ofNat_le.mpr h1
  -- c − (g1·p) ≥ c − (g2·p)  ⟺  c − (g2·p) ≤ c − (g1·p) (sub_le_sub_left)
  exact Int.sub_le_sub_left h1i (Int.ofNat c)

/-- Geo-free inference input: only vertex coordinates are available to
    the policy at decision time — no visibility matrix, no oracle. -/
def GeoFreeInput := List (Nat × Int × Int)

/-- A valid policy emission is a finite guard sequence terminated by an
    end-of-sequence token. -/
def ValidEmission := GuardSet

/-- Escalation gate (fail-closed): an under-covered placement must not be
    deployed; it is escalated to the classical greedy feasibility pass. -/
def escalateIfUnderCovered (guards : GuardSet) (n : Nat) : Bool :=
  if underCovered guards n = true then false else true

/-- Escalation fires exactly when the polygon is under-covered. -/
theorem escalation_fires_on_undercoverage (guards : GuardSet) (n : Nat) :
  underCovered guards n = true -> escalateIfUnderCovered guards n = false := by
  intro h
  unfold escalateIfUnderCovered
  simp [h]

/-- A fully feasible placement does not escalate. -/
theorem no_escalation_on_covered (guards : GuardSet) (n : Nat)
    (h : clearsFeasibility guards n = true) :
  escalateIfUnderCovered guards n = true := by
  unfold escalateIfUnderCovered
  have hne : underCovered guards n = false := (cleared_iff_not_undercovered guards n).1 h
  simp [hne]

/-- Deployment gate: a placement is deployment-safe exactly when it
    clears feasibility (RL alone is not feasibility-guaranteed, so the
    gate is mandatory before deployment). -/
def deploymentSafe (guards : GuardSet) (n : Nat) : Bool :=
  clearsFeasibility guards n

/-- A fully covering guard set deploys safely. -/
theorem full_coverage_deploys (guards : GuardSet) (n : Nat)
    (h : clearsFeasibility guards n = true) :
  deploymentSafe guards n = true := by
  unfold deploymentSafe
  exact h

/-- The probe-classifier escalation cost: restoring feasibility is
    reported at an explicit cost in guard count. -/
def escalationGuardCost (baseCost : Nat) : Nat := baseCost + 1

/-- Escalation strictly raises the guard budget (the reported cost of
    closing the feasibility tail). -/
theorem escalation_cost_positive (baseCost : Nat) :
  escalationGuardCost baseCost >= baseCost + 1 := by
  unfold escalationGuardCost
  omega

end SpiralCore.VertexGuard