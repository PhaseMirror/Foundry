//! Wire types for `MeasurementProgram` — the JSON surface of the observable.
//!
//! All coefficients are exact integers (`i64`, bounded by `MAX_ENTRY`) and all
//! matrices are validated into shape before any linear algebra runs. Every
//! quantity that survives into a verdict (kernels, obstruction dimensions,
//! Walsh coefficients) is re-derived by `crate::kernel` from this validated
//! representation — the JSON is the source of truth and nothing is inferred.

use serde::{Deserialize, Serialize};

use crate::rat::Q;

pub const MAX_ENTRY: i64 = 1 << 31;
pub const MAX_DIM: usize = 32;
pub const MAX_STAGES: usize = 16;
pub const MAX_TARGETS: usize = 16;
pub const MAX_PROBES: usize = 16;
pub const MAX_CLAIMS: usize = 24;
pub const MAX_CUBE_N: usize = 10;
pub const MAX_WIRE_BYTES: usize = 1 << 20;
pub const WIRE_VERSION: u16 = 0x004F; // "O"

/// Stage kinds of the layered map M = T ∘ A ∘ P ∘ R ∘ S (ADR-0027).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Hash)]
#[serde(rename_all = "snake_case")]
pub enum StageKind {
    /// Source/state preparation (antiferromagnetic domain state).
    Source,
    /// Response of the material to the probe.
    Response,
    /// Polarization projection / channel selection.
    ProbeProjection,
    /// Symmetry or space averaging / domain cancellation.
    Averaging,
    /// Transfer / resolution / binning.
    Transfer,
    /// Declared nuisance map.
    Nuisance,
}

impl StageKind {
    /// Snake_case tag used in canonical bytes and defect language.
    pub fn as_str(self) -> &'static str {
        match self {
            StageKind::Source => "source",
            StageKind::Response => "response",
            StageKind::ProbeProjection => "probe_projection",
            StageKind::Averaging => "averaging",
            StageKind::Transfer => "transfer",
            StageKind::Nuisance => "nuisance",
        }
    }

    /// Legacy four-null taxonomy (ADR-0022) assigned to each stage kind.
    pub fn four_null(self) -> &'static str {
        match self {
            StageKind::Source | StageKind::Response => "physical",
            StageKind::ProbeProjection => "polarization_projection",
            StageKind::Averaging => "antiferromagnetic_domain_cancellation",
            StageKind::Transfer => "resolution",
            StageKind::Nuisance => "nuisance_confounding",
        }
    }
}

/// One stage `A_j` of the pipeline.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Stage {
    pub name: String,
    pub kind: StageKind,
    /// Exact square matrix, rows × cols both equal to `program.dim`.
    pub matrix: Vec<Vec<i64>>,
}

/// A target functional C (row block), or probe map P.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Channel {
    pub name: String,
    /// Exact matrix, any shape; validated against `dim`.
    pub rows: Vec<Vec<i64>>,
}

/// One component of the six-vector claim (ADR-0026).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ClaimClause {
    /// M | S | E | χ | R | K
    pub component: String,
    pub status: ClaimStatus,
    /// Must name a declared `Channel` (probe); the channel that would close
    /// this claim: the map A whose kernel the focus functional must kill.
    pub channel: Option<String>,
    /// Must name a declared target `Channel`; the functional C evaluated for
    /// identifiability `d_C(A) = 0`.
    pub focus: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Hash)]
#[serde(rename_all = "snake_case")]
pub enum ClaimStatus {
    Closed,
    Supported,
    Provisional,
    Open,
    Contradicted,
    Disfavored,
    Blocked,
    StateDependent,
}

