use anyhow::{Context, Result};
use clap::{Parser, Subcommand, ValueEnum};
use kernel_core::{Report, ReportFormat, RuleSet, Validator};
use std::{fs, path::PathBuf};

#[derive(Parser)]
#[command(name = "kernel-cli")]
#[command(about = "ADR-governed kernel validation CLI")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    Validate { file: PathBuf },
    Report {
        file: PathBuf,
        #[arg(long, value_enum, default_value_t = OutputFormat::Text)]
        format: OutputFormat,
    },
    ScaffoldAdr {
        #[arg(long)]
        number: u16,
        #[arg(long)]
        title: String,
    },
}

#[derive(Copy, Clone, Eq, PartialEq, ValueEnum)]
enum OutputFormat {
    Json,
    Text,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        Commands::Validate { file } => {
            let contents = fs::read_to_string(&file).with_context(|| format!("reading {}", file.display()))?;
            let rules = RuleSet::parse(&contents)?;
            let result = Validator::validate(&rules);
            if result.admissible {
                println!("VALID");
                Ok(())
            } else {
                println!("INVALID");
                for issue in result.issues {
                    println!("[{}] {}", issue.code, issue.message);
                }
                std::process::exit(2)
            }
        }
        Commands::Report { file, format } => {
            let contents = fs::read_to_string(&file).with_context(|| format!("reading {}", file.display()))?;
            let rules = RuleSet::parse(&contents)?;
            let result = Validator::validate(&rules);
            let report = Report::from_validation(result);
            let rendered = report.render(match format {
                OutputFormat::Json => ReportFormat::Json,
                OutputFormat::Text => ReportFormat::Text,
            })?;
            println!("{}", rendered);
            Ok(())
        }
        Commands::ScaffoldAdr { number, title } => {
            let slug = title.to_lowercase().replace(' ', "-");
            let path = format!("docs/adr/{:04}-{}.md", number, slug);
            let body = format!("# {:04}. {}\n\nDate: YYYY-MM-DD\n\n## Status\nProposed\n\n## Context\n\n## Decision\n\n## Consequences\n", number, title);
            fs::write(&path, body).with_context(|| format!("writing {path}"))?;
            println!("created {}", path);
            Ok(())
        }
    }
}

#[cfg(test)]
mod tests {
    use assert_cmd::Command;
    use predicates::prelude::*;

    #[test]
    fn validate_valid_fixture() {
        let mut cmd = Command::cargo_bin("kernel-cli").unwrap();
        cmd.arg("validate").arg("tests/fixtures/valid.rules");
        cmd.assert().success().stdout(predicate::str::contains("VALID"));
    }
}
