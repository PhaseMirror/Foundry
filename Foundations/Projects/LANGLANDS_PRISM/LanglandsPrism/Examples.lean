import LanglandsPrism.Core
import LanglandsPrism.TensorCascade
import LanglandsPrism.GaloisEntanglement
import LanglandsPrism.Stabilization
import LanglandsPrism.MARCL
import LanglandsPrism.Firewall

/-! # LanglandsPrism.Examples

Concrete, executable instantiations of:
1. 5-prime and 8-prime Langlands Prism networks
2. Galois permutation and Langlands duality evaluation
3. 4-agent MARCL epistemic shock and trust recovery
4. Gravitational wave cognitive packet modulation
-/

namespace LanglandsPrism

/-- Concrete 5-prime Langlands Prism state. -/
def examplePrism5 : PrismState :=
  let n2  : TensorNode := ⟨2, 900, 100, 500⟩
  let n3  : TensorNode := ⟨3, 800, 200, 450⟩
  let n5  : TensorNode := ⟨5, 700, 300, 400⟩
  let n7  : TensorNode := ⟨7, 600, 400, 350⟩
  let n11 : TensorNode := ⟨11, 500, 500, 300⟩
  ⟨0, LAMBDA_M_FP, [n2, n3, n5, n7, n11], 850, true⟩

/-- Concrete 8-prime extended Langlands Prism state. -/
def examplePrism8 : PrismState :=
  let primes := defaultPrimes8
  let indexedPrimes := (List.range primes.length).zip primes
  let nodes := indexedPrimes.map (fun (idx, p) =>
    let w := fpSub FP_DEN (idx * 60)
    let ph := (idx * 120) % FP_DEN
    let en := fpSub 600 (idx * 30)
    ⟨p, w, ph, en⟩
  )
  ⟨0, LAMBDA_M_FP, nodes, 900, true⟩

/-- Run 4-agent MARCL Epistemic Shock Simulation.
    1. Injects shock to Agent 3 at t=0.
    2. Executes 8 steps of MARCL trust reallocation. -/
def runMARCLShockExample : (MARCLCluster × List (List Nat)) :=
  let initialCluster := initMARCLCluster
  let shockVector : SemanticVector := ⟨[950, 950, 950, 950]⟩
  let shockedCluster := injectShockToAgent initialCluster 3 shockVector

  let rec loop (k : Nat) (c : MARCLCluster) (history : List (List Nat)) : (MARCLCluster × List (List Nat)) :=
    match k with
    | 0 => (c, history.reverse)
    | n + 1 =>
      let stepC := stepMARCLCluster c
      let trustRow0 := stepC.trustMatrix.getD 0 []
      loop n stepC (trustRow0 :: history)

  loop 8 shockedCluster []

/-- Gravitational cognitive wave packet calculation for 5-prime state. -/
def exampleGravitationalWave : Nat :=
  gravitationalWaveAmplitude examplePrism5

end LanglandsPrism
