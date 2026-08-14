#!/usr/bin/env python3
"""
exporter.py – Prometheus metrics endpoint for the Zeta-ROS lattice.
Exposes HS‑norm squared, reconstruction MAE, last proof timestamp,
and data freshness. Run with: python exporter.py --port 8000
"""
import time, json, argparse
from pathlib import Path
from prometheus_client import start_http_server, Gauge

parser = argparse.ArgumentParser()
parser.add_argument('--port', type=int, default=8000)
parser.add_argument('--metrics-file', default='benchmarks/metrics.json')
parser.add_argument('--proof-status-file', default='artifacts/proof_status.json')
args = parser.parse_args()

hs_norm_sq = Gauge('zmt_hs_norm_squared',
                   'Hilbert‑Schmidt norm squared of the ZMT bridge kernel')
reconstruction_mae = Gauge('zmt_reconstruction_mae',
                           'Mean absolute error of ZMT reconstruction')
proof_timestamp = Gauge('zmt_proof_timestamp_seconds',
                        'Timestamp of last successful Lean proof')
data_freshness = Gauge('zmt_data_freshness_seconds',
                       'Time since last data pull')

def update_metrics():
    if Path(args.metrics_file).exists():
        data = json.loads(Path(args.metrics_file).read_text())
        hs = data.get('dense', {}).get('hs_norm_sq', 0.0)
        mae = data.get('dense', {}).get('max_error', 0.0)
        hs_norm_sq.set(hs)
        reconstruction_mae.set(mae if mae is not None else 0.0)
        data_freshness.set(time.time() - Path(args.metrics_file).stat().st_mtime)
    if Path(args.proof_status_file).exists():
        proof = json.loads(Path(args.proof_status_file).read_text())
        proof_timestamp.set(proof.get('timestamp', 0.0))

if __name__ == '__main__':
    start_http_server(args.port)
    print(f'Exporter listening on :{args.port}/metrics')
    while True:
        update_metrics()
        time.sleep(15)
