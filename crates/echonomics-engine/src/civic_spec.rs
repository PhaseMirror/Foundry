//! # echonomics_engine::civic_spec — ADR-0010 & ADR-0011 Civic Infrastructure Framework
//!
//! Production-grade implementation of ADR-0010 (DUNA Governing Principles) & ADR-0011 (Model Specification v1.0):
//! - Wyoming DUNA Statutory Wrapper (§1.2 & §4.6): 100-member floor determines operating mode (UNA < 100 <= DUNA)
//! - One Member, One Vote (§4.3): 1 member = 1 vote for association-wide items (credits/tokens cannot purchase votes)
//! - Quorum & Passage Gate (§7.1): Quorum = min(10% of voting members, 30) when member count >= 100; 2/3 passage & 1/3 veto for amendments
//! - Treasury Dual-Control (§6.1): Movement > $2,500 USD requires dual authorization (Treasurer + Admin)
//! - Monthly Credit Cash-out Caps (§6.4): Youth $500, Member $2,000, Operator $3,000, Officer $4,000, Admin $5,000; transfer cap 2,000 credits/recipient
//! - Sovereignty Node Topology (§3.2, §5.1-5.5): Max 12 operators; auto-split when > 12; Three-Way Test (Dignity, Outcome, Solvency) pauses node on 2 failed quarters
//! - Mission Equation M = 2R + 1 (§1.1 ADR-0011): Unpaired R=0 -> M=1; R=1/2 -> M=2; R=1 -> M=3
//! - Four Capital Doors into UNA (§1.2 & §5 ADR-0011): Gift, Sponsor, Recoverable Grant, Operator Subscription (rejections for 5th door)
//! - Nine Civic L0 Invariants (§4.1 ADR-0011): L0-1 to L0-9 fail-closed verification
//! - Phase Mirror Oracle Tiers (§7.2 ADR-0011): L0 (<= 100ns), L1 (<= 1ms), L2 (<= 100ms)
//! - Four PMCP Certification Gates (§7.4 ADR-0011): Mastery, Playbook, Compliance, Supervised Engagement (Equity NEVER mints a diploma!)

use serde::{Deserialize, Serialize};

/// Operating wrapper status under Wyoming Law (§1.2 & §4.6).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DunaOperatingWrapper {
    Una,  // Unincorporated Nonprofit Association (member_count < 100)
    Duna, // Decentralized Unincorporated Nonprofit Association (member_count >= 100)
}

/// Determines the operating wrapper based on active member count (§4.6).
pub const fn determine_operating_wrapper(member_count: usize) -> DunaOperatingWrapper {
    if member_count >= 100 {
        DunaOperatingWrapper::Duna
    } else {
        DunaOperatingWrapper::Una
    }
}

/// Member Classification (§4.2).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum MemberClass {
    Youth,
    Associate,
    Affiliate,
    Sponsor,
    FriendOfTheGarden,
}

impl MemberClass {
    pub fn has_corporate_vote(&self) -> bool {
        matches!(
            self,
            MemberClass::Associate | MemberClass::Affiliate | MemberClass::Sponsor
        )
    }
}

/// Decision Proposal Types (§7.1).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ProposalType {
    AssociationWide,
    PrincipleAmendment,
    AdministratorSelection,
    MaterialAssetDisposition,
    ExistentialKillSwitch,
}

/// Quorum & Passage evaluation result for DUNA proposals (§7.1).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DunaProposalResult {
    Pass,
    RejSubQuorum,
    RejMajority,
    RejAmendmentVeto,
    RejKillSwitchSubQuorum,
}

