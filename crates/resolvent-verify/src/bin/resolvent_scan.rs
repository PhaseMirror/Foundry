// `resolvent_scan` binary: diagnostic parameter sweep over (kappa, gamma) for
// the 256-state real basis, with optional kernel normalization by the Universal
// Multiplicity Constant Λ_m = ||Xi_simple||_inf.
//
// Normalize the interaction (V2 = kappa*gamma * (Xi_simple/Λ_m) .* W) to turn
// the perturbation strength from κγ·||Xi|| (O(1)) into κγ·1, making the
// first-order (R1-based) truncation a small perturbation.
//
// NOTE: normalization only affects the Xi_simple (V2) term. The O(kappa) gcd
// coupling (V1 = kappa*K_gcd.*W) is untouched, so the simplified R0-based
// formula Tr(R2) ≈ fo still carries that O(kappa) error. See the diagnostics.

use resolvent_verify::*;

fn run_scan(sigma: f64, z: f64, normalize: bool) {
    let kappas = [
        0.1, 0.05, 0.02, 0.01, 0.005, 0.002, 0.001, 0.0005, 0.0001,
    ];
    let gammas = [0.5, 0.1, 0.02, 0.005];

    let mode = if normalize {
        format!("NORMALIZED (Λ_m = {})", LAMBDA_M)
    } else {
        "unnormalized".to_string()
    };
    println!();
    println!("--- mode: {mode} ---");
    println!(
        "| kappa | gamma | kappa*gamma | ||V2|| | rem_kg (genuine) | err_fo (R0-based) | rel_rem | valid R1? | valid paper? |"
    );
    println!("|---|---|---|---|---|---|---|---|---|");

    for &kappa in &kappas {
        for &gamma in &gammas {
            let d = diagnose(kappa, gamma, sigma, z, normalize);
            let rel_rem = d.rem_kg.abs() / d.tr_r2.abs();
            let rel_v1 = d.v1_part.abs() / d.tr_r2.abs();
            let valid_r1 = if rel_rem < 1e-2 { "YES" } else { "no" };
            let valid_paper = if rel_rem < 1e-2 && rel_v1 < 1e-2 {
                "YES"
            } else {
                "no"
            };
            println!(
                "| {kappa} | {gamma} | {:.4e} | {:.3e} | {:.3e} | {:.3e} | {:.3e} | {valid_r1} | {valid_paper} |",
                kappa * gamma,
                d.sup_v2,
                d.rem_kg,
                d.error_fo.abs(),
                rel_rem,
            );
            let _ = rel_v1;
        }
    }
}

fn main() {
    let sigma = 2.0;
    let z = 20.0;

    let args: Vec<String> = std::env::args().skip(1).collect();
    let only_norm = args.iter().any(|a| a == "--normalize");
    let only_unnorm = args.iter().any(|a| a == "--unnormalized");

    let do_unnorm = !only_norm;
    let do_norm = !only_unnorm;

    // The 256x256 matrices are 512 KB each; run the sweep on a thread with a
    // large stack to avoid overflowing the default main-thread stack.
    std::thread::Builder::new()
        .stack_size(64 * 1024 * 1024)
        .spawn(move || {
            if do_unnorm {
                run_scan(sigma, z, false);
            }
            if do_norm {
                run_scan(sigma, z, true);
            }
            println!();
            println!("rem_kg      = Tr(R1 V2 R2 V2 R1)  [the O(||V2||^2) = O((kappa*gamma)^2) term]");
            println!("err_fo      = |Tr(R2) - fo|        [paper formula error, includes the O(kappa) V1 part]");
            println!("rel_rem     = |rem_kg| / |Tr(R2)|");
            println!("valid R1    = rel_rem < 1e-2   (normalized: first-order around R1 is valid)");
            println!("valid paper = rel_rem < 1e-2 AND |v1_part|/|Tr(R2)| < 1e-2  (needs kappa small too)");
        })
        .expect("spawn")
        .join()
        .expect("join");
}
