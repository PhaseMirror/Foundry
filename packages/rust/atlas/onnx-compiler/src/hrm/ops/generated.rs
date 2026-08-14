//! Auto-generated ONNX operators
//!
//! This module defines simple ONNX operators using the `define_elementwise_ops!` macro.
//! Operators are defined declaratively - just specify the computation expression.
//!
//! # Adding New Operators
//!
//! To add a new element-wise operator:
//!
//! 1. Add it to the list below with the appropriate number of parameters
//! 2. Provide a doc string and computation expression
//! 3. Add it to the `define_onnx_operators!` macro in `mod.rs`
//! 4. Add it to `from_node_metadata()` in `mod.rs`
//!
//! # Example
//!
//! ```text
//! define_elementwise_ops! {
//!     // Unary operator (1 input)
//!     MyUnaryOp(x): "My custom unary operation" =>
//!         T::from_f32(x.to_f32().my_func()),
//!
//!     // Binary operator (2 inputs)
//!     MyBinaryOp(x, y): "My custom binary operation" =>
//!         x.add(y).mul(T::from_f32(2.0)),
//!
//!     // Ternary operator (3 inputs)
//!     MyTernaryOp(x, y, z): "My custom ternary operation" =>
//!         x.add(y).add(z),
//! }
//! ```

// Generate all element-wise operators from declarative definitions
define_elementwise_ops! {
    // Unary operators (1 input)
    AbsOp(x): "Absolute value (element-wise)" =>
        if x.gt(&T::zero()) { x } else { T::zero().sub(x) },

    NegOp(x): "Negation (element-wise)" =>
        T::zero().sub(x),

    SqrtOp(x): "Square root (element-wise)" =>
        T::from_f32(x.to_f32().sqrt()),

    ExpOp(x): "Exponential function (element-wise)" =>
        T::from_f32(x.to_f32().exp()),

    CeilOp(x): "Ceiling function (element-wise)" =>
        T::from_f32(x.to_f32().ceil()),

    FloorOp(x): "Floor function (element-wise)" =>
        T::from_f32(x.to_f32().floor()),

    LeakyReluOp(x): "Leaky ReLU activation (element-wise)" => {
        let alpha = T::from_f32(0.01);
        if x.gt(&T::zero()) {
            x
        } else {
            x.mul(alpha)
        }
    },

    ReluOp(x): "ReLU activation (element-wise)" =>
        if x.gt(&T::zero()) { x } else { T::zero() },

    SigmoidOp(x): "Sigmoid activation (element-wise)" =>
        T::from_f32({
            let x_f32 = x.to_f32();
            1.0 / (1.0 + (-x_f32).exp())
        }),

    TanhOp(x): "Tanh activation (element-wise)" =>
        T::from_f32(x.to_f32().tanh()),

    // Binary operators (2 inputs)
    AddOp(x, y): "Addition (element-wise)" =>
        x.add(y),

    SubOp(x, y): "Subtraction (element-wise)" =>
        x.sub(y),

    MulOp(x, y): "Multiplication (element-wise)" =>
        x.mul(y),

    DivOp(x, y): "Division (element-wise)" =>
        x.div(y),

    EqualOp(x, y): "Equality comparison (element-wise)" =>
        if x == y { T::one() } else { T::zero() },

    GreaterOp(x, y): "Greater-than comparison (element-wise)" =>
        if x.gt(&y) { T::one() } else { T::zero() },

    LessOp(x, y): "Less-than comparison (element-wise)" =>
        if x.lt(&y) { T::one() } else { T::zero() },
}
