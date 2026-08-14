use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// ── Type Aliases from the Contract ─────────────────────────
pub type Tick = u64;
pub type TissueId = u32;
pub type Prime = u32;
pub type Thickness = u32; // surviving_structure metric
pub type Token1 = bool;

// ── Data Structures ────────────────────────────────────────

/// A minimal native audit block recording a single tissue's thickness at a tick.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct AuditBlock {
    pub tissue_id: TissueId,
    pub tick: Tick,
    pub thickness: Thickness,
    pub anchored_ere_passes: u32, // count of successful ERE passes
    pub prime_factor: u32,        // characteristic prime for the tissue
}

/// The simulated native append-only log – monotonically increasing thickness.
#[derive(Debug, Clone, Default)]
pub struct AppendOnlyLog {
    pub blocks: Vec<AuditBlock>,
}

impl AppendOnlyLog {
    /// Append a block if it respects monotonic thickness growth.
    pub fn commit(&mut self, block: AuditBlock) -> Result<(), &'static str> {
        if let Some(last) = self
            .blocks
            .iter()
            .filter(|b| b.tissue_id == block.tissue_id)
            .last()
        {
            if block.thickness < last.thickness {
                return Err("thickness regression");
            }
        }
        self.blocks.push(block);
        Ok(())
    }

    /// Retrieve the latest thickness snapshot for a tissue at a given tick.
    pub fn tissue_snapshot(&self, tissue_id: TissueId, tick: Tick) -> Option<Thickness> {
        self.blocks
            .iter()
            .filter(|b| b.tissue_id == tissue_id && b.tick <= tick)
            .last()
            .map(|b| b.thickness)
    }

    /// Current live thickness for a tissue (most recent committed).
    pub fn live_thickness(&self, tissue_id: TissueId) -> Thickness {
        self.blocks
            .iter()
            .filter(|b| b.tissue_id == tissue_id)
            .last()
            .map(|b| b.thickness)
            .unwrap_or(0)
    }
}

/// A RegHom registry entry.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MorphismRecord {
    pub src_prime: Prime,
    pub tgt_prime: Prime,
    pub expiration_tick: Tick,
    pub lam_certificate_hash: [u8; 32],
    pub valid: bool,
}

/// The simulated RegHom registry – O(1) lookup via HashMap.
pub struct RegHomRegistry {
    pub morphisms: HashMap<(Prime, Prime), MorphismRecord>,
}

impl RegHomRegistry {
    pub fn new() -> Self {
        Self {
            morphisms: HashMap::new(),
        }
    }

    pub fn lookup(&self, src: Prime, tgt: Prime, current_tick: Tick) -> Option<&MorphismRecord> {
        self.morphisms
            .get(&(src, tgt))
            .filter(|m| m.valid && m.expiration_tick > current_tick)
    }
}

// ── The Contract's Exact Function Signature ─────────────────
/// This function must be called for every cross‑domain transition.
/// Returns `Ok(Token1)` if the bridge is lawful, otherwise `Err(reason)` (⊥_R(E)).
pub fn evaluate_governed_bridge(
    src_prime: Prime,
    tgt_prime: Prime,
    tissue_id: TissueId,
    current_tick: Tick,
    jubilee_window: (Tick, Tick), // (start, end)
    audit_log: &AppendOnlyLog,
    reg_hom: &RegHomRegistry,
    pre_memory: &[u8; 4],  // simplified memory snapshot before transition
    post_memory: &[u8; 4], // memory after applying SUBLEQ delta
) -> Result<Token1, String> {
    // ── Gate 1: Jubilee Admission Filter ─────────────────
    let (window_start, window_end) = jubilee_window;
    if current_tick < window_start || current_tick >= window_end {
        return Err("Jubilee violation: tick outside active window".into());
    }

    // ── Gate 2: RegHom Clonal Selection (lookup) ─────────
    let _morphism = reg_hom
        .lookup(src_prime, tgt_prime, current_tick)
        .ok_or_else(|| "RegHom rejection: no valid morphism".to_string())?;

    // Optional: Verify Λ‑certificate hash via FFI (simulate here)
    // In the harness we accept the morphism if present.

    // ── Gate 3: Tissue snapshot must match live thickness ─
    let snapshot = audit_log
        .tissue_snapshot(tissue_id, current_tick)
        .ok_or_else(|| "No tissue snapshot in native audit log".to_string())?;
    let live_thickness = audit_log.live_thickness(tissue_id);
    if snapshot != live_thickness {
        return Err("Tissue thickness desynchronization".into());
    }

    // ── Gate 4: Compute surviving_structure thickness ─────
    // Simulate memory transition effect: compute thickness as anchored ERE passes × prime factor.
    // Here we use a deterministic function: count of set bits difference as a proxy for pass complexity,
    // then multiply by tissue's prime factor (from the audit block).
    let last_block = audit_log
        .blocks
        .iter()
        .filter(|b| b.tissue_id == tissue_id)
        .last()
        .ok_or_else(|| "No prior block for tissue".to_string())?;
    let prime_factor = last_block.prime_factor;

    // Dynamic computation: difference in memory state → ERE pass count.
    let pre_sum: u32 = pre_memory.iter().map(|&b| b.count_ones()).sum();
    let post_sum: u32 = post_memory.iter().map(|&b| b.count_ones()).sum();
    let pass_count = if post_sum >= pre_sum {
        post_sum - pre_sum
    } else {
        0
    };
    let post_thickness = pass_count * prime_factor;

    // ── Gate 5: Non‑expansion check ───────────────────────
    if post_thickness > live_thickness {
        return Err(format!(
            "Non‑expansion violation: post_thickness {} > live_thickness {}",
            post_thickness, live_thickness
        ));
    }

    // ── All gates passed ──────────────────────────────────
    Ok(true) // Token‑1 emitted
}

