module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Holo.V1.CoreWasm

public structure Contract where
  exportedMemory : Bool
  allocatorExport : String
  entryExport : String
  importsEmpty : Bool
  memoryMaximumBytes : UInt32
  maximumPages : UInt32
  allocationAlignment : UInt8
  inputMaximum : UInt32
  outputMaximum : UInt32
  panicAbort : Bool

public structure PackedResult where
  pointer : UInt32
  length : UInt32

public inductive AbiError where
  | NegativePointer
  | NegativeLength
  | OverLimit
  | OutOfBounds
  | Overlap
  | GrowthFailure
  | WrongSignature
  | UnexpectedImport

@[expose] public def contractName : String := "hologram:guest/core-wasm@1"

@[expose] public def allocatorName : String := "holo_alloc"

end PrismPM.Foundation.Holo.V1.CoreWasm
