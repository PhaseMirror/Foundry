use crate::manifest::EnsembleManifest;
use pirtm_engine::spectral::{self, Ensemble};
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
/// It constructs the topological interconnection matrix A and gains λ,
/// and computes ρ(|A|·diag(λ)) < 1.0 via the Spectral Small-Gain Runtime Gate.
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

    /// Link a root ensemble, verifying all dependencies and true matrix spectral radius.
    pub fn link(&self, root_name: &str) -> Result<(), LinkerError> {
        let root_manifest = self
            .registry
            .get(root_name)
            .ok_or_else(|| LinkerError::DependencyNotFound(root_name.to_string()))?;

        // 1. Gather all nodes in the transitive dependency graph
        let mut nodes = Vec::new();
        let mut node_indices = HashMap::new();
        self.collect_dependencies(root_manifest, &mut nodes, &mut node_indices)?;

        let n = nodes.len();
        if n == 0 {
            return Ok(());
        }

        // 2. Build adjacency matrix A and lambda gain vector
        let mut adjacency = vec![vec![0.0; n]; n];
        let mut lambdas = vec![0.0; n];

        for (i, manifest) in nodes.iter().enumerate() {
            lambdas[i] = manifest.governance.spectral_radius;

            if let Some(deps) = &manifest.dependencies {
                for (dep_name, dep_meta) in deps {
                    let dep_manifest = self
                        .registry
                        .get(dep_name)
                        .ok_or_else(|| LinkerError::DependencyNotFound(dep_name.to_string()))?;

                    // Prime compatibility check
                    if let Some(expected_prime) = dep_meta.prime_index {
                        if expected_prime != dep_manifest.ensemble.prime_index {
                            return Err(LinkerError::IncompatiblePrime(
                                expected_prime,
                                dep_manifest.ensemble.prime_index,
                            ));
                        }
                    }

                    if let Some(&j) = node_indices.get(dep_name) {
                        adjacency[i][j] = dep_meta.spectral_max;
                    }
                }
            }
        }

        // 3. Evaluate the true Small-Gain Spectral Radius Invariant: ρ(|A|·diag(λ)) < 1.0
        let ensemble = Ensemble::new(root_name, adjacency, lambdas);
        let rho = spectral::check_small_gain(&ensemble, 1e-6).map_err(|_| {
            LinkerError::SpectralBudgetExceeded {
                ensemble: root_name.to_string(),
                total: 1.0,
                limit: 1.0,
            }
        })?;

        if rho >= 1.0 {
            return Err(LinkerError::SpectralBudgetExceeded {
                ensemble: root_name.to_string(),
                total: rho,
                limit: 1.0,
            });
        }

        Ok(())
    }

    fn collect_dependencies<'a>(
        &'a self,
        manifest: &'a EnsembleManifest,
        nodes: &mut Vec<&'a EnsembleManifest>,
        node_indices: &mut HashMap<String, usize>,
    ) -> Result<(), LinkerError> {
        if node_indices.contains_key(&manifest.ensemble.name) {
            return Ok(());
        }

        let idx = nodes.len();
        node_indices.insert(manifest.ensemble.name.clone(), idx);
        nodes.push(manifest);

        if let Some(deps) = &manifest.dependencies {
            for (dep_name, _) in deps {
                let dep_manifest = self
                    .registry
                    .get(dep_name)
                    .ok_or_else(|| LinkerError::DependencyNotFound(dep_name.to_string()))?;
                self.collect_dependencies(dep_manifest, nodes, node_indices)?;
            }
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
                spectral_radius: 0.2,
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

        let mut deps_a = HashMap::new();
        deps_a.insert(
            "node_b".to_string(),
            DependencyMeta {
                version: "1.0".to_string(),
                spectral_max: 1.5,
                prime_index: None,
            },
        );

        let mut deps_b = HashMap::new();
        deps_b.insert(
            "node_a".to_string(),
            DependencyMeta {
                version: "1.0".to_string(),
                spectral_max: 1.5,
                prime_index: None,
            },
        );

        let node_a = EnsembleManifest {
            ensemble: EnsembleMeta {
                name: "node_a".to_string(),
                version: "1.0".to_string(),
                prime_index: 2,
                description: None,
                authors: None,
            },
            governance: GovernanceMeta {
                spectral_radius: 0.9,
                epsilon: None,
                contractivity_receipt: "hash_a".to_string(),
                ledger_anchor: None,
            },
            dependencies: Some(deps_a),
        };

        let node_b = EnsembleManifest {
            ensemble: EnsembleMeta {
                name: "node_b".to_string(),
                version: "1.0".to_string(),
                prime_index: 3,
                description: None,
                authors: None,
            },
            governance: GovernanceMeta {
                spectral_radius: 0.9,
                epsilon: None,
                contractivity_receipt: "hash_b".to_string(),
                ledger_anchor: None,
            },
            dependencies: Some(deps_b),
        };

        governor.register(node_a);
        governor.register(node_b);

        // Feedback loop with high coupling gains (1.5 * 0.9 * 1.5 * 0.9 = 1.8225 > 1)
        assert!(governor.link("node_a").is_err());
    }
}
