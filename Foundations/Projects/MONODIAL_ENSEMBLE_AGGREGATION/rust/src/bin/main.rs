//! MEA CLI entry point.
//!
//! Provides command-line interface for monodial ensemble aggregation
//! operations and verification.

use monodial_ensemble_aggregation::{
    error::Result,
    ensemble::{Ensemble, WeightedElement},
    aggregate::{AggregateOp, aggregate},
    verify::{AlgebraicLaw, verify_law, verify_all_laws},
    monodial::MonoidalCategory,
};
use std::env;

fn print_usage() {
    println!("MEA — Monodial Ensemble Aggregation");
    println!();
    println!("USAGE:");
    println!("    mea-cli <command> [arguments]");
    println!();
    println!("COMMANDS:");
    println!("    aggregate <op> <values...>   Aggregate values (sum, avg, max, min)");
    println!("    verify                       Verify algebraic laws");
    println!("    monodial                     Show monoidal category info");
    println!("    help                         Show this help message");
}

fn aggregate_cmd(args: &[&str]) -> Result<()> {
    if args.is_empty() {
        return Err(monodial_ensemble_aggregation::Error::configuration("missing operation"));
    }
    let op = match args[0] {
        "sum" => AggregateOp::Sum,
        "avg" | "average" => AggregateOp::WeightedAverage,
        "max" => AggregateOp::Max,
        "min" => AggregateOp::Min,
        _ => return Err(monodial_ensemble_aggregation::Error::configuration("unknown operation")),
    };

    let mut ensemble: Ensemble<i32> = Ensemble::new(1);
    for (i, &arg) in args[1..].iter().enumerate() {
        let value: i32 = arg.parse().map_err(|_| monodial_ensemble_aggregation::Error::configuration("invalid value"))?;
        let weight = 1.0 / (args[1..].len() as f64);
        ensemble.add(WeightedElement::new(value, weight));
    }

    let result = aggregate(&ensemble, op)?;
    println!("Aggregation result: {} (confidence: {})", result.value(), result.confidence());
    Ok(())
}

fn verify_cmd(_args: &[&str]) -> Result<()> {
    let mut a: Ensemble<i32> = Ensemble::new(1);
    a.add(WeightedElement::new(1, 1.0));
    let mut b: Ensemble<i32> = Ensemble::new(2);
    b.add(WeightedElement::new(2, 1.0));
    let mut c: Ensemble<i32> = Ensemble::new(3);
    c.add(WeightedElement::new(3, 1.0));

    let results = verify_all_laws(&[a, b, c]);
    for result in &results {
        println!("{}: {}", result.law().name(), if result.passed() { "PASS" } else { "FAIL" });
    }
    Ok(())
}

fn monodial_cmd(_args: &[&str]) -> Result<()> {
    let cat = MonoidalCategory::new(0);
    println!("Monoidal category with unit object: {}", cat.unit_id());
    println!("Objects: {}", cat.objects().len());
    println!("Morphisms: {}", cat.morphisms().len());
    Ok(())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        print_usage();
        std::process::exit(1);
    }

    let command = args[1].as_str();
    let rest = &args[2..];
    let rest_strs: Vec<&str> = rest.iter().map(|s| s.as_str()).collect();

    let result = match command {
        "help" | "--help" | "-h" => {
            print_usage();
            Ok(())
        }
        "aggregate" => aggregate_cmd(&rest_strs),
        "verify" => verify_cmd(&rest_strs),
        "monodial" => monodial_cmd(&rest_strs),
        _ => {
            eprintln!("Unknown command: {}", command);
            print_usage();
            std::process::exit(1);
        }
    };

    if let Err(e) = result {
        eprintln!("Error: {}", e);
        std::process::exit(1);
    }
}
