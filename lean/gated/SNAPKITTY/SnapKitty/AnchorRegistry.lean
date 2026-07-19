/-
  AnchorRegistry — Formal Verification (ADR-PML-055)
  --------------------------------------------------
  This module is the Lean4 formal mirror of `contracts/AnchorRegistry.sol`.
  It proves the invariants cited in ADR-PML-055 §Risks: root uniqueness (the
  newly anchored block is fresh), no replay (a root cannot be re-anchored at an
  already-used block), and authenticated submission (only an allowlisted
  sidecar may transition the anchor state).

  Style follows `lean/gated/SNAPKITTY/SnapKitty/Contracts.lean`.
-/

namespace Multiplicity.AnchorRegistry

/-- A cryptographic root plus the UTC timestamp asserted by the sidecar. -/
structure Anchor where
  root : String
  timestamp : Nat
  blockNumber : Nat
  signer : String
  deriving DecidableEq, Repr

/-- The on-chain registry state: a list of anchors plus the allowlisted signers. -/
structure Registry where
  anchors : List Anchor
  authorizedSidecars : List String
  deriving DecidableEq, Repr

/-- Result of attempting to submit a root. -/
inductive SubmitResult
  | success (newState : Registry)
  | rejectedNotSidecar
  | rejectedZeroRoot
  | rejectedReplay

/-- True when `bn` already appears among the anchored block numbers. -/
def replayed (state : Registry) (bn : Nat) : Bool :=
  state.anchors.any fun a => a.blockNumber = bn

/--
  The state transition. Mirrors `submitRoot`:
  - rejects if the block is already used (replay protection),
  - rejects a zero root,
  - rejects if the recovered signer is not authorized,
  - otherwise appends the anchor.
-/
def submit (state : Registry) (root : String) (timestamp : Nat) (blockNumber : Nat) (signer : String) : SubmitResult :=
  if replayed state blockNumber then
    SubmitResult.rejectedReplay
  else if root = "" then
    SubmitResult.rejectedZeroRoot
  else if ¬ (signer ∈ state.authorizedSidecars) then
    SubmitResult.rejectedNotSidecar
  else
    SubmitResult.success
      { anchors := state.anchors ++ [⟨root, timestamp, blockNumber, signer⟩]
      , authorizedSidecars := state.authorizedSidecars }

/--
  Authenticated Submission Invariant:
  A submission only transitions state when the signer is an authorized sidecar.
-/
theorem submit_requires_authorized_sidecar
    (state : Registry) (root : String) (ts : Nat) (bn : Nat) (signer : String)
    (h_success : ∃ s', submit state root ts bn signer = SubmitResult.success s') :
    signer ∈ state.authorizedSidecars := by
  obtain ⟨_, hs⟩ := h_success
  simp only [submit] at hs
  split at hs
  · contradiction
  · split at hs
    · contradiction
    · by_cases hc : signer ∈ state.authorizedSidecars
      · exact hc
      · simp only [hc] at hs
        contradiction

/--
  No Replay Invariant:
  If a block number is already present in the anchor history, submission reverts.
-/
theorem replay_protection_invariant
    (state : Registry) (root : String) (ts : Nat) (bn : Nat) (signer : String)
    (h_used : replayed state bn = true) :
    submit state root ts bn signer = SubmitResult.rejectedReplay := by
  simp only [submit]
  rw [h_used]
  simp

/--
  Zero Root Invariant:
  With no replay, an empty root always resolves to `rejectedZeroRoot`, independent
  of the authorizing signer.
-/
theorem zero_root_rejected
    (state : Registry) (ts : Nat) (bn : Nat) (signer : String)
    (h_fresh : replayed state bn = false) :
    submit state "" ts bn signer = SubmitResult.rejectedZeroRoot := by
  simp only [submit]
  rw [h_fresh]
  simp

/--
  Root Uniqueness Invariant:
  After a successful submission, the only anchor whose block number equals `bn`
  is the newly appended one. The new block is fresh by construction of the
  success branch (see `replay_protection_invariant`).
-/
theorem root_uniqueness
    (state : Registry) (root : String) (ts : Nat) (bn : Nat) (signer : String)
    (h_fresh : replayed state bn = false)
    (h_auth : signer ∈ state.authorizedSidecars)
    (h_nonzero : root ≠ "")
    (s' : Registry)
    (h_success : submit state root ts bn signer = SubmitResult.success s') :
    ∀ a ∈ s'.anchors, a.blockNumber = bn → a = ⟨root, ts, bn, signer⟩ := by
  simp only [submit, h_fresh, h_auth, h_nonzero] at h_success
  injection h_success with h_anchors
  rw [← h_anchors]
  intro a h_mem h_eq
  simp only [List.mem_append] at h_mem
  cases h_mem with
  | inl h_old =>
    -- old anchor cannot have blockNumber = bn (freshness invariant)
    rw [replayed, List.any_eq_false] at h_fresh
    have : ¬ decide (a.blockNumber = bn) = true := h_fresh a h_old
    rw [decide_eq_true_iff] at this
    contradiction
  | inr h_new =>
    rw [List.mem_singleton] at h_new
    rw [h_new]

/--
  State Monotonicity Invariant:
  The set of authorized sidecars is unchanged by a submission, and the anchor
  list grows monotonically.
-/
theorem state_monotonicity
    (state : Registry) (root : String) (ts : Nat) (bn : Nat) (signer : String)
    (h_fresh : replayed state bn = false)
    (h_auth : signer ∈ state.authorizedSidecars)
    (h_nonzero : root ≠ "")
    (s' : Registry)
    (h_success : submit state root ts bn signer = SubmitResult.success s') :
    state.authorizedSidecars = s'.authorizedSidecars ∧
    state.anchors.length < s'.anchors.length := by
  simp only [submit, h_fresh, h_auth, h_nonzero] at h_success
  injection h_success with h_anchors
  rw [← h_anchors]
  constructor
  · rfl
  · simp only [List.length_append, List.length_singleton]
    exact Nat.lt_succ_self (state.anchors.length)

end Multiplicity.AnchorRegistry
