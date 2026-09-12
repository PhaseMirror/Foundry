use clap::{Parser, Subcommand};
use std::path::PathBuf;

use crate::canonical::{canonical_hash, canonicalize};
use crate::parser::parse_ir_file;

/// Command-line interface for the DRMM IR parser.
#[derive(Parser)]
#[command(author, version, about, long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

/// Available subcommands.
#[derive(Subcommand)]
pub enum Commands {
    /// Validate an IR JSON file and print the IR version.
    Validate {
        #[arg(value_name = "FILE")]
        file: PathBuf,
    },
    /// Output the canonical JSON representation of an IR file.
    Canonical {
        #[arg(value_name = "FILE")]
        file: PathBuf,
    },
    /// Output the SHA-256 hash of the canonical representation.
    Hash {
        #[arg(value_name = "FILE")]
        file: PathBuf,
    },
    /// Output the deserialized Rust AST for inspection.
    Ast {
        #[arg(value_name = "FILE")]
        file: PathBuf,
    },
}

/// Execute the selected CLI command.
pub fn run(cli: Cli) -> anyhow::Result<()> {
    match cli.command {
        Commands::Validate { file } => {
            let path = file
                .to_str()
                .ok_or_else(|| anyhow::anyhow!("Invalid file path"))?;
            let doc = parse_ir_file(path)?;
            println!("✅ Valid IR v{}", doc.ir_version);
            Ok(())
        }
        Commands::Canonical { file } => {
            let path = file
                .to_str()
                .ok_or_else(|| anyhow::anyhow!("Invalid file path"))?;
            let doc = parse_ir_file(path)?;
            let json = canonicalize(&doc)?;
            println!("{}", json);
            Ok(())
        }
        Commands::Hash { file } => {
            let path = file
                .to_str()
                .ok_or_else(|| anyhow::anyhow!("Invalid file path"))?;
            let doc = parse_ir_file(path)?;
            let hash = canonical_hash(&doc)?;
            println!("{}", hash);
            Ok(())
        }
        Commands::Ast { file } => {
            let path = file
                .to_str()
                .ok_or_else(|| anyhow::anyhow!("Invalid file path"))?;
            let doc = parse_ir_file(path)?;
            println!("{:#?}", doc);
            Ok(())
        }
    }
}
