import MOC.Core

namespace PIRTM

/-- Proof Hash for external verification -/
structure ProofHash where
  hash : String
  deriving Repr

/-- Transition Structure linking OperatorWord to its dimension -/
structure Transition where
  domain : Nat
  codomain : Nat
  action : MOC.OperatorWord
  proof_hash : ProofHash
  h_morphism : MOC.dim action = codomain

end PIRTM
