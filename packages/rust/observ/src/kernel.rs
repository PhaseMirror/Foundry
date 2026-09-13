//! The observability gate (ADR-0022…0028): null filtration, witness duality,
//! obstruction dimension, design gain, reversal-space coding, source-sector
//! admissibility, and the six-component claim gate — closed by the fail latch.
//!
//! ## What is computed
//!
//! For a declared layering M = T ∘ A ∘ P ∘ R ∘ S (stages applied first-to-last
//! in `program.stages`), the kernel derives the cumulative maps F_j, the null
//! filtration K_j = ker F_j, the dual witnesses W_j = Ann(K_j) = im F_j^*, the
//! per-stage null growth, every target's obstruction dimension
//! `d_C(A_stack) = dim C(ker A_stack)` with a constructive dual counterexample
//! when positive, the design gain Δ_C(B|E) = d_C(E) − d_C(E∪B) of each
//! declared probe, the Walsh–Hadamard reversal characters (exact rationals),
//! the reference-sector projector and admissibility certificate, and the
//! six-vector claim verdicts.
//!
//! ## Fail-closed
//!
//! A named defect Δ or an expansive pipeline kills the transition through the
//! Kani-verified [`crmf::failgate::FailLatch`]. No autoduction: every status
//! change is reported as *declared* vs *revised*, and every disagreement is a
//! named English defect, not a silent rewrite.
//!
//! ## Storage boundary
//!
//! This crate issues receipts and binds them into the CRMF PWEH chain; it
//! performs no archival (no WORM). See `crate::receipt`.

use serde::{Deserialize, Serialize};

use crate::claim::assess_claims;
use crate::defect::{DefectCode, ObservDefect};
use crate::la::{self, Row};
use crate::levers as lever_lang;
use crate::levers::Lever;
use crate::rat::Q;
use crate::receipt::Receipt;
use crate::reversal::{self, WalshReport};
use crate::sector;
use crate::system::{program_hash, q_rows, validate, MeasurementProgram, StageKind};
use crmf::failgate::{FailLatch, GovSignal};
use std::collections::HashMap;

/// Lockdown on pipeline cells `dim × stages`; exceeding it is an expansive
/// transition (ADR-0027 §6 recursion-escalation analog).
pub const LOCKDOWN_PIPELINE_CELLS: usize = MAX_DIM * MAX_STAGES;
use crate::system::{MAX_DIM, MAX_STAGES};

/// Component ordering inside the six-vector claim (ADR-0026).
const COMPONENT_INDEX: [&str; 6] = ["M", "S", "E", "X", "R", "K"];
pub fn component_index(c: &str) -> u8 {
    COMPONENT_INDEX
        .iter()
        .position(|&x| x == c.to_uppercase())
        .map(|i| i as u8)
        .unwrap_or(0)
}

/// The serializable governance signal of a measurement.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum GateSignal {
    Nominal,
    SigGovKill,
}

impl GateSignal {
    #[inline]
    pub const fn is_kill(&self) -> bool {
        matches!(self, GateSignal::SigGovKill)
    }
}

impl From<GovSignal> for GateSignal {
    fn from(sig: GovSignal) -> Self {
        match sig {
            GovSignal::Nominal => GateSignal::Nominal,
            GovSignal::SigGovKill => GateSignal::SigGovKill,
        }
    }
}

/// One stage of the null filtration report.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StageReport {
    pub index: usize,
    pub name: String,
    pub kind: String,
    /// rank(F_j)
    pub rank: usize,
    /// dim K_j = dim ker F_j
    pub null_dim: usize,
    /// dim W_j = dim im F_j^*
    pub witness_dim: usize,
    /// dim K_j − dim K_{j−1}: new null directions born this stage.
    pub new_null: usize,
    /// Legacy four-null taxonomy class of the stage kind (ADR-0022).
    pub four_null_class: String,
}

/// Per-target identifiability over the full stacked pipeline.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TargetReport {
    pub name: String,
    /// d_C(all maps ∪ probes)
    pub obstruction_dim: usize,
    /// Whether the final cumulative map alone identifies the target (K ⊆ ker C).
    pub final_survives: bool,
    /// The first cumulative stage at which a target-changing direction is born
    /// (K_j gains a direction not killed by C). None when never.
    pub first_kill_at: Option<usize>,
    /// A constructive dual counterexample v ∈ ker A_stack with C v ≠ 0,
    /// when the obstruction is positive.
    pub counterexample: Option<Vec<Q>>,
}

