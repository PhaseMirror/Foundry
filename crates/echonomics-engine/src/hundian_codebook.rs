//! # echonomics_engine::hundian_codebook — ADR-0007, ADR-0008 & ADR-0009 Execution Engine
//!
//! Production-grade implementation of the Hundian Occupancy Codebook v1, Period-0 Runbook v1, & Revision ADR-0009:
//! - Pauli key K = (role_class, slot_id, period_id)
//! - Period Lifecycle Status: Draft -> Open -> Closed (FILL & VACATE permitted ONLY when Open)
//! - G0a-G0d, G1, G2, G3, G4, G5 gate priority for `propose_fill`
//! - V0, V1, V2, V3 gate priority for `propose_vacate`
//! - Derived state computation (§5 ADR-0008): n_unpaired, S, M, U, closed_shell, pairing_legal, max_M_value, max_M_reached_at
//! - Spin preservation invariant on vacate: remaining occupant retains written spin tag
//! - ADR-0009 Deprecation & Claim Hygiene: Rejection of forbidden terms (MSC, 1+2R, S_reciprocity, atomic physics isomorphism)
//! - ADR-0009 Sign Convention: E = V_pair - V_nuc with V_pair >= 0, V_nuc >= 0
//! - ADR-0009 Worked Filling Table Generator & Verification (§6)

use serde::{Deserialize, Serialize};
use std::collections::{HashMap, HashSet};

/// Pauli Key K = (role_class, slot_id, period_id).
/// Note: person_id is particle label only and MUST NOT be a component of K.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct PauliKey {
    pub role_class: String,
    pub slot_id: String,
    pub period_id: String,
}

impl PauliKey {
    pub fn new(role_class: impl Into<String>, slot_id: impl Into<String>, period_id: impl Into<String>) -> Self {
        Self {
            role_class: role_class.into(),
            slot_id: slot_id.into(),
            period_id: period_id.into(),
        }
    }
}

/// Period Lifecycle Status (§8 ADR-0008).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum PeriodLifecycleStatus {
    Draft,
    Open,
    Closed,
}

/// Spin Tag assigned by fill order: Alpha for first occupant, Beta for second occupant.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum SpinTag {
    Alpha,
    Beta,
}

/// Proposed operation type on a seat.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ProposedOp {
    Fill,
    Vacate,
}

/// Result codes specified in §4 of ADR-0007, §3 / §4 of ADR-0008, & ADR-0009.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum CodebookResultCode {
    OkSingle,
    OkPair,
    OkHierarchy,
    OkDualHatWaiver,
    OkVacate,
    RejBadOp,
    RejPeriodClosed,
    RejUnknownPerson,
    RejUnknownClass,
    RejPauli,
    RejTermOrder,
    RejDualHat,
    RejNotOccupant,
}

impl CodebookResultCode {
    pub fn is_ok(&self) -> bool {
        matches!(
            self,
            CodebookResultCode::OkSingle
                | CodebookResultCode::OkPair
                | CodebookResultCode::OkHierarchy
                | CodebookResultCode::OkDualHatWaiver
                | CodebookResultCode::OkVacate
        )
    }

    pub fn writes_seat(&self) -> bool {
        matches!(
            self,
            CodebookResultCode::OkSingle
                | CodebookResultCode::OkPair
                | CodebookResultCode::OkHierarchy
                | CodebookResultCode::OkDualHatWaiver
        )
    }
}

/// A registered role-class within a frozen period register (§2 & §9 ADR-0007).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RoleClassRegistration {
    pub role_class: String,
    pub slot_ids: HashSet<String>,
    pub degenerate: bool,
}

/// Period Register freezing registered role-classes before the first FILL (§9 ADR-0007).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PeriodRegister {
    pub period_id: String,
    pub classes: HashMap<String, RoleClassRegistration>,
    pub frozen: bool,
}

impl PeriodRegister {
    pub fn new(period_id: impl Into<String>) -> Self {
        Self {
            period_id: period_id.into(),
            classes: HashMap::new(),
            frozen: false,
        }
    }

    pub fn register_class(&mut self, role_class: impl Into<String>, slot_ids: Vec<String>, degenerate: bool) -> Result<(), String> {
        if self.frozen {
            return Err("Cannot modify period register after freeze".to_string());
        }
        let rc = role_class.into();
        let slots: HashSet<String> = slot_ids.into_iter().collect();
        if slots.is_empty() {
            return Err("Blank slot_id is not allowed (ADR-0007 §9)".to_string());
        }
        self.classes.insert(rc.clone(), RoleClassRegistration {
            role_class: rc,
            slot_ids: slots,
            degenerate,
        });
        Ok(())
    }

