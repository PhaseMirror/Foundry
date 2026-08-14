//! ONNX Operations for MoonshineHRM Pre-Computation
//!
//! This module defines the `OnnxHRMNode` trait and implementations for ONNX operations
//! that execute during Pass 3 pre-computation in embedded Griess algebra space.
//!
//! ## Overview
//!
//! Each ONNX operation (Add, MatMul, Conv2d, etc.) implements the `OnnxHRMNode` trait
//! to define how it computes results from embedded inputs during pre-computation.
//!
//! ## Execution Flow
//!
//! During Pass 3:
//! 1. Input patterns are embedded into 196,884-dimensional Griess algebra space
//! 2. Operations execute via `OnnxHRMNode::execute()` in embedded space
//! 3. Results are stored in the address space for O(1) runtime lookup
//!
//! ## Example
//!
//! ```
//! use hologram_onnx_compiler::hrm::ops::{OnnxHRMNode, AddOp};
//! use hologram::Atlas;
//!
//! # fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let atlas = Atlas::with_cache()?;
//! let add_op = AddOp;
//!
//! // Embed inputs (during Pass 3)
//! let input_a = vec![1.0, 2.0, 3.0];
//! let input_b = vec![4.0, 5.0, 6.0];
//!
//! // Execute operation in embedded space
//! let result = add_op.execute(&atlas, &[&input_a, &input_b])?;
//!
//! // Result is stored in address space for O(1) lookup at runtime
//! assert_eq!(result.len(), 3);
//! # Ok(())
//! # }
//! ```

use crate::error::Result;
use crate::hrm::numeric::Numeric;
use hologram::Atlas;

#[macro_use]
pub mod macros;
pub mod generated;
pub mod matrix;
pub mod normalization;
pub mod onnx_ops;
pub mod reductions;
pub mod shape;
pub mod simple_extended;
pub mod tensor;

// Re-exports for convenience
pub use generated::*;
// Matrix operators with N-D support
pub use matrix::{GemmOp, MatMulOp};
pub use normalization::*;
// Only export new multi-input operators from onnx_ops (to avoid conflicts)
pub use onnx_ops::{
    ClipOp, MulOp10, MulOp4, MulOp5, MulOp6, MulOp7, MulOp8, MulOp9, SumOp10, SumOp4, SumOp5,
    SumOp6, SumOp7, SumOp8, SumOp9, WhereOp,
};
pub use reductions::*;
// Export all shape operations from shape module
pub use shape::{ArgMaxOp, ConstantOp, ExpandOp, RangeOp, ShapeOp, SqueezeOp, TransposeOp};
pub use simple_extended::*;
pub use tensor::*;

// Use macro to generate operator enum and trait implementation
// This reduces 150+ lines of boilerplate to just 23 lines!
crate::define_onnx_operators! {
    // Math operators (4)
    Add(AddOp),
    Sub(SubOp),
    Mul(MulOp),
    Div(DivOp),

    // Matrix operators (2)
    MatMul(MatMulOp),
    Gemm(GemmOp),

    // Activation operators (4)
    Relu(ReluOp),
    Sigmoid(SigmoidOp),
    Tanh(TanhOp),
    Softmax(SoftmaxOp),

    // Simple operators - unary (37)
    Abs(AbsOp),
    Neg(NegOp),
    Sqrt(SqrtOp),
    Exp(ExpOp),
    Ceil(CeilOp),
    Floor(FloorOp),
    LeakyRelu(LeakyReluOp),
    Log(LogOp),
    Reciprocal(ReciprocalOp),
    Sign(SignOp),
    Round(RoundOp),
    Sin(SinOp),
    Cos(CosOp),
    Tan(TanOp),
    Asin(AsinOp),
    Acos(AcosOp),
    Atan(AtanOp),
    Sinh(SinhOp),
    Cosh(CoshOp),
    Atanh(AtanhOp),
    Cbrt(CbrtOp),
    Erf(ErfOp),
    Expm1(Expm1Op),
    Log1p(Log1pOp),
    IsNaN(IsNaNOp),
    IsInf(IsInfOp),
    Not(NotOp),
    Elu(EluOp),
    Selu(SeluOp),
    Softsign(SoftsignOp),
    Softplus(SoftplusOp),
    HardSigmoid(HardSigmoidOp),
    HardSwish(HardSwishOp),
    Shrink(ShrinkOp),
    Cast(CastOp),

    // Simple operators - binary (15)
    Equal(EqualOp),
    Greater(GreaterOp),
    Less(LessOp),
    Min(MinOp),
    Max(MaxOp),
    Pow(PowOp),
    Mod(ModOp),
    Atan2(Atan2Op),
    And(AndOp),
    Or(OrOp),
    Xor(XorOp),
    GreaterOrEqual(GreaterOrEqualOp),
    LessOrEqual(LessOrEqualOp),
    PRelu(PReluOp),
    Mean(MeanOp),

    // Reduction operators (4)
    ReduceSum(ReduceSumOp),
    ReduceProd(ReduceProdOp),
    ReduceMax(ReduceMaxOp),
    ReduceMin(ReduceMinOp),

    // Accumulation operators (2)
    CumSum(CumSumOp),
    CumProd(CumProdOp),

    // Tensor operators (6)
    Reshape(ReshapeOp),
    Concat(ConcatOp),
    Slice(SliceOp),
    Gather(GatherOp),
    Unsqueeze(UnsqueezeOp),
    Flatten(FlattenOp),

    // Shape operators (7)
    Constant(ConstantOp<T>),
    Range(RangeOp),
    Shape(ShapeOp),
    ArgMax(ArgMaxOp),
    Transpose(TransposeOp),
    Squeeze(SqueezeOp),
    Expand(ExpandOp),

    // Normalization operators (4)
    LayerNormalization(LayerNormalizationOp),
    SkipLayerNormalization(SkipLayerNormalizationOp),
    BiasGelu(BiasGeluOp),
    Attention(AttentionOp),

    // Multi-input operators from onnx_ops (2)
    Where(WhereOp),
    Clip(ClipOp),
}

