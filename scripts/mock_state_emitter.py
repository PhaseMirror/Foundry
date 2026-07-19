#!/usr/bin/env python3
"""mock_state_emitter.py -- emit mock UAC state events for ADR-PML-055 tests.

For each category it publishes a JSON event to `uac.state.<category>` on NATS
(best-effort; skipped if no server is reachable) AND appends the same event
to a WORM JSONL log. The WORM log is what `scripts/verify_anchor.py`
consumes, so the offline integration test works without a live NATS/EVM.

Each emitted record carries:
  - `category`  : one of governance/orchestrator/chemistry/proofs/attestations
  - `hash`      : SHA-256 of the canonical JSON payload (used by the verifier)
  - `burst_id` / `event_id` : traceability
"""
from __future__ import annotations

import argparse
import asyncio
import json
import logging
import random
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from anchor_math import sha256  # type: ignore

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger("emitter")

CATEGORIES = {
    "governance": lambda: {
        "anomaly_score": round(random.uniform(-0.1, 0.1), 4),
        "entropy": round(random.uniform(4.5, 6.0), 2),
        "unstable_count": random.randint(0, 2),
        "sig_gov_kill": False,
    },
    "orchestrator": lambda: {
        "d16_frac": round(random.uniform(0.75, 0.92), 3),
        "utilization": round(random.uniform(0.65, 0.89), 3),
        "thermal_slope": round(random.uniform(-0.05, 0.05), 4),
        "active_sessions": random.randint(90, 100),
    },
    "chemistry": lambda: {
        "molecule": random.choice(["FeMoco", "P-cluster", "MoFe", "VFe"]),
        "cas": "20200",
        "entropy_analysis": round(random.uniform(0.1, 0.5), 3),
        "reduction_error": round(random.uniform(0.001, 0.005), 4),
    },
    "proofs": lambda: {
        "commit_sha": "a" * 40,
        "new_theorem_count": random.randint(0, 3),
        "sorry_manifest_hash": "b" * 64,
    },
    "attestations": lambda: {
        "batch_count": random.randint(5, 20),
        "merkle_root": "c" * 64,
        "total_runs": random.randint(50, 150),
    },
}


def make_record(category: str, burst: int) -> dict:
    payload = CATEGORIES[category]()
    payload["timestamp"] = datetime.now(timezone.utc).isoformat()
    payload["burst_id"] = burst
    payload["event_id"] = f"{category}-{burst}-{random.randint(1000, 9999)}"
    rec = {
        "category": category,
        "hash": "0x" + sha256(json.dumps(payload, sort_keys=True).encode()).hex(),
        "burst_id": burst,
        "event_id": payload["event_id"],
    }
    return rec


async def publish_nats(nats_url: str, prefix: str, records: list[dict]) -> None:
    try:
        import logging as _logging
        from nats.aio.client import Client as Nats  # type: ignore
        _logging.getLogger("nats").setLevel(_logging.CRITICAL)
    except Exception:
        logger.info("  (nats-py not installed; skipping NATS publish)")
        return
    try:
        nc = Nats()
        await asyncio.wait_for(nc.connect(servers=[nats_url]), timeout=2.0)
    except Exception as exc:
        logger.info(f"  (NATS unreachable at {nats_url}; skipping publish)")
        return
    for rec in records:
        subject = f"{prefix}.{rec['category']}"
        await nc.publish(subject, json.dumps(rec).encode())
        logger.info(f"  -> nats {subject}: {rec['event_id']}")
    await nc.close()


async def main() -> None:
    ap = argparse.ArgumentParser(description="Mock UAC state event emitter (ADR-PML-055)")
    ap.add_argument("--nats-url", default="nats://localhost:4222")
    ap.add_argument("--subject-prefix", default="uac.state")
    ap.add_argument("--count", type=int, default=3)
    ap.add_argument("--delay", type=float, default=0.2)
    ap.add_argument("--worm-log", default="mock_events.log",
                   help="WORM JSONL path the verifier consumes.")
    args = ap.parse_args()

    worm_path = Path(args.worm_log)
    all_records: list[dict] = []
    for i in range(1, args.count + 1):
        logger.info(f"Emitting burst {i}/{args.count}")
        burst = [make_record(cat, i) for cat in CATEGORIES]
        all_records.extend(burst)
        with worm_path.open("a") as fh:
            for rec in burst:
                fh.write(json.dumps(rec) + "\n")
        await publish_nats(args.nats_url, args.subject_prefix, burst)
        if i < args.count:
            await asyncio.sleep(args.delay)
    logger.info(f"Wrote {len(all_records)} events to {worm_path}")


if __name__ == "__main__":
    asyncio.run(main())
