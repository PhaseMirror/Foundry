//! Reduction and accumulation ONNX operators
//!
//! This module defines reduction operators using the `define_reduction_ops!` macro
//! and accumulation operators using the `define_accumulation_ops!` macro.
//!
//! # Reduction Operators
//!
//! Reduce all elements to a single value (e.g., sum, mean, max, min).
//!
//! # Accumulation Operators
//!
//! Compute running totals (e.g., cumulative sum, cumulative product).

// ============================================================================
// Reduction Operators
// ============================================================================

define_reduction_ops! {
    ReduceSumOp: "Computes sum of all input elements" => {
        init: T::zero(),
        accumulate: |acc: T, val: T| acc.add(val),
    },

    ReduceProdOp: "Computes product of all input elements" => {
        init: T::one(),
        accumulate: |acc: T, val: T| acc.mul(val),
    },

    ReduceMaxOp: "Computes maximum of all input elements" => {
        init: T::from_f32(f32::NEG_INFINITY),
        accumulate: |acc: T, val: T| if val.gt(&acc) { val } else { acc },
    },

    ReduceMinOp: "Computes minimum of all input elements" => {
        init: T::from_f32(f32::INFINITY),
        accumulate: |acc: T, val: T| if val.lt(&acc) { val } else { acc },
    },
}

// ============================================================================
// Accumulation Operators
// ============================================================================

define_accumulation_ops! {
    CumSumOp: "Computes cumulative sum (running total)" => {
        init: T::zero(),
        accumulate: |acc: T, val: T| acc.add(val),
    },

    CumProdOp: "Computes cumulative product (running product)" => {
        init: T::one(),
        accumulate: |acc: T, val: T| acc.mul(val),
    },
}
