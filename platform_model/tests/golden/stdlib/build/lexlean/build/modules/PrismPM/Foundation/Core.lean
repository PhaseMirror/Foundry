module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Core

public inductive UnitValue where
  | UnitValue

@[expose] public def portableTrue : Bool := true

end PrismPM.Foundation.Core
