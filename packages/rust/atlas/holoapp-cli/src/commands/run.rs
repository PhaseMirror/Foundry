use anyhow::Result;
use colored::Colorize;
use dialoguer::Input;
use hologram_app::{Config, HologramApp};

pub async fn run(config: Config, model: &str, prompt: Option<&str>) -> Result<()> {
    let app = HologramApp::new(config).await?;

    // Check if model exists
    if !app.models().exists(model) {
        println!(
            "{} Model '{}' not found. Pull it first with: hologram pull {}",
            "✗".red(),
            model,
            model
        );
        return Ok(());
    }

    if let Some(prompt) = prompt {
        // Non-interactive mode
        run_single_prompt(&app, model, prompt).await?;
    } else {
        // Interactive mode
        run_interactive(&app, model).await?;
    }

    Ok(())
}

async fn run_single_prompt(app: &HologramApp, model: &str, prompt: &str) -> Result<()> {
    let request = hologram_app::ChatRequest {
        model: model.to_string(),
        messages: vec![hologram_app::Message {
            role: "user".to_string(),
            content: prompt.to_string(),
            images: None,
        }],
        stream: false,
        format: None,
        options: None,
        keep_alive: None,
    };

    let response = app.chat().complete(request).await?;
    println!("{}", response.message.content);

    Ok(())
}

async fn run_interactive(app: &HologramApp, model: &str) -> Result<()> {
    println!(
        "{} Running {} interactively. Type 'exit' or Ctrl+C to quit.",
        "▶".green(),
        model.cyan()
    );
    println!();

    let mut messages: Vec<hologram_app::Message> = vec![];

    loop {
        let input: String = Input::new()
            .with_prompt(">>>")
            .allow_empty(false)
            .interact_text()?;

        let input = input.trim();

        if input.eq_ignore_ascii_case("exit") || input.eq_ignore_ascii_case("quit") {
            break;
        }

        // Handle multiline input (triple quotes)
        let prompt = if input.starts_with("\"\"\"") {
            let mut lines = vec![input.trim_start_matches("\"\"\"").to_string()];
            loop {
                let line: String = Input::new()
                    .with_prompt("...")
                    .allow_empty(true)
                    .interact_text()?;
                if line.ends_with("\"\"\"") {
                    lines.push(line.trim_end_matches("\"\"\"").to_string());
                    break;
                }
                lines.push(line);
            }
            lines.join("\n")
        } else {
            input.to_string()
        };

        messages.push(hologram_app::Message {
            role: "user".to_string(),
            content: prompt,
            images: None,
        });

        let request = hologram_app::ChatRequest {
            model: model.to_string(),
            messages: messages.clone(),
            stream: false,
            format: None,
            options: None,
            keep_alive: None,
        };

        match app.chat().complete(request).await {
            Ok(response) => {
                println!();
                println!("{}", response.message.content);
                println!();

                messages.push(hologram_app::Message {
                    role: "assistant".to_string(),
                    content: response.message.content,
                    images: None,
                });
            }
            Err(e) => {
                println!("{} Error: {}", "✗".red(), e);
            }
        }
    }

    println!("Goodbye!");
    Ok(())
}
