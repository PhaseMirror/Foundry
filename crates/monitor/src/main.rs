// src/main.rs – entry point for the certification binary

mod certify_constants;

fn main() {
    if let Err(e) = certify_constants::run_certification() {
        eprintln!("Certification failed: {}", e);
        std::process::exit(1);
    } else {
        println!("All constants successfully certified.");
    }
}
