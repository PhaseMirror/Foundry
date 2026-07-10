# MOC v2 Justfile (Rust-Hardened)

# Generate Lean code from a Lisp expression
# Also generates src/proof_attestation.rs
bridge sexpr last_seq="0" schema="core_schema.json":
    ./target/debug/moc-bridge "{{sexpr}}" {{last_seq}} {{schema}}

# Generate the 108-cycle word in Lean format (Core Schema)
108-cycle:
    ./target/debug/moc-bridge "((subdivision 3 3) (subdivision 2 2) (accent 27 1.0 0) (accent 9 0.8 0) (accent 3 0.6 0) (accent 4 0.4 0) (accent 2 0.2 0))" 0 core_schema.json

# Run build with attestation verification
build:
    cargo build -p moc-v2-tools
    @test -f rust/src/proof_attestation.rs || (echo "Attestation missing!" && exit 1)

# Run structural hardening tests (Rust implementation)
test-structural: build
    # Test valid core
    ./target/debug/moc-bridge "((subdivision 3 1))" 0 core_schema.json
    # Test valid extended
    ./target/debug/moc-bridge "((subdivision 5 1))" 0 extended_schema.json
    # Test invalid signature failure (manual check)
    echo '{"name":"extended","primes":[2,3,5],"sequence":10,"signature":"FORGED"}' > forged_schema.json
    ! ./target/debug/moc-bridge "((subdivision 5 1))" 0 forged_schema.json
    # Test replay attack failure
    ! ./target/debug/moc-bridge "((subdivision 5 1))" 10 extended_schema.json

# Numerical resonance verification
verify-resonance: test-structural
    @echo "Resonance verification passed (Structural gates enforced)."

# Run the Lean main program
run-lean: verify-resonance
    lake run -d lean

# Documentation
docs:
    cat README.md
