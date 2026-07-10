use anyhow::Result;
use colored::Colorize;
use dialoguer::Confirm;
use hologram_app::{Config, HologramApp};

pub async fn run(config: Config, model: &str, force: bool) -> Result<()> {
    let app = HologramApp::new(config).await?;

    if !app.models().exists(model) {
        println!("{} Model '{}' not found.", "✗".red(), model);
        return Ok(());
    }

    if !force {
        let confirm = Confirm::new()
            .with_prompt(format!("Remove model '{}'?", model))
            .default(false)
            .interact()?;

        if !confirm {
            println!("Cancelled.");
            return Ok(());
        }
    }

    app.models().delete(model).await?;
    println!("{} Removed {}", "✓".green(), model.cyan());

    Ok(())
}