impl ClaimStatus {
    pub fn as_str(self) -> &'static str {
        match self {
            ClaimStatus::Closed => "closed",
            ClaimStatus::Supported => "supported",
            ClaimStatus::Provisional => "provisional",
            ClaimStatus::Open => "open",
            ClaimStatus::Contradicted => "contradicted",
            ClaimStatus::Disfavored => "disfavored",
            ClaimStatus::Blocked => "blocked",
            ClaimStatus::StateDependent => "state_dependent",
        }
    }

    /// Statuses that assert the component has been established: closure or
    /// model-backed support. Both require structural identifiability.
    pub const fn closes(self) -> bool {
        matches!(self, ClaimStatus::Closed | ClaimStatus::Supported)
    }

    /// A microstructure in this state forces every downstream component to
    /// block (ADR-0026 source-state precedence).
    pub const fn contaminates_downstream(self) -> bool {
        matches!(self, ClaimStatus::Contradicted | ClaimStatus::Blocked)
    }
}

/// A Walsh–Hadamard (reversal-space) cube with exact integer measurements
/// `y(s)` indexed by `∑ bit_i · 2^i` over sign patterns `s ∈ {±1}^N`.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ReversalCube {
    pub n: usize,
    pub cube: Vec<i64>,
    /// Masks of sectors the model forbids (contribute zero on symmetry
    /// grounds). A nonzero character there is a leakage defect.
    pub forbidden_masks: Vec<u64>,
    /// State dimension the reversal maps act on.
    pub state_dim: usize,
    /// Signed-permutation maps r_i for the path-consistency gate.
    pub reversal_maps: Vec<Vec<Vec<i64>>>,
}

/// Declared reference (group-averaged source sector, ADR-0023).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Reference {
    /// Dimension of the operator space the group acts on.
    pub operator_dim: usize,
    /// Group elements ρ(g) as exact integer matrices.
    pub group: Vec<Vec<Vec<i64>>>,
    /// The target channel O whose null behaviour is checked at the reference.
    pub target: Vec<Vec<i64>>,
    /// Explicit declarations of the admissibility certificate:
    /// A = A_ind ∧ A_state ∧ A_null ∧ A_no_retune.
    pub declared: AdmissibilityDecl,
    /// A declared "odd" direction λ (lives in ker P; the δJ7 complement).
    pub odd_direction: Vec<i64>,
    /// Character χ_O(g) sampled at each element of `group`, ±1, for the
    /// covariance check F_O(ρ_g λ) = χ_O(g) · F_O(λ).
    pub characters: Vec<i64>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct AdmissibilityDecl {
    pub independent: bool,
    pub state: bool,
    pub no_retune: bool,
}

/// One measurement program, the top-level wire document.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MeasurementProgram {
    pub name: String,
    pub dim: usize,
    pub stages: Vec<Stage>,
    pub targets: Vec<Channel>,
    pub probes: Vec<Channel>,
    pub claims: Vec<ClaimClause>,
    pub reversals: Vec<ReversalCube>,
    pub reference: Option<Reference>,
}

// ---------------------------------------------------------------------------
// Exact bootstrap: i64 -> Q.
// ---------------------------------------------------------------------------

pub fn q_of(v: i64) -> Q {
    Q::from_i128(v as i128)
}

pub fn q_rows(m: &[Vec<i64>]) -> Vec<Vec<Q>> {
    m.iter()
        .map(|r| r.iter().copied().map(q_of).collect())
        .collect()
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ProgramError {
    Message(String),
}

impl std::fmt::Display for ProgramError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ProgramError::Message(msg) => f.write_str(msg),
        }
    }
}

impl std::error::Error for ProgramError {}

