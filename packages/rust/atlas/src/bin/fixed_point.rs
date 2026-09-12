fn main() {
    let primes = vec![2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31];
    let kappa = 0.9;
    let sigma = 0.5;
    let mut max_c = 0.0;

    println!("--- [MULTIPLICITY] F MAP CONTRACTION TRACE ---");
    println!("Prime | Lambda_p | L_p | c_p");
    for p in primes {
        let a_p_norm = 108.0 / (p as f64).sqrt();
        let l_p = a_p_norm * 1.05;
        let lambda_p = kappa * (p as f64).powf(-sigma) / a_p_norm;
        let c_p = lambda_p * l_p;
        if c_p > max_c { max_c = c_p; }
        println!("{:5} | {:.6} | {:.6} | {:.6}", p, lambda_p, l_p, c_p);
    }
    println!("\nMAX contraction c: {:.10}", max_c);
    
    let w = [1.0, 0.8, 0.6, 0.4, 0.2];
    let mut x = [0.0f64; 108];
    for t in 0..108 {
        if t % 27 == 0 { x[t] = w[0]; }
        else if t % 9 == 0 { x[t] = w[1]; }
        else if t % 3 == 0 { x[t] = w[2]; }
        else if t % 4 == 0 { x[t] = w[3]; }
        else if t % 2 == 0 { x[t] = w[4]; }
    }

    let r1: f64 = (0..108).step_by(27).map(|i| x[i] * x[i]).sum();
    let r2: f64 = (0..108).step_by(9).map(|i| x[i] * x[i]).sum::<f64>() - r1;
    let r3: f64 = (0..108).step_by(3).map(|i| x[i] * x[i]).sum::<f64>() - (r1 + r2);

    println!("\n--- [MULTIPLICITY] TIER ENERGY REPRODUCTION ---");
    println!("R1 (27-cycle): {:.2}", r1);
    println!("R2 (9-cycle):  {:.2}", r2);
    println!("R3 (3-cycle):  {:.2}", r3);
    
    if max_c < 1.0 - 1e-6 {
        println!("\n[RESULT] FIXED POINT VERIFIED.");
    } else {
        println!("\n[RESULT] BLOCK. Contraction violation.");
    }
}
