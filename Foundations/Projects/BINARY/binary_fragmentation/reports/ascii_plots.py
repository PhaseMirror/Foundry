"""
reports/ascii_plots.py
======================
Zero-Dependency ASCII Charts and Sparklines for Terminal Visualizations.
"""

from __future__ import annotations
from typing import List


def render_ascii_bar(val: float, max_val: float = 1.0, width: int = 30) -> str:
    """Renders a progress/loss bar: [████████░░░░░░░░] 0.50"""
    clamped = max(0.0, min(val, max_val))
    ratio = clamped / max(max_val, 1e-9)
    filled_len = int(round(ratio * width))
    unfilled_len = width - filled_len
    bar = "█" * filled_len + "░" * unfilled_len
    return f"[{bar}] {val:.4f}"


def render_ascii_sparkline(values: List[float], width: int = 40) -> str:
    """Renders a sparkline for drift trajectories: ░ ▂▃▄▅▆▇█"""
    if not values:
        return ""
    ticks = [" ", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
    min_v = min(values)
    max_v = max(values)
    span = max_v - min_v if max_v > min_v else 1.0

    chars = []
    for v in values:
        idx = int((v - min_v) / span * (len(ticks) - 1))
        idx = max(0, min(idx, len(ticks) - 1))
        chars.append(ticks[idx])

    return "".join(chars)


def render_trajectory_chart(values: List[float], height: int = 8, width: int = 50) -> str:
    """Renders a 2D ASCII line plot of drift over recursive generations."""
    if not values:
        return "No trajectory data."

    min_v = 0.0
    max_v = max(max(values), 0.1)
    
    # Resample or pad values to width
    n = len(values)
    lines = []
    lines.append(f"Drift D_n (max={max_v:.4f})")
    lines.append("  ┌" + "─" * (n * 3 + 2) + "┐")

    for h in range(height, -1, -1):
        threshold = min_v + (max_v - min_v) * (h / height)
        row = [f"{threshold:4.2f} │ "]
        for v in values:
            if v >= threshold:
                row.append(" ● ")
            else:
                row.append(" · ")
        row.append("│")
        lines.append("".join(row))

    lines.append("     └" + "─" * (n * 3 + 2) + "┘")
    gen_row = ["       "] + [f"{i:2d} " for i in range(len(values))]
    lines.append("".join(gen_row) + " (Generation n)")

    return "\n".join(lines)
