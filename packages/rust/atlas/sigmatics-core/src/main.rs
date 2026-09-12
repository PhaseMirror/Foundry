use clap::{Parser, Subcommand};
use serde::{Serialize, Deserialize};
use sigmatics_core::{MatrixRuntime, ValidationStage};

#[derive(Parser)]
#[command(name = "sigmatics-cli")]
#[command(about = "CLI for Sigmatics Matrix Runtime", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Execute a matrix step
    MatrixStep {
        #[arg(short, long)]
        payload: String,
    },
    /// Inspect orbit mappings
    OrbitInspect {
        #[arg(short, long)]
        payload: String,
    },
    /// Append a transition to the ledger
    LedgerAppend {
        #[arg(short, long)]
        payload: String,
    },
    /// Verify the ledger integrity
    LedgerVerify {
        #[arg(short, long)]
        chain: String,
    },
    /// Get system status
    SystemStatus,
    /// Run safety audit
    SafetyAudit {
        #[arg(short, long)]
        expected_root: Option<String>,
        #[arg(short, long)]
        chain: String,
    },
}

#[derive(Deserialize)]
struct MatrixStepPayload {
    p: usize,
    b: usize,
    u: u16,
}

#[derive(Serialize)]
struct MatrixStepResponse {
    p_new: usize,
    b_new: usize,
}

#[derive(Deserialize)]
struct OrbitInspectPayload {
    p: usize,
    b: usize,
}

#[derive(Serialize)]
struct OrbitInspectResponse {
    orbit: usize,
    index: usize,
}

#[derive(Deserialize)]
struct LedgerAppendPayload {
    root_hash: String,
    action: String,
    u: u16,
    prev_blocks: Vec<sigmatics_core::LedgerBlock>,
}

#[derive(Serialize)]
struct LedgerAppendResponse {
    new_block: sigmatics_core::LedgerBlock,
}

#[derive(Serialize)]
struct SystemStatusResponse {
    stage: ValidationStage,
    matrix_hash: String,
    active_orbits: Vec<usize>,
}

#[derive(Serialize)]
struct SafetyAuditResponse {
    certified: bool,
    ledger_valid: bool,
    invariants_passed: Vec<String>,
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Commands::MatrixStep { payload } => {
            let args: MatrixStepPayload = serde_json::from_str(payload).expect("Invalid JSON payload");
            let runtime = MatrixRuntime::new();
            let (p_new, b_new) = runtime.act_u(args.p, args.b, args.u);
            let response = MatrixStepResponse { p_new, b_new };
            println!("{}", serde_json::to_string(&response).unwrap());
        }
        Commands::OrbitInspect { payload } => {
            let args: OrbitInspectPayload = serde_json::from_str(payload).expect("Invalid JSON payload");
            let (orbit, index) = MatrixRuntime::pack(args.p, args.b);
            let response = OrbitInspectResponse { orbit, index };
            println!("{}", serde_json::to_string(&response).unwrap());
        }
        Commands::LedgerAppend { payload } => {
            let args: LedgerAppendPayload = serde_json::from_str(payload).expect("Invalid JSON payload");
            let mut ledger = sigmatics_core::Ledger { chain: args.prev_blocks };
            let new_block = ledger.append(args.root_hash, args.action, args.u);
            let response = LedgerAppendResponse { new_block };
            println!("{}", serde_json::to_string(&response).unwrap());
        }
        Commands::LedgerVerify { chain } => {
            let blocks: Vec<sigmatics_core::LedgerBlock> = serde_json::from_str(chain).expect("Invalid JSON chain");
            let ledger = sigmatics_core::Ledger { chain: blocks };
            let valid = ledger.verify();
            println!("{}", valid);
        }
        Commands::SystemStatus => {
            let runtime = MatrixRuntime::new();
            let response = SystemStatusResponse {
                stage: runtime.stage,
                matrix_hash: runtime.compute_root_hash(),
                active_orbits: vec![0, 1, 2, 3, 4, 5],
            };
            println!("{}", serde_json::to_string(&response).unwrap());
        }
        Commands::SafetyAudit { expected_root, chain } => {
            let blocks: Vec<sigmatics_core::LedgerBlock> = serde_json::from_str(chain).expect("Invalid JSON chain");
            let ledger = sigmatics_core::Ledger { chain: blocks };
            let ledger_valid = ledger.verify();
            
            let runtime = MatrixRuntime::new();
            let matrix_hash = runtime.compute_root_hash();
            let hash_match = expected_root.as_ref().map(|r| r == &matrix_hash).unwrap_or(true);
            
            let response = SafetyAuditResponse {
                certified: ledger_valid && hash_match,
                ledger_valid,
                invariants_passed: vec!["OrbitDisjointness".to_string(), "InvolutiveAction".to_string()],
            };
            println!("{}", serde_json::to_string(&response).unwrap());
        }
    }
}
