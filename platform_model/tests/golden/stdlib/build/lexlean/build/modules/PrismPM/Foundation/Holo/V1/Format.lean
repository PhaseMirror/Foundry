module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Holo.V1.Format

public inductive SectionKind where
  | KernelCalls
  | Metadata
  | Extension
  | AppManifest
  | ContentBlob

public structure Header where
  magic : ByteArray
  version : UInt16
  flags : UInt16
  sectionCount : UInt16

public structure SectionTableEntry where
  kind : UInt8
  offset : UInt64
  length : UInt64

@[expose] public def physicalVersion : UInt16 := (4 : UInt16)

@[expose] public def canonicalFlags : UInt16 := (0 : UInt16)

@[expose] public def magic : ByteArray := ByteArray.mk #[72, 79, 76, 79]

end PrismPM.Foundation.Holo.V1.Format
