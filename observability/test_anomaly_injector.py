import asyncio
import json
import logging
import nats

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(message)s')

NATS_URL = "nats://localhost:4222"
TELEMETRY_SUBJECT = "uac.telemetry.run_data"
SIG_KILL_SUBJECT = "uac.gov.control.kill"

# 1. Nominal (Score > 0.0006)
PAYLOAD_NOMINAL = {
    "entropy": 5.2,
    "unstable_rate": 0.0,
    "utilization": 0.82,
    "d16_frac": 0.88,
    "thermal_slope": 0.01
}

# 2. Thermal Spike (Score < 0.0006)
PAYLOAD_THERMAL_SPIKE = {
    "entropy": 5.8,
    "unstable_rate": 0.0,
    "utilization": 0.94,
    "d16_frac": 0.78,
    "thermal_slope": 0.12
}

# 3. HSEC Entropy Breach
PAYLOAD_HSEC_BREACH = {
    "entropy": 6.5,
    "unstable_rate": 2.0,
    "utilization": 0.80,
    "d16_frac": 0.85,
    "thermal_slope": 0.01
}

async def run_injector():
    nc = await nats.connect(NATS_URL)
    logging.info(f"Connected to {NATS_URL}")

    # Listen for the kill signal to verify the electrical path
    kill_received = asyncio.Event()
    
    async def kill_handler(msg):
        data = json.loads(msg.data.decode())
        logging.critical(f"SUCCESS: Intercepted SIG_GOV_KILL! Reason: {data.get('reason')} | Score: {data.get('anomaly_score'):.3f}")
        kill_received.set()

    await nc.subscribe(SIG_KILL_SUBJECT, cb=kill_handler)
    logging.info(f"Subscribed to {SIG_KILL_SUBJECT} to monitor for breaker trips.")
    
    await asyncio.sleep(1)

    logging.info("\n--- Phase 1: Injecting Nominal Payload ---")
    await nc.publish(TELEMETRY_SUBJECT, json.dumps(PAYLOAD_NOMINAL).encode())
    await asyncio.sleep(2) # Give the monitor time to process
    
    logging.info("\n--- Phase 2: Injecting Thermal Spike ---")
    kill_received.clear()
    await nc.publish(TELEMETRY_SUBJECT, json.dumps(PAYLOAD_THERMAL_SPIKE).encode())
    try:
        await asyncio.wait_for(kill_received.wait(), timeout=3.0)
    except asyncio.TimeoutError:
        logging.error("FAILED: Did not receive SIG_GOV_KILL for Thermal Spike.")

    logging.info("\n--- Phase 3: Injecting HSEC Entropy Breach ---")
    kill_received.clear()
    await nc.publish(TELEMETRY_SUBJECT, json.dumps(PAYLOAD_HSEC_BREACH).encode())
    try:
        await asyncio.wait_for(kill_received.wait(), timeout=3.0)
    except asyncio.TimeoutError:
        logging.error("FAILED: Did not receive SIG_GOV_KILL for HSEC Breach.")

    logging.info("\nInjection testing complete. Closing connection.")
    await nc.close()

if __name__ == '__main__':
    asyncio.run(run_injector())
