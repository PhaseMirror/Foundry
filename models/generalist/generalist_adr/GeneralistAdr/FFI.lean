import GeneralistAdr.Core

/-!
# FFI Bindings for Rust
-/

namespace GeneralistAdr

@[export generalist_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  Core.ADR.checkAcyclic id supersedesId

end GeneralistAdr
