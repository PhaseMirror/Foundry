module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Holo.V1.PrismExtension

public inductive BrowserProjection where
  | None
  | Present (_ : ByteArray)

public inductive ViewBinding where
  | None
  | Present (_ : ByteArray) (_ : ByteArray) (_ : BrowserProjection)

public structure ModelProvenance where
  schema : String
  modelContentKappa : ByteArray
  modelId : ByteArray
  sourceId : ByteArray
  semanticId : ByteArray
  compilerSemanticsId : ByteArray
  snapshotId : ByteArray
  stdlibSemanticsId : ByteArray
  prismStdlibCrateSha256 : ByteArray
  lexleanCommit : ByteArray
  lexleanPackageSha256 : ByteArray
  lean4ProdCommit : ByteArray
  hologramLiveCommit : ByteArray
  uorHologramCommit : ByteArray
  targetProfileId : ByteArray
  coreWasmContract : String
  leanManifestSha256 : ByteArray
  lcnfManifestSha256 : ByteArray
  generatedCoreSha256 : ByteArray
  cargoName : String
  cargoVersion : String
  cargoCrateSha256 : ByteArray
  guestContentKappa : ByteArray
  viewBinding : ViewBinding
  applicationKappa : ByteArray

@[expose] public def extensionName : String := "https://uor.foundation/extension/prismpm-model/v1"

@[expose] public def schema : String := "prismpm/model-provenance/1"

end PrismPM.Foundation.Holo.V1.PrismExtension
