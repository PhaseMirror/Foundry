import FintonAdr.Core

/-!
# FFI Bindings for Rust
-/

namespace FintonAdr

@[export finton_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  Core.ADR.checkAcyclic id supersedesId

end FintonAdr
