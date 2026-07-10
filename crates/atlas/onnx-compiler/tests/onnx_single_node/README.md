# ONNX Single-Node Operator Tests

This directory contains comprehensive unit tests for individual ONNX operators implemented in the HRM (Hologram Runtime Model) execution layer.

## Overview

These tests validate that each ONNX operator works correctly in isolation by:

- Testing basic functionality with simple, deterministic inputs
- Testing edge cases (zeros, negatives, boundaries, special values)
- Testing various tensor shapes and dimensions
- Verifying mathematical properties and invariants

## Test Structure

### Infrastructure (`mod.rs`)

Provides test utilities and helpers:

**Data Generation:**
- `zeros(size)` - Generate tensor filled with zeros
- `ones(size)` - Generate tensor filled with ones
- `range(start, count)` - Generate sequential values
- `identity_matrix(n)` - Generate n×n identity matrix

**Validation:**
- `assert_tensors_equal(actual, expected, tolerance)` - Compare tensors within tolerance
- `assert_shape_equal(actual, expected)` - Verify tensor shapes match
- `assert_all_finite(tensor)` - Verify no NaN/Inf values
- `assert_sum_equals(tensor, expected, tolerance)` - Verify tensor sum

**ONNX Graph Builder:**
- `OnnxGraphBuilder` - Programmatic ONNX graph construction (for reference)

### Test Files

Each operator category has its own test file:

| File | Operators | Tests |
|------|-----------|-------|
| `test_math.rs` | Add, Sub, Mul, Div | 16 |
| `test_matrix.rs` | MatMul, Gemm | 8 |
| `test_activation.rs` | Relu, Sigmoid, Tanh | 12 |
| `test_tensor_manipulation.rs` | Reshape, Concat, Slice, Gather, Unsqueeze, Flatten | 25 |
| `test_utility.rs` | Constant, Range, Shape, ArgMax | 20 |
| `test_normalization.rs` | LayerNormalization, SkipLayerNormalization, BiasGelu, Attention | 21 |
| **Total** | **23 operators** | **102 tests** |

## Test Pattern

Each operator follows a consistent 4-test pattern:

### 1. Basic Functionality Test

Simple deterministic case with known input/output:

```rust
#[test]
fn test_add_basic() {
    let atlas = Atlas::with_cache().unwrap();
    let add_op = AddOp;

    let a = vec![1.0, 2.0, 3.0];
    let b = vec![4.0, 5.0, 6.0];
    let expected = vec![5.0, 7.0, 9.0];

    let result = add_op.execute(&atlas, &[&a, &b]).unwrap();
    assert_tensors_equal(&result, &expected, 1e-6);
}
```

### 2. Edge Cases Test

Boundary conditions and special values:

```rust
#[test]
fn test_add_edge_cases() {
    let atlas = Atlas::with_cache().unwrap();
    let add_op = AddOp;

    let test_cases = vec![
        // Zeros
        (vec![0.0, 0.0], vec![1.0, 2.0], vec![1.0, 2.0]),
        // Negatives
        (vec![-1.0, -2.0], vec![1.0, 2.0], vec![0.0, 0.0]),
        // Large values
        (vec![1e6, 1e7], vec![1e6, 1e7], vec![2e6, 2e7]),
    ];

    for (a, b, expected) in test_cases {
        let result = add_op.execute(&atlas, &[&a, &b]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-3);
    }
}
```

### 3. Various Shapes Test

Different tensor dimensions and sizes:

```rust
#[test]
fn test_add_various_shapes() {
    let atlas = Atlas::with_cache().unwrap();
    let add_op = AddOp;

    for size in [2, 5, 10, 100].iter() {
        let a: Vec<f32> = (0..*size).map(|i| i as f32).collect();
        let b: Vec<f32> = (0..*size).map(|i| (i * 2) as f32).collect();
        let expected: Vec<f32> = (0..*size).map(|i| (i * 3) as f32).collect();

        let result = add_op.execute(&atlas, &[&a, &b]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }
}
```

### 4. Properties/Invariants Test

Mathematical properties and correctness checks:

```rust
#[test]
fn test_add_properties() {
    let atlas = Atlas::with_cache().unwrap();
    let add_op = AddOp;

    let a = vec![1.0, 2.0, 3.0];
    let b = vec![4.0, 5.0, 6.0];

    // Commutative: a + b == b + a
    let result_ab = add_op.execute(&atlas, &[&a, &b]).unwrap();
    let result_ba = add_op.execute(&atlas, &[&b, &a]).unwrap();
    assert_tensors_equal(&result_ab, &result_ba, 1e-6);

    // Identity: a + 0 == a
    let zero = vec![0.0, 0.0, 0.0];
    let result_identity = add_op.execute(&atlas, &[&a, &zero]).unwrap();
    assert_tensors_equal(&result_identity, &a, 1e-6);
}
```

## Running Tests

Run all single-node tests:

```bash
cargo test --test onnx_single_node_suite
```

Run specific operator category:

```bash
cargo test --test onnx_single_node_suite test_math
cargo test --test onnx_single_node_suite test_activation
```

Run individual test:

```bash
cargo test --test onnx_single_node_suite test_add_basic
```

## Code Generation Macros

**NEW**: The ONNX compiler now includes macros to reduce boilerplate significantly.

### Operator Dispatch Macro

The `define_onnx_operators!` macro in [hologram-onnx-compiler/src/hrm/ops/macros.rs](../../../src/hrm/ops/macros.rs) generates the operator enum and trait implementations:

**Reduces 150+ lines to 37 lines (80% reduction)**

