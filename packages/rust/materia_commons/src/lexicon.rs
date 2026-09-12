// materia_commons/src/lexicon.rs

use num_bigint::BigUint;

#[derive(Debug, Clone, Copy)]
pub enum TopologyState {
    Full,    // 3 Anchors
    Partial, // 2 Anchors
    Solo,    // 1 Anchor
}

#[derive(Debug, Clone, Copy)]
pub enum CivicAction {
    ResonanceCalibration,
    TreasuryDisbursement,
    DissonanceFlag,
    ProtocolUpgrade,
}

pub struct PrimeLexicon;

impl PrimeLexicon {
    #[inline(always)]
    pub fn get_topology_prime(state: TopologyState) -> BigUint {
        match state {
            TopologyState::Full => BigUint::from(2u32),
            TopologyState::Partial => BigUint::from(3u32),
            TopologyState::Solo => BigUint::from(5u32),
        }
    }

    #[inline(always)]
    pub fn get_action_prime(action: CivicAction) -> BigUint {
        match action {
            CivicAction::ResonanceCalibration => BigUint::from(7u32),
            CivicAction::TreasuryDisbursement => BigUint::from(11u32),
            CivicAction::DissonanceFlag => BigUint::from(13u32),
            CivicAction::ProtocolUpgrade => BigUint::from(17u32),
        }
    }

    /// Generates the composite P_triad vector for the Living Ledger transition
    pub fn generate_p_triad(state: TopologyState, action: CivicAction) -> BigUint {
        let p_topo = Self::get_topology_prime(state);
        let p_act = Self::get_action_prime(action);
        
        // P_triad = p_topo * p_act
        p_topo * p_act 
    }
}
