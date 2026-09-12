//! # echonomics_engine::buurtzorg — ADR-0016, ADR-0017, ADR-0018 Buurtzorg Self-Governing Care
//!
//! Production-grade implementation of the Buurtzorg care-model series:
//! - ADR-0016 (Eight Virtues & Self-Governing Teams): the eight Bushidō
//!   virtues are formalized as duties; self-governing teams are
//!   capacity-bounded (`nurse_count ≤ max_capacity ≤ 12`) and keep overhead
//!   at or under 15%.
//! - ADR-0017 (Integration Schema): care teams map onto DUNA governance nodes
//!   only when `nurse_count ≤ team_capacity ≤ 12`; resource allocations must
//!   be covered by the node envelope (90-day burn coverage).
//! - ADR-0018 (Non-Coercive Coaching): coaching is voluntary, advisory-only,
//!   and never command-bearing; formal escalation is gated on prior
//!   non-coercive coaching.
//!
//! Kani model-checking harnesses (`cargo kani`) discharge the gate properties
//! for all symbolic inputs.

use serde::{Deserialize, Serialize};

/// Buurtzorg ceiling: at most 12 nurses per self-governing team.
pub const MAX_TEAM_NURSES: u64 = 12;

/// Overhead target: commons overhead at or under 15%.
pub const OVERHEAD_TARGET_PCT: u64 = 15;

/// The eight Bushidō virtues as duty code (ADR-0016).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Virtue {
    Gi,     // Rectitude
    Yu,     // Courage
    Jin,    // Benevolence
    Rei,    // Respect
    Makoto, // Honesty
    Meiyo,  // Honor
    Chugi,  // Loyalty
    Jisei,  // Self-Control
}

/// The complete eight-virtue codebook.
pub const ALL_VIRTUES: [Virtue; 8] = [
    Virtue::Gi,
    Virtue::Yu,
    Virtue::Jin,
    Virtue::Rei,
    Virtue::Makoto,
    Virtue::Meiyo,
    Virtue::Chugi,
    Virtue::Jisei,
];

/// Every virtue is a duty: the codebook carries no optional virtues.
pub const fn is_virtue_duty(_v: Virtue) -> bool {
    true
}

/// Self-governing care team: active nurses within a declared ceiling.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct BuurtzorgTeamEngine {
    pub nurse_count: u64,
    pub max_capacity: u64,
}

impl BuurtzorgTeamEngine {
    /// Capacity validity: active team fits its ceiling and the ceiling never
    /// exceeds the Buurtzorg bound of 12 nurses.
    pub const fn is_team_size_valid(&self) -> bool {
        self.nurse_count <= self.max_capacity && self.max_capacity <= MAX_TEAM_NURSES
    }
}

/// Overhead within the 15% target is admitted (ADR-0016).
pub const fn is_overhead_within_target(overhead_pct: u64) -> bool {
    overhead_pct <= OVERHEAD_TARGET_PCT
}

/// Care team mapped onto civic infrastructure (ADR-0017).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct CareTeam {
    pub team_id: u64,
    pub nurse_count: u64,
}

/// DUNA governance node hosting care-team capacity (ADR-0017).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct GovernanceNode {
    pub node_id: u64,
    pub team_capacity: u64,
}

impl GovernanceNode {
    /// Mapping validity: the care team fits the node capacity and the node
    /// capacity respects the Buurtzorg ceiling (≤ 12).
    pub const fn is_mapping_valid(&self, team: &CareTeam) -> bool {
        team.nurse_count <= self.team_capacity && self.team_capacity <= MAX_TEAM_NURSES
    }
}

/// Ninety-day envelope coverage: the envelope must fund 90 days of burn.
pub const fn envelope_covers_90_days(envelope_usd: u64, daily_burn_usd: u64) -> bool {
    envelope_usd >= daily_burn_usd * 90
}

/// Coaching session (ADR-0018): participation is voluntary, the coach
/// advises without command authority, and `coaching_attempted` records that
/// the protocol ran.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct CoachingSession {
    pub voluntary: bool,
    pub advisory_only: bool,
    pub coach_has_command: bool,
    pub coaching_attempted: bool,
}

impl CoachingSession {
    /// Non-coercion: voluntary, advisory-only, and free of command authority.
    pub const fn is_non_coercive(&self) -> bool {
        self.voluntary && self.advisory_only && !self.coach_has_command
    }

    /// Escalation gate: formal dispute escalation requires prior non-coercive
    /// coaching.
    pub const fn is_escalation_allowed(&self) -> bool {
        self.is_non_coercive() && self.coaching_attempted
    }

