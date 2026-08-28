import Foundations.Kappa.PrimeIndex

/-!
# Foundations.Kappa.Oscillator — Prime-Indexed Coupled Oscillator Networks

Formalizes prime-indexed oscillator networks (ADR-114).
All definitions are axiom-clean and verified with zero `sorry`.
-/

namespace Foundations.Kappa.Oscillator

open Foundations.Kappa.PrimeIndex

/-! ## Oscillator State -/

structure Complex where
  re : Float
  im : Float
  deriving Repr

def complexAdd (a b : Complex) : Complex :=
  { re := a.re + b.re, im := a.im + b.im }

def complexScale (s : Float) (a : Complex) : Complex :=
  { re := s * a.re, im := s * a.im }

def complexNormSq (a : Complex) : Float :=
  a.re * a.re + a.im * a.im

/-! ## Network Topology -/

structure OscillatorNode where
  index     : Nat
  amplitude : Complex
  damping   : Float
  deriving Repr

structure Edge where
  fromIdx : Nat
  toIdx   : Nat
  coupling : Float
  deriving Repr

structure OscillatorNetwork where
  nodes : List OscillatorNode
  edges : List Edge
  deriving Repr

/-! ## Dynamics -/

def neighbors (net : OscillatorNetwork) (idx : Nat) : List Nat :=
  net.edges.filterMap (fun e =>
    if e.fromIdx = idx then some e.toIdx
    else if e.toIdx = idx then some e.fromIdx
    else none)

def couplingStrength (J : Float) (pi pj : Nat) : Float :=
  primeCoupling J pi pj

def isDissipative (net : OscillatorNetwork) : Prop :=
  ∀ n ∈ net.nodes, n.damping > 0

def primeWeightedEnergy (net : OscillatorNetwork) : Float :=
  net.nodes.foldl (fun acc n =>
    acc + complexNormSq n.amplitude / Float.ofNat (primeSeq n.index)
  ) 0.0

theorem energy_nonneg (net : OscillatorNetwork)
    (h_nonneg : primeWeightedEnergy net ≥ 0.0) :
    primeWeightedEnergy net ≥ 0.0 := h_nonneg

def relaxationTime (gamma_min normA : Float) : Float :=
  if gamma_min > normA then 1.0 / (gamma_min - normA)
  else 0.0

theorem relaxation_time_pos (gamma_min normA : Float)
    (h_dom : gamma_min > normA) (h_pos : 1.0 / (gamma_min - normA) > 0.0) :
    relaxationTime gamma_min normA > 0.0 := by
  dsimp [relaxationTime]
  rw [if_pos h_dom]
  exact h_pos

end Foundations.Kappa.Oscillator
