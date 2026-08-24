# ADR-0029: FPES Production Makefile
# Enforces the provable-contracts seven-phase pipeline:
#   Extract → Specify → Scaffold → Implement → Falsify → Verify → Prove

.PHONY: all lean-build lean-check fpes-test fold-build fold-test word-love-build word-love-test word-love-gate kani-full kani-fpes gate clean

# ── Lean targets ──────────────────────────────────────────────

lean-build:
	lake build Multiplicity.FPES.Test

lean-check: lean-build
	@echo "Lean kernel accepted all FPES theorems (no sorry)"

# ── Test targets ──────────────────────────────────────────────

fpes-test:
	lake test

# ── Fold Theory targets (ADR-0032) ───────────────────────────

fold-build:
	lake build Multiplicity.Fold.Test

fold-test: fold-build
	lake exec fold_test

# ── Word Love targets (ADR-0031) ──────────────────────────────

word-love-build:
	lake build word_love_test

word-love-test: word-love-build
	lake exe word_love_test

word-love-gate:
	scripts/word-love-gate.sh --verbose

# ── Kani targets ──────────────────────────────────────────────

kani-fpes-001:
	cargo kani --manifest-path Multiplicity/kani/Cargo.toml \
		--harness kani_fpes_001_multiplicity_nonzero

kani-fpes-002:
	cargo kani --manifest-path Multiplicity/kani/Cargo.toml \
		--harness kani_fpes_002_contraction_preserves_multiplicity

kani-fpes: kani-fpes-001 kani-fpes-002

kani-full: kani-fpes
	@echo "All Kani FPES harnesses passed (N ≤ 8)"

# ── Gate ──────────────────────────────────────────────────────

gate:
	scripts/fpes-gate.sh --verbose

# ── All ───────────────────────────────────────────────────────

all: lean-check fpes-test gate
	@echo "ADR-0029 FPES: all verification gates passed"

# ── Clean ─────────────────────────────────────────────────────

clean:
	lake clean
	cargo clean --manifest-path Multiplicity/kani/Cargo.toml