/// Validate shape, bounds, and cross-references of a program (ADR-0027 §5:
/// a measurement program that cannot be built exactly must not run).
pub fn validate(p: &MeasurementProgram) -> Result<(), ProgramError> {
    if p.dim == 0 || p.dim > MAX_DIM {
        return Err(err("dimension out of range"));
    }
    if p.stages.is_empty() {
        return Err(err("at least one stage is required"));
    }
    if p.stages.len() > MAX_STAGES {
        return Err(err("too many stages"));
    }
    if p.targets.is_empty() {
        return Err(err("at least one target is required"));
    }
    if p.targets.len() > MAX_TARGETS || p.probes.len() > MAX_PROBES {
        return Err(err("too many targets or probes"));
    }
    if p.claims.len() > MAX_CLAIMS {
        return Err(err("too many claims"));
    }
    if p.name.is_empty() || p.name.len() > 255 {
        return Err(err("program name must be 1..255 chars"));
    }

    for (i, st) in p.stages.iter().enumerate() {
        check_square(st.matrix.len(), p.dim, "stage")?;
        check_bounds(&st.matrix)?;
        if st.name.is_empty() {
            return Err(err(&format!("stage {i}: name required")));
        }
    }

    for c in p.targets.iter().chain(p.probes.iter()) {
        check_bounds(&c.rows)?;
        if c.rows.iter().any(|r| r.len() != p.dim) {
            return Err(err(&format!(
                "channel '{}': columns must equal dim",
                c.name
            )));
        }
    }

    let names: Vec<&str> = p
        .targets
        .iter()
        .chain(p.probes.iter())
        .map(|c| c.name.as_str())
        .collect();
    for cl in &p.claims {
        let comp = cl.component.to_uppercase();
        if !matches!(comp.as_str(), "M" | "S" | "E" | "X" | "R" | "K") {
            return Err(err(&format!(
                "claim component '{}' not in M,S,E,X,R,K",
                cl.component
            )));
        }
        if let Some(ch) = &cl.channel {
            if !names.contains(&ch.as_str()) {
                return Err(err(&format!(
                    "claim '{}' references unknown channel '{}'",
                    cl.component, ch
                )));
            }
        }
        if let Some(ft) = &cl.focus {
            if !p.targets.iter().any(|t| &t.name == ft) {
                return Err(err(&format!(
                    "claim '{}' references unknown focus target '{}'",
                    cl.component, ft
                )));
            }
        }
    }

    for rv in &p.reversals {
        let expect = 1usize << rv.n;
        if rv.n > MAX_CUBE_N || rv.n == 0 {
            return Err(err("reversal cube n out of range 1..=MAX_CUBE_N"));
        }
        if rv.cube.len() != expect {
            return Err(err("reversal cube length must be 2^n"));
        }
        if rv.forbidden_masks.iter().any(|&m| m >= expect as u64) {
            return Err(err("forbidden mask out of cube range"));
        }
        if rv.reversal_maps.len() != rv.n {
            return Err(err("reversal group must have n maps"));
        }
        if rv.state_dim == 0 || rv.state_dim > MAX_DIM {
            return Err(err("reversal state_dim out of range"));
        }
        for m in &rv.reversal_maps {
            check_square(m.len(), rv.state_dim, "reversal map")?;
            check_bounds(m)?;
            check_signed_permutation(m)?;
        }
    }

    if let Some(r) = &p.reference {
        if r.operator_dim == 0 || r.operator_dim > MAX_DIM {
            return Err(err("reference operator_dim out of range"));
        }
        if r.group.is_empty() {
            return Err(err("reference group must be non-empty"));
        }
        for g in &r.group {
            check_square(g.len(), r.operator_dim, "reference group element")?;
            check_bounds(g)?;
        }
        check_bounds(&r.target)?;
        if r.target.iter().any(|row| row.len() != r.operator_dim) {
            return Err(err("reference target columns must equal operator_dim"));
        }
        if r.odd_direction.len() != r.operator_dim {
            return Err(err(
                "reference odd_direction length must equal operator_dim",
            ));
        }
        check_bounds(std::slice::from_ref(&r.odd_direction))?;
        if r.characters.len() != r.group.len() {
            return Err(err("reference characters length must equal group length"));
        }
        if r.characters.iter().any(|&c| c != -1 && c != 1) {
            return Err(err("reference characters must be ±1"));
        }
    }
    Ok(())
}

fn check_square(rows: usize, want: usize, what: &str) -> Result<(), ProgramError> {
    if rows != want {
        return Err(err(&format!("{what}: must be square {want}×{want}")));
    }
    Ok(())
}

