//! CLI command parsing, canonical machine output, and stable exit classes.

use crate::controller::{BuildRequest, CheckRequest, CleanRequest, Controller, VerifyRequest};
use crate::error::PrismError;
use crate::holo::canonical::encode_value;
use clap::{Parser, Subcommand};
use serde::Serialize;
use serde_json::json;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

/// The Prism Platform Model CLI.
#[derive(Parser, Debug)]
#[command(name = "prismpm", version, about = "Prism Platform Model Framework")]
pub struct Cli {
    /// Optional project path (defaults to current directory).
    #[arg(short, long, global = true)]
    pub project: Option<PathBuf>,

    /// Optional confined project configuration path.
    #[arg(long, global = true)]
    pub config: Option<PathBuf>,

    /// Emit exactly one canonical JSON value.
    #[arg(long, global = true)]
    pub json: bool,

    /// Subcommand to execute.
    #[command(subcommand)]
    pub command: Commands,
}

/// Available CLI subcommands.
#[derive(Subcommand, Debug)]
pub enum Commands {
    /// Check project static validity without filesystem modification.
    Check,
    /// Build project artifacts and publish under .prism/build/<id>.
    Build,
    /// Verify model through Lean, leanchecker, LCNF, and generated Rust.
    Verify,
    /// Remove only the configured Prism output root.
    Clean,
}

fn canonical<T: Serialize>(value: &T) -> Result<Vec<u8>, PrismError> {
    let value = serde_json::to_value(value)
        .map_err(|error| PrismError::new("PP9001", format!("serialize CLI result: {error}")))?;
    encode_value(&value)
}

fn write_line(mut stream: impl Write, bytes: &[u8]) -> Result<(), PrismError> {
    stream
        .write_all(bytes)
        .and_then(|()| stream.write_all(b"\n"))
        .map_err(|error| PrismError::new("PP9001", format!("write CLI output: {error}")))
}

fn execute(cli: &Cli) -> Result<(serde_json::Value, String), PrismError> {
    let root = cli.project.as_deref().unwrap_or_else(|| Path::new("."));
    let controller = Controller::load(root)?;
    match cli.command {
        Commands::Check => {
            let result = controller.check(CheckRequest {
                config_path: cli.config.clone(),
            })?;
            let human = format!("check passed (semantic ID: {})", result.semantic_id);
            Ok((
                serde_json::to_value(result)
                    .map_err(|error| PrismError::new("PP9001", error.to_string()))?,
                human,
            ))
        }
        Commands::Build => {
            let result = controller.build(BuildRequest {
                config_path: cli.config.clone(),
            })?;
            let human = format!("build published: {}", result.build_id);
            Ok((
                serde_json::to_value(result)
                    .map_err(|error| PrismError::new("PP9001", error.to_string()))?,
                human,
            ))
        }
        Commands::Verify => {
            let result = controller.verify(VerifyRequest {
                config_path: cli.config.clone(),
            })?;
            let human = format!("verified attestation: {}", result.attestation_id);
            Ok((
                serde_json::to_value(result)
                    .map_err(|error| PrismError::new("PP9001", error.to_string()))?,
                human,
            ))
        }
        Commands::Clean => {
            let result = controller.clean(CleanRequest {
                config_path: cli.config.clone(),
            })?;
            Ok((
                serde_json::to_value(result)
                    .map_err(|error| PrismError::new("PP9001", error.to_string()))?,
                "Prism output removed".to_owned(),
            ))
        }
    }
}

/// Parse process arguments, execute one command, and emit stable output.
#[must_use]
pub fn run() -> ExitCode {
    let machine_requested = std::env::args().any(|argument| argument == "--json");
    let cli = match Cli::try_parse() {
        Ok(cli) => cli,
        Err(error) => {
            if machine_requested {
                let diagnostic = PrismError::new("PP1001", error.to_string());
                let envelope =
                    json!({"diagnostic": diagnostic, "schema": "prismpm/error-result/1"});
                let bytes = canonical(&envelope)
                    .unwrap_or_else(|_| b"{\"schema\":\"prismpm/error-result/1\"}".to_vec());
                let _ = write_line(std::io::stdout().lock(), &bytes);
                return ExitCode::from(2);
            }
            let _ = error.print();
            return ExitCode::from(2);
        }
    };

    match execute(&cli) {
        Ok((value, human)) => {
            let result = if cli.json {
                canonical(&value).and_then(|bytes| write_line(std::io::stdout().lock(), &bytes))
            } else {
                write_line(std::io::stdout().lock(), human.as_bytes())
            };
            match result {
                Ok(()) => ExitCode::SUCCESS,
                Err(error) => ExitCode::from(error.exit_code()),
            }
        }
        Err(error) => {
            let exit = error.exit_code();
            if cli.json {
                let envelope = json!({"diagnostic": error, "schema": "prismpm/error-result/1"});
                match canonical(&envelope) {
                    Ok(bytes) => {
                        let _ = write_line(std::io::stdout().lock(), &bytes);
                    }
                    Err(fallback) => {
                        let _ = writeln!(std::io::stderr().lock(), "{fallback}");
                    }
                }
            } else {
                let _ = writeln!(std::io::stderr().lock(), "{error}");
            }
            ExitCode::from(exit)
        }
    }
}
