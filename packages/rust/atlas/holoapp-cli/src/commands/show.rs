use anyhow::Result;
use colored::Colorize;
use hologram_app::{Config, HologramApp};

pub async fn run(config: Config, model: &str) -> Result<()> {
    let app = HologramApp::new(config).await?;

    match app.models().show(model).await {
        Ok(info) => {
            println!("{}: {}", "Model".bold(), model.cyan());
            println!();
            println!("{}", "Details:".bold());
            println!("  Format:        {}", info.details.format);
            println!("  Family:        {}", info.details.family);
            println!("  Parameter Size: {}", info.details.parameter_size);
            println!("  Quantization:  {}", info.details.quantization_level);
            println!();
            println!("{}", "Modelfile:".bold());
            println!("{}", info.modelfile.dimmed());
        }
        Err(e) => {
            println!("{} {}", "✗".red(), e);
        }
    }

    Ok(())
}
