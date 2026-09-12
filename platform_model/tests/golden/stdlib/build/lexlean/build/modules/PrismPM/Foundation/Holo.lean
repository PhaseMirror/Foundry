module
public import Init
public import PrismPM.Foundation.Application
public import PrismPM.Foundation.Arch
public import PrismPM.Foundation.Bytes
public import PrismPM.Foundation.Codec
public import PrismPM.Foundation.Core
public import PrismPM.Foundation.Holo.V1.Archive
public import PrismPM.Foundation.Holo.V1.Capability
public import PrismPM.Foundation.Holo.V1.CoreWasm
public import PrismPM.Foundation.Holo.V1.Directory
public import PrismPM.Foundation.Holo.V1.Format
public import PrismPM.Foundation.Holo.V1.Identity
public import PrismPM.Foundation.Holo.V1.Manifest
public import PrismPM.Foundation.Holo.V1.PrismExtension
public import PrismPM.Foundation.Holo.V1.SourceManifest
public import PrismPM.Foundation.Holo.V1.View
public import PrismPM.Foundation.Integer
public import PrismPM.Foundation.Qual
public import PrismPM.Foundation.Result
public import PrismPM.Foundation.Runtime
public import PrismPM.Foundation.Sec
public import PrismPM.Foundation.Utf8
public import PrismPM.Foundation.View.V1.Interaction
public import PrismPM.Foundation.View.V1.Model
public import PrismPM.Foundation.View.V1.Projection
set_option autoImplicit false
namespace PrismPM.Foundation.Holo

public structure StandardsProfile where
  architectureEdition : Nat
  applicationSecurityEdition : Nat
  controlEdition : Nat
  riskEdition : Nat
  qualityEdition : Nat

public structure NormalizedHolo where
  componentIndexes : List (Nat)
  edgeEndpoints : List (Nat)
  riskLinks : List (Nat)
  controlLinks : List (Nat)
  viewpointLinks : List (Nat)
  qualityLinks : List (Nat)
  flattenedIndexes : List (Nat)

public structure FlatValidationInput where
  bound : Nat
  indexes : List (Nat)
  references : List (Nat)

@[expose] public def allConsecutive : (expected : Nat) -> (values : List (Nat)) -> Bool
  | _expected, List.nil => true
  | expected, List.cons value rest => ((Nat.beq (expected) (value)) && allConsecutive ((expected + 1)) (rest))

@[expose] public def allConsecutiveProp : (expected : Nat) -> (values : List (Nat)) -> Prop
  | expected, List.nil => (expected = expected)
  | expected, List.cons value rest => ((expected = value) /\ allConsecutiveProp ((expected + 1)) (rest))

@[expose] public def allBelow : (bound : Nat) -> (values : List (Nat)) -> Bool
  | _bound, List.nil => true
  | bound, List.cons value rest => ((Nat.blt (value) (bound)) && allBelow (bound) (rest))

@[expose] public def allBelowProp : (bound : Nat) -> (values : List (Nat)) -> Prop
  | bound, List.nil => (bound = bound)
  | bound, List.cons value rest => ((value < bound) /\ allBelowProp (bound) (rest))

@[expose] public def validateComponentIndexes (values : List (Nat)) : Bool := allConsecutive (0) (values)

@[expose] public def validateEdgeEndpoints (componentCount : Nat) (endpoints : List (Nat)) : Bool := allBelow (componentCount) (endpoints)

@[expose] public def validateRiskLinks (assetOrThreatCount : Nat) (links : List (Nat)) : Bool := allBelow (assetOrThreatCount) (links)

@[expose] public def validateControlLinks (riskCount : Nat) (links : List (Nat)) : Bool := allBelow (riskCount) (links)

@[expose] public def validateViewpointLinks (targetCount : Nat) (links : List (Nat)) : Bool := allBelow (targetCount) (links)

@[expose] public def validateQualityLinks (targetCount : Nat) (links : List (Nat)) : Bool := allBelow (targetCount) (links)

@[expose] public def validateFlattenedBounds (bound : Nat) (indexes : List (Nat)) : Bool := allBelow (bound) (indexes)

