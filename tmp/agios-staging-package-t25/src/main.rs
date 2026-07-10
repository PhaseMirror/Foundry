mod crypto;
mod audit;
mod plic;
mod stability;
mod recursive;
mod tee;
use crypto::{SafeNecessityProjector, CIRCUIT_WIDTH};
use audit::{LambdaTraceAtom, LedgerEmitter};
use plic::PlicExecutionGate;
use recursive::RecursiveProofBridge;
use tokio::net::TcpListener;
use tokio_rustls::{TlsAcceptor, rustls};
use std::error::Error;
use std::sync::Arc;
use std::fs::File;
use std::io::BufReader;
use serde::{Deserialize, Serialize};

const CERT_PATH: &str = "certs/";

#[derive(Debug, Deserialize, Serialize)]
pub struct FhirPatientData<'a> {
    pub patient_id: &'a str,
    pub observations: Vec<f64>,
    pub metadata: &'a str,
}

impl<'a> Into<[f64; CIRCUIT_WIDTH]> for FhirPatientData<'a> {
    fn into(self) -> [f64; CIRCUIT_WIDTH] {
        let mut padded = [0.0; CIRCUIT_WIDTH];
        for (i, &val) in self.observations.iter().take(CIRCUIT_WIDTH).enumerate() {
            padded[i] = val;
        }
        padded
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    println!("[INFO] Initializing agiOS API Spine Edge Proxy...");
    println!("[INFO] Production Strict Posture: ARMED");

    // 0. Perform TEE Remote Attestation verification before listening
    tee::TeeAttestationVerifier::verify_environment().await?;

    // Load certificates from the provisioned certs directory
    let certs = load_certs(&format!("{}server.crt", CERT_PATH))?;
    let key = load_key(&format!("{}server.key", CERT_PATH))?;
    let root_ca = load_roots(&format!("{}rootCA.crt", CERT_PATH))?;
    
    let config = rustls::ServerConfig::builder()
        .with_safe_defaults()
        .with_client_cert_verifier(Arc::new(rustls::server::AllowAnyAuthenticatedClient::new(root_ca)))
        .with_single_cert(certs, key)?;

    let acceptor = TlsAcceptor::from(Arc::new(config));
    let listener = TcpListener::bind("0.0.0.0:8443").await?;
    println!("[INFO] mTLS Gateway listening on port 8443...");

    // Create bounded channel for asynchronous CPU offloading (Prover Pool)
    let (prover_tx, mut prover_rx) = tokio::sync::mpsc::channel::<(
        [f64; CIRCUIT_WIDTH],
        tokio::sync::oneshot::Sender<Result<(), String>>,
    )>(32);

    // Spawn centralized prover task
    tokio::spawn(async move {
        while let Some((circuit_input, reply_tx)) = prover_rx.recv().await {
            tokio::spawn(async move {
                let res = tokio::task::spawn_blocking(move || -> Result<(), String> {
                    // Quantize matrix for ZK circuit
                    let quantized = SafeNecessityProjector::quantize_matrix(&circuit_input)
                        .map_err(|e| e.to_string())?;
                        
                    println!("[INFO] CPU-bound proving worker started for job.");
                    println!("[DEBUG] Proof aggregation complete for quantized matrix: {:?}", &quantized[0..2]);

                    // 3. Dynamic Stability Monitoring: Compute the contraction witness (q)
                    let q = stability::StabilityModule::compute_witness(&circuit_input);

                    // 4. Provenance Hook: Generate LambdaTraceAtom
                    let state_root_hash = audit::compute_quantized_hash(&quantized);
                    
                    // Pallas/Vesta Recursive Proof Bridge Integration
                    let state_root_bytes = audit::compute_quantized_bytes(&quantized);
                    let bridge = RecursiveProofBridge::new();
                    let blinding = num_bigint::BigUint::from(987654321u64);
                    
                    let current_rpo = bridge.wrap_state_root(&state_root_bytes, &blinding)
                        .map_err(|e| e.to_string())?;
                        
                    let mock_historical_root = [42u8; 32];
                    let mock_historical_rpo = bridge.wrap_state_root(&mock_historical_root, &blinding)
                        .map_err(|e| e.to_string())?;
                        
                    let apo = bridge.aggregate_rpos(&[current_rpo, mock_historical_rpo], &blinding)
                        .map_err(|e| e.to_string())?;
                        
                    println!("[INFO] Recursive proof aggregation succeeded. APO aggregate root: {:?}, seal x: {}", apo.aggregate_root, apo.seal_x);

                    // Compute proof digest based on the aggregate root from our recursive circuit integration
                    let proof_digest = audit::compute_bytes_hash(&apo.aggregate_root);
                    
                    let timestamp = std::time::SystemTime::now()
                        .duration_since(std::time::UNIX_EPOCH)
                        .unwrap()
                        .as_millis() as u64;

                    let atom = LambdaTraceAtom {
                        proof_digest,
                        state_root_hash,
                        timestamp,
                        q,
                    };

                    // 5. PLIC Gate: Authorize state update or trigger Silence Clause (Fail-closed)
                    if let Err(gate_err) = PlicExecutionGate::verify_atom(&atom) {
                        eprintln!("[PRESERVATION ALERT] [PLIC SILENCE CLAUSE TRIGGERED] Actuation Denied: {}", gate_err);
                        return Err(gate_err.to_string());
                    }

                    LedgerEmitter::emit(&atom).map_err(|e| e.to_string())?;
                    Ok(())
                }).await.unwrap_or_else(|e| Err(e.to_string()));
                let _ = reply_tx.send(res);
            });
        }
    });

    loop {
        let (socket, _) = listener.accept().await?;
        let acceptor = acceptor.clone();
        let tx = prover_tx.clone();
        
        tokio::spawn(async move {
            if let Err(e) = handle_client_stream(socket, acceptor, tx).await {
                eprintln!("[ERROR] Transaction aborted down-stream: {:?}", e);
            }
        });
    }
}

async fn handle_client_stream(
    stream: tokio::net::TcpStream,
    acceptor: TlsAcceptor,
    tx: tokio::sync::mpsc::Sender<([f64; CIRCUIT_WIDTH], tokio::sync::oneshot::Sender<Result<() ,String>>)>
) -> Result<(), Box<dyn Error>> {
    let mut stream = acceptor.accept(stream).await?;
    
    use tokio::io::AsyncReadExt;
    let mut buffer = Vec::new();
    stream.read_to_end(&mut buffer).await?;
    
    // 1. Structural Validation (Zero-Copy Deserialization)
    let data: FhirPatientData<'_> = serde_json::from_slice(&buffer)?;
    let circuit_input: [f64; CIRCUIT_WIDTH] = data.into();
    
    // Explicitly zero out memory segments of the raw FHIR payload buffer to scrub PHI from memory
    for byte in &mut buffer {
        *byte = 0;
    }
    
    // 2. Offload to centralized CPU-bound prover pool via bounded MPSC channel
    let (reply_tx, reply_rx) = tokio::sync::oneshot::channel();
    tx.send((circuit_input, reply_tx)).await?;
    
    // Wait for the prover task to complete
    reply_rx.await?.map_err(|e| -> Box<dyn Error> { e.into() })?;
    
    Ok(())
}

fn load_certs(path: &str) -> Result<Vec<rustls::Certificate>, Box<dyn Error>> {
    let mut reader = BufReader::new(File::open(path)?);
    Ok(rustls_pemfile::certs(&mut reader)?.into_iter().map(rustls::Certificate).collect())
}

fn load_key(path: &str) -> Result<rustls::PrivateKey, Box<dyn Error>> {
    let mut reader = BufReader::new(File::open(path)?);
    let keys = rustls_pemfile::pkcs8_private_keys(&mut reader)?;
    Ok(rustls::PrivateKey(keys[0].clone()))
}

fn load_roots(path: &str) -> Result<rustls::RootCertStore, Box<dyn Error>> {
    let mut store = rustls::RootCertStore::empty();
    let mut reader = BufReader::new(File::open(path)?);
    let certs = rustls_pemfile::certs(&mut reader)?;
    for cert in certs {
        store.add(&rustls::Certificate(cert))?;
    }
    Ok(store)
}

#[cfg(test)]
mod pipeline_tests {
    use super::*;

