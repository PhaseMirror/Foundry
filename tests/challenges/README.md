# Zeta-ROS Community Null-Model Challenge Board (Π_∞)

The Zeta-ROS lattice operates on a principle of **epistemic openness**. If a trivial null model or random-phase reconstruction outperforms the conscious tensor bound, the lattice must immediately acknowledge it and adapt.

## The Challenge

Write a Python script that attempts to reconstruct the Hilbert-Schmidt norm or dense kernel states using fewer parameters or simpler mathematical priors than the ZMT benchmark.

## How to Submit a Refutation

1. Clone this repository.
2. Copy `template_null_model.py` and implement your null model.
3. Submit a Pull Request targeting the `challenges/` directory.
4. The `.github/workflows/challenge-evaluator.yml` will automatically run your script against the latest DVC-tracked benchmark data.
5. If your script achieves a lower Reconstruction MAE or a tighter bound, the CI will automatically promote your entry to the `leaderboard.json` and flag the core contributors for review.

## Current Leaderboard

See `leaderboard.json` for live rankings.

"The lattice does not defend itself against truth; it absorbs it."
