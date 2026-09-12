//! Macros for reducing boilerplate in ONNX operator implementation
//!
//! This module provides declarative macros that eliminate repetitive code patterns
//! when implementing ONNX operators.

/// Generate ONNX operator enum with automatic trait delegation
///
/// This macro generates:
/// 1. The `OnnxOperator<T>` enum with all operator variants
/// 2. Complete `OnnxHRMNode<T>` trait implementation with dispatching
///
/// # Benefits
///
/// - **Reduces 150+ lines to 23 lines** for operator enum
/// - **Guaranteed consistency** across all trait implementations
/// - **No forgotten match arms** - compile-time enforcement
/// - **Easy to add operators** - just one line per operator
///
/// # Example
///
/// ```text
/// define_onnx_operators! {
///     // Math operators
///     Add(AddOp),
///     Sub(SubOp),
///     Mul(MulOp),
///     Div(DivOp),
///
///     // Matrix operators
///     MatMul(MatMulOp),
///     Gemm(GemmOp),
/// }
/// ```
///
/// This generates the entire `OnnxOperator<T>` enum and all trait implementations.
#[macro_export]
macro_rules! define_onnx_operators {
    (
        $(
            $(#[$variant_meta:meta])*
            $variant:ident($op_type:ty)
        ),* $(,)?
    ) => {
        /// Central enum representing all ONNX operations
        ///
        /// This enum provides a unified type for all ONNX operations while maintaining
        /// the trait-based implementation pattern. Each variant wraps an operator that
        /// implements `OnnxHRMNode<T>`.
        ///
        /// # Categories
        ///
        /// - **Math**: Element-wise arithmetic (Add, Sub, Mul, Div)
        /// - **Matrix**: Linear algebra (MatMul, Gemm)
        /// - **Activation**: Non-linear functions (Relu, Sigmoid, Tanh)
        /// - **Tensor**: Tensor manipulation (Reshape, Concat, Slice, Gather, Unsqueeze, Flatten)
        /// - **Shape**: Shape operations (Constant, Range, Shape, ArgMax)
        /// - **Normalization**: Normalization and attention (LayerNorm, SkipLayerNorm, BiasGelu, Attention)
        ///
        /// # Example
        ///
        /// ```text
        /// use hologram_onnx_compiler::hrm::ops::{OnnxOperator, OnnxHRMNode, AddOp};
        /// use hologram::Atlas;
        ///
        /// let atlas = Atlas::with_cache()?;
        ///
        /// // Create operator through enum
        /// let op = OnnxOperator::Add(AddOp);
        ///
        /// // Execute through trait
        /// let a = vec![1.0_f32, 2.0, 3.0];
        /// let b = vec![4.0_f32, 5.0, 6.0];
        /// let result = op.execute(&atlas, &[&a, &b])?;
        ///
        /// assert_eq!(result, vec![5.0, 7.0, 9.0]);
        /// ```
        #[derive(Debug, Clone)]
        pub enum OnnxOperator<T: $crate::hrm::numeric::Numeric> {
            $(
                $(#[$variant_meta])*
                $variant($op_type),
            )*
        }

        impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for OnnxOperator<T> {
            fn op_type(&self) -> &'static str {
                match self {
                    $(
                        Self::$variant(op) => <$op_type as $crate::hrm::ops::OnnxHRMNode<T>>::op_type(op),
                    )*
                }
            }

            fn execute(&self, atlas: &hologram::Atlas, inputs: &[&[T]]) -> $crate::error::Result<Vec<T>> {
                match self {
                    $(
                        Self::$variant(op) => <$op_type as $crate::hrm::ops::OnnxHRMNode<T>>::execute(op, atlas, inputs),
                    )*
                }
            }

            fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                match self {
                    $(
                        Self::$variant(op) => <$op_type as $crate::hrm::ops::OnnxHRMNode<T>>::validate_inputs(op, inputs),
                    )*
                }
            }
        }
    };
}

/// Generate element-wise ONNX operators with flexible arity
///
/// This macro generates complete operator implementations for element-wise operations
/// with any number of inputs (1, 2, 3, ..., N). The macro automatically generates the
/// correct iteration pattern based on parameter count.
///
/// # Benefits
///
/// - **Flexible arity** - handles 1, 2, 3+ inputs without separate macros
/// - **Clean syntax** - flat list, no nested `unary {}`/`binary {}` blocks
/// - **Type-safe** - uses `Numeric` trait for all types
/// - **Zero runtime cost** - expands at compile time
///
/// # Syntax
///
/// ```text
/// define_elementwise_ops! {
///     OpName(param1, param2, ...): "Documentation" => expression,
/// }
/// ```
///
/// # Example
///
/// ```text
/// define_elementwise_ops! {
///     AbsOp(x): "Absolute value" => if x.gt(&T::zero()) { x } else { T::zero().sub(x) },
///     AddOp(x, y): "Addition" => x.add(y),
///     ClipOp(x, min, max): "Clip to range" => {
///         if x.lt(&min) { min } else if x.gt(&max) { max } else { x }
///     },
/// }
/// ```
///
/// This generates complete implementations for 1-input, 2-input, and 3-input operators.
#[macro_export]
macro_rules! define_elementwise_ops {
    // Entry point - process all operators
    (
        $(
            $name:ident($($param:ident),+): $doc:literal => $expr:expr
        ),* $(,)?
    ) => {
        $(
            $crate::_dispatch_elementwise_op! {
                $name($($param),+): $doc => $expr
            }
        )*
    };
}

