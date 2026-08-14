"""Official Python interop layer for the `multiplicity.crypto` package.

The ACE / CAS runtime uses this bridge to call the TypeScript/WASM crypto
backend through a stable Python API. When the Node/WASM bridge is unavailable,
a deterministic SHA-256 compatibility mode is used with the same public API.
"""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional

PROJECT_ROOT = Path(__file__).resolve().parents[3]
TS_PACKAGE_DIR = PROJECT_ROOT / "ts"
BRIDGE_SCRIPT_PATH = TS_PACKAGE_DIR / "python" / "crypto_bridge.js"
DIST_ENTRY_PATH = TS_PACKAGE_DIR / "dist" / "src" / "index.js"


def _normalize_hex(value: str) -> str:
    return value if value.startswith("0x") else f"0x{value}"


def _sha256_hex(*parts: str) -> str:
    hasher = hashlib.sha256()
    for part in parts:
        hasher.update(part.encode("utf8"))
    return hasher.hexdigest()


def _fallback_commitment(message: str, randomness: str) -> str:
    return _normalize_hex(_sha256_hex(message, ":commit:", randomness))


def _fallback_merkle_root(leaves: List[str]) -> str:
    if not leaves:
        raise ValueError("Cannot compute Merkle root of empty leaves")

    nodes = [_fallback_commitment(leaf, "merkle-leaf") for leaf in leaves]
    while len(nodes) > 1:
        next_level: List[str] = []
        for index in range(0, len(nodes), 2):
            left = nodes[index]
            right = nodes[index + 1] if index + 1 < len(nodes) else left
            next_level.append(_fallback_commitment(f"{left}:{right}", "merkle-node"))
        nodes = next_level
    return nodes[0]


def _fallback_generate_merkle_proof(leaves: List[str], leaf_index: int) -> Dict[str, Any]:
    if leaf_index < 0 or leaf_index >= len(leaves):
        raise ValueError("Invalid leaf index")

    proof: List[str] = []
    nodes = [_fallback_commitment(leaf, "merkle-leaf") for leaf in leaves]
    current_index = leaf_index

    while len(nodes) > 1:
        is_left_child = current_index % 2 == 0
        if is_left_child:
            sibling = nodes[current_index + 1] if current_index + 1 < len(nodes) else nodes[current_index]
            proof.append(f"right:{sibling}")
        else:
            proof.append(f"left:{nodes[current_index - 1]}")

        next_level: List[str] = []
        for index in range(0, len(nodes), 2):
            left = nodes[index]
            right = nodes[index + 1] if index + 1 < len(nodes) else left
            next_level.append(_fallback_commitment(f"{left}:{right}", "merkle-node"))
        nodes = next_level
        current_index //= 2

    return {"proof": proof, "root": nodes[0]}


def _fallback_verify_merkle_proof(leaf: str, proof: List[str], root: str) -> bool:
    current = _fallback_commitment(leaf, "merkle-leaf")
    for proof_item in proof:
        position, sibling = proof_item.split(":", 1)
        combined = f"{sibling}:{current}" if position == "left" else f"{current}:{sibling}"
        current = _fallback_commitment(combined, "merkle-node")
    return current == root


def _fallback_bls_sign(private_key: str, message: str) -> Dict[str, str]:
    public_key = _normalize_hex(_sha256_hex(f"bls-pk:{private_key}"))
    signature = _normalize_hex(_sha256_hex(public_key, ":bls-sign:", message))
    return {"signature": signature, "publicKey": public_key, "message": message}


def _fallback_bls_verify(payload: Dict[str, Any]) -> bool:
    signature = str(payload.get("signature", ""))
    public_key = str(payload.get("publicKey", ""))
    message = str(payload.get("message", ""))
    expected = _normalize_hex(_sha256_hex(public_key, ":bls-sign:", message))
    return signature == expected


def _fallback_bls_aggregate(signatures: List[Dict[str, Any]]) -> str:
    combined = "".join(str(sig.get("signature", "")) for sig in signatures)
    return _normalize_hex(_sha256_hex(combined, ":aggregate:"))


