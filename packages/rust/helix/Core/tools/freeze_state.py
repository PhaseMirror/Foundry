#!/usr/bin/env python3
"""
HELIX-TTD: EXPERIMENTAL FREEZE TOOL
-----------------------------------
Generates a cryptographic manifest of the experiment state.
Captures: Git Commit, File Hashes, and Configuration Parameters.
"""

import hashlib
import json
import subprocess
import os
from datetime import datetime, timezone

# CONFIGURATION TO LOCK
EXPERIMENTAL_CONFIG = {
    "temperature": 0.7,
    "top_p": 0.9,
    "frequency_penalty": 0.0,
    "presence_penalty": 0.0,
    "max_tokens": 1024,
    "seeds": [42, 1337, 2026],
    "models": ["claude-3-5-sonnet-20240620", "gpt-4o-2024-05-13", "deepseek-coder-v2"]
}

def get_git_sha():
    try:
        return subprocess.check_output(["git", "rev-parse", "HEAD"]).strip().decode('utf-8')
    except:
        return "UNKNOWN_GIT_SHA"

def hash_file(filepath):
    """SHA256 hash of a file's content."""
    if not os.path.exists(filepath):
        return "MISSING_FILE"
    
    sha256 = hashlib.sha256()
    with open(filepath, 'rb') as f:
        while chunk := f.read(8192):
            sha256.update(chunk)
    return sha256.hexdigest()

def main():
    print("🥶 INITIATING CRYPTOGRAPHIC FREEZE...")
    
    manifest = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "git_commit": get_git_sha(),
        "config": EXPERIMENTAL_CONFIG,
        "artifacts": {
            # The Law
            "council_charter": hash_file("governance/COUNCIL_CHARTER.md"),
            # The Science
            "doctrine_01": hash_file("governance/DOCTRINE_01_SHARED_PRIMITIVES.md"),
            "protocol_spec": hash_file("governance/RUNTIME_ASSURANCE_SPEC.md"),
            # The Data
            "ambiguity_corpus": hash_file("research/data/ambiguity_corpus_v1.json"),
            # The Machinery
            "corpus_generator": hash_file("research/corpus_generator.py"),
            "monitor_script": hash_file("quiescence_monitor/monitor.py")
        },
        "signatures": {
            "pi": "Stephen Hope (ORCID: 0009-0000-7367-248X)",
            "status": "LOCKED"
        }
    }
    
    # Save the Manifest
    os.makedirs("research", exist_ok=True)
    outfile = "research/FREEZE_MANIFEST.json"
    
    with open(outfile, "w") as f:
        json.dump(manifest, f, indent=2)
        
    print(f"✅ STATE FROZEN: {outfile}")
    print(f"   Git SHA: {manifest['git_commit']}")
    print(f"   Corpus Hash: {manifest['artifacts']['ambiguity_corpus'][:16]}...")

if __name__ == "__main__":
    main()
