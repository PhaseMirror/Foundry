use crate::sigma_layer::ZeroModeQuantities;
use std::time::{SystemTime, UNIX_EPOCH};
use sha2::{Sha256, Digest};

/// Represents the raw hardware telemetry from the AXI-Stream interface
#[derive(Debug, Clone)]
pub struct AxiTelemetry {
    pub drift_warning: bool,
    pub rho_violation: bool,
    pub raw_tdata: u32,
    pub timestamp_ns: u64,
}

impl AxiTelemetry {
    /// Parses the 32-bit tdata streamed from uac_safety_interlock
    pub fn from_tdata(tdata: u32) -> Self {
        let rho_violation = (tdata & 1) != 0;
        let drift_warning = (tdata & 2) != 0;
        
        let timestamp_ns = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos() as u64;
            
        Self {
            drift_warning,
            rho_violation,
            raw_tdata: tdata,
            timestamp_ns,
        }
    }
}

/// The immutable CRMF Request that will be anchored to the GitLedger
pub struct CrmfRequest {
    pub telemetry: AxiTelemetry,
    pub zm_snapshot: Option<ZeroModeQuantities>,
}

impl CrmfRequest {
    /// Generates the LawfulRecursionHash to seal the telemetry.
    /// (Using SHA-256 here to bootstrap the binding; ideally swapped for a ZK-friendly hash like Poseidon2 in full production)
    pub fn generate_lawful_recursion_hash(&self) -> String {
        let mut hasher = Sha256::new();
        
        // Bind the hardware fault bits
        hasher.update(self.telemetry.raw_tdata.to_be_bytes());
        hasher.update(self.telemetry.timestamp_ns.to_be_bytes());
        
        // Bind the pre-halt state snapshot if available
        if let Some(zm) = &self.zm_snapshot {
            hasher.update(zm.xi_magnitude.to_be_bytes());
            hasher.update(zm.lipschitz_t.to_be_bytes());
            
            // Sort primes to ensure deterministic hashing
            let mut primes: Vec<_> = zm.prime_weights.keys().copied().collect();
            primes.sort_unstable();
            
            for p in primes {
                if let Some(w) = zm.prime_weights.get(&p) {
                    hasher.update(p.to_be_bytes());
                    hasher.update(w.to_be_bytes());
                }
            }
        }
        
        let hash_bytes = hasher.finalize();
        let mut hash_str = String::with_capacity(64);
        for byte in hash_bytes {
            use std::fmt::Write;
            write!(&mut hash_str, "{:02x}", byte).unwrap();
        }
        hash_str
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    #[test]
    fn test_telemetry_packing() {
        // Simulating an AXI-Stream tdata with rho_violation (bit 0) and drift_warning (bit 1) both set to 1
        // Thus, tdata = 3
        let tdata: u32 = 3;
        let telemetry = AxiTelemetry::from_tdata(tdata);

        assert!(telemetry.rho_violation, "rho_violation should be true");
        assert!(telemetry.drift_warning, "drift_warning should be true");
        assert_eq!(telemetry.raw_tdata, 3, "raw_tdata should match");
        assert!(telemetry.timestamp_ns > 0, "Timestamp should be populated");
    }

    #[test]
    fn test_lawful_recursion_hash_binding() {
        // Construct mock ZM quantities
        let mut prime_weights = HashMap::new();
        prime_weights.insert(2, 0.1);
        prime_weights.insert(3, 0.15);

        let zm = ZeroModeQuantities {
            xi_magnitude: 0.5,
            lipschitz_t: 1.0,
            prime_weights,
        };

        // Simulating a safe state tdata (0)
        let mut telemetry = AxiTelemetry::from_tdata(0);
        // Force timestamp for deterministic hash test if needed, but here we just test it runs without error
        telemetry.timestamp_ns = 1689200000000000000;

        let request = CrmfRequest {
            telemetry,
            zm_snapshot: Some(zm),
        };

        let hash = request.generate_lawful_recursion_hash();
        assert_eq!(hash.len(), 64, "SHA-256 hash should be 64 hex characters");
        println!("Generated CRMF LawfulRecursionHash: {}", hash);
    }
}

