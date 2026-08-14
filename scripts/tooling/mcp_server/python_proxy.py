#!/usr/bin/env python3
import sys
import json
import os
import traceback
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey

def verify_sat(sat_token: dict, pub_key_hex: str) -> bool:
    try:
        # Clone token to mutate
        token_copy = dict(sat_token)
        signature_hex = token_copy.pop("signature", "")
        
        # Recreate canonical payload
        payload = json.dumps(token_copy, separators=(',', ':'), sort_keys=True)
        
        # Verify signature
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

    for line in sys.stdin:
        if not line.strip():
            continue
            
        try:
            req = json.loads(line)
            req_id = req.get("id")
            method = req.get("method")
            params = req.get("params", {})
            
            if method == "initialize":
                res = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "protocolVersion": "2024-11-05",
                        "capabilities": {},
                        "serverInfo": {"name": "python-policy-proxy", "version": "1.0.0"}
                    }
                }
                print(json.dumps(res), flush=True)
                
            elif method == "notifications/initialized":
                pass
                
            elif method == "tools/list":
                res = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {
                        "tools": [
                            {
                                "name": "proxied_tool",
                                "description": "A proxied tool",
                                "inputSchema": {
                                    "type": "object",
                                    "properties": {}
                                }
                            }
                        ]
                    }
                }
                print(json.dumps(res), flush=True)
                
            elif method == "tools/call":
                name = params.get("name")
                args = params.get("arguments", {})
                
                _sat = args.get("_sat")
                if not _sat:
                    error_res = {
                        "jsonrpc": "2.0",
                        "id": req_id,
                        "error": {"code": -32602, "message": "Missing _sat in arguments. Policy proxy requires an In-band SAT."}
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
                
                # If SAT is valid, we would normally delegate. Here we mock success.
                # Remove _sat before passing to actual tool
                clean_args = {k: v for k, v in args.items() if k != "_sat"}
                
                # Mock tool execution
                tool_result = {
                    "content": [
                        {"type": "text", "text": f"Successfully executed {name} through policy proxy!"}
                    ],
                    "isError": False
                }
                
                res = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": tool_result
                }
                print(json.dumps(res), flush=True)
                
        except Exception as e:
            print(f"Error handling request: {e}", file=sys.stderr)
            traceback.print_exc(file=sys.stderr)

if __name__ == "__main__":
    main()
