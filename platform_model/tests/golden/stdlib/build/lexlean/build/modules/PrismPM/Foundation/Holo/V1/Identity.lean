module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Holo.V1.Identity

public inductive HashAlgorithm where
  | Blake3
  | Sha256

public inductive HashPhase where
  | Leaf
  | Application
  | Physical

public inductive IdentityRole where
  | ContentKappa
  | CapabilityKappa
  | ModelKappa
  | ApplicationKappa
  | ArchiveFingerprint
  | ArchiveKappa
  | PackageSha256
  | BrowserSha256

public structure Digest where
  algorithm : HashAlgorithm
  bytes : ByteArray

public structure HashRequest where
  phase : HashPhase
  role : IdentityRole
  preimage : ByteArray

public structure HashResult where
  phase : HashPhase
  role : IdentityRole
  digest : Digest

end PrismPM.Foundation.Holo.V1.Identity
