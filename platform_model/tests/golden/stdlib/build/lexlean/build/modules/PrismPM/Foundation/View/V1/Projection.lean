module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.View.V1.Projection

public inductive Target where
  | HologramIntent
  | PagesWasmBindgen

public inductive ForbiddenContent where
  | RawHtml
  | RawCss
  | RawScript
  | Url
  | HostCommand

public structure ProjectionBinding where
  target : Target
  modelId : ByteArray
  viewModelId : ByteArray
  generatedCoreSha256 : ByteArray
  transport : String
  escaped : Bool
  rawContentAllowed : Bool

end PrismPM.Foundation.View.V1.Projection
