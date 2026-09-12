use anyhow::Result;
use colored::Colorize;
use hologram_app::Config;

pub async fn run(mut config: Config, host: String, port: u16) -> Result<()> {
    // Update config with CLI arguments
    config.server.host = host;
    config.server.port = port;

    println!(
        "{} Starting Hologram server...",
        "▶".green()
    );
    println!(
        "  {} http://{}",
        "Listening on:".dimmed(),
        config.server_addr()
    );
    println!(
        "  {} {}",
        "Models directory:".dimmed(),
        config.storage.models_dir.display()
    );
    println!();

    // Start the server
    hologram_app::server::run(config).await?;

    Ok(())
}