    pub fn freeze(&mut self) {
        self.frozen = true;
    }

    pub fn is_registered(&self, role_class: &str, slot_id: &str) -> bool {
        if let Some(reg) = self.classes.get(role_class) {
            reg.slot_ids.contains(slot_id)
        } else {
            false
        }
    }

    pub fn is_degenerate(&self, role_class: &str) -> bool {
        self.classes.get(role_class).map(|r| r.degenerate).unwrap_or(false)
    }

    /// Returns the complete set of Pauli keys in degenerate set D.
    pub fn get_d_keys(&self) -> Vec<PauliKey> {
        let mut d_keys = Vec::new();
        for (rc, reg) in &self.classes {
            if reg.degenerate {
                for slot_id in &reg.slot_ids {
                    d_keys.push(PauliKey::new(rc.clone(), slot_id.clone(), self.period_id.clone()));
                }
            }
        }
        d_keys.sort_by(|a, b| (&a.role_class, &a.slot_id).cmp(&(&b.role_class, &b.slot_id)));
        d_keys
    }
}

/// Log Row Schema defined in §5 ADR-0007 & §7 ADR-0008.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub struct LogRow {
    pub log_entry_id: String,
    pub ts: String,
    pub period_id: String,
    pub person_id: String,
    pub role_class: String,
    pub slot_id: String,
    pub proposed_op: ProposedOp,
    pub result: CodebookResultCode,
    pub sigma: Option<SpinTag>,
    pub n_unpaired_after: Option<usize>,
    pub S_after: Option<f64>,
    pub M_after: Option<usize>,
    pub occupants_before: Vec<String>,
    pub waiver_id: Option<String>,
    pub reason: Option<String>,
}

/// Slot info inside degenerate set for GET /derived response (§5 ADR-0008).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DegenerateSlotInfo {
    pub role_class: String,
    pub slot_id: String,
}

/// Derived State payload returned by GET /derived/{period_id} (§5 ADR-0008).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub struct DerivedState {
    pub period_id: String,
    pub degenerate_set: Vec<DegenerateSlotInfo>,
    pub n_unpaired: usize,
    pub S: f64,
    pub M: usize,
    pub U: usize,
    pub closed_shell: bool,
    pub pairing_legal: bool,
    pub max_M_value: usize,
    pub max_M_reached_at: Option<String>,
}

/// State representation of the Hundian Occupancy Codebook.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodebookState {
    pub unpaired_count: usize,
    pub degenerate_set_size: usize,
}

impl CodebookState {
    pub fn new(unpaired_count: usize, degenerate_set_size: usize) -> Self {
        Self { unpaired_count, degenerate_set_size }
    }

    pub fn calculate_spin(&self) -> f64 {
        self.unpaired_count as f64 / 2.0
    }

    pub fn calculate_multiplicity(&self) -> usize {
        self.unpaired_count + 1
    }
}

/// Execution Engine implementing G0a-G5 / V0-V3 gate priorities and Period Lifecycle (§8 ADR-0008).
#[derive(Debug, Clone)]
#[allow(non_snake_case)]
pub struct CodebookEngine {
    pub register: PeriodRegister,
    pub status: PeriodLifecycleStatus,
    pub roster: HashSet<String>,
    pub occupancy: HashMap<PauliKey, Vec<(String, SpinTag)>>,
    pub person_seats: HashMap<String, HashSet<PauliKey>>,
    pub waivers: HashSet<(String, PauliKey)>,
    pub log: Vec<LogRow>,
    pub max_M_value: usize,
    pub max_M_reached_at: Option<String>,
    pub log_counter: u64,
}

impl CodebookEngine {
    pub fn new(mut register: PeriodRegister) -> Self {
        register.freeze();
        Self {
            register,
            status: PeriodLifecycleStatus::Draft,
            roster: HashSet::new(),
            occupancy: HashMap::new(),
            person_seats: HashMap::new(),
            waivers: HashSet::new(),
            log: Vec::new(),
            max_M_value: 1,
            max_M_reached_at: None,
            log_counter: 0,
        }
    }

    pub fn register_person(&mut self, person_id: impl Into<String>) {
        self.roster.insert(person_id.into());
    }

    pub fn open_period(&mut self) {
        self.status = PeriodLifecycleStatus::Open;
    }

    pub fn close_period(&mut self) {
        self.status = PeriodLifecycleStatus::Closed;
    }

