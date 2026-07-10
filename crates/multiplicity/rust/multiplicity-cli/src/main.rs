use clap::{Parser, Subcommand};
use anyhow::Result;

#[derive(Parser)]
#[command(name = "m", about = "Multiplicity CLI")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Init {
        #[arg(short, long)]
        template: Option<String>,
    },
    Analyze {
        files: Vec<String>,
    },
    Validate,
    Drift,
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    match cli.command {
        Commands::Init { template } => {
            println!("Initializing with template: {:?}", template);
        }
        Commands::Analyze { files } => {
            println!("Analyzing: {:?}", files);
        }
        Commands::Validate => {
            println!("Validating L0 invariants...");
        }
        Commands::Drift => {
            println!("Detecting drift...");
        }
    }
    Ok(())
}
