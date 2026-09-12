module
public import Init
public import PrismPM.Foundation.Arch
public import PrismPM.Foundation.Holo
public import PrismPM.Foundation.Qual
public import PrismPM.Foundation.Sec
set_option autoImplicit false
namespace PrismPM.System

@[expose] public def stdlibModel : PrismPM.Foundation.Holo.NormalizedHolo := ({ componentIndexes := (0 :: (1 :: ([] : List (Nat)))), edgeEndpoints := (0 :: (1 :: (1 :: (0 :: ([] : List (Nat)))))), riskLinks := (0 :: (0 :: ([] : List (Nat)))), controlLinks := (0 :: ([] : List (Nat))), viewpointLinks := (0 :: (0 :: (0 :: ([] : List (Nat))))), qualityLinks := (0 :: (0 :: ([] : List (Nat)))), flattenedIndexes := (0 :: (1 :: ([] : List (Nat)))) } : PrismPM.Foundation.Holo.NormalizedHolo)

@[expose] public def stdlibValidated : Bool := (PrismPM.Foundation.Holo.validateComponentIndexes ((stdlibModel).componentIndexes) && (PrismPM.Foundation.Holo.validateEdgeEndpoints (2) ((stdlibModel).edgeEndpoints) && (PrismPM.Foundation.Holo.validateRiskLinks (1) ((stdlibModel).riskLinks) && (PrismPM.Foundation.Holo.validateControlLinks (1) ((stdlibModel).controlLinks) && (PrismPM.Foundation.Holo.validateViewpointLinks (1) ((stdlibModel).viewpointLinks) && (PrismPM.Foundation.Holo.validateQualityLinks (1) ((stdlibModel).qualityLinks) && PrismPM.Foundation.Holo.validateFlattenedBounds (2) ((stdlibModel).flattenedIndexes)))))))

public theorem stdlibNoDanglingReferences : (stdlibValidated = true) := by
  decide

public theorem stdlibCrossFacetConsistency : (stdlibValidated = true) := by
  decide

end PrismPM.System