/// Internal dispatcher - routes operator definition to correct arity implementation
///
/// This macro matches on parameter count and delegates to the appropriate
/// arity-specific macro. This enables support for 1-10 input operators.
#[macro_export]
#[doc(hidden)]
macro_rules! _dispatch_elementwise_op {
    // Arity 1
    ($name:ident($p0:ident): $doc:literal => $expr:expr) => {
        $crate::_impl_elementwise_op_arity1!($name, $p0, $doc, $expr);
    };
    // Arity 2
    ($name:ident($p0:ident, $p1:ident): $doc:literal => $expr:expr) => {
        $crate::_impl_elementwise_op_arity2!($name, $p0, $p1, $doc, $expr);
    };
    // Arity 3
    ($name:ident($p0:ident, $p1:ident, $p2:ident): $doc:literal => $expr:expr) => {
        $crate::_impl_elementwise_op_arity3!($name, $p0, $p1, $p2, $doc, $expr);
    };
    // Arity 4
    ($name:ident($p0:ident, $p1:ident, $p2:ident, $p3:ident): $doc:literal => $expr:expr) => {
        $crate::_impl_elementwise_op_arity4!($name, $p0, $p1, $p2, $p3, $doc, $expr);
    };
    // Arity 5
    ($name:ident($p0:ident, $p1:ident, $p2:ident, $p3:ident, $p4:ident): $doc:literal => $expr:expr) => {
        $crate::_impl_elementwise_op_arity5!($name, $p0, $p1, $p2, $p3, $p4, $doc, $expr);
    };
    // Arity 6
    ($name:ident($p0:ident, $p1:ident, $p2:ident, $p3:ident, $p4:ident, $p5:ident): $doc:literal => $expr:expr) => {
        $crate::_impl_elementwise_op_arity6!($name, $p0, $p1, $p2, $p3, $p4, $p5, $doc, $expr);
    };
    // Arity 7
    ($name:ident($p0:ident, $p1:ident, $p2:ident, $p3:ident, $p4:ident, $p5:ident, $p6:ident): $doc:literal => $expr:expr) => {
        $crate::_impl_elementwise_op_arity7!($name, $p0, $p1, $p2, $p3, $p4, $p5, $p6, $doc, $expr);
    };
    // Arity 8
    ($name:ident($p0:ident, $p1:ident, $p2:ident, $p3:ident, $p4:ident, $p5:ident, $p6:ident, $p7:ident): $doc:literal => $expr:expr) => {
        $crate::_impl_elementwise_op_arity8!(
            $name, $p0, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $doc, $expr
        );
    };
    // Arity 9
    ($name:ident($p0:ident, $p1:ident, $p2:ident, $p3:ident, $p4:ident, $p5:ident, $p6:ident, $p7:ident, $p8:ident): $doc:literal => $expr:expr) => {
        $crate::_impl_elementwise_op_arity9!(
            $name, $p0, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $doc, $expr
        );
    };
    // Arity 10
    ($name:ident($p0:ident, $p1:ident, $p2:ident, $p3:ident, $p4:ident, $p5:ident, $p6:ident, $p7:ident, $p8:ident, $p9:ident): $doc:literal => $expr:expr) => {
        $crate::_impl_elementwise_op_arity10!(
            $name, $p0, $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $doc, $expr
        );
    };
}

/// ARITY 1: Unary elementwise operator implementation
///
/// Invocation pattern: [p0], [0], 1
#[macro_export]
#[doc(hidden)]
macro_rules! _impl_elementwise_op_arity1 {
    ($name:ident, $p0:ident, $doc:literal, $expr:expr) => {
        #[doc = $doc]
        ///
        /// Element-wise operation with 1 input.
        ///
        /// # ONNX Operator
        ///
        #[doc = concat!("`", stringify!($name), "`")]
        #[derive(Debug, Clone, Copy)]
        pub struct $name;

        impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for $name {
            fn op_type(&self) -> &'static str {
                stringify!($name)
            }

            fn execute(
                &self,
                _atlas: &hologram::Atlas,
                inputs: &[&[T]],
            ) -> $crate::error::Result<Vec<T>> {
                self.validate_inputs(inputs)?;
                let len = inputs[0].len();
                Ok((0..len)
                    .map(|i| {
                        let $p0 = inputs[0][i];
                        $expr
                    })
                    .collect())
            }

            fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                if inputs.len() != 1 {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} requires 1 input, got {}",
                        stringify!($name),
                        inputs.len()
                    )));
                }
                Ok(())
            }
        }
    };
}

