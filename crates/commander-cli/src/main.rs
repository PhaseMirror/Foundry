use archivum::WitnessLedger;
use clap::{Parser, Subcommand};
use sigma::{SigmaKernel, StateTransition, Thresholds, PolicyEngine};
use std::io::{self, Read};

#[derive(Parser)]
#[command(name = "pscmd")]
#[command(about = "PhaseSpace Commander — governed operator shell", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Evaluate a state transition through the Sigma kernel
    Sigma {
        #[command(subcommand)]
        action: SigmaAction,
    },
}

#[derive(Subcommand)]
enum SigmaAction {
    /// Evaluate a transition JSON (stdin or --input)
    Evaluate {
        /// Path to transition JSON file (reads stdin if omitted)
        #[arg(short, long)]
        input: Option<std::path::PathBuf>,
    },
}

fn load_transition(input: Option<std::path::PathBuf>) -> anyhow::Result<StateTransition> {
    let raw = if let Some(path) = input {
        std::fs::read_to_string(path)?
    } else {
        let mut buf = String::new();
        io::stdin().read_to_string(&mut buf)?;
        buf
    };
    Ok(serde_json::from_str(&raw)?)
}

fn run_sigma_evaluate(input: Option<std::path::PathBuf>) -> anyhow::Result<()> {
    let transition = load_transition(input)?;

    let thresholds = Thresholds::default();

    let engine = PolicyEngine::new();
    let ledger = WitnessLedger::new("state/archivum/witnesses.jsonl");
    let mut kernel = SigmaKernel::new(engine, ledger, thresholds);

    match kernel.evaluate(transition) {
        Ok(block) => {
            println!("✅ Ratified Transition Block");
            println!("ID: {}", block.transition_id);
            println!("Ratified: {}", block.ratified);
            Ok(())
        }
        Err(e) => {
            eprintln!("❌ Dissonance Trap: {}", e);
            eprintln!("Check state/archivum/witnesses.jsonl for ConflictLogSchema + PWEH");
            anyhow::bail!(e)
        }
    }
}

fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Sigma { action: SigmaAction::Evaluate { input } } => {
            run_sigma_evaluate(input)
        }
    }
}
