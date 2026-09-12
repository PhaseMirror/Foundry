mod audit;
mod ablation;

use anyhow::{Result, bail, Context};
use ndarray::Array2;
use sha2::{Sha256, Digest};
use std::fs;
use std::path::{Path};
use serde::{Serialize, Deserialize};

/// Constants defined by Constitutional Core v1.0
const CONTRACTION_THRESHOLD: f64 = 1.0 - 1e-6;
const LAWFUL_RECURSION_HASH_VERSION: &str = "v1.0";

#[derive(Serialize, Deserialize, Debug)]
pub struct Anchor {
    pub file_path: String,
    pub hash: String,
    pub tag: String,
    pub timestamp: String,
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Manifest {
    pub version: String,
    pub anchors: Vec<Anchor>,
}

pub struct ContractionValidator {
    pub operator: Array2<f64>,
}

impl ContractionValidator {
    pub fn new(operator: Array2<f64>) -> Result<Self> {
        if !operator.is_square() {
            bail!("Recursion operator must be a square matrix.");
        }
        Ok(Self { operator })
    }

    pub fn verify_contraction(&self) -> Result<f64> {
        let mut max_row_sum: f64 = 0.0;
        for row in self.operator.rows() {
            let row_sum: f64 = row.iter().map(|&x| x.abs()).sum();
            if row_sum > max_row_sum {
                max_row_sum = row_sum;
            }
        }
        
        let witness = max_row_sum;
        
        if witness >= CONTRACTION_THRESHOLD {
            bail!(
                "Contraction failure: Max(λ_p L_p) witness = {:.10} >= threshold {:.10}",
                witness,
                CONTRACTION_THRESHOLD
            );
        }
        
        Ok(witness)
    }

    pub fn generate_anchor(&self, witness: f64) -> String {
        let mut hasher = Sha256::new();
        hasher.update(LAWFUL_RECURSION_HASH_VERSION.as_bytes());
        hasher.update(format!("{:.10}", witness).as_bytes());
        for &val in self.operator.iter() {
            hasher.update(val.to_be_bytes());
        }
        let result = hasher.finalize();
        format!("{:x}", result)
    }
}

fn anchor_file(path: &Path, tag: &str) -> Result<Anchor> {
    let content = fs::read(path).with_context(|| format!("Failed to read {:?}", path))?;
    let mut hasher = Sha256::new();
    hasher.update(content);
    let hash = format!("{:x}", hasher.finalize());
    
    Ok(Anchor {
        file_path: path.to_string_lossy().into_owned(),
        hash,
        tag: tag.to_string(),
        timestamp: chrono::Utc::now().to_rfc3339(),
    })
}

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    
    if args.len() > 1 && args[1] == "anchor" {
        println!("[FINTON] Anchoring Financial Artifacts to LawfulRecursionHash...");
        // ... (rest of anchoring logic)
        
        let artifacts = vec![
            "/home/multiplicity/Multiplicity/crates/umc-parom/Prime-Addressed Recursive Operator Modules.tex",
            "/home/multiplicity/Multiplicity/Governance/Documentation/docs/publications/Prime_Indexed_Recursive_Governance.pdf",
            "/home/multiplicity/Multiplicity/Governance/Documentation/docs/publications/The_Fundamental_Theorem_of_Arithmetic_as_Constitutional_Operator.pdf",
            "/home/multiplicity/Multiplicity/Governance/Documentation/docs/publications/Prime_Indexed_Recursive_Stabilization_of_Tensor_Networks.pdf",
            "/home/multiplicity/Multiplicity/Governance/Documentation/docs/publications/Contractive_Recursive_Operator_Framework.pdf"
        ];
        
        let manifest_path = Path::new("/home/multiplicity/Multiplicity/Phase Mirror/phasemirror-agent/harness/anchors/MANIFEST.json");
        let mut new_anchors = Vec::new();
        
        for art in artifacts {
            let path = Path::new(art);
            if path.exists() {
                let anchor = anchor_file(path, "v1.0")?;
                println!("[ANCHORED] {} -> {}", art, anchor.hash);
                new_anchors.push(anchor);
            } else {
                println!("[WARNING] Artifact not found: {}", art);
            }
        }
        
        let mut manifest: Manifest = if manifest_path.exists() {
            let content = fs::read_to_string(manifest_path)?;
            serde_json::from_str(&content)?
        } else {
            Manifest {
                version: "v1.0".to_string(),
                anchors: Vec::new(),
            }
        };

        for new_anchor in new_anchors {
            if let Some(existing) = manifest.anchors.iter_mut().find(|a| a.file_path == new_anchor.file_path) {
                *existing = new_anchor;
            } else {
                manifest.anchors.push(new_anchor);
            }
        }

        let updated_content = serde_json::to_string_pretty(&manifest)?;
        fs::write(manifest_path, updated_content)?;
        println!("[SUCCESS] Manifest updated at {:?}", manifest_path);
        
    } else if args.len() > 1 && args[1] == "audit" {
        let manifest_path = Path::new("/home/multiplicity/Multiplicity/Phase Mirror/phasemirror-agent/harness/anchors/MANIFEST.json");
        audit::run_md005_audit(manifest_path)?;
    } else if args.len() > 1 && args[1] == "ablation" {
        ablation::run_prime_grid_ablation()?;
    } else {
        println!("[FINTON] Initializing Financial Transaction Stability Audit...");

        // In Finton, the operator represents a transaction sequence or liquidity flow
        let size = 108;
        let mut operator = Array2::<f64>::eye(size);
        let scale = 0.6; // Aligning with LEAN_ACE_BOUND for conservative financial stability
        operator *= scale;

        let validator = ContractionValidator::new(operator)?;
        
        match validator.verify_contraction() {
            Ok(witness) => {
                let anchor = validator.generate_anchor(witness);
                println!("[SUCCESS] Financial Stability Verified: λ_p L_p = {:.10}", witness);
                println!("[ANCHOR] TransactionHash: {}", anchor);
                println!("[TAG] Version: {}", LAWFUL_RECURSION_HASH_VERSION);
            }
            Err(e) => {
                println!("[FAILURE] Financial Dissonance Detected: {}", e);
                std::process::exit(1);
            }
        }
    }

    Ok(())
}
