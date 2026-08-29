import SHPA.Types

set_option autoImplicit false

/-!
# Binary Canonical Serialization (BCS) & Operator Hash Integrity
-/

namespace SHPA

/-- Deterministic ULEB128-encoded length serialization. -/
def uleb128_len (len : Nat) : List Nat :=
  if len < 128 then [len] else [len % 128 + 128, len / 128]

/-- BCS byte encoding of an OperatorDescriptor. -/
def bcs_encode_operator (op : OperatorDescriptor) : List Nat :=
  [op.schema_id, op.op_type, op.scale, op.depth]

/-- Theorem: BCS encoding of distinct operator descriptors yields distinct encodings (Injectivity). -/
theorem bcs_operator_injective (op1 op2 : OperatorDescriptor)
    (h : bcs_encode_operator op1 = bcs_encode_operator op2) :
    op1 = op2 := by
  cases op1
  cases op2
  dsimp [bcs_encode_operator] at h
  injection h with h1 h2
  injection h2 with h3 h4
  injection h4 with h5 h6
  injection h6 with h7 _
  rw [h1, h3, h5, h7]

end SHPA
