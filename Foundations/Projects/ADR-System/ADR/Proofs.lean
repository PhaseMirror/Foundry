import ADR.Core
import ADR.Formal
import ADR.Attributes

/-!
# ADR Proofs

Formal theorems for the ADR-System. Every `@[proof]` declaration is a
machine-checkable statement about the ADR-009 specification:

## Governance

- `accepted_transition_requires_supersession` — once `Accepted`, any status
  change requires a superseding ADR (immutability without supersession).
- `accepted_cannot_become_accepted_without_supersession` — the immutability
  theorem for the concrete governance rule.
- `registry_accepted_not_proposed` — accepted and proposed states are
  disjoint within a registry.

## Formal model (ADR-009)

- `processable_*` — soundness and monotonicity of the `Processable` guard.
- `qcheck_*` — `QCheck` is propositionally equivalent to `LatticeAligned`.
- `physical_*` — `Physical` implies coordinate boundedness; inter-point
  distances are bounded by the domain size.
- `ace_budget_*` — budget conditions below resonance are safe.
- `softThreshold_*` — the ACE projection is sub-identity and exact above the
  threshold.
- `monitors_*` — the fail-closed sentinel is sound and complete with respect
  to the monitor invariant.
- `pirTM_*` — strict contraction per tick and eventual convergence to the
  fixed point `budget = 0`.

## Traceability

- `trace_*` — every ADR has a reconstructible, non-empty supersession
  history whose first element is the ADR itself.

Proof sketches are provided in the docstring of each theorem.
-/

namespace ADR.Proofs

open ADR
open ADR.Formal

/-! ### Governance theorems -/

/-- **Once `Accepted`, a status change requires a superseding ADR.**

Sketch: case analysis on `ValidTransition`. The `accept` rule requires the
source to be `Proposed`, contradicting `hsrc` (constructor injectivity);
`supersede` and `deprecate` both carry the successor's `supersedes` field
equal to `some src.id` by construction. -/
@[proof]
theorem accepted_transition_requires_supersession {src dst : ADR}
    (h : ValidTransition src dst) (hsrc : src.status = ADRStatus.Accepted) :
    dst.supersedes = some src.id := by
  cases h with
  | accept h1 _ _ =>
      rw [h1] at hsrc
      cases hsrc
  | supersede _ hd =>
      exact hd
  | deprecate _ _ hd =>
      exact hd

/-- **Immutability:** an `Accepted` ADR cannot become `Accepted` again
without naming a superseding ADR.

Sketch: as above; in the `deprecate` branch the successor's status is
`Deprecated`, contradicting `hdst`. -/
@[proof]
theorem accepted_cannot_become_accepted_without_supersession {src dst : ADR}
    (h : ValidTransition src dst) (hsrc : src.status = ADRStatus.Accepted)
    (hdst : dst.status = ADRStatus.Accepted) :
    dst.supersedes = some src.id := by
  cases h with
  | accept h1 _ _ =>
      rw [h1] at hsrc
      cases hsrc
  | supersede _ hd =>
      exact hd
  | deprecate _ h1 _ =>
      rw [h1] at hdst
      cases hdst

/-- **Registry discipline:** the accepted and proposed sublists of a registry
are disjoint — no ADR is simultaneously accepted and proposed.

Sketch: `List.mem_filter` extracts `a.status == Accepted = true`; rewriting
`a.status` to `Proposed` makes the left side compute to `false`, contradicting
the extracted equality (a `decide`-proved negation closes the case). -/
@[proof]
theorem registry_accepted_not_proposed (reg : Registry) {a : ADR}
    (ha : a ∈ reg.accepted) :
    a.status ≠ ADRStatus.Proposed := by
  unfold Registry.accepted at ha
  have hbeq : (a.status == ADRStatus.Accepted) = true := (List.mem_filter.mp ha).2
  intro hProp
  rw [hProp] at hbeq
  have hn : ¬ ((ADRStatus.Proposed == ADRStatus.Accepted) = true) := by decide
  exact hn hbeq