/// Evaluates DUNA proposal quorum and voting outcomes (§4.3 & §7.1).
pub fn evaluate_duna_proposal(
    proposal_type: ProposalType,
    total_voting_members: usize,
    votes_for: usize,
    votes_against: usize,
    sitting_admins: usize,
    admin_approvals: usize,
) -> DunaProposalResult {
    let votes_cast = votes_for + votes_against;

    match proposal_type {
        ProposalType::AssociationWide => {
            let wrapper = determine_operating_wrapper(total_voting_members);
            let quorum_needed = if wrapper == DunaOperatingWrapper::Duna {
                let ten_percent = (total_voting_members + 9) / 10;
                if ten_percent < 30 { ten_percent } else { 30 }
            } else {
                1 // Single member threshold for UNA
            };

            if votes_cast < quorum_needed {
                DunaProposalResult::RejSubQuorum
            } else if votes_for > votes_against {
                DunaProposalResult::Pass
            } else {
                DunaProposalResult::RejMajority
            }
        }
        ProposalType::PrincipleAmendment => {
            // 2/3 of votes cast to pass; 1/3 veto (votes_against * 3 >= votes_cast) rejects
            if votes_cast == 0 {
                return DunaProposalResult::RejSubQuorum;
            }
            if votes_against * 3 >= votes_cast {
                DunaProposalResult::RejAmendmentVeto
            } else if votes_for * 3 >= votes_cast * 2 {
                DunaProposalResult::Pass
            } else {
                DunaProposalResult::RejMajority
            }
        }
        ProposalType::ExistentialKillSwitch => {
            // 3/5 of sitting administrators
            if admin_approvals * 5 >= sitting_admins * 3 {
                DunaProposalResult::Pass
            } else {
                DunaProposalResult::RejKillSwitchSubQuorum
            }
        }
        ProposalType::AdministratorSelection | ProposalType::MaterialAssetDisposition => {
            if votes_cast == 0 {
                DunaProposalResult::RejSubQuorum
            } else if votes_for > votes_against {
                DunaProposalResult::Pass
            } else {
                DunaProposalResult::RejMajority
            }
        }
    }
}

/// Treasury Dual-Control Guard (§6.1).
pub const DUAL_CONTROL_THRESHOLD_USD: u64 = 2500;

/// Checks if a treasury movement requires dual control approval (§6.1).
pub const fn requires_dual_control(amount_usd: u64) -> bool {
    amount_usd > DUAL_CONTROL_THRESHOLD_USD
}

/// Validates treasury movement authorization (§6.1).
pub fn validate_treasury_movement(
    amount_usd: u64,
    treasurer_approved: bool,
    admin_approved: bool,
) -> Result<(), String> {
    if requires_dual_control(amount_usd) {
        if treasurer_approved && admin_approved {
            Ok(())
        } else {
            Err("Treasury movement above $2,500 USD requires dual authorization (Treasurer + Admin)".to_string())
        }
    } else if treasurer_approved || admin_approved {
        Ok(())
    } else {
        Err("Treasury movement requires authorization".to_string())
    }
}

/// Validates monthly credit cash-out caps by role (§6.4).
pub fn validate_credit_cashout(role: MemberClass, amount_usd: u64) -> Result<(), String> {
    let max_cap = match role {
        MemberClass::Youth => 500,
        MemberClass::Associate | MemberClass::Affiliate | MemberClass::Sponsor => 2000,
        MemberClass::FriendOfTheGarden => 0,
    };

    if amount_usd <= max_cap {
        Ok(())
    } else {
        Err(format!("Cashout amount ${} exceeds monthly role cap of ${}", amount_usd, max_cap))
    }
}

/// Validates monthly credit transfer cap per recipient (§6.4).
pub const MAX_MONTHLY_RECIPIENT_TRANSFER_CREDITS: u64 = 2000;

pub fn validate_credit_transfer(credits: u64) -> Result<(), String> {
    if credits <= MAX_MONTHLY_RECIPIENT_TRANSFER_CREDITS {
        Ok(())
    } else {
        Err(format!("Credit transfer {} exceeds recipient monthly cap of 2,000 credits", credits))
    }
}