class MultiplicityCrypto:
    """Official Python bridge for the TypeScript/WASM crypto backend."""

    def __init__(self, force_fallback: Optional[bool] = None):
        self.ts_package_dir = TS_PACKAGE_DIR
        self.bridge_script_path = BRIDGE_SCRIPT_PATH
        self.dist_entry_path = DIST_ENTRY_PATH
        self.node_binary = shutil.which("node")
        self.force_fallback = bool(
            force_fallback
            if force_fallback is not None
            else os.getenv("MULTIPLICITY_CRYPTO_FORCE_FALLBACK", "0").lower() in {"1", "true", "yes"}
        )
        self._bridge_status = self._resolve_bridge_status()

    def _ensure_built(self) -> bool:
        src_dir = self.ts_package_dir / "src"
        needs_build = not self.dist_entry_path.exists()

        if not needs_build and src_dir.exists():
            dist_mtime = self.dist_entry_path.stat().st_mtime
            latest_src_mtime = max((path.stat().st_mtime for path in src_dir.rglob("*.ts")), default=0.0)
            needs_build = latest_src_mtime > dist_mtime

        if not needs_build:
            return True

        pnpm_binary = shutil.which("pnpm")
        if not pnpm_binary:
            return False

        try:
            subprocess.run(
                [pnpm_binary, "run", "build"],
                cwd=self.ts_package_dir,
                check=True,
                capture_output=True,
                text=True,
            )
        except subprocess.CalledProcessError:
            return False

        return self.dist_entry_path.exists()

    def _run_node_json(self, command: str, *args: Any) -> Any:
        if not self.node_binary:
            raise RuntimeError("Node.js is not available for the multiplicity.crypto bridge")

        serialized_args = [
            json.dumps(arg) if isinstance(arg, (dict, list)) else str(arg)
            for arg in args
        ]
        result = subprocess.run(
            [self.node_binary, str(self.bridge_script_path), command, *serialized_args],
            cwd=self.ts_package_dir,
            check=True,
            capture_output=True,
            text=True,
        )
        stdout = result.stdout.strip() or "null"
        return json.loads(stdout)

    def _resolve_bridge_status(self) -> Dict[str, Any]:
        if self.force_fallback:
            return {"available": True, "mode": "fallback", "reason": "forced"}

        if not self.bridge_script_path.exists():
            return {"available": True, "mode": "fallback", "reason": "bridge-script-missing"}

        if not self.node_binary:
            return {"available": True, "mode": "fallback", "reason": "node-unavailable"}

        if not self._ensure_built():
            return {"available": True, "mode": "fallback", "reason": "dist-unavailable"}

        try:
            status = self._run_node_json("getBridgeStatus")
            if isinstance(status, dict):
                status.setdefault("available", True)
                status.setdefault("mode", "fallback")
                return status
        except Exception as exc:  # pragma: no cover - defensive fallback
            return {"available": True, "mode": "fallback", "reason": str(exc)}

        return {"available": True, "mode": "fallback", "reason": "status-unavailable"}

    def getBridgeStatus(self) -> Dict[str, Any]:
        return dict(self._bridge_status)

    def _call(self, command: str, *args: Any) -> Any:
        can_use_node_bridge = (
            not self.force_fallback
            and self.node_binary is not None
            and self.bridge_script_path.exists()
            and self.dist_entry_path.exists()
        )

        if can_use_node_bridge:
            try:
                return self._run_node_json(command, *args)
            except Exception as exc:  # pragma: no cover - defensive fallback
                self._bridge_status = {"available": True, "mode": "fallback", "reason": str(exc)}

        if command == "computeCommitment":
            return _fallback_commitment(str(args[0]), str(args[1]))
        if command == "verifyCommitment":
            expected = _fallback_commitment(str(args[1]), str(args[2]))
            return str(args[0]) == expected
        if command == "merkleRoot":
            return _fallback_merkle_root(list(args[0]))
        if command == "generateMerkleProof":
            return _fallback_generate_merkle_proof(list(args[0]), int(args[1]))
        if command == "verifyMerkleProof":
            return _fallback_verify_merkle_proof(str(args[0]), list(args[1]), str(args[2]))
        if command == "deriveIdentityCommitment":
            return _fallback_commitment(str(args[0]), "identity:v1")
        if command == "deriveIdentityAuditHash":
            value = str(args[0])
            base_commitment = value if value.startswith("0x") else _fallback_commitment(value, "identity:v1")
            return _fallback_commitment(base_commitment, "audit:v1")
        if command == "redactIdentity":
            return f"redacted:{_fallback_commitment(str(args[0]), 'redact:v1')}"
        if command == "blsSign":
            return _fallback_bls_sign(str(args[0]), str(args[1]))
        if command == "blsVerify":
            return _fallback_bls_verify(dict(args[0]))
        if command == "blsAggregate":
            return _fallback_bls_aggregate(list(args[0]))
        if command == "qpaRunPrototype":
            params = dict(args[0])
            message = str(args[1])
            mode = str(args[2])
            shadow_count = int(args[3])
            return {
                "instance": {"id": "qpa-fallback-1", "params": params, "createdAt": "1970-01-01T00:00:00Z"},
                "pmhpInstance": {
                    "id": "pmhp-fallback-1",
                    "description": params.get("description"),
                    "primes": params.get("primes", []),
                    "partitionCount": params.get("partitionCount", 2),
                    "hyperedges": [],
                    "constraints": [],
                    "createdAt": "1970-01-01T00:00:00Z",
                },
                "state": {
                    "instance": {"id": "qpa-fallback-1", "params": params, "createdAt": "1970-01-01T00:00:00Z"},
                    "status": "committed",
                    "summary": {"note": "fallback qpa prototype result"},
                },
                "shadows": [
                    {"index": i, "basis": f"pauli-{i}", "outcome": _normalize_hex(_sha256_hex(str(params), str(i)))}
                    for i in range(shadow_count)
                ],
                "invariant": f"qpa-invariant-fallback:{message}",
                "commitment": {
                    "commitment": _normalize_hex(_sha256_hex(str(params), message, mode)),
                    "mode": mode,
                    "description": "fallback qpa prototype commitment",
                    "createdAt": "1970-01-01T00:00:00Z",
                },
                "evaluation": {
                    "assignment": [0] * len(params.get("primes", [])),
                    "cutCost": 0,
                    "constraintResiduals": [],
                    "totalResidual": 0,
                    "objective": 0,
                },
            }
        if command == "computeGapWitness":
            gap_lb = float(args[0])
            slope_ub = float(args[1])
            couplings = list(args[2])
            salt = str(args[3])
            payload = json.dumps({
                "gapLB": gap_lb,
                "slopeUB": slope_ub,
                "couplings": sorted(couplings, key=lambda x: x.get("prime", 0)),
                "version": "1.0.0",
                "engine": "multiplicity.qpa",
            }, sort_keys=True)
            return _fallback_commitment(payload, salt)

        if command == "getBridgeStatus":
            return self.getBridgeStatus()

        raise ValueError(f"Unknown bridge command: {command}")

    async def computeCommitment(self, leaf: str, salt: str) -> str:
        return str(self._call("computeCommitment", leaf, salt))

    async def verifyCommitment(self, commitment: str, leaf: str, salt: str) -> bool:
        return bool(self._call("verifyCommitment", commitment, leaf, salt))

    async def merkleRoot(self, leaves: List[str]) -> str:
        return str(self._call("merkleRoot", leaves))

    async def generateMerkleProof(self, leaves: List[str], leafIndex: int) -> Dict[str, Any]:
        result = self._call("generateMerkleProof", leaves, leafIndex)
        return dict(result)

    async def verifyMerkleProof(self, leaf: str, proof: List[str], root: str) -> bool:
        return bool(self._call("verifyMerkleProof", leaf, proof, root))

    async def deriveIdentityCommitment(self, input_str: str) -> str:
        return str(self._call("deriveIdentityCommitment", input_str))

    async def deriveIdentityAuditHash(self, input_str: str) -> str:
        return str(self._call("deriveIdentityAuditHash", input_str))

    async def redactIdentity(self, input_str: str) -> str:
        return str(self._call("redactIdentity", input_str))

    async def blsSign(self, private_key: str, message: str) -> Dict[str, Any]:
        result = self._call("blsSign", private_key, message)
        return dict(result)

    async def blsVerify(self, payload: Dict[str, Any]) -> bool:
        return bool(self._call("blsVerify", payload))

    async def blsAggregate(self, signatures: List[Dict[str, Any]]) -> str:
        return str(self._call("blsAggregate", signatures))

    async def qpaRunPrototype(
        self,
        params: Dict[str, Any],
        message: str,
        mode: str,
        shadow_count: int,
    ) -> Dict[str, Any]:
        result = self._call("qpaRunPrototype", params, message, mode, shadow_count)
        return dict(result)

    async def computeGapWitness(
        self,
        gap_lb: float,
        slope_ub: float,
        couplings: List[Dict[str, Any]],
        salt: str,
    ) -> str:
        return str(self._call("computeGapWitness", gap_lb, slope_ub, couplings, salt))

    async def compute_commitment(self, leaf: str, salt: str) -> str:
        return await self.computeCommitment(leaf, salt)

    async def verify_commitment(self, commitment: str, leaf: str, salt: str) -> bool:
        return await self.verifyCommitment(commitment, leaf, salt)

    async def merkle_root(self, leaves: List[str]) -> str:
        return await self.merkleRoot(leaves)

    async def generate_merkle_proof(self, leaves: List[str], leaf_index: int) -> Dict[str, Any]:
        return await self.generateMerkleProof(leaves, leaf_index)

    async def verify_merkle_proof(self, leaf: str, proof: List[str], root: str) -> bool:
        return await self.verifyMerkleProof(leaf, proof, root)

    async def derive_identity_commitment(self, input_str: str) -> str:
        return await self.deriveIdentityCommitment(input_str)

    async def derive_identity_audit_hash(self, input_str: str) -> str:
        return await self.deriveIdentityAuditHash(input_str)

    async def redact_identity(self, input_str: str) -> str:
        return await self.redactIdentity(input_str)

    async def compute_gap_witness(
        self,
        gap_lb: float,
        slope_ub: float,
        couplings: List[Dict[str, Any]],
        salt: str,
    ) -> str:
        return await self.computeGapWitness(gap_lb, slope_ub, couplings, salt)

    async def bls_sign(private_key: str, message: str) -> Dict[str, Any]:
        return await self.blsSign(private_key, message)

    async def bls_verify(payload: Dict[str, Any]) -> bool:
        return await self.blsVerify(payload)

    async def bls_aggregate(signatures: List[Dict[str, Any]]) -> str:
        return await self.blsAggregate(signatures)

    async def qpa_run_prototype(
        self,
        params: Dict[str, Any],
        message: str,
        mode: str = 'prototype',
        shadow_count: int = 8,
    ) -> Dict[str, Any]:
        return await self.qpaRunPrototype(params, message, mode, shadow_count)