/// ARITY 2: Binary elementwise operator implementation
///
/// Invocation pattern: [p0, p1], [0, 1], 2
#[macro_export]
#[doc(hidden)]
macro_rules! _impl_elementwise_op_arity2 {
    ($name:ident, $p0:ident, $p1:ident, $doc:literal, $expr:expr) => {
        #[doc = $doc]
        ///
        /// Element-wise operation with 2 inputs.
        ///
        /// # ONNX Operator
        ///
        #[doc = concat!("`", stringify!($name), "`")]
        #[derive(Debug, Clone, Copy)]
        pub struct $name;

        impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for $name {
            fn op_type(&self) -> &'static str {
                stringify!($name)
            }

            fn execute(
                &self,
                _atlas: &hologram::Atlas,
                inputs: &[&[T]],
            ) -> $crate::error::Result<Vec<T>> {
                self.validate_inputs(inputs)?;

                let len0 = inputs[0].len();
                let len1 = inputs[1].len();

                // Determine output length (max of the two inputs)
                let output_len = len0.max(len1);

                // Support broadcasting:
                // - Scalar (length 1) broadcasts to any length
                // - Smaller tensor cycles for batched operations
                Ok((0..output_len)
                    .map(|i| {
                        let $p0 = if len0 == 1 {
                            inputs[0][0]
                        } else {
                            inputs[0][i % len0]
                        };
                        let $p1 = if len1 == 1 {
                            inputs[1][0]
                        } else {
                            inputs[1][i % len1]
                        };
                        $expr
                    })
                    .collect())
            }

            fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                if inputs.len() != 2 {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} requires 2 inputs, got {}",
                        stringify!($name),
                        inputs.len()
                    )));
                }
                // Support broadcasting: allow different lengths if:
                // 1. One is scalar (length 1)
                // 2. Lengths are equal
                // 3. One length is a multiple of the other (batched broadcasting)
                let len0 = inputs[0].len();
                let len1 = inputs[1].len();
                let is_compatible = len0 == len1
                    || len0 == 1
                    || len1 == 1
                    || len0 % len1 == 0
                    || len1 % len0 == 0;

                if !is_compatible {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} inputs have incompatible shapes for broadcasting: {} vs {}",
                        stringify!($name),
                        len0,
                        len1
                    )));
                }
                Ok(())
            }
        }
    };
}

/// ARITY 3: Ternary elementwise operator implementation
///
/// Invocation pattern: [p0, p1, p2], [0, 1, 2], 3
#[macro_export]
#[doc(hidden)]
macro_rules! _impl_elementwise_op_arity3 {
    ($name:ident, $p0:ident, $p1:ident, $p2:ident, $doc:literal, $expr:expr) => {
        #[doc = $doc]
        ///
        /// Element-wise operation with 3 inputs.
        ///
        /// # ONNX Operator
        ///
        #[doc = concat!("`", stringify!($name), "`")]
        #[derive(Debug, Clone, Copy)]
        pub struct $name;

        impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for $name {
            fn op_type(&self) -> &'static str {
                stringify!($name)
            }

            fn execute(
                &self,
                _atlas: &hologram::Atlas,
                inputs: &[&[T]],
            ) -> $crate::error::Result<Vec<T>> {
                self.validate_inputs(inputs)?;
                // Support broadcasting: find maximum length
                let len0 = inputs[0].len();
                let len1 = inputs[1].len();
                let len2 = inputs[2].len();
                let output_len = len0.max(len1).max(len2);

                Ok((0..output_len)
                    .map(|i| {
                        let $p0 = if len0 == 1 {
                            inputs[0][0]
                        } else {
                            inputs[0][i % len0]
                        };
                        let $p1 = if len1 == 1 {
                            inputs[1][0]
                        } else {
                            inputs[1][i % len1]
                        };
                        let $p2 = if len2 == 1 {
                            inputs[2][0]
                        } else {
                            inputs[2][i % len2]
                        };
                        $expr
                    })
                    .collect())
            }

            fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                if inputs.len() != 3 {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} requires 3 inputs, got {}",
                        stringify!($name),
                        inputs.len()
                    )));
                }
                // Support broadcasting: allow different lengths if they're compatible
                let len0 = inputs[0].len();
                let len1 = inputs[1].len();
                let len2 = inputs[2].len();
                let max_len = len0.max(len1).max(len2);

                let is_compatible = (len0 == max_len || len0 == 1 || max_len % len0 == 0)
                    && (len1 == max_len || len1 == 1 || max_len % len1 == 0)
                    && (len2 == max_len || len2 == 1 || max_len % len2 == 0);

                if !is_compatible {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} inputs have incompatible shapes for broadcasting: {} vs {} vs {}",
                        stringify!($name),
                        len0,
                        len1,
                        len2
                    )));
                }
                Ok(())
            }
        }
    };
}