/-! ### Formal model theorems (ADR-009) -/

/-! #### Processable guard -/

/-- **Guard soundness:** a processable query respects the resolution guard. -/
@[proof]
theorem processable_width_bound (q : Query) (g : Nat) (h : Processable q g) :
    q.kernelWidth ≤ g := h.1

/-- **Guard strictness:** a processable query has a positive kernel width. -/
@[proof]
theorem processable_positive_width (q : Query) (g : Nat) (h : Processable q g) :
    0 < q.kernelWidth := h.2

/-- **Guard monotonicity:** relaxing the resolution guard preserves
processability. -/
@[proof]
theorem processable_monotone (q : Query) {g1 g2 : Nat}
    (h1 : Processable q g1) (hg : g1 ≤ g2) :
    Processable q g2 := ⟨Nat.le_trans h1.1 hg, h1.2⟩

/-! #### QCheck / LatticeAligned -/

/-- **QCheck correctness:** `QCheck p q ε = true` iff the extents are
lattice-aligned within `ε`.

Sketch: unfold `QCheck` and `LatticeAligned`; `Bool.and_eq_true` distributes
the `= true` over each `&&`; `decide_eq_true_eq` identifies each scalar
`aligned` check. -/
@[proof]
theorem qcheck_iff_lattice_aligned (p q : LatticePoint) (ε : Nat) :
    QCheck p q ε = true ↔ LatticeAligned p q ε := by
  unfold QCheck LatticeAligned
  simp [Bool.and_eq_true]

/-- **QCheck reflexivity:** every point is aligned with itself for any `ε`. -/
@[proof]
theorem qcheck_refl (p : LatticePoint) (ε : Nat) : QCheck p p ε = true := by
  simp [QCheck, aligned]

/-- **Aligned reflexivity (propositional form).** -/
@[proof]
theorem lattice_aligned_refl (p : LatticePoint) (ε : Nat) : LatticeAligned p p ε := by
  exact qcheck_iff_lattice_aligned p p ε |>.mp (qcheck_refl p ε)

/-- **Alignment is a symmetric relation.** -/
@[proof]
theorem lattice_aligned_symm (p q : LatticePoint) (ε : Nat) :
    LatticeAligned p q ε → LatticeAligned q p ε := by
  intro h
  simp [LatticeAligned, aligned] at h ⊢
  omega

/-- **QCheck returns `false` for misaligned points** (witness that the
check is not vacuously true). -/
@[proof]
theorem qcheck_misalignment_detected :
    QCheck { x := 0, y := 0, z := 0 } { x := 5, y := 0, z := 0 } 2 = false := by
  native_decide

/-! #### Physical domain -/

/-- **Physical boundedness (x):** a physical point has a bounded x extent. -/
@[proof]
theorem physical_bounded_x (d : Domain) (p : LatticePoint) (h : Physical d p) :
    Int.natAbs p.x ≤ d.halfSize := h.1

/-- **Physical boundedness (y):** a physical point has a bounded y extent. -/
@[proof]
theorem physical_bounded_y (d : Domain) (p : LatticePoint) (h : Physical d p) :
    Int.natAbs p.y ≤ d.halfSize := h.2.1

/-- **Physical boundedness (z):** a physical point has a bounded z extent. -/
@[proof]
theorem physical_bounded_z (d : Domain) (p : LatticePoint) (h : Physical d p) :
    Int.natAbs p.z ≤ d.halfSize := h.2.2

/-- **Distance boundedness:** two physical points are at distance at most
`6 · halfSize`.

