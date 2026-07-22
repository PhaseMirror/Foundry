.PHONY: all clean lean rust kani test verify docs help

# Default target
all: lean rust

# Lean 4 formal core
lean:
	cd lean && lake build

# Rust implementation
rust:
	cd rust && cargo build

# Kani bounded model checking
kani:
	cd rust && cargo kani --harness verify_adjunction_lift_property
	cd rust && cargo kani --harness verify_no_panic_termination
	cd rust && cargo kani --harness verify_blockade_enforced
	cd rust && cargo kani --harness verify_associator_bounded
	cd rust && cargo kani --harness verify_ffi_proof_export
	cd rust && cargo kani --harness verify_union_find_no_panic
	cd rust && cargo kani --harness verify_no_index_out_of_bounds

# Run all tests
test: lean-test rust-test

# Lean tests
lean-test:
	cd lean && lake test

# Rust tests
rust-test:
	cd rust && cargo test

# Run full verification pipeline
verify:
	./scripts/verify-all.sh

# Generate Kani harnesses from YAML contracts
generate-harnesses:
	./scripts/generate-harnesses.sh

# Sync Lean theorems to Rust contracts
sync:
	./scripts/sync-lean-rust.sh

# Generate documentation
docs:
	cd lean && lake build docs
	mkdir -p docs/verification
	@echo "Documentation generated in docs/"

# Clean build artifacts
clean:
	cd lean && lake clean
	cd rust && cargo clean
	rm -rf docs/verification/*.md

# Help
help:
	@echo "Universal Closure Theory - Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all              - Build Lean and Rust (default)"
	@echo "  lean             - Build Lean 4 formal core"
	@echo "  rust             - Build Rust implementation"
	@echo "  kani             - Run Kani bounded model checking"
	@echo "  test             - Run all tests"
	@echo "  lean-test        - Run Lean tests"
	@echo "  rust-test        - Run Rust tests"
	@echo "  verify           - Run full verification pipeline"
	@echo "  generate-harnesses - Generate Kani harnesses from YAML"
	@echo "  sync             - Sync Lean theorems to Rust contracts"
	@echo "  docs             - Generate documentation"
	@echo "  clean            - Clean build artifacts"
	@echo "  help             - Show this help"
	@echo ""
	@echo "Examples:"
	@echo "  make all         - Build everything"
	@echo "  make kani        - Run Kani verification"
	@echo "  make verify      - Run full verification pipeline"
	@echo "  make test        - Run all tests"
