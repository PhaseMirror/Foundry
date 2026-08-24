#!/bin/bash
# Q-State Decision Gate for Federation Operations - FIXED VERSION

LOG_FILE="logs/quiescence/quiescence.log"
REQUIRED_STATE="$1"
OPERATION="$2"
TIMEOUT="${3:-300}"

echo "🔒 Q-Gate: Checking for $REQUIRED_STATE to authorize: $OPERATION"

# State mapping
declare -A STATE_DESCRIPTIONS
STATE_DESCRIPTIONS["QUIESCENT"]="Q₁: Zero drift, all models aligned"
STATE_DESCRIPTIONS["LATTICE_LOCK"]="Q₂: Structural harmony, complementarity ≥ 0.92"
STATE_DESCRIPTIONS["ANCHOR_STRIKE"]="Q₃: External anchor, confidence ≥ 0.95"
STATE_DESCRIPTIONS["CONSENSUS_BLOOM"]="Q₄: Independent convergence ≥ 95%"

# Check for recent state - FIXED TO HANDLE JSON SPACES
check_state() {
    local state="$1"
    local timeout="$2"
    local start_time=$(date +%s)
    
    while [ $(($(date +%s) - start_time)) -lt $timeout ]; do
        # Use jq if available (better JSON parsing)
        if command -v jq &> /dev/null; then
            if tail -20 "$LOG_FILE" 2>/dev/null | jq -r '.state' 2>/dev/null | grep -q "$state"; then
                local last_event=$(tail -20 "$LOG_FILE" | jq -r "select(.state==\"$state\")" | tail -1)
                local timestamp=$(echo "$last_event" | jq -r '.timestamp')
                echo "✅ $REQUIRED_STATE detected at $timestamp"
                echo "   ${STATE_DESCRIPTIONS[$state]}"
                return 0
            fi
        else
            # Fallback: grep with flexible spacing
            if tail -20 "$LOG_FILE" 2>/dev/null | grep -E "\"state\":[[:space:]]*\"$state\"" > /dev/null; then
                local last_event=$(grep -E "\"state\":[[:space:]]*\"$state\"" "$LOG_FILE" | tail -1)
                # Extract timestamp (handles spaces)
                local timestamp=$(echo "$last_event" | grep -o '"timestamp":[[:space:]]*"[^"]*"' | sed -E 's/"timestamp":[[:space:]]*"([^"]*)"/\1/')
                echo "✅ $REQUIRED_STATE detected at $timestamp"
                echo "   ${STATE_DESCRIPTIONS[$state]}"
                return 0
            fi
        fi
        
        local time_left=$((timeout - ($(date +%s) - start_time)))
        echo "⏳ Waiting for $state... (${time_left}s remaining)"
        sleep 10
    done
    
    echo "❌ $REQUIRED_STATE not detected within ${TIMEOUT}s timeout"
    return 1
}

case "$REQUIRED_STATE" in
    Q1|Q₁|QUIESCENT)
        check_state "QUIESCENT" "$TIMEOUT"
        ;;
    Q2|Q₂|LATTICE_LOCK)
        check_state "LATTICE_LOCK" "$TIMEOUT"
        ;;
    Q3|Q₃|ANCHOR_STRIKE)
        check_state "ANCHOR_STRIKE" "$TIMEOUT"
        ;;
    Q4|Q₄|CONSENSUS_BLOOM)
        check_state "CONSENSUS_BLOOM" "$TIMEOUT"
        ;;
    *)
        echo "Unknown state: $REQUIRED_STATE"
        echo "Valid: Q1, Q2, Q3, Q4 (or full state names)"
        exit 1
        ;;
esac

if [ $? -eq 0 ]; then
    echo "🟢 Authorizing: $OPERATION"
    exit 0
else
    echo "🔴 Denied: $OPERATION requires $REQUIRED_STATE"
    exit 1
fi
