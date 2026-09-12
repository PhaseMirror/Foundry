use serde::{Deserialize, Serialize};
use std::collections::HashMap;

// ------------------------------------------------------------
// Root IR document
// ------------------------------------------------------------

/// Top-level DRMM IR v1.0 document.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IrDocument {
    /// IR format version. Must be `"1.0.0"`.
    pub ir_version: String,
    /// Schema version. Must be `"1.0.0"`.
    pub schema_version: String,
    /// Semantics version (e.g., core, execution, verification).
    pub semantics_version: String,
    /// Certificate version bound to this document.
    pub certificate_version: String,
    /// Layer this document targets.
    pub layer: IrLayer,
    /// Top-level named node definitions.
    pub nodes: Vec<Expr>,
    /// Root expression of the computation graph.
    pub output: Expr,
}

/// The three official IR layers.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum IrLayer {
    Core,
    Execution,
    Verification,
}

// ------------------------------------------------------------
// Core IR nodes (10 primitives)
// ------------------------------------------------------------

/// A single expression node in the IR. Serialized as a tagged enum
/// with `"type"` discriminator in snake_case.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Expr {
    /// A literal value.
    Literal {
        /// Unique identifier matching `^[a-z]+_[0-9]{6}$`.
        id: String,
        /// The literal value.
        value: LiteralValue,
        /// Optional extensible metadata.
        #[serde(default)]
        metadata: HashMap<String, serde_json::Value>,
    },
    /// A named variable binding.
    Variable {
        /// Unique identifier.
        id: String,
        /// Variable name.
        name: String,
        #[serde(default)]
        metadata: HashMap<String, serde_json::Value>,
    },
    /// A typed tensor.
    Tensor {
        /// Unique identifier.
        id: String,
        /// Tensor rank (number of dimensions).
        rank: u32,
        /// Extent of each dimension.
        shape: Vec<u32>,
        /// Scalar element type.
        scalar_type: ScalarType,
        #[serde(default)]
        metadata: HashMap<String, serde_json::Value>,
    },
    /// A prime-indexed node (for multiplicity encoding).
    Prime {
        /// Unique identifier.
        id: String,
        /// The prime number index.
        index: u64,
        #[serde(default)]
        metadata: HashMap<String, serde_json::Value>,
    },
    /// A weighted sub-expression.
    Weight {
        /// Unique identifier.
        id: String,
        /// Scalar weight value.
        value: f64,
        /// The weighted sub-expression.
        expr: Box<Expr>,
        #[serde(default)]
        metadata: HashMap<String, serde_json::Value>,
    },
    /// An operator application.
    Operator {
        /// Unique identifier.
        id: String,
        /// Operator name (e.g., `"identity"`, `"matmul"`).
        name: String,
        /// Operator-specific parameters.
        params: HashMap<String, serde_json::Value>,
        #[serde(default)]
        metadata: HashMap<String, serde_json::Value>,
    },
    /// Sequential composition of expressions.
    Compose {
        /// Unique identifier.
        id: String,
        /// Ordered sequence of sub-expressions.
        sequence: Vec<Expr>,
        #[serde(default)]
        metadata: HashMap<String, serde_json::Value>,
    },
    /// Iterative application of an operator to an input.
    Iterate {
        /// Unique identifier.
        id: String,
        /// Iteration termination semantics.
        iterations: IterationSpec,
        /// The operator to apply each iteration.
        operator: Box<Expr>,
        /// Initial input expression.
        input: Box<Expr>,
        #[serde(default)]
        metadata: HashMap<String, serde_json::Value>,
    },
    /// Conditional branching.
    Branch {
        /// Unique identifier.
        id: String,
        /// Ordered list of condition/consequence pairs.
        conditions: Vec<Condition>,
        /// Optional default branch if no condition matches.
        default: Option<Box<Expr>>,
        #[serde(default)]
        metadata: HashMap<String, serde_json::Value>,
    },
}

// ------------------------------------------------------------
// Literal values
// ------------------------------------------------------------

/// A JSON literal value.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum LiteralValue {
    Integer(i64),
    Float(f64),
    Boolean(bool),
    String(String),
}

// ------------------------------------------------------------
// Tensor scalar type
// ------------------------------------------------------------

/// Numeric scalar type for tensor elements.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ScalarType {
    Real,
    Complex,
    Rational,
    Integer,
}

// ------------------------------------------------------------
// Iteration semantics
// ------------------------------------------------------------

/// How an iteration loop terminates.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "mode", rename_all = "snake_case")]
pub enum IterationSpec {
    /// Run for a fixed number of iterations.
    FixedCount {
        /// Exact number of iterations (must be > 0).
        count: u64,
    },
    /// Run until a convergence tolerance is met.
    UntilTolerance {
        /// Convergence threshold (must be > 0.0).
        tolerance: f64,
        /// Optional hard cap on iterations.
        max_iter: Option<u64>,
    },
}

// ------------------------------------------------------------
// Branch condition
// ------------------------------------------------------------

/// A predicate/consequence pair inside a branch.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Condition {
    /// Boolean predicate expression.
    pub predicate: Expr,
    /// Expression to evaluate when predicate is true.
    pub consequence: Expr,
}

// ------------------------------------------------------------
// Metadata helpers (for validation)
// ------------------------------------------------------------
impl Expr {
    /// Return the unique identifier of this expression node.
    pub fn id(&self) -> &str {
        match self {
            Expr::Literal { id, .. } => id,
            Expr::Variable { id, .. } => id,
            Expr::Tensor { id, .. } => id,
            Expr::Prime { id, .. } => id,
            Expr::Weight { id, .. } => id,
            Expr::Operator { id, .. } => id,
            Expr::Compose { id, .. } => id,
            Expr::Iterate { id, .. } => id,
            Expr::Branch { id, .. } => id,
        }
    }

    /// Mutable access to the metadata map of this expression node.
    pub fn metadata_mut(&mut self) -> &mut HashMap<String, serde_json::Value> {
        match self {
            Expr::Literal { metadata, .. } => metadata,
            Expr::Variable { metadata, .. } => metadata,
            Expr::Tensor { metadata, .. } => metadata,
            Expr::Prime { metadata, .. } => metadata,
            Expr::Weight { metadata, .. } => metadata,
            Expr::Operator { metadata, .. } => metadata,
            Expr::Compose { metadata, .. } => metadata,
            Expr::Iterate { metadata, .. } => metadata,
            Expr::Branch { metadata, .. } => metadata,
        }
    }
}
