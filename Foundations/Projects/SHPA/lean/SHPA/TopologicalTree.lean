import SHPA.Types
import SHPA.BCS

set_option autoImplicit false

/-!
# Topological Signatures for Fractal Trees (Non-Commutative)
-/

namespace SHPA

/-- Deterministic positional node encoding for child list. -/
def encode_children_acc (idx : Nat) (children : List Nat) : Nat :=
  match children with
  | [] => 0
  | c :: cs => c * (idx + 1) + encode_children_acc (idx + 1) cs

/-- Deterministic hash combiner for ordered topological nodes. -/
def hash_combine (h_op : Nat) (child_hashes : List Nat) : Nat :=
  h_op * 1000003 + encode_children_acc 1 child_hashes

/-- Recursive topological signature evaluation on tree nodes. -/
def topological_signature : TreeNode → Nat
  | TreeNode.leaf op_hash => hash_combine op_hash.val []
  | TreeNode.node op_hash children =>
      hash_combine op_hash.val (children.map topological_signature)

/-- Theorem: Commutativity violation witness — Swapping distinct children changes the signature. -/
theorem topological_signature_non_commutative (op_h : Nat) (c1 c2 : Nat)
    (h_distinct : c1 ≠ c2) :
    hash_combine op_h [c1, c2] ≠ hash_combine op_h [c2, c1] := by
  dsimp [hash_combine, encode_children_acc]
  intro h_eq
  have h_alg : op_h * 1000003 + (c1 * 2 + (c2 * 3 + 0)) =
               op_h * 1000003 + (c2 * 2 + (c1 * 3 + 0)) := h_eq
  have h_sub : c1 * 2 + c2 * 3 = c2 * 2 + c1 * 3 := by omega
  have h_contra : c1 = c2 := by omega
  exact h_distinct h_contra

end SHPA
