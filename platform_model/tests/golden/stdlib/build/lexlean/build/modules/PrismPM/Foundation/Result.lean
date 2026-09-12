module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Result

public inductive PortableError where
  | Malformed
  | OutOfBounds
  | Overflow

end PrismPM.Foundation.Result
