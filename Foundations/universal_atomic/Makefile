# =============================================================================
# UAC – Production‑grade Makefile
# =============================================================================
# Targets:
#   all      – default, builds Lean library and Rust crate.
#   build    – compiles Lean (lake) and Rust (cargo).
#   audit    – regenerates inventory and Lean status table.
#   docs     – builds the LaTeX manuscript (requires pdflatex).
#   test     – runs Rust unit tests and Lean test suite.
#   lint     – runs rustfmt, clippy, and Lean formatting checks.
#   clean    – removes generated artefacts.
# =============================================================================

# Directories
LEANDIR   := lean
SRCDIR    := $(LEANDIR)/src
SCRIPTDIR := scripts
DOCDIR    := docs
GENERATED := $(DOCDIR)/generated_lean_status.tex
INVENTORY := inventory.txt

# Tools
LAKE      := lake
CARGO     := cargo
PDLATEX   := pdflatex
RUSTFMT   := rustfmt
CLIPPY    := cargo clippy

.PHONY: all build audit docs test lint clean

all: build

# -----------------------------------------------------------------------------
# Build Lean library and Rust crate
# -----------------------------------------------------------------------------
build:
	@echo "▶ Building Lean library"
	$(LAKE) build -R $(LEANDIR)
	@echo "▶ Building Rust crate"
	$(CARGO) build --release

# -----------------------------------------------------------------------------
# Audit – generate inventory and Lean status table
# -----------------------------------------------------------------------------
audit:
	@echo "▶ Generating inventory"
	python3 $(SCRIPTDIR)/gen_lean_status.py
	@echo "▶ Inventory written to $(GENERATED)"

# -----------------------------------------------------------------------------
# Docs – compile LaTeX manuscript (includes ADR fragment)
# -----------------------------------------------------------------------------
docs: $(GENERATED)
	@echo "▶ Building PDF manuscript"
	cd $(DOCDIR) && $(PDLATEX) "Universal Atomic Calculator.tex" && $(PDLATEX) "Universal Atomic Calculator.tex"

# -----------------------------------------------------------------------------
# Test – Rust unit tests and Lean test suite
# -----------------------------------------------------------------------------
test:
	@echo "▶ Running Rust tests"
	$(CARGO) test --release
	@echo "▶ Running Lean tests"
	$(LAKE) test -R $(LEANDIR)

# -----------------------------------------------------------------------------
# Lint – enforce code style
# -----------------------------------------------------------------------------
lint:
	@echo "▶ Formatting Rust code"
	$(RUSTFMT) --edition 2021 $(shell find src -name "*.rs")
	@echo "▶ Running Clippy"
	$(CLIPPY) -- -D warnings
	@echo "▶ Checking Lean formatting"
	$(LAKE) fmt -R $(LEANDIR)

# -----------------------------------------------------------------------------
# Clean – remove generated artefacts
# -----------------------------------------------------------------------------
clean:
	@echo "▶ Cleaning build artefacts"
	$(CARGO) clean
	$(LAKE) clean -R $(LEANDIR)
	rm -f $(GENERATED) $(INVENTORY) $(DOCDIR)/*.pdf