/// Design gain Δ_C(B|E) of one probe over the baseline pipeline.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DesignGain {
    pub probe: String,
    pub baseline_dim: usize,
    pub with_probe_dim: usize,
    pub gain: usize,
}

/// Walsh–Hadamard character report for one reversal cube.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReversalReport {
    pub n: usize,
    /// Non-zero exact characters Î_A keyed by mask.
    pub characters: Vec<(u64, Q)>,
    pub group_characters_valid: bool,
    pub forbidden_leaks: Vec<u64>,
}

/// Sector report for one declared reference (ADR-0023).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReferenceReport {
    pub operator_dim: usize,
    pub group_size: usize,
    pub invariant_dim: usize,
    pub complement_dim: usize,
    pub a_null: bool,
    pub odd_in_complement: bool,
    pub odd_flipped: bool,
    pub parity_holds: bool,
    pub admissible: bool,
}

/// Judgment of one six-vector clause, wired into the verdict.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClaimJudgement {
    pub component: String,
    pub declared: String,
    pub revised: String,
    pub identified: bool,
    pub downstream_blocked: bool,
    pub message: String,
}

/// The verdict of one `measure` call.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ObservVerdict {
    pub program_name: String,
    pub kernel_version: String,
    pub filtration: Vec<StageReport>,
    pub targets: Vec<TargetReport>,
    pub design_gain: Vec<DesignGain>,
    pub reversals: Vec<ReversalReport>,
    pub reference: Option<ReferenceReport>,
    pub claims: Vec<ClaimJudgement>,
    pub defects: Vec<ObservDefect>,
    pub levers: Vec<Lever>,
    pub signal: GateSignal,
    pub expansive: bool,
    pub receipt: Receipt,
}

/// The stateless observ kernel.
#[derive(Debug, Clone, Copy, Default)]
pub struct Kernel;

impl Kernel {
    pub const fn new() -> Self {
        Kernel
    }

    /// Run the gate over a measurement program.
    pub fn measure(&self, program: &MeasurementProgram) -> ObservVerdict {
        let (mut defects, expansive) = measure_laws(program);

        // Only well-formed programs have geometry; malformed ones are named and
        // killed without touching the linear algebra (no panics on bad shapes).
        let geometry = if validate(program).is_ok() {
            measure_geometry(program)
        } else {
            Geometry::default()
        };
        let signal = decide(!defects.is_empty(), expansive);

        // Wire claim judgements produced during geometry back into the gates.
        for (i, j) in geometry.claims.iter().enumerate() {
            let Some(cl) = program.claims.get(i) else {
                continue;
            };
            // ClaimMigration: a closing claim whose channel does not resolve.
            if cl.status.closes() && !j.identified {
                defects.push(
                    ObservDefect::new(DefectCode::ClaimMigration, 1)
                        .at(component_index(&cl.component) as u64),
                );
            }
            // DownstreamBeforeSourceGate: closing downstream while M is dirty.
            if cl.status.closes() && j.downstream_blocked {
                defects.push(
                    ObservDefect::new(DefectCode::DownstreamBeforeSourceGate, 1)
                        .at(component_index(&cl.component) as u64),
                );
            }
            // ReferenceInapplicable: an S claim closes without an admissible
            // declared reference sector.
            if cl.component.eq_ignore_ascii_case("S")
                && cl.status.closes()
                && geometry
                    .reference
                    .as_ref()
                    .map(|r| !r.admissible)
                    .unwrap_or(true)
            {
                defects.push(ObservDefect::new(DefectCode::ReferenceInapplicable, 1).at(4));
            }
        }
        // Mark expansive if the pipeline exceeded lockdown (already in laws).

        let levers = derive_levers(&defects);
        let receipt = Receipt::issue(program_hash(program), signal, &defects);

        ObservVerdict {
            program_name: program.name.clone(),
            kernel_version: crate::KERNEL_VERSION.to_string(),
            filtration: geometry.filtration,
            targets: geometry.targets,
            design_gain: geometry.design_gain,
            reversals: geometry.reversals,
            reference: geometry.reference,
            claims: geometry.claims,
            defects,
            levers,
            signal,
            expansive,
            receipt,
        }
    }

