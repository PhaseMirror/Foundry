//! # echonomics_engine::v4p_wada — ADR-0042 & ADR-0043 Execution Engine
//!
//! Production-grade implementation of V4P-VSAM Vector-State Addressing (ADR-0042) & WADA-LADA Distributed Agent Topology (ADR-0043):
//! - V4P Address (§4.2 ADR-0042): 32-bit IPv4-shaped vector pair state address (`octet0.octet1.octet2.octet3`)
//! - Nibble Pair Extraction: 8 coordinates (0..15) per V4P address
//! - CIDR-style Semantic Prefix Matching (`matches_prefix`)
//! - LADA Domain (§4 ADR-0043): Private site-local fabric of agents, memory nodes, and resolvers
//! - WADA Domain (§4 ADR-0043): Federation of 2 or more LADAs across cloud regions
//! - HLCA & HWCA Root Election (§8 ADR-0043): Deterministic central-agent coordination & spanning-tree loop prevention
//! - Demarcation Gateways (§13 ADR-0043): Fail-closed quarantine gate for unauthenticated or uncertified state routes

use serde::{Deserialize, Serialize};

/// IPv4-shaped Vector Pair Address V4P (§4.2 ADR-0042).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct V4pAddress {
    pub octet0: u8,
    pub octet1: u8,
    pub octet2: u8,
    pub octet3: u8,
}

impl V4pAddress {
    pub const fn new(octet0: u8, octet1: u8, octet2: u8, octet3: u8) -> Self {
        Self { octet0, octet1, octet2, octet3 }
    }

    /// Converts 32-bit integer to V4pAddress.
    pub const fn from_u32(val: u32) -> Self {
        Self {
            octet0: ((val >> 24) & 0xFF) as u8,
            octet1: ((val >> 16) & 0xFF) as u8,
            octet2: ((val >> 8) & 0xFF) as u8,
            octet3: (val & 0xFF) as u8,
        }
    }

    /// Converts V4pAddress to 32-bit integer.
    pub const fn to_u32(&self) -> u32 {
        ((self.octet0 as u32) << 24)
            | ((self.octet1 as u32) << 16)
            | ((self.octet2 as u32) << 8)
            | (self.octet3 as u32)
    }

    /// Returns the 8 coordinates (0..15) from high and low nibbles of each octet.
    pub fn to_nibbles(&self) -> [u8; 8] {
        [
            (self.octet0 >> 4) & 0x0F, self.octet0 & 0x0F,
            (self.octet1 >> 4) & 0x0F, self.octet1 & 0x0F,
            (self.octet2 >> 4) & 0x0F, self.octet2 & 0x0F,
            (self.octet3 >> 4) & 0x0F, self.octet3 & 0x0F,
        ]
    }

    /// Checks if address matches CIDR prefix mask (§4.2 ADR-0042).
    pub fn matches_prefix(&self, target: &V4pAddress, prefix_bits: u8) -> bool {
        if prefix_bits == 0 {
            true
        } else if prefix_bits >= 32 {
            self.to_u32() == target.to_u32()
        } else {
            let mask = !((1u32 << (32 - prefix_bits)) - 1);
            (self.to_u32() & mask) == (target.to_u32() & mask)
        }
    }
}

/// Agent Domain Classification (§4 ADR-0043).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum AgentDomainType {
    Lada, // Local Area Distributed Agents (private site-local)
    Wada, // Wide Area Distributed Agents (federated inter-site)
}

/// Agent Role Classification (§4 ADR-0043).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum AgentRole {
    Hlca, // Hosted Local Central Agent
    Hwca, // Hosted Wide Central Agent
    WorkerAgent,
    MemoryResolver,
}

/// Root Election State for HLCA / HWCA (§8 ADR-0043).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RootElectionState {
    pub domain_id: String,
    pub domain_type: AgentDomainType,
    pub active_root_id: String,
    pub root_priority: u32,
    pub term_counter: u64,
}

impl RootElectionState {
    pub fn new(domain_id: impl Into<String>, domain_type: AgentDomainType, root_id: impl Into<String>, priority: u32) -> Self {
        Self {
            domain_id: domain_id.into(),
            domain_type,
            active_root_id: root_id.into(),
            root_priority: priority,
            term_counter: 1,
        }
    }

    /// Elects candidate as new root if candidate priority > current root priority (§8 ADR-0043).
    pub fn propose_root_candidate(&mut self, candidate_id: &str, candidate_priority: u32) -> bool {
        if candidate_priority > self.root_priority {
            self.active_root_id = candidate_id.to_string();
            self.root_priority = candidate_priority;
            self.term_counter += 1;
            true
        } else {
            false
        }
    }
}

/// Demarcation Gateway Route Authorization Gate (§13 ADR-0043).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum RouteDemarcationResult {
    PassAuthorizedRoute,
    RejUnsignedRoute,
    RejLoopDetected,
    RejQuarantine,
}

pub fn evaluate_route_demarcation(
    route_signed: bool,
    path_contains_self: bool,
    quarantine_flag: bool,
) -> RouteDemarcationResult {
    if quarantine_flag {
        RouteDemarcationResult::RejQuarantine
    } else if path_contains_self {
        RouteDemarcationResult::RejLoopDetected
    } else if !route_signed {
        RouteDemarcationResult::RejUnsignedRoute
    } else {
        RouteDemarcationResult::PassAuthorizedRoute
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_v4p_address_nibbles_and_cidr_matching() {
        let addr = V4pAddress::new(10, 81, 33, 47);
        assert_eq!(addr.to_u32(), 0x0A51212F);

        let nibbles = addr.to_nibbles();
        assert_eq!(nibbles, [0, 10, 5, 1, 2, 1, 2, 15]);

        let target = V4pAddress::new(10, 81, 0, 0);
        assert!(addr.matches_prefix(&target, 16));
        assert!(!addr.matches_prefix(&target, 24));
    }

    #[test]
    fn test_root_election_and_demarcation_gate() {
        let mut election = RootElectionState::new("lada-dubai", AgentDomainType::Lada, "hlca-01", 100);
        assert!(!election.propose_root_candidate("hlca-02", 90));
        assert!(election.propose_root_candidate("hlca-03", 150));
        assert_eq!(election.active_root_id, "hlca-03");

        assert_eq!(evaluate_route_demarcation(true, false, false), RouteDemarcationResult::PassAuthorizedRoute);
        assert_eq!(evaluate_route_demarcation(false, false, false), RouteDemarcationResult::RejUnsignedRoute);
        assert_eq!(evaluate_route_demarcation(true, true, false), RouteDemarcationResult::RejLoopDetected);
        assert_eq!(evaluate_route_demarcation(true, false, true), RouteDemarcationResult::RejQuarantine);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    #[kani::proof]
    fn verify_v4p_address_u32_roundtrip() {
        let val: u32 = kani::any();
        let addr = V4pAddress::from_u32(val);
        kani::assert(addr.to_u32() == val, "V4pAddress to_u32 roundtrip must be identity");
    }

    #[kani::proof]
    fn verify_route_demarcation_quarantine_priority() {
        let signed: bool = kani::any();
        let loop_det: bool = kani::any();
        let quar: bool = kani::any();

        let res = evaluate_route_demarcation(signed, loop_det, quar);
        if quar {
            kani::assert(res == RouteDemarcationResult::RejQuarantine, "Must reject quarantine first");
        } else if loop_det {
            kani::assert(res == RouteDemarcationResult::RejLoopDetected, "Must reject loop second");
        } else if !signed {
            kani::assert(res == RouteDemarcationResult::RejUnsignedRoute, "Must reject unsigned third");
        }
    }
}
