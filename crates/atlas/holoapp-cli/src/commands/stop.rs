use anyhow::Result;
use colored::Colorize;
use hologram_app::{Config, HologramApp};

pub async fn run(config: Config, model: &str) -> Result<()> {
    let app = HologramApp::new(config).await?;
    let processes = app.processes();
    let mut guard = processes.write().await;

    match guard.stop(model) {
        Ok(()) => {
            println!("{} Stopped {}", "✓".green(), model.cyan());
        }
        Err(e) => {
            println!("{} {}", "✗".red(), e);
        }
    }

    Ok(())
}