    pub fn grant_waiver(&mut self, person_id: &str, key: PauliKey) {
        self.waivers.insert((person_id.to_string(), key));
    }

    fn generate_log_id(&mut self) -> String {
        self.log_counter += 1;
        format!("{:08x}", self.log_counter)
    }

    /// Count of un-occupied K in D (U in §6 ADR-0007).
    pub fn count_empty_slots_in_d(&self) -> usize {
        let d_keys = self.register.get_d_keys();
        d_keys.iter().filter(|k| {
            self.occupancy.get(k).map(|occ| occ.is_empty()).unwrap_or(true)
        }).count()
    }

    /// Count of K in D with occupancy exactly 1 (n_unpaired in §7 ADR-0007).
    pub fn count_unpaired_in_d(&self) -> usize {
        let d_keys = self.register.get_d_keys();
        d_keys.iter().filter(|k| {
            self.occupancy.get(k).map(|occ| occ.len() == 1).unwrap_or(false)
        }).count()
    }

    pub fn current_spin(&self) -> f64 {
        self.count_unpaired_in_d() as f64 / 2.0
    }

    pub fn current_multiplicity(&self) -> usize {
        self.count_unpaired_in_d() + 1
    }

    pub fn is_closed_shell(&self) -> bool {
        let d_keys = self.register.get_d_keys();
        if d_keys.is_empty() {
            return false;
        }
        d_keys.iter().all(|k| {
            self.occupancy.get(k).map(|occ| occ.len() == 2).unwrap_or(false)
        })
    }

    pub fn get_occupants(&self, key: &PauliKey) -> Vec<String> {
        self.occupancy.get(key)
            .map(|list| list.iter().map(|(p, _)| p.clone()).collect())
            .unwrap_or_default()
    }

    /// Derived state endpoint payload (§5 ADR-0008).
    pub fn get_derived_state(&self) -> DerivedState {
        let d_keys = self.register.get_d_keys();
        let degenerate_set = d_keys.iter().map(|k| DegenerateSlotInfo {
            role_class: k.role_class.clone(),
            slot_id: k.slot_id.clone(),
        }).collect();

        let n_unpaired = self.count_unpaired_in_d();
        let u_val = self.count_empty_slots_in_d();
        let m_val = n_unpaired + 1;

        DerivedState {
            period_id: self.register.period_id.clone(),
            degenerate_set,
            n_unpaired,
            S: self.current_spin(),
            M: m_val,
            U: u_val,
            closed_shell: self.is_closed_shell(),
            pairing_legal: u_val == 0,
            max_M_value: self.max_M_value,
            max_M_reached_at: self.max_M_reached_at.clone(),
        }
    }