_crypto_instance: Optional[MultiplicityCrypto] = None


def _get_crypto_instance() -> MultiplicityCrypto:
    global _crypto_instance
    if _crypto_instance is None:
        _crypto_instance = MultiplicityCrypto()
    return _crypto_instance


async def computeCommitment(leaf: str, salt: str) -> str:
    return await _get_crypto_instance().computeCommitment(leaf, salt)


async def verifyCommitment(commitment: str, leaf: str, salt: str) -> bool:
    return bool(await _get_crypto_instance().verifyCommitment(commitment, leaf, salt))


async def merkleRoot(leaves: List[str]) -> str:
    return str(await _get_crypto_instance().merkleRoot(leaves))


async def generateMerkleProof(leaves: List[str], leafIndex: int) -> Dict[str, Any]:
    result = await _get_crypto_instance().generateMerkleProof(leaves, leafIndex)
    return dict(result)


async def verifyMerkleProof(leaf: str, proof: List[str], root: str) -> bool:
    return bool(await _get_crypto_instance().verifyMerkleProof(leaf, proof, root))


async def deriveIdentityCommitment(input_str: str) -> str:
    return str(await _get_crypto_instance().deriveIdentityCommitment(input_str))


async def deriveIdentityAuditHash(input_str: str) -> str:
    return str(await _get_crypto_instance().deriveIdentityAuditHash(input_str))


