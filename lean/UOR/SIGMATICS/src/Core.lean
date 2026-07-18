-- Auto‑generated Lean4 definitions for sigmatics‑core (mirroring Rust)
namespace Sigmatics

inductive Transform where
| Rotate
| Triality
| Twist
  deriving Repr, DecidableEq

structure ClassSystem where
  deriving Repr, DecidableEq

open Nat

/-- Decode a byte into its three component fields. Returns Nat triples. -/
def decode_byte_to_components (byte : UInt8) : Nat × Nat × Nat :=
  let b := byte.toNat
  let c1 := (b >>> 6) &&& 0x3
  let c2 := (b >>> 3) &&& 0x7
  let c3 := b &&& 0x7
  (c1, c2, c3)

/-- Encode three component fields back into a byte. -/
def encode_components_to_byte (c1 c2 c3 : Nat) : UInt8 :=
  let b := ((c1 &&& 0x3) <<< 6) ||| ((c2 &&& 0x7) <<< 3) ||| (c3 &&& 0x7)
  UInt8.ofNat b

/-- Apply a transform to a resonance byte. -/
def apply_transform (byte : UInt8) (t : Transform) : UInt8 :=
  let (c1, c2, c3) := decode_byte_to_components byte
  match t with
  | Transform.Rotate   => encode_components_to_byte c1 c3 c2
  | Transform.Triality => encode_components_to_byte c3 c1 c2
  | Transform.Twist    => encode_components_to_byte c2 c1 c3

/-- Compute the linear belt address for given class, page, and byte. -/
def compute_belt_address (class_index page byte : Nat) : UInt64 :=
  let classStride : UInt64 := 12288
  (class_index : UInt64) * classStride + (page : UInt64) * 256 + (byte : UInt64)

end Sigmatics
