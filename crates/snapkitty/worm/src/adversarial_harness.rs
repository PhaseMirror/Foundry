#[cfg(test)]
mod tests {
    use crate::ahmad_packet::{AhmadPacket, DomainPredicate, DriftCertificate, SubleqDelta, TissueBlock, WormLog, jubilee_admissible};
    use crate::reg_hom_manager::{CryptoAnchors, RegHomManager, MorphismRecord};
    use crate::translation::TranslationLayer;

    // Helper to generate a valid crypto anchor stub
    fn valid_anchors() -> CryptoAnchors {
        CryptoAnchors {
            sha256_hash: [0u8; 32],
            ed25519_sig: vec![0u8; 64],
        }
    }

    // Helper to initialize a WORM Log with known tissue states
    fn setup_worm_log() -> WormLog {
        WormLog {
            blocks: vec![
                TissueBlock { tissue_id: 1, tick: 100, thickness: 50 },
                TissueBlock { tissue_id: 2, tick: 108, thickness: 75 },
            ]
        }
    }

    // Helper to initialize RegHom with a valid pathway
    fn setup_reghom() -> RegHomManager {
        let mut manager = RegHomManager::new();
        // AVP to Prime maps to (2, 3) for empty AVP data in our simple hashing
        let pred = DomainPredicate { avp_data: vec![], vp_data: vec![1] };
        let (src, tgt) = TranslationLayer::translate_predicate(&pred);
        
        manager.insert_morphism(
            src, tgt, 
            MorphismRecord {
                lam_certificate: [0u8; 32],
                merkle_root: [0u8; 32],
                crypto_anchors: valid_anchors(),
                expiration_tick: 200, // Valid until tick 200
            }
        );
        manager
    }

    // Base template for an Ahmad Packet
    fn base_packet() -> AhmadPacket {
        AhmadPacket {
            delta: SubleqDelta { a: 0, b: 1 },
            predicates: DomainPredicate { avp_data: vec![], vp_data: vec![1] },
            drift_certificate: DriftCertificate { tissue_id: 1, tick: 100, claimed_thickness: 50 },
            twin_signature: valid_anchors(),
        }
    }

    #[test]
    fn test_valid_packet_admitted() {
        let log = setup_worm_log();
        let packet = base_packet();
        // Current tick is 105, Delta_J is 108. Window is [0, 108)
        assert!(jubilee_admissible(&packet.drift_certificate, 105, 108, &log));
    }

    #[test]
    fn test_vector_1_stale_tick() {
        let log = setup_worm_log();
        let mut packet = base_packet();
        packet.drift_certificate.tick = 99; // Assume window is [100, 200)
        
        // Current tick is 105, Delta_J is 100. Window is [100, 200)
        let admitted = jubilee_admissible(&packet.drift_certificate, 105, 100, &log);
        assert!(!admitted, "Expected false positive for stale tick");
    }

    #[test]
    fn test_vector_2_thickness_mismatch() {
        let log = setup_worm_log();
        let mut packet = base_packet();
        packet.drift_certificate.claimed_thickness = 999; // Log has 50
        
        let admitted = jubilee_admissible(&packet.drift_certificate, 105, 108, &log);
        assert!(!admitted, "Expected false positive for thickness mismatch");
    }

    #[test]
    fn test_vector_3_invalid_tissue_id() {
        let log = setup_worm_log();
        let mut packet = base_packet();
        packet.drift_certificate.tissue_id = 99; // Not in log
        
        let admitted = jubilee_admissible(&packet.drift_certificate, 105, 108, &log);
        assert!(!admitted, "Expected false positive for invalid tissue ID");
    }

    #[test]
    fn test_vector_4_unregistered_morphism() {
        let reghom = setup_reghom();
        // Unknown mapping
        let unknown_pred = DomainPredicate { avp_data: vec![9, 9], vp_data: vec![9, 9] };
        let (src, tgt) = TranslationLayer::translate_predicate(&unknown_pred);
        
        // Lookup fails
        let lookup = reghom.reg_hom_lookup(src, tgt, 105);
        assert!(lookup.is_none(), "Expected lookup to fail for unregistered morphism");
    }

    #[test]
    fn test_vector_5_expired_morphism() {
        let mut reghom = RegHomManager::new();
        let pred = DomainPredicate { avp_data: vec![], vp_data: vec![] };
        let (src, tgt) = TranslationLayer::translate_predicate(&pred);
        
        reghom.insert_morphism(
            src, tgt, 
            MorphismRecord {
                lam_certificate: [0u8; 32],
                merkle_root: [0u8; 32],
                crypto_anchors: valid_anchors(),
                expiration_tick: 50, // Expired
            }
        );
        
        // Current tick is 100
        let lookup = reghom.reg_hom_lookup(src, tgt, 100);
        assert!(lookup.is_none(), "Expected lookup to fail for expired morphism");
    }
}