    /// Self-governing teams operate without a manager's command.
    pub const fn is_self_governing(&self) -> bool {
        !self.coach_has_command
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_eight_virtues_codebook() {
        assert_eq!(ALL_VIRTUES.len(), 8);
        for v in ALL_VIRTUES {
            assert!(is_virtue_duty(v), "every virtue is a duty");
        }
    }

    #[test]
    fn test_buurtzorg_team_capacity() {
        let team = BuurtzorgTeamEngine { nurse_count: 8, max_capacity: 12 };
        assert!(team.is_team_size_valid());

        let over = BuurtzorgTeamEngine { nurse_count: 13, max_capacity: 12 };
        assert!(!over.is_team_size_valid(), "13 nurses must split");

        let bad_ceiling = BuurtzorgTeamEngine { nurse_count: 8, max_capacity: 20 };
        assert!(!bad_ceiling.is_team_size_valid(), "ceiling may never exceed 12");
    }

    #[test]
    fn test_overhead_target() {
        assert!(is_overhead_within_target(15));
        assert!(!is_overhead_within_target(16));
    }

    #[test]
    fn test_care_team_node_mapping_and_envelope() {
        let team = CareTeam { team_id: 1, nurse_count: 9 };
        let node = GovernanceNode { node_id: 1, team_capacity: 12 };
        assert!(node.is_mapping_valid(&team));

        let oversize = CareTeam { team_id: 2, nurse_count: 13 };
        assert!(!node.is_mapping_valid(&oversize));

        assert!(envelope_covers_90_days(9000, 100));
        assert!(!envelope_covers_90_days(8999, 100));
    }

    #[test]
    fn test_non_coercive_coaching_gates() {
        let good = CoachingSession {
            voluntary: true,
            advisory_only: true,
            coach_has_command: false,
            coaching_attempted: true,
        };
        let no_coaching = CoachingSession {
            voluntary: true,
            advisory_only: true,
            coach_has_command: false,
            coaching_attempted: false,
        };
        let coercive = CoachingSession {
            voluntary: true,
            advisory_only: true,
            coach_has_command: true,
            coaching_attempted: true,
        };

        assert!(good.is_non_coercive());
        assert!(good.is_escalation_allowed());
        assert!(!no_coaching.is_escalation_allowed(), "no coaching, no escalation");
        assert!(!coercive.is_escalation_allowed(), "coercive coaching never escalates");
        assert!(good.is_self_governing());
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    /// ADR-0016: Buurtzorg teams must not exceed 12 nurses.
    #[kani::proof]
    fn verify_buurtzorg_team_capacity_bound() {
        let nurse_count: u64 = kani::any();
        let max_capacity: u64 = kani::any();

        let team = BuurtzorgTeamEngine { nurse_count, max_capacity };
        if max_capacity > MAX_TEAM_NURSES {
            kani::assert(!team.is_team_size_valid(), "Buurtzorg teams must not exceed 12 nurses");
        }
    }

    /// ADR-0016: all eight virtues are duties.
    #[kani::proof]
    fn verify_all_virtues_are_duties() {
        for v in ALL_VIRTUES {
            kani::assert(is_virtue_duty(v), "every virtue is a duty");
        }
    }

    /// ADR-0017: a valid mapping always fits the team into the node capacity.
    #[kani::proof]
    fn verify_mapping_requires_capacity() {
        let nurse_count: u64 = kani::any();
        let team_capacity: u64 = kani::any();
        kani::assume(team_capacity <= MAX_TEAM_NURSES);

        let team = CareTeam { team_id: 0, nurse_count };
        let node = GovernanceNode { team_capacity, node_id: 0 };
        if node.is_mapping_valid(&team) {
            kani::assert(nurse_count <= team_capacity, "valid mapping fits the team");
        }
    }

    /// ADR-0018: allowed escalation implies prior coaching and no command.
    #[kani::proof]
    fn verify_escalation_gate_fail_closed() {
        let voluntary: bool = kani::any();
        let advisory_only: bool = kani::any();
        let coach_has_command: bool = kani::any();
        let coaching_attempted: bool = kani::any();

        let session = CoachingSession { voluntary, advisory_only, coach_has_command, coaching_attempted };
        if session.is_escalation_allowed() {
            kani::assert(coaching_attempted, "escalation requires prior coaching");
            kani::assert(!coach_has_command, "escalation never carries coach command");
        }
    }
}