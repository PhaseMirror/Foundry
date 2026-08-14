use crate::manifest::EnsembleManifest;
use std::collections::HashMap;

#[derive(Debug)]
pub enum LinkerError {
    DependencyNotFound(String),
    SpectralBudgetExceeded {
        ensemble: String,
        total: f64,
        limit: f64,
    },
    IncompatiblePrime(u64, u64),
}

/// The SpectralGovernor oversees the linking of multiple ensembles.
/// It ensures that their composite spectral radius stays within contractive bounds (< 1.0).
pub struct SpectralGovernor {
    registry: HashMap<String, EnsembleManifest>,
}

impl SpectralGovernor {
    pub fn new() -> Self {
        Self {
            registry: HashMap::new(),
        }
    }

    /// Register an available ensemble manifest into the linker's registry.
    pub fn register(&mut self, manifest: EnsembleManifest) {
        self.registry
            .insert(manifest.ensemble.name.clone(), manifest);
    }

    /// Link a root ensemble, verifying all dependencies and spectral bounds recursively.
    pub fn link(&self, root_name: &str) -> Result<(), LinkerError> {
        let root_manifest = self
            .registry
            .get(root_name)
            .ok_or_else(|| LinkerError::DependencyNotFound(root_name.to_string()))?;

        self.verify_composition(root_manifest)
    }

    fn verify_composition(&self, manifest: &EnsembleManifest) -> Result<(), LinkerError> {
        let mut total_spectral_radius = manifest.governance.spectral_radius;

        if let Some(deps) = &manifest.dependencies {
            for (dep_name, dep_meta) in deps {
                let dep_manifest = self
                    .registry
                    .get(dep_name)
                    .ok_or_else(|| LinkerError::DependencyNotFound(dep_name.to_string()))?;

                // Add the dependency's declared max budget
                total_spectral_radius += dep_meta.spectral_max;

                // Prime compatibility check: If a dependency requests a specific prime,
                // it must match the dependency's actual prime.
                if let Some(expected_prime) = dep_meta.prime_index {
                    if expected_prime != dep_manifest.ensemble.prime_index {
                        return Err(LinkerError::IncompatiblePrime(
                            expected_prime,
                            dep_manifest.ensemble.prime_index,
                        ));
                    }
                }

                // Recursively verify the dependency
                self.verify_composition(dep_manifest)?;
            }
        }

        if total_spectral_radius >= 1.0 {
            return Err(LinkerError::SpectralBudgetExceeded {
                ensemble: manifest.ensemble.name.clone(),
                total: total_spectral_radius,
                limit: 1.0,
            });
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::manifest::{DependencyMeta, EnsembleMeta, GovernanceMeta};

    #[test]
    fn test_linker_composition_success() {
        let mut governor = SpectralGovernor::new();

        let mut deps = HashMap::new();
        deps.insert(
            "tensor-ops".to_string(),
            DependencyMeta {
                version: "0.1".to_string(),
                spectral_max: 0.3,
                prime_index: Some(17),
            },
        );

        let main = EnsembleManifest {
            ensemble: EnsembleMeta {
                name: "main-app".to_string(),
                version: "1.0".to_string(),
                prime_index: 2,
                description: None,
                authors: None,
            },
            governance: GovernanceMeta {
                spectral_radius: 0.5,
                epsilon: None,
                contractivity_receipt: "hash1".to_string(),
                ledger_anchor: None,
            },
            dependencies: Some(deps),
        };

        let dep = EnsembleManifest {
            ensemble: EnsembleMeta {
                name: "tensor-ops".to_string(),
                version: "0.1".to_string(),
                prime_index: 17,
                description: None,
                authors: None,
            },
            governance: GovernanceMeta {
                spectral_radius: 0.2, // Within the 0.3 budget
                epsilon: None,
                contractivity_receipt: "hash2".to_string(),
                ledger_anchor: None,
            },
            dependencies: None,
        };

        governor.register(main);
        governor.register(dep);

        assert!(governor.link("main-app").is_ok());
    }

    #[test]
    fn test_linker_composition_failure() {
        let mut governor = SpectralGovernor::new();

        let mut deps = HashMap::new();
        deps.insert(
            "tensor-ops".to_string(),
            DependencyMeta {
                version: "0.1".to_string(),
                spectral_max: 0.6,
                prime_index: None,
            },
        );

        let main = EnsembleManifest {
            ensemble: EnsembleMeta {
                name: "main-app".to_string(),
                version: "1.0".to_string(),
                prime_index: 2,
                description: None,
                authors: None,
            },
            governance: GovernanceMeta {
                spectral_radius: 0.5,
                epsilon: None,
                contractivity_receipt: "hash1".to_string(),
                ledger_anchor: None,
            },
            dependencies: Some(deps),
        };

        let dep = EnsembleManifest {
            ensemble: EnsembleMeta {
                name: "tensor-ops".to_string(),
                version: "0.1".to_string(),
                prime_index: 17,
                description: None,
                authors: None,
            },
            governance: GovernanceMeta {
                spectral_radius: 0.5,
                epsilon: None,
                contractivity_receipt: "hash2".to_string(),
                ledger_anchor: None,
            },
            dependencies: None,
        };

        governor.register(main);
        governor.register(dep);

        // 0.5 + 0.6 = 1.1 >= 1.0 => Exceeds bound!
        let result = governor.link("main-app");
        assert!(matches!(
            result,
            Err(LinkerError::SpectralBudgetExceeded { .. })
        ));
    }
}
