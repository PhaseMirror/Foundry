//! StableHLO to P²C PETC v1.2 Lowering Pass
//!
//! Provides lowering functions mapping MLIR / StableHLO operations
//! (`dot_general`, `reshape`, `transpose`, `all_reduce`) directly into
//! verified P²C witness bytecode streams with meet-semilattice validation.

use crate::witness_bytecode::*;
use std::collections::HashMap;

/// Context holding mesh axis identifiers and lowering configurations
#[derive(Debug, Clone)]
pub struct StableHloLoweringContext {
    pub mesh_dims: HashMap<String, u32>,
}

impl StableHloLoweringContext {
    pub fn new(mesh_dims: HashMap<String, u32>) -> Self {
        Self { mesh_dims }
    }

    /// Lower a `stablehlo.dot_general` contraction
    pub fn lower_dot_general(
        &self,
        lhs_axes: &[DecoratedSignature],
        rhs_axes: &[DecoratedSignature],
        contracting_dims: (usize, usize),
    ) -> Result<(Vec<DecoratedSignature>, WitnessOp), WitnessError> {
        let (l_idx, r_idx) = contracting_dims;
        if l_idx >= lhs_axes.len() || r_idx >= rhs_axes.len() {
            return Err(WitnessError::IndexOutOfBounds {
                index: l_idx.max(r_idx),
                size: lhs_axes.len().max(rhs_axes.len()),
            });
        }

        // Assert signature match along contracted dimensions
        if lhs_axes[l_idx].atom_exponents != rhs_axes[r_idx].atom_exponents {
            return Err(WitnessError::ContractionMismatch {
                left: l_idx,
                right: r_idx,
                details: format!(
                    "Contraction signature mismatch: {:?} != {:?}",
                    lhs_axes[l_idx].atom_exponents, rhs_axes[r_idx].atom_exponents
                ),
            });
        }

        // Build output axes: LHS remaining axes + RHS remaining axes
        let mut out_axes = Vec::new();
        for (i, ax) in lhs_axes.iter().enumerate() {
            if i != l_idx {
                out_axes.push(ax.clone());
            }
        }
        for (j, ax) in rhs_axes.iter().enumerate() {
            if j != r_idx {
                out_axes.push(ax.clone());
            }
        }

        let op = WitnessOp::MultiContract {
            pairs: vec![(l_idx as u32, (lhs_axes.len() + r_idx) as u32)],
        };

        Ok((out_axes, op))
    }

    /// Lower a `stablehlo.transpose` axis permutation
    pub fn lower_transpose(
        &self,
        src_axes: &[DecoratedSignature],
        permutation: &[usize],
    ) -> Result<(Vec<DecoratedSignature>, WitnessOp), WitnessError> {
        if permutation.len() != src_axes.len() {
            return Err(WitnessError::RankMismatch {
                expected: permutation.len(),
                actual: src_axes.len(),
            });
        }

        let mut out_axes = Vec::with_capacity(src_axes.len());
        let mut perm_u32 = Vec::with_capacity(permutation.len());
        for &p in permutation {
            if p >= src_axes.len() {
                return Err(WitnessError::InvalidPermutationIndex {
                    index: p as u32,
                    rank: src_axes.len(),
                });
            }
            out_axes.push(src_axes[p].clone());
            perm_u32.push(p as u32);
        }

        let op = WitnessOp::Permute {
            rank: src_axes.len() as u32,
            perm: perm_u32,
        };

        Ok((out_axes, op))
    }

    /// Lower a `stablehlo.all_reduce` or collective operation
    pub fn lower_collective(
        &self,
        src_axes: &[DecoratedSignature],
        kind: CollectiveKind,
        mesh_axis: u32,
    ) -> Result<(Vec<DecoratedSignature>, WitnessOp), WitnessError> {
        let mut out_axes = src_axes.to_vec();
        match kind {
            CollectiveKind::AllReduceSum | CollectiveKind::AllReduceMax | CollectiveKind::AllGather => {
                for ax in &mut out_axes {
                    ax.partition.apply_allreduce(mesh_axis);
                }
            }
            _ => {}
        }

        let op = WitnessOp::Collective {
            kind,
            mesh_axis,
        };

        Ok((out_axes, op))
    }

    /// Lower a factorized `stablehlo.reshape` split
    pub fn lower_reshape(
        &self,
        src_axes: &[DecoratedSignature],
        src_idx: usize,
        parts: &[DecoratedSignature],
    ) -> Result<(Vec<DecoratedSignature>, WitnessOp), WitnessError> {
        if src_idx >= src_axes.len() {
            return Err(WitnessError::IndexOutOfBounds {
                index: src_idx,
                size: src_axes.len(),
            });
        }

        let mut out_axes = Vec::new();
        for (i, ax) in src_axes.iter().enumerate() {
            if i == src_idx {
                out_axes.extend_from_slice(parts);
            } else {
                out_axes.push(ax.clone());
            }
        }

        let op = WitnessOp::Split {
            src_axis: src_idx as u32,
            parts: parts.to_vec(),
        };

        Ok((out_axes, op))
    }
}
