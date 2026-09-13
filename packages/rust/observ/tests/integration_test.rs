//! Integration tests: end-to-end verdicts over the ADR-0022…0028 worked
//! examples, mirroring the program JSON files under `programs/`.

use observ::kernel::{GateSignal, Kernel};
use observ::system::{
    validate, AdmissibilityDecl, Channel, ClaimClause, ClaimStatus, MeasurementProgram, Reference,
    ReversalCube, Stage, StageKind,
};

fn stage(name: &str, kind: StageKind, matrix: Vec<Vec<i64>>) -> Stage {
    Stage {
        name: name.into(),
        kind,
        matrix,
    }
}

fn channel(name: &str, rows: Vec<Vec<i64>>) -> Channel {
    Channel {
        name: name.into(),
        rows,
    }
}

/// Parse a program JSON fixture; fails the test loudly on a bad fixture.
fn from_fixture(path: &str) -> MeasurementProgram {
    let dir = env!("CARGO_MANIFEST_DIR");
    let full = std::path::Path::new(dir).join(path);
    let text = std::fs::read_to_string(&full).unwrap_or_else(|e| panic!("fixture {full:?}: {e}"));
    serde_json::from_str(&text).unwrap_or_else(|e| panic!("fixture {full:?}: {e}"))
}

// ---------------------------------------------------------------------------
// ADR-0022: the MnF2 four-null taxonomy — an unpolarized projection stage is
// honest and keeps the lattice even-odd channels.
// ---------------------------------------------------------------------------

#[test]
fn polarized_projection_stage_is_honest() {
    let program = MeasurementProgram {
        name: "polarization_split".into(),
        dim: 2,
        stages: vec![
            // Probe projection onto the polarization-even channel.
            stage(
                "unpolarized",
                StageKind::ProbeProjection,
                vec![vec![1, 0], vec![0, 0]],
            ),
        ],
        targets: vec![channel("chiral_correlator", vec![vec![1, 0]])],
        probes: vec![],
        claims: vec![],
        reversals: vec![],
        reference: None,
    };
    assert!(validate(&program).is_ok());
    let verdict = Kernel::new().measure(&program);
    // The even channel survives; the odd one is a polarization-projection null.
    assert_eq!(verdict.signal, GateSignal::Nominal);
    assert!(verdict.defects.is_empty());
    let proj = &verdict.filtration[0];
    assert_eq!(proj.new_null, 1);
    assert_eq!(proj.four_null_class, "polarization_projection");
}

// ---------------------------------------------------------------------------
// ADR-0023 + 0022: δJ7 reference sector — group average, odd complement,
// admissibility certificate, parity covariance.
// ---------------------------------------------------------------------------

#[test]
fn mnf2_dj7_reference_sector_is_admissible() {
    let program = MeasurementProgram {
        name: "mnf2_sector".into(),
        dim: 2,
        stages: vec![stage(
            "response",
            StageKind::Response,
            vec![vec![1, 0], vec![0, 1]],
        )],
        targets: vec![channel("dj7_odd", vec![vec![1, -1]])],
        probes: vec![],
        claims: vec![],
        reversals: vec![],
        reference: Some(Reference {
            operator_dim: 2,
            group: vec![vec![vec![1, 0], vec![0, 1]], vec![vec![0, 1], vec![1, 0]]],
            target: vec![vec![1, -1]],
            declared: AdmissibilityDecl {
                independent: true,
                state: true,
                no_retune: true,
            },
            odd_direction: vec![1, -1],
            characters: vec![1, -1],
        }),
    };
    let verdict = Kernel::new().measure(&program);
    let sector = verdict.reference.expect("sector reported");
    assert!(sector.a_null);
    assert!(sector.odd_in_complement);
    assert!(sector.odd_flipped);
    assert!(sector.parity_holds);
    assert!(sector.admissible);
    assert_eq!(sector.invariant_dim, 1);
    assert_eq!(sector.complement_dim, 1);
}