/// ARITY 4: Quaternary elementwise operator implementation
///
/// Invocation pattern: [p0, p1, p2, p3], [0, 1, 2, 3], 4
#[macro_export]
#[doc(hidden)]
macro_rules! _impl_elementwise_op_arity4 {
    ($name:ident, $p0:ident, $p1:ident, $p2:ident, $p3:ident, $doc:literal, $expr:expr) => {
        #[doc = $doc]
        ///
        /// Element-wise operation with 4 inputs.
        ///
        /// # ONNX Operator
        ///
        #[doc = concat!("`", stringify!($name), "`")]
        #[derive(Debug, Clone, Copy)]
        pub struct $name;

        impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for $name {
            fn op_type(&self) -> &'static str {
                stringify!($name)
            }

            fn execute(
                &self,
                _atlas: &hologram::Atlas,
                inputs: &[&[T]],
            ) -> $crate::error::Result<Vec<T>> {
                self.validate_inputs(inputs)?;
                let len = inputs[0].len();
                Ok((0..len)
                    .map(|i| {
                        let $p0 = inputs[0][i];
                        let $p1 = inputs[1][i];
                        let $p2 = inputs[2][i];
                        let $p3 = inputs[3][i];
                        $expr
                    })
                    .collect())
            }

            fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                if inputs.len() != 4 {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} requires 4 inputs, got {}",
                        stringify!($name),
                        inputs.len()
                    )));
                }
                let len = inputs[0].len();
                if inputs[1].len() != len || inputs[2].len() != len || inputs[3].len() != len {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} inputs must have same length",
                        stringify!($name)
                    )));
                }
                Ok(())
            }
        }
    };
}

/// ARITY 5: Five-input elementwise operator implementation
///
/// Invocation pattern: [p0, p1, p2, p3, p4], [0, 1, 2, 3, 4], 5
#[macro_export]
#[doc(hidden)]
macro_rules! _impl_elementwise_op_arity5 {
    ($name:ident, $p0:ident, $p1:ident, $p2:ident, $p3:ident, $p4:ident, $doc:literal, $expr:expr) => {
        #[doc = $doc]
        ///
        /// Element-wise operation with 5 inputs.
        ///
        /// # ONNX Operator
        ///
        #[doc = concat!("`", stringify!($name), "`")]
        #[derive(Debug, Clone, Copy)]
        pub struct $name;

        impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for $name {
            fn op_type(&self) -> &'static str {
                stringify!($name)
            }

            fn execute(
                &self,
                _atlas: &hologram::Atlas,
                inputs: &[&[T]],
            ) -> $crate::error::Result<Vec<T>> {
                self.validate_inputs(inputs)?;
                let len = inputs[0].len();
                Ok((0..len)
                    .map(|i| {
                        let $p0 = inputs[0][i];
                        let $p1 = inputs[1][i];
                        let $p2 = inputs[2][i];
                        let $p3 = inputs[3][i];
                        let $p4 = inputs[4][i];
                        $expr
                    })
                    .collect())
            }

            fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                if inputs.len() != 5 {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} requires 5 inputs, got {}",
                        stringify!($name),
                        inputs.len()
                    )));
                }
                let len = inputs[0].len();
                for (idx, input) in inputs.iter().enumerate().skip(1) {
                    if input.len() != len {
                        return Err($crate::CompilerError::InvalidModel(format!(
                            "{} input {} length mismatch: expected {}, got {}",
                            stringify!($name),
                            idx,
                            len,
                            input.len()
                        )));
                    }
                }
                Ok(())
            }
        }
    };
}

