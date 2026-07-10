use clap::Parser;
use hcalc_rs::{classify_terminal_state, HCalcInput};
use std::fs;
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Path to the input JSON file
    #[arg(short, long)]
    input: PathBuf,

    /// Output the result as JSON
    #[arg(short, long)]
    json: bool,
}

fn main() {
    let args = Args::parse();

    let input_str = fs::read_to_string(args.input).expect("Failed to read input file");
    let input: HCalcInput = serde_json::from_str(&input_str).expect("Failed to parse input JSON");

    let result = classify_terminal_state(&input, None);

    if args.json {
        println!("{}", serde_json::to_string_pretty(&result).unwrap());
    } else {
        println!("Terminal State: {}", result.state);
        println!("Reason: {}", result.reason);
        println!("Contraction Witness Q: {:.4}", result.contraction_witness_q);
        println!("Top-K Concentration: {:.4}", result.top_k_concentration);
    }
}