Sketch: `Int.natAbs_sub_le` gives `|a - b| ≤ |a| + |b|`, each of which is
`≤ halfSize` by `Physical`; the three coordinate bounds sum to `6 · halfSize`. -/
@[proof]
theorem physical_dist_bounded (d : Domain) (p q : LatticePoint)
    (hp : Physical d p) (hq : Physical d q) :
    metric p q ≤ 6 * d.halfSize := by
  unfold metric
  have hxp : Int.natAbs p.x ≤ d.halfSize := hp.1
  have hxq : Int.natAbs q.x ≤ d.halfSize := hq.1
  have hyp : Int.natAbs p.y ≤ d.halfSize := hp.2.1
  have hyq : Int.natAbs q.y ≤ d.halfSize := hq.2.1
  have hzp : Int.natAbs p.z ≤ d.halfSize := hp.2.2
  have hzq : Int.natAbs q.z ≤ d.halfSize := hq.2.2
  have hx : Int.natAbs (p.x - q.x) ≤ Int.natAbs p.x + Int.natAbs q.x :=
    Int.natAbs_sub_le p.x q.x
  have hxb : Int.natAbs p.x + Int.natAbs q.x ≤ 2 * d.halfSize := by
    omega
  have hy : Int.natAbs (p.y - q.y) ≤ Int.natAbs p.y + Int.natAbs q.y :=
    Int.natAbs_sub_le p.y q.y
  have hyb : Int.natAbs p.y + Int.natAbs q.y ≤ 2 * d.halfSize := by
    omega
  have hz : Int.natAbs (p.z - q.z) ≤ Int.natAbs p.z + Int.natAbs q.z :=
    Int.natAbs_sub_le p.z q.z
  have hzb : Int.natAbs p.z + Int.natAbs q.z ≤ 2 * d.halfSize := by
    omega
  omega

/-! #### ACE budget -/

/-- **Budget condition soundness:** a satisfied budget is below its
resonance level. -/
@[proof]
theorem ace_budget_satisfies_below_resonance (b : ACEBudget) (h : b.satisfies) :
    b.budget < b.resonance := h

/-- **Budget condition safety:** a budget below a bounded resonance is below
the Planck bound. -/
@[proof]
theorem ace_budget_resonance_bounded (b : ACEBudget) (h : b.satisfies)
    (hb : b.resonance ≤ PlanckResonance) :
    b.budget < PlanckResonance := Nat.lt_of_lt_of_le h hb

/-! #### ACE projection (soft threshold) -/

/-- **Projection is sub-identity:** `softThreshold l x ≤ x`.

Sketch: `by_cases x > l`. If so, the result is `x - l` and `Nat.sub_le`;
otherwise the result is `0 ≤ x`. -/
@[proof]
theorem softThreshold_le (l x : Nat) : softThreshold l x ≤ x := by
  unfold softThreshold
  by_cases h : x > l
  · have hsub : x - l ≤ x := Nat.sub_le x l
    simpa [h] using hsub
  · simp [h]

/-- **Projection exactness:** above the threshold, projection is the
identity shift `x ↦ x - l`. -/
@[proof]
theorem softThreshold_id (l x : Nat) (h : l ≤ x) : softThreshold l x = x - l := by
  unfold softThreshold
  by_cases hgt : x > l
  · simp [hgt]
  · have hEq : x = l := by omega
    simp [hgt, hEq]

/-- **Projection fixed point:** at or below the threshold, projection maps
the value to `0`. -/
@[proof]
theorem softThreshold_zero_below (l x : Nat) (h : x < l) : softThreshold l x = 0 := by
  unfold softThreshold
  by_cases hgt : x > l
  · have : x < x := Nat.lt_trans h hgt
    omega
  · simp [hgt]

/-! #### Audit monitors (SlopeUB / GapLB / budget sum) -/

/-- **Sentinel soundness and completeness:** the fail-closed sentinel is
`false` exactly when the monitor invariant holds.