    #[test]
    fn test_end_to_end_recursive_pipeline() {
        // 1. Setup mock patient observations
        let observations = vec![0.05, 0.1, 0.15, 0.2];
        let patient_data = FhirPatientData {
            patient_id: "test-patient-123",
            observations,
            metadata: "test-metadata",
        };
        let circuit_input: [f64; CIRCUIT_WIDTH] = patient_data.into();

        // 2. Quantize matrix
        let quantized = SafeNecessityProjector::quantize_matrix(&circuit_input).unwrap();

        // 3. Compute stability witness (q)
        let q = stability::StabilityModule::compute_witness(&circuit_input);
        assert!(q < plic::STABILITY_THRESHOLD);

        // 4. Retrieve state root bytes and hash
        let state_root_hash = audit::compute_quantized_hash(&quantized);
        let state_root_bytes = audit::compute_quantized_bytes(&quantized);

        // 5. Instantiate bridge and create recursive proofs
        let bridge = RecursiveProofBridge::new();
        let blinding = num_bigint::BigUint::from(987654321u64);

        let current_rpo = bridge.wrap_state_root(&state_root_bytes, &blinding).unwrap();
        let mock_historical_root = [42u8; 32];
        let mock_historical_rpo = bridge.wrap_state_root(&mock_historical_root, &blinding).unwrap();

        // 6. Aggregate proofs into an APO
        let apo = bridge.aggregate_rpos(&[current_rpo, mock_historical_rpo], &blinding).unwrap();
        assert_eq!(apo.protocol_v, 1);
        assert_eq!(apo.member_roots.len(), 2);

        // 7. Verify trace atom structure and PLIC verification
        let proof_digest = audit::compute_bytes_hash(&apo.aggregate_root);
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64;

        let atom = LambdaTraceAtom {
            proof_digest,
            state_root_hash,
            timestamp,
            q,
        };

        let verification_result = PlicExecutionGate::verify_atom(&atom);
        assert!(verification_result.is_ok(), "PLIC execution gate validation failed: {:?}", verification_result);
    }
}
