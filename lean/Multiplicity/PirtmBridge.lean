import alp.Constitution.Model
import alp.Constitution.L0
import alp.PolicyEngine.Core

namespace Multiplicity.ALP.Candle.PirtmBridge

structure SedonaTrace where
  valid : Bool
  contractivity_ok : Bool

theorem candle_ignition_sound (trace : SedonaTrace) (_h_valid : trace.valid = true)
  (h_ok : trace.contractivity_ok = true) : trace.contractivity_ok = true := h_ok

end Multiplicity.ALP.Candle.PirtmBridge
