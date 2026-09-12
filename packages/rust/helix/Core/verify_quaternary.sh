#!/bin/bash
echo "🦆 HELIX QUATERNARY FRAMEWORK - DEPLOYMENT VERIFICATION"
echo "======================================================="

echo "1. GIT STATUS"
echo "   Commit: $(git log --oneline -1)"
echo "   Tag: $(git describe --tags --abbrev=0 2>/dev/null || echo 'None')"
echo "   Branch: $(git branch --show-current)"

echo -e "\n2. CONTAINER STATUS"
if docker ps --filter "name=quiescence" --format "{{.Names}}" | grep -q quiescence; then
    echo "   ✅ helix_quiescence_monitor: RUNNING"
    echo "   Uptime: $(docker ps --filter "name=quiescence" --format "{{.RunningFor}}")"
else
    echo "   ❌ helix_quiescence_monitor: NOT RUNNING"
fi

echo -e "\n3. Q-EVENT STATUS"
Q1_COUNT=$(grep -c '"state": "QUIESCENT"' logs/quiescence/quiescence.log 2>/dev/null || echo 0)
Q2_COUNT=$(grep -c '"state": "LATTICE_LOCK"' logs/quiescence/quiescence.log 2>/dev/null || echo 0)
echo "   Q₁ Events: $Q1_COUNT"
echo "   Q₂ Events: $Q2_COUNT"

if [ -f logs/quiescence/quiescence.log ]; then
    LAST_EVENT=$(tail -1 logs/quiescence/quiescence.log | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4 || echo "None")
    echo "   Last Event: $LAST_EVENT"
fi

echo -e "\n4. OPERATIONAL FILES"
[ -f RUNBOOK_QUIESCENCE.md ] && echo "   ✅ RUNBOOK_QUIESCENCE.md" || echo "   ❌ RUNBOOK_QUIESCENCE.md"
[ -f scripts/q_gate.sh ] && echo "   ✅ scripts/q_gate.sh" || echo "   ❌ scripts/q_gate.sh"
[ -f config/quiescence/thresholds.yaml ] && echo "   ✅ config/quiescence/thresholds.yaml" || echo "   ❌ config.yaml"
[ -f docker-compose.prod.yml ] && echo "   ✅ docker-compose.prod.yml" || echo "   ❌ docker-compose.prod.yml"

echo -e "\n5. CHARTER INTEGRATION"
if grep -q "ARTICLE XIV" governance/charter.md; then
    echo "   ✅ Charter Article XIV present"
else
    echo "   ❌ Charter not updated"
fi

echo -e "\n🎉 DEPLOYMENT VERIFICATION COMPLETE"
echo "🦆 The Duck quacks in production"
echo "📚 Runbook: RUNBOOK_QUIESCENCE.md"
echo "🚀 Next: Integrate Q-gates into federation operations"
