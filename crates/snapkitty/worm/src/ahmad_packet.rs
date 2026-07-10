use serde::{Deserialize, Serialize};
use crate::reg_hom_manager::{Tick, CryptoAnchors};

/// The raw SUBLEQ operation memory offsets (A, B).
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SubleqDelta {
    pub a: u32,
    pub b: u32,
}

/// The domain-specific legal/economic logical assertions.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct DomainPredicate {
    pub avp_data: Vec<u8>,
    pub vp_data: Vec<u8>,
}

/// The synchronized drift certificate from the Sovereign Digital Twin.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct DriftCertificate {
    pub tissue_id: u32,
    pub tick: Tick,
    pub claimed_thickness: u32,
}

/// The serialized transport layer for Zeroproof Docking.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AhmadPacket {
    pub delta: SubleqDelta,
    pub predicates: DomainPredicate,
    pub drift_certificate: DriftCertificate,
    pub twin_signature: CryptoAnchors,
}

/// Extended WORM block containing tissue-specific tracking.
#[derive(Debug, Clone)]
pub struct TissueBlock {
    pub tissue_id: u32,
    pub tick: Tick,
    pub thickness: u32,
}

/// The Immutable Event Log containing sovereign tissue blocks.
pub struct WormLog {
    pub blocks: Vec<TissueBlock>,
}

impl WormLog {
    /// Retrieve the exact thickness anchored at a specific tick for a tissue.
    pub fn tissue_snapshot(&self, tissue_id: u32, tick: Tick) -> Option<u32> {
        self.blocks.iter()
            .find(|b| b.tissue_id == tissue_id && b.tick == tick)
            .map(|b| b.thickness)
    }
}

/// The Jubilee Coordination Window
pub struct JubileeWindow {
    pub start: Tick,
    pub end_tick: Tick,
}

/// Calculates the Jubilee window boundaries for a given global tick.
pub fn current_window(t: Tick, delta_j: Tick) -> JubileeWindow {
    let start = if delta_j == 0 { t } else { (t / delta_j) * delta_j };
    JubileeWindow {
        start,
        end_tick: start + delta_j,
    }
}

/// Jubilee Admission Filter (ADR-007 Phase 3)
/// Validates if an Ahmad Packet is admissible under the current Jubilee window constraints.
/// Replaces human levers with strict mathematical bounds.
pub fn jubilee_admissible(
    cert: &DriftCertificate,
    current_tick: Tick,
    delta_j: Tick,
    log: &WormLog,
) -> bool {
    let window = current_window(current_tick, delta_j);

    // 1. Packet tick must fall exactly within the currently active Jubilee window.
    if cert.tick < window.start || cert.tick >= window.end_tick {
        return false;
    }

    // 2. The claimed thickness must exactly match the TissueSnapshot anchored in the WORM log.
    if let Some(anchored_thickness) = log.tissue_snapshot(cert.tissue_id, cert.tick) {
        if anchored_thickness == cert.claimed_thickness {
            return true;
        }
    }

    // ⊥_R(E) - Immediate rejection path (No human override)
    false
}
