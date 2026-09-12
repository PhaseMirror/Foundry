#!/bin/bash
# Health check based on quiescence states

LOG_FILE="logs/quiescence/quiescence.log"
HEALTHY=true
MESSAGE=""

# Check if monitor is running
if ! docker ps --format "{{.Names}}" | grep -q "quiescence"; then
    HEALTHY=false
    MESSAGE="Quiescence monitor not running"
fi

# Check if logs are being written
if [ ! -f "$LOG_FILE" ]; then
    HEALTHY=false
    MESSAGE="No quiescence logs found"
else
    # Check last Q₁ time
    LAST_Q1=$(grep '"state":"QUIESCENT"' "$LOG_FILE" | tail -1 | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
    if [ -n "$LAST_Q1" ]; then
        LAST_Q1_SEC=$(date -d "$LAST_Q1" +%s 2>/dev/null || echo 0)
        NOW_SEC=$(date +%s)
        SEC_SINCE_Q1=$((NOW_SEC - LAST_Q1_SEC))
        
        if [ $SEC_SINCE_Q1 -gt 300 ]; then  # 5 minutes
            HEALTHY=false
            MESSAGE="No Q₁ for $((SEC_SINCE_Q1/60)) minutes"
        fi
    else
        HEALTHY=false
        MESSAGE="No Q₁ events recorded"
    fi
fi

if $HEALTHY; then
    echo "✅ HEALTHY: Quiescence monitoring operational"
    echo "   Last Q₁: $LAST_Q1"
    exit 0
else
    echo "❌ UNHEALTHY: $MESSAGE"
    exit 1
fi
