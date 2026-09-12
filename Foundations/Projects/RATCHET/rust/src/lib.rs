//! # RATCHET — The Intelligence Ratchet
//!
//! Production-grade reference implementation of ADR-0038 / ADR-0039 / Σ̄ Adversarial Twin:
//! A Dual-Mode Control Proposal for Bounded Recursive Growth.

pub mod adversarial_twin;
pub mod attacks;
pub mod controller;
pub mod estimators;
pub mod null_space;
pub mod phase_a_transformer_agent;
pub mod phase_c_adaptive_adversary;
pub mod phase_d_governance_halt;
pub mod phase_e_public_audit;
pub mod plant;
pub mod rate_cap;
pub mod receipt;
pub mod sandbox;
pub mod snapshot_store;
pub mod types;

pub use adversarial_twin::{AdversarialError, AdversarialTwin, ModificationProposal, PreCommitError, PreCommitGate};
pub use attacks::{AttackResult, RedTeamHarness};
pub use controller::{ControllerConfig, ExternalController};
pub use estimators::ExpansionEstimator;
pub use null_space::NullSpaceGate;
pub use phase_a_transformer_agent::{AgentToolSandbox, ToolCall, ToolResult, TransformerAgentPlant};
pub use phase_c_adaptive_adversary::{AdaptiveAdversary, EvasionStrategy};
pub use phase_d_governance_halt::{GovernanceHaltInterlock, GovernanceReleaseToken, HaltAuditRecord, HaltReason};
pub use phase_e_public_audit::{PublicAuditBundle, PublicAuditSuite};
pub use plant::ChaoticPlant;
pub use rate_cap::RateCapLimiter;
pub use receipt::{CeilingRecord, ReceiptRecord};
pub use sandbox::Sandbox;
pub use snapshot_store::SnapshotStore;
pub use types::{AccessMode, Mode, PlantState, SafetyBarrier, Snapshot, WriteManifest, WritePath};
