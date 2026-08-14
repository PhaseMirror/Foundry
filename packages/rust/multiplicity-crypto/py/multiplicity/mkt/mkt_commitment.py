"""ADR-104 Phase 0: Multiplicity-Based Commitment (MBC) prototype scaffold."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from typing import Iterable, List, Tuple

from multiplicity.mkt.mkt_colored_braid import BraidWord
from multiplicity.mkt.mkt_constants_estimation import c0_of_x, z_of_x
from multiplicity.mkt.mkt_invariant import p_of_braid_x


@dataclass(frozen=True)
class Commitment:
    digest: str
    invariant_vector: Tuple[float, ...]


@dataclass(frozen=True)
class OpeningData:
    message: str
    braid_serialized: str


def setup(cutoffs: Iterable[int] = (100, 1000)) -> dict:
    xs = tuple(sorted(set(int(x) for x in cutoffs if int(x) > 1)))
    return {"cutoffs": xs, "hash": "sha256", "version": "mbc_phase0"}


def _serialize_commit_payload(message: str, braid: BraidWord) -> bytes:
    payload = {
        "message": message,
        "braid": braid.serialize(),
    }
    return json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")


def commit(pp: dict, message: str, braid: BraidWord) -> tuple[Commitment, OpeningData]:
    payload = _serialize_commit_payload(message, braid)
    digest = hashlib.sha256(payload).hexdigest()

    vector: List[float] = []
    for x in pp["cutoffs"]:
        c0_x = c0_of_x(x)
        z_x = z_of_x(x)
        vector.append(p_of_braid_x(braid, x_cutoff=x, c0_x=c0_x, z_x=z_x))

    return (
        Commitment(digest=digest, invariant_vector=tuple(vector)),
        OpeningData(message=message, braid_serialized=braid.serialize()),
    )


def open_commitment(pp: dict, commitment: Commitment, message: str, opening: OpeningData) -> bool:
    if message != opening.message:
        return False

    braid = _deserialize_braid(opening.braid_serialized)
    recomputed, _ = commit(pp, message, braid)
    return (
        recomputed.digest == commitment.digest
        and recomputed.invariant_vector == commitment.invariant_vector
    )


def _deserialize_braid(serialized: str) -> BraidWord:
    if not serialized:
        return BraidWord(())
    items = []
    for token in serialized.split(";"):
        left, right = token.split(":", 1)
        items.append((int(left), int(right)))
    return BraidWord(tuple(items))
