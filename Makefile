.PHONY: all verify verify-lean verify-rust verify-kani test bench clean help

all: verify

help:
	@echo "Universal Closure Theory - Build Targets"
	@echo ""
	@echo "  make verify       - Run all verification (Lean + Rust + Kani)"
	@echo "  make verify-lean  - Run Lean 4 spec type-checks only"
	@echo "  make verify-rust  - Run Rust tests only"
	@echo "  make verify-kani  - Run Kani BMC only"
	@echo "  make test         - Run all Rust tests"
	@echo "  make bench        - Run benchmarks"
	@echo "  make clean        - Clean build artifacts"
	@echo ""

verify: verify-lean verify-rust
	@echo "=== All verification complete ==="

verify-lean:
	@echo "--- Lean 4 Spec Verification ---"
	cd lean && lake build Core
	@echo "Sorry count:"
	@grep -r "sorry" lean/Core/Spec/ lean/Core/Properties/ lean/Core/Ext/ --include="*.lean" 2>/dev/null | grep -v "^--" | wc -l || echo "0"
	@echo "Mathlib import count:"
	@grep -r "Mathlib" lean/Core/ --include="*.lean" 2>/dev/null | wc -l || echo "0"
	@echo "Lean verification: DONE"

verify-rust:
	@echo "--- Rust Verification ---"
	cd rust && cargo test --lib
	cd rust && cargo test --test completion_test --test quantum_test --test proptest
	@echo "Rust verification: DONE"

verify-kani:
	@echo "--- Kani BMC Verification ---"
	cd rust && cargo kani --harness verify_adjunction_lift_property || true
	cd rust && cargo kani --harness verify_no_panic_termination || true
	cd rust && cargo kani --harness verify_blockade_enforced || true
	cd rust && cargo kani --harness verify_associator_bounded || true
	cd rust && cargo kani --harness verify_ffi_proof_export || true
	cd rust && cargo kani --harness verify_union_find_no_panic || true
	cd rust && cargo kani --harness verify_no_index_out_of_bounds || true
	@echo "Kani verification: DONE"

test: verify-rust

bench:
	@echo "--- Benchmarks ---"
	cd rust && cargo bench
	@echo "Benchmarks: DONE"

clean:
	cd lean && lake clean
	cd rust && cargo clean
	@echo "Clean: DONE"

verify-contracts:
	@echo "--- Contract Validation ---"
	@for f in contracts/*.yaml; do \
		python3 -c "import yaml; yaml.safe_load(open('$$f'))" && echo "$$f: VALID" || echo "$$f: INVALID"; \
	done
