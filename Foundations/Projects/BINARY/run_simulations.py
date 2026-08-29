#!/usr/bin/env python3
"""
run_simulations.py
==================
Top-level executable runner for the Binary Fragmentation Simulator.
"""

import sys
import os

# Add BINARY directory to sys.path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from binary_fragmentation.cli import main

if __name__ == "__main__":
    sys.exit(main())