// ── Simulated Runtime ────────────────────────────
/// Simulates the full Treasury→Clinical trace as defined in the contract.
pub fn run_treasury_clinical_trace() -> Result<(), String> {
    // Setup
    let mut audit_log = AppendOnlyLog::default();
    // Initial commitment for tissue 1 (Treasury)
    audit_log
        .commit(AuditBlock {
            tissue_id: 1,
            tick: 0,
            thickness: 10,
            anchored_ere_passes: 2,
            prime_factor: 5, // 5 = 3rd prime (proxy)
        })
        .unwrap();

    let mut reg_hom = RegHomRegistry::new();
    // Register Treasury→Clinical morphism (e.g., prime 2 → 3)
    reg_hom.morphisms.insert(
        (2, 3),
        MorphismRecord {
            src_prime: 2,
            tgt_prime: 3,
            expiration_tick: 100,
            lam_certificate_hash: [0u8; 32],
            valid: true,
        },
    );

    let jubilee_window = (0, 50);

    // Memory states (simplified 4-byte arrays)
    let pre_memory = [0x01, 0x02, 0x03, 0x04];
    let post_memory = [0x02, 0x03, 0x04, 0x05]; // slight increase in set bits

    let result = evaluate_governed_bridge(
        2,
        3,  // src_prime, tgt_prime
        1,  // tissue_id
        10, // current_tick (inside window)
        jubilee_window,
        &worm_log,
        &reg_hom,
        &pre_memory,
        &post_memory,
    );

    assert!(
        result.is_ok(),
        "Expected lawful bridge, got {}",
        result.err().unwrap()
    );
    println!("Treasury→Clinical trace PASSED. Token‑1 emitted.");
    Ok(())
}

// ── Negative Test Cases ────────────────────────────────────
#[cfg(test)]
mod tests {
    use super::*;

    fn setup() -> (WormLog, RegHomRegistry, (Tick, Tick)) {
        let mut log = WormLog::default();
        log.commit(WormBlock {
            tissue_id: 1,
            tick: 0,
            thickness: 20,
            anchored_ere_passes: 4,
            prime_factor: 5,
        })
        .unwrap();
        let mut reg = RegHomRegistry::new();
        reg.morphisms.insert(
            (2, 3),
            MorphismRecord {
                src_prime: 2,
                tgt_prime: 3,
                expiration_tick: 100,
                lam_certificate_hash: [0; 32],
                valid: true,
            },
        );
        (log, reg, (0, 50))
    }

    #[test]
    fn test_valid_bridge() {
        let (log, reg, window) = setup();
        let pre = [0u8; 4];
        let post = [0u8; 4]; // no change → thickness 0 ≤ 20
        let res = evaluate_governed_bridge(2, 3, 1, 10, window, &log, &reg, &pre, &post);
        assert!(res.is_ok());
    }

    #[test]
    fn test_stale_tick() {
        let (log, reg, window) = setup();
        let pre = [0u8; 4];
        let post = [0u8; 4];
        let res = evaluate_governed_bridge(2, 3, 1, 51, window, &log, &reg, &pre, &post);
        assert!(res.is_err());
        assert!(res.unwrap_err().contains("Jubilee violation"));
    }

    #[test]
    fn test_unregistered_morphism() {
        let (log, reg, window) = setup();
        let pre = [0u8; 4];
        let post = [0u8; 4];
        // (4,5) not registered
        let res = evaluate_governed_bridge(4, 5, 1, 10, window, &log, &reg, &pre, &post);
        assert!(res.is_err());
    }

    #[test]
    fn test_non_expansion_violation() {
        let (log, reg, window) = setup();
        // Memory change that causes thickness > 20
        // pre sum = 0, post sum = 5 → pass_count =5, prime_factor=5 → 25 > 20
        let pre = [0u8; 4];
        let post = [0xFF, 0xFF, 0xFF, 0xFF]; // 32 set bits → sum=32 → pass_count=32, thickness=160
        let res = evaluate_governed_bridge(2, 3, 1, 10, window, &log, &reg, &pre, &post);
        assert!(res.is_err());
        assert!(res.unwrap_err().contains("Non‑expansion violation"));
    }
}
