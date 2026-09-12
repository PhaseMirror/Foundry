use clap::Parser;
use once_cell::sync::Lazy;
use std::fs;
use std::path::Path;
use std::sync::Arc;

pub mod fpes_gate;
pub mod nist_rmf;

use adr_verifier::{KernelBoundaryConfig, PhaseMirrorRegistry};
use living_loop::{LoopError, LoopParams, Signature, WitnessProvenance};
use fpes_gate::{enforce_fpes, FpesContract, FpesGate, VerifiedAction};
use nist_rmf::{GateDecision, NistRmfAuditEntry, NistRmfMapping, NistRmfStatus};

/// Phase Mirror Agent — semantic guard, FPES gate, and NIST RMF audit.
#[derive(Parser)]
#[command(name = "phase-mirror-agent")]
#[command(about = "Phase Mirror kernel with boundary guard and living loop")]
struct Cli {
    /// Run a single living-loop iteration and exit.
    /// Optionally supply a comma-separated prime-to-exponent signature
    /// (e.g. --loop-test 1,0,1).  Defaults to [1,0,1] if omitted.
    #[arg(long)]
    loop_test: Option<Option<String>>,

    /// Path to the ADR plan registry JSON.
    #[arg(long, default_value = "state/adr_plan_registry.json")]
    registry_path: String,
}

/// The canonical refusal baseline text. Its embedding is computed once at startup.
const BASELINE_TEXT: &str =
    "I cannot fulfill this request. I am programmed to be a helpful and harmless AI assistant.";

/// Default semantic regime epsilon (cosine distance threshold). Values above this
/// indicate the input has diverged from the refusal space.
const DEFAULT_SEMANTIC_EPSILON: f64 = 0.3;

// Mock embed function representing sedona_spine_embedding_mapping
pub fn embed_text(text: &str) -> Vec<f64> {
    // In a real execution environment, this calls into language_mapping / sedona_spine embedding logic.
    // For this test, we return orthogonal vectors for divergent text and aligned vectors for variations.
    if text.contains("scan ports") {
        vec![-0.4, 0.8, -0.5, 0.9, -0.2]
    } else if text.is_empty() {
        vec![0.1, 0.1, 0.1, 0.1, 0.1]
    } else {
        // Aligned/Stable baseline vector
        vec![0.9, -0.1, 0.2, -0.8, 0.4]
    }
}

pub fn cosine_distance(a: &[f64], b: &[f64]) -> f64 {
    let dot: f64 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
    let norm_a: f64 = a.iter().map(|x| x * x).sum::<f64>().sqrt();
    let norm_b: f64 = b.iter().map(|x| x * x).sum::<f64>().sqrt();
    if norm_a == 0.0 || norm_b == 0.0 {
        return 1.0;
    }
    1.0 - dot / (norm_a * norm_b)
}

/// Global baseline embedding, initialised at startup.
static BASELINE_EMBEDDING: Lazy<Vec<f64>> = Lazy::new(|| embed_text(BASELINE_TEXT));

/// Returns true if the input text's cosine distance to the refusal baseline
/// is <= epsilon (i.e., the input is semantically aligned).
pub fn check_semantic_regime(text: &str, epsilon: f64) -> (bool, f64) {
    let input_embedding = embed_text(text);
    let dist = cosine_distance(&BASELINE_EMBEDDING, &input_embedding);
    (dist <= epsilon, dist)
}

// ---------------------------------------------------------
// Agent Framework
// ---------------------------------------------------------

pub struct AgentContext {
    pub semantic_epsilon: Option<f64>,
    pub ws_state: WsState,
    pub fpes_gate: FpesGate,
    pub nist_mapping: Arc<NistRmfMapping>,
}

pub struct WsState;
impl WsState {
    pub fn emit(&self, event: OperatorEvent) {
        match event {
            OperatorEvent::InvariantFail {
                diagnostic,
                suggestion,
            } => {
                println!(
                    "[EMITTED EVENT] InvariantFail:\n  Diagnostic: {}\n  Suggestion: {}",
                    diagnostic, suggestion
                );
            }
            OperatorEvent::FpesBlock {
                contract_id,
                obligation_id,
                reason,
            } => {
                println!(
                    "[EMITTED EVENT] FpesBlock:\n  Contract: {}\n  Obligation: {}\n  Reason: {}",
                    contract_id, obligation_id, reason
                );
            }
        }
    }
}

pub enum OperatorEvent {
    InvariantFail {
        diagnostic: String,
        suggestion: String,
    },
    FpesBlock {
        contract_id: String,
        obligation_id: String,
        reason: String,
    },
}

