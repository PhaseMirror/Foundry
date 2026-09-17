.PHONY: all clean lean rust kani test verify docs help fpes-gate fpes-test kani-full adr-index adr-sorry-check adr-verify check-toolchain

# Prefer the elan toolchain-resolving `lake`/`lean` over any standalone
# binaries earlier on PATH (e.g. ~/.local/bin/lake pinned to an older Lean).
# Preceding with a non-existent directory is harmless: shells fall through
# to the next PATH entry.
ELAN_BIN ?= $(HOME)/.elan/bin
export PATH := $(ELAN_BIN):$(PATH)

# Default target
all: lean rust

# Lean 4 formal core
lean:
	cd lean && lake build

# Rust implementation
rust:
	cd packages/rust && cargo build

# Kani bounded model checking
kani:
	cd packages/rust && cargo kani --harness verify_adjunction_lift_property
	cd packages/rust && cargo kani --harness verify_no_panic_termination
	cd packages/rust && cargo kani --harness verify_blockade_enforced
	cd packages/rust && cargo kani --harness verify_associator_bounded
	cd packages/rust && cargo kani --harness verify_ffi_proof_export
	cd packages/rust && cargo kani --harness verify_union_find_no_panic
	cd packages/rust && cargo kani --harness verify_no_index_out_of_bounds

# Run all tests
test: lean-test rust-test

# Lean tests
lean-test:
	cd lean && lake test

# Rust tests
rust-test:
	cd packages/rust && cargo test

# Run full verification pipeline
verify:
	./scripts/verify-all.sh

# ADR-0029: FPES escape-proof gate (Lean kernel + sorry/mathlib audits + Kani)
fpes-gate:
	./scripts/fpes-gate.sh

# ADR-0029: run the FPES Lean test harness directly
fpes-test:
	cd lean && lake test

# ADR-0029: full Kani suite for the FPES kernel (bounded, N <= 8)
kani-full:
	cd lean/Multiplicity/kani && cargo kani --harness kani_fpes_001_multiplicity_nonzero --unwind 9
	cd lean/Multiplicity/kani && cargo kani --harness kani_fpes_002_contraction_preserves_multiplicity --unwind 9

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

# Regenerate ADR index from registry.json
adr-index:
	python3 scripts/generate_adr_index.py

# ADR-0010: Check for sorry tactics in ADR/ directory
adr-sorry-check:
	python3 scripts/check_adr_sorry.py

# Preflight: fail loudly if the active lake/lean binary disagrees with the
# pinned lean-toolchain revision (protects against PATH shadowing).
check-toolchain:
	@bash scripts/check_lake_toolchain.sh

# Unified ADR verification gate: index + sorry check + toolchain + lean build/test
adr-verify: check-toolchain adr-index adr-sorry-check
	lake build ADR
	lake test

# Run the full ADR verification gate for one ADR and propagate the results into
# docs/adr/results/<adr-id>-<slug>/ (runs index + sorry check + lake build/test +
# pirtm-engine cargo tests + Kani BMC harnesses). Pass ADR_FILE to target a
# specific ADR, e.g.: make adr-test-results ADR_FILE="docs/adr/completed/ADR-0108-PrismPM and Langlands Prism.md"
adr-test-results:
	python3 scripts/run_adr_tests.py "$(ADR_FILE)"

# Clean build artifacts
clean:
	cd lean && lake clean
	cd packages/rust && cargo clean
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
	@echo "  fpes-gate        - ADR-0029 escape-proof FPES gate"
	@echo "  fpes-test        - Run the FPES Lean test harness"
	@echo "  kani-full        - ADR-0029 full FPES Kani suite (N <= 8)"
	@echo "  adr-verify       - ADR gate (index + sorry + lake build + lake test)"
	@echo "  adr-test-results - Per-ADR gate; propagates results to docs/adr/results/ (ADR_FILE=<path>)"
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