    /// Pure lawfulness evaluation (no gate side effects, no receipt) — the
    /// `verify` surface.
    pub fn laws(&self, program: &MeasurementProgram) -> (Vec<ObservDefect>, bool) {
        measure_laws(program)
    }
}

/// The pure fail-closed decision. Verified by the Kani harnesses in
/// `[kani_proofs]`.
#[inline]
pub fn decide(named_defect: bool, expansive: bool) -> GateSignal {
    let mut latch = FailLatch::new();
    latch.commit(named_defect, expansive).into()
}

/// Restricted analysis rows derived during geometry (`TargetGeometry`).
struct TargetGeometry {
    name: String,
    obstruction: usize,
    final_survives: bool,
    first_kill_at: Option<usize>,
    counterexample: Option<Vec<Q>>,
}

#[derive(Default)]
pub(crate) struct Geometry {
    filtration: Vec<StageReport>,
    targets: Vec<TargetReport>,
    design_gain: Vec<DesignGain>,
    reversals: Vec<ReversalReport>,
    reference: Option<ReferenceReport>,
    claims: Vec<ClaimJudgement>,
}

/// Stage maps as exact rows.
fn stage_rows(program: &MeasurementProgram) -> Vec<Vec<Row>> {
    program.stages.iter().map(|s| q_rows(&s.matrix)).collect()
}

/// The full stacked map: every stage applied plus every declared probe.
fn full_stack(program: &MeasurementProgram, cumulative: &[Vec<Row>]) -> Vec<Row> {
    let mut rows: Vec<Row> = cumulative
        .last()
        .cloned()
        .unwrap_or_else(|| la::identity(program.dim));
    for p in &program.probes {
        rows.extend(q_rows(&p.rows));
    }
    rows
}

fn target_geometries(program: &MeasurementProgram, cumulative: &[Vec<Row>]) -> Vec<TargetGeometry> {
    let targets_q: Vec<Vec<Row>> = program.targets.iter().map(|t| q_rows(&t.rows)).collect();
    let stacked = full_stack(program, cumulative);
    let final_map = cumulative
        .last()
        .cloned()
        .unwrap_or_else(|| la::identity(program.dim));
    program
        .targets
        .iter()
        .zip(targets_q.iter())
        .map(|(declared, c)| {
            let ob = la::obstruction_dimension(&stacked, c);
            let mut first_kill_at: Option<usize> = None;
            for (j, f) in cumulative.iter().enumerate() {
                if !la::target_survives(f, c) {
                    first_kill_at = Some(j);
                    break;
                }
            }
            TargetGeometry {
                name: declared.name.clone(),
                obstruction: ob.dimension,
                final_survives: la::target_survives(&final_map, c),
                first_kill_at,
                counterexample: ob.counterexample,
            }
        })
        .collect()
}

