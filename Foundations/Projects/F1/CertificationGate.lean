/-!
# CertificationGate — formal linkage for the documented control surfaces

This module backs the README/Governance claim that the certification
pipeline enforces a **triple-lock** (examiner → guardian → publisher) plus a
**guardian veto**, with no bypass route. It is deliberately dependency-free
(no Mathlib) so the linkage theorems reduce to kernel-checked `Bool` algebra.

Model
-----
* Each of the three governance domains holds a `LockState`.
* A `GateRequest` carries the anomaly score scaled to integer micro-units
  against a declared ceiling, the triple-lock state, and the guardian veto bit.
* `certify` emits `certified` only when the veto is clear, the anomaly score
  is below the ceiling, and every lock is engaged. Every other combination
  yields `rejected`.

Linkage theorems (the point of this module)
-------------------------------------------
* `certification_gate_veto_link`          — a guardian veto forces rejection.
* `certification_gate_triple_lock_full`   — clean request + full lock ⇒ certified.
* `no_bypass_triple_lock`                 — any open lock ⇒ cannot certify.
* `certification_gate_triple_lock_sound`  — certification implies the exact
  conjunct of preconditions (veto clear, below ceiling, all locks engaged).
* `triple_lock_complete`                  — those preconditions imply
  certification (round-trip with the sound direction).

Governance constants mirror `alp_sorry_manifest.json` /
`invariant_gaps.lean`: values are carried in integer micro-units so all
comparisons stay decidable inside the kernel.
-/

namespace CertificationGate

/-! ### Governance constants (integer-scaled, kernel-decidable) -/

/-- Anomaly governor ceiling, 0.85 scaled to one-millionth units. -/
def ANOMALY_GOV_CEILING_MICRO : Nat := 850000

/-- Anomaly governor alert threshold, 0.0006 scaled to one-millionth units. -/
def ANOMALY_GOV_THRESHOLD_MICRO : Nat := 600

/-- The published ceiling strictly dominates the alert threshold. -/
theorem ceiling_above_threshold :
    ANOMALY_GOV_THRESHOLD_MICRO < ANOMALY_GOV_CEILING_MICRO := by decide

/-! ### Lock and verdict model -/

/-- State of a single governance lock. -/
inductive LockState where
  | open_  : LockState
  | locked : LockState
  deriving DecidableEq, Repr

/-- The three documented governance domains. -/
inductive LockDomain where
  | examiner  : LockDomain
  | guardian  : LockDomain
  | publisher : LockDomain
  deriving DecidableEq, Repr

/-- Verdict emitted by the certification gate. -/
inductive Verdict where
  | certified : Verdict
  | rejected  : Verdict
  deriving DecidableEq, Repr

/-- The triple-lock: one independent lock per governance domain. -/
structure TripleLock where
  examiner  : LockState
  guardian  : LockState
  publisher : LockState
  deriving Repr

/-- A request presented to the certification gate.
Fields:
* `anomalyMicro` — anomaly score scaled to one-millionth units;
* `anomalyCeilingMicro` — declared ceiling in the same units;
* `tripleLock` — independent state of each of the three governance locks;
* `guardianVeto` — explicit guardian veto bit. -/
structure GateRequest where
  anomalyMicro : Nat
  anomalyCeilingMicro : Nat
  tripleLock : TripleLock
  guardianVeto : Bool
  deriving Repr

/-- All three governance locks are engaged simultaneously. -/
def allLocked (t : TripleLock) : Bool :=
  (t.examiner == .locked) && (t.guardian == .locked) && (t.publisher == .locked)

/-- Full conjunction of pass conditions, kept as `Bool` for kernel reduction. -/
def gatePasses (r : GateRequest) : Bool :=
  !r.guardianVeto
    && (r.anomalyMicro < r.anomalyCeilingMicro)
    && allLocked r.tripleLock

/-- The single certification decision point. There is no other entry path. -/
def certify (r : GateRequest) : Verdict :=
  if gatePasses r then .certified else .rejected

/-! ### Linkage theorems -/

/-- **Veto link.** When the guardian raises the veto bit, the gate rejects,
regardless of the anomaly score or the state of any lock. This is the formal
statement that the documented veto authority is wired to enforcement. -/
theorem certification_gate_veto_link (r : GateRequest)
    (hv : r.guardianVeto = true) :
    certify r = .rejected := by
  simp [certify, gatePasses, hv]

/-- **Triple-lock completeness.** A clean request (no veto, anomaly below
ceiling) with all three locks engaged is certified. -/
theorem certification_gate_triple_lock_full (r : GateRequest)
    (hv : r.guardianVeto = false)
    (hb : r.anomalyMicro < r.anomalyCeilingMicro)
    (hl : allLocked r.tripleLock = true) :
    certify r = .certified := by
  have hp : gatePasses r = true := by
    simp [gatePasses, hv, hb, hl]
  simp [certify, hp]

/-- **No bypass.** If any governance lock is open, the gate cannot emit
`certified` — there is no code path around the triple-lock conjunction. -/
theorem no_bypass_triple_lock (r : GateRequest)
    (hl : allLocked r.tripleLock = false) :
    certify r ≠ .certified := by
  have hnp : gatePasses r = false := by
    simp [gatePasses, hl]
  simp [certify, hnp]

/-- **Triple-lock soundness.** Certification implies the full precondition
conjunction: veto clear, anomaly below ceiling, all locks engaged. -/
theorem certification_gate_triple_lock_sound (r : GateRequest)
    (h : certify r = .certified) :
    r.guardianVeto = false
      ∧ (r.anomalyMicro < r.anomalyCeilingMicro)
      ∧ allLocked r.tripleLock = true := by
  unfold certify at h
  split at h
  case isTrue hp =>
    have hp2 :
        (r.guardianVeto = false ∧ r.anomalyMicro < r.anomalyCeilingMicro)
          ∧ allLocked r.tripleLock = true := by
      simpa [gatePasses] using hp
    exact ⟨hp2.1.1, hp2.1.2, hp2.2⟩
  case isFalse =>
    simp at h

/-- **Round-trip completeness**: the soundness conjunction is exactly the
precondition accepted by `certification_gate_triple_lock_full`, so the gate
admits precisely the intended set of requests. -/
theorem triple_lock_complete (r : GateRequest)
    (h : r.guardianVeto = false
      ∧ (r.anomalyMicro < r.anomalyCeilingMicro)
      ∧ allLocked r.tripleLock = true) :
    certify r = .certified := by
  obtain ⟨hv, hb, hl⟩ := h
  exact certification_gate_triple_lock_full r hv hb hl

end CertificationGate
