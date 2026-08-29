"""
tests/test_experiments.py
==========================
Unit tests for all experiment suites:
Modes A-E, Financial, Rollback, Relational Stress, Comparative Stress,
Provenance Cascade, Rich Sharding, Adversarial Schema, Temporal Permutation,
Chained ETL Pipeline, Advanced Failures Frontier Suite, Real-World Case Studies 1 & 2.
"""

import unittest
from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.experiments.baseline import BaselineExperiment
from binary_fragmentation.experiments.lossy import LossyBinaryExperiment
from binary_fragmentation.experiments.recursive import RecursiveDriftExperiment
from binary_fragmentation.experiments.network import NetworkFragmentationExperiment
from binary_fragmentation.experiments.comparative import ComparativeRepresentationExperiment
from binary_fragmentation.experiments.financial_relational import FinancialRelationalExperiment
from binary_fragmentation.experiments.rollback import RollbackExperiment
from binary_fragmentation.experiments.relational_stress import (
    RelationalStressExperiment,
    ComparativeStressExperiment,
)
from binary_fragmentation.experiments.provenance_cascade import ProvenanceCascadeExperiment
from binary_fragmentation.experiments.rich_sharding import RichShardingExperiment
from binary_fragmentation.experiments.etl_metadata_stripping import ETLMetadataStrippingExperiment
from binary_fragmentation.experiments.adversarial_schema import AdversarialSchemaExperiment
from binary_fragmentation.experiments.temporal_permutation import TemporalPermutationExperiment
from binary_fragmentation.experiments.chained_etl_pipeline import ChainedEnterpriseETLExperiment
from binary_fragmentation.experiments.advanced_failures import AdvancedFailuresExperimentSuite
from binary_fragmentation.experiments.real_world_case_study import RealWorldCorporateCaseStudy
from binary_fragmentation.experiments.procurement_case_study import ProcurementCaseStudy
from binary_fragmentation.metrics.semantic import compute_semantic_loss


def get_fixture_state() -> State:
    st = State(context={"test": True})
    st.add_node(Node(id="a", value=100.0, created_at=10.0, attributes={"role": "supplier"}))
    st.add_node(Node(id="b", value=200.0, created_at=20.0, attributes={"role": "supplier"}))
    st.add_node(Node(id="c", value=300.0, created_at=30.0, attributes={"role": "buyer"}))
    st.add_edge(Edge(source_id="a", target_id="b", relation_type="transfers", weight=100.0))
    st.add_edge(Edge(source_id="b", target_id="c", relation_type="transfers", weight=200.0))
    return st


class TestExperiments(unittest.TestCase):
    def test_mode_a_baseline(self):
        st = get_fixture_state()
        res = BaselineExperiment().run(st)
        self.assertTrue(res["lossless_exact_match"])
        self.assertEqual(res["vector"]["F_v"], 0.0)

    def test_mode_b_lossy(self):
        st = get_fixture_state()
        res = LossyBinaryExperiment().run(st)
        self.assertEqual(res["final_edges"], 0)

    def test_mode_c_recursive(self):
        st = get_fixture_state()
        res = RecursiveDriftExperiment(iterations=5).run(st)
        self.assertEqual(len(res["drift_trajectory"]), 6)
        self.assertTrue("dynamics_classification" in res)

    def test_mode_d_network(self):
        st = get_fixture_state()
        res = NetworkFragmentationExperiment(num_shards=2).run(st)
        self.assertTrue("cross_edges_lost" in res)

    def test_mode_e_comparative(self):
        st = get_fixture_state()
        res = ComparativeRepresentationExperiment().run(st)
        self.assertEqual(len(res["comparison"]), 5)

    def test_financial_relational_experiment(self):
        res = FinancialRelationalExperiment().run()
        self.assertTrue(res["crucial_hypothesis_confirmed"])

    def test_rollback_experiment(self):
        st = get_fixture_state()
        res = RollbackExperiment().run(st)
        self.assertTrue(res["computational_irreversibility_index"] > 0.0)

    def test_relational_stress_preserves_topology(self):
        st = get_fixture_state()
        res = RelationalStressExperiment(cycles=5).run(st)
        self.assertTrue(res["relational_preservation_maintained"])
        self.assertEqual(res["final_edges"], 2)

    def test_comparative_stress(self):
        st = get_fixture_state()
        res = ComparativeStressExperiment(cycles=3).run(st)
        self.assertEqual(len(res["results"]), 5)

    def test_provenance_cascade(self):
        st = get_fixture_state()
        res = ProvenanceCascadeExperiment().run(st)
        self.assertNotEqual(res["first_irreversible_stage"], "None")

    def test_rich_sharding(self):
        st = get_fixture_state()
        res = RichShardingExperiment(num_shards=2).run(st)
        self.assertEqual(res["rich_relational_sharding"]["edges_lost"], 0)

    def test_etl_metadata_stripping(self):
        st = get_fixture_state()
        res = ETLMetadataStrippingExperiment().run(st)
        self.assertEqual(res["metrics"]["relational_loss_Fr"], 1.0)

    def test_adversarial_schema_failures(self):
        st = get_fixture_state()
        res = AdversarialSchemaExperiment().run(st)
        self.assertEqual(res["node_only_serialization"]["relational_loss_Fr"], 1.0)

    def test_temporal_permutation(self):
        res = TemporalPermutationExperiment().run()
        self.assertTrue(res["temporal_loss_Ft"] > 0.0)

    def test_chained_etl_pipeline(self):
        res = ChainedEnterpriseETLExperiment().run()
        self.assertEqual(res["total_hops"], 5)
        self.assertEqual(res["final_vector"]["F_r"], 1.0)

    def test_advanced_failures_suite(self):
        st = get_fixture_state()
        res = AdvancedFailuresExperimentSuite().run(st)
        self.assertTrue("differential_privacy_sweep" in res["results"])
        self.assertTrue("sampling_sweep" in res["results"])
        self.assertTrue("entity_resolution" in res["results"])

    def test_real_world_case_study_1(self):
        res = RealWorldCorporateCaseStudy().run()
        self.assertTrue(res["regimes"]["1_sovereign_relational_ledger"]["ubo_traceability_intact"])
        self.assertFalse(res["regimes"]["2_enterprise_csv_data_mart"]["ubo_traceability_intact"])

    def test_real_world_case_study_2(self):
        res = ProcurementCaseStudy().run()
        self.assertTrue(res["regimes"]["1_sovereign_relational_ledger"]["conflict_of_interest_detectable"])
        self.assertFalse(res["regimes"]["2_open_data_csv_tender_portal"]["conflict_of_interest_detectable"])

    def test_semantic_equivalence_metric(self):
        st0 = get_fixture_state()
        st1 = st0.clone()
        st1.edges = [Edge(source_id="a", target_id="c", relation_type="direct_master", weight=300.0)]
        sem_loss = compute_semantic_loss(st0, st1)
        self.assertEqual(sem_loss, 0.0)


if __name__ == "__main__":
    unittest.main()
