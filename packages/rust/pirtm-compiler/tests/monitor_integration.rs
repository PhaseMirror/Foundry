use pirtm_monitor::{ManifoldState, MockStateProvider, MonitorAction, MonitorConfig, WardMonitor};
use std::time::SystemTime;

fn mock_state(rho: f64, delta: f64, lambda_l_product: f64) -> ManifoldState {
    let timestamp = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .unwrap()
        .as_secs();
    ManifoldState {
        rho,
        delta,
        lambda_l_product,
        timestamp,
    }
}

#[test]
fn test_monitor_full_run_with_kill() {
    let mut config = MonitorConfig::default();
    config.kappa0 = 0.0; // Disable attenuation so raw drift triggers kill
    let states = vec![
        mock_state(0.4, 5e-5, 0.9), // normal
        mock_state(0.9, 5e-5, 0.9), // warning
        mock_state(1.2, 5e-5, 0.9), // kill
    ];
    let provider = MockStateProvider::new(states);
    let mut monitor = WardMonitor::new(config, provider);

    // Step 1: continue
    assert!(matches!(monitor.step().unwrap(), MonitorAction::Continue));
    // Step 2: continue (warning, but no kill)
    assert!(matches!(monitor.step().unwrap(), MonitorAction::Continue));
    // Step 3: kill
    match monitor.step().unwrap() {
        MonitorAction::Kill(reason) => assert!(reason.contains("Halt threshold")),
        _ => panic!("Expected kill"),
    }
}