async def redactIdentity(input_str: str) -> str:
    return str(await _get_crypto_instance().redactIdentity(input_str))


async def computeGapWitness(
    gap_lb: float,
    slope_ub: float,
    couplings: List[Dict[str, Any]],
    salt: str,
) -> str:
    return str(await _get_crypto_instance().computeGapWitness(gap_lb, slope_ub, couplings, salt))


async def blsSign(private_key: str, message: str) -> Dict[str, Any]:
    result = await _get_crypto_instance().blsSign(private_key, message)
    return dict(result)


async def blsVerify(payload: Dict[str, Any]) -> bool:
    return bool(await _get_crypto_instance().blsVerify(payload))


async def blsAggregate(signatures: List[Dict[str, Any]]) -> str:
    return str(await _get_crypto_instance().blsAggregate(signatures))


async def qpaRunPrototype(
    params: Dict[str, Any],
    message: str,
    mode: str = 'prototype',
    shadow_count: int = 8,
) -> Dict[str, Any]:
    return dict(await _get_crypto_instance().qpaRunPrototype(params, message, mode, shadow_count))


async def compute_commitment(leaf: str, salt: str) -> str:
    return await computeCommitment(leaf, salt)


async def verify_commitment(commitment: str, leaf: str, salt: str) -> bool:
    return await verifyCommitment(commitment, leaf, salt)


