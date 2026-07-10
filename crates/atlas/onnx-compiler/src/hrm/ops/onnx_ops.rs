//! Advanced ONNX Operators (Multi-Input Support)
//!
//! This module defines ONNX operators that require 3+ inputs using the macro system.
//! Supports operators with 3-10 inputs using the flexible arity macro dispatcher.
//!
//! # New Operators
//!
//! - **Where** (3 inputs): Conditional selection
//! - **Clip** (3 inputs): Clamp values between min/max
//! - **SumN** (4-10 inputs): Sum of N values
//! - **MulN** (4-10 inputs): Product of N values
//!
//! # Design
//!
//! All operators defined using `define_elementwise_ops!` macro with automatic:
//! - Struct definition
//! - OnnxHRMNode trait implementation
//! - execute() method with Atlas integration
//! - Broadcasting support
//!
//! Note: Operators with 1-2 inputs are defined in `generated.rs` and `simple_extended.rs`.

define_elementwise_ops! {
    // ============================================================================
    // TERNARY OPERATORS (3 inputs)
    // ============================================================================

    WhereOp(condition, x, y): "Select: x if condition != 0 else y" =>
        if condition != T::zero() { x } else { y },

    ClipOp(x, min_val, max_val): "Clip: clamp x between min and max" => {
        if x.lt(&min_val) {
            min_val
        } else if x.gt(&max_val) {
            max_val
        } else {
            x
        }
    },

    // ============================================================================
    // QUATERNARY+ OPERATORS (4-10 inputs)
    // ============================================================================

    SumOp4(a, b, c, d): "Sum of 4 values" =>
        a.add(b).add(c).add(d),

    SumOp5(a, b, c, d, e): "Sum of 5 values" =>
        a.add(b).add(c).add(d).add(e),

    SumOp6(a, b, c, d, e, f): "Sum of 6 values" =>
        a.add(b).add(c).add(d).add(e).add(f),

    SumOp7(a, b, c, d, e, f, g): "Sum of 7 values" =>
        a.add(b).add(c).add(d).add(e).add(f).add(g),

    SumOp8(a, b, c, d, e, f, g, h): "Sum of 8 values" =>
        a.add(b).add(c).add(d).add(e).add(f).add(g).add(h),

    SumOp9(a, b, c, d, e, f, g, h, i): "Sum of 9 values" =>
        a.add(b).add(c).add(d).add(e).add(f).add(g).add(h).add(i),

    SumOp10(a, b, c, d, e, f, g, h, i, j): "Sum of 10 values" =>
        a.add(b).add(c).add(d).add(e).add(f).add(g).add(h).add(i).add(j),

    MulOp4(a, b, c, d): "Product of 4 values" =>
        a.mul(b).mul(c).mul(d),

    MulOp5(a, b, c, d, e): "Product of 5 values" =>
        a.mul(b).mul(c).mul(d).mul(e),

    MulOp6(a, b, c, d, e, f): "Product of 6 values" =>
        a.mul(b).mul(c).mul(d).mul(e).mul(f),

    MulOp7(a, b, c, d, e, f, g): "Product of 7 values" =>
        a.mul(b).mul(c).mul(d).mul(e).mul(f).mul(g),

    MulOp8(a, b, c, d, e, f, g, h): "Product of 8 values" =>
        a.mul(b).mul(c).mul(d).mul(e).mul(f).mul(g).mul(h),

    MulOp9(a, b, c, d, e, f, g, h, i): "Product of 9 values" =>
        a.mul(b).mul(c).mul(d).mul(e).mul(f).mul(g).mul(h).mul(i),

    MulOp10(a, b, c, d, e, f, g, h, i, j): "Product of 10 values" =>
        a.mul(b).mul(c).mul(d).mul(e).mul(f).mul(g).mul(h).mul(i).mul(j),
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::hrm::numeric::Numeric;
    use crate::hrm::ops::OnnxHRMNode;
    use hologram::Atlas;

    #[test]
    fn test_ternary_where() {
        let atlas = Atlas::with_cache().unwrap();
        let where_op = WhereOp;
        let result = where_op
            .execute(&atlas, &[&[1.0_f32, 0.0, 1.0], &[10.0, 20.0, 30.0], &[100.0, 200.0, 300.0]])
            .unwrap();
        assert_eq!(result, vec![10.0, 200.0, 30.0]);
    }

    #[test]
    fn test_ternary_clip() {
        let atlas = Atlas::with_cache().unwrap();
        let clip = ClipOp;
        let result = clip
            .execute(&atlas, &[&[0.5_f32, 1.5, 2.5], &[1.0, 1.0, 1.0], &[2.0, 2.0, 2.0]])
            .unwrap();
        assert_eq!(result, vec![1.0, 1.5, 2.0]);
    }

    #[test]
    fn test_sum_4_inputs() {
        let atlas = Atlas::with_cache().unwrap();
        let sum4 = SumOp4;
        let result = sum4
            .execute(&atlas, &[&[1.0_f32], &[2.0], &[3.0], &[4.0]])
            .unwrap();
        assert_eq!(result, vec![10.0]);
    }

    #[test]
    fn test_mul_5_inputs() {
        let atlas = Atlas::with_cache().unwrap();
        let mul5 = MulOp5;
        let result = mul5
            .execute(&atlas, &[&[2.0_f32], &[3.0], &[4.0], &[5.0], &[1.0]])
            .unwrap();
        assert_eq!(result, vec![120.0]);
    }
}
