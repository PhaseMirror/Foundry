use personalized_medicine::domain_lint::DomainLint;
use personalized_medicine::runtime_monitor::{MonitorStatus, RuntimeMonitor};

#[test]
fn test_runtime_monitor_nominal_and_violation() {
    let mut monitor = RuntimeMonitor::new();
    assert!(monitor.is_sealed);

    // Valid update: 4 * 3 + 2 = 14
    let ok = monitor.process_update(3, 2, 14);
    assert!(ok);
    assert_eq!(monitor.history[0].status, MonitorStatus::Nominal);
    assert!(monitor.is_sealed);

    // Corrupted update: 4 * 3 + 2 = 14 != 99
    let mismatch = monitor.process_update(3, 2, 99);
    assert!(!mismatch);
    assert!(!monitor.is_sealed);
    match &monitor.history[1].status {
        MonitorStatus::Violated { expected, actual } => {
            assert_eq!(*expected, 14);
            assert_eq!(*actual, 99);
        }
        _ => panic!(),
    }
}

#[test]
fn test_domain_lint_scanner() {
    let clean_code = "def F_10 (y u : Int) : Int := 4 * y + u";
    assert!(DomainLint::scan_source_code(clean_code).is_empty());

    let tainted_code = "def F_patient (y u : Int) : Int := 4 * y + u // Clinical note";
    let violations = DomainLint::scan_source_code(tainted_code);
    assert!(!violations.is_empty());
}
