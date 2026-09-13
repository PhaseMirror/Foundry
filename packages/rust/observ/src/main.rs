//! observ CLI — the ADR-0022…0028 observability gate driver.
//!
//! Subcommands:
//! - `measure <program.json> [--out <dir>]` — run the gate; writes
//!   `verdict.json` and `receipt.json`; prints Δ in English.
//! - `verify <program.json>` — lawfulness only, no artifacts.
//! - `version` — kernel and verification status (hygiene gate).
//!
//! Exit codes: 0 = lawful measurement; 2 = kill; 1 = usage/IO; 3 =
//! serialization.

use std::env;
use std::fs;
use std::path::Path;
use std::process;

use observ::kernel::{self, ObservVerdict};
use observ::system::{validate, MeasurementProgram};
use observ::KERNEL_VERSION;

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
        "measure" => cmd_measure(&args),
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
        "observ kernel {} | wire version 0x{:04X} | kani harnesses: {} (this build verified: {}) | lean mirror: pending",
        KERNEL_VERSION,
        observ::system::WIRE_VERSION,
        observ::receipt::KANI_HARNESSES.len(),
        cfg!(kani),
    );
}

fn cmd_measure(args: &[String]) {
    let program = parse_args("measure", args);
    if let Err(e) = validate(&program) {
        eprintln!("[ERROR] program validation failed: {e}");
        process::exit(EXIT_UNLAWFUL);
    }
    let verdict = kernel::Kernel::new().measure(&program);

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
    let program = parse_args("verify", args);
    if let Err(e) = validate(&program) {
        eprintln!("[ERROR] program validation failed: {e}");
        process::exit(EXIT_UNLAWFUL);
    }
    let kernel = kernel::Kernel::new();
    let (defects, expansive) = kernel.laws(&program);
    if defects.is_empty() && !expansive {
        println!(
            "[OK] observability lawfulness holds: Δ = ∅, pipeline within lockdown ({} stages, dim {})",
            program.stages.len(),
            program.dim
        );
    } else {
        println!(
            "[UNLAWFUL] Δ ≠ ∅: {} named defect(s), expansive={}",
            defects.len(),
            expansive
        );
        for d in &defects {
            println!(
                "  - {} (metric {}): {}",
                code_name(d.code),
                d.metric,
                d.english
            );
        }
        process::exit(EXIT_UNLAWFUL);
    }
}

fn code_name(code: observ::DefectCode) -> String {
    format!("{code:?}")
}

fn parse_args(subcommand: &str, args: &[String]) -> MeasurementProgram {
    let program_path = args
        .iter()
        .skip(2)
        .find(|a| !a.starts_with("--"))
        .map(|s| s.as_str())
        .unwrap_or_else(|| {
            eprintln!("[ERROR] {subcommand} requires <program.json>");
            process::exit(EXIT_USAGE);
        });

    let contents = match fs::read_to_string(program_path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("[ERROR] failed to read {}: {e}", program_path);
            process::exit(EXIT_USAGE);
        }
    };

    match serde_json::from_str::<MeasurementProgram>(&contents) {
        Ok(program) => program,
        Err(e) => {
            eprintln!("[ERROR] program JSON parse failed: {e}");
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

fn write_artifacts(out_dir: &str, verdict: &ObservVerdict) {
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

fn print_delta(verdict: &ObservVerdict) {
    if verdict.signal.is_kill() {
        println!("[KILL] Δ ≠ ∅ — closure withheld.");
        for d in &verdict.defects {
            println!(
                "  Δ ({}): {} [owner {}] metric={}",
                code_name(d.code),
                d.english,
                d.owner,
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
        println!(
            "[OK] Δ = 0 — observability lawfulness holds over {} stage(s); {} targets identified.",
            verdict.filtration.len(),
            verdict
                .targets
                .iter()
                .filter(|t| t.obstruction_dim == 0)
                .count()
        );
    }
}

fn usage() -> ! {
    eprintln!(
        "usage: observ <measure|verify|version> <program.json> [--out <dir>]\n\
         exit codes: 0 lawful, 2 kill, 1 usage/io, 3 serialization"
    );
    process::exit(EXIT_USAGE);
}