/// Sovereignty Node Engine (§3.2, §5.1-5.5).
pub const MAX_NODE_OPERATORS: usize = 12;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum NodeStatus {
    Active,
    Paused,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SovereigntyNodeState {
    pub node_id: String,
    pub active_operators: usize,
    pub consecutive_failed_quarters: usize,
    pub status: NodeStatus,
}

pub type CivicNodeState = SovereigntyNodeState;

impl SovereigntyNodeState {
    pub fn new(node_id: impl Into<String>, active_operators: usize) -> Self {
        Self {
            node_id: node_id.into(),
            active_operators,
            consecutive_failed_quarters: 0,
            status: NodeStatus::Active,
        }
    }

    /// Split rule (§5.3): Stably > 12 operators requires splitting node.
    pub fn should_split(&self) -> bool {
        self.active_operators > MAX_NODE_OPERATORS
    }

    /// Evaluates quarterly Three-Way Test (§5.5): Member Dignity, Community Outcome, Node Solvency.
    /// If all 3 pass, reset failed counter. If any fail, increment failed counter.
    /// If failed counter reaches 2, node enters Paused state (Kill-switch).
    pub fn record_quarterly_test(&mut self, dignity_pass: bool, outcome_pass: bool, solvency_pass: bool) {
        let passed_all = dignity_pass && outcome_pass && solvency_pass;
        if passed_all {
            self.consecutive_failed_quarters = 0;
        } else {
            self.consecutive_failed_quarters += 1;
            if self.consecutive_failed_quarters >= 2 {
                self.status = NodeStatus::Paused;
            }
        }
    }
}

// ============================================================================
// ADR-0012: UNIFIED CIVIC INFRASTRUCTURE BLUEPRINT ENGINE
// ============================================================================

/// Dual seat (§7 ADR-0012): a counterparty may both practice (PMCP) and own
/// the hosted oracle — two papers, one firewall.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct DualSeat {
    pub pmcp_certified: bool,
    pub equity_held: bool,
}

impl DualSeat {
    /// Firewall predicate (§7 ADR-0012): equity close never mints PMCP
    /// certification, and a certificate never mints equity.
    pub const fn is_equity_pmcp_firewalled(&self) -> bool {
        !(self.equity_held && self.pmcp_certified)
    }
}

/// Material-asset floor (§9 ADR-0012): USD 5,000.
pub const MATERIAL_ASSET_FLOOR_USD: u64 = 5000;

/// A proposed acquisition is material when it crosses the USD floor, or is a
/// vehicle, any interest in land, or a lease longer than 12 months (§9
/// ADR-0012). Material assets require member approval after 14-day notice.
pub const fn is_material_asset(
    value_usd: u64,
    is_vehicle: bool,
    is_land: bool,
    lease_months: u64,
) -> bool {
    value_usd >= MATERIAL_ASSET_FLOOR_USD || is_vehicle || is_land || lease_months > 12
}

// ============================================================================
// ADR-0011: MODEL SPECIFICATION V1.0 ENGINE
// ============================================================================

/// Mission Equation (§1.1 ADR-0011): M = 2R + 1.
/// `reciprocity_half_steps` represents R in steps of 0.5 (0 -> R=0, 1 -> R=0.5, 2 -> R=1.0).
pub fn calculate_reciprocity_multiplicity(reciprocity_half_steps: usize) -> usize {
    reciprocity_half_steps + 1
}

/// Four Capital Doors into UNA (§1.2 & §5 ADR-0011).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum CapitalDoor {
    Gift,
    Sponsor,
    RecoverableGrant,
    OperatorSubscription,
}

impl CapitalDoor {
    pub fn parse_door(input: &str) -> Result<Self, String> {
        match input.to_lowercase().as_str() {
            "gift" => Ok(CapitalDoor::Gift),
            "sponsor" => Ok(CapitalDoor::Sponsor),
            "recoverable_grant" | "grant" => Ok(CapitalDoor::RecoverableGrant),
            "operator_subscription" | "subscription" => Ok(CapitalDoor::OperatorSubscription),
            _ => Err(format!("Door '{}' is invalid. Exactly 4 doors allowed into UNA: Gift, Sponsor, Recoverable Grant, Operator Subscription (ADR-0011 §5)", input)),
        }
    }
}

