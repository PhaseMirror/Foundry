import ThePublisherAdr.Core

/-!
# FFI Bindings for Rust
-/

namespace ThePublisherAdr

@[export the_publisher_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  id != supersedesId

end ThePublisherAdr
