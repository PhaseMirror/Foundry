use anyhow::Result;
use colored::Colorize;
use hologram_app::{Config, HologramApp};

pub async fn run(config: Config) -> Result<()> {
    let app = HologramApp::new(config).await?;
    let processes = app.processes();
    let guard = processes.read().await;
    let ps = guard.list();

    if ps.models.is_empty() {
        println!("{} No models currently running.", "ℹ".blue());
        return Ok(());
    }

    // Print header
    println!(
        "{:<40} {:<15} {:<15} {}",
        "NAME".bold(),
        "SIZE".bold(),
        "EXPIRES".bold(),
        "ID".bold()
    );

    for model in ps.models {
        let size = format_size(model.size);
        let expires = format_time(&model.expires_at);
        let id = &model.digest[7..19];

        println!("{:<40} {:<15} {:<15} {}", model.name, size, expires, id);
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
            let duration = dt.signed_duration_since(now);

            if duration.num_seconds() < 0 {
                "expired".to_string()
            } else if duration.num_minutes() < 1 {
                "< 1 minute".to_string()
            } else {
                format!("{} minutes", duration.num_minutes())
            }
        }
        None => "unknown".to_string(),
    }
}