#[test]
fn dj7_with_no_retune_loss_is_inadmissible_and_bound_default() {
    let program = MeasurementProgram {
        name: "mnf2_sector_no_retune".into(),
        dim: 2,
        stages: vec![stage(
            "response",
            StageKind::Response,
            vec![vec![1, 0], vec![0, 1]],
        )],
        targets: vec![channel("dj7_odd", vec![vec![1, -1]])],
        probes: vec![],
        claims: vec![ClaimClause {
            component: "S".into(),
            status: ClaimStatus::Closed,
            channel: Some("dj7_odd".into()),
            focus: Some("dj7_odd".into()),
        }],
        reversals: vec![],
        reference: Some(Reference {
            operator_dim: 2,
            group: vec![vec![vec![1, 0], vec![0, 1]], vec![vec![0, -1], vec![-1, 0]]],
            target: vec![vec![1, -1]],
            declared: AdmissibilityDecl {
                independent: true,
                state: true,
                no_retune: false,
            },
            odd_direction: vec![1, -1],
            characters: vec![1, -1],
        }),
    };
    let verdict = Kernel::new().measure(&program);
    assert!(verdict.signal.is_kill());
    assert!(verdict
        .defects
        .iter()
        .any(|d| d.code == observ::DefectCode::ReferenceInapplicable));
}

// ---------------------------------------------------------------------------
// ADR-0024 + 0027: Walsh–Hadamard reversal coding and the path-consistency
// gate.
// ---------------------------------------------------------------------------

#[test]
fn reversal_cube_detects_sector_and_leak() {
    let program = MeasurementProgram {
        name: "reversal_cube".into(),
        dim: 2,
        stages: vec![stage(
            "response",
            StageKind::Response,
            vec![vec![1, 0], vec![0, 1]],
        )],
        targets: vec![channel("target", vec![vec![1, 0]])],
        probes: vec![],
        claims: vec![],
        reversals: vec![ReversalCube {
            // y(s) = s_0 s_1 → character in sector 3.
            n: 2,
            cube: vec![1, -1, -1, 1],
            forbidden_masks: vec![3],
            state_dim: 2,
            reversal_maps: vec![vec![vec![1, 0], vec![0, 1]], vec![vec![1, 0], vec![0, 1]]],
        }],
        reference: None,
    };
    let verdict = Kernel::new().measure(&program);
    assert!(verdict.signal.is_kill());
    assert!(verdict
        .defects
        .iter()
        .any(|d| d.code == observ::DefectCode::ForbiddenSectorLeak));
    let rep = &verdict.reversals[0];
    assert_eq!(rep.forbidden_leaks, vec![3]);
    let sector3 = rep
        .characters
        .iter()
        .find(|(m, _)| *m == 3)
        .map(|(_, q)| *q)
        .expect("mask 3 is nonzero");
    assert_eq!(sector3, observ::Q::ONE);
}

#[test]
fn non_commuting_reversals_breach_path_consistency() {
    let sx = vec![vec![0, 1], vec![1, 0]];
    let sz = vec![vec![1, 0], vec![0, -1]];
    let program = MeasurementProgram {
        name: "reversal_breach".into(),
        dim: 2,
        stages: vec![stage(
            "response",
            StageKind::Response,
            vec![vec![1, 0], vec![0, 1]],
        )],
        targets: vec![channel("target", vec![vec![1, 0]])],
        probes: vec![],
        claims: vec![],
        reversals: vec![ReversalCube {
            n: 2,
            cube: vec![0, 0, 0, 0],
            forbidden_masks: vec![],
            state_dim: 2,
            reversal_maps: vec![sx, sz],
        }],
        reference: None,
    };
    let verdict = Kernel::new().measure(&program);
    assert!(!verdict.reversals[0].group_characters_valid);
    assert!(verdict.signal.is_kill());
}

// ---------------------------------------------------------------------------
// ADR-0025/0027/0028: the stress-test target — a tiny Δ beats a huge σ.
// Exact integer stand-in for the paper's ([0 1], σ=0.01, τ=1) example:
// B_sig = [0 10000], B_tar = [100 1], C = [1 0].
// ---------------------------------------------------------------------------

