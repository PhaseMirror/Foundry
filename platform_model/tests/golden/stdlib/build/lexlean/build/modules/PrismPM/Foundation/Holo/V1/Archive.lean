module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Holo.V1.Archive

public inductive Packaging where
  | Fat
  | Thin

public structure Section where
  kind : UInt8
  offset : UInt64
  length : UInt64
  payload : ByteArray

public structure PhysicalArchive where
  magic : ByteArray
  version : UInt16
  flags : UInt16
  sections : List (Section)
  footer : ByteArray

public inductive ArchiveError where
  | BadHeader
  | BadVersion
  | BadTable
  | DuplicateSection
  | MissingContent
  | BadFooter
  | NonCanonical

end PrismPM.Foundation.Holo.V1.Archive