async def merkle_root(leaves: List[str]) -> str:
    return await merkleRoot(leaves)


async def generate_merkle_proof(leaves: List[str], leaf_index: int) -> Dict[str, Any]:
    return await generateMerkleProof(leaves, leaf_index)


async def verify_merkle_proof(leaf: str, proof: List[str], root: str) -> bool:
    return await verifyMerkleProof(leaf, proof, root)


async def derive_identity_commitment(input_str: str) -> str:
    return await deriveIdentityCommitment(input_str)


async def derive_identity_audit_hash(input_str: str) -> str:
    return await deriveIdentityAuditHash(input_str)


async def redact_identity(input_str: str) -> str:
    return await redactIdentity(input_str)


async def compute_gap_witness(
    gap_lb: float,
    slope_ub: float,
    couplings: List[Dict[str, Any]],
    salt: str,
) -> str:
    return await computeGapWitness(gap_lb, slope_ub, couplings, salt)


async def bls_sign(private_key: str, message: str) -> Dict[str, Any]:
    return await blsSign(private_key, message)


async def bls_verify(payload: Dict[str, Any]) -> bool:
    return await blsVerify(payload)


async def bls_aggregate(signatures: List[Dict[str, Any]]) -> str:
    return await blsAggregate(signatures)


async def qpa_run_prototype(
    params: Dict[str, Any],
    message: str,
    mode: str = 'prototype',
    shadow_count: int = 8,
) -> Dict[str, Any]:
    return await qpaRunPrototype(params, message, mode, shadow_count)


def getBridgeStatus() -> Dict[str, Any]:
    return _get_crypto_instance().getBridgeStatus()


__all__ = [
    "MultiplicityCrypto",
    "computeCommitment",
    "verifyCommitment",
    "merkleRoot",
    "generateMerkleProof",
    "verifyMerkleProof",
    "deriveIdentityCommitment",
    "deriveIdentityAuditHash",
    "redactIdentity",
    "computeGapWitness",
    "blsSign",
    "blsVerify",
    "blsAggregate",
    "qpaRunPrototype",
    "getBridgeStatus",
    "compute_commitment",
    "verify_commitment",
    "merkle_root",
    "generate_merkle_proof",
    "verify_merkle_proof",
    "derive_identity_commitment",
    "derive_identity_audit_hash",
    "redact_identity",
    "compute_gap_witness",
    "bls_sign",
    "bls_verify",
    "bls_aggregate",
    "qpa_run_prototype",
]