Sketch: unfold both sides; each conjunct of `MonitorsSatisfied` is a
decidable proposition whose `decide` matches the corresponding `Bool` in
`failClosed`, so `simp [Bool.and_eq_true, decide_eq_true_eq]` closes both
directions. -/
@[proof]
theorem monitors_satisfied_iff_no_failClosed (th : MonitorThresholds)
    (m : AuditMonitors) :
    MonitorsSatisfied th m ↔ failClosed th m = false := by
  unfold MonitorsSatisfied failClosed
  simp [Bool.and_eq_true, Bool.not_eq_false, decide_eq_true_eq]

/-- **Fail-closed detection:** if the monitor invariant is violated the
sentinel must be `true` (no silent degradation).

Sketch: a `Bool` is either `false` or `true`; from the iff above the
violation rules out `false`, leaving `true`. -/
@[proof]
theorem failClosed_detects_violation (th : MonitorThresholds) (m : AuditMonitors)
    (h : ¬ MonitorsSatisfied th m) :
    failClosed th m = true := by
  have hno : failClosed th m ≠ false := by
    intro hf
    apply h
    exact (monitors_satisfied_iff_no_failClosed th m).mpr hf
  cases h : failClosed th m with
  | false => exact False.elim (hno h)
  | true => rfl

/-- **No false alarm:** a healthy monitor never trips the sentinel. -/
@[proof]
theorem failClosed_no_false_alarm (th : MonitorThresholds) (m : AuditMonitors)
    (h : MonitorsSatisfied th m) :
    failClosed th m = false := by
  exact (monitors_satisfied_iff_no_failClosed th m).mp h

/-! #### PIRTM dynamics and convergence -/

/-- **Strict contraction per tick:** a positive budget strictly decreases
under every safe contraction factor.

Sketch: `pirTMstep k s` sets the budget to `s.budget / k`; `Nat.div_lt_self`
yields `s.budget / k < s.budget` for `0 < s.budget` and `1 < k`, and
`2 ≤ k` gives `1 < k` by `omega`. -/
@[proof]
theorem pirTMstep_reduces_budget (k : Nat) (hk : 2 ≤ k) {s : PIRTMState}
    (hb : 0 < s.budget) :
    (pirTMstep k s).budget < s.budget := by
  unfold pirTMstep
  have hk1 : 1 < k := by omega
  exact Nat.div_lt_self hb hk1

/-- **Zero budget is a fixed point:** the contraction leaves a zero budget
at zero. -/
@[proof]
theorem pirTMstep_zero_fixed (k : Nat) (s : PIRTMState) (hb : s.budget = 0) :
    (pirTMstep k s).budget = 0 := by
  unfold pirTMstep
  simp [hb]

/-- **Eventual convergence (helper):** from any budget, finitely many PIRTM
ticks reach the fixed point `budget = 0`.

