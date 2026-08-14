use clap::{Parser, Subcommand};
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "hologram")]
#[command(author, version, about = "Run local LLMs with Ollama-compatible APIs")]
#[command(propagate_version = true)]
pub struct Cli {
    /// Home directory for Hologram data
    #[arg(long, global = true, env = "HOLOGRAM_HOME")]
    pub home: Option<PathBuf>,

    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Start the Hologram API server
    Serve {
        /// Host address to bind to
        #[arg(long, default_value = "127.0.0.1")]
        host: String,

        /// Port to listen on
        #[arg(short, long, default_value = "11434")]
        port: u16,
    },

    /// Run a model interactively
    Run {
        /// Model name (e.g., meta-llama/Llama-3.2-1B)
        model: String,

        /// Optional prompt (non-interactive mode)
        #[arg(long)]
        prompt: Option<String>,
    },

    /// Pull a model from HuggingFace
    Pull {
        /// Model name (e.g., meta-llama/Llama-3.2-1B)
        model: String,
    },

    /// List available models
    #[command(alias = "ls")]
    List,

    /// Show running models
    Ps,

    /// Remove a model
    Rm {
        /// Model name to remove
        model: String,

        /// Force removal without confirmation
        #[arg(long, short)]
        force: bool,
    },

    /// Show model information
    Show {
        /// Model name
        model: String,
    },

    /// Stop a running model
    Stop {
        /// Model name to stop
        model: String,
    },
}
