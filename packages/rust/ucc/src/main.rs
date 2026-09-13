//! UCC CLI — ADR-0014 Q0 gate driver.
//!
//! Subcommands:
//! - `close <system.json> [--out <dir>]` — run the L0 gate; writes
//!   `verdict.json` and `receipt.json`; prints Δ in English.
//! - `verify <system.json>` — lawfulness only, no artifacts.
//! - `version` — kernel and verification status (hygiene gate).
//!
//! Exit codes: 0 = lawful close; 2 = unlawful (kill); 1 = usage/IO; 3 =
//! serialization.

use std::env;
use std::fs;
use std::path::Path;
use std::process;

use ucc::kernel::{Kernel, UccVerdict};
use ucc::system::SystemInput;
use ucc::KERNEL_VERSION;

const EXIT_LAWFUL: i32 = 0;
const EXIT_UNLAWFUL: i32 = 2;
const EXIT_USAGE: i32 = 1;
const EXIT_SERIALIZE: i32 = 3;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        usage();
    }

    match args[1].as_str() {
        "version" => cmd_version(),
        "close" => cmd_close(&args),
        "verify" => cmd_verify(&args),
        "-h" | "--help" => usage(),
        other => {
            eprintln!("[ERROR] unknown subcommand: {other}");
            usage();
        }
    }
}

fn cmd_version() {
    println!(
        "ucc kernel {} | lawful_recursion_version {} | kani harnesses: {} (this build verified: {}) | lean mirror: pending",
        KERNEL_VERSION,
        ucc::system::LAWFUL_RECURSION_VERSION,
        ucc::receipt::KANI_HARNESSES.len(),
        cfg!(kani),
    );
}

fn cmd_close(args: &[String]) {
    let input = parse_args("close", args);
    let verdict = Kernel::new().close(&input);

    if let Some(out_dir) = find_flag(args, "--out") {
        write_artifacts(out_dir, &verdict);
    } else {
        let pretty = serde_json::to_string_pretty(&verdict).expect("verdict serializes");
        println!("{pretty}");
    }

    print_delta(&verdict);

    process::exit(if verdict.signal.is_kill() {
        EXIT_UNLAWFUL
    } else {
        EXIT_LAWFUL
    });
}

fn cmd_verify(args: &[String]) {
    let input = parse_args("verify", args);
    let kernel = Kernel::new();
    let (defects, expansive) = kernel.laws(&input);
    if defects.is_empty() && !expansive {
        println!(
            "[OK] lawfulness holds: Δ = ∅, Λ_m contractive ({} nodes, {} relations)",
            input.x.len(),
            input.relations.len()
        );
    } else {
        println!(
            "[UNLAWFUL] Δ ≠ ∅: {} named defect(s), expansive={}",
            defects.len(),
            expansive
        );
        for d in &defects {
            println!("  - {} (metric {}): {}", code_name(d.code), d.metric, d.english);
        }
        process::exit(EXIT_UNLAWFUL);
    }
}

fn code_name(code: ucc::DefectCode) -> String {
    format!("{code:?}")
}

fn parse_args(subcommand: &str, args: &[String]) -> SystemInput {
    let system_path = args
        .iter()
        .skip(2)
        .find(|a| !a.starts_with("--"))
        .map(|s| s.as_str())
        .unwrap_or_else(|| {
            eprintln!("[ERROR] {subcommand} requires <system.json>");
            process::exit(EXIT_USAGE);
        });

    let contents = match fs::read_to_string(system_path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("[ERROR] failed to read {}: {e}", system_path);
            process::exit(EXIT_USAGE);
        }
    };

    match serde_json::from_str::<SystemInput>(&contents) {
        Ok(input) => input,
        Err(e) => {
            eprintln!("[ERROR] system JSON parse failed: {e}");
            process::exit(EXIT_SERIALIZE);
        }
    }
}

fn find_flag<'a>(args: &'a [String], flag: &str) -> Option<&'a str> {
    args.iter()
        .position(|a| a == flag)
        .and_then(|i| args.get(i + 1))
        .map(|s| s.as_str())
}

fn write_artifacts(out_dir: &str, verdict: &UccVerdict) {
    let dir = Path::new(out_dir);
    if let Err(e) = fs::create_dir_all(dir) {
        eprintln!("[ERROR] cannot create {}: {e}", dir.display());
        process::exit(EXIT_USAGE);
    }
    write_json(dir, "verdict.json", &verdict);
    write_json(dir, "receipt.json", &verdict.receipt);
}

fn write_json(dir: &Path, name: &str, value: &impl serde::Serialize) {
    let path = dir.join(name);
    match serde_json::to_string_pretty(value) {
        Ok(pretty) => {
            if let Err(e) = fs::write(&path, pretty) {
                eprintln!("[ERROR] cannot write {}: {e}", path.display());
                process::exit(EXIT_USAGE);
            }
            println!("[WROTE] {}", path.display());
        }
        Err(e) => {
            eprintln!("[ERROR] serialization failed: {e}");
            process::exit(EXIT_SERIALIZE);
        }
    }
}

fn print_delta(verdict: &UccVerdict) {
    if verdict.signal.is_kill() {
        println!("[KILL] Δ ≠ ∅ — closure withheld.");
        for d in &verdict.defects {
            println!(
                "  Δ ({}): {} [affected: {:?}] ‖Δ‖={}",
                code_name(d.code),
                d.english,
                d.nodes,
                d.metric
            );
        }
        if !verdict.levers.is_empty() {
            println!("  levers:");
            for l in &verdict.levers {
                println!(
                    "    [{}] {} | metric {} | {}",
                    l.owner, l.action, l.metric, l.horizon
                );
            }
        }
    } else {
        let closure = verdict.closure.as_ref().expect("nominal closes");
        println!("[OK] Δ = 0 — lawfulness holds; closure computed.");
        for c in &closure.components {
            println!(
                "  component {} = {}", c.canonical_label(), c.label
            );
        }
        println!(
            "  Λ_m scaled = {} (contractive: {})",
            closure.lambda_m_scaled,
            closure.lambda_m_scaled < crmf::failgate::CONTRACTIVITY_SCALE
        );
    }
}

fn usage() -> ! {
    eprintln!(
        "usage: ucc <close|verify|version> <system.json> [--out <dir>]\n\
         exit codes: 0 lawful, 2 unlawful (kill), 1 usage/io, 3 serialization"
    );
    process::exit(EXIT_USAGE);
}