/// ARITY 6: Six-input elementwise operator implementation
///
/// Invocation pattern: [p0, p1, p2, p3, p4, p5], [0, 1, 2, 3, 4, 5], 6
#[macro_export]
#[doc(hidden)]
macro_rules! _impl_elementwise_op_arity6 {
    ($name:ident, $p0:ident, $p1:ident, $p2:ident, $p3:ident, $p4:ident, $p5:ident, $doc:literal, $expr:expr) => {
        #[doc = $doc]
        ///
        /// Element-wise operation with 6 inputs.
        ///
        /// # ONNX Operator
        ///
        #[doc = concat!("`", stringify!($name), "`")]
        #[derive(Debug, Clone, Copy)]
        pub struct $name;

        impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for $name {
            fn op_type(&self) -> &'static str {
                stringify!($name)
            }

            fn execute(
                &self,
                _atlas: &hologram::Atlas,
                inputs: &[&[T]],
            ) -> $crate::error::Result<Vec<T>> {
                self.validate_inputs(inputs)?;
                let len = inputs[0].len();
                Ok((0..len)
                    .map(|i| {
                        let $p0 = inputs[0][i];
                        let $p1 = inputs[1][i];
                        let $p2 = inputs[2][i];
                        let $p3 = inputs[3][i];
                        let $p4 = inputs[4][i];
                        let $p5 = inputs[5][i];
                        $expr
                    })
                    .collect())
            }

            fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                if inputs.len() != 6 {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} requires 6 inputs, got {}",
                        stringify!($name),
                        inputs.len()
                    )));
                }
                let len = inputs[0].len();
                for (idx, input) in inputs.iter().enumerate().skip(1) {
                    if input.len() != len {
                        return Err($crate::CompilerError::InvalidModel(format!(
                            "{} input {} length mismatch: expected {}, got {}",
                            stringify!($name),
                            idx,
                            len,
                            input.len()
                        )));
                    }
                }
                Ok(())
            }
        }
    };
}

/// ARITY 7: Seven-input elementwise operator implementation
///
/// Invocation pattern: [p0, p1, p2, p3, p4, p5, p6], [0, 1, 2, 3, 4, 5, 6], 7
#[macro_export]
#[doc(hidden)]
macro_rules! _impl_elementwise_op_arity7 {
    ($name:ident, $p0:ident, $p1:ident, $p2:ident, $p3:ident, $p4:ident, $p5:ident, $p6:ident, $doc:literal, $expr:expr) => {
        #[doc = $doc]
        ///
        /// Element-wise operation with 7 inputs.
        ///
        /// # ONNX Operator
        ///
        #[doc = concat!("`", stringify!($name), "`")]
        #[derive(Debug, Clone, Copy)]
        pub struct $name;

        impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for $name {
            fn op_type(&self) -> &'static str {
                stringify!($name)
            }

            fn execute(
                &self,
                _atlas: &hologram::Atlas,
                inputs: &[&[T]],
            ) -> $crate::error::Result<Vec<T>> {
                self.validate_inputs(inputs)?;
                let len = inputs[0].len();
                Ok((0..len)
                    .map(|i| {
                        let $p0 = inputs[0][i];
                        let $p1 = inputs[1][i];
                        let $p2 = inputs[2][i];
                        let $p3 = inputs[3][i];
                        let $p4 = inputs[4][i];
                        let $p5 = inputs[5][i];
                        let $p6 = inputs[6][i];
                        $expr
                    })
                    .collect())
            }

            fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                if inputs.len() != 7 {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} requires 7 inputs, got {}",
                        stringify!($name),
                        inputs.len()
                    )));
                }
                let len = inputs[0].len();
                for (idx, input) in inputs.iter().enumerate().skip(1) {
                    if input.len() != len {
                        return Err($crate::CompilerError::InvalidModel(format!(
                            "{} input {} length mismatch: expected {}, got {}",
                            stringify!($name),
                            idx,
                            len,
                            input.len()
                        )));
                    }
                }
                Ok(())
            }
        }
    };
}

/// ARITY 8: Eight-input elementwise operator implementation
///
/// Invocation pattern: [p0, p1, p2, p3, p4, p5, p6, p7], [0, 1, 2, 3, 4, 5, 6, 7], 8
#[macro_export]
#[doc(hidden)]
macro_rules! _impl_elementwise_op_arity8 {
    ($name:ident, $p0:ident, $p1:ident, $p2:ident, $p3:ident, $p4:ident, $p5:ident, $p6:ident, $p7:ident, $doc:literal, $expr:expr) => {
        #[doc = $doc]
        ///
        /// Element-wise operation with 8 inputs.
        ///
        /// # ONNX Operator
        ///
        #[doc = concat!("`", stringify!($name), "`")]
        #[derive(Debug, Clone, Copy)]
        pub struct $name;

        impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for $name {
            fn op_type(&self) -> &'static str {
                stringify!($name)
            }

            fn execute(
                &self,
                _atlas: &hologram::Atlas,
                inputs: &[&[T]],
            ) -> $crate::error::Result<Vec<T>> {
                self.validate_inputs(inputs)?;
                let len = inputs[0].len();
                Ok((0..len)
                    .map(|i| {
                        let $p0 = inputs[0][i];
                        let $p1 = inputs[1][i];
                        let $p2 = inputs[2][i];
                        let $p3 = inputs[3][i];
                        let $p4 = inputs[4][i];
                        let $p5 = inputs[5][i];
                        let $p6 = inputs[6][i];
                        let $p7 = inputs[7][i];
                        $expr
                    })
                    .collect())
            }

            fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                if inputs.len() != 8 {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} requires 8 inputs, got {}",
                        stringify!($name),
                        inputs.len()
                    )));
                }
                let len = inputs[0].len();
                for (idx, input) in inputs.iter().enumerate().skip(1) {
                    if input.len() != len {
                        return Err($crate::CompilerError::InvalidModel(format!(
                            "{} input {} length mismatch: expected {}, got {}",
                            stringify!($name),
                            idx,
                            len,
                            input.len()
                        )));
                    }
                }
                Ok(())
            }
        }
    };
}