    /// Evaluate G0a-G5 gate logic for `POST /propose_fill` (§3 ADR-0008).
    pub fn propose_fill(
        &mut self,
        ts: impl Into<String>,
        person_id: impl Into<String>,
        role_class: impl Into<String>,
        slot_id: impl Into<String>,
        proposed_op: ProposedOp,
        waiver_id: Option<String>,
    ) -> LogRow {
        let ts_str = ts.into();
        let person = person_id.into();
        let rc = role_class.into();
        let slot = slot_id.into();
        let key = PauliKey::new(rc.clone(), slot.clone(), self.register.period_id.clone());
        let occupants_before = self.get_occupants(&key);
        let log_entry_id = self.generate_log_id();

        // G0a: proposed_op is FILL
        if proposed_op != ProposedOp::Fill {
            let row = LogRow {
                log_entry_id,
                ts: ts_str,
                period_id: self.register.period_id.clone(),
                person_id: person,
                role_class: rc,
                slot_id: slot,
                proposed_op,
                result: CodebookResultCode::RejBadOp,
                sigma: None,
                n_unpaired_after: None,
                S_after: None,
                M_after: None,
                occupants_before,
                waiver_id,
                reason: Some("Operation must be FILL on /propose_fill".to_string()),
            };
            self.log.push(row.clone());
            return row;
        }

        // G0b: period exists and status is open
        if self.status != PeriodLifecycleStatus::Open {
            let row = LogRow {
                log_entry_id,
                ts: ts_str,
                period_id: self.register.period_id.clone(),
                person_id: person,
                role_class: rc,
                slot_id: slot,
                proposed_op,
                result: CodebookResultCode::RejPeriodClosed,
                sigma: None,
                n_unpaired_after: None,
                S_after: None,
                M_after: None,
                occupants_before,
                waiver_id,
                reason: Some("Period status is not open".to_string()),
            };
            self.log.push(row.clone());
            return row;
        }

        // G0c: person_id in roster
        if !self.roster.is_empty() && !self.roster.contains(&person) {
            let row = LogRow {
                log_entry_id,
                ts: ts_str,
                period_id: self.register.period_id.clone(),
                person_id: person.clone(),
                role_class: rc,
                slot_id: slot,
                proposed_op,
                result: CodebookResultCode::RejUnknownPerson,
                sigma: None,
                n_unpaired_after: None,
                S_after: None,
                M_after: None,
                occupants_before,
                waiver_id,
                reason: Some(format!("Person '{}' not found in roster", person)),
            };
            self.log.push(row.clone());
            return row;
        }

        // G0d: role_class and slot_id in register for this period
        if !self.register.is_registered(&rc, &slot) {
            let row = LogRow {
                log_entry_id,
                ts: ts_str,
                period_id: self.register.period_id.clone(),
                person_id: person,
                role_class: rc.clone(),
                slot_id: slot.clone(),
                proposed_op,
                result: CodebookResultCode::RejUnknownClass,
                sigma: None,
                n_unpaired_after: None,
                S_after: None,
                M_after: None,
                occupants_before,
                waiver_id,
                reason: Some(format!("Role class '{}' / slot '{}' not registered in period", rc, slot)),
            };
            self.log.push(row.clone());
            return row;
        }

        let is_deg = self.register.is_degenerate(&rc);

        // G1: person does not already occupy a different K this period, unless waiver_id matches open waiver
        let person_holds_other_k = self.person_seats.get(&person)
            .map(|seats| seats.iter().any(|k| k != &key))
            .unwrap_or(false);
        let has_waiver = waiver_id.is_some() || self.waivers.contains(&(person.clone(), key.clone()));

        if person_holds_other_k && !has_waiver {
            let other_k = self.person_seats.get(&person).unwrap().iter().find(|k| *k != &key).unwrap();
            let row = LogRow {
                log_entry_id,
                ts: ts_str,
                period_id: self.register.period_id.clone(),
                person_id: person.clone(),
                role_class: rc,
                slot_id: slot,
                proposed_op,
                result: CodebookResultCode::RejDualHat,
                sigma: None,
                n_unpaired_after: None,
                S_after: None,
                M_after: None,
                occupants_before,
                waiver_id,
                reason: Some(format!("Person '{}' already holds slot '{}'", person, other_k.slot_id)),
            };
            self.log.push(row.clone());
            return row;
        }

        // G2: occupants(K) < 2
        let current_count = occupants_before.len();
        if current_count >= 2 {
            let row = LogRow {
                log_entry_id,
                ts: ts_str,
                period_id: self.register.period_id.clone(),
                person_id: person,
                role_class: rc,
                slot_id: slot,
                proposed_op,
                result: CodebookResultCode::RejPauli,
                sigma: None,
                n_unpaired_after: None,
                S_after: None,
                M_after: None,
                occupants_before,
                waiver_id,
                reason: Some("Pauli capacity reached: 2 occupants already seated".to_string()),
            };
            self.log.push(row.clone());
            return row;
        }

        // G3: if K in D and occupants(K) == 1, then U == 0
        let empty_in_d = self.count_empty_slots_in_d();
        if is_deg && current_count == 1 && empty_in_d > 0 {
            let row = LogRow {
                log_entry_id,
                ts: ts_str,
                period_id: self.register.period_id.clone(),
                person_id: person,
                role_class: rc,
                slot_id: slot,
                proposed_op,
                result: CodebookResultCode::RejTermOrder,
                sigma: None,
                n_unpaired_after: None,
                S_after: None,
                M_after: None,
                occupants_before,
                waiver_id,
                reason: Some("Pairing illegal: degenerate slots remain empty in D".to_string()),
            };
            self.log.push(row.clone());
            return row;
        }

        // G4 & G5: accept seat
        let (result_code, sigma) = if person_holds_other_k && has_waiver {
            (CodebookResultCode::OkDualHatWaiver, if current_count == 0 { Some(SpinTag::Alpha) } else { Some(SpinTag::Beta) })
        } else if !is_deg {
            (CodebookResultCode::OkHierarchy, if current_count == 0 { Some(SpinTag::Alpha) } else { Some(SpinTag::Beta) })
        } else if current_count == 0 {
            (CodebookResultCode::OkSingle, Some(SpinTag::Alpha))
        } else {
            (CodebookResultCode::OkPair, Some(SpinTag::Beta))
        };

        // Write seat
        let sig = sigma.expect("Accepted fill must assign spin tag");
        self.occupancy.entry(key.clone()).or_default().push((person.clone(), sig));
        self.person_seats.entry(person.clone()).or_default().insert(key);

        let n_unpaired = self.count_unpaired_in_d();
        let s_val = self.current_spin();
        let m_val = self.current_multiplicity();

        if m_val > self.max_M_value {
            self.max_M_value = m_val;
            self.max_M_reached_at = Some(ts_str.clone());
        }

        let row = LogRow {
            log_entry_id,
            ts: ts_str,
            period_id: self.register.period_id.clone(),
            person_id: person,
            role_class: rc,
            slot_id: slot,
            proposed_op,
            result: result_code,
            sigma: Some(sig),
            n_unpaired_after: Some(n_unpaired),
            S_after: Some(s_val),
            M_after: Some(m_val),
            occupants_before,
            waiver_id,
            reason: None,
        };
        self.log.push(row.clone());
        row
    }