// Separate impl for f32-specific construction from node metadata
impl OnnxOperator<f32> {
    /// Construct an operator from ONNX node metadata
    ///
    /// This is the proper construction pattern - operators know how to build themselves
    /// from ONNX metadata, rather than having construction logic in the compiler.
    ///
    /// # Arguments
    ///
    /// * `op_type` - ONNX operator type string (e.g., "MatMul", "Add")
    /// * `input_shapes` - Input tensor shapes from the ONNX graph
    /// * `pattern_len` - Length of the input pattern (for operators that need it)
    ///
    /// # Returns
    ///
    /// Fully constructed operator ready for execution
    pub fn from_node_metadata(
        op_type: &str,
        input_shapes: &[Vec<i64>],
        pattern_len: usize,
    ) -> Result<Self> {
        match op_type {
            // Simple operators - no shape dependencies
            "Add" => Ok(OnnxOperator::Add(AddOp)),
            "Sub" => Ok(OnnxOperator::Sub(SubOp)),
            "Mul" => Ok(OnnxOperator::Mul(MulOp)),
            "Div" => Ok(OnnxOperator::Div(DivOp)),
            "Relu" => Ok(OnnxOperator::Relu(ReluOp)),
            "Sigmoid" => Ok(OnnxOperator::Sigmoid(SigmoidOp)),
            "Tanh" => Ok(OnnxOperator::Tanh(TanhOp)),
            "Softmax" => Ok(OnnxOperator::Softmax(SoftmaxOp)),

            // Generated unary operators
            "Abs" => Ok(OnnxOperator::Abs(AbsOp)),
            "Neg" => Ok(OnnxOperator::Neg(NegOp)),
            "Sqrt" => Ok(OnnxOperator::Sqrt(SqrtOp)),
            "Exp" => Ok(OnnxOperator::Exp(ExpOp)),
            "Ceil" => Ok(OnnxOperator::Ceil(CeilOp)),
            "Floor" => Ok(OnnxOperator::Floor(FloorOp)),
            "LeakyRelu" => Ok(OnnxOperator::LeakyRelu(LeakyReluOp)),
            "Log" => Ok(OnnxOperator::Log(LogOp)),
            "Reciprocal" => Ok(OnnxOperator::Reciprocal(ReciprocalOp)),
            "Sign" => Ok(OnnxOperator::Sign(SignOp)),
            "Round" => Ok(OnnxOperator::Round(RoundOp)),
            "Sin" => Ok(OnnxOperator::Sin(SinOp)),
            "Cos" => Ok(OnnxOperator::Cos(CosOp)),
            "Tan" => Ok(OnnxOperator::Tan(TanOp)),
            "Asin" => Ok(OnnxOperator::Asin(AsinOp)),
            "Acos" => Ok(OnnxOperator::Acos(AcosOp)),
            "Atan" => Ok(OnnxOperator::Atan(AtanOp)),
            "Sinh" => Ok(OnnxOperator::Sinh(SinhOp)),
            "Cosh" => Ok(OnnxOperator::Cosh(CoshOp)),
            "Atanh" => Ok(OnnxOperator::Atanh(AtanhOp)),
            "Cbrt" => Ok(OnnxOperator::Cbrt(CbrtOp)),
            "Erf" => Ok(OnnxOperator::Erf(ErfOp)),
            "Expm1" => Ok(OnnxOperator::Expm1(Expm1Op)),
            "Log1p" => Ok(OnnxOperator::Log1p(Log1pOp)),
            "IsNaN" => Ok(OnnxOperator::IsNaN(IsNaNOp)),
            "IsInf" => Ok(OnnxOperator::IsInf(IsInfOp)),
            "Not" => Ok(OnnxOperator::Not(NotOp)),
            "Elu" => Ok(OnnxOperator::Elu(EluOp)),
            "Selu" => Ok(OnnxOperator::Selu(SeluOp)),
            "Softsign" => Ok(OnnxOperator::Softsign(SoftsignOp)),
            "Softplus" => Ok(OnnxOperator::Softplus(SoftplusOp)),
            "HardSigmoid" => Ok(OnnxOperator::HardSigmoid(HardSigmoidOp)),
            "HardSwish" => Ok(OnnxOperator::HardSwish(HardSwishOp)),
            "Shrink" => Ok(OnnxOperator::Shrink(ShrinkOp)),
            "Cast" => Ok(OnnxOperator::Cast(CastOp)),

            // Generated binary operators
            "Equal" => Ok(OnnxOperator::Equal(EqualOp)),
            "Greater" => Ok(OnnxOperator::Greater(GreaterOp)),
            "Less" => Ok(OnnxOperator::Less(LessOp)),
            "Min" => Ok(OnnxOperator::Min(MinOp)),
            "Max" => Ok(OnnxOperator::Max(MaxOp)),
            "Pow" => Ok(OnnxOperator::Pow(PowOp)),
            "Mod" => Ok(OnnxOperator::Mod(ModOp)),
            "Atan2" => Ok(OnnxOperator::Atan2(Atan2Op)),
            "And" => Ok(OnnxOperator::And(AndOp)),
            "Or" => Ok(OnnxOperator::Or(OrOp)),
            "Xor" => Ok(OnnxOperator::Xor(XorOp)),
            "GreaterOrEqual" => Ok(OnnxOperator::GreaterOrEqual(GreaterOrEqualOp)),
            "LessOrEqual" => Ok(OnnxOperator::LessOrEqual(LessOrEqualOp)),
            "PRelu" => Ok(OnnxOperator::PRelu(PReluOp)),
            "Mean" => Ok(OnnxOperator::Mean(MeanOp)),

            // Reduction operators
            "ReduceSum" => Ok(OnnxOperator::ReduceSum(ReduceSumOp)),
            "ReduceProd" => Ok(OnnxOperator::ReduceProd(ReduceProdOp)),
            "ReduceMax" => Ok(OnnxOperator::ReduceMax(ReduceMaxOp)),
            "ReduceMin" => Ok(OnnxOperator::ReduceMin(ReduceMinOp)),

            // Accumulation operators
            "CumSum" => Ok(OnnxOperator::CumSum(CumSumOp)),
            "CumProd" => Ok(OnnxOperator::CumProd(CumProdOp)),

            // Shape operators
            "Reshape" => Ok(OnnxOperator::Reshape(ReshapeOp)),
            "Range" => Ok(OnnxOperator::Range(RangeOp)),

            // Matrix operators - extract dimensions from shapes
            "MatMul" => MatMulOp::from_shapes(input_shapes).map(OnnxOperator::MatMul),
            "Gemm" => GemmOp::from_shapes(input_shapes).map(OnnxOperator::Gemm),

            // Normalization operators
            "LayerNormalization" => LayerNormalizationOp::from_shapes(input_shapes)
                .map(OnnxOperator::LayerNormalization),
            "SkipLayerNormalization" => Ok(OnnxOperator::SkipLayerNormalization(
                SkipLayerNormalizationOp::new(1e-5),
            )),
            "BiasGelu" => Ok(OnnxOperator::BiasGelu(BiasGeluOp)),
            "Attention" => AttentionOp::from_shapes(input_shapes).map(OnnxOperator::Attention),

            // Tensor manipulation
            "Flatten" => Ok(OnnxOperator::Flatten(FlattenOp::new(1))),
            "Unsqueeze" => Ok(OnnxOperator::Unsqueeze(UnsqueezeOp::new(vec![0]))),
            "Gather" => Ok(OnnxOperator::Gather(GatherOp::new(0))),
            "Slice" => Ok(OnnxOperator::Slice(SliceOp::new(
                vec![0],
                vec![pattern_len as i64],
                vec![1],
            ))),
            "Concat" => Ok(OnnxOperator::Concat(ConcatOp::new(0))),
            "ArgMax" => Ok(OnnxOperator::ArgMax(ArgMaxOp::new(0, false))),
            "Squeeze" => Ok(OnnxOperator::Squeeze(SqueezeOp::new(
                vec![pattern_len],
                None,
            ))),
            "Transpose" => Ok(OnnxOperator::Transpose(TransposeOp::new(
                vec![pattern_len],
                None,
            ))),

            // Shape/Constant operators
            "Constant" => Ok(OnnxOperator::Constant(ConstantOp::new(vec![]))),
            "Shape" => Ok(OnnxOperator::Shape(ShapeOp::new(vec![pattern_len as i64]))),

            // Multi-input operators
            "Where" => Ok(OnnxOperator::Where(WhereOp)),
            "Clip" => Ok(OnnxOperator::Clip(ClipOp)),
            "Expand" => Ok(OnnxOperator::Expand(ExpandOp::new(vec![pattern_len]))),

            _ => Err(crate::CompilerError::UnsupportedOp(format!(
                "Unknown ONNX operator: {}",
                op_type
            ))),
        }
    }
}

