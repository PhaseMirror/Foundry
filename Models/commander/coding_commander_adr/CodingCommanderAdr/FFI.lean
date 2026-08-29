import CodingCommanderAdr.Core

/-!
# FFI Bindings for Rust
-/

namespace CodingCommanderAdr

@[export commander_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  id != supersedesId

end CodingCommanderAdr
