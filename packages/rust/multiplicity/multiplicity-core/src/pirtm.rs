
pub type GroundingType = bool;
pub type GroundingHook = u32;
pub type Context = u32;
pub type Actor = u32;
pub type Time = u32;

#[derive(Clone, Copy)]
pub struct Event {
    pub prime: u32,
    pub time: Time,
    pub context: Context,
    pub actor: Actor,
    pub hooks: [GroundingHook; 4],
}

#[derive(Clone, Copy)]
pub struct BranchState {
    pub embedding: [u32; 8],
    pub stance: [u32; 4],
    pub institution: [u32; 4],
    pub grounding_coverage: u32,
}

#[derive(Clone, Copy)]
pub struct Field {
    pub branches: [BranchState; 2],
    pub tension_matrix: [[u32; 2]; 2],
}

pub fn tension(b1: BranchState, b2: BranchState, _alpha: u32, _beta: u32, _gamma: u32, eta: u32) -> u32 {
    let diff = if b1.grounding_coverage > b2.grounding_coverage {
        b1.grounding_coverage - b2.grounding_coverage
    } else {
        b2.grounding_coverage - b1.grounding_coverage
    };
    eta.saturating_mul(diff)
}

pub enum GateResult {
    Pass(BranchState),
    RejectGrounding,
    RejectRobustness,
}

pub fn grounding_gate(b: BranchState, gamma_min: u32) -> GateResult {
    if b.grounding_coverage >= gamma_min {
        GateResult::Pass(b)
    } else {
        GateResult::RejectGrounding
    }
}
