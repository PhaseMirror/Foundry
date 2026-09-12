use clap::Parser;
use drmm_ir_parser::cli;

fn main() -> anyhow::Result<()> {
    let cli = cli::Cli::parse();
    cli::run(cli)
}
