//! CLI mirror of `core/scripts/nl_to_pirtm.py`.
//!
//! Usage: `nl-to-pirtm '<natural language requirement>'`

use core_transpiler::PirtmTranspiler;
use std::env;

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    if args.is_empty() {
        eprintln!("Usage: nl-to-pirtm '<natural language requirement>'");
        std::process::exit(1);
    }
    let nl_input = args.join(" ");
    let mut transpiler = PirtmTranspiler::new();
    transpiler.parse_nl(&nl_input);

    println!("--- PIRTM Transpiler Output (Ring 0.5 ISA) ---");
    println!("Input: {nl_input}");
    println!("\n[MLIR Dialect]");
    println!("{}", transpiler.emit_mlir("generated_module"));

    println!("\n[Dual-Hash Witness]");
    let witness = transpiler.emit_witness();
    println!("SHA256:  {}", witness.sha256);
    println!("Poseidon: {}", witness.poseidon);
}