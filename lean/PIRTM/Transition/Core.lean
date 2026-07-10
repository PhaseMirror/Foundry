import MOC.Core

namespace PIRTM

/-- Formal Proof Hash linking Lean transition to Rust runtime artifact -/
structure ProofHash where
  hash : String
  deriving Repr

/-- Tensor Morphism: A transition defined as a sequence of MOC operators. -/
structure Transition where
  action : MOC.OperatorWord
  proof_hash : ProofHash
  h_stable : MOC.isACEStable action = true

end PIRTM
