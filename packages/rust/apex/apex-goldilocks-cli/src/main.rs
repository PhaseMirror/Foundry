use clap::{Parser, Subcommand};
use apex_goldilocks_core::boundary_lattice::LatticeCertificate;
use multiplicity_runtime::{MultiplicityRuntime, CRMFConfig};
use multiplicity_runtime::harness::{NeuralHarness, EchoBraidState, HarnessAdapter};
use apex_hologram::{AtlasEmbeddingProof, RecursiveProof};
use goldilocks::{GoldilocksField, PrimeMask};
use apex_goldilocks_core::GoldVector;

use apex_pikernel::{
    ProjectorFamily, PiIndexGrid, HologramAdapterManaged, HologramAdapterConfig, Rational
};
use num_traits::{Zero, One};
use ndarray::{Array1, Array2};
use std::collections::HashMap;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Verify the 12,288 Boundary Lattice invariants.
    AuditLattice,
    /// Run an end-to-end EchoBraid certification pilot.
    Pilot {
        #[arg(short, long, default_value_t = 0x42)]
        domain: u64,
        #[arg(short, long, default_value_t = 100)]
        budget: u64,
    },
    /// Verify ACE stability for a set of operators (PIRTM Phase C).
    VerifyStability {
        /// Sum of operator norms (in units of 0.000001)
        #[arg(short, long)]
        total_norm: i64,
        /// Governance constant c (in units of 0.000001)
        #[arg(short, long, default_value_t = 50000)]
        gov_c: i64,
    },
    /// Validate PIRTM source code using tree-sitter (PIRTM Phase A).
    ValidatePirtm {
        /// PIRTM source code or file path
        #[arg(short, long)]
        source: String,
        /// JSON set of allowed primes
        #[arg(short, long, default_value = "[2, 3, 5, 7, 11, 13]")]
        primes: String,
        /// Stratum ID for admissibility check
        #[arg(short, long, default_value = "S1")]
        stratum: String,
    },
    /// Run an E2E parameter sweep for the pi-kernel bridge.
    SweepPikernel {
        /// Start value for tau (in units of 0.1)
        #[arg(long, default_value_t = 10)]
        tau_start: u32,
        /// End value for tau (in units of 0.1)
        #[arg(long, default_value_t = 20)]
        tau_end: u32,
        /// Start value for alpha (in units of 0.1)
        #[arg(long, default_value_t = 1)]
        alpha_start: u32,
        /// End value for alpha (in units of 0.1)
        #[arg(long, default_value_t = 5)]
        alpha_end: u32,
    },
}