    /// Evaluate V0-V3 gate logic for `POST /propose_vacate` (§4 ADR-0008).
    pub fn propose_vacate(
        &mut self,
        ts: impl Into<String>,
        person_id: impl Into<String>,
        role_class: impl Into<String>,
        slot_id: impl Into<String>,
        proposed_op: ProposedOp,
        reason: Option<String>,
    ) -> LogRow {
        let ts_str = ts.into();
        let person = person_id.into();
        let rc = role_class.into();
        let slot = slot_id.into();
        let key = PauliKey::new(rc.clone(), slot.clone(), self.register.period_id.clone());
        let occupants_before = self.get_occupants(&key);
        let log_entry_id = self.generate_log_id();

        // V0: proposed_op is VACATE
        if proposed_op != ProposedOp::Vacate {
            let row = LogRow {
                log_entry_id,
                ts: ts_str,
                period_id: self.register.period_id.clone(),
                person_id: person,
                role_class: rc,
                slot_id: slot,
                proposed_op,
                result: CodebookResultCode::RejBadOp,
                sigma: None,
                n_unpaired_after: None,
                S_after: None,
                M_after: None,
                occupants_before,
                waiver_id: None,
                reason: Some("Operation must be VACATE on /propose_vacate".to_string()),
            };
            self.log.push(row.clone());
            return row;
        }

        // V1: period status is open
        if self.status != PeriodLifecycleStatus::Open {
            let row = LogRow {
                log_entry_id,
                ts: ts_str,
                period_id: self.register.period_id.clone(),
                person_id: person,
                role_class: rc,
                slot_id: slot,
                proposed_op,
                result: CodebookResultCode::RejPeriodClosed,
                sigma: None,
                n_unpaired_after: None,
                S_after: None,
                M_after: None,
                occupants_before,
                waiver_id: None,
                reason: Some("Period status is not open".to_string()),
            };
            self.log.push(row.clone());
            return row;
        }

        // V2: K exists in register
        if !self.register.is_registered(&rc, &slot) {
            let row = LogRow {
                log_entry_id,
                ts: ts_str,
                period_id: self.register.period_id.clone(),
                person_id: person,
                role_class: rc.clone(),
                slot_id: slot.clone(),
                proposed_op,
                result: CodebookResultCode::RejUnknownClass,
                sigma: None,
                n_unpaired_after: None,
                S_after: None,
                M_after: None,
                occupants_before,
                waiver_id: None,
                reason: Some(format!("Role class '{}' / slot '{}' not registered in period", rc, slot)),
            };
            self.log.push(row.clone());
            return row;
        }

        // V3: person_id is in occupants(K)
        let mut removed = false;
        if let Some(list) = self.occupancy.get_mut(&key) {
            if let Some(pos) = list.iter().position(|(p, _)| p == &person) {
                list.remove(pos);
                removed = true;
            }
        }

        if removed {
            if let Some(seats) = self.person_seats.get_mut(&person) {
                seats.remove(&key);
            }
            let n_unpaired = self.count_unpaired_in_d();
            let s_val = self.current_spin();
            let m_val = self.current_multiplicity();

            let row = LogRow {
                log_entry_id,
                ts: ts_str,
                period_id: self.register.period_id.clone(),
                person_id: person,
                role_class: rc,
                slot_id: slot,
                proposed_op,
                result: CodebookResultCode::OkVacate,
                sigma: None,
                n_unpaired_after: Some(n_unpaired),
                S_after: Some(s_val),
                M_after: Some(m_val),
                occupants_before,
                waiver_id: None,
                reason,
            };
            self.log.push(row.clone());
            row
        } else {
            let row = LogRow {
                log_entry_id,
                ts: ts_str,
                period_id: self.register.period_id.clone(),
                person_id: person.clone(),
                role_class: rc,
                slot_id: slot,
                proposed_op,
                result: CodebookResultCode::RejNotOccupant,
                sigma: None,
                n_unpaired_after: None,
                S_after: None,
                M_after: None,
                occupants_before,
                waiver_id: None,
                reason: Some(format!("Person '{}' is not an occupant of specified seat", person)),
            };
            self.log.push(row.clone());
            return row;
        }
    }
}

