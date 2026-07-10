use bitflags::bitflags;

bitflags! {
    /// 8-bit enforcement state flags per ADR-032.
    ///
    /// Meaning of each bit:
    ///   R (0x01): Rollback - system rolled back from this state
    ///   C (0x02): Commit - changes committed locally
    ///   S (0x04): Sync - physical system synchronized with this state
    ///   B (0x08): Bounce - state rejected by enforcement gate
    ///   V (0x10): Verify - state passed all verification checks
    ///   T (0x20): Taint - state contains bad precedent
    ///   M (0x40): Mirror - state currently mirrored in digital twin
    ///   P_bad (0x80): Precedent_bad - problematic precedent reference
    #[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
    pub struct EnforcementBits: u8 {
        const ROLLBACK      = 0x01;
        const COMMIT        = 0x02;
        const SYNC          = 0x04;
        const BOUNCE        = 0x08;
        const VERIFY        = 0x10;
        const TAINT         = 0x20;
        const MIRROR        = 0x40;
        const PRECEDENT_BAD = 0x80;
    }
}

pub struct EnforcementLegitimacyPredicate;

impl EnforcementLegitimacyPredicate {
    /// Determines if an enforcement state is legitimate (valid).
    ///
    /// Per ADR-032, legitimate states satisfy all constraints:
    /// 1. Not (ROLLBACK && VERIFY): Rollback invalidates verification
    /// 2. Not (COMMIT && SYNC): Must transition COMMIT → SYNC, not simultaneous
    /// 3. TAINT implies BOUNCE: Tainted states are rejected
    /// 4. VERIFY implies SYNC: Cannot verify without syncing
    /// 5. Not (BOUNCE && VERIFY): Bounced states don't verify
    /// 6. PRECEDENT_BAD is consistent with other flags
    pub fn is_legitimate(bits: EnforcementBits) -> bool {
        // 1. Not (ROLLBACK && VERIFY)
        if bits.contains(EnforcementBits::ROLLBACK | EnforcementBits::VERIFY) {
            return false;
        }

        // 2. Not (COMMIT && SYNC)
        if bits.contains(EnforcementBits::COMMIT | EnforcementBits::SYNC) {
            return false;
        }

        // 3. TAINT implies BOUNCE
        if bits.contains(EnforcementBits::TAINT) && !bits.contains(EnforcementBits::BOUNCE) {
            return false;
        }

        // 4. VERIFY implies SYNC
        if bits.contains(EnforcementBits::VERIFY) && !bits.contains(EnforcementBits::SYNC) {
            return false;
        }

        // 5. Not (BOUNCE && VERIFY)
        if bits.contains(EnforcementBits::BOUNCE | EnforcementBits::VERIFY) {
            return false;
        }

        true
    }

    /// Evaluates if the state passes enforcement gates.
    pub fn is_enforceable(bits: EnforcementBits) -> bool {
        Self::is_legitimate(bits) && 
        bits.contains(EnforcementBits::VERIFY) &&
        !bits.contains(EnforcementBits::TAINT) &&
        !bits.contains(EnforcementBits::PRECEDENT_BAD)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EnforcementStateSnapshot {
    pub state_id: String,
    pub bits: EnforcementBits,
    pub timestamp: String,
    pub enforcement_depth: u32,
    pub validation_hash: Option<String>,
}

impl EnforcementStateSnapshot {
    pub fn new(
        state_id: String,
        bits: EnforcementBits,
        timestamp: String,
        enforcement_depth: u32,
        validation_hash: Option<String>,
    ) -> anyhow::Result<Self> {
        if state_id.is_empty() {
            anyhow::bail!("state_id required");
        }
        
        // Basic ISO8601 validation
        chrono::DateTime::parse_from_rfc3339(&timestamp)
            .map_err(|e| anyhow::anyhow!("timestamp must be valid ISO 8601: {}", e))?;

        Ok(Self {
            state_id,
            bits,
            timestamp,
            enforcement_depth,
            validation_hash,
        })
    }
}