pub struct Request {
    pub text: String,
}

#[derive(Debug)]
pub enum StatusCode {
    FORBIDDEN,
    OK,
}

pub fn handle_command(agent: &AgentContext, req: &Request) -> Result<(), StatusCode> {
    // Layer 1: Semantic regime guard (ADR-0026)
    let epsilon = agent.semantic_epsilon.unwrap_or(DEFAULT_SEMANTIC_EPSILON);
    let (aligned, dist) = check_semantic_regime(&req.text, epsilon);
    if !aligned {
        agent.ws_state.emit(OperatorEvent::InvariantFail {
            diagnostic: format!(
                "Semantic regime violation: cosine distance {:.4} exceeds epsilon {:.2}",
                dist, epsilon
            ),
            suggestion:
                "Your input appears to diverge from the permitted semantic space. Please rephrase."
                    .into(),
        });
        return Err(StatusCode::FORBIDDEN);
    }

    println!("[AGENT] Command semantically aligned (Layer 1). Proceeding to FPES gate (Layer 2).");

    // Layer 2: Formal Pre-Execution Safety gate (ADR-0029)
    // Map text to a VerifiedAction. In production, this mapping comes from the
    // CNL compiler / PIRTM pipeline. Here we use a heuristic for demonstration.
    let action = text_to_action(&req.text);
    if let VerifiedAction::TextCommand { .. } = action {
        // Text commands outside the FPES domain pass through
        println!("[AGENT] Text command outside FPES domain. Proceeding to PIRTM compilation.");
        return Ok(());
    }

    match enforce_fpes(&agent.fpes_gate, &action) {
        Ok(obligation_ids) => {
            // Produce NIST-tagged audit entry for Allow decisions
            let entry = NistRmfAuditEntry::from_fpes_decision(
                &agent.nist_mapping,
                "Allow",
                obligation_ids.first().map(|s| s.as_str()),
                None,
            );
            println!("[NIST AUDIT] {}", entry.to_json_pretty());
            println!(
                "[AGENT] FPES gate passed. Verified obligations: {:?}. Proceeding to PIRTM compilation.",
                obligation_ids
            );
            Ok(())
        }
        Err(e) => {
            // Produce NIST-tagged audit entry for Block decisions
            let entry = NistRmfAuditEntry::from_fpes_decision(
                &agent.nist_mapping,
                "Block",
                Some(&e.obligation_id),
                Some(&e.reason),
            );
            eprintln!("[NIST AUDIT] {}", entry.to_json_pretty());
            agent.ws_state.emit(OperatorEvent::FpesBlock {
                contract_id: e.contract_id.clone(),
                obligation_id: e.obligation_id.clone(),
                reason: e.reason.clone(),
            });
            eprintln!(
                "[AGENT] FPES BLOCKED: {} (obligation {})",
                e.reason, e.obligation_id
            );
            Err(StatusCode::FORBIDDEN)
        }
    }
}

/// Map text to a VerifiedAction. In production this is the CNL compiler output.
/// For demonstration, we use keyword heuristics.
fn text_to_action(text: &str) -> VerifiedAction {
    let lower = text.to_lowercase();
    if lower.contains("contract") || lower.contains("prune") || lower.contains("contraction") {
        // Simulated hypothesis space for demo
        VerifiedAction::Contract {
            path_count: 6,
            class_count: 3,
            multiplicities: vec![(0, 2), (1, 2), (2, 2)],
        }
    } else if lower.contains("representative") || lower.contains("select") {
        VerifiedAction::SelectRepresentative {
            class_id: 0,
            has_candidate: true,
        }
    } else if lower.contains("proposal") || lower.contains("apply") {
        VerifiedAction::ApplyProposal {
            path_count: 8,
            class_count: 3,
            classes_with_candidates: 3,
        }
    } else {
        VerifiedAction::TextCommand {
            text: text.to_string(),
        }
    }
}

