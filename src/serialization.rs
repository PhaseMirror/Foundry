use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::io::{Read, Write, Seek, SeekFrom};
use std::fs::File;

pub const PIRTM_MAGIC: &[u8; 4] = b"\x7FPIR";
pub const PIRTM_VERSION: u8 = 1;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PIRTMProofSection {
    pub prime_index: u64,
    pub epsilon: f64,
    pub op_norm_t: f64,
    pub contractivity_check: String, // "PASS" or "FAIL"
    pub proof_hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PIRTMGovernanceSection {
    pub ensemble_hash: String,
    pub global_spectral_radius: f64,
    pub is_contractive: bool,
    pub timestamp: f64,
    // Maps aliases to prime indices for audit purposes, 
    // but not part of the execution IR.
    pub session_map: HashMap<String, u64>, 
}

pub struct PIRTMRuntime {
    pub proof: PIRTMProofSection,
    pub governance: PIRTMGovernanceSection,
    pub code: Vec<u8>,
}

impl PIRTMRuntime {
    pub fn save(&self, path: &str) -> Result<(), String> {
        let mut file = File::create(path).map_err(|e| e.to_string())?;
        
        // 1. Write Header
        file.write_all(PIRTM_MAGIC).map_err(|e| e.to_string())?;
        file.write_all(&[PIRTM_VERSION]).map_err(|e| e.to_string())?;
        
        let proof_json = serde_json::to_vec(&self.proof).unwrap();
        let gov_json = serde_json::to_vec(&self.governance).unwrap();
        
        // Section count
        file.write_all(&[3u8]).map_err(|e| e.to_string())?;
        
        // 2. Write Section Headers (Fixed width: Tag[4], Offset[8], Size[8])
        let mut offset = 5 + 1 + (3 * 20); // Header + Section Count + 3 Headers
        
        // Align offset to 16 bytes
        offset = (offset + 15) & !15;
        
        // Proof Section Header
        file.write_all(b"PROF").unwrap();
        file.write_all(&(offset as u64).to_le_bytes()).unwrap();
        file.write_all(&(proof_json.len() as u64).to_le_bytes()).unwrap();
        let next_offset = (offset + proof_json.len() + 15) & !15;
        
        // Governance Section Header
        let gov_offset = next_offset;
        file.write_all(b"GOVN").unwrap();
        file.write_all(&(gov_offset as u64).to_le_bytes()).unwrap();
        file.write_all(&(gov_json.len() as u64).to_le_bytes()).unwrap();
        let code_offset = (gov_offset + gov_json.len() + 15) & !15;
        
        // Code Section Header
        file.write_all(b"CODE").unwrap();
        file.write_all(&(code_offset as u64).to_le_bytes()).unwrap();
        file.write_all(&(self.code.len() as u64).to_le_bytes()).unwrap();
        
        // 3. Write Section Data with Padding
        file.seek(SeekFrom::Start(offset as u64)).unwrap();
        file.write_all(&proof_json).unwrap();
        
        file.seek(SeekFrom::Start(gov_offset as u64)).unwrap();
        file.write_all(&gov_json).unwrap();
        
        file.seek(SeekFrom::Start(code_offset as u64)).unwrap();
        file.write_all(&self.code).unwrap();
        
        Ok(())
    }

    pub fn load(path: &str) -> Result<Self, String> {
        let mut file = File::open(path).map_err(|e| e.to_string())?;
        let mut magic = [0u8; 4];
        file.read_exact(&mut magic).unwrap();
        if &magic != PIRTM_MAGIC {
            return Err("Invalid magic".to_string());
        }
        
        let mut version = [0u8; 1];
        file.read_exact(&mut version).unwrap();
        
        let mut section_count = [0u8; 1];
        file.read_exact(&mut section_count).unwrap();
        
        let mut proof = None;
        let mut governance = None;
        let mut code = None;
        
        for _ in 0..section_count[0] {
            let mut tag = [0u8; 4];
            file.read_exact(&mut tag).unwrap();
            
            let mut offset_bytes = [0u8; 8];
            file.read_exact(&mut offset_bytes).unwrap();
            let offset = u64::from_le_bytes(offset_bytes);
            
            let mut size_bytes = [0u8; 8];
            file.read_exact(&mut size_bytes).unwrap();
            let size = u64::from_le_bytes(size_bytes);
            
            let current_pos = file.stream_position().unwrap();
            
            file.seek(SeekFrom::Start(offset)).unwrap();
            let mut data = vec![0u8; size as usize];
            file.read_exact(&mut data).unwrap();
            
            match &tag {
                b"PROF" => {
                    proof = Some(serde_json::from_slice(&data).map_err(|e| e.to_string())?);
                },
                b"GOVN" => {
                    governance = Some(serde_json::from_slice(&data).map_err(|e| e.to_string())?);
                },
                b"CODE" => {
                    code = Some(data);
                },
                _ => {}
            }
            
            file.seek(SeekFrom::Start(current_pos)).unwrap();
        }
        
        Ok(Self {
            proof: proof.ok_or("Missing PROF section")?,
            governance: governance.ok_or("Missing GOVN section")?,
            code: code.ok_or("Missing CODE section")?,
        })
    }

    pub fn inspect(&self) -> String {
        let mut out = String::new();
        out.push_str("=== PIRTM SEAL INSPECTION ===\n");
        out.push_str(&format!("Module: p={}\n", self.proof.prime_index));
        out.push_str(&format!("Stability: ε={:.4}, op_norm_T={:.4}\n", self.proof.epsilon, self.proof.op_norm_t));
        out.push_str(&format!("Contractivity Check: {}\n", self.proof.contractivity_check));
        out.push_str(&format!("Proof Hash: {}\n", self.proof.proof_hash));
        out.push_str("\n--- Governance Seal ---\n");
        out.push_str(&format!("Ensemble Hash: {}\n", self.governance.ensemble_hash));
        out.push_str(&format!("Global ρ: {:.4}\n", self.governance.global_spectral_radius));
        out.push_str(&format!("Is Contractive: {}\n", self.governance.is_contractive));
        out.push_str(&format!("Session Map: {:?}\n", self.governance.session_map));
        out.push_str("\nAudit Chain: NOT EMBEDDED — retrieve via pirtm audit <trace.log>\n");
        out
    }
}

pub fn compute_proof_hash(prime_index: u64, epsilon: f64, op_norm_t: f64) -> String {
    use sha2::{Sha256, Digest};
    let nonce = "PIRTM-DAY14";
    let params = format!("{}|{}|{}|{}", prime_index, epsilon, op_norm_t, nonce);
    let mut hasher = Sha256::new();
    hasher.update(params.as_bytes());
    hex::encode(hasher.finalize())
}