fn main() {
    env_logger::init();
    let cli = Cli::parse();

    match &cli.command {
        Commands::AuditLattice => {
            println!("Auditing 12,288 Boundary Lattice...");
            let cert = LatticeCertificate::verify();
            println!("Total Elements: {}", cert.total_elements);
            println!("Orbit Sizes: {:?}", cert.orbit_sizes);
            println!("Free Action: {}", cert.is_free_action);
            if cert.total_elements == 12288 && cert.is_free_action {
                println!("Lattice Verification: PASSED");
            } else {
                println!("Lattice Verification: FAILED");
                std::process::exit(1);
            }
        }
        Commands::ValidatePirtm { source, primes, stratum } => {
            println!("Validating PIRTM Source (PIRTM Phase A)...");
            // Check if source is a file path
            let content = if std::path::Path::new(source).exists() {
                std::fs::read_to_string(source).expect("Failed to read PIRTM source file")
            } else {
                source.clone()
            };

            match pirtm_compiler::compiler::validate_source(&content, primes, stratum) {
                Ok(envelope) => {
                    println!("Validation Complete.");
                    println!("Version: {}", envelope.version);
                    if envelope.diagnostics.is_empty() {
                        println!("Result: ADMISSIBLE");
                    } else {
                        println!("Result: INADMISSIBLE");
                        for diag in envelope.diagnostics {
                            println!("  [{}:{}] {:?} - {}", diag.start_line, diag.start_col, diag.code, diag.message);
                        }
                        std::process::exit(1);
                    }
                }
                Err(e) => {
                    println!("Validation Error: {}", e);
                    std::process::exit(1);
                }
            }
        }
        Commands::VerifyStability { total_norm, gov_c } => {
            println!("Verifying ACE Stability (PIRTM Phase C)...");
            let op = pirtm_compiler::ace::DynamicOperator {
                signature: pirtm_compiler::types::Sig::new(),
                norm: pirtm_compiler::ace::FixedPoint(*total_norm),
            };
            let c = pirtm_compiler::ace::FixedPoint(*gov_c);
            
            match pirtm_compiler::ace::verify_stability(&[op], c) {
                Ok(_) => println!("Stability Check: PASSED"),
                Err(e) => {
                    println!("Stability Check: FAILED ({})", e);
                    std::process::exit(1);
                }
            }
        }
        Commands::Pilot { domain, budget } => {
            println!("Starting EchoBraid Pilot for Domain 0x{:X}...", domain);
            
            // 1. Initialize Runtime
            let config = CRMFConfig {
                domain_tag: *domain,
                prime_index: 256,
                prime_mask: PrimeMask(0xFFFFFFFFFFFFFFFF),
                signature: None,
            };
            let mut runtime = MultiplicityRuntime::new(config, *budget);
            let harness = NeuralHarness::new(10);
            
            // 2. Initial State
            let initial_theta = GoldVector::new(vec![GoldilocksField::new(1); 10]);
            let current_state = EchoBraidState {
                theta: initial_theta,
                iteration: 0,
            };

            // 3. Harness Adaptation
            let mut adapter = HarnessAdapter::new(&mut runtime, harness);
            let proposal = adapter.harness.propose_adaptation(&current_state);
            
            println!("Committing EchoBraid proposal (Iteration {})...", proposal.proposed_state.iteration);
            
            // 4. Veto-Enforced Certification
            match adapter.commit_proposal(proposal) {
                Ok(_) => {
                    println!("Certification: SUCCESS");
                    
                    // 5. Generate AEP
                    let initial_hash = [0x55; 32]; // Mock hash
                    let proof = RecursiveProof::new_initial(initial_hash);
                    let aep = AtlasEmbeddingProof {
                        proof,
                        domain_tag: *domain,
                    };
                    println!("Atlas-Embedding Proof (AEP) generated for Domain 0x{:X}", aep.domain_tag);
                }
                Err(e) => {
                    println!("Certification: VETOED ({})", e);
                    std::process::exit(1);
                }
            }
        }
        Commands::SweepPikernel { tau_start, tau_end, alpha_start, alpha_end } => {
            println!("🚀 Starting E2E Parameter Sweep for pi-kernel...");
            
            // 1. Define fixed families for 16D space
            let a = ProjectorFamily::new(
                vec![vec![0, 4, 8, 12], vec![1, 5, 9, 13], vec![2, 6, 10, 14], vec![3, 7, 11, 15]],
                "Spectral".to_string()
            );
            let b = ProjectorFamily::new(
                vec![vec![0, 1, 2, 3, 4, 5, 6, 7], vec![8, 9, 10, 11, 12, 13, 14, 15]],
                "Memory".to_string()
            );
            let families = vec![a, b];
            let grid = PiIndexGrid::new(families.clone()).unwrap();

            println!("| Tau | Alpha | Stability (GapLB) | MUB Alarms | Ledger Entries | Status |");
            println!("|-----|-------|-------------------|------------|----------------|--------|");

            for t_idx in *tau_start..=*tau_end {
                for a_idx in *alpha_start..=*alpha_end {
                    let tau = Rational::new(t_idx as i128, 10);
                    let alpha = Rational::new(a_idx as i128, 10);

                    let mut alphas = HashMap::new();
                    let mut weights = HashMap::new();
                    let mut taus = HashMap::new();

                    for pi in &grid.pi_ids {
                        alphas.insert(pi.clone(), alpha);
                        let indices = grid.indices(pi).unwrap();
                        weights.insert(pi.clone(), Array1::from_elem(indices.len(), Rational::one()));
                        taus.insert(pi.clone(), tau);
                    }

                    let m = grid.pi_ids.len();
                    let k = Array2::from_elem((m, m), Rational::new(35, 100)); // Higher coupling (0.35)
                    
                    let config = HologramAdapterConfig {
                        families: families.clone(),
                        alphas,
                        weights,
                        taus,
                        k,
                        use_poseidon: true,
                        ledger_path: None,
                        mub_threshold: 3.0,
                        tau_shrink_factor: Rational::new(9, 10),
                    };

                    let mut adapter = HologramAdapterManaged::new(config).unwrap();
                    let x = Array1::from_elem(16, Rational::new(5, 10));
                    
                    let result = adapter.step(&x).unwrap();
                    let status = if result.gap_lb > Rational::zero() { "STABLE" } else { "UNSTABLE" };
                    
                    println!("| {}.{} | {}.{} | {} | {} | {} | {} |", 
                        t_idx / 10, t_idx % 10, a_idx / 10, a_idx % 10, result.gap_lb, 
                        result.mub_alarms, adapter.ledger.get_entries().len(), status);
                }
            }
            println!("\n✅ Parameter Sweep Complete.");
        }
    }
}
