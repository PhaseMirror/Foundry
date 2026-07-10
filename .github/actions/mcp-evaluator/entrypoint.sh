#!/usr/bin/env bash
set -euo pipefail

# Start the MCP server in the background
pscmd mcp --listen 127.0.0.1:8080 &
MCP_PID=$!

# Wait for the server to be ready (ping)
MAX_RETRIES=30
RETRY_DELAY=1
for i in $(seq 1 $MAX_RETRIES); do
    if echo '{"jsonrpc":"2.0","id":1,"method":"ping"}' | nc -N 127.0.0.1 8080 | grep -q '"result":"pong"'; then
        echo "MCP server is ready."
        break
    fi
    echo "Waiting for MCP server... ($i/$MAX_RETRIES)"
    sleep $RETRY_DELAY
    if [ $i -eq $MAX_RETRIES ]; then
        echo "MCP server failed to start."
        kill $MCP_PID
        exit 1
    fi
done

# Export connection details for the Python client
export MCP_HOST=127.0.0.1
export MCP_PORT=8080

# Run the evaluation script
python3 /app/evaluate.py
RESULT=$?

# Shut down the MCP server
kill $MCP_PID || true
wait $MCP_PID 2>/dev/null || true

exit $RESULT
