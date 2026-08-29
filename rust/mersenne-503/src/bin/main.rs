//! MERSENNE_503 CLI entry point.
//!
//! Provides command-line interface for Mersenne prime operations,
//! Leech lattice constructions, and formal verification.

use mersenne_503::{
    error::Result,
    mersenne::Mersenne503,
    leech::LeechLattice,
    tensor::TensorField,
    psl2r::MobiusTransform,
    ads::AdSCoord,
    bayesian::{CrystalLattice, CrystalPoint},
    crypto::ZenoLock,
};
use std::env;

fn print_usage() {
    println!("MERSENNE_503 — Formal Verification Framework");
    println!();
    println!("USAGE:");
    println!("    m503 <command> [arguments]");
    println!();
    println!("COMMANDS:");
    println!("    mersenne <value>             Test Mersenne503 field operations");
    println!("    leech                        Test Leech lattice construction");
    println!("    tensor <beta>                Compute tensor contraction");
    println!("    psl2r <a> <b> <c> <d>       Test PSL(2,R) transformation");
    println!("    ads <t> <r>                  Compute AdS interval");
    println!("    entropy                      Compute Shannon entropy");
    println!("    crypto <depth>               Test Zeno lock");
    println!("    help                         Show this help message");
}

fn mersenne_cmd(args: &[&str]) -> Result<()> {
    if args.is_empty() {
        return Err(mersenne_503::Error::configuration("missing value"));
    }
    let value: u64 = args[0].parse().map_err(|_| mersenne_503::Error::configuration("invalid value"))?;
    let m = Mersenne503::new(value);
    println!("Mersenne503({}) = {:?}", value, m.limb(0));
    Ok(())
}

fn leech_cmd(_args: &[&str]) -> Result<()> {
    let coords = [2i32; 24];
    let lattice = LeechLattice::new(coords);
    println!("Leech lattice dimension: {}", lattice.dim());
    println!("Norm squared: {}", lattice.norm_sq());
    println!("Is valid: {}", lattice.is_valid());
    Ok(())
}

fn tensor_cmd(args: &[&str]) -> Result<()> {
    if args.is_empty() {
        return Err(mersenne_503::Error::configuration("missing beta"));
    }
    let beta: f64 = args[0].parse().map_err(|_| mersenne_503::Error::configuration("invalid beta"))?;
    let coeffs = vec![
        mersenne_503::TensorCoeff::new(2, 1),
        mersenne_503::TensorCoeff::new(3, 1),
        mersenne_503::TensorCoeff::new(5, 1),
    ];
    let field = TensorField::new(coeffs, 10);
    let result = field.contract(beta)?;
    println!("Tensor contraction at beta={}: {}", beta, result);
    Ok(())
}

fn psl2r_cmd(args: &[&str]) -> Result<()> {
    if args.len() < 4 {
        return Err(mersenne_503::Error::configuration("usage: psl2r <a> <b> <c> <d>"));
    }
    let a: i64 = args[0].parse().map_err(|_| mersenne_503::Error::configuration("invalid a"))?;
    let b: i64 = args[1].parse().map_err(|_| mersenne_503::Error::configuration("invalid b"))?;
    let c: i64 = args[2].parse().map_err(|_| mersenne_503::Error::configuration("invalid c"))?;
    let d: i64 = args[3].parse().map_err(|_| mersenne_503::Error::configuration("invalid d"))?;
    let transform = MobiusTransform::new(a, b, c, d)?;
    let (re, im) = transform.apply(1.0, 0.0);
    println!("Mobius transform applied: ({}, {})", re, im);
    Ok(())
}

fn ads_cmd(args: &[&str]) -> Result<()> {
    if args.len() < 2 {
        return Err(mersenne_503::Error::configuration("usage: ads <t> <r>"));
    }
    let t: i64 = args[0].parse().map_err(|_| mersenne_503::Error::configuration("invalid t"))?;
    let r: i64 = args[1].parse().map_err(|_| mersenne_503::Error::configuration("invalid r"))?;
    let coord = AdSCoord::new(t, r, 0);
    println!("AdS interval: {}", coord.interval());
    println!("Is bulk: {}", coord.is_bulk());
    Ok(())
}

fn entropy_cmd(_args: &[&str]) -> Result<()> {
    let points = vec![
        CrystalPoint::new(0, 1, 5),
        CrystalPoint::new(1, 2, 5),
        CrystalPoint::new(2, 1, 5),
        CrystalPoint::new(3, 2, 5),
    ];
    let lattice = CrystalLattice::new(points, 2);
    println!("Shannon entropy: {}", lattice.shannon_entropy());
    println!("Is crystallized: {}", lattice.is_crystallized(1.0));
    Ok(())
}

fn crypto_cmd(args: &[&str]) -> Result<()> {
    if args.is_empty() {
        return Err(mersenne_503::Error::configuration("missing depth"));
    }
    let depth: usize = args[0].parse().map_err(|_| mersenne_503::Error::configuration("invalid depth"))?;
    let mut lock = ZenoLock::new(depth);
    lock.set_commitment(0, 1024).unwrap();
    for i in 1..depth {
        let prev = lock.get_commitment(i - 1).unwrap();
        lock.set_commitment(i, prev / 2).unwrap();
    }
    println!("Zeno lock verified: {}", lock.verify());
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
        "mersenne" => mersenne_cmd(&rest_strs),
        "leech" => leech_cmd(&rest_strs),
        "tensor" => tensor_cmd(&rest_strs),
        "psl2r" => psl2r_cmd(&rest_strs),
        "ads" => ads_cmd(&rest_strs),
        "entropy" => entropy_cmd(&rest_strs),
        "crypto" => crypto_cmd(&rest_strs),
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