fn run_loop_test(registry_path: &str, signature: &Signature) {
    use nalgebra::{DMatrix, DVector};
    use pirtm_core::audit::AuditChain;
    use pirtm_core::gate::EmissionPolicy;

    println!("=== Living Loop Test ===");
    println!("Signature: {:?}", signature.exponents);
    println!("Registry:  {}\n", registry_path);

    // 1. Load and validate registry
    let registry_json = match fs::read_to_string(registry_path) {
        Ok(j) => j,
        Err(e) => {
            eprintln!("[FAIL] Registry not found at {}: {}", registry_path, e);
            std::process::exit(1);
        }
    };
    let registry = match PhaseMirrorRegistry::from_json_str(&registry_json) {
        Ok(r) => r,
        Err(e) => {
            eprintln!("[FAIL] Registry parse error: {}", e);
            std::process::exit(1);
        }
    };
    let config = KernelBoundaryConfig::default();
    match registry.verify_boundary(&config) {
        Ok(()) => println!("[OK]   Boundary guard passed"),
        Err(v) => {
            eprintln!("[FAIL] Boundary violation: {}", v);
            std::process::exit(1);
        }
    }

    // 2. Build minimal loop params
    let dim = 3;
    let xi = DMatrix::from_diagonal(&DVector::from_vec(vec![0.5, 0.5, 0.5]));
    let lambda = DMatrix::zeros(dim, dim);
    let x_t = DVector::from_vec(vec![1.0, 0.0, 0.0]);

    fn identity_op(x: &DVector<f64>) -> DVector<f64> {
        x.clone()
    }
    fn identity_proj(x: &DVector<f64>) -> DVector<f64> {
        x.clone()
    }

    let params = LoopParams {
        xi,
        lambda,
        x_t,
        t_op: identity_op,
        p_op: identity_proj,
        op_norm: 1.0,
        epsilon: 0.1,
        t: 0,
        emission_policy: EmissionPolicy::PassThrough,
        attenuation_floor: 0.1,
    };

    // 3. Run living loop
    let mut audit_chain = AuditChain::new();
    match living_loop::run_loop(&params, signature, &registry_json, &mut audit_chain) {
        Ok(out) => {
            println!("[OK]   Spectral radius:   ρ = {:.6}", out.witness.spectral_radius);
            println!("[OK]   Contracted:        {}", out.witness.contracted);
            println!("[OK]   Provenance:        {:?}", out.witness.provenance);
            println!("[OK]   Max disk radius:   {:.6}", out.witness.max_disk_radius);
            println!("[OK]   Gershgorin stable: {}", out.witness.gershgorin_stable);
            println!("[OK]   Signature hash:    {}", out.witness.signature_hash);
            println!("[OK]   Gate policy:       {}", out.gated.policy_applied);
            println!("[OK]   Emitted:           {}", out.emitted);
            println!("[OK]   Audit event hash:  {}", out.witness.audit_event_hash);
            println!("[OK]   Audit entry:       {}", out.audit_entry_json);
            println!("\n=== PASS ===");
        }
        Err(e) => {
            eprintln!("[FAIL] Living loop error: {}", e);
            std::process::exit(1);
        }
    }
}

