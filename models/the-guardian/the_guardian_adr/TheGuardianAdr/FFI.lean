import TheGuardianAdr.Core

/-!
# FFI Bindings for Rust
-/

namespace TheGuardianAdr

@[export the_guardian_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  id != supersedesId

end TheGuardianAdr
