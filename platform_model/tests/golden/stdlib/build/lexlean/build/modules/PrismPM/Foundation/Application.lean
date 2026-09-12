module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Application

public inductive ApplicationLayerKind where
  | Wasm
  | View

public inductive PackagingIntent where
  | Fat
  | Thin

public inductive PresentationTarget where
  | HologramPortable
  | GithubPages

public structure Layer where
  kind : ApplicationLayerKind
  entry : String
  contract : String
  primary : Bool

public structure CargoPackage where
  name : String
  version : String
  description : String
  repository : String
  homepage : String
  stdlibVersion : String
  stdFeature : Bool

public structure Application where
  name : String
  entryRoot : String
  requestCodec : String
  responseCodec : String
  requestMaximum : UInt32
  responseMaximum : UInt32
  guestAllocationMaximum : UInt32
  capabilitiesEmpty : Bool
  packaging : PackagingIntent
  layers : List (Layer)
  targets : List (PresentationTarget)
  cargoPackage : CargoPackage

end PrismPM.Foundation.Application