/// Compute the pure geometry report (no gate side effects).
pub(crate) fn measure_geometry(program: &MeasurementProgram) -> Geometry {
    let stage_mats = stage_rows(program);
    let cumulative = la::cumulative_maps(program.dim, &stage_mats);
    let filtration: Vec<Vec<Row>> = la::null_filtration(&cumulative);

    // Filtration report.
    let mut prev_kernel: Vec<Row> = Vec::new();
    let mut stage_reports: Vec<StageReport> = Vec::new();
    for (i, stage) in program.stages.iter().enumerate() {
        let kernel = filtration.get(i).cloned().unwrap_or_default();
        let witness_dim = la::rank(&cumulative[i]);
        let new_null = la::new_direction_count(&kernel, &prev_kernel);
        stage_reports.push(StageReport {
            index: i,
            name: stage.name.clone(),
            kind: stage.kind.as_str().to_string(),
            rank: la::rank(&cumulative[i]),
            null_dim: kernel.len(),
            witness_dim,
            new_null,
            four_null_class: stage.kind.four_null().to_string(),
        });
        prev_kernel = kernel;
    }

    let targets = target_geometries(program, &cumulative);
    let target_report: Vec<TargetReport> = targets
        .iter()
        .map(|t| TargetReport {
            name: t.name.clone(),
            obstruction_dim: t.obstruction,
            final_survives: t.final_survives,
            first_kill_at: t.first_kill_at,
            counterexample: t.counterexample.clone(),
        })
        .collect();

    // Design gain per probe over the baseline (final map + all other probes).
    let mut design_gain: Vec<DesignGain> = Vec::new();
    {
        let final_map = cumulative
            .last()
            .cloned()
            .unwrap_or_else(|| la::identity(program.dim));
        for (pi, probe) in program.probes.iter().enumerate() {
            let mut base_rows: Vec<Row> = final_map.clone();
            for (q, other) in program.probes.iter().enumerate() {
                if q != pi {
                    base_rows.extend(q_rows(&other.rows));
                }
            }
            let c_row = program
                .targets
                .first()
                .map(|t| q_rows(&t.rows))
                .unwrap_or_default();
            let base_dim = if c_row.is_empty() {
                0
            } else {
                la::obstruction_dimension(&base_rows, &c_row).dimension
            };
            let mut plus_rows = base_rows;
            plus_rows.extend(q_rows(&probe.rows));
            let with_dim = if c_row.is_empty() {
                0
            } else {
                la::obstruction_dimension(&plus_rows, &c_row).dimension
            };
            design_gain.push(DesignGain {
                probe: probe.name.clone(),
                baseline_dim: base_dim,
                with_probe_dim: with_dim,
                gain: base_dim.saturating_sub(with_dim),
            });
        }
    }

    // Reversal reports.
    let reversals: Vec<ReversalReport> = program
        .reversals
        .iter()
        .map(|rv| {
            let w: WalshReport = reversal::walsh(rv);
            ReversalReport {
                n: rv.n,
                characters: w
                    .coefficients
                    .into_iter()
                    .filter(|(_, q)| !q.is_zero())
                    .collect(),
                group_characters_valid: w.group_characters_valid,
                forbidden_leaks: w.forbidden_leaks,
            }
        })
        .collect();

    // Reference sector.
    let reference = match &program.reference {
        None => None,
        Some(r) => match sector::analyze_reference(r, &program.name) {
            Ok((rep, _)) => Some(ReferenceReport {
                operator_dim: rep.operator_dim,
                group_size: rep.group_size,
                invariant_dim: rep.invariant_dim,
                complement_dim: rep.complement_dim,
                a_null: rep.a_null,
                odd_in_complement: rep.odd_in_complement,
                odd_flipped: rep.odd_flipped,
                parity_holds: rep.parity_holds,
                admissible: rep.admissible,
            }),
            Err(_) => None,
        },
    };

    // Claim judgements.
    let probes_q: Vec<Vec<Row>> = program.probes.iter().map(|p| q_rows(&p.rows)).collect();
    let targets_q: Vec<Vec<Row>> = program.targets.iter().map(|t| q_rows(&t.rows)).collect();
    let mut channel_by_name: HashMap<&str, &Vec<Row>> = HashMap::new();
    for (c, q) in program.probes.iter().zip(probes_q.iter()) {
        channel_by_name.insert(c.name.as_str(), q);
    }
    for (c, q) in program.targets.iter().zip(targets_q.iter()) {
        channel_by_name.insert(c.name.as_str(), q);
    }
    let mut target_by_name: HashMap<&str, &Vec<Row>> = HashMap::new();
    for (c, q) in program.targets.iter().zip(targets_q.iter()) {
        target_by_name.insert(c.name.as_str(), q);
    }

    let identify = |cl: &crate::system::ClaimClause| -> Option<bool> {
        let probe = cl.channel.as_ref()?;
        let focus = cl.focus.as_ref()?;
        let a = channel_by_name.get(probe.as_str())?;
        let c = target_by_name.get(focus.as_str())?;
        Some(la::obstruction_dimension(a, c).dimension == 0)
    };

    let assessments = assess_claims(&program.claims, &identify);
    let claims = program
        .claims
        .iter()
        .zip(assessments.iter())
        .map(|(cl, a)| {
            let message = match a.identified {
                true => "channel resolves this component (obstruction zero)".to_string(),
                false => "channel does not resolve this component".to_string(),
            };
            ClaimJudgement {
                component: cl.component.to_uppercase(),
                declared: cl.status.as_str().to_string(),
                revised: a.revised.as_str().to_string(),
                identified: a.identified,
                downstream_blocked: a.downstream_blocked,
                message,
            }
        })
        .collect();

    Geometry {
        filtration: stage_reports,
        targets: target_report,
        design_gain,
        reversals,
        reference,
        claims,
    }
}

