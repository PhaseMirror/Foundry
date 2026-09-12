module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Runtime

public inductive CryptoPrimitive where
  | Blake3
  | Sha256

public structure GuestMemory where
  maximumBytes : UInt32
  maximumPages : UInt32
  alignment : UInt8
  monotonic : Bool
  freshInstance : Bool

public structure HashRequest where
  primitive : CryptoPrimitive
  role : String
  preimage : ByteArray
  expectedBytes : UInt8

public structure HashResult where
  role : String
  digest : ByteArray

@[expose] public def coreWasmMemory : GuestMemory := ({ maximumBytes := (65536 : UInt32), maximumPages := (4 : UInt32), alignment := (8 : UInt8), monotonic := true, freshInstance := true } : GuestMemory)

end PrismPM.Foundation.Runtime
