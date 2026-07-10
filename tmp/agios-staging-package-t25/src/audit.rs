use serde::{Serialize, Deserialize};
use std::fs::{OpenOptions, create_dir_all};
use std::io::Write;
use std::path::Path;
use sha2::{Sha256, Digest};
use crate::crypto::{FieldElement, CIRCUIT_WIDTH};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LambdaTraceAtom {
    pub proof_digest: String,      // Hex-encoded SNARK proof digest
    pub state_root_hash: String,   // Hex-encoded state root hash
    pub timestamp: u64,            // Transaction intent timestamp (Unix epoch ms)
    pub q: f64,                    // Contraction witness
}

pub struct LedgerEmitter;

impl LedgerEmitter {
    /// Appends the lightweight LambdaTraceAtom proof payload to the append-only Archivum ledger.
    pub fn emit(atom: &LambdaTraceAtom) -> Result<(), Box<dyn std::error::Error>> {
        // Target log directory: ./logs
        let log_dir = Path::new("./logs");
        if !log_dir.exists() {
            create_dir_all(log_dir)?;
        }

        let log_path = log_dir.join("receipts.jsonl");
        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(log_path)?;

        let serialized = serde_json::to_string(atom)?;
        writeln!(file, "{}", serialized)?;
        
        println!("[INFO] [Archivum] LambdaTraceAtom dispatched to ledger successfully.");
        println!("[DEBUG] Proof Digest: {}", atom.proof_digest);
        println!("[DEBUG] State Root:   {}", atom.state_root_hash);
        Ok(())
    }
}

/// Compute SHA-256 hash of a serialized quantized field element matrix.
pub fn compute_quantized_hash(matrix: &[FieldElement; CIRCUIT_WIDTH]) -> String {
    let bytes = compute_quantized_bytes(matrix);
    let mut s = String::with_capacity(64);
    for byte in bytes {
        s.push_str(&format!("{:02x}", byte));
    }
    s
}

/// Compute SHA-256 raw bytes of a serialized quantized field element matrix.
pub fn compute_quantized_bytes(matrix: &[FieldElement; CIRCUIT_WIDTH]) -> [u8; 32] {
    let mut hasher = Sha256::new();
    for element in matrix {
        hasher.update(&element.0.to_be_bytes());
    }
    hasher.finalize().into()
}

/// Compute SHA-256 hash of generic byte data.
pub fn compute_bytes_hash(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    format!("{:x}", hasher.finalize())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs::{self, File};
    use std::io::BufRead;

    #[test]
    fn test_compute_hashes() {
        let matrix = [FieldElement(42); CIRCUIT_WIDTH];
        let state_hash = compute_quantized_hash(&matrix);
        assert!(!state_hash.is_empty());
        assert_eq!(state_hash.len(), 64); // SHA-256 hex length

        let data_hash = compute_bytes_hash(b"test_payload");
        assert!(!data_hash.is_empty());
        assert_eq!(data_hash.len(), 64);
    }

    #[test]
    fn test_ledger_emission() {
        // Prepare a unique dummy atom
        let proof = "test_proof_digest_123".to_string();
        let state = "test_state_root_hash_456".to_string();
        let ts = 1718000000000;
        let q_val = 0.95;
        
        let atom = LambdaTraceAtom {
            proof_digest: proof.clone(),
            state_root_hash: state.clone(),
            timestamp: ts,
            q: q_val,
        };

        // Backup existing log file if it exists to avoid side effects
        let log_path = Path::new("./logs/receipts.jsonl");
        let backup_path = Path::new("./logs/receipts.jsonl.bak");
        let existed = log_path.exists();
        if existed {
            fs::rename(log_path, backup_path).unwrap();
        }

        // Emit our test atom
        LedgerEmitter::emit(&atom).expect("Emission failed");

        // Verify the file was created and contains our atom
        assert!(log_path.exists());
        let file = File::open(log_path).expect("Could not open emitted ledger file");
        let reader = std::io::BufReader::new(file);
        let mut lines = reader.lines();
        let first_line = lines.next().expect("No line in file").expect("Failed to read line");

        let read_atom: LambdaTraceAtom = serde_json::from_str(&first_line).expect("Failed to parse JSON");
        assert_eq!(read_atom.proof_digest, proof);
        assert_eq!(read_atom.state_root_hash, state);
        assert_eq!(read_atom.timestamp, ts);
        assert_eq!(read_atom.q, q_val);

        // Clean up test file and restore backup if it existed
        fs::remove_file(log_path).unwrap();
        if existed {
            fs::rename(backup_path, log_path).unwrap();
        }
    }
}

