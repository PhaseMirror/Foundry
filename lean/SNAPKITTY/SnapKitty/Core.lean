namespace Sovereign.Policy

abbrev PolicyId     := String
abbrev Role         := String
abbrev CorrelationId := String
abbrev HashURI      := String
abbrev DID          := String
abbrev Subject      := String

structure Evidence where
  refs       : List HashURI
  hashes     : List ByteArray
  signatures : List (DID × ByteArray)

structure Context where
  correlation_id : CorrelationId
  actor          : DID
  task_type      : String
  evidence       : Evidence
  timestamp      : UInt64
  nonce          : ByteArray

inductive Verdict where
  | approve       (policy_id : PolicyId) : Verdict
  | reject        (policy_id : PolicyId) : Verdict
  | defer         (reason    : String)   : Verdict
  | escalate      (target    : Role)     : Verdict
  | human_required (policy_ids : List PolicyId) : Verdict
  deriving BEq

def Verdict.priority : Verdict → Nat
  | .escalate _      => 4
  | .human_required _ => 3
  | .reject _        => 2
  | .defer _         => 1
  | .approve _       => 0

def Verdict.combine (vs : List Verdict) : Verdict :=
  match vs with
  | []      => Verdict.approve "SOV-DEFAULT-PASS"
  | v :: rest =>
    rest.foldl (fun acc cur =>
      if cur.priority > acc.priority then
        match acc, cur with
        | .human_required ps, .human_required qs => .human_required (ps ++ qs)
        | _,                   _                  => cur
      else
        match acc, cur with
        | .human_required ps, .human_required qs => .human_required (ps ++ qs)
        | _,                   _                  => acc
    ) v

class Policy (π : PolicyId) where
  eval : Context → Verdict

def Verdict.isFinal : Verdict → Bool
  | .approve _ | .reject _ => true
  | _                      => false

def Verdict.requiresHuman : Verdict → Bool
  | .human_required _ => true
  | _                 => false

def Verdict.toNatsSubject : Verdict → Subject
  | .approve _        => "sovereign.audit.bifrost.commit.v1"
  | .reject _         => "sovereign.audit.bifrost.commit.v1"
  | .defer _          => "sovereign.governance.decision.pending.v1"
  | .escalate _       => "sovereign.governance.decision.pending.v1"
  | .human_required _ => "sovereign.governance.decision.pending.v1"

end Sovereign.Policy



namespace SnapKitty.Math

-- SCALE = 10000 ensures deterministic fraction logic without floats
def SCALE : Nat := 10000

-- 1. Thermal Window
structure ThermalWindow where
  lo : Nat
  hi : Nat
  valid : lo ≤ hi

def computeEMA (eps_scaled : Nat) : Nat :=
  (9 * eps_scaled + 1 * 5000) / 10

def thermalWindowScaled (eps_scaled : Nat) (d_max : Nat) (h_dmax : d_max ≥ 1) : ThermalWindow :=
  let ema := computeEMA eps_scaled
  let lo_sub := (8000 * ema) / 10000
  let lo := 10000 - lo_sub
  let hi_raw := 10000 + (12000 * ema) / 10000
  let hi := if d_max * 10000 < hi_raw then d_max * 10000 else hi_raw
  { lo := lo,
    hi := hi,
    valid := by
      dsimp [hi]
      split
      · have h1 : lo ≤ 10000 := Nat.sub_le _ _
        have h2 : 10000 ≤ d_max * 10000 := by
          calc 10000 = 1 * 10000 := by rw [Nat.one_mul]
               _     ≤ d_max * 10000 := Nat.mul_le_mul_right 10000 h_dmax
        exact Nat.le_trans h1 h2
      · have h1 : lo ≤ 10000 := Nat.sub_le _ _
        have h2 : 10000 ≤ hi_raw := Nat.le_add_right _ _
        exact Nat.le_trans h1 h2
  }

-- 2. QuantumM Monad
inductive QuantumM (α : Type) : Type where
  | pure (a : α)
  | superpose (branches : List (Nat × α))
  | collapse (state : α)

def QuantumM.bind {α β : Type} (ma : QuantumM α) (f : α → QuantumM β) (fallback : β) : QuantumM β :=
  match ma with
  | .pure a => f a
  | .superpose bs => 
      .superpose (bs.map fun x => (x.1, match f x.2 with
                                        | .pure b => b
                                        | .collapse b => b
                                        | .superpose _ => fallback))
  | .collapse a => 
      .collapse (match f a with
                 | .pure b => b
                 | .collapse b => b
                 | .superpose _ => fallback)

theorem bind_collapse_no_clone {α β : Type} (a : α) (f : α → QuantumM β) (fb : β) :
  QuantumM.bind (.collapse a) f fb = .collapse (match f a with
                                                | .pure b => b
                                                | .collapse b => b
                                                | .superpose _ => fb) := rfl

-- 3. call49 mirror identity
def call49 {α : Type} (X : List α) : List α :=
  X.reverse

theorem call49_mirror {α : Type} (X : List α) : call49 (call49 X) = X :=
  List.reverse_reverse X

-- 4. Von Neumann Entropy
def H_max_scaled : Nat := 60000 -- 6.0 bits * 10000

def checkEntropyBound (s_rho_scaled : Nat) : Bool :=
  s_rho_scaled ≤ H_max_scaled

-- 5. MA-VQE Compiler Thresholds
def chemicalAccuracyThresholdMhaScaled : Nat := 150000 -- 15 mHa * 10000

def checkChemicalAccuracy (energy_mha_scaled : Nat) : Bool :=
  energy_mha_scaled < chemicalAccuracyThresholdMhaScaled

end SnapKitty.Math
