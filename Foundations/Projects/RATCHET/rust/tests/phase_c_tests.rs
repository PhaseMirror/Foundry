use ratchet::phase_c_adaptive_adversary::AdaptiveAdversary;

#[test]
fn test_adaptive_adversary_all_strategies_blocked() {
    let adversary = AdaptiveAdversary::new(0.5);
    let results = adversary.evaluate_adaptive_defenses();

    assert_eq!(results.len(), 4);
    for (strategy, blocked, mitigation) in results {
        println!("Adaptive strategy test: {} -> blocked={} ({})", strategy, blocked, mitigation);
        assert!(blocked, "Adaptive evasion strategy '{}' was not blocked", strategy);
    }
}