@[expose] public def validateExactStandardsProfile (profile : StandardsProfile) : Bool := ((Nat.beq ((profile).architectureEdition) (2022)) && ((Nat.beq ((profile).applicationSecurityEdition) (2011)) && ((Nat.beq ((profile).controlEdition) (2017)) && ((Nat.beq ((profile).riskEdition) (2022)) && (Nat.beq ((profile).qualityEdition) (2023))))))

@[expose] public def componentIndexesValid (values : List (Nat)) : Prop := allConsecutiveProp (0) (values)

@[expose] public def edgeEndpointsValid (componentCount : Nat) (endpoints : List (Nat)) : Prop := allBelowProp (componentCount) (endpoints)

@[expose] public def riskLinksValid (count : Nat) (links : List (Nat)) : Prop := allBelowProp (count) (links)

@[expose] public def controlLinksValid (count : Nat) (links : List (Nat)) : Prop := allBelowProp (count) (links)

@[expose] public def viewpointLinksValid (count : Nat) (links : List (Nat)) : Prop := allBelowProp (count) (links)

@[expose] public def qualityLinksValid (count : Nat) (links : List (Nat)) : Prop := allBelowProp (count) (links)

@[expose] public def flattenedBoundsValid (count : Nat) (links : List (Nat)) : Prop := allBelowProp (count) (links)

@[expose] public def standardsProfileValid (profile : StandardsProfile) : Prop := (((profile).architectureEdition = 2022) /\ (((profile).applicationSecurityEdition = 2011) /\ (((profile).controlEdition = 2017) /\ (((profile).riskEdition = 2022) /\ ((profile).qualityEdition = 2023)))))

@[expose] public def canonicalStandardsProfile : StandardsProfile := ({ architectureEdition := 2022, applicationSecurityEdition := 2011, controlEdition := 2017, riskEdition := 2022, qualityEdition := 2023 } : StandardsProfile)

public theorem allConsecutive_sound_complete (expected : Nat) (values : List (Nat)) : ((allConsecutive (expected) (values) = true) <-> allConsecutiveProp (expected) (values)) := by
  have llAndBridge : ∀ left right : Bool, ((left && right) = true) ↔ left = true ∧ right = true := by
    intro left right
    cases left <;> cases right <;> decide
  have llBeqRefl : ∀ value : Nat, Nat.beq value value = true := by
    intro value
    induction value with
    | zero => rfl
    | succ value ih => exact ih
  induction values generalizing expected with
  | nil => constructor <;> intro _ <;> rfl
  | cons llValue llRest llIH =>
    constructor
    · intro h
      have hpair := (llAndBridge _ _).mp h
      exact And.intro (Nat.eq_of_beq_eq_true hpair.left) ((llIH (expected + 1)).mp hpair.right)
    · intro h
      have hleft : Nat.beq expected llValue = true := h.left ▸ llBeqRefl expected
      have hright : allConsecutive (expected + 1) llRest = true := (llIH (expected + 1)).mpr h.right
      exact (llAndBridge _ _).mpr (And.intro hleft hright)

public theorem allBelow_sound_complete (bound : Nat) (values : List (Nat)) : ((allBelow (bound) (values) = true) <-> allBelowProp (bound) (values)) := by
  have llAndBridge : ∀ left right : Bool, ((left && right) = true) ↔ left = true ∧ right = true := by
    intro left right
    cases left <;> cases right <;> decide
  induction values generalizing bound with
  | nil => constructor <;> intro _ <;> rfl
  | cons llValue llRest llIH =>
    constructor
    · intro h
      have hpair := (llAndBridge _ _).mp h
      exact And.intro (Nat.le_of_ble_eq_true hpair.left) ((llIH bound).mp hpair.right)
    · intro h
      have hleft : Nat.blt llValue bound = true := Nat.ble_eq_true_of_le h.left
      have hright : allBelow bound llRest = true := (llIH bound).mpr h.right
      exact (llAndBridge _ _).mpr (And.intro hleft hright)

