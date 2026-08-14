use anyhow::Result;
use colored::Colorize;
use hologram_app::{Config, HologramApp};

pub async fn run(config: Config) -> Result<()> {
    let app = HologramApp::new(config).await?;
    let models = app.models().list().await?;

    if models.is_empty() {
        println!("{} No models installed.", "ℹ".blue());
        println!("  Pull a model with: hologram pull meta-llama/Llama-3.2-1B");
        return Ok(());
    }

    // Print header
    println!(
        "{:<40} {:<15} {:<15} {}",
        "NAME".bold(),
        "SIZE".bold(),
        "MODIFIED".bold(),
        "ID".bold()
    );

    for model in models {
        let size = format_size(model.size);
        let modified = format_time(&model.modified_at);
        let id = &model.digest[7..19]; // Show short digest

        println!("{:<40} {:<15} {:<15} {}", model.name, size, modified, id);
    }

    Ok(())
}

fn format_size(bytes: u64) -> String {
    const KB: u64 = 1024;
    const MB: u64 = KB * 1024;
    const GB: u64 = MB * 1024;

    if bytes >= GB {
        format!("{:.1} GB", bytes as f64 / GB as f64)
    } else if bytes >= MB {
        format!("{:.1} MB", bytes as f64 / MB as f64)
    } else if bytes >= KB {
        format!("{:.1} KB", bytes as f64 / KB as f64)
    } else {
        format!("{} B", bytes)
    }
}

fn format_time(rfc3339: &str) -> String {
    use chrono::{DateTime, Utc};

    let dt = DateTime::parse_from_rfc3339(rfc3339)
        .map(|dt| dt.with_timezone(&Utc))
        .ok();

    match dt {
        Some(dt) => {
            let now = Utc::now();
            let duration = now.signed_duration_since(dt);

            if duration.num_days() > 30 {
                format!("{} months ago", duration.num_days() / 30)
            } else if duration.num_days() > 0 {
                format!("{} days ago", duration.num_days())
            } else if duration.num_hours() > 0 {
                format!("{} hours ago", duration.num_hours())
            } else if duration.num_minutes() > 0 {
                format!("{} minutes ago", duration.num_minutes())
            } else {
                "just now".to_string()
            }
        }
        None => "unknown".to_string(),
    }
}