/// Lawfulness: every structural invariant of the measurement program,
/// collected into named English defects plus the expansivity flag.
pub fn measure_laws(program: &MeasurementProgram) -> (Vec<ObservDefect>, bool) {
    let mut defects: Vec<ObservDefect> = Vec::new();

    if let Err(e) = validate(program) {
        defects.push(
            ObservDefect::new(DefectCode::ProgramMalformed, 1)
                .at(0)
                .with_english(&e.to_string()),
        );
        return (defects, false);
    }

    // Expansivity (ADR-0027 §6): pipeline cells beyond lockdown.
    let cells = program.dim * program.stages.len();
    let expansive = cells > LOCKDOWN_PIPELINE_CELLS;
    if expansive {
        defects.push(ObservDefect::new(
            DefectCode::ExpansiveTransition,
            cells as u64,
        ));
    }

    let g = measure_geometry(program);

    // NullMisattribution: the FIRST stage to birth a target-changing null
    // direction must not be a declared nuisance map.
    for (i, stage) in program.stages.iter().enumerate() {
        if stage.kind != StageKind::Nuisance {
            continue;
        }
        if g.targets.iter().any(|t| t.first_kill_at == Some(i)) {
            defects.push(ObservDefect::new(DefectCode::NullMisattribution, 1).at(i as u64));
        }
    }

    // Reversal-path and leakage defects.
    for (i, rv) in program.reversals.iter().enumerate() {
        let w: WalshReport = reversal::walsh(rv);
        if !w.group_characters_valid {
            defects.push(ObservDefect::new(DefectCode::ReversalPathBreach, 1).at(i as u64));
        }
        if !w.forbidden_leaks.is_empty() {
            defects.push(
                ObservDefect::new(
                    DefectCode::ForbiddenSectorLeak,
                    w.forbidden_leaks.len() as u64,
                )
                .at(i as u64),
            );
        }
    }

    // Claim-gate defects are derived from the geometry judgements.
    let (mut gate_defects, _) = claim_gate_defects(program, &g);
    defects.append(&mut gate_defects);

    (defects, expansive)
}

/// The claim-gate defects derivable from the geometry judgements.
fn claim_gate_defects(program: &MeasurementProgram, g: &Geometry) -> (Vec<ObservDefect>, bool) {
    let mut defects: Vec<ObservDefect> = Vec::new();
    for (i, j) in g.claims.iter().enumerate() {
        let Some(cl) = program.claims.get(i) else {
            continue;
        };
        if cl.status.closes() && !j.identified {
            defects.push(
                ObservDefect::new(DefectCode::ClaimMigration, 1)
                    .at(component_index(&cl.component) as u64),
            );
        }
        if cl.status.closes() && j.downstream_blocked {
            defects.push(
                ObservDefect::new(DefectCode::DownstreamBeforeSourceGate, 1)
                    .at(component_index(&cl.component) as u64),
            );
        }
        if cl.component.eq_ignore_ascii_case("S")
            && cl.status.closes()
            && g.reference.as_ref().map(|r| !r.admissible).unwrap_or(true)
        {
            defects.push(ObservDefect::new(DefectCode::ReferenceInapplicable, 1).at(4));
        }
    }
    (defects, false)
}

/// One `[owner] — action — metric — horizon` lever per named defect.
pub fn derive_levers(defects: &[ObservDefect]) -> Vec<Lever> {
    defects
        .iter()
        .map(|d| {
            Lever::new(
                d.owner,
                lever_lang::lever_action(d.code),
                d.metric,
                lever_lang::horizon(),
            )
        })
        .collect()
}

