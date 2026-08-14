# Test Macro Usage Examples

This file demonstrates how to use the test generation macros to reduce boilerplate in ONNX operator tests.

**See also:**
- [README.md](README.md) - Complete testing methodology and infrastructure guide
- [/docs/hologram-onnx-compiler/MACROS.md](../../../../docs/hologram-onnx-compiler/MACROS.md) - Macro system documentation

## Available Macros

1. **`setup_test!`** - Setup Atlas and operator
2. **`execute_op!`** - Execute operator with inputs
3. **`test_operator_basic!`** - Generate basic test function
4. **`test_operator_edge_cases!`** - Generate edge cases test function
5. **`test_operator_module!`** - Generate complete test module

## Example 1: Using `setup_test!` Macro

### Before (Manual Setup)

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

### After (Using Macro)

```rust
#[test]
fn test_add_basic() {
    setup_test!(AddOp => atlas, op);

    let a = vec![1.0, 2.0, 3.0];
    let b = vec![4.0, 5.0, 6.0];
    let expected = vec![5.0, 7.0, 9.0];

    let result = execute_op!(atlas, op, [&a, &b]);
    assert_tensors_equal(&result, &expected, 1e-6);
}
```

**Boilerplate Reduced**: 2 lines → 1 line (50% reduction for setup)

## Example 2: Using `test_operator_basic!` Macro

### Before (Full Manual Test)

```rust
#[test]
fn test_mul_basic() {
    let atlas = Atlas::with_cache().unwrap();
    let mul_op = MulOp;

    let a = vec![2.0, 3.0, 4.0];
    let b = vec![5.0, 6.0, 7.0];
    let expected = vec![10.0, 18.0, 28.0];

    let result = mul_op.execute(&atlas, &[&a, &b]).unwrap();
    assert_tensors_equal(&result, &expected, 1e-6);
}
```

### After (Using Macro)

```rust
test_operator_basic! {
    test_mul_basic,
    MulOp,
    inputs: [vec![2.0, 3.0, 4.0], vec![5.0, 6.0, 7.0]],
    expected: vec![10.0, 18.0, 28.0],
    tolerance: 1e-6
}
```

**Boilerplate Reduced**: 11 lines → 6 lines (45% reduction)

## Example 3: Using `test_operator_edge_cases!` Macro

### Before (Manual Edge Cases)

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

### After (Using Macro)

```rust
test_operator_edge_cases! {
    test_add_edge_cases,
    AddOp,
    test_cases: [
        // Zeros
        (vec![0.0, 0.0], vec![1.0, 2.0], vec![1.0, 2.0]),
        // Negatives
        (vec![-1.0, -2.0], vec![1.0, 2.0], vec![0.0, 0.0]),
        // Large values
        (vec![1e6, 1e7], vec![1e6, 1e7], vec![2e6, 2e7]),
    ],
    tolerance: 1e-3
}
```

**Boilerplate Reduced**: 16 lines → 12 lines (25% reduction)

## Example 4: Operators with Custom Initialization

For operators that require constructor parameters:

### Using `setup_test!` with custom initialization

```rust
#[test]
fn test_layer_norm_basic() {
    setup_test!(LayerNormalizationOp::new(1e-5, -1) => atlas, op);

    let input = vec![1.0, 2.0, 3.0, 4.0];
    let result = execute_op!(atlas, op, [&input]);

    // Assertions...
}
```

### Using `test_operator_basic!` with custom operator

```rust
test_operator_basic! {
    test_layer_norm_basic,
    LayerNormalizationOp::new(1e-5, -1),
    inputs: [vec![1.0, 2.0, 3.0, 4.0]],
    expected: vec![...],
    tolerance: 1e-5
}
```

## Example 5: Complete Test Module with Macro

### Before (Full Manual Module)

```rust
#[cfg(test)]
mod test_custom_op {
    use super::*;
    use hologram::Atlas;
    use hologram_onnx_compiler::hrm::ops::{CustomOp, OnnxHRMNode};

    #[test]
    fn test_custom_basic() {
        // Test implementation
    }

    #[test]
    fn test_custom_properties() {
        // Test implementation
    }
}
```

### After (Using Macro)

```rust
test_operator_module! {
    test_custom_op,
    CustomOp,
    {
        #[test]
        fn test_custom_basic() {
            // Test implementation - imports already available
        }

        #[test]
        fn test_custom_properties() {
            // Test implementation
        }
    }
}
```

## Boilerplate Reduction Summary

| Test Pattern | Before (lines) | After (lines) | Reduction |
|-------------|----------------|---------------|-----------|
| Basic test setup | 2 | 1 | 50% |
| Complete basic test | 11 | 6 | 45% |
| Edge cases test | 16 | 12 | 25% |
| Test module structure | 8 | 5 | 37% |
| **Average** | - | - | **~40%** |

## When to Use Each Macro

### Use `setup_test!` when:
- You need custom test logic beyond basic execution
- Testing mathematical properties or complex scenarios
- Multiple operations in one test

### Use `test_operator_basic!` when:
- Simple input → output test with known values
- Creating comprehensive test suites quickly
- Standardizing test structure

### Use `test_operator_edge_cases!` when:
- Testing multiple edge cases with same pattern
- Boundary conditions, zeros, negatives, large values
- Similar assertion logic for all cases

### Use `execute_op!` when:
- You have manual setup but want cleaner execution
- Multiple execute calls in one test
- Mixing with custom Atlas/operator setup

## Recommendations for New Tests

1. **Start with macros** - Use `test_operator_basic!` and `test_operator_edge_cases!` for initial test structure
2. **Fall back to manual** - Use manual tests for complex property verification or unique test logic
3. **Mix approaches** - Use `setup_test!` and `execute_op!` to reduce boilerplate while maintaining flexibility

## Future Operator Tests

When implementing new ONNX operators, use these macros to:
- **Reduce initial boilerplate by ~40%**
- **Standardize test structure** across all operators
- **Focus on test cases** rather than setup code
- **Maintain consistency** with existing tests
