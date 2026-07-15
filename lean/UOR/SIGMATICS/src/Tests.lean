import Std.Tactic
import SigmaticsCore

open SigmaticsCore

-- Round‑trip encode/decode property
example (b : UInt8) :
  let (c1, c2, c3) := decode_byte_to_components b
  encode_components_to_byte c1 c2 c3 = b := by
  simp [encode_components_to_byte, decode_byte_to_components]

-- Rotating twice returns original
example (b : UInt8) :
  apply_transform (apply_transform b Transform.Rotate) Transform.Rotate = b := by
  simp [apply_transform, encode_components_to_byte, decode_byte_to_components]

-- Ledger block hash identity
example (h ts : UInt64) : ledger_block_hash {hash := h, timestamp := ts} = h := rfl

@[test]
def testAll : TestIO Unit := do
  IO.println "All placeholder tests passed."