/// Research surface: recover the exact obstruction theory for a stage-known
/// program. Also makes the crate's no-float claim auditable.
pub fn exact_counterexample(program: &MeasurementProgram, target: &str) -> Result<Vec<Q>, String> {
    let g = measure_geometry(program);
    let tr = g
        .targets
        .iter()
        .find(|t| t.name == target)
        .ok_or_else(|| format!("unknown target {target}"))?;
    tr.counterexample
        .clone()
        .ok_or_else(|| "target is identified; obstruction is zero".to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::system::{Channel, ClaimClause, ClaimStatus, Stage};

    fn identity_stage(kind: StageKind) -> Stage {
        Stage {
            name: format!("s-{}", kind.as_str()),
            kind,
            matrix: vec![vec![1, 0], vec![0, 1]],
        }
    }

    fn base_program() -> MeasurementProgram {
        MeasurementProgram {
            name: "t".into(),
            dim: 2,
            stages: vec![identity_stage(StageKind::Response)],
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
    fn nominal_pipeline_measures() {
        let p = base_program();
        let v = Kernel::new().measure(&p);
        assert_eq!(v.signal, GateSignal::Nominal);
        assert!(v.defects.is_empty());
        assert_eq!(v.targets[0].obstruction_dim, 0);
        assert_eq!(v.filtration[0].new_null, 0);
    }

    #[test]
    fn obstructed_target_kills_claimed_closure() {
        // Zero probe keeps every direction in the kernel: focus not identifiable.
        let mut p = base_program();
        p.probes.push(Channel {
            name: "zero".into(),
            rows: vec![vec![0, 0]],
        });
        p.claims.push(ClaimClause {
            component: "M".into(),
            status: ClaimStatus::Closed,
            channel: Some("zero".into()),
            focus: Some("t".into()),
        });
        let v = Kernel::new().measure(&p);
        assert!(v
            .defects
            .iter()
            .any(|d| d.code == DefectCode::ClaimMigration));
    }

    #[test]
    fn contaminated_micro_blocks_downstream_and_kills() {
        let mut p = base_program();
        p.claims.push(ClaimClause {
            component: "M".into(),
            status: ClaimStatus::Contradicted,
            channel: Some("t".into()),
            focus: Some("t".into()),
        });
        p.claims.push(ClaimClause {
            component: "S".into(),
            status: ClaimStatus::Closed,
            channel: Some("t".into()),
            focus: Some("t".into()),
        });
        let v = Kernel::new().measure(&p);
        assert!(v
            .defects
            .iter()
            .any(|d| d.code == DefectCode::DownstreamBeforeSourceGate));
        assert!(v.signal.is_kill());
        // Reference rule also fires for the closed S claim (no reference).
        assert!(v
            .defects
            .iter()
            .any(|d| d.code == DefectCode::ReferenceInapplicable));
    }

    #[test]
    fn design_gain_is_nonnegative_and_matches_paper6() {
        // Intervention U = [[0,1],[1,0]] restores the erased direction that the
        // focus functional C = [0 1] observes.
        let mut p = base_program();
        p.stages[0].matrix = vec![vec![1, 0], vec![0, 0]];
        p.targets[0].rows = vec![vec![0, 1]];
        p.probes.push(Channel {
            name: "U".into(),
            rows: vec![vec![0, 1], vec![1, 0]],
        });
        let v = Kernel::new().measure(&p);
        // Stacked = I ⇒ d_C = 0 with the probe.
        assert_eq!(v.targets[0].obstruction_dim, 0);
        assert_eq!(v.design_gain[0].with_probe_dim, 0);
        assert!(v.design_gain[0].gain > 0);
    }
}

#[cfg(kani)]
mod kani_proofs {
    use super::*;

    /// Fail-closed: any named defect or expansive pipeline kills.
    #[kani::proof]
    pub fn observ_gate_fail_closed() {
        let named: bool = kani::any();
        let expansive: bool = kani::any();
        kani::assume(named || expansive);
        let sig = decide(named, expansive);
        assert!(sig.is_kill());
    }

    /// No false kills: a fresh, defect-free nominal measurement stays Nominal.
    #[kani::proof]
    pub fn observ_gate_no_false_kill() {
        let sig = decide(false, false);
        assert!(!sig.is_kill());
    }

    /// A kill is warranted: it implies a named defect or an expansive pipeline.
    #[kani::proof]
    pub fn observ_gate_kill_requires_evidence() {
        let named: bool = kani::any();
        let expansive: bool = kani::any();
        let sig = decide(named, expansive);
        if sig.is_kill() {
            assert!(named || expansive);
        } else {
            assert!(!named && !expansive);
        }
    }
}
