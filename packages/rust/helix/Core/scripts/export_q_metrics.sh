#!/bin/bash
echo "# HELP helix_q_state Current Q state"
echo "# TYPE helix_q_state gauge"
echo "helix_q_state{state=\"Q1\"} $(grep -c '"state": "QUIESCENT"' logs/quiescence/quiescence.log 2>/dev/null || echo 0)"
echo "helix_q_state{state=\"Q2\"} $(grep -c '"state": "LATTICE_LOCK"' logs/quiescence/quiescence.log 2>/dev/null || echo 0)"
echo "helix_q_state{state=\"Q3\"} $(grep -c '"state": "ANCHOR_STRIKE"' logs/quiescence/quiescence.log 2>/dev/null || echo 0)"
echo "helix_q_state{state=\"Q4\"} $(grep -c '"state": "CONSENSUS_BLOOM"' logs/quiescence/quiescence.log 2>/dev/null || echo 0)"