Sketch: strong induction on the budget. If `s.budget = 0` we are done;
otherwise one tick strictly reduces the budget (`pirTMstep_reduces_budget`),
and the induction hypothesis applies to the reduced budget. This is the
formal content of "fixed-point convergence of PIRTM when budget < 1": the
contraction factor `1/k < 1` guarantees a finite convergence time. -/
private theorem pirTM_eventually_fixed_aux (k : Nat) (hk : 2 ≤ k) (s : PIRTMState) :
    ∀ b : Nat, s.budget = b → ∃ n : Nat, (iterate (pirTMstep k) n s).budget = 0 := by
  intro b
  revert s
  refine Nat.strongRecOn b ?_
  intro b ih s hs
  by_cases hz : s.budget = 0
  · have hzero : (iterate (pirTMstep k) 0 s).budget = 0 := by
      simp [hz]
    exact ⟨0, hzero⟩
  · have hpos : 0 < s.budget := Nat.pos_of_ne_zero hz
    let s' := pirTMstep k s
    have hs'lt : s'.budget < b := by
      unfold s'
      have hred : (pirTMstep k s).budget < s.budget := pirTMstep_reduces_budget k hk hpos
      exact lt_of_lt_of_eq hred hs
    rcases ih s'.budget hs'lt s' rfl with ⟨n, hn⟩
    refine ⟨n + 1, ?_⟩
    simpa [s', iterate_succ, pirTMstep] using hn

/-- **PIRTM convergence:** for any safe contraction factor `k ≥ 2` and any
starting state, the iterated PIRTM map reaches the fixed point `budget = 0`
in finitely many ticks. -/
@[proof]
theorem pirTM_converges (k : Nat) (hk : 2 ≤ k) (s : PIRTMState) :
    ∃ n : Nat, (iterate (pirTMstep k) n s).budget = 0 :=
  pirTM_eventually_fixed_aux k hk s s.budget rfl

/-- **Convergence certificate:** every safe factor yields a valid PIRTM
convergence certificate. -/
def pirTM_certificate (k : Nat) (hk : 2 ≤ k) : PIRTMConvergence :=
  { factor := k, factorSafe := hk }

/-! ### Traceability -/

end ADR.Proofs

/-! # Traceability machinery (namespace `ADR`) -/

namespace ADR
open ADR.Formal

/-- The result of reconstructing an ADR's supersession history. -/
structure TraceResult where
  path : List String
  cycleDetected : Bool
  deriving Repr, BEq

/-- Walk the supersession pointers of a registry, bounded by the registry
size, recording the visited ids in order.

`cycleDetected = true` means the walk either revisited an id or failed to
resolve a `supersedes` pointer (dangling reference). -/
def traceGo (reg : List ADR) : Nat → List String → ADR → TraceResult
  | 0, acc, a => { path := acc ++ [a.id], cycleDetected := true }
  | m + 1, acc, a =>
      if a.id ∈ acc then { path := acc ++ [a.id], cycleDetected := true }
      else match a.supersedes with
        | none => { path := acc ++ [a.id], cycleDetected := false }
        | some target =>
            match reg.find? (fun b => b.id == target) with
            | none => { path := acc ++ [a.id], cycleDetected := true }
            | some b => traceGo reg m (acc ++ [a.id]) b

/-- Reconstruct the supersession history of `a` within a registry, in order
from `a` back to the root (an ADR with `supersedes = none`). -/
def Registry.trace (reg : Registry) (a : ADR) : TraceResult :=
  traceGo reg.adrs reg.adrs.length [] a

end ADR

namespace ADR.Proofs
open ADR
open ADR.Formal

/-- Every reconstructed history is non-empty (it contains at least the ADR
itself). -/
private theorem traceGo_nonempty (reg : List ADR) :
    ∀ (n : Nat) (acc : List String) (a : ADR),
      1 ≤ (traceGo reg n acc a).path.length := by
  intro n
  induction n with
  | zero =>
      intro acc a
      simp [traceGo]
  | succ n ih =>
      intro acc a
      unfold traceGo
      by_cases hmem : a.id ∈ acc
      · simp [hmem]
      · cases a.supersedes with
        | none => simp [hmem]
        | some target =>
            cases reg.find? (fun b => b.id == target) with
            | none => simp [hmem]
            | some b => exact ih (acc ++ [a.id]) b

/-- The reconstructed history starts with the ADR itself. -/
private theorem traceGo_head (reg : List ADR) :
    ∀ (n : Nat) (acc : List String) (a : ADR),
      (traceGo reg n acc a).path.head? = (acc ++ [a.id]).head? := by
  intro n
  induction n with
  | zero =>
      intro acc a
      simp [traceGo]
  | succ n ih =>
      intro acc a
      unfold traceGo
      by_cases hmem : a.id ∈ acc
      · simp [hmem]
      · cases a.supersedes with
        | none => simp [hmem]
        | some target =>
            cases reg.find? (fun b => b.id == target) with
            | none => simp [hmem]
            | some b =>
                simp [hmem]
                have hih := ih (acc ++ [a.id]) b
                rw [hih]
                cases acc <;> simp

/-- **Traceability (non-emptiness):** every ADR has a reconstructible,
non-empty history. -/
@[proof]
theorem trace_nonempty (reg : Registry) (a : ADR) :
    1 ≤ (reg.trace a).path.length := by
  unfold Registry.trace
  simpa using (traceGo_nonempty reg.adrs reg.adrs.length [] a)

/-- **Traceability (origin):** the reconstructed history begins with the ADR
being traced. -/
@[proof]
theorem trace_reconstructs_history (reg : Registry) (a : ADR) :
    (reg.trace a).path.head? = some a.id := by
  unfold Registry.trace
  simpa using (traceGo_head reg.adrs reg.adrs.length [] a)

/-- **Traceability (root reachable):** walking a history whose terminal node
has no `supersedes` pointer and has not already been visited yields
`cycleDetected = false`.

Proof sketch: induction on the walk budget. The base case `m = 0` (budget
`1`) resolves the `supersedes = none` branch immediately; the step case does
the same after ruling out the visited-id branch with `hnotin`. -/
private theorem traceGo_root_reachable (reg : List ADR) :
    ∀ (m : Nat) (acc : List String) (a : ADR),
      a.id ∉ acc → a.supersedes = none → (traceGo reg (m + 1) acc a).cycleDetected = false := by
  intro m
  induction m with
  | zero =>
      intro acc a hnotin hnone
      unfold traceGo
      simp [hnone, hnotin]
  | succ m ih =>
      intro acc a hnotin hnone
      unfold traceGo
      by_cases hmem : a.id ∈ acc
      · exact False.elim (hnotin hmem)
      · simp [hmem, hnone]

/-- **Traceability (root reachable):** for an ADR present in the registry with
no `supersedes` pointer, the reconstructed history reaches the root cleanly
(no cycle, no dangling reference). -/
@[proof]
theorem trace_root_reachable (reg : Registry) (a : ADR)
    (hmem : a ∈ reg.adrs) (hnone : a.supersedes = none) :
    (reg.trace a).cycleDetected = false := by
  unfold Registry.trace
  revert hmem
  cases reg.adrs with
  | nil =>
      intro hmem
      exact False.elim (List.not_mem_nil (a := a) hmem)
  | cons b rest =>
      intro hmem
      rw [List.length_cons]
      exact traceGo_root_reachable (b :: rest) rest.length [] a (by simp) hnone

/-! ### Consequence entailment (deliberately minimal) -/

/-- Split a string into words by spaces. -/
def wordsOf (s : String) : List String :=
  let rec go (cs : List Char) (current : List Char) (acc : List String) : List String :=
    match cs with
    | [] => (String.ofList current.reverse :: acc).reverse
    | c :: rest =>
      if c = ' ' then
        go rest [] (if current.length = 0 then acc else String.ofList current.reverse :: acc)
      else
        go rest (c :: current) acc
  go s.toList [] []

/-- Simple entailment check: a consequence is entailed when it is non-empty
and its words are a subset of the words in context + decision.

`(deliberately minimal: the checker is a word-subset test over prose; a
production system replaces it with a structured DSL whose entailment is
decidable by construction, per ADR-009 Phase 1.)` -/
def entails (context decision consequence : String) : Bool :=
  let words := wordsOf context ++ wordsOf decision
  let cwords := wordsOf consequence
  cwords.all (fun w => List.elem w words) && consequence != ""

/-- Convert `Bool` entailment into a proposition. -/
def entails_prop (context decision consequence : String) : Prop :=
  entails context decision consequence = true

/-- **Entailment sanity:** an entailed consequence is never the empty
string. -/
@[proof]
theorem entails_implies_nonempty (h : entails c d x = true) : x ≠ "" := by
  unfold entails at h
  simp at h
  intro hx
  rw [hx] at h
  simp at h

end ADR.Proofs
