# CAHP v1.0.0 - Quickstart

## Introduction
Welcome to the Cross-Architecture Handshake Protocol (CAHP) v1.0.0. This package contains the reference implementation of the secure handshake protocol used by Helix and Stonecharm nodes.

## Prerequisites
- Python 3.10+
- `cryptography` library

```bash
pip install cryptography
```

## Directory Structure
- `modules/cahp/`: The core engine source code.
- `tests/cahp/`: Validation scripts.
- `docs/`: Protocol specification and security notes.

## Running Tests
To verify the integrity of this release, run the included test suite:

```bash
# 1. Verify Basic Handshake
python3 tests/cahp/test_basic.py

# 2. Run Security Regression Tests
python3 tests/cahp/test_security.py

# 3. Simulate Network Loopback
python3 tests/cahp/test_loopback.py
```

## Usage Example
```python
from modules.cahp.cahp_engine_v1 import CAHPEngine

# Initialize Nodes
initiator = CAHPEngine("metabolic")
responder = CAHPEngine("open_weight")

# Phase 1: Discovery
msg1 = initiator.discovery()

# Phase 2: Proof & Challenge
verified_msg1 = responder._verify(msg1)
msg2 = responder.proof_and_challenge(verified_msg1)

# Phase 3: Response
verified_msg2 = initiator._verify(msg2)
msg3 = initiator.response_and_final(verified_msg2)

# Phase 4: Ticket
verified_msg3 = responder._verify(msg3)
ticket = responder.ticket(verified_msg3)

print("Session Established:", ticket)
```

## License
MIT / Helix Core Open Source.
