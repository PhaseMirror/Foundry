"""Cryptographic Provenance Ledger and SHA-256 state signatures."""

import hashlib
import struct
from dataclasses import dataclass, field
from .cascade import PrismTensorState
from .firewall import firewall_gate, compute_ethical_metric

@dataclass
class ProvenanceBlock:
    time: int
    state_hash: str
    previous_hash: str
    ethical_metric: float
    was_collapsed: bool
    timestamp_epoch: int

@dataclass
class ProvenanceLedger:
    blocks: list[ProvenanceBlock] = field(default_factory=list)

    @staticmethod
    def hash_state(st: PrismTensorState, prev_hash: str) -> str:
        h = hashlib.sha256()
        h.update(struct.pack(">Q", st.time))
        h.update(struct.pack(">d", st.lambda_m))
        h.update(prev_hash.encode("utf-8"))

        for n in st.nodes:
            h.update(struct.pack(">Q", n.prime))
            h.update(struct.pack(">d", n.weight))
            h.update(struct.pack(">d", n.phase))
            h.update(struct.pack(">d", n.energy))

        return h.hexdigest()

    def record_state(self, st: PrismTensorState) -> ProvenanceBlock:
        safe_st, was_collapsed = firewall_gate(st)
        metric = compute_ethical_metric(safe_st)
        prev_hash = self.blocks[-1].state_hash if self.blocks else "0" * 64
        state_hash = self.hash_state(safe_st, prev_hash)

        block = ProvenanceBlock(
            time=safe_st.time,
            state_hash=state_hash,
            previous_hash=prev_hash,
            ethical_metric=metric,
            was_collapsed=was_collapsed,
            timestamp_epoch=1724774400 + safe_st.time * 60,
        )
        self.blocks.append(block)
        return block

    def verify_chain_integrity(self) -> bool:
        for i in range(1, len(self.blocks)):
            if self.blocks[i].previous_hash != self.blocks[i - 1].state_hash:
                return False
        return True
