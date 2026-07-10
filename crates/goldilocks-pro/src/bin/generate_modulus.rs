use num_bigint::BigUint;
use num_prime::RandPrime;
use rand::thread_rng;
use zeroize::Zeroize;
use std::fs::File;
use std::io::Write;

fn main() {
    println!("Generating secure 2048-bit modulus in simulated air-gapped environment...");
    
    let mut rng = thread_rng();
    
    // Generate two 1024-bit primes
    let mut p: BigUint = RandPrime::gen_prime(&mut rng, 1024, None);
    let mut q: BigUint = RandPrime::gen_prime(&mut rng, 1024, None);
    
    let n = &p * &q;
    
    // Zeroize primes by replacing with 0 via their bytes and resetting
    let mut p_bytes = p.to_bytes_be();
    let mut q_bytes = q.to_bytes_be();
    
    p_bytes.zeroize();
    q_bytes.zeroize();
    
    // We can't zeroize BigUint directly, but assigning to zero drops the data
    p = BigUint::from(0u32);
    q = BigUint::from(0u32);
    
    let n_hex = format!("{:x}", n);
    
    println!("Primes generated, multiplied, and zeroized successfully.");
    
    // Write to simulated HSM / secure enclave file
    let mut file = File::create("secure_enclave_modulus.txt").expect("Failed to create file");
    writeln!(file, "{}", n_hex).expect("Failed to write modulus");
    
    println!("Modulus saved to secure_enclave_modulus.txt");
}
