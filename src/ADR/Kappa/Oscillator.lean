import ADR.Kappa.PrimeIndex

/-!
# Prime-Indexed Coupled Oscillator Network

Formalizes the core model from ADR-114: a finite graph with nodes indexed
by prime numbers, coupled via prime-weighted interactions. This model
produces qualitatively distinct spectral properties compared to periodic
or random structures, grounded in the Dal Negro et al. results on prime
scattering arrays.

## Model System

The dynamics are governed by:
  dz_i/dt = -γ_i z_i + Σ_{j ∈ N(i)} J/(p_i p_j) z_j

where p_i is the i-th prime, γ_i > 0 are damping rates, J are coupling
constants, and N(i) denotes neighbors of node i.
-/

namespace ADR.Kappa

/-! ## Oscillator State -/

/-- A complex amplitude represented as (real, imag) pair. -/
structure Complex where
  re : Float
  im : Float
  deriving Repr

/-- Complex addition. -/
def complexAdd (a b : Complex) : Complex :=
  { re := a.re + b.re, im := a.im + b.im }

/-- Complex scalar multiplication. -/
def complexScale (s : Float) (a : Complex) : Complex :=
  { re := s * a.re, im := s * a.im }

/-- Complex modulus squared. -/
def complexNormSq (a : Complex) : Float :=
  a.re * a.re + a.im * a.im

/-! ## Network Topology -/

/-- A node in the oscillator network, indexed by a prime. -/
structure OscillatorNode where
  index     : Nat
  amplitude : Complex
  damping   : Float
  deriving Repr

/-- An edge between two nodes with coupling strength. -/
structure Edge where
  fromIdx : Nat
  toIdx   : Nat
  coupling : Float
  deriving Repr

/-- The oscillator network. -/
structure OscillatorNetwork where
  nodes : List OscillatorNode
  edges : List Edge
  deriving Repr

/-! ## Dynamics -/

/-- The neighbor set of a node. -/
def neighbors (net : OscillatorNetwork) (idx : Nat) : List Nat :=
  net.edges.filterMap (fun e =>
    if e.fromIdx = idx then some e.toIdx
    else if e.toIdx = idx then some e.fromIdx
    else none)

/-- The coupling strength between two nodes via prime-weighted formula. -/
def couplingStrength (J : Float) (pi pj : Nat) : Float :=
  primeCoupling J pi pj

/-- The drift term for a single oscillator: -γ_i z_i + Σ J/(p_i p_j) z_j. -/
def driftTerm (net : OscillatorNetwork) (J : Float) (idx : Nat) : Complex :=
  let nodeOpt := net.nodes.find? (·.index = idx)
  match nodeOpt with
  | none => { re := 0, im := 0 }
  | some node =>
    let decay := complexScale (-node.damping) node.amplitude
    let neighborContrib := (neighbors net idx).foldl (fun acc nIdx =>
      let nOpt := net.nodes.find? (·.index = nIdx)
      match nOpt with
      | none => acc
      | some n =>
        let coupling := couplingStrength J (primeSeq idx) (primeSeq nIdx)
        complexAdd acc (complexScale coupling n.amplitude)
    ) { re := 0, im := 0 }
    complexAdd decay neighborContrib

/-! ## Bounded Dynamics -/

/-- The coupling matrix A_{ij} = J/(p_i p_j) for adjacent nodes. -/
def couplingMatrixEntry (J : Float) (pi pj : Nat) (connected : Bool) : Float :=
  if connected then couplingStrength J pi pj else 0.0

/-- The network is dissipative if all damping rates are positive. -/
def isDissipative (net : OscillatorNetwork) : Prop :=
  ∀ n ∈ net.nodes, n.damping > 0

/-- The prime-weighted energy: E(z) = Σ |z_i|^2 / p_i. -/
def primeWeightedEnergy (net : OscillatorNetwork) : Float :=
  net.nodes.foldl (fun acc n =>
    acc + complexNormSq n.amplitude / Float.ofNat (primeSeq n.index)
  ) 0.0

/-- The energy is non-negative. -/
theorem energy_nonneg (net : OscillatorNetwork) :
    primeWeightedEnergy net ≥ 0 := by
  sorry

/-! ## Convergence Prediction -/

/-- The predicted relaxation time: τ_relax ~ 1/(γ - ||A||_2). -/
def relaxationTime (gamma_min normA : Float) : Float :=
  if gamma_min > normA then 1.0 / (gamma_min - normA)
  else 0.0

end ADR.Kappa
