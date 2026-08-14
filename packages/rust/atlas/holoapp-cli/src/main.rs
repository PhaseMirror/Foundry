use anyhow::Result;
use clap::Parser;
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

mod cli;
mod commands;

use cli::{Cli, Commands};

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize logging
    tracing_subscriber::registry()
        .with(fmt::layer())
        .with(EnvFilter::from_default_env().add_directive(tracing::Level::INFO.into()))
        .init();

    let cli = Cli::parse();

    // Determine home directory
    let home_dir = cli.home.unwrap_or_else(|| {
        dirs::home_dir()
            .unwrap_or_else(|| std::path::PathBuf::from("."))
            .join(".hologram")
    });

    let config = hologram_app::Config::from_home_dir(home_dir);

    match cli.command {
        Commands::Serve { host, port } => {
            commands::serve::run(config, host, port).await
        }
        Commands::Run { model, prompt } => {
            commands::run::run(config, &model, prompt.as_deref()).await
        }
        Commands::Pull { model } => {
            commands::pull::run(config, &model).await
        }
        Commands::List => {
            commands::list::run(config).await
        }
        Commands::Ps => {
            commands::ps::run(config).await
        }
        Commands::Rm { model, force } => {
            commands::rm::run(config, &model, force).await
        }
        Commands::Show { model } => {
            commands::show::run(config, &model).await
        }
        Commands::Stop { model } => {
            commands::stop::run(config, &model).await
        }
    }
}
