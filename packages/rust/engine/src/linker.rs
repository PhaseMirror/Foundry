use crate::spectral::spectral_decomposition;
use nalgebra::DMatrix;
use serde::{Deserialize, Serialize};
use blake3::Hasher;
use std::collections::HashMap;
use std::path::Path;
use std::fs;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleMetadata {
    pub name: String,
    pub prime_index: u64,
    pub epsilon: f64,
    pub op_norm_t: f64,
    pub identity_commitment: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PIRTMBytecode {
    pub metadata: ModuleMetadata,
    pub proof_hash: String,
    pub mlir_source: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleInput {
    pub alias: String,
    pub path: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionSpec {
    pub name: String,
    pub modules: Vec<ModuleInput>,
    pub coupling_matrix: Vec<Vec<f64>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CouplingConfig {
    pub version: String,
    pub sessions: Vec<SessionSpec>,
    pub cross_session_coupling: Option<Vec<Vec<f64>>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GovernanceSeal {
    pub ensemble_hash: String,
    pub global_spectral_radius: f64,
    pub is_contractive: bool,
    pub timestamp: f64,
    pub session_map: HashMap<String, u64>, // Maps alias to prime_index
}

pub struct PirtmLinkWithEnsemble {
    pub config: CouplingConfig,
    pub workspace_root: String,
    resolved_modules: HashMap<String, PIRTMBytecode>,
}

impl PirtmLinkWithEnsemble {
    pub fn new(config_path: &str, workspace_root: &str) -> Result<Self, String> {
        let content = fs::read_to_string(config_path)
            .map_err(|e| format!("Failed to read coupling.json: {}", e))?;
        let config: CouplingConfig = serde_json::from_str(&content)
            .map_err(|e| format!("Failed to parse coupling.json: {}", e))?;
        
        Ok(Self {
            config,
            workspace_root: workspace_root.to_string(),
            resolved_modules: HashMap::new(),
        })
    }

    /// Pass 1: Name Resolution
    /// Maps human-readable aliases from coupling.json to .pirtm.bc binaries.
    pub fn pass1_name_resolution(&mut self) -> Result<(), String> {
        for session in &self.config.sessions {
            for module_input in &session.modules {
                let full_path = Path::new(&self.workspace_root).join(&module_input.path);
                if !full_path.exists() {
                    return Err(format!("Pass 1: Bytecode not found for alias {}: {:?}", module_input.alias, full_path));
                }
                
                let content = fs::read_to_string(&full_path)
                    .map_err(|e| format!("Pass 1: Failed to read {}: {}", module_input.alias, e))?;
                
                let bytecode: PIRTMBytecode = serde_json::from_str(&content)
                    .map_err(|e| format!("Pass 1: Invalid bytecode format for {}: {}", module_input.alias, e))?;
                
                self.resolved_modules.insert(module_input.alias.clone(), bytecode);
            }
        }
        Ok(())
    }

    /// Pass 2: Commitment Crosscheck
    /// Scans all modules for duplicate identity_commitment hashes (L0.6).
    pub fn pass2_commitment_crosscheck(&self) -> Result<(), String> {
        let mut seen_commitments = HashMap::new();
        
        for (alias, bytecode) in &self.resolved_modules {
            let commitment = &bytecode.metadata.identity_commitment;
            if let Some(prev_alias) = seen_commitments.insert(commitment, alias) {
                return Err(format!(
                    "Pass 2 Violation (L0.6): Duplicate identity_commitment detected!\n  Alias '{}' and '{}' share commitment: {}",
                    prev_alias, alias, commitment
                ));
            }
        }
        Ok(())
    }

    /// Pass 3: Matrix Construction & Spectral Small-Gain
    /// Builds the global coupling matrix and runs the stability test.
    pub fn pass3_spectral_gate(&self) -> Result<GovernanceSeal, String> {
        let mut total_dim = 0;
        let mut session_map = HashMap::new();

        for session in &self.config.sessions {
            for module in &session.modules {
                if let Some(bytecode) = self.resolved_modules.get(&module.alias) {
                    session_map.insert(module.alias.clone(), bytecode.metadata.prime_index);
                    total_dim += 1;
                }
            }
        }

        if total_dim == 0 {
            return Err("Pass 3: No modules resolved for linking".to_string());
        }

        let mut psi = DMatrix::zeros(total_dim, total_dim);
        let mut offset = 0;

        for session in &self.config.sessions {
            let dim = session.modules.len();
            if session.coupling_matrix.len() != dim {
                return Err(format!("Pass 3: Session {}: coupling matrix size mismatch", session.name));
            }
            for (i, row) in session.coupling_matrix.iter().enumerate() {
                if row.len() != dim {
                    return Err(format!("Pass 3: Session {}: coupling row {} size mismatch", session.name, i));
                }
                for (j, &val) in row.iter().enumerate() {
                    psi[(offset + i, offset + j)] = val;
                }
            }
            offset += dim;
        }

        // Spectral Small-Gain Test: r(Psi) < 1.0
        let eigvals = spectral_decomposition(&psi);
        let spectral_radius = eigvals.iter().map(|c| c.norm()).fold(0.0, f64::max);

        let mut hasher = Hasher::new();
        hasher.update(serde_json::to_string(&self.config).unwrap().as_bytes());
        let ensemble_hash = hasher.finalize().to_hex().to_string();

        let is_contractive = spectral_radius < 1.0;

        Ok(GovernanceSeal {
            ensemble_hash,
            global_spectral_radius: spectral_radius,
            is_contractive,
            timestamp: SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_secs_f64(),
            session_map,
        })
    }

    pub fn link(&mut self) -> Result<GovernanceSeal, String> {
        self.pass1_name_resolution()?;
        self.pass2_commitment_crosscheck()?;
        self.pass3_spectral_gate()
    }
}
