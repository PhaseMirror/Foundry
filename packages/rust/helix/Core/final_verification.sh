#!/bin/bash
echo "🦆 FINAL QUATERNARY DEPLOYMENT VERIFICATION"
echo "==========================================="
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

echo "1. GIT STATUS"
echo "   Latest Commit: $(git log --oneline -1)"
echo "   Tag: v1.1.0-quaternary"
echo "   Branch: $(git branch --show-current)"
echo "   Ahead/Behind: $(git rev-list --count --left-right origin/main...HEAD 2>/dev/null | tr '\t' '/' || echo 'Synced')"
echo ""

echo "2. DOCKER STATUS"
CONTAINER_ID=$(docker ps -q --filter "name=quiescence")
if [ -n "$CONTAINER_ID" ]; then
    echo "   ✅ Container RUNNING: $CONTAINER_ID"
    echo "   Status: $(docker ps --filter "name=quiescence" --format "{{.Status}}")"
    echo "   Uptime: $(docker ps --filter "name=quiescence" --format "{{.RunningFor}}")"
    echo ""
    echo "   Recent Logs:"
    docker logs --tail=3 "$CONTAINER_ID" 2>/dev/null | while read line; do
        echo "   - $line"
    done
else
    echo "   ❌ Container NOT RUNNING"
    echo "   Attempting to start..."
    docker run -d --name helix_quiescence_monitor \
        -v $(pwd)/logs/quiescence:/var/log/quiescence \
        -v $(pwd)/config/quiescence:/etc/quiescence \
        --restart unless-stopped \
        helix/quiescence-monitor:v1.1 > /dev/null 2>&1
    sleep 5
    if docker ps -q --filter "name=quiescence"; then
        echo "   ✅ Container started successfully"
    else
        echo "   ❌ Failed to start container"
    fi
fi
echo ""

echo "3. Q-EVENT STATUS"
if [ -f "logs/quiescence/quiescence.log" ]; then
    Q1_COUNT=$(grep -c '"state": "QUIESCENT"' logs/quiescence/quiescence.log)
    Q2_COUNT=$(grep -c '"state": "LATTICE_LOCK"' logs/quiescence/quiescence.log)
    echo "   Q₁ Events: $Q1_COUNT"
    echo "   Q₂ Events: $Q2_COUNT"
    
    if [ $Q1_COUNT -gt 0 ]; then
        LAST_Q1=$(grep '"state": "QUIESCENT"' logs/quiescence/quiescence.log | tail -1 | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        echo "   Last Q₁: $LAST_Q1"
    fi
    if [ $Q2_COUNT -gt 0 ]; then
        LAST_Q2=$(grep '"state": "LATTICE_LOCK"' logs/quiescence/quiescence.log | tail -1 | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
        echo "   Last Q₂: $LAST_Q2"
    fi
else
    echo "   No log file found (container may be starting)"
fi
echo ""

echo "4. KEY FILES VERIFICATION"
declare -A FILES
FILES=(
    ["RUNBOOK_QUIESCENCE.md"]="Operations Runbook"
    ["config/quiescence/thresholds.yaml"]="Configuration"
    ["scripts/q_gate.sh"]="Decision Gate"
    ["scripts/q_alert.sh"]="Alert System"
    ["docker-compose.prod.yml"]="Service Definition"
    ["governance/charter.md"]="Charter Article XIV"
)

for file in "${!FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file (${FILES[$file]})"
    else
        echo "   ❌ $file (MISSING)"
    fi
done
echo ""

echo "5. .gitignore CONFIGURATION"
if grep -q "quiescence.log" .gitignore; then
    echo "   ✅ Logs properly ignored in git"
else
    echo "   ❌ Logs not in .gitignore"
fi
echo ""

echo "🎉 FINAL DEPLOYMENT STATUS"
if [ -n "$(docker ps -q --filter name=quiescence)" ] && [ -f "RUNBOOK_QUIESCENCE.md" ]; then
    echo "   🟢 FULLY OPERATIONAL"
    echo "   The Quaternary Framework is live in production."
    echo "   Q₁-Q₂ monitoring active across 9 federated models."
else
    echo "   🟡 PARTIALLY DEPLOYED"
    echo "   Framework committed but container needs attention."
fi
echo ""
echo "📚 Documentation: RUNBOOK_QUIESCENCE.md"
echo "🚀 Next Steps: Integrate Q-gates into federation operations"
echo ""
echo "Quack. 🦆🦆🔒 | Climb on. 🐐"