/// ARITY 9: Nine-input elementwise operator implementation
///
/// Invocation pattern: [p0, p1, p2, p3, p4, p5, p6, p7, p8], [0, 1, 2, 3, 4, 5, 6, 7, 8], 9
#[macro_export]
#[doc(hidden)]
macro_rules! _impl_elementwise_op_arity9 {
    ($name:ident, $p0:ident, $p1:ident, $p2:ident, $p3:ident, $p4:ident, $p5:ident, $p6:ident, $p7:ident, $p8:ident, $doc:literal, $expr:expr) => {
        #[doc = $doc]
        ///
        /// Element-wise operation with 9 inputs.
        ///
        /// # ONNX Operator
        ///
        #[doc = concat!("`", stringify!($name), "`")]
        #[derive(Debug, Clone, Copy)]
        pub struct $name;

        impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for $name {
            fn op_type(&self) -> &'static str {
                stringify!($name)
            }

            fn execute(
                &self,
                _atlas: &hologram::Atlas,
                inputs: &[&[T]],
            ) -> $crate::error::Result<Vec<T>> {
                self.validate_inputs(inputs)?;
                let len = inputs[0].len();
                Ok((0..len)
                    .map(|i| {
                        let $p0 = inputs[0][i];
                        let $p1 = inputs[1][i];
                        let $p2 = inputs[2][i];
                        let $p3 = inputs[3][i];
                        let $p4 = inputs[4][i];
                        let $p5 = inputs[5][i];
                        let $p6 = inputs[6][i];
                        let $p7 = inputs[7][i];
                        let $p8 = inputs[8][i];
                        $expr
                    })
                    .collect())
            }

            fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                if inputs.len() != 9 {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} requires 9 inputs, got {}",
                        stringify!($name),
                        inputs.len()
                    )));
                }
                let len = inputs[0].len();
                for (idx, input) in inputs.iter().enumerate().skip(1) {
                    if input.len() != len {
                        return Err($crate::CompilerError::InvalidModel(format!(
                            "{} input {} length mismatch: expected {}, got {}",
                            stringify!($name),
                            idx,
                            len,
                            input.len()
                        )));
                    }
                }
                Ok(())
            }
        }
    };
}

/// ARITY 10: Ten-input elementwise operator implementation
///
/// Invocation pattern: [p0, p1, p2, p3, p4, p5, p6, p7, p8, p9], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 10
#[macro_export]
#[doc(hidden)]
macro_rules! _impl_elementwise_op_arity10 {
    ($name:ident, $p0:ident, $p1:ident, $p2:ident, $p3:ident, $p4:ident, $p5:ident, $p6:ident, $p7:ident, $p8:ident, $p9:ident, $doc:literal, $expr:expr) => {
        #[doc = $doc]
        ///
        /// Element-wise operation with 10 inputs.
        ///
        /// # ONNX Operator
        ///
        #[doc = concat!("`", stringify!($name), "`")]
        #[derive(Debug, Clone, Copy)]
        pub struct $name;

        impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for $name {
            fn op_type(&self) -> &'static str {
                stringify!($name)
            }

            fn execute(
                &self,
                _atlas: &hologram::Atlas,
                inputs: &[&[T]],
            ) -> $crate::error::Result<Vec<T>> {
                self.validate_inputs(inputs)?;
                let len = inputs[0].len();
                Ok((0..len)
                    .map(|i| {
                        let $p0 = inputs[0][i];
                        let $p1 = inputs[1][i];
                        let $p2 = inputs[2][i];
                        let $p3 = inputs[3][i];
                        let $p4 = inputs[4][i];
                        let $p5 = inputs[5][i];
                        let $p6 = inputs[6][i];
                        let $p7 = inputs[7][i];
                        let $p8 = inputs[8][i];
                        let $p9 = inputs[9][i];
                        $expr
                    })
                    .collect())
            }

            fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                if inputs.len() != 10 {
                    return Err($crate::CompilerError::InvalidModel(format!(
                        "{} requires 10 inputs, got {}",
                        stringify!($name),
                        inputs.len()
                    )));
                }
                let len = inputs[0].len();
                for (idx, input) in inputs.iter().enumerate().skip(1) {
                    if input.len() != len {
                        return Err($crate::CompilerError::InvalidModel(format!(
                            "{} input {} length mismatch: expected {}, got {}",
                            stringify!($name),
                            idx,
                            len,
                            input.len()
                        )));
                    }
                }
                Ok(())
            }
        }
    };
}

