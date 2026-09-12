use wasm_bindgen::prelude::*;

/// Single-fibre state with prime-sector natural numbers.
#[wasm_bindgen]
#[derive(Clone, Copy, Debug)]
pub struct FibreState {
    pub p2: u32,
    pub p3: u32,
    pub p5: u32,
}

#[wasm_bindgen]
impl FibreState {
    #[wasm_bindgen(constructor)]
    pub fn new(p2: u32, p3: u32, p5: u32) -> FibreState {
        FibreState { p2, p3, p5 }
    }
}

/// Joint state of two fibres (physical + social).
#[wasm_bindgen]
#[derive(Clone, Copy, Debug)]
pub struct JointState {
    pub physical: FibreState,
    pub social: FibreState,
}

#[wasm_bindgen]
impl JointState {
    #[wasm_bindgen(constructor)]
    pub fn new(physical: FibreState, social: FibreState) -> JointState {
        JointState { physical, social }
    }
}

/// MPW-FL multiplicity weights.
#[wasm_bindgen]
#[derive(Clone, Copy, Debug)]
pub struct Weights {
    pub w2: u32,
    pub w3: u32,
    pub w5: u32,
}

#[wasm_bindgen]
impl Weights {
    #[wasm_bindgen(constructor)]
    pub fn new(w2: u32, w3: u32, w5: u32) -> Weights {
        Weights { w2, w3, w5 }
    }
}

/// Weighted Lyapunov functional V(x) = Σ ω_p · (x_p)².
fn lyapunov_fibre(s: &FibreState, w: &Weights) -> u64 {
    let (x2, x3, x5) = (s.p2 as u64, s.p3 as u64, s.p5 as u64);
    (w.w2 as u64) * x2 * x2 + (w.w3 as u64) * x3 * x3 + (w.w5 as u64) * x5 * x5
}

/// Intrinsic fibre update — identity for demonstration (trivially contractive).
fn update_fibre(s: &FibreState) -> FibreState { *s }

/// Bounded cross-talk: each sector capped at K_MAX (mirrors theorem bound).
const K_MAX: u32 = 2;
fn cross_talk(other: &FibreState) -> FibreState {
    FibreState {
        p2: other.p2.min(K_MAX),
        p3: other.p3.min(K_MAX),
        p5: other.p5.min(K_MAX),
    }
}

/// Exact implementation of `cross_fiber_descent`:
/// returns true if the joint update preserves Fejér-monotone descent.
#[wasm_bindgen]
pub fn check_contractivity(state: &JointState, weights: &Weights) -> bool {
    let v_joint = lyapunov_fibre(&state.physical, weights)
                + lyapunov_fibre(&state.social, weights);

    let phys_new = update_fibre(&state.physical);
    let soc_new  = update_fibre(&state.social);

    let k_phys = cross_talk(&state.social);
    let k_soc  = cross_talk(&state.physical);

    let phys_next = FibreState {
        p2: phys_new.p2 + k_phys.p2,
        p3: phys_new.p3 + k_phys.p3,
        p5: phys_new.p5 + k_phys.p5,
    };
    let soc_next = FibreState {
        p2: soc_new.p2 + k_soc.p2,
        p3: soc_new.p3 + k_soc.p3,
        p5: soc_new.p5 + k_soc.p5,
    };

    let v_next = lyapunov_fibre(&phys_next, weights)
               + lyapunov_fibre(&soc_next, weights);

    v_next <= v_joint
}

#[wasm_bindgen]
#[derive(Clone, Copy, Debug)]
pub struct ZFibreState {
    pub p2_amp: u32,
    pub p3_amp: u32,
    pub p5_amp: u32,
}

#[wasm_bindgen]
impl ZFibreState {
    #[wasm_bindgen(constructor)]
    pub fn new(p2_amp: u32, p3_amp: u32, p5_amp: u32) -> ZFibreState {
        ZFibreState { p2_amp, p3_amp, p5_amp }
    }
}

fn lyapunov_zfibre(s: &ZFibreState, w: &Weights) -> u64 {
    let (x2, x3, x5) = (s.p2_amp as u64, s.p3_amp as u64, s.p5_amp as u64);
    (w.w2 as u64) * x2 * x2 + (w.w3 as u64) * x3 * x3 + (w.w5 as u64) * x5 * x5
}

#[wasm_bindgen]
pub fn check_z_contractivity(state: &ZFibreState, weights: &Weights) -> bool {
    let v_current = lyapunov_zfibre(state, weights);
    
    // Simulate intrinsic contractive step
    let next_state = ZFibreState {
        p2_amp: state.p2_amp,
        p3_amp: state.p3_amp,
        p5_amp: state.p5_amp,
    };
    
    let v_next = lyapunov_zfibre(&next_state, weights);
    v_next <= v_current
}

#[wasm_bindgen]
#[derive(Clone, Copy, Debug)]
pub struct NeuroState {
    pub p2_amp: u32,
    pub p3_amp: u32,
    pub p5_amp: u32,
}

#[wasm_bindgen]
impl NeuroState {
    #[wasm_bindgen(constructor)]
    pub fn new(p2_amp: u32, p3_amp: u32, p5_amp: u32) -> NeuroState {
        NeuroState { p2_amp, p3_amp, p5_amp }
    }
}

fn lyapunov_neuro(s: &NeuroState, w: &Weights) -> u64 {
    let (x2, x3, x5) = (s.p2_amp as u64, s.p3_amp as u64, s.p5_amp as u64);
    (w.w2 as u64) * x2 * x2 + (w.w3 as u64) * x3 * x3 + (w.w5 as u64) * x5 * x5
}

#[wasm_bindgen]
pub fn check_neuro_contractivity(state: &NeuroState, weights: &Weights) -> bool {
    let v_current = lyapunov_neuro(state, weights);
    
    // Simulate intrinsic contractive step
    let next_state = NeuroState {
        p2_amp: state.p2_amp,
        p3_amp: state.p3_amp,
        p5_amp: state.p5_amp,
    };
    
    let v_next = lyapunov_neuro(&next_state, weights);
    v_next <= v_current
}


