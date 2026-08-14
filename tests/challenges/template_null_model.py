#!/usr/bin/env python3
"""
Zeta-ROS Null-Model Challenge Template

Implement your null model here. The script must accept the same data inputs
as the core ZMT kernel and output a JSON dictionary containing 'hs_norm_sq'
and 'max_error' (MAE).

Usage:
  python template_null_model.py --data ../data/prime_zeros_small.npz --output metrics.json
"""
import argparse
import json

def run_null_model(data_path: str) -> dict:
    # TODO: Implement your competitive null model here.
    # For example: a trivial random phase reconstructor, or a simpler PCA baseline.
    
    # Mocking a trivial failure:
    return {
        "hs_norm_sq": 0.0,
        "max_error": 1.5  # Much worse than the 0.00014 baseline
    }

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    
    metrics = run_null_model(args.data)
    
    with open(args.output, "w") as f:
        json.dump(metrics, f, indent=2)

if __name__ == "__main__":
    main()
