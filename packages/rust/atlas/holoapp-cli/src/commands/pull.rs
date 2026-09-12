use anyhow::Result;
use colored::Colorize;
use hologram_app::{Config, HologramApp};
use indicatif::{ProgressBar, ProgressStyle};

pub async fn run(config: Config, model: &str) -> Result<()> {
    println!("{} Pulling {}...", "▶".green(), model.cyan());

    let app = HologramApp::new(config).await?;

    let mut rx = app.models().pull(model).await?;

    let pb = ProgressBar::new(100);
    pb.set_style(
        ProgressStyle::default_bar()
            .template("{spinner:.green} [{bar:40.cyan/blue}] {bytes}/{total_bytes} ({eta})")?
            .progress_chars("#>-"),
    );

    while let Ok(progress) = rx.recv().await {
        match progress.status.as_str() {
            "pulling manifest" => {
                pb.set_message("Fetching model info...");
            }
            "downloading" => {
                if let (Some(total), Some(completed)) = (progress.total, progress.completed) {
                    pb.set_length(total);
                    pb.set_position(completed);
                }
            }
            "compiling to .holo format" => {
                pb.finish_and_clear();
                println!("  {} Compiling model...", "⚙".yellow());
            }
            "success" => {
                pb.finish_and_clear();
                println!("{} Successfully pulled {}", "✓".green(), model.cyan());
            }
            status if status.starts_with("downloaded") => {
                pb.finish_and_clear();
                println!("{} {}", "✓".green(), status);
            }
            status if status.starts_with("error") => {
                pb.finish_and_clear();
                println!("{} {}", "✗".red(), status);
            }
            status => {
                pb.set_message(status.to_string());
            }
        }
    }

    Ok(())
}