/// Trait for ONNX operation nodes in MoonshineHRM pre-computation
///
/// Implementations define how operations execute in embedded Griess algebra space
/// during Pass 3 pre-computation. Results are stored in the address space for
/// O(1) runtime lookup.
///
/// # Type Parameters
///
/// Operations are generic over `T: Numeric`, supporting all ONNX numeric types:
/// - Floating-point: f32, f64, f16, bf16
/// - Signed integers: i8, i16, i32, i64
/// - Unsigned integers: u8, u16, u32, u64
///
/// # Methods
///
/// - `op_type()`: Returns the ONNX operation type name (e.g., "Add", "MatMul")
/// - `execute()`: Executes the operation on embedded inputs
/// - `validate_inputs()`: Validates input shapes and types
///
/// # Example
///
/// ```
/// use hologram_onnx_compiler::hrm::ops::OnnxHRMNode;
/// use hologram_onnx_compiler::hrm::numeric::Numeric;
/// use hologram::Atlas;
///
/// struct CustomOp;
///
/// impl<T: Numeric> OnnxHRMNode<T> for CustomOp {
///     fn op_type(&self) -> &'static str {
///         "CustomOp"
///     }
///
///     fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>, hologram_onnx_compiler::CompilerError> {
///         // Custom operation logic
///         Ok(inputs[0].to_vec())
///     }
///
///     fn validate_inputs(&self, inputs: &[&[T]]) -> Result<(), hologram_onnx_compiler::CompilerError> {
///         if inputs.len() != 1 {
///             return Err(hologram_onnx_compiler::CompilerError::InvalidModel(
///                 "CustomOp requires exactly 1 input".to_string()
///             ));
///         }
///         Ok(())
///     }
/// }
/// ```
pub trait OnnxHRMNode<T: Numeric>: Send + Sync {
    /// Return the ONNX operation type name
    ///
    /// This should match the ONNX specification (e.g., "Add", "MatMul", "Conv").
    fn op_type(&self) -> &'static str;

    /// Execute the operation on embedded inputs
    ///
    /// This is called during Pass 3 pre-computation. Inputs are already embedded
    /// in Griess algebra space. The operation computes results that will be
    /// stored in the address space for O(1) runtime lookup.
    ///
    /// # Type Parameters
    ///
    /// * `T` - Numeric type (f32, f64, i32, i64, f16, bf16, etc.)
    ///
    /// # Arguments
    ///
    /// * `atlas` - The Griess algebra Atlas for embedding operations
    /// * `inputs` - Embedded input tensors (flattened to 1D)
    ///
    /// # Returns
    ///
    /// The computed output tensor (flattened to 1D)
    ///
    /// # Errors
    ///
    /// Returns `Err` if:
    /// - Input validation fails
    /// - Embedding operations fail
    /// - Computation encounters errors
    fn execute(&self, atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>>;

    /// Validate input tensors
    ///
    /// Checks that inputs have correct shapes and types for this operation.
    /// Called before `execute()` to catch errors early.
    ///
    /// # Arguments
    ///
    /// * `inputs` - Input tensors to validate
    ///
    /// # Errors
    ///
    /// Returns `Err` if inputs are invalid (wrong count, wrong shapes, etc.)
    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()>;
}
