/-!
# Foundations.Zenolock.Core — Zeno Lock Concurrency Guard & State Machine
-/

namespace Foundations.Zenolock

inductive LockStatus where
  | Unlocked
  | Locked (owner : Nat) (nonce : Nat)
  | Degraded (reason : String)
  deriving Repr, DecidableEq

structure ZenoLock where
  status       : LockStatus
  failureCount : Nat
  maxFailures  : Nat
  deriving Repr, DecidableEq

def isLocked (lock : ZenoLock) : Bool :=
  match lock.status with
  | LockStatus.Locked _ _ => true
  | _ => false

def acquire (lock : ZenoLock) (owner : Nat) (nonce : Nat) : ZenoLock :=
  match lock.status with
  | LockStatus.Unlocked => { lock with status := LockStatus.Locked owner nonce }
  | LockStatus.Locked cur_owner _ =>
      if cur_owner == owner then lock
      else { lock with failureCount := lock.failureCount + 1,
                       status := if lock.failureCount + 1 ≥ lock.maxFailures
                                 then LockStatus.Degraded "Max lock contention reached"
                                 else lock.status }
  | LockStatus.Degraded _ => lock

def release (lock : ZenoLock) (owner : Nat) : ZenoLock :=
  match lock.status with
  | LockStatus.Locked cur_owner _ =>
      if cur_owner == owner then { lock with status := LockStatus.Unlocked }
      else lock
  | _ => lock

theorem acquire_unlocked_succeeds (lock : ZenoLock) (owner nonce : Nat)
    (h : lock.status = LockStatus.Unlocked) :
    (acquire lock owner nonce).status = LockStatus.Locked owner nonce := by
  unfold acquire
  simp [h]

end Foundations.Zenolock
