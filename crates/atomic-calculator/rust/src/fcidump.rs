//! FCIDUMP / Integral Parsing
//!
//! Ingests preprocessed one- and two-body integrals for MA-VQE.

use std::collections::HashMap;

/// Represents a loaded electronic structure active space from an FCIDUMP file.
pub struct FciDump {
    pub num_orbitals: usize,
    pub num_electrons: usize,
    /// Mocked 1-body integrals h_{pq}
    pub one_body: HashMap<(usize, usize), f64>,
    /// Mocked 2-body integrals h_{pqrs}
    pub two_body: HashMap<(usize, usize, usize, usize), f64>,
}

impl FciDump {
    /// Simulates parsing a preprocessed FCIDUMP file for the Reiher FeMoco benchmark
    pub fn mock_parse_reiher_femoco() -> Self {
        // The classical preprocessing (e.g. PySCF) has already frozen the core orbitals.
        // We ingest the truncated CAS(114, 114) integrals directly.
        Self {
            num_orbitals: 114,
            num_electrons: 114,
            one_body: HashMap::new(),
            two_body: HashMap::new(),
        }
    }
}
