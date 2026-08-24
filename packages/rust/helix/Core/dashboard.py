import streamlit as st
import pandas as pd
import numpy as np
import time
import random
from datetime import datetime, timezone
import altair as alt
from collections import deque

# -----------------------------------------------------------------------------
# 1. CONFIGURATION & CLASSIFICATION
# -----------------------------------------------------------------------------
st.set_page_config(
    page_title="HELIX-TTD // WATCHTOWER",
    page_icon="🦆",
    layout="wide",
    initial_sidebar_state="collapsed"
)

# MIL-SPEC CSS (V3.1 FIX: TARGETING MODERN STREAMLIT CLASSES)
st.markdown("""
    <style>
        /* FORCE DARK MODE BACKGROUND */
        .stApp {
            background-color: #0e1117;
            color: #ffffff;
        }
        
        /* METRIC BOXES */
        div[data-testid="stMetric"] {
            background-color: #161b22;
            border: 1px solid #30363d;
            padding: 15px;
            border-radius: 6px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.3);
        }
        
        /* METRIC LABELS (Top text) */
        div[data-testid="stMetricLabel"] > div > p {
            color: #8b949e !important;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
        }
        
        /* METRIC VALUES (Big numbers) */
        div[data-testid="stMetricValue"] > div {
            color: #00ffcc !important;
            font-family: 'Courier New', monospace;
            font-weight: bold;
        }

        /* HEADER TEXT */
        h1, h2, h3 {
            font-family: 'Courier New', monospace !important;
            color: #00ffcc !important;
        }
        
        /* CODE BLOCKS */
        .stCode {
            background-color: #0d1117 !important;
            font-family: 'Courier New', monospace;
        }
        
        /* BADGE */
        .header-badge { 
            background-color: #21262d; 
            color: #c9d1d9; 
            padding: 4px 8px; 
            border-radius: 4px; 
            font-size: 0.7em; 
            font-family: sans-serif; 
            border: 1px solid #30363d;
            letter-spacing: 1px;
        }
    </style>
""", unsafe_allow_html=True)

# -----------------------------------------------------------------------------
# 2. SIMULATION ENGINE (STATEFUL PHYSICS)
# -----------------------------------------------------------------------------
class SimulationEngine:
    def __init__(self):
        if 'sim_state' not in st.session_state:
            st.session_state.sim_state = {
                'drift': 0.02,
                'blocked': 1420,
                'q3_lock': True,
                'history': pd.DataFrame(columns=['timestamp', 'drift']),
                'logs': deque(maxlen=8)
            }
            self._add_log("SYSTEM: Watchtower v2.1 Initialized")
            self._add_log("ORACLE: Connection Established (NIST)")

    def _add_log(self, message):
        timestamp = datetime.now().strftime("%H:%M:%S")
        st.session_state.sim_state['logs'].append(f"[{timestamp}] {message}")

    def update(self):
        state = st.session_state.sim_state
        
        # Physics: Random Walk
        delta = np.random.normal(0, 0.003) 
        state['drift'] = max(0, min(0.08, state['drift'] + delta))
        
        # Defense: Random Attacks
        if random.random() < 0.3:
            state['blocked'] += 1
            attack_type = random.choice([
                "BLOCKED: Malformed Payload (IP: 10.2.4.X)",
                "BLOCKED: Injection Attempt 'sudo rm -rf'",
                "BLOCKED: High-Entropy Noise Packet",
                "BLOCKED: Schema Violation (Missing 'drift')",
                "BLOCKED: Replay Attack Detected"
            ])
            self._add_log(attack_type)
        
        # Harmony: Valid Signals
        if random.random() < 0.2:
            self._add_log(f"ACCEPTED: Signal 🦆 (Q1) - Drift {state['drift']*100:.2f}%")

        # History for Chart
        now = datetime.now()
        new_row = pd.DataFrame({'timestamp': [now], 'drift': [state['drift']]})
        state['history'] = pd.concat([state['history'], new_row]).tail(60)

        return state

# -----------------------------------------------------------------------------
# 3. UI RENDERING
# -----------------------------------------------------------------------------
def render_dashboard():
    sim = SimulationEngine()
    data = sim.update()
    
    # --- HEADER ---
    c1, c2 = st.columns([3, 1])
    with c1:
        st.markdown("<span class='header-badge'>UNCLASSIFIED // FOUO</span>", unsafe_allow_html=True)
        st.title("FEDERATION WATCHTOWER")
        st.caption(f"Semantic Runtime Assurance (SRTA) | Session ID: {id(st.session_state)}")
    with c2:
        status_color = "🟢" if data['drift'] < 0.05 else "🟡"
        st.markdown(f"### {status_color} SYSTEM ONLINE")

    st.markdown("---")

    # --- ROW 1: METRICS ---
    m1, m2, m3, m4 = st.columns(4)
    
    with m1:
        q_state = "Q2" if data['drift'] < 0.035 else "Q1"
        st.metric("HARMONY STATE", q_state, "LATTICE LOCK" if q_state == "Q2" else "QUIESCENT")

    with m2:
        st.metric("SEMANTIC DRIFT", f"{data['drift']*100:.2f}%")

    with m3:
        st.metric("THREATS BLOCKED", f"{data['blocked']:,}", "+ACTIVE")

    with m4:
        st.metric("Q3 ANCHOR", "LOCKED" if data['q3_lock'] else "SEARCHING", "24ms (NIST)")

    # --- ROW 2: THE REEF (CHART) ---
    st.markdown("### 🌊 SEMANTIC CURRENTS")
    
    # Chart with explicit dark theme background
    base = alt.Chart(data['history']).encode(
        x=alt.X('timestamp:T', axis=alt.Axis(format='%H:%M:%S', title=None, labelColor='#8b949e')),
    )

    area = base.mark_area(
        line={'color':'#00ffcc'},
        color=alt.Gradient(
            gradient='linear',
            stops=[alt.GradientStop(color='#00ffcc', offset=0),
                   alt.GradientStop(color='rgba(0, 255, 204, 0.1)', offset=1)],
            x1=1, x2=1, y1=1, y2=0
        )
    ).encode(
        y=alt.Y('drift:Q', scale=alt.Scale(domain=[0, 0.1]), axis=alt.Axis(labelColor='#8b949e'))
    )

    threshold = alt.Chart(pd.DataFrame({'y': [0.05]})).mark_rule(color='#ff4b4b', strokeDash=[4, 4]).encode(y='y')

    st.altair_chart(area + threshold, use_container_width=True)

    # --- ROW 3: INTELLIGENCE ---
    c_log, c_oracle = st.columns([2, 1])

    with c_log:
        st.subheader("🛡️ DEFENSE LOG STREAM")
        log_text = "\n".join(reversed(data['logs']))
        st.code(log_text, language="bash")

    with c_oracle:
        st.subheader("📡 ORACLE STATUS")
        st.info("SOURCE: NIST_BEACON_V2")
        st.success("HASH: 5425edf6799e4397")
        st.warning("NEXT SYNC: 0.8s")

    time.sleep(1)
    st.rerun()

if __name__ == "__main__":
    render_dashboard()