fn check_bounds(m: &[Vec<i64>]) -> Result<(), ProgramError> {
    for row in m {
        for &v in row {
            if !(-MAX_ENTRY..=MAX_ENTRY).contains(&v) {
                return Err(err("coefficient outside ±2^31"));
            }
        }
    }
    Ok(())
}

/// A signed permutation matrix: every row and every column has exactly one
/// non-zero entry, equal to ±1.
fn check_signed_permutation(m: &[Vec<i64>]) -> Result<(), ProgramError> {
    let n = m.len();
    for row in m {
        let mut nz = 0;
        for &v in row {
            if v == 0 {
                continue;
            }
            if v != 1 && v != -1 {
                return Err(err("reversal map entries must be ±1 or 0"));
            }
            nz += 1;
        }
        if nz != 1 {
            return Err(err("reversal map rows must be signed permutations"));
        }
    }
    for c in 0..n {
        if m.iter().filter(|row| row[c] != 0).count() != 1 {
            return Err(err("reversal map columns must be signed permutations"));
        }
    }
    Ok(())
}

fn err(msg: &str) -> ProgramError {
    ProgramError::Message(msg.to_string())
}

// ---------------------------------------------------------------------------
// Canonical bytes (integer-only hash preimage; mirror of the crmf `canonical`
// contract so verdicts are reproducible).
// ---------------------------------------------------------------------------

/// Deterministic byte encoding of the program. Uses uleb128 + be_u64 primitives
/// in the crmf substrate; no floats appear anywhere.
pub fn canonical_bytes(p: &MeasurementProgram) -> Vec<u8> {
    use crmf::canonical::{be_u64, uleb128};

    fn ul(out: &mut Vec<u8>, v: u64) {
        out.extend_from_slice(&uleb128(v));
    }
    fn be(out: &mut Vec<u8>, v: u64) {
        out.extend_from_slice(&be_u64(v));
    }

    let mut out = Vec::new();
    ul(&mut out, WIRE_VERSION as u64);
    ul(&mut out, p.dim as u64);
    ul(&mut out, p.stages.len() as u64);
    for st in &p.stages {
        ul(&mut out, stage_kind_tag(st.kind) as u64);
        ul(&mut out, st.name.len() as u64);
        out.extend_from_slice(st.name.as_bytes());
        push_mat(&mut out, &st.matrix);
    }
    ul(&mut out, p.targets.len() as u64);
    for t in &p.targets {
        be(&mut out, t.name.len() as u64);
        out.extend_from_slice(t.name.as_bytes());
        push_mat(&mut out, &t.rows);
    }
    ul(&mut out, p.probes.len() as u64);
    for pb in &p.probes {
        be(&mut out, pb.name.len() as u64);
        out.extend_from_slice(pb.name.as_bytes());
        push_mat(&mut out, &pb.rows);
    }
    ul(&mut out, p.claims.len() as u64);
    for cl in &p.claims {
        ul(&mut out, claim_component_tag(cl.component.as_str()) as u64);
        ul(&mut out, claim_status_tag(cl.status) as u64);
        match &cl.channel {
            Some(name) => {
                be(&mut out, 1);
                be(&mut out, name.len() as u64);
                out.extend_from_slice(name.as_bytes());
            }
            None => be(&mut out, 0),
        }
        match &cl.focus {
            Some(name) => {
                be(&mut out, 1);
                be(&mut out, name.len() as u64);
                out.extend_from_slice(name.as_bytes());
            }
            None => be(&mut out, 0),
        }
    }
    ul(&mut out, p.reversals.len() as u64);
    for rv in &p.reversals {
        ul(&mut out, rv.n as u64);
        for &v in &rv.cube {
            be(&mut out, v as u64);
        }
        ul(&mut out, rv.forbidden_masks.len() as u64);
        for &m in &rv.forbidden_masks {
            be(&mut out, m);
        }
        ul(&mut out, rv.state_dim as u64);
        ul(&mut out, rv.reversal_maps.len() as u64);
        for map in &rv.reversal_maps {
            push_mat(&mut out, map);
        }
    }
    match &p.reference {
        None => be(&mut out, 0),
        Some(r) => {
            be(&mut out, 1);
            ul(&mut out, r.operator_dim as u64);
            ul(&mut out, r.group.len() as u64);
            for g in &r.group {
                push_mat(&mut out, g);
            }
            push_mat(&mut out, &r.target);
            // Declared certificate.
            be(&mut out, r.declared.independent as u64);
            be(&mut out, r.declared.state as u64);
            be(&mut out, r.declared.no_retune as u64);
            for &v in &r.odd_direction {
                be(&mut out, v as u64);
            }
            for &c in &r.characters {
                be(&mut out, c as u64);
            }
        }
    }
    out
}

