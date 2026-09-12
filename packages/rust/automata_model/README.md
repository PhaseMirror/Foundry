# automata-rs: Multiplicity Automata Runtime

High-performance Rust implementation of finite and omega automata for the Multiplicity substrate.

## Features
- **DFA (Deterministic Finite Automata)**: Efficient runtime with Hopcroft minimization.
- **NFA (Nondeterministic Finite Automata)**: Support for epsilon-transitions and subset construction to DFA.
- **Regex Compiler**: Thompson construction for compiling regular expressions into NFAs.
- **Omega Automata**: Support for $\omega$-words with Lasso runs and Buchi/Parity acceptance conditions.
- **Type Safety**: Fully generic over state and symbol types with `serde` support.

## Usage
### Build
```bash
cargo build --release
```

### Test
```bash
cargo test
```

## Verification
The implementation is verified against standard automata algorithms and maintains parity with the `automata_core` Python package.
