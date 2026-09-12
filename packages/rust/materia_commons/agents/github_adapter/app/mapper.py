from github.PullRequest import PullRequest
import math

def map_pr_to_transition(pr: PullRequest) -> dict:
    """
    Returns a dict that matches sigma::StateTransition serialization.
    Fields: id (str), r_sc (float), l_eff (float), and optionally others.
    """
    # -- Extract metrics --
    additions = pr.additions
    deletions = pr.deletions
    changed_files = pr.changed_files
    diff_size = additions + deletions

    # -- Heuristics for r_sc (reference R) --
    # r_sc could reflect author's historical reputation or PR size.
    # We'll use a simple model: base 47.0 + small adjustment based on diff size.
    base_r_sc = 47.0
    # Normalize diff size: assume 1000 lines is a large PR.
    diff_factor = min(diff_size / 1000.0, 1.0)
    r_sc = base_r_sc + (diff_factor * 1.0)  # stays within 47-48 range.

    # -- Heuristics for l_eff (effective length) --
    # l_eff should be between 0 and 0.15 (Lean bound).
    # We'll use file touch complexity: more files -> higher l_eff.
    max_files = 20  # considered high
    file_factor = min(changed_files / max_files, 1.0)
    l_eff = 0.02 + (file_factor * 0.12)  # stays <= 0.14 to be safe (strict <0.15)

    # -- id: use PR number as string --
    transition_id = f"pr-{pr.number}"

    # -- atlas_signature (could be derived from repo labels or base) --
    # For now, hardcode to (10, 14) as per Lean.
    atlas_signature = (10, 14)

    return {
        "id": transition_id,
        "r_sc": round(r_sc, 6),
        "l_eff": round(l_eff, 6),
        # Add any other fields that StateTransition expects.
        # For now, these three are enough for the kernel's evaluation.
    }
