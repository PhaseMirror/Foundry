import TheExaminerAdr.Core

/-!
# FFI Bindings for Rust
-/

namespace TheExaminerAdr

@[export the_examiner_adr_check_acyclic]
def checkAcyclic (id : UInt32) (supersedesId : UInt32) : Bool :=
  id != supersedesId

end TheExaminerAdr
