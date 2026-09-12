import TheGeniusAdr.Core

/-!
# FFI Bindings for Rust
-/

namespace TheGeniusAdr

@[export the_genius_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  id != supersedesId

end TheGeniusAdr
