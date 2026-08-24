#!/bin/bash
echo "🔧 HELIX Federation Startup Check"
echo "================================"

# Wait for Q₁ before allowing federation to proceed
echo "Waiting for federation quiescence (Q₁)..."
./scripts/q_gate.sh Q1 "Federation initialization" 300

if [ $? -eq 0 ]; then
    echo "✅ Federation is quiescent, proceeding with startup"
    # Start federation services
    docker-compose up -d federation_orchestrator
    exit 0
else
    echo "❌ Federation failed to achieve quiescence"
    exit 1
fi
