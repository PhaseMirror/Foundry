#!/usr/bin/env python3
import sys
import json
import os
import traceback
import subprocess
import threading
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey

def verify_sat(sat_token: dict, pub_key_hex: str) -> bool:
    try:
        token_copy = dict(sat_token)
        signature_hex = token_copy.pop("signature", "")
        payload = json.dumps(token_copy, separators=(',', ':'), sort_keys=True)
        public_key = Ed25519PublicKey.from_public_bytes(bytes.fromhex(pub_key_hex))
        public_key.verify(bytes.fromhex(signature_hex), payload.encode('utf-8'))
        return True
    except Exception as e:
        print(f"SAT verification failed: {e}", file=sys.stderr)
        return False

def main():
    pub_key_hex = os.environ.get("COMMANDER_SAT_PUBLIC_KEY")
    if not pub_key_hex:
        print("COMMANDER_SAT_PUBLIC_KEY environment variable is required", file=sys.stderr)
        sys.exit(1)

    # Start the actual github mcp server as a subprocess
    github_process = subprocess.Popen(
        ["npx", "-y", "@modelcontextprotocol/server-github"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=sys.stderr,
        text=True,
        bufsize=1
    )

    # Thread to forward stdout from github server to our stdout
    def forward_stdout():
        for line in github_process.stdout:
            sys.stdout.write(line)
            sys.stdout.flush()

    threading.Thread(target=forward_stdout, daemon=True).start()

    # Read stdin and intercept calls to verify SAT
    for line in sys.stdin:
        if not line.strip():
            continue
            
        try:
            req = json.loads(line)
            req_id = req.get("id")
            method = req.get("method")
            params = req.get("params", {})
            
            if method == "tools/call":
                args = params.get("arguments", {})
                
                _sat = args.get("_sat")
                if not _sat:
                    error_res = {
                        "jsonrpc": "2.0",
                        "id": req_id,
                        "error": {"code": -32602, "message": "Missing _sat in arguments. GitHub Adapter requires an In-band SAT."}
                    }
                    print(json.dumps(error_res), flush=True)
                    continue
                
                if not verify_sat(_sat, pub_key_hex):
                    error_res = {
                        "jsonrpc": "2.0",
                        "id": req_id,
                        "error": {"code": -32602, "message": "Invalid _sat signature. Access denied."}
                    }
                    print(json.dumps(error_res), flush=True)
                    continue
                
                # Strip _sat before forwarding
                clean_args = {k: v for k, v in args.items() if k != "_sat"}
                req["params"]["arguments"] = clean_args
                
                # Forward to github process
                github_process.stdin.write(json.dumps(req) + "\n")
                github_process.stdin.flush()
            else:
                # Forward other requests normally
                github_process.stdin.write(line)
                github_process.stdin.flush()
                
        except Exception as e:
            print(f"Error handling request: {e}", file=sys.stderr)
            traceback.print_exc(file=sys.stderr)

if __name__ == "__main__":
    main()