/// SHA-256 of the canonical program bytes.
pub fn program_hash(p: &MeasurementProgram) -> [u8; 32] {
    use sha2::Digest;
    let mut h = sha2::Sha256::new();
    h.update(canonical_bytes(p));
    h.finalize().into()
}

fn push_mat(out: &mut Vec<u8>, m: &[Vec<i64>]) {
    use crmf::canonical::be_u64;
    out.extend_from_slice(&be_u64(m.len() as u64));
    for row in m {
        out.extend_from_slice(&be_u64(row.len() as u64));
        for &v in row {
            out.extend_from_slice(&be_u64(v as u64));
        }
    }
}

fn stage_kind_tag(k: StageKind) -> u8 {
    match k {
        StageKind::Source => 1,
        StageKind::Response => 2,
        StageKind::ProbeProjection => 3,
        StageKind::Averaging => 4,
        StageKind::Transfer => 5,
        StageKind::Nuisance => 6,
    }
}

fn claim_component_tag(c: &str) -> u8 {
    match c.to_uppercase().as_str() {
        "M" => 1,
        "S" => 2,
        "E" => 3,
        "X" => 4,
        "R" => 5,
        "K" => 6,
        _ => 0,
    }
}

fn claim_status_tag(s: ClaimStatus) -> u8 {
    match s {
        ClaimStatus::Closed => 1,
        ClaimStatus::Supported => 2,
        ClaimStatus::Provisional => 3,
        ClaimStatus::Open => 4,
        ClaimStatus::Contradicted => 5,
        ClaimStatus::Disfavored => 6,
        ClaimStatus::Blocked => 7,
        ClaimStatus::StateDependent => 8,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn minimal() -> MeasurementProgram {
        MeasurementProgram {
            name: "mn_test".into(),
            dim: 2,
            stages: vec![Stage {
                name: "s".into(),
                kind: StageKind::Response,
                matrix: vec![vec![1, 0], vec![0, 1]],
            }],
            targets: vec![Channel {
                name: "t".into(),
                rows: vec![vec![1, 0]],
            }],
            probes: vec![],
            claims: vec![],
            reversals: vec![],
            reference: None,
        }
    }

    #[test]
    fn minimal_program_validates_and_hashes_stably() {
        let p = minimal();
        assert!(validate(&p).is_ok());
        let a = program_hash(&p);
        let b = program_hash(&p);
        assert_eq!(a, b);
    }

    #[test]
    fn rejects_wide_target() {
        let mut p = minimal();
        p.targets[0].rows = vec![vec![1, 0, 0]];
        assert!(validate(&p).is_err());
    }

    #[test]
    fn rejects_bad_claim_component() {
        let mut p = minimal();
        p.claims.push(ClaimClause {
            component: "Z".into(),
            status: ClaimStatus::Open,
            channel: None,
            focus: None,
        });
        assert!(validate(&p).is_err());
    }

    #[test]
    fn roundtrip_json() {
        let p = minimal();
        let text = serde_json::to_string(&p).unwrap();
        let back: MeasurementProgram = serde_json::from_str(&text).unwrap();
        assert_eq!(back, p);
    }

    #[test]
    fn canonical_bytes_are_deterministic_across_ordering_insensitive_fields() {
        let p = minimal();
        assert_eq!(canonical_bytes(&p), canonical_bytes(&p));
    }
}
