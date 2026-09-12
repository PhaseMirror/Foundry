module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Holo.V1.Manifest

public inductive LayerKind where
  | WasmCodemodule
  | TensorPlan
  | RootfsImage
  | View
  | InferenceModel

public structure Layer where
  kind : LayerKind
  contentKappa : ByteArray
  entry : String
  auxiliary : String

public structure Child where
  applicationKappa : ByteArray
  capabilitiesKappa : ByteArray

public structure AppManifest where
  primary : Option (UInt32)
  requires : ByteArray
  layers : List (Layer)
  children : List (Child)

end PrismPM.Foundation.Holo.V1.Manifest
