#!/bin/bash
echo "🦆 Validating Quiescence Framework..."

echo "1. Checking directories..."
[ -d "config/quiescence" ] && echo "✅ config/quiescence" || echo "❌ Missing config"
[ -d "logs/quiescence" ] && echo "✅ logs/quiescence" || echo "❌ Missing logs"

echo "2. Checking configuration..."
[ -f "config/quiescence/thresholds.yaml" ] && echo "✅ thresholds.yaml" || echo "❌ Missing"

echo "3. Checking Charter updates..."
grep -q "ARTICLE XIV" governance/charter.md && echo "✅ Charter updated" || echo "❌ Charter not updated"

echo "4. Checking docker-compose..."
grep -q "quiescence_monitor" docker-compose.prod.yml && echo "✅ Service defined" || echo "❌ Service missing"

echo ""
echo "🎯 To complete:"
echo "   1. Update image tags in docker-compose.prod.yml (if using custom images)"
echo "   2. Adjust thresholds in config/quiescence/thresholds.yaml"
echo "   3. Run: docker-compose up -d"
echo "   4. Monitor: tail -f logs/quiescence/quiescence.log"
