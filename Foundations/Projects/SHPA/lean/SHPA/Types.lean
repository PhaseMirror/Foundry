set_option autoImplicit false

/-!
# SHPA Core Types: Stateless Hash-to-Prime Attestation
-/

namespace SHPA

/-- 256-bit hash representation modeled as a natural number or 32-byte sequence. -/
structure Hash256 where
  val : Nat
  deriving Repr, DecidableEq

/-- Operator representation with canonical serialization identifier. -/
structure OperatorDescriptor where
  schema_id : Nat
  op_type   : Nat
  scale     : Nat
  depth     : Nat
  deriving Repr, DecidableEq

/-- Ordered tree node for non-commutative fractal topology. -/
inductive TreeNode where
  | leaf (op_hash : Hash256) : TreeNode
  | node (op_hash : Hash256) (children : List TreeNode) : TreeNode
  deriving Repr

/-- Execution manifest recording H2P offset and prime assignment. -/
structure H2PManifest where
  op_hash : Hash256
  seed_n  : Nat
  offset_k : Nat
  prime_p : Nat
  deriving Repr, DecidableEq

end SHPA