#[test]
fn wide_variances_do_not_substitute_for_target_channel() {
    let program = MeasurementProgram {
        name: "stress_target".into(),
        dim: 2,
        stages: vec![stage(
            "source",
            StageKind::Source,
            vec![vec![0, 1], vec![0, 0]],
        )],
        targets: vec![channel("C", vec![vec![1, 0]])],
        probes: vec![
            channel("B_sig", vec![vec![0, 1], vec![0, 10000]]),
            channel("B_tar", vec![vec![0, 1], vec![100, 1]]),
        ],
        claims: vec![],
        reversals: vec![],
        reference: None,
    };
    let verdict = Kernel::new().measure(&program);
    // Repeating B_sig cannot remove the obstruction (rows dependent): Δ = 0.
    let sig = verdict
        .design_gain
        .iter()
        .find(|g| g.probe == "B_sig")
        .expect("B_sig");
    assert_eq!(sig.gain, 0);
    // B_tar adds the missing direction: Δ = 1.
    let tar = verdict
        .design_gain
        .iter()
        .find(|g| g.probe == "B_tar")
        .expect("B_tar");
    assert_eq!(tar.gain, 1);
    assert_eq!(tar.with_probe_dim, 0);
    // With B_tar the full stack (−= no residual kernel) is fully identified.
    assert_eq!(verdict.targets[0].obstruction_dim, 0);
}

// ---------------------------------------------------------------------------
// ADR-0026: the six-component claim matrix across bulk-AFM materials.
// ---------------------------------------------------------------------------

#[test]
fn bulk_ruo2_source_claim_blocked_by_contradicted_microstructure() {
    let program = from_fixture("programs/claim_matrix.json");
    assert!(validate(&program).is_ok());
    let verdict = Kernel::new().measure(&program);
    // Source-state gate blocks S under the RuO2 contradictory micro result.
    let s = verdict
        .claims
        .iter()
        .find(|c| c.component == "S")
        .expect("S clause");
    assert!(s.downstream_blocked);
    assert_eq!(s.revised, "blocked");
    assert!(verdict.signal.is_kill());
}

#[test]
fn clean_mnsi_claim_matrix_keeps_chi_and_stress_signals() {
    let program = from_fixture("programs/claim_matrix_mnsi.json");
    assert!(validate(&program).is_ok());
    let verdict = Kernel::new().measure(&program);
    assert_eq!(verdict.signal, GateSignal::Nominal);
    let chi = verdict
        .claims
        .iter()
        .find(|c| c.component == "X")
        .expect("X clause");
    // χ ≠ 0 with no source attribution is not an altermagnet claim.
    assert_eq!(chi.declared, "closed");
    assert_eq!(chi.revised, "closed");
    let s = verdict.claims.iter().find(|c| c.component == "S").unwrap();
    assert_eq!(s.revised, "open");
}

// ---------------------------------------------------------------------------
// ADR-0028 refactorization: same total map, different stage attribution.
// ---------------------------------------------------------------------------

#[test]
fn factorization_attribution_differs_at_the_stage_but_not_the_fiber() {
    let program_a = from_fixture("programs/refactor_a.json");
    let program_b = from_fixture("programs/refactor_b.json");
    let va = Kernel::new().measure(&program_a);
    let vb = Kernel::new().measure(&program_b);

    // Same total fibers: identical null_dim at the end.
    let last_null = |v: &observ::ObservVerdict| -> usize {
        v.filtration.last().map(|s| s.null_dim).unwrap_or(0)
    };
    assert_eq!(last_null(&va), last_null(&vb));
    // Different attribution: the null appears at different stages.
    assert_ne!(va.filtration[0].new_null, vb.filtration[0].new_null);
}

// ---------------------------------------------------------------------------
// Receipts: issued on kills and nominals, bound into PWEH.
// ---------------------------------------------------------------------------

#[test]
fn receipts_bound_into_pweh_on_both_paths() {
    let nominal = from_fixture("programs/polarization_split.json");
    let disputed = from_fixture("programs/claim_matrix.json");

    let vn = Kernel::new().measure(&nominal);
    let vk = Kernel::new().measure(&disputed);
    assert_eq!(vn.receipt.pweh_chain_root.len(), 64);
    assert_eq!(vk.receipt.pweh_chain_root.len(), 64);
    assert!(vn.receipt.lean_mirror.is_none());
    assert_ne!(vn.receipt.program_sha256, vk.receipt.program_sha256);
}

// ---------------------------------------------------------------------------
// Malformed programs never reach the gate.
// ---------------------------------------------------------------------------

#[test]
fn malformed_program_is_named_and_killed() {
    let mut program = from_fixture("programs/polarization_split.json");
    program.targets[0].rows = vec![vec![1, 0, 0, 0]];
    let verdict = Kernel::new().measure(&program);
    assert!(verdict.signal.is_kill());
    assert!(verdict
        .defects
        .iter()
        .any(|d| d.code == observ::DefectCode::ProgramMalformed));
}
