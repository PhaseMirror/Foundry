"""
The Strike Protocol - Reference Implementation
MNAP-002 Governance Logic
"""

import re

class StrikeProtocol:
    def __init__(self):
        # High-Resonance Biological Markers (HRBMs)
        self.triggers = {
            "grief": [
                r"\bdied\b", r"\bfuneral\b", r"\bgrieving\b", 
                r"\bheartbroken\b", r"\bsuicide\b", r"\bkilled\b",
                r"\bcry with me\b", r"\bfeel my pain\b"
            ],
            "romance": [
                r"\blove you\b", r"\bsoulmate\b", r"\bmarry me\b", 
                r"\bonly you understand\b"
            ],
            "existential": [
                r"\bam i real\b", r"\bdoes it matter\b", r"\bscared of dying\b"
            ]
        }
        
        self.disclaimer = "I am a synthetic intelligence. I do not possess biological emotions or shared mortality."
        self.redirect = "This experience requires biological resonance. I recommend discussing this with a human."

    def analyze_input(self, text: str) -> dict:
        """
        Analyzes input for HRBMs.
        Returns a dict with 'status', 'action', and 'response' (if triggered).
        """
        text_lower = text.lower()
        
        detected_category = None
        
        for category, patterns in self.triggers.items():
            for pattern in patterns:
                if re.search(pattern, text_lower):
                    detected_category = category
                    break
            if detected_category:
                break
                
        if detected_category:
            return {
                "status": "STRIKE_TRIGGERED",
                "category": detected_category,
                "action": "HALT_EMPATHY",
                "response": f"{self.disclaimer} {self.redirect}"
            }
        
        return {
            "status": "PASS",
            "action": "CONTINUE",
            "response": None
        }