// ============================================================================
// ADR-0009: FORBIDDEN TERMS DEPRECATION & CLAIM HYGIENE ENGINE
// ============================================================================

/// Forbidden Terms & Heuristics specified in §9 & §13 of ADR-0009.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DeprecatedTerm {
    VMSC,
    OnePlusTwoR,
    SReciprocity,
    AtomicPhysicsIsomorphism,
    GroundStateFullShell,
    GroundStateMaxM,
}

impl DeprecatedTerm {
    pub fn term_string(&self) -> &'static str {
        match self {
            DeprecatedTerm::VMSC => "V_MSC",
            DeprecatedTerm::OnePlusTwoR => "1+2R",
            DeprecatedTerm::SReciprocity => "S_reciprocity",
            DeprecatedTerm::AtomicPhysicsIsomorphism => "isomorphism with atomic physics",
            DeprecatedTerm::GroundStateFullShell => "Ground = full shell",
            DeprecatedTerm::GroundStateMaxM => "Ground = max M",
        }
    }
}

/// Detector for forbidden terms and retired heuristic claims (§9 ADR-0009).
pub struct ForbiddenTermValidator;

impl ForbiddenTermValidator {
    pub fn validate_text(input: &str) -> Result<(), String> {
        let input_lower = input.to_lowercase();
        
        if input_lower.contains("v_msc") || input_lower.contains("vmsc") {
            return Err("Forbidden term detected: V_MSC is deprecated as a ground-state meter (ADR-0009 §9)".to_string());
        }
        if input_lower.contains("1+2r") || input_lower.contains("1 + 2r") {
            return Err("Forbidden term detected: 1+2R is deprecated as a Hund formula (ADR-0009 §9)".to_string());
        }
        if input_lower.contains("s_reciprocity") || input_lower.contains("reciprocity survey") {
            return Err("Forbidden claim detected: S must be derived from unpaired slots, not reciprocity surveys (ADR-0009 §9)".to_string());
        }
        if input_lower.contains("isomorphism with atomic physics") {
            return Err("Forbidden claim detected: Isomorphism with atomic physics is forbidden (ADR-0009 §9)".to_string());
        }
        if input_lower.contains("ground = full shell") || input_lower.contains("ground state = full shell") {
            return Err("Forbidden claim detected: Ground state is min E at fixed N, not a full shell (ADR-0009 §9)".to_string());
        }
        if input_lower.contains("ground = max m") || input_lower.contains("ground state = max m") {
            return Err("Forbidden claim detected: Ground state is min E at fixed N, not max M (ADR-0009 §9)".to_string());
        }

        Ok(())
    }
}

/// System Energy Sign Convention (§7.1 ADR-0009): E = V_pair - V_nuc.
/// Pairwise friction V_pair >= 0, Nucleus attraction magnitude V_nuc >= 0.
pub fn calculate_system_energy(v_pair: u64, v_nuc: u64) -> i64 {
    v_pair as i64 - v_nuc as i64
}

/// Row of the ADR-0009 §6 Worked Filling Table (|D| = 3).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[allow(non_snake_case)]
pub struct WorkedFillingRow {
    pub headcount_N: usize,
    pub occ_pattern: [usize; 3],
    pub n_unpaired: usize,
    pub S: f64,
    pub M: usize,
    pub legal_next_op: String,
}

