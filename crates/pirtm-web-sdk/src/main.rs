use clap::{Parser, Subcommand};
use std::process::Command;
use anyhow::{Context, Result};
use std::path::PathBuf;
use std::env;

#[derive(Parser)]
#[command(name = "pirtm-web")]
#[command(about = "Governed WebAssembly SDK and Component Builder for PIRTM", long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Build the Lean code into WebAssembly web components
    Build {
        /// Target environment (e.g., node, web)
        #[arg(short, long, default_value = "web")]
        target: String,
    },
    /// Run the compiled WASM via Node (for testing)
    Run,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    
    // Find the directory where lakefile.lean lives
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").unwrap_or_else(|_| ".".to_string());
    let sdk_dir = PathBuf::from(manifest_dir);

    match &cli.command {
        Commands::Build { target } => {
            println!("Building PIRTM Web Component (target: {})...", target);
            
            // Execute the lake build command via the underlying Lean toolchain
            let status = Command::new("lake")
                .arg("build")
                .current_dir(&sdk_dir)
                .status()
                .context("Failed to execute lake build. Ensure 'lake' and 'emcc' are in your PATH.")?;
                
            if !status.success() {
                anyhow::bail!("Lake build failed with status: {}", status);
            }
            
            println!("Successfully built WASM components in .lake/build/wasm/");
        }
        Commands::Run => {
            println!("Running compiled WebAssembly via Node.js...");
            let main_js = sdk_dir.join(".lake/build/wasm/main.js");
            
            if !main_js.exists() {
                anyhow::bail!("Compiled artifacts not found. Please run 'build' first.");
            }
            
            let status = Command::new("node")
                .arg(main_js)
                .current_dir(&sdk_dir)
                .status()
                .context("Failed to execute node. Ensure 'node' is in your PATH.")?;
                
            if !status.success() {
                anyhow::bail!("Node execution failed with status: {}", status);
            }
        }
    }

    Ok(())
}
