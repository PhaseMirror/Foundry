use serde::{Deserialize, Serialize};
use std::path::Path;
use sha2::{Sha256, Digest};
use std::fmt::Write;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProofHashParams {
    pub prime_index: u64,
    pub epsilon: f64,
    pub op_norm_t: f64,
    pub nonce: String,
}

impl ProofHashParams {
    pub fn compute(&self) -> String {
        let params = format!("{}|{}|{}|{}", self.prime_index, self.epsilon, self.op_norm_t, self.nonce);
        let mut hasher = Sha256::new();
        hasher.update(params.as_bytes());
        let digest = hasher.finalize();
        let mut s = String::new();
        for byte in digest {
            write!(&mut s, "{:02x}", byte).unwrap();
        }
        s
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModuleMetadata {
    pub name: String,
    pub prime_index: u64,
    pub epsilon: f64,
    pub op_norm_t: f64,
    pub contractivity_check: String,
    pub proof_hash: String,
    pub timestamp: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PirtmBytecodeContent {
    pub modules: Vec<ModuleMetadata>,
    pub coupling: String,
    pub mlir_source: String,
    pub audit_trail: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PirtmBytecode {
    pub format: String,
    pub version: String,
    pub timestamp: String,
    pub content: PirtmBytecodeContent,
}

impl PirtmBytecode {
    pub fn new(content: PirtmBytecodeContent) -> Self {
        PirtmBytecode {
            format: "pirtm.bc".to_string(),
            version: "1.0".to_string(),
            timestamp: chrono::Utc::now().to_rfc3339(),
            content,
        }
    }

    pub fn save_to_file<P: AsRef<Path>>(&self, path: P) -> Result<(), Box<dyn std::error::Error>> {
        let json = serde_json::to_string_pretty(self)?;
        std::fs::write(path, json)?;
        Ok(())
    }

    pub fn load_from_file<P: AsRef<Path>>(path: P) -> Result<Self, Box<dyn std::error::Error>> {
        let json = std::fs::read_to_string(path)?;
        let bytecode: PirtmBytecode = serde_json::from_str(&json)?;
        Ok(bytecode)
    }
}