// =============================================================================
// Helper Macros for Stateful Operations
// =============================================================================

/// Validate input count for operations
///
/// Generates a standard error if the number of inputs doesn't match expected count.
///
/// # Example
///
/// ```text
/// validate_input_count!(inputs, 2, "MatMul");
/// ```
#[macro_export]
macro_rules! validate_input_count {
    ($inputs:expr, $expected:expr, $op_name:expr) => {
        if $inputs.len() != $expected {
            return Err($crate::CompilerError::InvalidModel(format!(
                "{} requires {} input{}, got {}",
                $op_name,
                $expected,
                if $expected == 1 { "" } else { "s" },
                $inputs.len()
            )));
        }
    };
}

/// Validate input count is within a range
///
/// Generates a standard error if the number of inputs is outside the valid range.
///
/// # Example
///
/// ```text
/// validate_input_count_range!(inputs, 2, 3, "Gemm");
/// ```
#[macro_export]
macro_rules! validate_input_count_range {
    ($inputs:expr, $min:expr, $max:expr, $op_name:expr) => {
        if $inputs.len() < $min || $inputs.len() > $max {
            return Err($crate::CompilerError::InvalidModel(format!(
                "{} requires {}-{} inputs, got {}",
                $op_name,
                $min,
                $max,
                $inputs.len()
            )));
        }
    };
}

/// Validate tensor size matches expected size
///
/// Generates a standard error if tensor size doesn't match.
///
/// # Example
///
/// ```text
/// validate_input_size!(inputs[0], self.m * self.k, "MatMul input A");
/// ```
#[macro_export]
macro_rules! validate_input_size {
    ($input:expr, $expected_size:expr, $name:expr) => {
        if $input.len() != $expected_size {
            return Err($crate::CompilerError::InvalidModel(format!(
                "{} has wrong size: expected {}, got {}",
                $name,
                $expected_size,
                $input.len()
            )));
        }
    };
}

/// Validate shape has minimum rank
///
/// Generates a standard error if shape doesn't have enough dimensions.
///
/// # Example
///
/// ```text
/// validate_shape_rank!(input_shapes[0], 2, "MatMul");
/// ```
#[macro_export]
macro_rules! validate_shape_rank {
    ($shape:expr, $min_rank:expr, $op_name:expr) => {
        if $shape.len() < $min_rank {
            return Err($crate::CompilerError::InvalidModel(format!(
                "{} requires {}D+ input, got shape {:?}",
                $op_name, $min_rank, $shape
            )));
        }
    };
}

/// Extract 2D dimensions from shape (last 2 dimensions)
///
/// Returns (rows, cols) from shape like [batch, rows, cols].
///
/// # Example
///
/// ```text
/// let (m, k) = extract_2d_dims!(input_shapes[0], "MatMul input A")?;
/// ```
#[macro_export]
macro_rules! extract_2d_dims {
    ($shape:expr, $name:expr) => {{
        if $shape.len() < 2 {
            return Err($crate::CompilerError::InvalidModel(format!(
                "{} requires 2D+ tensor, got shape {:?}",
                $name, $shape
            )));
        }
        let rows = $shape[$shape.len() - 2] as usize;
        let cols = $shape[$shape.len() - 1] as usize;
        (rows, cols)
    }};
}

/// Validate two inputs have same length
///
/// Generates a standard error if inputs have different lengths.
///
/// # Example
///
/// ```text
/// validate_same_length!(inputs[0], inputs[1], "SkipLayerNorm", "input", "skip");
/// ```
#[macro_export]
macro_rules! validate_same_length {
    ($input1:expr, $input2:expr, $op_name:expr, $name1:expr, $name2:expr) => {
        if $input1.len() != $input2.len() {
            return Err($crate::CompilerError::InvalidModel(format!(
                "{} {} and {} must have same length: {} vs {}",
                $op_name,
                $name1,
                $name2,
                $input1.len(),
                $input2.len()
            )));
        }
    };
}

// Re-export helper macros for convenience
pub use validate_input_count;
pub use validate_input_count_range;
pub use validate_input_size;
pub use validate_same_length;
pub use validate_shape_rank;

