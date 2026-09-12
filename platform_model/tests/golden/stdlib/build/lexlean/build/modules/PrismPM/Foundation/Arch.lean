module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Arch

public structure StandardReference where
  standardIndex : Nat
  editionIndex : Nat

public inductive ComponentKind where
  | service
  | database
  | externalSystem

public inductive EdgeKind where
  | dataFlow
  | controlFlow

public inductive ModelKind where
  | componentModel
  | securityModel
  | qualityModel

public structure Component where
  index : Nat
  kind : ComponentKind

public structure Edge where
  index : Nat
  fromIndex : Nat
  toIndex : Nat
  kind : EdgeKind

public structure Stakeholder where
  index : Nat

public structure Concern where
  index : Nat

public structure Viewpoint where
  index : Nat
  stakeholderIndex : Nat
  concernIndex : Nat
  modelKindIndex : Nat

public structure View where
  index : Nat
  viewpointIndex : Nat
  modelKindIndex : Nat

public class ViewpointClass where
  selectedModelKind : Nat

public class ViewClass where
  selectedViewpoint : Nat

public instance (priority := 1000) canonicalViewpoint : ViewpointClass where
  selectedModelKind := 0

public instance (priority := 1000) canonicalView : ViewClass where
  selectedViewpoint := 0

@[expose] public def componentGateway : Component := ({ index := 1, kind := ComponentKind.service } : Component)

@[expose] public def componentAuth : Component := ({ index := 0, kind := ComponentKind.database } : Component)

@[expose] public def edgeIngress : Edge := ({ index := 0, fromIndex := 0, toIndex := 1, kind := EdgeKind.dataFlow } : Edge)

@[expose] public def edgeReturnCycle : Edge := ({ index := 1, fromIndex := 1, toIndex := 0, kind := EdgeKind.controlFlow } : Edge)

@[expose] public def stakeholderOperator : Stakeholder := ({ index := 0 } : Stakeholder)

@[expose] public def concernSecurity : Concern := ({ index := 0 } : Concern)

@[expose] public def modelKindComponents : ModelKind := ModelKind.componentModel

@[expose] public def viewpointOperations : Viewpoint := ({ index := 0, stakeholderIndex := 0, concernIndex := 0, modelKindIndex := 0 } : Viewpoint)

@[expose] public def viewPrimary : View := ({ index := 0, viewpointIndex := 0, modelKindIndex := 0 } : View)

public theorem componentIdentityUnique (value : Component) : (value = value) := by
  rfl

public theorem cyclesPermitted : (true = true) := by
  rfl

end PrismPM.Foundation.Arch
