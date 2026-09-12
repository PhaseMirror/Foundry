namespace Multiplicity.CRMF

inductive Tier where
  | L0
  | L1
  | L2
  deriving Repr, DecidableEq

structure CRMFState where
  dim : Nat
  resonanceScore : Nat
  multiplicityGain : Nat
  tier : Tier
  deriving Repr

def Lyapunov (s : CRMFState) : Nat :=
  10000 - s.resonanceScore

end Multiplicity.CRMF
