"""
CAS Registry — Content Addressable Storage with Cryptographic Commitments

Provides the Python-ACE bridge connecting the Algebraic Constraint Engine
with WASM-based Pedersen commitments for cryptographically-backed ACE witnesses.

This registry enables:
- Cryptographic verification of ACE certificates
- Pedersen commitment-based witness storage and retrieval
- Zero-knowledge proof integration for ACE governance
- Merkle tree-based batch verification of constraint certificates

See ADR-087 for design rationale and ADR-063a for crypto migration context.
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import logging
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any
from datetime import datetime

# Import ACE types
from pirtm.ace.types import AceCertificate, CertLevel
from pirtm.ace.witness import AceWitness

# Import the official multiplicity.crypto Python bridge.
try:
    from multiplicity.crypto import (
        computeCommitment,
        verifyCommitment,
        merkleRoot,
        generateMerkleProof,
        verifyMerkleProof,
        deriveIdentityCommitment,
        deriveIdentityAuditHash,
        redactIdentity,
        getBridgeStatus,
    )

    _CRYPTO_STATUS = getBridgeStatus()
    CRYPTO_AVAILABLE = True
    CRYPTO_MODE = _CRYPTO_STATUS.get("mode", "fallback")
except ImportError as e:
    CRYPTO_AVAILABLE = False
    CRYPTO_MODE = "fallback"
    _CRYPTO_STATUS = {
        "available": False,
        "mode": "fallback",
        "reason": str(e),
    }
    print(f"⚠️ WARNING: multiplicity-crypto not available: {e}, using SHA-256 fallbacks.")

    async def computeCommitment(leaf: str, salt: str) -> str:
        digest = hashlib.sha256(f"{leaf}:commit:{salt}".encode()).hexdigest()
        return f"0x{digest}"

    async def verifyCommitment(commitment: str, leaf: str, salt: str) -> bool:
        expected = await computeCommitment(leaf, salt)
        return commitment == expected

    async def merkleRoot(leaves: List[str]) -> str:
        if not leaves:
            raise ValueError("Cannot compute Merkle root of empty leaves")

        nodes = [await computeCommitment(leaf, "merkle-leaf") for leaf in leaves]
        while len(nodes) > 1:
            next_level: List[str] = []
            for i in range(0, len(nodes), 2):
                left = nodes[i]
                right = nodes[i + 1] if i + 1 < len(nodes) else left
                next_level.append(await computeCommitment(f"{left}:{right}", "merkle-node"))
            nodes = next_level
        return nodes[0]

    async def generateMerkleProof(leaves: List[str], leafIndex: int) -> dict:
        if leafIndex < 0 or leafIndex >= len(leaves):
            raise ValueError("Invalid leaf index")

        proof: List[str] = []
        nodes = [await computeCommitment(leaf, "merkle-leaf") for leaf in leaves]
        current_index = leafIndex

        while len(nodes) > 1:
            is_left_child = current_index % 2 == 0
            if is_left_child:
                sibling = nodes[current_index + 1] if current_index + 1 < len(nodes) else nodes[current_index]
                proof.append(f"right:{sibling}")
            else:
                proof.append(f"left:{nodes[current_index - 1]}")

            next_level: List[str] = []
            for i in range(0, len(nodes), 2):
                left = nodes[i]
                right = nodes[i + 1] if i + 1 < len(nodes) else left
                next_level.append(await computeCommitment(f"{left}:{right}", "merkle-node"))
            nodes = next_level
            current_index //= 2

        return {"proof": proof, "root": nodes[0]}

    async def verifyMerkleProof(leaf: str, proof: List[str], root: str) -> bool:
        current = await computeCommitment(leaf, "merkle-leaf")
        for proof_item in proof:
            position, sibling = proof_item.split(":", 1)
            combined = f"{sibling}:{current}" if position == "left" else f"{current}:{sibling}"
            current = await computeCommitment(combined, "merkle-node")
        return current == root

    async def deriveIdentityCommitment(input_str: str) -> str:
        return await computeCommitment(input_str, "identity:v1")

    async def deriveIdentityAuditHash(input_str: str) -> str:
        value = input_str if input_str.startswith("0x") else await deriveIdentityCommitment(input_str)
        return await computeCommitment(value, "audit:v1")

    async def redactIdentity(input_str: str) -> str:
        return f"redacted:{await computeCommitment(input_str, 'redact:v1')}"

    def getBridgeStatus() -> Dict[str, Any]:
        return dict(_CRYPTO_STATUS)

logger = logging.getLogger(__name__)


@dataclass
class CryptoBackedWitness:
    """
    ACE witness with cryptographic commitment backing.

    Extends AceWitness with Pedersen commitments for:
    - Witness integrity (hiding property)
    - Witness authenticity (binding property)
    - Batch verification (Merkle tree aggregation)
    """
    witness: AceWitness
    commitment: str                    # Pedersen commitment to witness data
    salt: str                         # Random salt for commitment
    merkle_root: Optional[str] = None # Merkle root if part of batch
    merkle_proof: Optional[List[str]] = None # Proof path if part of batch
    leaf_index: Optional[int] = None  # Position in Merkle tree

    @classmethod
    async def create(
        cls,
        witness: AceWitness,
        salt: Optional[str] = None
    ) -> "CryptoBackedWitness":
        """Create a cryptographically-backed witness."""

        # Generate salt if not provided
        if salt is None:
            salt = hashlib.sha256(
                f"{witness.witness_id}:{witness.timestamp_iso}".encode()
            ).hexdigest()

        # Create commitment to witness data
        witness_data = json.dumps({
            "witness_id": witness.witness_id,
            "level": witness.cert.level.value,
            "certified": witness.cert.certified,
            "lipschitz_upper": witness.cert.lipschitz_upper,
            "gap_lb": witness.cert.gap_lb,
            "prime_index": witness.prime_index,
            "timestamp": witness.timestamp_iso,
        }, sort_keys=True)

        commitment = await computeCommitment(witness_data, salt)

        return cls(
            witness=witness,
            commitment=commitment,
            salt=salt,
        )

    async def verify_integrity(self) -> bool:
        """Verify witness integrity using cryptographic commitment."""
        witness_data = json.dumps({
            "witness_id": self.witness.witness_id,
            "level": self.witness.cert.level.value,
            "certified": self.witness.cert.certified,
            "lipschitz_upper": self.witness.cert.lipschitz_upper,
            "gap_lb": self.witness.cert.gap_lb,
            "prime_index": self.witness.prime_index,
            "timestamp": self.witness.timestamp_iso,
        }, sort_keys=True)

        return await verifyCommitment(self.commitment, witness_data, self.salt)

    async def verify_batch_membership(
        self,
        expected_root: str
    ) -> bool:
        """Verify membership in a batch using Merkle proof."""
        if not self.merkle_proof or self.leaf_index is None:
            return False

        leaf_data = json.dumps({
            "commitment": self.commitment,
            "witness_id": self.witness.witness_id,
        }, sort_keys=True)

        return await verifyMerkleProof(leaf_data, self.merkle_proof, expected_root)


@dataclass
class CasRegistry:
    """
    Content Addressable Storage registry for ACE witnesses.

    Provides cryptographic guarantees for:
    - Witness immutability (Pedersen commitments)
    - Batch verification (Merkle trees)
    - Identity management (commitment-based)
    - Audit trails (redacted identity tracking)
    """

    witnesses: Dict[str, CryptoBackedWitness] = field(default_factory=dict)
    merkle_batches: Dict[str, List[str]] = field(default_factory=dict)  # batch_id -> witness_ids
    identity_commitments: Dict[str, str] = field(default_factory=dict)  # commitment -> audit_hash
    audit_trail: List[Dict[str, Any]] = field(default_factory=list)

    async def register_witness(
        self,
        witness: AceWitness,
        identity: Optional[str] = None,
        batch_id: Optional[str] = None
    ) -> CryptoBackedWitness:
        """
        Register an ACE witness with cryptographic backing.

        Args:
            witness: The ACE witness to register
            identity: Optional identity for audit trail
            batch_id: Optional batch ID for Merkle tree aggregation

        Returns:
            CryptoBackedWitness with commitment backing
        """
        # Create cryptographically-backed witness
        backed_witness = await CryptoBackedWitness.create(witness)

        # Store in registry
        self.witnesses[witness.witness_id] = backed_witness

        # Handle batching if requested
        if batch_id:
            if batch_id not in self.merkle_batches:
                self.merkle_batches[batch_id] = []
            self.merkle_batches[batch_id].append(witness.witness_id)

            # Update Merkle proofs for all witnesses in batch
            await self._update_batch_merkle_proofs(batch_id)

        # Handle identity tracking
        if identity:
            await self._track_identity(identity, witness.witness_id)

        logger.info(f"Registered witness {witness.witness_id} with commitment {backed_witness.commitment}")
        return backed_witness

    async def verify_witness(
        self,
        witness_id: str,
        batch_root: Optional[str] = None
    ) -> bool:
        """
        Verify a witness's cryptographic integrity and optional batch membership.

        Args:
            witness_id: ID of witness to verify
            batch_root: Expected Merkle root for batch verification

        Returns:
            True if witness is valid and (if batch_root provided) member of batch
        """
        if witness_id not in self.witnesses:
            return False

        witness = self.witnesses[witness_id]

        # Verify witness integrity
        if not await witness.verify_integrity():
            logger.warning(f"Witness {witness_id} integrity check failed")
            return False

        # Verify batch membership if requested
        if batch_root and not await witness.verify_batch_membership(batch_root):
            logger.warning(f"Witness {witness_id} batch membership check failed")
            return False

        return True

    async def get_batch_root(self, batch_id: str) -> Optional[str]:
        """Get the Merkle root for a batch of witnesses."""
        if batch_id not in self.merkle_batches:
            return None

        witness_ids = self.merkle_batches[batch_id]
        if not witness_ids:
            return None

        # Create leaves from witness commitments
        leaves = []
        for witness_id in witness_ids:
            if witness_id in self.witnesses:
                commitment = self.witnesses[witness_id].commitment
                leaf_data = json.dumps({
                    "commitment": commitment,
                    "witness_id": witness_id,
                }, sort_keys=True)
                leaves.append(leaf_data)

        if not leaves:
            return None

        return await merkleRoot(leaves)

    async def _update_batch_merkle_proofs(self, batch_id: str) -> None:
        """Update Merkle proofs for all witnesses in a batch."""
        witness_ids = self.merkle_batches[batch_id]
        if len(witness_ids) < 2:
            return  # Need at least 2 witnesses for meaningful Merkle tree

        # Create leaves
        leaves = []
        for witness_id in witness_ids:
            if witness_id in self.witnesses:
                commitment = self.witnesses[witness_id].commitment
                leaf_data = json.dumps({
                    "commitment": commitment,
                    "witness_id": witness_id,
                }, sort_keys=True)
                leaves.append(leaf_data)

        # Generate Merkle root
        root = await merkleRoot(leaves)

        # Update each witness with its proof
        for i, witness_id in enumerate(witness_ids):
            if witness_id in self.witnesses:
                proof_result = await generateMerkleProof(leaves, i)
                self.witnesses[witness_id].merkle_root = proof_result.get("root", root)
                self.witnesses[witness_id].merkle_proof = proof_result.get("proof", [])
                self.witnesses[witness_id].leaf_index = i

    async def _track_identity(
        self,
        identity: str,
        witness_id: str
    ) -> None:
        """Track identity with cryptographic commitment for audit trail."""
        if not CRYPTO_AVAILABLE:
            return

        # Create identity commitment and audit hash on the shared crypto spec.
        identity_commitment = await deriveIdentityCommitment(identity)
        identity_audit_hash = await deriveIdentityAuditHash(identity_commitment)
        self.identity_commitments[identity_commitment] = identity_audit_hash

        # Create redacted audit entry
        redacted_identity = await redactIdentity(identity)
        audit_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "witness_id": witness_id,
            "identity_commitment": identity_commitment,
            "identity_audit_hash": identity_audit_hash,
            "redacted_identity": redacted_identity,
            "crypto_mode": CRYPTO_MODE,
            "action": "witness_registration",
        }

        self.audit_trail.append(audit_entry)

    async def get_audit_trail(
        self,
        identity_commitment: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Get audit trail, optionally filtered by identity commitment."""
        if identity_commitment:
            return [
                entry for entry in self.audit_trail
                if entry.get("identity_commitment") == identity_commitment
            ]
        return self.audit_trail.copy()

    def get_witness_stats(self) -> Dict[str, Any]:
        """Get statistics about registered witnesses."""
        total_witnesses = len(self.witnesses)
        certified_witnesses = sum(
            1 for w in self.witnesses.values()
            if w.witness.cert.certified
        )
        batch_count = len(self.merkle_batches)

        return {
            "total_witnesses": total_witnesses,
            "certified_witnesses": certified_witnesses,
            "certification_rate": certified_witnesses / total_witnesses if total_witnesses > 0 else 0,
            "batches": batch_count,
            "identities_tracked": len(self.identity_commitments),
            "audit_entries": len(self.audit_trail),
            "crypto_available": CRYPTO_AVAILABLE,
            "crypto_mode": CRYPTO_MODE,
            "crypto_status": dict(getBridgeStatus()),
        }


# Global registry instance
_registry_instance: Optional[CasRegistry] = None


def get_registry() -> CasRegistry:
    """Get the global CAS registry instance."""
    global _registry_instance
    if _registry_instance is None:
        _registry_instance = CasRegistry()
    return _registry_instance


async def register_ace_witness(
    witness: AceWitness,
    identity: Optional[str] = None,
    batch_id: Optional[str] = None
) -> CryptoBackedWitness:
    """
    Convenience function to register an ACE witness in the global registry.

    This is the main entry point for the Python-ACE bridge.
    """
    registry = get_registry()
    return await registry.register_witness(witness, identity, batch_id)


async def verify_ace_witness(
    witness_id: str,
    batch_root: Optional[str] = None
) -> bool:
    """
    Convenience function to verify an ACE witness in the global registry.
    """
    registry = get_registry()
    return await registry.verify_witness(witness_id, batch_root)