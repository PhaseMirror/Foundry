#!/usr/bin/env python3
"""
Integration test for VQC anomaly sidecar + orchestrator.
"""

import asyncio
import json
import random
import time
from nats.aio.client import Client as NATS

async def run_test():
    nc = NATS()
    await nc.connect(["nats://localhost:4222"])

    # Subscribe to anomaly scores and governance logs
    async def anomaly_handler(msg):
        data = json.loads(msg.data.decode())
        print(f"[VQC] score={data['anomaly_score']:.3f}, trigger={data['trigger']}")

    async def governance_handler(msg):
        data = json.loads(msg.data.decode())
        if "VQC_ANOMALY_DETECTED" in str(data):
            print(f"[Governance] VQC kill event: {data}")

    await nc.subscribe("uac.predict.anomaly", cb=anomaly_handler)
    await nc.subscribe("uac.state.governance", cb=governance_handler)

    # Generate synthetic telemetry: mix normal and anomalous
    for i in range(50):
        # Alternate between normal and anomalous every 10 steps
        if i % 10 < 7:
            # Normal
            entropy = 5.4 + random.gauss(0, 0.1)
            unstable = 0.0
            util = 0.84 + random.gauss(0, 0.02)
            d16 = 0.87 + random.gauss(0, 0.02)
            slope = 0.0 + random.gauss(0, 0.01)
        else:
            # Anomalous: high entropy, unstable, high util
            entropy = 6.2 + random.gauss(0, 0.1)
            unstable = 0.5 + random.gauss(0, 0.1)
            util = 0.92 + random.gauss(0, 0.02)
            d16 = 0.75 + random.gauss(0, 0.05)
            slope = 0.1 + random.gauss(0, 0.02)

        telemetry = {
            "timestamp": int(time.time()),
            "entropy": entropy,
            "unstable_rate": unstable,
            "utilization": util,
            "d16_frac": d16,
            "thermal_slope": slope,
        }
        await nc.publish("uac.telemetry.fpga", json.dumps(telemetry).encode())
        print(f"[Publish] entropy={entropy:.2f}, unstable={unstable:.2f}")
        await asyncio.sleep(0.1)  # fast for test

    # Wait for scores and governance events
    await asyncio.sleep(2)
    await nc.close()

if __name__ == "__main__":
    asyncio.run(run_test())