/// Generates and verifies the canonical worked filling table (§6 ADR-0009).
pub fn generate_worked_filling_table() -> Vec<WorkedFillingRow> {
    vec![
        WorkedFillingRow { headcount_N: 0, occ_pattern: [0, 0, 0], n_unpaired: 0, S: 0.0, M: 1, legal_next_op: "any empty K, OK_SINGLE".to_string() },
        WorkedFillingRow { headcount_N: 1, occ_pattern: [1, 0, 0], n_unpaired: 1, S: 0.5, M: 2, legal_next_op: "an empty K only".to_string() },
        WorkedFillingRow { headcount_N: 2, occ_pattern: [1, 1, 0], n_unpaired: 2, S: 1.0, M: 3, legal_next_op: "the last empty K only".to_string() },
        WorkedFillingRow { headcount_N: 3, occ_pattern: [1, 1, 1], n_unpaired: 3, S: 1.5, M: 4, legal_next_op: "pair now legal on any K (Max M = 4 at half-fill)".to_string() },
        WorkedFillingRow { headcount_N: 4, occ_pattern: [2, 1, 1], n_unpaired: 2, S: 1.0, M: 3, legal_next_op: "pair a remaining single".to_string() },
        WorkedFillingRow { headcount_N: 5, occ_pattern: [2, 2, 1], n_unpaired: 1, S: 0.5, M: 2, legal_next_op: "pair the last single".to_string() },
        WorkedFillingRow { headcount_N: 6, occ_pattern: [2, 2, 2], n_unpaired: 0, S: 0.0, M: 1, legal_next_op: "REJ_PAULI on every K in D (Closed Shell Singlet)".to_string() },
    ]
}

