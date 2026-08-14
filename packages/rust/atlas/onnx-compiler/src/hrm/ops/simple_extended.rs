//! Extended simple ONNX operators
//!
//! This module contains an extended set of simple operators generated using macros.
//! These cover most element-wise mathematical operations in the ONNX spec.

define_elementwise_ops! {
    // ============================================================================
    // Unary Mathematical Operators (1 input)
    // ============================================================================

    LogOp(x): "Natural logarithm (element-wise)" =>
        T::from_f32(x.to_f32().ln()),

    ReciprocalOp(x): "Reciprocal 1/x (element-wise)" =>
        T::one().div(x),

    SignOp(x): "Sign function (element-wise)" => {
        if x.gt(&T::zero()) {
            T::one()
        } else if x.lt(&T::zero()) {
            T::zero().sub(T::one())
        } else {
            T::zero()
        }
    },

    RoundOp(x): "Round to nearest integer (element-wise)" =>
        T::from_f32(x.to_f32().round()),

    SinOp(x): "Sine function (element-wise)" =>
        T::from_f32(x.to_f32().sin()),

    CosOp(x): "Cosine function (element-wise)" =>
        T::from_f32(x.to_f32().cos()),

    TanOp(x): "Tangent function (element-wise)" =>
        T::from_f32(x.to_f32().tan()),

    AsinOp(x): "Arcsine function (element-wise)" =>
        T::from_f32(x.to_f32().asin()),

    AcosOp(x): "Arccosine function (element-wise)" =>
        T::from_f32(x.to_f32().acos()),

    AtanOp(x): "Arctangent function (element-wise)" =>
        T::from_f32(x.to_f32().atan()),

    SinhOp(x): "Hyperbolic sine (element-wise)" =>
        T::from_f32(x.to_f32().sinh()),

    CoshOp(x): "Hyperbolic cosine (element-wise)" =>
        T::from_f32(x.to_f32().cosh()),

    AtanhOp(x): "Hyperbolic arctangent (element-wise)" =>
        T::from_f32(x.to_f32().atanh()),

    CbrtOp(x): "Cube root (element-wise)" =>
        T::from_f32(x.to_f32().cbrt()),

    ErfOp(x): "Error function (element-wise)" =>
        T::from_f32({
            let t = x.to_f32();
            let a1 = 0.254_829_6;
            let a2 = -0.284_496_72;
            let a3 = 1.421_413_8;
            let a4 = -1.453_152_1;
            let a5 = 1.061_405_4;
            let p = 0.3275911;
            let sign = if t < 0.0 { -1.0 } else { 1.0 };
            let x_abs = t.abs();
            let t_val = 1.0 / (1.0 + p * x_abs);
            let y = 1.0 - (((((a5 * t_val + a4) * t_val) + a3) * t_val + a2) * t_val + a1) * t_val * (-x_abs * x_abs).exp();
            sign * y
        }),

    Expm1Op(x): "Exponential minus 1 (element-wise)" =>
        T::from_f32(x.to_f32().exp_m1()),

    Log1pOp(x): "Natural log of 1 + x (element-wise)" =>
        T::from_f32(x.to_f32().ln_1p()),

    IsNaNOp(x): "Check if NaN (element-wise)" =>
        if x.to_f32().is_nan() { T::one() } else { T::zero() },

    IsInfOp(x): "Check if infinite (element-wise)" =>
        if x.to_f32().is_infinite() { T::one() } else { T::zero() },

    NotOp(x): "Logical NOT (element-wise)" =>
        if x == T::zero() { T::one() } else { T::zero() },

    CastOp(x): "Type conversion (pass-through in pattern compilation)" =>
        x,

    EluOp(x): "ELU activation (element-wise)" => {
        let alpha = T::from_f32(1.0);
        if x.gt(&T::zero()) {
            x
        } else {
            alpha.mul(T::from_f32(x.to_f32().exp() - 1.0))
        }
    },

    SeluOp(x): "SELU activation (element-wise)" => {
        let alpha = T::from_f32(1.67326);
        let gamma = T::from_f32(1.0507);
        if x.gt(&T::zero()) {
            gamma.mul(x)
        } else {
            gamma.mul(alpha.mul(T::from_f32(x.to_f32().exp() - 1.0)))
        }
    },

    SoftsignOp(x): "Softsign activation (element-wise)" =>
        T::from_f32({
            let x_f32 = x.to_f32();
            x_f32 / (1.0 + x_f32.abs())
        }),

    SoftplusOp(x): "Softplus activation (element-wise)" =>
        T::from_f32(x.to_f32().exp().ln_1p()),

    HardSigmoidOp(x): "HardSigmoid activation (element-wise)" =>
        T::from_f32({
            let val = 0.2 * x.to_f32() + 0.5;
            val.clamp(0.0, 1.0)
        }),

    HardSwishOp(x): "HardSwish activation (element-wise)" =>
        T::from_f32({
            let x_f32 = x.to_f32();
            let hard_sigmoid = (0.2 * x_f32 + 0.5).clamp(0.0, 1.0);
            x_f32 * hard_sigmoid
        }),

    ShrinkOp(x): "Shrink activation (element-wise)" => {
        let bias = T::from_f32(0.0);
        let lambd = T::from_f32(0.5);
        if x.lt(&T::zero().sub(lambd)) {
            x.add(bias)
        } else if x.gt(&lambd) {
            x.sub(bias)
        } else {
            T::zero()
        }
    },

    // ============================================================================
    // Binary Mathematical Operators (2 inputs)
    // ============================================================================

    MinOp(x, y): "Minimum (element-wise)" =>
        if x.lt(&y) { x } else { y },

    MaxOp(x, y): "Maximum (element-wise)" =>
        if x.gt(&y) { x } else { y },

    PowOp(x, y): "Power x^y (element-wise)" =>
        T::from_f32(x.to_f32().powf(y.to_f32())),

    ModOp(x, y): "Modulo (element-wise)" =>
        T::from_i64(x.to_i64() % y.to_i64()),

    Atan2Op(x, y): "Arctangent2 atan2(y, x) (element-wise)" =>
        T::from_f32(x.to_f32().atan2(y.to_f32())),

    AndOp(x, y): "Bitwise AND (element-wise)" =>
        T::from_i64(x.to_i64() & y.to_i64()),

    OrOp(x, y): "Bitwise OR (element-wise)" =>
        T::from_i64(x.to_i64() | y.to_i64()),

    XorOp(x, y): "Bitwise XOR (element-wise)" =>
        T::from_i64(x.to_i64() ^ y.to_i64()),

    GreaterOrEqualOp(x, y): "Greater or equal comparison (element-wise)" =>
        if x.gt(&y) || x == y { T::one() } else { T::zero() },

    LessOrEqualOp(x, y): "Less or equal comparison (element-wise)" =>
        if x.lt(&y) || x == y { T::one() } else { T::zero() },

    PReluOp(x, y): "PReLU activation (element-wise)" =>
        if x.gt(&T::zero()) { x } else { x.mul(y) },

    MeanOp(x, y): "Mean of two values (element-wise)" =>
        T::from_f32((x.to_f32() + y.to_f32()) / 2.0),
}

