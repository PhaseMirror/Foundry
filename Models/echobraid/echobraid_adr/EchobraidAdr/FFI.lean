import EchobraidAdr.Core

/-!
# FFI Bindings for Rust
-/

namespace EchobraidAdr

@[export echobraid_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  id != supersedesId

end EchobraidAdr
