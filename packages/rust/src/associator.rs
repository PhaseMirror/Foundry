use super::partial_system::{GateOperation, HardwareSpec};

pub fn associator_defect<const N: usize>(
    x: &GateOperation,
    y: &GateOperation,
    z: &GateOperation,
    hw: &HardwareSpec,
) -> f64 {
    let compose = |a: &GateOperation, b: &GateOperation| -> Vec<GateOperation> {
        let mut result = vec![a.clone()];
        result.extend(b.active_qubits().iter().map(|&q| {
            GateOperation::SingleQubitGate {
                qubit: q,
                angle: 0.0,
                axis: super::partial_system::Axis::X,
            }
        }));
        result
    };

    let xy = compose(x, y);
    let yz = compose(y, z);

    let mut xy_z_ops = Vec::new();
    for op in &xy {
        xy_z_ops.push(op.clone());
    }
    xy_z_ops.push(z.clone());

    let mut x_yz_ops = vec![x.clone()];
    x_yz_ops.extend(yz.iter().cloned());

    let cost_xy_z = hw.associator_defect(&xy_z_ops, &[]);
    let cost_x_yz = hw.associator_defect(&x_yz_ops, &[]);

    let cost_x = hw.associator_defect(&[x.clone()], &[]);
    let _cost_y = hw.associator_defect(&[y.clone()], &[]);
    let cost_z = hw.associator_defect(&[z.clone()], &[]);
    let cost_xy = hw.associator_defect(&xy, &[]);
    let cost_yz = hw.associator_defect(&yz, &[]);

    let left_path = cost_xy_z + cost_xy + cost_z;
    let right_path = cost_x_yz + cost_x + cost_yz;

    (left_path - right_path).abs()
}

pub fn binary_residual(
    x: &GateOperation,
    y: &GateOperation,
    hw: &HardwareSpec,
) -> f64 {
    let mut min_delta = f64::INFINITY;
    let qubits = x.active_qubits().into_iter()
        .chain(y.active_qubits())
        .collect::<Vec<_>>();

    for &z_qubit in &qubits {
        let z = GateOperation::SingleQubitGate {
            qubit: z_qubit,
            angle: 0.0,
            axis: super::partial_system::Axis::X,
        };
        let delta = associator_defect::<8>(x, y, &z, hw);
        if delta < min_delta {
            min_delta = delta;
        }
    }

    min_delta
}