// Softmax requires reduction across all elements, so implement manually
use super::{OnnxHRMNode, Result};
use crate::error::CompilerError;
use crate::hrm::numeric::Numeric;
use hologram::Atlas;

/// Softmax activation function
///
/// Converts input vector to probability distribution using:
/// softmax(x_i) = exp(x_i - max(x)) / sum(exp(x_j - max(x)))
#[derive(Debug, Clone, Copy)]
pub struct SoftmaxOp;

impl<T: Numeric> OnnxHRMNode<T> for SoftmaxOp {
    fn op_type(&self) -> &'static str {
        "Softmax"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        let data = inputs[0];
        if data.is_empty() {
            return Ok(Vec::new());
        }

        // Find max for numerical stability
        let mut max_val = data[0];
        for &val in data.iter().skip(1) {
            if val.gt(&max_val) {
                max_val = val;
            }
        }

        // Compute exp(x - max) and sum
        let mut exp_vals = Vec::with_capacity(data.len());
        let mut sum = T::zero();
        for &val in data.iter() {
            let shifted = val.sub(max_val);
            let exp_val = T::from_f32(shifted.to_f32().exp());
            exp_vals.push(exp_val);
            sum = sum.add(exp_val);
        }

        // Normalize by sum
        Ok(exp_vals.iter().map(|&exp_val| exp_val.div(sum)).collect())
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() != 1 {
            return Err(CompilerError::InvalidModel(format!(
                "Softmax requires 1 input, got {}",
                inputs.len()
            )));
        }
        Ok(())
    }
}
