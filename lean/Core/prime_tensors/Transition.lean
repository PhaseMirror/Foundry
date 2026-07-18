import Core.Spine

namespace PIRTM

/-- Proof Hash for external verification -/
structure ProofHash where
  hash : String
  deriving Repr

/-- Transition Structure linking OperatorWord to its dimension -/
structure Transition where
  domain : Nat
  codomain : Nat
  action : Core.Spine.OperatorWord
  proof_hash : ProofHash
  h_morphism : Core.Spine.dim action = codomain

end PIRTM
