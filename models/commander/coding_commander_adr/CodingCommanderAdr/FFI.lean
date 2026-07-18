import CodingCommanderAdr.Core

/-!
# FFI Bindings for Rust
-/

namespace CodingCommanderAdr

@[export coding_commander_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  Core.ADR.checkAcyclic id supersedesId

end CodingCommanderAdr
