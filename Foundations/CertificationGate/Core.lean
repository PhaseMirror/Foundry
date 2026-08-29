/-!
# Foundations.CertificationGate.Core — Certification Gate & Triple-Lock Governance Invariants

Formalizes spectral admissibility, ledger invariants, gate completeness, and triple-lock
circuit breaker invariants (ADR-034 / ADR-094 / ADR-MC-001).
-/

namespace Foundations.CertificationGate

/-- A Session represents an execution instance characterized by spectral radius rho. -/
structure Session where
  id : String
  spectralRadius : Nat -- Fixed point scaled by 1000 (< 1000 implies rho < 1.0)
  deriving Repr, DecidableEq

/-- A session is Admissible if its spectral radius is strictly bounded below 1.0 (1000). -/
def is_admissible (s : Session) : Prop :=
  s.spectralRadius < 1000

/-- The Ledger is a list of certified sessions. -/
abbrev Ledger := List Session

/-- The invariant of the Ledger: it only contains admissible sessions. -/
def ledger_invariant (l : Ledger) : Prop :=
  ∀ s ∈ l, is_admissible s

/-- The Certification Gate check: passes if the session is found in a lawful ledger. -/
def check_ready (s : Session) (l : Ledger) : Prop :=
  ledger_invariant l ∧ s ∈ l

/-- Theorem: Certification Gate Completeness.
    If a session passes the check_ready gate, it is mathematically guaranteed to be admissible. -/
theorem certification_gate_completeness {s : Session} {l : Ledger} :
    check_ready s l → is_admissible s := by
  intro h
  let ⟨h_inv, h_in⟩ := h
  exact h_inv s h_in

/-- Triple-lock status: three independent guardians must approve. -/
structure TripleLock where
  guardian_approved : Bool
  examiner_audited  : Bool
  publisher_signed  : Bool
  deriving Repr, DecidableEq

/-- A TripleLock is engaged if and only if all three roles approve. -/
def TripleLock.is_locked (tl : TripleLock) : Prop :=
  tl.guardian_approved = true ∧ tl.examiner_audited = true ∧ tl.publisher_signed = true

/-- Theorem: Triple-Lock Completeness. -/
theorem triple_lock_complete (tl : TripleLock) :
    tl.guardian_approved = true →
    tl.examiner_audited = true →
    tl.publisher_signed = true →
    tl.is_locked := by
  intro hg he hp
  exact ⟨hg, he, hp⟩

/-- Theorem: Triple-Lock Soundness. -/
theorem triple_lock_sound (tl : TripleLock) :
    tl.is_locked →
    tl.guardian_approved = true ∧ tl.examiner_audited = true ∧ tl.publisher_signed = true := by
  intro ⟨hg, he, hp⟩
  exact ⟨hg, he, hp⟩

/-- Theorem: No Bypass via Triple Lock.
    If the triple-lock is not engaged, the session cannot achieve full dual certification. -/
theorem no_bypass_triple_lock (s : Session) (l : Ledger) (tl : TripleLock) :
    ¬tl.is_locked →
    ¬(check_ready s l ∧ tl.is_locked) := by
  intro h_nolock ⟨_, h_lock⟩
  exact h_nolock h_lock

end Foundations.CertificationGate
