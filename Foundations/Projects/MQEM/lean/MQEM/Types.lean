/-!
# MQEM.Types — Data Structures for the Modular Multiplicative Ecosystem Model

Formalizes core ecosystem entities:
- HabitatGraph: vertices, adjacency, dispersal coupling
- PatchState: species biomasses / occupancy levels at a habitat patch
- AugmentedState: delayed history vector X_v(t) = [x(t), x(t-1), ..., x(t-tau)]
- ModelConfig: time step, delay tau, noise scale, Lipschitz drift parameters
-/

namespace MQEM

/-- Habitat node identifier. -/
def NodeId := Nat
deriving Repr, DecidableEq

/-- Discrete state vector of d ecological variables (e.g. species biomasses, resources). -/
structure PatchState (d : Nat) where
  values : List Int
  valid  : values.length = d
  deriving Repr

/-- History buffer representing the augmented state X_v(t) over delay horizon tau. -/
structure AugmentedState (d tau : Nat) where
  history : List (PatchState d)
  valid   : history.length = tau + 1
  deriving Repr

/-- Edge in the habitat network with integer coupling strength. -/
structure DispersalEdge where
  source : NodeId
  target : NodeId
  weight : Nat
  deriving Repr, DecidableEq

/-- Habitat graph G = (V, E) of patches. -/
structure HabitatGraph where
  num_nodes : Nat
  edges     : List DispersalEdge
  deriving Repr

/-- Core model configuration and hyper-parameters. -/
structure ModelConfig where
  dim_d     : Nat
  delay_tau : Nat
  dt_scale  : Nat  -- discrete integer scaling factor for dt (e.g. 1000 = 1.0)
  drift_l_f : Nat  -- Lipschitz constant L_F scaled by 1000
  coup_norm : Nat  -- Coupling norm ||A|| scaled by 1000
  noise_c2  : Nat  -- Noise upper bound c_2 scaled by 1000
  deriving Repr, DecidableEq

end MQEM
