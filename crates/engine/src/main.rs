use pirtm_engine::state::{RuntimeState, SkeletonState, TensorMapState, PrimeChannel};
use pirtm_engine::sigma_layer::{ZeroModeExtractable, certify_state};

fn main() {
    println!("Initializing Universal Atomic Calculator (UAC) Substrate...");
    
    // Inside your execution loop...
    let current_state = RuntimeState {
        skeleton: SkeletonState { operator_norm: 0.85 },
        tensor_map: TensorMapState { lipschitz_bound: 1.0 },
        active_channels: vec![
            PrimeChannel { prime_index: 2, weight: 0.05 },
            PrimeChannel { prime_index: 3, weight: 0.05 },
        ],
    };

    // 1. Extract the ZM quantities
    let zm_metrics = current_state.extract_zm_quantities().expect("Failed to extract ZM quantities");

    // 2. Pass to the Sigma-Layer for certification
    match certify_state(&zm_metrics) {
        Ok(_) => {
            println!("State certified. Contractivity bounds maintained.");
            // Proceed with state commit / WORM ledger append
        },
        Err(e) => {
            // This will trigger the SIG_GOV_KILL or fail-closed state
            eprintln!("CRITICAL HALT: {}", e);
            // Handle rejection...
        }
    }
}
