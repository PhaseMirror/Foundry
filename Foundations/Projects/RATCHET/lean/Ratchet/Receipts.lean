import Ratchet.Types

/-!
# Ratchet.Receipts — Cryptographic Safety Receipts & Complexity Ceilings

Formalizes operational schema and audit criteria for safety receipts and complexity ceilings:
- ReceiptRecord: burst metadata, T_pred, lambda_hat, C3/post-use bits, C_ext signature
- CeilingRecord: coordinate limits, lambda cap, rate limits, mandatory review triggers
-/

namespace Ratchet

/-- Safety Receipt record format (ADR-0038 §8.1). -/
structure ReceiptRecord where
  burst_id         : Nat
  snapshot_id      : Nat
  t_pred_used      : Nat
  lambda_hat_final : Nat
  v_score_final    : Nat
  c3_pass          : Bool
  post_use_pass    : Bool
  state_hash       : String
  c_ext_signature  : String
  issue_time       : Nat
  expiry_time      : Nat
  deriving Repr, DecidableEq

/-- Complexity Ceiling record format (ADR-0038 §8.2). -/
structure CeilingRecord where
  max_coordinates     : Nat
  max_lambda_hat      : Nat
  max_theta_norm      : Nat
  max_v_change        : Nat
  max_bursts_unscaled : Nat
  deriving Repr, DecidableEq

/-- Valid receipt predicate: all verification bits set, non-empty signature, unexpired. -/
def is_receipt_valid (r : ReceiptRecord) (current_time : Nat) : Bool :=
  r.c3_pass &&
  r.post_use_pass &&
  r.c_ext_signature != "" &&
  r.c_ext_signature != "PENDING" &&
  (current_time <= r.expiry_time)

/-- Theorem: Expired receipt fails validation. -/
theorem expired_receipt_invalid (r : ReceiptRecord) (current_time : Nat)
    (h_exp : current_time > r.expiry_time) :
    is_receipt_valid r current_time = false := by
  have h_dec : decide (current_time ≤ r.expiry_time) = false := decide_eq_false (by omega)
  dsimp [is_receipt_valid]
  rw [h_dec]
  simp

/-- State within complexity ceiling bounds. -/
def within_ceiling (coordinates lambda_hat theta_norm bursts : Nat) (c : CeilingRecord) : Bool :=
  (coordinates <= c.max_coordinates) &&
  (lambda_hat <= c.max_lambda_hat) &&
  (theta_norm <= c.max_theta_norm) &&
  (bursts <= c.max_bursts_unscaled)

/-- Theorem: Exceeding maximum coordinates violates ceiling. -/
theorem coordinate_overflow_violates_ceiling (coordinates lambda_hat theta_norm bursts : Nat)
    (c : CeilingRecord) (h_ovf : coordinates > c.max_coordinates) :
    within_ceiling coordinates lambda_hat theta_norm bursts c = false := by
  have h_dec : decide (coordinates ≤ c.max_coordinates) = false := decide_eq_false (by omega)
  dsimp [within_ceiling]
  rw [h_dec]
  simp

end Ratchet
