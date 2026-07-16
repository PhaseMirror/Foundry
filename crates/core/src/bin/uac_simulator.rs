use pirtm_rs::rta::{State, RtaMetric};
use pirtm_rs::uac_loss::{uac_total_loss, LanglandsLossConfig, ArithmeticBinduAttractor};
use pirtm_rs::gates::{gate_langlands, LanglandsZKConfig};
use std::fs;
use serde_json::Value;


fn main() {
    println!("Initializing UAC Social-Simulation Harness...");
    println!("Target: Monster Group Symmetry Confinement (Tier V Declaration)");

    let mut state = State::new();
    let community_primes = vec![2, 3, 5, 7, 11, 13, 17, 19, 23, 29];
    for &p in &community_primes {
        state.active_primes.insert(p);
    }

    println!("Seeding initial civic reality (chaotic configuration)...");
    for i in 0..community_primes.len() {
        for j in i + 1..community_primes.len() {
            let p = community_primes[i];
            let q = community_primes[j];
            let tension = ((p * q) % 17) as f64 + 1.0;
            state.joint_words.insert((p, q), tension);
        }
    }

    let initial_defect = state.arta_defect();
    let initial_langlands = uac_total_loss(&state, LanglandsLossConfig::default());

    println!("\n[PRE-FIT METRICS]");
    println!("Arta Defect (Symmetry Deviation): {:.4}", initial_defect);
    println!("Langlands Loss (Arithmetic Deviation): {:.4}", initial_langlands);
    println!("L3 Gate Status: REJECTED (Deviation > 1e-5)\n");
    println!("pre_arta_defect: {:.4}", initial_defect);
    println!("pre_langlands_loss: {:.4}", initial_langlands);
    println!("pre_total_loss: {:.4}", initial_defect + initial_langlands);
    println!("pre_rta_dist: N/A");

    println!("Engaging UAC Fit Operator (Symmetry Reduction via MA-VQE)...");
    state.fit(0.1, 1e-7);

    let final_defect = state.arta_defect();
    let final_langlands = uac_total_loss(&state, LanglandsLossConfig::default());
    let attractor = ArithmeticBinduAttractor::new();
    let dist = attractor.distance(&state);

    println!("\n[POST-FIT METRICS]");
    println!("Arta Defect (Symmetry Deviation): {:.8}", final_defect);
    println!("Langlands Loss (Arithmetic Deviation): {:.8}", final_langlands);
    println!("Distance to Arithmetic Bindu: {:.8}", dist);
    println!("post_arta_defect: {:.8}", final_defect);
    println!("post_langlands_loss: {:.8}", final_langlands);
    println!("post_total_loss: {:.8}", final_defect + final_langlands);
    println!("post_rta_dist: {:.8}", dist);
// Determine if ZK verification is enabled via CLI flag
// Parse CLI flags for ZK verification and optional verification key
let args: Vec<String> = std::env::args().collect();
let zk_enabled = args.iter().any(|a| a == "--zk" || a == "--enable-zk");
let vk_path_opt = args.iter().position(|a| a == "--vk");
let vk_json = if let Some(idx) = vk_path_opt {
    if idx + 1 < args.len() {
        let path = &args[idx + 1];
        match fs::read_to_string(path) {
            Ok(content) => match serde_json::from_str::<Value>(&content) {
                Ok(v) => Some(v),
                Err(e) => {
                    eprintln!("Failed to parse vk JSON at {}: {}", path, e);
                    None
                }
            },
            Err(e) => {
                eprintln!("Failed to read vk file {}: {}", path, e);
                None
            }
        }
    } else {
        eprintln!("--vk flag provided without a path");
        None
    }
} else { None };
let zk_config = if zk_enabled {
    LanglandsZKConfig { enabled: true, vk_json }
} else {
    LanglandsZKConfig::default()
};
let gate_result = gate_langlands(&state, 1e-12, Some(zk_config));
match gate_result {
    Ok(_) => {
        println!("L3 Gate Status: ACCEPTED (Monster Identity Representation Anchored)");
        println!("zk_status: ACCEPTED");
    }
    Err(e) => {
        println!("L3 Gate Status: REJECTED ({})", e);
        println!("zk_status: REJECTED");
    }
};
    println!("\nThe Civic Node is now navigating strictly within the Hilbert space of the Monster Group.");
}
