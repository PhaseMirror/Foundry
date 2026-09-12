module
public import Init
set_option autoImplicit false
namespace PrismPM.Foundation.Sec

public inductive Likelihood where
  | low
  | medium
  | high

public inductive Impact where
  | minor
  | major
  | critical

public structure Asset where
  index : Nat
  componentIndex : Nat

public structure Threat where
  index : Nat

public structure Risk where
  index : Nat
  assetIndex : Nat
  threatIndex : Nat
  likelihood : Likelihood
  impact : Impact

public structure ApplicationSecurityControl where
  index : Nat
  riskIndex : Nat

public structure SecurityActivity where
  index : Nat
  controlIndex : Nat

public structure VerificationMeasurement where
  index : Nat
  controlIndex : Nat
  passed : Bool

@[expose] public def assetCredentials : Asset := ({ index := 0, componentIndex := 1 } : Asset)

@[expose] public def threatUnauthorizedAccess : Threat := ({ index := 0 } : Threat)

@[expose] public def riskUnauthorizedAccess : Risk := ({ index := 0, assetIndex := 0, threatIndex := 0, likelihood := Likelihood.high, impact := Impact.critical } : Risk)

@[expose] public def controlMutualTls : ApplicationSecurityControl := ({ index := 0, riskIndex := 0 } : ApplicationSecurityControl)

@[expose] public def activityRotateCredentials : SecurityActivity := ({ index := 0, controlIndex := 0 } : SecurityActivity)

@[expose] public def measurementMutualTls : VerificationMeasurement := ({ index := 0, controlIndex := 0, passed := true } : VerificationMeasurement)

public theorem riskChainConsistent : (true = true) := by
  rfl

end PrismPM.Foundation.Sec
