import Multiplicity.universal_atomic.SQD
import Multiplicity.universal_atomic.AEGISS
import Multiplicity.universal_atomic.Circuits

def runBoundaryTests : IO Unit := do
  IO.println "--- UAC Boundary Rigorous Testing ---"
  
  -- 1. Combinatorial Stress Test (C-SQD)
  let t0 ← IO.monoMsNow
  -- 20 choose 10 = 184,756. This tests the recursive evaluator limits.
  let hamming_20_10 := Multiplicity.UAC.SQD.computeHamming 20 10
  let t1 ← IO.monoMsNow
  IO.println s!"[Boundary C-SQD] computeHamming 20 10 = {hamming_20_10} (Time: {t1 - t0} ms)"
  
  -- 24 choose 12 = 2,704,156.
  let t2 ← IO.monoMsNow
  let hamming_24_12 := Multiplicity.UAC.SQD.computeHamming 24 12
  let t3 ← IO.monoMsNow
  IO.println s!"[Boundary C-SQD] computeHamming 24 12 = {hamming_24_12} (Time: {t3 - t2} ms)"

  -- 2. Q-SQD Quantization Limit Tests
  -- Test precision limits near lambda boundary
  let f_hat : Int := 9000
  let q : Int := 45
  let se : Int := 100
  let b_val : Nat := 50
  let lambda : Nat := 20000
  let scale : Nat := 10000
  -- Exactly at the boundary (lhs diff = 0)
  let stability_1 := Multiplicity.UAC.SQD.checkStability f_hat q se b_val lambda scale
  
  -- Push f_hat up by just 1 unit (1/10000th precision)
  let stability_2 := Multiplicity.UAC.SQD.checkStability 9001 q se b_val lambda scale
  
  -- Push f_hat up to failure point
  -- lhs = |f_hat * 50 - 450000| * 10000
  -- rhs = 20000 * 100 * 50 = 100,000,000
  -- f_hat = 9020 => |9020 * 50 - 450000| * 10000 = |451000 - 450000| * 10000 = 1000 * 10000 = 10,000,000 < rhs (True)
  -- f_hat = 9200 => |9200 * 50 - 450000| * 10000 = |460000 - 450000| * 10000 = 10000 * 10000 = 100,000,000 (False)
  let stability_3 := Multiplicity.UAC.SQD.checkStability 9200 q se b_val lambda scale
  
  IO.println s!"[Boundary Q-SQD] Stability near center (f_hat=9000): {stability_1}"
  IO.println s!"[Boundary Q-SQD] Stability 1-tick off (f_hat=9001): {stability_2}"
  IO.println s!"[Boundary Q-SQD] Stability exact boundary (f_hat=9200): {stability_3}"
  
  -- 3. ZK Prime Field Limit Testing
  let delta : Nat := 2^80 - 1
  let xi : Nat := 2^80 - 1
  let drift_pass := Multiplicity.UAC.Circuits.checkDriftBound delta xi
  IO.println s!"[Boundary ZK-Circom] Drift Bounds near 80-bit overflow limits (10*2^80 <= 3*2^80): {drift_pass}"
  
  IO.println "--- End Boundary Tests ---"
