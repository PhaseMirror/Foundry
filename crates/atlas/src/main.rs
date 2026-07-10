pub mod lawful;

fn main() {
    let (trace, max_c) = lawful::run_108_cycle();
    println!("--- [MULTIPLICITY] F MAP CONTRACTION TRACE ---");
    println!("Prime | Lambda_p | L_p | c_p");
    for e in trace {
        println!("{:5} | {:.6} | {:.6} | {:.6}", e.p, e.lambda_p, e.l_p, e.c_p);
    }
    println!("\nMAX contraction c: {:.10}", max_c);
    
    let (r1, r2, r3) = lawful::reproduce_tier_energies();
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

// LawfulRecursionVersion:1.0
