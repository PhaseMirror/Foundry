use lean_sdk::verification;

fn main() {
    let path = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "tests/fixtures/valid_drmm_cert.bin".to_string());

    match verification::generate_certificate_file(&path) {
        Ok((digest, lambda)) => {
            println!("wrote fixture: {}", path);
            let bytes = std::fs::read(&path).expect("read back fixture");
            println!("bytes: {}", bytes.len());
            let v = verification::verify_certificate(&bytes);
            println!("dimension D = {}", v.dimension);
            println!(
                "lambda_eff  = {:.6} (bound {})",
                v.lambda_eff,
                lean_sdk::ACE_BOUND
            );
            println!("hecke_ok={} deligne_ok={}", v.hecke_ok, v.deligne_ok);
            println!("proof_digest = {}", hex::encode(digest));
        }
        Err(e) => {
            eprintln!("Error generating certificate: {}", e);
            std::process::exit(1);
        }
    }
}