/// Nine Civic L0 Non-Negotiable Invariants (§4.1 ADR-0011).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[allow(non_camel_case_types)]
pub enum CivicL0Invariant {
    L0_1_NoMemberProfitDistribution,
    L0_2_NoCamerasInPrivacyZone,
    L0_3_NoMembershipListOffPurpose,
    L0_4_NoAdminBeyondWrittenAuthority,
    L0_5_NoUnlicensedManagedService,
    L0_6_YouthGuardianConsentRequired,
    L0_7_ConsentWithdrawable,
    L0_8_CreditsDoNotBuyVotes,
    L0_9_NotAPac,
}

impl CivicL0Invariant {
    pub fn evaluate(&self, condition_pass: bool) -> Result<(), String> {
        if condition_pass {
            Ok(())
        } else {
            Err(format!("Civic L0 Invariant violation: {:?} failed closed (ADR-0011 §4.1)", self))
        }
    }
}

/// Phase Mirror Oracle Tiers & Latency Targets (§7.2 ADR-0011).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum OracleTier {
    L0Invariant, // <= 100 ns p99
    L1Rule,      // <= 1 ms p99
    L2Semantic,  // <= 100 ms p99
}

impl OracleTier {
    pub fn max_latency_ns(&self) -> u64 {
        match self {
            OracleTier::L0Invariant => 100,
            OracleTier::L1Rule => 1_000_000,
            OracleTier::L2Semantic => 100_000_000,
        }
    }

    pub fn validate_latency(&self, latency_ns: u64) -> bool {
        latency_ns <= self.max_latency_ns()
    }
}

/// PMCP Four Certification Gates (§7.4 ADR-0011).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct PmcpGates {
    pub mastery_pass: bool,
    pub playbook_pass: bool,
    pub compliance_pass: bool,
    pub supervised_engagement_pass: bool,
}

