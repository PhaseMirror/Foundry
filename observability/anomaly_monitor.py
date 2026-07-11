import os
import asyncio
import json
import logging
from collections import deque
import numpy as np
from sklearn.ensemble import IsolationForest
from joblib import load
import nats
from nats.errors import ConnectionClosedError, TimeoutError, NoServersError

# Setup Observability Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("AnomalyMonitor")

# --- Configuration & Tuning Parameters ---
NATS_URL = "nats://localhost:4222"
TELEMETRY_SUBJECT = "uac.telemetry.run_data"
SIG_KILL_SUBJECT = "uac.gov.control.kill"

WINDOW_SIZE = 100  # Number of recent runs to keep in the rolling window
ANOMALY_THRESHOLD = float(os.getenv("ANOMALY_GOV_THRESHOLD", 0.0006))
CONTAMINATION = 0.01 # Expected proportion of outliers in the data

class ObservabilitySentinel:
    def __init__(self):
        self.nc = None
        self.window = deque(maxlen=WINDOW_SIZE)
        # Load the calibrated model
        self.model = load('observability/anomaly_model.pkl')
        logger.info("Isolation Forest loaded from observability/anomaly_model.pkl.")

    async def connect(self):
        try:
            self.nc = await nats.connect(NATS_URL)
            logger.info(f"Connected to NATS at {NATS_URL}")
        except NoServersError as e:
            logger.error(f"Failed to connect to NATS: {e}")
            raise

    async def trigger_sig_gov_kill(self, anomaly_score, run_data):
        """Executes the fatal L0 halt when a severe anomaly is detected."""
        payload = {
            "signal": "SIG_GOV_KILL",
            "reason": "AI_ANOMALY_DETECTED",
            "severity": "CRITICAL",
            "anomaly_score": float(anomaly_score),
            "trigger_data": run_data
        }
        logger.critical(f"TRIGGERING SIG_GOV_KILL! Score: {anomaly_score:.3f} Data: {run_data}")
        await self.nc.publish(SIG_KILL_SUBJECT, json.dumps(payload).encode())

    async def message_handler(self, msg):
        """Processes incoming OTel telemetry runs."""
        try:
            data = json.loads(msg.data.decode())
            
            # Extract Features
            entropy = float(data.get("entropy", 5.4))
            unstable_rate = float(data.get("unstable_rate", 0.0))
            utilization = float(data.get("utilization", 0.84))
            d16_frac = float(data.get("d16_frac", 0.87))
            thermal_slope = float(data.get("thermal_slope", 0.0))
            
            feature_vector = [entropy, unstable_rate, utilization, d16_frac, thermal_slope]
            
            # Online Anomaly Scoring
            score = self.model.decision_function([feature_vector])[0]
            
            if score < ANOMALY_THRESHOLD:
                logger.warning(f"Anomaly detected! Score: {score:.3f} | Features: {feature_vector}")
                await self.trigger_sig_gov_kill(score, data)
            else:
                logger.debug(f"Run healthy. Score: {score:.3f}")
                
            # Update the sliding window
            self.window.append(feature_vector)
            
            # removed window refitting to maintain strict model versioning
            pass
                
        except json.JSONDecodeError:
            logger.error("Failed to decode telemetry JSON.")
        except Exception as e:
            logger.error(f"Error processing message: {e}")

    async def run(self):
        await self.connect()
        sub = await self.nc.subscribe(TELEMETRY_SUBJECT, cb=self.message_handler)
        logger.info(f"Listening for telemetry on {TELEMETRY_SUBJECT}...")
        
        # Keep the event loop running
        while True:
            await asyncio.sleep(1)

if __name__ == '__main__':
    sentinel = ObservabilitySentinel()
    asyncio.run(sentinel.run())
