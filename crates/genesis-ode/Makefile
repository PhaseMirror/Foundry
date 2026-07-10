.PHONY: test test-arch sweep-met-ai review golden-master install clean help

PYTHONPATH := src

help:
	@echo "Genesis Governance Makefile"
	@echo "Usage:"
	@echo "  make install        Install the package in editable mode"
	@echo "  make test           Run all tests"
	@echo "  make test-arch      Run architecture validation tests"
	@echo "  make sweep-met-ai   Run the Path A heterogeneous sweep"
	@echo "  make golden-master  Regenerate the metallurgical golden master"
	@echo "  make clean          Remove output and cache files"

install:
	pip install -e ".[dev]"

test:
	PYTHONPATH=$(PYTHONPATH) pytest

test-arch:
	PYTHONPATH=$(PYTHONPATH) pytest tests/architecture/test_module_boundaries.py

sweep-met-ai:
	mkdir -p output
	PYTHONPATH=$(PYTHONPATH) python3 src/genesis_governance/cli/main.py sweep-cross --kappa_values 0.1 0.5 1.0 2.0 --output output/path_a_deep_sweep.json

jitter-stress:
	mkdir -p output
	PYTHONPATH=$(PYTHONPATH) python3 examples/semi_jitter_stress.py

golden-master:
	mkdir -p tests/golden
	PYTHONPATH=$(PYTHONPATH) python3 src/genesis_governance/cli/main.py run --ramp 0.1 --output tests/golden/expected-metallurgical-shrapnel.json

clean:
	rm -rf output/*
	rm -rf tests/golden/*
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
