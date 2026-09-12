# Hologram ONNX Compiler

ONNX model compiler for the Hologram Runtime Model (HRM) execution layer.

## Overview

This compiler translates ONNX models to HRM execution format, enabling neural network inference through Hologram's canonical computation system.

**Current Status:** 23/282 ONNX operators implemented (8% coverage), 110 tests passing

## Documentation

### For Developers

- **[tests/onnx_single_node/README.md](tests/onnx_single_node/README.md)** - Complete testing methodology, operator testing patterns, and macro usage guide
- **[docs/onnx/IMPLEMENTATION_SPEC.md](../../../docs/onnx/IMPLEMENTATION_SPEC.md)** - Full ONNX operator implementation specification and roadmap
- **[/docs/hologram-onnx-compiler/MACROS.md](../../../docs/hologram-onnx-compiler/MACROS.md)** - Complete macro system documentation

### Implementation Resources

- **Operator dispatch macro:** [src/hrm/ops/macros.rs](src/hrm/ops/macros.rs) - Reduces operator enum boilerplate by 80%
- **Test generation macros:** [tests/onnx_single_node/mod.rs](tests/onnx_single_node/mod.rs) - Reduces test boilerplate by ~40%
- **Macro examples:** [tests/onnx_single_node/MACRO_EXAMPLES.md](tests/onnx_single_node/MACRO_EXAMPLES.md) - Usage patterns and examples

## Architecture

```
ONNX Model (.onnx)
       ↓
   [Parser]
       ↓
   ONNX Graph
       ↓
  [HRM Compiler]
       ↓
 HRM Execution Plan
       ↓
  [Atlas Runtime]
       ↓
  Inference Results
```

## Implemented Operators

### Math (4)
Add, Sub, Mul, Div

### Matrix (2)
MatMul, Gemm

### Activation (3)
Relu, Sigmoid, Tanh

### Tensor Manipulation (6)
Reshape, Concat, Slice, Gather, Unsqueeze, Flatten

### Utility (4)
Constant, Range, Shape, ArgMax

### Normalization (4)
LayerNormalization, SkipLayerNormalization, BiasGelu, Attention

## Testing

Run all single-node operator tests:

```bash
cargo test --test onnx_single_node_suite
# Result: 110 tests passing (102 operator + 8 infrastructure)
```

Run specific category:

```bash
cargo test --test onnx_single_node_suite test_math
cargo test --test onnx_single_node_suite test_activation
```

See [tests/onnx_single_node/README.md](tests/onnx_single_node/README.md) for complete testing methodology.

## Adding New Operators

Follow the five-step workflow documented in [IMPLEMENTATION_SPEC.md](../../../docs/onnx/IMPLEMENTATION_SPEC.md):

1. Create Atlas schema (`schemas/onnx/{category}/{op}.py`)
2. Implement HRM execution (`src/hrm/ops/{category}.rs`)
3. Write single-node tests (using macros)
4. Add to composition matrix
5. Validate with full test suite

**Quick start with macros:**

```rust
// 1. Add to operator enum (1 line)
define_onnx_operators! {
    // ... existing operators ...
    NewOp(NewOpImpl),  // ← Add new operator
}

// 2. Generate test with macro (6 lines)
test_operator_basic! {
    test_new_op_basic,
    NewOpImpl::new(),
    inputs: [vec![1.0, 2.0], vec![3.0, 4.0]],
    expected: vec![4.0, 6.0],
    tolerance: 1e-6
}
```

## Macro System

The compiler uses Rust macros to reduce boilerplate:

### Operator Dispatch Macro
- **Reduces:** 150+ lines → 37 lines (80% reduction)
- **Usage:** All 23 operators use this macro
- **File:** [src/hrm/ops/macros.rs](src/hrm/ops/macros.rs)

### Test Generation Macros
- **Reduces:** ~40% test boilerplate
- **Available:** 5 macros for different test patterns
- **Files:** [tests/onnx_single_node/mod.rs](tests/onnx_single_node/mod.rs), [MACRO_EXAMPLES.md](tests/onnx_single_node/MACRO_EXAMPLES.md)

See [tests/onnx_single_node/README.md](tests/onnx_single_node/README.md) for complete macro documentation.

## docs/roadmaps/Roadmap

### Current: 23 operators (8%)
Math, activations, tensor manipulation, normalization

### Phase 1: 37 operators (13%)
+ Softmax, BatchNorm, Conv, MaxPool, Transpose, Squeeze, reductions

### Phase 2: 52 operators (18%)
+ Advanced activations, comparisons, more shape operations

### Phase 3+: 100+ operators (35%+)
+ RNN/LSTM, vision ops, quantization

See [IMPLEMENTATION_SPEC.md](../../../docs/onnx/IMPLEMENTATION_SPEC.md) for complete priority roadmap.

## Project Structure

```
hologram-onnx-compiler/
├── src/
│   ├── hrm/
│   │   ├── ops/           # Operator implementations
│   │   │   ├── macros.rs  # Operator dispatch macro ⭐
│   │   │   ├── math.rs    # Math operators
│   │   │   ├── matrix.rs  # Matrix operators
│   │   │   └── ...
│   │   └── ...
│   └── lib.rs
├── tests/
│   ├── onnx_single_node/
│   │   ├── mod.rs         # Test macros ⭐
│   │   ├── MACRO_EXAMPLES.md  # Macro usage guide
│   │   ├── test_math.rs
│   │   └── ...
│   └── onnx_single_node_suite.rs
├── tests/onnx_single_node/README.md       # Testing methodology ⭐
└── README.md              # This file
```

## Contributing

When implementing new operators:

1. **Use the macros** - Reduces boilerplate by 40-80%
2. **Follow test patterns** - 4 tests per operator (basic, edge cases, shapes, properties)
3. **Update documentation** - Add to tests/onnx_single_node/README.md and IMPLEMENTATION_SPEC.md
4. **Verify tests pass** - All 110+ tests must pass

## License

See [LICENSE](../../../LICENSE) for details.
