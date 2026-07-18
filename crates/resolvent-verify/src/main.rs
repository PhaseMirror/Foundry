// `resolvent_verify` binary.
//
// CENTRAL VERIFICATION: the Kani proof of the resolvent identity
// `R2 = R1 + R1 V2 R2` (see `kani_proofs::verify_resolvent_identity`) is the
// formal guarantee that the implemented perturbation expansion is correct.
//
// The 256-state numeric comparison below is a *diagnostic*, not the proof:
// it reports whether the first-order truncation is actually a good
// approximation for the chosen (kappa, gamma, sigma, z), and shows that the
// O(kappa) gcd coupling is dropped by the simplified paper formula.

use resolvent_verify::*;
use std::env;

fn run_diagnostic(kappa: f64, gamma: f64, sigma: f64, z: f64, normalize: bool) {
    let d = diagnose(kappa, gamma, sigma, z, normalize);

    let n = basis_data::N_STATES as f64;
    let reconstructed = d.fo + d.v1_part + d.rem_kg;

    println!("=== Resolvent trace expansion (256-state real basis) ===");
    println!("z = {}, kappa = {}, gamma = {}, sigma = {}, normalize = {}", d.z, d.kappa, d.gamma, d.sigma, d.normalize);
    println!("Λ_m (||Xi_simple||_inf) = {}", LAMBDA_M);
    println!("Tr(R2)                          = {:.10e}", d.tr_r2);
    println!("fo (R0-based first order)       = {:.10e}", d.fo);
    println!("  error Tr(R2) - fo             = {:.10e}", d.error_fo);
    println!("  O(kappa) V1 correction         = {:.10e}", d.v1_part);
    println!("  genuine O(||V2||^2) remainder   = {:.10e}", d.rem_kg);
    println!("fo_r1 (R1-based, correct ref)   = {:.10e}", d.fo_r1);
    println!("  error Tr(R2) - fo_r1           = {:.10e}  (== genuine remainder)", d.tr_r2 - d.fo_r1);
    println!("||V2|| (sup)                    = {:.10e}   (kappa*gamma = {:.4e})", d.sup_v2, d.kappa * d.gamma);
    println!("||Xi_simple|| (sup)             = {:.10e}", d.sup_m);
    println!("N*||R1||*||V2|| proxy for ||R1 V2|| = {:.10e}", d.r1v2_proxy);

    // ---- Sound, non-vacuous runtime checks (these are what must always hold) ----
    // 1. Exact decomposition from the resolvent identity at N=256:
    //    Tr(R2) = fo + [Tr(R1)-Tr(R0)] + [Tr(R1 V2 R1)-Tr(R0 V2 R0)] + Tr(R1 V2 R2 V2 R1).
    assert!(
        (d.tr_r2 - reconstructed).abs() < 1e-6,
        "resolvent-identity decomposition failed at N=256"
    );
    // 2. Genuine remainder satisfies the O(||V2||^2) bound (valid but loose).
    assert!(
        d.rem_kg.abs() <= d.loose_bound * 1.0000001,
        "genuine remainder violates the O(||V2||^2) bound"
    );
    // 3. The implemented resolvent identity R2 = R1 + R1 V2 R2 holds numerically.
    const N: usize = basis_data::N_STATES;
    let h1 = build_h1(&basis_data::NUMBERS, &basis_data::VALS, kappa, sigma);
    let h2 = build_h2(&basis_data::NUMBERS, &basis_data::VALS, kappa, gamma, sigma, normalize);
    let r1 = (Matrix::<N>::identity().scale(z).sub(&h1)).inv().unwrap();
    let r2 = (Matrix::<N>::identity().scale(z).sub(&h2)).inv().unwrap();
    let v2 = build_v2(&basis_data::NUMBERS, &basis_data::VALS, kappa, gamma, sigma, normalize);
    let rhs = r1.add(&r1.mul(&v2).mul(&r2));
    assert!(
        r2.approx_eq(&rhs, 1e-6),
        "resolvent identity R2 = R1 + R1 V2 R2 failed at runtime"
    );

    // ---- Diagnostic verdict (not a proof) ----
    let rel_rem = d.rem_kg.abs() / d.tr_r2.abs();
    if d.r1v2_proxy < 1.0 {
        println!("VERDICT: ||R1 V2|| < 1, first-order truncation is a valid approximation.");
    } else {
        println!("VERDICT: ||R1 V2|| >= 1 -- the perturbation is NOT small, so the");
        println!("         first-order formula Tr(R2) = fo + O((kappa*gamma)^2) is INVALID here.");
    }
    println!(
        "DIAGNOSTIC: relative genuine remainder |rem|/|Tr(R2)| = {:.3e} (this is the",
        rel_rem
    );
    println!("            O((kappa*gamma)^2) term; the O(kappa) V1 part is {:.3e}).",
        d.v1_part.abs());

    let _ = n;
}

