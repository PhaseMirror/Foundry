#[cfg(test)]
mod tests {
    use crate::{ParmEngine, ParmError, ParmSealWitness, TripleLockParm};

    // -----------------------------------------------------------------------
    // Sealed state core tests
    // -----------------------------------------------------------------------

    #[test]
    fn test_empty_input_returns_error() {
        let engine = ParmEngine;
        assert_eq!(engine.sealed_state(&[]), Err(ParmError::EmptyInput));
    }

    #[test]
    fn test_singleton_seal() {
        let engine = ParmEngine;
        assert_eq!(engine.sealed_state(&[3]), Ok(9));
        assert_eq!(engine.sealed_state(&[2]), Ok(4));
        assert_eq!(engine.sealed_state(&[7]), Ok(49));
    }

    #[test]
    fn test_108_cycle_anchor() {
        let engine = ParmEngine;
        assert_eq!(engine.sealed_state(&[3, 3, 3, 2, 2]), Ok(960));
    }

    #[test]
    fn test_determinism() {
        let engine = ParmEngine;
        let primes = &[5u64, 7, 11, 13];
        let r1 = engine.sealed_state(primes).unwrap();
        let r2 = engine.sealed_state(primes).unwrap();
        assert_eq!(r1, r2);
    }

    #[test]
    fn test_overflow_detection() {
        let engine = ParmEngine;
        let result = engine.sealed_state(&[u64::MAX]);
        assert!(result.is_err());
    }

    #[test]
    fn test_large_but_valid_sequence() {
        let engine = ParmEngine;
        let primes = &[2u64, 3, 5, 7, 11];
        let result = engine.sealed_state(primes);
        assert!(result.is_ok());
        let v = result.unwrap();
        assert!(v > 0);
    }

    #[test]
    fn test_single_large_prime() {
        let engine = ParmEngine;
        let primes = &[4294967291u64];
        let result = engine.sealed_state(primes);
        assert!(result.is_ok());
    }

    // -----------------------------------------------------------------------
    // Witness tests
    // -----------------------------------------------------------------------

    #[test]
    fn test_witness_hash_deterministic() {
        let primes = &[3u64, 3, 3, 2, 2];
        let engine = ParmEngine;
        let (_, w1) = engine.seal_with_witness(primes).unwrap();
        let (_, w2) = engine.seal_with_witness(primes).unwrap();
        assert_eq!(w1.input_hash, w2.input_hash);
        assert_eq!(w1.sealed_value, w2.sealed_value);
    }

    #[test]
    fn test_witness_input_hash_changes_with_input() {
        let engine = ParmEngine;
        let (_, w1) = engine.seal_with_witness(&[3, 3]).unwrap();
        let (_, w2) = engine.seal_with_witness(&[3, 5]).unwrap();
        assert_ne!(w1.input_hash, w2.input_hash);
    }

    // -----------------------------------------------------------------------
    // Triple-Lock integration tests
    // -----------------------------------------------------------------------

    #[test]
    fn test_triple_lock_full_flow() {
        let mut lock = TripleLockParm::new();
        let engine = ParmEngine;
        let primes = &[3u64, 3, 3, 2, 2];

        #[cfg(feature = "archivum")]
        {
            let mut ledger = archivum::WitnessLedger::new("/tmp/parm_test_ledger.json");
            let (sealed, _witness) = lock.execute(&engine, primes, &mut ledger).unwrap();
            assert_eq!(sealed, 960);
        }

        #[cfg(not(feature = "archivum"))]
        {
            let (sealed, _witness) = lock.execute(&engine, primes).unwrap();
            assert_eq!(sealed, 960);
        }

        assert!(lock.is_locked());
    }

    #[test]
    fn test_triple_lock_rejects_empty_input() {
        let mut lock = TripleLockParm::new();
        let engine = ParmEngine;

        #[cfg(feature = "archivum")]
        {
            let mut ledger = archivum::WitnessLedger::new("/tmp/parm_test_ledger.json");
            let result = lock.execute(&engine, &[], &mut ledger);
            assert!(result.is_err());
        }

        #[cfg(not(feature = "archivum"))]
        {
            let result = lock.execute(&engine, &[]);
            assert!(result.is_err());
        }

        assert!(!lock.is_locked());
    }

    #[test]
    fn test_triple_lock_partial_flow_not_locked() {
        let mut lock = TripleLockParm::new();
        lock.guardian_approve();
        assert!(!lock.is_locked());
        lock.examiner_audit(&ParmSealWitness {
            input_hash: [0u8; 32],
            sealed_value: 960,
            timestamp: 0,
        });
        assert!(!lock.is_locked());

        #[cfg(feature = "archivum")]
        lock.publisher_sign(&archivum::ParmSealProof::new([0u8; 32], 960));

        #[cfg(not(feature = "archivum"))]
        lock.publisher_sign();

        assert!(lock.is_locked());
    }

    // -----------------------------------------------------------------------
    // Lean parity tests
    // -----------------------------------------------------------------------

    #[test]
    fn test_lean_parity_108_cycle() {
        let engine = ParmEngine;
        assert_eq!(engine.sealed_state(&[3, 3, 3, 2, 2]), Ok(960));
    }

    #[test]
    fn test_lean_parity_singletons() {
        let engine = ParmEngine;
        for p in [2u64, 3, 5, 7, 11, 13, 17, 19, 23, 29] {
            assert_eq!(engine.sealed_state(&[p]), Ok(p * p));
        }
    }

    #[test]
    fn test_lean_parity_determinism_theorem() {
        let engine = ParmEngine;
        let primes = &[2u64, 3, 5, 7, 11, 13];
        let a = engine.sealed_state(primes).unwrap();
        let b = engine.sealed_state(primes).unwrap();
        assert_eq!(a, b);
    }
}
