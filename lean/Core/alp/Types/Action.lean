import Core.alp.Basic

namespace ALP.Types

inductive TrustLevel
  | Internal
  | External
  deriving DecidableEq

structure Action where
  id : String
  payload : String  -- JSON-serialized payload; corresponds to serde_json::Value
  mutating : Bool
  server_binding : Option String

structure AdmissibilityReport where
  allowed : Bool
  reason : String
  deriving DecidableEq

end ALP.Types