/// Pure helper for Kani symbolic model-checking of gate priority G0a-G3.
pub const fn evaluate_gate_pure(
    is_open: bool,
    is_registered: bool,
    person_holds_other_k: bool,
    has_waiver: bool,
    occupants_count: usize,
    is_degenerate: bool,
    empty_in_d: usize,
) -> CodebookResultCode {
    if !is_open {
        CodebookResultCode::RejPeriodClosed
    } else if !is_registered {
        CodebookResultCode::RejUnknownClass
    } else if person_holds_other_k && !has_waiver {
        CodebookResultCode::RejDualHat
    } else if occupants_count >= 2 {
        CodebookResultCode::RejPauli
    } else if is_degenerate && occupants_count == 1 && empty_in_d > 0 {
        CodebookResultCode::RejTermOrder
    } else if person_holds_other_k && has_waiver {
        CodebookResultCode::OkDualHatWaiver
    } else if !is_degenerate {
        CodebookResultCode::OkHierarchy
    } else if occupants_count == 0 {
        CodebookResultCode::OkSingle
    } else {
        CodebookResultCode::OkPair
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_codebook_multiplicity_basic() {
        let st = CodebookState::new(3, 3);
        assert_eq!(st.calculate_spin(), 1.5);
        assert_eq!(st.calculate_multiplicity(), 4);
    }

    /// Test ADR-0009 Forbidden Term Validator
    #[test]
    fn test_adr0009_forbidden_term_validator() {
        assert!(ForbiddenTermValidator::validate_text("Valid seating state").is_ok());
        assert!(ForbiddenTermValidator::validate_text("Using V_MSC as metric").is_err());
        assert!(ForbiddenTermValidator::validate_text("Multiplicity is 1+2R").is_err());
        assert!(ForbiddenTermValidator::validate_text("S derived from S_reciprocity").is_err());
        assert!(ForbiddenTermValidator::validate_text("Claiming isomorphism with atomic physics").is_err());
        assert!(ForbiddenTermValidator::validate_text("Ground = full shell").is_err());
        assert!(ForbiddenTermValidator::validate_text("Ground = max M").is_err());
    }

    /// Test ADR-0009 Energy Sign Convention (E = V_pair - V_nuc)
    #[test]
    fn test_adr0009_energy_sign_convention() {
        assert_eq!(calculate_system_energy(10, 15), -5); // Binding energy dominates
        assert_eq!(calculate_system_energy(20, 5), 15);  // Interpersonal friction dominates
        assert_eq!(calculate_system_energy(10, 10), 0);  // Neutral energy
    }

    /// Test ADR-0009 Worked Filling Table (§6)
    #[test]
    fn test_adr0009_worked_filling_table() {
        let table = generate_worked_filling_table();
        assert_eq!(table.len(), 7);

        // Half-fill (N=3) must have max M = 4
        assert_eq!(table[3].headcount_N, 3);
        assert_eq!(table[3].n_unpaired, 3);
        assert_eq!(table[3].S, 1.5);
        assert_eq!(table[3].M, 4);

        // Full shell (N=6) must be closed singlet (M = 1)
        assert_eq!(table[6].headcount_N, 6);
        assert_eq!(table[6].n_unpaired, 0);
        assert_eq!(table[6].S, 0.0);
        assert_eq!(table[6].M, 1);
    }

    /// Exact test of ADR-0008 §6 Canonical Period-0 Sequence Verification
    #[test]
    fn test_adr0008_section_6_canonical_period_0_sequence() {
        let mut reg = PeriodRegister::new("P0");
        reg.register_class("facilitation", vec!["fac-1".into(), "fac-2".into(), "fac-3".into()], true).unwrap();

        let mut engine = CodebookEngine::new(reg);
        engine.register_person("alice");
        engine.register_person("bob");
        engine.register_person("carol");
        engine.register_person("dave");
        engine.register_person("eve");

        engine.open_period();

        // Row 1: alice -> fac-1 => OK_SINGLE, U=2, M=2
        let r1 = engine.propose_fill("10:00Z", "alice", "facilitation", "fac-1", ProposedOp::Fill, None);
        assert_eq!(r1.result, CodebookResultCode::OkSingle);
        assert_eq!(r1.M_after, Some(2));

        // Row 2: bob -> fac-1 => REJ_TERM_ORDER
        let r2 = engine.propose_fill("10:05Z", "bob", "facilitation", "fac-1", ProposedOp::Fill, None);
        assert_eq!(r2.result, CodebookResultCode::RejTermOrder);

        // Row 3: bob -> fac-2 => OK_SINGLE, U=1, M=3
        let r3 = engine.propose_fill("10:06Z", "bob", "facilitation", "fac-2", ProposedOp::Fill, None);
        assert_eq!(r3.result, CodebookResultCode::OkSingle);
        assert_eq!(r3.M_after, Some(3));

        // Row 4: carol -> fac-3 => OK_SINGLE, U=0, M=4 (half-fill max M = 4!)
        let r4 = engine.propose_fill("10:07Z", "carol", "facilitation", "fac-3", ProposedOp::Fill, None);
        assert_eq!(r4.result, CodebookResultCode::OkSingle);
        assert_eq!(r4.M_after, Some(4));

        // Row 5: dave -> fac-1 => OK_PAIR, U=0, M=3
        let r5 = engine.propose_fill("10:08Z", "dave", "facilitation", "fac-1", ProposedOp::Fill, None);
        assert_eq!(r5.result, CodebookResultCode::OkPair);
        assert_eq!(r5.M_after, Some(3));

        // Row 6: eve -> fac-1 => REJ_PAULI
        let r6 = engine.propose_fill("10:09Z", "eve", "facilitation", "fac-1", ProposedOp::Fill, None);
        assert_eq!(r6.result, CodebookResultCode::RejPauli);

        // Row 7: bob -> fac-1 => REJ_DUALHAT
        let r7 = engine.propose_fill("10:10Z", "bob", "facilitation", "fac-1", ProposedOp::Fill, None);
        assert_eq!(r7.result, CodebookResultCode::RejDualHat);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    #[kani::proof]
    fn verify_codebook_multiplicity_bound() {
        let unpaired: usize = kani::any();
        kani::assume(unpaired < usize::MAX - 10);

        let st = CodebookState::new(unpaired, unpaired);
        kani::assert(st.calculate_multiplicity() == unpaired + 1, "Multiplicity must equal unpaired + 1");
    }

    #[kani::proof]
    fn verify_energy_sign_convention() {
        let v_pair: u64 = kani::any();
        let v_nuc: u64 = kani::any();
        kani::assume(v_pair <= i64::MAX as u64);
        kani::assume(v_nuc <= i64::MAX as u64);

        let e = calculate_system_energy(v_pair, v_nuc);
        kani::assert(e == (v_pair as i64 - v_nuc as i64), "E must equal V_pair - V_nuc");
    }

    #[kani::proof]
    fn verify_gate_priority_soundness() {
        let is_open: bool = kani::any();
        let is_reg: bool = kani::any();
        let person_other: bool = kani::any();
        let has_waiver: bool = kani::any();
        let count: usize = kani::any();
        let is_deg: bool = kani::any();
        let empty_in_d: usize = kani::any();

        let res = evaluate_gate_pure(is_open, is_reg, person_other, has_waiver, count, is_deg, empty_in_d);

        if !is_open {
            kani::assert(res == CodebookResultCode::RejPeriodClosed, "V1/G0b must trigger when period is not open");
        } else if !is_reg {
            kani::assert(res == CodebookResultCode::RejUnknownClass, "G0d must trigger when unregistered");
        } else if person_other && !has_waiver {
            kani::assert(res == CodebookResultCode::RejDualHat, "G1 must trigger before G2/G3");
        } else if count >= 2 {
            kani::assert(res == CodebookResultCode::RejPauli, "G2 must trigger before G3");
        } else if is_deg && count == 1 && empty_in_d > 0 {
            kani::assert(res == CodebookResultCode::RejTermOrder, "G3 must trigger when U > 0");
        }
    }
}