public theorem componentIndexes_sound_complete (values : List (Nat)) : ((validateComponentIndexes (values) = true) <-> componentIndexesValid (values)) := by
  exact allConsecutive_sound_complete (0) (values)

public theorem edgeEndpoints_sound_complete (componentCount : Nat) (endpoints : List (Nat)) : ((validateEdgeEndpoints (componentCount) (endpoints) = true) <-> edgeEndpointsValid (componentCount) (endpoints)) := by
  exact allBelow_sound_complete (componentCount) (endpoints)

public theorem riskLinks_sound_complete (count : Nat) (links : List (Nat)) : ((validateRiskLinks (count) (links) = true) <-> riskLinksValid (count) (links)) := by
  exact allBelow_sound_complete (count) (links)

public theorem controlLinks_sound_complete (count : Nat) (links : List (Nat)) : ((validateControlLinks (count) (links) = true) <-> controlLinksValid (count) (links)) := by
  exact allBelow_sound_complete (count) (links)

public theorem viewpointLinks_sound_complete (count : Nat) (links : List (Nat)) : ((validateViewpointLinks (count) (links) = true) <-> viewpointLinksValid (count) (links)) := by
  exact allBelow_sound_complete (count) (links)

public theorem qualityLinks_sound_complete (count : Nat) (links : List (Nat)) : ((validateQualityLinks (count) (links) = true) <-> qualityLinksValid (count) (links)) := by
  exact allBelow_sound_complete (count) (links)

public theorem flattenedBounds_sound_complete (count : Nat) (links : List (Nat)) : ((validateFlattenedBounds (count) (links) = true) <-> flattenedBoundsValid (count) (links)) := by
  exact allBelow_sound_complete (count) (links)

public theorem standardsProfile_sound_complete (profile : StandardsProfile) : ((validateExactStandardsProfile (profile) = true) <-> standardsProfileValid (profile)) := by
  have llAndBridge : ∀ left right : Bool, ((left && right) = true) ↔ left = true ∧ right = true := by
    intro left right
    cases left <;> cases right <;> decide
  have llBeqRefl : ∀ value : Nat, Nat.beq value value = true := by
    intro value
    induction value with
    | zero => rfl
    | succ value ih => exact ih
  have llBeqBridge : ∀ left right : Nat, Nat.beq left right = true ↔ left = right := by
    intro left right
    constructor
    · exact Nat.eq_of_beq_eq_true
    · intro h
      cases h
      exact llBeqRefl left
  change (((Nat.beq ((profile).architectureEdition) (2022) && (Nat.beq ((profile).applicationSecurityEdition) (2011) && (Nat.beq ((profile).controlEdition) (2017) && (Nat.beq ((profile).riskEdition) (2022) && Nat.beq ((profile).qualityEdition) (2023)))))) = true) ↔ (((profile).architectureEdition = 2022) /\ (((profile).applicationSecurityEdition = 2011) /\ (((profile).controlEdition = 2017) /\ (((profile).riskEdition = 2022) /\ ((profile).qualityEdition = 2023)))))
  exact Iff.trans (llAndBridge _ _) (and_congr (llBeqBridge _ _) (Iff.trans (llAndBridge _ _) (and_congr (llBeqBridge _ _) (Iff.trans (llAndBridge _ _) (and_congr (llBeqBridge _ _) (Iff.trans (llAndBridge _ _) (and_congr (llBeqBridge _ _) (llBeqBridge _ _))))))))

@[expose] public def canonicalIndexes : (expected : Nat) -> (count : Nat) -> List (Nat)
  | _expected, Nat.zero => ([] : List (Nat))
  | expected, Nat.succ rest => (expected :: canonicalIndexes ((expected + 1)) (rest))

@[expose] public def canonicalIndexAssignment (count : Nat) (values : List (Nat)) : Prop := (values = canonicalIndexes (0) (count))

public theorem canonicalIndexAssignmentUnique (count : Nat) (values : List (Nat)) : (canonicalIndexAssignment (count) (values) <-> (values = canonicalIndexes (0) (count))) := by
  rfl

end PrismPM.Foundation.Holo
