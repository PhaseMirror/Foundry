//! Execution of operations as native `.holo` artifacts.

use hologram_backend::CpuBackend;
use hologram_compiler::{compile, BackendKind};
use hologram_exec::{buffer::InputBuffer, BufferArena, InferenceSession};
use hologram_graph::constant::ConstantEntry;
use hologram_graph::graph::Graph;
use hologram_graph::node::{GatherAttrs, GraphOp, InputSource, Node};
use hologram_graph::registry::DTypeId;
use hologram_ops::OpKind;
use uor_foundation::WittLevel;

/// A Hologram compiled artifact.
pub struct HoloArtifact {
    /// The name of the gate.
    pub gate_name: String,
    /// The compiled artifact bytes.
    pub archive_bytes: Vec<u8>,
    /// The κ-address of the artifact.
    pub kappa: String,
    /// The execution backend used.
    pub backend: String,
}

/// The result of executing a `.holo` artifact.
pub struct HoloExecution {
    /// The artifact that was executed.
    pub artifact: HoloArtifact,
    /// The κ-address of the input state.
    pub input_kappa: String,
    /// The κ-address of the output state.
    pub output_kappa: String,
    /// The resulting output state bytes.
    pub output_bytes: Vec<u8>,
}

/// Compiles a permutation gate into a `.holo` artifact and executes it on the native engine.
///
/// This dynamically constructs a computation graph with a `Gather` op, compiles it to an archive,
/// and runs it using `InferenceSession` over the binary-encoded κ-state inputs.
pub fn execute_holo_gate(
    gate_name: &str,
    targets: &[usize],
    state_bytes: &[u8],
) -> Result<HoloExecution, String> {
    let mut g = Graph::new();
    let dtype_i64 = DTypeId(5); // DTYPE_I64 is 5
    let input_len = (state_bytes.len() / 8) as u64;
    let shape_input = g
        .shape_registry_mut()
        .intern(hologram_graph::registry::ShapeDescriptor::rank1(input_len));
    let shape_indices =
        g.shape_registry_mut()
            .intern(hologram_graph::registry::ShapeDescriptor::rank1(
                targets.len() as u64 * 2,
            ));

    let in_node = g.add_node(Node {
        op: GraphOp::Input,
        inputs: smallvec::smallvec![],
        output_dtype: dtype_i64,
        output_shape: shape_input,
    });
    g.add_named_input(in_node, "state");

    let mut indices = Vec::with_capacity(targets.len() * 2);
    for &t in targets {
        indices.push((t * 2) as i64);
        indices.push((t * 2 + 1) as i64);
    }
    let indices_bytes: Vec<u8> = indices.iter().flat_map(|&x| x.to_le_bytes()).collect();

    let cid = g.constants_mut().insert(ConstantEntry {
        bytes: indices_bytes,
        dtype: dtype_i64,
        shape: shape_indices,
    });

    let c_node = g.add_node(Node {
        op: GraphOp::Constant(cid),
        inputs: smallvec::smallvec![],
        output_dtype: dtype_i64,
        output_shape: shape_indices,
    });

    let gather_node = g.add_node(Node {
        op: GraphOp::Op(OpKind::Gather),
        inputs: smallvec::smallvec![InputSource::Node(in_node), InputSource::Node(c_node)],
        output_dtype: dtype_i64,
        output_shape: shape_indices,
    });
    g.set_gather_attrs(gather_node, GatherAttrs { axis: 0 });
    g.add_named_output(gather_node, "output");

    let compiled = compile(g, BackendKind::Cpu, WittLevel::W32).map_err(|e| format!("{:?}", e))?;
    let backend = CpuBackend::<BufferArena>::new();
    let mut session =
        InferenceSession::load(&compiled.archive, backend).map_err(|e| format!("{:?}", e))?;

    let outputs = session
        .execute(&[InputBuffer { bytes: state_bytes }])
        .map_err(|e| format!("{:?}", e))?;

    let output_bytes = outputs[0].bytes.to_vec();

    let archive_bytes = compiled.archive.clone();
    let kappa = crate::kappa(&archive_bytes);

    // Save artifact to disk for persistence/addressability
    let artifacts_dir = std::path::Path::new("target/holo_artifacts");
    std::fs::create_dir_all(artifacts_dir)
        .map_err(|e| format!("failed to create holo_artifacts dir: {}", e))?;
    let filename = artifacts_dir.join(format!("{}_{}.holo", gate_name, kappa));
    std::fs::write(&filename, &archive_bytes)
        .map_err(|e| format!("failed to write holo artifact: {}", e))?;

    Ok(HoloExecution {
        artifact: HoloArtifact {
            gate_name: gate_name.to_string(),
            archive_bytes,
            kappa: kappa.to_string(),
            backend: "CpuBackend".to_string(),
        },
        input_kappa: crate::kappa(state_bytes).to_string(),
        output_kappa: crate::kappa(&output_bytes).to_string(),
        output_bytes,
    })
}
