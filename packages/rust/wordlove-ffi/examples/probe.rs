use wordlove_ffi::LargePrimeExport;
fn main() {
    match LargePrimeExport::connect() {
        Ok(lp) => println!("CONNECT-OK prime13={}", lp.hybrid_prime(13).unwrap_or_default()),
        Err(e) => { println!("CONNECT-FAIL {e}"); std::process::exit(1); }
    }
}
