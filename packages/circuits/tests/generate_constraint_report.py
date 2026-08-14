import json
import os
import re
import sys


CIRCOM_PATH = os.path.join(os.path.dirname(__file__), "..", "ace.circom")
REPORT_PATH = os.path.join(os.path.dirname(__file__), "..", "build", "ace_js", "constraint_report.json")


POSEIDON2_T9_R8_CONSTRAINTS = 384


def parse_circom_components(path):
    components = {}
    with open(path, "r") as f:
        content = f.read()

    # Count template instantiations
    instantiations = re.findall(r"component\s+(\w+)\s*=\s*(\w+)\s*\(", content)
    for var_name, template_name in instantiations:
        key = template_name
        components[key] = components.get(key, 0) + 1

    # Count component array instantiations
    array_inst = re.findall(r"component\s+(\w+)\s*\[\s*(\w+)\s*\]\s*=\s*(\w+)\s*\(", content)
    for var_name, size, template_name in array_inst:
        key = f"{template_name}[{size}]"
        components[key] = components.get(key, 0) + 1

    return components


def generate_report():
    os.makedirs(os.path.dirname(REPORT_PATH), exist_ok=True)

    components = parse_circom_components(CIRCOM_PATH)

    report = {
        "circuit": os.path.basename(CIRCOM_PATH),
        "total_constraints": None,  # populated by snarkjs at build time
        "components": components,
    }

    with open(REPORT_PATH, "w") as f:
        json.dump(report, f, indent=2)

    print(f"Generated constraint report: {REPORT_PATH}")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    generate_report()
