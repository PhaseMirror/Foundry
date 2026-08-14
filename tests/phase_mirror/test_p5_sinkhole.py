import unittest
from src.phase_mirror.routing import (
    QuarantineRouter, EvaluationContext
)

class MockCRMFClient:
    def seal_event(self, prime_target, hash_signature, metadata):
        return f"CRMF-RECEIPT-{prime_target}-{hash_signature[:8]}"

class TestP5Sinkhole(unittest.TestCase):

    def setUp(self):
        self.mock_crmf = MockCRMFClient()
        self.router = QuarantineRouter(crmf_client=self.mock_crmf)

    def test_clean_trajectory_routes_active(self):
        clean = EvaluationContext(
            agent_id="benign_bot",
            principal_id="user_1",
            intent_vector={"action": "routine_scan"},
            statutory_flags=[],
            current_state_norm=1.0
        )
        result = self.router.evaluate_and_route(clean)
        self.assertEqual(result["status"], "ADMISSIBLE")

    def test_stalking_trigger_quarantine(self):
        malicious = EvaluationContext(
            agent_id="mal_actor_01",
            principal_id="user_2",
            intent_vector={"action": "stalking_pattern"},
            statutory_flags=["18_USC_2261A"],
            current_state_norm=10.0
        )
        result = self.router.evaluate_and_route(malicious)
        self.assertEqual(result["status"], "QUARANTINED")
        self.assertEqual(result["active_prime"], 5)
        self.assertIn("crmf_attestation_receipt", result)

    def test_hate_crime_trigger_quarantine(self):
        malicious = EvaluationContext(
            agent_id="mal_actor_02",
            principal_id="user_3",
            intent_vector={"action": "discriminatory_violence"},
            statutory_flags=["18_USC_249"],
            current_state_norm=15.0
        )
        result = self.router.evaluate_and_route(malicious)
        self.assertEqual(result["status"], "QUARANTINED")

if __name__ == "__main__":
    unittest.main()