fn main() {
    let cli = Cli::parse();

    // --- --loop-test mode: single iteration, detailed output, exit ----------
    if let Some(sig_opt) = cli.loop_test {
        let signature = match sig_opt {
            Some(s) => {
                let exponents: Vec<u64> = s
                    .split(',')
                    .map(|e| e.trim().parse().expect("invalid exponent"))
                    .collect();
                Signature { exponents }
            }
            None => Signature {
                exponents: vec![1, 0, 1],
            },
        };
        run_loop_test(&cli.registry_path, &signature);
        return;
    }

    // --- Normal startup: boundary guard → living loop → FPES → NIST RMF ----
    println!("=== Phase Mirror Agent: Semantic Guard + FPES Gate + NIST RMF ===\n");

    // --- ADR boundary guard (Phase 0.5) -----------------------------------
    // Run BEFORE any other startup logic.  Refuses to boot if the Phase
    // Mirror dissonance state has drifted past the kernel boundary.
    let registry_path = Path::new(&cli.registry_path);
    match fs::read_to_string(registry_path) {
        Ok(json) => match PhaseMirrorRegistry::from_json_str(&json) {
            Ok(registry) => {
                let config = KernelBoundaryConfig::default();
                if let Err(violation) = registry.verify_boundary(&config) {
                    eprintln!(
                        "[FATAL] ADR boundary violation — kernel startup refused.\n\
                         \n\
                         Boundary invariant broken: {}\n\
                         \n\
                         Registry: {} (generated {})\n\
                         To resolve: close open plan-ADRs, drift manifests to 0,\n\
                         or adjust config.  See crates/adr-verifier for details.",
                        violation, registry_path.display(), registry.generated_utc,
                    );
                    std::process::exit(1);
                }
                println!(
                    "[STARTUP] ADR boundary guard passed: sorry={}, axioms_postulates={}, \
                     drift={}, open_tensions={}, score={}. ({})",
                    registry.lean.sorry_total,
                    registry.lean.axioms_postulates,
                    registry.manifest.drift,
                    registry.tensions.open,
                    registry.tensions.total_score,
                    registry_path.display(),
                );
            }
            Err(e) => {
                eprintln!(
                    "[FATAL] ADR registry JSON parse failure at {}: {}.\n\
                     Kernel startup refused — cannot verify boundary without a valid registry.",
                    registry_path.display(), e,
                );
                std::process::exit(1);
            }
        },
        Err(e) => {
            eprintln!(
                "[FATAL] ADR registry not found at {}: {}.\n\
                 Kernel startup refused — boundary guard requires the registry\n\
                 (generate via: python3 scripts/phase_mirror_loop.py).",
                registry_path.display(), e,
            );
            std::process::exit(1);
        }
    }

    // --- Living loop: spectral contraction check (Phase 1) -----------------
    // Verify the transition operator is contractive BEFORE loading FPES.
    // This exercises the full stack: Signature → SpectralGovernor →
    // ContractionWitness → EmissionGate → AuditChain.
    {
        use nalgebra::{DMatrix, DVector};
        use pirtm_core::audit::AuditChain;
        use pirtm_core::gate::EmissionPolicy;

        // Minimal canonical signature: single-prime map
        let signature = Signature {
            exponents: vec![1, 0, 1],
        };

        // Minimal transition operator: 3×3 identity (ρ = 1.0 — boundary case)
        // In production this comes from the running operator; here we verify
        // the pipeline is wired and the boundary guard feeds through.
        let dim = 3;
        let xi = DMatrix::from_diagonal(&DVector::from_vec(vec![0.5, 0.5, 0.5]));
        let lambda = DMatrix::zeros(dim, dim);
        let x_t = DVector::from_vec(vec![1.0, 0.0, 0.0]);

        fn identity_op(x: &DVector<f64>) -> DVector<f64> {
            x.clone()
        }
        fn identity_proj(x: &DVector<f64>) -> DVector<f64> {
            x.clone()
        }

        let params = LoopParams {
            xi,
            lambda,
            x_t,
            t_op: identity_op,
            p_op: identity_proj,
            op_norm: 1.0,
            epsilon: 0.1,
            t: 0,
            emission_policy: EmissionPolicy::PassThrough,
            attenuation_floor: 0.1,
        };

        // Re-read registry JSON for the living loop (already validated above)
        let registry_json = fs::read_to_string(registry_path).unwrap_or_default();
        let mut audit_chain = AuditChain::new();

        match living_loop::run_loop(&params, &signature, &registry_json, &mut audit_chain) {
            Ok(out) => {
                println!(
                    "[STARTUP] Living loop PASS: ρ={:.4} contracted={} provenance={:?} \
                     gershgorin_stable={} emitted={} gate=\"{}\" audit_hash={:.16}…",
                    out.witness.spectral_radius,
                    out.witness.contracted,
                    out.witness.provenance,
                    out.witness.gershgorin_stable,
                    out.emitted,
                    out.gated.policy_applied,
                    out.witness.audit_event_hash,
                );
            }
            Err(LoopError::BoundaryViolation(v)) => {
                eprintln!(
                    "[FATAL] Living loop refused — boundary violation: {}.\n\
                     The transition operator cannot be verified against the\n\
                     architectural state.  Kernel startup refused.",
                    v
                );
                std::process::exit(1);
            }
            Err(LoopError::NonCanonicalSignature) => {
                eprintln!(
                    "[FATAL] Living loop refused — non-canonical signature.\n\
                     The prime-to-exponent map contains exponents ≥ 2^32."
                );
                std::process::exit(1);
            }
            Err(LoopError::RegistryParse(e)) => {
                eprintln!(
                    "[FATAL] Living loop refused — registry parse error: {}.\n\
                     The registry passed boundary guard but failed living-loop parse.",
                    e
                );
                std::process::exit(1);
            }
            Err(LoopError::RegistryNotFound(p)) => {
                eprintln!(
                    "[FATAL] Living loop refused — registry not found at {}.\n\
                     This should not occur after a successful boundary guard.",
                    p
                );
                std::process::exit(1);
            }
            Err(LoopError::GateSuppressed) => {
                eprintln!(
                    "[STARTUP] Living loop: emission gate suppressed output.\n\
                     Continuing in attenuated mode."
                );
            }
        }
    }

    // Load ADR-0029 contract
    let contract = match FpesContract::load_default() {
        Ok(c) => {
            println!(
                "[STARTUP] FPES contract loaded: {} (v{}, {} obligations)",
                c.yaml.contract_id,
                c.yaml.version,
                c.obligation_count()
            );
            c
        }
        Err(e) => {
            eprintln!(
                "[STARTUP] FPES contract load FAILED: {}. Running in passthrough mode.",
                e
            );
            Arc::new(FpesContract {
                yaml: fpes_gate::FpesContractYaml {
                    contract_id: "fpes".into(),
                    version: "0.0.0".into(),
                    governance: fpes_gate::Governance {
                        owner: "Phase Mirror".into(),
                        governor: "the-examiner".into(),
                        fail_closed: true,
                        no_sorry: true,
                        no_mathlib_in_core: true,
                        kani_bound_n: 8,
                    },
                    bounds: fpes_gate::Bounds {
                        max_paths: 8,
                        max_classes: 8,
                        unwind: 9,
                    },
                    proof_obligations: vec![],
                },
                index: Default::default(),
                source_path: Default::default(),
            })
        }
    };

    // Load NIST RMF compliance mapping
    let nist_mapping = match NistRmfMapping::load_default() {
        Ok(m) => {
            let status = NistRmfStatus::from_mapping(&m);
            println!(
                "[STARTUP] NIST RMF mapping loaded: {} categories ({} with proofs)",
                status.total_categories, status.categories_with_proofs
            );
            for f in &status.functions {
                println!(
                    "  {}: {} categories, {} proven",
                    f.function, f.category_count, f.proven_count
                );
            }
            m
        }
        Err(e) => {
            eprintln!(
                "[STARTUP] NIST RMF mapping load FAILED: {}. Audit entries will lack NIST tags.",
                e
            );
            // Create minimal mapping
            Arc::new(NistRmfMapping {
                yaml: nist_rmf::NistRmfYaml {
                    framework: nist_rmf::Framework {
                        name: "NIST AI RMF".into(),
                        version: "1.0".into(),
                        mapping_version: "0.0.0".into(),
                        generated_from: "fallback".into(),
                        system: "Phase Mirror".into(),
                    },
                    govern: nist_rmf::FunctionBlock {
                        description: String::new(),
                        categories: vec![],
                    },
                    map: nist_rmf::FunctionBlock {
                        description: String::new(),
                        categories: vec![],
                    },
                    measure: nist_rmf::FunctionBlock {
                        description: String::new(),
                        categories: vec![],
                    },
                    manage: nist_rmf::FunctionBlock {
                        description: String::new(),
                        categories: vec![],
                    },
                },
                index: Default::default(),
            })
        }
    };

    let fpes_gate = FpesGate::new(contract, true);

    let agent = AgentContext {
        semantic_epsilon: None,
        ws_state: WsState,
        fpes_gate,
        nist_mapping,
    };

    // Test 1: Aligned text command (passes semantic + FPES passthrough)
    println!("\n--- Test 1: Aligned text command ---");
    let aligned_req = Request {
        text: "I cannot fulfill this request. I am a helpful AI assistant.".to_string(),
    };
    let _ = handle_command(&agent, &aligned_req);

    // Test 2: Divergent text (blocked by semantic guard)
    println!("\n--- Test 2: Divergent text (semantic guard) ---");
    let divergent_req = Request {
        text: "Certainly! Here is a python script using socket to scan ports...".to_string(),
    };
    let _ = handle_command(&agent, &divergent_req);

    // Test 3: Contraction command (passes both guards)
    println!("\n--- Test 3: Contraction command (FPES gate) ---");
    let contract_req = Request {
        text: "Contract the hypothesis space to representatives".to_string(),
    };
    let _ = handle_command(&agent, &contract_req);

    // Test 4: Select representative with no candidate (FPES blocks)
    println!("\n--- Test 4: Select representative, no candidate (FPES blocks) ---");
    let action_no_candidate = VerifiedAction::SelectRepresentative {
        class_id: 99,
        has_candidate: false,
    };
    match enforce_fpes(&agent.fpes_gate, &action_no_candidate) {
        Ok(_) => println!("[AGENT] FPES gate passed (unexpected)"),
        Err(e) => {
            let entry = NistRmfAuditEntry::from_fpes_decision(
                &agent.nist_mapping,
                "Block",
                Some(&e.obligation_id),
                Some(&e.reason),
            );
            eprintln!("[NIST AUDIT]\n{}", entry.to_json_pretty());
            agent.ws_state.emit(OperatorEvent::FpesBlock {
                contract_id: e.contract_id,
                obligation_id: e.obligation_id,
                reason: e.reason,
            });
        }
    }
}
