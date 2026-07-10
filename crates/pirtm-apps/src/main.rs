use std::env;
use pirtm_stdlib::prelude::*;
use pirtm_apps::WorkflowOrchestrator;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 3 || args[1] != "deploy" {
        eprintln!("Usage: pirtm-apps deploy <ensemble_name>");
        std::process::exit(1);
    }

    let ensemble_name = &args[2];
    
    let word = match ensemble_name.as_str() {
        "lawful_ensemble" => Ap(2) + Ap(3),
        "unlawful_ensemble" => Ap(1),
        _ => {
            eprintln!("Unknown ensemble. Use 'lawful_ensemble' or 'unlawful_ensemble'.");
            std::process::exit(1);
        }
    };

    println!("Deploying {}...", ensemble_name);
    
    match WorkflowOrchestrator::deploy_application(ensemble_name, &word) {
        Ok(receipt) => {
            println!("Deploy SUCCESS:");
            println!("  Package: {}", receipt.package_name);
            println!("  Publish: {}", receipt.publish_status);
            println!("  Install: {}", receipt.install_status);
            println!("  Run: {}", receipt.run_status);
            println!("  PWEH: {}", receipt.pweh);
        }
        Err(e) => {
            eprintln!("Deploy ABORTED:");
            eprintln!("  Reason: {}", e);
            std::process::exit(1);
        }
    }
}