```rust
define_onnx_operators! {
    Add(AddOp),
    Sub(SubOp),
    Mul(MulOp),
    // ... 20 more operators
}
```

This automatically generates:
- `OnnxOperator<T>` enum with all variants
- Complete `OnnxHRMNode<T>` trait implementation with proper dispatching
- All three trait methods: `op_type()`, `execute()`, `validate_inputs()`

**Benefits:**
- Adding new operator requires just one line
- Guaranteed consistency across implementations
- No risk of forgetting match arms
- Compile-time enforcement

### Test Generation Macros

Test infrastructure includes macros to reduce test boilerplate by ~40%.

See [MACRO_EXAMPLES.md](MACRO_EXAMPLES.md) for detailed usage examples and patterns.

**Available test macros:**
- `setup_test!` - Setup Atlas and operator (reduces 2 lines to 1)
- `execute_op!` - Execute operator with cleaner syntax
- `test_operator_basic!` - Generate complete basic test (reduces ~45% boilerplate)
- `test_operator_edge_cases!` - Generate edge cases test (reduces ~25% boilerplate)
- `test_operator_module!` - Generate test module structure

**Example:**
```rust
// Before: 11 lines of boilerplate
#[test]
fn test_add_basic() {
    let atlas = Atlas::with_cache().unwrap();
    let op = AddOp;
    let a = vec![1.0, 2.0];
    let b = vec![3.0, 4.0];
    let expected = vec![4.0, 6.0];
    let result = op.execute(&atlas, &[&a, &b]).unwrap();
    assert_tensors_equal(&result, &expected, 1e-6);
}

// After: 6 lines using macros
test_operator_basic! {
    test_add_basic,
    AddOp,
    inputs: [vec![1.0, 2.0], vec![3.0, 4.0]],
    expected: vec![4.0, 6.0],
    tolerance: 1e-6
}
```

## Adding New Operator Tests

To add tests for a new ONNX operator:

### 1. Determine the Category

- **Math**: Arithmetic operations (Add, Sub, Mul, Div, etc.)
- **Matrix**: Linear algebra (MatMul, Gemm, etc.)
- **Activation**: Non-linear functions (Relu, Sigmoid, Tanh, etc.)
- **Tensor**: Shape manipulation (Reshape, Concat, Slice, etc.)
- **Utility**: Shape operations (Constant, Range, Shape, ArgMax, etc.)
- **Normalization**: Normalization and attention (LayerNorm, Attention, etc.)

### 2. Add Tests to Appropriate File

Add a new test module to the appropriate `test_*.rs` file:

```rust
#[cfg(test)]
mod test_my_operator {
    use super::*;

    #[test]
    fn test_my_operator_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let my_op = MyOperatorOp::new(/* params */);

        let input = vec![/* test data */];
        let expected = vec![/* expected result */];

        let result = my_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    // Add edge_cases, various_shapes, and properties tests...
}
```

### 3. Follow the 4-Test Pattern

Implement all 4 test types:
- `test_my_operator_basic()` - Simple deterministic case
- `test_my_operator_edge_cases()` - Boundary conditions
- `test_my_operator_various_shapes()` - Different dimensions
- `test_my_operator_properties()` - Mathematical properties

### 4. Register New File (if needed)

If creating a new test file, register it in `onnx_single_node_suite.rs`:

```rust
#[path = "onnx_single_node/test_my_category.rs"]
mod test_my_category;
```

## Test Guidelines

### Input Data
- Use simple, deterministic values (e.g., 1.0, 2.0, 3.0)
- Test edge cases: zeros, negatives, large values, boundaries
- Use known mathematical values (e.g., sigmoid(0) = 0.5)

### Tolerances
- Use `1e-6` for most floating-point comparisons
- Use `1e-3` or `1e-5` for operations with larger numerical error
- Document why a specific tolerance is used if non-standard

### Properties to Test
- **Commutativity**: a + b == b + a
- **Associativity**: (a + b) + c == a + (b + c)
- **Identity**: a + 0 == a, a * 1 == a
- **Inverse**: a - a == 0, a / a == 1
- **Idempotence**: f(f(x)) == f(x)
- **Symmetry**: f(-x) relation to f(x)
- **Range bounds**: Output within valid range

## Implementation Status

**Fully Tested Operators (23):**

✅ Math (4): Add, Sub, Mul, Div
✅ Matrix (2): MatMul, Gemm
✅ Activation (3): Relu, Sigmoid, Tanh
✅ Tensor (6): Reshape, Concat, Slice, Gather, Unsqueeze, Flatten
✅ Utility (4): Constant, Range, Shape, ArgMax
✅ Normalization (4): LayerNormalization, SkipLayerNormalization, BiasGelu, Attention

**Total Coverage:**
- 23 operators tested
- 102 unit tests
- 8 infrastructure tests
- **110 tests total**

## Related Documentation

- [/docs/onnx/IMPLEMENTATION_SPEC.md](../../../../docs/onnx/IMPLEMENTATION_SPEC.md) - Full ONNX implementation specification
- [ONNX Specification](https://onnx.ai/onnx/operators/) - Official ONNX operator reference

## Philosophy

These tests follow the principle of **testing operators in isolation** to enable:

1. **Precise Bug Identification** - When a test fails, you know exactly which operator is broken
2. **Fast Iteration** - Tests run in seconds, not minutes
3. **Clear Contracts** - Each test documents expected behavior
4. **Regression Prevention** - Catch bugs before they reach production models

Rather than debugging a 100+ node production graph, we test each operator individually with deterministic inputs and known outputs.
