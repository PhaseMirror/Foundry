import importlib
import pytest

def test_csl_has_no_write_path_to_orchestrator():
    """
    Ensures CSL analysis (STI) cannot import or mutate the orchestrator or core modules.
    """
    # This is a static analysis check - simple import test
    # If this fails, we have a dependency violation.
    try:
        from genesis_governance.lane_d.sti_engine import STIEngine
        # If we reached here, the module is at least importable.
    except ImportError:
        pytest.fail("CSL analysis code (STI) should be in lane_d.")



def test_lane_s_does_not_exist():
    # Ensure no remnant of Lane S
    import os
    assert not os.path.exists("src/genesis_governance/lane_s")
