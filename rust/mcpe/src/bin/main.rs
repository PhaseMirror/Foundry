//! MCPE CLI entry point.
//!
//! Provides command-line interface for protocol verification, state space
//! exploration, and Kani proof execution.

use mcpe::{
    error::{Result, StateId},
    numeric::FixedPoint,
    protocol::{Message, MessageType, Session},
    state::{RepairTransition, StateVector, Transition},
};
use std::env;

fn print_usage() {
    println!("MCPE — Formal Verification Framework");
    println!();
    println!("USAGE:");
    println!("    mcpe-cli <command> [arguments]");
    println!();
    println!("COMMANDS:");
    println!("    verify-session <id>        Verify session state invariants");
    println!("    round-trip <type> <sid> <seq> <payload>  Verify message round-trip");
    println!("    fixed-point <value> <frac> <total>       Test fixed-point conversion");
    println!("    transition <dim> <eta> <lo> <hi>         Test repair transition");
    println!("    help                        Show this help message");
}

fn verify_session(args: &[&str]) -> Result<()> {
    if args.is_empty() {
        return Err(mcpe::Error::configuration("missing session id"));
    }
    let id: u32 = args[0]
        .parse()
        .map_err(|_| mcpe::Error::configuration("invalid session id"))?;
    let mut session = Session::new(id);
    session.activate(id).unwrap();
    session.close().unwrap();
    session.terminate();
    println!("Session {} state: {:?}", id, session.state());
    Ok(())
}

fn round_trip(args: &[&str]) -> Result<()> {
    if args.len() < 4 {
        return Err(mcpe::Error::configuration(
            "usage: round-trip <type> <session_id> <sequence> <payload>",
        ));
    }
    let msg_type = MessageType::from_byte(args[0].parse::<u8>().map_err(|_| {
        mcpe::Error::configuration("invalid message type byte")
    })?)
    .ok_or_else(|| mcpe::Error::configuration("unknown message type byte"))?;
    let session_id: u32 = args[1]
        .parse()
        .map_err(|_| mcpe::Error::configuration("invalid session id"))?;
    let sequence: u32 = args[2]
        .parse()
        .map_err(|_| mcpe::Error::configuration("invalid sequence"))?;
    let payload = args[3].as_bytes().to_vec();

    let msg = Message::new(msg_type, session_id, sequence, payload);
    let serialized = msg.serialize();
    let deserialized = Message::deserialize(&serialized)?;

    if msg == deserialized {
        println!("Round-trip verified: {:?}", msg.msg_type());
        Ok(())
    } else {
        Err(mcpe::Error::serialization_round_trip("Message"))
    }
}

fn fixed_point(args: &[&str]) -> Result<()> {
    if args.len() < 3 {
        return Err(mcpe::Error::configuration(
            "usage: fixed-point <value> <frac_bits> <total_bits>",
        ));
    }
    let value: f64 = args[0]
        .parse()
        .map_err(|_| mcpe::Error::configuration("invalid value"))?;
    let frac_bits: u8 = args[1]
        .parse()
        .map_err(|_| mcpe::Error::configuration("invalid frac_bits"))?;
    let total_bits: u8 = args[2]
        .parse()
        .map_err(|_| mcpe::Error::configuration("invalid total_bits"))?;

    let fp = FixedPoint::from_f64(value, frac_bits, total_bits)
        .ok_or_else(|| mcpe::Error::numeric_overflow("from_f64", 0))?;
    println!(
        "FixedPoint({}) = {} (raw: {})",
        value,
        fp.to_f64(),
        fp.raw()
    );
    Ok(())
}

fn transition(args: &[&str]) -> Result<()> {
    if args.len() < 4 {
        return Err(mcpe::Error::configuration(
            "usage: transition <dim> <eta> <lower> <upper>",
        ));
    }
    let dim: usize = args[0]
        .parse()
        .map_err(|_| mcpe::Error::configuration("invalid dim"))?;
    let eta: i64 = args[1]
        .parse()
        .map_err(|_| mcpe::Error::configuration("invalid eta"))?;
    let lower: i64 = args[2]
        .parse()
        .map_err(|_| mcpe::Error::configuration("invalid lower"))?;
    let upper: i64 = args[3]
        .parse()
        .map_err(|_| mcpe::Error::configuration("invalid upper"))?;

    let id = StateId::new(1);
    let values = vec![100i64; dim];
    let state = StateVector::new(id, values, dim)?;
    let transition = RepairTransition::new(eta, lower, upper);
    let next = transition.apply(&state)?;

    println!("Transition applied:");
    println!("  Input:  {:?}", state.values());
    println!("  Output: {:?}", next.values());
    println!("  Safe:   {}", transition.is_safe(&state));
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
        "verify-session" => verify_session(&rest_strs),
        "round-trip" => round_trip(&rest_strs),
        "fixed-point" => fixed_point(&rest_strs),
        "transition" => transition(&rest_strs),
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
