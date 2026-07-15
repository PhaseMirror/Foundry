import Core.alp.Types.Action

namespace ALP.Types.TrustLevel

def isInternal : TrustLevel → Bool
  | TrustLevel.Internal => true
  | TrustLevel.External => false

def isExternal : TrustLevel → Bool
  | TrustLevel.Internal => false
  | TrustLevel.External => true

end ALP.Types.TrustLevel