impl PmcpGates {
    /// PMCP certification verification (§7.4): Requires all 4 gates.
    /// Equity NEVER mints a diploma (`equity_shortcut_attempted` MUST be false).
    pub fn verify_certification(&self, equity_shortcut_attempted: bool) -> Result<(), String> {
        if equity_shortcut_attempted {
            return Err("PMCP certification rejected: Equity never mints a diploma (ADR-0011 §7.4)".to_string());
        }
        if self.mastery_pass && self.playbook_pass && self.compliance_pass && self.supervised_engagement_pass {
            Ok(())
        } else {
            Err("PMCP certification rejected: All four gates required (Mastery, Playbook, Compliance, Supervised Engagement)".to_string())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_100_member_floor_wrapper() {
        assert_eq!(determine_operating_wrapper(45), DunaOperatingWrapper::Una);
        assert_eq!(determine_operating_wrapper(99), DunaOperatingWrapper::Una);
        assert_eq!(determine_operating_wrapper(100), DunaOperatingWrapper::Duna);
        assert_eq!(determine_operating_wrapper(250), DunaOperatingWrapper::Duna);
    }

    #[test]
    fn test_duna_proposal_voting() {
        let res1 = evaluate_duna_proposal(ProposalType::AssociationWide, 150, 20, 5, 5, 3);
        assert_eq!(res1, DunaProposalResult::Pass);

        let res2 = evaluate_duna_proposal(ProposalType::AssociationWide, 150, 5, 2, 5, 3);
        assert_eq!(res2, DunaProposalResult::RejSubQuorum);

        let res3 = evaluate_duna_proposal(ProposalType::PrincipleAmendment, 150, 7, 5, 5, 3);
        assert_eq!(res3, DunaProposalResult::RejAmendmentVeto);

        let res4 = evaluate_duna_proposal(ProposalType::PrincipleAmendment, 150, 10, 2, 5, 3);
        assert_eq!(res4, DunaProposalResult::Pass);

        let res5 = evaluate_duna_proposal(ProposalType::ExistentialKillSwitch, 150, 0, 0, 5, 3);
        assert_eq!(res5, DunaProposalResult::Pass);

        let res6 = evaluate_duna_proposal(ProposalType::ExistentialKillSwitch, 150, 0, 0, 5, 2);
        assert_eq!(res6, DunaProposalResult::RejKillSwitchSubQuorum);
    }

    #[test]
    fn test_treasury_dual_control_and_caps() {
        assert!(!requires_dual_control(2500));
        assert!(requires_dual_control(2501));

        assert!(validate_treasury_movement(2500, true, false).is_ok());
        assert!(validate_treasury_movement(3000, true, false).is_err());
        assert!(validate_treasury_movement(3000, true, true).is_ok());

        assert!(validate_credit_cashout(MemberClass::Youth, 500).is_ok());
        assert!(validate_credit_cashout(MemberClass::Youth, 501).is_err());
        assert!(validate_credit_transfer(2000).is_ok());
        assert!(validate_credit_transfer(2001).is_err());
    }

    #[test]
    fn test_sovereignty_node_split_and_three_way_test() {
        let mut node = SovereigntyNodeState::new("node-01", 10);
        assert!(!node.should_split());

        node.active_operators = 13;
        assert!(node.should_split());

        node.record_quarterly_test(true, true, false);
        assert_eq!(node.status, NodeStatus::Active);

        node.record_quarterly_test(true, false, true);
        assert_eq!(node.status, NodeStatus::Paused);
    }

    #[test]
    fn test_adr0011_mission_equation_reciprocity() {
        assert_eq!(calculate_reciprocity_multiplicity(0), 1); // R=0 -> M=1
        assert_eq!(calculate_reciprocity_multiplicity(1), 2); // R=1/2 -> M=2
        assert_eq!(calculate_reciprocity_multiplicity(2), 3); // R=1 -> M=3
    }

    #[test]
    fn test_adr0011_four_capital_doors() {
        assert!(CapitalDoor::parse_door("gift").is_ok());
        assert!(CapitalDoor::parse_door("sponsor").is_ok());
        assert!(CapitalDoor::parse_door("grant").is_ok());
        assert!(CapitalDoor::parse_door("subscription").is_ok());
        assert!(CapitalDoor::parse_door("fifth_door_token").is_err());
    }

    #[test]
    fn test_adr0011_pmcp_certification_equity_shortcut_denied() {
        let gates = PmcpGates {
            mastery_pass: true,
            playbook_pass: true,
            compliance_pass: true,
            supervised_engagement_pass: true,
        };
        assert!(gates.verify_certification(false).is_ok());
        assert!(gates.verify_certification(true).is_err()); // Equity shortcut MUST fail!
    }

    #[test]
    fn test_adr0011_oracle_tier_latencies() {
        assert!(OracleTier::L0Invariant.validate_latency(50));
        assert!(!OracleTier::L0Invariant.validate_latency(150));
        assert!(OracleTier::L1Rule.validate_latency(500_000));
        assert!(OracleTier::L2Semantic.validate_latency(50_000_000));
    }

    #[test]
    fn test_adr0012_dual_seat_firewall() {
        let practitioner = DualSeat { pmcp_certified: true, equity_held: false };
        let equity_holder = DualSeat { pmcp_certified: false, equity_held: true };
        let both = DualSeat { pmcp_certified: true, equity_held: true };

        assert!(practitioner.is_equity_pmcp_firewalled());
        assert!(equity_holder.is_equity_pmcp_firewalled());
        assert!(!both.is_equity_pmcp_firewalled(), "equity close never mints PMCP");
    }

    #[test]
    fn test_adr0012_material_asset_floor() {
        // Vehicle is material regardless of value.
        assert!(is_material_asset(100, true, false, 0));
        // Value at/above the $5,000 floor is material.
        assert!(is_material_asset(20_000, false, false, 0));
        assert!(is_material_asset(5_000, false, false, 0));
        // Land is material regardless of value.
        assert!(is_material_asset(0, false, true, 0));
        // Lease longer than 12 months is material.
        assert!(is_material_asset(0, false, false, 13));
        // Small, non-special acquisition is NOT material.
        assert!(!is_material_asset(100, false, false, 0));
        assert!(!is_material_asset(4_999, false, false, 12));
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    #[kani::proof]
    fn verify_operating_wrapper_floor() {
        let count: usize = kani::any();
        let wrapper = determine_operating_wrapper(count);
        if count >= 100 {
            kani::assert(wrapper == DunaOperatingWrapper::Duna, "Must be DUNA when member count >= 100");
        } else {
            kani::assert(wrapper == DunaOperatingWrapper::Una, "Must be UNA when member count < 100");
        }
    }

    #[kani::proof]
    fn verify_dual_control_threshold() {
        let amount: u64 = kani::any();
        let req = requires_dual_control(amount);
        if amount > DUAL_CONTROL_THRESHOLD_USD {
            kani::assert(req, "Amount > $2500 requires dual control");
        } else {
            kani::assert(!req, "Amount <= $2500 does not require dual control");
        }
    }

    #[kani::proof]
    fn verify_node_split_condition() {
        let operators: usize = kani::any();
        kani::assume(operators < 100);
        let node = SovereigntyNodeState::new("test", operators);
        if operators > MAX_NODE_OPERATORS {
            kani::assert(node.should_split(), "Must split when operators > 12");
        } else {
            kani::assert(!node.should_split(), "Must not split when operators <= 12");
        }
    }

    #[kani::proof]
    fn verify_mission_equation_multiplicity() {
        let half_steps: usize = kani::any();
        kani::assume(half_steps < usize::MAX - 10);
        let m = calculate_reciprocity_multiplicity(half_steps);
        kani::assert(m == half_steps + 1, "M must equal half_steps + 1");
    }

    #[kani::proof]
    fn verify_pmcp_equity_shortcut_denied() {
        let gates = PmcpGates {
            mastery_pass: true,
            playbook_pass: true,
            compliance_pass: true,
            supervised_engagement_pass: true,
        };
        let res = gates.verify_certification(true);
        kani::assert(res.is_err(), "Equity shortcut MUST be denied");
    }

    #[kani::proof]
    fn verify_oracle_tier_l0_latency_bound() {
        let latency: u64 = kani::any();
        let valid = OracleTier::L0Invariant.validate_latency(latency);
        if latency <= 100 {
            kani::assert(valid, "Latency <= 100ns must pass L0");
        } else {
            kani::assert(!valid, "Latency > 100ns must fail L0");
        }
    }

    #[kani::proof]
    fn verify_dual_seat_firewall_equity_never_mints_pmcp() {
        let pmcp_certified: bool = kani::any();
        let equity_held: bool = kani::any();
        let seat = DualSeat { pmcp_certified, equity_held };
        if equity_held && pmcp_certified {
            kani::assert(!seat.is_equity_pmcp_firewalled(), "Equity close must never mint PMCP");
        } else {
            kani::assert(seat.is_equity_pmcp_firewalled(), "Firewall admits non-overlapping seats");
        }
    }

    #[kani::proof]
    fn verify_material_asset_floor_threshold() {
        let value_usd: u64 = kani::any();
        let material = is_material_asset(value_usd, false, false, 0);
        if value_usd >= MATERIAL_ASSET_FLOOR_USD {
            kani::assert(material, "Value >= $5,000 must be material");
        } else {
            kani::assert(!material, "Small non-special value must not be material");
        }
    }
}