// =============================================================================
// Reduction and Accumulation Macros
// =============================================================================

/// Generate reduction ONNX operators from declarative definitions
///
/// This macro generates complete operator implementations for reduction operations
/// that aggregate values across all elements (e.g., sum, mean, max, min).
///
/// # Benefits
///
/// - **Handles all reduction patterns** - sum, mean, product, max, min, etc.
/// - **Type-safe accumulation** - proper initialization and aggregation
/// - **Consistent validation** - standard error handling
/// - **Zero runtime cost** - expands at compile time
///
/// # Example
///
/// ```text
/// define_reduction_ops! {
///     ReduceSumOp: "Sum of all elements" => {
///         init: T::zero(),
///         accumulate: |acc, val| acc.add(val),
///     },
///     ReduceMaxOp: "Maximum of all elements" => {
///         init: T::from_f32(f32::NEG_INFINITY),
///         accumulate: |acc, val| if val.gt(&acc) { val } else { acc },
///     },
/// }
/// ```
#[macro_export]
macro_rules! define_reduction_ops {
    (
        $(
            $name:ident: $doc:literal => {
                init: $init_expr:expr,
                accumulate: $acc_expr:expr $(,)?
            }
        ),* $(,)?
    ) => {
        $(
            #[doc = $doc]
            ///
            /// Reduction operation (all elements).
            ///
            /// # ONNX Operator
            ///
            #[doc = concat!("`", stringify!($name), "`")]
            #[derive(Debug, Clone, Copy)]
            pub struct $name;

            impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for $name {
                fn op_type(&self) -> &'static str {
                    stringify!($name)
                }

                fn execute(&self, _atlas: &hologram::Atlas, inputs: &[&[T]]) -> $crate::error::Result<Vec<T>> {
                    self.validate_inputs(inputs)?;

                    let mut acc = $init_expr;
                    let accumulate = $acc_expr;

                    for &val in inputs[0].iter() {
                        acc = accumulate(acc, val);
                    }

                    // Return single-element vector with result
                    Ok(vec![acc])
                }

                fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                    if inputs.len() != 1 {
                        return Err($crate::CompilerError::InvalidModel(format!(
                            "{} requires 1 input, got {}",
                            stringify!($name),
                            inputs.len()
                        )));
                    }
                    if inputs[0].is_empty() {
                        return Err($crate::CompilerError::InvalidModel(
                            format!("{} requires non-empty input", stringify!($name))
                        ));
                    }
                    Ok(())
                }
            }
        )*
    };
}

/// Generate accumulation ONNX operators from declarative definitions
///
/// This macro generates operators that perform cumulative operations
/// (e.g., cumulative sum, cumulative product).
///
/// # Example
///
/// ```text
/// define_accumulation_ops! {
///     CumSumOp: "Cumulative sum" => {
///         init: T::zero(),
///         accumulate: |acc, val| acc.add(val),
///     },
/// }
/// ```
#[macro_export]
macro_rules! define_accumulation_ops {
    (
        $(
            $name:ident: $doc:literal => {
                init: $init_expr:expr,
                accumulate: $acc_expr:expr $(,)?
            }
        ),* $(,)?
    ) => {
        $(
            #[doc = $doc]
            ///
            /// Accumulation operation (running total).
            ///
            /// # ONNX Operator
            ///
            #[doc = concat!("`", stringify!($name), "`")]
            #[derive(Debug, Clone, Copy)]
            pub struct $name;

            impl<T: $crate::hrm::numeric::Numeric> $crate::hrm::ops::OnnxHRMNode<T> for $name {
                fn op_type(&self) -> &'static str {
                    stringify!($name)
                }

                fn execute(&self, _atlas: &hologram::Atlas, inputs: &[&[T]]) -> $crate::error::Result<Vec<T>> {
                    self.validate_inputs(inputs)?;

                    let mut acc = $init_expr;
                    let accumulate = $acc_expr;
                    let mut result = Vec::with_capacity(inputs[0].len());

                    for &val in inputs[0].iter() {
                        acc = accumulate(acc, val);
                        result.push(acc);
                    }

                    Ok(result)
                }

                fn validate_inputs(&self, inputs: &[&[T]]) -> $crate::error::Result<()> {
                    if inputs.len() != 1 {
                        return Err($crate::CompilerError::InvalidModel(format!(
                            "{} requires 1 input, got {}",
                            stringify!($name),
                            inputs.len()
                        )));
                    }
                    Ok(())
                }
            }
        )*
    };
}

// Re-export for convenience
pub use define_accumulation_ops;
pub use define_elementwise_ops;
pub use define_onnx_operators;
pub use define_reduction_ops;