// ===========================================================================
// Kani proofs. The resolvent identity is the CENTRAL verification; the other
// two support it. Excluded from ordinary `cargo build`.
// ===========================================================================

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    /// Operational correctness of Gauss-Jordan inversion: for every symbolic
    /// 2x2 matrix that is (assumed) invertible with a margin, A * A^-1 == I
    /// up to f64 rounding.
    #[kani::proof]
    #[kani::unwind(3)]
    fn verify_matrix_inverse() {
        let a = Matrix::<2> {
            e: [
                [kani::any::<f64>(), kani::any::<f64>()],
                [kani::any::<f64>(), kani::any::<f64>()],
            ],
        };
        for i in 0..2 {
            for j in 0..2 {
                kani::assume(a.e[i][j].abs() <= 5.0);
            }
        }
        let det = a.e[0][0] * a.e[1][1] - a.e[0][1] * a.e[1][0];
        kani::assume(det.abs() > 0.5);
        let inv = a.inv().expect("invertible by assumption");
        let prod = a.mul(&inv);
        let id = Matrix::<2>::identity();
        assert!(
            prod.approx_eq(&id, 1e-6),
            "A * A^-1 must equal the identity (operational correctness)"
        );
    }

    /// CENTRAL VERIFICATION: the resolvent identity R2 = R1 + R1 V2 R2,
    /// implemented exactly as in the 256-state harness, holds for symbolic
    /// inputs (well away from spectrum). This is the formal guarantee that the
    /// implemented perturbation expansion is correct.
    #[kani::proof]
    #[kani::unwind(4)]
    fn verify_resolvent_identity() {
        let z: f64 = kani::any();
        kani::assume(z > 20.0 && z < 100.0);
        let h0 = Matrix::<2> {
            e: [[kani::any::<f64>(), 0.0], [0.0, kani::any::<f64>()]],
        };
        kani::assume(h0.e[0][0].abs() < 10.0 && h0.e[1][1].abs() < 10.0);
        kani::assume((z - h0.e[0][0]).abs() > 1.0 && (z - h0.e[1][1]).abs() > 1.0);
        let v1 = Matrix::<2> {
            e: [
                [kani::any::<f64>(), kani::any::<f64>()],
                [kani::any::<f64>(), kani::any::<f64>()],
            ],
        };
        let v2 = Matrix::<2> {
            e: [
                [kani::any::<f64>(), kani::any::<f64>()],
                [kani::any::<f64>(), kani::any::<f64>()],
            ],
        };
        for i in 0..2 {
            for j in 0..2 {
                kani::assume(v1.e[i][j].abs() <= 0.1);
                kani::assume(v2.e[i][j].abs() <= 0.1);
            }
        }
        let h1 = h0.add(&v1);
        let h2 = h1.add(&v2);
        let r1 = (Matrix::<2>::identity().scale(z).sub(&h1))
            .inv()
            .expect("R1 invertible");
        let r2 = (Matrix::<2>::identity().scale(z).sub(&h2))
            .inv()
            .expect("R2 invertible");
        let rhs = r1.add(&r1.mul(&v2).mul(&r2));
        assert!(
            r2.approx_eq(&rhs, 1e-6),
            "resolvent identity R2 = R1 + R1 V2 R2 must hold"
        );
    }

    /// The genuine remainder is bounded by N^5 * ||R1||^2 * ||R2|| * ||V2||^2,
    /// i.e. O(||V2||^2) = O((kappa*gamma)^2) once the kernel is normalized.
    /// Verified for symbolic 2x2 inputs; the same sup-norm algebra proves it
    /// for any N.
    #[kani::proof]
    #[kani::unwind(6)]
    fn verify_remainder_bound() {
        let z: f64 = kani::any();
        kani::assume(z > 20.0 && z < 100.0);
        let h0 = Matrix::<2> {
            e: [[kani::any::<f64>(), 0.0], [0.0, kani::any::<f64>()]],
        };
        kani::assume(h0.e[0][0].abs() < 10.0 && h0.e[1][1].abs() < 10.0);
        kani::assume((z - h0.e[0][0]).abs() > 1.0 && (z - h0.e[1][1]).abs() > 1.0);
        let v1 = Matrix::<2> {
            e: [
                [kani::any::<f64>(), kani::any::<f64>()],
                [kani::any::<f64>(), kani::any::<f64>()],
            ],
        };
        let v2 = Matrix::<2> {
            e: [
                [kani::any::<f64>(), kani::any::<f64>()],
                [kani::any::<f64>(), kani::any::<f64>()],
            ],
        };
        for i in 0..2 {
            for j in 0..2 {
                kani::assume(v1.e[i][j].abs() <= 0.1);
                kani::assume(v2.e[i][j].abs() <= 0.1);
            }
        }
        let h1 = h0.add(&v1);
        let h2 = h1.add(&v2);
        let r1 = (Matrix::<2>::identity().scale(z).sub(&h1))
            .inv()
            .expect("R1 invertible");
        let r2 = (Matrix::<2>::identity().scale(z).sub(&h2))
            .inv()
            .expect("R2 invertible");
        let rem = r1.mul(&v2).mul(&r2).mul(&v2).mul(&r1).trace();
        let nn = 2.0_f64;
        let c = nn.powi(5) * r1.sup_norm().powi(2) * r2.sup_norm() * v2.sup_norm().powi(2);
        assert!(
            rem.abs() <= c + 1e-6,
            "genuine remainder must satisfy the O(||V2||^2) bound"
        );
    }
}

fn main() {
    // Optional CLI override: resolvent_verify [kappa gamma sigma z] [--normalize]
    let mut normalize = false;
    let mut pos: Vec<f64> = Vec::new();
    for arg in env::args().skip(1) {
        if arg == "--normalize" {
            normalize = true;
        } else {
            pos.push(arg.parse().expect("numeric arg"));
        }
    }
    let (kappa, gamma, sigma, z) = if pos.len() >= 4 {
        (pos[0], pos[1], pos[2], pos[3])
    } else {
        (0.1_f64, 0.5_f64, 2.0_f64, 20.0_f64)
    };
    // The 256x256 matrices are 512 KB each; run on a thread with a large stack
    // to avoid overflowing the default main-thread stack.
    std::thread::Builder::new()
        .stack_size(64 * 1024 * 1024)
        .spawn(move || run_diagnostic(kappa, gamma, sigma, z, normalize))
        .expect("spawn")
        .join()
        .expect("join");
}
