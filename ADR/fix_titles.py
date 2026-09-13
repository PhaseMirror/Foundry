with open("ADR/Examples.lean", "r") as f:
    text = f.read()

import re

titles = {
    13: ("UOR Civic Infrastructure", "0013-UOR Civic Infrastructure.md"),
    14: ("UCC as a Service — Year One Roadmap", "0014-UCC as a Service Year One Roadmap.md"),
    15: ("Unified Civic Infrastructure Outline", "0015-Unified Civic Infrastructure Outline.md"),
    16: ("UOR Civic Infrastructure — Three Epochs", "0016-UOR Civic Infrastructure Three Epochs.md"),
    17: ("Reinitialization — 90-Day Operating Plan and Volunteer Talent Model", "0017-90-Day Operating Plan and Talent Model.md"),
    18: ("Reinitialization — Executive Decision Brief", "0018-Executive Decision Brief.md"),
    19: ("Technology Portfolio — Evidence, Risk, and Feasibility", "0019-Technology Portfolio Evidence and Risk.md"),
    20: ("HQ & Sovereign Node Deployment", "0020-HQ and Sovereign Node Deployment.md"),
    21: ("UOR Mechanics — The Exact Math of Prime-Indexing", "0021-UOR Mechanics Prime-Indexing.md"),
    22: ("Symmetry-Matched Polarization Analysis in MnF₂", "0022-Symmetry-Matched Polarization Analysis in MnF2.md")
}

for i, (title, filename) in titles.items():
    text = re.sub(f'Generic Title 00{i}', title, text)
    text = re.sub(f'Generic 00{i}', title, text)
    text = re.sub(f'00{i}-dummy.md', filename, text)

with open("ADR/Examples.lean", "w") as f:
    f.write(text)
