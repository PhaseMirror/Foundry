# Contributing to PIRTM Compiler

## Build

```bash
cargo build --all
```

## Test

```bash
cargo test --all
python substrates/tests/python/test_pweh_integration.py
```

## Lint

```bash
cargo clippy --all -- -D warnings
```

## Commit Convention

Use conventional commits:
- `feat:` for new features
- `fix:` for bug fixes
- `test:` for test additions
- `refactor:` for code restructuring

## Witness Integration

Every workflow execution produces a `UnifiedWitness` in `state/archivum/witnesses.jsonl`. Verify before committing.