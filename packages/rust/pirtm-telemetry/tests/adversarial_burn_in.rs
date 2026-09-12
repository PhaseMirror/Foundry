use num_rational::Ratio;
use pirtm_telemetry::{GardenTelemetry, GeniusV2PracticeModel, MAX_ADMISSIBLE_DRIFT};

#[test]
fn test_10k_cycle_adversarial_burn_in() {
    let mut model = GeniusV2PracticeModel::new();
    let mut accepted_count = 0;
    let mut tripwire_killed_count = 0;

    let mut current_moisture = 50;
    let mut current_temp = 50;
    let mut current_solar = 50;
    let current_civic = 50;

    let total_cycles = 10_000;

    for cycle in 0..total_cycles {
        let is_adversarial = cycle % 100 == 0 && cycle > 0;

        let telemetry = if is_adversarial {
            // Adversarial transient spike: huge jump to 95 or 5 without corrupting physical baseline
            let val = if cycle % 200 == 0 { 95 } else { 5 };
            GardenTelemetry::new((val, 100), (val, 100), (val, 100), (val, 100))
        } else {
            // Natural bounded physical drift: within [-2, +2] per step
            let step = ((cycle % 5) as i64) - 2;
            current_moisture = (current_moisture + step).clamp(20, 80);
            current_temp = (current_temp - step).clamp(20, 80);
            current_solar = (current_solar + step).clamp(20, 80);
            GardenTelemetry::new(
                (current_moisture, 100),
                (current_temp, 100),
                (current_solar, 100),
                (current_civic, 100),
            )
        };

        match model.ingest_telemetry(&telemetry) {
            Ok(receipt) => {
                accepted_count += 1;
                assert!(!is_adversarial, "Adversarial spike must not be accepted");
                assert!(receipt.is_contractive);
                let drift = Ratio::new(receipt.drift_ratio.0, receipt.drift_ratio.1);
                assert!(drift <= MAX_ADMISSIBLE_DRIFT, "Accepted reading had drift > 0.03");
                assert_eq!(receipt.seal_hash.len(), 64);
                assert!(receipt.poseidon_commitment.starts_with("pos2_"));
            }
            Err(err) => {
                tripwire_killed_count += 1;
                assert!(is_adversarial, "Normal drift must not trigger tripwire");
                assert!(err.contains("SIG_GOV_KILL"));
                assert!(err.contains("Drift violation"));
            }
        }
    }

    println!("============================================================");
    println!("🔥 ADVERSARIAL BURN-IN STRESS TEST COMPLETED");
    println!("Total Cycles:           {}", total_cycles);
    println!("Accepted Contractive:   {}", accepted_count);
    println!("SIG_GOV_KILL Halts:     {}", tripwire_killed_count);
    println!("============================================================");

    assert_eq!(tripwire_killed_count, 99, "Every adversarial spike was caught fail-closed");
    assert_eq!(accepted_count, 9901, "Every normal drift cycle passed without false positives");
}

#[test]
fn test_exact_rational_boundary_drift() {
    let mut model = GeniusV2PracticeModel::new();
    let t0 = GardenTelemetry::new((50, 100), (50, 100), (50, 100), (50, 100));
    assert!(model.ingest_telemetry(&t0).is_ok());

    // Boundary Test 1: Exact limit Delta = 3/100 = 0.0300 (PASS)
    // Shift moisture by +12/100 -> (12/100) / 4 = 3/100
    let t_exact = GardenTelemetry::new((62, 100), (50, 100), (50, 100), (50, 100));
    let res_exact = model.ingest_telemetry(&t_exact);
    assert!(res_exact.is_ok(), "Exact boundary drift 3/100 must be accepted");
    let receipt = res_exact.unwrap();
    assert_eq!(receipt.drift_ratio, (3, 100));

    // Boundary Test 2: Micro-breach Delta > 3/100 (REJECT)
    // Shift moisture by +25/100 -> (25/100) / 4 = 25/400 = 0.0625 > 0.03
    let t_breach = GardenTelemetry::new((75, 100), (50, 100), (50, 100), (50, 100));
    let res_breach = model.ingest_telemetry(&t_breach);
    assert!(res_breach.is_err(), "Micro-breach drift > 3/100 must be rejected");
    assert!(res_breach.unwrap_err().contains("SIG_GOV_KILL"));
}
