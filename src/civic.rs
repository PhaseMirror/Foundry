use multiplicity_common::identity::CivicProfile;

#[derive(Debug, Clone, Copy)]
pub enum SocioAtomicRole { Proton, Neutron, Electron, Nucleus }

#[derive(Debug, Clone, Copy)]
pub enum IndexedFactor { Resonance, Agency, Integrity, Viability }

pub struct Multiplicity {
    pub reciprocity: f64,
}

impl Multiplicity {
    /// M(R) = 2R + 1: The Multiplicity generation function.
    pub fn calculate(&self) -> f64 {
        2.0 * self.reciprocity + 1.0
    }
}

/// Aggregates system factors into a single civic state value.
pub fn calculate_civic_state(lambda_m: f64, factors: &[f64], res: f64, emb: f64) -> f64 {
    let factor_sum: f64 = factors.iter().sum();
    lambda_m * factor_sum * res * emb
}

#[derive(Debug)]
pub struct AtomicCivicAggregator {
    pub lambda_m: f64,
    pub embodied_viability: f64,
    pub ecosystem_reciprocity: f64,
}

impl AtomicCivicAggregator {
    /// Atomicity: Consumes a frozen snapshot slice of active CivicProfiles.
    /// Performance: O(N) single-pass aggregation designed to execute well under the 920ns target.
    #[inline(always)]
    pub fn calculate_civic_state(&self, active_profiles: &[CivicProfile]) -> f64 {
        if active_profiles.is_empty() {
            return 0.0; // Total dissonance/halt if network is empty
        }

        // Telemetry Integration: Summing the 4-Factor Minimal Core across the network
        // Optimization: Single accumulator for the combined factor sum reduces register pressure
        let factor_sum = active_profiles.iter().fold(0.0, |acc, profile| {
            acc + profile.resonance + profile.agency + profile.integrity + profile.viability
        });

        let n = active_profiles.len() as f64;
        
        // Final civic state calculation: lambda * (factor_sum / n) * reciprocity * embodied_viability
        self.lambda_m * (factor_sum / n) * self.ecosystem_reciprocity * self.embodied_viability
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compute_multiplicity() {
        let m = Multiplicity { reciprocity: 1.0 };
        assert_eq!(m.calculate(), 3.0);

        let m2 = Multiplicity { reciprocity: 0.0 };
        assert_eq!(m2.calculate(), 1.0);
    }

    #[test]
    fn test_calculate_civic_state() {
        let factors = vec![1.0, 2.0, 3.0, 4.0];
        let state = calculate_civic_state(0.5, &factors, 2.0, 1.5);
        // 0.5 * 10.0 * 2.0 * 1.5 = 15.0
        assert_eq!(state, 15.0);
    }

    #[test]
    fn test_atomic_civic_aggregator() {
        let agg = AtomicCivicAggregator {
            lambda_m: 0.5,
            embodied_viability: 1.5,
            ecosystem_reciprocity: 2.0,
        };
        let profiles = vec![
            CivicProfile { resonance: 1.0, agency: 1.0, integrity: 1.0, viability: 1.0 },
            CivicProfile { resonance: 3.0, agency: 3.0, integrity: 3.0, viability: 3.0 },
        ];
        // Average resonance = 2.0, agency = 2.0, integrity = 2.0, viability = 2.0
        // factor_sum = 8.0
        // state = 0.5 * 8.0 * 2.0 * 1.5 = 12.0
        assert_eq!(agg.calculate_civic_state(&profiles), 12.0);
    }

    #[test]
    fn bench_atomic_civic_aggregator() {
        let agg = AtomicCivicAggregator {
            lambda_m: 0.5,
            embodied_viability: 1.5,
            ecosystem_reciprocity: 2.0,
        };
        // Simulate a network of 1000 nodes
        let profiles: Vec<CivicProfile> = (0..1000).map(|i| CivicProfile {
            resonance: 1.0 + (i as f64 * 0.01 % 2.0),
            agency: 1.0,
            integrity: 1.0,
            viability: 1.0,
        }).collect();

        let iterations = 100_000;
        let start = std::time::Instant::now();
        for _ in 0..iterations {
            std::hint::black_box(agg.calculate_civic_state(&profiles));
        }
        let duration = start.elapsed();
        let ns_per_iter = (duration.as_nanos() as f64) / (iterations as f64);
        
        println!("BENCHMARK: Aggregator latency for 1000 nodes: {:.2} ns", ns_per_iter);
        assert!(ns_per_iter <= 920.0, "Latency exceeded 920ns target! Measured: {:.2}ns", ns_per_iter);
    }
}

