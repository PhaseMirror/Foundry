"""ACE / multiplicity crypto integration tests.

These checks validate the Phase 2 Python bridge end-to-end:
- the official `multiplicity.crypto` Python wrapper loads
- ACE witnesses register through the bridge with commitments
- batch membership proofs verify through the shared Merkle helpers
- matrix-based ACE certification also flows through the same registry
"""

from __future__ import annotations

import asyncio
import os
import sys

import numpy as np

# Add pirtm to path
pirtm_path = os.path.join(os.path.dirname(__file__), '..', 'pirtm')
if pirtm_path not in sys.path:
    sys.path.insert(0, pirtm_path)

from pirtm.ace.protocol import AceProtocol
from pirtm.step_types import StepInfo

from multiplicity import CAS_AVAILABLE, get_registry, register_ace_witness, verify_ace_witness
from multiplicity.math.cas_registry import CRYPTO_AVAILABLE
from multiplicity.crypto import MultiplicityCrypto


def _make_records() -> list[StepInfo]:
    return [
        StepInfo(epsilon=0.1, q=0.85),
        StepInfo(epsilon=0.08, q=0.82),
        StepInfo(epsilon=0.06, q=0.78),
    ]


def test_official_python_bridge_loads() -> None:
    """Phase 2 requires the official Python bridge to be available."""
    assert CAS_AVAILABLE, "Expected the CAS registry bridge to load from `multiplicity.crypto`."
    assert CRYPTO_AVAILABLE, "Expected the official multiplicity crypto Python wrapper to be available."

    stats = get_registry().get_witness_stats()
    assert stats["crypto_available"] is True
    assert stats["crypto_mode"] in {"wasm", "fallback"}


async def _register_two_witnesses_in_batch() -> tuple[str, str, str]:
    registry = get_registry()

    ace = AceProtocol(tau=1.0, delta=0.05)
    first = ace.certify_from_telemetry(_make_records(), prime_index=2)
    second = ace.certify_from_telemetry(_make_records(), prime_index=3)

    batch_id = "test-batch-phase2"
    first_crypto = await register_ace_witness(
        first,
        identity="test-researcher@phasemirror.ai",
        batch_id=batch_id,
    )
    second_crypto = await register_ace_witness(
        second,
        identity="reviewer@phasemirror.ai",
        batch_id=batch_id,
    )

    assert first_crypto.commitment.startswith("0x")
    assert second_crypto.commitment.startswith("0x")

    assert await verify_ace_witness(first.witness_id) is True
    assert await verify_ace_witness(second.witness_id) is True

    batch_root = await registry.get_batch_root(batch_id)
    assert batch_root is not None
    assert batch_root.startswith("0x")

    assert await verify_ace_witness(first.witness_id, batch_root) is True
    assert await verify_ace_witness(second.witness_id, batch_root) is True

    audit_trail = await registry.get_audit_trail()
    assert len(audit_trail) >= 2
    assert audit_trail[-1]["redacted_identity"].startswith("redacted:")

    return first.witness_id, second.witness_id, batch_root


def test_ace_witness_registration_and_batch_membership() -> None:
    """ACE witness registration should succeed through the official bridge."""
    first_id, second_id, batch_root = asyncio.run(_register_two_witnesses_in_batch())

    assert first_id != second_id
    assert batch_root.startswith("0x")


def test_forced_fallback_mode_remains_deterministic() -> None:
    """Fallback mode is tested separately from the default bridge path."""

    async def _run() -> tuple[dict, str, bool]:
        bridge = MultiplicityCrypto(force_fallback=True)
        status = bridge.getBridgeStatus()
        commitment = await bridge.computeCommitment("fallback-leaf", "fallback-salt")
        verified = await bridge.verifyCommitment(commitment, "fallback-leaf", "fallback-salt")
        return status, commitment, verified

    status, commitment, verified = asyncio.run(_run())
    assert status["mode"] == "fallback"
    assert commitment.startswith("0x")
    assert verified is True


def test_matrix_based_certification_registers_with_crypto() -> None:
    """L2 matrix certification should also flow through the same crypto-backed registry."""

    async def _run() -> tuple[bool, str]:
        ace = AceProtocol(tau=10.0, delta=0.05)
        matrix = np.array([
            [0.01, 0.005],
            [0.008, 0.02],
        ])

        witness = ace.certify_from_matrix(matrix, prime_index=5)
        crypto_witness = await register_ace_witness(
            witness,
            identity="matrix-test@phasemirror.ai",
            batch_id="matrix-batch-phase2",
        )
        verified = await verify_ace_witness(witness.witness_id)
        return verified, crypto_witness.commitment

    verified, commitment = asyncio.run(_run())
    assert verified is True
    assert commitment.startswith("0x")
