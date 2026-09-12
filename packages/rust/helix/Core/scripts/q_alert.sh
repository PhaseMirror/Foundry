#!/bin/bash
# Q-State Alerting System

LOG_FILE="logs/quiescence/quiescence.log"
ALERT_FILE="alerts/q_alerts_$(date +%Y%m%d).log"

mkdir -p alerts

check_q1_frequency() {
    # Count Q₁ events in last hour (should be ~20, since 3/min = 60/3 = 20)
    local q1_count=$(grep -c '"state": "QUIESCENT"' "$LOG_FILE" 2>/dev/null)
    local expected_min=15  # Allow some slack
    
    if [ "$q1_count" -lt "$expected_min" ]; then
        echo "🚨 ALERT: Low Q₁ frequency. Expected ≥$expected_min, got $q1_count" >> "$ALERT_FILE"
        echo "🚨 Q₁ frequency low"
        return 1
    fi
    return 0
}

check_recent_q2() {
    # Check if we've had a Q₂ in last 15 minutes
    local last_q2=$(grep '"state": "LATTICE_LOCK"' "$LOG_FILE" 2>/dev/null | tail -1)
    if [ -n "$last_q2" ]; then
        local timestamp=$(echo "$last_q2" | grep -o '"timestamp": "[^"]*"' | cut -d'"' -f4)
        local last_q2_sec=$(date -d "${timestamp}" +%s 2>/dev/null || echo 0)
        local now_sec=$(date +%s)
        local minutes_since=$(((now_sec - last_q2_sec) / 60))
        
        if [ "$minutes_since" -gt 15 ]; then
            echo "🚨 ALERT: No Q₂ for $minutes_since minutes" >> "$ALERT_FILE"
            echo "🚨 No recent Q₂"
            return 1
        fi
    else
        echo "🚨 ALERT: No Q₂ events recorded" >> "$ALERT_FILE"
        echo "🚨 No Q₂ events"
        return 1
    fi
    return 0
}

# Run checks
echo "🔍 Running Q-State Health Checks..."
check_q1_frequency
check_recent_q2

if [ $? -eq 0 ]; then
    echo "✅ All Q-State checks passed"
else
    echo "⚠️  Some checks failed. See $ALERT_FILE"
    cat "$ALERT_FILE" 2>/dev/null
fi
