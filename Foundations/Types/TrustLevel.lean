import Foundations.Types.Action

namespace Multiplicity.ALP.Types.TrustLevel

def isInternal : TrustLevel → Bool
  | TrustLevel.Internal => true
  | TrustLevel.External => false

def isExternal : TrustLevel → Bool
  | TrustLevel.Internal => false
  | TrustLevel.External => true

end Multiplicity.ALP.Types.TrustLevel
