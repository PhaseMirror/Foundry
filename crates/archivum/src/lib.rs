use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::fs::{OpenOptions, File};
use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ArchivumError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
    #[error("Validation error: {0}")]
    Validation(String),
    #[error("Duplicate witness: {state_hash}")]
    DuplicateWitness { state_hash: String },
    #[error("Chain integrity violation")]
    ChainViolation,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Witness {
    pub state_hash: String,
    pub event_type: String,
    pub timestamp: i64,
    pub commit_hash: Option<String>,
    pub previous_hash: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ArchivumLedger {
    pub witnesses: Vec<Witness>,
    pub root_hash: [u8; 32],
}

impl ArchivumLedger {
    pub fn new() -> Self {
        Self { witnesses: Vec::new(), root_hash: [0u8; 32] }
    }

    pub fn append(&mut self, w: Witness) -> Result<[u8; 32], ArchivumError> {
        if self.witnesses.iter().any(|x| x.state_hash == w.state_hash) {
            return Err(ArchivumError::DuplicateWitness { state_hash: w.state_hash });
        }
        self.witnesses.push(w);
        self.root_hash = self.compute_root_hash();
        Ok(self.root_hash)
    }

    pub fn verify_chain(&self) -> bool {
        self.root_hash == self.compute_root_hash()
    }

    pub fn root_hash(&self) -> [u8; 32] {
        self.root_hash
    }

    fn compute_root_hash(&self) -> [u8; 32] {
        let mut hasher = blake3::Hasher::new();
        for w in &self.witnesses {
            hasher.update(w.state_hash.as_bytes());
        }
        *hasher.finalize().as_bytes()
    }

    pub fn produce_tee_quote(&self) -> Result<String, ArchivumError> {
        let root = self.root_hash();
        // LambdaTraceAtom protocol: Bind the root hash to the TEE hardware register.
        // In a real SGX/TDX enclave, this would generate a signed hardware quote.
        // Here we simulate the non-repudiable quote generation.
        let quote = format!("TEE-QUOTE-LAMBDA-TRACE-{:?}", root);
        Ok(quote)
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_append_only_and_chain_integrity() {
        let mut ledger = ArchivumLedger::new();
        let w = Witness {
            state_hash: "test_hash".to_string(),
            event_type: "test_event".to_string(),
            timestamp: 0,
            commit_hash: None,
            previous_hash: None,
        };
        
        let res = ledger.append(w.clone());
        kani::assert(res.is_ok(), "Append failed on empty ledger");
        kani::assert(ledger.verify_chain(), "Chain invalid after append");
        
        let res2 = ledger.append(w);
        kani::assert(res2.is_err(), "Duplicate witness not rejected");
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConflictLogSchema {
    pub receipt_hash: String,
    pub r_sc: f64,
    pub l_eff: f64,
    pub tau_r: f64,
    pub breach_type: String,
    pub timestamp: String,
    pub pweh_hash: String,
}

impl ConflictLogSchema {
    pub fn new(transition_id: &str, r_sc: f64, l_eff: f64, tau_r: f64, breach_type: String) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
        
        let receipt_hash = format!("PWEH-TRAP-{}", timestamp);
        let pweh_hash = PwehHash::compute(transition_id, &receipt_hash);
        
        Self {
            receipt_hash,
            r_sc,
            l_eff,
            tau_r,
            breach_type,
            timestamp,
            pweh_hash,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransitionBlock {
    pub transition_id: String,
    pub ratified: bool,
}

impl TransitionBlock {
    pub fn new_ratified(transition_id: String) -> Self {
        Self {
            transition_id,
            ratified: true,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZmosSpectralProof {
    pub operator_id: String,
    pub spectral_radius: f64,
    pub lean_proof_hash: String,
    pub rust_binary_hash: String,
    pub tee_quote: String,
    pub timestamp: String,
}

impl ZmosSpectralProof {
    pub fn new(operator_id: String, spectral_radius: f64, lean_proof_hash: String, rust_binary_hash: String, tee_quote: String) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            operator_id,
            spectral_radius,
            lean_proof_hash,
            rust_binary_hash,
            tee_quote,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SigmaProof {
    pub state_hash: String,
    pub invariant_holds: bool,
    pub dissonance_level: String,
    pub timestamp: String,
}

impl SigmaProof {
    pub fn new(state_hash: String, invariant_holds: bool, dissonance_level: String) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            state_hash,
            invariant_holds,
            dissonance_level,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct StratumProof {
    pub transition_signature: String,
    pub from_stratum: u8,
    pub to_stratum: u8,
    pub timestamp: String,
}

impl StratumProof {
    pub fn new(transition_signature: String, from_stratum: u8, to_stratum: u8) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            transition_signature,
            from_stratum,
            to_stratum,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct MatrixEngineProof {
    pub kernel_name: String,
    pub contraction_param: f64,
    pub grade: i64,
    pub timestamp: String,
}

impl MatrixEngineProof {
    pub fn new(kernel_name: String, contraction_param: f64, grade: i64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            kernel_name,
            contraction_param,
            grade,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ACEProof {
    pub witness_count: usize,
    pub final_cycles: u64,
    pub timestamp: String,
}

impl ACEProof {
    pub fn new(witness_count: usize, final_cycles: u64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            witness_count,
            final_cycles,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct PirtmCompileProof {
    pub ast_hash: String,
    pub type_signature: String,
    pub timestamp: String,
}

impl PirtmCompileProof {
    pub fn new(ast_hash: String, type_signature: String) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            ast_hash,
            type_signature,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct XiCompileProof {
    pub target_arch: String,
    pub optimized_blob: String,
    pub timestamp: String,
}

impl XiCompileProof {
    pub fn new(target_arch: String, optimized_blob: String) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            target_arch,
            optimized_blob,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct AutomorphicTrainingProof {
    pub energy_bound: f64,
    pub step_count: u64,
    pub timestamp: String,
}

impl AutomorphicTrainingProof {
    pub fn new(energy_bound: f64, step_count: u64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            energy_bound,
            step_count,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct MQNNExecutionProof {
    pub qudit_output_hash: String,
    pub classical_output_hash: String,
    pub fidelity: f64,
    pub timestamp: String,
}

impl MQNNExecutionProof {
    pub fn new(qudit_output_hash: String, classical_output_hash: String, fidelity: f64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            qudit_output_hash,
            classical_output_hash,
            fidelity,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct EchoBraidProof {
    pub sender: String,
    pub receiver: String,
    pub payload_hash: String,
    pub timestamp: String,
}

impl EchoBraidProof {
    pub fn new(sender: String, receiver: String, payload_hash: String) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            sender,
            receiver,
            payload_hash,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ALPCheckProof {
    pub policy_name: String,
    pub rta_metric: f64,
    pub timestamp: String,
}

impl ALPCheckProof {
    pub fn new(policy_name: String, rta_metric: f64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            policy_name,
            rta_metric,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ORFCoherenceProof {
    pub lambda_hat_descent: f64,
    pub in_coherence_manifold: bool,
    pub timestamp: String,
}

impl ORFCoherenceProof {
    pub fn new(lambda_hat_descent: f64, in_coherence_manifold: bool) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            lambda_hat_descent,
            in_coherence_manifold,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct MocOperationProof {
    pub operation_type: String, // "commute", "braid", "resonance"
    pub result_summary: String,
    pub timestamp: String,
}

impl MocOperationProof {
    pub fn new(operation_type: String, result_summary: String) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            operation_type,
            result_summary,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct FockContractionProof {
    pub operator_norm: f64,
    pub lipschitz_constant: f64,
    pub timestamp: String,
}

impl FockContractionProof {
    pub fn new(operator_norm: f64, lipschitz_constant: f64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            operator_norm,
            lipschitz_constant,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SovereignStackProof {
    pub proof_digest: [u8; 32],
    pub margin: f64,
    pub timestamp: String,
}

impl SovereignStackProof {
    pub fn new(proof_digest: [u8; 32], margin: f64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            proof_digest,
            margin,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct NoiseSuppressionProof {
    pub max_depth: usize,
    pub final_amplitude: f64,
    pub timestamp: String,
}

impl NoiseSuppressionProof {
    pub fn new(max_depth: usize, final_amplitude: f64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            max_depth,
            final_amplitude,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct QuantumAlgorithmProof {
    pub algorithm: String,
    pub norm: f64,
    pub timestamp: String,
}

impl QuantumAlgorithmProof {
    pub fn new(algorithm: String, norm: f64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            algorithm,
            norm,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct IKEExecutionProof {
    pub query_hash: [u8; 32],
    pub result_count: usize,
    pub timestamp: String,
}

impl IKEExecutionProof {
    pub fn new(query_hash: [u8; 32], result_count: usize) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            query_hash,
            result_count,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct PTQEKeyProof {
    pub prime_count: usize,
    pub entropy_bits: u64,
    pub timestamp: String,
}

impl PTQEKeyProof {
    pub fn new(prime_count: usize, entropy_bits: u64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            prime_count,
            entropy_bits,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct CVFeedbackProof {
    pub original_norm: f64,
    pub final_norm: f64,
    pub iterations: usize,
    pub timestamp: String,
}

impl CVFeedbackProof {
    pub fn new(original_norm: f64, final_norm: f64, iterations: usize) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            original_norm,
            final_norm,
            iterations,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct POTUSimulationProof {
    pub tensor_hash: [u8; 32],
    pub lambda_m_norm: f64,
    pub timestamp: String,
}

impl POTUSimulationProof {
    pub fn new(tensor_hash: [u8; 32], lambda_m_norm: f64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            tensor_hash,
            lambda_m_norm,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ZmodTensorProof {
    pub grads_hash: [u8; 32],
    pub prime: u64,
    pub tensor_value: u64,
    pub timestamp: String,
}

impl ZmodTensorProof {
    pub fn new(grads_hash: [u8; 32], prime: u64, tensor_value: u64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            grads_hash,
            prime,
            tensor_value,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct GoldilocksOpProof {
    pub op_type: String,
    pub operand_hash: [u8; 32],
    pub result: u64,
    pub timestamp: String,
}

impl GoldilocksOpProof {
    pub fn new(op_type: String, operand_hash: [u8; 32], result: u64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            op_type,
            operand_hash,
            result,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct UORTypeProof {
    pub type_name: String,
    pub type_hash: [u8; 32],
    pub timestamp: String,
}

impl UORTypeProof {
    pub fn new(type_name: String, type_hash: [u8; 32]) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            type_name,
            type_hash,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ParmSealProof {
    pub input_hash: [u8; 32],
    pub sealed_value: u64,
    pub timestamp: String,
}

impl ParmSealProof {
    pub fn new(input_hash: [u8; 32], sealed_value: u64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            input_hash,
            sealed_value,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct PrmsTelemetryProof {
    pub telemetry_hash: [u8; 32],
    pub cond_number: u64,
    pub timestamp: String,
}

impl PrmsTelemetryProof {
    pub fn new(telemetry_hash: [u8; 32], cond_number: u64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            telemetry_hash,
            cond_number,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct MocSchemaProof {
    pub schema_hash: [u8; 32],
    pub seq: u64,
    pub timestamp: String,
}

impl MocSchemaProof {
    pub fn new(schema_hash: [u8; 32], seq: u64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            schema_hash,
            seq,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct XiFormalProof {
    pub function_hash: [u8; 32],
    pub kappa: u64,
    pub is_contraction: bool,
    pub timestamp: String,
}

impl XiFormalProof {
    pub fn new(function_hash: [u8; 32], kappa: u64, is_contraction: bool) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            function_hash,
            kappa,
            is_contraction,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct RocDynamicsProof {
    pub state_hash: [u8; 32],
    pub v_before: u64,
    pub v_after: u64,
    pub timestamp: String,
}

impl RocDynamicsProof {
    pub fn new(state_hash: [u8; 32], v_before: u64, v_after: u64) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            state_hash,
            v_before,
            v_after,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct MocCertificateProof {
    pub operator_name: String,
    pub prime_gate: u64,
    pub lambda_p: f64,
    pub proof_hash: String,
    pub timestamp: String,
}

impl MocCertificateProof {
    pub fn new(operator_name: String, prime_gate: u64, lambda_p: f64, proof_hash: String) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            operator_name,
            prime_gate,
            lambda_p,
            proof_hash,
            timestamp,
        }
    }
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ApoProof {
    pub apo_root_hash: String,
    pub proof_count: usize,
    pub timestamp: String,
}

impl ApoProof {
    pub fn new(apo_root_hash: String, proof_count: usize) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
            
        Self {
            apo_root_hash,
            proof_count,
            timestamp,
        }
    }
}

#[derive(Debug, Clone)]
pub struct PwehHash(String);

impl PwehHash {
    pub fn compute(transition_id: &str, receipt_hash: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(transition_id.as_bytes());
        hasher.update(receipt_hash.as_bytes());
        format!("{:x}", hasher.finalize())
    }
}

pub struct WitnessLedger {
    path: PathBuf,
}

impl WitnessLedger {
    pub fn new<P: AsRef<Path>>(path: P) -> Self {
        Self { path: path.as_ref().to_path_buf() }
    }

    pub fn stamp_pweh(&self, log: &ConflictLogSchema) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(log)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_zmos_proof(&self, proof: &ZmosSpectralProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_sigma_proof(&self, proof: &SigmaProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_stratum_proof(&self, proof: &StratumProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_matrix_engine_proof(&self, proof: &MatrixEngineProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_ace_proof(&self, proof: &ACEProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_pirtm_compile_proof(&self, proof: &PirtmCompileProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_apo_proof(&self, proof: &ApoProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_xi_compile_proof(&self, proof: &XiCompileProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_automorphic_training_proof(&self, proof: &AutomorphicTrainingProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_mqnn_execution_proof(&self, proof: &MQNNExecutionProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_echo_braid_proof(&self, proof: &EchoBraidProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_alp_check_proof(&self, proof: &ALPCheckProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_orf_coherence_proof(&self, proof: &ORFCoherenceProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_moc_operation_proof(&self, proof: &MocOperationProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_fock_contraction_proof(&self, proof: &FockContractionProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_sovereign_stack_proof(&self, proof: &SovereignStackProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_noise_suppression_proof(&self, proof: &NoiseSuppressionProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_quantum_algorithm_proof(&self, proof: &QuantumAlgorithmProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_ike_execution_proof(&self, proof: &IKEExecutionProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_ptqe_key_proof(&self, proof: &PTQEKeyProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_cv_feedback_proof(&self, proof: &CVFeedbackProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_potu_simulation_proof(&self, proof: &POTUSimulationProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_zmod_tensor_proof(&self, proof: &ZmodTensorProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_goldilocks_op_proof(&self, proof: &GoldilocksOpProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_uor_type_proof(&self, proof: &UORTypeProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_parm_seal_proof(&self, proof: &ParmSealProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_prms_telemetry_proof(&self, proof: &PrmsTelemetryProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_moc_schema_proof(&self, proof: &MocSchemaProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_xi_formal_proof(&self, proof: &XiFormalProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_roc_dynamics_proof(&self, proof: &RocDynamicsProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn stamp_moc_certificate_proof(&self, proof: &MocCertificateProof) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(proof)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn append_block(&self, block: &TransitionBlock) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(block)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn has_conflict_log(&self) -> bool {
        if let Ok(file) = File::open(&self.path) {
            let reader = BufReader::new(file);
            reader.lines().any(|line| {
                if let Ok(l) = line {
                    if let Ok(obj) = serde_json::from_str::<serde_json::Value>(&l) {
                        return obj.get("breach_type").is_some() && obj.get("pweh_hash").is_some();
                    }
                }
                false
            })
        } else {
            false
        }
    }

    pub fn contains_pweh_for(&self, block: &TransitionBlock) -> bool {
        if let Ok(file) = File::open(&self.path) {
            let reader = BufReader::new(file);
            reader.lines().any(|line| {
                if let Ok(l) = line {
                    if let Ok(obj) = serde_json::from_str::<serde_json::Value>(&l) {
                        return obj.get("transition_id")
                            .and_then(|v| v.as_str())
                            .map(|s| s == block.transition_id)
                            .unwrap_or(false);
                    }
                }
                false
            })
        } else {
            false
        }
    }

    fn ensure_dir(&self) -> Result<(), ArchivumError> {
        if let Some(parent) = self.path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        Ok(())
    }
}
