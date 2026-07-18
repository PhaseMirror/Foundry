import AtaraxiaAdr.Core

/-!
# FFI Bindings for Rust
-/

namespace AtaraxiaAdr

@[export ataraxia_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  Core.ADR.checkAcyclic id supersedesId

end AtaraxiaAdr
