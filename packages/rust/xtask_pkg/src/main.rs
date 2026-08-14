use anyhow::{bail, Result};
use clap::{Parser, Subcommand};
use std::process::Command;

#[derive(Parser)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Ci,
    Test,
    Lint,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        Commands::Ci => run_all(["fmt --all -- --check", "clippy --workspace --all-targets --all-features -- -D warnings", "test --workspace"]),
        Commands::Test => run("cargo", &["test", "--workspace"]),
        Commands::Lint => run_all(["fmt --all -- --check", "clippy --workspace --all-targets --all-features -- -D warnings"]),
    }
}

fn run_all<const N: usize>(commands: [&str; N]) -> Result<()> {
    for command in commands {
        let parts: Vec<&str> = command.split_whitespace().collect();
        run("cargo", &parts)?;
    }
    Ok(())
}

fn run(program: &str, args: &[&str]) -> Result<()> {
    let status = Command::new(program).args(args).status()?;
    if !status.success() {
        bail!("command failed: {} {:?}", program, args);
    }
    Ok(())
}
