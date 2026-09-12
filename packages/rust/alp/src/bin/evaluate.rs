use alp_rs::evaluate_preservation;

fn main() {
    let stdin = std::io::read_to_string(std::io::stdin()).unwrap_or_default();
    match evaluate_preservation(&stdin) {
        Ok(risk) => {
            println!(r#"{{"risk": "{}"}}"#, risk);
        }
        Err(err) => {
            eprintln!("{}", err);
            println!(r#"{{"error": "{}"}}"#, err);
        }
    }
}
