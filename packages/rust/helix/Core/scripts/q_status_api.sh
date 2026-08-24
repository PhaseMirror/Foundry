#!/bin/bash
# Simple HTTP server to expose Q-state status
# Run this in background: ./scripts/q_status_api.sh &

PORT=8084
LOG_FILE="logs/quiescence/quiescence.log"

echo "🌐 Starting Q-State API on port $PORT"

while true; do
    echo -e "HTTP/1.1 200 OK\nContent-Type: application/json\n\n" | nc -l -p "$PORT" -q 1 | {
        read request
        # Get latest Q-state
        latest=$(tail -1 "$LOG_FILE" 2>/dev/null || echo '{"error": "No log file"}')
        
        # Get counts
        q1_count=$(grep -c '"state": "QUIESCENT"' "$LOG_FILE" 2>/dev/null || echo 0)
        q2_count=$(grep -c '"state": "LATTICE_LOCK"' "$LOG_FILE" 2>/dev/null || echo 0)
        
        # Create response
        cat << RESPONSE
{
  "status": "operational",
  "latest": $latest,
  "counts": {
    "q1": $q1_count,
    "q2": $q2_count
  },
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
RESPONSE
    }
done
