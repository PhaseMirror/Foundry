#!/usr/bin/env python3
"""
Integration test for LSTM predictive thermal sidecar + orchestrator.
Publishes synthetic telemetry to NATS and listens for forecasts/throttling.
"""

import asyncio
import json
import random
import time
from datetime import datetime, timedelta
import nats
import numpy as np

async def run_test():
    nc = await nats.connect("nats://localhost:4222")

    # Subscribe to forecasts
    async def forecast_handler(msg):
        data = json.loads(msg.data.decode())
        print(f"[Forecast] {data}")

    async def governance_handler(msg):
        data = json.loads(msg.data.decode())
        if "thermal_throttle" in data.get("event_type", ""):
            print(f"[Governance] Throttle event: {data}")

    await nc.subscribe("uac.predict.thermal", cb=forecast_handler)
    await nc.subscribe("uac.state.governance", cb=governance_handler)

    # Generate synthetic telemetry for 35 points at 0.1s intervals to test quickly
    # Include a ramp up to high utilization
    base_util = 0.70
    for i in range(35):
        # Simulate a gradual increase
        util = base_util + 0.02 * i
        if util > 0.95:
            util = 0.95
        # Add random noise
        util += random.gauss(0, 0.01)
        util = max(0.5, min(0.98, util))

        # Create telemetry point
        now = datetime.utcnow()
        telemetry = {
            "timestamp": int(now.timestamp()),
            "utilization": util,
            "error_rate": 0.005 + random.random() * 0.01,
            "session_count": 95 + random.randint(-5, 5),
            "thermal_slope": (util - 0.70) / (i+1) if i > 0 else 0.0,
            "hour_sin": np.sin(2 * np.pi * now.hour / 24),
            "hour_cos": np.cos(2 * np.pi * now.hour / 24),
            "dow_sin": np.sin(2 * np.pi * now.weekday() / 7),
            "dow_cos": np.cos(2 * np.pi * now.weekday() / 7),
        }
        await nc.publish("uac.telemetry.fpga", json.dumps(telemetry).encode())
        print(f"[Publish] util={util:.3f}")

        await asyncio.sleep(0.1)

    # Wait a bit for forecasts to be processed
    await asyncio.sleep(10)
    await nc.close()

if __name__ == "__main__":
    asyncio.run(run_test())
