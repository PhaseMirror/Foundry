//! Phase 1 P=11 Pilot Suite & Canonical Symbol Library

use crate::csc::{ConsciousSymbol, SymbolRegistry};

pub struct PilotP11Suite;

impl PilotP11Suite {
    /// 11-prime mask: P = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31}
    pub fn get_prime_mask() -> Vec<u64> {
        vec![2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31]
    }

    /// Load the 8 canonical pilot symbols specified in templateArxiv.tex §10.1:
    /// (○, 3), (ζ, 2), (yin-yang, 5), (△, 7), (Π, 11), (m, 13), (♡, 17), (Ω, 19)
    pub fn create_pilot_registry() -> SymbolRegistry {
        let mut registry = SymbolRegistry::new(1.0);

        let symbols = vec![
            ConsciousSymbol::new("circle_3", 3, vec![(1, 0.8, 0.0), (2, 0.3, 0.1)], (1.0, 0.0), 0.95),
            ConsciousSymbol::new("zeta_2", 2, vec![(1, 0.9, 0.0), (2, 0.4, 0.0)], (0.8, 0.2), 0.90),
            ConsciousSymbol::new("yin_yang_5", 5, vec![(1, 0.7, 0.7), (2, 0.2, -0.2)], (1.0, 0.0), 1.0),
            ConsciousSymbol::new("triangle_7", 7, vec![(1, 0.6, 0.0), (2, 0.1, 0.0)], (0.7, 0.0), 0.85),
            ConsciousSymbol::new("pi_11", 11, vec![(1, 0.85, 0.0), (2, 0.15, 0.0)], (0.9, 0.1), 0.95),
            ConsciousSymbol::new("moonshine_13", 13, vec![(1, 0.5, 0.5), (2, 0.2, 0.0)], (0.6, 0.0), 0.80),
            ConsciousSymbol::new("heart_17", 17, vec![(1, 0.75, 0.0), (2, 0.25, 0.0)], (0.8, 0.0), 0.90),
            ConsciousSymbol::new("omega_19", 19, vec![(1, 0.9, 0.0), (2, 0.3, 0.0)], (1.0, 0.0), 1.0),
        ];

        for sym in symbols {
            registry.register(sym);
        }

        registry
    }
}
