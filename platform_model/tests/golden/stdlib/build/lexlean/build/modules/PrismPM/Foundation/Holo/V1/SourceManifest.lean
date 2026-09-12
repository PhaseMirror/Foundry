module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Holo.V1.SourceManifest

public structure SourceFile where
  path : String
  sha256 : ByteArray
  byteLength : UInt64

public structure SourceManifest where
  version : UInt16
  applicationName : String
  coreContract : String
  wasmPath : String
  viewPath : String
  files : List (SourceFile)

@[expose] public def sourceManifestVersion : UInt16 := (4 : UInt16)

end PrismPM.Foundation.Holo.V1.SourceManifest
