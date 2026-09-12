use multiplicity_ensembles::{EnsembleModule, EnsembleSessionGraph};
use serde_json::json;
use std::fs;
use std::path::Path;

#[test]
fn test_contractivity_fixtures() {
    let out_dir = Path::new("../../tests/ensemble/out");
    fs::create_dir_all(out_dir).unwrap();

    // Fixture 1: uncoupled_2module
    let modules_1 = vec![
        EnsembleModule { prime_index: 2, spectral_radius: 8200 },
        EnsembleModule { prime_index: 3, spectral_radius: 7500 },
    ];
    let coupling_1 = vec![
        vec![10000, 0],
        vec![0, 10000],
    ];
    let graph_1 = EnsembleSessionGraph::new(modules_1, coupling_1);
    let res_1 = graph_1.evaluate_stability();
    assert!(res_1.is_ok());
    let (rho_1, delta_1) = res_1.unwrap();
    assert!(rho_1 < 8300);

    write_summary(out_dir, "uncoupled_2module", rho_1, delta_1, "PASS");

    // Fixture 2: four_prime_near_boundary
    let modules_2 = vec![
        EnsembleModule { prime_index: 2, spectral_radius: 8200 },
        EnsembleModule { prime_index: 3, spectral_radius: 7800 },
        EnsembleModule { prime_index: 5, spectral_radius: 7500 },
        EnsembleModule { prime_index: 7, spectral_radius: 7100 },
    ];
    let coupling_2 = vec![
        vec![10000, 200, 200, 200],
        vec![200, 10000, 200, 200],
        vec![200, 200, 10000, 200],
        vec![200, 200, 200, 10000],
    ];
    let graph_2 = EnsembleSessionGraph::new(modules_2, coupling_2);
    let res_2 = graph_2.evaluate_stability();
    assert!(res_2.is_ok());
    let (rho_2, delta_2) = res_2.unwrap();
    assert!(rho_2 < 9500);

    write_summary(out_dir, "four_prime_near_boundary", rho_2, delta_2, "PASS");

    // Fixture 3: high_rho_outlier_reject
    let modules_3 = vec![
        EnsembleModule { prime_index: 2, spectral_radius: 6000 },
        EnsembleModule { prime_index: 3, spectral_radius: 9600 },
        EnsembleModule { prime_index: 5, spectral_radius: 6000 },
    ];
    let coupling_3 = vec![
        vec![10000, 500, 500],
        vec![500, 10000, 500],
        vec![500, 500, 10000],
    ];
    let graph_3 = EnsembleSessionGraph::new(modules_3, coupling_3);
    let res_3 = graph_3.evaluate_stability();
    assert!(res_3.is_err());
    if let Err(multiplicity_ensembles::ContractivityError::EnsembleUnstable { rho_global, delta }) = res_3 {
        assert!(rho_global >= 9500);
        write_summary(out_dir, "high_rho_outlier_reject", rho_global, delta, "FAIL");
    } else {
        panic!("Expected EnsembleUnstable error");
    }
}

fn format_scaled(val: i64) -> String {
    let sign = if val < 0 { "-" } else { "" };
    let val_abs = val.abs();
    let integer = val_abs / 10000;
    let fraction = val_abs % 10000;
    format!("{}{}.{:04}", sign, integer, fraction)
}

fn write_summary(out_dir: &Path, name: &str, rho: u64, delta: i64, verdict: &str) {
    let rho_str = format_scaled(rho as i64);
    let delta_str = format_scaled(delta);
    let rho_val: serde_json::Value = serde_json::from_str(&rho_str).unwrap();
    let delta_val: serde_json::Value = serde_json::from_str(&delta_str).unwrap();
    let summary = json!({
        "fixture": name,
        "rho_global": rho_val,
        "delta": delta_val,
        "verdict": verdict,
    });
    let file_path = out_dir.join(format!("{}.json", name));
    fs::write(file_path, serde_json::to_string_pretty(&summary).unwrap()).unwrap();
}
