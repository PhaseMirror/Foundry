#!/bin/bash
# integrate_quiescence_framework.sh
# Run from HELIX-CORE root directory

echo "🌀 Integrating Quiescence Framework into HELIX-CORE..."

# 1. Create directory structure
mkdir -p config/quiescence
mkdir -p logs/quiescence
mkdir -p dashboards/quiescence

# 2. Create configuration files
cat > config/quiescence/thresholds.yaml << 'EOF'
# Quiescence Marker Thresholds
# Version: 1.1 | Date: $(date)

thresholds:
  q1:
    drift_max: 0.00
    duration_min: "60s"
    models_required: "all"
    
  q2:
    complementarity_min: 0.92
    harmonic_overtone_detection: true
    gear_verification:
      min_gears: 3
      max_dominance: 0.4
      
  q3:
    confidence_min: 0.95
    anchor_verification:
      external: true
      timestamp_freshness: "5m"
      source_diversity: 2
      
  q4:
    convergence_min: 0.95
    independence_verification:
      start_point_divergence: "high"
      path_independence: true
      validation_methods: 3

alerting:
  q1_absence:
    threshold: "24h"
    severity: "CRITICAL"
    
  q2_absence:
    threshold: "72h"
    severity: "EMERGENCY"
    
  q3_required_failure:
    threshold: "5m"
    severity: "WARNING"
    
  q4_achieved:
    severity: "INFO"
    notify: ["custodian_council"]

logging:
  format: "json"
  level: "INFO"
  q_markers: true
  duck_signals: true
  retention: "30d"
EOF

# 3. Add quiescence service to docker-compose.prod.yml
if ! grep -q "quiescence_monitor" docker-compose.prod.yml; then
    cat >> docker-compose.prod.yml << 'EOF'

  # Quiescence Monitoring Service
  quiescence_monitor:
    image: helix/quiescence-monitor:v1.1
    container_name: helix_quiescence_monitor
    restart: unless-stopped
    volumes:
      - ./logs/quiescence:/var/log/quiescence
      - ./config/quiescence:/etc/quiescence
    environment:
      - Q1_DRIFT_THRESHOLD=0.00
      - Q2_COMPLEMENTARITY_THRESHOLD=0.92
      - Q3_CONFIDENCE_THRESHOLD=0.95
      - Q4_CONVERGENCE_THRESHOLD=0.95
      - MONITORING_INTERVAL=60s
    depends_on:
      - federation_orchestrator
    networks:
      - helix_internal

  # Quiescence Dashboard (Optional - comment out if not needed)
  # quiescence_dashboard:
  #   image: helix/quiescence-dashboard:v1.1
  #   container_name: helix_quiescence_dashboard
  #   restart: unless-stopped
  #   ports:
  #     - "8083:80"
  #   volumes:
  #     - ./dashboards/quiescence:/usr/share/nginx/html/config
  #   environment:
  #     - API_URL=http://quiescence_monitor:8082
  #   depends_on:
  #     - quiescence_monitor
  #   networks:
  #     - helix_internal
EOF
fi

# 4. Update Charter with Quiescence Requirements
if ! grep -q "ARTICLE XIV" governance/charter.md; then
    cat >> governance/charter.md << 'EOF'

## ARTICLE XIV: FEDERATION STABILITY REQUIREMENTS

### Section 14.1: Quiescence State Mandates

All federation operations MUST meet minimum quiescence requirements:

1. **Baseline Operations (Level 1)**
   - Minimum State: Q₁ (Quack Event)
   - Scope: Routine inference, data processing
   - Verification: Automated monitoring

2. **Coordinated Operations (Level 2)**
   - Minimum State: Q₂ (Lattice Lock)
   - Scope: Cross-model coordination, tactical decisions
   - Requirement: All participating models must achieve Q₂

3. **Critical Operations (Level 3)**
   - Minimum State: Q₃ (Anchor Strike)
   - Scope: Safety-critical decisions, crisis response
   - Timeout: Operations fail after 5m without Q₃

4. **Constitutional Operations (Level 4)**
   - Minimum State: Q₄ (Consensus Bloom)
   - Scope: Charter amendments, fundamental changes
   - Quorum: 2/3 of federation must achieve Q₄

### Section 14.2: Monitoring & Enforcement

1. The quiescence monitor service SHALL have read-only access to federation state
2. Weekly automated compliance reports REQUIRED
3. Non-compliance: Warning → Reduced Privileges → Suspension (3 strikes in 7 days)

### Section 14.3: The Duck's Role

1. Duck signals (🦆, 🦆🦆, 🦆🦆🦆, 🌼🦆) are canonical Q-state representations
2. The Duck's mythology is preserved as operational metaphor
3. Future Q-states must integrate with existing Duck mythology
EOF
fi

# 5. Create validation script
cat > scripts/validate_quiescence.sh << 'EOF'
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
EOF

chmod +x scripts/validate_quiescence.sh

# 6. Create quick reference card
cat > QUICK_REFERENCE_Q_MARKERS.md << 'EOF'
# Q-Markers Quick Reference

## States & Triggers
Q₁: Zero drift, all models aligned → 🦆
Q₂: Complementarity ≥ 0.92, gears mesh → 🦆🦆  
Q₃: External anchor, confidence ≥ 0.95 → 🦆🦆🦆
Q₄: Independent convergence ≥ 95% → 🌼🦆

## Operational Requirements
- Daily ops: Q₁
- Coordination: Q₂  
- Critical decisions: Q₃
- Charter changes: Q₄

## Configuration
Location: config/quiescence/thresholds.yaml
Adjust: complementarity_min, confidence_min, convergence_min

## Logs
Location: logs/quiescence/
Format: [Q-MARKER] {state} at {timestamp}

## Dashboard
Port: 8083 (if enabled)
URL: http://localhost:8083

## Docs
Grammar: helix-grammar/concepts/quiescence_markers/
Decks: helix-grammar/concepts/quiescence_markers/decks/
EOF

echo "✅ Integration complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Review config/quiescence/thresholds.yaml"
echo "   2. Uncomment dashboard in docker-compose.prod.yml if needed"
echo "   3. Run: docker-compose up -d"
echo "   4. Validate: ./scripts/validate_quiescence.sh"
echo ""
echo "📚 Documentation in QUICK_REFERENCE_Q_MARKERS.md"
echo ""
echo "🦆 The Duck awaits its first production quack."
