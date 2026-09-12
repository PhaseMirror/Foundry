module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Holo.V1.Directory

public structure DirectoryLayer where
  position : UInt32
  kind : String
  contentKappa : ByteArray
  entry : String
  contract : Option (String)
  architecture : Option (String)
  surface : Option (String)
  engine : Option (String)

public structure DirectoryChild where
  position : UInt32
  applicationKappa : ByteArray
  capabilitiesKappa : ByteArray

public structure DirectoryBlob where
  contentKappa : ByteArray
  byteLength : UInt64

public structure ApplicationDirectory where
  schemaVersion : UInt16
  primary : Option (UInt32)
  requiresKappa : ByteArray
  layers : List (DirectoryLayer)
  children : List (DirectoryChild)
  blobs : List (DirectoryBlob)

@[expose] public def extensionName : String := "https://hologram.foundation/extension/application-directory/v1"

end PrismPM.Foundation.Holo.V1.Directory
