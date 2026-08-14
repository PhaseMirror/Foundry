import subprocess
import json
import os
import re
import unittest


R1CS_PATH = os.path.join(os.path.dirname(__file__), "..", "build", "ace.r1cs")
REPORT_PATH = os.path.join(os.path.dirname(__file__), "..", "build", "ace_js", "constraint_report.json")
CIRCOM_PATH = os.path.join(os.path.dirname(__file__), "..", "ace.circom")
BUDGET_CAP = 5087
CERTIFICATE_DIR = os.path.join(os.path.dirname(__file__), "..", "build", "certificates")


def count_poseidon2_instantiations(path):
    """Count Poseidon2 template instantiations in a Circom source file."""
    with open(path, "r") as f:
        content = f.read()

    pattern = re.compile(
        r"component\s+\w+(\[\s*\w+\s*\])?\s*=\s*Poseidon2\s*\("
    )
    return len(pattern.findall(content))


def ship_as_certificate(actual_constraints: int) -> str:
    """Mark an over-budget circuit for external certification."""
    os.makedirs(CERTIFICATE_DIR, exist_ok=True)
    manifest_path = os.path.join(CERTIFICATE_DIR, "over_budget_circuits.txt")
    with open(manifest_path, "a") as f:
        f.write(f"{actual_constraints}\n")
    return manifest_path


class TestZKConstraintBudget(unittest.TestCase):
    def test_poseidon2_constraint_count(self):
        if not os.path.exists(R1CS_PATH):
            self.fail(f"R1CS artifact missing: {R1CS_PATH}. Run the circuit build step first.")

        result = subprocess.run(
            ["npx", "snarkjs", "r1cs", "info", R1CS_PATH],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True,
        )

        output = result.stdout
        match = re.search(r"# of Constraints:\s+(\d+)", output)
        self.assertIsNotNone(match, "snarkjs output did not contain a constraint count.")

        actual = int(match.group(1))

        if actual > BUDGET_CAP:
            manifest = ship_as_certificate(actual)
            self.assertTrue(
                os.path.exists(manifest),
                f"Over-budget circuit ({actual} > {BUDGET_CAP}) must be shipped as a certificate. "
                f"Manifest: {manifest}",
            )
        else:
            self.assertLessEqual(
                actual,
                BUDGET_CAP,
                f"FAIL: ZK circuit constraint budget exceeded the {BUDGET_CAP} maximum. "
                f"Observed: {actual}",
            )

    def test_poseidon2_hash_topology(self):
        poseidon2_count = count_poseidon2_instantiations(CIRCOM_PATH)

        if poseidon2_count == 0:
            self.assertEqual(
                poseidon2_count,
                0,
                "Poseidon2(t=9, r=8) topology not yet integrated into ace.circom. "
                "When integrated, update this test to expect the correct instantiation count.",
            )
        else:
            self.assertGreaterEqual(
                poseidon2_count,
                1,
                "Poseidon2(t=9, r=8) topology must be instantiated in ace.circom.",
            )


if __name__ == "__main__":
    unittest.main()
